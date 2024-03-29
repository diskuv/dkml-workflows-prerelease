open Bos

let ( let* ) = Rresult.R.bind

let exe_name = "generate-setup-dkml-scaffold"

let do_not_edit =
  Printf.sprintf
    {|; DO NOT EDIT THIS FILE. It is auto-generated by %s
; Typical upgrade steps:
;   opam upgrade dkml-workflows && opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote
|}
    exe_name

type gh_config = { gh_dir : string; gh_output_option : string }

let gh_configs =
  [
    { gh_dir = "gh-darwin"; gh_output_option = "darwin" };
    { gh_dir = "gh-linux"; gh_output_option = "linux" };
    { gh_dir = "gh-windows"; gh_output_option = "windows" };
  ]

let scaffold_gh ~output_dir () =
  let rec helper = function
    | [] -> Ok ()
    | { gh_dir; gh_output_option } :: tl ->
        let gh_dir = Fpath.(output_dir / gh_dir) in
        let gh_dune_file_pre = Fpath.(gh_dir / "pre" / "dune") in
        let gh_dune_file_post = Fpath.(gh_dir / "post" / "dune") in
        let dune_content_pre =
          Printf.sprintf
            {|%s
(rule
 (alias gen-dkml)
 (target action.gen.yml)
 (enabled_if %%{bin-available:gh-dkml-action-yml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run gh-dkml-action-yml --phase pre --output-%s %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:gh-dkml-action-yml})
 (action
  (diff action.yml action.gen.yml)))
|}
            do_not_edit gh_output_option
        in
        let dune_content_post =
          Printf.sprintf
            {|%s
(rule
 (alias gen-dkml)
 (target action.gen.yml)
 (enabled_if %%{bin-available:gh-dkml-action-yml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run gh-dkml-action-yml --phase post --output-%s %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:gh-dkml-action-yml})
 (action
  (diff action.yml action.gen.yml)))
|}
            do_not_edit gh_output_option
        in
        let* (_exists : bool) = OS.Dir.create (Fpath.parent gh_dune_file_pre) in
        let* (_exists : bool) =
          OS.Dir.create (Fpath.parent gh_dune_file_post)
        in
        let* () = OS.File.write gh_dune_file_pre dune_content_pre in
        let* () = OS.File.write gh_dune_file_post dune_content_post in
        helper tl
  in
  helper gh_configs

let scaffold_gl ~output_dir () =
  let gl_dir = Fpath.(output_dir / "gl") in
  let gl_dune_file = Fpath.(gl_dir / "dune") in
  let dune_content =
    Printf.sprintf
      {|%s
(rule
 (target setup-dkml.gen.gitlab-ci.yml)
 (alias gen-dkml)
 (enabled_if %%{bin-available:gl-setup-dkml-yml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run gl-setup-dkml-yml --output-file %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:gl-setup-dkml-yml})
 (action
  (diff setup-dkml.gitlab-ci.yml setup-dkml.gen.gitlab-ci.yml)))
|}
      do_not_edit
  in
  let* (_exists : bool) = OS.Dir.create gl_dir in
  let* () = OS.File.write gl_dune_file dune_content in
  Ok ()

let scaffold_pc ~output_dir () =
  let pc_dir = Fpath.(output_dir / "pc") in
  let pc_dune_file = Fpath.(pc_dir / "dune") in
  let dune_content =
    Printf.sprintf
      {|%s
; windows_x86

(rule
 (target setup-dkml-windows_x86-gen.ps1)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-windows_x86 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-windows_x86.ps1 setup-dkml-windows_x86-gen.ps1)))

; windows_x86_64

(rule
 (target setup-dkml-windows_x86_64-gen.ps1)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-windows_x86_64 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-windows_x86_64.ps1 setup-dkml-windows_x86_64-gen.ps1)))

; darwin_x86_64

(rule
 (target setup-dkml-darwin_x86_64-gen.sh)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-darwin_x86_64 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-darwin_x86_64.sh setup-dkml-darwin_x86_64-gen.sh)))

; darwin_arm64

(rule
 (target setup-dkml-darwin_arm64-gen.sh)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-darwin_arm64 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-darwin_arm64.sh setup-dkml-darwin_arm64-gen.sh)))

; linux_x86

(rule
 (target setup-dkml-linux_x86-gen.sh)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-linux_x86 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-linux_x86.sh setup-dkml-linux_x86-gen.sh)))

; linux_x86_64

(rule
 (target setup-dkml-linux_x86_64-gen.sh)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (setenv
   OCAMLRUNPARAM
   b
   (run pc-setup-dkml --output-linux_x86_64 %%{target}))))

(rule
 (alias gen-dkml)
 (enabled_if %%{bin-available:pc-setup-dkml})
 (action
  (diff setup-dkml-linux_x86_64.sh setup-dkml-linux_x86_64-gen.sh)))
|}
      do_not_edit
  in
  let* (_exists : bool) = OS.Dir.create pc_dir in
  let* () = OS.File.write pc_dune_file dune_content in
  Ok ()

let scaffold ~output_dir () =
  let* (_exists : bool) = OS.Dir.create output_dir in
  let* () = scaffold_gh ~output_dir () in
  let* () = scaffold_gl ~output_dir () in
  let* () = scaffold_pc ~output_dir () in
  Ok ()

let () =
  (* Parse args *)
  let usage = Printf.sprintf "%s --output-file OUTPUT_FILE" exe_name in
  let anon _s = failwith "No command line arguments are supported" in
  let output_dir = ref "ci/setup-dkml" in
  Arg.parse
    [
      ( "--output-dir",
        Set_string output_dir,
        "Output directory. Defaults to " ^ !output_dir );
    ]
    anon exe_name;
  if String.equal "" !output_dir then failwith usage;
  let res = scaffold ~output_dir:(Fpath.v !output_dir) () in
  Rresult.R.failwith_error_msg res
