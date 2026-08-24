#  hosts ? {
#    paths = [];
#    modules = [];
#    specialArgs = {};
#    system = "x86_64-linux";
#  },
{
  nixpkgs,
  pkgs,
  recursivelyImport,
}: hosts: let
  inherit (builtins) mapAttrs concatMap hasAttr isAttrs;
  mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
in
  mapAttrs
  (name: value: let
    importedModules = map import (recursivelyImport value.paths or []);
  in
    value.mkSystem or mkSystem {
      inherit pkgs;
      modules =
        concatMap (importedModule:
          if isAttrs importedModule
          then
            [
              (importedModule.all or {})
            ]
            ++ (pkgs.lib.optionals (hasAttr "these" importedModule && hasAttr name importedModule) [
              importedModule.these
            ])
            ++ (pkgs.lib.optionals (hasAttr "others" importedModule && !(hasAttr name importedModule)) [
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
      system = value.system or "x86_64-linux";
    })
  hosts
