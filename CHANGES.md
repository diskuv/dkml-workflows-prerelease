## v1

New Features:
1. Support GitLab CI/CD
2. Support desktop testing on Windows
3. GitHub now uses a composite action rather than a child
   workflow, resulting in less artifact copying and
   quicker builds.

There are significant breaking changes. It will be far easier
to onboard with [the new version `v1` instructions](https://github.com/diskuv/dkml-workflows/tree/v1#readme)
and then remove your `v0` code, rather than try to do an in-place upgrade:
* Any custom build logic you have in your GitHub workflow should go into
  the new `ci/build-test.sh`. Alternatively, if you don't care about ever running troubleshooting
  CI on your desktop or GitLab, directly into your new `.github/workflows/build-with-dkml.yml`.

Breaking changes:
- The GitHub child workflow has been replaced by a GitHub composite action
- Input variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

  | Old Name                  | New Name                  |
  | ------------------------- | ------------------------- |
  | cache-prefix              | CACHE_PREFIX              |
  | ocaml-compiler            | OCAML_COMPILER            |
  | dkml-compiler             | DKML_COMPILER             |
  | conf-dkml-cross-toolchain | CONF_DKML_CROSS_TOOLCHAIN |
  | diskuv-opam-repository    | DISKUV_OPAM_REPOSITORY    |
  | ocaml-options             | ocaml_options             |
  | vsstudio-arch             | vsstudio_arch             |
  | vsstudio-hostarch         | vsstudio_hostarch         |
  | vsstudio-dir              | vsstudio_dir              |
  | vsstudio-vcvarsver        | vsstudio_vcvarsver        |
  | vsstudio-winsdkver        | vsstudio_winsdkver        |
  | vsstudio-msvspreference   | vsstudio_msvspreference   |
  | vsstudio-cmakegenerator   | vsstudio_cmakegenerator   |

- Matrix variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

- The shell matrix variable `default_shell` has been renamed `gh_unix_shell`

- The operating system matrix variable has been reorganized to distingush GitHub
  from GitLab:

  - `os` is now `gh_os` and in use only for GitHub Actions
  - `gl_tags` and `gl_image` are the new GitLab CI/CD equivalents. GitLab CI/CD uses tags like
    `[shared-windows, windows, windows-1809]` to specify the type of runner machine to use,
    and for macOS image you can supply an XCode version like `macos-11-xcode-12`.
  
## v0

Initial release