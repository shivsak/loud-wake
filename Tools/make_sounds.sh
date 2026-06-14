#!/bin/bash
# Generate WAV alarm tones and convert them to .caf (preferred by AlarmKit / AVAudioPlayer).
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS="$DIR/../Sources/Resources/Sounds"

python3 "$DIR/make_sounds.py"

for f in "$SOUNDS"/*.wav; do
  base="${f%.wav}"
  afconvert -f caff -d LEI16@44100 -c 1 "$f" "$base.caf"
  echo "converted $(basename "$base").caf"
done
