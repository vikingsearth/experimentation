import json, math, os, re, subprocess
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../.tmp/groundcontrol-deck/')
S = R + 'build/'
MD = open(R + 'voice-script.md').read()
blocks = re.split(r'^## ', MD, flags=re.M)[1:]
names = [re.sub(r'^\d+\s+', '', b.splitlines()[0]).strip() for b in blocks]
def caption(b):
  t = ' '.join(l.strip() for l in b.splitlines()[1:] if l.strip()).lower()
  t = t.replace('ground control', 'groundcontrol')
  return re.sub(r"\bi\b|\bi'", lambda m: m.group(0).upper(), t)
L = [[n, caption(b)] for n, b in zip(names, blocks)]
json.dump(L, open(S + 'lines.json', 'w'), indent=1, ensure_ascii=False)
durs = []
for k, (n, line) in enumerate(L, 1):
  a = S + 'gc/project/audio/s%d.mp4' % k
  subprocess.run(['afconvert', '-f', 'mp4f', '-d', 'aac', S + 'cbx_out/s%d.wav' % k, a], check=True)
  out = subprocess.run(['afinfo', a], capture_output=True, text=True).stdout
  d = float([l for l in out.splitlines() if 'estimated duration' in l][0].split()[2]); durs.append(max(9, math.ceil(d) + 2))
  print(k, n, round(d, 1))
js = '[\n' + ',\n'.join('      { name: %s, dur: %d, line: %s }' % (json.dumps(n), d, json.dumps(l)) for (n, l), d in zip(L, durs)) + '\n    ]'
p = S + 'gc/project/Main.dc.html'; s = open(p).read()
a = s.index('scenes() {\n    return [') + len('scenes() {\n    return '); b = s.index('];', a) + 1
open(p, 'w').write(s[:a] + js + s[b:])
p = S + 'gc/project/Script.dc.html'; s = open(p).read()
a = s.index('    const s = ['); b = s.index('    ];', a) + len('    ];')
screens = ['groundcontrol - mission control for my work', 'my work was all over the place', "what's mine, right now?", 'and it tells you what to do next',
           'it keeps itself current', 'only the PRs that name you', 'flight checks for every issue', 'know when your pile clears', 'make it yours', 'all your work, one orbit']
rows = ',\n'.join('      [%s, %s, %s, %s]' % (json.dumps(n), json.dumps('%d s' % d), json.dumps(sc), json.dumps(l)) for (n, l), d, sc in zip(L, durs, screens))
s = s[:a] + '    const s = [\n' + rows + '\n    ];' + s[b:]
open(p, 'w').write(re.sub(r'~\d+ MIN', '~%d MIN' % round(sum(durs) / 60), s))
print(durs, sum(durs))
