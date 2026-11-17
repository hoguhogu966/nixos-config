{ pkgs, ... }:
{
  home.packages = [ pkgs.xdg-utils ];

  xdg.dataFile."noctalia/plugins/meeting-bar" = {
    source = ./plugins/meeting-bar;
    recursive = true;
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        corner_radius_scale = 1.0;
        font_family = "Gen Interface JP";
        clipboard_enabled = false;
        telemetry_enabled = false;
        screen_time_enabled = true;
        panel.open_near_click_control_center = true;
      };

      theme = {
        mode = "dark";
        source = "wallpaper";
        builtin = "Rosé Pine";
        templates = {
          enable_builtin_templates = false;
          enable_community_templates = false;
        };
      };

      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers";
        fill_mode = "crop";
        transition = [
          "fade"
          "disc"
          "stripes"
          "wipe"
          "honeycomb"
        ];
        transition_duration = 1500;
        edge_smoothness = 0.05;
        automation = {
          enabled = true;
          interval_seconds = 1200;
          order = "random";
          recursive = true;
        };
      };

      location.auto_locate = true;
      weather = {
        enabled = true;
        unit = "celsius";
        effects = true;
      };

      calendar = {
        enabled = true;
        reminders = {
          enabled = true;
          use_event_reminders = true;
          default_lead_minutes = 10;
        };
      };
      control_center = {
        sidebar = "full";
        shortcuts = [
          { type = "bluetooth"; }
          { type = "nightlight"; }
          { type = "notification"; }
          { type = "mic_mute"; }
          { type = "system"; }
          { type = "session"; }
        ];
        calendar = {
          show_events_card = true;
          show_week_numbers = false;
        };
      };

      audio = {
        enable_overdrive = false;
        enable_sounds = false;
      };

      brightness = {
        enable_ddcutil = true;
        sync_all_monitors = true;
      };

      lockscreen = {
        enabled = true;
        transition = [ ];
      };

      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.7;
        radius = 12;
        margin_ends = 4;
        margin_edge = 4;
        padding = 4;
        widget_spacing = 6;
        capsule = true;
        capsule_padding = 10;
        capsule_opacity = 0.7;
        auto_hide = false;
        start = [
          "launcher"
          "clock"
          "sysmon"
          "active_window"
          "yuta/meeting-bar:bar"
          "media"
        ];
        center = [ "workspaces" ];
        end = [
          "tray"
          "notifications"
          "wallpaper"
          "battery"
          "volume"
          "brightness"
          "control-center"
        ];
      };
      widget.clock = {
        format = "{:%H:%M}";
        vertical_format = "{:%H\\n%M}";
        tooltip_format = "{:%Y/%m/%d %H:%M (%a)}";
      };
      widget.tray.scale = 1.15;

      plugins = {
        enabled = [
          "yuta/meeting-bar"
          "yuta/codexbar-usage"
          "dotnetrob/cat"
        ];
        auto_update = "none";
      };
    };
  };
}
