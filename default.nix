let
  recursivelyImport = import ./lib/recursivelyImport {inherit (npf) hasSuffix;};
  npf = import ./lib/nixpkgs; # Functions of pkgs.lib
in {
  inherit recursivelyImport;
  mkSystems = import ./lib/mkSystems.nix {
    inherit (npf) optional;
    inherit recursivelyImport;
  };
}
