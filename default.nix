with import <unstable> {};
stdenv.mkDerivation {
  name = "my";
  buildInputs = [ sqlite pcre openssl ];
  nativeBuildInputs = [ nim ];
  LD_LIBRARY_PATH = ''${sqlite.out}/lib:${pcre.out}/lib:${openssl.out}/lib'';
}
