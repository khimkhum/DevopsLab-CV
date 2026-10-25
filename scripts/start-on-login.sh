#!/usr/bin/env bash
set -euo pipefail

cd /mnt/f/Devops_Lab
mkdir -p .artifacts
exec >> .artifacts/startup.log 2>&1

echo "=== Lab startup: $(date -Is) ==="

docker_ready=false

for ((attempt=1; attempt<=30; attempt++)); do
    if timeout 5s docker info \
        >/dev/null 2>.artifacts/docker-startup-error.log; then
        docker_ready=true
        break
    fi
    sleep 5
done

if [[ "$docker_ready" != true ]]; then
    echo "ERROR: Docker did not become ready."
    exit 1
fi

echo "Starting CV Harbor..."
bash scripts/harbor.sh up -d --pull never \
    --wait --wait-timeout 240

echo "Starting Kubernetes cv-lab..."
/usr/local/bin/k3d cluster start cv-lab \
    --wait --timeout 180s

/usr/local/bin/kubectl \
    --kubeconfig /mnt/f/Devops_Lab/.secrets/kubeconfig-cv-lab.yaml \
    --context k3d-cv-lab \
    -n cv-production rollout status deployment/cv \
    --timeout=180s

echo "Starting monitoring and Compose fallback..."
docker compose -f compose.yaml -f compose.monitoring.yaml \
    up -d --force-recreate --no-build --pull never \
    --wait --wait-timeout 120

curl --retry 10 --retry-connrefused --retry-delay 1 \
    --connect-timeout 3 --max-time 10 \
    -fsS -H 'Host: khimkum.xyz' \
    http://127.0.0.1:18081/healthz

echo
echo "Lab startup completed: $(date -Is)"

exec sleep infinity
