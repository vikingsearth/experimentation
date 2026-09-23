# Hypothesis 2.1 run assets

Runs and tooling for
[hypothesis_2_1.md](../../docs/research/optimization/hypothesis_2_1.md),
extending the subagent tier ladder below Haiku with local models.

| Path | What |
|---|---|
| `ollama-context.mjs` | Reports what context each local model supports, what the daemon actually loads it with, and where `num_ctx` can and cannot be set. Zero dependencies, read-only |

Nothing has been run yet. Reports will land here per arm when they are.

## Usage

```bash
node ollama-context.mjs                    # every local model
node ollama-context.mjs qwen3:8b           # named models only
node ollama-context.mjs --json             # machine readable
```

Set `OLLAMA_HOST` if the daemon is not on `http://localhost:11434`.

## Running an arm

```bash
./run-local-arm.sh qwen3-8b-40k    arm-c-qwen3-8b-40k
./run-local-arm.sh gemma4-12b-256k arm-d-gemma4-12b-256k
```

Sequential by design: the ollama daemon serves one slot on stock defaults, so
concurrency queues rather than parallelises (measured in hypothesis 1).

Briefs run in the order 1, 2, 3, 4, 5. Brief 5 is last because it is the
heaviest at ~17,800 tokens of intended content, so four results are banked
before the riskiest one.

Per worker the runner records `input_tokens`, `output_tokens`, turns, API time,
wall-clock and a status of `ok`, `empty`, `malformed` or `no-json`. A worker
that does not produce a report with a Findings section is retried once, then
recorded as incomplete rather than scored as poor quality. There is a 45 minute
watchdog per worker, implemented by hand because this machine has no
`timeout(1)`.

Outputs land in `reports/<arm>/`:

| File | What |
|---|---|
| `NN-name.md` | The report, extracted, only written when the worker succeeded |
| `NN-name.attemptN.json` | The raw harness output, kept for every attempt |
| `_metrics.tsv` | One row per attempt |
| `_progress.log` | Timestamped progress, tail it during a run |
