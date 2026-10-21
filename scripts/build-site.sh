#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir/app"
export ASTRO_TELEMETRY_DISABLED=1
npm ci --no-audit --no-fund
npm run build
npm test
