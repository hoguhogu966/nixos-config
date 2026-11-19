# Tool services managed from ~/src/tool — grouped by genre:
#   web/       self-hosted web apps (gitea, linkding, penpot, pydio, vikunja)
#   media/     media servers (jellyfin)
#   files/     file transfer and sharing (samba)
#   research/  knowledge bases and search (altero, rustxng)
#   dev/       bots and helper tools (color-dis-bot)
#
# These are Home Manager / darwin modules (launchd.agents); they are only
# imported by hosts that actually run the services (currently darwin
# zephyr, via home/zephyr.nix).
{ ... }:
{
  imports = [
    ./web
    ./media
    ./files
    ./research
    ./dev
  ];
}
