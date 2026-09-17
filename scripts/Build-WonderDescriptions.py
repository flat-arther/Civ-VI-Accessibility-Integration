#!/usr/bin/env python3
"""Keep the wonder movie descriptions in sync: JSON -> document -> XML.

Usage: Build-WonderDescriptions.py [--from-json] [--check]

docs/wonder-descriptions.md is the authoring source, in the same shape as
docs/great-work-descriptions.md: a "## N. KEY" heading, the wonder's name, a
blank line, the paragraph, a blank line, and a "Seen:" note. By default the
script regenerates src/Text/en_US/WonderDescStrings_CAI.xml from the document
(one <Row Tag="LOC_CAI_WONDERDESC_KEY">, KEY being the game's BuildingType or
FeatureType). The other languages are translated from the final English and
must keep the same tag set.

--from-json rebuilds the document from the per-wonder JSON files that
Describe-WonderVideos.py writes under wonder-videos/descriptions/, which
overwrites any hand edits, so use it only after redoing a description. --check
reports whether the XML matches the document and exits 1 if it does not.
"""
import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "scripts", "wonder-video-sources.json")
SRC = os.path.join(ROOT, "wonder-videos", "descriptions")
DOC = os.path.join(ROOT, "docs", "wonder-descriptions.md")
XML = os.path.join(ROOT, "src", "Text", "en_US", "WonderDescStrings_CAI.xml")

HEADER = """\
# Wonder movies - spoken descriptions

Authoring source for the paragraph CAI reads on demand for a world wonder or
natural wonder movie, the way the Great Work Showcase reads an image
description. One static paragraph per wonder, keyed by the game's
`BuildingType` or `FeatureType`; the wonder popups speak it on F2. The game
speaks the wonder's name first and the Civilopedia carries the history, so the
paragraph is about the picture: what the movie shows, in order, with the real
place's features named.

Edit the paragraphs here, then run `scripts/Build-WonderDescriptions.py` to
regenerate `src/Text/en_US/WonderDescStrings_CAI.xml` (`--check` verifies it
is up to date); the other language files are translated from the final
English. The entries were first written by `scripts/Describe-WonderVideos.py`
(Gemini 3.1 Pro over the clips cut by `scripts/Extract-WonderVideos.py`) and
`--from-json` rebuilds the document from those files. The "Seen" line is the
model's own list of what it noticed, kept as a review aid. The movies are
engine-rendered and the land around a wonder belongs to the player's map, so
each prompt limited the setting to what the game's placement rules guarantee;
see the `setting` field in `scripts/wonder-video-sources.json`.

"""

XML_HEAD = """\
<?xml version="1.0" encoding="utf-8"?>
<GameData>
  <LocalizedText>
    <!-- ENGLISH -->
    <!-- Wonder movie accessibility descriptions (CAI). Spoken on F2 from the wonder built and
         natural wonder discovered popups. Keys: LOC_CAI_WONDERDESC_<BuildingType> for world
         wonders and LOC_CAI_WONDERDESC_<FeatureType> for natural wonders.
         Authoring source and rules: docs/wonder-descriptions.md. Edit there first, then run
         scripts/Build-WonderDescriptions.py to regenerate this file. -->
"""
XML_TAIL = """\
  </LocalizedText>
</GameData>
"""


def build_doc():
    manifest = json.load(open(MANIFEST, encoding="utf-8"))["clips"]
    parts = [HEADER]
    n = 0
    for kind, title in (("world", "World wonders"), ("natural", "Natural wonders")):
        parts.append("## {}\n\n".format(title))
        for key, clip in manifest[kind].items():
            path = os.path.join(SRC, key + ".json")
            n += 1
            if not os.path.exists(path):
                parts.append("## {}. {}\n{}\n\n(not described yet)\n\n".format(n, key, clip["name"]))
                continue
            d = json.load(open(path, encoding="utf-8"))
            parts.append("## {}. {}\n{}\n\n{}\n\nSeen: {}\n\n".format(
                n, key, clip["name"], d["description"].strip(),
                "; ".join(d.get("seen", [])) or "none listed"))
    return "".join(parts).rstrip("\n") + "\n"


def entries():
    text = open(DOC, encoding="utf-8").read()
    found = re.findall(r"^## \d+\. ([A-Z0-9_]+)\n.+?\n\n(.+?)\n", text, re.M)
    keys = [k for k, _ in found]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        sys.exit("duplicate keys in doc: {}".format(sorted(dupes)))
    return [(k, d) for k, d in found if d != "(not described yet)"]


def build_xml(found):
    rows = "\n".join(
        '    <Row Tag="LOC_CAI_WONDERDESC_{}" Language="en_US">\n'
        "      <Text>{}</Text>\n"
        "    </Row>".format(k, html.escape(d, quote=False))
        for k, d in found)
    return XML_HEAD + rows + "\n" + XML_TAIL


def main():
    if "--from-json" in sys.argv:
        doc = build_doc()
        open(DOC, "w", encoding="utf-8").write(doc)
        print("wrote {}{}".format(DOC, ", {} wonders still undescribed".format(
            doc.count("(not described yet)")) if "(not described yet)" in doc else ""))
    found = entries()
    new = build_xml(found)
    current = open(XML, encoding="utf-8").read() if os.path.exists(XML) else ""
    if "--check" in sys.argv:
        if new == current:
            print("{} entries, XML up to date".format(len(found)))
            return
        sys.exit("XML is out of date; run Build-WonderDescriptions.py")
    open(XML, "w", encoding="utf-8").write(new)
    print("{} entries written to {}".format(len(found), XML))


if __name__ == "__main__":
    main()
