# SimpleXMQ v7.0.1 test investigation

Native status: REQUIRES_OPENBSD_TESTING. The only completed OpenBSD run
available for this investigation remains:

```text
810 examples, 9 failures, 38 pending
Finished in 2809.7839 seconds
Randomized with seed 346723068
```

Completed Linux N1 run after the corrections:

```text
812 examples, 0 failures, 38 pending
Finished in 1394.7233 seconds
GHC 9.14.1, +RTS -N1, seed 346723068
```

The two additional examples exercise worker ownership/cancellation. All nine
original native failures passed in this run. This is not an OpenBSD result;
the native result above remains unchanged.

The following N2 full run completed in 1218.3336s with
812 examples, 2 failures, 38 pending. The nine original cases passed again.
The additional failures were AUTH timing (SX25519 queue / Ed448 signature,
43.15% aggregate CPU-time difference) and the two-user session-mode fixture
(expected its third DOWN at FunctionalAPITests.hs:3896). These were then
reproduced separately; the N1 pass does not erase the N2 failures.

The first completed post-reboot N2 full run finished in 1054.3086s with
812 examples, 3 failures, 38 pending. All original nine cases and the
corrected user/session-mode example passed. Additional failures were the
journal-store service-subscription metrics fixture (EOF), journal-store
Ed25519/Ed25519 AUTH SUB timing (34.8073%) and memory-store Ed448/Ed448 AUTH
SUB timing (30.4084%). These results are retained even when later isolated
repetitions pass.

After the session, metrics and AUTH corrections, the N2 full suite passed
812 examples, 0 failures, 38 pending in 1091.3430s. The following N1 full
suite completed with 812 examples, 1 failure, 38 pending in 1545.4778s:
XRCP / New controller/host pairing / should connect to new pairing reached
the 300s watchdog. All nine original failures and all session/metrics/AUTH
examples passed in both executions. Maximum AUTH differences were 13.7152%
(N2) and 20.9448% (N1). The N1 failure is not counted as a successful suite.

On September 8 the user paused testing. The subsequent full N1 run with the
XRCP fixture correction was explicitly terminated without a final result;
its queued N2 run was stopped before starting. No tests or builds were run
after that instruction. The new XRCP production changes below have only
been reviewed and checked for clean patch application, not compiled or tested.
Resume execution only after the user says "Continua". Earlier passing runs
must not be presented as verification of this final, untested source revision.

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

## Resumption after the September 7 reboot

The reboot removed the temporary source/build trees and the uncompleted
N2 diagnostic run. No result from that interrupted run is counted as a
completed repetition. The native log and its hash, the port patches and
the earlier completed results recorded above survived unchanged.

Reconstructed v7.0.1 and pinned dependencies from the port manifests,
checking archive hashes. The cryptostore revision-1 Cabal file also needs
LF normalization before its dependency patch. Rechecked 47 SimpleXMQ
patches, 25 patches against Chat's pinned embedded SimpleX revision and
five TLS patches on fresh sources with fuzz=0. The eight shared production
changes are still synchronized; all five TLS patches are byte-identical.

The remaining session-mode example is
`SMP client agent, server memory message store / Functional API / Users /
should connect two users and switch session mode`. Source inspection shows
that reconnectServerClients forks each close independently. Each
smpClientDisconnected requests DOWN for its subscriptions before resubscribing,
but that does not guarantee queue-arrival order. notifySub calls
Client.nonBlockingWriteTBQueue, which forks a writer when the queue is full.
The fixture sleeps 250ms before reading its four-slot queue, making deferred
writes particularly likely. Those writers can reorder even one connection's
DOWN and UP, in addition to interleaving independent reconnects.

Before correction, all five N2 diagnostic repetitions failed (approximately
4.8-5.3s each). In repetition 1 the last transition delivered
DOWN(c1), DOWN(c2), DOWN(c3), UP(c1), UP(c2), UP(c4), DOWN(c4),
then failed at FunctionalAPITests.hs:3901 while expecting another UP.
Other repetitions failed at :3896 with an UP in the third DOWN slot.
This is not evidence of a slow or unready listening socket.

A reduced Haskell probe using the same full-queue/forked-writer mechanism,
without sockets, TLS or SQLite, reversed DOWN/UP in 149 of 1000 iterations
under N2. All 1000 iterations received both values exactly once. The probe
had a 10s outer timeout. This independently confirms the ordering mechanism,
not an OpenBSD runtime result.

Fix: remove the four post-switch sleeps, consume continuously, and collect
separate exact sets of DOWN and UP connection IDs under the existing 10s
bound. Reject empty events, duplicate IDs, unexpected IDs and other event
types. Retain every session-count assertion and all bidirectional message
exchanges. The two pre-switch sleeps after earlier exchanges are unchanged.
The previous wildcard/predicate sequence neither tracked IDs nor consistently
counted event types. No notification is silently discarded.

This corrects a fixture assumption, not the upstream notification queue's
ordering guarantees. Changing its generic nonblocking writer to a blocking
write can deadlock lifecycle operations; it is also used for protocol sends.
An ordered, owned overflow dispatcher would need a separate lifecycle and
backpressure design and consumer regression tests. No such production change
or new ordering guarantee is claimed here. Therefore this test-only change
does not require another patch in simplex-chat.

After correction, all twenty isolated session-mode repetitions passed:
ten under N2 and ten under N1 (4.57-5.74s, seed 346723068). No process was
retried on failure; these are twenty separately completed executions with
the same assertions. Temporary event-printing instrumentation was removed.

For AUTH, keep the existing 30% CPU-time assertion (45% for PostgreSQL).
Inspection of the exact timeit-2.0/System/TimeIt.hs confirms that timeItT
uses System.CPUTime.getCPUTime, not wall time. The earlier report wrongly
called it wall time. The first resumed diagnostics inadvertently measured
CPU time twice, without changing the original assertion's metric. Correct
the diagnostic to record a GHC.Clock monotonic wall-time delta alongside
the original CPU-time measurement and label the SUB/SEND phase. CPU time
includes all process threads, including GC; wall time is diagnostic only.
With +RTS -T, also record total/major collection counts and GC CPU deltas
around each block. Do not subtract GC time or change the threshold. These
APIs were checked against GHC 9.10.3's GHC.Internal.Stats source as well as
the local compiler. Counts and CPU deltas cover the whole process, not only
the authentication worker. With -T, passing samples are also printed for
comparison; without it, diagnostics are failure-only. See the
[GHC 9.10.3 RTS documentation](https://downloads.haskell.org/ghc/9.10.3/docs/users_guide/runtime_control.html).
The SX25519-queue/Ed448-signature case uses the same dummy Ed448 verification
for a mismatched key and a missing queue. This narrows the investigation,
but does not explain CPU/GC variation or rule out a timing regression. All ten
isolated AUTH examples passed after the reboot (five repetitions, memory and
journal stores, N2, 11.3-13.1s per pair). No failure sample was generated;
these passes do not explain away the earlier full-suite failure.

Three subsequent N2 AUTH-group repetitions with CPU/wall/GC diagnostics
completed in 75.7094s, 76.7742s and 73.3946s. The first two passed 14/14;
the third failed two of 14 (40/42 passed overall). Both failures were in
the memory store: Ed25519/Ed25519 SEND, 40.7558%; Ed448/Ed448 SUB, 34.7103%.
All original response assertions were evaluated; neither was a timeout.
Thus these failures do not require full-suite contamination.

In the Ed25519 SEND failure, wrong-key CPU blocks were 0.283801, 0.332579,
0.122994 seconds; missing-queue blocks were 0.165569, 0.130108, 0.142359.
The SAME wrong-key action became 2.7 times faster in its third block.
Their aggregate CPU gap was 0.301338 seconds but the aggregate GC gap was
only 0.006939 seconds. This rules out GC accounting as the main explanation
for this reproduction. It does not identify an OpenBSD kernel or crypto bug.
No perf, strace or pidstat is installed; no host tools or limits were changed.

Correct the measurement design: retain three rounds and exactly n requests
per case per round (n=150 or 200, depending on the unchanged key-type matrix),
but split each round into blocks of at most 25 requests. Alternate which
case runs first in adjacent blocks and rounds. Sum every CPU sample, with
no trimming, retries, GC subtraction or threshold change. Keep one existing
100ms settling delay per round; remove the gap between the two cases, which
is not a protocol synchronization requirement. The warm-up remains unchanged.
This limits fixed-order sampling bias while retaining the regression check;
it is not a proof of cryptographic constant-time behavior. No production
authentication code or simplex-chat dependency patch changes.

After interleaving: three N2 AUTH-group executions passed all 42 examples
(63.6261s, 66.3555s, 66.3340s). Across the 84 SUB/SEND comparisons the largest
aggregate difference was 15.0422%, below the unchanged 30% limit. The block
schedule was also checked to contain exactly 450/600 requests per case and
an equal number of first/second placements (9/9 or 12/12). No outliers were
removed. Confidence: high that fixed-order sampling was invalid under the
observed drift; medium for eliminating all platform-dependent variation.

The complete SMP server via TLS group then passed 105 examples with 0 failures
and 2 existing pending in 163.5982s (N2). Both metric fixtures and their
neighboring store/restart/notification tests passed; the maximum AUTH
difference over its 28 comparisons was 16.5231%.

Related groups after the session-mode correction, before the later metrics
and AUTH changes, each in a separate process:

| Group | N2 | N1 |
|---|---|---|
| Functional API / Users | 4 examples, 0 failures; 15.7452s | 4 examples, 0 failures; 15.7399s |
| Batching SMP commands | 3 examples, 0 failures, 1 existing pending; 10.1008s | 3 examples, 0 failures, 1 existing pending; 10.0174s |
| Suspending agent | 3 examples, 0 failures; 8.3834s | 3 examples, 0 failures; 8.2317s |
| Timing of AUTH error | 14 examples, 0 failures; 77.4282s | 14 examples, 0 failures; 75.1090s |

All executions used seed 346723068. No new test or pending marker was added.

### Service-subscription metrics EOF

Exact example: `SMP server via TLS, jornal message store / Service message
subscriptions / should track totalServiceSubs correctly via SUBS and SUB`.
The full run rethrows an IOException EOF at tests/Util.hs:71:33. The client
and server use :5001; the metric path is tests/tmp/smp-server-metrics.txt.
Its memory-store variant passes in that full run.

Cause: the fixture uses lazy Prelude.readFile and demands only the metric's
line, not the rest of the file. Its semi-closed handle can remain registered
in GHC's file-lock table until GC. Server.hs savePrometheusMetrics opens the
same path for writing every second. An open failure escapes raceAny_, which
stops the server and disconnects the test clients. This is an upstream test
resource-lifetime bug, not TLS record corruption or an OpenBSD socket bug.

Before fix: six separate N2 executions of both store variants (12 examples)
yielded 6 failures in 4 executions: HandshakeFailed Error_EOF or PostHandshake
Error_EOF. Three failing logs explicitly show the writer's
`withFile: resource busy (file is locked)` immediately before those TLS
errors. The full-run EOF is consistent with the same server shutdown,
although that log alone did not expose the writer exception.

A focused no-network Haskell probe retained the lazy reader and reproduced
the writer failure 100/100 times; strict ByteString.readFile permitted all
100 writes. Fix both fixture reads to strict ByteString.readFile, closing
before parsing the required metric. No exception is swallowed, no TLS
validation changes, and both exact metric assertions (2 and 3) remain.
This is a test-only edit in patch-tests_ServerTests_hs; no production patch
needs copying to simplex-chat. Confidence: high for the isolated failures;
native timing and publication concurrency still require OpenBSD repetition.
After fix: ten N2 executions of both variants passed all 20 examples
(7.45-7.65s per pair), without writer-lock errors or retries.

### New XRCP pairing timeout in the N1 full run

Exact path: `XRCP / New controller/host pairing / should connect to new pairing`.
Exception: tests/Util.hs:71:33, user error (test timed out after 300 seconds).
The immediately preceding XFTP/Web tests passed, as did the subsequent
existing-pairing and multicast examples. The port is allocated by the OS;
neither its number nor the selected local address was logged. There is no
database in this example. Ten isolated N1 baseline repetitions passed
(0.63-0.81s); this does not explain away the full-run timeout.

Source defect: testNewPairing waited on the listener's HC.action BEFORE
waiting for its two application peers. Only the controller peer's successful
path cancelled that listener. Exceptions in either independently spawned
Async were not observed during that wait, outside the later five-second
timeout. The test also never explicitly cancelled its RCCtrlClient, and
exceptional exits did not own/join either peer or the listener. The full log
does not reveal which operation originally stopped progressing, so the
precise trigger remains unproved.

Fix the fixture's lifetime and observation order: acquire both clients under
base Control.Exception.bracket; run the two encrypted packet exchanges with
Control.Concurrent.Async.concurrently, propagating either peer's failure;
apply the existing five-second bound to that exchange, rather than only to
a final wait after listener termination. Keep session-code equality and both
decrypted-payload assertions. Cancel/join both exported non-multicast client
actions interruptibly under a five-second cleanup bound. Their absence of
an announcer is known from connectRCHost's False argument. Do not use the
uninterruptible public cancellation helpers in these test finalizers.
The listener must still finish with AsyncCancelled. Eliminate the two 250ms
post-exchange sleeps, since completion now synchronizes both peers.

Use a loopback preference for these two local peers, as already done for
the multicast fixture; do not depend on the builder's LAN address/firewall.
This does not disable IPv6 or change production discovery, authentication,
TLS, encryption, or the separate address-selection/IPv6 parsing tests.
This fixture correction is confined to patch-tests_RemoteControl_hs and is
not copied to Chat. The separate production audit below adds a shared XRCP
lifecycle correction; the fixture results here precede that production edit.

A reduced Async/MVar probe injects a peer exception into the old wait order:
all 20 trials hit its 100ms listener-wait timeout, whereas all 20 concurrent
controls immediately surfaced that exception. The same results held under
N1 and N2; all probe workers were bracketed and joined. This proves the
exception-observation defect, not the unlogged cause of the full-run stall.
After correction, the real new-pairing example passed ten N1 and ten N2
repetitions (20/20); the complete nine-example XRCP group passed three times
under each configuration (54/54). IPv6 parsing and real multicast discovery
were included. Linux sometimes logged an already-joined multicast interface
warning; these were successful discovery tests, not ignored HSpec failures.

Confidence: high for the unobserved-exception/resource-ownership defect;
medium attribution to the one full-run timeout, whose stage was not logged.
If it recurs natively, the bounded exchange or shutdown label now distinguishes
those phases, and peer exceptions are surfaced instead of waiting for 300s.
Capture TLS/connection errors at that stage and the ephemeral listener before
changing network semantics or any deadline.

## Production applicability audit (September 8, testing paused)

| Finding | Can it occur outside tests? | Runtime patch decision |
|---|---|---|
| RSLV timeout | Resource leaks and TLS corruption can affect real proxy clients; the native timeout's stage is unknown. | Retain shared transport/TLS fixes. Fix the demonstrated unclosed clients in the fixture, not speculative DNS/socket behavior. |
| Concurrent-delivery deadlock | An application that stops consuming agent events can create backpressure too. | Repair the fixture's premature consumer exit. Do not discard runtime events or change queue limits to conceal it. |
| Reconnect refusal | The one-second negative connection cache also exists at runtime. | Intentional cache behavior, not a proven socket regression. Disable the cache only in this second-attempt fixture. |
| Retry and SQLite I/O errors | Removing/reusing a live database pathname is unsafe in any application. The demonstrated misuse was fixture-owned. | Correct fixture ownership and retain shared agent shutdown/store-lock fixes. No SQLite durability or locking workaround. The original missing INFO still lacks a proved individual cause. |
| TLS RecordOverflow | Yes: the upstream TLS handshake timeout can interrupt a partially consumed record in real connections. | Keep the five-file upstream backport identical in both ports. |
| SENT after deletion | Yes: an already dequeued message can remain in flight after DB deletion. | Do not cancel all in-flight deliveries: the adjacent test explicitly requires one such delivery. Resolve the queued/in-flight contract first. |
| Session-mode DOWN/UP reordering | Yes: the generic nonblocking queue writer forks on a full queue and does not preserve order. | Document the risk; do not replace it with a blocking write, which can deadlock lifecycle code. Ordered overflow ownership and consumer-state regression coverage are still needed. |
| Metrics EOF | The observed GHC lock conflict requires a reader in the server's own process, as in this fixture. An external scraper does not acquire that Haskell handle lock. | Use strict fixture reads. Non-atomic metric publication and fatal write errors are separate runtime concerns, not proved causes needing an untested server rewrite here. |
| AUTH timing differences | CPU-time sampling bias does not establish a production authentication flaw. | Balance measurement order without changing authentication, thresholds or response assertions. |
| XRCP confirmation and repeated cancellation | Yes: these public operations are production code, independent of the faulty fixture wait order. | Add the narrow shared lifecycle patch described next. |

### Shared XRCP production patch: STATICALLY_IMPLEMENTED

Source: src/Simplex/RemoteControl/Client.hs, connectRCCtrl_/runSession,
confirmCtrlSession, cancelHostClient and cancelCtrlClient. The same code
exists in Chat's pinned embedded SimpleX revision.

confirmCtrlSession writes the decision, then writes it a second time to wait
for acknowledgement. The worker initially uses readTMVar, not takeTMVar;
only successful encrypted session setup removes that first decision. A
rejection or setup error can therefore terminate the worker with the slot
still full, leaving the caller blocked on the second put forever. For an
accepted session, putRCError publishes setup failure into the original
session-result TMVar before terminating the worker.

Retain successful acknowledgement, but use STM orElse to also observe
Control.Concurrent.Async.waitSTM on the connection action. Completion
releases the caller to inspect the original result; worker exceptions are
propagated, not ignored. This does not manufacture a valid session, consume
its result or weaken HELLO/TLS validation. A live but stalled peer still
requires the caller's deadline; this is not a general handshake-timeout fix.

Both cancellation functions previously used a blocking putTMVar on
endSession. Cancelling before establishment can leave that slot full after
the worker terminates, so a second shutdown request blocks before it reaches
cancellation. Use tryPutTMVar: an existing signal already requests shutdown.
The existing worker cancellation/join is retained. In particular, upstream
uninterruptibleCancel is not made globally bounded by this small change;
redesigning that cleanup without losing worker ownership needs further work.

Update the existing one-file patch in both locations, byte-identically:
net/simplexmq/patches/patch-src_Simplex_RemoteControl_Client_hs and
net/simplex-chat/files/patch-src_Simplex_RemoteControl_Client_hs.
Chat already registers this patch in SIMPLEXMQ_PATCHES; no manifest or new
dependency is required. Preserve the earlier multicast-interface fix.

Confidence: high for the two source-level blocking paths; attribution to
the uninstrumented N1 XRCP timeout remains unproved. No reproduction or
post-change execution was attempted after the testing pause. When authorized,
first add bounded regressions for rejection, a failing HELLO after TLS,
worker cancellation during confirmation, and repeated cancellation before
and after establishment. Check that the exact session error remains available,
then run XRCP, relevant Chat pairing tests, and the full N1/N2 suites.

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
  On the resumed SimpleX-only pass, all eight shared production patches
  have identical added/removed lines; version-specific hunk context is kept.
  The five TLS patches are byte-identical. All 25 embedded SimpleX patches
  and the TLS backport apply with fuzz=0. The later XRCP production patch
  is also byte-identical in both ports. All 47 MQ patches and 25 embedded
  Chat patches were applied again to fresh pinned sources after that edit,
  with fuzz=0; all patched MQ Haskell files match the prepared source tree.
  This last application check is not a build or an executable test.
  Test-only subscription/lifecycle fixtures are not copied into chat's
  independently defined test suite. A full simplex-chat build is not claimed.
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
- Batch-subscription correction: 20/20 isolated runs passed, ten each under
  N1/N2. Batching and suspension groups also passed under both configurations.
- Earlier N1 full run: 812 examples, 0 failures, 38 pending in 1394.7233s.
  TMPDIR was confined to the temporary working tree. No new OpenBSD run
  has been performed.
- Following N2 full run: 812 examples, 2 failures, 38 pending in 1218.3336s.
  All original nine cases passed; AUTH timing and user/session switching
  exposed additional issues. No failing test was retried to obtain this result.
- All SimpleXMQ patches, shared embedded SimpleX patches and TLS patches
  apply to fresh exact sources with fuzz=0. Every repository patch is
  one-target-file and has SPDX-License-Identifier and Index metadata.

## Native rerun

The do-test recipe now shell-quotes SIMPLEXMQ_TEST_OPTIONS with make's :Q
modifier. Wrapping the expanded value in double quotes does not protect
embedded quotes: the documented `--match "two way concurrently (50)"`
example previously caused a shell syntax error before Cabal ran. An isolated
Linux bmake/argument-capture probe reproduced that error; :Q preserved the
entire option string, its spaced selector and parentheses, and also handled
the empty default. This is a recipe-quoting check, not execution of the
OpenBSD ports infrastructure. The modifier is documented in
[OpenBSD make(1)](https://man.openbsd.org/make.1#Q).
simplex-chat has no corresponding interpolated test-option variable and
does not require this particular change.

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
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "/Functional API/Users/" --seed 346723068 +RTS -N2 -RTS'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "Timing of AUTH error" --seed 346723068 +RTS -N2 -T -RTS'
make do-test SIMPLEXMQ_TEST_OPTIONS='--match "Service message subscriptions" --seed 346723068 +RTS -N2 -RTS'
```

Run certificate rejection/TLS groups and the full suite again after those
checks; vary N1/N2 without changing the port's default. Record ulimit -a,
fstat -p PID, ps and netstat -an before/after groups to check native leaks
and listener shutdown. Run portcheck from current infrastructure.
Build/test simplex-chat natively after the shared TLS/transport changes.

Cleanup completed after pausing execution on September 8. Removed the
investigation's temporary sources, binaries, probes and Linux logs, and the
Cabal download cache at /var/home/david/.cache/cabal. Selectively removed
161 investigation-built Cabal package directories and 159 registrations,
then rebuilt the remaining registry cache. All 161 older registrations and
the user's Cabal configuration were preserved and their hashes checked.
Also removed the identified registration temporaries and 278 investigation
pip-cache files; cache entries refreshed by unrelated work were preserved.
The original OpenBSD log and this report remain. Deleted build artifacts
and dependency caches can be regenerated; the removed raw Linux logs cannot
be recovered from this checkout, so their results are recorded above.

## Files changed in the resumed SimpleX-only pass

- net/simplexmq/Makefile
- net/simplexmq/TEST-FAILURES.md
- net/simplexmq/patches/patch-tests_AgentTests_FunctionalAPITests_hs
- net/simplexmq/patches/patch-tests_ServerTests_hs
- net/simplexmq/patches/patch-tests_RemoteControl_hs
- net/simplexmq/patches/patch-src_Simplex_RemoteControl_Client_hs
- net/simplex-chat/files/patch-src_Simplex_RemoteControl_Client_hs

The unrelated fetch-ports.ksh worktree change was not edited or reverted.
No commit or push was performed in this pass. Final diff whitespace checks
are clean. Every updated patch retains SPDX and a single Index/target file.

## Files changed during this investigation and requested follow-ups

Historical list across the investigation, before subsequent user commits;
this is not the list of currently uncommitted files. The resumed task is
limited to simplexmq and relevant shared patches in simplex-chat. Other
ports and subsequent user changes are left untouched.

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
