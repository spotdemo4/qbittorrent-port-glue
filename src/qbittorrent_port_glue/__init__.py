from .qbittorrent import qBittorrent, ConnectionStatus
from os import environ
from watchfiles import watch, Change
from pathlib import Path
import logging
import signal
import threading
import sys

logging.basicConfig(
    level=logging.getLevelName(environ.get("LOG_LEVEL", "INFO").upper()),
    format="%(asctime)s - %(levelname)s - %(message)s",
)
done_event = threading.Event()


# watch port file for changes
def watch_file(qb: qBittorrent, file: Path, done_event: threading.Event) -> None:
    logging.info(f"Watching file {file} for changes")

    for changes in watch(file, stop_event=done_event):
        logging.debug("File changed!")

        # skip checking if connected or offline
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            logging.debug("qBittorrent is connected")
            continue

        if qb_connected == ConnectionStatus.OFFLINE:
            logging.debug("qBittorrent is offline")
            continue

        for change in changes:
            (change_type, path) = change

            # ignore deleted file, wait for next change
            if change_type == Change.deleted:
                logging.warning("Port file deleted!")
                continue

            # get port from file
            file_port = int(file.read_text().strip())

            # get port from qBittorrent
            qb_port = qb.get_port()

            # update qBittorrent if different
            if qb_port == file_port:
                logging.debug(f"Both qBittorrent and file using port {qb_port}")
            else:
                logging.info(f"Updating port ({qb_port} -> {file_port})")
                qb.set_port(file_port)


# periodically check file for changes
def timer_qbit(qb: qBittorrent, file: Path, done_event: threading.Event) -> None:
    while not done_event.is_set():
        logging.debug("Checking qBittorrent connection")

        # skip checking if connected or offline
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            logging.debug("qBittorrent is connected")
            done_event.wait(timeout=30)
            continue

        if qb_connected == ConnectionStatus.OFFLINE:
            logging.debug("qBittorrent is offline")
            done_event.wait(timeout=30)
            continue

        # get port from file
        file_port = int(file.read_text().strip())

        # get port from qBittorrent
        qb_port = qb.get_port()

        # update qBittorrent if different
        if qb_port == file_port:
            logging.debug(f"Both qBittorrent and file using port {qb_port}")
        else:
            logging.info(f"Updating port ({qb_port} -> {file_port})")
            qb.set_port(file_port)

        done_event.wait(timeout=30)


def main() -> None:
    qb = qBittorrent()
    done_event = threading.Event()

    # validate PORT_FILE
    file = Path(environ.get("PORT_FILE"))
    if not file.exists():
        logging.error(f"File {file} does not exist!")
        sys.exit(1)
    if not file.is_file():
        logging.error(f"{file} is not a file!")
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

    def shutdown(signum, frame):
        logging.info("Shutting down")
        done_event.set()

    signal.signal(signal.SIGINT, shutdown)

    file_thread.start()
    qbit_thread.start()

    file_thread.join()
    qbit_thread.join()
