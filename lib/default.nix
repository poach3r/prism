{parsnip}: let
  # Code for pkgs.lib functions this repo needs so it
  # doesn't depend on a consumer's nixpkgs.
  npf = import ./nixpkgs;
  childTagsOf = import ./childTagsOf.nix;
in {
  inherit childTagsOf;
  recursivelyImport = import ./recursivelyImport {inherit (npf) hasSuffix;};
  closureOf = import ./closureOf.nix;
  presets = import ./presets.nix;
  mkSystems = import ./mkSystems.nix {
    inherit (npf) optional hasSuffix;
    inherit childTagsOf;
    importParsnip =
      if parsnip == null
      then path: throw "prism: ${toString path} is a Parsnip module; pass `parsnip` to prism to load it"
      else parsnip.importParsnip;
  };
}
