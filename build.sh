#!/bin/bash
set -x

if [[ -n "$DRONE_TAG" ]]; then
	VERSION="${DRONE_TAG##v}"
elif [[ -n "$DRONE_COMMIT" ]]; then
	VERSION="${DRONE_COMMIT:0:6}"
else
	VERSION=$(date +%Y%m%d-%H%M%S)
fi

bld_clean() {
	rm -rf dist
}

bld_test() {
	busted
}

bld_localtest() {
	bld_dist
	cp -a dist/NeedsFoodBadly "C:/Program Files (x86)/World of Warcraft/_classic_/Interface/Addons"
}

bld_dist() {
	mkdir -p dist/NeedsFoodBadly
	cp *.lua *.md dist/NeedsFoodBadly
	sed "s/{{ version }}/${VERSION}/" <NeedsFoodBadly.toc >dist/NeedsFoodBadly/NeedsFoodBadly.toc
}

bld_package() {
	pushd dist &>/dev/null
	zip -r NeedsFoodBadly-${VERSION}.zip NeedsFoodBadly/
	popd &>/dev/null
}

bld_archive() {
	cp dist/*.zip /home/git/
}

for command in $@; do bld_$command || exit $?; done

