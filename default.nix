pkgs: let
  recursivelyImport = import ./lib/recursivelyImport.nix pkgs.lib;
in {
  inherit recursivelyImport;
  mkSystems = import ./lib/mkSystems.nix pkgs recursivelyImport;
}
