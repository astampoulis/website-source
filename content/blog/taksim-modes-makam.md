---
date: 2020-05-01T17:30:00-04:00
title: "A language design taksim on mode declarations for Makam"
type: post
---

In this post, we will explore a few design ideas related to integrating mode declarations into Makam, using bidirectional typing as an example. This feature is still in the design phase, so I'd be glad to hear comments and ideas!

<!--more-->

## todo

This post is WIP. To keep track of updates, follow this [PR](https://github.com/astampoulis/website-source/pull/2).

## intro

Recommended soundtrack: [Kalthoum (Alf Leila Wa Leila), by Ibrahim Maalouf](https://open.spotify.com/album/1Agh6GiahtO2bt4t5zLJR2)

Thoughts for this post came from reading [J. Dunfield](http://research.cs.queensu.ca/home/joshuad/) and [Neel Krishnaswami](https://semantic-domain.blogspot.com/)'s [survey on bidirectional typing](https://arxiv.org/abs/1908.05839), as well as other discussions.

You can run the code in this post in your browser, through the
Makam Web UI. Click on the play button on the bottom-right corner, or press Ctrl+Enter!

## setup

```makam-hidden
tests : testsuite. %testsuite tests.
```

One of the distinguishing characteristics of logic programming languages is being able to use predicates in multiple modes.
The same predicate can be used both for computing what is typically the output parameter, or what is typically an input parameter[^1].
For example, `append` can be used both to append one list to another, but also to find which list we need to append to one to get a certain result:

```makam
append [1, 2, 3] [4, 5, 6] Result ?
```

```makam-hidden
>> Yes:
>> Result := [1, 2, 3, 4, 5, 6].
```

```makam
append [1, 2, 3] InputList2 [1, 2, 3, 4, 5] ?
```

```makam-hidden
>> Yes:
>> InputList2 := [4, 5].
```

[^1]: In Makam unfortunately the usefulness of this feature is limited for programming language settings, due to the naive depth-first search procedure used. For great examples of this in a PL context, look at [A Unified Approach to Solving Seven Programming Problems](http://io.livecode.ch/learn/gregr/icfp2017-artifact-auas7pp) by William Byrd et al.

Still, in many cases, it is useful to be able to specify and restrict the modes under which a predicate is used.
This is especially useful when we are trying to accurately model existing type inferencing algorithms.
This comes up in bidirectional typing for example, where we have two different typing judgments with different modes:

- $\Gamma \vdash e \Rightarrow \tau$, the type *synthesis* or type *inference* judgment, where the type $\tau$ is unknown and is being synthesized from $e$
- $\Gamma \vdash e \Leftarrow \tau$, the type *analysis* or type *checking* judgment, where the type $\tau$ is known and is being checked against $e$

```makam-hidden
expr : type.
typ : type.

annot : expr -> typ -> expr.
eunit : expr.
lambda : (expr -> expr) -> expr.
app : expr -> expr -> expr.

tunit : typ.
arrow : typ -> typ -> typ.
```

Modeling these judgments as predicates in λProlog/Makam, their types are the same:

```makam-noeval
type_synth : expr -> typ -> prop.
type_check : expr -> typ -> prop.
```

However, the two predicates differ in terms of how they are supposed to be used. In both of them, the expression argument is supposed to be known, so it's an input parameter; in the analysis predicate, the type is an input parameter; whereas in the synthesis predicate, the type argument is an output parameter, since it is unknown and what the predicate will compute.

To capture this intention of how predicates are supposed to be used, *mode declarations* are common in logic programming (and higher-order logic programming) languages; in that way, we can turn off the "generative" behavior of predicates for input parameters. These could look something like this, using informal syntax:

```
mode type_synth (input output).
mode type_check (input input).
```

Makam does not support mode declarations though. This brings us to the main thing we'll explore in this post: can we add some support for them, without changing the core language?

Here's the structure of the rest of this.

- What happens if we transcribe the bidirectional system for the STLC directly? [→ example, naively](#example-naively)
- How can we model bidirectional typing accurately? [→ example, manually](#example-manually)
- It would be nice to be able to fix this just by adding a mode declaration for `type_synth` and `type_check`. Can we add mode declarations to Makam? Is there a way to do this without changing the core language? [→ modes in makam](#modes-in-makam)
- Do simple mode declarations provide enough generality? (TODO) [→ modes in makam, take 2](#todo)
- Can we turn the bidirectional recipe into a Makam program, to "bidirectionalize" an existing typing declaration? (TODO) [→ writing recipes in makam](#todo)

## example, naively

```makam-hidden
type_of_var : expr -> typ -> prop.
```

```makam-hidden
%extend naive.
type_synth : expr -> typ -> prop.
type_check : expr -> typ -> prop.
```

As a first step, let's look at the basic bidirectional typing rules for the simply-typed lambda calculus, and try to transcribe them directly to Makam. Following the definitions in the [survey](https://arxiv.org/pdf/1908.05839) paper mentioned above (Figure 1), the rules are:

<center><img src="/blog/taksim-modes-bidir-spec.svg" alt="Abstract syntax tree" width="500" /></center>

Transcribing them to Makam should be simple:

```makam
type_synth X A :-
  type_of_var X A.

type_check E B :-
  type_synth E A, unify A B.

type_synth (annot E A) A :-
  type_check E A.

type_check eunit tunit.

type_check (lambda E) (arrow A1 A2) :-
  (x:expr -> type_of_var x A1 -> type_check (E x) A2).

type_synth (app E1 E2) B :-
  type_synth E1 (arrow A B),
  type_check E1 A.
```

Here I am using the additional predicate `type_of_var` to model the context $\Gamma$.

This seems to work:

```makam
type_check (lambda (fun x => x)) (arrow tunit tunit) ?
```

```makam-hidden
>> Yes.
```

As we expect though, this does not model the bidirectional system accurately. For example,
it is able to discover a type `T` when we are using the type-checking judgment:

```makam
type_check (lambda (fun x => x)) T ?
```

```makam-hidden
>> Yes:
>> T := arrow T1 T1.
```

```makam-hidden
%end.
```

An accurate model of the bidirectional system should fail instead,
as the type `T` is unknown and can thus not be used with the
type-checking judgment.

So instead, let's try to transcribe the system more accurately.

## example, manually

```makam-hidden
%extend manual.
type_check : expr -> typ -> prop.
type_synth : expr -> typ -> prop.
```

To start, let us focus on just one indicative checking rule:

<center><img src="/blog/taksim-modes-bidir-focused.svg" alt="Abstract syntax tree" width="300" /></center>

To encode this rule properly, we need to make sure
that the type `T` of `type_check E T` is treated as an input.
The key difference is that
given an unknown type like `T` as input, we should not unify it with the
`arrow A1 A2` term; instead, we should check that `T` *already*
looks like `arrow A1 A2`. So we should perform *pattern matching*
rather than *unification* with `arrow A1 A2`. Fortunately,
Makam provides us with a `pattern_match` implementation that behaves
as expected:

```makam
unify (arrow A1 A2) T ?
pattern_match (arrow A1 A2) T ?
pattern_match (arrow A1 A2) (arrow tunit tunit) ?
pattern_match (arrow A1 A2) (arrow C D) ?
```

```makam-hidden
>> unify (arrow A1 A2) T ?
>> Yes:
>> T := arrow A1 A2, A1 := A1, A2 := A2.

>> pattern_match (arrow A1 A2) T ?
>> Impossible.

>> pattern_match (arrow A1 A2) (arrow tunit tunit) ?
>> Yes:
>> A1 := tunit, A2 := tunit.

>> pattern_match (arrow A1 A2) (arrow C D) ?
>> Yes:
>> A1 := C, A2 := D, C := C, D := D.
```

(The first argument to `pattern_match` is the pattern, and the second is the scrutinee).

So encoding the arrow introduction rule accurately is simple -- we
can just use `pattern_match` instead of unifying directly:

```makam
type_check (lambda E) T :-
  pattern_match (arrow A1 A2) T,
  (x:expr -> type_of_var x A1 -> type_check (E x) A2).
```

To be entirely accurate, we should use pattern matching for the
expression argument, since we expect that to be an input too. But
we'll keep that as-is for now and revisit that later.

Transcribing the rest of the rules, we proceed similarly for the
checking rules, and there is not much we need to change for synthesis rules.

```makam
type_synth X A :-
  type_of_var X A.

type_check E B :-
  type_synth E A, unify A B.

type_synth (annot E A) A :-
  type_check E A.

type_check eunit T :-
  pattern_match tunit T.

type_synth (app E1 E2) B :-
  type_synth E1 (arrow A B),
  type_check E1 A.
```

Let's try a few examples to see what we did:

```makam
type_check (lambda (fun x => x)) (arrow tunit tunit) ?
type_check (lambda (fun x => x)) T ?
type_check (lambda (fun x => x)) (arrow tunit X) ?
type_check (lambda (fun x => x)) (arrow tunit (arrow tunit tunit)) ?
```

These all behave as expected.

```makam-hidden
>> type_check (lambda (fun x => x)) (arrow tunit tunit) ?
>> Yes.

>> type_check (lambda (fun x => x)) T ?
>> Impossible.

>> type_check (lambda (fun x => x)) (arrow tunit X) ?
>> Yes:
>> X := tunit.

>> type_check (lambda (fun x => x)) (arrow (arrow tunit tunit) X) ?
>> Yes:
>> X := arrow tunit tunit.

>> type_check (lambda (fun x => x)) (arrow tunit (arrow tunit tunit)) ?
>> Impossible.
```

```makam-hidden
%end.
```

## modes in makam

So the recipe for properly enforcing a mode is pretty simple: for
input arguments, we should use pattern matching rather than
unification.  Is there some way that we can extend Makam to support
this recipe?

Note that this will be patently different than the mode support in other logic programming languages (such as Twelf and Mercury). We will not be doing mode *checking*, that is, a static check that a certain predicate behaves according to the specified mode. Instead, we will be *enforcing* a mode, at a per-predicate level, by *making* predicates behave according to their mode. This is similar to the mode support in [ELPI](https://github.com/LPCIC/elpi/), for example.

```makam-hidden
(* stdlib extensions required for this. will open a PR for Makam soon *)

%extend refl.

decompose_term : [Full Head] Full -> Head -> args Head Full -> prop.
decompose_term Term Head Args :-
  refl.headargs Term Head ArgsDyn,
  dyn.to_args ArgsDyn Args.

recompose_term : [Full Head] Head -> args Head Full -> Full -> prop.
recompose_term Head Args Term :-
  args.applyfull Head Args Term.

%end.
```

```makam-hidden
%extend modes_v1.
```

Here's the basic approach we'll follow: we can do some meta-programming in Makam, transforming predicates that utilize a specific mode according to the recipe. We will have to perform that transformation for all rules of the relevant predicates.

Let's see how this would work. First of all, we can define `mode` as a predicate, that will be used to specify the mode for predicates. This `mode` predicate will only serve as a way to record information for predicates that we define; it will not itself have any built-in rules that contain any sort of logic. The transformation logic will be elsewhere, and will just make use of the mode information that the `mode` predicate records.

We can make light use of GADTs to make sure that when specifying a mode, the number of arguments we specify matches the number of arguments of the predicate.

```makam
argument_mode : type.
input, output : argument_mode.

mode_spec : type -> type.
nil : mode_spec prop.
cons : argument_mode -> mode_spec B -> mode_spec (A -> B).

mode : [A] A -> mode_spec A -> prop.
```

Now we should be able to specify modes for our predicates:

```makam
type_check : expr -> typ -> prop.
mode type_check [input, input].

type_synth : expr -> typ -> prop.
mode type_synth [input, output].
```

Now let's work on the logic of the actual clause transformation. A clause like the following:

```makam-noeval
type_check (lambda E) (arrow A1 A2) :-
  (x:expr -> type_of_var x A1 -> type_check (E x) A2).
```

should be turned to:

```makam-noeval
type_check Arg1 Arg2 :-
  pattern_match (lambda E) Arg1,
  pattern_match (arrow A1 A2) Arg2,
  (x:expr -> type_of_var x A1 -> type_check (E x) A2).
```

Desugaring, the above clauses correspond to the following Makam terms:

```makam-noeval
clause (type_check (lambda E) (arrow A1 A2))
  (newvar (fun (x:expr) =>
    (assume (clause (type_of_var x A1) success)
      (type_check (E x) A2))))
```

and after transformation:

```makam-noeval
clause (type_check Arg1 Arg2)
  (and_many
    [ pattern_match (lambda E) Arg1,
      pattern_match (arrow A1 A2) Arg2,
      newvar (fun (x:expr) =>
        (assume (clause (type_of_var x A1) success)
          (type_check (E x) A2))) ])
```

Let's write a predicate to do that transformation:

```makam
generate_matches :
  [A] mode_spec A ->
      args A prop -> args A prop -> list prop -> prop.

mode_transform : clause -> clause -> prop.
mode_transform
    (clause Goal Premise)
    (clause Goal' (and_many MatchesAndPremise)) :-
  refl.decompose_term Goal Predicate Patterns,
  refl.recompose_term Predicate Args Goal',
  mode Predicate ModeSpec,
  generate_matches ModeSpec Patterns Args Matches,
  append Matches [Premise] MatchesAndPremise.
```

OK, there's a lot going on in these few lines:

- We use `refl.decompose_term` to decompose a term into its head and arguments, turning `type_check (lambda E) (arrow A1 A2)` into
`type_check` (the head, which in this case is the `Predicate`) and `[lambda E, arrow A1 A2]` (the arguments, which in this case are the `Patterns` we are interested in).
- We use `refl.recompose_term` to recompose a term from a head and arguments. Since `Args` is not concrete, this will generate turn it into a list of new unification variables, giving us a term like `type_check Arg1 Arg2`.
- We use the `mode` predicate to *look up* the mode specification of the `Predicate`.
- We use `generate_matches` to zip together the patterns and the new unification variables into the corresponding propositions, following the mode specification. This will give us a term like `pattern_match (lambda E) Arg1` for the first pattern and argument.

The rules for `generate_matches` are as follows:

```makam
generate_matches [] [] [] [].
generate_matches
    (input :: Modes)
    (Pattern :: Patterns)
    (Arg :: Args)
    ((pattern_match Pattern Arg) :: Rest) :-
  generate_matches Modes Patterns Args Rest.
generate_matches
    (output :: Modes)
    (Pattern :: Patterns)
    (Arg :: Args)
    ((unify Pattern Arg) :: Rest) :-
  generate_matches Modes Patterns Args Rest.
```

Let's see what we did:

```makam
mode_transform
  (clause (type_check (lambda E) (arrow A1 A2))
    (newvar (fun x =>
      (assume (clause (type_of_var x A1) success)
        (type_check (E x) A2)))))
  Transformed ?
```

```makam-hidden
>> Yes:
>> Transformed :=
     clause (type_check Arg1 Arg2)
       (and_many
         [ pattern_match (lambda E) Arg1,
           pattern_match (arrow A1 A2) Arg2,
           newvar (fun (x:expr) =>
             (assume (clause (type_of_var x A1) success)
               (type_check (E x) A2))) ]).
```

If we squint away the poor naming of the new unification variables,
the result looks OK! Does this work OK for output arguments too?

```makam
mode_transform
  (clause (type_synth (annot E A) A)
    (type_check E A))
  Transformed ?
```

```makam-hidden
>> Yes:
>> Transformed := clause (type_synth Arg1 Arg2) (and_many [ (pattern_match (annot E A) Arg1), (unify A Arg2), (type_check E A) ]).
```

This introduces an extra unification variable that is not strictly needed, but the behavior should still be as expected.

So the transformation based on modes seems to work OK. Now, there's two ways we can use this transformation to make use of the mode specifications for our predicates:

- [statically](#statically): that is, do the transformation when defining a new rule for a predicate that includes a mode. We can do this using the staging support of Makam: instead of defining the rules directly, we'll call a predicate that generates a new rule, using the transformation we just defined.
- [dynamically](#dynamically): that is, we can perform the transformation whenever the rules are about to get used. We can do this using the reflection support of Makam: we'll define a wrapper that performs reflection to get all the rules of the predicates, do the transformation, and then execute/interpret the transformed rules.

#### statically

Let's see how those work. For the *static* version, we will need a predicate that takes the goal and the premise of a rule, and generates
a *command*: one of the top-level definitions that make up a Makam
program. Using our transformation predicate above, we'll turn the goal and the premise into the clause that takes the mode specification into account, and we will generate the command to define this as a new clause:

```makam
define_with_mode : prop -> prop -> cmd -> prop.
define_with_mode Goal Premise (cmd_newclause Clause') :-
  mode_transform (clause Goal Premise) Clause'.
```

Now we have to change how we write our rules for `type_check` and `type_synth`. Here's an example:


```makam-hidden
%extend static.
type_check : expr -> typ -> prop.
mode type_check [input, input].

type_synth : expr -> typ -> prop.
mode type_synth [input, output].

`(define_with_mode
  (type_synth X A)
  (type_of_var X A)).

`(define_with_mode (type_check E B)
  {prop| type_synth E A, unify A B |}).

`(define_with_mode (type_synth (annot E A) A)
  (type_check E A)).

`(define_with_mode (type_check eunit tunit) success).
```

```makam
`(define_with_mode (type_check (lambda E) (arrow A1 A2))
  {prop| (x:expr -> type_of_var x A1 -> type_check (E x) A2) |}).
```

Having to write rules in this syntax is unfortunate and error-prone.
We have to use `{prop|` to use propositional syntax for the premise, and we also have to remember to use `define_with_mode`; nothing
is preventing us from writing the rules using the normal syntax, but
the mode specification will not be taken into account if we do that.

```makam-hidden
`(define_with_mode (type_synth (app E1 E2) B)
  {prop|
    type_synth E1 (arrow A B),
    type_check E1 A |}).

>> type_check (lambda (fun x => x)) (arrow tunit tunit) ?
>> Yes.

>> type_check (lambda (fun x => x)) T ?
>> Impossible.

>> type_check (lambda (fun x => x)) (arrow tunit X) ?
>> Yes:
>> X := tunit.

>> type_check (lambda (fun x => x)) (arrow (arrow tunit tunit) X) ?
>> Yes:
>> X := arrow tunit tunit.

>> type_check (lambda (fun x => x)) (arrow tunit (arrow tunit tunit)) ?
>> Impossible.

%end.
```

#### dynamically

```makam-hidden
%extend dynamic.
```

Let's see how the dynamic version works out. The main thing we'll do is to use reflection to get all the rules associated with a predicate and then write a small special interpreter for them: we'll first transform them using `mode_transform` and then mimic what Makam
does normally for rules:

```makam
run_with_modes : prop -> prop.
run_clauses_with_modes : prop -> list clause -> prop.

run_with_modes Goal :-
  refl.rules_get Goal Clauses,
  run_clauses_with_modes Goal Clauses.

run_clauses_with_modes Goal (ActualRule :: Rest) :-
  mode_transform ActualRule (clause Goal' Premise'),
  ((unify Goal Goal', Premise')
   ; run_clauses_with_modes Goal Rest).
```

The reflective predicate `refl.rules_get` is what gives us the rules associated with a proposition as a list of clauses. Then
for each rule, `run_clauses_with_modes` transforms it, tries
to unify our current goal with the transformed goal of the rule,
and then runs the transformed premise. It also inserts a backtracking
point to try the rest of the rules using the `or` connective, written
as `;`.

Now to use this for our typing rules, we still have to do some work:

- we have to move all of our "real" rules from `type_check` and `type_synth` into separate predicates `type_check_rules` and `type_synth_rules`
- we have to change the `type_check` and `type_synth` predicates to be helper predicates that use `run_with_modes` with the "real" rules

Here's the basic setup we'll need:

```makam
type_check_rules : expr -> typ -> prop.
mode type_check_rules [input, input].

type_synth_rules : expr -> typ -> prop.
mode type_synth_rules [input, output].

type_check : expr -> typ -> prop.
type_check E T :-
  run_with_modes (type_check_rules E T).

type_synth : expr -> typ -> prop.
type_synth E T :-
  run_with_modes (type_synth_rules E T).
```

The good news is that in this case, we will be able to write the rules in a relatively normal way. I'm giving the full rules here, which I copy-pasted from our naive transcription above, and just moved them to the `_rules` predicates:

```makam
type_synth_rules X A :-
  type_of_var X A.

type_check_rules E B :-
  type_synth E A, unify A B.

type_synth_rules (annot E A) A :-
  type_check E A.

type_check_rules eunit tunit.

type_check_rules (lambda E) (arrow A1 A2) :-
  (x:expr -> type_of_var x A1 -> type_check (E x) A2).

type_synth_rules (app E1 E2) B :-
  type_synth E1 (arrow A B),
  type_check E1 A.
```

Of course, even in this solution there is a little bit of definition overhead: we have to remember to define the wrapper predicates, to
make sure we add the "real" rules to the `_rules` predicates, and to
call the wrapper predicates recursively in the premises rather than the `_rules` predicates. And there definitely is runtime overhead in this solution, as we perform the mode transformation every time that the predicates get used.

```makam-hidden
>> type_check (lambda (fun x => x)) (arrow tunit tunit) ?
>> Yes.

>> type_check (lambda (fun x => x)) T ?
>> Impossible.

>> type_check (lambda (fun x => x)) (arrow tunit X) ?
>> Yes:
>> X := tunit.

>> type_check (lambda (fun x => x)) (arrow (arrow tunit tunit) X) ?
>> Yes:
>> X := arrow tunit tunit.

>> type_check (lambda (fun x => x)) (arrow tunit (arrow tunit tunit)) ?
>> Impossible.
```

```makam-hidden
%end.
```

#### recap and future

We have found a couple of ways to take mode specifications into account without having to change the core of Makam. Unfortunately, none of these two solutions are ideal:

- doing the mode transformation statically is nice because there's no runtime overhead every time we call the rules. However, we have to remember to use `define_with_mode` for predicates that include a mode specification, and we have to give up on writing rules for our predicates natively. Additionally, it is hard to inspect the output of staging and understand what rules actually constitute the program.
- doing the transformation dynamically is nice because we can write the rules in the standard way. However, there is a significant runtime overhead, and debugging predicates written in this style becomes much harder.

So it turns out that we might need some additional support in the core
of Makam for mode declarations to be nice. One idea there is that we
could add a way to register "rule transformer" predicates that run
whenever we add a new rule. This would be similar to the staging
approach, but would have better ergonomics: we could register the mode transformation once, proceed to write all the rules
in the normal style, and the staged transformation would happen behind
the scenes. Still, there's a few design questions for this feature:

- should we run transformers retroactively for existing rules?
- how would multiple transformers work out?
- could we have a nice way in an IDE to switch between the pre-transformation rules and the post-transformation rules?

Still, one good thing that we found is that the mode specification part itself looks quite nice and does not need to be part of the core language. Are these kinds of mode specifications general enough though?

```makam-hidden
%end.
```
