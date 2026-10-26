#!/usr/bin/env bash
set -euo pipefail

cd /mnt/f/Devops_Lab
mkdir -p .artifacts
exec >> .artifacts/startup.log 2>&1

echo "=== Lab startup: $(date -Is) ==="

trap 'echo "ERROR: startup failed at line $LINENO; keeping WSL alive for diagnosis"; exec sleep infinity' ERR

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
    echo "ERROR: Docker did not become ready; keeping WSL alive."
    exec sleep infinity
fi

echo "Starting monitoring and Compose fallback..."
docker compose -f compose.yaml -f compose.monitoring.yaml \
    up -d --force-recreate --no-build --pull never \
    --wait --wait-timeout 120

echo "Starting CV Harbor..."
bash scripts/harbor.sh up -d --pull never \
    --wait --wait-timeout 240

echo "Starting Kubernetes cv-runtime..."
/usr/local/bin/k3d cluster start cv-runtime \
    --wait --timeout 180s

kcv() {
    /usr/local/bin/kubectl \
        --kubeconfig /mnt/f/Devops_Lab/.secrets/kubeconfig-cv-runtime.yaml \
        --context k3d-cv-runtime "$@"
}

echo "Waiting for Kubernetes API readiness..."
api_ready=false

for ((attempt=1; attempt<=60; attempt++)); do
    if kcv --request-timeout=5s get --raw=/readyz \
        >.artifacts/kubernetes-readyz.log 2>&1; then
        api_ready=true
        break
    fi
    sleep 3
done

if [[ "$api_ready" != true ]]; then
    echo "ERROR: Kubernetes API did not become ready."
    false
fi

echo "Waiting for node readiness..."
kcv wait --for=condition=Ready \
    node/k3d-cv-runtime-server-0 --timeout=180s

echo "Waiting for Traefik..."
kcv -n kube-system rollout status \
    deployment/traefik --timeout=180s

echo "Waiting for CV application..."
kcv -n cv-production rollout status \
    deployment/cv --timeout=180s
echo "Checking CV HTTP endpoint..."
curl --retry 10 --retry-connrefused --retry-delay 1 \
    --connect-timeout 3 --max-time 10 \
    -fsS -H 'Host: khimkum.xyz' \
    http://127.0.0.1:18082/healthz

echo
echo "Lab startup completed: $(date -Is)"

exec sleep infinity
