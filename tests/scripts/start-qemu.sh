#!/usr/bin/env bash
set -Eo pipefail

# In short, this file uses a downloaded Arch Linux ISO as the base
# Virtual Machine image, and also mounts the folder containing
# `tests/usb` (which is exposed as `/dev/sda`) to `/mnt`. It then
# executes the containing `post-boot-1.sh` script.

# It mounts the folder by emulating keypresses on the command line through running
# `netcat` on the host machine. QEMU opens a socket, which can have keypress commands
# sent to it. There is a 37ish second wait time for the keypresses to start happening
# to account for the VM POST and boot period

[[ $(basename "$PWD") == 'tests' ]] || {
	printf "\033[0;31m%s\033[0m\n" "ERROR: Script must be ran in 'tests' directory. Exiting" >&2
	exit 1
}

source scripts/util.sh

#
# ─── MAIN ───────────────────────────────────────────────────────────────────────
#

main() {
	# ---------------------- reset-files --------------------- #
	{
		# ensure remains of previous tests do not exist

		mountpoint usb.mountpoint >/dev/null 2>&1 && {
			sudo umount usb.mountpoint
			rm -rf usb.mountpoint ||:
		}

		rm ./data/image.raw ||:
		rm ./data/image.qcow2 ||:
		rm ./data/usb.raw ||:

		# copy over files to ./shared (which will be mounted in VM)
		reset-shared
	}

	cd ./data || die 'Could not cd to ./data'


	# ------------------- create-disk-image ------------------ #

	{
		# create the disk we install Arch Linux onto. we
		# first create a raw disk because sgdisk cannot
		# operate on qcow2 images. since our partition table
		# layout accords with GPT and we're booting with GRUB, we specify and utilize a bios boot partition (partition type code EF02)

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


	# ------------------- create-usb-image ------------------- #

	declare usbLoop=
	{
		# create the usb image that contains the `post-boot-1.sh` script
		# this could be made better / more efficient with guestfish

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

	cd .. || die 'cd .. failed'


	# ---------------------- start qemu ---------------------- #

	(
		# before starting qemu (because it takes control of the
		# tty and blocks), we start a background process that
		# sends keypresses that automatically mounts and execs
		# `post-boot-1.sh` on first boot. the timing may have
		# to be adjusted, depending on your computer

		# sends keys to qemu, which forwards them to the VM
		sendkey() (
				[[ -z $1 ]] && log_error "sendkey: no input"

				netcat 127.0.0.1 55555 <<< "sendkey $1" &
				sleep 0.08
				# shellcheck disable=SC2046
				kill $(jobs -p)
		) >/dev/null

		# post-POST
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

main "$@"
