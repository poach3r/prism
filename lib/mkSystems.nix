#  hosts ? {
#    paths = [];
#    modules = [];
#    specialArgs = {};
#    system = "x86_64-linux";
#    pkgs = nixpkgs.legacyPackages.${system};
#  },
{
  nixpkgs,
  recursivelyImport,
}: hosts: let
  inherit (builtins) mapAttrs concatMap attrValues;
  lib = import "${nixpkgs}/lib";
  mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
  systemOf = host: host.system or "x86_64-linux";

  # One pkgs per system, shared by every host on that system. Falls back to
  # importing nixpkgs when it isn't a flake input.
  pkgsBySystem =
    lib.genAttrs (lib.unique (map systemOf (attrValues hosts)))
    (system: nixpkgs.legacyPackages.${system} or (import nixpkgs {inherit system;}));

  select = name: importedModule:
    lib.optional (importedModule ? all) importedModule.all
    ++ (lib.optionals (importedModule ? these && importedModule ? "${name}") [
      importedModule.these
    ])
    ++ (lib.optionals (importedModule ? others && !(importedModule ? "${name}")) [
      importedModule.others
    ])
    ++ (lib.optional (importedModule ? "${name}") importedModule."${name}");
in
  mapAttrs
  (name: value: let
    importedModules = map import (recursivelyImport value.paths or []);
    system = systemOf value;
  in
    value.mkSystem or mkSystem {
      inherit system;
      pkgs = value.pkgs or pkgsBySystem.${system};
      modules =
        concatMap (select name) importedModules
        ++ (value.modules or []);
      specialArgs = value.specialArgs or {};
    })
  hosts
