#!/usr/bin/env node
// Transparent proxy in front of ollama. Logs what the harness sends, forwards
// unchanged, logs what comes back. Used once, to design the real shim against
// observed traffic rather than assumed traffic.
import { createServer } from 'node:http';
import { appendFileSync } from 'node:fs';

const UP = 'http://localhost:11434';
const LOG = '/tmp/shim-spy.log';
const note = (...a) => appendFileSync(LOG, a.join(' ') + '\n');

createServer(async (req, res) => {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const body = Buffer.concat(chunks).toString();

  let parsed = null;
  try { parsed = JSON.parse(body); } catch {}
  note(`\n=== ${req.method} ${req.url} ===`);
  if (parsed) {
    note('keys:', Object.keys(parsed).join(','));
    note('stream:', JSON.stringify(parsed.stream));
    note('tools:', parsed.tools ? `${parsed.tools.length} -> ${parsed.tools.map(t => t.name || t.function?.name).join(',')}` : 'none');
    note('tool shape:', parsed.tools?.[0] ? JSON.stringify(parsed.tools[0]).slice(0, 300) : '-');
    note('messages:', parsed.messages?.length);
    note('last msg:', JSON.stringify(parsed.messages?.at(-1)).slice(0, 400));
    note('system:', JSON.stringify(parsed.system)?.slice(0, 150));
  } else note('non-json body, bytes:', body.length);

  const up = await fetch(UP + req.url, {
    method: req.method,
    headers: { ...req.headers, host: 'localhost:11434' },
    body: ['GET', 'HEAD'].includes(req.method) ? undefined : body,
  });

  const ct = up.headers.get('content-type') || '';
  res.writeHead(up.status, { 'content-type': ct });
  if (ct.includes('event-stream')) {
    note('<- streaming response');
    let first = true;
    for await (const c of up.body) {
      if (first) { note('first SSE bytes:', c.toString().slice(0, 300)); first = false; }
      res.write(c);
    }
    res.end();
  } else {
    const txt = await up.text();
    note('<- ', up.status, txt.slice(0, 400));
    res.end(txt);
  }
}).listen(11435, () => console.log('spy on :11435 -> 11434, log at ' + LOG));
