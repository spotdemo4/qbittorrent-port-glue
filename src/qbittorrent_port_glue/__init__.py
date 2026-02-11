from .qbittorrent import qBittorrent, ConnectionStatus
from os import environ
from watchfiles import watch, Change
import signal
import threading

done_event = threading.Event()


# watch port file for changes
def watch_file(qb: qBittorrent, done_event: threading.Event) -> None:
    for changes in watch(environ.get("PORT_FILE"), stop_event=done_event):
        # skip checking if connected
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            continue

        for change in changes:
            (change_type, path) = change

            # ignore deleted file, wait for next change
            if change_type == Change.deleted:
                print("Port file deleted!")
                continue

            # get port from file
            with open(path, "r") as f:
                port = int(f.read().strip())

            # get port from qBittorrent
            qb_port = qb.get_port()

            # update qBittorrent if different
            if qb_port != port:
                print(f"Updating port ({qb_port} -> {port})")
                qb.set_port(port)


# periodically check file for changes
def timer_qbit(qb: qBittorrent, done_event: threading.Event) -> None:
    while not done_event.is_set():
        # skip checking if connected
        qb_connected = qb.get_connection_status()
        if qb_connected == ConnectionStatus.CONNECTED:
            done_event.wait(timeout=30)
            continue

        # get port from file
        with open(environ.get("PORT_FILE"), "r") as f:
            port = int(f.read().strip())

        # get port from qBittorrent
        qb_port = qb.get_port()

        # update qBittorrent if different
        if qb_port != port:
            print(f"Updating port ({qb_port} -> {port})")
            qb.set_port(port)

        done_event.wait(timeout=30)


def main() -> None:
    qb = qBittorrent()
    done_event = threading.Event()

    file_thread = threading.Thread(
        target=watch_file,
        args=(
            qb,
            done_event,
        ),
    )

    qbit_thread = threading.Thread(
        target=timer_qbit,
        args=(
            qb,
            done_event,
        ),
    )

    def signal_handler(signum, frame):
        print("Signal received, shutting down...")
        done_event.set()

    signal.signal(signal.SIGINT, signal_handler)

    file_thread.start()
    qbit_thread.start()

    file_thread.join()
    qbit_thread.join()
