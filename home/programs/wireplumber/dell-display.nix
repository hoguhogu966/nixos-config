{ ... }:
{
  xdg.configFile."wireplumber/wireplumber.conf.d/51-dell-display-audio.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            device.name = "alsa_card.pci-0000_01_00.1"
          }
        ]
        actions = {
          update-props = {
            device.profile = "output:hdmi-stereo"
          }
        }
      }
      {
        matches = [
          {
            node.name = "alsa_output.pci-0000_01_00.1.hdmi-stereo"
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
