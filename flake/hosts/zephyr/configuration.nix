{ lib, username, self, pkgs, inputs, ... }:
{
  imports = [
    ./brew.nix
    ../../../modules/cachix
    ../../../modules/sops
  ];

  environment.systemPackages = with pkgs; [
    vim
  ];

  # Self-hosted atuin sync server.
  # Listens on 127.0.0.1:8888 only; expose it to the tailnet with
  #   tailscale serve --bg http://127.0.0.1:8888
  # which serves https://zephyr.tail32a8e5.ts.net (tailscale-managed TLS).
  launchd.daemons.atuin =
    let
      dataDir = "/Users/${username}/.local/share/atuin";
    in
    {
      script = ''
        mkdir -p "${dataDir}"
        exec ${lib.getExe' pkgs.atuin "atuin-server"} start
      '';
      environment = {
        ATUIN_HOST = "127.0.0.1";
        ATUIN_PORT = "8888";
        ATUIN_CONFIG_DIR = dataDir;
        ATUIN_DB_URI = "sqlite://${dataDir}/server.db";
        # tailscale serve proxies from loopback; log real client addresses.
        ATUIN_TRUSTED_PROXIES = "127.0.0.1";
        # Keep open only while registering the first account, then set to "false".
        ATUIN_OPEN_REGISTRATION = "true";
      };
      serviceConfig = {
        UserName = username;
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        StandardOutPath = "/var/log/atuin.log";
        StandardErrorPath = "/var/log/atuin.log";
      };
    };

  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = username;
  nixpkgs.config.allowUnfree = true;

  users.users.${username} = {
    name = "${username}";
    home = "/Users/${username}";
  };
}
