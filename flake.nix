{
  description = "A server which analyzes an obsidian vault and sends you notifications.";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs?ref=nixos-22.11;
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    genSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgs =
      genSystems (system:
        import nixpkgs {inherit system;});
  in {
    packages = genSystems (system: {
      notify-tasks = pkgs.${system}.callPackage ./. {};
      default = self.packages.${system}.notify-tasks;
    });
  };
}
