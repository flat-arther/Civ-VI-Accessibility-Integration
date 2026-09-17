#!/usr/bin/env python3
"""Lint leader descriptions against docs/leader-descriptions.md rules.

Usage: Lint-LeaderDescriptions.py <LeaderDescStrings_CAI.xml or leader-descriptions.md>

Reads either the built XML (any language) or the authoring markdown. Checks
sentence completeness, punctuation, banned words, hedges, comparisons,
spelling, and length guides.
"""
import re
import sys

BANNED_WORDS = {"masterpiece", "stunning", "beautiful", "gorgeous", "breathtaking",
                "iconic"}
HEDGES = ("almost", "nearly", "seems", "seem", "appears", "appear", "as though", "as if",
          "possibly", "probably", "likely", "reads as", "suggests", "apparently")
FRAMING = ("in conversation", "when he denounces", "when she denounces", "when defeated",
           "when denouncing")
COMPARISONS = ("like a", "like an", "resembl")
BRITISH = ("colour", "grey", "centre", "theatre", "armour", "storey", "harbour",
           "jewelled", "travell", "labour", "moustache")
MIN_WORDS, MAX_WORDS, MAX_SENT_WORDS = 120, 320, 38
VERB = re.compile(r"\b(is|are|has|have|hang|wait|stand|sit|lie|rise|fall|hold|look|"
                  r"meet|float|drift|press|crowd|gather|ride|wear|spread|reach|frame|"
                  r"cross|fill|glow|run|lean|rest|carry|[a-z]+s|[a-z]+ed)\b")


def sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+", text.strip()) if s]


def lint_one(text):
    issues, warnings = [], []
    if not text.endswith("."):
        issues.append("does not end with a period")
    bad = sorted(set(re.findall(r"[^\x20-\x7E\w]", text)))
    if bad:
        issues.append(f"non-ASCII punctuation {bad}")
    for ch, name in (("(", "parenthesis"), ("/", "slash"),
                     ("...", "ellipsis"), (" - ", "dash"), ("--", "double dash")):
        if ch in text:
            issues.append(f"contains {name}")
    if ";" in text:
        warnings.append(f"semicolon, check it sets two parallel clauses side by side: {text[text.index(';')-40:text.index(';')+40]}")
    if text.count(":") > 1:
        issues.append("more than one colon")
    sents = sentences(text)
    words = len(text.split())
    if words < MIN_WORDS:
        issues.append(f"{words} words, under {MIN_WORDS}")
    for i, s in enumerate(sents):
        if i > 0 and s.count(",") > 3:
            issues.append(f"sentence with {s.count(',')} commas: {s[:50]}")
        if len(s.split()) > MAX_SENT_WORDS:
            warnings.append(f"sentence of {len(s.split())} words: {s[:50]}")
        if not VERB.search(s):
            issues.append(f"possible fragment: {s[:50]}")
        for h in HEDGES:
            if re.search(rf"\b{h}\b", s.lower()):
                warnings.append(f"hedge '{h}': {s[:50]}")
        for f in FRAMING:
            if f in s.lower():
                warnings.append(f"animation framing '{f}': {s[:50]}")
    for a, b in zip(sents, sents[1:]):
        if re.search(r", and ", a) and re.search(r", and ", b) and a.count(",") == 1 and b.count(",") == 1:
            warnings.append(f"two 'X, and Y' sentences in a row: {a[:40]}")
    low = text.lower()
    if re.search(r"\byou\b|\byour\b|\bviewer\b", low):
        issues.append("second person or viewer")
    comps = sum(low.count(c) for c in COMPARISONS)
    if comps > 1:
        issues.append(f"{comps} comparisons")
    for w in BANNED_WORDS:
        if re.search(rf"\b{w}\b", low):
            issues.append(f"banned word {w}")
    if re.search(r"\bmagnificent\b", low) and "the magnificent" not in low:
        issues.append("banned word magnificent")
    for w in BRITISH:
        if w in low:
            issues.append(f"British spelling {w}")
    if re.search(r"\b(?![IVX]+\b)[A-Z]{3,}\b", text):
        issues.append("all-caps word")
    if re.search(r"\b[0-9]\b", text):
        issues.append("single-digit numeral")
    if words > MAX_WORDS:
        warnings.append(f"{words} words, over the {MAX_WORDS} word guide")
    return issues, warnings


def load(path):
    text = open(path, encoding="utf-8").read()
    if path.endswith(".md"):
        return re.findall(r"^## \d+\. (LEADER_[A-Z0-9_]+)\n.+?\n\n(.+?)\n", text, re.M)
    rows = re.findall(r'Tag="LOC_CAI_LEADERDESC_(LEADER_[A-Z0-9_]+)"[^>]*>\s*<Text>(.*?)</Text>',
                      text, re.S)
    return [(k, t.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")) for k, t in rows]


def main():
    rows = load(sys.argv[1])
    total = 0
    for key, text in rows:
        issues, warnings = lint_one(text)
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
