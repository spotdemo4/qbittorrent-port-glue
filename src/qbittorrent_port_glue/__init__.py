import logging
import signal
import sys
import threading
from os import environ
from pathlib import Path
from types import FrameType

from watchfiles import Change, watch

from .qbittorrent import ConnectionStatus, qBittorrent

LOG_LEVELS = {
    "CRITICAL": logging.CRITICAL,
    "FATAL": logging.FATAL,
    "ERROR": logging.ERROR,
    "WARNING": logging.WARNING,
    "WARN": logging.WARNING,
    "INFO": logging.INFO,
    "DEBUG": logging.DEBUG,
    "NOTSET": logging.NOTSET,
}

logging.basicConfig(
    level=LOG_LEVELS[environ.get("LOG_LEVEL", "INFO").upper()],
    format="%(asctime)s - %(levelname)s - %(message)s",
)
log = logging.getLogger(__name__)


# watch port file for changes
def watch_file(qb: qBittorrent, file: Path, done_event: threading.Event) -> None:
    log.info(f"Watching file {file} for changes")

    for changes in watch(file, stop_event=done_event):
        log.debug("File changed!")

        # skip checking if connected or offline
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            log.debug("qBittorrent is connected")
            continue

        if qb_connected == ConnectionStatus.OFFLINE:
            log.debug("qBittorrent is offline")
            continue

        for change in changes:
            (change_type, _path) = change

            # ignore deleted file, wait for next change
            if change_type == Change.deleted:
                log.warning("Port file deleted!")
                continue

            # get port from file
            file_port = int(file.read_text().strip())

            # get port from qBittorrent
            qb_port = qb.get_port()

            # update qBittorrent if different
            if qb_port == file_port:
                log.debug(f"Both qBittorrent and file using port {qb_port}")
            else:
                log.info(f"Updating port ({qb_port} -> {file_port})")
                qb.set_port(file_port)


# periodically check file for changes
def timer_qbit(qb: qBittorrent, file: Path, done_event: threading.Event) -> None:
    while not done_event.is_set():
        log.debug("Checking qBittorrent connection")

        # skip checking if connected or offline
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            log.debug("qBittorrent is connected")
            _ = done_event.wait(timeout=30)
            continue

        if qb_connected == ConnectionStatus.OFFLINE:
            log.debug("qBittorrent is offline")
            _ = done_event.wait(timeout=30)
            continue

        # get port from file
        file_port = int(file.read_text().strip())

        # get port from qBittorrent
        qb_port = qb.get_port()

        # update qBittorrent if different
        if qb_port == file_port:
            log.debug(f"Both qBittorrent and file using port {qb_port}")
        else:
            log.info(f"Updating port ({qb_port} -> {file_port})")
            qb.set_port(file_port)

        _ = done_event.wait(timeout=30)


def main() -> None:
    qb = qBittorrent()
    done_event = threading.Event()

    # validate PORT_FILE
    port_file = environ.get("PORT_FILE")
    if port_file is None:
        log.error("PORT_FILE is not set!")
        sys.exit(1)

    file = Path(port_file)
    if not file.exists():
        log.error(f"File {file} does not exist!")
        sys.exit(1)
    if not file.is_file():
        log.error(f"{file} is not a file!")
        sys.exit(1)

    file_thread = threading.Thread(
        target=watch_file,
        args=(
            qb,
            file,
            done_event,
        ),
    )

    qbit_thread = threading.Thread(
        target=timer_qbit,
        args=(
            qb,
            file,
            done_event,
        ),
    )

    def shutdown(_signum: int, _frame: FrameType | None) -> None:
        log.info("Shutting down")
        done_event.set()

    _ = signal.signal(signal.SIGINT, shutdown)

    file_thread.start()
    qbit_thread.start()

    file_thread.join()
    qbit_thread.join()
