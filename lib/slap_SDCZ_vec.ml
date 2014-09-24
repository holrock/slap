(* Sized Linear Algebra Package (SLAP)

   Copyright (C) 2013- Akinori ABE <abe@kb.ecei.tohoku.ac.jp>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*)

module type CNTVEC =
  sig
    type n
    val value : (n, 'cnt) vec
  end

module type DSCVEC =
  sig
    type n
    val value : (n, dsc) vec
  end

let cnt = PVec.cnt

(** {2 Creation of vectors} *)

let empty = PVec.create prec 0

let create n = PVec.create prec n

let make n a = PVec.make prec n a

let make0 n = make n zero

let make1 n = make n one

let init n f = PVec.init prec n f

(** {2 Accessors} *)

let dim = PVec.dim

let get_dyn = PVec.get_dyn

let set_dyn = PVec.set_dyn

let unsafe_get = PVec.unsafe_get

let unsafe_set = PVec.unsafe_set

let replace_dyn = PVec.replace_dyn

(** {2 Basic operations} *)

let copy ?y (n, ofsx, incx, x) =
  let ofsy, incy, y = PVec.opt_vec_alloc prec n y in
  let _ = I.copy ~n ~ofsy ~incy ~y ~ofsx ~incx x in
  (n, ofsy, incy, y)

let fill = PVec.fill

let append = PVec.append

let shared_rev = PVec.shared_rev

let rev = PVec.rev

(** {2 Type conversion} *)

let to_array = PVec.to_array

let of_array_dyn n array = PVec.of_array_dyn prec n array

module Of_array (X : sig val value : num_type array end) : CNTVEC =
  struct
    type n
    let value = PVec.unsafe_of_array prec (Array.length X.value) X.value
  end

let of_array a =
  let module V = Of_array(struct let value = a end) in
  (module V : CNTVEC)

let to_list = PVec.to_list

let of_list_dyn n list = PVec.of_list_dyn prec n list

module Of_list (X : sig val value : num_type list end) : CNTVEC =
  struct
    type n
    let value = PVec.unsafe_of_list prec (List.length X.value) X.value
  end

let of_list l =
  let module V = Of_list(struct let value = l end) in
  (module V : CNTVEC)

let to_bigarray = PVec.to_bigarray

let of_bigarray_dyn = PVec.of_bigarray_dyn

module Of_bigarray (X : sig
                          val share : bool
                          val value : (num_type, prec, fortran_layout) Array1.t
                        end) : CNTVEC =
  struct
    type n
    let value = PVec.unsafe_of_bigarray ~share:X.share
                                        (Array1.dim X.value) X.value
  end

let of_bigarray ?(share=false) ba =
  let module V = Of_bigarray(struct let share = share
                                    let value = ba end) in
  (module V : CNTVEC)

(** {2 Iterators} *)

let map = PVec.map prec

let mapi = PVec.mapi prec

let fold_left = PVec.fold_left

let fold_lefti = PVec.fold_lefti

let fold_right = PVec.fold_right

let fold_righti = PVec.fold_righti

let replace_all = PVec.replace_all

let replace_alli = PVec.replace_alli

let iter = PVec.iter

let iteri = PVec.iteri

(** {2 Iterators on two vectors} *)

let map2 = PVec.map2 prec

let mapi2 = PVec.mapi2 prec

let fold_left2 = PVec.fold_left2

let fold_lefti2 = PVec.fold_lefti2

let fold_right2 = PVec.fold_right2

let fold_righti2 = PVec.fold_righti2

let iter2 = PVec.iter2

let iteri2 = PVec.iteri2

(** {2 Iterators on three vectors} *)

let map3 = PVec.map3 prec

let mapi3 = PVec.mapi3 prec

let fold_left3 = PVec.fold_left3

let fold_lefti3 = PVec.fold_lefti3

let fold_right3 = PVec.fold_right3

let fold_righti3 = PVec.fold_righti3

let iter3 = PVec.iter3

let iteri3 = PVec.iteri3

(** {2 Scanning} *)

let for_all = PVec.for_all

let exists = PVec.exists

let for_all2 = PVec.for_all2

let exists2 = PVec.exists2

(** {2 Arithmetic operations} *)

let max (n, ofsx, incx, x) = I.Vec.max ~n ~ofsx ~incx x

let min (n, ofsx, incx, x) = I.Vec.min ~n ~ofsx ~incx x

let sum (n, ofsx, incx, x) = I.Vec.sum ~n ~ofsx ~incx x

let prod (n, ofsx, incx, x) = I.Vec.prod ~n ~ofsx ~incx x

let add_const c ?y (n, ofsx, incx, x) =
  let ofsy, incy, y = PVec.opt_vec_alloc prec n y in
  ignore (I.Vec.add_const c ~n ~ofsy ~incy ~y ~ofsx ~incx x);
  (n, ofsy, incy, y)

let sqr_nrm2 ?stable (n, ofsx, incx, x) =
  I.Vec.sqr_nrm2 ?stable ~n ~ofsx ~incx x

let ssqr ?c (n, ofsx, incx, x) =
  I.Vec.ssqr ~n ?c ~ofsx ~incx x

let sort ?cmp ?decr ?p (n, ofsx, incx, x) =
  match p with
  | None ->
     I.Vec.sort ?cmp ?decr ~n ~ofsx ~incx x
  | Some (n', ofsp, incp, p) ->
     assert(n = n');
     I.Vec.sort ?cmp ?decr ~n ~ofsp ~incp ~p ~ofsx ~incx x

let neg ?y (n, ofsx, incx, x) =
  let ofsy, incy, y = PVec.opt_vec_alloc prec n y in
  let _ = I.Vec.neg ~n ~ofsy ~incy ~y ~ofsx ~incx x in
  (n, ofsy, incy, y)

let reci ?y (n, ofsx, incx, x) =
  let ofsy, incy, y = PVec.opt_vec_alloc prec n y in
  ignore (I.Vec.reci ~n ~ofsy ~incy ~y ~ofsx ~incx x);
  (n, ofsy, incy, y)

let add ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.add ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let sub ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.sub ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let mul ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.mul ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let div ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.div ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let zpxy ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.zpxy ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let zmxy ?z (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  let ofsz, incz, z = PVec.opt_vec_alloc prec n z in
  let _ = I.Vec.zmxy ~n ~ofsz ~incz ~z ~ofsx ~incx x ~ofsy ~incy y in
  (n, ofsz, incz, z)

let ssqr_diff (n, ofsx, incx, x) (n', ofsy, incy, y) =
  assert(n = n');
  I.Vec.ssqr_diff ~n ~ofsx ~incx x ~ofsy ~incy y

(** {2 Subvectors} *)

let subcntvec_dyn = PVec.subcntvec_dyn

let subdscvec_dyn = PVec.subdscvec_dyn

let subvec_dyn = PVec.subvec_dyn