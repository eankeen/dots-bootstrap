test-download:
	cd tests && ./download.sh

test-reset-shared:
	#!/usr/bin/env bash
	set -euxEo pipefail
	cd tests
	. ./util.sh
	reset-shared
test:
	cd tests && ./start.sh

test-monitor:
	netcat 127.0.0.1 55555
