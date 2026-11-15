{
  lib,
  fetchurl,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plamonic";
  version = "0.1.1";

  src = fetchurl {
    url = "https://github.com/sizumita/Plamonic/releases/download/v${finalAttrs.version}/Plamonic.zip";
    hash = "sha256-lDpeWTadBBnZ416YWJFYzbMvoRHv0FInpq3oufm/Bk8=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    unzip -q "$src" -d "$out/Applications"
    test -d "$out/Applications/Plamonic.app"

    runHook postInstall
  '';

  meta = {
    description = "On-device PLaMo translation overlay for macOS";
    homepage = "https://github.com/sizumita/Plamonic";
    license = lib.licenses.agpl3Only;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
