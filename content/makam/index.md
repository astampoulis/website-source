---
title: Makam
type: main
---

Makam is a metalanguage: a language for implementing languages. It supports
concise declarative definitions, aimed at allowing rapid prototyping and experimentation
with new programming language research ideas. The design of Makam is based on higher-order logic
programming and is a refinement of the [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/) language. Makam is implemented from scratch in OCaml.

The name comes from the [makam/maqam](https://en.wikipedia.org/wiki/Turkish_makam) of traditional Turkish and Arabic music: a set of
techniques of improvisation, defining the pitches, patterns and development of a piece of music.

I started working on the design and implementation of Makam in 2012 at MIT, under the
supervision of [Prof. Adam Chlipala](http://adam.chlipala.net/), and continue to work on it as a
personal project at [Originate NYC](http://www.originate.com/).

# Tutorial series

I have started a series of posts that introduce Makam and show examples of how to use it
for prototyping small languages. They aim to be pretty self-contained, only assuming
familiarity with functional programming languages.

1. [Introducing abstract and concrete syntax; implementing an interpreter for a toy language; implementing concrete syntax in Makam.](/blog/makam-tutorial-01/)

# Taksims in language design series

This a more experimental series of posts, where I might be talking about design aspects of existing
languages, and exploring design ideas for Makam and other languages. They assume some familiarity
with Makam and logic programming already. By the way, a [taksim](https://en.wikipedia.org/wiki/Taqsim) is an improvised
musical introduction before performing a traditional composition.

- [A language design taksim on mode declarations for Makam](/blog/taksim-modes-makam/)

# Code, papers and slides.

- [The GitHub repository for Makam](http://github.com/astampoulis/makam).
  Makam is free software, released under the GPLv3. This is the
  official GitHub repository for it.
- [Our ICFP 2018 paper](https://github.com/astampoulis/makam-paper-funpearl/raw/master/published.pdf), "Prototyping a Functional Language using Higher-Order Logic Programming: A Functional Pearl on Learning the Ways of λProlog/Makam", Antonis Stampoulis and Adam Chlipala. This is a functional pearl demonstrating the development of a MetaML-like type system in Makam. It serves both as a λProlog/Makam tutorial and also explains the details of some useful Makam design patterns, such as encoding complex binding structures and writing structurally recursive definitions while avoiding boilerplate. The paper is a fun read (for some definitions of "fun"), written in the style of a play between [Roza Eskenazi](https://en.wikipedia.org/wiki/Roza_Eskenazi) and [Hagop Stambulyan](https://en.wikipedia.org/wiki/Agapios_Tomboulis), reimagined as programming language researchers. The [paper repository](https://github.com/astampoulis/makam-paper-funpearl/) includes all code, together with the [artifact](https://github.com/astampoulis/makam-paper-funpearl/raw/master/makam-funpearl-artifact.zip) and the [presentation](https://rawcdn.githack.com/astampoulis/makam-paper-funpearl/5634404aad01b3c62514cfeeebfe44a4122f5c13/slides/index.html). Also available: the [video](https://dl.acm.org/ft_gateway.cfm?id=3236788&ftid=2006435) from the presentation at ICFP (about 20 minutes long).
- [Technical Overview](techoverview.pdf). A paper describing the
    main technical features of Makam (quite dated at this point)
- [Slides for the CRSX User Meeting](slides-crsx.pdf). These are
    the slides for a talk I gave in the 2nd CRSX User Meeting, in Two
    Sigma NYC. They describe the main features of Makam and are a good
    reference point if you need a quick overview of the language.
- [Slides for the MIT PL/SE Offsite](slides-lightning.pdf). This
    is a lightning 3-minute talk (with my notes) for the MIT
    Programming Languages/Software Engineering Offsite event. This is
    the talk that I have most enjoyed giving, and might be
    interesting, even though it will not give you too much information
    about Makam :)
- A [technical description](technical) of Makam, geared towards
  programming language researchers.
