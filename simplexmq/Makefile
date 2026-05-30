COMMENT =		SimpleX messaging protocol server and client library

V =			6.5.2.0
DISTNAME =		simplexmq-${V}
WRKDIST =		${WRKDIR}/simplexmq-${V:R}
WRKSRC =		${WRKDIST}
ONLY_FOR_ARCHS =	amd64 arm64

CATEGORIES =		net

HOMEPAGE =		https://github.com/simplex-chat/simplexmq

MAINTAINER =		Porting Team <ports@example.org>

# AGPL-3
PERMIT_PACKAGE =	Yes

SITES =			https://codeload.github.com/simplex-chat/
DISTFILES =		simplexmq-${V}${EXTRACT_SUFX}{simplexmq/tar.gz/refs/tags/v${V:R}}

BUILD_DEPENDS =		devel/cabal-install \
			devel/git \
			lang/ghc

LIB_DEPENDS =		databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS =		databases/sqlcipher \
			archivers/zstd

post-extract:
	mkdir -p ${WRKSRC}/apps/common/Web/static/.well-known

# Build with SQLite backend (default), without PostgreSQL.
do-build:
	cd ${WRKSRC} && env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal update && \
		env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal build -j exe:smp-server exe:xftp exe:xftp-server

do-install:
	smp=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/smp-server/build/smp-server/smp-server' | head -n 1); \
	xftp=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/xftp/build/xftp/xftp' | head -n 1); \
	xftp_server=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/xftp-server/build/xftp-server/xftp-server' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$smp" ${PREFIX}/bin/smp-server; \
	install -m 755 "$$xftp" ${PREFIX}/bin/xftp; \
	install -m 755 "$$xftp_server" ${PREFIX}/bin/xftp-server

.include <bsd.port.mk>
