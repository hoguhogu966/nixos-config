# Generate a docker-compose YAML file from a Nix attrset and register a
# launchd user agent that keeps the compose project applied: it runs
# `docker compose up -d` at login (waiting for colima's daemon to come up)
# and re-applies periodically, so a `nix` rebuild is picked up without
# restarting anything by hand. Existing containers are reused/recreated
# because the project name and container/volume names stay identical.
#
# Usage (from a service module under modules/services/<genre>/<service>/):
#   imports = [ (import ../../lib/compose.nix { name = "gitea"; compose = { ... }; }) ];
#
# settings:
#   name       compose project name (must match the one the existing
#              containers were created with)
#   compose    attrset rendered to YAML with pkgs.writers.writeYAML
#   envFile    optional absolute path passed as --env-file; needed when the
#              YAML contains ${VAR} substitutions (secrets live outside this
#              repo in ~/src/tool/<service>/.env, never in this repo)
#   interval   seconds between re-apply runs (default: 1800)
settings:

{ config, pkgs, lib, ... }:
let
  composeFile = pkgs.writers.writeYAML "docker-compose.yml" settings.compose;

  envFileArgs =
    if settings.envFile or null != null
    then [ "--env-file" settings.envFile ]
    else [ ];

  upScript = pkgs.writeShellScript "compose-${settings.name}-up" ''
    export DOCKER_HOST="''${DOCKER_HOST:-unix://$HOME/.colima/default/docker.sock}"

    # colima is started by its own launchd service at login; wait for the
    # docker daemon before applying the compose project.
    elapsed=0
    until ${pkgs.docker-client}/bin/docker info >/dev/null 2>&1; do
      if [ "$elapsed" -ge 300 ]; then
        echo "compose-${settings.name}: docker daemon unreachable, giving up" >&2
        exit 1
      fi
      sleep 5
      elapsed=$((elapsed + 5))
    done

    exec ${pkgs.docker-client}/bin/docker compose \
      --project-name ${settings.name} \
      ${lib.escapeShellArgs envFileArgs} \
      --file ${composeFile} \
      up --detach --remove-orphans
  '';
in
{
  launchd.agents."compose-${settings.name}" = {
    enable = true;
    config = {
      Program = "${upScript}";
      RunAtLoad = true;
      StartInterval = settings.interval or 1800;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/compose-${settings.name}.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/compose-${settings.name}.err.log";
    };
  };
}
