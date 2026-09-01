import logging
from enum import Enum
from os import environ
from typing import cast, final

from qbittorrentapi import Client
from qbittorrentapi.exceptions import NotFound404Error

log = logging.getLogger(__name__)


class ConnectionStatus(Enum):
    CONNECTED = "connected"
    FIREWALLED = "firewalled"
    DISCONNECTED = "disconnected"
    OFFLINE = "offline"


@final
class qBittorrent:
    def __init__(self) -> None:
        self._client = Client(
            host=environ["QBITTORRENT_HOST"],
            port=environ.get("QBITTORRENT_PORT"),
            username=environ.get("QBITTORRENT_USER"),
            password=environ.get("QBITTORRENT_PASS"),
        )

    def get_port(self) -> int:
        port = cast(int, self._client.app.preferences.listen_port)
        log.debug(f"Got port: {port}")
        return port

    def set_port(self, port: int) -> None:
        self._client.app.preferences = {"listen_port": port}
        log.debug(f"Set port: {port}")

    def get_connection_status(self) -> ConnectionStatus:
        try:
            status = ConnectionStatus(
                cast(str, self._client.transfer.info.connection_status)
            )
            log.debug(f"Connection status {status}")
            return status
        except NotFound404Error as e:
            log.warning(f"Could not connect to qBittorrent: {e}")
        except Exception as e:  # noqa: BLE001
            log.warning(f"An error occurred: {e}")

        return ConnectionStatus.OFFLINE
