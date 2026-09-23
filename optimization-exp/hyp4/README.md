# Hypothesis 4 run assets

Speed levers on a single model. The design doc is written once arm D of
[hypothesis 2.1](../../docs/research/optimization/hypothesis_2_1.md) lands,
because arm D is the baseline it measures against.

## Queued, in order

| Step | What | Blocked on |
|---|---|---|
| 1 | `probe-think-control.mjs` - can thinking be set on the route a worker uses? | Arm D finishing. The daemon serves one slot |
| 2 | Write the hypothesis 4 and 5 design docs | Arm D results, plus what step 1 finds |
| 3 | Run the speed arms | Step 1 confirming a lever exists |

## Why step 1 comes first

Hypothesis 4's central arm is "same model, less thinking". Gemma spent **60,400
output tokens** across three briefs in arm D, and brief 3 alone emitted 36,819
tokens to produce a 505-word report. At 5.7 to 13.1 tokens per second that is
essentially the entire wall-clock. Thinking, not hardware, is the cost.

But the control may not be reachable. ollama's CLI has `--think` accepting
`true`/`false` or `high`/`medium`/`low`, so the capability exists. Workers do
not use the CLI; they use `/v1/messages`, and that route was already shown to
**ignore** `options.num_ctx` (hypothesis 2.1). `think` is also not among the
parameters gemma carries, so the derived-model trick that fixed context may not
fix this.

Three outcomes, three different hypothesis 4 designs:

| If | Then |
|---|---|
| The route honours a thinking flag | Run the arm as designed, ideally as a `high`/`medium`/`low` sweep rather than on/off |
| Only a derived model carries it | Same arm, one extra `ollama create` per setting |
| Neither works | The only lever left is an instruction in the brief, which is brief design rather than runtime. Hypothesis 4 narrows to the runtime question alone |

## Usage

```bash
node probe-think-control.mjs                  # gemma4-12b-40k
node probe-think-control.mjs <other-model>
```

Sequential by design. Detection is by output-token count: a model that stops
thinking emits far fewer tokens for the same answer.
