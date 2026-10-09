import re
import numpy as np
import librosa
import soundfile as sf

LIMITS = {
  'min_s': 2.0,
  'max_s': 15.0,
  'max_s_free': 20.0,
  'max_s_heldout': 30.0,
  'clip_frac': 1e-4,
  'noise_dbfs': -55.0,
  'speech_lo_dbfs': -32.0,
  'speech_hi_dbfs': -12.0,
  'snr_db': 30.0,
  'pad_s': 0.15,
  'max_wer': 0.15
}

_model = None


def whisper_model():
  global _model
  if _model is None:
    import whisper
    _model = whisper.load_model('small.en')
  return _model


def dbfs(x):
  return float(20 * np.log10(max(float(x), 1e-10)))


def words(text):
  t = text.lower().replace('’', "'")
  return re.sub(r"[^a-z0-9' ]+", ' ', t).split()


def wer(ref, hyp):
  r, h = words(ref), words(hyp)
  prev = list(range(len(h) + 1))
  for i in range(1, len(r) + 1):
    cur = [i] + [0] * len(h)
    for j in range(1, len(h) + 1):
      cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (r[i - 1] != h[j - 1]))
    prev = cur
  return prev[-1] / max(len(r), 1)


def transcribe(y, sr):
  y16 = librosa.resample(y, orig_sr=sr, target_sr=16000).astype(np.float32)
  out = whisper_model().transcribe(y16, language='en', fp16=False, temperature=0, condition_on_previous_text=False)
  return out['text'].strip()


def validate(path, line):
  """Audio gates first, so a bad room fails fast before Whisper runs."""
  y, sr = sf.read(path, dtype='float32')
  if y.ndim > 1:
    y = y.mean(axis=1)
  fails, m = [], {'sr': sr, 'total_s': round(len(y) / sr, 2)}

  clip = float(np.mean(np.abs(y) >= 0.999))
  m['peak_dbfs'] = round(dbfs(np.max(np.abs(y))), 1)
  if clip > LIMITS['clip_frac']:
    fails.append('clipping - move back from the mic or turn the input gain down')

  _, (a, b) = librosa.effects.trim(y, top_db=40, frame_length=2048, hop_length=512)
  speech_s = (b - a) / sr
  m['speech_s'] = round(speech_s, 2)
  max_s = LIMITS['max_s_heldout'] if line['heldout'] else LIMITS['max_s_free'] if line['free'] else LIMITS['max_s']
  if speech_s < LIMITS['min_s']:
    fails.append('too short - %.1f s of speech, needs at least %.0f s' % (speech_s, LIMITS['min_s']))
  if speech_s > max_s:
    fails.append('too long - %.1f s of speech, max is %.0f s' % (speech_s, max_s))
  if a / sr < LIMITS['pad_s'] or (len(y) - b) / sr < LIMITS['pad_s']:
    fails.append('no breathing room - leave a beat of silence before you start and after you finish')

  frames = librosa.feature.rms(y=y, frame_length=2048, hop_length=512)[0]
  noise = dbfs(np.percentile(frames, 10))
  speech = dbfs(np.sqrt(np.mean(y[a:b] ** 2))) if b > a else -100.0
  m.update(noise_dbfs=round(noise, 1), speech_dbfs=round(speech, 1), snr_db=round(speech - noise, 1))
  if noise > LIMITS['noise_dbfs']:
    fails.append('noisy room - background at %.0f dBFS, needs under %.0f (fan, aircon, traffic?)' % (noise, LIMITS['noise_dbfs']))
  if speech < LIMITS['speech_lo_dbfs']:
    fails.append('too quiet - move closer or turn the input gain up')
  if speech > LIMITS['speech_hi_dbfs']:
    fails.append('too hot - move back a little')
  if speech - noise < LIMITS['snr_db']:
    fails.append('voice not far enough above the background (%.0f dB, needs %.0f)' % (speech - noise, LIMITS['snr_db']))

  heard = transcribe(y, sr) if not fails else ''
  m['heard'] = heard
  if heard and not line['free']:
    m['wer'] = round(wer(line['text'], heard), 3)
    if m['wer'] > LIMITS['max_wer']:
      fails.append('read differs from the script - heard "%s"' % heard)

  return {'ok': not fails, 'fails': fails, 'metrics': m}
