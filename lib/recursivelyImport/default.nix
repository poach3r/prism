# Written by [Llakala](https://github.com/llakala) and modified by me
lib: let
  inherit (builtins) attrNames concatMap readDir substring;
  isModuleFile = filename: lib.hasSuffix ".nix" filename || lib.hasSuffix ".psn" filename;
  isIgnored = filename: substring 0 1 filename == "_";
  # Built files in `.parsnip` aren't modules themselves
  isBuildDir = filename: filename == ".parsnip";

  listNixFilesRecursive = let
    recurse = folder: let
      contents = readDir folder;
    in
      concatMap (
        filename: let
          type = contents.${filename};
        in
          if type == "regular" && isModuleFile filename && !isIgnored filename
          then [(folder + "/${filename}")]
          else if type == "directory" && !isBuildDir filename
          then recurse (folder + "/${filename}")
          else []
      ) (attrNames contents);
  in
    recurse;
in
  concatMap listNixFilesRecursive
