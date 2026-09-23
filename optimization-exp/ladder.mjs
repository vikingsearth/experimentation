#!/usr/bin/env node
// The full tier ladder across every arm run so far.
//   node ladder.mjs            markdown tables
//   node ladder.mjs --json
// Read-only. Recomputes everything from the reports on disk.

import { readFileSync, existsSync, readdirSync } from 'node:fs';

const REPO = '/Users/wikus.bergh/dev/experimentation';
const SRC  = `${REPO}/general-experimentation/agentic-workflows/src`;
const BRIEFS = ['01-data-model', '02-policy-thresholds', '03-risk-and-budget', '04-state-and-audit', '05-presentation-and-docs'];

const ARMS = [
  ['A Haiku',            'optimization-exp/hyp2/reports/arm-a-haiku',                 'cloud'],
  ['B Sonnet',           'optimization-exp/hyp2/reports/arm-b-sonnet',                'cloud'],
  ['C qwen3 run1',       'optimization-exp/hyp2-1/reports/arm-c-qwen3-8b-40k-run01',  'local'],
  ['C qwen3 run2',       'optimization-exp/hyp2-1/reports/arm-c-qwen3-8b-40k-run02',  'local'],
  ['D gemma think-on',   'optimization-exp/hyp2-1/reports/arm-d-gemma4-12b-40k',      'local'],
  ['D2 gemma think-off', 'optimization-exp/hyp2-1/reports/arm-d2-gemma-nothink',      'local'],
  ['E devstral:24b',     'optimization-exp/hyp5/reports/arm-e-devstral',              'local'],
];

const src = Object.fromEntries(readdirSync(SRC).filter(f => f.endsWith('.py'))
  .map(f => [f, readFileSync(`${SRC}/${f}`, 'utf8').split('\n')]));

// Per-brief notion of "a line that actually carries what the brief asked about".
const ON_TARGET = {
  '01-data-model':            /\d+\.\d+|monthly_budget|max_single|requires_pre|receipt_required|amount|auto_approve|can_approve|total_30|largest_single|spent_this|allocated/,
  '02-policy-thresholds':     /[<>]=?|max_single|requires_pre|receipt_required|auto_approve|amount|threshold|per_person|alcohol/,
  '03-risk-and-budget':       /[<>+\-*/]=?|score|ratio|util|budget|total|amount|spent|monthly|flag/,
  '04-state-and-audit':       /limit|amount|expense|snapshot|audit|log|detail|currency|budget|float|deepcopy/,
  '05-presentation-and-docs': /print|f"|format|\$|amount|summary|table|rationale|observation/,
};

const cites = path => {
  if (!existsSync(path)) return null;
  const txt = readFileSync(path, 'utf8');
  const out = new Set();
  for (const m of txt.matchAll(/\*\*Location\*\*:\s*(.+)/g))
    for (const fm of m[1].matchAll(/(\w+\.py)[`\s]*:\s*([0-9,\s\-–]+)/g))
      for (const n of fm[2].match(/\d+/g) || []) out.add(`${fm[1]}:${n}`);
  return { set: out, words: txt.split(/\s+/).length, findings: (txt.match(/^### F/gm) || []).length };
};

const classify = (key, brief) => {
  const [f, n] = key.split(':');
  if (!src[f] || +n > src[f].length) return 'fabricated';
  return ON_TARGET[brief].test(src[f][+n - 1]) ? 'ontarget' : 'offtarget';
};

const metrics = dir => {
  const p = `${REPO}/${dir}/_metrics.tsv`;
  if (!existsSync(p)) return {};
  const [head, ...rows] = readFileSync(p, 'utf8').trim().split('\n');
  const cols = head.split('\t');
  const out = {};
  for (const r of rows) {
    const o = Object.fromEntries(r.split('\t').map((v, i) => [cols[i], v]));
    if (!out[o.brief] || o.status === 'ok') out[o.brief] = o;   // prefer the successful attempt
  }
  return out;
};

const data = {};
for (const [name, dir] of ARMS) {
  data[name] = { dir, briefs: {}, m: metrics(dir) };
  for (const b of BRIEFS) data[name].briefs[b] = cites(`${REPO}/${dir}/${b}.md`);
}

// The reference set: what the two cloud arms found between them, per brief.
const UNION = {};
for (const b of BRIEFS) {
  UNION[b] = new Set([...(data['A Haiku'].briefs[b]?.set || []), ...(data['B Sonnet'].briefs[b]?.set || [])]);
}

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({ data, union: Object.fromEntries(Object.entries(UNION).map(([k, v]) => [k, [...v]])) }, null, 1));
  process.exit(0);
}

console.log('## Per-arm totals\n');
console.log('| Arm | Briefs done | Citations | On target | Fabricated | Coverage vs cloud union | Words | Wall |');
console.log('|---|---|---|---|---|---|---|---|');
for (const [name, dir, kind] of ARMS) {
  const d = data[name];
  const done = BRIEFS.filter(b => d.briefs[b]);
  let cites = 0, on = 0, fab = 0, hit = 0, tot = 0, words = 0;
  for (const b of done) {
    for (const k of d.briefs[b].set) {
      cites++;
      const c = classify(k, b);
      if (c === 'ontarget') on++; else if (c === 'fabricated') fab++;
      if (UNION[b].has(k)) hit++;
    }
    tot += UNION[b].size; words += d.briefs[b].words;
  }
  const wall = Object.values(d.m).reduce((a, r) => a + (+r.wall_s || Math.round((+r.duration_ms || 0) / 1000)), 0);
  const wtxt = wall ? (wall >= 600 ? `${(wall / 60).toFixed(0)} min` : `${wall}s`) : 'n/a';
  console.log(`| ${name} | ${done.length}/5 | ${cites} | ${on} | ${fab ? `**${fab}**` : 0} | ${hit}/${tot} = ${tot ? (100 * hit / tot).toFixed(0) : 0}% | ${words.toLocaleString()} | ${wtxt} |`);
}

console.log('\n## Coverage by brief (% of what the cloud arms found)\n');
console.log(`| Arm | ${BRIEFS.map(b => b.slice(0, 2)).join(' | ')} |`);
console.log(`|---|${BRIEFS.map(() => '---|').join('')}`);
for (const [name] of ARMS) {
  const cells = BRIEFS.map(b => {
    const d = data[name].briefs[b];
    if (!d) return '-';
    const u = UNION[b];
    return u.size ? `${(100 * [...d.set].filter(k => u.has(k)).length / u.size).toFixed(0)}%` : '-';
  });
  console.log(`| ${name} | ${cells.join(' | ')} |`);
}

console.log('\n## Wall clock by brief\n');
console.log(`| Arm | ${BRIEFS.map(b => b.slice(0, 2)).join(' | ')} |`);
console.log(`|---|${BRIEFS.map(() => '---|').join('')}`);
for (const [name] of ARMS) {
  const cells = BRIEFS.map(b => {
    const r = data[name].m[b];
    if (!r) return '-';
    const s = +r.wall_s || Math.round((+r.duration_ms || 0) / 1000);
    if (!s) return '-';
    return (r.status === 'ok' || !r.status) ? (s >= 600 ? `${(s / 60).toFixed(0)}m` : `${s}s`) : `**${r.status}**`;
  });
  console.log(`| ${name} | ${cells.join(' | ')} |`);
}
