---
layout: default
title: Sized Linear Algebra Package (SLAP)
---

What's SLAP?
------------

SLAP is a linear algebra library in OCaml with type-based static size checking
for matrix operations.

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

This [OCaml](http://ocaml.org/)-library is a wrapper of
[Lacaml](https://github.com/mmottl/lacaml), a binding of two widely used
linear algebra libraries BLAS (Basic Linear Algebra Subprograms) and LAPACK
(Linear Algebra PACKage) for FORTRAN.
This provides many useful and high-performance linear algebraic operations with
type-based static size checking, e.g., least squares problems, linear equations,
Cholesky, QR-factorization, eigenvalue problems and singular value decomposition
(SVD). Most of their interfaces are compatible with Lacaml functions.

Install
-------

OPAM installation:

```
$ opam install slap
```

Manual build (requiring [Lacaml](https://github.com/mmottl/lacaml) and
[cppo](http://mjambon.com/cppo.html)):

```
$ ./configure
$ make
$ make install
```

Documentation
-------------

- API documentation: http://akabe.github.io/slap/api/ (generated by `make doc`)
- PPX syntax extensions: http://akabe.github.io/slap/ppx/ (generated by `make doc`)
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

The following code
([examples/linsys/jacobi.ml](https://github.com/akabe/slap/blob/master/examples/linsys/jacobi.ml))
is simple demonstration for static size checking of SLAP. It is implementation
of [Jacobi method](http://en.wikipedia.org/wiki/Jacobi_method) (to solve a
system of linear equations). You do not need to understand the implementation.

```ocaml
open Slap.Io
open Slap.D
open Slap.Size
open Slap.Common

let jacobi a b =
  let d_inv = Vec.reci (Mat.diag a) in (* reciprocal numbers of diagonal elements *)
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

let () =
  let a = [%mat [5.0, 1.0, 0.0;
                 1.0, 3.0, 1.0;
                 0.0, 1.0, 4.0]] in
  let b = [%vec [7.0; 10.0; 14.0]] in
  let x = jacobi a b in
  Format.printf "a = @[%a@]@.b = @[%a@]@." pp_fmat a pp_rfvec b;
  Format.printf "x = @[%a@]@." pp_rfvec x;
  Format.printf "a*x = @[%a@]@." pp_rfvec (gemv ~trans:normal a x)
```

`jacobi a b` solves a system of linear equations `a * x = b` where `a` is
a n-by-n matrix, and `x` and `b` is a n-dimensional vectors.
Let's compile and execute this program:

```
$ git clone https://github.com/akabe/slap
$ cd slap/examples/linsys/
$ ocamlfind ocamlc -linkpkg -package slap,slap.ppx -short-paths jacobi.ml
$ ./a.out
a = 5 1 0
    1 3 1
    0 1 4
b = 7 10 14
x = 1 2 3
a*x = 7 10 14
```

OK, vector `x` is computed correctly (since `a*x = b` is satisfied).
`jacobi` has the following type:

```ocaml
val jacobi : ('n, 'n, _) mat -> ('n, _) vec -> ('n, _) vec
```

This means "`jacobi` gets a `'n`-by-`'n` matrix and a `'n`-dimensional vector,
and returns a `'n`-dimensional vector." If you pass arguments that do not
satisfy the condition, a type error happens and the compilation fails.
Try to modify any one of the dimensions of `a`, `b` and `x` in the above code,
e.g.,

```ocaml
...

let () =
  let a = ... in
  let b = [%vec [7.0; 10.0]] in (* remove the last element `14.0' *)
  ...
```

and compile the changed code. Then OCaml reports inconsistency of dimensions:

```ocaml
File "jacobi.ml", line 31, characters 19-20:
Error: This expression has type
         (two, 'a) vec = (two, float, rprec, 'a) Slap_vec.t
       but an expression was expected of type
         (three, 'b) vec = (three, float, rprec, 'b) Slap_vec.t
       Type two = z s s is not compatible with type three = z s s s
       Type z is not compatible with type z s
```

By using SLAP, your mistake (i.e., a bug) is captured at **compile time**!