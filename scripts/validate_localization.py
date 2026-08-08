from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET


TARGET_LANGUAGE = "zh_Hans_CN"
NUMBER_RE = re.compile(r"(?<![A-Za-z_])-?\d+(?:\.\d+)?%?")
SQL_UPDATE_RE = re.compile(
    r"""
    UPDATE\s+LocalizedText\s+SET\s+Text\s*=\s*'(?P<text>(?:''|[^'])*)'
    \s+WHERE\s+Tag\s*=\s*'(?P<tag>(?:''|[^'])*)'
    \s+AND\s+Language\s*=\s*'(?P<language>(?:''|[^'])*)'\s*;
    """,
    re.IGNORECASE | re.DOTALL | re.VERBOSE,
)
SCRIPT_DIR = Path(__file__).resolve().parent
OFFICIAL_EXACT_TAGS_PATH = SCRIPT_DIR / "localization_official_exact_tags.txt"
ENGLISH_ALLOWLIST_PATH = SCRIPT_DIR / "localization_english_allowlist.txt"
USER_FACING_PATTERNS = (
    re.compile(r'\bSpeak(?:Lines)?\(\s*"(?P<text>[^"\r\n]+)"'),
    re.compile(r"\bSpeak(?:Lines)?\(\s*'(?P<text>[^'\r\n]+)'"),
    re.compile(
        r'\bSet(?:Text|ToolTipString|Tooltip|Label)\(\s*"(?P<text>[^"\r\n]+)"'
    ),
    re.compile(
        r"\bSet(?:Text|ToolTipString|Tooltip|Label)\(\s*'(?P<text>[^'\r\n]+)'"
    ),
)


@dataclass(frozen=True)
class Entry:
    tag: str
    language: str
    text: str


def _balanced_brace_end(text: str, start: int) -> int | None:
    depth = 0
    for index in range(start, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return index + 1
    return None


def _top_level_colon(text: str) -> int | None:
    depth = 0
    for index, character in enumerate(text):
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
        elif character == ":" and depth == 0:
            return index
    return None


def _choice_selectors(text: str) -> list[str]:
    selectors: list[str] = []
    depth = 0
    start = 0
    for index, character in enumerate(text):
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
        elif character == "?" and depth == 0:
            selectors.append(text[start:index].strip())
        elif character == ";" and depth == 0:
            start = index + 1
    return selectors


def _format_tokens(raw: str) -> list[str]:
    inner = raw[1:-1]
    colon = _top_level_colon(inner)
    if colon is None:
        return [raw]
    parameter = inner[:colon].strip()
    remainder = inner[colon + 1 :].lstrip()
    match = re.match(r"(?P<kind>[A-Za-z_]+)\b(?P<body>.*)", remainder, re.DOTALL)
    if match is None or match.group("kind") not in {"plural", "gender"}:
        return [raw]
    kind = match.group("kind")
    body = match.group("body").lstrip()
    signature = f"{{{parameter}:{kind}:{'|'.join(_choice_selectors(body))}}}"
    return [signature, *_scan_tokens(body)]


def _scan_tokens(text: str) -> list[str]:
    tokens: list[str] = []
    index = 0
    while index < len(text):
        if text[index] == "[":
            end = text.find("]", index + 1)
            if end != -1:
                tokens.append(text[index : end + 1])
                index = end + 1
                continue
        if text[index] == "{":
            end = _balanced_brace_end(text, index)
            if end is not None:
                tokens.extend(_format_tokens(text[index:end]))
                index = end
                continue
        number = NUMBER_RE.match(text, index)
        if number is not None:
            tokens.append(number.group(0))
            index = number.end()
            continue
        index += 1
    return tokens


def _visible_prose(text: str) -> str:
    """Return text excluding localization markup and substitution parameters."""
    visible: list[str] = []
    index = 0
    while index < len(text):
        if text[index] == "[":
            end = text.find("]", index + 1)
            if end != -1:
                index = end + 1
                continue
        if text[index] == "{":
            end = _balanced_brace_end(text, index)
            if end is not None:
                index = end
                continue
        visible.append(text[index])
        index += 1
    return "".join(visible)


def extract_tokens(text: str) -> Counter[str]:
    """Return formatting structure, parameters, icons, and numbers as a multiset."""
    return Counter(_scan_tokens(text or ""))


def parse_xml_entries(path: Path) -> tuple[list[Entry], list[str]]:
    """Parse mod localization rows and report duplicate or malformed data."""
    errors: list[str] = []
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        return [], [f"{path}: malformed XML: {exc}"]

    rows = root.findall("./LocalizedText/Row")
    entries = [
        Entry(
            row.get("Tag", ""),
            row.get("Language", ""),
            row.findtext("Text", default=""),
        )
        for row in rows
    ]
    seen: set[str] = set()
    for entry in entries:
        if entry.tag in seen:
            errors.append(f"{path}: duplicate tag {entry.tag}")
        seen.add(entry.tag)
    return entries, sorted(errors)


def validate_xml_pair(english: Path, chinese: Path) -> list[str]:
    """Validate one English/Chinese XML localization file pair."""
    en_entries, errors = parse_xml_entries(english)
    zh_entries, zh_errors = parse_xml_entries(chinese)
    errors.extend(zh_errors)
    en_by_tag = {entry.tag: entry for entry in en_entries}
    zh_by_tag = {entry.tag: entry for entry in zh_entries}

    for tag in en_by_tag.keys() - zh_by_tag.keys():
        errors.append(f"{chinese}: missing tag {tag}")
    for tag in zh_by_tag.keys() - en_by_tag.keys():
        errors.append(f"{chinese}: extra tag {tag}")
    if [entry.tag for entry in en_entries] != [entry.tag for entry in zh_entries]:
        errors.append(f"{chinese}: tag order differs from English")

    for tag in en_by_tag.keys() & zh_by_tag.keys():
        en_entry = en_by_tag[tag]
        zh_entry = zh_by_tag[tag]
        if zh_entry.language != TARGET_LANGUAGE:
            errors.append(f"{chinese}: {tag}: expected language {TARGET_LANGUAGE}")
        if not zh_entry.text.strip():
            errors.append(f"{chinese}: {tag}: empty translation")
        if extract_tokens(en_entry.text) != extract_tokens(zh_entry.text):
            errors.append(f"{chinese}: {tag}: token mismatch")
    return sorted(errors)


def _unescape_sql(value: str) -> str:
    return value.replace("''", "'")


def parse_sql_updates(path: Path) -> list[Entry]:
    """Parse the restricted LocalizedText UPDATE syntax used by the mod."""
    source = path.read_text(encoding="utf-8-sig")
    matches = list(SQL_UPDATE_RE.finditer(source))
    remainder_parts: list[str] = []
    cursor = 0
    for match in matches:
        remainder_parts.append(source[cursor : match.start()])
        cursor = match.end()
    remainder_parts.append(source[cursor:])
    remainder = "".join(remainder_parts)
    remainder = re.sub(r"(?m)^\s*--.*$", "", remainder).strip()
    if remainder:
        preview = " ".join(remainder.split())[:120]
        raise ValueError(f"{path}: unrecognized SQL: {preview}")
    return [
        Entry(
            _unescape_sql(match.group("tag")),
            _unescape_sql(match.group("language")),
            _unescape_sql(match.group("text")),
        )
        for match in matches
    ]


def _duplicate_tag_errors(path: Path, entries: list[Entry]) -> list[str]:
    seen: set[str] = set()
    errors: list[str] = []
    for entry in entries:
        if entry.tag in seen:
            errors.append(f"{path}: duplicate tag {entry.tag}")
        seen.add(entry.tag)
    return errors


def _validate_entries(
    english: Path,
    chinese: Path,
    en_entries: list[Entry],
    zh_entries: list[Entry],
) -> list[str]:
    errors = _duplicate_tag_errors(english, en_entries)
    errors.extend(_duplicate_tag_errors(chinese, zh_entries))
    en_by_tag = {entry.tag: entry for entry in en_entries}
    zh_by_tag = {entry.tag: entry for entry in zh_entries}
    for tag in en_by_tag.keys() - zh_by_tag.keys():
        errors.append(f"{chinese}: missing tag {tag}")
    for tag in zh_by_tag.keys() - en_by_tag.keys():
        errors.append(f"{chinese}: extra tag {tag}")
    if [entry.tag for entry in en_entries] != [entry.tag for entry in zh_entries]:
        errors.append(f"{chinese}: tag order differs from English")
    for tag in en_by_tag.keys() & zh_by_tag.keys():
        en_entry = en_by_tag[tag]
        zh_entry = zh_by_tag[tag]
        if zh_entry.language != TARGET_LANGUAGE:
            errors.append(f"{chinese}: {tag}: expected language {TARGET_LANGUAGE}")
        if not zh_entry.text.strip():
            errors.append(f"{chinese}: {tag}: empty translation")
        if extract_tokens(en_entry.text) != extract_tokens(zh_entry.text):
            errors.append(f"{chinese}: {tag}: token mismatch")
    return errors


def validate_sql_pair(english: Path, chinese: Path) -> list[str]:
    """Validate one English/Chinese SQL localization file pair."""
    try:
        en_entries = parse_sql_updates(english)
        zh_entries = parse_sql_updates(chinese)
    except (OSError, ValueError) as exc:
        return [str(exc)]
    errors = _validate_entries(english, chinese, en_entries, zh_entries)
    try:
        with sqlite3.connect(":memory:") as db:
            db.execute(
                "CREATE TABLE LocalizedText "
                "(Tag TEXT NOT NULL, Language TEXT NOT NULL, Text TEXT)"
            )
            db.executemany(
                "INSERT INTO LocalizedText (Tag, Language, Text) VALUES (?, ?, '')",
                [(entry.tag, entry.language) for entry in zh_entries],
            )
            db.executescript(chinese.read_text(encoding="utf-8-sig"))
    except (OSError, sqlite3.Error) as exc:
        errors.append(f"{chinese}: SQL execution failed: {exc}")
    return sorted(errors)


def load_official_chinese(paths: list[Path]) -> dict[str, str]:
    """Load Simplified Chinese Row and Replace elements from Firaxis XML."""
    values: dict[str, str] = {}
    for path in paths:
        root = ET.parse(path).getroot()
        for element_name in ("Row", "Replace"):
            for row in root.findall(f".//{element_name}"):
                if row.get("Language") != TARGET_LANGUAGE:
                    continue
                tag = row.get("Tag", "")
                text = row.findtext("Text", default="")
                values[tag] = text
    return values


def _read_config_lines(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    return {
        line.strip()
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }


def _entries_for(path: Path) -> list[Entry]:
    if path.suffix.lower() == ".xml":
        entries, errors = parse_xml_entries(path)
        if errors:
            raise ValueError("\n".join(errors))
        return entries
    if path.suffix.lower() == ".sql":
        return parse_sql_updates(path)
    raise ValueError(f"{path}: unsupported localization file")


def _official_xml_paths(game_dir: Path) -> list[Path]:
    paths: list[Path] = []
    base = game_dir / "Base" / "Assets" / "Text" / "Vanilla_zh_Hans_CN.xml"
    if base.is_file():
        paths.append(base)
    dlc = game_dir / "DLC"
    if dlc.is_dir():
        paths.extend(sorted(dlc.glob("**/Text/*Translations*.xml")))
    return paths


def validate_locale_directories(
    english_dir: Path,
    chinese_dir: Path,
    *,
    allow_untranslated: bool = False,
    official_game_dir: Path | None = None,
    selected_file: str | None = None,
) -> list[str]:
    """Validate matching localization resources in two locale directories."""
    errors: list[str] = []
    if not english_dir.is_dir():
        return [f"{english_dir}: English locale directory not found"]
    if not chinese_dir.is_dir():
        return [f"{chinese_dir}: Chinese locale directory not found"]

    en_names = {path.name for path in english_dir.iterdir() if path.is_file()}
    zh_names = {path.name for path in chinese_dir.iterdir() if path.is_file()}
    if selected_file:
        names = {selected_file}
    else:
        names = en_names | zh_names
        for name in sorted(en_names - zh_names):
            errors.append(f"{chinese_dir}: missing locale file {name}")
        for name in sorted(zh_names - en_names):
            errors.append(f"{chinese_dir}: extra locale file {name}")

    allowlist = _read_config_lines(ENGLISH_ALLOWLIST_PATH)
    exact_tags = _read_config_lines(OFFICIAL_EXACT_TAGS_PATH)
    official: dict[str, str] = {}
    if official_game_dir is not None:
        try:
            official = load_official_chinese(_official_xml_paths(official_game_dir))
        except (OSError, ValueError, ET.ParseError) as exc:
            errors.append(str(exc))

    for name in sorted(names):
        en_path = english_dir / name
        zh_path = chinese_dir / name
        if not en_path.is_file():
            errors.append(f"{english_dir}: missing locale file {name}")
            continue
        if not zh_path.is_file():
            errors.append(f"{chinese_dir}: missing locale file {name}")
            continue
        if en_path.suffix.lower() == ".xml":
            errors.extend(validate_xml_pair(en_path, zh_path))
        elif en_path.suffix.lower() == ".sql":
            errors.extend(validate_sql_pair(en_path, zh_path))
        else:
            errors.append(f"{en_path}: unsupported localization file")
            continue
        try:
            en_entries = {entry.tag: entry for entry in _entries_for(en_path)}
            zh_entries = {entry.tag: entry for entry in _entries_for(zh_path)}
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
            continue
        if not allow_untranslated:
            for tag in en_entries.keys() & zh_entries.keys():
                en_text = " ".join(en_entries[tag].text.split())
                zh_text = " ".join(zh_entries[tag].text.split())
                if (
                    en_text == zh_text
                    and re.search(r"[A-Za-z]{4}", _visible_prose(en_text))
                    and en_text not in allowlist
                ):
                    errors.append(f"{zh_path}: {tag}: unchanged English")
        if official:
            for tag in exact_tags & zh_entries.keys():
                if tag not in official:
                    errors.append(f"{zh_path}: {tag}: official Chinese text not found")
                elif zh_entries[tag].text != official[tag]:
                    errors.append(f"{zh_path}: {tag}: differs from official Chinese")
    return sorted(set(errors))


def audit_loaded_literals(manifest: Path, source_root: Path) -> list[str]:
    """Find direct user-facing string literals in manifest-loaded Lua files."""
    root = ET.parse(manifest).getroot()
    loaded = {
        element.text.strip().replace("\\", "/")
        for element in root.findall(".//File")
        if element.text and element.text.strip().lower().endswith(".lua")
    }
    allowlist = _read_config_lines(ENGLISH_ALLOWLIST_PATH)
    findings: list[str] = []
    for relative in sorted(loaded):
        path = source_root / Path(relative)
        if not path.is_file():
            continue
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8-sig").splitlines(), start=1
        ):
            if line.lstrip().startswith("--"):
                continue
            for pattern in USER_FACING_PATTERNS:
                for match in pattern.finditer(line):
                    text = match.group("text").strip()
                    if (
                        text
                        and text not in allowlist
                        and re.search(r"[A-Za-z]{2}", _visible_prose(text))
                    ):
                        findings.append(f"{relative}:{line_number}: {text}")
    return sorted(set(findings))


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--english", type=Path, required=True)
    parser.add_argument("--chinese", type=Path, required=True)
    parser.add_argument("--official-game-dir", type=Path)
    parser.add_argument("--file", dest="selected_file")
    parser.add_argument("--allow-untranslated", action="store_true")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--source-root", type=Path)
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    errors = validate_locale_directories(
        args.english,
        args.chinese,
        allow_untranslated=args.allow_untranslated,
        official_game_dir=args.official_game_dir,
        selected_file=args.selected_file,
    )
    if args.manifest or args.source_root:
        if not args.manifest or not args.source_root:
            errors.append("--manifest and --source-root must be supplied together")
        else:
            errors.extend(audit_loaded_literals(args.manifest, args.source_root))
    if errors:
        for error in sorted(set(errors)):
            print(error, file=sys.stderr)
        return 1
    selected = args.selected_file or "all locale files"
    print(f"Localization validation passed: {selected}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
