test-setup:
	cd tests && ./setup.sh

test-reset:
	cd tests/data && { \
		mountpoint usb.mountpoint >/dev/null 2>&1 \
			&& sudo umount usb.mountpoint \
			&& rm -rf usb.mountpoint; \
		rm image.qcow2 ||:; \
		rm usb.raw ||:; \
	}

test: test-reset test-setup
	cd tests && ./start.sh

test-monitor:
	netcat 127.0.0.1 55555
