---
title: The Makam metalanguage
---

The main focus of Makam is in prototyping sophisticated type systems such as dependent types,
contextual types, etc. Other use cases are also possible, such as translations between languages,
transformations between successive intermediate representations, etc.

Makam works through *declarative and executable specifications*, written in the form of
*rules*. Rules in Makam are both readable and concise, and resemble to a large extent the rules that
one would write down on paper to describe a language — e.g. its typing judgement, its operational
semantics, and so on. After writing a set of rules, the user can proceed to issue queries to the
Makam implementation; these will work as a prototype type checker (with inference), interpreter,
etc., and follow the rules that have been implemented. Further rules can always be added without
changing the existing code. In the future, we aim to use Makam itself to translate those rules into
an optimized, concrete implementation of the corresponding prototype tools.

The design of Makam is largely based on [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/): a
typed, higher-order extension to Prolog that allows the use of higher-order abstract syntax to
represent binding in the terms of the object languages. We have refined the base λProlog design for
our purposes, supporting a richer class of higher-order predicates, ensuring robust support for
dynamic typing unification, and adding some lightweight staging and reflective features. These
features allow us to implement things like complicated binding structures, generic structural
recursion traversals, Hindley-Milner generalization, as well as metalanguage extensions within the
metalanguage itself (e.g. adding a form of rules for parsing and pretty printing generation). We
have so far used Makam to model a number of type systems, both traditional, like the core of an
ML-like language, as well as modern, like VeriML (the language I designed for my Ph.D.) and Ur/Web
(the secure web services language Adam has been working on).  The difference in implementation cost
is tremendous: implementing VeriML within Makam was three days' work, whereas the equivalent version
of the prototype implementation of VeriML in OCaml that I did during my Ph.D.  was at least three
months' work. We have also modeled the CPS and closure conversion phases of the classic translation
of System F to Typed Assembly Language, as an example of how to model compilation phases within
Makam.

# Draft papers and talks

- [Technical Overview](techoverview.pdf). A paper describing the main technical features of Makam
    (slightly dated).
- [Slides for the CRSX User Meeting](slides-crsx.pdf). These are the slides for a talk I gave in the
    2nd CRSX User Meeting, in Two Sigma NYC. They describe the main features of Makam and are a good
    reference point if you need a quick overview of the language.
- [Slides for the MIT PL/SE Offsite](slides-lightning.pdf). This is a lightning 3-minute talk (with
    my notes) for the MIT Programming Languages/Software Engineering Offsite event. Not a lot
    of info on Makam, but quite a fun talk to give :-)

