#!/usr/bin/env python3
"""Verify a translated CAI language folder against en_US.

Usage:
    python .claude/skills/localize-language/scripts/verify_language.py <lang>

Run from the repository root. <lang> is a Civ VI locale code, e.g. fr_FR.

Checks, for the given language:
  - XML well-formedness of the four translated XML files and the modinfo.
  - Tag parity: each translated XML has exactly the same Tag set as its en_US
    counterpart (no missing, no extra).
  - No leftover Language="en_US" in a translated file.
  - Even single-quote parity on every SQL line (apostrophes doubled).
  - All five content files registered in the three modinfo <File> blocks, with
    tutorial_advisor_text_CAI.sql correctly omitted from the FrontEnd block.

Exits 0 if everything passes, 1 otherwise.
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

XML_FILES = [
    "cai_text_ui.xml",
    "AccessibilityPediaText_CAI.xml",
    "TutorialText_CAI.xml",
]
SQL_FILES = [
    "hotkey_symbol_names.sql",
    "tutorial_advisor_text_CAI.sql",
]
MODINFO = Path("src/CivViAccess.modinfo")
TAG_RE = re.compile(r'Tag="([^"]+)"')


def tags(path: Path):
    return sorted(TAG_RE.findall(path.read_text(encoding="utf-8")))


def check_xml_wellformed(path: Path, problems: list) -> None:
    try:
        ET.parse(path)
    except ET.ParseError as exc:
        problems.append(f"{path}: XML parse error: {exc}")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: verify_language.py <lang>  (run from repo root)")
        return 2
    lang = sys.argv[1]
    en = Path("src/Text/en_US")
    tr = Path("src/Text") / lang
    problems: list[str] = []

    if not tr.is_dir():
        print(f"error: {tr} does not exist")
        return 1

    # Every content file plus modinfo_CAI.xml should be present.
    for name in XML_FILES + SQL_FILES + ["modinfo_CAI.xml"]:
        if not (tr / name).is_file():
            problems.append(f"missing file: {tr / name}")

    # XML well-formedness (translated files + the modinfo).
    check_xml_wellformed(MODINFO, problems)
    for name in XML_FILES + ["modinfo_CAI.xml"]:
        p = tr / name
        if p.is_file():
            check_xml_wellformed(p, problems)

    # Tag parity and no en_US leftovers in the three big translated XML files.
    for name in XML_FILES:
        src, dst = en / name, tr / name
        if not (src.is_file() and dst.is_file()):
            continue
        s, d = tags(src), tags(dst)
        missing = sorted(set(s) - set(d))
        extra = sorted(set(d) - set(s))
        if missing:
            problems.append(
                f"{dst}: {len(missing)} tag(s) missing vs en_US, "
                f"e.g. {missing[:5]}"
            )
        if extra:
            problems.append(
                f"{dst}: {len(extra)} tag(s) not in en_US, e.g. {extra[:5]}"
            )
        text = dst.read_text(encoding="utf-8")
        n_en = text.count('Language="en_US"')
        if n_en:
            problems.append(f'{dst}: {n_en} leftover Language="en_US"')

    # SQL apostrophe parity: every non-blank line should have an even count of '.
    for name in SQL_FILES:
        p = tr / name
        if not p.is_file():
            continue
        for i, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            if line.count("'") % 2 != 0:
                problems.append(
                    f"{p}:{i}: odd number of single quotes "
                    f"(unescaped apostrophe?)"
                )

    # modinfo registration across the three blocks.
    if MODINFO.is_file():
        mtext = MODINFO.read_text(encoding="utf-8")

        def registered(fname: str) -> int:
            return mtext.count(f"Text/{lang}/{fname}")

        # Expected total <File> occurrences across the three blocks.
        expected = {
            "cai_text_ui.xml": 3,
            "AccessibilityPediaText_CAI.xml": 3,
            "TutorialText_CAI.xml": 3,
            "hotkey_symbol_names.sql": 3,
            "tutorial_advisor_text_CAI.sql": 2,  # omitted from FrontEnd block
        }
        for fname, exp in expected.items():
            got = registered(fname)
            if got != exp:
                problems.append(
                    f"modinfo: Text/{lang}/{fname} registered {got} time(s), "
                    f"expected {exp}"
                )
        if registered("modinfo_CAI.xml") < 3:
            problems.append(
                f"modinfo: Text/{lang}/modinfo_CAI.xml should appear in all "
                f"three blocks"
            )

    if problems:
        print(f"FAIL ({len(problems)} problem(s)) for {lang}:")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"OK: {lang} passes all checks.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
