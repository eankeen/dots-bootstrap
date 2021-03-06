#!/usr/bin/env bats

@test "node exists" {
	[[ command -v node &>/dev/null ]]
}
