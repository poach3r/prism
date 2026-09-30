tags: let
  inherit (builtins) attrNames attrValues concatMap elem filter;
  parentNames = concatMap (tag: map (parent: parent.name) (tag.parents or [])) (attrValues tags);
in
  filter (name: !(elem name parentNames)) (attrNames tags)
