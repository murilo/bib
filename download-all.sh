#!/usr/bin/env bash
set -eo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/data"
API="https://bolls.life/get-chapter"

# Book ID → number of chapters (1-66)
declare -A BOOK_CHAPTERS=(
[1]=50 [2]=40 [3]=27 [4]=36 [5]=34 [6]=24 [7]=21 [8]=4 [9]=31 [10]=25
[11]=36 [12]=22 [13]=29 [14]=36 [15]=10 [16]=13 [17]=10 [18]=42 [19]=150 [20]=31
[21]=12 [22]=8 [23]=22 [24]=66 [25]=52 [26]=5 [27]=48 [28]=12 [29]=14 [30]=3
[31]=9 [32]=1 [33]=4 [34]=7 [35]=3 [36]=3 [37]=3 [38]=2 [39]=14 [40]=4
[41]=28 [42]=16 [43]=24 [44]=21 [45]=28 [46]=16 [47]=16 [48]=13 [49]=6 [50]=6
[51]=4 [52]=4 [53]=5 [54]=3 [55]=6 [56]=4 [57]=3 [58]=1 [59]=13 [60]=5
[61]=5 [62]=3 [63]=5 [64]=1 [65]=1 [66]=22
)

TRANSLATIONS=(NTLH NVT NAA ACF11 ARC09 KJA)

for trans in "${TRANSLATIONS[@]}"; do
  echo "=== $trans ==="
  for bookId in $(seq 1 66); do
    numCh=${BOOK_CHAPTERS[$bookId]}
    mkdir -p "$BASE_DIR/$trans/$bookId"
    for ch in $(seq 1 "$numCh"); do
      out="$BASE_DIR/$trans/$bookId/$ch.json"
      [ -f "$out" ] && [ -s "$out" ] && continue
      curl -sf "$API/$trans/$bookId/$ch/" -o "$out" 2>/dev/null || echo "FAIL $trans/$bookId/$ch"
      sleep 0.1
    done
  done
  count=$(find "$BASE_DIR/$trans" -name "*.json" -size +0 | wc -l)
  echo "=== $trans done: $count chapters ==="
done
echo "ALL DONE"
