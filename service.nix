{
  qbittorrent-port-glue,
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.qbittorrent-port-glue;
in
with lib;
{
  options = {
    services.qbittorrent-port-glue = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''
          Start the qBittorrent port glue service.
        '';
      };

      user = mkOption {
        type = with types; nullOr string;
        description = ''
          Name of the user.
        '';
      };

      host = mkOption {
        type = with types; string;
        description = ''
          qBittorrent host to connect to.
        '';
      };

      port = mkOption {
        type = with types; int;
        description = ''
          qBittorrent port to connect to.
        '';
      };

      username = mkOption {
        type = with types; string;
        description = ''
          qBittorrent username.
        '';
      };

      password = mkOption {
        type = with types; string;
        description = ''
          qBittorrent password.
        '';
      };

      portFile = mkOption {
        type = with types; string;
        description = ''
          Path to the file containing the port number.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.qbittorrent-port-glue = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Keeps the qBittorrent port in sync with a file.";
      serviceConfig = {
        Type = "simple";
        User = mkIf cfg.user "${cfg.user}";
        Environment = [
          "QB_HOST=${cfg.host}"
          "QB_PORT=${toString cfg.port}"
          "QB_USERNAME=${cfg.username}"
          "QB_PASSWORD=${cfg.password}"
          "PORT_FILE=${cfg.portFile}"
        ];
        ExecStart = "${qbittorrent-port-glue}";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    environment.systemPackages = [ qbittorrent-port-glue ];
  };
}
