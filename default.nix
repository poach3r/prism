{
  nixpkgs ? null,
  pkgs ?
    if (nixpkgs == null)
    then abort "booayh hasn't been passed either nixpkgs or pkgs."
    else
      builtins.warn "Not explicitly passing pkgs to booyah may result in an additional instance being created, decreasing performance."
      (import nixpkgs {system = "x86_64-linux";}),
}: let
  recursivelyImport = import ./lib/recursivelyImport.nix pkgs.lib;
in {
  inherit recursivelyImport;
  mkSystems = import ./lib/mkSystems.nix {inherit pkgs nixpkgs recursivelyImport;};
}
