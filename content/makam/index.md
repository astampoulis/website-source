---
title: Makam
type: main
---

Makam is a metalanguage: a language for implementing languages. It supports
concise declarative definitions, aimed at allowing rapid prototyping and experimentation
with new programming language research ideas. The design of Makam is based on higher-order logic
programming and is a refinement of the λProlog language. Makam is implemented from scratch in OCaml.

The name comes from the makam/maqam of traditional Turkish and Arabic music: a set of
techniques of improvisation, defining the pitches, patterns and development of a piece of music.

I started working on the design and implementation of Makam in 2012 at MIT, under the
supervision of [Prof. Adam Chlipala](http://adam.chlipala.net/), and continue to work on it as a
personal project at [Originate NYC](http://www.originate.com/).

# Tutorial series

I have started a series of posts that introduce Makam and show examples of how to use it
for prototyping small languages. They aim to be pretty self-contained, only assuming
familiarity with functional programming languages.

1. [Introducing abstract and concrete syntax; implementing an interpreter for a toy language; implementing concrete syntax in Makam.](/blog/makam-tutorial-01/)

# Code, papers and slides.

- [The GitHub repository for Makam](http://github.com/astampoulis/makam).
  Makam is free software, released under the GPLv3. This is the
  official GitHub repository for it.
- [Technical Overview](techoverview.pdf). A paper describing the
    main technical features of Makam, which is the closest thing that
    we have right now to a more in-depth language reference. Still, this is quite
    dated at this point, so expect newer material soon.
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
