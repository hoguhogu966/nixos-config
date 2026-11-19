#!/usr/bin/env bash
# Updates herdr-app and herdr-core from their release manifests.
#
# Both publish a latest.json manifest at https://releases.herdr.dev with the
# version, download url and sha256 per platform. The app manifest also pins
# core_min, and both components update in the same run, so the core stays new
# enough for the app.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

releases=${HERDR_RELEASES_URL:-https://releases.herdr.dev}

update_component() {
  local attr=$1 file=$2 channel=$3
  local latest current newest

  latest=$(curl -fsSL "$releases/$channel/latest.json" | jq -r '.version')
  current=$(sed -n 's/^  version = "\([^"]*\)";$/\1/p' "$file")
  if [ -z "$latest" ] || [ -z "$current" ]; then
    echo "Could not determine the latest or current $attr version" >&2
    return 1
  fi

  if [ "$current" = "$latest" ]; then
    echo "$attr is already at the latest version ($current)"
    return 0
  fi

  newest=$(printf '%s\n' "$current" "$latest" | sort -V | tail -n1)
  if [ "$newest" != "$latest" ]; then
    echo "Refusing to downgrade $attr from $current to $latest"
    return 0
  fi

  nix-update --file pkgs/update-targets.nix --override-filename "$file" \
    --version "$latest" --src-only "$attr"
}

update_component herdr-app pkgs/herdr-app.nix app
update_component herdr-core pkgs/herdr-core.nix core
