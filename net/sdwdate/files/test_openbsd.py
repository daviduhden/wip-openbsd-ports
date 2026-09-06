# SPDX-License-Identifier: AGPL-3.0-or-later
"""Offline tests: no Tor connection, privilege transition or clock mutation."""
from contextlib import contextmanager
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from sdwdate import openbsd as native
from sdwdate import config, timesanitycheck

ONION = "http://" + "a" * 56 + ".onion/"


class NativeTests(unittest.TestCase):
    def test_urls(self):
        self.assertEqual(native.validate_url(ONION), ONION)
        for url in ("http://example.org", "file:///etc/passwd", ONION + "#x",
                    "http://user@" + "a" * 56 + ".onion", "http://short.onion"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                native.validate_url(url)

    def response(self, dates, code=200):
        session = MagicMock()
        session.__enter__.return_value = session
        response = session.get.return_value.__enter__.return_value
        response.status_code = code
        response.raw.headers.getlist.return_value = dates
        return session

    def test_http(self):
        session = self.response(["Tue, 25 Aug 2026 00:00:00 GMT"])
        with patch("requests.Session", return_value=session):
            self.assertEqual(native.fetch_date("127.0.0.1", 9050, ONION), str(native.RELEASE_FLOOR))
        self.assertFalse(session.trust_env)
        kw = session.get.call_args.kwargs
        self.assertTrue(kw["stream"])
        self.assertFalse(kw["allow_redirects"])
        self.assertEqual(kw["timeout"], (30, 60))
        self.assertEqual(kw["proxies"], {"http": "socks5h://127.0.0.1:9050", "https": "socks5h://127.0.0.1:9050"})

    def test_invalid_headers(self):
        for dates in ([], ["x" * 101], ["Tue, 25 Aug 2026 00:00:00 GMT"] * 2,
                      ["Tue, 25 Aug 2026 00:00:00 +0100"], ["garbage"],
                      ["Tue, 25 Aug 2026 00:00:00 GMT junk"],
                      ["Mon, 25 Aug 2026 00:00:00 GMT"],
                      ["Tue, 25 Aug 2026 00:00:00 GMT\r\n"]):
            with self.subTest(dates=dates), patch("requests.Session", return_value=self.response(dates)):
                with self.assertRaises((ValueError, TypeError)):
                    native.fetch_date("127.0.0.1", 9050, ONION)
        with patch("requests.Session", return_value=self.response([], 302)):
            with self.assertRaises(ValueError):
                native.fetch_date("127.0.0.1", 9050, ONION)

    def test_obsolete_http_dates(self):
        for value in ("Tuesday, 25-Aug-26 00:00:00 GMT", "Tue Aug 25 00:00:00 2026"):
            with patch("requests.Session", return_value=self.response([value])):
                self.assertEqual(native.fetch_date("127.0.0.1", 9050, ONION), str(native.RELEASE_FLOOR))

    def test_no_nonlocal_proxy(self):
        with patch("requests.Session") as session:
            for address in ("example.org", "192.0.2.1"):
                with self.assertRaises(ValueError):
                    native.fetch_date(address, 9050, ONION)
            session.assert_not_called()

    def test_settings_and_checkpoint(self):
        with tempfile.TemporaryDirectory() as name:
            path = Path(name)
            with patch.object(native, "CONFIG", path), patch.object(native, "STATE", path):
                self.assertEqual(native.minimum_time(), native.RELEASE_FLOOR)
                native.atomic_write(path / "50_user.conf", "PROXY_PORT=9150\n")
                self.assertEqual(native.settings()["PROXY_PORT"], "9150")
                checkpoint = path / "time-replay-protection-utc-unixtime"
                native.atomic_write(checkpoint, str(native.RELEASE_FLOOR + 100))
                self.assertEqual(native.minimum_time(), native.RELEASE_FLOOR + 100)
                self.assertEqual(checkpoint.stat().st_mode & 0o777, 0o600)
                native.atomic_write(checkpoint, "not a timestamp")
                self.assertEqual(timesanitycheck.static_time_sanity_check(native.RELEASE_FLOOR)[0], "error")

    def test_consensus(self):
        self.assertEqual(native.consensus_time("2026-08-25 00:00:00"), native.RELEASE_FLOOR)
        controller = MagicMock()
        controller.get_info.side_effect = ["2026-08-25 00:00:00", "2026-08-25 03:00:00"]

        @contextmanager
        def mocked_controller():
            yield controller

        with patch.object(timesanitycheck, "tor_controller", mocked_controller):
            self.assertEqual(timesanitycheck.time_consensus_sanity_check(native.RELEASE_FLOOR + 1)[0], "ok")

    def test_upstream_median(self):
        from sdwdate import sdwdate as core
        with patch.object(core, "LOGGER", MagicMock(), create=True):
            obj = object.__new__(core.SdwdateClass)
            obj.request_took_times = dict(enumerate([2, 1, 3]))
            obj.half_took_time_float = dict(enumerate([1, .5, 1.5]))
            obj.list_of_pools_raw_diff = [-1000, 4, 1000]
            obj.pools_lag_cleaned_diff = [-1001, 3, 998]
            obj.build_median()
            self.assertEqual(obj.median_diff_raw_in_seconds, 4)
            self.assertEqual(obj.median_diff_lag_cleaned_in_seconds, 3)

    def test_pool_diversity(self):
        pool_conf = Path("etc/sdwdate.d/30_default.conf")
        with patch.object(config.glob, "glob", return_value=[str(pool_conf)]), \
                patch.object(config.os.path, "exists", return_value=True):
            for pool in range(3):
                urls, comments = config.read_pools(pool, "production")
                self.assertGreater(len(urls), 3)
                self.assertEqual(len(urls), len(comments))
                for url in urls:
                    native.validate_url(url)

    def test_pool_fetch_success_and_failure(self):
        from sdwdate import sdwdate as core

        def pool(number, mode):
            return ["http://" + "abc"[number] * 56 + ".onion/"], ["fixture"]

        def replies(pools, urls, address, port):
            self.assertEqual(len(set(urls)), 3)
            return (urls, [status] * 3, [str(native.RELEASE_FLOOR + 100)] * 3,
                    [2] * 3, [1] * 3, [-100, 5, 100], [-101, 4, 99])

        with tempfile.TemporaryDirectory() as name, \
                patch.multiple(core, LOGGER=MagicMock(), translate_object=lambda k: native.MESSAGES[k],
                               write_status=MagicMock(), status_first_success_path=str(Path(name) / "success"),
                               proxy_ip="127.0.0.1", proxy_port="9050", create=True), \
                patch.object(core, "read_pools", side_effect=pool), \
                patch.object(core, "allowed_failures_config", return_value="0.5"), \
                patch.object(core, "get_time_from_servers", side_effect=replies) as fetch:
            for status, expected in (("ok", "success"), ("error", "error")):
                with self.subTest(status=status):
                    obj = core.SdwdateClass()
                    self.assertEqual(obj.sdwdate_fetch_loop(), expected)
                    if status == "ok":
                        self.assertTrue(all(p.done for p in obj.pools))
                        obj.build_median()
                        self.assertEqual(obj.median_diff_raw_in_seconds, 5)
                    else:
                        self.assertFalse(any(p.done for p in obj.pools))
            self.assertEqual(fetch.call_count, 2)

    def test_random_sleep_without_waiting_or_systemd(self):
        from sdwdate import sdwdate as core
        with tempfile.TemporaryDirectory() as name, \
                patch.multiple(core, LOGGER=MagicMock(), translate_object=lambda k: native.MESSAGES[k],
                               sleep_long_file_path=str(Path(name) / "sleep"), create=True), \
                patch.object(core.secrets, "choice", side_effect=[3600, 0]), \
                patch.object(core.time, "sleep") as sleep:
            obj = object.__new__(core.SdwdateClass)
            obj.range_nanoseconds = range(999999999)
            obj.wait_sleep()
            sleep.assert_called_once_with(3600.0)
            self.assertEqual(obj.sleep_time_seconds, 3600)
            self.assertTrue((Path(name) / "sleep").is_file())
            self.assertIsNone(core.SDNOTIFY_OBJECT)


if __name__ == "__main__":
    unittest.main()
