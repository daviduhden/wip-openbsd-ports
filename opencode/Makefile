COMMENT =		open source coding agent

V =			1.17.12
GH_ACCOUNT =		anomalyco
GH_PROJECT =		opencode
GH_TAGNAME =		v${V}

CATEGORIES =		devel

HOMEPAGE =		https://opencode.ai/

# MIT
PERMIT_PACKAGE =	Yes

BUILD_DEPENDS =		lang/node
RUN_DEPENDS =		lang/node

NO_TEST =		Yes

PATCHORIG =		.orig.port

tarball:
	@# Create opencode-v${V}-node-modules.tar.gz from
	@# upstream source.  Network access required.
	@ftp -o - https://github.com/${GH_ACCOUNT}/${GH_PROJECT}/archive/refs/tags/${GH_TAGNAME}.tar.gz | \
		tar xzf -
	@mv ${GH_PROJECT}-${V} ${GH_PROJECT}-${V}-nm
	@for p in ${.CURDIR}/patches/*; do \
		patch -d ${GH_PROJECT}-${V}-nm -p0 -s < $$p || exit 1; \
	done
	@cd ${GH_PROJECT}-${V}-nm && \
		npm install --workspaces --legacy-peer-deps \
			--ignore-scripts --force
	@cd ${GH_PROJECT}-${V}-nm && \
		npm install --no-save --ignore-scripts tsx
	@cd ${GH_PROJECT}-${V}-nm && \
		find . -name '*.orig' -delete
	@tar czf opencode-v${V}-node-modules.tar.gz \
		-C ${GH_PROJECT}-${V}-nm node_modules
	@rm -rf ${GH_PROJECT}-${V}-nm
	@echo "=== distfile ready ==="
	@ls -lh opencode-v${V}-node-modules.tar.gz

pre-build:
	@test -d ${WRKSRC}/node_modules || \
		( echo "node_modules/ not found in WRKSRC."; \
		  echo "Extract opencode-v${V}-node-modules.tar.gz"; \
		  echo "into ${WRKSRC} before building."; \
		  exit 1 )
	rm -f ${WRKSRC}/bun.lock ${WRKSRC}/github/bun.lock

do-build:
	cd ${WRKSRC} && ${SETENV} HOME=${WRKDIR} \
		CFLAGS="-I${LOCALBASE}/include" \
		CXXFLAGS="-I${LOCALBASE}/include" \
		npm rebuild --nodedir=${LOCALBASE} \
		-w packages/opencode -w packages/core || true

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/lib/node_modules/opencode
	cd ${WRKSRC} && cp -a package.json packages node_modules \
		${PREFIX}/lib/node_modules/opencode/
	${INSTALL_DATA} ${FILESDIR}/txt-loader.mjs \
		${PREFIX}/lib/node_modules/opencode/
	${INSTALL_DATA} ${FILESDIR}/bun-prelude.cjs \
		${PREFIX}/lib/node_modules/opencode/
	${INSTALL_SCRIPT} ${FILESDIR}/opencode ${PREFIX}/bin/opencode

.include <bsd.port.mk>
