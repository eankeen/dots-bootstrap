#!/usr/bin/env bash
set -ue

die() {
	log_error "${*-'die: '}. Exiting"
	exit 1
}

log_error() {
	printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2
}

trap exit_immediately ERR
exit_immediately() {
	die 'Approached unhandled failure exit code'
}

# drive to install to
drive="/dev/sdb"

# mountpoint utilized to install OS / chroot into
# (arbitrary)
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

# install bootloader grub in chroot
arch-chroot "$mnt" '/bin/bash' <<-EOF
	pacman -Sy --noconfirm grub
	grub-install --target=i386-pc --bootloader-id GRUB-BOOT "$drive"
	mount host0

	echo 'EXITING CHROOT'
EOF

# start post-boot-2 on second startup
cat <<-EOF >> /etc/systemd/system/post-boot-2.service
	[Unit]
	Description=Post Boot 2 Service Auto Start
	After=shared.mount

	[Service]
	Type=oneshot
	ExecStart=/shared/post-boot-2.sh
	ConditionDirectoryNotEmpty=/shared
	ConditionPathIsMountPoint=/shared

	[Install]
	WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable post-boot-2.service

<<< "post-boot-1.sh: DONE" tee -a "$mnt/shared/con"

echo REBOOTING2
# reboot
