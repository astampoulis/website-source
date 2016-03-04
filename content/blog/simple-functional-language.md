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

## The object language

Let's talk a bit more about the language that we'll model in Makam. We'll be doing a version of the
[simply typed lambda calculus](https://en.wikipedia.org/wiki/Simply_typed_lambda_calculus), adding
natural numbers and recursion to make it easier to write interesting functions. The *terms* or
*expressions* of the language are:

- $- \lambda x:\tau.e -$ -- /lambda function/: a literal for an anonymous function

- $- e \; e' -$ -- /application/ of a function to an argument

- $- x -$ -- /variable/ 

- $- let x = e in e' -$ -- 

In cases like these where we are dealing with two languages at the same time and things can easily
get confusing, it is important to have a clear distinction between them. We call the language that
we are implementing the *object* language, and the language that we are using to implement it the *meta*
language (or *host* language). In our case, the simply-typed lambda calculus is the object language,
and Makam is the meta-language.

## Starting off: defining the abstract syntax

```makam
test : type.
```

## Differences between Makam and functional languages
