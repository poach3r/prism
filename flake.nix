{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    nixhooks = {
      url = "git+https://tangled.org/poacher.dev/nixhooks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    nixhooks,
    ...
  }: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
    mkLib = args:
      (import ./default.nix args)
      // {
        __functor = self: overrides: mkLib (args // overrides);
      };
  in
    nixhooks.lib.withHooks {
      hooks = forAllSystems (system: _: {
        inherit (nixhooks.lib.${system}.presets) alejandra commitlint;
        settings = {
          parallel = true;
          tangled.enable = true;
        };
      });
      lib = mkLib {inherit nixpkgs;};
      devShells = forAllSystems (system: pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.nixd
            pkgs.alejandra
            pkgs.harper
          ];
        };
      });
    };
}
