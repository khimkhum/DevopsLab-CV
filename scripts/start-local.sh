#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
command -v docker >/dev/null || { printf 'Docker CLI is missing. Enable Docker Desktop integration for Ubuntu.\n' >&2; exit 1; }
docker info >/dev/null
docker compose up -d --build --wait
printf 'CV: http://localhost:8080\n'
printf 'Release: http://localhost:8080/version.json\n'
