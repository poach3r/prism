#  hosts ? {
#    pkgs = null;
#    paths = [];
#    modules = [];
#    nixosSystem = null;
#    specialArgs = {};
#    system = "x86_64-linux";
#  },
pkgs: recursivelyImport: hosts: let
  inherit (builtins) mapAttrs concatLists;
in
  mapAttrs
  (name: value:
    value.mkSystem or (abort "Host ${name} was never passed an instance of mkSystem. You can find this at $${nixpkgs}/nixos/lib/eval-config.nix.") {
      inherit pkgs;
      modules =
        concatLists (map (module: let
          importedModule = import module;
        in [
          (importedModule.all or {})
          (importedModule."${name}" or {})
        ]) (recursivelyImport value.paths or []))
        ++ (value.modules or []);
      specialArgs = value.specialArgs or {};
      system = value.system or "x86_64-linux.default";
    })
  hosts
