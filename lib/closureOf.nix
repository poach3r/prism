tag:
map (entry: entry.key) (builtins.genericClosure {
  startSet = [
    {
      key = tag.name;
      inherit tag;
    }
  ];
  operator = {tag, ...}:
    map (parent: {
      key = parent.name;
      tag = parent;
    }) (tag.parents or []);
})
