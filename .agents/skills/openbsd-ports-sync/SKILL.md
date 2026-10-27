---
name: openbsd-ports-sync
description: Synchronize selected wip-openbsd-ports sources with an existing OpenBSD ports tree while preserving CVS metadata, backups, shared files, and local changes.
---

# Synchronize ports trees

Use this skill when copying ports into `/usr/ports` or bringing tested changes back into Git. For submission artifacts, use [openbsd-port-cvs](../openbsd-port-cvs/SKILL.md). Do not use this workflow to initialize or replace a complete tree, provision the host, or update unrelated ports.

## Prerequisites

Read [BUILDING.md](../../../docs/BUILDING.md) and inspect [fetch-ports.ksh](../../../fetch-ports.ksh). Run the helper with OpenBSD `ksh`; its supported safe overlay mode requires an existing tree containing `Makefile`, `infrastructure/`, and the destination category. Confirm both source and destination paths, permissions, current Git/CVS changes, target OpenBSD branch, and the requested port selection before copying. Record local changes outside the destination being replaced.

## Procedure

1. From the Git root, discover actual installable paths without modification:

   ```sh
   ./fetch-ports.ksh --list
   git status --short
   ```

   `sysutils/uutils` is a group; select a child such as `sysutils/uutils/awk`. Category-only paths, parent traversal, and symlinked roots are rejected. `WIP_OPENBSD_PORTS_DIR` can explicitly identify the Git checkout.
2. Inspect the destination with `cvs -nq update` and `cvs diff -uN` in the selected scope; the former contacts CVS but does not update files. For a Git tree, inspect its status and diff instead. Preserve modified, unknown, and removed files before replacement. Review shared parent files such as `sysutils/uutils/Makefile` and `Makefile.inc` separately: they affect siblings.
3. Copy only the authorized selection, using `doas` only if filesystem permissions require it:

   ```sh
   doas ./fetch-ports.ksh --copy-only /usr/ports net/simplexmq net/simplex-chat
   ```

   Without port arguments this copies every local port. It replaces each selected port, so stale patches disappear. Existing ports are saved under `TREE/.wip-backups/<label>.XXXXXXXX/port`; nested CVS directories are preserved. The label is the parent path with slashes changed to underscores, followed by `-<port>`, for example `sysutils_uutils-awk`.
4. Retain `.wip-backups` and inspect `.wip-changes/<label>.created.txt`, `.deleted.txt`, and `.created-dirs.txt`. Lists describe the latest replacement relative to that port, exclude CVS metadata, and do not register CVS changes. Repeated copies overwrite these lists, so preserve the initial lists or recompute against the recorded CVS baseline when preparing a cumulative submission.
5. Inspect the account registry diff. The helper merges entries for the
   **selected ports** (all local installable ports only when no port list is
   given) into `infrastructure/db/user.list`; it preserves upstream entries
   and rejects conflicting IDs/names. Never overwrite that registry with the
   repository snapshot. An account conflict can occur after ports have already
   been copied: inspect the partial result before retrying.
6. Review the destination and validate the copied sources with [openbsd-port-validation](../openbsd-port-validation/SKILL.md). Copy reviewed, tested source changes back to the matching Git paths explicitly, including manifests, checksums, patches, package files, and necessary shared parent files. Review removals as well as additions; copying files over an old directory alone leaves stale patches. Exclude CVS metadata, work directories, packages, backups, and change lists. Do not run a broad reverse overlay over unrelated changes.
7. Compare the Git version with the actual tested tree and inspect Git status/diff. If they differ, synchronize and repeat the affected validation; record which tree and revision were tested.

## Important boundaries

The helper backs up replaced **port directories**. It copies shared parent files directly, without equivalent backups or per-port change lists; preserve and review these separately. It changes copied permissions so the ports build user can read sources.

The default interactive helper removes the existing `/usr/ports` contents, checks out CVS, installs a package, changes shell/ports configuration, and may create accounts and configure `doas`. `--no-provision` only skips user creation and `doas` setup: it still replaces the checkout and changes configuration. Neither invocation is authorized by an ordinary synchronization request; destructive or global system changes require explicit authorization. `--copy-only` does not provision the host or create daemon accounts.

## Acceptance and diagnosis

Accept when the requested paths and shared files match the intended sources, destination changes are accounted for, CVS metadata and recoverable backups remain intact, registry changes are reviewed, and the Git sources match what was tested. Report any unperformed build/runtime checks.

For rejected paths, verify the path appears in `--list` and the destination is a real existing tree. For account conflicts, compare both registries and resolve allocation against the current official registry; do not force an overwrite. For copy failures, inspect logged staging/backup paths and completed replacements before restoring selected files; do not delete metadata or blindly repeat the entire collection copy.

References: [OpenBSD ports setup](https://www.openbsd.org/faq/ports/ports.html), [cvs(1)](https://man.openbsd.org/cvs.1), and [openbsd-port-cvs](../openbsd-port-cvs/SKILL.md).

## Maintenance & Continuous Learning

When this skill is used to modify the repository, review this skill after the
work. Update it when procedures, tools, configurations, project behavior, or
assumptions have changed, and add reusable knowledge that improves future use.
Correct instructions that proved wrong; keep examples and validation commands
current, and remove obsolete or duplicated guidance. Do not record one-off
execution details. Review linked skills and applicable `AGENTS.md` files for
consistency, validate local references, and run `python3 scripts/validate-agent-knowledge.py --scope worktree` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
