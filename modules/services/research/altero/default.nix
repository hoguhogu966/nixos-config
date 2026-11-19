# altero — Zotero companion server (Zotero Sync replacement; altero +
# postgres). Configuration comes from ~/src/tool/zotero/altero/.env, which
# is both handed to the container (env_file) and used for ${VAR:-default}
# substitution via --env-file.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "altero";
      envFile = "${config.home.homeDirectory}/src/tool/zotero/altero/.env";
      compose = {
        services.db = {
          image = "postgres:18-alpine";
          restart = "unless-stopped";
          environment = {
            POSTGRES_USER = "altero";
            POSTGRES_PASSWORD = "\${POSTGRES_PASSWORD:-altero}";
            POSTGRES_DB = "altero";
          };
          volumes = [ "db:/var/lib/postgresql" ];
          healthcheck = {
            test = [ "CMD-SHELL" "pg_isready -U altero" ];
            interval = "5s";
            timeout = "5s";
            retries = 10;
          };
        };

        services.altero = {
          image = "ghcr.io/eseifert/altero:\${ALTERO_IMAGE_TAG:-latest}";
          restart = "unless-stopped";
          depends_on = {
            db.condition = "service_healthy";
          };
          env_file = [
            "${config.home.homeDirectory}/src/tool/zotero/altero/.env"
          ];
          environment = {
            # Taken verbatim from .env: the password must be URL-encoded
            # here, while the db service below keeps POSTGRES_PASSWORD raw.
            ALTERO_DATABASE_URL = "\${ALTERO_DATABASE_URL}";
            ALTERO_SMTP_URL = "\${ALTERO_SMTP_URL:-}";
            ALTERO_MAIL_FROM = "\${ALTERO_MAIL_FROM:-altero@localhost}";
            ALTERO_PUBLIC_URL = "\${ALTERO_PUBLIC_URL:-}";
          };
          # Lets a host-side SMTP relay be reached via host.docker.internal.
          extra_hosts = [ "host.docker.internal:host-gateway" ];
          volumes = [ "storage:/data" ];
          ports = [ "127.0.0.1:\${ALTERO_PUBLISH_PORT:-8000}:8000" ];
        };

        volumes = {
          db = { };
          storage = { };
        };
      };
    })
  ];
}
