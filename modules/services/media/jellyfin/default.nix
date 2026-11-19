# Jellyfin — media server. It reads the samba share read-only and gets
# PUID/PGID/TZ from ~/src/tool/madia_server/.env via --env-file.
# Project name stays "madia_server" to reuse the existing containers.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "madia_server";
      envFile = "${config.home.homeDirectory}/src/tool/madia_server/.env";
      compose = {
        services.jellyfin = {
          image = "jellyfin/jellyfin:12.2";
          container_name = "jellyfin";
          restart = "unless-stopped";
          security_opt = [ "no-new-privileges:true" ];
          cap_drop = [ "ALL" ];
          environment = {
            PUID = "\${PUID}";
            PGID = "\${PGID}";
            TZ = "\${TZ}";
          };
          volumes = [
            "${config.home.homeDirectory}/src/tool/madia_server/config/jellyfin:/config"
            "${config.home.homeDirectory}/src/tool/madia_server/media:/media"
            "${config.home.homeDirectory}/src/tool/samba/data:/samba:ro"
          ];
          ports = [ "8096:8096" ];
        };
      };
    })
  ];
}
