#!/bin/sh
set -eu

: "${CI_PROJECT_DIR:?Missing CI_PROJECT_DIR}"
: "${CI_COMMIT_SHA:?Missing CI_COMMIT_SHA}"
: "${BUILD_TARGET:?Missing BUILD_TARGET}"
: "${HARBOR_DOCKER_AUTH:?Missing scoped File variable}"

case "$BUILD_TARGET" in
  runtime)
    repository='harbor.cv.test:8443/cv/portfolio'
    ;;
  gateway)
    repository='harbor.cv.test:8443/cv/gateway'
    ;;
  *)
    echo 'ERROR: unsupported BUILD_TARGET'
    exit 1
    ;;
esac

source="$CI_PROJECT_DIR/.artifacts/ci/images/$BUILD_TARGET"
output="$CI_PROJECT_DIR/.artifacts/ci/security/$BUILD_TARGET"

mkdir -p "$output"

test -s "$source/pinned-image.txt"
test -s "$source/digest.txt"
test -s "$source/metadata.json"
test -s "$HARBOR_DOCKER_AUTH"
test -s /etc/ci-ca/ca.crt

printf '%s\n' "$CI_COMMIT_SHA" |
  grep -Eq '^[0-9a-f]{40}$'

pinned_image=$(cat "$source/pinned-image.txt")

case "$pinned_image" in
  "$repository"@sha256:*)
    ;;
  *)
    echo 'ERROR: unexpected image repository'
    exit 1
    ;;
esac

digest=${pinned_image#"$repository"@}

printf '%s\n' "$digest" |
  grep -Eq '^sha256:[0-9a-f]{64}$'

test "$(cat "$source/digest.txt")" = "$digest"

grep -Fq "\"commit\":\"$CI_COMMIT_SHA\"" \
  "$source/metadata.json"

grep -Fq "\"pinned_image\":\"$pinned_image\"" \
  "$source/metadata.json"

cp "$source/metadata.json" "$output/build-metadata.json"

private_dir=$(mktemp -d)
trap 'rm -rf "$private_dir"' EXIT

export DOCKER_CONFIG="$private_dir/docker"
export SSL_CERT_FILE="$private_dir/ca-bundle.crt"
export TRIVY_CACHE_DIR="$CI_PROJECT_DIR/.artifacts/ci/trivy-cache"

mkdir -p "$DOCKER_CONFIG"

(
  umask 077
  cp "$HARBOR_DOCKER_AUTH" "$DOCKER_CONFIG/config.json"
)

cat /etc/ssl/certs/ca-certificates.crt \
  /etc/ci-ca/ca.crt > "$SSL_CERT_FILE"

trivy --version > "$output/scanner.txt"

# Scan once, retaining every severity and the package inventory.
trivy image \
  --image-src remote \
  --scanners vuln \
  --ignorefile /dev/null \
  --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL \
  --list-all-pkgs \
  --exit-code 0 \
  --exit-on-eol 1 \
  --timeout 10m \
  --no-progress \
  --format json \
  --output "$output/vulnerabilities.json" \
  "$pinned_image"

test -s "$output/vulnerabilities.json"

# Generate SBOM from the same scan result.
trivy convert \
  --format spdx-json \
  --ignorefile /dev/null \
  --output "$output/sbom.spdx.json" \
  "$output/vulnerabilities.json"

test -s "$output/sbom.spdx.json"

# Apply the release policy after preserving reports.
gate_status=0

trivy convert \
  --format table \
  --scanners vuln \
  --ignorefile /dev/null \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --output "$output/policy.txt" \
  "$output/vulnerabilities.json" || gate_status=$?

if test -f "$output/policy.txt"; then
  cat "$output/policy.txt"
fi

if test "$gate_status" -ne 0; then
  echo "FAIL: security gate for $BUILD_TARGET (exit $gate_status)"
  exit "$gate_status"
fi

printf '%s\n' "$pinned_image" > "$output/approved-image.txt"

echo "PASS: security gate for $BUILD_TARGET; HIGH=0, CRITICAL=0"
