"""Steal a Seed :: the Plant Almanac's stud texture.

One soft white dot, centred on a transparent 64px tile. IndexUI tiles it over
the moss body (ScaleType.Tile, GameConfig.Almanac.DotTile) and tints it with
ImageColor3, so the colour and strength live in GameConfig and this file only
draws the shape.

Standard library only -- there is no Pillow on this machine to rely on.

    python tools/art/almanac_dots.py   ->   art/index/almanac-dots-64.png
"""

import math
import os
import struct
import zlib

SIZE = 64
# At 64 texels; about two pixels across once tiled at 22.
RADIUS = 6.0
# The anti-aliasing ramp, in texels. A hard edge shimmers when a tile this small
# is scaled down.
SOFT = 1.6


def chunk(kind: bytes, payload: bytes) -> bytes:
    crc = zlib.crc32(kind + payload) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", crc)


def main() -> None:
    centre = (SIZE - 1) / 2.0
    rows = []
    for y in range(SIZE):
        row = bytearray([0])  # PNG filter: none
        for x in range(SIZE):
            distance = math.hypot(x - centre, y - centre)
            alpha = max(0.0, min(1.0, (RADIUS + SOFT * 0.5 - distance) / SOFT))
            row += bytes((255, 255, 255, int(round(alpha * 255))))
        rows.append(bytes(row))

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)  # 8-bit RGBA
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
           + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))

    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    out = os.path.join(root, "art", "index", "almanac-dots-64.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "wb") as handle:
        handle.write(png)
    print(f"{out}: {len(png)} bytes")


if __name__ == "__main__":
    main()
