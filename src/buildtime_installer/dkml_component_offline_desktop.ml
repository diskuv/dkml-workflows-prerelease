(* Cmdliner 1.0 -> 1.1 deprecated a lot of things. But until Cmdliner 1.1
   is in common use in Opam packages we should provide backwards compatibility.
   In fact, Diskuv OCaml is not even using Cmdliner 1.1. *)
[@@@alert "-deprecated"]
   
open Dkml_install_api
open Dkml_install_register
open Bos

let execute_install ctx =
  if Context.Abi_v2.is_windows ctx.Context.target_abi_v2 then
    Staging_ocamlrun_api.spawn_ocamlrun ctx
      Cmd.(
        v
          (Fpath.to_string
             (ctx.Context.path_eval
                "%{staging-desktop:share-generic}%/windows_install.bc"))
        %% Log_config.to_args ctx.Context.log_config
        % "--tmp-dir"
        % Fpath.to_string (ctx.Context.path_eval "%{tmp}%")
        % "--target-msys2-dir"
        % Fpath.to_string (ctx.Context.path_eval "%{prefix}%/tools/MSYS2")
        % "--target-sh"
        % Fpath.to_string
            (ctx.Context.path_eval "%{prefix}%/tools/desktop/bin/sh.exe")
        % "--curl-exe"
        % Fpath.to_string
            (ctx.Context.path_eval "%{staging-curl:share-abi}%/bin/curl.exe")
        %%
        match ctx.Context.target_abi_v2 with
        | Windows_x86 -> v "--32-bit"
        | _ -> empty)
  else
    Staging_ocamlrun_api.spawn_ocamlrun ctx
      Cmd.(
        v
          (Fpath.to_string
             (ctx.Context.path_eval
                "%{staging-desktop:share-generic}%/unix_install.bc"))
        % "-target-sh"
        % Fpath.to_string
            (ctx.Context.path_eval "%{prefix}%/tools/desktop/bin/sh"))

let register () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "offline-desktop"

      let install_depends_on = [ "staging-ocamlrun"; "staging-desktop" ]

      let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t
          =
        let doc = "Install Unix utilities" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Term.
              (const execute_install $ ctx_t, info subcommand_name ~doc),
            fl )

      let uninstall_user_subcommand ~component_name:_ ~subcommand_name ~fl
          ~ctx_t =
        let doc = "Uninstall Unix utilities" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Term.
              ( const Dkml_component_common_desktop.execute_uninstall $ ctx_t,
                info subcommand_name ~doc ),
            fl )
    end)
