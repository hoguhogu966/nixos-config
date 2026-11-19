{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  libGL,
  libgcc,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.16";

  # Prebuilt release; see https://releases.herdr.dev/app/latest.json
  src = fetchurl {
    url = "https://releases.herdr.dev/app/${finalAttrs.version}/herdr-app-linux-x86_64.tar.gz";
    hash = "sha256-KC0mMhlrI4IGz+Zr+2HA+vKZyhyRhDvQdlIbvjZXEhY=";
  };

  dontConfigure = true;
  dontBuild = true;

  strictDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];

  # Only libxcb and libxkbcommon are linked at build time. The app dlopens
  # libvulkan.so.1, libEGL.so.1, libwayland-{client,egl}.so and
  # libxkbcommon-x11.so.0 at runtime, so they only need to be reachable via
  # the RPATH autoPatchelfHook writes.
  buildInputs = [
    libGL
    libgcc
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      terminal = false;
      categories = [ "Development" ];
      startupWMClass = "herdr-app";
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 herdr-app $out/bin/herdr-app
    install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    install -Dm644 LICENSE -t $out/share/doc/herdr-app
    install -Dm644 THIRD-PARTY-NOTICES -t $out/share/doc/herdr-app

    runHook postInstall
  '';

  meta = {
    description = "Desktop app for terminals and coding agents";
    homepage = "https://github.com/herdrdev/herdr-app";
    license = lib.licenses.asl20;
    mainProgram = "herdr-app";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
