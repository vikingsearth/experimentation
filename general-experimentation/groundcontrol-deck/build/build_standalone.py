import base64, json, os, re, sys

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../.tmp/groundcontrol-deck/build/gc/project/')
OUT = sys.argv[1]
ACCENT = '#FFB020'

src = open(D + 'Main.dc.html').read()
helmet = re.search(r'<helmet>(.*?)</helmet>', src, re.S).group(1)
scenes_js = re.search(r'scenes\(\) \{\s*return (\[.*?\]);', src, re.S).group(1)

def sub_tokens(s):
  return s.replace('{{accentSoft}}', ACCENT + '66').replace('{{accent}}', ACCENT)

scenes = []
for n in range(1, 11):
  m = re.search(r'<sc-if value="\{\{s%d\}\}"[^>]*>(.*?)</sc-if>' % n, src, re.S)
  scenes.append(sub_tokens(m.group(1)))

# compliance grid, pre-rendered
P = {'ok': ('OK', '#3DD6C4', 'rgba(61,214,196,.12)'), 'missing': ('MISSING', '#FF6B6B', 'rgba(255,107,107,.13)'),
     'na': ('N/A', '#8A98A8', 'rgba(125,138,153,.12)'), 'blocked': ('BLOCKED', ACCENT, 'rgba(255,176,32,.13)')}
grid = [('epic', ['ok', 'na', 'ok', 'ok', 'ok']), ('feature', ['ok', 'ok', 'missing', 'ok', 'ok']),
        ('bug', ['ok', 'ok', 'ok', 'missing', 'ok']), ('task', ['ok', 'missing', 'ok', 'ok', 'missing']),
        ('untyped', ['missing', 'ok', 'blocked', 'ok', 'ok'])]
rows = ''
for r, (name, states) in enumerate(grid):
  cells = ''.join(
    '<span class="mono pop" style="text-align: center; font-size: 18px; letter-spacing: .1em; padding: 12px 0; border-radius: 10px; '
    'color: %s; background: %s; animation-delay: %.2fs">%s</span>' % (P[st][1], P[st][2], 1.2 + (r * 5 + c) * 0.11, P[st][0])
    for c, st in enumerate(states))
  rows += ('<div style="display: grid; grid-template-columns: 170px repeat(5, minmax(0, 1fr)); gap: 12px; align-items: center; '
           'padding: 14px 4px; border-top: 1px solid #1A232D"><span style="font-size: 26px; font-weight: 500">%s</span>%s</div>') % (name, cells)
scenes[6] = re.sub(r'<sc-for list="\{\{rows\}\}".*?</sc-for>\s*</div>\s*</sc-for>', rows, scenes[6], flags=re.S)
assert '{{' not in ''.join(scenes), [s for s in scenes if '{{' in s][0][:200]

audio = []
for n in range(1, 11):
  b = base64.b64encode(open(D + 'audio/s%d.mp4' % n, 'rb').read()).decode()
  audio.append('data:audio/mp4;base64,' + b)

templates = ''.join('<template id="t%d">%s</template>\n' % (k + 1, s) for k, s in enumerate(scenes))
icon = '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="13" cy="13" r="11"></circle><circle cx="13" cy="13" r="6"></circle><path d="M13 13 L22 6"></path></svg>'

html = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>groundcontrol</title>
%(helmet)s
<style>
html,body{height:100%%;margin:0;background:#07090C;overflow:hidden}
#fit{position:fixed;inset:0;display:flex;align-items:center;justify-content:center}
#stage{position:relative;width:1920px;height:1080px;flex:none;transform-origin:center center}
.gc button{font-family:inherit}
.ctl:focus-visible,.seg:focus-visible,.start:focus-visible{outline:2px solid %(accent)s;outline-offset:3px}
.hide{display:none!important}
.hint{position:absolute;right:140px;bottom:112px;font-size:15px;letter-spacing:.14em;color:#6F7D8C}
</style>
</head>
<body>
<div id="fit"><div id="stage" class="gc" style="overflow: hidden; background: #07090C">
<div class="grid"></div>
<div class="scan"></div>
<div class="mono" style="position: absolute; top: 48px; left: 140px; right: 140px; display: flex; justify-content: space-between; align-items: center; font-size: 18px; letter-spacing: .28em; color: #8A98A8; z-index: 2">
<div style="display: flex; align-items: center; gap: 14px">%(icon)s<span style="color: #E8EDF2">GROUNDCONTROL</span></div>
<div style="display: flex; align-items: center; gap: 28px"><span><span id="no">01</span> / 10 &#160;·&#160; <span id="name">STANDBY</span></span>
<span style="display: flex; align-items: center; gap: 10px; color: #3DD6C4"><span class="blink" style="width: 10px; height: 10px; border-radius: 999px; background: #3DD6C4"></span>LIVE</span></div>
</div>
<div id="scene" style="position: absolute; inset: 0"></div>

<div id="intro" style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 28px; z-index: 5">
<div class="fade" style="position: relative; width: 200px; height: 200px">
<div style="position: absolute; inset: 0; border-radius: 999px; border: 1px solid rgba(140,170,200,.3)"></div>
<div style="position: absolute; inset: 52px; border-radius: 999px; border: 1px solid rgba(140,170,200,.24)"></div>
<div class="spin" style="position: absolute; inset: 0; border-radius: 999px; background: conic-gradient(from 0deg, transparent 0deg, transparent 280deg, %(accent)s66 360deg)"></div>
</div>
<div class="mono rise d1" style="font-size: 22px; letter-spacing: .32em; color: #8A98A8">GROUNDCONTROL · STANDING BY</div>
<div class="rise d2" style="display: flex; gap: 20px; margin-top: 12px">
<button class="start" id="go-sound" style="height: 72px; padding: 0 40px; border-radius: 999px; border: 0; background: %(accent)s; color: #07090C; font-family: 'IBM Plex Mono', monospace; font-size: 22px; letter-spacing: .14em; font-weight: 500; cursor: pointer">PLAY WITH SOUND</button>
<button class="start" id="go-silent" style="height: 72px; padding: 0 40px; border-radius: 999px; border: 1px solid #2A3644; background: #0F141A; color: #E8EDF2; font-family: 'IBM Plex Mono', monospace; font-size: 22px; letter-spacing: .14em; cursor: pointer">PLAY SILENT</button>
</div>
<div class="mono rise d3" style="margin-top: 18px; font-size: 16px; letter-spacing: .14em; color: #6F7D8C">SPACE play/pause · ARROWS skip · F fullscreen · C captions</div>
</div>

<div id="cap" class="hide" style="position: absolute; left: 50%%; bottom: 124px; transform: translateX(-50%%); max-width: 1300px; padding: 16px 28px; border-radius: 14px; background: rgba(7,9,12,.86); border: 1px solid #1E2833; font-size: 27px; line-height: 1.4; color: #E8EDF2; text-align: center; z-index: 3"></div>

<div style="position: absolute; left: 140px; right: 140px; bottom: 36px; height: 56px; display: flex; align-items: center; gap: 14px; z-index: 4">
<button class="ctl" id="prev" aria-label="Previous scene"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6 L9 12 L15 18"></path></svg></button>
<button class="ctl" id="play" aria-label="Play"><svg id="i-pause" class="hide" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 6 V18 M15 6 V18"></path></svg><svg id="i-play" width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5 L19 12 L8 19 Z"></path></svg></button>
<button class="ctl" id="next" aria-label="Next scene"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6 L15 12 L9 18"></path></svg></button>
<button class="ctl mono" id="voice" aria-pressed="false" style="width: auto; padding: 0 20px; gap: 10px; font-size: 15px; letter-spacing: .16em; color: #A9B6C4"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10 V14 M8 7 V17 M12 4 V20 M16 8 V16 M20 11 V13"></path></svg><span id="vlabel">VOICE OFF</span></button>
<button class="ctl" id="fs" aria-label="Fullscreen"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9 V4 H9 M15 4 H20 V9 M20 15 V20 H15 M9 20 H4 V15"></path></svg></button>
<div id="segs" style="flex: 1; display: flex; gap: 8px; margin-left: 12px"></div>
</div>
</div></div>

%(templates)s
<script>
const SCENES = %(scenes)s;
const AUDIO = %(audio)s;
const ACCENT = '%(accent)s';
const $ = (id) => document.getElementById(id);
const st = { started: false, i: 0, playing: false, voice: false, captions: true, done: false };
let timer = null, tok = 0, cur = null;
const clips = AUDIO.map((src) => { const a = new Audio(src); a.preload = 'auto'; return a; });

function fit() {
  const s = Math.min(innerWidth / 1920, innerHeight / 1080);
  $('stage').style.transform = 'scale(' + s + ')';
}
addEventListener('resize', fit);
fit();

SCENES.forEach((s, k) => {
  const b = document.createElement('button');
  b.className = 'seg';
  b.setAttribute('aria-label', 'Go to scene ' + (k + 1) + ': ' + s.name.toLowerCase());
  b.innerHTML = '<div class="track" style="position: relative; width: 100%%; height: 4px; border-radius: 2px; background: #1E2833; overflow: hidden"><div class="f" style="position: absolute; left: 0; top: 0; bottom: 0; width: 0; background: ' + ACCENT + '"></div></div>';
  b.onclick = () => set({ started: true, i: k, playing: true, done: false });
  $('segs').appendChild(b);
});

function stopAudio() {
  if (cur) { cur.onended = null; cur.pause(); cur = null; }
}

function render(sceneChanged) {
  $('intro').classList.toggle('hide', st.started);
  $('no').textContent = String(st.i + 1).padStart(2, '0');
  $('name').textContent = st.started ? SCENES[st.i].name : 'STANDBY';
  if (sceneChanged) {
    const host = $('scene');
    host.innerHTML = '';
    if (st.started) host.appendChild($('t' + (st.i + 1)).content.cloneNode(true));
  }
  const on = st.started && st.playing;
  $('i-play').classList.toggle('hide', on);
  $('i-pause').classList.toggle('hide', !on);
  $('play').setAttribute('aria-label', st.done ? 'Replay from the start' : (on ? 'Pause' : 'Play'));
  $('vlabel').textContent = st.voiceErr ? 'VOICE BLOCKED' : (st.voice ? 'VOICE ON' : 'VOICE OFF');
  $('voice').style.color = st.voice ? ACCENT : '#A9B6C4';
  $('voice').setAttribute('aria-pressed', String(st.voice));
  const cap = $('cap');
  cap.textContent = SCENES[st.i].line;
  cap.classList.toggle('hide', !(st.started && st.voice && st.captions));
  [...$('segs').children].forEach((b, k) => {
    const f = b.querySelector('.f');
    if (!st.started || k > st.i) { f.style.animation = 'none'; f.style.width = '0'; }
    else if (k < st.i) { f.style.animation = 'none'; f.style.width = '100%%'; }
    else {
      if (sceneChanged) { f.style.animation = 'none'; void f.offsetWidth; f.style.width = ''; f.style.animation = 'fill ' + SCENES[k].dur + 's linear both'; }
      f.style.animationPlayState = on ? 'running' : 'paused';
    }
  });
}

function schedule() {
  clearTimeout(timer);
  const t = ++tok;
  stopAudio();
  if (!st.started || !st.playing) return;
  const ms = SCENES[st.i].dur * 1000;
  if (!st.voice) { timer = setTimeout(() => go(1), ms); return; }
  const a = clips[st.i];
  a.currentTime = 0;
  a.onended = () => { if (t !== tok) return; clearTimeout(timer); timer = setTimeout(() => go(1), 1400); };
  cur = a;
  timer = setTimeout(() => { if (t === tok) go(1); }, ms + 10000);
  a.play().catch(() => {
    if (t !== tok) return;
    clearTimeout(timer);
    st.voiceErr = true;
    render(false);
    timer = setTimeout(() => go(1), ms);
  });
}

function set(patch) {
  const prev = { ...st };
  Object.assign(st, patch);
  const sceneChanged = prev.i !== st.i || prev.started !== st.started;
  render(sceneChanged);
  if (sceneChanged || prev.playing !== st.playing || prev.voice !== st.voice) schedule();
}

function go(d) {
  const j = st.i + d;
  if (j >= SCENES.length) { set({ playing: false, done: true }); return; }
  if (j < 0) return;
  set({ i: j, done: false });
}

function togglePlay() {
  if (!st.started) set({ started: true, i: 0, playing: true });
  else if (st.done) set({ i: 0, playing: true, done: false });
  else set({ playing: !st.playing });
}

function fullscreen() {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen().catch(() => {});
}

$('go-sound').onclick = () => set({ started: true, i: 0, playing: true, voice: true, voiceErr: false, done: false });
$('go-silent').onclick = () => set({ started: true, i: 0, playing: true, voice: false, done: false });
$('prev').onclick = () => go(-1);
$('next').onclick = () => go(1);
$('play').onclick = togglePlay;
$('voice').onclick = () => set({ voice: !st.voice, voiceErr: false, started: true, playing: true, done: false });
$('fs').onclick = fullscreen;
addEventListener('keydown', (e) => {
  if (e.key === ' ' || e.key === 'k') { e.preventDefault(); togglePlay(); }
  else if (e.key === 'ArrowRight') { if (!st.started) set({ started: true, playing: true }); else go(1); }
  else if (e.key === 'ArrowLeft') go(-1);
  else if (e.key === 'f') fullscreen();
  else if (e.key === 'c') set({ captions: !st.captions });
  else if (e.key === 'm') set({ voice: !st.voice, voiceErr: false });
});
render(true);
</script>
</body>
</html>
''' % {'helmet': helmet, 'accent': ACCENT, 'icon': icon, 'templates': templates,
       'scenes': scenes_js, 'audio': json.dumps(audio)}

open(OUT, 'w').write(html)
print(OUT, len(html) // 1024, 'KB')
