(**
 * Copyright (c) 2015, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

let dump_filesinfo fn files_info =
  let chan = Sys_utils.open_out_no_fail fn in
  let saved = FileInfo.info_to_saved files_info in
  Marshal.to_channel chan saved [];
  Sys_utils.close_out_no_fail fn chan

let update_save_state ~file_info_on_disk files_info fn t =
  let db_name = fn ^ ".sql" in
  if not (Disk.file_exists db_name) then
    failwith "Given existing save state SQL file missing";
  dump_filesinfo fn files_info;
  let () = if file_info_on_disk then
    SharedMem.save_file_info_sqlite db_name |> ignore
  else () in
  let sqlite_save_t = SharedMem.update_dep_table_sqlite db_name Build_id.build_revision in
  Hh_logger.log "Updating deptable using sqlite took(seconds): %d" sqlite_save_t;
  ignore @@ Hh_logger.log_duration "Updating saved state took" t

let save_state ~file_info_on_disk files_info fn t =
  let () = Sys_utils.mkdir_p (Filename.dirname fn) in
  let db_name = fn ^ ".sql" in
  let () = if Sys.file_exists fn then
             failwith (Printf.sprintf "Cowardly refusing to overwrite '%s'." fn)
           else () in
  let () = if Sys.file_exists db_name then
             failwith (Printf.sprintf "Cowardly refusing to overwrite '%s'." db_name)
           else () in
  match SharedMem.loaded_dep_table_filename () with
  | None ->
    dump_filesinfo fn files_info;
    let () = if file_info_on_disk then
      SharedMem.save_file_info_sqlite db_name |> ignore
    else () in
    let sqlite_save_t = SharedMem.save_dep_table_sqlite db_name Build_id.build_revision in
    Hh_logger.log "Saving deptable using sqlite took(seconds): %d" sqlite_save_t;
    ignore @@ Hh_logger.log_duration "Saving saved state took" t
  | Some old_table_fn ->
    (** If server is running from a loaded saved state, it's in-memory
     * tracked depdnencies are incomplete - most of the actual dependencies
     * are in the SQL table. We need to copy that file and update it with
     * the in-memory edges. *)
    let content = Sys_utils.cat old_table_fn in
    let () = Sys_utils.mkdir_p (Filename.dirname fn) in
    let () = Sys_utils.write_file ~file:db_name content in
    let t = Hh_logger.log_duration "Made disk copy of loaded saved state. Took" t in
    update_save_state ~file_info_on_disk files_info fn t

let go ~file_info_on_disk files_info filename =
  Core_result.try_with (fun () ->
    let t = Unix.gettimeofday () in
    save_state ~file_info_on_disk files_info filename t)
  |> Core_result.map_error ~f:Printexc.to_string
