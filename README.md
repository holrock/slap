Sized Linear Algebra Package (SLAP)
===================================

SLAP is a linear algebra library in [OCaml](http://ocaml.org/) with type-based
static size checking for matrix operations.

Many programming languages for numerical analysis (e.g.,
[MatLab](http://www.mathworks.com/products/matlab/),
[GNU Octave](https://www.gnu.org/software/octave/),
[SciLab](http://www.scilab.org/), etc.) and linear algebra libraries (e.g.,
[BLAS](http://www.netlib.org/blas/), [LAPACK](http://www.netlib.org/lapack/),
[NumPy](http://www.numpy.org/), etc.) do not statically (i.e., at compile time)
guarantee consistency of dimensions of vectors and matrices.
Dimensional inconsistency, e.g., addition of two- and three-dimensional vectors
causes runtime errors like memory corruption or wrong computation.

SLAP helps your debug by detecting inconsistency of dimensions

- at **compile time** (instead of runtime) and
- at **higher level** (i.e., at a caller site rather than somewhere deep inside
  of a call stack).

For example, addition of vectors of different sizes causes a type error
at compile time, and dynamic errors such as exceptions do **not** happen.
For most high-level matrix operations, the consistency of sizes is verified
statically. (Certain low-level operations, like accesses to elements by indices,
need dynamic checks.)

This library is a wrapper of [Lacaml](https://github.com/mmottl/lacaml), a
binding of two widely used linear algebra libraries BLAS (Basic Linear Algebra
Subprograms) and LAPACK (Linear Algebra PACKage) for FORTRAN.
This provides many useful and high-performance linear algebraic operations with
type-based static size checking, e.g., least squares problems, linear equations,
Cholesky, QR-factorization, eigenvalue problems and singular value decomposition
(SVD). Most of their interfaces are compatible with Lacaml functions.

Install
-------

OPAM installation:

```
opam install slap
```

Manual build (requiring [Lacaml](https://github.com/mmottl/lacaml) and
[cppo](http://mjambon.com/cppo.html)):

```
./configure
make
make install
```

Documentation
-------------

- Web page: http://akabe.github.io/slap/
  - Tutorial: http://akabe.github.io/slap/usage.html
  - Online API documentation: http://akabe.github.io/slap/api/
    (generated by `make doc`).
- This library interface was announced at
  [ML Family Workshop 2014](http://okmij.org/ftp/ML/ML14.html) in Gothenburg,
  Sweden: A Simple and Practical Linear Algebra Library Interface with Static
  Size Checking, by Akinori Abe and Eijiro Sumii (Tohoku University).
  [PDF Abstract](https://ocaml.org/meetings/ocaml/2014/ocaml2014_19.pdf),
  [PDF Slides](https://ocaml.org/meetings/ocaml/2014/abe-sumii-slides.pdf),
  [PDF Supplement](https://akabe.github.io/sgpr/changes.pdf).
  (The talk was accepted by
  [OCaml Workshop 2014](https://ocaml.org/meetings/ocaml/2014/), but it was
  presented at ML Workshop.)

Demo
----

The following code ([examples/linsys/jacobi.ml](examples/linsys/jacobi.ml))
is an implementation of
[Jacobi method](http://en.wikipedia.org/wiki/Jacobi_method) (to solve
system of linear equations).

```ocaml
open Slap.Io
open Slap.D
open Slap.Size
open Slap.Common

let jacobi a b =
  let d_inv = Vec.reci (Mat.diag a) in (* reciprocal diagonal elements *)
  let r = Mat.mapi (fun i j aij -> if i = j then 0.0 else aij) a in
  let y = Vec.create (Vec.dim b) in (* temporary memory *)
  let rec loop z x =
    ignore (copy ~y b); (* y := b *)
    ignore (gemv ~y ~trans:normal ~alpha:(-1.0) ~beta:1.0 r x); (* y := y-r*x *)
    ignore (Vec.mul ~z d_inv y); (* z := element-wise mult. of d_inv and y *)
    if Vec.ssqr_diff x z < 1e-10 then z else loop x z (* Check convergence *)
  in
  let x0 = Vec.make (Vec.dim b) 1.0 in (* the initial values of `x' *)
  let z = Vec.create (Vec.dim b) in (* temporary memory *)
  loop z x0

let _ =
  let a = Mat.init four four (fun i j -> let p = float_of_int (i - j) in
                                         exp (~-. p *. p)) in
  let b = Vec.init four (fun i -> float_of_int i) in
  let x = jacobi a b in
  Format.printf "a = @[%a@]@.b = @[%a@]@." pp_fmat a pp_rfvec b;
  Format.printf "x = @[%a@]@." pp_rfvec x;
  Format.printf "a*x = @[%a@]@." pp_rfvec (gemv ~trans:normal a x)
```

`jacobi a b` solves a system of linear equations `a * x = b` where `a` is
a n-by-n matrix, and `x` and `b` is a n-dimensional vectors. This code can
be compiled by `ocamlfind ocamlc -linkpkg -package slap jacobi.ml`, and
`a.out` outputs:

```ocaml
a =          1  0.367879 0.0183156 0.00012341
      0.367879         1  0.367879  0.0183156
     0.0183156  0.367879         1   0.367879
    0.00012341 0.0183156  0.367879          1
b = 1 2 3 4
x = 0.496539 1.30705 1.21131 3.53038
a*x = 0.999998 2 3 4
```

OK. Vector `x` is computed. Try to modify any one of
the dimensions of `a`, `b` and `x` in the above code, e.g.,

```ocaml
...

let _ =
  let a = Mat.init four five (fun i j -> ...
  ...
```

and compile the changed code. Then OCaml reports a type error (not a runtime
error like an exception):

```ocaml
Error: This expression has type
  (z s s s s, z s s s s s, 'a) mat = (z s s s s, z s s s s s, float, rprec, 'a) Slap.Mat.t
but an expression was expected of type
  (z s s s s, z s s s s, 'b) mat = (z s s s s, z s s s s, float, rprec, 'b) Slap.Mat.t
Type z s is not compatible with type z
```

By using SLAP, your mistake (i.e., a bug) is captured at **compile time**!

Usage
-----

The following modules provide useful linear algebraic operations including
BLAS and LAPACK functions.

- `Slap.S`: Single-precision (32-bit) real numbers
- `Slap.D`: Double-precision (64-bit) real numbers
- `Slap.C`: Single-precision (32-bit) complex numbers
- `Slap.Z`: Double-precision (64-bit) complex numbers

### Simple computation

#### Dimensions (sizes)

`Slap.Size` provides operations on _sizes_ (i.e., natural numbers as dimensions
of vectors and matrices) of curious types. Look at the type of `Slap.Size.four`:

```ocaml
# open Slap.Size;;
# four;;
- : z s s s s t = 4
```

Types `z` and `'n s` correspond to zero and `'n + 1`, respectively. Thus,
`z s s s s` represents 0+1+1+1+1 = 4. `'n t` (= `'n Slap.Size.t`) is a
_singleton type_ on natural numbers; i.e., evaluation of a term (i.e.,
expression) of type `'n t` **always** results in the natural number
corresponding to  `'n`. Therefore `z s s s s t` is the type of terms always
evaluated to four.

#### Vectors

Creation of a four-dimensional vector:

```ocaml
# open Slap.D;;
# let x = Vec.init four (fun i -> float_of_int i);;
val x : (z s s s s, 'a) vec = R1 R2 R3 R4
                               1  2  3  4
```

`Vec.init` creates a vector initialized by the given function. `('n, 'a) vec` is
the type of `'n`-dimensional vectors. So `(z s s s s, 'a) vec` is the type of
four-dimensional vectors. (Description of the second type parameter is omitted.)

Vectors of different dimensions **always** have different types:

```ocaml
# let y = Vec.init five (fun i -> float_of_int i);;
val y : (z s s s s s, 'a) vec = R1 R2 R3 R4 R5
                                 1  2  3  4  5
```

The addition of four-dimensional vector `x` and five-dimensional vector `y`
causes a type error (at compile time):

```ocaml
# Vec.add x y;;
Error: This expression has type
  (z s s s s s, 'a) vec = (z s s s s s, float, rprec, 'a) Slap.Vec.t
but an expression was expected of type
  (z s s s s, 'b) vec = (z s s s s, float, rprec, 'b) Slap.Vec.t
Type z s is not compatible with type z
```

Of course, addition of vectors of the same dimension succeeds:

```ocaml
# let z = Vec.map (fun c -> c *. 2.0) x;;
val z : (z s s s s, 'a) vec = R1 R2 R3 R4
                               2  4  6  8
# Vec.add x z;;
- : (z s s s s, 'a) vec = R1 R2 R3 R4
                           3  6  9 12
```

#### Matrices

Creation of a 3-by-5 matrix:

```ocaml
# let a = Mat.init three five (fun i j -> float_of_int (10 * i + j));;
val a : (z s s s, z s s s s s, 'a) mat =
     C1 C2 C3 C4 C5
  R1 11 12 13 14 15
  R2 21 22 23 24 25
  R3 31 32 33 34 35
```

`('m, 'n, 'a) mat` is the type of `'m`-by-`'n` matrices. Thus
`(z s s s, z s s s s s, 'a) mat` is the type of 3-by-5 matrices. (Description of
the third type parameter is omitted.)

BLAS function `gemm` multiplies two general matrices:

```ocaml
gemm ?beta ?c ~transa ?alpha a ~transb b
```

executes `c := alpha * a * b + beta * c` with matrices `a`, `b` and `c`, and
scalar values `alpha` and `beta`. The parameters `transa` and `transb` specify
no transpose (`Slap.Common.normal`), transpose (`Slap.Common.trans`) or
conjugate transpose (`Slap.Common.conjtr`) of matrices `a` and `b`,
respectively. (`conjtr` can be used only for complex operations in `Slap.C`
and `Slap.Z`.) For example, if `transa`=`normal` and `transb`=`trans`, then
`gemm` executes `c := alpha * a * b^T + beta * c` (where `b^T` is the transpose
of `b`). When you compute `a * a^T` by `gemm`, a 3-by-3 matrix is returned since
`a` is a 3-by-5 matrix:

```ocaml
# open Slap.Common;;
# gemm ~transa:normal ~transb:trans a a;;
- : (z s s s, z s s s, 'a) mat =
     C1   C2   C3
R1  855 1505 2155
R2 1505 2655 3805
R3 2155 3805 5455
```

`a * a` causes a type error since the number of columns of the first matrix is
not equal to the number of rows of the second matrix:

```ocaml
# gemm ~transa:normal ~transb:normal a a;;
Error: This expression has type
  (z s s s, z s s s s s, 'a) mat =
  (z s s s, z s s s s s, float, rprec, 'a) Slap.Mat.t
but an expression was expected of type
  (z s s s s s, 'b, 'c) mat =
  (z s s s s s, 'b, float, rprec, 'c) Slap.Mat.t
Type z is not compatible with type z s s
```

### Sizes decided at runtime

SLAP can safely treat sizes that are unknown until runtime
(e.g., the dimension of a vector loaded from a file)!
Unfortunately, SLAP does not provide functions to load a
vector or a matrix from a file. (Maybe such operations will be implemented.)
You need to write a function to load a list or an array from a file
and call a SLAP function to convert it to a vector or a matrix.

Conversion of a list into a vector:

```ocaml
# module X = (val Vec.of_list [1.; 2.; 3.] : Vec.CNTVEC);;
module X : Slap.D.Vec.CNTVEC
```

The returned module `X` has the following signature:

```ocaml
module type Slap.D.Vec.CNTVEC = sig
  type n (* a type to represent the dimension of a vector *)
  val value : (n, 'cnt) vec (* the instance of a vector *)
end
```

The instance of a vector is `X.value`:

```ocaml
# X.value;;
- : (X.n, 'cnt) vec = R1 R2 R3
                       1  2  3
```

It can be treated as stated above. It's very easy!

You can also convert a list into a matrix:

```ocaml
# module A = (val Mat.of_list [[1.; 2.; 3.];
                               [4.; 5.; 6.]] : Mat.CNTMAT);;
# A.value;;
- : (A.m, A.n, 'cnt) mat =    C1 C2 C3
                           R1  1  2  3
                           R2  4  5  6
```

#### Idea of generative phantom type

In this section, we explain our basic idea of static size checking. For
example, let's think about the function `loadvec : string -> (?, _) vec`.
It returns a vector of some dimension, loaded from the given path.
The dimension is decided at **runtime**, but we need to type it at
**compile time**. How do we represent the return type `?`?
Consider the following code for example:

```ocaml
let (x : (?1, _) vec) = loadvec "file1" in
let (y : (?2, _) vec) = loadvec "file2" in
Vec.add x y
```

The third line should be ill-typed because the dimensions of `x` and `y` are
probably different. (Even if `"file1"` and `"file2"` were the same path, the
addition should be ill-typed because the file might change between the two
loads.) Thus, the return type of `loadvec` should be different every time it is
called (regardless of the specific values of the argument). We call such a
return type _generative_ because the function returns a value of a fresh type
for each call. The vector type with generative size information essentially
corresponds to an existentially quantified sized type like `exists n. n vec`.

Type parameters `'m`, `'n` and `'a` of types `'n Size.t`, `('n, 'a) vec` and
`('m, 'n, 'a) mat` are _phantom_, meaning that they do not appear on the right
hand side of the type definition. A phantom type parameter is often instantiated
with a type that has no value (i.e., no constructor) which we call a
_phantom type_. Then we call the type `?` a _generative phantom type_.

Actually, type `X.n` (returned by `Vec.of_list`) is different for each call of
the function, i.e., a generative phantom type:

```ocaml
# module Y = (val Vec.of_list [4.; 5.] : Vec.CNTVEC);;
# Vec.add X.value Y.value;;
Error: This expression has type
  (Y.n, 'a) vec = (Y.n, float, rprec, 'a) Slap.Vec.t
but an expression was expected of type
  (X.n, 'b) vec = (X.n, float, rprec, 'b) Slap.Vec.t
Type Y.n is not compatible with type X.n
```

#### Addition of vectors loaded from different files

When you want to add vectors loaded from different files, you can use
`Vec.of_list_dyn`:

```ocaml
val Vec.of_list_dyn : 'n Size.t -> float list -> ('n, 'cnt) vec
```

It also converts a list into a vector, but differs from `Vec.of_list`: You need
to give the length of a list to the first parameter as a size. For example, if
you consider that two lists `lst1` and `lst2` (loaded from different files) have
the same length, you can add them as follows:

```ocaml
# let lst1 = [1.; 2.; 3.; 4.; 5.];; (* loaded from a file *)
val lst1 : float list = [1.; 2.; 3.; 4.; 5.]
# let lst2 = [6.; 7.; 8.; 9.; 10.];; (* loaded from another file *)
val lst2 : float list = [6.; 7.; 8.; 9.; 10.]
# module X = (val Vec.of_list lst1 : Vec.CNTVEC);;
module X : Slap.D.Vec.CNTVEC
# let y = Vec.of_list_dyn (Vec.dim X.value) lst2;;
val y : (X.n, 'a) vec = R1 R2 R3 R4 R5
                         6  7  8  9 10
# Vec.add X.value y;;
- : (X.n, 'a) vec = R1 R2 R3 R4 R5
                     7  9 11 13 15
```

`Vec.of_list` raises an **exception** (at runtime) if the given size is not
equal to the length, i.e., the lengths of `lst1` and `lst2`
are different in the above case. This dynamic check is unavoidable because the
equality of sizes of two vectors loaded from different files cannot be
statically guaranteed. We gave functions containing dynamic checks the suffix
`_dyn`.

Advanced information
--------------------

### Size constraints

When a matrix operation is implemented by low-level index-based accesses, its
size constraints cannot be inferred statically (since they are checked only at
runtime): For example, consider the function `axby`, which calculates
`alpha * x + beta * y` with scalar values `alpha` and `beta`, and vectors `x`
and `y`:

```ocaml
open Slap.D

let axby alpha x beta y =
  let n = Vec.dim x in
  let z = Vec.create n in
  for i = 1 to Slap.Size.to_int n do
    let p = alpha *. (Vec.get_dyn x i) +. beta *. (Vec.get_dyn y i) in
    Vec.set_dyn z i p
  done;
  z
```

The dimensions of vectors `x` and `y` must be the same, but OCaml infers that
they may be different:

```ocaml
val axby : float -> ('n, _) vec -> float -> ('m, _) vec -> ('n, _) vec
```

There are two ways to solve this problem.

##### 1. To write size constraints by hand

One is to type-annotate `axby` by hand:

```ocaml
let axby alpha (x : ('n, _) vec) beta (y : ('n, _) vec) =
  ...
```

##### 2. To use high-level matrix operations (recommended)

The other way is to use high-level operations such as `map`, `fold`, BLAS and
LAPACK functions instead of low-level operations such as `get_dyn` and
`set_dyn`:

```ocaml
let axby alpha x beta y =
  let z = copy y in (* z = y *)
  scal beta z; (* z := beta * z *)
  axpy ~alpha ~x y; (* z := alpha * x + z *)
  z
```

or

```ocaml
let axby alpha x beta y =
  Vec.map2 (fun xi yi -> alpha *. xi +. beta *. yi) x y
```

In this case, size constraints are automatically inferred by OCaml.
We strongly recommend this way.

### Escaping generative phantom types

Consider a function that converts an array of strings into a vector:

```ocaml
open Slap.D

let vec_of_str_array a =
  let module N = Slap.Size.Of_int_dyn(struct let value = Array.length a end) in
  Vec.init N.value (fun i -> float_of_string a.(i-1))

let main () =
  let a = [| "1"; "2"; "3" |] in
  let v = vec_of_str_array a in
  Format.printf "%a\n" pp_vec v
```

`Slap.Size.Of_int_dyn` converts an integer into a size and returns a module
containing a generative phantom type (cf. `Vec.of_list`).
OCaml cannot compile this code because the generative phantom type `N.n`
escapes its scope:

```
Error: This expression has type
  (N.n, 'a) vec = ('b, float, rprec, 'c) Slap.Vec.t
but an expression was expected of type (N.n, 'a) vec
The type constructor N.n would escape its scope
```

There are two ways to handle this in SLAP.

##### 1. To add extra arguments

One is to insert the argument `n` for the size of the array, and remove the
generative phantom type from the function:

```ocaml
open Slap.Size
open Slap.D

(* val vec_of_str_array : 'n Size.t -> string array -> ('n, _) vec *)
let vec_of_str_array n a =
  if to_int n <> Array.length a then invalid_arg "error";
  Vec.init n (fun i -> float_of_string a.(i-1))

let main () =
  let a = [| "1"; "2"; "3" |] in
  let module N = (val of_int_dyn (Array.length a) : SIZE) in
  let v = vec_of_str_array N.value a in
  Format.printf "%a\n" pp_vec v
```

In this case, programming is easy because the code is simple, but whether `n` is
equal to the length of `a` should be **dynamically** checked.

##### 2. To use first-class modules

Another way is to use a first-class module and
return a module containing the generative phantom type:

```ocaml
open Slap.Size
open Slap.D

(* val vec_of_str_array : string array -> (module SIZE) *)
let vec_of_str_array a =
  let module N = (val of_int_dyn (Array.length a) : SIZE) in
  let module V = struct
    type n = N.n
    let value = Vec.init N.value (fun i -> float_of_string a.(i-1))
  end in
  (module V : Vec.CNTVEC)

let main () =
  let a = [| "1"; "2"; "3" |] in
  let module V = (val vec_of_str_array a : Vec.CNTVEC) in
  Format.printf "%a\n" pp_vec V.value
```

In the latter case, dynamic check is not needed, but programming is (slightly)
hard due to the heavy syntax and the type annotations (i.e., signatures) of
modules.

##### Trade-off of two solutions

Both solutions have merits and demerits. In practical cases, they are in a
trade-off relationship:

|                        | generative phantom types         | static size checking | programming     |
|:-----------------------|:--------------------------------:|:--------------------:|:---------------:|
| 1. extra arguments     | given from outside of a function | no                   | **easy**        |
| 2. first-class modules | created in a function            | **yes**              | (slightly) hard |