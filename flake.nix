{
  description = "Gixsql";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            automake
            autoconf
            libtool
            pkg-config
            spdlog
            unixODBC
            libmysqlclient
            postgresql
            gmp
          ];

          packages = with pkgs; [
            gnucobol
            clang-tools
            cppcheck
            gnum4
            dotnetCorePackages.sdk_6_0_1xx
            flex
            bison
          ];

          shellHook = ''
            export PATH="${pkgs.gnucobol.bin}/bin:$PATH"
            export LD_LIBRARY_PATH="${pkgs.gnucobol.lib}/lib:$LD_LIBRARY_PATH"
            export GNUCOBOL_BIN="${pkgs.gnucobol.bin}/bin"
            export GNUCOBOL_LIB="${pkgs.gnucobol.lib}/lib"
            export GNUCOBOL_SHARE="${pkgs.gnucobol.bin}/share"
          '';
        };
      };
    };
}
