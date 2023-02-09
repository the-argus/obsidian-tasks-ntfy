{
  nimRelease ? true,
  nimPackages,
  ...
}:
nimPackages.buildNimPackage {
  pname = "notify_tasks";
  version = "0.0.1";
  src = ./.;

  nimBinOnly = false;
  nimbleFile = ./notify_tasks.nimble;
  inherit nimRelease;
  nimFlags = ["--threads:on"];
  
  buildInputs = with nimPackages; [
    (nimPackages.fetchNimble {
      pname = "markdown";
      version = "0.8.5";
      hash = "sha256-UUcI/7q0FgbEqygd+O6vKZQJuKO80cn9H4nDAhXU3do=";
    })
    regex
  ];
}
