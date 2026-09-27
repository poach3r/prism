# Written by [Llakala](https://github.com/llakala)
lib: let
  inherit (builtins) attrNames concatMap readDir;
  isNixFile = lib.hasSuffix ".nix";

  listNixFilesRecursive = let
    recurse = folder: let
      contents = readDir folder;
    in
      concatMap (
        filename: let
          type = contents.${filename};
        in
          if type == "regular" && isNixFile filename
          then [(folder + "/${filename}")]
          else if type == "directory"
          then recurse (folder + "/${filename}")
          else []
      ) (attrNames contents);
  in
    recurse;
in
  concatMap listNixFilesRecursive
