# Plan: map the behaviour beyond the grid

*Written 2026-09-09, before implementation. Implementation status updated as
the vertical slices land.*

RakuMap is an autonomous differential explorer for Raku implementations. It is
a sibling of Rakugrid, not a replacement: Rakugrid owns durable behavioural
tests and adjudications; RakuMap owns search, stability, minimization and the
evidence package from which a durable test can be made.

## The first measurable claim

Given two engine commands and the fixed numeric-v1 campaign, RakuMap generates
10,000 deterministic, oracle-valid cases, executes both engines with bounded
resources, reproduces every stable divergence from its seed, and automatically
reduces each one while preserving its divergence signature. A killed, crashed
or timed-out engine never kills or wedges the campaign.

The claim says **oracle-valid**, not “correct Raku.” A pinned Rakudo establishes
that the reference accepts the program; adjudication decides what the language
requires. RakuMap discovers evidence and does not turn an oracle observation
into a ruling silently.

## Terms

- **case** — one source program plus its generation witness;
- **observation** — one engine's compile/run result;
- **divergence** — observations differ under a declared comparator;
- **signature** — the normalized identity used to decide whether a divergence
  survived shrinking and whether two findings are probably duplicates;
- **finding** — a stable divergence with its evidence;
- **dossier** — the persisted, replayable finding directory;
- **ruling** — a human decision about expected language behaviour; owned by
  Rakugrid when exported;
- **campaign** — generator, domain, comparator, engines, budgets and seed range.

## Invariants

1. A mismatch is a lead, not a verdict.
2. The generated source, engine identities and raw observations are never
   discarded in favor of normalized output.
3. Every stochastic decision comes from the campaign seed and is recorded.
4. Engines run out of process, with wall time and output bounded independently.
5. Minimization preserves a divergence signature, not merely “still differs.”
6. Invalid generation is measured as generator debt, not hidden by filtering.
7. Rakudo is the default oracle but not the arbiter.
8. No normalizer may erase a semantic distinction without a pinned test.
9. Search output is disposable; dossiers are reproducible; confirmed behaviour
   graduates to a permanent suite.
10. RakuMap can consume Rakugrid vocabulary but neither repository is a runtime
    dependency of the other.

## Observation envelope

Each engine run produces a JSON record independent of presentation:

```json
{
  "engine": {
    "command": "/path/to/rakupp",
    "identity": "rakupp 3.26.0 build ..."
  },
  "compile": {
    "status": "accepted",
    "exit": 0,
    "duration-ms": 12
  },
  "run": {
    "status": "completed",
    "exit": 0,
    "stdout-sha256": "...",
    "stderr-sha256": "...",
    "duration-ms": 8
  },
  "limits": {
    "wall-ms": 1000,
    "output-bytes": 65536
  }
}
```

Statuses are closed vocabularies: `accepted`, `rejected`, `completed`,
`exception`, `timeout`, `crash`, `output-limit`, `spawn-failed`. Raw stdout and
stderr live beside the envelope. Signals and platform exception codes are
recorded without pretending they are portable.

Compile and run are separate. “Rakudo accepts, candidate rejects” is a finding,
not a case to discard before runtime comparison.

## Validity model

Validity is evidence with levels, not one Boolean:

| level | source | ordinary use |
|---|---|---|
| A | unchanged Roast/Rakugrid/regression/example case | trusted seed |
| B | known-valid seed under a proven metamorphic transformation | high-confidence search |
| C | restricted typed generator, accepted by the pinned oracle | synthetic search and CI |
| D | exploratory generator, accepted by the oracle | large campaigns, human triage |
| E | intentionally invalid mutation | rejection and diagnostic campaigns |

Every generator returns source plus a witness: template, feature tags,
assumptions, seed decisions and expected comparison mode. An oracle rejection
of a C case increments a generator-invalid counter and preserves a sample. A
campaign whose invalid rate crosses its declared ceiling fails even if it finds
interesting divergences.

Definedness is separate. Programs containing time, unseeded randomness,
unspecified iteration order, object addresses or unsynchronized shared mutation
are excluded from exact-output campaigns unless a comparator declares an
appropriate invariant.

## Comparison

Comparators are named and versioned:

- exact stdout/stderr/exit;
- value plus type envelope;
- exception type and message class;
- compile acceptance;
- unordered element collection;
- numeric tolerance with explicit absolute/relative bounds;
- repeated outcome set;
- invariant predicate.

Normalization removes only declared noise such as temporary directory prefixes,
engine banners and platform line endings. Each rule has a counterexample test
showing what it must not erase. Raw observations remain the evidence.

A divergence signature includes comparator version, acceptance/status pair,
exit/signal class, normalized difference, exception types, feature tags and a
coarse syntax shape. It excludes source length so shrinking does not change the
identity it is trying to preserve.

## Phases

### P0 — repository and contract (complete)

- project name and Rakugrid boundary;
- CLI vocabulary;
- finding/dossier format;
- this plan;
- load test and deterministic version output.

No result is claimed in P0.

### P1 — bounded engine runner (initial implementation)

Implement one reliable primitive:

```text
source + engine command + limits -> observation envelope + raw streams
```

Requirements:

- argument-vector spawning, never shell interpolation;
- isolated temporary working directory;
- controlled environment and deterministic locale/timezone;
- process-group/job-object timeout that kills descendants;
- separate stdout/stderr capture with per-stream and total limits;
- engine identity captured once per campaign;
- compile-only then runtime modes;
- cleanup after success, crash, timeout and coordinator interruption;
- coordinator runs under Raku++; observed engines remain arbitrary child
  commands and do not host RakuMap itself.

The first planted programs exit normally, reject at compile time, loop forever,
fork/spawn a lingering child, crash, and emit unbounded output. Each must yield
one bounded observation and leave no process behind.

### P2 — campaign and replay (initial implementation)

Define canonical campaign JSON: engines, generator and version, seed interval,
budgets, comparator and normalizer versions, stability repetitions and output
directory.

`rakumap explore` writes the campaign before starting, appends results
atomically, and resumes without repeating completed seeds. Parallel workers may
finish out of order; dossier identities and final summaries remain deterministic.

`rakumap replay DOSSIER` runs the exact recorded source and settings, verifies
engine identity unless explicitly relaxed, and reports whether the original
signature reproduced.

### P3 — numeric-v1 generator (initial implementation)

Build a small typed expression language rather than random source text:

- `Int`, boundary `Int`, `Rat`, `Num`, `Complex` and numeric allomorph leaves;
- prefix operations, arithmetic, comparisons and explicit conversions;
- literal, variable, parameter and return-value contexts;
- observations of `.raku`, `.^name`, `.Str`, `.Numeric` and truthiness;
- divisor/non-finite preconditions recorded in the witness;
- language revision as a campaign axis, never mixed inside one comparison.

The renderer owns parentheses and statement structure. The type/context model
is deliberately approximate; its invalid rate is reported and gated. P3 is not
a miniature implementation of Raku's type checker.

### P4 — stability and clustering

Re-run every first divergence at least three times per engine. Classify:

- stable;
- oracle-unstable;
- candidate-unstable;
- both unstable;
- timeout boundary (duration too near the limit).

Only stable divergences enter automatic shrinking. Cluster by signature before
shrinking so one defect does not produce ten thousand dossiers. Preserve counts
and representative seeds for every cluster.

### P5 — syntax-aware shrinking

Numeric-v1 initially owns its own AST and reducers:

- delete statements and unused declarations;
- inline variables;
- replace an expression with a compatible child;
- shrink integer magnitude toward `0`, `1`, `-1` and numeric boundaries;
- reduce rational numerators/denominators;
- remove conversions and observation fields;
- simplify context from return/parameter/container to direct expression;
- remove language pragmas only when the signature survives.

Use deterministic ordered reduction, cache attempted source hashes, and require
the same signature across the configured stability repetitions. Save both the
original and minimum. A reducer that creates oracle-invalid source is a rejected
step, not a new finding.

The minimizer has a call/time budget and returns the best known reduction when
exhausted. “Minimal” means no configured reducer succeeds, not a proof of global
minimality.

P5 completes the first measurable claim.

### P6 — known-valid mutation and metamorphic campaigns

Import seeds with provenance from Rakugrid, Roast, documentation examples and
engine regression suites. Transformations declare preconditions and the relation
they promise:

- introduce/inline a temporary;
- add redundant parentheses;
- move an expression through a parameter or return;
- add/remove a scalar container where semantics require decontainerization;
- convert a topic block and an equivalent WhateverCode;
- reorder independent declarations;
- substitute normalization-equivalent Unicode strings in domains where that is
  the promised relation.

Metamorphic campaigns compare each engine with itself before comparing engines.
If the oracle violates the promised relation, that is transformation debt or an
oracle lead, not automatically a candidate failure.

### P7 — signatures, containers, Unicode and regex domains

Status: the shared registry plus initial `containers-v1`, `signatures-v1`,
`unicode-v1`, and `regex-v1` generators are implemented.

Add one domain per release, each with its own validity model, comparators,
reducers and measurable invalid-rate ceiling. Do not build one universal Raku
AST prematurely.

Suggested order:

1. signatures, constraints and dispatch;
2. binding, containers and aliases;
3. Unicode grapheme/string operations;
4. regex capture and backtracking;
5. invalid syntax and diagnostics;
6. sanitizer-backed memory-safety campaigns;
7. concurrency invariants and repeated schedules.

### P8 — adjudication and export

Classification is explicit: candidate defect, intentional divergence, oracle
defect/suspect, unspecified/unstable, unsupported feature, duplicate, generator
defect, normalizer defect, or pending.

Exporters produce a patch-ready artifact but do not mutate another repository
unless asked:

- Rakugrid atom/molecule skeleton with oracle observation, provenance and
  proposed expectation;
- Raku++ `t/regression` case ending in `PASS`;
- generic standalone reproducer plus Markdown report.

The dossier records the destination commit when a finding graduates. Export is
idempotent and never marks a ruling as signed automatically.

## Initial layout

```text
bin/rakumap                  CLI
lib/RakuMap.rakumod          version and public entry point
lib/RakuMap/Runner.rakumod   P1 child-process boundary
lib/RakuMap/Observation.rakumod
lib/RakuMap/Campaign.rakumod
lib/RakuMap/Compare.rakumod
lib/RakuMap/Generators/      domain generators
lib/RakuMap/Shrink/          domain reducers
t/                           deterministic unit and process tests
fixtures/                    planted programs and engine shims
out/                         ignored campaign output
```

Modules appear when their phase starts; empty architecture is not progress.

## Gates for the first release

1. **Determinism:** two numeric-v1 runs with the same campaign and engine
   identities generate byte-identical source per seed and identical summaries.
2. **Runner containment:** planted timeout, descendant, crash and output-flood
   cases complete within the suite budget and leave no descendants.
3. **Acceptance visibility:** oracle-accept/candidate-reject and its inverse are
   both recorded as divergences, never filtered away.
4. **Generator honesty:** oracle-invalid C cases are counted and the fixed
   campaign remains below its declared invalid-rate ceiling.
5. **Raw evidence:** changing a normalizer cannot change stored raw output.
6. **Normalizer counterexamples:** every normalization rule's semantic near-miss
   remains observably different.
7. **Stability:** planted nondeterminism is classified unstable and never sent
   to exact shrinking.
8. **Signature-preserving shrink:** every planted divergence reaches its checked
   minimum; a tempting smaller program with a different failure category is
   rejected.
9. **Replay:** every checked-in dossier reproduces from source and reports an
   engine-identity mismatch clearly.
10. **Raku++ host:** the harness and every shipped `rakumap` command run under
    pinned Raku++; Rakudo may be an observed oracle child but is never the host
    interpreter for RakuMap.

Every gate gets a planted defect before it is trusted.

## Non-goals for the first release

- proving generated programs correct from first principles;
- generating arbitrary Raku syntax;
- declaring Rakudo behavior normative automatically;
- replacing Roast or Rakugrid;
- fuzzing filesystem, network, NativeCall or unrestricted `EVAL`;
- exact comparison of time, randomness, hash order or racy programs;
- a universal semantics-preserving reducer;
- unattended publication of issues or patches;
- distributed execution;
- coverage-guided native instrumentation.

## Relationship protocol with Rakugrid

The repositories share concepts, not internal modules. RakuMap may consume a
versioned Rakugrid export containing atom IDs, feature tags, facet coordinates,
ladders and seed programs. Rakugrid may consume a versioned RakuMap export
containing a minimized case, raw oracle observation, proposed comparator,
provenance and dossier ID.

Neither reaches into the other's `lib/` or undocumented file layout. The first
integration is a JSON interchange fixture checked into both repositories. This
keeps each tool usable with any Raku implementation and independently releasable.

## Release boundary

P0-P5 are v0.1.0. It ships only when the runner is containment-tested, the
numeric-v1 fixed campaign meets its validity ceiling, every stable planted
divergence shrinks to its expected minimum, and the whole campaign replays under
Raku++ as the coordinator, with both Rakudo and Raku++ exercised as observed
child engines.

The release statement is narrow:

> RakuMap can explore one defined numeric subset, distinguish acceptance,
> runtime and stability divergences between two Raku implementations, and turn
> each stable result into a bounded, replayable, automatically minimized
> dossier.

That is enough foundation to add language domains without changing what a
finding means.
