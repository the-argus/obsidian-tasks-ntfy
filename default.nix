{
  nimRelease ? true,
  nimPackages,
  fetchurl,
  useMusl ? false,
  lib,
  curl,
  upx,
  binutils,
  ...
}: let
  confignims = fetchurl {
    url = "https://raw.githubusercontent.com/kaushalmodi/hello_musl/35a674ef675a4cf0ef1b62d395ab0668f43f6446/config.nims";
    sha256 = "";
  };
  nimFlags = ["--threads:on"];
  pname = "notify_tasks";
  outname = builtins.replaceStrings ["_"] ["-"] pname;
in
  nimPackages.buildNimPackage ({
      inherit pname;
      version = "0.0.1";
      src = ./.;

      nimBinOnly = false;
      nimbleFile = ./notify_tasks.nimble;
      inherit nimRelease nimFlags;

      buildInputs = with nimPackages; [
        (nimPackages.fetchNimble {
          pname = "markdown";
          version = "0.8.5";
          hash = "sha256-UUcI/7q0FgbEqygd+O6vKZQJuKO80cn9H4nDAhXU3do=";
        })
        (nimPackages.fetchNimble {
          pname = "taskman";
          version = "0.5.4";
          hash = "sha256-0D1MkC45uu2voRys6JQMupjUhCifZ7bMxLbfqYc3zxI=";
        })
        regex
        unicodedb
      ];
    }
    // (lib.optionalAttrs useMusl {
      buildPhase = let
        flags = builtins.concatStringsSep " " nimFlags;
      in ''
        nim musl ${flags} ${pname}.nim
      '';

      nativeBuildInputs = [
        curl
        upx
        binutils
      ];

      installPhase = ''
        mkdir -p $out/bin
        mv ${pname} $out/bin/${outname}
      '';

      postPatch = ''cp ${confignims} config.nims'';
    }))
