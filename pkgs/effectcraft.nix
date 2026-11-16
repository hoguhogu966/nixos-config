{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  pkg-config,
  alsa-lib,
  wayland,
  makeWrapper,
  libxkbcommon,
  vulkan-loader,
  libglvnd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "effectcraft";
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "storytold";
    repo = "effectcraft";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dtqPop1xmtd/duzJt02QCZj5zrtVtyvUI8hj4TbeSkc=";
  };

  cargoLock = {
    lockFile = finalAttrs.src + "/Cargo.lock";
    outputHashes = {
      "craft-docpath-0.1.0" = "sha256-yTMWFdJDxJnbwHbing7TsrbmKRMhrjceMz5RwFJYt5g=";
      "craft-ecproj-format-0.1.0" = "sha256-aEW6WiEyi9YB/mAVdhRJ/WaPBxaIhH1wkhenPE8KLNE=";
      "craft-media-0.1.0" = "sha256-JfBkl7/RX3Fn1nCn0bpKsvtFhb8CVfOtkHp/ISuXc00=";
      "craft-update-0.1.0" = "sha256-BD+uNOEutI9lGz1sWcdOBC4+VgT/7HlwpWGY73ZiGxs=";
      "ecolor-0.37.0" = "sha256-xzgBk6K1X/MZ8WUlIdy+r/0cf1FDkhJJuwQHZX+WY9U=";
      "filmcraft-aac-0.12.0" = "sha256-3air4KEDFztlwg+fYO8ziGA6zzQ/LoL77V72+mHF7VE=";
      "winit-0.30.13" = "sha256-+67bk7cqhM5VHqROL3PeghmhKJvlPIxhU73ay45vaxw=";
    };
  };

  cargoBuildFlags = [ "-p" "effectcraft" "-p" "effectcraft-cli" ];

  doCheck = false;

  nativeBuildInputs = lib.optionals stdenv.isLinux [ pkg-config makeWrapper ];
  buildInputs = lib.optionals stdenv.isLinux [
    alsa-lib
    wayland
    libxkbcommon
  ];

  postInstall = lib.optionalString stdenv.isLinux ''
    for bin in effectcraft effectcraft-cli; do
      wrapProgram $out/bin/$bin --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          alsa-lib
          wayland
          libxkbcommon
          vulkan-loader
          libglvnd
        ]
      } --set __EGL_VENDOR_LIBRARY_DIRS /run/opengl-driver/share/glvnd/egl_vendor.d
    done

    install -Dm644 packaging/linux/ai.storyteller.effectcraft.desktop \
      $out/share/applications/ai.storyteller.effectcraft.desktop

    for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
      install -Dm644 assets/app-icon/hicolor/$size/apps/ai.storyteller.effectcraft.png \
        $out/share/icons/hicolor/$size/apps/ai.storyteller.effectcraft.png
    done
  '';

  meta = with lib; {
    description = "Motion graphics and visual effects; an open-source reimplementation of Adobe After Effects";
    homepage = "https://github.com/storytold/effectcraft";
    license = with licenses; [ mit asl20 ];
    mainProgram = "effectcraft";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
