#!/bin/bash
# Build gzip-compressed Bible bundles for offline download
# Each translation gets a single .json.gz file: {bookId: {chapter: [verses...]}}

cd "$(dirname "$0")"

echo "Building Bible bundles..."
echo ""

for trans_dir in data/*/; do
  trans=$(basename "$trans_dir")
  # Skip if not a directory with book subdirs
  [[ -d "$trans_dir/1" ]] || continue
  
  echo -n "  $trans: "
  
  # Use python to combine all chapters into one JSON
  python3 -c "
import json, os, sys

trans_dir = sys.argv[1]
result = {}

for book_dir in sorted(os.listdir(trans_dir), key=lambda x: int(x) if x.isdigit() else 999):
    book_path = os.path.join(trans_dir, book_dir)
    if not os.path.isdir(book_path) or not book_dir.isdigit():
        continue
    result[book_dir] = {}
    for ch_file in sorted(os.listdir(book_path), key=lambda x: int(x.replace('.json','')) if x.endswith('.json') else 999):
        if not ch_file.endswith('.json'):
            continue
        ch_num = ch_file.replace('.json', '')
        with open(os.path.join(book_path, ch_file)) as f:
            result[book_dir][ch_num] = json.load(f)

json.dump(result, sys.stdout, ensure_ascii=False, separators=(',',':'))
" "$trans_dir" | gzip -9 > "data/${trans}.json.gz"

  # Size info
  orig_size=$(du -sb "$trans_dir" | cut -f1)
  gz_size=$(stat -c%s "data/${trans}.json.gz")
  orig_mb=$(echo "scale=1; $orig_size/1048576" | bc)
  gz_mb=$(echo "scale=1; $gz_size/1048576" | bc)
  ratio=$(echo "scale=0; 100*$gz_size/$orig_size" | bc)
  echo "${orig_mb}MB → ${gz_mb}MB (${ratio}%)"
done

echo ""
echo "Validating..."
gzip -t data/*.json.gz && echo "✅ All bundles valid!" || echo "❌ Some bundles failed validation"
echo ""
ls -lh data/*.json.gz
