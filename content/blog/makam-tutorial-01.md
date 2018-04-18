---
date: 2018-03-19T18:16:01-04:00
title: "Makam Tutorial 1: Prototyping a toy language and its interpreter"
---

*In this post, we'll implement a toy interpreter for a small functional language.*

Some time ago I was designing and implementing a language: there was a class of programs that were
hard to write and I wanted better ways to express them.

There were a lot of decisions to make. For starters, *what should the constructs of the language
be*?  How do these constructs enable writing the example programs that I had in mind? Which
constructs should be the "core" ones of the language, and which ones should be defined in terms of
them?

<!-- more -->

What does it mean to use the language? How do you write programs in it -- what's the syntax like,
what information can one get about their programs (and how much of it can be inferred)?  What do the
constructs of the language mean -- how do you compute with them, how do they relate to the
constructs in existing languages?

Coming up with answers to these questions is an iterative process: I would start with some answers,
try to write example programs, see what works and what does not, and adapt accordingly. This process
benefitted immensely from implementing the language: actually using the language revealed patterns
that were important but that I wouldn't have found otherwise -- so that informed how to refine the
language further and what constructs to add.

Still, implementing a language takes a long time, which hinders this experimentation and refinement
process. There is a long "feedback" loop involved between having a new language design idea and
having a working (even toy-ish) implementation of it.

This is why I started working on the design and implementation of **Makam**, which is a
**metalanguage**: a language to help with designing and implementing (prototypes of) new
languages. It is a dialect of [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/). I worked on
Makam with [Adam Chlipala](http://adam.chlipala.net) while I was a post-doc at MIT. Since then,
development has been on an on-and-off basis as a personal project while
at [Originate](http://www.originate.com), but over the past six months or so I've been working quite
a bit on it.

In this series of posts, we will use Makam to prototype various parts of a toy programming
language. We will also talk through the current set of answers of the λProlog/Makam language design,
in terms of what the base constructs are, and what can be programmed using those.

A caveat before we start is that many things are work-in-progress. Though the base language and
implementation is pretty well established at this point, Makam is still in a state of evolution and
refinement, where I am exploring what further tools that are needed for doing language prototyping
effectively and implementing those for Makam, using Makam itself.

So, welcome to the world of Makam. There are various levels of meta at play, some things are a bit
of a mess, but there are some nice things going on.

# Expressing the main constructs of our language: Abstract syntax

Let's start defining and implementing our toy language. First of all, we will need to decide what
our base constructs are. To keep things simple let's start with this:

- String constants like `"foo"`, `"bar"`
- Integer constants like `5`, `42`
- Boolean constants, namely `true` and `false`
- An expression to add two integers or two strings together
- Array literal expressions, like `[40 + 2, "foo"]`
- Record literal expressions, like `{ foo: "bar" }`

Here is a more formal way where you might see this kind of definition of language constructs on paper:

`$$\begin{array}{llll}
e & \text{(expressions)} & ::= & s \; | \; n \; | \; b \; | \; e_1 + e_2 \; | \; [ e_1, \cdots, e_n ] \; | \; \{ s_1: e_1, \cdots, s_n: e_n \} \\
s & \text{(string constants)} & ::= & \cdots \\
n & \text{(integer constants)} & ::= & \cdots \\
b & \text{(boolean constants)} & ::= & \text{true} \; | \; \text{false}
\end{array}$$`

In this notation, *expressions*, *string constants*, *integer constants* etc. are different **sorts** --
the different "kinds of things" that might be involved in the terms of our language.  For example,
if we were encoding an imperative language that included statements and statement blocks, we would
have separate sorts for them, like:

`$$\begin{array}{llll}
st & \text{(statements)} & ::= & x = e; \; | \; \text{return} \; e; \; | \;
    \; | \; \text{if} \; (e) \; \text{then} \; b_1 \; \text{else} \; b_2; \; | \; \\
& & & 
    \text{for} \; (\text{const} \; x \; \text{in} \; e) \; b; \; | \;
    \; | \; \text{for} \; (\text{const} \; x \; \text{of} \; e) \; b; \; | \; \cdots \\
b & \text{(blocks)} & ::= & \{ \; st_1 \; \cdots \; st_n \; \}
\end{array}$$`

Each alternative given for a sort is a **constructor**. When we read a constructor definition like
"$e_1 + e_2$" it means that it's a constructor for expressions that is formed by two expressions. Similarly,
"$\text{if} \; (e) \; \text{then} \; b_1 \; \text{else} \; b_2;$" is formed by an expression
and two blocks. A constructor of the form "$[ e_1, \cdots, e_n ]$" means that it is formed through
a list of expressions. So the letters we give to sorts (like $e$, $s$) are a handy pun that
allows us to specify the constituent parts of each constructor concisely.

Now this notation mixes a couple of things together: we are defining *what the constructors are* 
together with *what is the real syntax that we will use to write down those constructors*.
However, we can separate those two aspects of the definition out. In terms of what the
language *is*, the important part is *what the constructors are*. The syntax that we use
for them is secondary: it is important in terms of actually writing down terms of the language
in a way that is human-readable, but we could have different syntaxes for the same exact language.

Instead, we can separate those two concerns into two parts: one where we just give an explicit name
to each constructor and describe what its constituents are (how many are there and of what sorts) --
on paper, we could denote that with something like "$\text{add}(e_1, e_2)$"; and one where we
describe what the real syntactic form for the constructor is when we write out a program in the
language. When we talk about **abstract syntax**, we refer to the first part; and **concrete
syntax** is the latter one.

Let's now see how we would encode these in Makam.

First of all, we define the *sorts* that we need, which are referred to as *types* in Makam.
For our simple language, we just need expressions:

```makam
expr : type.
```

There are built-in sorts for strings and integers in Makam, and booleans and lists are already
defined in its standard library. Like in most functional languages, all elements of a list are
of the same type, so lists of expressions are a different type than, say, lists of strings.

We can now define the constructors for expressions as follows:

```makam
stringconst : (S: string) -> expr.
intconst : (I: int) -> expr.
boolconst : (B: bool) -> expr.
add : (E1: expr) (E2: expr) -> expr.
array : (ES: list expr) -> expr.
```

So we first give the name of the constructor, like `add`, the arguments it takes (that is, its
constituent parts), like `(E1: expr) (E2: expr)`, and the resulting sort that it belongs to, like
`expr`, following the arrow.  The names of the arguments, like `E1` and `E2`, are only given as
documentation. This helps sometimes to disambiguate between what each different argument is -- for
example, we could define the `if`-`then`-`else` statement as:

```makam-noeval
ifthenelse : (Condition: expr) (Then: block) (Else: block) -> statement
```

Going back to booleans and lists, they are defined as follows:

```makam-noeval
bool : type.
true : bool.
false : bool.

list : (A: type) -> type.
nil : list A.
cons : (Head: A) (Tail: list A) -> list A.
```

Lists are type constructors: that is, for each type `A`, `list A` is a type. Also, this shows what
the notation is like when a constructor needs no arguments, like `true` and `false`.

We have left the constructor for records out. We can view records as a list of fields, where each
field pairs together a key with a value:

```makam
field : type.
record : (Fields: list field) -> expr.
mkfield : (Key: string) (Val: expr) -> field.
```

And that's all the constructors there are for the time being. Let's now define operations on them.

##### WIP from here on

# Interpretation

```makam
eval : (E: expr) (V: expr) -> prop.

eval (stringconst S) (stringconst S).
eval (intconst I) (intconst I).
eval (boolconst B) (boolconst B).
eval (add E1 E2) (intconst N) :-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  plus N1 N2 N.
eval (add E1 E2) (stringconst S) :-
  eval E1 (stringconst S1),
  eval E2 (stringconst S2),
  string.append S1 S2 S.
eval (array ES) (array VS) :-
  map eval ES VS.
```

```makam
update_or_add :
  (In: list field) (Key: string) (Value: expr) (Out: list field) -> prop.
update_or_add [] Key Value [mkfield Key Value].
update_or_add (mkfield Key Value1 :: Rest) Key Value2 (mkfield Key Value2 :: Rest).
update_or_add (mkfield Key1 Value1 :: Rest) Key2 Value2 (mkfield Key1 Value1 :: Rest') :-
  not(eq Key1 Key2), update_or_add Rest Key2 Value2 Rest'.

eval_fields : (Evaled: list field) (Unevaled: list field) (Result: list field) -> prop.
eval_fields Evaled [] Evaled.
eval_fields Evaled (mkfield Key Expr :: Rest) Result :-
  eval Expr Value,
  update_or_add Evaled Key Value Evaled',
  eval_fields Evaled' Rest Result.

eval (record ES) (record VS) :-
  eval_fields [] ES VS.
```

# Defining the concrete syntax for our language

```makam-hidden
%open syntax.
```

```makam
baseexpr, expr : syntax expr.
field : syntax field.

`(syntax_rules {{

  baseexpr ->
    stringconst { <makam.string_literal> }
  / intconst    { <makam.int_literal> }
  / array       { "[" <list_sep (token ",") expr> "]" }
  / record      { "{" <list_sep (token ",") field> "}" }

  field ->
    mkfield  { <makam.string_literal> ":" <expr> }
  / mkfield  { <makam.ident> ":" <expr> }

  expr ->
    add      { <baseexpr> "+" <expr> }
  / baseexpr

}}).
```

```makam
`( syntax.def_toplevel_js expr ).
```

```makam
eval : string -> string -> prop.
eval Input Output :-
  syntax.parse_opt expr Input E,
  print E,
  debug(eval E V),
  syntax.pretty expr V Output.
```


```makam-input
syntax.parse_opt expr << { "foo": [ "bar", 42 ] } >> X ?

eval << { "foo": "a", "foo": [ "bar", 40 + 2 ] } >> Y ?
```
