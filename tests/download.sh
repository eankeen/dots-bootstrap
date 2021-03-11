#!/usr/bin/env bash
set -Eo pipefail

[[ $(basename "$PWD") == 'tests' ]] || {
	printf "\033[0;31m%s\033[0m\n" "ERROR: Script must be ran in 'tests' directory. Exiting" >&2
	exit 1
}

source util.sh

# get latest version of ArchLinux
# ex. output: 2021.03.01
get-latest-version() {
	local -r mirror="http://mirror.rackspace.com/archlinux"
	local -r mirror2="http://arch.mirror.constant.com"
	local -r mirror3="http://mirrors.evowise.com/archlinux"
	local -r mirror4="http://arch.mirror.constant.com"

	local -r url="$mirror/iso/latest/sha1sums.txt"

	sums="$(curl -sLo- "$url")" || {
		log_error 'Could not retrieve sha1sums.txt'
		return 1
	}
	sums="$(<<< "$sums" grep '.*.iso$')"
	sums="${sums#*-}"
	sums="${sums%-*}"
	echo "$sums"
}

main() {
	local version
	version="$(get-latest-version)" || die 'Could not retrieve latest version'

	mkdir -p ./data
	cd ./data || die 'Could not cd to ./data'

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
}

main
