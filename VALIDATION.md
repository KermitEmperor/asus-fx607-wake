# Validation status

Local checks completed before the initial commit:

- `dpkg-buildpackage --no-sign --build=binary` produced the .deb, .changes
  and .buildinfo successfully, without installing anything.
- Extracted .deb source compiled against installed Ubuntu 7.0.0-38-generic
  headers; exported API symbol checks passed.
- The PKGBUILD package function staged the same module, DKMS configuration,
  hardware checker and systemd service as the .deb. Source SHA-256 hashes,
  shell syntax, versions, service/checker permissions and workflow YAML were
  checked.
- GitHub Actions jobs build natively in Debian, Ubuntu and Arch containers
  and compile against distribution headers. They have not run locally.
- Native Arch makepkg, real DKMS install/remove, boot activation and other
  kernels remain unvalidated until tested in those environments.

Hardware evidence from the investigation (not private files in this repo):

- Before: s2idle preparation successfully writes 0x00 to enable register
  0x1870, disabling GPE02; runtime restoration writes 0x04.
- After manual module load: preparation successfully writes 0x04 instead.
- User confirmed actual lid-opening wake with the original module source
  included here. Both the board and firmware version are guarded.
- Post-fix keyboard and power-button wake, battery behavior and S0ix
  residency have not been verified.

No tests run by the packaging scripts automatically suspend the machine.
