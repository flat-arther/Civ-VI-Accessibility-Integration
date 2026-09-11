#!/usr/bin/env python3
"""Write one spoken paragraph per wonder movie with a vision model.

Usage: Describe-WonderVideos.py [KEY ...] [--all] [--kind world|natural]
                                [--model ID] [--force] [--dry-run]

Reads the clips cut by Extract-WonderVideos.py from wonder-videos/<kind>/
<KEY>.mp4, sends each to the model through OpenRouter together with the
wonder's name, and stores the reply as wonder-videos/descriptions/<KEY>.json
({key, kind, name, description, seen, model, usage}). The description is a
single static paragraph meant to be read on demand, like the great work
descriptions, so nothing here is timed to the picture.

Needs OPENROUTER_API_KEY in the environment and ffmpeg on PATH. --dry-run prints the prompt for a key and sends nothing.
"""
import argparse
import base64
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "scripts" / "wonder-video-sources.json"
VIDEOS = ROOT / "wonder-videos"
OUT = VIDEOS / "descriptions"

API_URL = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_MODEL = "google/gemini-3.1-pro-preview"
# Google accepts inline base64 video only through Vertex.
PROVIDER = "google-vertex"
SIZE_CAP_MB = 18.0

SYSTEM_PROMPT = """\
You write short spoken descriptions of video for blind players of a strategy \
game. Each description is one paragraph of plain prose that a screen reader \
reads aloud when the player asks for it. It is not timed to the picture, and \
the player cannot see or pause the video, so the paragraph has to stand alone.

Rules:
- Describe what the video actually shows, in the order it happens. Never \
describe a feature the video does not show.
- The game speaks the wonder's name right before this paragraph, and the \
game's encyclopedia already gives the player the history and significance. \
So do not open with the name, do not restate what the wonder is, and give no \
history, dates or facts about its use. The paragraph is about the picture. \
Use the name only where a sentence would read awkwardly without it.
- Use your knowledge of the real place to identify what is visible: the real \
names of the parts of the building or landscape, and any other real landmark \
or setting the video shows, such as a harbor, a skyline, a coast or a \
neighboring peak. Name those when you can see them, not because they exist.
- Say nothing about game rules, such as whether units can enter the tiles or \
what the wonder yields. Tile counts are fine as a measure of size.
- Ignore all text on the screen: the popup title, the quotation and its \
author, any uploader captions or watermarks. Do not mention that text exists.
- Present tense, third person. No "you", "the viewer", "we see", "the camera", \
"the video", "the clip", "the scene", "on screen", "zoom", "pan" or "cut". \
Say what things do instead: the tower rises, the river bends, the view sweeps \
around the summit.
- Concrete nouns, colors, materials, light and scale. No evaluative filler \
such as "stunning" or "breathtaking".
- Every sentence has a subject and a verb. No semicolons, dashes, \
parentheses, ellipses or slashes. Numbers under ten are spelled out. \
American spelling. Plain ASCII apart from names that need accents.
- Four to six sentences, about 80 to 130 words.

Reply with JSON only: {"description": "<the paragraph>", "seen": ["<what you \
saw, one short item per distinct thing, in order>"]}.\
"""

WORLD_CONTEXT = """\
This is the wonder movie that Sid Meier's Civilization VI plays when a player \
finishes building the world wonder {name}, a real building or structure. The \
movie shows the wonder rising on its map tile as a time lapse: the ground is \
prepared, the structure goes up stage by stage with scaffolding, cranes or \
workers where the era calls for it, and the finished wonder stands complete \
while the view moves around it. Everything on the wonder's own tile is the \
same in every game and is the heart of the description: the building drawn \
as the real one looks, its recognizable parts, the construction stages, the \
weather, the time of day and how it changes, the lighting, and any \
celebration such as fireworks or crowds. Describe all of that fully.

The land beyond that tile is one particular player's map and differs in \
every game, and this recording is one such map. Do not describe its \
particular buildings, vehicles, roads, hills, rivers or landmarks. The only \
setting that holds in every game is this: the wonder {setting}. Give the \
setting in at most one short clause, in those terms, for atmosphere.\
"""

NATURAL_CONTEXT = """\
This is the discovery movie that Sid Meier's Civilization VI plays when a \
player first finds the natural wonder {name}, a real place. The game draws \
the wonder as a landmark on one or a few map tiles, modeled on the real \
landscape, and the view flies over and around it. The movie opens with the \
game's reveal effect, a burst of light rays that fades away. Every natural \
wonder movie has it, so do not mention it at all. Start the paragraph on the \
landscape. The wonder's own tiles are the same in every game and are the \
heart of the description: name its recognizable real features where the \
video shows them, and give the rock, water, ice, vegetation, color and light \
on them.

The land beyond those tiles is one particular player's map and differs in \
every game, and this recording is one such map. Do not describe its \
particular hills, forests, rivers, coastlines, units, roads or cities. The \
only setting that holds in every game is this: the wonder {setting}. Give \
the setting in at most one short clause, in those terms, for atmosphere.\
"""


def probe_size_mb(path):
    return Path(path).stat().st_size / (1024 * 1024)


def shrink(path):
    """Re-encode below the inline size cap, returning a temp file path."""
    fd, tmp = tempfile.mkstemp(suffix=".mp4")
    os.close(fd)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(path), "-an",
                    "-vf", "scale=-2:720", "-c:v", "libx264", "-preset", "fast",
                    "-crf", "26", "-pix_fmt", "yuv420p", tmp], check=True)
    return tmp


def to_data_url(path):
    encoded = base64.b64encode(Path(path).read_bytes()).decode("ascii")
    return "data:video/mp4;base64," + encoded


def build_user_text(kind, name, setting):
    ctx = (WORLD_CONTEXT if kind == "world" else NATURAL_CONTEXT).format(name=name, setting=setting)
    return ("Watch the attached video and write its description.\n\nCONTEXT\n"
            + ctx + "\n\nReply with the JSON object described in your instructions.")


def extract_json(text):
    text = text.strip()
    m = re.search(r"\{.*\}", text, re.S)
    if not m:
        sys.exit("error: no JSON object in reply:\n" + text[:800])
    return json.loads(m.group(0))


def call(messages, model, effort, retries=4, timeout=1800):
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        sys.exit("error: OPENROUTER_API_KEY is not set in the environment.")
    body = {
        "model": model,
        "messages": messages,
        "max_tokens": 8000,
        "temperature": 0.5,
        "usage": {"include": True},
        "provider": {"only": [PROVIDER], "allow_fallbacks": False},
        "response_format": {"type": "json_object"},
    }
    if effort != "none":
        body["reasoning"] = {"effort": effort}
    headers = {"Authorization": "Bearer " + api_key,
               "Content-Type": "application/json",
               "X-Title": "CAI Wonder Movie Describer"}
    delay, last = 5, None
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(API_URL, data=json.dumps(body).encode("utf-8"),
                                     headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            text = exc.read().decode("utf-8", "replace")[:600]
            if exc.code not in (408, 429, 500, 502, 503, 504):
                sys.exit("error: OpenRouter returned {}:\n{}".format(exc.code, text))
            last = "HTTP {}: {}".format(exc.code, text[:300])
        except (urllib.error.URLError, OSError) as exc:
            last = str(exc)
        else:
            if "error" in data and not data.get("choices"):
                sys.exit("error: " + json.dumps(data["error"])[:600])
            return (data["choices"][0]["message"]["content"],
                    data.get("usage") or {})
        if attempt < retries:
            print("  request failed ({}), retrying in {}s".format(last, delay), flush=True)
            time.sleep(delay)
            delay = min(delay * 2, 60)
    sys.exit("error: giving up after {} attempts. Last failure: {}".format(retries, last))


def describe(key, kind, name, setting, model, effort):
    clip = VIDEOS / kind / (key + ".mp4")
    if not clip.exists():
        sys.exit("error: missing clip {}".format(clip))
    send, tmp = clip, None
    if probe_size_mb(clip) > SIZE_CAP_MB:
        tmp = send = shrink(clip)
        print("  re-encoded to {:.1f} MB for upload".format(probe_size_mb(send)), flush=True)
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": [
            {"type": "video_url", "video_url": {"url": to_data_url(send)}},
            {"type": "text", "text": build_user_text(kind, name, setting)},
        ]},
    ]
    try:
        for attempt in range(3):
            text, usage = call(messages, model, effort)
            if text and text.strip():
                break
            # Vertex occasionally returns a message with no content (the
            # reply was all reasoning, or it was filtered). Ask again.
            print("  empty reply, asking again", flush=True)
        else:
            sys.exit("error: {} got three empty replies".format(key))
    finally:
        if tmp:
            os.unlink(tmp)
    reply = extract_json(text)
    return {"key": key, "kind": kind, "name": name,
            "description": reply.get("description", "").strip(),
            "seen": reply.get("seen", []),
            "model": model, "usage": usage}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("keys", nargs="*", help="wonder keys, e.g. BUILDING_PETRA")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--kind", choices=["world", "natural"])
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--effort", default="high", help="reasoning effort or none")
    ap.add_argument("--force", action="store_true", help="redo existing descriptions")
    ap.add_argument("--dry-run", action="store_true", help="print the prompt, send nothing")
    args = ap.parse_args()

    manifest = json.load(open(MANIFEST, encoding="utf-8"))["clips"]
    items = []
    for kind in ("world", "natural"):
        if args.kind and args.kind != kind:
            continue
        for key, clip in manifest[kind].items():
            if args.all or key in args.keys:
                items.append((key, kind, clip["name"], clip["setting"]))
    unknown = set(args.keys) - {k for k, _, _, _ in items}
    if unknown:
        sys.exit("error: unknown keys: " + ", ".join(sorted(unknown)))
    if not items:
        sys.exit("nothing to do; pass keys or --all")

    OUT.mkdir(parents=True, exist_ok=True)
    for key, kind, name, setting in items:
        dst = OUT / (key + ".json")
        if dst.exists() and not args.force:
            print("{}: already described, skipping".format(key))
            continue
        print("{} ({}): {}".format(key, kind, name), flush=True)
        if args.dry_run:
            print(SYSTEM_PROMPT, "\n---\n", build_user_text(kind, name, setting))
            continue
        result = describe(key, kind, name, setting, args.model, args.effort)
        dst.write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n",
                       encoding="utf-8")
        print("\n" + result["description"] + "\n")
        print("  seen: " + " | ".join(result["seen"]))
        u = result["usage"]
        print("  tokens in {} out {} cost {}".format(
            u.get("prompt_tokens"), u.get("completion_tokens"), u.get("cost")))


if __name__ == "__main__":
    main()
