#! /bin/bash

set -e
IFS=$' \t\n' # workaround for conda 4.2.13+toolchain bug

# Adopt a Unix-friendly path if we're on Windows (see bld.bat).
[ -n "$PATH_OVERRIDE" ] && export PATH="$PATH_OVERRIDE"

# On Windows we want $LIBRARY_PREFIX not $PREFIX, but its Unix path
# currently works out to "/" which needs special-casing.
if [ "$LIBRARY_PREFIX" = / ] ; then
    useprefix=""
elif [ -n "$LIBRARY_PREFIX" ] ; then
    useprefix="$LIBRARY_PREFIX"
else
    useprefix="$PREFIX"
fi

# On Windows we need to regenerate the configure scripts.
if [ -n "$VS_MAJOR" ] ; then
    am_version=1.15 # keep sync'ed with meta.yaml
    export ACLOCAL=aclocal-$am_version
    export AUTOMAKE=automake-$am_version
    autoreconf_args=(
        --force
        --install
        -I "$useprefix/mingw-w64/share/aclocal" # note: this is correct for win32 also!
    )
    autoreconf "${autoreconf_args[@]}"
fi

# We used to provide our own config.{guess,sub} on Windows; now we are
# transitioning to running autoreconf in all Windows builds, since the
# distributed configure scripts have a lot of Windows special-casing that
# fails on msys2 unless we use msys2's autotools. But to smooth the transition
# we'll keep distributing the files for a bit.

mkdir -p $useprefix/share/util-macros

for f in config.guess config.sub ; do
    cp -p $RECIPE_DIR/$f .
    cp -p $RECIPE_DIR/$f $useprefix/share/util-macros/
done

export PKG_CONFIG_LIBDIR=$useprefix/lib/pkgconfig:$useprefix/share/pkgconfig

configure_args=(
    --prefix=$useprefix
    --disable-dependency-tracking
    --disable-selective-werror
    --disable-silent-rules
)

./configure "${configure_args[@]}"
make -j${CPU_COUNT}
make install
make check
