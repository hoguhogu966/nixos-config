# Vikunja — task manager (vikunja + postgres). The DB password and the
# service secret live in ~/src/tool/vikunja/.env and are substituted at
# compose parse time via --env-file.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "vikunja";
      envFile = "${config.home.homeDirectory}/src/tool/vikunja/.env";
      compose = {
        services.vikunja = {
          image = "vikunja/vikunja";
          restart = "unless-stopped";
          ports = [ "10000:3456" ];
          volumes = [
            "${config.home.homeDirectory}/src/tool/vikunja/files:/app/vikunja/files"
          ];
          environment = {
            VIKUNJA_SERVICE_PUBLICURL = "https://zephyr.tail32a8e5.ts.net:10101/";
            VIKUNJA_DATABASE_HOST = "db";
            VIKUNJA_DATABASE_PASSWORD = "\${VIKUNJA_DB_PASSWORD}";
            VIKUNJA_DATABASE_TYPE = "postgres";
            VIKUNJA_DATABASE_USER = "vikunja";
            VIKUNJA_DATABASE_DATABASE = "vikunja";
            VIKUNJA_SERVICE_SECRET = "\${VIKUNJA_SERVICE_SECRET}";
          };
          depends_on = {
            db.condition = "service_healthy";
          };
        };

        services.db = {
          image = "postgres:18";
          restart = "unless-stopped";
          environment = {
            POSTGRES_PASSWORD = "\${VIKUNJA_DB_PASSWORD}";
            POSTGRES_USER = "vikunja";
          };
          volumes = [
            "${config.home.homeDirectory}/src/tool/vikunja/db:/var/lib/postgresql"
          ];
          healthcheck = {
            test = [ "CMD-SHELL" "pg_isready -h localhost -U $$POSTGRES_USER" ];
            interval = "30s";
            start_period = "15s";
            start_interval = "5s";
          };
        };
      };
    })
  ];
}
