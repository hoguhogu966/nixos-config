{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  fontconfig,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ink";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "borghei";
    repo = "ink";
    rev = "v${finalAttrs.version}";
    hash = "sha256-c2PK7+h4rZDb5eGPMwNwjI7D4tZH/gPCq73xT/8r5xE=";
  };

  cargoLock = {
    lockFile = finalAttrs.src + "/Cargo.lock";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ fontconfig ];

  meta = with lib; {
    description = "A terminal markdown reader that actually looks good";
    homepage = "https://github.com/borghei/ink";
    license = licenses.unfreeRedistributable;
    mainProgram = "ink";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
