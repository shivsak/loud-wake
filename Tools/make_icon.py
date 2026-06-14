#!/usr/bin/env python3
"""Generate a 1024x1024 LoudWake app icon: a dark canvas with warm 'sound wave' arcs
radiating from a clock dot. Minimal, Apple/OpenAI-ish."""
import math
import os
from PIL import Image, ImageDraw

S = 1024
OUT = os.path.join(
    os.path.dirname(__file__), "..", "Sources", "Resources",
    "Assets.xcassets", "AppIcon.appiconset", "icon_1024.png",
)

ACCENT = (255, 107, 53)
ACCENT_SOFT = (255, 150, 80)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    img = Image.new("RGB", (S, S), (10, 10, 12))
    d = ImageDraw.Draw(img)

    # vertical dark gradient with a warm glow toward the bottom
    for y in range(S):
        t = y / S
        top = (12, 12, 15)
        bot = (28, 12, 8)
        d.line([(0, y), (S, y)], fill=lerp(top, bot, t))

    cx, cy = S * 0.40, S * 0.52

    # radiating sound-wave arcs
    for i, r in enumerate([180, 280, 380]):
        col = lerp(ACCENT, ACCENT_SOFT, i / 2)
        width = 46 - i * 8
        box = [cx - r, cy - r, cx + r, cy + r]
        d.arc(box, start=-55, end=55, fill=col, width=width)

    # central dot (the "clock")
    dot = 70
    d.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=ACCENT)
    # clock hands
    d.line([(cx, cy), (cx, cy - 44)], fill=(10, 10, 12), width=16)
    d.line([(cx, cy), (cx + 34, cy + 8)], fill=(10, 10, 12), width=16)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
