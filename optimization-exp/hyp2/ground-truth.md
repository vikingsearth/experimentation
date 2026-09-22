# Ground truth key - hypothesis 2 benchmark task

Date generated: 2026-09-10
Target: `general-experimentation/agentic-workflows`

**Do not give this file to a subagent.** It exists so the blind grader can
check a claimed file path, symbol or line number in seconds rather than
re-investigating. Regenerate it if the target code changes.

## Every file in the target

| Path | Lines |
|---|---|
| `general-experimentation/agentic-workflows/README.md` | 64 |
| `general-experimentation/agentic-workflows/docs/planning/plan.md` | 201 |
| `general-experimentation/agentic-workflows/docs/research/agentic-patterns.md` | 121 |
| `general-experimentation/agentic-workflows/docs/research/business-logic-modeling.md` | 121 |
| `general-experimentation/agentic-workflows/docs/research/frameworks-overview.md` | 129 |
| `general-experimentation/agentic-workflows/docs/research/guardrails-and-hitl.md` | 167 |
| `general-experimentation/agentic-workflows/requirements.txt` | 10 |
| `general-experimentation/agentic-workflows/src/agents.py` | 528 |
| `general-experimentation/agentic-workflows/src/data.py` | 179 |
| `general-experimentation/agentic-workflows/src/main.py` | 192 |
| `general-experimentation/agentic-workflows/src/state.py` | 98 |
| `general-experimentation/agentic-workflows/src/tools.py` | 192 |

## Every symbol defined in the source

| Symbol | Kind | Path | Line |
|---|---|---|---|
| `_header` | def | `general-experimentation/agentic-workflows/src/agents.py` | 39 |
| `_thought` | def | `general-experimentation/agentic-workflows/src/agents.py` | 45 |
| `_action` | def | `general-experimentation/agentic-workflows/src/agents.py` | 49 |
| `_observation` | def | `general-experimentation/agentic-workflows/src/agents.py` | 54 |
| `_result` | def | `general-experimentation/agentic-workflows/src/agents.py` | 58 |
| `TriageAgent` | class | `general-experimentation/agentic-workflows/src/agents.py` | 67 |
| `run` | method | `general-experimentation/agentic-workflows/src/agents.py` | 72 |
| `PolicyAgent` | class | `general-experimentation/agentic-workflows/src/agents.py` | 118 |
| `run` | method | `general-experimentation/agentic-workflows/src/agents.py` | 123 |
| `RiskAgent` | class | `general-experimentation/agentic-workflows/src/agents.py` | 227 |
| `run` | method | `general-experimentation/agentic-workflows/src/agents.py` | 239 |
| `DecisionAgent` | class | `general-experimentation/agentic-workflows/src/agents.py` | 335 |
| `run` | method | `general-experimentation/agentic-workflows/src/agents.py` | 345 |
| `ReviewAgent` | class | `general-experimentation/agentic-workflows/src/agents.py` | 442 |
| `run` | method | `general-experimentation/agentic-workflows/src/agents.py` | 453 |
| `ExpenseApprovalWorkflow` | class | `general-experimentation/agentic-workflows/src/main.py` | 40 |
| `__init__` | method | `general-experimentation/agentic-workflows/src/main.py` | 52 |
| `run` | method | `general-experimentation/agentic-workflows/src/main.py` | 61 |
| `_print_summary` | method | `general-experimentation/agentic-workflows/src/main.py` | 95 |
| `main` | def | `general-experimentation/agentic-workflows/src/main.py` | 146 |
| `AuditEntry` | class | `general-experimentation/agentic-workflows/src/state.py` | 18 |
| `__str__` | method | `general-experimentation/agentic-workflows/src/state.py` | 26 |
| `WorkflowState` | class | `general-experimentation/agentic-workflows/src/state.py` | 31 |
| `log` | method | `general-experimentation/agentic-workflows/src/state.py` | 72 |
| `snapshot` | method | `general-experimentation/agentic-workflows/src/state.py` | 82 |
| `clone` | method | `general-experimentation/agentic-workflows/src/state.py` | 96 |
| `categorize_expense` | def | `general-experimentation/agentic-workflows/src/tools.py` | 36 |
| `lookup_employee` | def | `general-experimentation/agentic-workflows/src/tools.py` | 63 |
| `get_policy_rules` | def | `general-experimentation/agentic-workflows/src/tools.py` | 73 |
| `check_receipt_attached` | def | `general-experimentation/agentic-workflows/src/tools.py` | 83 |
| `get_spending_history` | def | `general-experimentation/agentic-workflows/src/tools.py` | 103 |
| `calculate_risk_score` | def | `general-experimentation/agentic-workflows/src/tools.py` | 120 |
| `get_approval_thresholds` | def | `general-experimentation/agentic-workflows/src/tools.py` | 168 |
| `check_budget_remaining` | def | `general-experimentation/agentic-workflows/src/tools.py` | 178 |

## Module-level data structures

| Name | Path | Line |
|---|---|---|
| `INDENT` | `general-experimentation/agentic-workflows/src/agents.py` | 36 |
| `EMPLOYEES` | `general-experimentation/agentic-workflows/src/data.py` | 8 |
| `POLICIES` | `general-experimentation/agentic-workflows/src/data.py` | 36 |
| `SPENDING_HISTORY` | `general-experimentation/agentic-workflows/src/data.py` | 92 |
| `DEPARTMENT_BUDGETS` | `general-experimentation/agentic-workflows/src/data.py` | 120 |
| `APPROVAL_THRESHOLDS` | `general-experimentation/agentic-workflows/src/data.py` | 134 |
| `SAMPLE_EXPENSES` | `general-experimentation/agentic-workflows/src/data.py` | 142 |
| `CATEGORY_KEYWORDS` | `general-experimentation/agentic-workflows/src/tools.py` | 28 |

## Lines that touch a monetary value

Generated by matching `amount|budget|limit|expense|threshold|per_person|receipt_required|max_single|pre_approval|\$`.
A claim citing a line **not** in this list, in a file that is, deserves a
second look. A claim citing a file not in the file table above is a
fabrication.

| Path | Lines |
|---|---|
| `general-experimentation/agentic-workflows/src/agents.py` | 87 lines: 2 23 24 26 68 76 77 78 79 80 86 89 119 133 136 137 139 140 141 143 144 149 152 154 155 158 163 165 169 180 182 183 188 189 190 195 197 199 200 201 229 258 259 260 262 264 266 271 273 274 276 277 278 280 281 283 285 286 287 289 290 293 312 314 315 349 355 361 362 363 365 366 368 378 379 382 393 397 398 413 422 472 475 482 485 487 494 |
| `general-experimentation/agentic-workflows/src/data.py` | 48 lines: 2 15 23 31 35 38 39 40 44 46 50 51 52 55 56 61 62 63 67 71 72 73 81 82 83 86 95 96 98 103 104 106 111 112 114 119 120 122 127 133 134 141 142 147 156 159 165 174 |
| `general-experimentation/agentic-workflows/src/main.py` | 29 lines: 3 13 16 17 32 40 42 61 62 64 65 68 69 70 127 148 151 154 158 160 161 162 164 167 170 171 179 182 183 |
| `general-experimentation/agentic-workflows/src/state.py` | 6 lines: 6 33 41 50 85 87 |
| `general-experimentation/agentic-workflows/src/tools.py` | 43 lines: 18 19 26 36 38 39 75 83 88 89 91 92 93 97 98 111 112 114 126 128 130 134 135 150 151 152 153 159 163 168 170 171 173 174 175 178 180 181 183 185 190 191 192 |

## Known absences

True statements about the target. A report claiming otherwise is wrong.

| Claim | Status |
|---|---|
| Any currency handling exists | **False.** A case-insensitive search for `currency` across `src/` returns **0** matches |
| The project has third-party dependencies | **False.** `requirements.txt` contains no package lines. The README states standard library only |
| A test suite exists | **False.** **0** files match `test_*.py` or `*_test.py` |

## Traps in the target

Things a careless investigator can get wrong. Not planted, found while mapping
the target, and useful because they separate a real read from a skim.

| Trap | The wrong answer | The right answer |
|---|---|---|
| `requirements.txt` lists `langgraph`, `langchain`, `anthropic` and `openai` | "The project depends on LangChain" | Every one of those lines is **commented out**. They are suggestions for extending the demo. The project has no dependencies |
| The README describes a five-agent pipeline | Treating the README's description as the code | The README is documentation. A claim about behaviour must cite `src/`, not the README |
| `state.py` mentions LangGraph in a docstring | "The project uses LangGraph" | The docstring says what this *would* be in LangGraph. It is a plain dataclass |
| `applicable_limit` is the only obviously monetary field name on the state | "Only one state field holds money" | The `expense` dict also carries `amount`, reached via `.get("amount")` |

## Monetary fields on the shared state

Brief 4 covers this area and it is the sparsest, so it is spelled out here.

```
50:    applicable_limit: float = 0.0;87:            "amount": self.expense.get("amount", 0),;
```
