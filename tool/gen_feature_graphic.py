#!/usr/bin/env python3
"""Generates the Play Store feature graphic (1024x500, RGB, no alpha), TR + EN.

Uses the same original calculator artwork as the launcher/store icon
(tool/gen_launcher_icon.py, one geometry) plus an honest caption that names
the vault and the calculator entry. No ranking/price/promo text (Play
Metadata policy). Output: docs/store/feature_graphic/feature_graphic_{tr,en}.png

Run: python3 tool/gen_feature_graphic.py   (needs Pillow; fonts: Roboto from
the Flutter SDK cache, $FLUTTER_ROOT/bin/cache/artifacts/material_fonts).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_launcher_icon as icon  # noqa: E402  (same colours + geometry)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'docs', 'store', 'feature_graphic')
W, H = 1024, 500
FONT_DIR = os.path.join(
    os.environ.get('FLUTTER_ROOT', '/workspace/tools/flutter'),
    'bin', 'cache', 'artifacts', 'material_fonts',
)

TEXT = {
    'en': {
        'subtitle': 'Calculator Vault',
        'body': ['Encrypted photos, files and notes', 'behind a real, working calculator.'],
        'foot': 'Offline  ·  No internet permission  ·  No ads',
    },
    'tr': {
        'subtitle': 'Hesap Makineli Kasa',
        'body': ['Şifreli fotoğraf, dosya ve notlar', 'gerçekten çalışan bir hesap makinesinin arkasında.'],
        'foot': 'Çevrimdışı  ·  İnternet izni yok  ·  Reklam yok',
    },
}


def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def fit(draw, text, name, size, max_w):
    """Largest size <= size so that text fits max_w."""
    while size > 10:
        f = font(name, size)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 1
    return font(name, size)


def render(lang):
    ss = 2
    img = Image.new('RGB', (W * ss, H * ss), icon.BG)
    d = ImageDraw.Draw(img)
    # Soft diagonal band in the display colour for depth (flat, no gradients).
    d.polygon([(560 * ss, 0), (W * ss, 0), (W * ss, H * ss), (380 * ss, H * ss)], fill='#132D44')

    # Icon: the store icon artwork with rounded corners, left, vertically centred.
    size = 300
    art = icon.render(size * ss, 'square')          # RGBA with rounded-square alpha
    img.paste(art, (80 * ss, (H - size) // 2 * ss), art)

    t = TEXT[lang]
    x0, max_w = 430 * ss, (W - 430 - 60) * ss
    y = 120 * ss
    title_f = font('Roboto-Bold.ttf', 72 * ss)
    d.text((x0, y), 'GizliAlan', font=title_f, fill='#FFFFFF')
    y += 88 * ss
    sub_f = fit(d, t['subtitle'], 'Roboto-Medium.ttf', 44 * ss, max_w)
    d.text((x0, y), t['subtitle'], font=sub_f, fill=icon.EQ_KEY)
    y += 66 * ss
    body_f = min((fit(d, line, 'Roboto-Regular.ttf', 26 * ss, max_w) for line in t['body']),
                 key=lambda f: f.size)
    for line in t['body']:
        d.text((x0, y), line, font=body_f, fill=icon.BODY)
        y += int(body_f.size * 1.3)
    y += 14 * ss
    foot_f = fit(d, t['foot'], 'Roboto-Regular.ttf', 20 * ss, max_w)
    d.text((x0, y), t['foot'], font=foot_f, fill=icon.KEY)

    return img.resize((W, H), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    for lang in TEXT:
        path = os.path.join(OUT, f'feature_graphic_{lang}.png')
        im = render(lang)
        assert im.size == (W, H) and im.mode == 'RGB'
        im.save(path, optimize=True)
        print('wrote', os.path.relpath(path, ROOT), im.size, im.mode)


if __name__ == '__main__':
    main()
