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

## Intended command line

The checked-in CLI currently establishes the command vocabulary; the engine
runner lands first.

```sh
rakumap explore --generator=numeric --cases=10000 --seed=1000 \
  --oracle=raku --candidate=/path/to/rakupp

rakumap mutate t/seeds/signatures.raku --transform=container-layer \
  --oracle=raku --candidate=/path/to/rakupp

rakumap replay out/findings/2026-09-09-00017
rakumap shrink out/findings/2026-09-09-00017
rakumap classify out/findings/2026-09-09-00017 --as=candidate-defect
rakumap export out/findings/2026-09-09-00017 --rakugrid=/path/to/rakugrid
rakumap stats
```

Run the current scaffold:

```sh
raku -Ilib bin/rakumap help
raku -Ilib t/00-load.rakutest
```

## Finding layout

```text
out/findings/2026-09-09-00017/
  case.raku             minimized reproducer
  original.raku         first generated program
  finding.json          seed, generator, engines, classification, signature
  oracle.stdout
  oracle.stderr
  candidate.stdout
  candidate.stderr
```

Generated bulk output lives under `out/` and is not committed. A small curated
`fixtures/` and fixed-seed campaign corpus will be committed as the project
grows.

## Status

Phase 0: repository and contract. The name, boundary with Rakugrid, finding
model, initial CLI vocabulary and implementation plan are in place. No search
result is claimed yet.

See [docs/PLAN.md](docs/PLAN.md) for the phased build and release gates.

