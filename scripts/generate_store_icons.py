from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MASTER_SIZE = 1024
SCALE = 4


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size), top)
    pixels = image.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3))
        for x in range(size):
            pixels[x, y] = color
    return image


def radial_glow(size: int, center: tuple[float, float], radius: float, color: tuple[int, int, int, int]) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = layer.load()
    cx, cy = center
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            distance = (dx * dx + dy * dy) ** 0.5
            if distance < radius:
                t = 1 - distance / radius
                alpha = round(color[3] * (t ** 1.7))
                pixels[x, y] = (*color[:3], alpha)
    return layer


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def draw_wave(draw: ImageDraw.ImageDraw, points: Iterable[tuple[int, int]], width: int, fill: tuple[int, int, int, int]) -> None:
    pts = list(points)
    draw.line(pts, fill=fill, width=width, joint="curve")
    for point in pts:
        r = width // 3
        draw.ellipse((point[0] - r, point[1] - r, point[0] + r, point[1] + r), fill=fill)


def render_icon(size: int = MASTER_SIZE) -> Image.Image:
    canvas_size = size * SCALE
    bg = gradient(canvas_size, (14, 23, 34), (8, 11, 18)).convert("RGBA")
    bg.alpha_composite(radial_glow(canvas_size, (canvas_size * 0.28, canvas_size * 0.16), canvas_size * 0.62, (45, 212, 191, 145)))
    bg.alpha_composite(radial_glow(canvas_size, (canvas_size * 0.82, canvas_size * 0.84), canvas_size * 0.72, (96, 165, 250, 105)))

    draw = ImageDraw.Draw(bg)
    pad = round(canvas_size * 0.065)
    draw.rounded_rectangle(
        (pad, pad, canvas_size - pad, canvas_size - pad),
        radius=round(canvas_size * 0.205),
        outline=(255, 255, 255, 34),
        width=round(canvas_size * 0.018),
    )

    shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    bubble = (
        round(canvas_size * 0.18),
        round(canvas_size * 0.245),
        round(canvas_size * 0.82),
        round(canvas_size * 0.675),
    )
    radius = round(canvas_size * 0.12)
    shadow_draw.rounded_rectangle(
        (bubble[0], bubble[1] + round(canvas_size * 0.035), bubble[2], bubble[3] + round(canvas_size * 0.035)),
        radius=radius,
        fill=(0, 0, 0, 118),
    )
    shadow_draw.polygon(
        [
            (round(canvas_size * 0.42), bubble[3] + round(canvas_size * 0.02)),
            (round(canvas_size * 0.51), bubble[3] + round(canvas_size * 0.02)),
            (round(canvas_size * 0.38), round(canvas_size * 0.82)),
        ],
        fill=(0, 0, 0, 105),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(canvas_size * 0.035)))
    bg.alpha_composite(shadow)

    bubble_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bubble_draw = ImageDraw.Draw(bubble_layer)
    bubble_draw.rounded_rectangle(bubble, radius=radius, fill=(240, 253, 250, 247))
    bubble_draw.polygon(
        [
            (round(canvas_size * 0.405), bubble[3] - round(canvas_size * 0.005)),
            (round(canvas_size * 0.535), bubble[3] - round(canvas_size * 0.005)),
            (round(canvas_size * 0.37), round(canvas_size * 0.80)),
        ],
        fill=(240, 253, 250, 247),
    )
    bubble_draw.rounded_rectangle(
        (
            bubble[0] + round(canvas_size * 0.034),
            bubble[1] + round(canvas_size * 0.034),
            bubble[2] - round(canvas_size * 0.034),
            bubble[3] - round(canvas_size * 0.034),
        ),
        radius=round(canvas_size * 0.092),
        outline=(20, 184, 166, 82),
        width=round(canvas_size * 0.014),
    )
    bg.alpha_composite(bubble_layer)

    accent = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    center_y = round(canvas_size * 0.465)
    wave_points = [
        (round(canvas_size * 0.285), center_y),
        (round(canvas_size * 0.35), round(canvas_size * 0.395)),
        (round(canvas_size * 0.43), round(canvas_size * 0.555)),
        (round(canvas_size * 0.51), round(canvas_size * 0.345)),
        (round(canvas_size * 0.605), round(canvas_size * 0.58)),
        (round(canvas_size * 0.715), round(canvas_size * 0.43)),
    ]
    draw_wave(accent_draw, wave_points, round(canvas_size * 0.04), (13, 148, 136, 255))
    draw_wave(accent_draw, wave_points, round(canvas_size * 0.018), (94, 234, 212, 255))

    for x, h in [
        (0.315, 0.115),
        (0.385, 0.205),
        (0.455, 0.155),
        (0.525, 0.245),
        (0.595, 0.145),
        (0.665, 0.195),
    ]:
        cx = round(canvas_size * x)
        y1 = round(center_y - canvas_size * h / 2)
        y2 = round(center_y + canvas_size * h / 2)
        accent_draw.rounded_rectangle(
            (cx - round(canvas_size * 0.012), y1, cx + round(canvas_size * 0.012), y2),
            radius=round(canvas_size * 0.012),
            fill=(15, 23, 42, 56),
        )

    accent_draw.ellipse(
        (
            round(canvas_size * 0.675),
            round(canvas_size * 0.235),
            round(canvas_size * 0.765),
            round(canvas_size * 0.325),
        ),
        fill=(34, 197, 94, 235),
    )
    accent_draw.ellipse(
        (
            round(canvas_size * 0.702),
            round(canvas_size * 0.262),
            round(canvas_size * 0.738),
            round(canvas_size * 0.298),
        ),
        fill=(240, 253, 250, 225),
    )
    bg.alpha_composite(accent)

    gloss = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    gloss_draw = ImageDraw.Draw(gloss)
    gloss_draw.arc(
        (
            round(canvas_size * 0.17),
            round(canvas_size * 0.11),
            round(canvas_size * 0.89),
            round(canvas_size * 0.84),
        ),
        205,
        300,
        fill=(255, 255, 255, 46),
        width=round(canvas_size * 0.022),
    )
    bg.alpha_composite(gloss)

    image = bg.convert("RGB").resize((size, size), Image.Resampling.LANCZOS)
    return image


def save_resized(master: Image.Image, path: Path, size: int, *, rgba: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = master.resize((size, size), Image.Resampling.LANCZOS)
    if rgba:
        image = image.convert("RGBA")
    else:
        image = image.convert("RGB")
    image.save(path, "PNG", optimize=True)


def main() -> None:
    master = render_icon(MASTER_SIZE)

    store_dir = ROOT / "store_assets" / "icons"
    save_resized(master, store_dir / "appstore_icon_1024.png", 1024)
    save_resized(master, store_dir / "playstore_icon_512.png", 512)

    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        save_resized(master, ios_dir / filename, size)

    mac_dir = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    mac_sizes = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    for filename, size in mac_sizes.items():
        save_resized(master, mac_dir / filename, size, rgba=True)

    android_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    android_sizes = {
        "mipmap-mdpi/ic_launcher.png": 48,
        "mipmap-hdpi/ic_launcher.png": 72,
        "mipmap-xhdpi/ic_launcher.png": 96,
        "mipmap-xxhdpi/ic_launcher.png": 144,
        "mipmap-xxxhdpi/ic_launcher.png": 192,
    }
    for filename, size in android_sizes.items():
        save_resized(master, android_dir / filename, size)

    web_dir = ROOT / "web" / "icons"
    save_resized(master, web_dir / "Icon-192.png", 192)
    save_resized(master, web_dir / "Icon-512.png", 512)
    save_resized(master, web_dir / "Icon-maskable-192.png", 192)
    save_resized(master, web_dir / "Icon-maskable-512.png", 512)
    save_resized(master, ROOT / "web" / "favicon.png", 32)

    print(f"Generated app icons from master: {store_dir / 'appstore_icon_1024.png'}")


if __name__ == "__main__":
    main()
