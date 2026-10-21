#!/usr/bin/env bash
set -euo pipefail

cd /mnt/f/Devops_Lab
mkdir -p .artifacts
exec >> .artifacts/startup.log 2>&1

echo "=== Lab startup: $(date -Is) ==="

docker_ready=false

for ((attempt=1; attempt<=30; attempt++)); do
    if timeout 5s docker info >/dev/null 2>.artifacts/docker-startup-error.log; then
        docker_ready=true
        break
    fi
    sleep 5
done

if [[ "$docker_ready" != true ]]; then
    echo "ERROR: Docker was not ready within 5 minutes."
    exit 1
fi

docker compose -f compose.yaml -f compose.monitoring.yaml \
    up -d --force-recreate --no-build --pull never \
    --wait --wait-timeout 120

echo "Compose startup completed: $(date -Is)"

exec sleep infinity
