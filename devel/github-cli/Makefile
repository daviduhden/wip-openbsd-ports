COMMENT =	command-line access to github pull requests, issues and more

V =		2.101.0
MODGO_MODNAME =	github.com/cli/cli/v${V:R:R}
MODGO_VERSION =	v${V}

DISTNAME =	cli-${MODGO_VERSION}
PKGNAME =	github-cli-${V}

# The survey module still uses the indirect syscall(2) interface for
# termios, which OpenBSD 7.5 removed (golang/go#63900).  Patch the module
# source from its distfile instead of fetching a fork.
SURVEY_MOD =	github.com/!alec!aivazis/survey/v2
SURVEY_V =	v2.3.7

CATEGORIES =	devel
HOMEPAGE =	https://cli.github.com/

MAINTAINER =	Klemens Nanni <kn@openbsd.org>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=	c pthread

MODULES =	lang/go
MODGO_LDFLAGS +=	-X "${MODGO_MODNAME}/internal/build.Version=$V"

TEST_TARGET =	./...

PORTHOME =	${WRKDIR}

post-extract:
	${UNZIP} -oq ${DISTDIR}/go_modules/${SURVEY_MOD}/@v/${SURVEY_V}.zip \
	    -d ${WRKDIR}/survey-extract
	mv ${WRKDIR}/survey-extract/github.com/AlecAivazis/survey/v2@${SURVEY_V} \
	    ${WRKDIR}/survey
	rm -rf ${WRKDIR}/survey-extract

post-patch:
	patch -d ${WRKDIR}/survey -p0 \
	    < ${FILESDIR}/patch-survey_terminal_runereader_posix_go
	patch -d ${WRKDIR}/survey -p0 \
	    < ${FILESDIR}/patch-survey_go_mod

pre-build:
	cd ${WRKSRC}; ${MODGO_CMD} mod edit -replace \
	    github.com/AlecAivazis/survey/v2=${WRKDIR}/survey

post-install:
	${WRKDIR}/go/bin/gen-docs --doc-path ${PREFIX}/man/man1 --man-page
	rm ${PREFIX}/bin/gen-docs

.include "modules.inc"
.include <bsd.port.mk>
