#!/usr/bin/env bash
# Regenerates the Play Store screenshots (issue #6) by rendering the real app
# screens in a Flutter widget test with fabricated demo content.
# Output: docs/store/screenshots/{play,full}/{tr,en}/0N_*.png
# (play = Google Play build without Second phone, used for the listing) — 1080×1920, RGB, no alpha.
# No emulator/device needed; FLAG_SECURE in MainActivity is not touched.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${FLUTTER_ROOT:-/workspace/tools/flutter}/bin:$PATH"
flutter test test/store_screenshots_test.dart --dart-define=STORE_SCREENSHOTS=true
# Optional check (needs Pillow): every file must be 1080x1920 RGB.
if python3 -c 'import PIL' 2>/dev/null; then
  python3 - <<'PY'
from PIL import Image
import glob
files = sorted(glob.glob('docs/store/screenshots/*/*/*.png'))
assert len(files) == 24, files
for f in files:
    im = Image.open(f)
    assert im.size == (1080, 1920) and im.mode == 'RGB', (f, im.size, im.mode)
print('OK: 24 screenshots, 1080x1920 RGB')
PY
fi
