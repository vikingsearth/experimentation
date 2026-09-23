#!/usr/bin/env node
// Show what context length each local ollama model supports, what the daemon
// actually loads it with, and how much of that a hypothesis 2.1 brief needs.
//
//   node ollama-context.mjs              # all local models
//   node ollama-context.mjs qwen3:8b     # just these
//   node ollama-context.mjs --json
//
// Zero dependencies. Reads only; changes nothing.

const HOST = process.env.OLLAMA_HOST?.replace(/\/$/, '') || 'http://localhost:11434';

const api = async (path, body) => {
  const res = await fetch(`${HOST}${path}`, body
    ? { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) }
    : {});
  if (!res.ok) throw new Error(`${path} -> HTTP ${res.status}`);
  return res.json();
};

// The architecture's own ceiling is stored family-prefixed, e.g. `qwen3.context_length`,
// `gemma4.context_length`, `qwen3moe.context_length`. Find it without knowing the family.
const archContext = (info = {}) => {
  const hit = Object.entries(info).find(([k]) => k.endsWith('.context_length'));
  return hit ? { key: hit[0], value: hit[1] } : { key: null, value: null };
};

// A num_ctx pinned in the model's own Modelfile overrides the daemon default.
const modelfileNumCtx = (params = '') => {
  const m = params.match(/^\s*num_ctx\s+(\d+)/m);
  return m ? Number(m[1]) : null;
};

const fmt = n => (n == null ? '-' : n.toLocaleString('en-US'));

// The API carries no link to the model's library page - verified 2026-09-11,
// the only URLs anywhere in /api/show are inside the licence text. This builds
// the conventional URL from the tag. It is constructed, not reported, so it can
// be wrong for models that did not come from the official library.
const libraryUrl = name => `https://ollama.com/library/${name.split(':')[0]}`;
const gb = b => (b == null ? '-' : `${(b / 1024 ** 3).toFixed(1)} GB`);

const main = async () => {
  const args = process.argv.slice(2);
  const asJson = args.includes('--json');
  const wanted = args.filter(a => !a.startsWith('--'));

  const { models = [] } = await api('/api/tags');
  const names = wanted.length ? wanted : models.map(m => m.name);
  const sizeOf = Object.fromEntries(models.map(m => [m.name, m.size]));

  // What is resident right now, and with what context the daemon chose.
  let loaded = {};
  try {
    const ps = await api('/api/ps');
    loaded = Object.fromEntries((ps.models || []).map(m => [m.name, m.context_length ?? null]));
  } catch { /* /api/ps is optional */ }

  const rows = [];
  for (const name of names) {
    try {
      const show = await api('/api/show', { model: name });
      const arch = archContext(show.model_info);
      rows.push({
        model: name,
        family: show.details?.family ?? '?',
        params: show.details?.parameter_size ?? '?',
        quant: show.details?.quantization_level ?? '?',
        disk: sizeOf[name] ?? null,
        arch_max: arch.value,
        arch_key: arch.key,
        modelfile_num_ctx: modelfileNumCtx(show.parameters),
        loaded_with: loaded[name] ?? null,
        capabilities: show.capabilities ?? [],
        library_url_constructed: libraryUrl(name),
      });
    } catch (e) {
      rows.push({ model: name, error: e.message });
    }
  }

  if (asJson) { console.log(JSON.stringify(rows, null, 2)); return; }

  console.log(`ollama at ${HOST}\n`);
  console.log('| Model | Params | On disk | Architecture max | Modelfile num_ctx | Loaded with | Thinking |');
  console.log('|---|---|---|---|---|---|---|');
  for (const r of rows) {
    if (r.error) { console.log(`| ${r.model} | ERROR: ${r.error} |`); continue; }
    console.log(`| ${r.model} | ${r.params} | ${gb(r.disk)} | ${fmt(r.arch_max)} | ${r.modelfile_num_ctx ?? 'not set'} | ${r.loaded_with ? fmt(r.loaded_with) : 'not resident'} | ${r.capabilities.includes('thinking') ? 'yes' : 'no'} |`);
  }

  console.log('\nLibrary pages (constructed from the tag, NOT reported by the API):');
  for (const r of rows) if (!r.error) console.log(`  ${r.model.padEnd(14)} ${r.library_url_constructed}`);

  const anyLoaded = rows.find(r => r.loaded_with);
  console.log(`
How to read this:
  Architecture max   what the model itself supports. From model_info.<family>.context_length
  Modelfile num_ctx  a ceiling pinned into the model. "not set" means the daemon decides
  Loaded with        what the running daemon actually gave it. Only visible while resident

The daemon decides the real number unless a Modelfile pins it. Change it with
OLLAMA_CONTEXT_LENGTH and restart the daemon, which drops every loaded model:

  OLLAMA_CONTEXT_LENGTH=65536 ollama serve

A larger context costs key-value cache memory per loaded model, so it trades
against how many models fit at once.

Setting num_ctx, verified 2026-09-11:
  /api/generate, /api/chat   options.num_ctx IS honoured per request
  /v1/messages               options.num_ctx is IGNORED. The daemon default wins

The Anthropic-format route is the one Claude Code uses, so a worker launched
with ANTHROPIC_BASE_URL pointed here cannot choose its own context. Only
OLLAMA_CONTEXT_LENGTH plus a daemon restart changes it.

There is no endpoint listing which parameters are settable or their ranges.
The "parameters" field shows only what a Modelfile pinned. The practical
ceiling for num_ctx is the architecture max above: beyond it ollama still
allocates the cache, but the model is past what it was trained for.`);
  if (!anyLoaded) console.log(`
Nothing is resident, so "Loaded with" is blank. Run any prompt against a model
and re-run this within its keep-alive window to see the real figure.`);
};

main().catch(e => { console.error(`failed: ${e.message}`); process.exit(1); });
