COMMENT-main =		fast-paced multiplayer first-person shooter
COMMENT-server =	dedicated AssaultCube server
COMMENT-data =		AssaultCube game data

GH_ACCOUNT =		assaultcube
GH_PROJECT =		AC
GH_TAGNAME =		v1.3.0.2
PKGNAME =		assaultcube-${GH_TAGNAME:S/v//}
CATEGORIES =		games
HOMEPAGE =		https://assault.cubers.net/

MULTI_PACKAGES =		-main -server -data
PKG_ARCH-data =		*

# Modified zlib-style engine license; mixed restrictive/non-commercial assets.
# Upstream's aggregate distribution permission requires unmodified packages.
PERMIT_PACKAGE =	no modification, non-commercial assets
PERMIT_DISTFILES =	Yes

COMPILER =		base-clang ports-gcc
USE_GMAKE =		Yes
WRKSRC =		${WRKDIST}/source/src

LIB_DEPENDS-main =	devel/sdl2-image \
			audio/openal \
			audio/libvorbis \
			net/enet
LIB_DEPENDS-server =	net/enet
WANTLIB-main +=		${COMPILER_LIBCXX} GL SDL2 SDL2_image X11 c enet
WANTLIB-main +=		m openal pthread vorbisfile z
WANTLIB-server +=	${COMPILER_LIBCXX} c enet m pthread z
RUN_DEPENDS-main =	${BASE_PKGPATH},-data=${GH_TAGNAME:S/v//}
RUN_DEPENDS-server =	${BASE_PKGPATH},-data=${GH_TAGNAME:S/v//}

MAKE_ENV =		CXXFLAGS="${CXXFLAGS} -std=c++11"
MAKE_FLAGS =		CXX="${CXX}" USE_SYSTEM_ENET=1 \
			INCLUDES="-I. -Ibot -I${LOCALBASE}/include -I${X11BASE}/include" \
			CLIENT_INCLUDES="-I. -Ibot -I${LOCALBASE}/include -I${LOCALBASE}/include/SDL2 -I${X11BASE}/include" \
			CLIENT_LIBS="${LDFLAGS} -L${LOCALBASE}/lib -L${X11BASE}/lib -lSDL2 -lSDL2_image -lGL -lX11 -lopenal -lvorbisfile -lenet -lz -lpthread" \
			SERVER_LIBS="${LDFLAGS} -L${LOCALBASE}/lib -lenet -lz -lpthread"

# No upstream automated test suite. Client/server interoperability is a
# separate, unprivileged native runtime test, not a package-build test.
NO_TEST =		Yes

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/ac_client ${PREFIX}/libexec/assaultcube-client
	${INSTALL_PROGRAM} ${WRKSRC}/ac_server ${PREFIX}/libexec/assaultcube-server
.for script in assaultcube assaultcube-server
	${SUBST_CMD} -c -m 555 ${FILESDIR}/${script} ${WRKDIR}/${script}
	${INSTALL_SCRIPT} ${WRKDIR}/${script} ${PREFIX}/bin/
.endfor
	${INSTALL_DATA_DIR} ${PREFIX}/share/assaultcube
	cp -R ${WRKDIST}/{bot,config,docs,packages} ${PREFIX}/share/assaultcube/

.include <bsd.port.mk>
