# Penpot — design & prototyping platform (official 5-container compose:
# frontend, backend, exporter, mcp, postgres, valkey, mailcatch + nginx).
# The secret key and version pin live in ~/src/tool/penpot/.env and are
# substituted at compose parse time via --env-file. nginx.conf and the
# nginx-overrides directory stay in ~/src/tool/penpot.
{ config, ... }:
let
  version = "\${PENPOT_VERSION:-2.18.7}";

  # Shared environment blocks (compose YAML anchors, inlined here).
  penpotFlags = {
    PENPOT_FLAGS = "disable-email-verification disable-registration enable-smtp enable-prepl-server enable-mcp";
  };
  penpotPublicUri = {
    PENPOT_PUBLIC_URI = "https://penpot.ns-siokon.f5.si";
  };
  penpotHttpBodySize = {
    PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
    PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE = "367001600";
  };
  penpotSecretKey = {
    PENPOT_SECRET_KEY = "\${PENPOT_SECRET_KEY}";
  };
in
{
  imports = [
    (import ../../lib/compose.nix {
      name = "penpot";
      envFile = "${config.home.homeDirectory}/src/tool/penpot/.env";
      compose = {
        networks.penpot = { };

        volumes = {
          penpot_postgres_v15 = { };
          penpot_assets = { };
        };

        services.penpot-frontend = {
          image = "penpotapp/frontend:${version}";
          restart = "always";
          volumes = [ "penpot_assets:/opt/data/assets" ];
          depends_on = [
            "penpot-backend"
            "penpot-exporter"
            "penpot-mcp"
          ];
          networks = [ "penpot" ];
          environment = penpotFlags // penpotHttpBodySize // penpotPublicUri;
        };

        services.penpot-backend = {
          image = "penpotapp/backend:${version}";
          restart = "always";
          volumes = [ "penpot_assets:/opt/data/assets" ];
          depends_on = {
            penpot-postgres.condition = "service_healthy";
            penpot-valkey.condition = "service_healthy";
          };
          networks = [ "penpot" ];
          environment = {
            JVM_OPTS = "-Xmx1g -XX:MaxMetaspaceSize=512m";

            # Database connection parameters.
            PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
            PENPOT_DATABASE_USERNAME = "penpot";
            PENPOT_DATABASE_PASSWORD = "penpot";

            # Valkey is used for the websockets notifications.
            PENPOT_REDIS_URI = "redis://penpot-valkey/0";

            # Filesystem-based asset storage in a docker volume.
            PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
            PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";

            PENPOT_TELEMETRY_ENABLED = "true";
            PENPOT_TELEMETRY_REFERER = "compose";

            # Mail goes to the local mailcatcher while no real SMTP is set up.
            PENPOT_SMTP_DEFAULT_FROM = "no-reply@example.com";
            PENPOT_SMTP_DEFAULT_REPLY_TO = "no-reply@example.com";
            PENPOT_SMTP_HOST = "penpot-mailcatch";
            PENPOT_SMTP_PORT = "1025";
            PENPOT_SMTP_USERNAME = "";
            PENPOT_SMTP_PASSWORD = "";
            PENPOT_SMTP_TLS = "false";
            PENPOT_SMTP_SSL = "false";
          } // penpotFlags // penpotPublicUri // penpotHttpBodySize // penpotSecretKey;
        };

        services.penpot-mcp = {
          image = "penpotapp/mcp:${version}";
          restart = "always";
          networks = [ "penpot" ];
        };

        services.penpot-exporter = {
          image = "penpotapp/exporter:${version}";
          restart = "always";
          depends_on = {
            penpot-valkey.condition = "service_healthy";
          };
          networks = [ "penpot" ];
          environment = {
            # Internal docker network to the frontend.
            PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
            PENPOT_REDIS_URI = "redis://penpot-valkey/0";
          } // penpotSecretKey // penpotPublicUri;
        };

        services.penpot-postgres = {
          image = "postgres:15";
          restart = "always";
          stop_signal = "SIGINT";
          healthcheck = {
            test = [ "CMD-SHELL" "pg_isready -U penpot" ];
            interval = "2s";
            timeout = "10s";
            retries = 5;
            start_period = "2s";
          };
          volumes = [ "penpot_postgres_v15:/var/lib/postgresql/data" ];
          networks = [ "penpot" ];
          environment = {
            POSTGRES_INITDB_ARGS = "--data-checksums";
            POSTGRES_DB = "penpot";
            POSTGRES_USER = "penpot";
            POSTGRES_PASSWORD = "penpot";
          };
        };

        services.penpot-valkey = {
          image = "valkey/valkey:8.1";
          restart = "always";
          healthcheck = {
            test = [ "CMD-SHELL" "valkey-cli ping | grep PONG" ];
            interval = "1s";
            timeout = "3s";
            retries = 5;
            start_period = "3s";
          };
          networks = [ "penpot" ];
          environment = {
            VALKEY_EXTRA_FLAGS = "--maxmemory 128mb --maxmemory-policy volatile-lfu";
          };
        };

        services.penpot-mailcatch = {
          image = "sj26/mailcatcher:latest";
          restart = "always";
          expose = [ "1025" ];
          ports = [ "127.0.0.1:1080:1080" ];
          networks = [ "penpot" ];
        };

        services.nginx = {
          image = "nginx:alpine";
          restart = "always";
          ports = [ "127.0.0.1:9002:80" ];
          volumes = [
            "${config.home.homeDirectory}/src/tool/penpot/nginx.conf:/etc/nginx/conf.d/default.conf:ro"
          ];
          depends_on = [ "penpot-frontend" ];
          networks = [ "penpot" ];
        };
      };
    })
  ];
}
