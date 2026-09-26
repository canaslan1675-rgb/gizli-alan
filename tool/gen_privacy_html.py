#!/usr/bin/env python3
"""PRIVACY.md -> docs/privacy/index.html (GitHub Pages, /docs on main).

Self-contained static page: no trackers, no external fonts/scripts/CSS.
Needs `markdown` (pip install --user markdown). Re-run after editing PRIVACY.md.
"""
import pathlib
import markdown

root = pathlib.Path(__file__).resolve().parent.parent
body = markdown.markdown(
    (root / 'PRIVACY.md').read_text(encoding='utf-8'),
    extensions=['tables'],
)
html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>GizliAlan — Privacy Policy / Gizlilik Politikası</title>
<style>
body{{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;max-width:820px;margin:0 auto;padding:24px 16px;line-height:1.55;color:#1b2430;background:#fff}}
h1,h2{{line-height:1.25}} h2{{margin-top:2em;border-bottom:1px solid #dde3ea;padding-bottom:.2em}}
table{{border-collapse:collapse;width:100%;margin:1em 0;font-size:.95em}}
th,td{{border:1px solid #cfd7e0;padding:6px 8px;text-align:left;vertical-align:top}}
code{{background:#f1f4f7;padding:1px 4px;border-radius:4px}}
blockquote{{margin:1em 0;padding:.5em 1em;border-left:4px solid #2ecc8f;background:#f4fbf8}}
</style>
</head>
<body>
{body}
</body>
</html>
"""
out = root / 'docs' / 'privacy' / 'index.html'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(html, encoding='utf-8')
print('wrote', out.relative_to(root))
