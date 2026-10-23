#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

exec docker compose \
  -p cv-harbor \
  -f "$project_dir/.secrets/harbor/runtime/harbor/docker-compose.yml" \
  -f "$project_dir/infra/harbor/compose.override.yaml" \
  "$@"
