#!/usr/bin/env python3
"""Lint great work descriptions against docs/great-work-descriptions.md rules.

Usage: Lint-GreatWorkDescriptions.py <GreatworkDescStrings_CAI.xml or great-work-descriptions.md> [names.tsv]

Reads either the built XML (any language) or the authoring markdown. Checks
sentence completeness, punctuation, banned words, hedges, comparisons,
spelling, and length guides.

names.tsv: optional, lines of "<KEY>\t<title>\t<artist>" used for the
no-title / no-artist repetition check (English only).
"""
import re
import sys

BANNED_WORDS = {
    "masterpiece", "stunning", "beautiful", "gorgeous", "breathtaking",
    "iconic", "byzantine",
}
HEDGES = ("almost", "seems", "seem", "as though", "as if", "like a", "like an")
COMPARISONS = ("as if", "as though", "like a", "like an", "resembl")
BRITISH = ("colour", "grey", "centre", "theatre", "armour", "storey",
           "harbour", "jewelled", "travell", "labour")
MAX_SENT, MIN_WORDS, MAX_WORDS = 4, 40, 85


def sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+", text.strip()) if s]


def lint_one(key, text, title=None, artist=None):
    issues = []
    if not text.endswith("."):
        issues.append("does not end with a period")
    if re.search(r"[^\x20-\x7E]", text):
        bad = sorted(set(re.findall(r"[^\x20-\x7E]", text)))
        issues.append(f"non-ASCII characters {bad}")
    for ch, name in ((";", "semicolon"), ("(", "parenthesis"), ("/", "slash"),
                     ("...", "ellipsis"), (" - ", "dash"), ("--", "double dash")):
        if ch in text:
            issues.append(f"contains {name}")
    if text.count(":") > 1:
        issues.append("more than one colon")
    short = key.startswith(("ARTIFACT_", "GREATWORK_RELIC_", "GREATWORKOBJECT_",
                            "GREATWORK_HERO_", "VOIDSINGER_", "PRODUCT_"))
    sents = sentences(text)
    if len(sents) > (3 if short else MAX_SENT):
        issues.append(f"{len(sents)} sentences")
    words = len(text.split())
    if words < (10 if short else MIN_WORDS):
        issues.append(f"{words} words")
    for s in sents:
        if s.count(",") > 3:
            issues.append(f"sentence with {s.count(',')} commas: {s[:50]}")
        if not re.search(r"\b(is|are|has|have|hang|wait|stand|sit|lie|rise|"
                         r"fall|hold|look|meet|float|drift|press|crowd|gather|"
                         r"ride|wear|spread|reach|frame|cross|fill|glow|run|"
                         r"[a-z]+s|[a-z]+ed)\b", s):
            issues.append(f"possible fragment: {s[:50]}")
        hedges = {h.split()[0][:4] for h in HEDGES if h in s.lower()}
        if len(hedges) > 1:
            issues.append(f"stacked hedges {hedges}: {s[:50]}")
    low = text.lower()
    if re.match(r"(this|it|here) (is|are)\b", low):
        issues.append("opens with a bare This is or It is")
    if short:
        if re.match(r"(this|these) ", low):
            issues.append("simple object should open with the object itself")
        if "the same for every" in low or "like every" in low:
            issues.append("mentions that the image is shared")
    elif re.match(r"the [a-z-]+ (is|are|belongs|shows|covers)\b", low):
        issues.append("opener should point with This or These")
    if re.search(r"\byou\b|\byour\b|\bviewer\b", low):
        issues.append("second person or viewer")
    comps = sum(low.count(c) for c in COMPARISONS)
    if comps > 1:
        issues.append(f"{comps} comparisons")
    for w in BANNED_WORDS:
        if re.search(rf"\b{w}\b", low):
            issues.append(f"banned word {w}")
    for w in BRITISH:
        if w in low:
            issues.append(f"British spelling {w}")
    if re.search(r"\b(?![IVX]+\b)[A-Z]{3,}\b", text):
        issues.append("all-caps word")
    if re.search(r"\b[0-9]\b", text):
        issues.append("single-digit numeral")
    warnings = []
    if words > MAX_WORDS:
        warnings.append(f"{words} words, over the {MAX_WORDS} word guide")
    return issues, warnings


def load(path):
    text = open(path, encoding="utf-8").read()
    if path.endswith(".md"):
        return re.findall(r"^## \d+\. ([A-Z0-9_]+)\n.+?\n\n(.+?)\n", text, re.M)
    rows = re.findall(r'Tag="LOC_CAI_GWDESC_([A-Z0-9_]+)"[^>]*>\s*<Text>(.*?)</Text>',
                      text, re.S)
    return [(k, t.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")) for k, t in rows]


def main():
    path = sys.argv[1]
    names = {}
    if len(sys.argv) > 2:
        for line in open(sys.argv[2], encoding="utf-8"):
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 3:
                names[parts[0]] = (parts[1], parts[2])
    rows = load(path)
    total = 0
    for key, text in rows:
        title, artist = names.get(key, (None, None))
        issues, warnings = lint_one(key, text, title, artist)
        if issues or warnings:
            total += len(issues)
            print(key)
            for i in issues:
                print("    error:", i)
            for w in warnings:
                print("    warning:", w)
    print(f"{len(rows)} entries, {total} issues")
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
