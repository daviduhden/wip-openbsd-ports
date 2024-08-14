COMMENT=	secure, private and untraceable digital currency

VERSION=	0.18.3.3
PKGNAME=	monero-${VERSION}
DISTNAME=	monero-source-v${VERSION}
SITES=		https://downloads.getmonero.org/cli/
EXTRACT_SUFX=	.tar.bz2

CATEGORIES=	net
HOMEPAGE=	https://getmonero.org

# Licencia BSD, permite distribución
PERMIT_PACKAGE=	Yes

WANTLIB += c ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_regex-mt boost_serialization-mt boost_system-mt
WANTLIB += boost_thread-mt crypto execinfo m readline sodium ssl
WANTLIB += unbound zmq

COMPILER=	base-clang ports-gcc
MODULES=	devel/cmake
CONFIGURE_ARGS+=-DMANUAL_SUBMODULES=1 -Wno-dev

# Dependencias necesarias para la compilación y la ejecución
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
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${SYSCONFDIR}/monero/
	${INSTALL_DATA_DIR} ${VARBASE}/monero/lib
	${INSTALL_DATA_DIR} ${VARBASE}/monero/log
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/monero
	cp -r ${WRKSRC}/docs/* ${PREFIX}/share/doc/monero/
	@${MODGID} _monerod || groupadd -g 900 _monerod
	@${MODUID} _monerod || useradd -u 900 -g _monerod -c "monerod account" -d ${VARBASE}/monero/lib -s /sbin/nologin _monerod
	chown -R _monerod:_monerod ${VARBASE}/monero/lib
	chown -R _monerod:_monerod ${VARBASE}/monero/log
	chmod 750 ${VARBASE}/monero/lib
	chmod 750 ${VARBASE}/monero/log

.include <bsd.port.mk>