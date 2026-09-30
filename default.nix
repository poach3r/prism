let
  # Code for pkgs.lib functions this repo needs so it # doesn't depend on a
  # consumer's nixpkgs.
  npf = import ./lib/nixpkgs;
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
