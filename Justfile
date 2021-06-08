# ------------------------ Qemu ------------------------
# Download required ISO files for VM
qemu-init:
	cd tests && ./scripts/init-qemu.sh

# Deploys the dotfiles on a virtual machine though QEMU
# Note that you should wait up to 30 seconds for text to
# automatically perform the installation
qemu-start sync-shared:
	cd tests && ./scripts/start-qemu.sh

# Talk to VM after start
qemu-monitor:
	netcat 127.0.0.1 55555

# ----------------------- Chroot -----------------------
# Populate the rootfs
chroot-init:
	cd tests&& ./scripts/init-chroot.sh

# Creates an overlayfs over an Arch file system
chroot-start sync-shared:
	cd tests && ./scripts/start-chroot.sh

sync-shared:
	#!/usr/bin/env bash
	set -euxEo pipefail
	cd tests
	. ./scripts/util.sh
	reset-shared
