COMMENT-main =		share files and services privately over Tor
COMMENT-gui =		Qt interface for OnionShare

MODPY_DISTV =		2.6.5
DISTNAME =		onionshare-${MODPY_DISTV}
CATEGORIES =		net
HOMEPAGE =		https://onionshare.org/
SITES =			https://github.com/onionshare/onionshare/releases/download/v${MODPY_DISTV}/
DIST_SUBDIR =		onionshare
WRKDIST =		${WRKDIR}/onionshare

MULTI_PACKAGES =		-main -gui
PKGNAME-main =		onionshare-cli-${MODPY_DISTV}
PKGNAME-gui =		onionshare-${MODPY_DISTV}

# GPLv3+, private Socket.IO stack MIT / bidict MPL-2.0.
# Embedded source and web asset notices remain in their installed resources.
PERMIT_PACKAGE =	Yes

MODULES =		lang/python
MODPY_PYBUILD =		poetry-core
MODPY_BUILD_DIR =	${WRKSRC}/cli

RUN_DEPENDS-main =	devel/py-cffi \
			devel/py-click \
			devel/py-colorama \
			devel/py-gevent \
			graphics/py-qrcode \
			net/py-gevent-websocket \
			net/py-socks \
			net/py-stem \
			net/py-wsproto \
			net/tor \
			security/py-PyNaCl \
			sysutils/py-packaging \
			sysutils/py-psutil \
			textproc/py-unidecode \
			www/py-flask \
			www/py-flask-compress \
			www/py-requests \
			www/py-urllib3 \
			www/py-waitress \
			www/py-werkzeug
RUN_DEPENDS-gui =	${BASE_PKGPATH},-main=${MODPY_DISTV} \
			devel/desktop-file-utils \
			devel/xdg-utils \
			security/py-gnupg \
			x11/gtk+4,-guic \
			x11/qt6/pyside6/pyside

# These protocol versions cannot use the older shared Socket.IO ports.
# All five are pure Python; files/vendor.py rewrites imports into a private
# namespace. No .pth files, pip environments, or build-phase downloads.
SITES.vendor =		https://files.pythonhosted.org/packages/source/
DISTFILES.vendor =	flask_socketio-5.6.1{f/flask-socketio/flask_socketio-5.6.1}.tar.gz \
			python_socketio-5.16.3{p/python-socketio/python_socketio-5.16.3}.tar.gz \
			python_engineio-4.13.3{p/python-engineio/python_engineio-4.13.3}.tar.gz \
			simple_websocket-1.1.0{s/simple-websocket/simple_websocket-1.1.0}.tar.gz \
			bidict-0.23.1{b/bidict/bidict-0.23.1}.tar.gz

TEST_DEPENDS =		${RUN_DEPENDS-main}
PORTHOME =		${WRKDIR}

post-extract:
	${MODPY_BIN} ${FILESDIR}/vendor.py ${WRKDIR} ${WRKSRC}/cli

post-patch:
	${SUBST_CMD} ${WRKSRC}/cli/onionshare_cli/common.py

do-build:
	${MODPY_BUILD_TARGET}
	cd ${WRKSRC}/desktop && ${SETENV} ${MAKE_ENV} \
		${MODPY_BIN} -sBm build -w --no-isolation

do-test:
	cd ${WRKSRC}/cli && ${SETENV} ${MAKE_ENV} ${MODPY_BIN} -m pytest tests

do-install:
	${MODPY_INSTALL_TARGET}
	${MODPY_BIN} -m installer -d ${WRKINST} ${WRKSRC}/desktop/dist/*.whl
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/onionshare
	${INSTALL_DATA} ${WRKSRC}/LICENSE.txt \
		${PREFIX}/share/doc/onionshare/
	${INSTALL_DATA_DIR} ${PREFIX}/share/applications \
		${PREFIX}/share/icons/hicolor/scalable/apps
	${INSTALL_DATA} ${WRKSRC}/desktop/org.onionshare.OnionShare.desktop \
		${PREFIX}/share/applications/
	${INSTALL_DATA} ${WRKSRC}/desktop/org.onionshare.OnionShare.svg \
		${PREFIX}/share/icons/hicolor/scalable/apps/

.include <bsd.port.mk>
