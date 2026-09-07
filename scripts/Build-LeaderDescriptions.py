#!/usr/bin/env python3
"""Regenerate src/Text/en_US/LeaderDescStrings_CAI.xml from the authoring
source docs/leader-descriptions.md.

Usage: Build-LeaderDescriptions.py [--check]

Each entry in the doc is a "## N. LEADER_TYPE" heading, a display-name line, a
blank line, the description on one line, a blank line, and a "Sources:" note.
The description becomes <Row Tag="LOC_CAI_LEADERDESC_LEADER_TYPE">. With
--check the script only reports whether the XML is up to date and exits 1 if
it is not.
"""
import html
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "docs", "leader-descriptions.md")
XML = os.path.join(ROOT, "src", "Text", "en_US", "LeaderDescStrings_CAI.xml")


def entries():
    text = open(DOC, encoding="utf-8").read()
    found = re.findall(r"^## \d+\. (LEADER_[A-Z0-9_]+)\n.+?\n\n(.+?)\n", text, re.M)
    keys = [k for k, _ in found]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        sys.exit(f"duplicate keys in doc: {sorted(dupes)}")
    return found


def rows(found):
    return "\n".join(
        f'    <Row Tag="LOC_CAI_LEADERDESC_{k}" Language="en_US">\n'
        f"      <Text>{html.escape(d, quote=False)}</Text>\n"
        f"    </Row>"
        for k, d in found
    )


def main():
    found = entries()
    current = open(XML, encoding="utf-8").read()
    new = re.sub(r"    <Row Tag=.*</Row>\n", lambda m: rows(found) + "\n", current,
                 flags=re.S)
    if "--check" in sys.argv:
        if new == current:
            print(f"{len(found)} entries, XML up to date")
            return
        sys.exit("XML is out of date; run Build-LeaderDescriptions.py")
    open(XML, "w", encoding="utf-8").write(new)
    print(f"wrote {len(found)} entries to {os.path.relpath(XML, ROOT)}")


if __name__ == "__main__":
    main()
