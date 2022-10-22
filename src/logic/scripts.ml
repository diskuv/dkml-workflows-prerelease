open Astring
open Jingoo

let indent ~pad s =
  String.cuts ~sep:"\n" s
  |> List.mapi (fun i s' -> if i > 0 then pad ^ s' else s')
  |> String.concat ~sep:"\n"

let variations = [ ("gh_", "        "); ("gl_", "      ") ]

(* literally from https://erratique.ch/software/uutf/doc/Uutf/index.html#examples *)
let recode ?nln ?encoding out_encoding
    (src : [ `Channel of in_channel | `String of string ])
    (dst : [ `Channel of out_channel | `Buffer of Buffer.t ]) =
  let rec loop d e =
    match Uutf.decode d with
    | `Uchar _ as u ->
        ignore (Uutf.encode e u);
        loop d e
    | `End -> ignore (Uutf.encode e `End)
    | `Malformed _ ->
        ignore (Uutf.encode e (`Uchar Uutf.u_rep));
        loop d e
    | `Await -> assert false
  in
  let d = Uutf.decoder ?nln ?encoding src in
  let e = Uutf.encoder out_encoding dst in
  loop d e

let f ~read_script (name, scriptname) =
  match read_script scriptname with
  | None -> failwith (Printf.sprintf "The script %s was not found" scriptname)
  | Some script ->
      List.map
        (fun (name_prefix, pad) ->
          (* Transcode to UTF-8 for output in YAML, especially Powershell
             scripts which are usually UTF-16BE or UTF-16LE *)
          let buf = Buffer.create (String.length script) in
          recode `UTF_8 (`String script) (`Buffer buf);
          let script_utf8 = Bytes.to_string (Buffer.to_bytes buf) in
          (* Indent and return *)
          let indented = indent ~pad script_utf8 in
          (name_prefix ^ name, Jg_types.Tstr indented))
        variations

let to_vars read_script =
  List.map (f ~read_script)
    [
      ("common_values_script", "common-values.sh");
      ("setup_dkml_script", "setup-dkml.sh");
      ("checkout_code_script", "checkout-code.sh");
      ("config_vsstudio_ps1", "config-vsstudio.ps1");
      ("get_msvcpath_cmd", "get-msvcpath.cmd");
      ("msvcenv_awk", "msvcenv.awk");
      ("msvcpath_awk", "msvcpath.awk");
    ]
  |> List.flatten
