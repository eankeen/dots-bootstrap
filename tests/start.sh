#!/usr/bin/env bash
set -Eo pipefail

[[ $(basename "$PWD") == 'tests' ]] || {
	printf "\033[0;31m%s\033[0m\n" "ERROR: Script must be ran in 'tests' directory. Exiting" >&2
	exit 1
}

source util.sh

sendkey() (
		[[ -z $1 ]] && log_error "sendkey: no input"
		netcat 127.0.0.1 55555 <<< "sendkey $1" &
		# shellcheck disable=SC2181
		[[ $? -eq 0 ]] || {
			echo "failed"
		}
		sleep 0.08
		# shellcheck disable=SC2046
		kill $(jobs -p)
)

# create disk for post-boot-1.sh script
create-usb-image() {
	cd data || die 'create-usb-image: Could not cd to ./data'

	local -r usbRaw='usb.raw'
	local usbLoop=
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

trap exit2 SIGALRM
exit2() {
	# shellcheck disable=SC2046
	kill $(jobs -p)
	exit 1
}

( kill -n 14 $PPID ) &

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

	coproc {
		while IFS= read -r line; do
			echo "sent text: '$line'"
			if [[ $line = "post-boot-1.sh: DONE" ]]; then
				echo 'DONE THING'
			fi
		done < <(tail -F ./shared/con)
	}

	qemu-system-x86_64 \
		-name 'Arch Linux Install Test' \
		-uuid "$(uuid)" \
		-drive if=ide,media=cdrom,file="$(echo ./data/archlinux-*-x86_64.iso)" \
		-drive if=ide,media=disk,index=0,file=./data/image.qcow2 \
		-drive if=virtio,media=disk,file="$(get_loop_device ./data/usb.raw)",format=raw \
		-monitor tcp:127.0.0.1:55555,server,nowait \
		-m 2G \
		-cpu host \
		-smp 2 \
		-boot order=cd,once=d \
		-machine accel=kvm \
		-virtfs local,path=./shared,mount_tag=host0,security_model=mapped-file,id=host0 \
		\ # -bios /usr/share/ovmf/x64/OVMF.fd \
		\ # -pidfile data/qemu.pid \
	|| {
		# shellcheck disable=SC2046
		kill $(jobs -p)
	}
}

create-usb-image \
	&& main
