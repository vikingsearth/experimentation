#!/usr/bin/env node
// Hypothesis 4 shim.
//
// A `claude -p` worker speaks Anthropic /v1/messages. ollama serves that route
// but IGNORES any thinking control on it, and `PARAMETER think` is rejected by
// `ollama create`. The only place the control works is ollama's native
// /api/chat, where `think:false` cut output 61x and latency 21x.
//
// So: accept /v1/messages, translate to /api/chat, set think as configured,
// translate the answer back into an Anthropic SSE stream.
//
//   THINK=false node think-shim.mjs      # arm 4A, thinking off
//   THINK=true  node think-shim.mjs      # arm 4B, control: shim cost only
//
// Calls upstream with stream:false and synthesises the SSE at the end. The
// worker gets valid events, just not incrementally, which is fine for batch.

import { createServer } from 'node:http';
import { appendFileSync } from 'node:fs';

const UP    = process.env.OLLAMA_HOST || 'http://localhost:11434';
const PORT  = Number(process.env.PORT || 11435);
const THINK = process.env.THINK === 'true';
const LOG   = process.env.SHIM_LOG || '/tmp/think-shim.log';
const log = (...a) => appendFileSync(LOG, `[${new Date().toISOString()}] ${a.join(' ')}\n`);

const textOf = c => typeof c === 'string' ? c
  : Array.isArray(c) ? c.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';

// Anthropic messages -> ollama chat messages.
// A tool_result references its call by id only. ollama associates a tool
// message with its call by NAME, so the id->name map built from the assistant
// turns has to be carried across, or the model never sees that its call was
// answered and simply calls again. That cost 7 turns instead of 2 before it
// was fixed.
const toOllamaMessages = (system, messages) => {
  const out = [];
  const sys = textOf(system);
  if (sys) out.push({ role: 'system', content: sys });

  const nameById = new Map();
  for (const m of messages) {
    for (const b of (Array.isArray(m.content) ? m.content : [])) {
      if (b.type === 'tool_use' && b.id) nameById.set(b.id, b.name);
    }
  }

  for (const m of messages) {
    if (m.role === 'system') { out.push({ role: 'system', content: textOf(m.content) }); continue; }

    const blocks = Array.isArray(m.content) ? m.content : [{ type: 'text', text: m.content }];
    const toolResults = blocks.filter(b => b.type === 'tool_result');
    const toolUses    = blocks.filter(b => b.type === 'tool_use');
    const text        = textOf(blocks);

    if (m.role === 'assistant') {
      const msg = { role: 'assistant', content: text };
      if (toolUses.length) msg.tool_calls = toolUses.map(t => ({
        function: { name: t.name, arguments: t.input || {} },
      }));
      out.push(msg);
    } else {
      // A user turn carrying tool results becomes one tool message per result.
      if (text) out.push({ role: 'user', content: text });
      for (const r of toolResults) {
        const msg = { role: 'tool', content: typeof r.content === 'string' ? r.content : textOf(r.content) };
        const name = nameById.get(r.tool_use_id);
        if (name) msg.tool_name = name;
        out.push(msg);
      }
      if (!text && !toolResults.length) out.push({ role: 'user', content: '' });
    }
  }
  return out;
};

const toOllamaTools = tools => (tools || [])
  .filter(t => t.name && t.input_schema)     // skip server-side tool stubs
  .map(t => ({ type: 'function', function: {
    name: t.name, description: t.description || '', parameters: t.input_schema,
  } }));

const sse = (res, event, data) => res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);

createServer(async (req, res) => {
  const chunks = []; for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks).toString();

  if (!req.url.startsWith('/v1/messages')) {          // anything else passes straight through
    const up = await fetch(UP + req.url, { method: req.method, headers: { ...req.headers, host: 'localhost:11434' },
      body: ['GET', 'HEAD'].includes(req.method) ? undefined : raw });
    const txt = await up.text();
    res.writeHead(up.status, { 'content-type': up.headers.get('content-type') || 'application/json' });
    return res.end(txt);
  }

  let body; try { body = JSON.parse(raw); } catch { res.writeHead(400); return res.end('{}'); }

  const payload = {
    model: body.model,
    messages: toOllamaMessages(body.system, body.messages || []),
    tools: toOllamaTools(body.tools),
    think: THINK,
    stream: false,
    options: { num_predict: body.max_tokens ?? -1 },
  };
  if (!payload.tools.length) delete payload.tools;

  const t0 = Date.now();
  let j;
  try {
    const up = await fetch(`${UP}/api/chat`, { method: 'POST',
      headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload) });
    j = await up.json();
  } catch (e) {
    log('upstream failed:', e.message);
    res.writeHead(502, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ type: 'error', error: { type: 'api_error', message: e.message } }));
  }
  if (j.error) {
    log('upstream error:', JSON.stringify(j.error).slice(0, 200));
    res.writeHead(400, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ type: 'error', error: { type: 'invalid_request_error', message: String(j.error) } }));
  }

  const msg   = j.message || {};
  const calls = msg.tool_calls || [];
  const text  = msg.content || '';
  const inTok = j.prompt_eval_count ?? 0;
  const outTok = j.eval_count ?? 0;
  log(`think=${THINK} ${Date.now() - t0}ms in=${inTok} out=${outTok} tools=${calls.length} textlen=${text.length}`);

  res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-cache', connection: 'keep-alive' });
  const id = 'msg_' + Math.random().toString(16).slice(2, 14);
  sse(res, 'message_start', { type: 'message_start', message: { id, type: 'message', role: 'assistant',
    model: body.model, content: [], stop_reason: null, stop_sequence: null,
    usage: { input_tokens: inTok, output_tokens: 0 } } });

  let idx = 0;
  if (text) {
    sse(res, 'content_block_start', { type: 'content_block_start', index: idx, content_block: { type: 'text', text: '' } });
    sse(res, 'content_block_delta', { type: 'content_block_delta', index: idx, delta: { type: 'text_delta', text } });
    sse(res, 'content_block_stop', { type: 'content_block_stop', index: idx });
    idx++;
  }
  for (const c of calls) {
    const fn = c.function || {};
    const args = typeof fn.arguments === 'string' ? fn.arguments : JSON.stringify(fn.arguments || {});
    sse(res, 'content_block_start', { type: 'content_block_start', index: idx,
      content_block: { type: 'tool_use', id: 'toolu_' + Math.random().toString(16).slice(2, 14), name: fn.name, input: {} } });
    sse(res, 'content_block_delta', { type: 'content_block_delta', index: idx,
      delta: { type: 'input_json_delta', partial_json: args } });
    sse(res, 'content_block_stop', { type: 'content_block_stop', index: idx });
    idx++;
  }

  sse(res, 'message_delta', { type: 'message_delta',
    delta: { stop_reason: calls.length ? 'tool_use' : 'end_turn', stop_sequence: null },
    usage: { output_tokens: outTok } });
  sse(res, 'message_stop', { type: 'message_stop' });
  res.end();
}).listen(PORT, () => console.log(`think-shim on :${PORT} -> ${UP}/api/chat  think=${THINK}  log=${LOG}`));
