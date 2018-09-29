with import <nixpkgs> {};
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
  name = "my";
  buildInputs = [ sqlite pcre openssl ];
  nativeBuildInputs = [ nim-current ];

  LD_LIBRARY_PATH = ''${sqlite.out}/lib:${pcre.out}/lib:${openssl.out}/lib'';
  NIM_FLAGS = "--path:" + builtins.concatStringsSep ":" nim-deps;
}
