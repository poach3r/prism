{
  optional = condition: value:
    if condition
    then [value]
    else [];

  hasSuffix = suffix: let
    lenSuffix = builtins.stringLength suffix;
  in
    if builtins.isPath suffix
    then
      # Before 23.05, paths would be copied to the store before converting them
      # to strings and comparing. This was surprising and confusing.
      throw ''
        lib.strings.hasSuffix: The first argument (${toString suffix}) is a path value, but only strings are supported.
        There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
        This function also copies the path to the Nix store, which may not be what you want.''
    else
      content: let
        lenContent = builtins.stringLength content;
      in
        lenContent >= lenSuffix && builtins.substring (lenContent - lenSuffix) lenContent content == suffix;
}
