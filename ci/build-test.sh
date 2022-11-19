#!/bin/sh
set -euf

FLAVOR=$1
shift
CHANNEL=$1
shift

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
---------
Arguments
---------
FLAVOR=$FLAVOR
CHANNEL=$CHANNEL
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
"

preinstall() {
    true
}
case "$CHANNEL" in
next)
    preinstall() {
        opamrun repository set-url diskuv git+https://github.com/diskuv/diskuv-opam-repository.git
        opamrun pin dkml-runtime-common         git+https://github.com/diskuv/dkml-runtime-common.git#main --switch dkml --no-action --yes
        opamrun pin dkml-runtime-distribution   git+https://github.com/diskuv/dkml-runtime-distribution.git#main --switch dkml --no-action --yes
        opamrun pin dkml-runtimelib             git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        # with_pkg_ver(): opamrun pin dkml-apps                   git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        # with_pkg_ver(): opamrun pin with-dkml                   git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        opamrun upgrade \
            dkml-runtime-common dkml-runtime-distribution \
            --switch dkml --yes
            # dkml-runtimelib dkml-apps with-dkml \
    }
    ;;
release)
    ;;
*)
    echo "FATAL: The CHANNEL must be 'release' or 'next'"; exit 3
esac

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Where to stage files before we make a tarball archive
STAGE_RELDIR=.ci/stage-build
rm -rf "$STAGE_RELDIR"
install -d "$STAGE_RELDIR"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list --switch dkml
opamrun list --switch two
opamrun var --switch dkml
opamrun config report --switch dkml
opamrun option --switch dkml
opamrun exec --switch dkml -- ocamlc -config

# Update
opamrun update

# ----------- Secondary Switch ------------

# Install dkml-build-desktop.opam into secondary switch.
#
# opamrun install ... --with-test:
#   Testing does code hygiene, especially the checking of .gitlab-ci.yml to make
#   sure the PIN_* variables are in sync with dkml-runtime-distribution.

#   Use latest dkml-runtime-distribution when channel=next in the secondary switch
if [ "$CHANNEL" = next ]; then
    opamrun pin dkml-runtime-distribution git+https://github.com/diskuv/dkml-runtime-distribution.git --switch two --no-action --yes
fi
#   Weird error on Windows when directly do
#   `opamrun list --switch two -s | grep -q '^dkml-runtime-distribution$'`:
#
#       Fatal error: exception Sys_error("Invalid argument")
#       Raised by primitive operation at OpamConsole.print_message.(fun) in file "src/core/opamConsole.ml", line 507, characters 6-53
#       Called from OpamConsole.errmsg in file "src/core/opamConsole.ml" (inlined), line 605, characters 17-42
#       Called from OpamCliMain.main_catch_all in file "src/client/opamCliMain.ml", line 365, characters 6-94
#       Called from Dune__exe__OpamMain in file "src/client/opamMain.ml", line 12, characters 9-28
#   So split the opamrun and grep commands.
opamrun list --switch two -s >.ci/two.list
if grep -q '^dkml-runtime-distribution$' .ci/two.list; then
    #   bump to latest dkml-runtime-distribution
    opamrun upgrade --switch two dkml-runtime-distribution --yes
fi
#   Only test (aka. code hygiene) on non-Windows systems. We don't expect [ctypes] dependent libraries
#   like [yaml] (used to check .gitlab-ci.yml) to work on Windows yet. But it would be good
#   to get rid of this Windows/non-Windows check!
case "$dkml_host_abi" in
windows_*)
    opamrun install --switch two ./dkml-build-desktop.opam --yes
    ;;
*)
    opamrun install --switch two ./dkml-build-desktop.opam --with-test --yes
esac

# Use the `dkml-desktop-gen-global-install` executable to create a part of this shell
# script
install -d .ci
opamrun exec --switch two -- dkml-desktop-gen-global-install "$FLAVOR" >.ci/self-invoker.source.sh

# ----------- Primary Switch ------------

# Define the shell functions that will be called by .ci/self-invoker.source.sh
THE_SWITCH_PREFIX=$(opamrun var prefix --switch dkml)
start_pkg_vers() {
    echo "Pinning: $*"
}
with_pkg_ver() {
    with_pkg_ver_PKG=$1
    shift
    with_pkg_ver_VER=$1
    shift
    #   Pin. Technically most of these pins are unnecessary
    #   because they will be repeated in `opamrun install` (end_pkg_vers)
    #   but some are required to remove DKML's standard MSVC pins
    opamrun pin "$with_pkg_ver_PKG" --switch dkml -k version "$with_pkg_ver_VER" --no-action --yes
}
end_pkgs() {
    echo "Installing: $*"
    # Do pre installation
    preinstall
    # Install all the [## global-install] packages. No version numbers because
    # they could be pinned.
    opamrun install "$@" --switch dkml --yes
}
post_pkg() {
    post_pkg_ver_PKG=$1
    shift

    # Copy using `dkml-desktop-copy-installed` all the installed files to the
    # archive directory
    opamrun show --switch dkml --list-files "$post_pkg_ver_PKG" >.ci/opamshow.txt
    cat .ci/opamshow.txt >&2 # troubleshooting
    opamrun exec --switch two -- dkml-desktop-copy-installed \
        --file-list .ci/opamshow.txt \
        --opam-switch-prefix "$THE_SWITCH_PREFIX" \
        --output-dir "$STAGE_RELDIR"
}

# Call the shell functions (which will build the distribution packages)
set -x
#   shellcheck disable=SC1091
. .ci/self-invoker.source.sh
set +x

# Tar ball
install -d "dist/$CHANNEL/$FLAVOR/$dkml_host_abi"
#   TODO: Could use cross-compilation ... simplify cross-compilation first! Confer
#         diskuvbox. Then bundle the _opam/darwin_arm64-sysroot/ instead of _opam/.
tar cvCfz "$STAGE_RELDIR" "dist/$CHANNEL/$FLAVOR/$dkml_host_abi.tar.gz" .
