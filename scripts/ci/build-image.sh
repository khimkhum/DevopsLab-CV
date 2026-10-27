#!/bin/sh
set -eu

: "${CI_PROJECT_DIR:?Missing CI_PROJECT_DIR}"
: "${CI_COMMIT_SHA:?Missing CI_COMMIT_SHA}"
: "${BUILD_TARGET:?Missing BUILD_TARGET}"
: "${HARBOR_DOCKER_AUTH:?Missing scoped File variable}"

test -s "$HARBOR_DOCKER_AUTH"
test -r /etc/ci-ca/ca.crt

case "$BUILD_TARGET" in
  runtime)
    repository="harbor.cv.test:8443/cv/portfolio"
    ;;
  gateway)
    repository="harbor.cv.test:8443/cv/gateway"
    ;;
  *)
    echo "Unsupported BUILD_TARGET"
    exit 1
    ;;
esac

tagged_image="${repository}:ci-${CI_COMMIT_SHA}"
output="${CI_PROJECT_DIR}/.artifacts/ci/images/${BUILD_TARGET}"

mkdir -p /kaniko/.docker "$output"

(
  umask 077
  cp "$HARBOR_DOCKER_AUTH" /kaniko/.docker/config.json
  chmod 600 /kaniko/.docker/config.json
)

trap 'rm -f /kaniko/.docker/config.json' EXIT

/kaniko/executor \
  --context="dir://${CI_PROJECT_DIR}" \
  --dockerfile="${CI_PROJECT_DIR}/Dockerfile" \
  --target="$BUILD_TARGET" \
  --build-arg="APP_REVISION=${CI_COMMIT_SHA}" \
  --destination="$tagged_image" \
  --registry-certificate=harbor.cv.test:8443=/etc/ci-ca/ca.crt \
  --cache=false \
  --digest-file="$output/digest.txt"

digest=$(cat "$output/digest.txt")
printf '%s\n' "$digest" |
  grep -Eq '^sha256:[0-9a-f]{64}$'

pinned_image="${repository}@${digest}"
printf '%s\n' "$pinned_image" > "$output/pinned-image.txt"

printf '{"target":"%s","commit":"%s","tagged_image":"%s","pinned_image":"%s","digest":"%s","pipeline_url":"%s"}\n' \
  "$BUILD_TARGET" \
  "$CI_COMMIT_SHA" \
  "$tagged_image" \
  "$pinned_image" \
  "$digest" \
  "$CI_PIPELINE_URL" \
  > "$output/metadata.json"

echo "PASS: image pushed"
cat "$output/pinned-image.txt"
