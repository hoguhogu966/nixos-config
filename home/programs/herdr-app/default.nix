{ pkgs, ... }:
{
  home.packages = [
    pkgs.herdr-app
    pkgs.herdr-core
  ];
}
