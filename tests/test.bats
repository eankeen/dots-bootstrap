#!/usr/bin/env bats

@test "node exists" {
	[[ command -v node &>/dev/null ]]
}

@test "symlinks" {
	for dir in Dls Docs Music Pics Vids; do
		[[ -L ~/$dir ]]
	done
}
