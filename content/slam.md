---
title: Pointer analysis for SLAM
draft: true
---

During the summer of 2007, I interned with
[Ella Bounimova](http://research.microsoft.com/en-us/people/ellab/) and
[Tom Ball](http://research.microsoft.com/en-us/people/tball/) at the
[Software Reliability Group](http://research.microsoft.com/en-us/groups/srr/default.aspx) of
[Microsoft Research](http://research.microsoft.com/), Redmond. I worked on the
[SLAM project](http://research.microsoft.com/en-us/projects/slam/">SLAM project), a static analysis
tool that follows the CEGAR methodology to verify whether Windows device drivers written in C make
valid system API calls according to some specification. I designed and implemented a field-sensitive
pointer analysis algorithm in OCaml, that replaced the existing pointer analysis in SLAM resulting
both in greater precision and increased efficiency. The new analysis allowed SLAM to scale to
one-order-of-magnitude larger device drivers and got shipped as part of the SDK of the next version
of Windows!

