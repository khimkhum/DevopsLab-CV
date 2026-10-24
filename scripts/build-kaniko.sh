#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

target="${1:-runtime}"
case "$target" in
  runtime) repository=portfolio ;;
  gateway) repository=gateway ;;
  *) echo "Usage: bash scripts/build-kaniko.sh runtime|gateway" >&2; exit 1 ;;
esac

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Commit các thay đổi trước: builder lấy source từ git archive HEAD." >&2
  exit 1
fi

for file in .secrets/kaniko/config.json .secrets/harbor/ca.crt; do
  [[ -s "$file" ]] || { echo "Missing file: $file" >&2; exit 1; }
done

revision="$(git rev-parse HEAD)"
context="$project_dir/.artifacts/kaniko/context-$revision"
output="$project_dir/.artifacts/kaniko/$target-$revision"
destination="harbor.cv.test:8443/cv/$repository:kaniko-$revision"
executor="ghcr.io/osscontainertools/kaniko:v1.28.6@sha256:2fa20b0a4b40c7db72b479d57e55c2cf79f2178533b2d3bcbd129d6bd3c087ed"

mkdir -p "$context" "$output"
git archive HEAD | tar -x -C "$context"

docker run --rm \
  --network cv-harbor-net \
  --memory 2g \
  --cpus 2 \
  --pids-limit 256 \
  --security-opt no-new-privileges:true \
  --mount "type=bind,src=$context,dst=/workspace,readonly" \
  --mount "type=bind,src=$project_dir/.secrets/kaniko/config.json,dst=/kaniko/.docker/config.json,readonly" \
  --mount "type=bind,src=$project_dir/.secrets/harbor/ca.crt,dst=/kaniko/harbor-ca.crt,readonly" \
  --mount "type=bind,src=$output,dst=/kaniko/out" \
  "$executor" \
  --context=dir:///workspace \
  --dockerfile=/workspace/Dockerfile \
  --target="$target" \
  --build-arg="APP_REVISION=$revision" \
  --destination="$destination" \
  --registry-certificate=harbor.cv.test:8443=/kaniko/harbor-ca.crt \
  --cache=false \
  --digest-file=/kaniko/out/digest.txt \
  2>&1 | tee "$output/build.log"

printf '\nTarget: %s\nImage: %s\nDigest: ' "$target" "$destination"
cat "$output/digest.txt"
printf '\n'
