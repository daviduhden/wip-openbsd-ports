#!/bin/ksh
set -eu
# Create patched dependency copies in ${WRKDIR}/deps/
# Called from do-build before cabal build

WRKDIR="${1:?}"
FILESDIR="${2:?}"
SPLITMIX_V="${3:-0.1.3.1}"
DEPS="${WRKDIR}/deps"
HACKAGE="https://hackage.haskell.org/package"

mkdir -p "${DEPS}"

# --- splitmix: download from hackage and patch ---
if [ ! -d "${DEPS}/splitmix" ]; then
	ftp -o "${DEPS}/splitmix.tar.gz" \
		"${HACKAGE}/splitmix-${SPLITMIX_V}/splitmix-${SPLITMIX_V}.tar.gz"
	tar -xzf "${DEPS}/splitmix.tar.gz" -C "${DEPS}"
	mv "${DEPS}/splitmix-${SPLITMIX_V}" "${DEPS}/splitmix"
	rm -f "${DEPS}/splitmix.tar.gz"
	patch -d "${DEPS}/splitmix" -p0 < "${FILESDIR}/patch-deps-splitmix"
fi

# --- aeson: clone simplex-chat fork and patch ---
if [ ! -d "${DEPS}/aeson" ]; then
	git clone --depth 1 https://github.com/simplex-chat/aeson.git "${DEPS}/aeson"
	cd "${DEPS}/aeson"
	git fetch --depth 1 origin aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b
	git checkout aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b
	patch -p0 < "${FILESDIR}/patch-deps-aeson"
fi

# --- warp: clone wai fork and patch ---
if [ ! -d "${DEPS}/warp" ]; then
	git clone --depth 1 https://github.com/simplex-chat/wai.git "${DEPS}/wai-src"
	cd "${DEPS}/wai-src"
	git fetch --depth 1 origin 2f6e5aa5f05ba9140ac99e195ee647b4f7d926b0
	git checkout 2f6e5aa5f05ba9140ac99e195ee647b4f7d926b0
	cp -r warp "${DEPS}/warp"
	patch -d "${DEPS}/warp" -p0 < "${FILESDIR}/patch-deps-warp"
	rm -rf "${DEPS}/wai-src"
fi

# --- tls: extract from cabal cache and patch ---
TLS_VER="2.1.6"
if [ ! -d "${DEPS}/tls" ]; then
	if [ -f "${WRKDIR}/.cabal/packages/hackage.haskell.org/tls/${TLS_VER}/tls-${TLS_VER}.tar.gz" ]; then
		tar -xzf "${WRKDIR}/.cabal/packages/hackage.haskell.org/tls/${TLS_VER}/tls-${TLS_VER}.tar.gz" -C "${DEPS}"
		mv "${DEPS}/tls-${TLS_VER}" "${DEPS}/tls"
	else
		ftp -o "${DEPS}/tls.tar.gz" \
			"${HACKAGE}/tls-${TLS_VER}/tls-${TLS_VER}.tar.gz"
		tar -xzf "${DEPS}/tls.tar.gz" -C "${DEPS}"
		mv "${DEPS}/tls-${TLS_VER}" "${DEPS}/tls"
		rm -f "${DEPS}/tls.tar.gz"
	fi
	patch -d "${DEPS}/tls" -p0 < "${FILESDIR}/patch-deps-tls"
fi

# --- cryptostore: extract from cabal cache and patch ---
if [ ! -d "${DEPS}/cryptostore" ]; then
	CS_VER="0.5.0.0"
	if [ -f "${WRKDIR}/.cabal/packages/hackage.haskell.org/cryptostore/${CS_VER}/cryptostore-${CS_VER}.tar.gz" ]; then
		tar -xzf "${WRKDIR}/.cabal/packages/hackage.haskell.org/cryptostore/${CS_VER}/cryptostore-${CS_VER}.tar.gz" -C "${DEPS}"
		mv "${DEPS}/cryptostore-${CS_VER}" "${DEPS}/cryptostore"
	else
		ftp -o "${DEPS}/cryptostore.tar.gz" \
			"${HACKAGE}/cryptostore-${CS_VER}/cryptostore-${CS_VER}.tar.gz"
		tar -xzf "${DEPS}/cryptostore.tar.gz" -C "${DEPS}"
		mv "${DEPS}/cryptostore-${CS_VER}" "${DEPS}/cryptostore"
		rm -f "${DEPS}/cryptostore.tar.gz"
	fi
	patch -d "${DEPS}/cryptostore" -p0 < "${FILESDIR}/patch-deps-cryptostore"
fi
