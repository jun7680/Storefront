#!/usr/bin/env bash
#
# SF Symbol 조합으로 임시 1024x1024 PNG 앱 아이콘을 만든 뒤,
# AppIcon.appiconset에 필요한 모든 해상도를 sips로 산출한다.
#
# 요구사항: macOS + sips + Python3 (Pillow optional)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT/Storefront/Resources/Assets.xcassets/AppIcon.appiconset"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

MASTER="$TMPDIR/icon_1024.png"

# SF Symbol → PNG (macOS 15+에서 가능한 가장 단순한 경로는 없으므로,
# 여기서는 단색 그라디언트 배경 + 텍스트 "S"를 sips/coreimage 대신 Python으로 렌더)
python3 - <<PY > "$MASTER.b64"
from __future__ import annotations
import base64, sys
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("ERROR: Pillow 필요 — pip install Pillow", file=sys.stderr)
    sys.exit(1)

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# 둥근 사각형 배경 + 그라디언트 (Sky → Orange 대각선)
grad = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * SIZE)
        r = int(0x5A * (1 - t) + 0xFF * t)
        g = int(0xA7 * (1 - t) + 0x9F * t)
        b = int(0xE6 * (1 - t) + 0x5A * t)
        grad.putpixel((x, y), (r, g, b, 255))

# 라운드 마스크
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
radius = 220
md.rounded_rectangle([(0, 0), (SIZE, SIZE)], radius=radius, fill=255)
img.paste(grad, (0, 0), mask)

# 중앙에 "S" 로고
draw = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("/System/Library/Fonts/SFCompactRounded.ttf", 620)
except OSError:
    font = ImageFont.load_default()
text = "S"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
x = (SIZE - tw) // 2 - bbox[0]
y = (SIZE - th) // 2 - bbox[1] - 20
draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

import io
buf = io.BytesIO()
img.save(buf, format="PNG")
sys.stdout.write(base64.b64encode(buf.getvalue()).decode())
PY

base64 -D < "$MASTER.b64" > "$MASTER"

declare -a SPECS=(
  "16:1x:16"
  "16:2x:32"
  "32:1x:32"
  "32:2x:64"
  "128:1x:128"
  "128:2x:256"
  "256:1x:256"
  "256:2x:512"
  "512:1x:512"
  "512:2x:1024"
)

for spec in "${SPECS[@]}"; do
  IFS=":" read -r base scale px <<< "$spec"
  out="$ICONSET/icon_${base}x${base}@${scale}.png"
  sips -z "$px" "$px" "$MASTER" --out "$out" > /dev/null
  echo "wrote $out (${px}px)"
done

# Contents.json 업데이트 (파일명 매핑)
cat > "$ICONSET/Contents.json" <<JSON
{
  "images" : [
    { "idiom": "mac", "scale": "1x", "size": "16x16", "filename": "icon_16x16@1x.png" },
    { "idiom": "mac", "scale": "2x", "size": "16x16", "filename": "icon_16x16@2x.png" },
    { "idiom": "mac", "scale": "1x", "size": "32x32", "filename": "icon_32x32@1x.png" },
    { "idiom": "mac", "scale": "2x", "size": "32x32", "filename": "icon_32x32@2x.png" },
    { "idiom": "mac", "scale": "1x", "size": "128x128", "filename": "icon_128x128@1x.png" },
    { "idiom": "mac", "scale": "2x", "size": "128x128", "filename": "icon_128x128@2x.png" },
    { "idiom": "mac", "scale": "1x", "size": "256x256", "filename": "icon_256x256@1x.png" },
    { "idiom": "mac", "scale": "2x", "size": "256x256", "filename": "icon_256x256@2x.png" },
    { "idiom": "mac", "scale": "1x", "size": "512x512", "filename": "icon_512x512@1x.png" },
    { "idiom": "mac", "scale": "2x", "size": "512x512", "filename": "icon_512x512@2x.png" }
  ],
  "info" : { "author": "xcode", "version": 1 }
}
JSON

echo "==> AppIcon.appiconset 업데이트 완료"
