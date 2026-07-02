// Copyright (c) 2026 David David Uhden Collado <david@uhden.dev>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

const textExts = [".txt", ".md", ".csv", ".jsonl", ".yml", ".yaml", ".toml"]
const fileExts = [".wasm", ".mp3", ".ogg", ".wav", ".aac", ".flac"]

export function resolve(specifier, context, nextResolve) {
  if (specifier === "bun" || specifier.startsWith("bun:")) {
    return { format: "module", shortCircuit: true, url: "node:stub:bun" }
  }
  for (const ext of [...textExts, ...fileExts]) {
    if (specifier.endsWith(ext)) {
      try {
        const resolved = nextResolve(specifier, context)
        if (resolved && resolved.url) return { format: "module", shortCircuit: true, url: resolved.url }
      } catch (e) {}
      if (context.parentURL) {
        return { format: "module", shortCircuit: true, url: new URL(specifier, context.parentURL).href }
      }
    }
  }
  return nextResolve(specifier, context)
}

export function load(url, context, nextLoad) {
  if (url === "node:stub:bun") {
    return { format: "module", shortCircuit: true, source: "function b(){}\nconst e=new Proxy(b,{get:()=>b,apply:()=>({})});e.plugin=b;e.$=b;export default e;export{b as plugin,b as $,b as which,b as file,b as write,b as stdin,b as spawn,b as spawnSync,b as hash,b as stringWidth,b as sleep,b as connect,b as listen,b as dlopen,b as FFI,b as Database}" }
  }
  if (context.format !== "module" && context.format !== undefined) return nextLoad(url, context)
  for (const ext of textExts) {
    if (url.endsWith(ext)) {
      try {
        const path = fileURLToPath(url)
        const source = readFileSync(path, "utf8")
        return { format: "module", shortCircuit: true, source: "export default " + JSON.stringify(source) + ";\n" }
      } catch (e) { return nextLoad(url, context) }
    }
  }
  for (const ext of fileExts) {
    if (url.endsWith(ext)) {
      try {
        const path = fileURLToPath(url)
        return { format: "module", shortCircuit: true, source: "export default " + JSON.stringify(path) + ";\n" }
      } catch (e) { return nextLoad(url, context) }
    }
  }
  return nextLoad(url, context)
}
