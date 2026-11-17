#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

latest_version=$(
  gh api --paginate 'repos/ollama/ollama/releases?per_page=100' \
    --jq '.[] | select(.prerelease == false) | .tag_name' \
    | sed -n 's/^v//p' \
    | grep -E '^[0-9]+(\.[0-9]+)*$' \
    | sort -V \
    | tail -n1
)
current_version=$(sed -n 's/^  version = "\([^"]*\)";$/\1/p' pkgs/ollama.nix)

if [ -z "$latest_version" ] || [ -z "$current_version" ]; then
  echo "Could not determine the latest or current Ollama version" >&2
  exit 1
fi

if [ "$current_version" = "$latest_version" ]; then
  echo "Ollama is already at the latest stable version ($current_version)"
  exit 0
fi

newest_version=$(printf '%s\n' "$current_version" "$latest_version" | sort -V | tail -n1)
if [ "$newest_version" != "$latest_version" ]; then
  echo "Refusing to downgrade Ollama from $current_version to $latest_version"
  exit 0
fi

# Ollama vendors llama.cpp server builds pinned by the LLAMA_CPP_VERSION file
# at the root of its source tree. The nixpkgs ollama derivation compares that
# file against the llamaCppVersion passthru and fails the build on a mismatch
# ("llama-cpp version mismatch, expected X, but found Y"), so the pinned tag
# and its hash must move together with the version before nix-update builds
# the go-modules fixed-output derivation.
llama_cpp_version=$(
  curl --fail --silent --show-error \
    "https://raw.githubusercontent.com/ollama/ollama/v${latest_version}/LLAMA_CPP_VERSION"
)
if ! grep -qE '^b[0-9]+$' <<<"$llama_cpp_version"; then
  echo "Could not read the llama.cpp version pinned by ollama v${latest_version}" >&2
  exit 1
fi

llama_cpp_hash=$(
  nix flake prefetch --json "github:ggml-org/llama.cpp/${llama_cpp_version}" \
    | jq --exit-status --raw-output .hash
)

python3 - "$llama_cpp_version" "$llama_cpp_hash" <<'PY'
from pathlib import Path
import re
import sys

llama_cpp_version, llama_cpp_hash = sys.argv[1:]
path = Path("pkgs/ollama.nix")
contents = path.read_text()

contents, count = re.subn(
    rf'(?m)^(  llamaCppVersion = ")[^"]+(";)$',
    rf'\g<1>{llama_cpp_version}\g<2>',
    contents,
    count=1,
)
if count != 1:
    raise SystemExit("Could not update the llamaCppVersion declaration")

contents, count = re.subn(
    r'(tag = llamaCppVersion;\n\s*hash = ")[^"]+(")',
    rf'\g<1>{llama_cpp_hash}\g<2>',
    contents,
    flags=re.DOTALL,
    count=1,
)
if count != 1:
    raise SystemExit("Could not update the llamaCppSrc hash")

path.write_text(contents)
PY

nix-update --file pkgs/update-targets.nix --override-filename pkgs/ollama.nix \
  --version "$latest_version" ollama
