# RustXNG — self-hosted metasearch engine (Rust, SearXNG-compatible).
# Runs from the published image with the Japanese-default settings layer
# from the startpage-rustxng-ja checkout. NOTE: the old standalone
# container (`docker run`, name "rustxng") must be removed once before
# the compose project can take over the container name:
#   docker rm -f rustxng
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "rustxng";
      compose = {
        services.rustxng = {
          image = "ghcr.io/sahenjp/rustxng:latest";
          container_name = "rustxng";
          restart = "unless-stopped";
          ports = [ "127.0.0.1:29483:29483" ];
          volumes = [
            "${config.home.homeDirectory}/src/gitea/startpage-rustxng-ja/config/rustxng-settings.toml:/app/config/rustxng-settings.toml"
          ];
        };
      };
    })
  ];
}
