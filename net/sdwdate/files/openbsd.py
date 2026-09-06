# SPDX-License-Identifier: AGPL-3.0-or-later
"""OpenBSD service boundary; upstream owns pool selection and median logic."""
import argparse
from contextlib import contextmanager
from datetime import timezone
import html
import ipaddress
import json
import logging
from logging.handlers import SysLogHandler
import math
import os
from pathlib import Path
import re
import signal
import socket
import select
import sys
import tempfile
import threading
import time
from urllib.parse import urlsplit

CONFIG = Path("${SYSCONFDIR}/sdwdate.d")
STATE = Path("/var/db/sdwdate")
RUNTIME = Path("/var/run/sdwdate")
# Release date, not the possibly incorrect build or boot clock.
RELEASE_FLOOR = 1787616000  # 2026-08-25 00:00:00 UTC
EXPIRATION = 1999936800     # Same upper bound as upstream timesanitycheck.


def sanitize_string(value):
    value = html.unescape(re.sub(r"<[^>]*>", " ", str(value)))
    return "".join(c for c in value if c.isprintable() or c == "\n")


def settings():
    values = {"PROXY_IP": "127.0.0.1", "PROXY_PORT": "9050",
              "CONTROL_PORT": "9051"}
    for path in sorted(CONFIG.glob("*.conf")):
        for line in path.read_text().splitlines():
            key, sep, value = line.partition("=")
            if sep and key in values:
                values[key] = value.split("#", 1)[0].strip()
    # An IP literal prevents local DNS resolution of the SOCKS endpoint.
    address = ipaddress.ip_address(values["PROXY_IP"])
    if not address.is_loopback:
        raise ValueError("PROXY_IP must be a loopback Tor SOCKS address")
    for key in ("PROXY_PORT", "CONTROL_PORT"):
        if not values[key].isascii() or not values[key].isdecimal() or not 1 <= int(values[key]) <= 65535:
            raise ValueError("invalid " + key)
    return values


@contextmanager
def tor_controller():
    from stem.control import Controller
    from stem.connection import authenticate_safecookie
    from stem.socket import ControlPort

    class BoundedControlPort(ControlPort):
        def _make_socket(self):
            return socket.create_connection((self.address, self.port), timeout=10)

    transport = BoundedControlPort(address="127.0.0.1", port=int(settings()["CONTROL_PORT"]))
    with Controller(transport) as control:
        # Never allow NULL authentication, prompt for passwords, or downgrade
        # to sending the raw cookie. This capability controls Tor completely.
        authenticate_safecookie(control, "/var/run/tor-sdwdate/control.authcookie")
        yield control


def consensus_time(value):
    from dateutil.parser import parse
    parsed = parse(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return int(parsed.timestamp())


def minimum_time():
    checkpoint = STATE / "time-replay-protection-utc-unixtime"
    try:
        raw = checkpoint.read_text().strip()
    except FileNotFoundError:
        return RELEASE_FLOOR
    if not raw.isascii() or not raw.isdecimal():
        raise ValueError("invalid replay checkpoint")
    value = int(raw)
    if not RELEASE_FLOOR <= value <= EXPIRATION:
        raise ValueError("replay checkpoint out of range")
    return max(RELEASE_FLOOR, value)


def atomic_write(path, value):
    fd, name = tempfile.mkstemp(prefix=".sdwdate-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as out:
            out.write(value)
            out.flush()
            os.fsync(out.fileno())
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def validate_url(url):
    parsed = urlsplit(url)
    if parsed.scheme not in ("http", "https") or parsed.username or parsed.password or parsed.fragment:
        raise ValueError("only onion HTTP(S) time sources are supported")
    host = parsed.hostname or ""
    if not re.fullmatch(r"(?:[a-z0-9-]+\.)*[a-z2-7]{56}\.onion", host):
        raise ValueError("time source must use a v3 onion hostname")
    if parsed.port is not None and not 1 <= parsed.port <= 65535:
        raise ValueError("invalid onion port")
    return url


def fetch_date(address, port, url):
    from email.utils import parsedate_to_datetime
    import requests
    validate_url(url)
    ip = ipaddress.ip_address(address)
    if not ip.is_loopback or not 1 <= int(port) <= 65535:
        raise ValueError("invalid local Tor SOCKS endpoint")
    host = "[" + str(ip) + "]" if ip.version == 6 else str(ip)
    proxy = "socks5h://" + host + ":" + str(int(port))
    with requests.Session() as session:
        session.trust_env = False
        with session.get(url, proxies={"http": proxy, "https": proxy},
                         timeout=(30, 60), stream=True, allow_redirects=False) as response:
            if not 200 <= response.status_code < 300:
                raise ValueError("time source returned non-success HTTP status")
            dates = response.raw.headers.getlist("Date")
            if len(dates) != 1 or not 24 <= len(dates[0]) <= 100:
                raise ValueError("missing, duplicate or overlong HTTP Date")
            # Full matching prevents the email parser accepting trailing junk.
            # HTTP defines all three date forms in UTC, including asctime.
            value = dates[0]
            if not value.isascii() or any(ord(c) < 32 or ord(c) == 127 for c in value):
                raise ValueError("malformed HTTP Date")
            day = r"(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)"
            month = r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
            hms = r"[0-9]{2}:[0-9]{2}:[0-9]{2}"
            forms = (
                day + r", [0-9]{2} " + month + r" [0-9]{4} " + hms + " GMT",
                r"(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday), [0-9]{2}-" + month + r"-[0-9]{2} " + hms + " GMT",
                day + " " + month + r" [ 0-9][0-9] " + hms + r" [0-9]{4}",
            )
            if not any(re.fullmatch(form, value) for form in forms):
                raise ValueError("invalid HTTP-date syntax")
            dt = parsedate_to_datetime(value)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            if dt.utcoffset().total_seconds() != 0:
                raise ValueError("HTTP Date must explicitly use UTC")
            if value[:3] != ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")[dt.weekday()]:
                raise ValueError("HTTP Date weekday mismatch")
            stamp = int(dt.timestamp())
            if not 0 < stamp <= 9999999999:
                raise ValueError("HTTP Date outside supported range")
            return str(stamp)


MESSAGES = {
    "fetching": "Time fetching in progress...",
    "restricted": "Initial time fetching in progress...",
    "sleeping": "Sleeping for ", "minutes": " minutes.",
    "success": "Time sources validated.",
    "no_valid_time": "No valid time returned from pool. ",
    "no_value_returned": "No values returned from servers. ",
    "list_not_built": "Could not build the time-source list. ",
    "restart": "Check Tor and the log before restarting.",
    "general_timeout_error": "All time sources timed out.",
}


def main():
    from stem import ControllerError
    from stem.connection import AuthenticationFailure
    parser = argparse.ArgumentParser()
    parser.add_argument("--broker", action="store_true", required=True)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--slew-only", action="store_true")
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()
    if os.geteuid() == 0:
        raise RuntimeError("network process must not run as root")
    channel = socket.socket(fileno=3)
    os.set_inheritable(3, False)  # Not inherited by HTTP subprocesses.
    channel.settimeout(6600)     # At most 30s / 5ms per second, plus slack.
    monitor_stop = threading.Event()

    def monitor_parent():
        watcher = select.poll()
        watcher.register(channel, select.POLLHUP | select.POLLERR | select.POLLNVAL)
        while not monitor_stop.is_set():
            if watcher.poll(1000) and not monitor_stop.is_set():
                # A killed broker cannot forward SIGTERM. Stop even while
                # sleeping or fetching, rather than orphaning a second daemon.
                os._exit(1)

    threading.Thread(target=monitor_parent, daemon=True).start()
    logging.basicConfig(level=logging.INFO)
    log = logging.getLogger("sdwdate")
    if Path("/dev/log").exists():
        handler = SysLogHandler(address="/dev/log", facility=SysLogHandler.LOG_DAEMON)
        handler.setFormatter(logging.Formatter("sdwdate: %(levelname)s %(message)s"))
        log.addHandler(handler)
    from . import sdwdate as core
    core.LOGGER = log
    core.translate_object = lambda key: MESSAGES[key]
    core.status_first_success_path = str(RUNTIME / "first_success")
    core.sleep_long_file_path = str(RUNTIME / "sleep_long")

    def status(icon, message):
        log.info("%s: %s", icon, sanitize_string(message))
        atomic_write(RUNTIME / "status", json.dumps({"icon": icon, "message": sanitize_string(message)}))

    core.write_status = status

    def shutdown(sig, frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    first = True
    try:
        while True:
            try:
                with tor_controller() as control:
                    if control.get_info("status/circuit-established") != "1":
                        raise RuntimeError("Tor has no established circuit")
                cfg = settings()
                core.proxy_ip, core.proxy_port = cfg["PROXY_IP"], cfg["PROXY_PORT"]
                obj = core.SdwdateClass()
                ratio = float(obj.failure_ratio_from_config)
                if not math.isfinite(ratio) or not 0 <= ratio < 1:
                    raise ValueError("MAX_FAILURE_RATIO must be in [0, 1)")
                for pool in obj.pools:
                    if not pool.url:
                        raise ValueError("an upstream time-source pool is empty")
                    for url in pool.url:
                        validate_url(url)
                if obj.sdwdate_fetch_loop() != "success":
                    raise RuntimeError("time-source validation failed")
                obj.build_median()
                obj.add_or_subtract_nanoseconds()
                target = int(time.time() + obj.new_diff_in_seconds)
                if not minimum_time() - 100 <= target <= EXPIRATION:
                    raise ValueError("proposed correction violates replay/expiry limits")
                mode = "J" if first and not args.slew_only else "A"
                request = (mode + " " + str(obj.new_diff_in_nanoseconds)).encode("ascii")
                channel.sendall(request)
                answer = channel.recv(64)
                if answer != b"OK":
                    raise RuntimeError("clock broker rejected correction: " + repr(answer))
                if args.dry_run:
                    status("dry-run", "Validated correction; clock and replay checkpoint unchanged")
                else:
                    now = int(time.time())
                    checkpoint = max(minimum_time(), min(now, EXPIRATION))
                    atomic_write(STATE / "time-replay-protection-utc-unixtime", str(checkpoint))
                    atomic_write(RUNTIME / "first_success", "")
                    status("success", "Clock correction completed")
                first = False
                if args.once:
                    return
                obj.wait_sleep()
                obj.check_clock_skew()
            except (OSError, ValueError, RuntimeError, ControllerError, AuthenticationFailure) as error:
                status("error", str(error))
                if args.once or channel.fileno() < 0:
                    raise
                # No clock change on source/control failure. A dead broker
                # closes the channel and terminates this process group.
                time.sleep(10)
    finally:
        monitor_stop.set()
        channel.close()
        for name in ("first_success", "sleep_long"):
            (RUNTIME / name).unlink(missing_ok=True)
        status("stopped", "sdwdate network process stopped")


if __name__ == "__main__":
    main()
