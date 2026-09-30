{optional}: {
  tags,
  mkSystem ? null,
  pkgs ? null,
  specialArgs ? {},
  modules ? [],
  extraModules ? [],
}: let
  inherit
    (builtins)
    any
    attrNames
    attrValues
    concatMap
    concatStringsSep
    elem
    filter
    foldl'
    genericClosure
    head
    isAttrs
    isBool
    length
    listToAttrs
    mapAttrs
    ;

  defaults = {inherit mkSystem pkgs specialArgs;};
  settingNames = attrNames defaults;
  moduleLists = {inherit modules extraModules;};
  tagFields = ["parents" "build" "select"] ++ settingNames ++ attrNames moduleLists;

  fail = message: throw "prism: ${message}";
  list = concatStringsSep ", ";

  checkTag = name: tag: let
    unknownFields = filter (field: !(elem field tagFields)) (attrNames tag);
  in
    if !isAttrs tag
    then fail "tag '${name}' must be an attribute set"
    else if unknownFields != []
    then fail "tag '${name}' has unknown fields: ${list unknownFields}"
    else if tag ? select && tag.build or false
    then fail "tag '${name}' is built, so it can't have a select"
    else if tag ? select && tag ? modules
    then fail "tag '${name}' has a select, so it can't set modules"
    else tag // {inherit name;};

  registry = let
    self = mapAttrs checkTag (tags self);
  in
    self;

  parentsOf = tag:
    map (
      parent:
        if isAttrs parent && parent ? name && registry ? ${parent.name}
        then registry.${parent.name}
        else fail "tag '${tag.name}' has a parent that isn't a tag reference; use self.<tag>"
    )
    (tag.parents or []);

  # Names of `root` and every ancestor reachable through parents accepted by `follow`.
  walk = follow: root:
    map (entry: entry.key) (genericClosure {
      startSet = [{key = root.name;}];
      operator = {key}:
        map (parent: {key = parent.name;})
        (filter follow (parentsOf registry.${key}));
    });

  ancestorsOf = walk (_: true);

  cyclicTags = root:
    filter
    (name: any (parent: elem name (ancestorsOf parent)) (parentsOf registry.${name}))
    (ancestorsOf root);

  # A value defined by a tag overrides any defined by that tag's ancestors.
  resolve = root: what: defines: get: fallback: let
    definers = filter (name: defines registry.${name}) (ancestorsOf root);
    overridden = definer: any (other: other != definer && elem definer (ancestorsOf registry.${other})) definers;
    nearest = filter (definer: !overridden definer) definers;
  in
    if nearest == []
    then fallback
    else if length nearest == 1
    then get registry.${head nearest}
    else fail "'${root.name}' inherits ${what} from unrelated tags ${list nearest}; set it on '${root.name}'";

  settingOf = root: name: resolve root name (tag: tag ? ${name}) (tag: tag.${name}) defaults.${name};

  specialArgsOf = root: let
    argNames = attrNames (foldl' (args: name: args // registry.${name}.specialArgs or {}) specialArgs (ancestorsOf root));
    resolveArg = arg:
      resolve root "specialArgs.${arg}"
      (tag: tag ? specialArgs.${arg})
      (tag: tag.specialArgs.${arg})
      specialArgs.${arg};
  in
    listToAttrs (map (arg: {
        name = arg;
        value = resolveArg arg;
      })
      argNames);

  importModule = path: let
    module = import path;
    undefinedTags = filter (key: !(registry ? ${key})) (attrNames module);
  in
    if !isAttrs module
    then fail "${toString path} must be an attribute set of tag sections"
    else if undefinedTags != []
    then fail "${toString path} uses undefined tags: ${list undefinedTags}"
    else {inherit path module;};

  # Every ancestor's list merged with the mkSystems default.
  mergedOf = root: name: moduleLists.${name} ++ concatMap (tag: registry.${tag}.${name} or []) (ancestorsOf root);

  uniquePaths = paths:
    map (entry: entry.path) (genericClosure {
      startSet =
        map (path: {
          key = toString path;
          inherit path;
        })
        paths;
      operator = _: [];
    });

  isActive = context: tag:
    if !(tag ? select)
    then true
    else let
      active = tag.select (context // {inherit tag;});
    in
      if isBool active
      then active
      else fail "select of tag '${tag.name}' must return a bool";

  sectionsOf = root: rootTags: {
    path,
    module,
  }: let
    active =
      walk (isActive {
        inherit root rootTags path module;
        tags = registry;
      })
      root;
  in
    # `_file` makes module system errors point at the source file.
    map (name: {
      _file = path;
      imports = [module.${name}];
    })
    (filter (name: elem name active) (attrNames module));

  buildSystem = root: let
    cycle = cyclicTags root;
    rootMkSystem = settingOf root "mkSystem";
    rootPkgs = settingOf root "pkgs";
    prismModules = map importModule (uniquePaths (mergedOf root "modules"));
  in
    if cycle != []
    then fail "tags ${list cycle} form a cycle"
    else if rootMkSystem == null
    then fail "'${root.name}' has no mkSystem; set it in mkSystems or on a tag"
    else
      rootMkSystem {
        specialArgs = specialArgsOf root;
        modules =
          concatMap (sectionsOf root (ancestorsOf root)) prismModules
          ++ mergedOf root "extraModules"
          ++ optional (rootPkgs != null) {nixpkgs.pkgs = rootPkgs;};
      };
in
  listToAttrs (map (root: {
    inherit (root) name;
    value = buildSystem root;
  }) (filter (tag: tag.build or false) (attrValues registry)))
