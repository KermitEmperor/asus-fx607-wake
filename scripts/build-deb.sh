#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${1:-"$root/dist"}
mkdir -p "$output"
output=$(cd -- "$output" && pwd)
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
python3 - "$root" "$stage" <<'PY'
from pathlib import Path
import shutil
import sys
root, stage = map(Path, sys.argv[1:])
control = (root / 'debian/control').read_text().split('\n\n', 1)[1].strip()
control = control.replace('Architecture: all', 'Version: 0.1.0-1\nArchitecture: all\nMaintainer: Nixie404 <tudormares30@gmail.com>')
(stage / 'DEBIAN').mkdir()
(stage / 'DEBIAN/control').write_text(control + '\n')
for name in ('postinst', 'prerm', 'postrm'):
    shutil.copyfile(root / 'packaging' / name, stage / 'DEBIAN' / name)
    (stage / 'DEBIAN' / name).chmod(0o755)
files = {
    'fx607_gpe02.c': 'usr/src/fx607-gpe02-0.1.0/fx607_gpe02.c',
    'Makefile': 'usr/src/fx607-gpe02-0.1.0/Makefile',
    'dkms.conf': 'usr/src/fx607-gpe02-0.1.0/dkms.conf',
    'check-platform': 'usr/lib/fx607-gpe02/check-platform',
    'fx607-gpe02.service': 'usr/lib/systemd/system/fx607-gpe02.service',
    'README.md': 'usr/share/doc/fx607-gpe02-dkms/README.md',
    'debian/copyright': 'usr/share/doc/fx607-gpe02-dkms/copyright',
    'LICENSE': 'usr/share/doc/fx607-gpe02-dkms/LICENSE',
}
for source, dest in files.items():
    target = stage / dest
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(root / source, target)
    target.chmod(0o755 if source == 'check-platform' else 0o644)
for directory in [stage, *[p for p in stage.rglob('*') if p.is_dir()]]:
    directory.chmod(0o755)
PY
dpkg-deb --root-owner-group --build "$stage" "$output/fx607-gpe02-dkms_0.1.0-1_all.deb"
