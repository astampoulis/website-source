---
date: 2018-03-19T18:16:01-04:00
title: "Building a small JavaScript interpreter in Makam"
type: post
---

```makam
expr : type.

stringconst : string -> expr.
intconst : int -> expr.
array : list expr -> expr.
object : list (string * expr) -> expr.
```

```makam-hidden
%open syntax.
```

```makam
expr : syntax expr.
object_field : syntax (string * expr).

`(syntax_rules {{

  expr ->
    stringconst { <makam.string_literal> }
  / intconst    { <makam.int_literal> }
  / array       { "[" <list_sep (token ",") expr> "]" }
  / object      { "{" <list_sep (token ",") object_field> "}" }

  object_field ->
    tuple  { <makam.ident> ":" <expr> }
  / tuple  { <makam.string_literal> ":" <expr> }

}}).
```

```makam
json : syntax expr.
`( syntax.def_js json expr ).
```

```makam-query
(syntax.parse_opt json << { lala: 1, "foo": 2, "zoo-tata": 3 } >> X, syntax.pretty json X Y) ?
syntax.parse_opt json << { rara: 1, "foo": 2 } >> X ?
```
