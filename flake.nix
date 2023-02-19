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
    systemToMusl = {
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
    };
    genSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgs =
      genSystems (system:
        import nixpkgs {inherit system;});
    muslPkgs = genSystems (system:
      import nixpkgs {
        localSystem = {
          inherit system;
          libc = "musl";
          config = systemToMusl.${system};
        };
      });

    makeMuslParsedPlatform = parsed: (parsed
      // {
        abi = with nixpkgs;
          {
            gnu = lib.systems.parse.abis.musl;
            gnueabi = lib.systems.parse.abis.musleabi;
            gnueabihf = lib.systems.parse.abis.musleabihf;
            gnuabin32 = lib.systems.parse.abis.muslabin32;
            gnuabi64 = lib.systems.parse.abis.muslabi64;
            gnuabielfv2 = lib.systems.parse.abis.musl;
            gnuabielfv1 = lib.systems.parse.abis.musl;
            musleabi = lib.systems.parse.abis.musleabi;
            musleabihf = lib.systems.parse.abis.musleabihf;
            muslabin32 = lib.systems.parse.abis.muslabin32;
            muslabi64 = lib.systems.parse.abis.muslabi64;
          }
          .${parsed.abi.name}
          or lib.systems.parse.abis.musl;
      });

    staticPkgs = genSystems (system:
      import nixpkgs {
        localSystem = {
          inherit system;
          libc = "musl";
          config = systemToMusl.${system};
        };
        crossSystem = {
          isStatic = true;
          parsed = makeMuslParsedPlatform muslPkgs.${system}.stdenv.hostPlatform.parsed;
        };
      });
  in {
    packages = genSystems (system: {
      notify-tasks = pkgs.${system}.callPackage ./. {};
      default = self.packages.${system}.notify-tasks;

      musl = pkgs.${system}.callPackage ./. {
        useMusl = true;
        muslPkgs = muslPkgs.${system};
        pcre = staticPkgs.${system}.pcre;
      };
    });
  };
}
