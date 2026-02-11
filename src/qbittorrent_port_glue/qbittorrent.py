from enum import Enum
from os import environ
from qbittorrentapi import Client


class ConnectionStatus(Enum):
    CONNECTED = "connected"
    FIREWALLED = "firewalled"
    DISCONNECTED = "disconnected"


class qBittorrent:
    def __init__(self):
        conn_info = dict(
            host=environ.get("QBITTORRENT_HOST"),
            port=environ.get("QBITTORRENT_PORT"),
            username=environ.get("QBITTORRENT_USER"),
            password=environ.get("QBITTORRENT_PASS"),
        )
        self._client = Client(**conn_info)
        print("Connected to qBittorrent")

    def get_port(self) -> int:
        return self._client.app.preferences.listen_port

    def set_port(self, port: int) -> None:
        self._client.app.preferences = dict(listen_port=port)

    def get_connection_status(self) -> ConnectionStatus:
        return ConnectionStatus(self._client.transfer.info.connection_status)
