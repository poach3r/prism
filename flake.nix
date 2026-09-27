{
  inputs = {
    scoped-flakes = {
      url = "git+https://tangled.org/poacher.dev/scoped-flakes";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixhooks.follows = "nixhooks";
      };
    };
    nixpkgs.url = "github:divnix/blank";
    nixhooks.url = "github:divnix/blank";
  };

  outputs = inputs: let
    inherit (inputs.scoped-flakes.lib) overrideInput;
    forAllSystems = inputs.scoped-flakes.lib.forAllSystems {
      inherit (inputs) self;
    };

    hooks = nixhooks: system:
      nixhooks.lib.${system}.mkHooks {
        hooks = {
          inherit (nixhooks.lib.${system}.presets) alejandra commitlint;
        };

        settings = {
          parallel = true;
          tangled.enable = true;
        };
      };
  in {
    lib = import ./.;

    apps = forAllSystems (system: {
      name = "apps-${system}";
      isApp = true;
      inputs.nixhooks = {
        url = "git+https://tangled.org/poacher.dev/nixhooks";
        override = overrideInput inputs.nixhooks;
      };

      outputs = {nixhooks, ...}: (hooks nixhooks system).apps;
    });

    devShells = forAllSystems (system: {
      name = "devshell-${system}";
      inputs = {
        nixpkgs = {
          url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
          override = overrideInput inputs.nixpkgs;
        };

        nixhooks = {
          url = "git+https://tangled.org/poacher.dev/nixhooks";
          override = overrideInput inputs.nixhooks;
        };
      };

      outputs = {
        nixpkgs,
        nixhooks,
        ...
      }: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          shellHook = "${(hooks nixhooks system).install-hooks}/bin/install-hooks";
          nativeBuildInputs = [
            pkgs.nixd
            pkgs.alejandra
            pkgs.harper
          ];
        };
      };
    });
  };
}
