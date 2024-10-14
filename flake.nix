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
          packages = with pkgs; [
            gnucobol
            clang-tools
            cppcheck
            automake
            autoconf
            libtool
            gnum4
            dotnetCorePackages.sdk_6_0_1xx
            flex
            unixODBC
            mariadb
            spdlog
            fmt
            postgresql
          ];

          shellHook = ''
            PATH="${pkgs.gnucobol}/bin:$PATH"
          '';
        };
      };
    };
}
