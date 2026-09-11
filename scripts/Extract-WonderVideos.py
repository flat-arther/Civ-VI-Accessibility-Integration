#!/usr/bin/env python3
"""Fetch the world wonder and natural wonder movies as one silent clip per
wonder, named by the game's BuildingType / FeatureType.

Usage: Extract-WonderVideos.py [--out DIR] [--cache DIR] [--only world|natural]
                               [--keys KEY,KEY,...] [--force]

Civilization VI does not ship these movies as video files. Both kinds are
rendered by the engine at runtime (a construction time-lapse model plus a
camera curve for world wonders, a camera flyover of the actual map tiles for
natural wonders), so the footage comes from public gameplay recordings on
YouTube instead. scripts/wonder-video-sources.json lists the source videos and
the verified time range of every wonder inside them; the ranges were checked
by reading the popup title of every sampled frame with OCR.

Needs yt-dlp and ffmpeg on PATH. Output: <out>/world/<BUILDING_KEY>.mp4 and
<out>/natural/<FEATURE_KEY>.mp4, H.264, 1080p, 30 fps, no audio. Source
downloads are kept in <cache> so a rerun only re-cuts.
"""
import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wonder-video-sources.json")
YTDLP_FORMAT = "bv*[height<=1080][ext=mp4]/bv*[height<=1080]"


def run(cmd):
    print("  $", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True)


def download(video_id, cache):
    path = os.path.join(cache, f"{video_id}.mp4")
    if os.path.exists(path):
        return path
    os.makedirs(cache, exist_ok=True)
    run(["yt-dlp", "-f", YTDLP_FORMAT, "--no-progress", "--remux-video", "mp4",
         "-o", os.path.join(cache, f"{video_id}.%(ext)s"), "--", video_id])
    if not os.path.exists(path):
        sys.exit(f"download of {video_id} did not produce {path}")
    return path


def cut(src, dst, start, end):
    cmd = ["ffmpeg", "-v", "error", "-y"]
    if start is not None:
        cmd += ["-ss", f"{start:.3f}"]
    if end is not None:
        cmd += ["-to", f"{end:.3f}"]
    cmd += ["-i", src, "-an", "-vf", "fps=30,scale=-2:1080", "-c:v", "libx264",
            "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", dst]
    run(cmd)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "wonder-videos"))
    ap.add_argument("--cache", default=None, help="default <out>/.sources")
    ap.add_argument("--only", choices=["world", "natural"])
    ap.add_argument("--keys", help="comma separated wonder keys to (re)build")
    ap.add_argument("--force", action="store_true", help="overwrite existing clips")
    args = ap.parse_args()
    cache = args.cache or os.path.join(args.out, ".sources")
    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    wanted = set(args.keys.split(",")) if args.keys else None

    done = skipped = 0
    for kind in ("world", "natural"):
        if args.only and args.only != kind:
            continue
        outdir = os.path.join(args.out, kind)
        os.makedirs(outdir, exist_ok=True)
        for key, clip in manifest["clips"][kind].items():
            if wanted and key not in wanted:
                continue
            dst = os.path.join(outdir, f"{key}.mp4")
            if os.path.exists(dst) and not args.force:
                skipped += 1
                continue
            print(f"{kind}/{key}: {clip['name']}", flush=True)
            src = download(clip["youtube"], cache)
            cut(src, dst, clip.get("start"), clip.get("end"))
            done += 1
    print(f"{done} clips written, {skipped} already present")


if __name__ == "__main__":
    main()
