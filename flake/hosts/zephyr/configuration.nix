{ lib, username, self, pkgs, inputs, ... }:
{
  imports = [
    ./brew.nix
    ../../../modules/cachix
    ../../../modules/sops
    ../../../modules/services/atuin
  ];

  environment.systemPackages = with pkgs; [
    vim
  ];

  # Self-hosted atuin sync server; see modules/services/atuin.
  services.atuin-server.enable = true;

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
