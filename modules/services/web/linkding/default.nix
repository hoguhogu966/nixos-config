# linkding — bookmark manager. Secrets come from ~/src/tool/linkding/.env
# (DISCORD-less: LINKDING_SECRET etc.), passed via env_file.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "linkding";
      compose = {
        services.linkding = {
          image = "sissbruecker/linkding:latest";
          container_name = "linkding";
          restart = "unless-stopped";
          ports = [ "127.0.0.1:9090:9090" ];
          volumes = [
            "${config.home.homeDirectory}/src/tool/linkding/data:/etc/linkding/data"
          ];
          env_file = [
            "${config.home.homeDirectory}/src/tool/linkding/.env"
          ];
        };
      };
    })
  ];
}
