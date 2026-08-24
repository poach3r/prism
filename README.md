# About
`booyah` is a library to facilitate complex multi-host NixOS configurations. 
Loosely inspired by the dendritic pattern, all modules specificy the host 
(or `all` for all hosts) that the configurations therein apply to.

# Installation
## Flakes
1. Add `booyah` to your inputs:
```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
        booyah = {
            url = "git+https://codeberg.org/poacher/booyah.git";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
}
```

2. Create your NixOS configurations with `mkSystems`:
```nix
{ 
    outputs = {nixpkgs, booyah, ...}: {
        nixosConfigurations = booyah.lib.x86_64-linux.mkSystems {
            foo = {
                # ...
            };
            bar = {
                # ...
            };
        };
    };
}
```

## Non-Flakes
1. Pin `booyah` with your pinner of choice, I'll be using `npins`:
```
npins add forgejo codeberg.org poacher booyah -b main
```

2. Import `booyah` in your NixOS entry-point:
```nix
let 
    inherit (sources) nixpkgs;
    sources = import ./npins;
    pkgs = import nixpkgs {}
    booyah = import sources.booyah { inherit nixpkgs pkgs; };
in {
    # ...
}
```

3. Create your NixOS configurations using `mkSystems`:
```nix
let
    # ...
in {
    nixosConfigurations = booyah.mkSystems {
        foo = {
            # ...
        };
        bar = {
            # ...
        };
    }:
}
```

# Usage
## mkSystems
`mkSystems` is a function which creates NixOS configurations based on the provided hosts.
Each host accepts the following arguments:

1. `paths ? []` module paths to be automatically imported and parsed. Only modules in the proper format (attribute sets with `all` and/or host keys) will be applied.
2. `modules ? []` non-booyah modules to be manually imported.
3. `specialArgs ? {}` arguments to be passed to every module.
4. `system ? "x86_64-linux"` defines the system arch.
5. `mkSystem ? import "${nixpkgs}/nixos/lib/eval-config.nix"` is the function used internally to create the system. If you're on Darwin this should be set to `nix-darwin.lib.darwinSystem`.

### Example
```nix
nixosConfigurations = mkSystems {
    desktop = {
        paths = [./modules];
        modules = [hjem.nixosModules.default];
        specialArgs = {inherit myPkgs;};
    };
}
```

## recursivelyImport
`recursivelyImport` is used internally to import `paths`. It accepts a list of
paths.

## Modules
Modules are now defined as attribute sets with host dependant configuration.
Creating an attribute set for a host with typical NixOS configuration inside
will only apply it to that host. Additionally, the host `all` can be used
to apply it to all hosts. The `these` key applies its configuration to every
host that is explicitly configured in the same module, while `others` applies
to every host **not** configured in it. Host configurations are able to be
passed arguments such as `pkgs`, `lib`, and everything specified in `specialArgs`.

### Example
`bluetooth.nix`
```nix
{
    # Enable bluetooth on my laptop and desktop.
    these = {pkgs, ...}: {
      environment.systemPackages = [pkgs.blueman];
      hardware.bluetooth.enable = true;
    };

    # Dummy configuration for `these`.
    laptop = {};
    
    # Enable powerOnBoot for my desktop, but not my laptop to save battery life.
    desktop.hardware.bluetooth.powerOnBoot = true;
}
```

# Living Examples
`booyah` is used in the following configs:
1. [mine](https://codeberg.org/poacher/nix-dotfiles)
2. [zushi](https://codeberg.org/zushi/nixos-config)

If you would like your config added here then please open an issue or PR.
