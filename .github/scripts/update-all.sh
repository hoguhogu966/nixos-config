#!/usr/bin/env bash
# Update every pinned custom package under pkgs/.
#
# A single package failing to update must not block the rest: each step runs
# in isolation and its files are reverted on failure, so the pull request
# only ever contains packages that updated cleanly. Failed packages are
# reported through UPDATE_FAILURES for the pull-request step.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

failed=()

run_update() {
  local name=$1 files=$2
  shift 2
  if "$@"; then
    echo "${name} updated or already current"
  else
    local status=$?
    echo "::warning::${name} failed to update (exit ${status}); reverting ${files}"
    # shellcheck disable=SC2086
    git checkout -- ${files}
    failed+=("${name}")
  fi
}

run_update rea pkgs/rea.nix .github/scripts/update-rea.sh
run_update rea pkgs/rea.nix nix-update --file pkgs/update-targets.nix --override-filename pkgs/rea.nix --no-src --version skip rea

# buzz-sidecars is passed into buzz-desktop's derivation, so buzz-desktop's
# lockfile extraction build also builds buzz-sidecars. Updating the sidecars
# first keeps the version injected into the desktop build in sync with its
# source revision.
run_update buzz 'pkgs/buzz-sidecars.nix pkgs/buzz-desktop.nix' .github/scripts/update-buzz.sh

run_update cloudflared pkgs/cloudflared.nix nix-update --file pkgs/update-targets.nix --override-filename pkgs/cloudflared.nix cloudflared
run_update effectcraft pkgs/effectcraft.nix nix-update --file pkgs/update-targets.nix --override-filename pkgs/effectcraft.nix effectcraft
run_update ink pkgs/ink.nix nix-update --file pkgs/update-targets.nix --override-filename pkgs/ink.nix ink

# Ollama vendors llama.cpp server builds; update-ollama.sh keeps the pinned
# llamaCppVersion/llamaCppSrc in sync with the release before nix-update
# refreshes the source and vendor hashes.
run_update ollama pkgs/ollama.nix .github/scripts/update-ollama.sh

run_update omniwm pkgs/omniwm.nix .github/scripts/update-omniwm.sh
run_update souieba pkgs/souieba.nix nix-update --file pkgs/update-targets.nix --override-filename pkgs/souieba.nix souieba

# herdr-app and herdr-core release together from https://releases.herdr.dev;
# update-herdr.sh keeps both in sync from the same manifests.
run_update herdr 'pkgs/herdr-app.nix pkgs/herdr-core.nix' .github/scripts/update-herdr.sh

if [ ${#failed[@]} -gt 0 ]; then
  echo "UPDATE_FAILURES=${failed[*]}" >> "${GITHUB_ENV:-/dev/null}"
  echo "::warning::failed package updates: ${failed[*]}"
else
  echo "All package updates completed"
fi
