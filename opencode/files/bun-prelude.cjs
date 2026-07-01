// OpenBSD port prelude: stub globalThis.Bun for vendored packages
// (@opentui/core, @opentui/solid) that assume Bun is always present.
// Loaded via --require before any module executes.

const noop = () => {}
const noopAsync = async () => {}
const noopStr = () => ""
const noopBuf = () => Buffer.alloc(0)

globalThis.Bun = {
  plugin: noop,
  $: new Proxy(noopAsync, { get: () => noopAsync }),
  file: () => ({ text: noopAsync, json: noopAsync, arrayBuffer: noopAsync }),
  write: noopAsync,
  stdin: { text: noopAsync, stream: () => ({ [Symbol.asyncIterator]() { return { next: async () => ({ done: true, value: undefined }) } } }) },
  which: noopStr,
  hash: (s) => { let h = 0; for (let i = 0; i < s.length; i++) { h = ((h << 5) - h) + s.charCodeAt(i); h |= 0 } return h },
  stringWidth: (s) => s.length,
  sleep: noopAsync,
  spawn: () => ({ exited: Promise.resolve(0), stdout: {}, stderr: {} }),
  spawnSync: () => ({ exitCode: 0, stdout: Buffer.alloc(0), stderr: Buffer.alloc(0) }),
  connect: noopAsync,
  listen: noop,
  dlopen: () => ({ symbols: new Proxy({}, { get: () => noop }) }),
  FFI: { dlopen: () => ({ symbols: new Proxy({}, { get: () => noop }) }), linkSymbols: noop, close: noop, ptr: noop, toArrayBuffer: noopBuf, toBuffer: noopBuf, readMemory: noopBuf, CString: noopBuf, ptrOf: noop },
  ptr: noop,
  toArrayBuffer: noopBuf,
  main: "",
  argv: [],
  env: {},
  version: "0.0.0",
  revision: "00000000",
  build: 0,
  TOML: { parse: () => ({}) },
  nanosecond: () => 0n,
  randomUUIDv7: () => "00000000-0000-0000-0000-000000000000",
  inflateSync: (buf) => buf,
  deflateSync: (buf) => buf,
  gunzipSync: (buf) => buf,
  gzipSync: (buf) => buf,
  deepEquals: (a, b) => a === b,
  escapeHTML: (s) => s,
  fileURLToPath: (url) => String(url).replace(/^file:\/\//, ""),
  pathToFileURL: (p) => new URL("file://" + p),
  resolveSync: (specifier, from) => specifier,
  password: noopAsync,
}

// Prevent packages from detecting missing Bun environment
process.env.BUN_INSTALL = "/nonexistent"
