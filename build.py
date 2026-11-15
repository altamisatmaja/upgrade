"""Validate data.txt, then generate opportunities.csv, data.json and DATABASE.md.
Exits 1 on any malformed row so the automation never commits bad data."""
import csv, json, re, sys, collections

HDR = ['category', 'name', 'country', 'type', 'summary', 'window', 'status', 'fit', 'link', 'checked_on']
rows, errs, seen = [], [], {}
for i, line in enumerate(open('data.txt', encoding='utf-8'), 1):
    s = line.strip()
    if not s or s.startswith('#'):
        continue
    p = [x.strip() for x in s.split('|')]
    if len(p) != len(HDR):
        errs.append(f'line {i}: {len(p)} fields, expected {len(HDR)}'); continue
    r = dict(zip(HDR, p))
    if r['status'] not in ('V', 'C'): errs.append(f'line {i}: status must be V or C')
    if r['fit'] not in ('1', '2', '3'): errs.append(f'line {i}: fit must be 1-3')
    if not r['link'].startswith('https://'): errs.append(f'line {i}: link must start with https://')
    if r['checked_on'] and not re.fullmatch(r'\d{4}-\d{2}-\d{2}', r['checked_on']):
        errs.append(f'line {i}: checked_on must be YYYY-MM-DD')
    if r['status'] == 'V' and not r['checked_on']: errs.append(f'line {i}: status V needs checked_on')
    key = r['name'].lower()
    if key in seen: errs.append(f'line {i}: duplicate name of line {seen[key]} ({r["name"]})')
    seen[key] = i
    rows.append(r)

# details.json: {name: {who, covers, dates, apply, bond, checked_on}} written in our own words
DKEYS = ['who', 'covers', 'dates', 'apply', 'bond', 'checked_on']
try:
    details = json.load(open('details.json', encoding='utf-8'))
except FileNotFoundError:
    details = {}
except json.JSONDecodeError as e:
    errs.append(f'details.json: invalid JSON ({e})'); details = {}
names = {r['name'] for r in rows}
for k, d in details.items():
    if k not in names: errs.append(f'details.json: "{k}" does not match any name in data.txt')
    if not isinstance(d, dict) or set(d) != set(DKEYS):
        errs.append(f'details.json: "{k}" must have exactly the keys {DKEYS}'); continue
    if not all(isinstance(v, str) for v in d.values()): errs.append(f'details.json: "{k}" values must be strings')
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', d['checked_on']): errs.append(f'details.json: "{k}" checked_on must be YYYY-MM-DD')
for r in rows:
    if r['name'] in details: r['details'] = details[r['name']]

if errs:
    print('INVALID DATA:\n' + '\n'.join(errs)); sys.exit(1)

with open('opportunities.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=HDR, extrasaction='ignore'); w.writeheader(); w.writerows(rows)

nV = sum(r['status'] == 'V' for r in rows)
last = max((r['checked_on'] for r in rows if r['checked_on']), default='')
with open('data.json', 'w', encoding='utf-8') as f:
    json.dump({'updated': last, 'total': len(rows), 'verified': nV, 'detailed': len(details), 'rows': rows}, f, ensure_ascii=False)

g = collections.OrderedDict()
for r in rows: g.setdefault(r['category'], []).append(r)
out = ['# Opportunity Database (generated from data.txt)\n',
       f'Total: **{len(rows)}** entries | ✅ verified on the web: {nV} | ⚠️ needs re-checking: {len(rows)-nV} | last update: {last}\n',
       'Fit: ★★★ = strong fit for a software / AI / robotics engineer and founder\n']
for k, rs in g.items():
    rs = sorted(rs, key=lambda r: -int(r['fit']))
    out.append(f'\n## {k} ({len(rs)})\n\n| Fit | Name | Country | Type | Summary | Window | Status |\n|---|---|---|---|---|---|---|')
    for r in rs:
        st = f"✅ {r['checked_on']}" if r['status'] == 'V' else '⚠️ check'
        out.append(f"| {'★'*int(r['fit'])} | [{r['name']}]({r['link']}) | {r['country']} | {r['type']} | {r['summary']} | {r['window']} | {st} |")
with open('DATABASE.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out) + '\n')
print(f'OK {len(rows)} entries, {nV} verified, {len(details)} detailed, {len(g)} categories')
