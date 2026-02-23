from enum import Enum
from os import environ
from qbittorrentapi import Client
from qbittorrentapi.exceptions import NotFound404Error
import logging

log = logging.getLogger(__name__)


class ConnectionStatus(Enum):
    CONNECTED = "connected"
    FIREWALLED = "firewalled"
    DISCONNECTED = "disconnected"
    OFFLINE = "offline"


class qBittorrent:
    def __init__(self):
        conn_info = dict(
            host=environ.get("QBITTORRENT_HOST"),
            port=environ.get("QBITTORRENT_PORT"),
            username=environ.get("QBITTORRENT_USER"),
            password=environ.get("QBITTORRENT_PASS"),
        )
        self._client = Client(**conn_info)

    def get_port(self) -> int:
        port = self._client.app.preferences.listen_port
        log.debug(f"Got port: {port}")
        return port

    def set_port(self, port: int) -> None:
        self._client.app.preferences = dict(listen_port=port)
        log.debug(f"Set port: {port}")

    def get_connection_status(self) -> ConnectionStatus:
        try:
            status = ConnectionStatus(self._client.transfer.info.connection_status)
            log.debug(f"Connection status {status}")
            return status
        except NotFound404Error as e:
            log.warning(f"Could not connect to qBittorrent: {e}")
        except Exception as e:
            log.warning(f"An error occurred: {e}")

        return ConnectionStatus.OFFLINE
