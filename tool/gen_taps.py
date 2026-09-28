"""يولّد «مشية الضغط»: بيفتح كل شاشة و**يدوس كل زرار فيها**.

ليه أداة تانية غير مسح المقاسات: الحوارات والشيتات **مابتتبنيش إلا لمّا حد
يدوس** — فمسح الشاشات مابيوصلهاش خالص. دى بتدوس فعلاً وبتمسك القصّ اللى
جوّه الحوار.
"""
import io
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
SEP = os.sep

SKIP = {'MushafScreen', 'MushafPageScreen'}

entries = []
for root, _, files in os.walk('lib/screens'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        p = os.path.join(root, f).replace(SEP, '/')
        s = io.open(p, encoding='utf-8').read()
        for m in re.finditer(
                r'^class ([A-Z][A-Za-z0-9_]*) extends (Stateless|Stateful)Widget',
                s, re.M):
            cls = m.group(1)
            cm = re.search(r'\n\s*const %s\(([^)]*)\)' % re.escape(cls), s)
            if not cm:
                cm = re.search(r'\n\s*%s\(([^)]*)\)' % re.escape(cls), s)
            args = cm.group(1) if cm else ''
            if 'required' in args or cls in SKIP:
                continue
            const = bool(cm and ('const %s(' % cls) in cm.group(0))
            entries.append((cls, p, const))

entries.sort()
seen = {}
uniq = []
for cls, p, const in entries:
    pref = 'w%d' % len(uniq) if cls in seen else None
    seen[cls] = p
    uniq.append((cls, p, const, pref))

imports = {}
for cls, p, const, pref in uniq:
    imports.setdefault(p, pref)

imp_lines = []
for p in sorted(imports):
    pref = imports[p]
    lib = 'package:my_assistant/%s' % p[len('lib/'):]
    imp_lines.append("import '%s'%s;" % (lib, (' as %s' % pref) if pref else ''))

test_lines = []
for cls, p, const, pref in uniq:
    name = cls if not pref else '%s (%s)' % (cls, p.split('/')[-2])
    ctor = '%s%s%s()' % ('const ' if const else '',
                         ('%s.' % pref) if pref else '', cls)
    test_lines.append(
        "  testWidgets('%s', (t) => tapWalk(t, () => %s));" % (name, ctor))

TEMPLATE = io.open('tool/taps_template.dart', encoding='utf-8').read()
out = (TEMPLATE
       .replace('// __IMPORTS__', '\n'.join(imp_lines))
       .replace('  // __TESTS__', '\n'.join(test_lines)))
io.open('tool/taps_test.dart', 'w', encoding='utf-8', newline='\n').write(out)
print('مشية الضغط:', len(uniq), 'شاشة × مقاسين')
