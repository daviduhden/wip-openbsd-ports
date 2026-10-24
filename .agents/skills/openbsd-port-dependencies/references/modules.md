# Dependency module procedures

Run commands inside the target port in the matching OpenBSD ports tree. Inspect local module targets first; upstream master can differ. These maintainer operations can fetch sources and metadata. Check version changes and the provenance of new distfiles before `make makesum`; never regenerate checksums to hide an unexplained mismatch. For unchanged sources, use `make checksum`.

A command's failure must stop its sequence. Store generator stdout in a temporary file, keeping stderr visible, and inspect the output before copying it over an included file. Never redirect directly into an include that make reads. Temporary files should be outside directories removed by `make clean`; preserve the previous include until generation succeeds.

## Cargo and Python Rust extensions

Read `devel/cargo/cargo.port.mk`, upstream `Cargo.toml` and `Cargo.lock`, and any workspace overrides. This repository uses standalone Cargo and Python `maturin`/`setuptools-rust`; Python's module can activate Cargo support. Check `MODCARGO_CARGOTOML` and `MODCARGO_CARGOLOCK`: py-litellm, py-html-to-markdown, and py-tokenizers build nested workspaces.

After updating the release variables, establish checksums and extract the changed source. An example sequence, run one command at a time and stop on error:

```sh
make clean
make makesum
make extract
crate_tmp=$(mktemp /tmp/wip-crates.XXXXXXXX)
make modcargo-gen-crates > "$crate_tmp"
```

Inspect the candidate, then `cp "$crate_tmp" crates.inc`. Regenerate checksums for the new registry crates, clean and prepare the new vendor tree:

```sh
make clean
make makesum
make patch
make configure
make modcargo-gen-crates-licenses > "$crate_tmp"
```

The license generator depends on `configure`; diagnose patch/configuration errors before retrying. Inspect output for missing licenses and wrong crate versions; only after success copy it to `crates.inc` and remove the temporary file. Run `make makesum` again if generated inputs changed, then clean before validation. `modcargo-metadata` refreshes vendor metadata after relevant source changes; use the module wrapper rather than internal `_` targets.

Registry generation omits Git dependencies. Keep pinned `DIST_TUPLE` archives and local path patches aligned with lockfile revisions, including uutils awk/indexmap and tar/uucore. Preserve `MODCARGO_FEATURES`, `MODCARGO_NO_DEFAULT_FEATURES`, and native `LIB_DEPENDS`/`WANTLIB`. `MODCARGO_CRATES_KEEP` exceptions can retain bundled source; do not add them to bypass a failed system-library check without understanding the cause. Review any `MODCARGO_CRATES_UPDATE` use against the installed module and resulting offline configuration.

Module: [cargo.port.mk](https://github.com/openbsd/ports/blob/master/devel/cargo/cargo.port.mk).

## Go

Check `MODGO_MODNAME`, `MODGO_VERSION`, upstream `go.mod`/`go.sum`, module replacements and version ldflags. Generate for the explicitly selected release:

```sh
make clean
module_tmp=$(mktemp /tmp/wip-modules.XXXXXXXX)
make modgo-gen-modules > "$module_tmp"
```

After successful generation and review, copy the candidate to `modules.inc`, remove the temporary file, and run `make makesum`. Inspect both `MODGO_MODULES` and `MODGO_MODFILES`; do not discard replacement hashes. Avoid `MODGO_VERSION=latest` in a reproducible update unless intentionally discovering a release and then pinning it.

For github-cli, retain the survey `DIST_TUPLE` and `pre-build` local `go mod edit -replace` when still required. Confirm ordinary build does not resolve the replacement online. Native linkage, runtime helpers, generated manuals and build-version flags need independent checking.

Module: [go.port.mk](https://github.com/openbsd/ports/blob/master/lang/go/go.port.mk).

## Cabal

Read the actual `cabal-inc` recipe: the three ports do not share identical output behavior. Hackage's `MODCABAL_VERSION` can differ from `GH_TAGNAME`. Reconcile `MODCABAL_EXECUTABLES`, pinned Git sources, dependency `*_V` variables, project options, and patches before regeneration.

For `net/simplexmq` and `net/simplex-chat`, back up `cabal.inc` outside the work directory, then:

```sh
make clean
make makesum
make patch
make cabal-inc
make makesum
```

These targets write `cabal.inc` themselves using `files/cabal-deps-merge.pl`; do not redirect their stdout over the manifest. They use `CABAL_INC_HOME`, executable and test plans, and `CABAL_INC_SKIP`/`CABAL_INC_EXTRA`. Check their plans and merged output, then run a fresh `make patch` and full validation. Missing newly listed Hackage tarballs during initial generation require the subsequent fetch/checksum/extract cycle; do not accept silently skipped dependency patches in final validation.

For `devel/fourmolu`, `cabal-inc` filters the bundler output and replaces
`cabal.inc` itself. Inspect the result for diagnostics and duplicate
`MODCABAL_STEM`/`MODCABAL_VERSION` lines. `make makesum` must then cover
the generated Hackage set.

Regeneration explicitly runs `cabal update`; this is a maintainer operation. Ordinary builds use the module's fetched sources. Test plans and test-only sources must match the regenerated build plan. SimpleX dependency patches and LF normalization under `files/` are part of the port, not a universal Cabal requirement.

Module: [cabal.port.mk](https://github.com/openbsd/ports/blob/master/devel/cabal/cabal.port.mk).

## Python

Read `pyproject.toml`, source distribution metadata, package requirements, extras and tests. Match the build backend with existing `MODPY_PYBUILD` conventions; `MODPY_PI` controls PyPI source handling. Separate runtime imports, build backends, native libraries, optional extras and test-only tools. Keep supported version bounds and markers coherent with the selected OpenBSD Python version; do not blindly copy every extra into runtime dependencies.

Use ports-provided backends and packages rather than pip's network resolver. Python-only ports have no common generated dependency include here; do not invent one. Rust extensions need the Cargo workflow above in addition to Python dependencies and native linkage. Some sdists omit test suites and several ports exclude network or unsupported tests: inspect why, record actual test coverage, and do not call a skipped suite a pass.

Module: [python.port.mk](https://github.com/openbsd/ports/blob/master/lang/python/3/python.port.mk). See the matching tree's [port-modules(5)](https://man.openbsd.org/port-modules) and [ports guide](https://www.openbsd.org/faq/ports/guide.html) for policy and supported module configuration.
