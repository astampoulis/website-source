---
title: VeriML
---

My dissertation research at Yale focused on the design, metatheory, implementation and usage of a
novel programming language and proof assistant, called VeriML. The goal behind VeriML is to enable
scalable development of logical proofs; the main idea about how to achieve this goal is to have good
support for writing proof-producing functions with precise, typed signatures.

More precisely, VeriML aims to provide a compelling alternative to tactic development compared to
existing approaches, by leveraging a rich type system coupled with a rich ML-style programming
model. I have also shown how generalizations of features of traditional proof assistants, such as
interactive development of proofs and tactics, are a direct consequence of VeriML's design. Thus the
language can be viewed as a proof assistant in its entirety. Through the addition of a simple
staging construct, VeriML provides extensible static checking of proofs and tactics, solving
long-standing issues such as having a safe yet user-extensible conversion rule. Because of this
support, users are free to extend the 'background reasoning' that the proof assistant uses to handle
trivial details with domain-specific sophistication of arbitrary complexity; this simplifies the
development of further proofs and automation, yielding an approach to formal proofs closer to
informal practice.

## Publications

- [VeriML: A dependently-typed, user-extensible and language-centric approach to proof assistants](dissertation.pdf).
This is my Ph.D. dissertation, submitted on November 2nd 2012. This is the canonical reference to
VeriML presenting its design, metatheory, implementation and examples in detail.

- [Static and User-Extensible Proof Checking](popl2012paper.pdf), Antonis Stampoulis and Zhong Shao, _POPL 2012, January 25-27, 2012, Philadelphia, PA, USA_. There is also the [Extended Version](popl2012tr.pdf), with full typing rules and extensive metatheory proofs.

- [VeriML: Typed Computation of Logical Terms inside a Language with Effects](icfp2010paper.pdf),
Antonis Stampoulis and Zhong Shao, _ICFP 2010, September 27-29, 2010, Baltimore, MD, USA_, as well as the [extended version](icfp2010tr.pdf).

## Talks

- [Ph.D.  Defense](https://github.com/astampoulis/dissertation-public/raw/master/defense.pptx),
    October 15, 2012
- [POPL 2012](popl2012slides.pdf), January 26, 2012, Philadelphia, PA,
    USA. [PowerPoint file](popl2012slides.pptx),
    [ACM link with video](http://dl.acm.org/citation.cfm?id=2103690)
- [TYPES 2011](types2011slides.pdf), September 9, 2011, Bergen, Norway. Using VeriML to have an
    alternative, safely user-extensible conversion rule.
- [ICFP 2010](icfp2010slides.pdf), September
    29, 2010, Baltimore, MD, USA. [Video of the talk](https://vimeo.com/16541746).
- [DTP 2010](dtp2010slides.pdf), July 9, 2010, Edinburgh, UK


## Implementation

-   [VeriML version 0.5](popl2012/veriml-0.5.tar.gz). A lot of big and
    small improvements and changes; the most major ones being that
    VeriML is now compiled through translation to ML (instead of
    interpreted) and that there is some inductive definition support.
-   [VeriML version 0.3](popl2012/veriml-0.3.tar.gz). This reflects
    VeriML as described in our POPL 2012 paper.
-   [VeriML version 0.1](icfp2010/veriml-0.1.tar.gz). An older version
    corresponding to our ICFP 2010 paper.
