---
name: openbsd-port-patches
description: Create, refresh, review, or remove OpenBSD port source and dependency patches, including upstream backports and obsolete patches.
---

# Port patches

Use this skill for changes under a port's `patches/` or dependency patches under `files/`. For dependency selection or generated manifests, use [openbsd-port-dependencies](../openbsd-port-dependencies/SKILL.md). Do not use patch files to replace a supported ports variable or module feature. An upstream contribution requires a separate diff against upstream sources.

## Prerequisites

Read [UPDATE.md](../../../docs/UPDATE.md) and the port's Makefile, existing patches, and relevant module. Establish the exact distfile, working source root, patch application order, and upstream license. Work in a matching OpenBSD ports tree; inspect `make show=WRKSRC` and `make show=PATCHDIR`. Save unrelated working changes before regenerating anything.

## Procedure

1. Explain each patch's purpose and check upstream history for an equivalent fix. A patch can still apply after its underlying problem has been fixed; successful application alone does not justify retaining it.
2. Prefer a supported Makefile setting for paths, flags, dependencies, and installation. Keep necessary source changes small and specific. Separate portability fixes from packaging policy so the former can be proposed upstream.
3. On OpenBSD, run `make extract` and `make patch` for a fresh working source tree. A failed patch may leave a partially modified tree: inspect rejects and logs before retrying. Preserve needed source edits before any scoped `make clean`; never delete CVS metadata.
4. Edit the intended source file and preserve the original as required by `make update-patches`; check the matching `bsd.port.mk(5)` target before using options. Run `make update-patches` and inspect every output file, including unexpected changes and deleted patches. Do not generate patches from an already patched file as if it were upstream's original.
5. Generate the patch with the ports tooling from a clean extraction:
   `make update-patches` uses `diff -u -p` and writes `Index:` headers and
   `patch-*` names. Do not hand-assemble a new patch from Git output. When
   editing a patch by hand, preserve the same format exactly. Follow the
   style contract below.
6. Style contract for every patch:
   - Put a short rationale (and upstream commit/issue when it exists) above
     the header, wrapped to at most 72 columns. Keep the comment separate from
     the diff by one blank line.
   - Use exactly one `Index:` line with a path relative to the patched source
     root. Do not use an absolute path or `..`.
   - Follow it with `--- path.orig` and `+++ path` for the same target. Use
     `--- /dev/null` for a new file. Do not emit `+++ /dev/null`.
   - Keep one target file per patch. Multiple hunks for that target are fine.
     If a target already has a patch, merge the new change into that file;
     do not add a second patch file for the same `Index:` path. Regenerate the
     combined patch from a clean source tree with `make update-patches`.
   - Use unified `diff -u -p` output. Do not use `git diff` headers, context
     diffs, timestamps, CRLF, or CVS keywords such as `$OpenBSD$`.
   - Dependency patches under `files/<dependency>/` follow the same format but
     their `Index:` paths are relative to that dependency's extraction root.
   - Add an SPDX identifier only when the licensing of the authored material
     is established; existing upstream notices stay intact.
7. Check the format before building. From the repository root:

   ```sh
   ksh .agents/skills/openbsd-port-patches/scripts/check-patch-style.ksh \
       $(find category/port/patches category/port/files -name 'patch-*' 2>/dev/null)
   ```

   The checker verifies the comment width, single `Index:`, relative path,
   `.orig`/target labels, line endings, and that every hunk count matches its
   header. It does not prove that a patch applies; a fresh `make patch` does
   that.
8. SPDX identifiers are optional in this repository. Preserve upstream
   notices and record an accurate SPDX identifier only when the licensing of
   the authored material is established. Do not assign a blanket license,
   treat a context-line identifier as patch metadata, or rewrite unrelated
   patches to normalize headers. Resolve uncertain licensing before
   distribution.
9. For Cabal dependencies, inspect the existing `DIST_TUPLE` and
   `post-patch` handling in `net/simplexmq` or `net/simplex-chat`. Their
   `files/<dependency>/patch-*` paths are relative to each dependency's
   extraction root; ordinary `update-patches` on the main source does not
   automatically maintain them. Cargo vendored-source patches likewise depend
   on the module's actual extraction layout. Keep dependency versions and
   patch roots aligned.
10. Regenerate affected manifests through their supported module procedure,
    then verify a fresh `make patch`. Rebuild/test the affected behavior using
    [openbsd-port-validation](../openbsd-port-validation/SKILL.md). Port
    patches and an upstream-ready diff are separate deliverables: upstream
    generally does not need OpenBSD package layout or ports-only dependency
    policy.

When the host cannot run OpenBSD `make update-patches`, rebase local-only
changes on a pristine extraction of the exact new upstream sources in a
temporary directory. Save the pristine target, apply the reviewed changes,
then generate each patch with `diff -u -p` and the repository's `Index:` and
`.orig` labels. Do not copy an official patch set over local patches without
comparing their behavior: retain needed local changes, drop fixes superseded
upstream, and update vendor-version paths. This source-level regeneration is
static evidence only; verify the resulting patch set with a fresh OpenBSD
`make patch` before claiming validation.

## Acceptance and diagnosis

- No unexpected targets, absolute workstation paths, generated build noise, or unrelated changes appear in the diff. Backports identify their upstream commit and retain relevant notices.
- The style checker passes for every touched patch, and each comment stays
  within 72 columns.
- All relevant main-source and dependency patches apply in the real build order. Review offsets/fuzz and rejects; wrong versions, wrong extraction roots, or double application commonly explain failures.
- Remove obsolete patches only after comparing upstream behavior; record what replaced them. Keep regressions for behavior fixes when practical.
- An extracted or patched tree proves neither compilation nor runtime correctness. Record the exact targets run, failures, and untested behavior. Run `git diff --check` before delivery.

## References

- [Porting guide](https://www.openbsd.org/faq/ports/guide.html): updating ports and upstreaming portability changes.
- [update-patches(1)](https://man.openbsd.org/update-patches.1): patch
  generation, `Index:` headers, and the `diff -u -p` format.
- [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk.5): patch stages and `update-patches`.
- Repository examples: `net/i2pd/patches/patch-libi2pd_Crypto_cpp` and `net/simplexmq/files/tls/` for compatibility and documented backports.

## Maintenance & Continuous Learning

When this skill is used to modify the repository, review this skill after the
work. Update it when procedures, tools, configurations, project behavior, or
assumptions have changed, and add reusable knowledge that improves future use.
Correct instructions that proved wrong; keep examples and validation commands
current, and remove obsolete or duplicated guidance. Do not record one-off
execution details. Review linked skills and applicable `AGENTS.md` files for
consistency, validate local references, and run `perl tools/check-agent-sync.pl` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
