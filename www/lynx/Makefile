V=		2.9.3
COMMENT=	text web browser
DISTNAME=	lynx${V}
PKGNAME=	lynx-${V}
EXTRACT_SUFX=	.tar.bz2
CATEGORIES=	www net

REVISION=	1

HOMEPAGE=	https://lynx.invisible-island.net/

# GPLv2 only
PERMIT_PACKAGE=	Yes

# uses pledge() and unveil()
WANTLIB +=	c crypto curses iconv ssl z

SITES=		https://invisible-mirror.net/archives/lynx/tarballs/ \
		ftp://ftp.invisible-island.net/lynx/tarballs/

LIB_DEPENDS=	converters/libiconv

CONFIGURE_STYLE= gnu
CONFIGURE_ARGS=	--datarootdir="${PREFIX}/share/doc/lynx" \
			--disable-idna \
			--disable-nls \
			--disable-bibp-urls \
			--disable-dired \
			--disable-cgi-links \
			--disable-exec-links \
			--disable-exec-scripts \
			--disable-finger \
			--disable-nsl-fork \
			--enable-default-colors \
			--enable-ipv6 \
			--enable-widec \
			--with-ssl=/usr \
			--with-zlib \
			--without-brotli \
			--without-bzlib

# This disables most calls to getpw*(3) so we can avoid pledge "getpw".
CONFIGURE_ENV += CFLAGS="-DNOUSERS"

# Point the decompressor paths at /dev/null so HTGetProgramPath rejects
# them; no external helper can be selected after pledge(2).
CONFIGURE_ENV += ac_cv_path_BZIP2=/dev/null \
		ac_cv_path_GZIP=/dev/null \
		ac_cv_path_UNCOMPRESS=/dev/null \
		ac_cv_path_COMPRESS=/dev/null \
		ac_cv_path_ZSTD=/dev/null

MAKE_FILE=	makefile

FAKE_FLAGS=	SYSCONFDIR="${DESTDIR}${PREFIX}/share/examples/lynx"
INSTALL_TARGET=	install install-help install-doc

NO_TEST=	Yes

.include <bsd.port.mk>
