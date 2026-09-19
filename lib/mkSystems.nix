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
  inherit (builtins) mapAttrs concatMap hasAttr isAttrs attrValues;
  lib = import "${nixpkgs}/lib";
  mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
  systemOf = host: host.system or "x86_64-linux";

  # One pkgs per system, shared by every host on that system. Falls back to
  # importing nixpkgs when it isn't a flake input.
  pkgsBySystem =
    lib.genAttrs (lib.unique (map systemOf (attrValues hosts)))
    (system: nixpkgs.legacyPackages.${system} or (import nixpkgs {inherit system;}));
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
        concatMap (importedModule:
          if isAttrs importedModule
          then
            [
              (importedModule.all or {})
            ]
            ++ (lib.optionals (hasAttr "these" importedModule && hasAttr name importedModule) [
              importedModule.these
            ])
            ++ (lib.optionals (hasAttr "others" importedModule && !(hasAttr name importedModule)) [
              importedModule.others
            ])
            ++ [
              (importedModule."${name}" or {})
            ]
          else [
          ])
        importedModules
        ++ (value.modules or []);
      specialArgs = value.specialArgs or {};
    })
  hosts
