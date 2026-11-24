"""Regenerate Android launcher icons: centered, smaller FirstStep triangle on white."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
TRI = ROOT / "assets" / "icons" / "triangle.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# Standard Android launcher sizes
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Logo occupies this fraction of the canvas (rest is padding / safe zone).
LOGO_FRAC = 0.52


def extract_logo(src: Image.Image) -> Image.Image:
    """Crop to logo content; treat near-black as transparent."""
    rgba = src.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    minx, miny, maxx, maxy = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 16:
                continue
            # Keep logo ink; drop black canvas.
            if r < 28 and g < 28 and b < 28:
                continue
            opx[x, y] = (r, g, b, a)
            minx = min(minx, x)
            miny = min(miny, y)
            maxx = max(maxx, x)
            maxy = max(maxy, y)
    if maxx < minx:
        raise SystemExit("No logo pixels found in triangle.png")
    return out.crop((minx, miny, maxx + 1, maxy + 1))


def visual_center(logo: Image.Image) -> tuple[float, float]:
    """Center of mass weighted by darkness so trails don't pull left."""
    px = logo.load()
    w, h = logo.size
    sx = sy = mass = 0.0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 16:
                continue
            # Darker ink weighs more (main arrow >> faint trails).
            darkness = (255 - (r + g + b) / 3.0) / 255.0
            weight = (a / 255.0) * (0.25 + 0.75 * darkness)
            sx += x * weight
            sy += y * weight
            mass += weight
    if mass <= 0:
        return w / 2.0, h / 2.0
    return sx / mass, sy / mass


def make_icon(logo: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    target = int(size * LOGO_FRAC)
    lw, lh = logo.size
    scale = min(target / lw, target / lh)
    nw, nh = max(1, int(lw * scale)), max(1, int(lh * scale))
    resized = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    cx, cy = visual_center(resized)
    # Place so visual center lands on canvas center.
    x = int(round(size / 2.0 - cx))
    y = int(round(size / 2.0 - cy))
    canvas.alpha_composite(resized, (x, y))
    return canvas.convert("RGB")


def main() -> None:
    logo = extract_logo(Image.open(TRI))
    print(f"logo crop: {logo.size}")
    for folder, size in SIZES.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        icon = make_icon(logo, size)
        path = out_dir / "ic_launcher.png"
        icon.save(path, "PNG")
        print(f"wrote {path} ({size}x{size})")


if __name__ == "__main__":
    main()
