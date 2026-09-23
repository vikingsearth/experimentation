# Hypothesis 3 run assets

Runs for [hypothesis_3.md](../../docs/research/optimization/hypothesis_3.md),
verification as its own tier. The design and the conclusions live in that
document; this directory holds only what a run consumed and produced.

| Directory | What ran | Outcome |
|---|---|---|
| `spike-01-synthesis-verification/` | One Sonnet verifier checking a manager's answer against the five reports it was built from, with no codebase access | Caught 0 of 3 known errors. Found 4 real but inconsequential ones |

Each spike directory holds its own `scoring.md` explaining what was tested and
how it was judged.
