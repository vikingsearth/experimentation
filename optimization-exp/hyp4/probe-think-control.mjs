#!/usr/bin/env node
// Can thinking be controlled on the route a `claude -p` worker actually uses?
//
// Workers talk to ollama over /v1/messages. That route was already shown to
// IGNORE options.num_ctx (hypothesis 2.1), so it may ignore a thinking control
// too. Hypothesis 4's main arm depends on the answer.
//
//   node probe-think-control.mjs [model]        default gemma4-12b-40k
//
// Runs one short prompt per probe, sequentially, because the daemon serves a
// single slot. Detection is by output-token count: a model that stops thinking
// emits dramatically fewer tokens for the same answer.

const HOST = process.env.OLLAMA_HOST?.replace(/\/$/, '') || 'http://localhost:11434';
const MODEL = process.argv[2] || 'gemma4-12b-40k';
const DERIVED = `${MODEL}-nothink`;

// Short, but the kind of question a thinking model chews on.
const Q = 'A policy limit is 3000 and an expense is 2850. Is it within limit? Answer yes or no and nothing else.';

const post = async (path, body, headers = {}) => {
  const t0 = Date.now();
  const res = await fetch(`${HOST}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  return { ms: Date.now() - t0, status: res.status, json };
};

// /api/chat reports eval_count; /v1/messages reports usage.output_tokens.
const outTokens = j => j.eval_count ?? j.usage?.output_tokens ?? null;
const answerOf = j => (j.message?.content ?? (j.content || []).map(c => c.text || '').join('')).trim().slice(0, 40);

const probes = [
  { name: 'native /api/chat, default',        run: () => post('/api/chat', { model: MODEL, stream: false, messages: [{ role: 'user', content: Q }] }) },
  { name: 'native /api/chat, think:false',    run: () => post('/api/chat', { model: MODEL, stream: false, think: false, messages: [{ role: 'user', content: Q }] }) },
  { name: 'native /api/chat, think:"low"',    run: () => post('/api/chat', { model: MODEL, stream: false, think: 'low', messages: [{ role: 'user', content: Q }] }) },
  { name: 'worker route /v1/messages, default',     run: () => post('/v1/messages', { model: MODEL, max_tokens: 512, messages: [{ role: 'user', content: Q }] }, { 'anthropic-version': '2023-06-01' }) },
  { name: 'worker route, think:false at top level', run: () => post('/v1/messages', { model: MODEL, max_tokens: 512, think: false, messages: [{ role: 'user', content: Q }] }, { 'anthropic-version': '2023-06-01' }) },
  { name: 'worker route, options.think:false',      run: () => post('/v1/messages', { model: MODEL, max_tokens: 512, options: { think: false }, messages: [{ role: 'user', content: Q }] }, { 'anthropic-version': '2023-06-01' }) },
];

const main = async () => {
  console.log(`model: ${MODEL}   host: ${HOST}\nprompt: ${Q}\n`);
  console.log('| probe | HTTP | output tokens | ms | answer |');
  console.log('|---|---|---|---|---|');
  const results = {};
  for (const p of probes) {
    try {
      const r = await p.run();
      results[p.name] = outTokens(r.json);
      console.log(`| ${p.name} | ${r.status} | ${outTokens(r.json) ?? '-'} | ${r.ms} | ${answerOf(r.json).replace(/\n/g, ' ')} |`);
    } catch (e) {
      console.log(`| ${p.name} | ERROR | - | - | ${e.message} |`);
    }
  }

  console.log(`
How to read it:
  If native think:false emits far fewer tokens than native default, the control
  works at the model level and the only question is whether the route carries it.
  If the three /v1/messages rows are all about equal, that route ignores the
  control, exactly as it ignores options.num_ctx.

Not covered here, because it needs a model build:
  PARAMETER think in a Modelfile. "think" is not among the parameters gemma
  currently carries (temperature, top_k, top_p, num_ctx), so it may simply be
  rejected. Test with:

    printf 'FROM ${MODEL}\\nPARAMETER think false\\n' > /tmp/Modelfile.nothink
    ollama create ${DERIVED} -f /tmp/Modelfile.nothink
    node probe-think-control.mjs ${DERIVED}

  If that create fails, the derived-model route is closed for thinking and the
  remaining lever is an instruction inside the brief, which is a brief-design
  change rather than a runtime one.`);
};

main().catch(e => { console.error(`failed: ${e.message}`); process.exit(1); });
