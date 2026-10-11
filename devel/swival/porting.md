# Swival port import

Swival 1.0.47 is imported from the official stable GitHub tag, commit
`15e80b0592a3df039aa74cb14e0594167cb080d0`. The source archive is used because
PyPI still published 1.0.46 at the time of this review (October 12, 2026).

Upstream: https://github.com/swival/swival/releases/tag/1.0.47

This change was prepared through static analysis. No package was built,
installed, or executed, and no upstream test suite was run. Python source
parsing, dependency resolution, Cargo metadata, archive checksums, patch
application, and file inventories do not establish runtime compatibility.

## Dependency selection

The import includes 37 dependency ports in addition to Swival. Existing
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

LiteLLM 1.105.0 now uses Maturin and a required Rust bridge. Its actual Python
workspace needs a regenerated Cargo.lock; the sdist's lock is inconsistent
with that workspace. The port installs the reviewed lock during extraction.
Its 579 registry crates are listed in crates.inc and distinfo. The Python SDK
and native bridge are retained. Optional proxy/CLI scripts are omitted because
their extras require rich below 14 while Swival requires rich 15 or newer.

HTML-to-Markdown uses its Python extension workspace with a reviewed root
Cargo.lock (130 registry crates), rather than the stale registry package lock
shipped in a workspace member directory. Tiktoken's sdist has no lock; a
reviewed lock with 27 registry crates is supplied. Maturin uses its upstream
lock with 472 registry crates. Original crate archives were checked against
Cargo.lock checksums. Native dependencies and build requirements were reviewed
from Cargo metadata and build scripts; final shared-library linkage requires
an OpenBSD build.

LiteLLM's AWS-LC ARM64 Keccak patches move readable constants out of executable
text and update addressing, following the existing OpenBSD Codex adaptation.
The amd64 port uses USE_NOEXECONLY for AWS-LC. System Oniguruma is selected.
Maturin uses system xz/OpenSSL. Google CRC32C explicitly builds against the
system crc32c library. gRPC retains the OpenBSD port's system-library build
configuration with patches refreshed against 1.84.0.

The Hugging Face dependency marker skips only the optional hf-xet accelerator
on OpenBSD; upstream's HTTP download fallback remains available. Google GenAI's
build requirements omit twine and pkginfo, which are publishing tools unused by
its setuptools build. Dynamic-version backends receive the release version
through UV_DYNAMIC_VERSIONING_BYPASS. MCP includes the dependencies of its
installed CLI. Filelock uses hatch-vcs, matching its current build backend.

All 10 imported patches apply to their original release sources with zero fuzz
and zero offset. Swival's 66 Python modules parse successfully. Makefile syntax
and dependency paths were checked with a minimal BSD make harness; the full
OpenBSD ports infrastructure was not executed on this host.

## Optional features

Swival's optional metaskills integration needs starlark-go, whose Go c-shared
build mode is unavailable on OpenBSD (golang/go#33896). It is not a mandatory
Swival dependency. All mandatory Swival dependencies are included.
HTTPX2's Truststore dependency has an OpenSSL fallback that recognizes
OpenBSD's /etc/ssl/cert.pem.

## Validation on OpenBSD -current

PLIST files were prepared from source and wheel file inventories, with native
extensions represented using OpenBSD Python substitutions. Wheels were used
only as inventory references; no foreign binaries are shipped. These lists
and native WANTLIB values must be confirmed against real OpenBSD builds.
Run these commands in a ports tree containing this overlay:

```sh
cd /usr/ports/devel/swival
make show=BUILD_DEPENDS
make show=RUN_DEPENDS
make checksum
make patch
make build
make test
make update-plist
make package
make install
swival --version
swival --help
pkg_info -f swival
```

Build imported dependency ports first in dependency order, or let the ports
infrastructure build them. For each imported dependency, run `make checksum`,
`make patch`, `make build`, `make update-plist`, and `make package` in its
port directory. Review generated PLIST changes and run the usual shared-library
and package dependency checks before installing. Swival's tests exclude the
upstream stress marker. Live provider/API tests need separate credentials and
must not be inferred from static validation.
