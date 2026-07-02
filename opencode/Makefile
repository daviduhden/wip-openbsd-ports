COMMENT =		open source coding agent

V =			1.17.13
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
	@# Replace Bun APIs with Node.js equivalents in all source files.
	@# This single script handles what would otherwise need ~34 patches.
	@echo "===> Running Bun→Node.js fixup"
	@cd ${WRKSRC} && node ${FILESDIR}/fixup.mjs
	@# Resolve Bun catalog: references to concrete versions for npm.
	@cd ${WRKSRC} && python3 -c "
import json, glob
with open('package.json') as f:
    cat = json.load(f).get('workspaces',{}).get('catalog',{})
if not cat:
    import sys; sys.exit(0)
for p in glob.glob('**/package.json', recursive=True):
    try:
        with open(p) as f: content = f.read()
        changed = False
        for n,v in cat.items():
            old = f'\"{n}\": \"catalog:\"'
            if old in content:
                content = content.replace(old, f'\"{n}\": \"{v}\"')
                changed = True
        if '\"workspace:*\"' in content:
            content = content.replace('\"workspace:*\"', '\"*\"')
            changed = True
        if changed:
            with open(p,'w') as f: f.write(content)
    except: pass
" 2>/dev/null
	@if [ ! -d ${WRKSRC}/node_modules ]; then \
		echo "===> Installing npm dependencies (network required)"; \
		cd ${WRKSRC} && \
			npm install --workspaces --legacy-peer-deps \
				--ignore-scripts --force && \
			npm install --no-save --ignore-scripts tsx ioredis; \
	fi
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
