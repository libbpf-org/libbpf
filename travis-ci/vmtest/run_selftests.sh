#!/bin/bash

set -euxo pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

read_lists() {
	(for path in "$@"; do
		if [[ -s "$path" ]]; then
			cat "$path"
		fi;
	done) | cut -d'#' -f1 | tr -s ' \t\n' ','
}

test_progs() {
	if [[ "${KERNEL}" != '4.9.0' ]]; then
		travis_fold start test_progs "Testing test_progs"
		./test_progs ${BLACKLIST:+-b$BLACKLIST} ${WHITELIST:+-t$WHITELIST}
		travis_fold end test_progs
	fi

	travis_fold start test_progs-no_alu32 "Testing test_progs-no_alu32"
	./test_progs-no_alu32 ${BLACKLIST:+-b$BLACKLIST} ${WHITELIST:+-t$WHITELIST}
	travis_fold end test_progs-no_alu32
}

test_maps() {
	travis_fold start test_maps "Testing test_maps"
	./test_maps
	travis_fold end test_maps
}

test_verifier() {
	travis_fold start test_verifier "Testing test_verifier"
	./test_verifier
	travis_fold end test_verifier
}

travis_fold end vm_init

configs_path=libbpf/travis-ci/vmtest/configs
BLACKLIST=$(read_lists "$configs_path/BLACKLIST-${KERNEL}" \
		       "$configs_path/BLACKLIST-${KERNEL}.${ARCH}")
WHITELIST=$(read_lists "$configs_path/WHITELIST-${KERNEL}" \
		       "$configs_path/WHITELIST-${KERNEL}.${ARCH}")

cd libbpf/selftests/bpf

test_progs

if [[ "${KERNEL}" == 'latest' ]]; then
	#test_maps
	test_verifier
fi
