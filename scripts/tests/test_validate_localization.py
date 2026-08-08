from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET


SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))

from validate_localization import (
    audit_loaded_literals,
    extract_tokens,
    load_official_chinese,
    parse_sql_updates,
    validate_locale_directories,
    validate_sql_pair,
    validate_xml_pair,
)


class XmlValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_xml(
        self, name: str, language: str, rows: list[tuple[str, str]]
    ) -> Path:
        body = "\n".join(
            f'    <Row Tag="{tag}" Language="{language}"><Text>{text}</Text></Row>'
            for tag, text in rows
        )
        path = self.root / name
        path.write_text(
            f'<?xml version="1.0" encoding="utf-8"?>\n'
            f"<GameData><LocalizedText>\n{body}\n</LocalizedText></GameData>\n",
            encoding="utf-8",
        )
        return path

    def test_matching_xml_pair_passes(self) -> None:
        en = self.write_xml(
            "en.xml", "en_US", [("LOC_A", "Move [ICON_Movement] {1_Num}")]
        )
        zh = self.write_xml(
            "zh.xml", "zh_Hans_CN", [("LOC_A", "移动 [ICON_Movement] {1_Num}")]
        )
        self.assertEqual([], validate_xml_pair(en, zh))

    def test_missing_tag_fails(self) -> None:
        en = self.write_xml(
            "en.xml", "en_US", [("LOC_A", "A"), ("LOC_B", "B")]
        )
        zh = self.write_xml("zh.xml", "zh_Hans_CN", [("LOC_A", "甲")])
        self.assertIn("missing tag LOC_B", "\n".join(validate_xml_pair(en, zh)))

    def test_wrong_language_fails(self) -> None:
        en = self.write_xml("en.xml", "en_US", [("LOC_A", "A")])
        zh = self.write_xml("zh.xml", "en_US", [("LOC_A", "甲")])
        self.assertIn(
            "expected language zh_Hans_CN", "\n".join(validate_xml_pair(en, zh))
        )

    def test_duplicate_tag_fails(self) -> None:
        en = self.write_xml("en.xml", "en_US", [("LOC_A", "A")])
        zh = self.write_xml(
            "zh.xml", "zh_Hans_CN", [("LOC_A", "甲"), ("LOC_A", "乙")]
        )
        self.assertIn("duplicate tag LOC_A", "\n".join(validate_xml_pair(en, zh)))

    def test_token_multiset_includes_markup_parameters_and_numbers(self) -> None:
        self.assertEqual(
            extract_tokens("Use [ICON_Movement] {1_Num} on turn 12, 12."),
            extract_tokens("第12回合使用 [ICON_Movement] {1_Num}，数值为12。"),
        )

    def test_plural_branch_text_can_be_localized(self) -> None:
        english = "{1_Count} {1_Count : plural 1?item; other?items;}"
        chinese = "{1_Count} {1_Count : plural 1?个项目; other?个项目;}"
        wrong_parameter = "{1_Count} {2_Count : plural 1?个项目; other?个项目;}"
        nested_english = (
            "{1_Count : plural 1?{1_Count} tile; other?{1_Count} tiles;}"
        )
        nested_chinese = (
            "{1_Count : plural 1?{1_Count}个单元格; other?{1_Count}个单元格;}"
        )

        self.assertEqual(extract_tokens(english), extract_tokens(chinese))
        self.assertEqual(extract_tokens(nested_english), extract_tokens(nested_chinese))
        self.assertNotEqual(extract_tokens(english), extract_tokens(wrong_parameter))


class SqlValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_sql_preserves_doubled_apostrophes_and_tag_order(self) -> None:
        en = self.root / "en.sql"
        zh = self.root / "zh.sql"
        en.write_text(
            "UPDATE LocalizedText SET Text = 'Scanner''s result' "
            "WHERE Tag = 'LOC_A' AND Language = 'en_US';\n",
            encoding="utf-8",
        )
        zh.write_text(
            "UPDATE LocalizedText SET Text = '扫描器结果' "
            "WHERE Tag = 'LOC_A' AND Language = 'zh_Hans_CN';\n",
            encoding="utf-8",
        )
        self.assertEqual([], validate_sql_pair(en, zh))
        self.assertEqual("Scanner's result", parse_sql_updates(en)[0].text)

    def test_sql_token_mismatch_fails(self) -> None:
        en = self.root / "en.sql"
        zh = self.root / "zh.sql"
        en.write_text(
            "UPDATE LocalizedText SET Text = 'Turn 12 [ICON_Food]' "
            "WHERE Tag = 'LOC_A' AND Language = 'en_US';\n",
            encoding="utf-8",
        )
        zh.write_text(
            "UPDATE LocalizedText SET Text = '第13回合' "
            "WHERE Tag = 'LOC_A' AND Language = 'zh_Hans_CN';\n",
            encoding="utf-8",
        )
        errors = "\n".join(validate_sql_pair(en, zh))
        self.assertIn("LOC_A: token mismatch", errors)

    def test_unmatched_sql_raises(self) -> None:
        path = self.root / "bad.sql"
        path.write_text("DELETE FROM LocalizedText;\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "unrecognized SQL"):
            parse_sql_updates(path)


class DirectoryAndOfficialValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.en = self.root / "en_US"
        self.zh = self.root / "zh_Hans_CN"
        self.en.mkdir()
        self.zh.mkdir()

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def write_xml(path: Path, language: str, text: str) -> None:
        path.write_text(
            '<GameData><LocalizedText><Row Tag="LOC_A" '
            f'Language="{language}"><Text>{text}</Text></Row>'
            "</LocalizedText></GameData>",
            encoding="utf-8",
        )

    def test_official_replace_rows_are_loaded(self) -> None:
        official = self.root / "official.xml"
        official.write_text(
            '<GameData><LocalizedText><Replace Tag="LOC_A" Language="zh_Hans_CN">'
            "<Text>官方译文</Text></Replace></LocalizedText></GameData>",
            encoding="utf-8",
        )
        self.assertEqual("官方译文", load_official_chinese([official])["LOC_A"])

    def test_later_official_package_overrides_an_existing_tag(self) -> None:
        base = self.root / "base.xml"
        package = self.root / "package.xml"
        base.write_text(
            '<GameData><LocalizedText><Replace Tag="LOC_A" Language="zh_Hans_CN">'
            "<Text>基础规则文本</Text></Replace></LocalizedText></GameData>",
            encoding="utf-8",
        )
        package.write_text(
            '<GameData><LocalizedText><Replace Tag="LOC_A" Language="zh_Hans_CN">'
            "<Text>剧本覆盖文本</Text></Replace></LocalizedText></GameData>",
            encoding="utf-8",
        )
        self.assertEqual(
            "剧本覆盖文本", load_official_chinese([base, package])["LOC_A"]
        )

    def test_missing_and_extra_files_fail(self) -> None:
        self.write_xml(self.en / "a.xml", "en_US", "English")
        self.write_xml(self.zh / "extra.xml", "zh_Hans_CN", "中文")
        errors = "\n".join(validate_locale_directories(self.en, self.zh))
        self.assertIn("missing locale file a.xml", errors)
        self.assertIn("extra locale file extra.xml", errors)

    def test_unchanged_english_fails_unless_permitted(self) -> None:
        self.write_xml(self.en / "a.xml", "en_US", "Untranslated sentence")
        self.write_xml(self.zh / "a.xml", "zh_Hans_CN", "Untranslated sentence")
        errors = "\n".join(validate_locale_directories(self.en, self.zh))
        self.assertIn("LOC_A: unchanged English", errors)
        self.assertEqual(
            [],
            validate_locale_directories(
                self.en, self.zh, allow_untranslated=True
            ),
        )

    def test_unchanged_placeholder_only_value_is_not_english_prose(self) -> None:
        self.write_xml(self.en / "a.xml", "en_US", "{1_Tooltip}")
        self.write_xml(self.zh / "a.xml", "zh_Hans_CN", "{1_Tooltip}")

        self.assertEqual([], validate_locale_directories(self.en, self.zh))


class LoadedLiteralTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_loaded_speech_literal_is_reported(self) -> None:
        source = self.root / "UI" / "Test.lua"
        source.parent.mkdir(parents=True)
        source.write_text('Speak("Visible English")\n', encoding="utf-8")
        manifest = self.root / "Test.modinfo"
        manifest.write_text(
            "<Mod><Files><File>UI/Test.lua</File></Files></Mod>", encoding="utf-8"
        )
        findings = audit_loaded_literals(manifest, self.root)
        self.assertEqual(1, len(findings))
        self.assertIn("Visible English", findings[0])

    def test_unloaded_speech_literal_is_ignored(self) -> None:
        source = self.root / "UI" / "Unused.lua"
        source.parent.mkdir(parents=True)
        source.write_text('Speak("Not loaded")\n', encoding="utf-8")
        manifest = self.root / "Test.modinfo"
        manifest.write_text("<Mod><Files /></Mod>", encoding="utf-8")
        self.assertEqual([], audit_loaded_literals(manifest, self.root))

    def test_loaded_markup_only_literal_is_ignored(self) -> None:
        source = self.root / "UI" / "Test.lua"
        source.parent.mkdir(parents=True)
        source.write_text('Controls.Label:SetText("[COLOR_RED]")\n', encoding="utf-8")
        manifest = self.root / "Test.modinfo"
        manifest.write_text(
            "<Mod><Files><File>UI/Test.lua</File></Files></Mod>", encoding="utf-8"
        )

        self.assertEqual([], audit_loaded_literals(manifest, self.root))

    def test_repository_has_no_loaded_user_facing_literals(self) -> None:
        repository = Path(__file__).resolve().parents[2]

        self.assertEqual(
            [],
            audit_loaded_literals(
                repository / "src" / "CivViAccess.modinfo",
                repository / "src",
            ),
        )


class ManifestMetadataTests(unittest.TestCase):
    def test_metadata_uses_keys_defined_in_both_locales(self) -> None:
        repository = Path(__file__).resolve().parents[2]
        manifest = ET.parse(repository / "src" / "CivViAccess.modinfo").getroot()
        expected = {
            "Name": "LOC_CAI_MOD_NAME",
            "Description": "LOC_CAI_MOD_DESCRIPTION",
            "Teaser": "LOC_CAI_MOD_TEASER",
        }

        for property_name, key in expected.items():
            self.assertEqual(key, manifest.findtext(f"./Properties/{property_name}"))
        for locale in ("en_US", "zh_Hans_CN"):
            text = ET.parse(
                repository / "src" / "Text" / locale / "cai_text_ui.xml"
            ).getroot()
            tags = {row.get("Tag") for row in text.findall("./LocalizedText/Row")}
            self.assertTrue(set(expected.values()) <= tags)


if __name__ == "__main__":
    unittest.main()
