import sys,json
for l in sys.stdin:
    l=l.strip()
    if l.startswith('{'):
        d=json.loads(l); print(d['t'],(d['x'],d['y']),d['n'],d['hp'],d['ride'],d['hh'],'Lv',d['lv'],'k',d['k'],'cb',d['cb'],d['cbMax'],'mg',d['mg'],'cap',d['cap'],'al',d.get('al'),'home',d['home'],d['vil'],d['tgt'],d['boss'],d['sk'])
    else: print(l[:700])
