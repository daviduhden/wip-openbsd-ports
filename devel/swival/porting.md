# Swival port import

Swival 1.0.47 is imported from the official stable GitHub tag, commit
`15e80b0592a3df039aa74cb14e0594167cb080d0`. The source archive is used because
PyPI still published 1.0.46 at the time of this review (October 12, 2026).

Upstream: https://github.com/swival/swival/releases/tag/1.0.47

This overlay was built, packaged, installed and tested on OpenBSD 8.0 amd64
on October 14, 2026, with Python 3.14.8. Swival reports version 1.0.47 and
its full non-stress test suite passes as the unprivileged build user. See
the validation results below.

## Dependency selection

The import includes 38 runtime dependency ports in addition to Swival, plus ASGI lifespan as a test dependency. Existing
OpenBSD ports are reused where their versions satisfy upstream requirements.
The dependency graph was evaluated for CPython 3.14 on OpenBSD, including
required transitive extras such as Google API Core's gRPC dependencies.
Every selected runtime version satisfies the reviewed graph's constraints.

| Port | Version |
| --- | --- |
| `devel/swival` | 1.0.47 |
| `net/py-boto3` | 1.43.111 |
| `devel/py-docstring-parser` | 0.18.0 |
| `security/py-fast-cipher` | 0.2.2 |
| `sysutils/py-filelock` | 3.32.7 |
| `devel/py-google-api-core` | 2.42.0 |
| `security/py-google-auth` | 2.61.0 |
| `devel/py-google-cloud-aiplatform` | 2.4.0 |
| `devel/py-google-cloud-bigquery` | 3.46.1 |
| `devel/py-google-cloud-core` | 2.8.0 |
| `devel/py-google-cloud-resource-manager` | 1.19.0 |
| `devel/py-google-cloud-storage` | 3.17.0 |
| `devel/py-google-crc32c` | 1.9.0 |
| `devel/py-google-genai` | 2.29.0 |
| `devel/py-google-resumable-media` | 2.11.0 |
| `net/py-grpc-google-iam-v1` | 0.14.5 |
| `net/py-grpcio` | 1.84.0 |
| `net/py-grpcio-status` | 1.84.0 |
| `converters/py-html-to-markdown` | 3.17.2 |
| `www/py-httpcore2` | 2.13.1 |
| `www/py-httpx2` | 2.13.1 |
| `devel/py-huggingface-hub` | 1.33.0 |
| `devel/py-importlib-metadata` | 8.9.0 |
| `devel/py-litellm` | 1.105.0 |
| `devel/maturin` | 1.15.0 |
| `devel/py-mcp` | 2.3.0 |
| `devel/py-mcp-types` | 2.3.0 |
| `devel/py-opentelemetry-api` | 1.45.1 |
| `devel/py-prompt_toolkit` | 3.0.53 |
| `devel/py-proto-plus` | 1.29.0 |
| `devel/py-protobuf` | 6.33.6 |
| `textproc/py-rank-bm25` | 0.2.2 |
| `devel/py-rich` | 15.0.0 |
| `www/py-sse-starlette` | 3.5.0 |
| `www/py-starlette` | 1.7.0 |
| `textproc/py-tiktoken` | 0.14.0 |
| `textproc/py-tokenizers` | 0.23.1 (package revision p0) |
| `www/py-uvicorn` | 0.54.0 |
| `net/py-websockets` | 16.1.1 |

Four dependencies use the latest stable release on a compatible branch,
rather than the newest major release: filelock 3.32.7, importlib-metadata
8.9.0, protobuf 6.33.6, and websockets 16.1.1. Upstream requirements exclude
the newer major versions in -current. Their PORTROACH limits document these
choices. Before replacing installed packages, check other consumers for
conflicting requirements; this import does not guarantee compatibility with
every unrelated consumer in the ports tree.

## Native components and patches

LiteLLM 1.105.0 uses Maturin and a required Rust bridge. Its 579 registry
crates are listed in crates.inc and distinfo. The Python SDK and native
bridge are retained. Optional proxy/CLI scripts are omitted because their
extras require rich below 14 while Swival requires rich 15 or newer.

HTML-to-Markdown uses its Python extension workspace (130 registry crates).
Tiktoken uses 27 registry crates, and Maturin's upstream lock lists 472.
No Cargo.lock is supplied in files/ or patched into these ports. Cargo uses
the upstream lock when applicable, or generates the workspace lock offline
in the working directory from the exact crates fixed in crates.inc and
distinfo. Clean extraction, patching, configuration and offline resolution
were checked for LiteLLM, HTML-to-Markdown and tiktoken. Their resolved
package versions and checksums exactly match the graphs used for the
successful builds and tests.

When regenerating a crate list for an sdist without its workspace lock,
configure the port and run Cargo metadata in WRKSRC with the port's
CARGO_HOME and MODCARGO_CARGOTOML first. Then use modcargo-gen-crates and
modcargo-gen-crates-licenses. Do not copy the generated lock into the port.

LiteLLM's AWS-LC ARM64 Keccak patches move readable constants out of executable
text and update addressing, following the existing OpenBSD Codex adaptation.
The amd64 port uses USE_NOEXECONLY for AWS-LC. System Oniguruma is selected.
Maturin uses Rust LZMA support and system OpenSSL. Google CRC32C explicitly builds against the
system crc32c library. gRPC retains the OpenBSD port's system-library build
configuration with patches refreshed against 1.84.0.

The Hugging Face dependency marker skips only the optional hf-xet accelerator
on OpenBSD; upstream's HTTP download fallback remains available. Google GenAI's
build requirements omit twine and pkginfo, which are publishing tools unused by
its setuptools build. Dynamic-version backends receive the release version
through UV_DYNAMIC_VERSIONING_BYPASS. MCP includes the dependencies of its
installed CLI. Filelock uses hatch-vcs, matching its current build backend.

Build validation found and corrected these additional issues:

- Swival's website `build.py` shadowed the Python build frontend. The port
  renames it during extraction.
- Deeply nested Python-bridge JSON overflowed the OpenBSD thread stack in
  CPython's C decoder. The port checks JSON nesting before decoding, with a
  128-level limit, and preserves the existing protocol error response. The
  original 200,000-level regression test now passes.
- The binary tokenizers package used Rust-crate metadata instead of the root
  Python metadata and omitted Python package files. Its port now lets Maturin
  read `pyproject.toml`, declares its Hugging Face runtime dependency and C++
  library requirements, and bumps the package revision.
- LiteLLM's HTTPX HTTP/2 extra needs `www/py-h2` explicitly.
- Unused WANTLIB entries were removed from Maturin, HTML-to-Markdown,
  tiktoken, protobuf and websockets after checking actual shared-library
  dependencies.

## Optional features

Swival's optional metaskills integration needs starlark-go, whose Go c-shared
build mode is unavailable on OpenBSD (golang/go#33896). It is not a mandatory
Swival dependency. All mandatory Swival dependencies are included.
HTTPX2's Truststore dependency has an OpenSSL fallback that recognizes
OpenBSD's /etc/ssl/cert.pem.

## Validation on OpenBSD 8.0 amd64

All 40 ports were built, packaged and installed. Available external
prerequisites were installed with `pkg_add`; tokenizers also needed a local
build to repair the binary package's metadata and Python file inventory.
`distinfo` and PLIST files were regenerated from real builds, and all five
`crates.inc` files were regenerated with the Cargo module's license target.
Every port passed `make checksum` and `make port-lib-depends-check`.

Swival's suite was run through `make do-test` as `build` (uid 21), preserving
the Python module's test environment. It completed with **6517 passed,
32 skipped and 7 deselected** in 384.18 seconds. The deselected tests carry
the upstream `stress` marker. Two Pydantic ReadOnly warnings remain.
The unreadable-objective test needs an unprivileged user: root can read
mode-000 files. The focused Python-bridge suite also passed all 71 tests.
The port uses LiteLLM's bundled model-cost data during tests.

The installed `swival --version` prints `1.0.47`, and `swival --help` works.
The installed dependency graph passed a recursive metadata audit covering
108 distribution/extra combinations. Functional smoke checks passed for
CRC32C, protobuf, BM25, HTTPX2, HTML-to-Markdown, both Python/Rust tokenizers,
a local gRPC server, Google AI Platform imports and a mocked LiteLLM
completion. Live provider calls were not tested.

Delivery files are in `/root/swival-results`: a CVS diff for 20 existing
ports plus four category Makefiles, a tarball for 20 new ports, a package
manifest, SHA256 checksums and individual build/test logs. The same port
changes are retained in this repository.

## Dependency port test validation (October 14, 2026)


All 40 ports build. Tests run as build (uid 21), not root.

| Port | Test result |
| --- | --- |
| devel/swival | 6517 passed, 32 skipped, 7 deselected, 2 warnings in 384.18s (0:06:24) |
| net/py-boto3 | No complete upstream test suite in source distribution |
| security/py-fast-cipher | 50 passed, 2 skipped in 54.74s |
| sysutils/py-filelock | 1446 passed, 59 skipped, 4 deselected in 317.74s (0:05:17) |
| security/py-google-auth | 2002 passed, 7 skipped, 90 warnings in 98.39s (0:01:38) |
| net/py-grpcio | No complete upstream test suite in source distribution |
| devel/py-importlib-metadata | 21 passed in 2.14s |
| devel/py-litellm | No complete upstream test suite in source distribution |
| devel/maturin | No complete upstream test suite in source distribution |
| devel/py-mcp | 5473 passed, 21 skipped, 1 xfailed in 61.03s (0:01:01) |
| devel/py-prompt_toolkit | 156 passed in 25.57s |
| devel/py-protobuf | No complete upstream test suite in source distribution |
| textproc/py-rank-bm25 | No complete upstream test suite in source distribution |
| devel/py-rich | No complete upstream test suite in source distribution |
| www/py-sse-starlette | 92 passed in 29.52s |
| www/py-starlette | 1212 passed, 6 skipped, 2 xfailed in 21.64s |
| textproc/py-tiktoken | 33 passed in 44.31s |
| www/py-uvicorn | 1015 passed, 336 skipped in 87.57s (0:01:27) |
| net/py-websockets | 1955 passed, 7 skipped, 16 deselected, 2 warnings, 581 subtests passed in 87.16s (0:01:27) |
| devel/py-docstring-parser | 254 passed in 1.68s |
| devel/py-google-api-core | 1549 passed, 1 skipped in 25.24s |
| devel/py-google-cloud-aiplatform | 44120 passed, 2704 warnings in 147.81s (0:02:27) |
| devel/py-google-cloud-bigquery | 1891 passed, 192 skipped in 42.69s |
| devel/py-google-cloud-core | 155 passed in 2.98s |
| devel/py-google-cloud-resource-manager | 2182 passed, 203 warnings in 23.90s |
| devel/py-google-cloud-storage | 2038 passed, 8 skipped, 346686 warnings in 64.55s (0:01:04) |
| devel/py-google-crc32c | 44 passed in 1.59s |
| devel/py-google-genai | 90 passed, 1 warning in 2.34s |
| devel/py-google-resumable-media | 300 passed in 1.97s |
| net/py-grpc-google-iam-v1 | 2 passed in 5.22s |
| net/py-grpcio-status | No complete upstream test suite in source distribution |
| converters/py-html-to-markdown | No complete upstream test suite in source distribution |
| www/py-httpcore2 | No complete upstream test suite in source distribution |
| www/py-httpx2 | No complete upstream test suite in source distribution |
| devel/py-huggingface-hub | 660 passed, 17 deselected, 1 warning in 9.67s |
| devel/py-mcp-types | No complete upstream test suite in source distribution |
| devel/py-opentelemetry-api | 256 passed, 1 skipped, 71 subtests passed in 2.18s |
| devel/py-proto-plus | 274 passed, 2 skipped, 12 warnings in 2.08s |
| textproc/py-tokenizers | 141 passed, 3 skipped, 49 deselected in 12.00s |
| www/py-asgi-lifespan | 30 passed, 2 xfailed in 0.61s |

Test scope and exclusions are explicit in each port Makefile and in tests-final.json.
No tests were disabled because of a runtime regression. SDists without complete upstream suites are marked NO_TEST.
Integration suites requiring cloud accounts, Docker or optional unported frameworks are excluded.
Warnings and expected failures are reported above; these are not counted as passes.

Key fixes: native-extension test paths; optional tracing test imports; native Google namespaces; current Starlette/HTTPX/Trio test APIs; actual mTLS fixture file.
SSE-Starlette and websockets use the matching GitHub release archives to obtain complete test fixtures.
ASGI lifespan 2.1.0 is a new test dependency, with 100% measured coverage.
No patches contain SPDX-License-Identifier. No port supplies Cargo.lock.
