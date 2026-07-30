{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  outputs = {nixpkgs, ...}: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
  in {
    lib = forAllSystems (_: pkgs: import ./default.nix pkgs);
    devShell = forAllSystems (system: pkgs:
      pkgs.mkShell {
        buildInputs = [
          pkgs.nixd
          pkgs.alejandra
        ];
      });

    #nixosConfigurations = lib.x86_64-linux.mkSystems {
    #  desktop = {
    #    mkSystem = x: x;
    #    modules = lib.x86_64-linux.recursivelyImport [./test];
    #  };
    #  laptop = {
    #    modules = [(import ./hardware.nix) (import ./configuration.nix)];
    #  };
    #};
  };
}
