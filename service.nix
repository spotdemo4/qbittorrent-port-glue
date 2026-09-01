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
{
  options = {
    services.qbittorrent-port-glue = {
      enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Start the qBittorrent port glue service.
        '';
      };

      user = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        description = ''
          Name of the user.
        '';
      };

      host = lib.mkOption {
        type = lib.types.str;
        description = ''
          qBittorrent host to connect to.
        '';
      };

      port = lib.mkOption {
        type = lib.types.int;
        description = ''
          qBittorrent port to connect to.
        '';
      };

      username = lib.mkOption {
        type = lib.types.str;
        description = ''
          qBittorrent username.
        '';
      };

      password = lib.mkOption {
        type = lib.types.str;
        description = ''
          qBittorrent password.
        '';
      };

      portFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          Path to the file containing the port number.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.qbittorrent-port-glue = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Keeps the qBittorrent port in sync with a file.";
      environment = {
        QBITTORRENT_HOST = cfg.host;
        QBITTORRENT_PORT = toString cfg.port;
        QBITTORRENT_USER = cfg.username;
        QBITTORRENT_PASS = cfg.password;
        PORT_FILE = cfg.portFile;
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe qbittorrent-port-glue;
        Restart = "always";
        RestartSec = "5s";
      }
      // lib.optionalAttrs (cfg.user != null) {
        User = cfg.user;
      };
    };

    environment.systemPackages = [ qbittorrent-port-glue ];
  };
}
