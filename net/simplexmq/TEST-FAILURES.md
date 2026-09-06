# SimpleXMQ v7.0.1 test investigation

Native status: REQUIRES_OPENBSD_TESTING. The only completed OpenBSD run
available for this investigation remains:

```text
810 examples, 9 failures, 38 pending
Finished in 2809.7839 seconds
Randomized with seed 346723068
```

Source log: ../simplexmq-build-test.log, SHA256
d0665234dff974f0e2579c29be905e5c076337ea45da2cb15ab33caaa55999be.
It is preserved unchanged. It contains one run, not repeated executions of
the same examples. Passing neighboring variants are not repeat successes.
No individual elapsed times, SQLite extended result codes, packet capture,
native filesystem information or native resource-limit samples were logged.
Line numbers below refer to the source used by that run, before these edits.

## Failure map

F is the common prefix
SMP client agent, server memory message store / Functional API.
Exception summaries are from the final failure section, log lines 10415-10509.

| # | Exact group / example below the indicated prefix | Source and exception | Deadline / endpoints |
|---|---|---|---|
| 1 | Core tests / RSLV functional API tests / RSLV forwarded (PFWD) / PFWD-wrapped RSLV success returns RNAME (record JSON frames over the proxy) | tests/RSLVTests.hs:82:5; IOException, user error (PCENetworkError NETimeoutError) | Setup stage unlabelled in original helper. Interactive connect 15s, command 10s, proxy PRXY 25s; internal background connect 45s; resolver HTTP 1s. localhost:5001 -> 127.0.0.1:5002 -> ephemeral HTTP listener. |
| 2 | F / Duplex connection - delivery stress test / two way concurrently (50) / current | FunctionalAPITests.hs:337:67, throw at 831:24; ErrorCall timeout (0,0,18,18) | 30s inactivity per receive; outer 300s watchdog; localhost:5001. |
| 3 | F / Duplex connection - delivery stress test / two way concurrently (50) / prev | Same source; ErrorCall timeout (0,0,3,3) | Same. |
| 4 | F / Establishing connection asynchronously / should connect on the second attempt if server was offline | FunctionalAPITests.hs:364:7; expected Right (), got BROKER localhost:5001 NETWORK NEConnectError; socket 16 ECONNREFUSED | Assertion, not timeout. Listener readiness already synchronized; Bob's failed-connection cache lasts 1s, fixture sleeps only 250ms. |
| 5 | F / Establishing connections with user retries / Via contact / should connect after errors | FunctionalAPITests.hs:372:42; ##> at 1353:12, shouldRespond at 150:13; operation timed out | 10s, waiting for Alice INFO after UP; localhost:5001 and 127.0.0.1:5002. |
| 6 | F / Short connection links / should connect via 1-time short link / 2 servers, directly | FunctionalAPITests.hs:375:74, runRight at 263:15 and 1393:5; INTERNAL SEInternal SQLite3 ErrorIO while performing step: disk I/O error | No database path in exception; fixture uses tests/tmp/smp-agent.test.protocol.db and smp-agent2.test.protocol.db. |
| 7 | F / Short connection links / should connect via 1-time short link / 2 servers, via proxy | FunctionalAPITests.hs:375:55; uncaught SQLError ErrorIO, disk I/O error | Same reused paths; third-agent fixture uses smp-agent3.test.protocol.db where needed. |
| 8 | F / Async agent commands / should get short link data and join connection using async agent commands | FunctionalAPITests.hs:2773:32; BROKER localhost:5001 NETWORK NETLSError, Terminated False, record exceeding maximum size, Error_Protocol RecordOverflow | TLS 2.4.3; no Warp/HTTP listener on this path. |
| 9 | F / Async agent commands / delete connection waiting for delivery / should delete connection by timeout even if message wasn't delivered | FunctionalAPITests.hs:2998:3, noMessages at 3030:18/1047:21; unexpected ("","Yxtb1duQTByhKqkz",SENT 4 Nothing) | Deletion deadline 1s; cleanup interval 10ms; quiet check only 50ms; server :5001 restarted after DEL_CONNS. |

Immediate run context:

- 1: forwarded 404 succeeds immediately before; direct RNAME succeeds after.
  RSLV means resolving a public SimpleX name, not DNS resolution itself.
- 2/3: proxy variants pass before and mixed-version variants pass after.
  Tuple fields are remaining SENT, MSG, RCVD and ACK-command OK counts:
  all ordinary messages and SENT events had arrived; receipts were blocked.
- 4: preceding output says Processed 1 and 0 log lines. The following
  restore-confirmation example passes.
- 5: preceding output includes retrying accept confirm twice and Processed
  2/0 log lines. A subsequent :5002/socket 18 refusal is logged; the
  restarted-client variant passes.
- 6/7 follow 5's failure; subsequent asynchronous short-link variants pass.
  At 23:08:55 agent runNtfSupervisor, logServersStats and cleanupManager
  threads report blocked indefinitely in STM. This supports leaked agents,
  not a measured filesystem fault.
- 8: the previous async set-short-link example passes; TLS failure is also
  logged immediately before the failed assertion. Following async restoration
  passes, with socket 17 ECONNREFUSED logged.
- 9: the AUTH-deletion example before and in-flight-delivery example after
  both pass. The latter explicitly permits one in-flight SENT after deletion.

## Root causes, fixes and confidence

### 1. Forwarded RSLV

Category: resource ownership / possible TLS contamination. Both
testRslvVersion and forwardedResolveAlice acquired protocol clients without
closing them. Add brackets and closeProtocolClient on every exit. Add
distinct proxy-connection and proxy-relay-session failure labels; the old
exception alone does not distinguish these stages.

Files: patches/patch-tests_RSLVTests_hs and shared transport/lifecycle
patches listed below. Confidence: high for the leaks, medium/low that they
explain this particular timeout. The TLS fix can also affect this path.
The baseline example passed individually on Linux in 0.5978s.
Do not enlarge any RSLV deadline.

If native failure remains, repeat the entire RSLV group, then its exact
PFWD example, and use the new stage label to distinguish initial :5001 TLS,
PRXY to :5002 and the final HTTP resolver request. Trace listener ownership
and TLS exceptions at that stage before changing resolution options.

### 2-3. Concurrent delivery

Category: test-infrastructure backpressure / premature consumer termination.
Reproduced on Linux with two RTS capabilities after the initial lifecycle
fixes: current failed with remaining (0,0,2,2). Diagnostics showed Alice's
queues empty while Bob's subQ was full (4/4), msgQ nonempty, and its delivery
worker still active. No worker restart or transport queue backlog was seen.

Each test receiver used to stop after its own counters completed and a
100ms drain. The other receiver can still need receipt delivery. QCONT
notifications then fill the departed receiver's small event queue, blocking
the agent work needed by its peer. QUOTA warnings also occupy the queue;
the first barrier experiment exposed MWARN QUOTA after completion in four
variants. A larger timeout does not empty that queue.

Fix: shared STM completion count. Each completed receiver continues consuming
QCONT and the events already filtered by pGet until BOTH receivers finish.
The original filter is shared, not broadened. Queue reads take precedence
over the completion branch, so extra data events still fail assertions. Keep all expected
message/receipt/OK counts, concurrency, quotas and the 30s deadline. Retain
the previous port's 25-per-peer workload rather than changing it again.

File: patches/patch-tests_AgentTests_FunctionalAPITests_hs.
Confidence: high for the reproduced current failure; same path and signatures
make it a strong explanation for prev, pending native repetitions.
Failure-only worker/queue snapshots remain useful and do not consume events.
Also correct an existing diagnostic that printed the receipt counter instead
of the unexpected event.

### 4. Reconnect refusal

Category: fixture timing versus the negative connection cache, not evidence
of an unready listening socket. The server helper signals only after listen.
Bob can reuse the cached offline failure for 1s; Alice UP and the 250ms sleep
do not establish that Bob's cache expired.

Fix only Bob's fixture configuration: persistErrorInterval = 0, remove the
sleep. The test still makes one failed offline join and one online join;
no blanket retry and no production-cache change.
File: patches/patch-tests_AgentTests_FunctionalAPITests_hs.
Baseline Linux: passed in 3.1984s. Confidence: high source-level race,
native causal verification still required. On any further refusal, distinguish
a fresh connect exception from the cached value and capture bind/listen errors.

### 5-7. Retry failure and following SQLite failures

Category: confirmed fixture lifetime bug; likely suite-order contamination.
Both user-retry test families disposed raw agents only on success. An
assertion failure could leave initial/replacement agents and SQLite stores
alive while Test.hs recursively removed tests/tmp and later tests reused it.

Fix: withAgentSessions owns every initial and restarted agent and cleans
them in reverse acquisition order even after failure. Already closed stores
are skipped. Failed agent acquisition also closes the just-opened store.
Additionally fix withStore2 in SQLiteTests: close the second handle before
the first handle's helper removes the database.

Files: patches/patch-tests_AgentTests_FunctionalAPITests_hs and
patches/patch-tests_AgentTests_SQLiteTests_hs.
No journal/durability setting is disabled. Inspected pragmas include
auto_vacuum FULL, secure_delete ON, foreign_keys ON and busy_timeout 100;
there is no WAL-mode configuration in these fixtures.

Reduced Linux SQLite experiment: in 100/100 trials, reusing a removed
database/journal pathname while an old writing connection remains open lets
the old rollback delete the new connection's journal. New commit fails with
SQLITE_IOERR_DELETE_NOENT (5898), disk I/O error. Closing before removing and
reopening succeeds in 100/100 controls. This proves the mechanism, not the
unlogged extended code of the OpenBSD failures.

Baseline Linux retry variants: 4/4 pass; short-link variants: 4/4 pass.
Confidence: high ownership bug, medium attribution of 6/7; the original
missing INFO in 5 is not independently proved fixed.
Next native experiment: run Via contact immediately followed by Short
connection links in the same process; after an injected assertion failure,
check live agent threads/open database descriptors before allowing directory
cleanup. Capture SQLCipher extended result codes if ErrorIO remains.

### 8. TLS record framing

Category: upstream TLS bug, independently reproduced; not a TLS size-limit
problem and no evidence that a plaintext or stale listener is necessary.

TLS 2.4.3 probes for a client-authentication alert using
timeout rtt (recvData13 ctx). This can discard an already consumed record
header/partial body and still return successfully from handshake. The next
read decodes ciphertext as a header. Even an empty requested client
certificate takes this code path.

Backport upstream commit
[218abdd67a4cde30854b5ca9b146b269da53bc07](https://github.com/haskell-tls/hs-tls/commit/218abdd67a4cde30854b5ca9b146b269da53bc07),
which explicitly describes SimpleX and fixes this race. Retain the result
and exception of a single locked reader; the caller's timeout stops waiting
without cancelling the record read. bye uses the same read lock without
blocking behind another reader. Certificate validation, authentication alerts,
record limits and TLS versions remain intact.

The backport needs one additional qualified Control.Exception import against
2.4.3. It is split into five per-file patches, including upstream regression
tests, under files/patch-tls_*. Both ports apply identical patches after LF
normalization. tls stays pinned to 2.4.3; no new distfile/dependency is needed.

Linux evidence: five unfixed delayed-record runs failed (four RecordOverflow,
one bounded read timeout), with successful server authentication in all cases;
with the backport, five runs recovered all 4096 original payload bytes.
The upstream keeps-record-alignment regression test passes (1 example,
0 failures). Confidence: high for the library defect and fix; native
SimpleX TLS/certificate regression testing is still required.

### 9. SENT after deletion

Category: unresolved test/production event-order contract, not safely fixed
by accepting the event. Deletion can remove DB rows while a delivery worker
already holds PendingMsgData and retries it in memory. The following
testWaitDeliveryTimeout2 explicitly expects that first in-flight message to
deliver after DEL_CONNS. Cancelling every in-flight delivery would break
that documented neighboring expectation.

No assertion or production deletion behavior is changed. Baseline isolated
Linux test passes in 6.8873s; its 50ms quiet interval does not prove permanent
silence. Confidence: high that the test lacks a queued-versus-in-flight
barrier; actual native ordering remains unobserved.

Next experiment: record worker dequeue, DEL_CONNS and retry-attempt timestamps
for message 4, using a controllable delivery gate in this test. Establish
whether the intended example is queued-only or in-flight before changing
its expectation. Test both deletion examples together under N1/N2. Never
silently drain or accept the unexpected SENT.

## Shared lifecycle patch audit

Retained: finite wrong-certificate tests, full server shutdown waits,
protocol-client/store cleanup, unprivileged test ports, selected existing
watchdogs, network 3.2.9.0, Warp compatibility and sqlite3 TEST_DEPENDS.
No failures are newly disabled, retried wholesale or marked pending.

Corrected:

- forkFinally called inside mask_ inherited MaskedInterruptible for worker
  bodies. forkFinallyUnmasked masks publication/finalizers but explicitly
  unmasks the worker. Reconnect async workers use asyncWithUnmask.
- An accepted connection set closed before gracefulClose finished. A parent
  racing registration could skip this still-closing worker. Publish closed,
  registry removal and completion together, including exceptional close.
- UnliftIO.Exception.bracket makes finalizers uninterruptible. An inner mask_
  cannot restore interruptibility. Use base Control.Exception.bracket for
  transport and fixture cleanup so TLS's own shutdown deadlines can fire.
- The fixture's 60s shutdown watchdog now includes killThread as well as the
  completion wait; killThread itself waits for exception delivery.

Shared files (patches/ in simplexmq, files/ in simplex-chat):
patch-src_Simplex_Messaging_Agent_hs,
patch-src_Simplex_Messaging_Agent_Client_hs,
patch-src_Simplex_Messaging_Client_hs,
patch-src_Simplex_Messaging_Client_Agent_hs,
patch-src_Simplex_Messaging_Transport_Client_hs,
patch-src_Simplex_Messaging_Transport_Server_hs,
patch-src_Simplex_Messaging_Util_hs.
The last is new; simplex-chat adds it to SIMPLEXMQ_PATCHES.
Test-fixture correction: patches/patch-tests_SMPClient_hs.
Two bounded lifecycle regression examples:
patches/patch-tests_CoreTests_UtilTests_hs.

Reduced mechanism tests reproduced inherited masking and premature
deregistration and verified corrected behavior in 100 repetitions each
under N1 and N2; cancellation/completion also passed. These are not proof
of an OpenBSD package build. Adding two examples changes the candidate
SimpleXMQ suite size from 810 to 812.

## Additional full-suite finding: suspended-agent shutdown

The first final Linux full run stopped making progress at `Suspending agent /
should complete sending messages when agent is suspended`. Its 300s example
watchdog could not complete cleanup. The original port-patched baseline also
failed to finish this example alone within 45s; the current candidate failed
within 35s. A temporary trace printed `DEBUG final stats begin` but never the
matching end marker. No live service sockets remained (15 total descriptors);
gdb attachment was denied by the host, and that restriction was not changed.

Root cause: the main agent's finalizer calls saveServersStats through withStore',
which waits on the AODatabase suspension gate. During disposal the agent is
being joined and no subsequent foreground event can release that gate. The
UnliftIO finalizer is uninterruptible, defeating the outer test timeout.
This is an upstream shutdown/suspension interaction exposed by complete joins,
not evidence that OpenBSD is merely slower.

Fix: the final shutdown save retains withTransaction's actual database lock,
while bypassing only the foreground-operation gate. Normal periodic statistics
saves still use withStore'. Shutdown errors are logged rather than sent into
an event queue whose consumer has already stopped. The database stays open
until the joined finalizer completes. No user transaction, suspension assertion
or concurrency is disabled. Shared patch-src_Simplex_Messaging_Agent_hs is
updated in both ports. Temporary DEBUG statements were removed.

After this change, the entire three-example suspension group passed in
8.7289s under N1. Repeated N1/N2 and full-suite outcomes are recorded below.
The original full attempt was deliberately terminated, not counted as a pass.

## Dependency and portability checks

### Additional batch-subscription fixture deadlock

A subsequent full Linux attempt stopped at `Batching SMP commands / should
subscribe to multiple (6) subscriptions with batching`; it was terminated,
not counted as a completed run. The isolated example passed once in 7.6114s,
then hung again in repetitions. A clean diagnostic repetition also exceeded
70s under N1. Traces showed both agents acquired, both listeners ready and
both servers stopped; no agent disposal had begun. This was not evidence of
a slow startup or an agent-finalizer deadlock.

The test unconditionally read two DOWN events and later two UP events.
However, Agent/Client.hs:serverDown and subscription success intentionally
omit events with no connection IDs. After deleting three of six randomly
distributed connections, all remaining subscriptions can use one server.
The blocked run's databases proved this: Alice had three live receive queues
at localhost:5001, Bob three at 127.0.0.1:5002, with no other live queues.
Each agent therefore emits only one DOWN. Waiting for a second can never
finish. Upstream also has the six-subscription variant, normally pending;
the existing port patch enabled it instead of the expensive 200 variant.

Fix in patch-tests_AgentTests_FunctionalAPITests_hs: accumulate the exact
expected subscription IDs across UP/DOWN events, under the existing 10s
shouldRespond bound. Reject empty events, duplicate IDs and IDs outside the
remaining expected set. Do not change server selection, connection counts,
deletion semantics, assertions about identifiers, or pending-test count.
Confidence: high for this independently reproduced fixture error.

After correction, 20 isolated executions passed (ten each under N1 and N2,
seed 346723068, approximately seven seconds each). Server selection still
uses its own upstream random generator; the HSpec seed does not fix that
distribution. Group and full-suite results are recorded below.

An earlier baseline attempt immediately after an externally killed test
found extra connection IDs. That attempt used the aborted test's database
and is explicitly not clean regression evidence. Aborted state was isolated
before the clean reproduction. Temporary DEBUG tracing was removed.

### Additional HTTP/2 compatibility and local-fixture findings

The first completed Linux full run after the suspension fix finished with
812 examples, 17 failures, 38 pending in 1266.5445s (seed 346723068).
All nine original native failures passed in that run. Sixteen failures were
XFTP SIZE errors or downstream consequences; the other was XRCP multicast.
This was not a passing full suite and was not an OpenBSD run.

The baseline binary independently reproduced the one-client XFTP SIZE error
in 0.8044s. The http2 5.4.4 compatibility patch used H.run, whose
Network/HTTP2/Client/Run.hs callback calls adjustRxWindow on return.
Network/HTTP2/H2/Window.hs implements that operation by draining queued DATA.
SimpleX returns HTTP2Response with a deferred body reader to another thread;
the callback can return before that thread consumes the file. This discards
real file bytes, not padding, and explains the timing-dependent SIZE errors.

Correction: use http2's exposed Client.Internal.runIO stream-ownership API.
Normal getResponseBodyChunk reads still provide flow-control updates;
connection teardown still closes streams. SimpleX does not use the optional
Aux ping/stream helpers. No integrity assertion, HTTP/TLS limit or authentication
check is disabled. The same per-file HTTP2_Client patch is applied in both
ports. Sources are identical at this file in both selected SimpleX revisions.
Error/cancellation and repeated large transfers still need native stress
testing, especially when consumers abandon bodies before reading to EOF.

The one-client test then passed once and in five N2 repetitions. The XFTP
group completed with 69 examples, 2 failures, 2 pending in 185.6177s; remaining failures
were CLI deletion after transient upload timeouts and send-resume cleanup.
The latter is a separate fixture race: SFDONE is emitted before removing
the encrypted source. The test disposed its sender immediately on SFDONE,
cancelling that cleanup, then slept 500ms after disposal. Keep the agent
alive while a bounded condition wait observes directory removal. The wait
uses the existing 10s shouldRespond watchdog, not an unconditional longer
sleep. Production event ordering is unchanged. Three N2 repetitions passed.
File: patches/patch-tests_XFTPAgent_hs (prior certificate/version fixes retained).

The CLI deletion example passed individually under N1 in 31.3627s and in
three N2 repetitions with temporary phase diagnostics. A transient failure
can occur during upload, before deletion, rather than on a deleted-file read.
Those diagnostics were removed. Do not mislabel this as a fixed deletion bug;
if it recurs, trace per-stream upload/window progress on :8000/:8001 and the
server receiveFile timeout. Random chunk-to-server assignment is separate
from the HSpec seed. Existing production retry behavior was not enlarged.

XRCP baseline multicast also failed independently. A minimal UDP probe with
IP_MULTICAST_LOOP=1 received its datagram on 127.0.0.1 but timed out using
the builder's 192.168.1.5 LAN interface. No firewall/system setting was changed.
The two-peer local test now explicitly prefers loopback for its multicast
invitation, using the existing address preference API. It still sends and
receives real encrypted multicast invitations and performs authenticated TLS
pairing. Production LAN/interface selection is untouched. It passed alone
in 1.4285s and three N2 repetitions. File: patches/patch-tests_RemoteControl_hs.
Cross-machine discovery and OpenBSD loopback multicast remain native tests.
The logged duplicate default-interface membership (EADDRINUSE) is not the
cause: other memberships succeed and the corrected local test still passes.

- Exact upstream v7.0.1 archive and all port patches inspected; package
  version remains 7.0.1.0. Source SHA256:
  428690b17376158d80350148ae49b826acbd609dcfff934609993652dfa711d7.
- Shared production changes also apply to simplex-chat's embedded
  simplexmq efaad8e73436d60f5052f07dda6b71151ad5039b. No unrelated chat
  watchdog, dependency or GUI changes.
- network 3.2.9.0's changelog only adds recvBufNoWait. Recent earlier
  versions fixed asynchronous getAddrInfo cleanup and gracefulClose.
  close invalidates its stored descriptor; ordinary double close is not
  evidence for closing a reused numeric fd. No proven network regression
  and no downgrade. The relevant connect hints do not use AI_ADDRCONFIG.
- OpenBSD's existing IPv4 listener selection is retained. :5001/:5002 are
  shared sequential fixtures, not concurrently randomized port allocations.
  RSLV's HTTP mock binds an OS-assigned port and passes it to the resolver.
  Do not run separate SimpleX test processes against the same fixed ports.
- RSLV uses the pinned Warp HTTP mock; the refreshed HTTP2 configuration and
  FileInfoCache compatibility patches do not change SMP TLS framing or
  listener ownership. Failure 8 does not transitively use that HTTP endpoint.
- dos2unix remains BUILD_DEPENDS. post-patch normalizes extracted dependency
  Haskell/Cabal/SQL/C/header files before their patches. Cryptostore must use
  the manifest's Cabal revision 1; archive revision 0 is not equivalent.
- Native sqlcipher remains LIB_DEPENDS, sqlite3 remains TEST_DEPENDS;
  neither test-only tools nor new debugging libraries enter RUN_DEPENDS.
  Distinfo, dependency manifests and WANTLIB are unchanged.
- Both do-test environments now set TMPDIR to a private WRKDIR/test-tmp.
  Inspection found XFTP diagnostic receive files and default-work-path receive
  directories left in global /tmp; these are now contained by make clean.
  This is test-environment hygiene, not a claim to have fixed every upstream
  temporary-file lifetime. In particular runXFTPServerTest's withTestChunk
  brackets its upload source, but does not unlink the separately allocated
  rcvPath. It does not explain the short-link SQLite failures.

Linux environment: Fedora Atomic, GHC 9.14.1, Cabal 3.18.1; native log used
GHC 9.10.3. Tests use threaded RTS, default N1; also checked N2.
The Linux experiment used bundled direct-sqlcipher and standalone zstd with
available LibreSSL, not the OpenBSD system SQLCipher build. Hackage sources
and pinned GitHub components were prepared separately; this does not
change the ports' offline build. No host deployment or system limits changed.
Linux open-file limit was 1024; native limits are unknown. Background Linux
I/O load was observed, but is not substituted for a correctness diagnosis.

## Verification results

- Baseline Linux focused run: 18 examples across the seven selectors,
  0 failures; includes all nine native failures and their matching variants.
- First corrected candidate: N1 focused checks passed. N2 exposed the
  concurrent-delivery deadlock above; it was not attributed to slowness.
- Focused N1/N2 checks: all 20 examples passed in each configuration.
  Six concurrent-delivery variants passed five N2 repetitions (30 examples).
  Suspension group passed three repetitions each under N1/N2 (18 examples).
  Original failure selectors passed again under N2 after the suspension fix.
- After the HTTP/2 and local-fixture changes, send-resume, local multicast
  and CLI deletion each passed three N2 repetitions (9 examples total).
  Final full-suite results follow after the completed run; no new OpenBSD
  run has been performed.
- All SimpleXMQ patches, shared embedded SimpleX patches and TLS patches
  apply to fresh exact sources with fuzz=0. Every repository patch is
  one-target-file and has SPDX-License-Identifier and Index metadata.

## Native rerun

Run on OpenBSD -current, not Fedora:

```sh
cd /usr/ports/net/simplexmq
make clean=all
make fetch
make checksum
make extract
make patch
make configure
make build
make test SIMPLEXMQ_TEST_OPTIONS='--seed 346723068'
make fake
make update-plist
make port-lib-depends-check
make package
make install
make deinstall
make clean
```

For individual repetitions after building, do-test intentionally bypasses
the successful test cookie:

```sh
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "two way concurrently (50)" --seed 346723068 +RTS -N2 -RTS'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "RSLV functional API tests" --seed 346723068'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "Establishing connections with user retries" --seed 346723068'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "Short connection links" --seed 346723068'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "delete connection waiting for delivery" --seed 346723068'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "XFTP" --seed 346723068 +RTS -N2 -RTS'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "XRCP" --seed 346723068'
```

Run certificate rejection/TLS groups and the full suite again after those
checks; vary N1/N2 without changing the port's default. Record ulimit -a,
fstat -p PID, ps and netstat -an before/after groups to check native leaks
and listener shutdown. Run portcheck from current infrastructure.
Build/test simplex-chat natively after the shared TLS/transport changes.

Temporary Linux sources, binaries, probes, logs and newly created Cabal
cache/store are development artifacts and are removed at the end of this
thread. The original native log and this intentional diagnostic report
are retained.

## Files changed during this investigation and requested follow-ups

The category moves and other dirty files present at the beginning were
preserved. This list compares against that initial dirty-tree snapshot,
not against HEAD. Changes outside SimpleX, sdwdate and the copy helpers
are patch-license/Index metadata only; the earlier port implementations
were not rewritten. No dependency manifest or distinfo for SimpleX changed.
The secondary repository changes are ../wip-openbsd-src/fetch-src.ksh and
../wip-openbsd-src/FETCHING.md.

```text
BUILDING.md
OPENBSD-PORTS-INITIAL-STATUS.md
devel/checkmake/patches/patch-cmd_checkmake_main_go
devel/mbake/patches/patch-mbake_cli_py
devel/mbake/patches/patch-tests_conftest_py
devel/mbake/patches/patch-tests_test__comprehensive_py
devel/mbake/patches/patch-tests_test__validate__command_py
fetch-ports.ksh
games/assaultcube/patches/patch-source_src_Makefile
games/assaultcube/patches/patch-source_src_main_cpp
games/assaultcube/patches/patch-source_src_platform_h
games/assaultcube/patches/patch-source_src_tools_cpp
graphics/ximaging/patches/patch-mf_Makefile_OpenBSD
graphics/ximaging/patches/patch-src_XImaging_ad
net/i2pd/patches/patch-contrib_i2pd_conf
net/i2pd/patches/patch-test_Makefile
net/i2pd-tools/patches/patch-Makefile
net/mullvad/patches/patch-Cargo_toml
net/mullvad/patches/patch-mullvad-cli_src_cmds_mod_rs
net/mullvad/patches/patch-mullvad-cli_src_main_rs
net/mullvad/patches/patch-mullvad-daemon_Cargo_toml
net/mullvad/patches/patch-mullvad-daemon_build_rs
net/mullvad/patches/patch-mullvad-daemon_src_cli_rs
net/mullvad/patches/patch-mullvad-daemon_src_main_rs
net/mullvad/patches/patch-mullvad-daemon_src_version_check_rs
net/mullvad/patches/patch-mullvad-management-interface_src_lib_rs
net/mullvad/patches/patch-mullvad-paths_src_cache_rs
net/mullvad/patches/patch-mullvad-paths_src_logs_rs
net/mullvad/patches/patch-mullvad-paths_src_rpc__socket_rs
net/mullvad/patches/patch-mullvad-paths_src_settings_rs
net/mullvad/patches/patch-mullvad-version_build_rs
net/mullvad/patches/patch-talpid-core_src_firewall_mod_rs
net/mullvad/patches/patch-talpid-core_src_firewall_openbsd_rs
net/mullvad/patches/patch-talpid-dns_src_lib_rs
net/mullvad/patches/patch-talpid-dns_src_openbsd_rs
net/mullvad/patches/patch-talpid-platform-metadata_src_lib_rs
net/mullvad/patches/patch-talpid-platform-metadata_src_openbsd_rs
net/mullvad/patches/patch-talpid-time_src_unix_rs
net/mullvad/patches/patch-talpid-tunnel_src_tun__provider_unix_rs
net/mullvad/patches/patch-tunnel-obfuscation_Cargo_toml
net/onionshare/patches/patch-cli_onionshare__cli_common_py
net/onionshare/patches/patch-cli_onionshare__cli_onion_py
net/onionshare/patches/patch-cli_onionshare__cli_web_chat__mode_py
net/onionshare/patches/patch-cli_onionshare__cli_web_web_py
net/onionshare/patches/patch-cli_pyproject_toml
net/onionshare/patches/patch-cli_tests_test__cli__common_py
net/onionshare/patches/patch-desktop_pyproject_toml
net/sdwdate/Makefile
net/sdwdate/distinfo
net/sdwdate/files/clock-parent.c
net/sdwdate/files/openbsd.py
net/sdwdate/files/sdwdate.8
net/sdwdate/files/test_broker.c
net/sdwdate/files/test_openbsd.py
net/sdwdate/patches/patch-usr_bin_url__to__unixtime
net/sdwdate/patches/patch-usr_lib_python3_dist-packages_sdwdate_config_py
net/sdwdate/patches/patch-usr_lib_python3_dist-packages_sdwdate_proxy__settings_py
net/sdwdate/patches/patch-usr_lib_python3_dist-packages_sdwdate_remote__times_py
net/sdwdate/patches/patch-usr_lib_python3_dist-packages_sdwdate_sdwdate_py
net/sdwdate/patches/patch-usr_lib_python3_dist-packages_sdwdate_timesanitycheck_py
net/sdwdate/patches/patch-usr_src_sdwdate_sclockadj_c
net/sdwdate/pkg/DESCR
net/sdwdate/pkg/PLIST
net/sdwdate/pkg/README
net/sdwdate/pkg/sdwdate.rc
net/simplex-chat/Makefile
net/simplex-chat/files/patch-direct-sqlcipher_cabal
net/simplex-chat/files/patch-src_Simplex_Messaging_Agent_Client_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Agent_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Client_Agent_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Client_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Transport_Client_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Transport_HTTP2_Client_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Transport_Server_hs
net/simplex-chat/files/patch-src_Simplex_Messaging_Util_hs
net/simplex-chat/files/patch-tls_Network_TLS_Context_Internal_hs
net/simplex-chat/files/patch-tls_Network_TLS_Context_hs
net/simplex-chat/files/patch-tls_Network_TLS_Core_hs
net/simplex-chat/files/patch-tls_test_HandshakeSpec_hs
net/simplex-chat/files/patch-tls_test_Run_hs
net/simplexmq/Makefile
net/simplexmq/TEST-FAILURES.md
net/simplexmq/files/patch-direct-sqlcipher_cabal
net/simplexmq/files/patch-tls_Network_TLS_Context_Internal_hs
net/simplexmq/files/patch-tls_Network_TLS_Context_hs
net/simplexmq/files/patch-tls_Network_TLS_Core_hs
net/simplexmq/files/patch-tls_test_HandshakeSpec_hs
net/simplexmq/files/patch-tls_test_Run_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Agent_Client_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Agent_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Client_Agent_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Client_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Transport_Client_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Transport_HTTP2_Client_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Transport_Server_hs
net/simplexmq/patches/patch-src_Simplex_Messaging_Util_hs
net/simplexmq/patches/patch-tests_AgentTests_FunctionalAPITests_hs
net/simplexmq/patches/patch-tests_AgentTests_SQLiteTests_hs
net/simplexmq/patches/patch-tests_CoreTests_UtilTests_hs
net/simplexmq/patches/patch-tests_RSLVTests_hs
net/simplexmq/patches/patch-tests_RemoteControl_hs
net/simplexmq/patches/patch-tests_SMPClient_hs
net/simplexmq/patches/patch-tests_XFTPAgent_hs
user.list
x11/emwm/patches/patch-mf_Makefile_OpenBSD
x11/emwm-utils/patches/patch-mf_Makefile_OpenBSD
x11/emwm-utils/patches/patch-src_common_mf
x11/emwm-utils/patches/patch-src_smconf_h
x11/emwm-utils/patches/patch-src_smmain_c
x11/emwm-utils/patches/patch-src_xmsm_1
x11/xfile/patches/patch-mf_Makefile_OpenBSD
x11/xfile/patches/patch-xfile-xdgsvc_Makefile
x11/xfile/patches/patch-xfile-xdgsvc_xfile-xdg_c
```
