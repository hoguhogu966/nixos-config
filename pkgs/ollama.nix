{
  fetchFromGitHub,
  ollama,
}:
let
  version = "0.40.16";
  llamaCppVersion = "b12177";
in
ollama.overrideAttrs (oldAttrs: {
  inherit version;

  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    tag = "v${version}";
    hash = "sha256-ita7MMcdRVBVNmOXnopJX31hnCaPHOx9079YGci5v18=";
  };

  vendorHash = "sha256-1mzJrZUHH2ouP6I+LVojHbft7No5AumqKZVq0I/Ubsg=";

  passthru = oldAttrs.passthru // {
    inherit llamaCppVersion;
    llamaCppSrc = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = llamaCppVersion;
      hash = "sha256-/bZRn+Zy4bqdJUWDX3a4+HClrsST60uXiNJT26mTgI0=";
    };
  };
})
