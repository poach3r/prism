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
  inherit (builtins) mapAttrs concatMap;
  mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
in
  mapAttrs
  (name: value:
    value.mkSystem or mkSystem {
      inherit pkgs;
      modules =
        concatMap (module: let
          importedModule = import module;
        in [
          (importedModule.all or {})
          (importedModule."${name}" or {})
        ]) (recursivelyImport value.paths or [])
        ++ (value.modules or []);
      specialArgs = value.specialArgs or {};
      system = value.system or "x86_64-linux";
    })
  hosts
