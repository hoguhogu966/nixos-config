{
  config,
  lib,
  username,
  pkgs,
  ...
}:
# Self-hosted atuin sync server as a launchd user agent (darwin only).
# Listens on the loopback only; expose it to the tailnet with
#   tailscale serve --bg http://127.0.0.1:<port>
# which serves a tailscale-managed TLS URL.
let
  cfg = config.services.atuin-server;
  dataDir = "/Users/${username}/.local/share/atuin";
in
{
  options.services.atuin-server = {
    enable = lib.mkEnableOption "atuin sync server (launchd user agent, darwin only)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind. Keep the loopback so only tailscale serve can reach it.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10002;
      description = ''
        Port to listen on. Override per host so the daemon never fights
        another service for the same port (e.g. another tool bound to 8888).
      '';
    };

    openRegistration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Keep open only while registering the first account, then set to false.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # User agent (gui domain), not a system daemon: launchd fails to open
    # stdio at root-only paths like /var/log for user jobs and the service
    # dies instantly with EX_CONFIG (verified 2026-11-19).
    launchd.user.agents.atuin = {
      script = ''
        mkdir -p "${dataDir}"
        exec ${lib.getExe' pkgs.atuin "atuin-server"} start
      '';
      environment = {
        ATUIN_HOST = cfg.host;
        ATUIN_PORT = toString cfg.port;
        ATUIN_CONFIG_DIR = dataDir;
        ATUIN_DB_URI = "sqlite://${dataDir}/server.db";
        # tailscale serve proxies from loopback; log real client addresses.
        ATUIN_TRUSTED_PROXIES = "127.0.0.1";
        ATUIN_OPEN_REGISTRATION =
          if cfg.openRegistration then "true" else "false";
      };
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        StandardOutPath = "/Users/${username}/Library/Logs/atuin.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/atuin.log";
      };
    };
  };
}
