let read_version ~version_file =
  let ic = open_in version_file in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () ->
      let first_line = input_line ic in
      String.trim first_line)

let () =
  let anon (_ : string) = () in
  let opam_file = ref "" in
  let version_file = ref "" in
  Arg.parse
    Arg.
      [
        ( "--version-file",
          Set_string version_file,
          "The file containing the version number" );
        ( "--opam-file",
          Set_string opam_file,
          "The .opam file (or .opam.template) which may need to be adjusted \
           with new versions" );
      ]
    anon "dkml-bump-source";
  if String.equal !opam_file "" then failwith "Missing --opam-file OPAMFILE";
  if String.equal !version_file "" then
    failwith "Missing --version-file OPAMFILE";

  let version = read_version ~version_file:!version_file in
  prerr_endline version
