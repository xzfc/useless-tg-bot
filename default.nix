let nixpkgs-pinned = 
  import (builtins.fetchTarball {
    name = "nixos-unstable-2018-12-17";
    url = https://github.com/nixos/nixpkgs/archive/51deb8951d8910e2706a3c48d9765fc8d410d5f5.tar.gz;
    sha256 = "1mkg1g2hsr4rm6xqyh4v6xjfcllx1lgczc9gaw51n9h1lhxfj71k";
  }) {};
in { nixpkgs ? nixpkgs-pinned }:
with nixpkgs;
let
  nim-common = version: sha256:
    nim.overrideAttrs (attrs: rec {
      name = "nim-${version}";
      inherit version;
      src = fetchurl {
        url = "https://nim-lang.org/download/${name}.tar.xz";
        inherit sha256;
      };

      doCheck = false;
      postPatch = '' rm -rf tests '';
      buildPhase = ''export LD=$CC XDG_CACHE_HOME=$PWD/.cache;'' + attrs.buildPhase;
    });
  nim-current = nim-common "0.19.0" "0biwvw1gividp5lkf0daq1wp9v6ms4xy6dkf5zj0sn9w4m3n76d1";
  nim-deps = [
    (fetchFromGitHub {
      owner  = "xzfc";
      repo   = "ndb.nim";
      rev    = "20e87a8e4067cdd54d658487404c87b263ca1f87";
      sha256 = "06547himxyk5npzypdkgvjzwl9bbmdfdw9scjg7b1n0vwgrlg0k2";
    })
  ];
in
stdenv.mkDerivation {
  name = "useless-tg-bot";
  buildInputs = [ sqlite pcre openssl ];
  nativeBuildInputs = [ nim-current ];
  src = builtins.filterSource (path: _:
    builtins.all (p: path != builtins.toString p) [
      ./.git
      ./default.nix
      ./autogen_modules.nim
      ./main
      ./utils/markov_cli
      ./result
    ]) ./.;
  doConfigure = false;
  buildPhase = ''
    nim $NIM_FLAGS --nimcache:nimcache c main
    nim $NIM_FLAGS --nimcache:nimcache c utils/markov_cli
  '';
  installPhase = ''
    install -Dt $out main utils/markov_cli
  '';
  LD_LIBRARY_PATH =
    if lib.inNixShell
    then ''${sqlite.out}/lib:${pcre.out}/lib:${openssl.out}/lib''
    else null;
  NIM_FLAGS = "--path:" + builtins.concatStringsSep ":" nim-deps;
}
