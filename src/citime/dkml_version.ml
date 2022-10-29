let () =
  let f (pkgname, _pkgver, _directives) = pkgname = "with-dkml" in
  match List.find_opt f Dkml_runtime_distribution.Config.ci_pkgs with
  | Some (_pkgname, pkgver, _directives) -> print_endline pkgver
  | None ->
      failwith "The with-dkml package was not in the CI flavor package list"

