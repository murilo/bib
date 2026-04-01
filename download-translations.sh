#!/usr/bin/env bash
set -euo pipefail

# Download all Bible translations from bolls.life API
# Each chapter saved as data/{TRANSLATION}/{bookId}/{chapter}.json

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/data"
API="https://bolls.life/get-chapter"

# All translations needed
TRANSLATIONS=(NTLH NVT NAA ACF11 ARC09 KJA)

# Book chapters (bookId 1-66, standard Protestant canon)
CHAPTERS=(50 40 27 36 34 24 21 4 31 25 36 22 66 36 35 28 33 42 150 31 12 8 22 66 52 5 48 12 14 3 9 1 4 7 3 3 3 2 14 4 28 16 24 21 28 16 16 13 6 6 4 4 5 3 6 4 3 1 13 5 5 3 5 1 1 22)

for trans in "${TRANSLATIONS[@]}"; do
  echo "=== Downloading $trans ==="
  for bookId in $(seq 1 66); do
    idx=$((bookId - 1))
    numCh=${CHAPTERS[$idx]}
    mkdir -p "$BASE_DIR/$trans/$bookId"
    for ch in $(seq 1 "$numCh"); do
      outFile="$BASE_DIR/$trans/$bookId/$ch.json"
      if [ -f "$outFile" ] && [ -s "$outFile" ]; then
        continue  # already downloaded
      fi
      curl -sf "$API/$trans/$bookId/$ch/" -o "$outFile" || echo "FAIL: $trans/$bookId/$ch"
      sleep 0.15  # be nice to the API
    done
    echo "  $trans book $bookId/$66 done ($numCh chapters)"
  done
  total=$(find "$BASE_DIR/$trans" -name "*.json" | wc -l)
  echo "=== $trans complete: $total chapters ==="
done

echo "All done!"
