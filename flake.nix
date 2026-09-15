{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  outputs = {nixpkgs, ...}: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
    mkLib = args:
      (import ./default.nix args)
      // {
        __functor = self: overrides: mkLib (args // overrides);
      };
  in {
    lib = forAllSystems (_: pkgs: mkLib {inherit nixpkgs pkgs;});
    devShell = forAllSystems (system: pkgs:
      pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.nixd
          pkgs.alejandra
          pkgs.harper
        ];
      });
  };
}
