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
  inherit (builtins) mapAttrs concatMap hasAttr;
  mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
in
  mapAttrs
  (name: value:
    value.mkSystem or mkSystem {
      inherit pkgs;
      modules =
        concatMap (module: let
          importedModule = import module;
        in
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
          ]) (recursivelyImport value.paths or [])
        ++ (value.modules or []);
      specialArgs = value.specialArgs or {};
      system = value.system or "x86_64-linux";
    })
  hosts
