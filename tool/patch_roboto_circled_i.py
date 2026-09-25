"""Builds test/fixtures/fonts/Roboto-Regular-circled-i.ttf for the store
screenshot generator: Flutter's Roboto-Regular + the "ⓘ" (U+24D8) glyph from
the Noto Sans CJK subset, because the widget-test engine has no system font
fallback (phones render ⓘ with Noto). Needs fontTools:
    python3 tool/patch_roboto_circled_i.py
"""
import os

from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

FLUTTER = os.environ.get("FLUTTER_ROOT", "/workspace/tools/flutter")
SRC = f"{FLUTTER}/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf"
SYM = "test/fixtures/fonts/NotoSansCJK-circled-i-subset.otf"
OUT = "test/fixtures/fonts/Roboto-Regular-circled-i.ttf"

roboto = TTFont(SRC)
sym = TTFont(SYM)
cp = 0x24D8
sym_name = sym.getBestCmap()[cp]
scale = roboto["head"].unitsPerEm / sym["head"].unitsPerEm

pen = TTGlyphPen(None)
sym.getGlyphSet()[sym_name].draw(
    TransformPen(Cu2QuPen(pen, max_err=1.0, reverse_direction=True), (scale, 0, 0, scale, 0, 0))
)
name = "uni24D8"
glyf = roboto["glyf"]
order = roboto.getGlyphOrder() + [name]
roboto.setGlyphOrder(order)
glyf.glyphOrder = order
glyf.glyphs[name] = pen.glyph()
adv, lsb = sym["hmtx"][sym_name]
roboto["hmtx"][name] = (round(adv * scale), round(lsb * scale))
for table in roboto["cmap"].tables:
    if table.isUnicode():
        table.cmap[cp] = name
roboto["maxp"].numGlyphs = len(roboto.getGlyphOrder())
roboto.save(OUT)
print("wrote", OUT)
