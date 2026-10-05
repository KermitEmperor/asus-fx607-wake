#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
bash -n PKGBUILD fx607-gpe02.install scripts/check.sh scripts/build-deb.sh
for script in check-platform packaging/postinst packaging/prerm packaging/postrm; do
    sh -n "$script"
done
python3 scripts/update-arch-checksums.py --check
python3 - <<'PY'
from pathlib import Path
import re
import subprocess

version = re.search(r'^pkgver=(.+)$', Path('PKGBUILD').read_text(), re.M)[1]
release = re.search(r'^pkgrel=(.+)$', Path('PKGBUILD').read_text(), re.M)[1]
debian = subprocess.check_output(['dpkg-parsechangelog', '-S', 'Version'], text=True).strip()
dkms = re.search(r'^PACKAGE_VERSION="(.+)"$', Path('dkms.conf').read_text(), re.M)[1]
assert debian == f'{version}-{release}' and dkms == version, 'Package versions differ'
assert 'FX607VJ.340' in Path('fx607_gpe02.c').read_text(), 'Hardware guard missing'
print('Syntax, Arch hashes and package versions checked.')
PY
