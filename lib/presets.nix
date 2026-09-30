let
  inherit (builtins) any elem filter;

  # Every system has `all`, `these`, and `others`, so they can't mark a module as its own.
  mentionsRoot = {
    module,
    rootTags,
    ...
  }:
    any (tag: module ? ${tag})
    (filter (tag: !(elem tag ["all" "these" "others"])) rootTags);
in {
  all = {};
  these.select = mentionsRoot;
  others.select = context: !(mentionsRoot context);
}
