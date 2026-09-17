#!/usr/bin/env python3
"""Extract the diplomacy-screen reference images for every Civilization VI
leader: the 2D leader cut-out, the painted scene layers, and a composite of
the two that approximates the diplomacy screen.

Usage: Extract-LeaderImages.py <Assets dir> <output dir>

<Assets dir> is the game's asset root, e.g.
  Windows: <Steam>/steamapps/common/Sid Meier's Civilization VI/Base/..  (pass
           the folder that contains Base/ and DLC/)
  Mac:     .../Sid Meier's Civilization VI/Civ6.app/Contents/Assets

The diplomacy screen draws an animated 3D leader model in front of painted 2D
parallax layers. The game ships no flat image of that screen, but it ships
everything needed to rebuild it:

  UI_LeaderScenes.blp        per ruleset/DLC: the scene layers, named
                             <LEADER>_1 (far, 960x505), _2 (mid, 960x505),
                             _3 (foreground, 1920x1010). The _4 entries are one
                             shared near-black vignette that blacks out the
                             right half of the screen; they are not scene art
                             and are skipped.
  LeaderFallbackImages.blp   per ruleset/DLC: FALLBACK_NEUTRAL_<NAME>, a 2D
                             render of the leader alone on transparency, about
                             1024 to 1080 px tall, in the neutral idle pose.
                             This is what the diplomacy screen shows when
                             leader scenes are set to low quality.

Output:
  cutouts/<LEADERTYPE>.png     the leader alone (RGBA)
  layers/<LEADERTYPE>_<n>.png  the scene layers
  composites/<LEADERTYPE>.jpg  layers plus the leader, 1920x1010

Scene layer extraction reuses Extract-GreatWorksBlp.py (same directory). The
fallback packages use a data-package layout that parser does not follow, so
their BLP::TextureEntry records are located by scanning for plausible
{format, width, height, mips, offset, size} tuples; the entry names are taken
from the string stripe in order, which matches entry order in every package
shipped so far. Requires Python 3 and Pillow.
"""
import importlib.util
import io
import os
import re
import struct
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python3 -m pip install --user pillow")

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("blp", os.path.join(HERE, "Extract-GreatWorksBlp.py"))
blp = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(blp)

# LeaderType (minus LEADER_) -> fallback texture name (minus FALLBACK_NEUTRAL_)
# for the leaders whose two names differ.
FALLBACK_ALIAS = {
    "CATHERINE_DE_MEDICI": "CATHERINE", "PHILIP_II": "PHILLIP", "T_ROOSEVELT": "ROOSEVELT",
    "ABRAHAM_LINCOLN": "LINCOLN", "CATHERINE_DE_MEDICI_ALT": "CATHERINE_M",
    "JOHN_CURTIN": "CURTAIN", "JULIUS_CAESAR": "JULIUS", "MENELIK": "MENELIK_II",
    "NADER_SHAH": "NADERSHAH", "NZINGA_MBANDE": "MBANDE", "QIN_ALT": "QINALT",
    "SIMON_BOLIVAR": "BOLIVAR", "T_ROOSEVELT_ROUGHRIDER": "ROOSEVELT_RR",
    "VICTORIA_ALT": "VICTORIAALT", "WU_ZETIAN": "WUZETIAN", "SULEIMAN_ALT": "SULEIMANALT",
    "HARDRADA": "HARDRADA", "AL_HAKAM_II": "AL_HAKAM_II", "BASIL_II": "BASIL_II",
}
# Leaders with no scene layers of their own (scenario leaders share one backdrop).
NO_SCENE = {"AL_HAKAM_II", "BASIL_II", "CHARLEMAGNE", "CNUT", "OLOF"}

DXGI = {28: "RGBA8", 71: "BC1", 74: "BC2", 77: "BC3", 80: "BC4", 83: "BC5", 98: "BC7"}
W, H = 1920, 1010


def find_files(root, name):
    out = []
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if f.lower() == name.lower():
                out.append(os.path.join(dirpath, f))
    return sorted(out)


def texture_bytes(fmt, w, h):
    if fmt == 28:
        return w * h * 4
    bpb = 8 if fmt in (71, 80) else 16
    return ((w + 3) // 4) * ((h + 3) // 4) * bpb


def dds_wrap(raw, w, h, fmt):
    hdr = struct.pack("<4sI", b"DDS ", 124)
    hdr += struct.pack("<IIIII", 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000, h, w, len(raw), 0)
    hdr += struct.pack("<I", 1) + b"\0" * 44
    hdr += struct.pack("<II4sIIIII", 32, 0x4, b"DX10", 0, 0, 0, 0, 0)
    hdr += struct.pack("<IIIII", 0x1000, 0, 0, 0, 0)
    hdr += struct.pack("<IIIII", fmt, 3, 0, 1, 0)
    return hdr + raw


def fallback_textures(path):
    """Yield (name, PIL image) for every leader cut-out in a fallback package."""
    d = open(path, "rb").read()
    if d[:6] != b"CIVBLP" or len(d) < 1_000_000:
        return
    _v, _hs, _u, big_data, _n, _fs = struct.unpack_from("<HIIIII", d, 6)
    names = [m.group().decode() for m in re.finditer(rb"FALLBACK_NEUTRAL_[A-Z_0-9]+", d[:big_data])]
    found = 0
    for o in range(0x400, big_data - 104):
        fmt, w, h = struct.unpack_from("<HHH", d, o + 88)
        if fmt not in DXGI or not (100 < w < 4096 and 100 < h < 4096):
            continue
        mips = d[o + 98]
        if not 1 <= mips <= 13:
            continue
        off = struct.unpack_from("<Q", d, o + 32)[0]
        size = struct.unpack_from("<I", d, o + 40)[0]
        need = texture_bytes(fmt, w, h)
        if size < need or big_data + off + size > len(d):
            continue
        raw = d[big_data + off: big_data + off + need]
        if fmt == 28:
            im = Image.frombytes("RGBA", (w, h), raw)
        else:
            im = Image.open(io.BytesIO(dds_wrap(raw, w, h, fmt))).convert("RGBA")
        name = names[found] if found < len(names) else f"UNNAMED_{found}"
        found += 1
        yield name.replace("FALLBACK_NEUTRAL_", ""), im


def scene_layers(path):
    """Yield (entry name, PIL image) for every decodable layer in a scene package."""
    try:
        pkg = blp.Package(path)
    except Exception as ex:  # scenario backdrops use another layout
        print(f"  skip {path}: {ex}")
        return
    pages = pkg.textures()
    tbufs = pkg.tbuffers()
    for e in pkg.entries():
        try:
            im = blp.decode_bc(pkg, e, tbufs[e["name"]]) if e["bc"] else blp.decode_plain(pkg, e, pages)
        except Exception:
            continue  # shared vignette pages and the like
        yield e["name"], im


def composite(layers, cutout):
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    for im in layers:
        if im.size != (W, H):
            im = im.resize((W, H), Image.LANCZOS)
        canvas.alpha_composite(im)
    s = H / cutout.height
    cut = cutout.resize((int(cutout.width * s), H), Image.LANCZOS)
    canvas.alpha_composite(cut, (int(W * 0.62) - cut.width // 2, 0))
    return canvas.convert("RGB")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    assets, out = sys.argv[1], sys.argv[2]
    for sub in ("cutouts", "layers", "composites"):
        os.makedirs(os.path.join(out, sub), exist_ok=True)

    cutouts = {}
    for path in find_files(assets, "LeaderFallbackImages.blp"):
        print(path)
        for name, im in fallback_textures(path):
            cutouts[name] = im
            print(f"  {name} {im.width}x{im.height}")

    layers = {}
    for path in find_files(assets, "UI_LeaderScenes.blp"):
        print(path)
        for name, im in scene_layers(path):
            m = re.match(r"(.+)_(\d)$", name)
            if not m or m.group(2) == "4":
                continue
            layers.setdefault(m.group(1), {})[int(m.group(2))] = im
            print(f"  {name} {im.width}x{im.height}")

    leaders = set(layers) | {k for k in FALLBACK_ALIAS} | NO_SCENE
    for leader in sorted(leaders):
        fb = FALLBACK_ALIAS.get(leader, leader)
        cut = cutouts.get(fb)
        if cut is None:
            print(f"no cut-out for {leader} (looked for {fb})")
            continue
        cut.save(os.path.join(out, "cutouts", f"LEADER_{leader}.png"))
        lay = layers.get(leader, {})
        for n, im in sorted(lay.items()):
            im.save(os.path.join(out, "layers", f"LEADER_{leader}_{n}.png"))
        composite([lay[n] for n in sorted(lay)], cut).save(
            os.path.join(out, "composites", f"LEADER_{leader}.jpg"), quality=90)
    print(f"{len(cutouts)} cut-outs, {len(layers)} scene sets, {len(leaders)} leaders written to {out}")


if __name__ == "__main__":
    main()
