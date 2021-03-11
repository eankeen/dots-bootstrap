#!/usr/bin/env bash
set -euxEo pipefail

# setup
log_info() { printf "\033[0;34m%s\033[0m\n" "INFO: $*"; }
log_error() { printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2; }
trap_int() { log_error 'Received SIGINT. Exiting'; exit 1; }
trap_err() { log_error 'Approached unhandled failure exit code. Exiting'; exit 1; }
trap trap_int INT
trap trap_err ERR


# drive to install to
drive="/dev/sda"

# mountpoint utilized to install OS / chroot into
mnt="/mnt-new-os"

# mount and format disks
mkdir -p "$mnt"

mkfs.ext4 "${drive}1"
mkfs.ext4 "${drive}2"
mkfs.ext4 "${drive}3"
mount "${drive}3" "$mnt"
mkdir -p "$mnt/boot"
mount "${drive}2" "$mnt/boot"

# install base Arch
pacstrap "$mnt" base linux-lts linux-firmware

# generate fstab
genfstab -U "$mnt" > "$mnt/etc/fstab"

# modify fstab
cat <<'EOF' >> "$mnt/etc/fstab"
host0  /shared  9p  trans=virtio,access=any,version=9p2000.L,msize=1000000,X-mount.mkdir=0755  0  0
EOF

# start post-boot-2 on second startup
cat <<-EOF >> "$mnt/etc/systemd/system/post-boot-2.service"
	[Unit]
	Description=Post Boot 2 Service Auto Start
	After=shared.mount
	ConditionDirectoryNotEmpty=/shared
	ConditionPathIsMountPoint=/shared
	#StandardInput=tty
	#TTYPath=/dev/tty1
	#TTYReset=yes
	#TTYVHangup=yes

	[Service]
	Type=oneshot
	ExecStart=/shared/post-boot-2.sh

	[Install]
	WantedBy=multi-user.target
EOF


# install bootloader grub in chroot
# same password (same as pre-bootstrap.sh's ENV_DEV_password)
declare -r password="password"
arch-chroot "$mnt" '/bin/bash' <<-EOF
	# grub
	pacman -Sy --noconfirm grub
	grub-install --target=i386-pc "$drive"
	grub-mkconfig -o /boot/grub/grub.cfg

	# for post-boot-1.sh tee -a "mnt/shared/con"
	mount host0

	# post-boot-2
	systemctl daemon-reload
	systemctl enable post-boot-2.service

	# change password
	printf "%s\n%s" "$password" "$password" | passwd

	echo 'EXITING CHROOT'
EOF

<<< "post-boot-1.sh: DONE" tee -a "$mnt/shared/con"
echo 'REBOOTING'
sleep 3
reboot
