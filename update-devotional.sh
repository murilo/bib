#!/bin/bash
# Update devotional image and text for bib.muitos.com
set -euo pipefail

BIB_DIR="/home/mh/sites/muitos/bib"
DEV_DIR="$BIB_DIR/devotional"
CRON_DATA="/home/mh/spok/workspace/crons/data/devotional"
PREGEN_DIR="$CRON_DATA/pregenerated"

mkdir -p "$DEV_DIR"
mkdir -p "$DEV_DIR/state"

TODAY=$(TZ=America/Sao_Paulo date +%Y-%m-%d)
MONTH=$(echo "$TODAY" | cut -d- -f1-2)
DAY=$(echo "$TODAY" | cut -d- -f3)

# Find today's image — pregenerated is primary
IMG=""

# 1. Pregenerated (primary — written by devotional-pregenerate-images.sh)
if [ -f "$PREGEN_DIR/${TODAY}.png" ]; then
  IMG="$PREGEN_DIR/${TODAY}.png"
fi

# 2. Spok media outbound (fallback — manual sends)
if [ -z "$IMG" ]; then
  IMG=$(ls -t /home/mh/spok/media/2026-*/${TODAY}*.png 2>/dev/null | head -1)
  [ -n "$IMG" ] && echo "Using spok media fallback: $IMG"
fi

if [ -z "$IMG" ]; then
  echo "ERROR: No devotional image found for $TODAY"
  exit 1
fi

# Copy source and convert to optimized JPEG
cp "$IMG" "$DEV_DIR/source.png"
ffmpeg -y -i "$DEV_DIR/source.png" -q:v 2 -vf "scale='min(800,iw)':'-1'" "$DEV_DIR/today.jpg" 2>/dev/null
echo "Image: $IMG -> $DEV_DIR/today.jpg"

# Build JSON from cron data
DATA_FILE="$CRON_DATA/$MONTH/$DAY.json"
if [ -f "$DATA_FILE" ]; then
  python3 -c "
import json
with open('$DATA_FILE') as f:
    d = json.load(f)
text = f\"📖 {d['verse_ref']}\n\\\"{d['verse_text']}\\\"\n\n✝️ {d['gospel_ref']}\n\\\"{d['gospel_text']}\\\"\n\n{d['reflection']}\"
out = {'date': '$TODAY', 'image': 'devotional/today.jpg', 'text': text, 'updated_at': '$TODAY'}
with open('$DEV_DIR/today.json', 'w') as f:
    json.dump(out, f, ensure_ascii=False)
print('JSON written')
"
else
  echo "WARNING: No cron data at $DATA_FILE"
  echo "{\"date\":\"$TODAY\",\"image\":\"devotional/today.jpg\",\"text\":\"\",\"updated_at\":\"$TODAY\"}" > "$DEV_DIR/today.json"
fi

TZ=America/Sao_Paulo date '+%Y-%m-%d %H:%M:%S %Z' > "$DEV_DIR/state/last-updated.txt"
cp "$DEV_DIR/state/last-updated.txt" "$DEV_DIR/last-updated.txt"
echo "Done: $TODAY"
