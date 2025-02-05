COMMENT =		onion routing service, written in Rust

DISTFILES =		${PKGNAME}${EXTRACT_SUFX}{${CRATE}/${V}/download}

CRATE =			arti
V =			1.3.2
PKGNAME =		${CRATE}-$V

CATEGORIES =		net

HOMEPAGE =		https://gitlab.torproject.org/tpo/core/arti

# MIT or Apache 2.0
PERMIT_PACKAGE =	Yes

WANTLIB += c c++abi crypto lzma m pthread sqlite3 ssl

SITES =			https://crates.io/api/v1/crates/

MODULES =		devel/cargo
LIB_DEPENDS =		archivers/xz \
			archivers/zstd \
			databases/sqlite3 \
			security/rust-ring
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

NO_TEST =		Yes

WRKSRC =		${WRKDIR}/${PKGNAME}

.include "crates.inc"

.include <bsd.port.mk>
