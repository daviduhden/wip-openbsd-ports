# The distfile keeps the GitHub project-tag name (see GH_DISTFILE); the
# package is named after the project it replaces.
PKGNAME ?=	uutils-${GH_PROJECT}-${GH_TAGNAME}

GH_ACCOUNT ?=	uutils

CATEGORIES ?=	sysutils

HOMEPAGE ?=	https://uutils.org/

# MIT
PERMIT_PACKAGE ?=	Yes

MODULES ?=	devel/cargo

CONFIGURE_STYLE ?=	cargo
