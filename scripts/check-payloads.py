#!/usr/bin/env python3
"""Compare an actual Debian archive with the staged Arch package payload.

Does not install packages, invoke DKMS, or load a kernel module. Native
makepkg validation is handled separately by the Arch CI job.
"""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent.parent
archive = Path(sys.argv[1]).resolve()
sources = ('fx607_gpe02.c', 'Makefile', 'dkms.conf', 'fx607-gpe02.service',
           'check-platform', 'README.md', 'LICENSE')
with tempfile.TemporaryDirectory(prefix='fx607-payloads-') as temporary:
    base = Path(temporary)
    src, arch, debian = (base / name for name in ('src', 'arch', 'debian'))
    for directory in (src, arch, debian):
        directory.mkdir()
    for name in sources:
        (src / name).write_bytes((root / name).read_bytes())
    env = os.environ.copy()
    env.update(srcdir=str(src), pkgdir=str(arch))
    subprocess.run(['bash', '-e', '-c', 'source "$1"; package',
                    'check', str(root / 'PKGBUILD')], env=env, check=True)
    subprocess.run(['dpkg-deb', '-x', str(archive), str(debian)], check=True)
    paths = [f'usr/src/fx607-gpe02-0.1.0/{name}' for name in sources[:3]]
    paths += ['usr/lib/systemd/system/fx607-gpe02.service',
              'usr/lib/fx607-gpe02/check-platform']
    for relative in paths:
        if (arch / relative).read_bytes() != (debian / relative).read_bytes():
            sys.exit(f'Debian/Arch payload mismatch: {relative}')
    if (debian / 'usr/lib/fx607-gpe02/check-platform').stat().st_mode & 0o777 != 0o755:
        sys.exit('Platform checker must be executable')
print('Debian and Arch module/service payloads match.')
