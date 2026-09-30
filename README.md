# prism
`prism` is a library for multi-host NixOS and nix-darwin configurations. Rather
than writing a configuration per host, you describe your machines with tags,
and every module splits (or refracts) its configuration across those tags.

```nix
# flake.nix
tags = self: {
    graphical = {};
    laptop = {
        build = true;
        parents = [self.graphical];
    };
    desktop = {
        build = true;
        parents = [self.graphical];
    };
    server.build = true;
};
```

```nix
# modules/bluetooth.nix
{
    graphical.hardware.bluetooth.enable = true;
    desktop.hardware.bluetooth.powerOnBoot = true;
}
```

`laptop` and `desktop` get bluetooth, only `desktop` powers it on at boot, and
`server` gets neither.

# Features
## Tags with multiple parents
A tag selects its own sections along with those of every ancestor. Tags can
have any number of parents, so machines are described by what they are rather
than by which list they appear in.

```nix
tags = self: {
    graphical = {};
    workstation.parents = [self.graphical];
    gaming.parents = [self.graphical];
    laptop = {
        build = true;
        parents = [self.workstation];
    };
    desktop = {
        build = true;
        parents = [self.workstation self.gaming];
    };
    deck = {
        build = true;
        parents = [self.gaming];
    };
};
```

## Conditional tags
A tag with `select` decides whether it's active on a per-module basis. Here,
`chaotic` applies to every system with the tag, except in modules
which also configure `gaming`, where it only applies to gaming systems.

```nix
chaotic.select = {module, rootTags, ...}:
    !(module ? ${self.gaming.name}) || builtins.elem self.gaming.name rootTags;
```

## Settings per tag
`pkgs`, `mkSystem`, and `specialArgs` are set once in `mkSystems` and may be
overridden by any tag. Systems inherit them from their most specific tag which
sets them.

```nix
tags = self: {
    arm.pkgs = nixpkgs.legacyPackages.x86_64-linux;
    desktop = {
        build = true;
        parents = [self.arm];
    };
    mac = {
        build = true;
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        mkSystem = nix-darwin.lib.darwinSystem;
    };
};
```

## Modules per tag
Tags can bring their own `modules` and `extraModules`, so external modules
follow the tag which uses them instead of being listed for every host.

```nix
agenix.extraModules = [agenix.nixosModules.default];
```

# Tutorials
## Installation
### Flakes
1. Add `prism` to your inputs:
```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
        prism.url = "git+https://codeberg.org/poacher/prism.git";
    };
}
```

2. Create your NixOS configurations with `mkSystems`:
```nix
{
    outputs = {nixpkgs, prism, ...}: {
        nixosConfigurations = prism.lib.mkSystems {
            mkSystem = nixpkgs.lib.nixosSystem;
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            modules = prism.lib.recursivelyImport [./modules];
            tags = self: {
                # ...
            };
        };
    };
}
```

### Non-Flakes
1. Pin `prism` with your pinner of choice, I'll be using `npins`:
```sh
npins add git https://tangled.org/poacher.dev/prism -b main
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
        mkSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";
        pkgs = import nixpkgs {};
        modules = prism.recursivelyImport [./modules];
        tags = self: {
            # ...
        };
    };
}
```

## Getting Started
1. Describe your machines. Every tag with `build = true` becomes a system, and
the `all` preset allows them to share configs:
```nix
tags = self: {
    inherit (prism.lib.presets) all;
    graphical.parents = [self.all];
    laptop = {
        build = true;
        parents = [self.all self.graphical];
    };
    server = {
        build = true;
        parents = [self.all];
    };
};
```

2. Write a module. Each section is standard NixOS configuration, keyed by the
tag it applies to:
```nix
# modules/desktop-environment.nix
{
    all.services.openssh.enable = true;
    laptop.services.power-profiles-daemon.enable = true;
    graphical = {pkgs, ...}: {
        services.desktopManager.plasma6.enable = true;
        environment.systemPackages = [pkgs.firefox];
    };
}
```

# Reference
## mkSystems
`mkSystems` creates a system for every tag with `build = true`. It accepts the
following arguments:

1. `tags` a function from the finished tag set (`self`) to tag definitions.
2. `modules ? []` prism module files.
3. `extraModules ? []` non-prism modules imported into every system.
4. `mkSystem` the function used to create each system. On NixOS this should
be `nixpkgs.lib.nixosSystem`, on Darwin this should be
`nix-darwin.lib.darwinSystem`.
5. `pkgs ? null` the nixpkgs instance, set as `nixpkgs.pkgs`.
6. `specialArgs ? {}` arguments passed to every module.

## Tags
Each tag is an attribute set which may contain:

1. `parents ? []` tags whose sections are also selected, referenced through
`self` (e.g. `self.graphical`).
2. `build ? false` whether this tag is a system.
3. `select` a function deciding, per module, whether this tag is active.
4. `mkSystem`, `pkgs`, `specialArgs` overrides of the `mkSystems` defaults.
5. `modules`, `extraModules` additions to the `mkSystems` lists.

## select
`select` receives the following and returns a bool:

1. `root` the tag being built.
2. `rootTags` the names of `root` and all of its ancestors.
3. `tag` the tag being selected.
4. `module` the prism module being selected from.
5. `path` the path of that module.
6. `tags` every tag.

## Modules
Modules are attribute sets of tag sections. Each section is standard
configuration passed to `mkSystem` which only applies to systems where its tag
is selected.

## lib.presets
1. `all` a tag to be used as a parent of every system.
2. `these` a tag which is active when the module has a section for any of the
built tag's tags, other than `all`, `these`, and `others`.
3. `others` a tag which is active when `these` isn't.

## lib.closureOf
`closureOf` returns the names of a tag and all of its parents. It can be used
to pass a system's tags to its modules:

```nix
laptop = {
    build = true;
    specialArgs.tags = prism.lib.closureOf self.laptop;
};
```

## lib.recursivelyImport
`recursivelyImport` returns every `.nix` file within a list of paths. Files
starting with `_` are ignored.

## readOnlyPkgs
On NixOS, importing `nixpkgs.nixosModules.readOnlyPkgs` through `extraModules` is
recommended as it prevents modules from reconfiguring `pkgs`.

# Living Examples
`prism` is used in the following configs:
1. [mine](https://tangled.org/poacher.dev/nixos-config)
2. [zushi](https://codeberg.org/zushi/nixos-config)

If you would like your config added here then please open an issue or PR.

# History
This project was formerly known as `booyah`. It has been renamed to `prism`
after I got peer-pressured.
