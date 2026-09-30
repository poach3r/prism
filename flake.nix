{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    nixhooks.url = "git+https://tangled.org/poacher.dev/nixhooks";
  };

  outputs = {
    nixpkgs,
    nixhooks,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    hooks = system:
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
    packages = forAllSystems (system: (hooks system).packages);
    apps = forAllSystems (system: (hooks system).apps);
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        inherit (hooks system) shellHook;
        nativeBuildInputs = [
          pkgs.nixd
          pkgs.alejandra
          pkgs.harper
        ];
      };
    });
  };
}
