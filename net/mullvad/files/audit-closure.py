"""Read target-filtered cargo metadata; never fetch or modify source files.

Usage: python3 audit-closure.py metadata-openbsd.json [metadata-other.json ...]
Generate inputs with cargo metadata --locked --format-version 1
--filter-platform TARGET. Build/normal edges are followed; dev edges are not.
Metadata feature unification can overestimate features: confirm each binary
with cargo tree -p NAME --target TARGET --edges normal,build -f '{p} {f}'.
"""
import json
from pathlib import Path
import sys

def audit(filename):
    data = json.loads(Path(filename).read_text())
    pkgs = {p['id']: p for p in data['packages']}
    nodes = {n['id']: n for n in data['resolve']['nodes']}

    def closure(name):
        todo = [p['id'] for p in pkgs.values() if p['name'] == name]
        seen = set()
        while todo:
            key = todo.pop()
            if key in seen:
                continue
            seen.add(key)
            todo.extend(d['pkg'] for d in nodes[key]['deps']
                        if any(k['kind'] in (None, 'build') for k in d['dep_kinds']))
        return seen

    cli, daemon = closure('mullvad-cli'), closure('mullvad-daemon')
    result = {}
    for name, ids in [('cli', cli), ('daemon', daemon), ('shared', cli & daemon)]:
        result[name] = {
            'package_count': len(ids),
            'internal_edges': {
                pkgs[i]['name']: sorted({pkgs[d['pkg']]['name'] for d in nodes[i]['deps']
                                        if d['pkg'] in ids and pkgs[d['pkg']]['source'] is None
                                        and any(k['kind'] in (None, 'build') for k in d['dep_kinds'])})
                for i in sorted(ids) if pkgs[i]['source'] is None
            },
            'external': sorted(pkgs[i]['name'] + '@' + pkgs[i]['version']
                               for i in ids if pkgs[i]['source'] is not None),
        }
    return result

if __name__ == '__main__':
    print(json.dumps({Path(p).name: audit(p) for p in sys.argv[1:]}, indent=2))
