open Tweetnacl
open Bip32_ed25519

module Crypto = struct
  open Digestif
  let sha256 s =
    s |> Cstruct.to_bigarray |> SHA256.Bigstring.digest |> Cstruct.of_bigarray
  let hmac_sha512 ~key s =
    let key = Cstruct.to_bigarray key in
    let s = Cstruct.to_bigarray s in
    SHA512.Bigstring.hmac ~key s |> Cstruct.of_bigarray
  let blake2b ~size s =
    s |>
    Cstruct.to_bigarray |>
    Sodium.Generichash.Bigbytes.digest ~size |>
    Sodium.Generichash.Bigbytes.of_hash |>
    Cstruct.of_bigarray
end

let c = (module Crypto : CRYPTO)

let basic () =
  let _seed, sk = random c in
  let pk = neuterize sk in
  let sk' = derive_exn c sk 0l in
  let pk' = derive_exn c pk 0l in
  let pk'' = neuterize sk' in
  assert (equal pk' pk'')

let serialization () =
  let _seed, ek = random c in
  let pk = neuterize ek in
  let ek1 = derive_exn c ek 32l in
  let cs = to_bytes ek in
  let ek' = of_ek_exn cs in
  assert (equal ek ek') ;
  let cs = to_bytes ek1 in
  let ek1' = of_ek_exn cs in
  assert (equal ek1 ek1') ;
  let cs = to_bytes pk in
  let pk' = of_pk_exn cs in
  assert (equal pk pk')

module HR = struct
  open Human_readable
  let of_string () =
    match of_string "44'/1'/0'/0/0" with
    | None -> assert false
    | Some [a; b; c; 0l; 0l] when
        a = to_hardened 44l &&
        b = to_hardened 1l &&
        c = to_hardened 0l -> ()
    | _ -> assert false

  let to_string () =
    let res =
      to_string [to_hardened 44l; to_hardened 1l; to_hardened 0l; 0l; 0l] in
    Printf.printf "%s\n%!" res ;
    assert (res = "44'/1'/0'/0/0") ;
    let res = to_string [] in
    assert (res = "") ;
    let res = to_string [to_hardened 2l; 123l] in
    assert (res = "2'/123")

  let of_string_exn_fail () =
    match of_string_exn "//" with
    | exception _ -> ()
    | _ -> assert false

  let of_string_exn_success () =
    ignore (of_string_exn "") ;
    ignore (of_string_exn "1/2") ;
    ignore (of_string_exn "1/2'/3'/0") ;
    ()
end

let basic = [
  "basic", `Quick, basic ;
  "serialization", `Quick, serialization ;
]

let human_readable = HR.[
    "of_string", `Quick, of_string ;
    "of_string_exn_fail", `Quick, of_string_exn_fail ;
    "of_string_exn_success", `Quick, of_string_exn_success ;
    "to_string", `Quick, to_string ;
  ]

let () =
  Alcotest.run "Bip32_ed25519" [
    "basic", basic ;
    "human_readable", human_readable ;
  ]
