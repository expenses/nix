{ lib
, stdenv
, mkMesonDerivation
, perl
, perlPackages
, meson
, ninja
, pkg-config
, nix-store
, darwin
, version
, curl
, bzip2
, libsodium
}:

let
  inherit (lib) fileset;
in

perl.pkgs.toPerlModule (mkMesonDerivation (finalAttrs: {
  pname = "nix-perl";
  inherit version;

  workDir = ./.;
  fileset = fileset.unions ([
    ./.version
    ../../.version
    ./MANIFEST
    ./lib
    ./meson.build
    ./meson.options
  ] ++ lib.optionals finalAttrs.doCheck [
    ./.yath.rc.in
    ./t
  ]);

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    perl
    curl
  ];

  buildInputs = [
    nix-store
    bzip2
    libsodium
  ];

  # `perlPackages.Test2Harness` is marked broken for Darwin
  doCheck = !stdenv.isDarwin;

  nativeCheckInputs = [
    perlPackages.Test2Harness
  ];

  preConfigure =
    # "Inline" .version so its not a symlink, and includes the suffix
    ''
      chmod u+w .version
      echo ${finalAttrs.version} > .version
    '';

  mesonFlags = [
    (lib.mesonOption "dbi_path" "${perlPackages.DBI}/${perl.libPrefix}")
    (lib.mesonOption "dbd_sqlite_path" "${perlPackages.DBDSQLite}/${perl.libPrefix}")
    (lib.mesonEnable "tests" finalAttrs.doCheck)
  ];

  mesonCheckFlags = [
    "--print-errorlogs"
  ];

  strictDeps = false;
}))
