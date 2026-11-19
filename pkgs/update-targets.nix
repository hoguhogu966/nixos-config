{ ... }:
let
  flake = builtins.getFlake (toString ../.);
  pkgs = flake.nixosConfigurations.saffron.pkgs;
in {
  inherit (pkgs)
    buzz-desktop
    buzz-sidecars
    effectcraft
    ink
    ollama
    rea
    souieba
    ;
  cloudflared = pkgs.callPackage ./cloudflared.nix { };
  herdr-app = pkgs.callPackage ./herdr-app.nix { };
  herdr-core = pkgs.callPackage ./herdr-core.nix { };
  omniwm = pkgs.callPackage ./omniwm.nix { };
}
