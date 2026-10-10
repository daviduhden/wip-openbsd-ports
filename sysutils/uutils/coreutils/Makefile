COMMENT =	alternative implementation of GNU coreutils

GH_PROJECT =	coreutils
GH_TAGNAME =	0.12.0

WANTLIB += ${MODCARGO_WANTLIB} m

# Select the standalone workspace packages; the root package builds the
# multicall executable. Keep this list in sync with pkg/PLIST.
COREUTILS =	\
		arch b2sum base32 base64 basename basenc \
		cat chgrp chmod chown chroot cksum \
		comm cp csplit cut date dd \
		df dir dircolors dirname du echo \
		env expand expr factor false fmt \
		fold groups head hostid hostname id \
		install join kill link ln logname \
		ls md5sum mkdir mkfifo mknod mktemp \
		more mv nice nl nohup nproc \
		numfmt od paste pathchk pinky pr \
		printenv printf ptx pwd readlink realpath \
		rm rmdir seq sha1sum sha224sum sha256sum \
		sha384sum sha512sum shred shuf sleep sort \
		split stat stdbuf stty sum sync \
		tac tail tee test timeout touch \
		tr true truncate tsort tty uname \
		unexpand uniq unlink uptime users vdir \
		wc who whoami yes

MODCARGO_INSTALL =	No

.for utility in ${COREUTILS}
MODCARGO_BUILD_ARGS +=	-p uu_${utility}
.endfor

# Keep stdbuf's preload library in the package instead of extracting it to /tmp.
MODCARGO_BUILD_ARGS +=	--features uu_stdbuf/feat_external_libstdbuf
MODCARGO_ENV +=		LIBSTDBUF_DIR=${PREFIX}/libexec/uutils-coreutils

do-install:
.for utility in ${COREUTILS}
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/${utility} \
	    ${PREFIX}/bin/uu-${utility}
.endfor
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/test ${PREFIX}/bin/'uu-['
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/uutils-coreutils
	${INSTALL_DATA} ${MODCARGO_TARGET_DIR}/release/deps/libstdbuf.so \
	    ${PREFIX}/libexec/uutils-coreutils/

.include "crates.inc"

.include <bsd.port.mk>
