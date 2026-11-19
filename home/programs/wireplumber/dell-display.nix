{ ... }:
{
  xdg.configFile."wireplumber/wireplumber.conf.d/51-dell-display-audio.conf".text = ''
    # AD107 (RTX 4060) HDMI audio outputs, per ELD (/proc/asound/card0/eld*):
    #   hdmi-output-0 (output:hdmi-stereo)        -> KTC H27T22C-3  (DP-1)
    #   hdmi-output-1 (output:hdmi-stereo-extra1)  -> DELL S2722DZ  (DP-3)
    # Prefer the Dell display output; fall back to the KTC one when the
    # Dell display is off. Requires WirePlumber >= 0.5.15 for this section.
    device.profile.priority.rules = [
      {
        matches = [
          {
            device.name = "alsa_card.pci-0000_01_00.1"
          }
        ]
        actions = {
          update-props = {
            priorities = [
              "output:hdmi-stereo-extra1"
              "output:hdmi-stereo"
            ]
          }
        }
      }
    ]

    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "~alsa_output.pci-0000_01_00.1.hdmi-stereo.*"
          }
        ]
        actions = {
          update-props = {
            priority.session = 1200
          }
        }
      }
    ]
  '';
}
