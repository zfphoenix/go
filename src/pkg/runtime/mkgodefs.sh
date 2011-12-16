#!/bin/sh
# Copyright 2011 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

SYS=$1
export GOOS=$(echo $SYS | sed 's/_.*//')
export GOARCH=$(echo $SYS | sed 's/.*_//')
shift

case "$GOARCH" in
386) CC=8c;;
amd64) CC=6c;;
arm) CC=5c;;
esac
export CC

export CFLAGS="-DGOOS_$GOOS -DGOARCH_$GOARCH"

cp arch_$GOARCH.h arch_GOARCH.h
cp defs_${GOOS}_$GOARCH.h defs_GOOS_GOARCH.h
cp os_$GOOS.h os_GOOS.h
cp signals_$GOOS.h signals_GOOS.h

cat <<EOF
// Go definitions for C variables and types.
// AUTO-GENERATED; run make -f Makefile.auto

package runtime
import "unsafe"
var _ unsafe.Pointer

EOF

for i in "$@"; do
	$CC $CFLAGS -q $i
done | awk '
/^func/ { next }
/^const/ { next }
/^\/\/.*type/ { next }

/^(const|func|type|var) / {
	if(seen[$2]++) {
        	skip = /{[^}]*$/;
		next;
	}
}

skip {
	skip = !/^}/
	next;
}

{print}
'

rm -f arch_GOARCH.h defs_GOOS_GOARCH.h os_GOOS.h signals_GOOS.h
