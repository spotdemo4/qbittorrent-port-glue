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
    trevpkgs = {
      url = "github:spotdemo4/trevpkgs";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      trevpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      pyprojectOverlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };
    in
    trevpkgs.libs.mkFlake (
      system: pkgs:
      let
        python = pkgs.python314;
        pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
          pkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            pyprojectOverlay
          ]
        );
        editablePythonSet = pythonSet.overrideScope editableOverlay;
        developmentVirtualenv = editablePythonSet.mkVirtualEnv "qbittorrent-port-glue-dev-env" workspace.deps.all;
      in
      {
        devShells = {
          default = pkgs.mkShell {
            shellHook = ''
              ${pkgs.shellhook.ref}
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = editablePythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
              UV_PROJECT_ENVIRONMENT = developmentVirtualenv;
              VIRTUAL_ENV = developmentVirtualenv;
            };
            packages = with pkgs; [
              # python
              developmentVirtualenv
              uv

              vscode-json-languageserver # json
              yaml-language-server # yaml
              tombi # toml
              oxfmt # format

              # nix
              nixd
              nixfmt

              # util
              treefmt
              bumper
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

              # python
              python
              uv
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate

              # python
              python
              uv
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              pysentry # python
              flake-checker # nix
              zizmor # actions
            ];
          };
        };

        packages =
          let
            inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;
          in
          {
            default =
              (mkApplication {
                venv = pythonSet.mkVirtualEnv "qbittorrent-port-glue-env" workspace.deps.default;
                package = pythonSet.qbittorrent-port-glue;
              }).overrideAttrs
                (old: {
                  meta = (old.meta or { }) // {
                    mainProgram = "qbittorrent-port-glue";
                    description = "glues qbittorrent's port to a file";
                    license = pkgs.lib.licenses.mit;
                    platforms = pkgs.lib.platforms.all;
                    homepage = "https://github.com/spotdemo4/qbittorrent-port-glue";
                    changelog = "https://github.com/spotdemo4/qbittorrent-port-glue/releases";
                    downloadPage = "https://github.com/spotdemo4/qbittorrent-port-glue/releases/tag/v${pythonSet.qbittorrent-port-glue.version}";
                  };
                });
          };

        images.default = pkgs.mkImage {
          src = self.packages.${system}.default;
          contents = with pkgs; [ dockerTools.caCertificates ];
        };

        nixosModules.default =
          { pkgs, ... }:
          {
            imports = [
              (import ./service.nix {
                qbittorrent-port-glue = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              })
            ];
          };

        formatter = pkgs.treefmt.withConfig {
          configFile = ./treefmt.toml;
          runtimeInputs = with pkgs; [
            developmentVirtualenv
            oxfmt
            nixfmt
          ];
        };

        checks = pkgs.mkChecks {
          package = self.packages.${system}.default;

          python = {
            root = ./.;
            filter = file: file.hasExt "py";
            include = [
              ./.python-version
              ./pyproject.toml
              ./uv.lock
            ];
            packages = [ developmentVirtualenv ];
            script = ''
              ruff check
              basedpyright
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            packages = with pkgs; [
              nixfmt
            ];
            script = ''
              nixfmt --check "$file"
            '';
          };

          actions-gh = {
            root = ./.github/workflows;
            filter = file: file.hasExt "yaml";
            packages = with pkgs; [
              action-validator
              zizmor
            ];
            script = ''
              action-validator "$file"
              zizmor --offline "$file"
            '';
          };

          renovate-gh = {
            root = ./.github;
            files = ./.github/renovate.json;
            packages = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          config = {
            root = ./.;
            filter = file: file.hasExt "json" || file.hasExt "yaml" || file.hasExt "toml" || file.hasExt "md";
            packages = with pkgs; [
              oxfmt
            ];
            script = ''
              oxfmt --check
            '';
          };
        };
      }
    );
}
