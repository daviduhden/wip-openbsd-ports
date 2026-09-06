"""Install the pinned private Socket.IO stack, without pip or sys.path changes.

The shared OpenBSD Socket.IO 4 / Engine.IO 3 ports are needed by other
applications. OnionShare's bundled JavaScript uses Socket.IO protocol 5.
Keep these five small pure-Python modules under OnionShare's namespace.
"""

import ast
from pathlib import Path
import re
import shutil
import sys

wrkdir, cli = map(Path, sys.argv[1:])
packages = {
    "flask_socketio": ("flask_socketio-5.6.1", "src"),
    "socketio": ("python_socketio-5.16.3", "src"),
    "engineio": ("python_engineio-4.13.3", "src"),
    "simple_websocket": ("simple_websocket-1.1.0", "src"),
    "bidict": ("bidict-0.23.1", ""),
}
namespace = "onionshare_cli._vendor"
dest = cli / "onionshare_cli" / "_vendor"
dest.mkdir()
(dest / "__init__.py").write_text('"""Private, version-pinned dependencies."""\n')

for module, (release, subdir) in packages.items():
    source = wrkdir / release
    shutil.copytree(source / subdir / module, dest / module)
    shutil.copyfile(source / "LICENSE", dest / module / "LICENSE")

for path in sorted(dest.rglob("*.py")):
    code = path.read_text()
    for module in packages:
        code = re.sub(
            rf"^(\s*)from {module}(\.| import )",
            rf"\1from {namespace}.{module}\2", code, flags=re.MULTILINE,
        )
        code = re.sub(
            rf"^(\s*)import {module}(\s*(?:#.*)?$)",
            rf"\1from {namespace} import {module}\2", code, flags=re.MULTILINE,
        )
    # Engine.IO selects the transport backend by module name.
    code = code.replace("'engineio.async_drivers.'", "'" + namespace + ".engineio.async_drivers.'")
    tree = ast.parse(code, filename=str(path))
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            assert all(x.name.split('.')[0] not in packages for x in node.names), path
        elif isinstance(node, ast.ImportFrom) and node.level == 0:
            assert (node.module or '').split('.')[0] not in packages, path
    path.write_text(code)
