(*
 * Copyright (c) 2004 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * $Id: ssh_config.ml,v 1.8 2006/03/16 08:28:51 avsm Exp $
 *)

open Ssh_utils

exception Config_error

module Server = struct
    (* Whether an auth succeeded, and any _other_ methods that
       must also succeed before it is considered a success.  These
       other methods might be on the basis of username.  The contents
       of this list MUST also be in the globally supported auth list
       returned by auth_methods_supported. *)
    type auth_response = bool * Userauth.t list
    type exec_response =
        (int * Unix.file_descr option * Unix.file_descr option * Unix.file_descr option) option

    type con_open_resp = 
      |Con_allow of (int32 * int32)
      |Con_deny of Message.Channel.OpenFailure.reason_code_t
end

module Client = struct
    type chanfn = Unix.file_descr -> int32 -> int32 ->
        Channel.pty_req option -> string option -> int32 option
end
    
class type client_config = object
    method verify_hostkey: Keys.PublicKey.t -> bool
    method auth_choose: Userauth.t list -> Userauth.t option
    method auth_banner: string -> unit
    method auth_username: string
    method auth_password: string
    method auth_success: Client.chanfn -> unit
    method channel_created: int32 -> bool option -> bool -> unit
    method channel_delete: int32 -> unit
end

class type server_config = object
    (* Initialize moduli for Gex key exchange *)
    method moduli_init : Kex.Methods.DHGex.moduli
    (* Servers RSA key, both private and public components required *)
    method get_rsa_key : Cryptokit.RSA.key
    (* An optional banner to display at start of authentication
       (actually only in response to an Auth.Req.None at the moment *)
    method auth_banner : string -> string option
    (* List of all the supported authentication methods *)
    method auth_methods_supported : Userauth.t list
    (* Callback to validate a username/password *)
    method auth_password : string -> string -> Server.auth_response
    (* Callback to validate a username/publickey *)
    method auth_public_key : string -> Message.Key.o -> Server.auth_response
    (* Client requests new session (window size * packet size) *)
    method connection_request : int32 -> int32 -> Server.con_open_resp
    (* Inform the library of a new connection, and its id *)
    method connection_add : Channel.channel -> unit
    (* Notify the library that the object is no longer valid *)
    method connection_del : Channel.channel -> unit
    (* Request a pty: id -> modes -> (row,col,xpix,ypix) -> (pty,pty_window) *)
    method connection_add_pty : Channel.channel -> string ->
        (int32 * int32 * int32 * int32) ->
        (Ounix.Pty.pty * Ounix.Pty.pty_window) option
    (* Request a command exec: id -> cmd -> exec_response *)
    method connection_request_exec : Channel.channel -> string -> Server.exec_response
    (* Request a shell : id -> exec_response *)
    method connection_request_shell : Channel.channel ->
        (Ounix.Pty.pty * Ounix.Pty.pty_window) option -> Server.exec_response

end
