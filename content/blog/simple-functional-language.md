---
date: 2015-11-01T15:59:38-04:00
title: "Implementing a simple functional language using Makam"
type: post
draft: true
---

Ideas for new features in programming languages come in various forms: from something as simple as
having a cleaner syntax for an existing language (e.g. [CoffeeScript](http://coffeescript.org/)), to
adding new type system features -- for example, the borrow checker that enables safe manual memory
management in [Rust](http://rust-lang.org/).

Implementing a new syntax is comparatively easy: all one needs to do is write a grammar for it, and
use a parser generator like Yacc and ANTLR to get an efficient parser. Grammars describe *what* to
parse, instead of *how* to parse it; as a result they are much more readable than a parser itself,
more amenable to change, and can serve as the canonical reference of the new syntax. Still, efficient
executable code can be generated based on that description.

Wouldn't it be great if there existed a similar formalism to describe all the parts of a programming
language implementation, instead of just the parser?

<!--more-->

While this is very much still an open research direction, one candidate for such a formalism is
*higher-order logic programming* and the [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/) language.
This is a formalism that solves some ubiquitous challenges in language implementation and enables
concise and readable descriptions of advanced type systems, compilation phases, etc. These descriptions
are executable, so they can be used directly as a prototype implementation.

**Makam** is a new implementation of λProlog that I've been working on for a while, and is meant to
be used as a language prototyping tool. In this post I'll show how to get started with Makam and how
to implement an interpreter and type checker for a small functional language using it. In later
posts in this series we'll explore how to implement further language constructs like algebraic
data-types, exceptions, etc. We will also explore different type system features, as well as what
the different compilation phases for this language would be; and I'll go into more details about the
fundamentals of Makam itself.

## Installing Makam

Makam is written in [OCaml](http://ocaml.org), so you first need to install `opam` -- the OCaml package manager.
You could follow the [instructions on the OPAM website](http://opam.ocaml.org/doc/Install.html), or try one of
these:

```bash
# on Ubuntu:
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:avsm/ppa
sudo apt-get update
sudo apt-get install opam
# on MacOS X with HomeBrew
brew install opam
# on both, after installation:
opam init
```

You're now ready to install Makam itself:
```bash
opam pin add makam https://github.com/astampoulis/makam.git
```

## Running code

You can download the code contained in this blog post as a Makam source file [from here]({{< post-makam-url >}}).
Then you can call Makam with:

    makam {{< post-makam-basename >}} -

This will load the definitions we'll see below and give you a REPL that looks like this:

	Makam, version 0.5

    #

## Starting off: a simple expression language

```makam
expr : type.
```

```makam
intconst : int -> expr.
add : expr -> expr -> expr.
minus : expr -> expr -> expr.
mult : expr -> expr -> expr.
```

```makam
eval : expr -> expr -> prop.
```

```makam
eval (intconst N) (intconst N).
```

```makam
eval (add E1 E2) (intconst N') <-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  plus N1 N2 N'.
```

```makam
eval (minus E1 E2) (intconst N') <-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  plus N2 N' N1.
```

```makam
eval (add (intconst 1) (intconst 2)) X ?
>> Yes:
>> X := intconst 3
```

```makam
eval (mult E1 E2) (intconst N') <-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  mult N1 N2 N'.
```

```makam
boolconst : bool -> expr.
lt : expr -> expr -> expr.
ifthenelse : expr -> expr -> expr -> expr.
```

```makam
eval (boolconst B) (boolconst B).

eval (lt E1 E2) (boolconst B) <-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  lessthan N1 N2 B.
```

```makam
eval (ifthenelse E1 E2 E3) V2 <-
  eval E1 (boolconst true),
  eval E2 V2.

eval (ifthenelse E1 E2 E3) V3 <-
  eval E1 (boolconst false),
  eval E3 V3.
```

```makam
eval (add (intconst 1) (ifthenelse (lt (intconst 1) (intconst 2)) (intconst 2) (intconst 3))) X ?
>> Yes:
>> X := intconst 3
```

```makam
eval (ifthenelse (intconst 0) (intconst 1) (intconst 2)) X ?
>> Impossible.
```

## Adding a type system

```makam
typ : type.

tint : typ.
tbool : typ.

typeof : expr -> typ -> prop.
```

```makam
typeof (intconst _) tint.
```

```makam
typeof (add E1 E2) tint <-
  typeof E1 tint, typeof E2 tint.
```

$$\frac{\vdash \texttt{E1} : \textsf{int} \hspace{3em} \vdash \texttt{E2} : \textsf{int}}
       {\vdash \texttt{E1 + E2} : \textsf{int}}
$$

```makam
typeof (minus E1 E2) tint <- typeof E1 tint, typeof E2 tint.
typeof (mult E1 E2) tint <- typeof E1 tint, typeof E2 tint.

typeof (boolconst B) tbool.

typeof (lt E1 E2) tbool <-
  typeof E1 tint, typeof E2 tint.

typeof (ifthenelse E1 E2 E3) T <-
  typeof E1 tbool, typeof E2 T, typeof E3 T.
```

$$\frac{\vdash \texttt{E1} : \textsf{bool} \hspace{3em} \vdash \texttt{E2} : \tau \hspace{3em} \vdash \texttt{E3} : \tau}
       {\vdash \texttt{if E1 then E2 else E3} : \tau}
$$

In cases like these where we are dealing with two languages at the same time and things can easily
get confusing, it is important to have a clear distinction between them. We call the language that
we are implementing the *object* language, and the language that we are using to implement it the *meta*
language (or *host* language). In our case, the simply-typed lambda calculus is the object language,
and Makam is the meta-language.

## Adding the lambda calculus

```makam
app : expr -> expr -> expr.
var : string -> expr.
lam : string -> expr -> expr.
```

```makam
eval (lam S E) (lam S E).

eval (var X) (var X).

>> eval (app E1 E2) V <-
>>  eval E1 (lam S E),
>>  eval E2 V2,
>>  subst E S V2 E',
>>  eval E' V.
```

```makam
lam : (expr -> expr) -> expr.

eval (lam E) (lam E).
```

```makam
eval (app E1 E2) V <-
  eval E1 (lam E),
  eval E2 V2,
  eval (E V2) V.
```

```makam
tarrow : typ -> typ -> typ.
```

```makam
typeof (app E1 E2) T' <-
  typeof E1 (tarrow T T'), typeof E2 T.
```

```makam
typeof (lam E) (tarrow T T') <-
  (x:expr -> typeof x T -> typeof (E x) T').
```

$$
\Gamma \; ::= \; \overrightarrow{x : \tau}
$$

$$
\frac{\Gamma, x : \tau \vdash \texttt{E} : \tau'}
     {\Gamma \vdash \texttt{lam(x.E)} : \tau \to \tau'}
$$

## Adding recursion

```makam
letrec : (expr -> expr) -> (expr -> expr) -> expr.
```

```makam
typeof (letrec Def Body) T' <-
  (x:expr -> typeof x T -> typeof (Def x) T),
  (x:expr -> typeof x T -> typeof (Body x) T').
```

```makam
eval (letrec Def Body) V <-
  eval (Body (Def (letrec Def (fun x => x)))) V.
```

```makam
(eq _Fact
  (letrec (fun fact => lam (fun n => ifthenelse (lt n (intconst 2)) (intconst 1) (mult n (app fact (minus n (intconst 1))))))
          (fun fact => fact)),
 typeof _Fact T,
 eval (app _Fact (intconst 5)) X) ?
>> Yes:
>> T := tarrow tint tint,
>> X := intconst 120
```

