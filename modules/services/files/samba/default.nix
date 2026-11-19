# Samba — SMB file server (share root: ~/src/tool/samba/data). Also
# mounted read-only by the Jellyfin container.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "samba";
      compose = {
        services.samba = {
          image = "ghcr.io/ensody/samba:latest";
          container_name = "samba";
          restart = "unless-stopped";
          ports = [ "445:445" ];
          volumes = [
            "${config.home.homeDirectory}/src/tool/samba/data:/data/share"
            "${config.home.homeDirectory}/src/tool/samba/conf:/conf"
            "${config.home.homeDirectory}/src/tool/samba/state:/var/lib/samba"
          ];
        };
      };
    })
  ];
}
