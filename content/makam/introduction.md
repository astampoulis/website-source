---
date: 2015-09-11T15:59:38-04:00
title: "Introduction to Makam"
type: post
draft: true
---

People set out to design new programming languages for all sorts of different reasons: someone might
be stuck with a language but hate the syntax for it (e.g. CoffeeScript); want to incorporate
new type system features (e.g. safe manual memory management through ownership tracking in Rust); adding
runtime features, such as primitives for concurrent code (e.g. agents in Erlang); or want to combine
existing ideas in a single language (e.g. combining a functional language with the Java OO system in
Scala).

In the case of building a new syntax, the tools to help along are quite well-known: parser
generators like Yacc and Bison and parser combinator libraries like Parsec. These tools take a
grammar -- a *declarative* description of the language syntax, and produce a parser -- code that
actually parses text using this syntax. Hand-rolling a parser is doable, but using a parser
generator significantly cuts down on the initial implementation time and on the time it takes
to incorporate changes. The focus is on the *what* the syntax is vs. to *how* parsing the syntax is
implemented. As a result, a grammar is a reliable way of communicating whereas a hand-rolled parser
is not. Typically the parser translates the *concrete syntax* of the language, the string-based
representation of a program, into the *abstract syntax tree*.

While doing research on [VeriML](/veriml), I found that when working on language features like a
complicated type system of a language, it is very important to be able to test it out in practice,
by writing programs using it. This often reveals patterns that are important, or shortcomings of the
design and suggests alternatives that work better or additions that are needed. Implementing a new
type system though is serious business, and takes multiple months; subsequent changes also take a long
time. As a result iterations of each design get really drawn out.

Wouldn't it be great if there was a way to do declarative and executable descriptions of the rest of
a language, instead of just its syntax? Makam started with this idea. We started out with the formalism
that was closest to this goal, namely [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/),
and explored how to encode parts of the [OCaml]() language, [VeriML]() and [Ur/Web]().

Programming language researchers already use a declarative way to communicate the definition of
things like the type system of a language, the runtime semantics of different primitives, etc.
These are called judgements. 
