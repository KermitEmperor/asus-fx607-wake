#!/usr/bin/env python3
"""Update local-source hashes, or validate them with --check."""
import hashlib
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
pkgbuild = root / 'PKGBUILD'
text = pkgbuild.read_text()
sources = re.findall(r"'([^']+)'", re.search(r'^source=\((.*?)\)', text, re.M | re.S)[1])
hashes = [hashlib.sha256((root / name).read_bytes()).hexdigest() for name in sources]
replacement = 'sha256sums=(' + '\n            '.join("'" + h + "'" for h in hashes) + ')'
updated = re.sub(r'^sha256sums=\(.*?\)', lambda _: replacement, text, flags=re.M | re.S)
if '--check' in sys.argv:
    if updated != text:
        sys.exit('Arch source hashes differ: run python3 scripts/update-arch-checksums.py')
else:
    pkgbuild.write_text(updated)
