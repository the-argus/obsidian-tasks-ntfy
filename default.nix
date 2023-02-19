{
  nimRelease ? true,
  nimPackages,
  useMusl ? false,
  lib,
  musl,
  muslPkgs ? null,
  upx,
  binutils,
  pcre,
  ...
}: let
  nimFlags =
    ["--threads:on" "-d:release"]
    ++ (lib.lists.optionals useMusl [
      "--gcc.exe:musl-gcc"
      "--gcc.linkerexe:musl-gcc"
      "--passL:-static"
      # this doesn't matter but I think I could make the project be aware
      # of whether or not its building with musl in the future
      "-d:musl"
      "--define:usePcreHeader"
      "--passL:${pcre.out}/lib/libpcre.a"
    ]);
      # "--passC:-I${pcre}/include"
  pname = "notify_tasks";

  builder =
    if useMusl
    then nimPackages.buildNimPackage.override {inherit (muslPkgs) stdenv;}
    else nimPackages.buildNimPackage;
in
  builder {
    inherit pname;
    version = "0.0.1";
    src = ./.;

    nimBinOnly = false;
    nimbleFile = ./notify_tasks.nimble;
    inherit nimRelease nimFlags;

    nativeBuildInputs = lib.lists.optionals useMusl [
      musl
      upx
      binutils
    ];

    buildInputs = with nimPackages; [
      muslPkgs.pcre.dev
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

    postFixup = lib.strings.optionalString useMusl ''
      strip -s $out/bin/${pname}
      upx --best $out/bin/${pname}
    '';
  }
