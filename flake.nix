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
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    trev = {
      url = "github:spotdemo4/nur";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      trev,
      ...
    }:
    trev.libs.mkFlake (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            trev.overlays.packages
            trev.overlays.libs
          ];
        };
        fs = pkgs.lib.fileset;
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
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              # python
              pysentry

              # flake
              flake-checker

              # actions
              octoscan
            ];
          };
        };

        checks = pkgs.lib.mkChecks {
          python = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.unions [
                ./uv.lock
                ./pyproject.toml
                ./.python-version
                (fs.fileFilter (file: file.hasExt "py") ./.)
              ];
            };
            deps = with pkgs; [
              ruff
            ];
            script = ''
              ruff check
            '';
          };

          nix = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "nix") ./.;
            };
            deps = with pkgs; [
              nixfmt-tree
            ];
            script = ''
              treefmt --ci
            '';
          };

          renovate = {
            src = fs.toSource {
              root = ./.github;
              fileset = ./.github/renovate.json;
            };
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          actions = {
            src = fs.toSource {
              root = ./.github/workflows;
              fileset = ./.github/workflows;
            };
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            script = ''
              action-validator **/*.yaml
              octoscan scan .
            '';
          };

          prettier = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md") ./.;
            };
            deps = with pkgs; [
              prettier
            ];
            script = ''
              prettier --check .
            '';
          };
        };

        apps = pkgs.lib.mkApps {
          dev.script = "uv run qbittorrent-port-glue";
        };

        packages = with pkgs.lib; rec {
          default = pkgs.python314Packages.buildPythonPackage (finalAttrs: {
            pname = "qbittorrent-port-glue";
            version = "0.0.1";
            pyproject = true;

            src = fs.toSource {
              root = ./.;
              fileset = fs.difference ./. (
                fs.unions [
                  ./.vscode
                  ./.github/workflows
                  ./flake.nix
                  ./flake.lock
                ]
              );
            };

            propagatedBuildInputs = with pkgs.python314Packages; [
              qbittorrent-api
              watchfiles
            ];

            build-system = with pkgs.python314Packages; [
              setuptools
              uv-build
            ];

            meta = {
              description = "glues qbittorrent's port to a file";
              mainProgram = "qbittorrent-port-glue";
              homepage = "https://github.com/spotdemo4/qbittorrent-port-glue";
              changelog = "https://github.com/spotdemo4/qbittorrent-port-glue/releases/tag/v${finalAttrs.version}";
              license = licenses.mit;
              platforms = platforms.all;
            };
          });

          image = pkgs.dockerTools.buildLayeredImage {
            name = default.pname;
            tag = default.version;

            contents = with pkgs; [
              dockerTools.caCertificates
            ];

            created = "now";
            meta = default.meta;

            config = {
              Entrypoint = [ "${meta.getExe default}" ];
              Labels = {
                "org.opencontainers.image.title" = default.pname;
                "org.opencontainers.image.description" = default.meta.description;
                "org.opencontainers.image.version" = default.version;
                "org.opencontainers.image.source" = default.meta.homepage;
                "org.opencontainers.image.licenses" = default.meta.license.spdxId;
              };
            };
          };
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
