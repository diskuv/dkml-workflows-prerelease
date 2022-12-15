(lang dune 2.9)

(name dkml-component-common-desktop)
(version 0.1.0)

(generate_opam_files true)

(source
 (uri "git+https://gitlab.com/diskuv-ocaml/components/dkml-component-desktop.git"))
(homepage "https://gitlab.com/diskuv-ocaml/components/dkml-component-desktop")
(documentation "https://gitlab.com/diskuv-ocaml/components/dkml-component-desktop/-/blob/main/README.md")
(bug_reports "https://gitlab.com/diskuv-ocaml/components/dkml-component-desktop/-/issues")
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")

(package
 (name dkml-component-common-desktop)
 (synopsis "Common code for installers of desktop executables for all DKML installable platforms")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-install (>= 0.2.0))
  (dkml-workflows (and (>= 1.1.0) :build))))

(package
 (name code-hygiene)
 (synopsis "Code hygiene")
 (depends
  ; dkml-runtime-distribution has a ~dev dependency within this package. Keep it this way.
  dkml-runtime-distribution
  (yaml (>= 3.0.0))))

(package
 (name dkml-component-staging-withdkml)
 (synopsis "Places with-dkml binary into the DKML staging-files")
 (description "Places with-dkml binary into the DKML staging-files")
 (depends
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-staging-desktop-ci)
 (synopsis "Collection of end-user installers of the CI flavor of desktop executables")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-staging-desktop-full)
 (synopsis "Collection of end-user installers of the Full flavor of desktop executables")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-staging-desktop-compile)
 (synopsis "Manifests of which packages are compiled on the end-user machine at installation")
 (description
  "Manifests of which packages are compiled on the end-user machine at installation")
 (depends
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-offline-desktop-ci)
 (synopsis "Offline install of the CI flavor of desktop executables")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-component-staging-withdkml (= :version))
  (dkml-component-staging-desktop-ci (= :version))
  (dkml-component-common-desktop (= :version))
  (dkml-component-staging-ocamlrun (>= 4.12.1~))
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-offline-desktop-full)
 (synopsis "Offline install of the Full flavor of desktop executables")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-component-staging-withdkml (= :version))
  (dkml-component-staging-desktop-full (= :version))
  (dkml-component-common-desktop (= :version))
  (dkml-component-staging-ocamlrun (>= 4.12.1~))
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-build-desktop)
 (synopsis "Tools for building desktop executables")
 (description
  "Tools for building desktop executables")
 (depends
  (re (>= 1.10.0))
  (yaml (and (>= 3.0.0) :with-test))
  (dkml-runtime-common (>= 1.0.2~prerel7))
  (dkml-runtime-distribution (>= 1.0.2~prerel7))))
