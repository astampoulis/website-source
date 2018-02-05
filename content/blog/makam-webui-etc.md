---
date: 2018-02-04T11:27:37-05:00
title: "Literate Makam web pages and other recent news"
type: post
---

I have been working a lot on Makam in the past few months, the
metalanguage based on λProlog that I started implementing at MIT
working with [Adam Chlipala](http://adam.chlipala.net).  The latest
feature I have been working on is a Web interface for Makam, meant to
be used for literate posts that have Makam code alongside the
text. The code is ran through a AWS Lambda Makam webservice. This is
the first such literate post -- so go ahead and evaluate the code of
this web page, or even try editing the final queries before
evaluating, using the two buttons on the bottom-right of the page!

<!-- more -->

It goes without saying what the first query utilizing this interface
should be:

```makam-hidden
post: testsuite. %testsuite post.
```

```makam
print_string "Hello world!\n" ?
```

```makam-hidden
>> Yes.
```

The "Yes." part you might notice in the result of this query means
that a solution was found. Typically, Makam queries will have
uninstantiated metavariables (that start with a capital letter), and
the point of executing them would be to find valid solutions for those
variables. More on these below.

```makam
string.concat ["Hello", " ", X, "!"] "Hello world!" ?
```

```makam-hidden
>> Yes:
>> X := "world".
```

Now that this interface is ready, I am planning to start a number of
tutorials on Makam and on language implementation. I also have a few
experimental ideas that I want to implement, where I would appreciate
some feedback, but that is a matter for a later time.  In any
case, [drop me a line]({{< mailto-url >}}) with your
thoughts if you are reading this!

Makam is meant to be used as a PL prototyping tool to explore research
ideas, and also as tool for encoding and understanding existing
languages and advanced type systems. It aims to be more of a very
expressive core language that can be used to define languages and
transformations between languages in a concise way, even when those
are quite involved.  In that sense, it does not aim to be a language
workbench that allows you to define specific aspects of your language
using different domain specific languages (e.g. parsing, name
resolution, typing, etc.), and gives you a full-blown IDE experience
as a result (for example, in the style
of [Spoofax](http://www.metaborg.org/en/latest/)). However, a lot of
the DSLs and tools that would comprise a language workbench in that
style can be implemented within Makam itself.

One such DSL that I have defined lately is a bidirectional syntax
language. It can be used to define a parser and a pretty-printer for
the language you are implementing, through a single set of rules
(hence the 'bidirectionality' in the name refers to viewing parsers
and pretty-printers as inverses of each other). The pretty-printing
part is quite basic at this point, but the parsing part is at a
relatively good state: it is based on PEG parser combinators, and it
generates parsing code in JavaScript that runs in Node.js under the
hood. This is done because Makam is interpreted and quite slow to
evaluate, so running the parsers in Node is a huge performance
boost. Of course, the parser generation, which transforms terms of the
PEG combinator language to JavaScript code, is implemented in Makam.


Other things that I have been working on recently is a concrete
binding library, to convert between abstract syntax with concrete
names and abstract binding syntax utilizing HOAS; a testing framework;
and various additions to the standard library.  There's now an `npm`
package for Makam too with precompiled binaries for Linux and MacOS X,
if you want to execute Makam locally and do not already have OCaml
installed. With these, I felt like a version bump was in order, so
this also marks the release of Makam 0.7.0.

As a small example of the syntax DSL, let's implement a simple calculator
language and its syntax description. I will not go into full details, so
stay tuned for a more in-depth introductory post along the same
lines. First, we will define the terms of our language-- let's say we
have integer constants, integer addition, `let` expressions and variables.

```makam
term : type.

intconst : int -> term.
add : term -> term -> term.
let : string -> term -> term -> term.
var : string -> term.
```

Now let's define the syntax for these. We split the syntax into
two precedence levels, and then give a syntax rule for each
term constructor. The angle brackets means that the result of
a parsing expression gets applied to the given term constructor --
so each rule needs to apply the right kind of arguments in sequence.
Quoted strings stand for tokens.

```makam
term, baseterm : syntax term.

`( syntax_rules {{

term ->
  add { <baseterm> "+" <term> }
/ let { "let" <makam.ident> "=" <term> "in" <term> }
/ baseterm
;

baseterm ->
  intconst { <makam.int_literal> }
/ var { <makam.ident> }
/ { "(" <term> ")" }

}}).

`( syntax.def_toplevel_js term ).
```

The two statements starting with the ``(` symbol are staged,
meaning that they are Makam programs that compute Makam
programs which are then evaluated in place. The former one
translates the surface-level syntax for syntax rules to
actual Makam rules; and the latter one generates a top-level
parser in JavaScript for the `term`. The double-bracket
notation stands for multi-line strings, which is useful
when writing code of a different language.

With these, we can issue parsing queries. For example:

```makam
syntax.parse_opt term {{ let a = 21 in a + a }} X ?
```

```makam-hidden
>> Yes:
>> X := let "a" (intconst 21) (add (var "a") (var "a")).
```

Let's also define an evaluator for this language that returns the
result of an expression. This will be a predicate that relates a term
of the language to its integer value:

```makam
eval : term -> int -> prop.

eval (intconst N) N.
eval (add E1 E2) N :-
  eval E1 N1, eval E2 N2,
  plus N1 N2 N.
eval (let VAR DEF BODY) N :-
  eval DEF N_DEF,
  (eval (var VAR) N_DEF -> eval BODY N).
```

We can also define a version of the `eval` predicate that accepts a
string as input, and parses the string before evaluating. Makam has
type-based overloading for constants, so types are used to
disambiguate between the two `eval` predicates:

```makam
eval : string -> int -> prop.
eval String Result :-
  syntax.parse_opt term String Term,
  eval Term Result.
```

Our simple calculator is ready! Here's an example query:

```makam-hidden
>> eval {{ let a = 21 in a + a }} X ?
>> Yes:
>> X := 42.
```

```makam-input
eval {{ let a = 21 in a + a }} X ?
```

Using the Makam web interface, you can edit the query above -- the
Edit button on the bottom-right takes you directly to it -- and re-run
Makam to see the result with the Play button. (For the time being,
only the query is editable, mostly to limit the AWS Lambda execution
times; in the future, the rest of the Makam code blocks in a post
might be editable as well if that proves useful.)

That's it for the time being! More introductory tutorial posts should
be coming up soon!
