COMMENT =		synchronize the clock through independent Tor sources

GH_ACCOUNT =		Kicksecure
GH_PROJECT =		sdwdate
GH_TAGNAME =		29.1-1
PKGNAME =		sdwdate-29.1.1
CATEGORIES =		net
HOMEPAGE =		https://www.kicksecure.com/wiki/sdwdate

# AGPLv3+
PERMIT_PACKAGE =	Yes

WANTLIB =		c
MODULES =		lang/python
RUN_DEPENDS =		devel/py-dateutil \
			net/py-socks \
			net/py-stem \
			net/tor \
			www/py-requests
TEST_DEPENDS =		${RUN_DEPENDS}

PYFILES =		${WRKSRC}/usr/lib/python3/dist-packages/sdwdate

post-extract:
	cp ${FILESDIR}/openbsd.py ${PYFILES}/
	cp ${FILESDIR}/clock-parent.c ${WRKSRC}/usr/src/sdwdate/
	cp ${FILESDIR}/test_broker.c ${WRKSRC}/usr/src/sdwdate/
	cp ${FILESDIR}/test_openbsd.py ${WRKSRC}/
	cp ${FILESDIR}/sdwdate.8 ${WRKSRC}/

post-patch:
	${SUBST_CMD} ${PYFILES}/*.py ${WRKSRC}/usr/bin/url_to_unixtime \
		${WRKSRC}/usr/src/sdwdate/clock-parent.c ${WRKSRC}/sdwdate.8

do-build:
	cd ${WRKSRC}/usr/src/sdwdate && ${CC} ${CFLAGS} -Wall -Wextra \
		-o sdwdate clock-parent.c
	cd ${WRKSRC}/usr/src/sdwdate && ${CC} ${CFLAGS} -Wall -Wextra \
		-o sclockadj sclockadj.c

do-test:
	cd ${WRKSRC} && ${SETENV} PYTHONPATH=${PYFILES:H} \
		${MODPY_BIN} -B test_openbsd.py
	cd ${WRKSRC}/usr/src/sdwdate && ${CC} ${CFLAGS} -Wall -Wextra \
		-Werror -DSCLOCKADJ_TEST -o clock-test sclockadj.c
	${WRKSRC}/usr/src/sdwdate/clock-test
	cd ${WRKSRC}/usr/src/sdwdate && ${CC} ${CFLAGS} -Wall -Wextra \
		-Werror -o broker-test test_broker.c
	${WRKSRC}/usr/src/sdwdate/broker-test

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/usr/src/sdwdate/sdwdate ${PREFIX}/sbin/
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/sdwdate/sdwdate \
		${PREFIX}/share/doc/sdwdate ${PREFIX}/share/examples/sdwdate
	${INSTALL_PROGRAM} ${WRKSRC}/usr/src/sdwdate/sclockadj \
		${PREFIX}/libexec/sdwdate/
	${INSTALL_SCRIPT} ${WRKSRC}/usr/bin/url_to_unixtime ${PREFIX}/bin/
	${INSTALL_DATA} ${PYFILES}/*.py ${PREFIX}/libexec/sdwdate/sdwdate/
	${INSTALL_DATA} ${WRKSRC}/COPYING ${PREFIX}/share/doc/sdwdate/
	${INSTALL_DATA} ${WRKSRC}/etc/sdwdate.d/30_default.conf \
		${PREFIX}/share/examples/sdwdate/
	${INSTALL_MAN} ${WRKSRC}/sdwdate.8 ${PREFIX}/man/man8/

.include <bsd.port.mk>
