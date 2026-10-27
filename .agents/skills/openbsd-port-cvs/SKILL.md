---
name: openbsd-port-cvs
description: Prepare complete CVS diffs for existing official OpenBSD ports or source archives for new ports, including nested shared files and account-registry changes.
---

# Prepare OpenBSD submissions

Use for a reviewable delivery against the official ports tree. Do not use for ordinary Git-only edits, synchronization alone, or committing to official CVS. A local Git commit does not submit a port to OpenBSD.

## Prerequisites

Read [BUILDING.md](../../../docs/BUILDING.md), inspect the target tree's CVS status and revisions, and establish whether the exact port already exists officially. A missing local directory does not prove a port is new. Verify against a matching, current official checkout or official source browser. Preserve preexisting edits before any CVS update; never remove CVS directories or overwrite their metadata. Finish [validation](../openbsd-port-validation/SKILL.md), or state the remaining limitations.

## Existing official ports: complete diff

1. Record the checkout branch/date and base revisions using `cvs status` in the port and relevant shared/registry scopes. Prefer a current checkout; reconcile with current HEAD while preserving local changes before final delivery. A normal `cvs diff` compares recorded checkout revisions, not automatically current HEAD. Do not use `-rHEAD` as a substitute for accounting for unknown files.
2. Inspect `cvs -nq update` and the source changes. If the overlay helper was used, inspect `TREE/.wip-changes/<label>.created.txt`, `.deleted.txt`, and `.created-dirs.txt`; these are starting aids, not a complete CVS inventory. They cover the latest replacement only. Include modifications to shared parent files and `infrastructure/db/user.list` explicitly.
3. Account for every new directory/file and every removed tracked file. CVS normally needs new directories added parent first, then `cvs add path/to/file` for new files and `cvs remove path/to/missing-file` for removed tracked files. Review each path before acting. **CVS directory addition can create directories in the remote repository immediately**; do not run it without explicit authorization and repository access. Do not use `cvs remove -f` to erase existing work or commit anything as part of artifact preparation.
4. If CVS registration is available and authorized, generate the final diff from the ports root, naming all affected scopes:

   ```sh
   cvs diff -uN category/port > /tmp/port.diff
   ```

   Add shared parent files and account-registry paths to the arguments when relevant. `-N` includes files scheduled for addition/removal; unknown files are still omitted. Diff exit status 1 means differences were found; distinguish that from command errors and inspect stderr.
5. If anonymous CVS or new directories prevent complete registration, use a disposable export/staging area to append explicitly labeled unified diffs for new files against `/dev/null`, and removed files against their recorded baseline. Native `diff -u` supports labels, for example:

   ```sh
   diff -u -L /dev/null -L category/port/files/new.conf \
       /dev/null /tmp/submission/category/port/files/new.conf
   ```

   Exclude duplicate hunks for files already represented by CVS. Document that the artifact combines CVS output with labeled additions/removals and identify its baseline. Do not claim a plain CVS diff captured unknown files. Preserve executable modes and directory requirements in accompanying notes; unified diffs do not encode all metadata.
6. Review the artifact itself, including all added/deleted paths, checksums, generated manifests, patches, package data, shared files, and registry entries. Run the patch style checker for every changed patch. Test applying it with `patch -C -p0` from a disposable copy of the matching baseline when its paths are relative to the ports root. Inspect labels first and select the correct strip level; perform an actual disposable application if the native check cannot cover the artifact completely. Never test application over user changes.

## New official port: source archive

Stage only the new port sources under `category/port`, retaining the layout expected when unpacked at a ports-tree root. For nested ports, include the necessary shared parent `Makefile`/`Makefile.inc` and selected children, without copying unrelated siblings. If the parent's recursion Makefile lists absent siblings, explain the intended existing-tree context or prepare a consistent new-group submission. Do not silently change the repository to make the archive self-contained.

Create and inspect the archive from the staging root:

```sh
tar -czf /tmp/new-port.tar.gz category/port
tar -tzf /tmp/new-port.tar.gz
```

For a nested group, name each required shared file and child path explicitly in the `tar` command. Exclude CVS/.git metadata, work/build products, downloaded archives, packages, logs, and backups **from staging**, without deleting any metadata from the actual tree. Supply required official account-registry changes as a separate baseline-specific diff; do not bundle the complete repository `user.list`. Unpack into a disposable tree and verify layout and source completeness.

## Acceptance and diagnosis

Deliver the artifact location, official baseline, affected paths, exact validation performed, and known failures. Accept only when added, removed, and modified sources are all represented and shared dependencies/layout survive extraction or patch application. Publishing, sending mail, and CVS commits need their own authorization.

Missing new files usually mean they were untracked and omitted by CVS; compare the staged inventory with status and the artifact. Rejected hunks usually indicate a wrong baseline, strip level, or stale patch: reproduce against the recorded revision rather than forcing application. Review CVS conflicts before producing a final artifact. Neither Git diffs nor the helper's change lists alone establish a complete official submission.

References: [OpenBSD porting guide](https://www.openbsd.org/faq/ports/guide.html), [cvs(1)](https://man.openbsd.org/cvs.1), [diff(1)](https://man.openbsd.org/diff.1), [patch(1)](https://man.openbsd.org/patch.1), and [openbsd-ports-sync](../openbsd-ports-sync/SKILL.md).

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
