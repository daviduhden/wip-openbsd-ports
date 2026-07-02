#!/usr/bin/env node
// fixup.mjs — replace all Bun-specific code with Node.js equivalents.
// Run from ${WRKSRC} after 'make patch' (which applies the few
// semantic patches that can't be automated).
//
// This script replaces 34 of the 39 patches, keeping only:
//   - ripgrep.ts    (complete rewrite)
//   - npm-config.ts (CJS interop)
//   - rpc.ts        (typeof guards in function bodies)
//   - index.ts      (lazy TUI command load)
//   - runtime.stdin.ts (add readStdinText function)

import { readFileSync, writeFileSync, readdirSync, statSync } from "fs";
import { join, relative } from "path";

function walk(dir, exts) {
  const results = [];
  try {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      let st;
      try { st = statSync(full) } catch { continue }
      if (st.isDirectory()) {
        if (entry === "node_modules" || entry === ".git") continue;
        results.push(...walk(full, exts));
      } else if (exts.some(e => entry.endsWith(e))) {
        results.push(relative(process.cwd(), full));
      }
    }
  } catch {}
  return results;
}

const root = process.argv[2] || ".";

function read(f) { return readFileSync(f, "utf8") }
function write(f, c) { writeFileSync(f, c) }

// ─── 1. Replace Bun-only import sources ──────────────────────────

function replaceImports(content, file) {
  // import { pathToFileURL } from "bun"  →  from "url"
  content = content.replace(
    /import\s*\{([^}]*)\}\s*from\s*"bun"/g,
    (m, names) => {
      const filtered = names.split(",").filter(n => n.trim() !== "pathToFileURL" && n.trim() !== "fileURLToPath");
      if (filtered.length === 0) return "";
      if (file.includes("message-v2")) {
        // SystemError type import → local type
        return `type SystemError = Error & { code?: string; syscall?: string }`;
      }
      return m; // keep other bun imports as-is (will be stubbed by loader)
    }
  );
  // Specific: pathToFileURL from bun
  content = content.replace(
    /import\s*\{\s*(pathToFileURL)\s*\}\s*from\s*"bun"/g,
    'import { $1 } from "url"'
  );
  content = content.replace(
    /import\s*\{\s*(fileURLToPath)\s*\}\s*from\s*"bun"/g,
    'import { $1 } from "url"'
  );
  return content;
}

// ─── 2. Replace Bun.stringWidth → stringWidth ────────────────────

function replaceStringWidth(content, file) {
  if (!content.includes("Bun.stringWidth")) return content;
  // Add import if not already present
  if (!content.includes('from "string-width"')) {
    content = content.replace(
      /(import\s+[^;]+;\n)/,
      '$1import stringWidth from "string-width";\n'
    );
    if (!content.includes('from "string-width"')) {
      // Add at top if no import matched
      content = 'import stringWidth from "string-width";\n' + content;
    }
  }
  return content.replace(/Bun\.stringWidth\(/g, "stringWidth(");
}

// ─── 3. Replace Bun.stdin.text() → readStdinText() ───────────────

function replaceStdin(content, file) {
  if (!content.includes("Bun.stdin")) return content;

  // Add Worker import to tui.ts
  if (file.includes("cli/cmd/tui.ts") && !content.includes('node:worker_threads')) {
    content = 'import { Worker } from "node:worker_threads";\n' + content;
  }

  // Add import
  if (!content.includes("readStdinText")) {
    const dir = file.includes("cmd/tui") ? "./run/runtime.stdin" : "./run/runtime.stdin";
    content = content.replace(
      /(import\s+[^;]+;\n)/,
      `$1import { readStdinText } from "${dir}";\n`
    );
    if (!content.includes("readStdinText")) {
      content = `import { readStdinText } from "${dir}";\n` + content;
    }
  }
  return content.replace(/await\s+Bun\.stdin\.text\(\)/g, "await readStdinText()");
}

// ─── 4. Replace Bun.file / Bun.write → fs/promises ───────────────

function replaceFileIO(content, file) {
  let changed = false;
  // Bun.file(p).text() → readFile(p, "utf8")
  if (/Bun\.file\([^)]+\)\.text\(\)/.test(content)) {
    if (!content.includes('from "fs/promises"') && !content.includes("from 'fs/promises'")) {
      content = content.replace(
        /(import\s+[^;]+;\n)/,
        '$1import { readFile, writeFile } from "fs/promises";\n'
      );
      if (!content.includes("fs/promises")) {
        content = 'import { readFile, writeFile } from "fs/promises";\n' + content;
      }
    }
    content = content.replace(
      /Bun\.file\(([^)]+)\)\.text\(\)/g,
      'readFile($1, "utf8")'
    );
    changed = true;
  }
  // Bun.file(p).json() → JSON.parse(await readFile(p, "utf8"))
  if (/Bun\.file\([^)]+\)\.json\(\)/.test(content)) {
    if (!content.includes("fs/promises")) {
      content = 'import { readFile, writeFile } from "fs/promises";\n' + content;
    }
    content = content.replace(
      /Bun\.file\(([^)]+)\)\.json\(\)/g,
      'JSON.parse(await readFile($1, "utf8"))'
    );
    changed = true;
  }
  // await Bun.write(p, c) → await writeFile(p, c)
  if (/await\s+Bun\.write\(/.test(content)) {
    if (!content.includes("fs/promises")) {
      content = 'import { readFile, writeFile } from "fs/promises";\n' + content;
    }
    content = content.replace(
      /await\s+Bun\.write\(([^,]+),\s*([^)]+)\)/g,
      'await writeFile($1, $2)'
    );
    changed = true;
  }
  return content;
}

// ─── 5. Replace Bun.hash → Hash.fast ────────────────────────────

function replaceHash(content, file) {
  if (!content.includes("Bun.hash")) return content;
  if (!content.includes('import { Hash }')) {
    content = content.replace(
      /(import\s+[^;]+;\n)/,
      '$1import { Hash } from "../util/hash";\n'
    );
  }
  return content.replace(/Bun\.hash\((\w+)\)\.toString\(16\)/g, 'Hash.fast($1)');
}

// ─── 6. Remove typeof Bun checks ────────────────────────────────

function removeTypeofBun(content) {
  // typeof Bun !== "undefined" ? ... : ...  → just the Node path
  content = content.replace(
    /typeof Bun\s*!==\s*"undefined"\s*\?\s*([^:]+):\s*([^;]+)/g,
    (_, bun, node) => node.trim()
  );
  // Remove null Bun.$.set assignments
  content = content.replace(
    /\$\s*:\s*typeof Bun\s*===\s*"undefined"\s*\?\s*undefined\s*:\s*Bun\.\$,/g,
    "$: undefined as any,"
  );
  return content;
}

// ─── 7. Plugin disablement ── handled by individual patches

// ─── 8. Upgrade / install disable ── handled by individual patches

// ─── 9. Zed / Terminal / Persistence stubs ──────────────────────

function stubModules(content, file) {
  const bn = file.replace(/.*\//, "");

  // editor-zed.ts: stub Database class
  if (bn === "editor-zed.ts") {
    content = content.replace(
      /import\s*\{\s*Database\s*\}\s*from\s*"bun:sqlite";?\n?/,
      `class Database {
  constructor(_dbPath, _options) { /* Zed sqlite disabled */ }
  query() { return { all: () => [], get: () => undefined } }
  close() { return }
}
`
    );
    return content;
  }

  // terminal-win32.ts: stub Windows functions
  if (bn === "terminal-win32.ts") {
    content = content.replace(
      /import\s*\{\s*dlopen,\s*ptr\s*\}\s*from\s*"bun:ffi";?\n?/g,
      ""
    );
    content = content.replace(
      /export function win32DisableProcessedInput[\s\S]*?(?=^export function|^$)/m,
      "export function win32DisableProcessedInput() { return }\n\n"
    );
    content = content.replace(
      /export function win32FlushInputBuffer[\s\S]*?(?=^export function|^$)/m,
      "export function win32FlushInputBuffer() { return }\n\n"
    );
    content = content.replace(
      /export function win32InstallCtrlCGuard[\s\S]*/,
      "export function win32InstallCtrlCGuard() { return () => {} }"
    );
    return content;
  }

  // persistence.ts: fs/promises
  if (bn === "persistence.ts") {
    content = content.replace(
      /Bun\.file\(([^)]+)\)\.text\(\)/g,
      'await readFile($1, "utf8")'
    );
    content = content.replace(
      /Bun\.file\(([^)]+)\)\.json\(\)/g,
      'JSON.parse(await readFile($1, "utf8"))'
    );
    content = content.replace(
      /await\s+Bun\.write\(([^,]+),\s*([^)]+)\)/g,
      'await writeFile($1, $2)'
    );
    if (!content.includes("fs/promises")) {
      content = content.replace(
        /import\s*\{([^}]*)\}\s*from\s*"fs\/promises"/,
        'import { $1, readFile, writeFile } from "fs/promises"'
      );
    }
    return content;
  }

  // plugin/openai/ws.ts: remove Bun proxy detection  
  if (bn === "ws.ts" && file.includes("plugin/openai")) {
    content = content.replace(/import\s*\{\s*ProxyEnv\s*\}\s*from\s*"[^"]+";?\n?/g, "");
    // Remove the proxy block and simplify connect
    content = content.replace(
      "// Bun does not apply HTTP(S)_PROXY to WebSockets unless the proxy is supplied explicitly.\n    const proxy =\n      typeof Bun === \"undefined\"\n        ? undefined\n        : ProxyEnv.getProxyForUrl(options.url.replace(/^wss:/, \"https:\").replace(/^ws:/, \"http:\"))\n    const connect = { headers, ...(proxy ? { proxy } : {}) }",
      "// Proxy detection removed for OpenBSD port\n    const connect = { headers }"
    );
    return content;
  }

  return content;
}

// ─── 10. Package.json additions ──────────────────────────────────

function fixPackageJson(content, file) {
  if (!file.endsWith("package.json")) return content;
  const bn = file.replace(/.*\//, "");

  if ((file.includes("opencode") || file.includes("tui")) && file.includes("packages/")) {
    if (!content.includes('"string-width"')) {
      content = content.replace(
        /"dependencies"\s*:\s*\{/,
        '"dependencies": {\n    "string-width": "7.2.0",'
      );
    }
  }
  return content;
}

// ─── Main ───────────────────────────────────────────────────────

const files = walk(".", [".ts", ".tsx", ".txt", ".json"]).filter(f => f.startsWith("packages/"));
let count = 0;

for (const file of files) {
  let content;
  try {
    content = read(file);
  } catch { continue; }

  const orig = content;

  content = replaceImports(content, file);
  content = replaceStringWidth(content, file);
  content = replaceStdin(content, file);
  content = replaceFileIO(content, file);
  content = replaceHash(content, file);
  content = removeTypeofBun(content);
  content = stubModules(content, file);
  content = fixPackageJson(content, file);

  if (content !== orig) {
    write(file, content);
    count++;
    console.log(`  ${file}`);
  }
}

console.log(`fixup: ${count} files modified`);
