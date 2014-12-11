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

open Bigarray

type prec = CONCAT(CONCAT(float, SLAP_SDCZ_BITS), _elt)
type num_type = float
type 'a trans3 = 'a Common.trans2
let prec = CONCAT(float, SLAP_SDCZ_BITS)
let zero = 0.0
let one = 1.0
let lacaml_trans3 = Common.lacaml_trans2

#if SLAP_SDCZ_BITS = 32
module I = Lacaml.S
let module_name = "Slap.S"
#else
module I = Lacaml.D
let module_name = "Slap.D"
#endif

#include "slap_SDCZ_common.ml"

module Vec =
  struct
#include "slap_SDCZ_vec.ml"
#include "slap_SD_vec.ml"
  end

module Mat =
  struct
#include "slap_SDCZ_mat.ml"
#include "slap_SD_mat.ml"
  end

#include "slap_SDCZ_la.ml"
#include "slap_SD_la.ml"