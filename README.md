# About
`prism` is a library to facilitate complex multi-host NixOS configurations. 
Loosely inspired by the dendritic pattern, all modules specificy the host 
that the configurations therein apply to.

This project was formerly known as `booyah`. It has been renamed to `prism`
after I got peer-pressured. The name comes from how a module can be split (or 
refracted) into various different configurations.

# Installation
## Flakes
1. Add `prism` to your inputs:
```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
        prism = {
            url = "git+https://codeberg.org/poacher/prism.git";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
}
```

2. Create your NixOS configurations with `mkSystems`:
```nix
{ 
    outputs = {nixpkgs, prism, ...}: {
        nixosConfigurations = prism.lib.mkSystems {
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
1. Pin `prism` with your pinner of choice, I'll be using `npins`:
```sh
npins add forgejo codeberg.org poacher prism -b main
```

2. Import `prism` in your NixOS entry-point:
```nix
let 
    inherit (sources) nixpkgs;
    sources = import ./npins;
    prism = import sources.prism;
in {
    # ...
}
```

3. Create your NixOS configurations using `mkSystems`:
```nix
let
    # ...
in {
    nixosConfigurations = prism.mkSystems {
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
2. `modules ? []` non-prism modules to be manually imported.
3. `specialArgs ? {}` arguments to be passed to every module.
4. `system ? "x86_64-linux"` defines the system arch.
5. `pkgs` is the pkgs used by this host.
6. `mkSystem` is the function used internally to create the system. On NixOS this should be `nixpkgs.lib.nixosSystem`, on Darwin this should be set to `nix-darwin.lib.darwinSystem`.

### Example
```nix
nixosConfigurations = mkSystems {
    desktop = {
        inherit pkgs;
        mkSystem = nixpkgs.lib.nixosSystem;
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
to every host not configured in it. Host configurations are able to be
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
`prism` is used in the following configs:
1. [mine](https://tangled.org/poacher.dev/nixos-config)
2. [zushi](https://codeberg.org/zushi/nixos-config)

If you would like your config added here then please open an issue or PR.
