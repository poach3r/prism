{nixpkgs ? abort "prism hasn't been passed nixpkgs."}: let
  recursivelyImport = import ./lib/recursivelyImport.nix (import "${nixpkgs}/lib");
in {
  inherit recursivelyImport;
  mkSystems = import ./lib/mkSystems.nix {inherit nixpkgs recursivelyImport;};
}
