---
date: 2018-03-19T18:16:01-04:00
title: "Makam Tutorial 1: Prototyping a toy language and its interpreter"
---

*In this post, we'll implement a toy interpreter for a small functional language. We will use Makam,
which is a language that helps in the 'initial spiking phase' of designing a new language, allowing
for a tight feedback loop and for iterating quickly.*

Some time ago I was designing and implementing a language: there was a class of programs that were
hard to write and I wanted better ways to express them.

There were a lot of decisions to make. For starters, *what should the constructs of the language
be*?  How do these constructs enable writing the example programs that I had in mind? Which
constructs should be the "core" ones of the language, and which ones should be defined in terms of
them?

<!-- more -->

```makam-hidden
tests : testsuite. %testsuite tests.
```

What does it mean to use the language? How do you write programs in it -- what's the syntax like,
what information can one get about their programs (and how much of it can be inferred)?  What do the
constructs of the language mean -- how do you compute with them, how do they relate to the
constructs in existing languages?

Coming up with answers to these questions is an iterative process: I would start with some answers,
try to write example programs, see what works and what does not, and adapt accordingly. Implementing
the language was quite crucial to this process: actually using the language revealed patterns
that were important but that I wouldn't have found otherwise -- so that informed how to refine the
language further and what constructs to add.

Still, implementing a language takes a long time, which hinders this experimentation and refinement
process. There is a long "feedback" loop involved between having a new language design idea and
having a working (even toy-ish) implementation of it.

This is why I started working on the design and implementation of **Makam**, which is a
**metalanguage**: a language to help with designing and implementing (prototypes of) new
languages. It aims to minimize the feedback loop involved when designing a language, allowing
you to iterate and validate your language ideas quickly.

Makam is a dialect of [λProlog](http://www.lix.polytechnique.fr/~dale/lProlog/) and is hence a
*higher-order logic programming language* (more on what that means later); I worked on it
with [Adam Chlipala](http://adam.chlipala.net) while I was a post-doc at MIT. Since then,
development has been on an on-and-off basis as a personal project while
at [Originate](http://www.originate.com), but over the past six months or so I've been working quite
a bit on it.

In this series of posts, we will use Makam to prototype various parts of a toy programming
language. We will also talk through the current set of answers of the λProlog/Makam language design,
in terms of what the base constructs are, and what can be programmed using those.

A caveat before we start is that many things are work-in-progress. Though the base language and
implementation is pretty well established at this point, Makam is still in a state of evolution and
refinement. Mostly, I am exploring what further tools are needed for doing language prototyping
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
e & \text{(expressions)} & ::= & s \; | \; n \; | \; b \; | \; e_1 + e_2 \; | \; [ e_1, \cdots, e_n ] \; | \; \\
                         & & &   \{ s_1: e_1, \cdots, s_n: e_n \} \\
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
on paper, we could denote that with something like "$\text{add}(e_1, e_2)$''; and one where we
describe what the real syntactic form for the constructor is when we write out a program in the
language. When we talk about **abstract syntax**, we refer to the first part; and **concrete
syntax** is the latter one.

Let's now see how we would encode these in Makam.

First of all, we define the *sorts* that we need, which are referred to as *types* in Makam.
For our simple language, we just need expressions:

```makam
expr : type.
```

There are built-in sorts for strings and integers in Makam; booleans and lists are already defined
in its standard library. Like in most functional languages, all elements of a list are of the same
type, so lists of expressions are a different type than, say, lists of strings.

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
ifthenelse :
  (Condition: expr) (Then: block) (Else: block) -> statement.
```

Terms built out from constructors like these correspond exactly to abstract syntax trees. For example,
the abstract syntax tree for the concrete syntax `5 + 3` would be:

<center><img src="/blog/makam-tutorial-01-pic1.svg" alt="Abstract syntax tree" width="300" /></center>

We would write this as `add (intconst 5) (intconst 3)` in Makam.

One thing that might be weird at first looking at the definitions above for somebody coming from a
language like Haskell or ML is that defining a new type and definining a new constructor are
separate statements. Typically in functional languages we define datatypes and give all of their
constructors as part of a single declaration. In Makam, this different style of declarations stems
from the fact that we can define new constructors for an existing type at any point.  That's quite
useful for experimentation -- we can define a 'base version' of a language first, and then try
adding new constructs later, in a separate place, without changing the base definition.

For completeness, let's look at the definition of booleans and lists:

```makam-noeval
bool : type.
true : bool.
false : bool.

list : (A: type) -> type.
nil : list A.
cons : (Head: A) (Tail: list A) -> list A.
```

Lists are type constructors: that is, for each type `A`, `list A` is a type. There is syntactic
sugar for lists of the form `[1, 2, 3]` or even `1 :: 2 :: 3 :: []`. These declarations show what
the constructor notation is like when a constructor needs no arguments, as is the case for `true`
and `false`.

We have left the constructor for records out. We can view records as a list of fields, where each
field pairs together a key with a value:

```makam
field : type.
record : (Fields: list field) -> expr.
mkfield : (Key: string) (Val: expr) -> field.
```

And that covers all the constructors we'll define for the time being. Now let's see how to actually
define *computations* over these terms. Our example will be an interpreter for our language,
that computes the value that an expression evaluates to.

# Computation in logic programming

We have to pause working on our toy language implementation for a bit to first explain a little bit
about how computation in Makam works.

Say that instead of using Makam, we were using a functional language. One of the main operations
of functional languages is *pattern-matching*: we try to match a terms against a pattern; if
the match is successful, we proceed to take the corresponding branch.  Patterns are kind of like
"templates" for terms: some parts are explicitly specified, while others are allowed to be
arbitrary. Another way to say this, is that if terms are like trees, patterns are like "trees with
holes":

<center><img src="/blog/makam-tutorial-01-pic2.svg" alt="Pattern" width="300" /></center>

We give names to the holes, so as to be able to refer to them -- these are the *pattern variables*.
Pattern matching basically tries to find a way to fill in these holes in the pattern so that it
matches the term exactly.  So its result when its successful is an instantiation (or substitution)
for the pattern variables:

<center><img src="/blog/makam-tutorial-01-pic3.svg" alt="Pattern" width="550" /></center>

Here's an example of a query that performs pattern matching between a pattern and a term in
Makam. We will talk about what queries *are* later on, but if you run this post right now using the Play button
on the bottom-right corner, you will see that an instantiation for the pattern variables `N`, `X` is found:

```makam
pattern_match
  (add (intconst N) X)
  (add (intconst 5) (intconst 3)) ?
```
```makam-hidden
>> Yes:
>> N := 5,
>> X := intconst 3.
```

Logic programming instead treats *unification* as one of the key operations. This is the symmetric,
more general, version of pattern matching: instead of having a "pattern" with potentially unknown parts,
and a "term" that is fully known, we have two patterns that might both have unknown parts in them.
Matching them against each other might force instantiations on either one of them, or even on both of
them (in different parts of them); some parts might even remain unknown after the unification. The
unknown parts are called *unification variables* and are denoted with identifiers starting with an
uppercase letter, whereas the identifiers of normal term constructors start with a lowercase letter.

```makam-hidden
unify : A -> A -> prop.
unify X X.
```

```makam
unify (add (intconst N1) X2) (add X1 (intconst N2)) ?
```

```makam-hidden
>> Yes:
>> X1 := intconst N1,
>> X2 := intconst N2,
>> N1 := N1,
>> N2 := N2.
```

(Note the color-coding on the side of codeblocks of this post: blue blocks are things that will be sent
to Makam, which become green after a successful run, and grey ones are skipped. Any esults from the Makam
interpreter, or any errors, show up as annotations in each codeblock.)

This choice has a wide-ranging implication on how computation in logic programming actually looks
like.  In a functional language, at the point where a function is applied, its inputs are fully
known (or at least fully knowable, in a call-by-need language), whereas outputs are fully unknown,
to be determined through evaluation of the function. In a logic programming language, there is no
need to explicitly separate inputs from outputs: both of them could only be partially known at the
point where a "function" is applied, and unification will reconcile the known and unknown parts.  So
instead of functions we talk about *predicates*: these describe relations between terms, without
explicitly designating some of them as inputs and some as outputs. What is an input and what is an
output depends on the arguments that the predicates are called with. Here is an example of the
`plus` predicate, which is the moral equivalent of the `a + b` operation on integers:

```makam
plus 1 2 X ?
plus X 2 3 ?
plus 1 X 3 ?
```

So the `plus A B C` predicate takes three arguments; the first two, `A`, `B`, are the operands, and
`C`, the last one, is the result of the addition. However, the predicate can be used not only to
find the result of `A + B`, but also to discover the value of `A` or `B` given the other operand and
the result.

The type of the `plus` predicate is:

```makam-noeval
plus : (Op1: int) (Op2: int) (Result: int) -> prop.
```

The name of the type `prop` comes from *proposition*: these are the statements that we can query
upon, and might be viewed as the logic programming equivalent of the *expressions* of a functional
programming language. So a fully applied predicate like `plus` is a proposition, and by querying
about it as we did above, we are asking the Makam interpreter to find an instantiation for the
unknown *unification variables* that makes the proposition hold.

One might ask -- why is this generalization to unification and relations instead of functions
useful? One example where we can make good use of this in Makam is when implementing a type checking
procedure for a language, where blurring the line between inputs and outputs allows us to get a type
inferencing procedure essentially for free. But that is getting too much ahead of ourselves; we will
see more on later posts.

With this out of the way, it is time to try our hand at writing our first predicate over the
expressions we defined.

# Writing an interpreter for our language

Let's go back to implementing our toy language now. Here is the base declaration of a predicate that
relates an expression of our language with the value it will result in upon evaluation. We can use
this predicate as an interpreter, if we give it a complete expression and a fully unknown value as
arguments.

```makam
eval : (E: expr) (V: expr) -> prop.
```

Here's how we would use this, to evaluate/interpret a small example program:

```makam
eval (add (intconst 1) (intconst 2)) Value ?
```

Of course, this query fails at this point, as we have not given any kind of implementation for the
`eval` predicate. We do this by giving *rules* for the predicate: basically, we define the cases
for which the `eval Expr Value` proposition holds. Each rule has a *goal* and optional *premises*.
Given the current query `Q`, we attempt to unify it with the goal of each rule and proceed to
the premises, treating them as subsequent queries that need to be satisfied. For example, here are the cases
for integer constants and integer addition:

```makam
eval (intconst I) (intconst I).
eval (add E1 E2) (intconst N) :-
  eval E1 (intconst N1),
  eval E2 (intconst N2),
  plus N1 N2 N.
```

The first rule says: integer constants evaluate to themselves (because they are already values).
The second one can be read as: the `add` expression evaluates to an integer constant `N`, when
the two operands evaluate to the integer constants `N1` and `N2`, and we also have `N = N1 + N2`.
With these two rules, the query from above should now work:

```makam
eval (add (intconst 1) (intconst 2)) Value ?
```
```makam-hidden
>> Yes:
>> Value := intconst 3.
```

(Note that in a functional language when defining a function by pattern-matching, we *have* to give
its full definition. In logic programming, we can add new rules for a predicate at any point of our
program, similarly to how we can add new constructors at any point.)

Let's also add the cases for boolean constants, string constants and appending strings together. For
the latter one, we can use the Makam builtin string predicate `string.append`:

```makam
eval (boolconst B) (boolconst B).
eval (stringconst S) (stringconst S).
eval (add E1 E2) (stringconst S) :-
  eval E1 (stringconst S1),
  eval E2 (stringconst S2),
  string.append S1 S2 S.
```

Let's try a couple more queries:

```makam
eval (add (stringconst "foo") (stringconst "bar")) V ?
eval (add (intconst 5) (stringconst "foo")) V ?
```

```makam-hidden
eval (add (stringconst "foo") (stringconst "bar")) V ?
>> Yes:
>> V := stringconst "foobar".

eval (add (intconst 5) (stringconst "foo")) V ?
>> Impossible.
```

Of course, the last query fails, as it should: we have only defined rules to handle the case where
the operands to `add` evaluate to the same type of constant. That could be a deliberate choice
depending on how we want evaluation in our language to behave.

How about arrays? For an array like `[1 + 2, "foo" + "bar"]`, every member of the array needs to
be evaluated. We can use a helper predicate `eval_list` to do that, as follows:

```makam-noeval
eval_list : (Exprs: list expr) (Vals: list expr) -> prop.
eval (array ES) (array VS) :- eval_list ES VS.
eval_list [] [].
eval_list (E :: ES) (V :: VS) :- eval E V, eval_list ES VS.
```

We can do better than this though: remember when we said that Makam is a *higher-order* logic
programming language? That means that we can define higher-order predicates (predicates that
take other predicates as arguments), similarly to how we can define higher-order functions
in a higher-order functional programming language. One example of such a predicate is `map`
for lists, which is defined as follows in the Makam standard library:

```makam-noeval
map Pred [] [].
map Pred (X :: XS) (Y :: YS) :- Pred X Y, map Pred XS YS.
```

Evaluation for arrays can thus be written as:

```makam
eval (array ES) (array VS) :- map eval ES VS.

eval (array [
       add (intconst 1) (intconst 2),
       add (stringconst "foo") (stringconst "bar")])
     Value ?
```
```makam-hidden
>> Yes:
>> Value := array [ intconst 3, stringconst "foobar" ].
```

Evaluating records is a little more complicated. We need to
evaluate the expressions contained within them, so that `{ foo: 1 + 1, bar: 2 + 2 }`
evaluates to `{ foo: 2, bar: 4 }`. However, we also need to decide
what to do about duplicate key entries, as in `{ foo: 1, foo: 2 }`. For that, we will follow the JavaScript
semantics for objects: duplicate entries for the same key are allowed, and
the last occurrence of the same key is the one that gets picked -- so the
previous object evaluates to `{ foo: 2 }`.

Let's see how to implement this in Makam. Here's a first attempt where we
do not handle duplicate keys properly:

```makam-noeval
eval (record []) (record []).
eval (record (mkfield Key Expr :: Rest))
     (record (mkfield Key Value :: Rest')) :-
  eval Expr Value,
  eval (record Rest) (record Rest').
```

To account for duplicate keys, we need to split this last rule into two: one for the last occurrence
of a key (where the key does not appear in subsequent fields) and one for any earlier
occurrences. In this second case, the field can safely be ignored, as the language we are encoding
does not have any side effects. To distinguish the two cases, we can use an auxiliary predicate
that succeeds whenever a key exists within a list of fields:

```makam
contains_key : (Fields: list field) (Key: string) -> prop.
contains_key (mkfield Key Expr :: Rest) Key.
contains_key (Field :: Rest) Key :-
  contains_key Rest Key.
```

And here's the rules for evaluation:

```makam
eval (record []) (record []).
eval (record (mkfield Key Expr :: Rest))
     (record Rest') :-
  contains_key Rest Key,
  eval (record Rest) (record Rest').
eval (record (mkfield Key Expr :: Rest))
     (record (mkfield Key Value :: Rest')) :-
  not(contains_key Rest Key),
  eval Expr Value, eval (record Rest) (record Rest').
```

Note the use of `not` here: basically, we are saying that this last rule applies whenever
`contains_key Rest Key` is not successful[^1]. 

[^1]: Negation in logic programming languages is a big topic, mostly because it breaks many of the invariants that hold about the language otherwise. For example: adding a new rule only makes more queries succeed, instead of making queries fail when they were previously succeeding; this does not hold in the presence of negation.

With these, the interpreter for our toy language is complete!

```makam
eval (record [
  mkfield "foo" (add (intconst 1) (intconst 1)),
  mkfield "bar" (array [ add (intconst 2) (intconst 2) ]),
  mkfield "foo" (add (intconst 4) (intconst 4))
]) V ?
```
```makam-hidden
>> Yes:
>> V := record [mkfield "bar" (array [intconst 4]), mkfield "foo" (intconst 8)].
```

# Defining the concrete syntax for our language

One issue with our interpreter, which is quite evident in the query above, is that we have to use
abstract syntax for writing down the terms of our language -- and that's not always pleasant.
Abstract syntax is often quite long-winded and verbose, even for simple terms.  It would be
nice to be able to use concrete syntax instead, to write queries like:

```makam-noeval
evalstring << { "foo": "a", "foo": [ "bar", 40 + 2 ] } >> Y ?
```

(The syntax form `<< .. >>` is alternative syntax for strings in Makam, so that we don't have to
escape the quotes `"` within it.)

What we need is a parser, that converts a `string` containing concrete syntax into the abstract
syntax terms that we have defined. So we need to define a predicate with the type:

```makam-noeval
parse_expr : (Concrete: string) (Abstract: expr) -> prop.
```

Let's ruminate on this: given a query on `parse_expr`, what would happen if the second argument was a
fully-known abstract syntax tree, whereas the first argument was fully unknown? In that case, we would
be reconstructing the concrete syntax of an abstract syntax tree -- namely, we would be using this
predicate as a pretty-printer for our terms.[^2] So maybe `parse_expr` is not such a great name for our
predicate, since we could use it both as a parser and a pretty-printer of expressions.

[^2]: The reality is more complicated of course -- using the same predicate for both kinds of queries is not always possible for free, or will not always terminate.

How about writing the predicate itself? Makam already has a `syntax` library that can help us
implement syntax predicates like these by only giving a grammar for our language, similar to how
parser generators are used in other languages. The details of how the library works is a topic for
another time; it is also a relatively recent development, so its exact details might change.
For now, I will just give an example of how to use it for our language.

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
    mkfield  { <makam.ident> ":" <expr> }
  / mkfield  { <makam.string_literal> ":" <expr> }

  expr ->
    add      { <baseexpr> "+" <expr> }
  / baseexpr

}}).
`( syntax.def_toplevel_js expr ).
```

OK, let's unpack this a bit. The constructor definitions for `baseexpr`, `expr`, and `field` (...)
**WIP from here on.**

```makam-hidden
%extend syntax.
run : syntax A -> string -> A -> prop.
run Stx Str Tm :-
  if (refl.isunif Str) then syntax.pretty Stx Tm Str else syntax.parse_opt Stx Str Tm.
%end.
```

```makam
evalstring : string -> string -> prop.
evalstring Input Output :-
  syntax.run expr Input E, eval E V, syntax.run expr Output V.
```


```makam-input
syntax.run expr << { "foo": [ "bar", 42 ] } >> X ?
syntax.run expr X (array [intconst 5]) ?
evalstring << { "foo": "a", "foo": [ "bar", 40 + 2 ] } >> Y ?
```

```makam-hidden
>> syntax.run expr << { "foo": [ "bar", 42 ] } >> X ?
>> Yes:
>> X := record [mkfield "foo" (array [stringconst "bar", intconst 42])].

>> evalstring << { "foo": "a", "foo": [ "bar", 40 + 2 ] } >> Y ?
>> Yes:
>> Y := "{ foo : [ \"bar\" , 42 ] } ".
```

# Conclusion

We did cover quite a bit of stuff here: concrete and abstract syntax, the very basics of computation
in logic programming, and writing an interpreter for a very simple language. Next time we will cover
how to encode more complicated constructs, like functions, how to implement a type checker for our
language in Makam, and more on the basics of higher-order logic programming.
