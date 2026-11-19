# Jellyfin — media server. It reads the samba share read-only and gets
# PUID/PGID/TZ from ~/src/tool/madia_server/.env via --env-file.
# Project name stays "madia_server" to reuse the existing containers.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "madia_server";
      envFile = "${config.home.homeDirectory}/src/tool/madia_server/.env";
      # Created before `up` so docker never owns it as root; the ${PUID} user
      # needs write access for the transcode cache.
      preDirs = [ "${config.home.homeDirectory}/src/tool/madia_server/cache" ];
      compose = {
        services.jellyfin = {
          image = "jellyfin/jellyfin:12.2";
          container_name = "jellyfin";
          restart = "unless-stopped";
          security_opt = [ "no-new-privileges:true" ];
          cap_drop = [ "ALL" ];
          environment = {
            # Set with user instead: the official image does not honor
            # PUID/PGID environment variables.
            TZ = "\${TZ}";
          };
          user = "\${PUID}:\${PGID}";
          volumes = [
            "${config.home.homeDirectory}/src/tool/madia_server/config/jellyfin:/config"
            # Persistent transcode cache; writable by the configured user
            # (an image-owned anonymous volume would stay root-owned).
            "${config.home.homeDirectory}/src/tool/madia_server/cache:/cache"
            "${config.home.homeDirectory}/src/tool/madia_server/media:/media"
            "${config.home.homeDirectory}/src/tool/samba/data:/samba:ro"
          ];
          ports = [ "8096:8096" ];
        };
      };
    })
  ];
}
