# color-dis-bot — Discord color-role bot (from ~/src/tool/color_dis_bot,
# built by its own flake and exposed here as a flake input). The token and
# optional settings live in ~/src/tool/color_dis_bot/.env, read from the
# working directory; bot.db is created there as well.
#
# NOTE: if the bot was started by hand, kill that instance once after
# switching (the launchd agent keeps its own copy alive).
{ config, pkgs, inputs, ... }:
{
  launchd.agents.color-dis-bot = {
    enable = true;
    config = {
      Program = inputs.color-dis-bot.apps.${pkgs.stdenv.hostPlatform.system}.default.program;
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = "${config.home.homeDirectory}/src/tool/color_dis_bot";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/color-dis-bot.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/color-dis-bot.err.log";
    };
  };
}
