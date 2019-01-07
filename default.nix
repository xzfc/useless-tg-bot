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
  nim-current = nim-common "0.18.0" "1l1vdygbgs5fdh2ffdjapcp90p8f6cbsw4hivndgm3gh6pdlmis5";
  nim-deps = [
    (fetchFromGitHub {
      owner  = "xzfc";
      repo   = "ndb.nim";
      rev    = "v0.19.3";
      sha256 = "0af0b9ws1i95bsdwx3sgy5vp49bxxz8psf2c1ck00z7d8vi98czf";
    })
  ];
in
stdenv.mkDerivation {
  name = "useless-tg-bot";
  buildInputs = [ sqlite pcre openssl ];
  nativeBuildInputs = [ nim-current gettext ];
  src = builtins.filterSource (path: _:
    builtins.all (p: path != builtins.toString p) [
      ./.git
      ./default.nix
      ./autogen_modules.nim
      ./main
      ./utils/markov_cli
      ./result
      ./nimcache
    ] &&
    !builtins.any (p: builtins.isList (builtins.match p path)) [
      ".*.mo$"
      ".*.po~$"
    ]) ./.;
  doConfigure = false;
  installPhase = ''
    install -Dt $out main utils/markov_cli
    install -DT {,"$out/"}po/ru/LC_MESSAGES/holy.mo
  '';
  LD_LIBRARY_PATH =
    if lib.inNixShell
    then ''${sqlite.out}/lib:${pcre.out}/lib:${openssl.out}/lib''
    else null;
  NIM_FLAGS = "--path:" + builtins.concatStringsSep ":" nim-deps;
}
