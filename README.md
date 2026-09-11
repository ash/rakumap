# RakuMap

Autonomous differential exploration for the Raku language.

[Roast](https://github.com/Raku/roast) asks whether an implementation conforms
to the language. [Rakugrid](https://github.com/ash/rakugrid) lays known Raku
behaviour out as atoms, ladders and combinations. **RakuMap explores beyond the
known grid**: it generates and mutates programs, runs them on multiple
implementations, separates stable divergences from noise, shrinks each finding
to its essential coordinates, and preserves enough evidence to reproduce and
adjudicate it.

The name is literal. Rakugrid is the coordinate system; RakuMap is the survey.

## The boundary with Rakugrid

| | Rakugrid | RakuMap |
|---|---|---|
| Primary job | Specify and gate known behaviour | Discover unknown behaviour |
| Inputs | Curated atoms, inventories, generators, rulings | Seeds, transformations, typed grammars, engine commands |
| Output | Stable assertions and coverage | Reproducible, minimized divergence dossiers |
| Normal mode | Deterministic test suite | Bounded autonomous search |
| A result becomes permanent by | Living in the grid | Exporting to Rakugrid or an engine regression suite |

RakuMap does not become another conformance suite. A finding stays a lead until
it is minimized and classified. Confirmed language behaviour should graduate
to Rakugrid; an implementation-specific regression may graduate directly to
that implementation's suite.

## The pipeline

```text
known-valid seeds + structured generators
                  |
                  v
       candidate Raku programs
                  |
          compile classification
                  |
          isolated engine runs
                  |
       normalize + stability check
                  |
          divergence clustering
                  |
       syntax-aware minimization
                  |
       one evidence-backed dossier
                  |
     adjudicate / export / suppress
```

Every run is reproducible from a generator version and seed. Every engine runs
as a bounded child process. A crash, timeout or unbounded output is a result,
not a way to lose the campaign.

## How validity is handled

RakuMap never claims that random text is a correct program.

- Synthetic cases come from restricted, context-aware generators that know the
  shapes they produce.
- Mutation campaigns begin with known-valid programs and apply named
  transformations with explicit preconditions.
- A pinned Rakudo classifies oracle acceptance, but is an observation source,
  not the final arbiter.
- Syntax acceptance, defined behaviour and output comparability are recorded
  separately.
- A mismatch is a **divergence**, not automatically a Raku++ bug.
- Minimization must preserve the same divergence signature; changing a wrong
  result into an unrelated parse error is not a successful shrink.

Confidence is visible on every case: imported known-valid, metamorphic,
typed-generated, oracle-accepted exploratory, or intentionally invalid.

## Repository map

```text
bin/
  rakumap                         command-line entry point; runs under rakupp

lib/
  RakuMap.rakumod                 project name and version
  RakuMap/
    Campaign.rakumod              generation, exploration, dossier writing, replay
    Runner.rakumod                bounded compile/run of observed child engines
    Generator/
      Registry.rakumod            generator names and --generator=all dispatch
      Numeric.rakumod             deterministic numeric-v1 program generator
      Containers.rakumod          deterministic containers-v1 program generator
      Signatures.rakumod          deterministic signatures-v1 program generator
      Unicode.rakumod             deterministic unicode-v1 program generator
      Regex.rakumod               deterministic regex-v1 program generator
      Control.rakumod             deterministic control-v1 program generator
      Operators.rakumod           deterministic operators-v1 program generator
      Types.rakumod               deterministic types-v1 program generator
      Variables.rakumod           deterministic variables-v1 program generator

t/
  00-load.rakutest                public module/version smoke test
  01-numeric-generator.rakutest   numeric determinism and generated-source checks
  02-runner.rakutest              acceptance, rejection, output and timeout checks
  03-campaign.rakutest            planted divergence, dossier and replay checks
  04-containers-generator.rakutest registry and container-template coverage
  05-signatures-generator.rakutest signature determinism and template coverage
  06-unicode-generator.rakutest   Unicode determinism and template coverage
  07-regex-generator.rakutest     regex determinism and template coverage
  08-control-generator.rakutest   bounded control-flow template coverage
  09-operators-generator.rakutest operator determinism and template coverage
  10-types-generator.rakutest     type-system determinism and template coverage
  11-variables-generator.rakutest variable and binding template coverage

fixtures/
  engines/                        small shell engines with planted behaviours
  generated/
    numeric-v1/                   committed numeric programs for seeds 40–49
    containers-v1/                committed container programs for seeds 40–49
    signatures-v1/                committed signature programs for seeds 40–51
    unicode-v1/                   committed Unicode programs for seeds 40–51
    regex-v1/                     committed regex programs for seeds 40–51
    control-v1/                   committed control-flow programs for seeds 40–51
    operators-v1/                 committed operator programs for seeds 40–51
    types-v1/                     committed type-system programs for seeds 40–51
    variables-v1/                 committed variable programs for seeds 40–51
  findings/
    numeric-00000048/             first preserved real differential finding
    operators-00000041/           preserved junction-output difference
    operators-00000048/           preserved reduction-result difference
    types-00000040/               preserved typed-array-name difference

docs/
  PLAN.md                         architecture, invariants, phases and release gates

out/                              ignored, disposable local campaign output
META6.json                        Raku distribution metadata and module index
.gitignore                        excludes generated campaign and editor/build state
```

The code that generates programs belongs in `lib/RakuMap/Generator/`. Small,
fixed examples used for review and regression live in `fixtures/generated/`.
Exploration writes bulk programs and findings to `out/`; that directory is
ignored because it may become large. A particularly useful finding may be
copied to `fixtures/findings/` deliberately, together with its raw evidence.

`fixtures/engines/` does not contain Raku implementations. Those scripts are
controlled test doubles used to prove that RakuMap recognizes successful runs,
compile rejection, differing output and timeouts without depending on a real
engine defect.

## Current command line

The first vertical slice is live: deterministic numeric program generation,
bounded two-engine execution, stability checks, persisted dossiers and replay.
RakuMap itself is hosted by Raku++; Rakudo is invoked only as an observed child
when it is selected as the oracle.

```sh
rakupp -Ilib bin/rakumap generate --cases=20 --seed=1000 \
  --out=out/generated

# Generate 20 programs per implemented domain:
rakupp -Ilib bin/rakumap generate --generator=all --cases=20 --seed=1000 \
  --out=out/generated-all

rakupp -Ilib bin/rakumap explore --generator=containers --cases=10000 --seed=1000 \
  --oracle=raku --candidate=/path/to/rakupp

rakupp -Ilib bin/rakumap replay out/latest/findings/numeric-00001048 \
  --oracle=raku --candidate=/path/to/rakupp

# Planned commands:
rakumap mutate t/seeds/signatures.raku --transform=container-layer \
  --oracle=raku --candidate=/path/to/rakupp
rakumap shrink out/findings/2026-09-09-00017
rakumap classify out/findings/2026-09-09-00017 --as=candidate-defect
rakumap export out/findings/2026-09-09-00017 --rakugrid=/path/to/rakugrid
rakumap stats
```

Run the test suite with Raku++:

```sh
rakupp -Ilib bin/rakumap help
for test_file in t/*.rakutest; do rakupp -Ilib "$test_file" || break; done
```

## Finding layout

```text
out/findings/2026-09-09-00017/
  case.raku             current reproducer (not minimized yet)
  original.raku         first generated program
  finding.json          seed, generator, engines, classification, signature
  oracle.stdout
  oracle.stderr
  candidate.stdout
  candidate.stderr
  oracle.signature
  candidate.signature
```

Generated bulk output lives under `out/` and is not committed. The fixed seeds
Fixed corpora are checked in under `fixtures/generated/numeric-v1/`,
`fixtures/generated/containers-v1/`, `fixtures/generated/signatures-v1/`, and
`fixtures/generated/unicode-v1/`, `fixtures/generated/regex-v1/`,
`fixtures/generated/control-v1/`, `fixtures/generated/operators-v1/`, and
`fixtures/generated/types-v1/`, and `fixtures/generated/variables-v1/`. The
numeric and container sets use seeds 40–49; signatures, Unicode, regex, control,
operators, types, and variables use 40–51 so all 12
templates in each domain are represented. The
first real stable divergence (numeric seed 48) is preserved under
`fixtures/findings/numeric-00000048/`. Operator seeds 41 and 48 are preserved
beside it, as is type seed 40. Each dossier contains both engines' raw
observations.

## Status

The first P1-P3 implementation and eight domain extensions are in place.
The registry currently exposes `numeric`, `containers`, `signatures`, and
`unicode`, `regex`, `control`, `operators`, `types`, and `variables`;
`--generator=all` runs all nine. It
deliberately remains smaller
than the release claim: output limits, campaign resume, engine identity,
clustering and syntax-aware shrinking still need to land. The current fixed
generator already produces replayable numeric divergences and reports every
oracle rejection instead of silently filtering it.

See [docs/PLAN.md](docs/PLAN.md) for the phased build and release gates.
