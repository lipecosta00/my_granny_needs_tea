"""Custom 16x16 sprites the Kenney packs don't cover (GDD "Próprios").

Run: python3 tools/art/gen_custom_tiles.py
Palette taken from Kenney Tiny Town (outline 3f2631) so they blend in.
"""
from pathlib import Path
from PIL import Image

PALETTE = {
    ".": (0, 0, 0, 0),
    "o": (63, 38, 49, 255),     # Kenney outline
    "w": (244, 238, 222, 255),  # bone
    "s": (200, 190, 170, 255),  # bone shade
}

OSSO = [
    "................",
    "................",
    "..oo............",
    ".owwo.......oo..",
    ".owwwo.....owwo.",
    "..owwwo...owwwo.",
    "...owwwooowwso..",
    "....owwwwwwso...",
    "...owswwwwwo....",
    "..owwsooowwwo...",
    ".owwso...owwwo..",
    ".owwo.....owwwo.",
    "..oo.......owwo.",
    "............oo..",
    "................",
    "................",
]


def paint(rows):
    img = Image.new("RGBA", (16, 16))
    for y, row in enumerate(rows):
        assert len(row) == 16, f"row {y}: {len(row)} px"
        for x, ch in enumerate(row):
            img.putpixel((x, y), PALETTE[ch])
    return img


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[2] / "assets" / "custom"
    out.mkdir(parents=True, exist_ok=True)
    paint(OSSO).save(out / "osso.png")
    print("wrote", out / "osso.png")
