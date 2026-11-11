COMMENT =		local search engine and MCP server for AI agents

# Upstream CI and release artifacts cover x86_64 and aarch64 only.
ONLY_FOR_ARCHS =	amd64 aarch64

V =			1.0.0-rc.102
GH_ACCOUNT =		xerj-org
GH_PROJECT =		xerj
GH_TAGNAME =		v${V}
# The upstream tag contains a hyphen; pkg(8) versions do not.
PKGNAME =		xerj-1.0.0rc102

CATEGORIES =		devel

HOMEPAGE =		https://xerj.org/

# Apache 2.0
PERMIT_PACKAGE =	Yes
PERMIT_DISTFILES =	Yes

WANTLIB +=		${MODCARGO_WANTLIB} crypto sqlite3 ssl zstd

MODULES =		devel/cargo

CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

# Only the server package provides the installed `xerj` binary.  Keep
# upstream's default features (neural and decide-local); the neural model
# is only downloaded when the administrator selects it at runtime.
WRKSRC =		${WRKDIST}/engine
MODCARGO_CARGOTOML =	${WRKSRC}/Cargo.toml
MODCARGO_CARGOLOCK =	${WRKSRC}/Cargo.lock
MODCARGO_BUILD_ARGS +=		--locked --package xerj-server --bin xerj
MODCARGO_INSTALL_ARGS +=	--locked
MODCARGO_INSTALL_TARGET_PATHS =	crates/xerj-server

# Use the system SQLite library.
MODCARGO_ENV +=			LIBSQLITE3_SYS_USE_PKG_CONFIG=1
# The Cargo module rewrites zstd-sys to rustc-link-lib=zstd without a
# search path; point the Rust linker at the ports library directory.
MODCARGO_RUSTFLAGS +=		-L${LOCALBASE}/lib

BUILD_DEPENDS =		devel/gmake
LIB_DEPENDS =		archivers/zstd \
			databases/sqlite3

# Run the xerj-server unit and integration tests.  The tests use only
# loopback listeners and temporary directories; they do not need external
# services.  HOME is writable because the auth code may create ~/.xerj.
MODCARGO_TEST_ARGS +=		--locked --package xerj-server
TEST_ENV =			${MAKE_ENV} HOME=${WRKSRC}

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/xerj
	${INSTALL_DATA} ${WRKSRC}/xerj.default.toml \
		${PREFIX}/share/examples/xerj/xerj.toml
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/xerj
	${INSTALL_DATA} ${WRKSRC}/README.md ${PREFIX}/share/doc/xerj/
	${INSTALL_DATA} ${WRKDIST}/LICENSE ${PREFIX}/share/doc/xerj/
	${INSTALL_DATA} ${WRKDIST}/NOTICE ${PREFIX}/share/doc/xerj/

# Generated on OpenBSD with `make modcargo-gen-crates`; keep the scaffold
# parseable until crates.inc exists.
.if exists(${.CURDIR}/crates.inc)
.include "crates.inc"
.endif

# Preserve strict upstream version checks; recognize base LibreSSL 4.4
# in the port patch instead of the module's unknown-version fallback.
MODCARGO_CRATES_KEEP +=	openssl-sys
MODCARGO_ENV +=		OPENSSL_NO_VENDOR=1 \
			OPENSSL_INCLUDE_DIR=/usr/include \
			OPENSSL_LIB_DIR=/usr/lib

.include <bsd.port.mk>
