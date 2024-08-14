COMMENT=	secure, private and untraceable digital currency

VERSION=	0.18.3.3
PKGNAME=	monero-${VERSION}
DISTNAME=	monero-source-v${VERSION}
SITES=		https://downloads.getmonero.org/cli/
EXTRACT_SUFX=	.tar.bz2

EPOCH=		0

CATEGORIES=	net
HOMEPAGE=	https://getmonero.org

# BSD
PERMIT_PACKAGE=	Yes

WANTLIB += c ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_regex-mt boost_serialization-mt boost_system-mt
WANTLIB += boost_thread-mt crypto execinfo m readline sodium ssl
WANTLIB += unbound zmq

COMPILER=	base-clang ports-gcc
MODULES=	devel/cmake
CONFIGURE_ARGS += -DMANUAL_SUBMODULES=1 -Wno-dev

BUILD_DEPENDS=	devel/boost \
		net/zeromq \
		net/libunbound \
		converters/libiconv
RUN_DEPENDS=	devel/boost \
		net/zeromq \
		net/libunbound \
		converters/libiconv

USE_GMAKE=	Yes

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/usr/local/bin/
	${INSTALL_DATA_DIR} ${PREFIX}/etc/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${PREFIX}/etc/monero
	${INSTALL_DATA_DIR} ${PREFIX}/var/lib/monero/
	${INSTALL_DATA_DIR} ${PREFIX}/var/log/monero/
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/monero
	cp -r ${WRKSRC}/docs/* ${PREFIX}/usr/local/share/doc/monero/
	if ! getent group _monerod >/dev/null; then \
		groupadd -g 900 _monerod; \
	fi
	if ! id _monerod >/dev/null 2>&1; then \
		useradd -u 900 -g _monerod -c "monerod account" \
		-d ${PREFIX}/var/lib/monero/ -s /sbin/nologin _monerod; \
	fi
	chown -R _monerod:_monerod ${PREFIX}/var/lib/monero/
	chown -R _monerod:_monerod ${PREFIX}/var/log/monero/
	chmod 750 ${PREFIX}/var/lib/monero/
	chmod 750 ${PREFIX}/var/log/monero/

.include <bsd.port.mk>