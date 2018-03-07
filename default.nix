with import <unstable> {};
let
  nim-018 = 
    nim.overrideAttrs (attrs: rec {
      name = "nim-${version}";
      version = "0.18.0";
      src = fetchurl {
        url = "https://nim-lang.org/download/${name}.tar.xz";
        sha256 = "1l1vdygbgs5fdh2ffdjapcp90p8f6cbsw4hivndgm3gh6pdlmis5";
      };
      doCheck = false;
    });
in
stdenv.mkDerivation {
  name = "my";
  buildInputs = [ sqlite pcre openssl ];
  nativeBuildInputs = [ nim-018 ];
  LD_LIBRARY_PATH = ''${sqlite.out}/lib:${pcre.out}/lib:${openssl.out}/lib'';
}
