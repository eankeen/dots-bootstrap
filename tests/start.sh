#!/usr/bin/env bash
set -Eo pipefail

source util.sh
init_debug

sendkey() (
		[[ -z $1 ]] && log_error "key: bNo input"
		netcat 127.0.0.1 55555 <<< "sendkey $1" &
		sleep 0.08
		kill "$(jobs -p)"
) &>/dev/null

# create disk for pre-boostrap script
create-usb-image() (
	cd data || die

	local loopDevice
	[ -f "usb.raw" ] || {
		log_info 'Creating usb.raw'
		dd if=/dev/zero of=usb.raw bs=10MiB count=5 >&4 2>&4
	}
	loopDevice="$(get_loop_device usb.raw)"

	# format and fill disk with pre-bootstrap script
	log_info 'Formatting usb.raw loop device'
	set -x
	sudo mkfs.fat "$loopDevice"
	set +x

	mkdir -p 'usb.mountpoint'
	log_info 'Mounting and copying files to usb.mountpoint'
	set -x
	sudo mount "$loopDevice" 'usb.mountpoint'
	sudo cp -r ../usb/* usb.mountpoint
	sudo umount 'usb.mountpoint'
	set +x
)

main() {
	(
		# post-post
		sleep 4
		sendkey 'ret'

		# post-getty
		sleep 32
		local -ra instructions=(
			# mount /dev/sda /mnt
			'mount'
			'.spc'
			'.slash'
			'dev'
			'.slash'
			'sda'
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
				sendkey "${keys:1}"
				continue
			}

			for ((i=0; i<${#keys}; i++)); do
				local key="${keys:$i:1}"
				# shellcheck disable=SC2015
				sleep 0.5
				sendkey "$key"
			done

		done
	) &

	coproc {
		while IFS= read -r line; do
			echo "sent text: '$line'"
			if [[ $line = "post-boot-1.sh: DONE" ]]; then
				echo DONE THING
			fi
		done < <(tail -F ./shared/con)
	}

	qemu-system-x86_64 \
		-name 'Arch Linux Install Test' \
		-uuid "$(uuid)" \
		-drive if=ide,media=cdrom,file="$(echo ./data/archlinux-*-x86_64.iso)" \
		-drive if=virtio,media=disk,index=0,file=./data/image.qcow2 \
		-drive if=ide,media=disk,file="$(get_loop_device ./data/usb.raw)",format=raw \
		-monitor tcp:127.0.0.1:55555,server,nowait \
		-m 2G \
		-cpu host \
		-smp 2 \
		-boot once=d \
		-machine accel=kvm \
		-virtfs local,path=./shared,mount_tag=host0,security_model=mapped-file,id=host0 \
		-pidfile data/qemu.pid \
	|| {
		kill "$(jobs -p)"
	}
}

create-usb-image || die 'create-usb-image failed'
main
