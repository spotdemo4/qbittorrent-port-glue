{
  description = "qbittorrent port glue";

  nixConfig = {
    extra-substituters = [
      "https://nix.trev.zip"
    ];
    extra-trusted-public-keys = [
      "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
    ];
  };

  inputs = {
    systems.url = "github:spotdemo4/systems";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    trev = {
      url = "github:spotdemo4/nur";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      trev,
      ...
    }:
    trev.libs.mkFlake (
      system: init:
      let
        pkgs = init.appendOverlays [ trev.overlays.python ];
      in
      {
        devShells = {
          default = pkgs.mkShell {
            shellHook = pkgs.shellhook.ref;
            packages = with pkgs; [
              # python
              python314
              uv

              # lint
              ruff

              # format
              nixfmt
              prettier

              # util
              bumper
              flake-release
              renovate
            ];
          };

          bump = pkgs.mkShell {
            packages = with pkgs; [
              bumper
            ];
          };

          release = pkgs.mkShell {
            packages = with pkgs; [
              flake-release
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate

              # python
              python314
              uv
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              pysentry # python
              flake-checker # flake
              octoscan # actions
            ];
          };
        };

        checks = pkgs.mkChecks {
          python = {
            src = self.packages.${system}.default;
            deps = with pkgs; [
              ruff
            ];
            script = ''
              ruff check
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            deps = with pkgs; [
              nixfmt
            ];
            forEach = ''
              nixfmt --check "$file"
            '';
          };

          renovate = {
            root = ./.github;
            fileset = ./.github/renovate.json;
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          actions = {
            root = ./.;
            fileset = ./.github/workflows;
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            forEach = ''
              action-validator "$file"
              octoscan scan "$file"
            '';
          };

          prettier = {
            root = ./.;
            filter = file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md";
            deps = with pkgs; [
              prettier
            ];
            forEach = ''
              prettier --check "$file"
            '';
          };
        };

        apps = pkgs.mkApps {
          dev = "uv run qbittorrent-port-glue";
        };

        packages = with pkgs.lib; {
          default = pkgs.python314Packages.buildPythonPackage (finalAttrs: {
            pname = "qbittorrent-port-glue";
            version = "0.1.1";
            pyproject = true;

            src = fileset.toSource {
              root = ./.;
              fileset = fileset.unions [
                ./.python-version
                ./pyproject.toml
                ./uv.lock
                ./.github/README.md
                ./src
              ];
            };

            propagatedBuildInputs = with pkgs.python314Packages; [
              qbittorrent-api
              watchfiles
            ];

            build-system = with pkgs.python314Packages; [
              setuptools
              uv-build.latest
            ];

            meta = {
              description = "glues qbittorrent's port to a file";
              mainProgram = "qbittorrent-port-glue";
              license = licenses.mit;
              platforms = platforms.all;
              homepage = "https://github.com/spotdemo4/qbittorrent-port-glue";
              changelog = "https://github.com/spotdemo4/qbittorrent-port-glue/releases/tag/v${finalAttrs.version}";
              downloadPage = "https://github.com/spotdemo4/qbittorrent-port-glue/releases/tag/v${finalAttrs.version}";
            };
          });
        };

        images = {
          default = pkgs.mkImage self.packages.${system}.default {
            contents = with pkgs; [ dockerTools.caCertificates ];
          };
        };

        nixosModules = {
          default = import ./service.nix {
            qbittorrent-port-glue = self.packages.${system}.default;
          };
        };

        formatter = pkgs.nixfmt-tree;
        schemas = trev.schemas;
      }
    );
}
