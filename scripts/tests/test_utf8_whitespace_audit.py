import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LUA_ROOT = ROOT / "src"

LOCALE_WHITESPACE = re.compile(r"%[sS]")

# These inputs are guaranteed ASCII by their owning APIs. Keep this allowlist
# narrow so localized UI text cannot silently return to locale-sensitive Lua
# whitespace classes.
ASCII_ONLY_ALLOWLIST = {
    (
        "UI/FiraxisLive/My2K.lua",
        "if (numAts > 1 or numAts == 0 or email:len() > 254 or email:find('%s')) then",
    ),
    (
        "UI/frontEnd/MainMenu.lua",
        'local major, minor, patch = version:match("^%s*(%d+)%.(%d+)%.(%d+)%s*$")',
    ),
    (
        "UI/uiManager/helpers/CAIWidgetHelpers_InputHelp.lua",
        'if part:match("^%s*(.-)%s*$") == entry.keyCombo then',
    ),
    (
        "UI/uiManager/CAIUIScreenManager.lua",
        'return string.format("%s%04d", prefix, self.NextWidgetId)',
    ),
    (
        "UI/shared/Options.lua",
        'local strTime = string.format("%.2d:%.2d%s", iHours, iMins, meridiem);',
    ),
    (
        "UI/frontEnd/Multiplayer/StagingRoom.lua",
        'bytesRemainingStr = string.format("%.02f%s/%.02f%s", bytesDownloadedScaled, modSizeStr, bytesTotalScaled, modSizeStr);',
    ),
    (
        "UI/inGame/interfaceInfoHelpers_CAI.lua",
        '"CAI movement diag unit=%s start=(%s,%s) target=(%s,%s) startPlotId=%s targetPlotId=%s reason=%s tech=%s targetOwner=%s targetVisibleUnit=%s startWater=%s targetWater=%s startArea=%s targetArea=%s plots=[%s] turns=[%s]",',
    ),
    (
        "UI/inGame/PlotToolTip_CAI.lua",
        '"CAI_RIVER_DEBUG plot=(%d,%d) isRiver=%s isRiverAdjacent=%s isRiverSide=%s isRiverCrossing=%s names=%s directions=%s self[E<-W=%s,SE<-NW=%s,SW<-NE=%s] west[W<-W=%s] northwest[NW<-NW=%s] northeast[NE<-NE=%s] crossingTo[NE=%s,E=%s,SE=%s,SW=%s,W=%s,NW=%s]",',
    ),
    (
        "UI/inGame/ProductionPanel_CAI.lua",
        'local focusKey = string.format("item:%d:%s:%d", tab, formation or "base", item.Hash or -1)',
    ),
}


class Utf8WhitespaceAuditTests(unittest.TestCase):
    def test_localized_text_patterns_do_not_use_locale_whitespace_classes(self):
        findings = []
        for path in sorted(LUA_ROOT.rglob("*.lua")):
            relative = path.relative_to(LUA_ROOT).as_posix()
            for line_number, line in enumerate(
                path.read_text(encoding="utf-8-sig").splitlines(), start=1
            ):
                stripped = line.strip()
                if not LOCALE_WHITESPACE.search(stripped):
                    continue
                if (relative, stripped) in ASCII_ONLY_ALLOWLIST:
                    continue
                findings.append(f"{relative}:{line_number}: {stripped}")

        self.assertEqual(
            findings,
            [],
            "Locale-sensitive %s/%S patterns remain in localized-text paths:\n"
            + "\n".join(findings),
        )


if __name__ == "__main__":
    unittest.main()
