{
  nimRelease ? true,
  nimPackages,
  ...
}:
nimPackages.buildNimPackage {
  pname = "notify-tasks";
  version = "0.0.1";
  src = ./.;

  nimBinOnly = false;
  nimbleFile = ./notify-tasks.nimble;
  inherit nimRelease;
  nimFlags = ["--threads:on"];
  
  buildInputs = with nimPackages; [
    (nimPackages.fetchNimble {
      pname = "markdown";
      version = "0.8.5";
      hash = "sha256-mrO+WeSzCBclqC2UNCY+IIv7Gs8EdTDaTeSgXy3TgNM=";
    })
  ];
}
