# shellcheck shell=bash

#
# ─── SETUP SYSTEM ───────────────────────────────────────────────────────────────
#

# -------------------- ensure network -------------------- #

ensure ping google.com -c1 -W2 &>/dev/null


# --------------------- set hostname --------------------- #

read -rp "Choose new hostname: " \
	-ei "$(</etc/hostname)"
ensure sudo hostname "$REPLY"
ensure sudo tee /etc/hostname <<< "$REPLY" &>/dev/null


# ----------------------- set hosts ---------------------- #

grep -qe "$REPLY" /etc/hosts || {
	sudo tee /etc/hosts <<-END >&/dev/null
	# IP-Address  Full-Qualified-Hostname  Short-Hostname
	127.0.0.1       localhost
	::1             localhost ipv6-localhost ipv6-loopback
	fe00::0         ipv6-localnet
	ff00::0         ipv6-mcastprefix
	ff02::1         ipv6-allnodes
	ff02::2         ipv6-allrouters
	ff02::3         ipv6-allhosts
	END

	read -rp "Check/edit /etc/hosts..." -sn 1
	sudo "${EDITOR:-vim}" /etc/hosts
}


# --------------------- update fstab --------------------- #

grep -qe '# extra' /etc/fstab || {
	sudo tee -a /etc/fstab >/dev/null <<-EOF
	# extra
	/dev/fox/stg.files  /storage/edwin  xfs  defaults,relatime,X-mount.mkdir=0755  0  2
	/dev/fox/stg.data  /storage/data  reiserfs defaults,X-mount.mkdir  0 0
	EOF

	read -rp "Check/edit /etc/fstab..." -sn 1
	sudo "${EDITOR:-vim}" /etc/fstab
}

sudo mount -a || {
	log_error "Error: 'mount -a' failed. Exiting early"
	[[ -v DEV ]] || exit 1
}

shopt -q dotglob && was_set=yes
shopt -u dotglob
for dir in /storage/edwin/*; do
	dir="${dir##*/}"
	ln -sT "/storage/data/$dir" "$HOME/$dir"
done
[ "$was_set" = "yes" ] && shopt -s dotglob

ln -sT /storage/data/BraveSoftware "$XDG_CONFIG_HOME/BraveSoftware"
ln -sT /storage/data/fonts "$XDG_DATA_HOME/fonts"
ln -sT /storage/data/gnupg "$XDG_DATA_HOME/gnupg"
ln -sT /storage/data/ssh ~/.ssh
ln -sT /storage/vault/rodinia/Steam "$XDG_DATA_HOME/Steam"
ln -sT /storage/data/mozilla/ ~/.mozilla

# ------------------------- date ------------------------- #

ensure sudo timedatectl set-ntp true
ensure sudo timedatectl set-timezone America/Los_Angeles
ensure sudo hwclock --systohc || die 'hwclock --systohc failed'


# ------------------------ locales ----------------------- #

ensure sudo sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
ensure sudo locale-gen


# ------------------------ groups ------------------------ #

# TODO: check /usr/lib/sysgroups.d
ensure sudo groupadd docker
ensure sudo groupadd libvirt
ensure sudo groupadd vboxusers
ensure sudo groupadd lxd
ensure sudo groupadd systemd-journal
ensure sudo groupadd nordvpn
ensure sudo usermod -aG docker,libvirt,vboxusers,lxd,systemd-journal,nordvpn edwin

# ------------------------ passwd ------------------------ #
read -rei "${XDG_CONFIG_HOME:-$HOME/.config}"
read -rp "Choose new hostname: " \
	-ei "$(</etc/hostname)"
read- rp "Root Password (enter to skip): "
[[ -n $REPLY ]] && passwd

#
# ─── INSTALL ACTUAL DOTFILES ────────────────────────────────────────────────────
#

# remove anything inherited from /etc/skell
{
	mkdir ~/.old
	mv ~/.bash_login ~/.old
	mv ~/.bash_logout ~/.old
	mv ~/.bash_profile ~/.old
	mv ~/.bashrc ~/.old
	mv ~/.profile ~/.old
} >&/dev/null

# temporary git config
# (in case commits need to be performed)
<<-EOF cat > ~/.gitconfig
	[user]
	    name = Edwin Kofler
	    email = edwin@kofler.dev
EOF

[ -d ~/.dots ] || {
	git clone https://github.com/eankeen/dots ~/.dots
	cd dots || die "Could not 'cd dots'"
	git config --local filter.npmrc-clean.clean "$(pwd)/user/config/npm/npmrc-clean.sh"
}

bm uninstall dotty || log_warn "Could not 'bm uninstall dotty"
bm install dotty
dotty reconcile || {
	die "Error: Could not apply user dotfiles. Exiting"
}


#
# ─── CONCLUSION ─────────────────────────────────────────────────────────────────
#

cat <<-EOF
	Prerequisites
	  - Network
	  - dotty
	  - cURL

	Bootstrapped:
	  - /etc/hostname
	  - /etc/hosts
	  - /etc/fstab
	  - timedatectl
	  - hwlock
	  - /etc/locale.gen
	  - locale-gen
	  - groupadd {docker,lxd,...}
	  - passwd
	  - eankeen/dotty

	Remember:
	  - \`dots-bootstrap install\`
	  - mkinitcpio
	  - Initramfs / Kernel (lvm2)
	  - Root Password
	  - Bootloader / refind
	  - Compile at /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
EOF
