VeraCrypt 1.26.29: OpenBSD amd64 validation

NOTES FOR DRAFTING THE VERACRYPT UPDATE PROPOSAL
Date: October 14, 2026

GOAL AND STATUS

Propose updating security/veracrypt from 1.25.9p1 (CVS base of the local
tree) to 1.26.29, with support for privilege elevation via doas and FFS
creation on OpenBSD. The update is compiled, packaged and installed on
OpenBSD 8.0 amd64. The changes are synchronized with
/root/wip-openbsd-ports/security/veracrypt. No commit has been made, no
mail has been sent, and the change has not been integrated into the
official CVS.

There is a single existing port. There are no new ports to deliver as a
tar.gz. The new files of this port are included in the diff as additions
from /dev/null, even though they are not yet registered in CVS. The diff
does not contain diagnostic lines starting with '? '. Names use a single
hyphen.

SOURCES AND DEPENDENCIES

Source used:
https://launchpad.net/veracrypt/trunk/1.26.29/+download/VeraCrypt_1.26.29_Source.tar.bz2

Specific version proposed: 1.26.29. Do not claim it is the latest
version when sending the mail without checking again. distinfo and PLIST
were regenerated. The port maintainer was not changed.

Dependencies installed with pkg_add:
- wxWidgets-gtk3 3.2.12 and its transitive graphics libraries.
- pcsc-lite 2.5.0.
- yasm 1.3.0p1.
- desktop-file-utils 0.28p0.
- gmake 4.4.1p0 and the prerequisites available on the system.

security/sudo was removed from RUN_DEPENDS: doas is part of the base
system. pcsc-lite was added for the headers and the token support of the
new version. No smartcard services were started and no devices were
tested. The coreutils dependency was removed. The reproducible-date
helper was adapted to the base system's awk. The build keeps using C++14
and the system's wxWidgets/FUSE libraries.

PORT CHANGES

1. General update
- Version 1.26.29; the previous version's revision disappears.
- Makefile patches updated, without the -O2 optimization imposed by
  upstream; CFLAGS/CXXFLAGS from the ports framework are injected and
  LFLAGS is preserved.
- TC_STR_RELEASE_DATE is corrected to June 9, 2026 to match the numeric
  fields of the source. The source_date_epoch helper checks that equality.
- Explicit continuations are added to the month ternary expression in the
  source_date_epoch.sh helper so it works with OpenBSD's awk.
- The desktop launcher uses TRUEPREFIX/bin/veracrypt.
- The installed icon changes from XPM to PNG, matching the new source.
- pkg/README is added with doas configuration and FFS usage.
- The patch that removed vnconfig -c is dropped: upstream already
  includes it.
- NO_TEST is removed and do-test is implemented via
  veracrypt --text --test.
- No patch includes an SPDX-License-Identifier.

2. Elevation via doas
- On OpenBSD the service uses doas instead of sudo.
- The inherited preflight 'sudo/doas -n true' is removed for OpenBSD. A
  rule restricted to veracrypt --core-service does not have to allow
  true.
- The real service is first attempted for elevation with doas -n. If a
  password is needed, the interface prompts for the password of the
  account running VeraCrypt.
- For authentication, a private pseudoterminal is created and set as the
  controlling terminal. The protocol's stdin/stdout channels are
  preserved.
- The slave is kept on stderr during doas: doas calls closefrom(3)
  before authenticating, and closing the slave's last descriptor would
  lose /dev/tty.
- Echo is disabled and the readpassphrase prompt is awaited before
  sending a single response. No fixed delay is used for synchronization.
- Terminal messages and the service's serialized exceptions are
  distinguished. The password does not pass through argv or the
  environment and is wiped from temporary buffers.
- After authenticating, the elevated worker detaches from the terminal
  session before releasing stderr; this prevents the terminal release
  from terminating it.
- Authentication failure returns control to the frontend to retry,
  without leaving doas waiting for another response on a private
  terminal.
- OpenBSD elevation errors reference doas and doas.conf.

Rule recommended in the README (normal execution as a user):
    permit :wheel cmd /usr/local/bin/veracrypt args --core-service

The rule authorizes VeraCrypt's privileged service. There is no need to
permit true or to elevate the normal CLI invocation. The nopass variant
was tested only as a temporary test-bench rule; it is not left
installed.

3. FFS
- FFS is added to the filesystem enum, as a native type on OpenBSD, to
  the --filesystem parser and to the CLI/GUI selectors.
- Non-interactive creation still chooses FAT by default. FFS is
  explicitly requested with --filesystem=FFS.
- A specific serialized request is added to the privileged service to
  run /sbin/newfs on the raw device corresponding to the volume.
- The service validates /dev/vnd[0-3]c and that it corresponds to a
  VeraCrypt volume with no mounted filesystem before converting it to
  /dev/rvndNc. No generic command-execution interface is added, and
  arbitrary disks are not accepted.
- CLI and GUI use the same formatting request. Ownership of the device
  is not temporarily handed to the user: that is not enough for newfs's
  ioctls.

FAILURES DETECTED AND FIXED DURING VALIDATION

The initial WIP compiled, but the doas true check prevented using a rule
limited to the service. The first FFS test as a normal user failed with
'newfs: ioctl (GDINFO): Operation not permitted': formatting had to
happen in the elevated service, not just by changing the owner of the raw
device. The first password test failed with 'doas: a tty is required':
the slave had to be kept on a descriptor that survived doas's closefrom.
These cases were fixed and repeated successfully on the final binary.

VALIDATION THE MAIL CAN CITE

- Compilation, checksum and shared-library check: correct.
- Self-tests of all algorithms: correct, also as a normal user.
- doas denied, restricted nopass, password authentication and retry
  after an incorrect password: expected behavior.
- FFS: create, mount, write/read as a user, unmount and remount with
  identical SHA256. fsck_ffs -fn with no errors.
- FAT batch still works without elevation for creation and mounts as
  msdos.
- Temporary account removed, doas.conf restored and all vnd free.

Do not turn this into a claim of support proven on all architectures or
of the GUI. Physical disks, hidden volumes and smartcards were not
tested. There is no numeric count of cryptographic tests: upstream
reports 'Self-tests of all algorithms passed'. There are compilation
warnings and the expected --quick warning, which was used only on test
images.

DELIVERY AND EVIDENCE

/root/veracrypt-results/por-port/diffs/security-veracrypt.diff
/root/veracrypt-results/por-port/RESULTADOS-PRUEBAS.txt
/root/veracrypt-results/por-port/CAMBIOS-PARA-PROPUESTA.txt
/root/veracrypt-results/por-port/SHA256

Package ready to install/test:
/usr/packages/amd64/all/veracrypt-1.26.29.tgz
Its size and SHA256 are recorded in
/root/veracrypt-results/package.json.

Logs and JSON evidence in /root/veracrypt-results:
- logs/build-doas-tty-final.log, package-tty-final.log,
  install-tty-final.log.
- logs/crypto-selftest-final.log and crypto-selftest-unprivileged.log.
- logs/ffs-*.log, ffs-payload.sha256 and fat-*.log.
- logs/doas-password-auth.log and doas-password-retry-auth.log.
- logs/doas-evidence.log, checks-final.log and patch-clean.log.
- cli-results.json, doas-password-result.json,
  doas-password-retry-result.json, extra-cli-results.json.
- test-account-cleanup.json and logs/vnd-final.log.

The diff has been checked with git apply --numstat and the patches were
applied to a clean extraction. Do not confuse it with a commit or with an
application test on an independent CVS checkout.

GUIDANCE FOR DRAFTING

Present an update proposal to 1.26.29 that adds the described doas/FFS
integration, with CLI validation on OpenBSD 8.0 amd64. Emphasize that
tests as a normal user uncovered failures that did not appear as root.
Request review of the elevation changes and testing on other
architectures. Do not invent a recipient, signature, public attachment
URL, GUI results or acceptance of the change. Do not send the mail
without an explicit instruction.

VERACRYPT VALIDATION RESULTS
OpenBSD 8.0 amd64, October 14, 2026
Installed version: VeraCrypt 1.26.29

BUILD AND PACKAGE
- Port build with clang/C++14 and wxWidgets: correct.
- distinfo and PLIST generated from the sources and the real fake.
- make checksum and make port-lib-depends-check: correct.
- Package veracrypt-1.26.29.tgz generated and installed.
- All patches apply to a clean extraction. The patched sources match
  those used to build the binary (except for the later TRUEPREFIX
  substitution in the desktop launcher).

CRYPTOGRAPHIC TESTS
- Port do-test target: Self-tests of all algorithms passed.
- Installed binary run as a temporary unprivileged user: Self-tests of
  all algorithms passed.
- veracrypt --text --version: VeraCrypt 1.26.29.

DOAS
- Temporary account vctest, uid 1001, no wheel membership.
- Denial rule: the privileged operation fails with exit 1, as expected;
  no vnd is configured and no mount remains.
- nopass rule limited to /usr/local/bin/veracrypt args --core-service:
  FFS creation, mounting, listing and unmounting without an interactive
  terminal: OK.
- The same rule without nopass: FFS mount from the CLI with a single
  prompt for the account password: OK.
- Incorrect password followed by the correct one: two prompts, expected
  authentication error and recovery without a lockout; final mount: OK.
- The doas log confirms that vctest ran --core-service as root.
- The administrator password is transmitted over a private terminal; it
  is not passed as a program argument or as an environment variable.

FFS
- Normal file container, 64 MiB, AES, SHA-512 and PIM 0.
- Creation with --filesystem=FFS as an unprivileged user: OK.
- newfs run as root on /dev/rvndNc via the elevated service.
- Explicit mount with --filesystem=ffs: ffs type confirmed by mount.
- Write and read of a 1,048,621-byte payload as a normal user.
- Unmount and automatic remount without specifying the type: OK.
- Payload SHA256 hash identical after remounting.
- Subsequent mount with doas authentication and a custom mount point:
  data intact.
- Opening without mounting a filesystem and fsck_ffs -fn: exit 0; clean
  filesystem, phases 1 to 5 completed without repairs.

FAT REGRESSION
- Non-interactive creation without --filesystem, with doas denied: OK.
- Subsequent automatic mount: msdos type confirmed.
- Unmount: OK. FAT is preserved as the default for batch creation.

CLEANUP
- All test volumes unmounted; vnd0, vnd1, vnd2 and vnd3 free.
- Temporary account and its directory with the images removed.
- /etc/doas.conf restored exactly to its original bytes.
- No persistent temporary credentials in the delivery files.

SCOPE
Normal file containers and the CLI were tested on amd64. The GUI
compiles and shares the formatting path, but its dialogs were not
tested. Other architectures, physical devices, hidden volumes,
smartcards, doas authentication other than password, and FFS
compatibility with other operating systems were not tested. The tests
are not equivalent to a complete audit of the privileged protocol or of
cryptography.

There are upstream compilation warnings and the expected --quick warning
on the disposable containers. The denial test and the first incorrect
password are intentional negative cases, not pending failures. The
historical logs of the fixed failures are kept for diagnostics; the
results above correspond to the final binary.
