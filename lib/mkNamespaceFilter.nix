{ pkgs, lib ? pkgs.lib }:
{ includeNamespaces, excludeNamespaces ? [ ], excludeExactNamespaces ? [ ] }:
let
  normalizePath =
    path:
    if builtins.isString path then
      lib.splitString "." path
    else
      path;

  includePaths = map normalizePath includeNamespaces;
  excludePaths = map normalizePath excludeNamespaces;
  excludeExactPaths = map normalizePath excludeExactNamespaces;

  pathIsPrefixOf =
    prefix: path:
    let
      prefixLen = builtins.length prefix;
    in
    builtins.length path >= prefixLen
    && lib.sublist 0 prefixLen path == prefix;

  pathMatchesInclude = path:
    includePaths == [ ]
    || builtins.any (
      includePath:
      pathIsPrefixOf path includePath || pathIsPrefixOf includePath path
    ) includePaths;

  pathMatchesExclude = path:
    builtins.any (excludePath: pathIsPrefixOf excludePath path) excludePaths;

  pathMatchesExactExclude = path:
    builtins.any (excludePath: path == excludePath) excludeExactPaths;
in
path: _node:
  pathMatchesInclude path && !pathMatchesExclude path && !pathMatchesExactExclude path
