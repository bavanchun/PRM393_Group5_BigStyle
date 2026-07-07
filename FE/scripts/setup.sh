#!/usr/bin/env bash
# BigStyle FE - one-shot dev setup.
# Creates .env from .env.example (if missing) and fetches Flutter deps.
# Run from the FE directory: bash scripts/setup.sh
set -euo pipefail

# Resolve FE root (parent of this scripts/ dir) so it works from anywhere.
FE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$FE_DIR"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "[setup] Created .env from .env.example"
  echo "[setup] ACTION REQUIRED: open .env and fill in the values (Supabase keys, Google client ID, etc.)"
else
  echo "[setup] .env already exists — leaving it untouched"
fi

echo "[setup] Running flutter pub get..."
flutter pub get

echo "[setup] Done. Next: fill .env if needed, then 'flutter run'."
