{
  nimRelease ? true,
  nimPackages,
  useMusl ? false,
  lib,
  musl,
  ...
}: let
  nimFlags =
    ["--threads:on" "-d:release"]
    ++ (lib.lists.optionals useMusl [
      "--gcc.exe:musl-gcc"
      "--gcc.linkerexe:musl-gcc"
      "--passL:-static"
      "-d:musl"
    ]);
  pname = "notify_tasks";
in
  nimPackages.buildNimPackage {
    inherit pname;
    version = "0.0.1";
    src = ./.;

    nimBinOnly = false;
    nimbleFile = ./notify_tasks.nimble;
    inherit nimRelease nimFlags;

    nativeBuildInputs = lib.lists.optionals useMusl [musl];

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
