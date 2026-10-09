import json, os, re, shutil, sys, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse
import validate

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, '../../../.tmp/voice-finetune'))
DECK = os.path.normpath(os.path.join(HERE, '../../../.tmp/groundcontrol-deck/voice-script.md'))
SCRIPT = os.path.join(HERE, '../script/batch-1.md')
MANIFEST = os.path.join(DATA, 'manifest.jsonl')
PORT = int(os.environ.get('PORT', 8797))
lock = threading.Lock()


def load_lines():
  """One `id | text` per line under `## category` headings; a heading containing `held-out` keeps its lines out of training."""
  lines, cat = [], None
  for raw in open(SCRIPT, encoding='utf-8'):
    h = re.match(r'^## (.+)$', raw)
    if h:
      cat = h.group(1).strip()
      continue
    l = re.match(r'^(\w+) \| (.+)$', raw.strip())
    if l and cat:
      lines.append({'id': l.group(1), 'text': l.group(2), 'category': cat,
                    'heldout': 'held-out' in cat, 'free': cat.startswith('free talk')})
  if os.path.exists(DECK):
    for n, block in enumerate(re.split(r'^## ', open(DECK, encoding='utf-8').read(), flags=re.M)[1:], 1):
      text = ' '.join(x.strip() for x in block.splitlines()[1:] if x.strip())
      lines.append({'id': 'deck%02d' % n, 'text': text, 'category': 'deck (held-out)', 'heldout': True, 'free': False})
  return lines


def read_manifest():
  if not os.path.exists(MANIFEST):
    return []
  return [json.loads(x) for x in open(MANIFEST, encoding='utf-8') if x.strip()]


def state():
  status = {}
  for r in read_manifest():
    if r['status'] == 'accepted' or status.get(r['id'], {}).get('status') != 'accepted':
      status[r['id']] = r
  out = []
  for l in load_lines():
    r = status.get(l['id'])
    out.append({**l, 'status': r['status'] if r else 'pending', 'last': r})
  return out


def next_take(id):
  d = os.path.join(DATA, 'takes', id)
  os.makedirs(d, exist_ok=True)
  return os.path.join(d, '%03d.wav' % (len(os.listdir(d)) + 1))


def accept(rec, transcript):
  os.makedirs(os.path.join(DATA, 'clips'), exist_ok=True)
  shutil.copyfile(rec['take'], os.path.join(DATA, 'clips', rec['id'] + '.wav'))
  rec.update(status='accepted', transcript=transcript)


def append(rec):
  with open(MANIFEST, 'a', encoding='utf-8') as f:
    f.write(json.dumps(rec, ensure_ascii=False) + '\n')


class Handler(BaseHTTPRequestHandler):
  def log_message(self, *a):
    pass

  def send(self, code, body, ctype='application/json'):
    data = body if isinstance(body, bytes) else json.dumps(body).encode()
    self.send_response(code)
    self.send_header('Content-Type', ctype)
    self.send_header('Content-Length', str(len(data)))
    self.end_headers()
    self.wfile.write(data)

  def do_GET(self):
    u = urlparse(self.path)
    if u.path == '/':
      return self.send(200, open(os.path.join(HERE, 'index.html'), 'rb').read(), 'text/html; charset=utf-8')
    if u.path == '/api/state':
      return self.send(200, state())
    if u.path == '/api/take':
      q = parse_qs(u.query)
      p = os.path.join(DATA, 'takes', os.path.basename(q['id'][0]), os.path.basename(q['take'][0]))
      return self.send(200, open(p, 'rb').read(), 'audio/wav') if os.path.exists(p) else self.send(404, {})
    self.send(404, {})

  def do_POST(self):
    u = urlparse(self.path)
    q = parse_qs(u.query)
    lines = {l['id']: l for l in load_lines()}
    line = lines.get(q.get('id', [''])[0])
    if not line:
      return self.send(404, {'error': 'unknown line'})
    body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
    with lock:
      if u.path == '/api/validate':
        path = next_take(line['id'])
        open(path, 'wb').write(body)
        res = validate.validate(path, line)
        rec = {'id': line['id'], 'take': path, 'ts': time.strftime('%Y-%m-%dT%H:%M:%S'),
               'status': 'rejected', 'fails': res['fails'], 'metrics': res['metrics']}
        if res['ok']:
          accept(rec, res['metrics']['heard'] if line['free'] else line['text'])
        append(rec)
        return self.send(200, {**rec, 'take': os.path.basename(path)})
      if u.path == '/api/override':
        # Human call on a near-miss read, e.g. a natural contraction; the manifest keeps the flag.
        take = os.path.join(DATA, 'takes', line['id'], os.path.basename(q['take'][0]))
        prev = [r for r in read_manifest() if r['take'] == take][-1]
        rec = {**prev, 'ts': time.strftime('%Y-%m-%dT%H:%M:%S'), 'overridden': True}
        text = json.loads(body or b'{}').get('transcript') or (prev['metrics'].get('heard') if line['free'] else line['text'])
        accept(rec, text)
        append(rec)
        return self.send(200, {**rec, 'take': os.path.basename(take)})
    self.send(404, {})


if __name__ == '__main__':
  os.makedirs(DATA, exist_ok=True)
  print('loading whisper...', flush=True)
  validate.whisper_model()
  print('recorder on http://127.0.0.1:%d - data in %s' % (PORT, DATA), flush=True)
  ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
