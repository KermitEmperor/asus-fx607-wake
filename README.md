# ASUS FX607VJ lid wake workaround

Experimental Linux DKMS module for **ASUS TUF Gaming F16 FX607VJ and FX607VUR with BIOS Version 340**. Forked from Nixie404.

## Evidence and scope

On the investigated laptop, s2idle resumed through USB input, while lid,
power button and built-in keyboard did not wake it. Tracing demonstrated
that Linux disabled GPE02 when preparing the suspend wake mask. ASUS's
firmware uses this event to dispatch lid and power-button notifications.

The module registers GPE02 as wake-capable and arms its wake mask through
the exported ACPI APIs. A second trace confirmed the wake bit remained
enabled. The user then confirmed that opening the lid woke actual s2idle.

Tested: one FX607VJ, BIOS 340, Ubuntu 26.04.1, kernel 7.0.0-38-generic.
The module refuses other board/BIOS combinations. **Power-button and keyboard
wake after applying the workaround are not yet verified.** Battery savings,
S0ix residency, other firmware and other models are not established.

It does not patch firmware, replace ACPI event handlers, change GRUB, force
S3 or change Windows settings. This is an experimental workaround, not a
general ASUS sleep fix.

## Build a Debian/Ubuntu package

Build dependencies: `dpkg-dev`, `make`, `python3`. No root privileges or
kernel headers are required to package the source:

```sh
dpkg-buildpackage --no-sign --build=binary
```

The `.deb`, `.changes` and `.buildinfo` appear in the parent directory.
Alternatively, `bash scripts/build-deb.sh` builds only the `.deb` into `dist/`.
This uses dpkg's native tools with explicit packaging rules; debhelper is
not required. Build commands do not install or load anything.

On the target laptop, install headers matching its running kernel first
(e.g. `linux-headers-$(uname -r)` where that package exists), then review and
install the `.deb`:

```sh
sudo apt install ../fx607-gpe02-dkms_0.1.0-1_all.deb
```

This adds module source and DKMS state and builds/installs the module for
the running kernel. It does not load the module or enable boot activation.
Future kernel rebuilds use DKMS AUTOINSTALL; matching headers remain necessary.

## Build an Arch package

From this checkout on Arch, with `base-devel` and the `dkms` build dependency
available, as a regular user:

```sh
makepkg -s
```

This creates `fx607-gpe02-dkms-0.1.0-1-x86_64.pkg.tar.zst`. It contains source;
Arch's DKMS hooks perform kernel builds on installation and upgrades.
Install the appropriate headers for your kernel (e.g. `linux-headers` or
`linux-lts-headers`) and review the package before installing:

```sh
sudo pacman -U ./fx607-gpe02-dkms-0.1.0-1-x86_64.pkg.tar.zst
```

The PKGBUILD uses checked-in local sources with actual SHA-256 hashes. This
works in a clone or source archive and does not need a GitHub URL filled in.
It is not yet an AUR recipe: an AUR release should reference an immutable
published source archive and generate `.SRCINFO` with `makepkg --printsrcinfo`.

## Explicit activation and rollback

After installation, the following command changes the running kernel wake
mask and makes that change recur at boot on the supported board/BIOS:

```sh
sudo systemctl enable --now fx607-gpe02.service
journalctl -k -b --no-pager | grep fx607_gpe02
```

To try only the current boot, use `systemctl start` without `enable`.
If a manually loaded experimental copy already exists, modprobe leaves it
in place; reboot to ensure the installed build is the one being tested.
No package or service automatically initiates suspend.

Rollback:

```sh
sudo systemctl disable --now fx607-gpe02.service
```

Then remove the package with `apt remove fx607-gpe02-dkms` or
`pacman -R fx607-gpe02-dkms` and reboot. Unloading clears the wake mask;
an added CAN_WAKE classification remains until reboot because the exported
API has no inverse operation. Removing autoload plus reboot restores baseline.

External kernel modules taint the kernel and can cause crashes or unwanted
wakeups. With Secure Boot enabled, module signatures/MOK enrollment may be
required according to your distribution's DKMS setup. This project does not
disable Secure Boot or enroll keys. A BIOS update disables this workaround's
hardware match intentionally; investigate new firmware before broadening it.

## Development and reporting

Run `bash scripts/check.sh` before committing. After changing any PKGBUILD
source, run `python3 scripts/update-arch-checksums.py`. Keep `pkgver`, Debian
changelog, `dkms.conf`, build scripts and package paths consistent when
releasing a new version.

For another model, provide board, BIOS, kernel and a trace of the actual GPE
wake path. Do not remove guards based only on similar symptoms. Reports should
distinguish lid, power-button, keyboard and USB wake, and include immediate
wakeups or increased battery drain. Full firmware dumps and private journals
are excluded from this repository.

The preferred eventual fix is a reviewed upstream ACPI/platform quirk or a
firmware correction. License: GPL-2.0-only; see `LICENSE`.

References: [kernel GPE APIs](https://github.com/torvalds/linux/blob/v7.0/drivers/acpi/acpica/evxfgpe.c),
[Arch DKMS guidelines](https://wiki.archlinux.org/title/DKMS_package_guidelines).
