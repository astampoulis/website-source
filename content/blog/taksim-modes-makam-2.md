---
date: 2021-02-21T17:30:00-04:00
title: "A language design taksim on mode declarations for Makam, part 2"
type: post
---

In this post, we will continue to explore how to integrate mode declarations into Makam, using bidirectional typing as an example.

<!--more-->

## intro

```makam-hidden
tests : testsuite. %testsuite tests.
%use "taksim-modes-makam.md".
```

In the [previous part](/blog/taksim-modes-makam/), we found a basic recipe for adding mode declarations to Makam:

- Through a `mode` predicate, we can declare the mode of each argument of a predicate.
  For example, in a bidirectional type system, type checking and type synthesis would need the declarations:

```makam-noeval
type_check : expr -> typ -> prop.
mode type_check [input, input].

type_synth : expr -> typ -> prop.
mode type_synth [input, output].
```

- Based on these declarations, we can transform each rule of our predicates, performing pattern
  matching for input arguments, and full unification for output arguments. This way,
  our predicates will look at input arguments as fixed data, and avoid unifying any
  uninstantiated unification variables that they contain with the terms specified in
  the rules. The "generative" property of logic programming is thus avoided for input
  arguments.

We did this transformation in two ways: statically, through the use of staging, to
transform the rules within Makam before they are added to the set of rules; and
dynamically, through the use of reflection, to transform the rules at the time of use.

Both of these approaches had issues. Since the last post, I have
merged a new feature into Makam, which gives us another approach with
much better ergonomics: toplevel command transformers. It will also
allow us to treat mode declarations in an entirely different way: as
information used in a static analysis, rather than information used to
guide a source-to-source transformation.

## mode declarations through command transformers

Toplevel command transformers is an experimental new feature in Makam, that gives
an alternative way to utilize the staging support of the language. The core idea is that
every toplevel command, such as the declaration of a new rule or a query, is first transformed through a Makam predicate before being issued as a command. This way we can apply
transformations, such as the mode transformation we'll be doing here; or transformations to implement other new features such as macro expansion and functional syntax.

Through this feature, we can resolve the main issue we faced when transforming our rules through staging: we had to manually use the `mode_transform` predicate to transform each rule, which introduced noise to our declarations and hurt readability. What we can do now instead is register `mode_transform` to be used automatically, whenever a rule for a predicate with a mode declaration gets added.

Let's see how this works. First, the command transformer feature is opt-in right now, so we'll have to import the relevant library that enables it:

```makam
%use "stdlib/transformers/init".
```

(As always, you can run the code in this post in your browser, through the
Makam Web UI. Click on the play button on the bottom-right corner, or press Ctrl+Enter!)

```makam-hidden
log_annotation : A -> expansion -> prop.

log_annotation Where Log :-
  log_info_do Where "Query result" Log.

%extend modes_enforcing.
```

The second step is to register a new toplevel transformer to do
the mode transformation. This is what this looks like:

```makam-noeval
toplevel_command_transformer "mode"
  (cmd_newclause Clause)
  (cmd_newclause Clause')
    when mode_transform Clause Clause'.
```

So what this says is that we transform new clause commands
(`cmd_newclause Clause`, the command to add a new clause as a rule
to a predicate) into the clause commands that actually
get issued to Makam (`cmd_newclause Clause'`); we do this
only when the `mode_transform` predicate that we implemented in [part 1](/blog/taksim-modes-makam/#modes-in-makam) is
successful. As `mode_transform` will fail for predicates that
do not include mode declarations (e.g. any predicate other than `type_synth` or `type_check`),
their rules will be preserved as they are.

The `when` part of the rule might be surprising: it is a *guard*
rather than a *premise*. Similar to guards in pattern matching,
this part of the rule controls whether the rule *applies* or not.
For most situations in Makam, it is equivalent to move a guard to be part of a
premise (so, a rule like `Goal when Guard :- Premise` can equivalently
be written as `Goal :- Guard, Premise`). However, in some cases it is useful to distinguish between
when a rule does not apply (the `Goal` does not match the current goal, or the `Guard`
fails), and when a rule applies but fails to produce a result. One such example is common when writing structurally
recursive predicates. In this case, we want the transformation to
only apply when a mode declaration exists, so the use of `when`
allows the transformer library to tell that this transformation needs
to be applied. An alternative would be to make the rule apply always,
change the `mode_transform` predicate to produce a result when no mode declaration exists, and make
`mode_transform` a premise.

```makam-hidden
(* In reality, make the command transformer also show what the
   resulting transformed clause is like. *)

toplevel_command_transformer "mode"
  (cmd_newclause Clause)
  (cmd_newclause Clause')
    when mode_transform Clause Clause' :-
  tostring Clause' S,
  log_annotation Clause `${S}`.
```

With the transformer registered, we should now be able to do a direct transcription
of the typing rules and get the expected behavior. Here are the rules again from last time:

<center><img src="/blog/taksim-modes-bidir-spec.svg" alt="Bidirectional typing" width="500" /></center>

```makam-hidden
type_check, type_synth : expr -> typ -> prop.
mode type_check [input, input].
mode type_synth [input, output].
```

And here is how we transcribe them into Makam.

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

Here, I have tweaked the command transformer to show what clause
actually gets added to Makam, to inspect the result of mode transformation. If you run the Makam code in your browser, the transformed clause will be presented below each rule.

These rules now have the expected behavior:

```makam
type_check (lambda (fun x => x)) (arrow tunit tunit) ?
type_check (lambda (fun x => x)) T ?
type_check (lambda (fun x => x)) (arrow tunit T) ?
type_check (lambda (fun x => x)) (arrow tunit (arrow tunit tunit)) ?
```

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

So in summary, all pieces of mode declarations can now be implemented as a library in Makam:

- the mode declaration itself can be declared as rules for a predicate, rather than a new built-in directive
- through the use of GADTs, we can make sure that the mode declaration includes as many arguments as each predicate defines
- we can write normal predicates that transform clauses as needed, to conform to the declared mode, thanks to the fact that Makam clauses can be viewed as normal Makam terms. This does not require some other meta-language -- in a sense, Makam is its own metalanguage.
- through the new feature of command transformers, we can apply these transformations automatically, whenever needed

One benefit of implementing mode declarations as a library is that we can further experiment with generalizations that our simple input and output modes do not cover right now. One example is a "mixed" mode for arguments that include both input and output parts -- proceeding by pattern matching for the input parts, and switching to full unification for the parts of the terms marked as output. Details about this are beyond the scope of this post, but if you are interested, you can find more details and an example in the [source code of this post]({{< post-markdown-url >}}).

```makam-hidden
%extend modes_enforcing.
%extend modes_mixed.

(* Mixed-mode pattern matching:

   mixed_match P E
     does normal pattern matching of E against pattern P,
     switching to unification for any parts of the pattern
     P that are annotated with `out`.
*)

out : A -> A.

mixed_match : [A]A -> A -> prop.

mixed_match_aux : [A]reified A -> reified A -> prop.

mixed_match A B :- once(reify A AR), once(reify B BR), mixed_match_aux AR BR.

mixed_match_aux (reified.term out [L])
                R :-
  reflect L L', reflect R R', unify L' R'.

mixed_match_aux (reified.unifvar _ _ _ L)
                R :-
  reflect R R', eq L R'.

mixed_match_aux (reified.term Head Args) (reified.term Head Args') when not(dyn.eq Head out) :-
  reified_args.map @mixed_match_aux Args Args'.

mixed_match_aux (reified.bvar Head Args) (reified.bvar Head Args') :-
  reified_args.map @mixed_match_aux Args Args'.

mixed_match_aux (reified.nvar Head Args) (reified.nvar Head Args') :-
  reified_args.map @mixed_match_aux Args Args'.

mixed_match_aux (reified.const Const) (reified.const Const).

mixed_match_aux (reified.lambda F) (reified.lambda F') :-
  (x:A -> mixed_match_aux (F x) (F' x)).

mixed : argument_mode.
generate_matches
    (mixed :: Modes)
    (Pattern :: Patterns)
    (Arg :: Args)
    ((mixed_match Pattern Arg) :: Rest) :-
  generate_matches Modes Patterns Args Rest.

>> mixed_match (app E1 eunit) (app E1' E2') ?
>> Impossible.

>> mixed_match (app E1 (out eunit)) (app E1' E2') ?
>> Yes:
>> E1' := E1,
>> E2' := eunit.

(* Example:
   (non-bidirectional) type-inferencing where all subterms
   are annotated with their type. The type of each subterm
   starts out as unknown, but after successfull type-checking,
   will match the type discovered for the subterm.

   The main rules for type-inferencing work on subterms
   annotated with their type, `annot E T`. These require using
   the mixed mode: the part `E` should be an input, while the
   part `T` is an output.

*)

(* First, a predicate that decorates all `expr` subterms `E` within
   a term, turning them into a `annot E T` term with an unknown
   type `T`. *)

annotate_with_types : [A] A -> A -> prop.

annotate_with_types E E' :-
  if (dyn.eq E (annot E0 T))
  then (refl.decompose_term E0 Head Args,
        structural @annotate_with_types Args Args',
        refl.recompose_term Head Args' E1,
        dyn.eq E' (annot E1 T))
  else if (dyn.eq E (E0: expr))
  then (structural @annotate_with_types E0 E1,
        dyn.eq E' (annot E1 T1))
  else (structural @annotate_with_types E E').

>> annotate_with_types (lambda (fun x => app x eunit)) E ?
>> Yes:
>> E := annot
          (lambda (fun x =>
            annot
              (app
                (annot x (T_x x))
                (annot eunit (T_eunit x)))
               (T_app x)))
            T_lambda.


type_infer : expr -> prop.
mode type_infer [mixed].

type_infer_aux : expr -> typ -> prop.
mode type_infer_aux [input, output].

type_infer (annot (app E1 E2) (out T2)) :-
  type_infer_aux E1 (arrow T1 T2),
  type_infer_aux E2 T1.

type_infer (annot (lambda E) (out (arrow T1 T2))) :-
  (x:expr -> type_of_var x T1 -> type_infer_aux (E x) T2).

type_infer (annot X T) :-
  type_of_var X T.

type_infer (annot eunit (out tunit)).

type_infer_aux (annot E T) T :-
  type_infer (annot E T).


do_type_infer : expr -> expr -> prop.

do_type_infer E E' :-
  annotate_with_types E E',
  type_infer E'.

>> do_type_infer (lambda (fun x => annot (app x eunit) tunit)) X ?
>> Yes:
>> X := annot (lambda (fun x => annot (app (annot x (arrow tunit tunit)) (annot eunit tunit)) tunit)) (arrow (arrow tunit tunit) tunit).

%end.
%end.
```

## mode checking

So far in these two posts, we have treated mode declarations as a "runtime"
concern -- namely, mode declarations transform our predicates in order
to enforce a specific mode when they get executed, by using pattern matching instead
of unification, etc. This follows the approach of λProlog dialects like
[ELPI](https://github.com/LPCIC/elpi/).

However, it is more common
in logic programming languages to treat mode declarations similarly
to type declarations -- that is, as an additional piece of
information that guide a "static" check of our logic programs, issuing errors at the point where a mode violation might occur in our program text. This way,
if a rule of a predicate like `type_synth` fails to conform to its
mode declaration, we would get an error at the point where the rule is
declared, rather than at any point where the rule could be executed.
Similarly, if we issue a query that does not conform to the declared
modes, we would get an error at that point as well. This approach is
the one taken for example in [Twelf](https://www.cs.cmu.edu/~twelf/guide-1-2/twelf_6.html), [Mercury](https://www.mercurylang.org/information/doc-latest/mercury_ref/Predicate-and-function-mode-declarations.html#Predicate-and-function-mode-declarations), and others.

Could it be possible to implement this approach to mode declarations
within Makam itself, without changing the core language? Thanks to
toplevel command transformers, it turns out that yes, that's indeed
possible! We can use command transformers as a hook that allows us
to execute an analysis for every new rule or query. We do not need
to transform the rules and queries per se, but we can issue any
errors that we detect as needed. So the combination of a
staging (made "transparent" through command transformers),
together with the reflective features of Makam
will allow us to *implement a new static analysis for Makam within
Makam itself*. This has parallels to how Racket, for example,
can be used to implement [Typed Racket](https://www2.ccs.neu.edu/racket/pubs/popl08-thf.pdf).

The bulk of the work of implementing mode checking is of course
implementing the static analysis itself. We will implement a rudimentary
version of the [Twelf mode checking algorithm](https://www.cs.cmu.edu/~twelf/guide-1-2/twelf_6.html#SEC31). This will cover enough
of Makam for the analysis to be meaningful for our running example
of bidirectional type checking.

The gist of the algorithm is this:

- looking first at the goal of each rule, we mark all unification variables within input arguments as ground
- we then visit the premises of the rule, making sure that unification variables within input arguments are ground, and marking any variables within output arguments as ground
- last, going back to the goal of the rule, we make sure that unification variables within the output arguments are ground

During this algorithm, any unification variables that should be ground but are not should be reported to the user as a mode violation.

The implementation of this analysis in Makam is relatively straightforward. It follows the above description closely and takes about 150 lines of code together with comments and tests. The main entry point for the analysis are two `mode_check` predicates for checking clauses and other predicates. These make use of a helper predicate that marks unification variables within an input or output term as ground, or checks that unification variables are ground already. For the full details of the implementation please refer to the [source code of this post]({{< post-markdown-url >}}).

```makam-hidden
%extend modes_checking.

argument_mode : type.
input, output : argument_mode.

mode_spec : type -> type.
nil : mode_spec prop.
cons : argument_mode -> mode_spec B -> mode_spec (A -> B).

mode : [A] A -> mode_spec A -> prop.

mode_declared : [B] prop -> mode_spec B -> prop.

mode_declared Goal Mode :-
  refl.decompose_term Goal Pred _,
  mode Pred Mode.

test_predicate : expr -> typ -> prop.
mode test_predicate [input, output].

>> mode_declared (test_predicate E T) X ?
>> Yes:
>> X := [input, output].



mode_info : type.
ground : mode_info.

visit_type : type.
check, mark: visit_type.


(* The main operation of the mode checking algorithm is the
    `mode_visit_predicate`:

   This is used to visit all unification variables in a predicate,
   which exist within an argument marked as an input or output
   argument (controlled by the `argument_mode` flag).

   Every unification variable is either marked as ground,
   or checked to already be ground, based on the `visit_type` flag.

   The `map int mode_info` is kept as state representing
   which unification variables are marked as ground.
*)

mode_visit_predicate : [A] visit_type -> argument_mode -> prop -> mode_spec A -> map int mode_info -> map int mode_info -> prop.

mode_visit_predicate_args : [A] visit_type -> argument_mode -> args A prop -> mode_spec A -> map int mode_info -> map int mode_info -> prop.

mode_visit_term, mode_visit_unifvar : [A] visit_type -> map int mode_info -> A -> map int mode_info -> prop.

mode_visit_predicate VisitType ArgMode Goal Mode Map Map' :-
  refl.decompose_term Goal _ Args,
  mode_visit_predicate_args VisitType ArgMode Args Mode Map Map'.

mode_visit_predicate_args VisitType ArgMode (Term :: Rest) (ArgMode :: Rest') Map Map'' :-
  mode_visit_term VisitType Map Term Map',
  mode_visit_predicate_args VisitType ArgMode Rest Rest' Map' Map''.

mode_visit_predicate_args VisitType ArgMode (Term :: Rest) (ArgMode' :: Rest') Map Map' when not(eq ArgMode ArgMode') :-
  mode_visit_predicate_args VisitType ArgMode Rest Rest' Map Map'.

mode_visit_predicate_args _ _ [] [] Map Map.

(* do a structural fold through a term, calling out to
   mode_visit_unifvar whenever we encounter a unification
   variable. This only covers strict occurrences of unification
   variables, as the Twelf mode checking algorithm specifies:
   we do not recurse within the substitutions used with
   unification variables, where we could have non-strict
   occurrences of further unification variables. *)
mode_visit_term VisitType Map X Map' :-
  if (refl.isunif X)
  then (mode_visit_unifvar VisitType Map X Map')
  else (generic.fold @(mode_visit_term VisitType) Map X Map').

mode_visit_unifvar mark Map X Map' :-
  refl.decomposeunif X I _,
  map.add_or_update Map (I, ground) Map'.

mode_visit_unifvar check Map X Map :-
  refl.decomposeunif X I _,
  if (map.find Map I ground)
  then success
  else (tostring X XS, log_annotation X `mode violation: variable ${XS} not ground`, failure).



>> (mode_visit_predicate mark input (test_predicate (app E1 E2) B) [input, output] [] Y, refl.decomposeunif E1 I_E1 _, refl.decomposeunif E2 I_E2 _, refl.decomposeunif B I_B _) ?
>> Yes:
>> Y := [ (I_E2, ground), (I_E1, ground) ].

>> (mode_visit_predicate mark output (test_predicate (app E1 E2) B) [input, output] [] Y, refl.decomposeunif E1 I_E1 _, refl.decomposeunif E2 I_E2 _, refl.decomposeunif B I_B _) ?
>> Yes:
>> Y := [ (I_B, ground) ].

>> (mode_visit_predicate mark input (test_predicate (app E1 E2) B) [input, output] [] _Map, mode_visit_predicate check input (test_predicate (app E1 E2) B) [input, output] _Map Y, refl.decomposeunif E1 I_E1 _, refl.decomposeunif E2 I_E2 _, refl.decomposeunif B I_B _) ?
>> Yes:
>> Y := [ (I_E2, ground), (I_E1, ground) ].


(* The main part of the mode checking algorithm is a rudimentary
    version of the Twelf mode checking algorithm, as
    described in the Twelf User Guide by Frank Pfenning and
    Carsten Schürmann, at:

    https://www.cs.cmu.edu/~twelf/guide-1-2/twelf_6.html#SEC31


    For every clause:
     - we first mark all variables within input arguments as ground
     - we proceed to check the premises for mode correctness
     - in each premise:
       - we validate that all variables within input arguments are already ground
       - we mark all variables within output arguments as ground
     - we validate that all variables within output arguments are ground

*)


mode_check : map int mode_info -> clause -> map int mode_info -> prop.
mode_check_per_mode : [A] map int mode_info -> clause -> list clause -> map int mode_info -> prop.

mode_check, mode_check_rules : [A] map int mode_info -> prop -> map int mode_info -> prop.

mode_check Map (clause Goal Premise) Map''
    when mode_declared Goal Mode :-
  mode_visit_predicate mark input Goal Mode Map Map',
  mode_check Map' Premise Map'',
  mode_visit_predicate check output Goal Mode Map'' Map''.

mode_check Map P Map' :-
  if (refl.rules_get_applicable (mode_check_rules Map P Map') [])
  then (tostring P PS, log_annotation P `don't know how to do mode checking for ${PS}, add a mode declaration or specialized rule`)
  else (mode_check_rules Map P Map').

mode_check_rules Map success Map.

mode_check_rules Map (and P1 P2) Map'' :-
  mode_check Map P1 Map',
  mode_check Map' P2 Map''.

mode_check_rules Map (newvar F) Map' :-
  (x:A -> mode_check Map (F x) Map').

mode_check_rules Map (assume Clause P) Map'' :-
  mode_check Map Clause _,
  mode_check Map P Map''.

mode_check_rules Map P Map''
    when mode_declared P Mode :-
  mode_visit_predicate check input P Mode Map Map',
  mode_visit_predicate mark output P Mode Map' Map''.

mode_check_existing_rules : A -> prop.
mode_check_existing_rules Predicate :-
  refl.rules_get Predicate Rules,
  map (pfun Clause => [Map] once(mode_check [] Clause Map)) Rules.

mode_check : clause -> prop.
mode_check Clause :- mode_check [] Clause _.

mode_check : prop -> prop.
mode_check P :- mode_check [] P _.

(* Mode specifications for other predicates that we'll use. *)

mode unify [input, output].

mode type_of_var [input, output].
```

Once these analysis predicates are implemented, all we have to do
is register them as toplevel command transformers, so that they
will analyze all new rules and queries, and emit errors if needed:

```makam
toplevel_command_transformer "mode-checker"
    (cmd_newclause Clause)
    (cmd_newclause Clause)
  when clause.get_goal Clause Goal, mode_declared Goal _ :-
    mode_check Clause.

toplevel_command_transformer "mode-checker"
    (cmd_query Query)
    (cmd_query Query)
  when mode_declared Query _ :-
    mode_check Query.
```

```makam-hidden
(* Tests *)


type_synth_correct, type_check_correct : expr -> typ -> prop.

(* We don't specify modes here to avoid triggering the
   modes checker; instead, we write an explicit mode checking
   test below. *)

type_synth_correct X A :-
  type_of_var X A.

type_check_correct E B :-
  type_synth_correct E A, unify A B.

type_synth_correct (annot E A) A :-
  type_check_correct E A.

type_check_correct eunit tunit.

type_check_correct (lambda E) (arrow A1 A2) :-
  (x:expr -> type_of_var x A1 -> type_check_correct (E x) A2).

type_synth_correct (app E1 E2) B :-
  type_synth_correct E1 (arrow A B),
  type_check_correct E1 A.

type_synth_error1 : expr -> typ -> prop.
type_synth_error1 (app E1 E2) B :-
  type_synth_correct E1 (arrow A B),
  type_check_correct E1 A'.

type_check_error2 : expr -> typ -> prop.
type_check_error2 (lambda E) (arrow A1 A2) :-
  (x:expr -> type_of_var x A1' -> type_check_correct (E x) A2).

with_modes : prop -> prop.
with_modes P :-
  assume_many [
    mode type_synth_correct [input, output],
    mode type_check_correct [input, input],
    mode type_synth_error1 [input, output],
    mode type_check_error2 [input, input]
  ] P.

>> (with_modes (mode_check_existing_rules type_synth_correct), with_modes(mode_check_existing_rules type_check_correct)) ?
>> Yes.

>> (with_modes (mode_check_existing_rules type_synth_error1)) ?
>> Impossible.

>> (with_modes (mode_check_existing_rules type_check_error2)) ?
>> Impossible.

%end.
```

Let's try this out! Repeating our `type_check` and `type_synth`
predicates from earlier, mode checking does not produce any errors,
meaning that they are mode correct. However, if we violate the given
mode declarations, we will get the expected errors: any unification
variables in input arguments that are found to be non-ground will be
highlighted. You can experiment with this below, as the following
Makam code block is editable. Try some changes that should fail mode
checking and see what happens when you re-run Makam. For example, you
can change the modes of `type_check` and `type_synth`; you can rename
unification variables so that they are not ground, e.g. by turning the
`type_of_var X A1` assumption in the lambda typing rule into
`type_of_var X A`; you can change the `type_check` query to violate
the mode declaration, leaving the type argument unknown as a
unification variable `T`, etc.

```makam-input
%open modes_checking.

type_synth, type_check : expr -> typ -> prop.

mode type_check [input, input].
mode type_synth [input, output].

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

type_check (lambda (fun x => x)) (arrow tunit tunit) ?
```

Of course, the mode checking algorithm here only covers a small part
of Makam. It would need to be extended to handle, for example,
higher-order predicates, like `map`; predicates that can be
used with multiple modes, like `unify`; or predicates with
arguments that don't qualify either as input or output. Still, I
believe that the approach outlined here could be generalized to
handle these cases as well.

## conclusion

In summary, we have covered two approaches to supporting
mode declarations in Makam: either through *runtime enforcement* semantics, where modes are used to do a source-to-source transformation of
our programs, so as to behave according to their mode when they
are executed; or, through *static checking* semantics, where any mode
violations are directly reported to the user as errors.

We were able to implement both approaches within Makam itself,
whereas typically these approaches would need to be part of the core
of a logic programming language like Makam. We implemented these
approaches as libraries instead, through the use of staging and
reflection -- that is, we have used Makam code to inspect, analyze,
and produce other Makam code. This is a powerful combination, and
in future posts of this series, I would like to explore how to
use similar ideas to implement features like macro definitions
and functional syntax for Makam.
