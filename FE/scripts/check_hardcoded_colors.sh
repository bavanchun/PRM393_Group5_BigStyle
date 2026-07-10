#!/bin/bash
# Hardcode guard — flags Colors.* / 8-digit-hex / legacy-font literals in
# lib/screens + lib/widgets. Anchored to the script location so it cannot
# silently scan nothing from the wrong CWD (fails hard instead).
cd "$(dirname "$0")/.." || exit 2
for d in lib/screens lib/widgets; do
  [ -d "$d" ] || { echo "ERROR: $d not found — wrong checkout?"; exit 2; }
done
hits=$(grep -rnoE --include="*.dart" \
  '(^|[^A-Za-z])Colors\.[A-Za-z0-9]+|0x[0-9A-Fa-f]{8}|GoogleFonts\.(playfairDisplay|dmSans)' \
  lib/screens lib/widgets | grep -v 'Colors\.transparent')
if [ -n "$hits" ]; then
  echo "Hardcoded colors/legacy fonts found outside theme files:"
  echo "$hits"
  echo "occurrences: $(echo "$hits" | wc -l | tr -d ' ')"
  exit 1
fi
exit 0
