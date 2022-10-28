# desktop 0.1.0

A component providing all the opam package files marked with `global-install`
in the [DKML runtime distribution packages](https://github.com/diskuv/dkml-runtime-distribution/tree/main/src/none).

These package files are executables, man pages and other assets which will be
available in the end-user installation directory.

## Developing

You can test on your desktop with a session as follows:

```console
# For macOS/Intel (darwin_x86_64). Other platforms are similar.
$ sh ci/setup-dkml/pc/setup-dkml-darwin_x86_64.sh --SECONDARY_SWITCH=true
...
Finished setup.

To continue your testing, run:
  export dkml_host_abi='darwin_x86_64'
  export abi_pattern='macos-darwin_all'
  export opam_root='/Volumes/Source/dkml-component-desktop/.ci/o'
  export exe_ext=''
  export PC_PROJECT_DIR='/Volumes/Source/dkml-component-desktop'
  export PATH="/Volumes/Source/dkml-component-desktop/.ci/sd4/opamrun:$PATH"

# Copy and adapt from above
$ export dkml_host_abi='darwin_x86_64'
$ export abi_pattern='macos-darwin_all'
$ export opam_root="$PWD/.ci/o"
$ export exe_ext=''
$ export PC_PROJECT_DIR="$PWD"
$ export PATH="$PWD/.ci/sd4/opamrun:$PATH"

# Run the build
$ opamrun exec -- sh ci/build-test.sh ci
```

## Status

[![Syntax check](https://github.com/diskuv/dkml-component-desktop/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/dkml-component-desktop/actions/workflows/syntax.yml)
