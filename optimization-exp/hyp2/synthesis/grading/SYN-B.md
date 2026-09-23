## The answer

This is a small change wearing a large costume. Four of the five reports frame it as "convert at every comparison" and between them list roughly 45 sites that need currency awareness — but almost all of those collapse if you normalise once, at the moment the expense enters the workflow, and make every downstream comparison, ratio and accumulation operate purely on a base-currency figure. What actually has to be built is one thing that does not exist today: a money representation, a static rate table and a conversion function, plus an explicit declaration that the policy and budget data — currently implicit USD floats scattered across six dicts in `data.py` — is denominated in the base currency. Everything after that is mechanical: about ten arithmetic sites stop reading `amount` and start reading `amount_base`, and about twenty format strings gain a currency code. The genuinely unresolved part is not conversion, it is the aggregates — `SPENDING_HISTORY` and `DEPARTMENT_BUDGETS` hold accumulated totals that become meaningless the moment expenses in different currencies are summed into them, and no report resolved whether those are stored pre-converted or need restructuring.

## What has to change

Grouped by seam, with my sizing — none of the five investigators estimated effort, so these are my numbers, not theirs.

| Seam | What changes | Volume | Why it groups |
|---|---|---|---|
| **Conversion core** (new) | A `Money` type or amount/currency/rate triple, a static rate table, `convert()`, and an unknown-currency error path | New file, ~80 lines. Nothing exists today | All five reports list "is there an FX mechanism?" under *could not determine*. There isn't one. This is the only net-new code, and every other seam depends on it |
| **Static data annotation** | `data.py`: `EMPLOYEES.monthly_budget`, three thresholds × five categories in `POLICIES`, `SPENDING_HISTORY` totals and category breakdowns, `DEPARTMENT_BUDGETS`, `APPROVAL_THRESHOLDS`, plus a `currency` field on each of the four `SAMPLE_EXPENSES` | ~25 literals across 6 dicts | Same decision applies to all of them: declare a base currency once at module level rather than annotating each value. Currently the USD assumption is nowhere written down |
| **Comparison and arithmetic** | `agents.py` 141, 152, 189, 200, 287, 393; `tools.py` 93, 136, 152–159, 191 | ~10 sites | These are the sites that are *silently wrong* rather than broken. Each is a bare `>`, `<=` or `/` between two floats. With normalisation at ingest, each is a one-token edit |
| **Hardcoded limits and rule strings** | The `$50` per-person meal cap (`agents.py:189`) and `$30` alcohol cap (`agents.py:200`); dollar amounts embedded as prose in `POLICIES` rule strings (`data.py` 44, 46, 55, 56, 67) | 2 constants, 5 strings | Both are policy values living outside the policy data. Lift the two constants into `POLICIES`; the prose strings are display-only and can be left, but should be labelled |
| **Aggregates and history** | Whether `total_30_days`, per-category breakdowns, `spent_this_month` and `remaining` are base-currency scalars or per-currency structures | 2 data structures, 2 tool functions | The only seam with a real structural fork. Report 3 is right that a mixed-currency sum is not a number; the fix is a declaration, not a data-structure change, if you choose base-currency storage |
| **State and audit** | `state.py`: `applicable_limit` (50), `snapshot()` (87) to emit original + base + currency; `AuditEntry` currency context | 3–4 touchpoints | Cheap once a base amount is computed at ingest, because state stops needing to know how to convert — it only carries what ingest stamped on |
| **Presentation and docs** | `main.py` 69 and 183; ~16 f-strings across `agents.py`; `README.md` sample table | ~20 format strings | Entirely mechanical, entirely last. Report 5's nineteen findings are one finding repeated |

## The decisions that have to be made first

**1. Convert once at the boundary, or convert at each comparison?**
Options: normalise the expense to base currency at ingest and stamp `amount_base` + `currency` + `rate` onto it; or leave the amount in its original currency and convert at each of the ~10 comparison sites. Four reports implicitly assume the second. **Go with the first.** It turns ten conversion sites into one, makes the wrong thing hard to write (no site is left holding two values in different currencies), and — decisively — it means a partial or abandoned implementation degrades loudly rather than quietly. The second design's failure mode is one missed comparison site producing plausible-looking wrong approvals forever.

**2. Are policy limits and thresholds base-currency-only, or per-currency?**
Options: one set of limits in USD against which everything converts; or per-region/per-category limits in local currency. Reports 1, 2 and 4 all raise this and none resolve it. **Base-currency only.** Per-currency limits are a policy question, not an engineering one, and nothing in the demo suggests regional policy divergence exists. Document the assumption where the base currency is declared.

**3. `float`, or `Decimal` / minor units?**
Only report 1 raised this, once, and then dropped it. **Move to `Decimal`** (standard library, so it costs nothing against the constraint) with an explicit rounding policy at the conversion boundary. Multiplying every amount by a rate is precisely the operation that turns float drift from theoretical into visible, and the aggregates then sum that drift.

**4. Where do rates come from, and as of when?**
Options: a static table in `data.py`; a tool the agents call; a live lookup. **Static table** — it matches the self-contained, stdlib-only shape of the demo. But: **store the rate used on the expense record**, not just the converted amount. Without it, a decision cannot be reproduced or explained after the table changes, and this is an approval workflow whose entire output is a justified decision.

**5. Are the historical aggregates already base currency?**
Options: declare them base-currency and require ingest to convert before accumulating; or restructure them into per-currency maps. **Declare them base-currency.** Report 3's per-currency structure (`{"travel": {"USD": 1500, "EUR": 300}}`) is more honest but propagates into risk scoring, budget utilisation and every consumer of those tools for no gain in a system that already only ever reports one utilisation number.

## Risks

**Silently wrong, ordered first — these produce plausible numbers, not errors.**

1. **Partial conversion coverage.** One missed comparison site — say `tools.py:93`, the least prominent of them — and a 900 EUR expense measures itself against a 1000 USD threshold and auto-approves. Nothing raises. The error is directionally consistent: any currency weaker per unit than USD systematically under-triggers policy checks, so the failures cluster and compound. Decision 1 is the mitigation.
2. **Mixed-currency aggregates.** `spent_this_month`, `total_30_days` and the derived `utilization` ratio feed risk scoring at `tools.py:152–153`. A contaminated total yields a utilisation of 0.78 instead of 0.94 — still a perfectly reasonable-looking ratio, still inside the valid range, still wrong. Report 3 identified this well.
3. **The free-text note parser.** `agents.py:199` extracts an alcohol amount from prose and compares it to a hardcoded 30. Reports 2 and 4 both flag it. Neither established what the parser matches on — if it keys on a `$` symbol, a note reading "€40 wine" matches nothing, the violation is never recorded, and the expense passes clean. A missed violation looks identical to no violation. This needs looking at before anything else in the meal-policy path is touched.
4. **Rounding and round-trip drift.** Convert, store, aggregate, divide, threshold at `> 0.8`. Float drift at the boundary of a threshold flips a discrete outcome.
5. **Non-reproducible decisions.** If the rate is not stamped on the record, the audit trail records a conversion nobody can reconstruct. For a workflow whose product is an auditable rationale, this defeats the purpose.

**Loud failures, lower priority.** Unknown currency codes (no report addressed what happens on an unrecognised code — decide it explicitly, and make it raise). Display showing a converted amount without labelling it as converted, so a reimbursement is disputed at the figure rather than at the rate.

**Process risk.** Not one of the five reports mentions a test suite. Either the demo has none or nobody checked. Given this change is defined by silent wrongness, that is the gap that most concerns me.

## What I would do first

1. **Settle decisions 1 and 3** — boundary conversion, `Decimal`. Half an hour of thinking, and it determines whether the rest of the work is ten edits or fifty.
2. **Find out whether tests exist.** Before writing anything. If they don't, the first commit is a handful of characterisation tests pinning the current USD-only outcomes of the four sample expenses.
3. **Build the conversion core with an identity path.** Rate table, `convert()`, `Decimal`, unknown-code error. Then run the existing four samples with `currency: "USD"` on each and confirm byte-identical output. This proves the scaffolding is inert before it carries weight.
4. **Declare the base currency in `data.py`** as a module-level constant, and annotate the six dicts against it. This is where the implicit assumption becomes explicit and reviewable.
5. **Normalise at ingest** — `main.py` / state construction stamps `currency`, `amount_base` and `rate` onto the expense before any agent runs. Still USD-only at this point.
6. **Rewrite the ten arithmetic sites to read `amount_base`,** and lift the `$50` and `$30` constants into `POLICIES`. Now introduce the first non-USD sample expense. This is the commit where behaviour changes, and it should be the one you review hardest.
7. **Inspect the notes parser** before trusting the meal path.
8. **Presentation and docs last** — the twenty format strings and the README table. Cosmetic, and doing them early creates the illusion the feature works.

Aggregates fall out of step 4 as a declaration. If step 4's review rejects base-currency storage, stop and re-plan — that is the only decision that reshapes the work rather than extending it.

## Confidence and gaps

**Solid.** Location coverage is genuinely good. The reports are line-level, and three of them independently landed on the same call sites — `agents.py` 141, 152, 287 and 393, `tools.py` 93 — from different starting points. That convergence is real evidence, not just redundancy. I would act on the site inventory without re-verifying it.

**Thin.** All five reports punt the FX mechanism to *could not determine*, meaning nobody actually established that no rate source exists — they each looked in their own lane and found none. Nobody estimated effort. Nobody mentioned tests. Precision was raised once by report 1 and never picked up by the four investigators whose areas — arithmetic, ratios, accumulation — are exactly where it bites. Nobody defined unknown-currency behaviour, rate as-of semantics, or whether historical data needs backfilling.

**Overlapping.** Roughly half of the 45 findings are the same code seen from different angles. Reports 2, 4 and 5 substantially re-cover each other on the comparison sites. Report 5 is the weakest per unit of length: nineteen findings that are one finding ("every `$`-formatted f-string needs a currency code"), including F14, which explicitly concludes no change is needed. It read four `docs/` files and reported nothing from any of them, so documentation coverage beyond the README is unverified. Report 3's F7, on historical flag counts, is speculative and self-labelled as inferred; I'd drop it.

**Disagreement.** There is none — and that is the thing that concerns me most. Four reports independently assumed convert-at-each-comparison and not one questioned the framing. Five investigators produced no dissent about the shape of the solution, only about details of schema. The split-five-ways structure got thorough coverage of *where* at the cost of any argument about *how*.

**Before committing.** Confirm a test suite exists and covers the four sample outcomes. Read the notes parser at `agents.py:199` and establish what it matches on. Confirm — properly, not per-lane — that no rate or currency utility exists anywhere in the tree. Those three checks are maybe an hour, and two of them guard against the silent failure modes above.
