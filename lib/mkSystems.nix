#  hosts ? {
#    paths = [];
#    modules = [];
#    specialArgs = {};
#    system = "x86_64-linux";
#    pkgs = <required>;
#    mkSystem = <required>;
#  },
{
  recursivelyImport,
  optional,
}: hosts: let
  inherit (builtins) mapAttrs concatMap removeAttrs;

  select = name: importedModule:
    optional (importedModule ? all) importedModule.all
    ++ optional (importedModule ? these && importedModule ? "${name}") importedModule.these
    ++ optional (importedModule ? others && !(importedModule ? "${name}")) importedModule.others
    ++ optional (importedModule ? "${name}") importedModule."${name}";
in
  mapAttrs
  (name: value: let
    importedModules = map import (recursivelyImport value.paths or []);
  in
    value.mkSystem (removeAttrs value ["paths" "mkSystem"]
      // {
        system = value.system or "x86_64-linux";
        modules =
          concatMap (select name) importedModules
          ++ (value.modules or []);
        specialArgs = value.specialArgs or {};
      }))
  hosts
