# https://github.com/llakala/synaptic-standard/blob/9365c4b7dc5c5d11685b0165bac88114c24df74b/demo/recursivelyImport.nix
lib: let
  inherit (lib) concatMap hasSuffix;
  inherit (builtins) isPath filter readFileType;

  expandIfFolder = elem:
    if !isPath elem || readFileType elem != "directory"
    then [elem]
    else lib.filesystem.listFilesRecursive elem;
in
  list:
    filter
    # Filter out any path that doesn't look like `*.nix`. Don't forget to use
    # toString to prevent copying paths to the store unnecessarily
    (elem: !isPath elem || hasSuffix ".nix" (toString elem))
    # Expand any folder to all the files within it.
    (concatMap expandIfFolder list)
