# Derived models for the local arms

Each pins `num_ctx` to its parent model's **architecture maximum**, so context
is never the binding constraint on a local arm. A Modelfile-pinned context is
the only method that survives the `/v1/messages` route a `claude -p` worker
uses.

```bash
ollama create qwen3-8b-40k    -f qwen3-8b-40k.Modelfile
ollama create gemma4-12b-256k -f gemma4-12b-256k.Modelfile
```

| Derived model | Parent | Context | Measured resident | Notes |
|---|---|---|---|---|
| `qwen3-8b-40k` | `qwen3:8b` | 40,960 | 10.6 GB | 40,960 is qwen3:8b's architecture ceiling. Cache costs 144 KB per token |
| `gemma4-12b-256k` | `gemma4:12b` | 262,144 | 7.7 GB | Sliding-window attention keeps the cache cheap. Costs less than the same model at 65,536 |

No extra disk. ollama layers are content-addressed, so each derived model
points at its parent's existing weight blob.

To remove them: `ollama rm qwen3-8b-40k gemma4-12b-256k`
