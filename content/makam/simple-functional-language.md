---
date: 2015-09-11T15:59:38-04:00
title: "Building a small functional language in one hour through Makam"
type: post
---

## Installing Makam

First, make sure you got `opam` installed -- the OCaml package manager.
You could follow the [instructions on the OPAM website](http://opam.ocaml.org/doc/Quick_Install.html),
or try one of these:

    # on Ubuntu:
    sudo add-apt-repository ppa:avsm/ppa
    sudo apt-get update
    sudo apt-get install opam
    # on MacOS X with HomeBrew
    brew install opam 

You're now ready to install Makam itself:
```bash
opam pin add makam https://github.com/astampoulis/makam.git
```

## Testing stuff

You can download this blog post as a Makam source file [from here](simple-functional-language.makam).
Then you can call Makam with:

    makam simple-functional-language.makam -

The extra dash option will give you a REPL like this:

	Makam, version 0.5

    #

## Alright, let's do this.
