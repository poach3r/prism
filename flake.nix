{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  outputs = {nixpkgs, ...}: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
  in {
    lib = forAllSystems (_: pkgs: import ./default.nix {inherit nixpkgs pkgs;});
    devShell = forAllSystems (system: pkgs:
      pkgs.mkShell {
        buildInputs = [
          pkgs.nixd
          pkgs.alejandra
          pkgs.harper
        ];
      });
  };
}
