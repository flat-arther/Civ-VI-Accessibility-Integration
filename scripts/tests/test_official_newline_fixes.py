import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ZH_FILE = ROOT / "src" / "Text" / "zh_Hans_CN" / "cai_text_ui.xml"
OFFICIAL_FILE = Path(
    r"D:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI"
) / "Base" / "Assets" / "Text" / "Vanilla_zh_Hans_CN.xml"

FIX_BREAKS = {
    "LOC_META_98_BODY": "技[NEWLINE]术",
    "LOC_META_105_BODY": "您[NEWLINE]决",
    "ADVISOR_LINE_FTUE_12ALT": "准[NEWLINE]备",
    "LOC_WORLD_RANKINGS_SCIENCE_DETAILS": "个[NEWLINE]重",
    "LOC_WORLD_RANKINGS_CULTURE_DETAILS_DOMESTIC_TOURISTS": "的[NEWLINE]旅",
    "LOC_TECH_MINING_QUOTE_1": "得[NEWLINE]信",
    "LOC_CIVIC_CODE_OF_LAWS_QUOTE_2": "的[NEWLINE]动",
    "LOC_CIVIC_MERCENARIES_QUOTE_1": "兵[NEWLINE]掠",
    "LOC_CIVIC_OPERA_BALLET_QUOTE_1": "了[NEWLINE]一",
    "LOC_CIVIC_URBANIZATION_QUOTE_2": "都[NEWLINE]很",
    "LOC_GREATWORK_CHAUCER_1_QUOTE": "马[NEWLINE]闯",
    "LOC_GREATWORK_SHAKESPEARE_2_QUOTE": "受[NEWLINE]坎",
    "LOC_GREATWORK_PUSHKIN_2_QUOTE": "考[NEWLINE]他",
    "LOC_GREATWORK_GOETHE_2_QUOTE": "到[NEWLINE]恐",
    "LOC_GREATWORK_DICKINSON_1_QUOTE": "半[NEWLINE]生",
    "LOC_GREATWORK_DICKINSON_2_QUOTE": "为[NEWLINE]成",
}


def load_texts(path: Path, language: str) -> dict[str, str]:
    root = ET.parse(path).getroot()
    values = {}
    for element in root.iter():
        if element.tag not in {"Row", "Replace"} or element.get("Language") != language:
            continue
        text = element.findtext("Text", default="")
        values[element.get("Tag", "")] = text
    return values


class OfficialNewlineFixTests(unittest.TestCase):
    def test_selected_official_breaks_are_overridden_without_mid_phrase_newlines(self):
        official = load_texts(OFFICIAL_FILE, "zh_Hans_CN")
        localized = load_texts(ZH_FILE, "zh_Hans_CN")
        for tag, bad_break in FIX_BREAKS.items():
            self.assertIn(bad_break, official[tag], f"official evidence missing for {tag}")
            self.assertIn(tag, localized, f"missing localized override for {tag}")
            self.assertNotIn(bad_break, localized[tag], f"mid-phrase break remains for {tag}")


if __name__ == "__main__":
    unittest.main()
