import os, re, sys, warnings
warnings.filterwarnings('ignore')
import librosa, torch, torchaudio
from chatterbox.tts import ChatterboxTTS
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../.tmp/groundcontrol-deck/')
MD = open(R + 'voice-script.md').read()
cfg = {k: float(v) for k, v in re.findall(r'(\w+) ([\d.]+)', re.search(r'^settings:(.*)$', MD, re.M).group(1))}
L = [' | '.join(l.strip() for l in b.splitlines()[1:] if l.strip()) for b in re.split(r'^## ', MD, flags=re.M)[1:]]
dev = 'mps' if torch.backends.mps.is_available() else 'cpu'
_load = torch.load
torch.load = lambda *a, **k: _load(*a, **{**k, 'map_location': torch.device(dev)})
m = ChatterboxTTS.from_pretrained(device=dev)
if os.environ.get('VOICE'):
  m.prepare_conditionals(R + 'build/' + os.environ['VOICE'], exaggeration=cfg['exaggeration'])
def say(i):
  torch.manual_seed(int(cfg['seed']) + i)
  parts = []
  for chunk in [c.strip() for c in L[i - 1].split('|') if c.strip()]:
    w = m.generate(chunk, exaggeration=cfg['exaggeration'], cfg_weight=cfg['cfg'], temperature=cfg['temperature'])
    parts += [w, torch.zeros(1, int(m.sr * cfg['gap']))]
  w = torch.cat([torch.zeros(1, int(m.sr * 0.15))] + parts[:-1], dim=1)
  if cfg.get('speed', 1.0) != 1.0:
    w = torch.from_numpy(librosa.effects.time_stretch(w[0].numpy(), rate=cfg['speed'])).unsqueeze(0)
  return w
out = R + 'build/' + sys.argv[1]
idx = [int(x) for x in sys.argv[2].split(',')] if len(sys.argv) > 2 else range(1, len(L) + 1)
os.makedirs(out, exist_ok=True)
print('settings', cfg, 'device', dev, flush=True)
for i in idx:
  torchaudio.save('%s/s%d.wav' % (out, i), say(i), m.sr); print('s%d' % i, flush=True)
