let
  npf = import ./lib/nixpkgs; # Functions of pkgs.lib
  childTagsOf = import ./lib/childTagsOf.nix;
in {
  inherit childTagsOf;
  recursivelyImport = import ./lib/recursivelyImport {inherit (npf) hasSuffix;};
  closureOf = import ./lib/closureOf.nix;
  presets = import ./lib/presets.nix;
  mkSystems = import ./lib/mkSystems.nix {
    inherit (npf) optional;
    inherit childTagsOf;
  };
}
