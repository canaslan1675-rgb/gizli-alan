Fonts used only by `test/store_screenshots_test.dart` (store screenshot generator, #6).
They are not bundled in the app.

- `NotoSansCJK-circled-i-subset.otf`: 1-glyph subset (U+24D8 "ⓘ") of Noto Sans CJK
  (© Google / Adobe, SIL Open Font License 1.1), made with
  `pyftsubset NotoSansCJK-Regular.ttc --font-number=0 --unicodes=U+24D8`.
- `Roboto-Regular-circled-i.ttf`: Flutter's Roboto Regular (© Google, Apache License 2.0)
  with that "ⓘ" glyph added by `tool/patch_roboto_circled_i.py`. The widget-test engine has
  no system font fallback; on phones Android renders "ⓘ" with its own Noto fonts.
