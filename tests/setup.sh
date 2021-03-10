#!/usr/bin/env bash
set -Eo pipefail

[[ $(basename "$PWD") == 'tests' ]] || {
	printf "\033[0;31m%s\033[0m\n" "ERROR: Script must be ran in 'tests' directory. Exiting" >&2
	exit 1
}

source util.sh

main() {
	local -r mirror="http://dfw.mirror.rackspace.com"
	local -r version="2021.03.01"

	mkdir ./data/dls
	cd ./data/dls || die 'Could not cd to ./data/dls'

	# download and check iso (live usb)
	{
		# download
		[ -f "archlinux-$version-x86_64.iso" ] || {
			log_info "Downloading Arch Linux ISO"
			curl -O "$mirror/archlinux/iso/$version/archlinux-$version-x86_64.iso"
		}

		# identity check
		[ -f "archlinux-$version-x86_64.iso.sig" ] || {
			log_info "Downloading PGP signature"
			curl -O "$mirror/archlinux/iso/$version/archlinux-$version-x86_64.iso.sig" || die "Could not download PGP signature"

		}
		log_info "Verifying Arch Linux ISO with Signature"
		gpg --keyserver-options auto-key-retrieve --verify "archlinux-$version-x86_64.iso.sig" "archlinux-$version-x86_64.iso" || die "Signature verification failed"

		# consistency check
		[ -f "md5sums.txt" ] || {
			log_info "Downloading checksum file"
			curl -O "$mirror/archlinux/iso/$version/md5sums.txt" || die "Could not download checksum file"
		}
		md5sum --ignore-missing --check "md5sums.txt" || die "Integrity verification failed"
	}

	# create disk (actual image we install arch to)
	rm 'image.raw' 'image.qcow2'
	{
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
}

main
