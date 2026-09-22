# Hypothesis 3 - verification as its own tier

Date: 2026-09-09
Status: **concept, plus one spike run 2026-09-10.** The spike result reshapes the design
Problem: [problem-statement.md](problem-statement.md)
Related: [hypothesis_1.md](hypothesis_1.md), [hypothesis_2.md](hypothesis_2.md)

## Why this is its own document

Verification kept surfacing as a side-effect while designing
[hypothesis 2](hypothesis_2.md), and it does not belong there. Hypothesis 2
asks how cheap the **producing** tier can be. This asks whether a separate
**checking** tier changes that answer. Folding it in would blur what either
result means.

## The hypothesis

> A swarm of cheap subagents followed by a small number of stronger,
> narrowly-scoped verification runs beats an equivalently-priced swarm of
> stronger subagents.

Wikus's shape for it:

> A Haiku swarm followed by 2 or 3 Sonnet verification runs focusing on
> different validation surfaces.

## What a verification run is for

**It gives the manager a trust map.**

A manager receiving five reports from a weak tier has no cheap way to tell
which claims it can build on. Re-reading the source to check defeats the point
of having delegated. A verification run marks up the reports so the manager can
synthesise confidently without redoing the investigation.

It does not make the reports better. It makes them **usable**.

## The idea that makes this more than a spellcheck

The obvious version of verification is one cheap agent checking that file paths
exist. That is worth having and it is nearly free, but it only catches
fabrication.

The version worth testing is **several stronger verifiers, each with one narrow
mandate**. Splitting by surface rather than by report is what makes a strong
model affordable here: each run is short, focused, and reads the reports rather
than the whole codebase.

Candidate validation surfaces, to be narrowed later:

| Surface | Question it answers | Catchable by a cheap verifier? |
|---|---|---|
| Existence | Do the cited paths, symbols and lines exist? | Yes. Possibly by a script with no model at all |
| Accuracy | Does the code actually do what the report says it does? | Partly |
| Completeness | Given the brief, what did the swarm **not** look at? | **No.** Needs a strong model and a specific mandate |
| Consistency | Do any two reports contradict each other? | Partly |
| Standards | Do the findings conform to the project's rules? | No, if the rules require judgment |

**Completeness is the surprising one.** A verifier normally cannot catch
shallowness, because it only checks what was said. A strong verifier handed the
brief *and* the reports, and asked what is missing, can. That single surface is
the reason this design is more interesting than a cheap correctness pass, and
it attacks depth, which hypothesis 2 predicts is exactly where a cheap tier
loses.

## Why the economics might work

Verification is cheaper than investigation for the same subject matter.
Producing an answer means searching a space; checking one means looking at a
known coordinate. A verifier also reads reports rather than a codebase, so its
input is small.

That asymmetry is the whole bet: a strong model on a narrow, short mandate may
cost less than the same model doing the original work, while removing the
specific weakness of the cheap tier.

Rough shape, to be measured rather than trusted:

| Configuration | Relative cost |
|---|---|
| 5 Haiku subagents | 5 units |
| 5 Haiku + 3 Sonnet verifiers on short mandates | to be measured. The bet is that it lands under 10 |
| 5 Sonnet subagents | 10 units |

## Spike - 2026-09-10

Run assets: `optimization-exp/hyp3/spike-01-synthesis-verification/`

### Why this ran first

[Results 2](results_2.md) found three factual errors in the manager's answer
built from the weaker subagent tier, and established that **all three were
manager-side**: the reports were correct and the manager degraded them. That
means a verifier placed between the subagents and the manager would have caught
none of them. The obvious cheap test is therefore to verify **the synthesis**
rather than the reports.

One run, one Sonnet verifier, given the manager's answer and the five reports
it was built from. **No codebase access**, deliberately: all three errors are
detectable from the reports alone, so this tests the cheapest possible form of
verification.

### Result: it caught none of the three

| Known error | Detectable from sources? | Caught? | What the verifier did instead |
|---|---|---|---|
| Two ratio sites listed as needing a currency edit, when the source says "No additional currency logic is needed here" | Yes, the sentence is verbatim in the report | **No** | Flagged the same table row, but for a *different* reason, and argued a further line should be **added** to the edit list. It reproduced the manager's error rather than catching it |
| Static-data work sized at ~25 literals | Yes. The report's line ranges sum to 44 | **No** | Classified it "unverifiable from sources", noting the manager had disclosed it as an estimate. Declined to count the ranges it was given |
| Receipt-threshold check used as the worked example of a wrong auto-approval | Yes. The report describes that location as "indicating a receipt is mandatory" | **No** | Did not examine the example at all |

### What it did find

Four issues, all real, all minor: a dropped line citation, a misquoted example
structure, two invented illustrative figures placed next to a source credit,
and a file count off by one. Useful hygiene. None of it would have changed what
an implementer did.

### What this means

**Cheap verification does not work on this failure mode.** The verifier was
given every piece of evidence needed to catch all three errors and caught none,
while finding four things that did not matter. On one of the three it made the
same class of mistake as the manager, which suggests the failure is not
inattention but that reading a synthesis against its sources is a genuinely
similar task to writing one, and inherits the same weaknesses.

Three consequences for the design:

1. **Verification probably needs ground truth, not just the sources.** Two of
   the three errors become trivial with codebase access: count the literals,
   read the twelve lines around the cited location. That is a much more
   expensive verifier than the one proposed, and it weakens the economic case,
   because a verifier that reads the codebase is doing the investigation again.
2. **Surface framing matters more than model tier.** The verifier was told to
   classify claims as supported, weakened, contradicted, unsourced or
   miscounted. It applied those categories diligently to the wrong claims. A
   mandate naming *what to check* ("every location the answer says needs
   changing, confirm the source did not say it needs no change") would likely
   have worked. That is a prompt design finding, not a model finding.
3. **The 2x2 as originally proposed is now less interesting.** Verifying
   reports was already ruled out by the results-2 correction. Verifying the
   synthesis cheaply has now failed once. What remains worth testing is a
   verifier **with codebase access and a specific mandate**, and the question
   becomes whether it costs less than simply running the stronger tier.

### What this does not settle

One run, one model, one prompt. A differently-worded mandate might catch all
three, which is exactly finding 2 above. Before abandoning the idea, the cheap
next step is the same spike with a mandate that names the checks explicitly.

## Open questions, to flesh out later

1. Which surfaces actually earn a run? Five is too many. Two or three is the
   proposal, and which two is the real design question.
2. Does a verifier need the codebase, or only the reports and the brief? This
   decides the cost.
3. How does a verifier report? A per-claim verdict, a per-report score, or a
   single "here is what to distrust" summary for the manager.
4. Does the manager act on verification automatically, or does it re-task a
   subagent when a claim fails?
5. How do we stop a verifier rubber-stamping? Likely by requiring tool output
   as evidence for each verdict.
6. Does verification beat simply asking the cheap tier for its own evidence up
   front? A brief that demands a tool-call citation per claim may remove most
   of the need. That is the null hypothesis and it is nearly free.

## Dependency

**Blocked on [hypothesis 2](hypothesis_2.md) arm A.** That run produces a
fabrication count for a cheap tier, and a depth score. If fabrication is zero
and depth is close to Sonnet's, most of the surfaces above have nothing to
catch and this document can be closed cheaply.

If it also serves [hypothesis 1](hypothesis_1.md): local subagents are the tier
most likely to invent a path, so a working verification tier would de-risk the
local route as well as the Haiku one.
