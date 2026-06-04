#!/usr/bin/env bash
# Install `tcli` for the current runner from the public release S3.
#
# Release layout (must match tabbify-cli/src/selfupdate.rs + CI release.yml):
#   <base>/latest             JSON manifest: {"latest":"v1.4.0", ...}
#   <base>/v<VER>/<arch>/tcli static binary, arch = x86_64 | aarch64
set -euo pipefail

# Must match the release bucket published by tabbify-cli CI (RELEASE_S3_BUCKET).
# NOTE: currently `tabbify-releases-leo`; tcli's selfupdate DEFAULT_CLI_BASE_URL
# still says `tabbify-releases` — reconcile the bucket name later. Overridable
# via TABBIFY_CLI_BASE_URL / the action's `cli-base-url` input.
BASE="${TABBIFY_CLI_BASE_URL:-https://tabbify-releases-leo.s3.eu-central-1.amazonaws.com/cli}"

case "$(uname -m)" in
  x86_64 | amd64) ARCH="x86_64" ;;
  aarch64 | arm64) ARCH="aarch64" ;;
  *) echo "tcli install: unsupported arch $(uname -m)" >&2; exit 1 ;;
esac

# Resolve the latest version from the manifest (jq if present, else grep).
MANIFEST="$(curl -fsSL "${BASE}/latest")"
if command -v jq >/dev/null 2>&1; then
  VER="$(printf '%s' "${MANIFEST}" | jq -r '.latest')"
else
  VER="$(printf '%s' "${MANIFEST}" | grep -o '"latest"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
fi
[ -n "${VER}" ] && [ "${VER}" != "null" ] || { echo "tcli install: could not read .latest from ${BASE}/latest" >&2; exit 1; }

URL="${BASE}/${VER}/${ARCH}/tcli"
DEST="${TCLI_INSTALL_DIR:-/usr/local/bin}/tcli"
echo "tcli install: ${URL} -> ${DEST}"
curl -fsSL "${URL}" -o "${DEST}"
chmod +x "${DEST}"
"${DEST}" --version
