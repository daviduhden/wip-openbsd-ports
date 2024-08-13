COMMENT=secure, private and untraceable digital currency

VERSION=0.18.3.3
PKGNAME=monero-${VERSION}
DISTNAME=monero-source-v${VERSION}
SITES=https://downloads.getmonero.org/cli/
EXTRACT_SUFX=.tar.bz2

CATEGORIES=net
HOMEPAGE=https://getmonero.org

# BSD
PERMIT_PACKAGE=Yes

WANTLIB += c ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_regex-mt boost_serialization-mt boost_system-mt
WANTLIB += boost_thread-mt crypto execinfo m readline sodium ssl
WANTLIB += unbound zmq

COMPILER=base-clang ports-gcc
MODULES=devel/cmake
CONFIGURE_ARGS+=-DMANUAL_SUBMODULES=1 -Wno-dev

BUILD_DEPENDS=devel/boost net/zeromq net/libunbound converters/libiconv
RUN_DEPENDS=devel/boost net/zeromq net/libunbound converters/libiconv

USE_GMAKE=Yes

USERS = _monerod
GROUPS = _monerod

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${PREFIX}/etc/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${PREFIX}/etc/monero/
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/monero
	cp -r ${WRKSRC}/docs/* ${PREFIX}/share/doc/monero/
	${INSTALL_SCRIPT} ${FILESDIR}/monerod.rc ${RCDIR}/monerod

post-install:
	chown -R _monerod:_monerod ${LOCALSTATEDIR}/lib/monero
	chown -R _monerod:_monerod ${LOCALSTATEDIR}/log/monero
	chmod 750 ${LOCALSTATEDIR}/lib/monero
	chmod 750 ${LOCALSTATEDIR}/log/monero

.include <bsd.port.mk>