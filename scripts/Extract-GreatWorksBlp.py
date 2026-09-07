#!/usr/bin/env python3
"""Extract the great work images from a Firaxis Civilization VI "CIVBLP" UI
texture package (ForgeUI::TexturePackage) as PNG files.

Usage: Extract-GreatWorksBlp.py <file.blp> <output dir>

File layout (all little endian):

  0x000  "CIVBLP", u16 version (2), u32 header size (0x400), u32 ?, u32 big-data
         offset (start of the raw pixel data, 0x400 aligned), u32 entry count,
         u32 file size.  0x048..0x248 looks like a 512 byte signature.
  0x400  Type package ("TypeInfoStripe"): a small header, then the name string,
         then stripe 0 (structs) and stripe 1 (strings), then an allocation
         table of 40 byte Serialization::PackageAllocation records
         {u8 stripe, u8 allocType, u8 pad[4], u16 parent, u32 offset,
          u32 size, u32 count, u32 pad, u64 userData, u64 typeName}.
         ptr64 values in the file are (allocation index + 1); 0 is null.
         Stripe 0 starts with the TypeVersion array (56 bytes each:
         name ptr, underlying ptr, fields ptr, u64 nElements, u64 currSize,
         u32 version, u32 size, u32 flags, pad); fields are FieldVersion
         (24 bytes: name ptr, type ptr, u32 version, u32 offset).
  Then   Data package: stripe 0 begins right after the type allocation table,
         stripe 1 (type name strings) follows, then its own allocation table
         (same 40 byte records) which ends before the big-data offset.

Data package contents that matter here:

  ForgeUI::TexturePackage      m_Textures: BLP::TextureEntry[] (atlas pages)
  BLP::TextureEntry (0x68)     +0x08 name ptr, +0x20 u64 offset into big data,
                               +0x28 u32 size, +0x58 u16 format (28 = RGBA8),
                               +0x5a u16 width, +0x5c u16 height, +0x62 u8 mips
  BLP::TBufferEntry (0x48)     +0x08 name ptr, +0x20 u64 offset, +0x28 u32 size,
                               +0x40 u32 element count (u32 elements),
                               +0x44 u32 format (42 = R32_UINT)
  ForgeUI::TexturePackageEntry (0x60)
                               +0x38 name ptr, +0x48 flags, +0x4c page index,
                               +0x50 u16 x, +0x52 u16 y, +0x54 u16 w, +0x56 u16 h
                               -> plain RGBA8 sub-rectangle of an atlas page.
  ForgeUI::BCTexturePackageEntry (0x70) = TexturePackageEntry +
                               +0x60 u32 blockOffset, +0x64 u32 indexOffset
                               (both in u32 elements), +0x68 u16 blockSize
                               (block edge in pixels: 1, 2, 4, 8 or 16),
                               +0x6a u16 bytesPerIndex (1 or 2)
                               -> a TBuffer of the same name holds
                               [unique blockSize*blockSize RGBA8 blocks]
                               [ceil(w/bs)*ceil(h/bs) block indices]
                               and the game reconstructs the image on the GPU.
"""
import os
import struct
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python3 -m pip install --user pillow")


class Package:
    """Parses the type package and the data package of one CIVBLP file."""

    REC = 40

    def __init__(self, path):
        with open(path, "rb") as fh:
            self.d = fh.read()
        d = self.d
        if d[:6] != b"CIVBLP":
            raise ValueError("not a CIVBLP file")
        self.version, self.header_size, _unused, self.big_data, self.entry_count, self.file_size = struct.unpack_from("<HIIIII", d, 6)

        # Type package: locate its name (first non-zero bytes after the header
        # end at the 16 byte block "10 00 00 00 30 00 00 00 28 00 00 00 10 00 00 00").
        sig = bytes.fromhex("10000000300000002800000010000000")
        pos = d.find(sig, self.header_size)
        if pos < 0:
            raise ValueError("type package header not found")
        sizes = struct.unpack_from("<18I", d, pos - 72)
        name_off = pos + 16
        self.type_name = d[name_off:d.index(b"\0", name_off)]
        self.S0 = name_off + len(self.type_name) + 1
        self.S0size = sizes[7]
        self.S1 = self.S0 + self.S0size
        self.S1size = sizes[14]

        o = self.S1 + self.S1size
        while not (self._valid(o) and self._rec(o)["tn"] >= 1):
            o += 1
        self.tallocs = []
        while self._valid(o) and self._rec(o)["tn"] >= 1:
            self.tallocs.append(self._rec(o))
            o += self.REC
        self.tend = o

        self.types = {}
        # The first allocation of stripe 0 is the TypeVersion array itself.
        ntypes = self.tallocs[0]["cnt"]
        for i in range(ntypes):
            b = self.S0 + i * 56
            name, under, fields, nel, ncur, ver, size, flags = struct.unpack_from("<QQQQQIII", d, b)
            if name < 1 or name - 1 >= len(self.tallocs):
                break
            fl = []
            if fields >= 1:
                fb = self.S0 + self.tallocs[fields - 1]["off"]
                for j in range(nel):
                    fn, ft, fv, fo = struct.unpack_from("<QQII", d, fb + j * 24)
                    fl.append((self.tstr(fn), self.tstr(ft), fo))
            self.types[self.tstr(name)] = {"size": size, "fields": fl}

        # Data package.
        self.DS0 = self.tend
        o = self.tend

        def ok(o):
            if not self._valid(o):
                return False
            r = self._rec(o)
            return 1 <= r["tn"] <= len(self.tallocs) and r["user"] <= len(self.tallocs) and r["size"] > 0

        while not (ok(o) and self._rec(o)["off"] == 0 and self._rec(o)["stripe"] == 0
                   and ok(o + self.REC) and self._rec(o + self.REC)["off"] == self._rec(o)["size"]):
            o += 1
        self.dtable = o
        self.dallocs = []
        while ok(o):
            self.dallocs.append(self._rec(o))
            o += self.REC
        self.dend = o
        self.DS0size = max(r["off"] + r["size"] for r in self.dallocs if r["stripe"] == 0)
        self.DS1 = self.DS0 + self.DS0size

    def _rec(self, o):
        d = self.d
        stripe, atype = d[o], d[o + 1]
        parent = struct.unpack_from("<H", d, o + 6)[0]
        off, size, cnt, pad, user, tn = struct.unpack_from("<IIIIQQ", d, o + 8)
        return dict(o=o, stripe=stripe, atype=atype, parent=parent, off=off, size=size, cnt=cnt, user=user, tn=tn)

    def _valid(self, o):
        if o + self.REC > len(self.d):
            return False
        r = self._rec(o)
        return (r["stripe"] < 8 and r["atype"] < 8 and self.d[o + 2:o + 6] == b"\0\0\0\0"
                and struct.unpack_from("<I", self.d, o + 20)[0] == 0
                and r["off"] < 0x10000000 and r["size"] < 0x10000000 and (r["size"] or r["cnt"] == 0))

    def tstr(self, p):
        """String referenced by a ptr64 inside the type package."""
        if p < 1:
            return None
        r = self.tallocs[p - 1]
        base = self.S1 if r["stripe"] == 1 else self.S0
        return self.d[base + r["off"]:self.d.index(b"\0", base + r["off"])].decode("latin1")

    def dbase(self, stripe):
        return self.DS0 if stripe == 0 else self.DS1

    def dstr(self, p):
        """String::BasicT referenced by a ptr64 inside the data package: u32 capacity, u32 length, chars."""
        r = self.dallocs[p - 1]
        base = self.dbase(r["stripe"]) + r["off"]
        cap, ln = struct.unpack_from("<II", self.d, base)
        return self.d[base + 8:base + 8 + ln].decode("latin1")

    def field_offset(self, type_name, field):
        for fn, ft, fo in self.types[type_name]["fields"]:
            if fn == field:
                return fo
        raise KeyError(f"{type_name}.{field}")

    def textures(self):
        """Atlas pages: list of dicts with name, offset, size, format, width, height."""
        d = self.d
        if "BLP::TextureEntry" not in self.types:
            return []
        te = self.types["BLP::TextureEntry"]["size"]
        f = lambda n: self.field_offset("BLP::TextureEntry", n)
        out = []
        for r in self.dallocs:
            if r["stripe"] != 0 or r["cnt"] < 1 or r["size"] != te * r["cnt"] or r["cnt"] == 1:
                continue
            base = self.DS0 + r["off"]
            for i in range(r["cnt"]):
                o = base + i * te
                name = struct.unpack_from("<Q", d, o + f("m_Name"))[0]
                if name < 1 or name > len(self.dallocs):
                    break
                out.append(dict(
                    name=self.dstr(name),
                    offset=struct.unpack_from("<Q", d, o + f("m_nOffset"))[0],
                    size=struct.unpack_from("<I", d, o + f("m_nSize"))[0],
                    format=struct.unpack_from("<H", d, o + f("m_eFormat"))[0],
                    width=struct.unpack_from("<H", d, o + f("m_nWidth"))[0],
                    height=struct.unpack_from("<H", d, o + f("m_nHeight"))[0],
                    mips=d[o + f("m_nMips")],
                ))
        return out

    def tbuffers(self):
        d = self.d
        if "BLP::TBufferEntry" not in self.types:
            return {}
        tb = self.types["BLP::TBufferEntry"]["size"]
        f = lambda n: self.field_offset("BLP::TBufferEntry", n)
        out = {}
        for r in self.dallocs:
            if r["stripe"] != 0 or r["cnt"] < 1 or r["size"] != tb * r["cnt"] or r["cnt"] == 1:
                continue
            base = self.DS0 + r["off"]
            for i in range(r["cnt"]):
                o = base + i * tb
                name = struct.unpack_from("<Q", d, o + f("m_Name"))[0]
                if name < 1 or name > len(self.dallocs):
                    break
                out[self.dstr(name)] = dict(
                    offset=struct.unpack_from("<Q", d, o + f("m_nOffset"))[0],
                    size=struct.unpack_from("<I", d, o + f("m_nSize"))[0],
                    count=struct.unpack_from("<I", d, o + f("m_nElementCount"))[0],
                    format=struct.unpack_from("<I", d, o + f("m_eFormat"))[0],
                )
        return out

    def entries(self):
        d = self.d
        plain = self.types.get("ForgeUI::TexturePackageEntry", {}).get("size", -1)
        bc = self.types.get("ForgeUI::BCTexturePackageEntry", {}).get("size", -1)
        f = lambda n: self.field_offset("ForgeUI::TexturePackageEntry", n)
        g = lambda n: self.field_offset("ForgeUI::BCTexturePackageEntry", n)
        out = []
        for r in self.dallocs:
            if r["stripe"] != 0 or r["cnt"] != 1 or r["size"] not in (plain, bc):
                continue
            o = self.DS0 + r["off"]
            name = struct.unpack_from("<Q", d, o + f("m_Name"))[0]
            if name < 1 or name > len(self.dallocs):
                continue
            e = dict(
                name=self.dstr(name),
                flags=struct.unpack_from("<I", d, o + f("m_uiFlags"))[0],
                page=struct.unpack_from("<I", d, o + f("m_nPageIndex"))[0],
                x=struct.unpack_from("<H", d, o + f("m_nXOffset"))[0],
                y=struct.unpack_from("<H", d, o + f("m_nYOffset"))[0],
                w=struct.unpack_from("<H", d, o + f("m_nTextureWidth"))[0],
                h=struct.unpack_from("<H", d, o + f("m_nTextureHeight"))[0],
                bc=None,
            )
            if r["size"] == bc:
                e["bc"] = dict(
                    block_offset=struct.unpack_from("<I", d, o + g("m_nBlockOffset"))[0],
                    index_offset=struct.unpack_from("<I", d, o + g("m_nIndexOffset"))[0],
                    block_size=struct.unpack_from("<H", d, o + g("m_nBlockSize"))[0],
                    bytes_per_index=struct.unpack_from("<H", d, o + g("m_nBytesPerIndex"))[0],
                )
            out.append(e)
        return out


def decode_plain(pkg, entry, pages):
    page = pages[entry["page"]]
    if page["format"] != 28:
        raise ValueError(f"page {page['name']} has unsupported format {page['format']}")
    pw, ph = page["width"], page["height"]
    x, y, w, h = entry["x"], entry["y"], entry["w"], entry["h"]
    if x + w > pw or y + h > ph:
        raise ValueError("entry rectangle outside its page")
    base = pkg.big_data + page["offset"]
    d = pkg.d
    rows = bytearray()
    for yy in range(y, y + h):
        s = base + (yy * pw + x) * 4
        rows += d[s:s + w * 4]
    return Image.frombytes("RGBA", (w, h), bytes(rows))


def decode_bc(pkg, entry, tbuf):
    bc = entry["bc"]
    bs, bpi = bc["block_size"], bc["bytes_per_index"]
    w, h = entry["w"], entry["h"]
    gw, gh = -(-w // bs), -(-h // bs)
    blob = pkg.d[pkg.big_data + tbuf["offset"]:pkg.big_data + tbuf["offset"] + tbuf["size"]]
    blocks_start = bc["block_offset"] * 4
    index_start = bc["index_offset"] * 4
    block_bytes = bs * bs * 4
    nblocks = (index_start - blocks_start) // block_bytes
    need = index_start + gw * gh * bpi
    if need > len(blob):
        raise ValueError(f"blob too small: need {need}, have {len(blob)}")
    if bpi == 1:
        idx = blob[index_start:index_start + gw * gh]
    elif bpi == 2:
        idx = struct.unpack_from(f"<{gw * gh}H", blob, index_start)
    else:
        raise ValueError(f"unsupported bytes per index {bpi}")
    if max(idx) >= nblocks:
        raise ValueError(f"block index {max(idx)} out of range ({nblocks} blocks)")
    row_bytes = bs * 4
    out = bytearray()
    for gy in range(gh):
        row_idx = idx[gy * gw:(gy + 1) * gw]
        row_starts = [blocks_start + i * block_bytes for i in row_idx]
        for py in range(bs):
            if gy * bs + py >= h:
                break
            line = bytearray()
            off = py * row_bytes
            for s in row_starts:
                line += blob[s + off:s + off + row_bytes]
            out += line[:w * 4]
    return Image.frombytes("RGBA", (w, h), bytes(out))


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: extract_blp.py <file.blp> <output dir>")
    path, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    pkg = Package(path)
    pages = pkg.textures()
    tbufs = pkg.tbuffers()
    entries = pkg.entries()
    print(f"{os.path.basename(path)}: {len(pages)} pages, {len(tbufs)} tbuffers, {len(entries)} entries (header says {pkg.entry_count})")
    failed = []
    for e in entries:
        try:
            if e["bc"] is None:
                img = decode_plain(pkg, e, pages)
                kind = f"page {e['page']} RGBA8"
            else:
                tb = tbufs[e["name"]]
                img = decode_bc(pkg, e, tb)
                kind = f"blocks {e['bc']['block_size']}x{e['bc']['block_size']} idx{e['bc']['bytes_per_index']}"
            img.save(os.path.join(outdir, e["name"] + ".png"))
            print(f"  {e['name']:16} {e['w']}x{e['h']}  {kind}")
        except Exception as ex:  # report and continue with the other textures
            failed.append((e["name"], str(ex)))
            print(f"  {e['name']:16} FAILED: {ex}")
    if failed:
        print(f"{len(failed)} failed: " + ", ".join(n for n, _ in failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
