# Pydio Cells — file sharing platform (cells + mysql). MySQL credentials
# live in ~/src/tool/pydio/.env and are substituted at compose parse time
# via --env-file. Named volumes (cellsdir/data/mysqldir) are project-scoped
# and reused from the existing "pydio" project.
{ config, ... }:
{
  imports = [
    (import ../../lib/compose.nix {
      name = "pydio";
      envFile = "${config.home.homeDirectory}/src/tool/pydio/.env";
      compose = {
        services.cells = {
          image = "pydio/cells:5.1.1";
          restart = "unless-stopped";
          ports = [ "8080:8080" ];
          volumes = [
            "cellsdir:/var/cells"
            "data:/var/cells/data"
          ];
        };

        services.mysql = {
          image = "mysql:8";
          restart = "unless-stopped";
          command = [
            "mysqld"
            "--character-set-server=utf8mb4"
            "--collation-server=utf8mb4_unicode_ci"
          ];
          environment = {
            MYSQL_ROOT_PASSWORD = "\${MYSQL_ROOT_PASSWORD}";
            MYSQL_DATABASE = "cells";
            MYSQL_USER = "pydio";
            MYSQL_PASSWORD = "\${MYSQL_PASSWORD}";
          };
          volumes = [ "mysqldir:/var/lib/mysql" ];
        };

        volumes = {
          data = { };
          cellsdir = { };
          mysqldir = { };
        };
      };
    })
  ];
}
