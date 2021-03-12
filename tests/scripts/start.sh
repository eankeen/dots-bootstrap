#!/usr/bin/env bash
set -Eo pipefail

[[ $(basename "$PWD") == 'tests' ]] || {
	printf "\033[0;31m%s\033[0m\n" "ERROR: Script must be ran in 'tests' directory. Exiting" >&2
	exit 1
}

source scripts/util.sh


# ------------------------ helpers ----------------------- #
# sends keys to qemu, which forwards them to VM
sendkey() (
		[[ -z $1 ]] && log_error "sendkey: no input"
		netcat 127.0.0.1 55555 <<< "sendkey $1" &
		sleep 0.08
		# shellcheck disable=SC2046
		kill $(jobs -p)
) >/dev/null


# ------------------------- main ------------------------- #
reset-files() {
	mountpoint usb.mountpoint >/dev/null 2>&1 &&{
		sudo umount usb.mountpoint
		rm -rf usb.mountpoint ||:
	}

	rm ./data/image.raw ||:
	rm ./data/image.qcow2 ||:
	rm ./data/usb.raw ||:

	reset-shared
}

# create disk (actual image we install arch to)
# we create a raw disk because sgdisk cannot operate on qcow2 images
create-disk-image() {
	log_info 'Creating image.raw'
	qemu-img create \
		-f "raw" \
		'image.raw' \
		'20G'

	sgdisk --clear 'image.raw'
	sgdisk --new 1::+1MiB 'image.raw'
	sgdisk --typecode 1:EF02 'image.raw'
	sgdisk --new 2::+1GiB 'image.raw'
	sgdisk --largest-new=0 'image.raw'

	log_info 'Creating image.qemu'
	qemu-img convert \
		-f "raw" \
		-O "qcow2" \
		'image.raw' \
		'image.qcow2'
}

# create disk for post-boot-1.sh script
declare usbLoop=
create-usb-image() {
	local -r usbRaw='usb.raw'
	# usbLoop
	local -r usbMount='usb.mountpoint'

	# create raw
	log_info "Creating $usbRaw"
	[[ -f "$usbRaw" ]] && { rm "$usbRaw" \
		|| die "rm $usbRaw failed"; }
	dd if=/dev/zero of="$usbRaw" bs=10MiB count=5 status=progress || die "dd of=$usbRaw failed"

	# create loop
	log_info "Creating loop device for $usbRaw"
	# [[ -e "$usbLoop" ]] && { rm -f "$usbLoop" \
	# 	|| die "rm $usbLoop failed"; }
	# ssudo mknod -m 0660 "$usbLoop" b 7 8
	# ssudo losetup "$PWD/$usbLoop" "$usbRaw"

	ssudo losetup -f "$usbRaw"
	usbLoop="$(losetup -j "$usbRaw" | cut -d: -f-1)"

	# format loop
	log_info "Formatting $usbLoop"
	ssudo mkfs.fat "$usbLoop"

	# copy data
	log_info "Copying data to $usbRaw via $usbLoop at $usbMount"
	[[ -d "$usbMount" ]] || mkdir -p "$usbMount" \
		|| die "mkdir -p $usbMount failed"
	ssudo mount "$usbLoop" "$usbMount"
	ssudo cp -r ../usb/* "$usbMount"
	ssudo umount "$usbMount"
	rmdir "$usbMount" || die "rmdir $usbMount failed"
}

main() {
	(
		# post-post
		sleep 5
		sendkey 'ret' || die 'a sendkey kill failed'

		# post-getty
		sleep 37
		local -ra instructions=(
			# mount /dev/sda /mnt
			'mount'
			'.spc'
			'.slash'
			'dev'
			'.slash'
			'vda'
			'.spc'
			'.slash'
			'mnt'
			'.ret'
			# /mnt/post-boot-1.sh
			'.slash'
			'mnt'
			'.slash'
			'post'
			'.minus'
			'boot'
			'.minus'
			'1'
			'.dot'
			'sh'
			'.ret'
		)

		for keys in "${instructions[@]}"; do
			[[ ${keys:0:1} == '.' ]] && {
				sendkey "${keys:1}" || die 'a sendkey kill failed'
				continue
			}

			for ((i=0; i<${#keys}; i++)); do
				local key="${keys:$i:1}"
				sleep 0.5
				sendkey "$key" || die 'a sendkey kill failed'
			done
		done
	) &

	sudo qemu-system-x86_64 \
		-name 'Arch Linux Install Test' \
		-uuid "$(uuid)" \
		-drive if=ide,media=cdrom,file="$(echo ./data/archlinux-*-x86_64.iso)" \
		-drive if=ide,media=disk,file=./data/image.qcow2 \
		-drive if=virtio,media=disk,file="$usbLoop",format=raw \
		-virtfs local,path=./shared,mount_tag=host0,security_model=mapped-file,id=host0 \
		-monitor tcp:127.0.0.1:55555,server,nowait \
		-m 2G \
		-cpu host \
		-smp 2 \
		-boot order=cd,once=d \
		-machine accel=kvm \
	|| {
		# shellcheck disable=SC2046
		kill $(jobs -p)
	}
}

reset-files

cd ./data || die 'create-usb-image: Could not cd to ./data'
create-usb-image \
	&& create-disk-image \
	&& cd .. \
	&& main
