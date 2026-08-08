COMMENT =	neomutt and isync configuration with good defaults
CATEGORIES =	mail

GH_ACCOUNT =	LukeSmithxyz
GH_PROJECT =	mutt-wizard
GH_COMMIT =	b4a28b2548e94c167bb74fcb5e8c44c34d2be842

EPOCH =		0
REVISION =	0

MAINTAINER =	Aisha Tammy <aisha@openbsd.org>

# GPLv3
PERMIT_PACKAGE =	Yes

RUN_DEPENDS =	mail/neomutt,gpgme,sasl,notmuch \
		mail/isync \
		mail/msmtp \
		security/password-store

NO_BUILD =	Yes
NO_TEST =	Yes
USE_GMAKE =	Yes

FAKE_FLAGS =	PREFIX=${TRUEPREFIX} MANPREFIX=${PREFIX}/man

.include <bsd.port.mk>
