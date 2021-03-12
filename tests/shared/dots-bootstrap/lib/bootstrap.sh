# shellcheck shell=bash

#
# ─── SETUP SYSTEM ───────────────────────────────────────────────────────────────
#

# -------------------- ensure network -------------------- #

ping google.com -c1 -W2 &>/dev/null || {
	die "'ping google.com' failed"
}


# --------------------- set hostname --------------------- #

read -rp "Choose new hostname: " \
	-ei "$(</etc/hostname)"
sudo hostname "$REPLY"
sudo tee /etc/hostname <<< "$REPLY" &>/dev/null


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
	sudo "${EDITOR:-${VISUAL:-vim}}" /etc/hosts
}


# --------------------- update fstab --------------------- #

grep -qe '# XDG Desktop Entries' /etc/fstab || {
	sudo tee -a /etc/fstab >/dev/null <<-EOF
	# XDG Desktop Entries
	/dev/fox/stg.files  /storage/edwin  xfs  defaults,relatime,X-mount.mkdir=0755  0  2
	/storage/edwin/Music  /home/edwin/Music  none  x-systemd.after=/data/edwin,X-mount.mkdir,bind,nofail  0  0
	/storage/edwin/Pics  /home/edwin/Pics  none  x-systemd.after=/data/edwin,X-mount.mkdir,bind,nofail  0  0
	/storage/edwin/Vids  /home/edwin/Vids  none  x-systemd.after=/data/edwin,X-mount.mkdir,bind,nofail  0  0
	/storage/edwin/Dls  /home/edwin/Dls  none  x-systemd.after=/data/edwin,X-mount.mkdir,bind,nofail  0  0
	/storage/edwin/Docs  /home/edwin/Docs  none  x-systemd.after=/data/edwin,X-mount.mkdir,bind,nofail  0  0

	# Data Bind Mounts
	/dev/fox/stg.data  /storage/data  reiserfs defaults,X-mount.mkdir  0 0
	/storage/data/calcurse  /home/edwin/data/calcurse  none  x-systemd.after=/storage/data,X-mount.mkdir,bind,nofail  0 0
	/storage/data/gnupg  /home/edwin/data/gnupg  none  x-systemd.after=/storage/data,X-mount.mkdir,bind,nofail  0 0
	/storage/data/fonts  /home/edwin/data/fonts  none x-systemd.after=/storage/data,X-mount.mkdir,bind,nofail  0 0
	/storage/data/BraveSoftware /home/edwin/config/BraveSoftware  none x-systemd.after=/storage/data,X-mount.mkdir,bind,nofail  0 0
	/storage/data/ssh /home/edwin/.ssh  none x-systemd.after=/storage/data,X-mount.mkdir,bind,nofail  0 0
	EOF

	read -rp "Check/edit /etc/fstab..." -sn 1
	sudo "${EDITOR:-${VISUAL:-vim}}" /etc/fstab
}

sudo mount -a || {
	log_error "Error: 'mount -a' failed. Exiting early"
	[[ -v DEV ]] || exit 1
}


# ------------------------- date ------------------------- #

sudo timedatectl set ntp true
sudo timedatectl set-timezone America/Los_Angeles
# ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
sudo hwclock --systohc


# ------------------------ locales ----------------------- #

sudo sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen


# ------------------------ groups ------------------------ #

sudo groupadd docker
sudo groupadd libvirt
sudo groupadd vboxusers
sudo groupadd lxd
sudo groupadd systemd-journal
sudo groupadd nordvpn
sudo usermod -aG docker,libvirt,vboxusers,lxd,systemd-journal,nordvpn edwin

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

[ -d ~/.dots ] || git clone https://github.com/eankeen/dots ~/.dots
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
