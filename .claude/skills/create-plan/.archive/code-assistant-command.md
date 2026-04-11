# MANDATORY SYNC PROTOCOL

1. Before making changes, analyze the [CONTRIBUTING.md], [docs/designs/architecture.md] and [docs/designs/use_cases.md] designs of the current system.

2. Read the [.ai/state/plan.md] first.

3. Create a [docs/designs/gap_analysis.md] which analyzes where to focus for the current Iteration of the work.

4. Update the [.ai/state/plan.md] based on a [.ai/templates/__plan.md] with the updated instructions as required.

5. Analyze remaining references in the [docs/designs/use_cases.md] and [docs/designs/architecture.md] to ensure all use cases are corrected updated.

6. Begin implementation as plan.

7. Follow validation steps to confirm everything works.

8. Once completing a change commit your changes as defined in [CONTRIBUTING.md] and update the [CHANGELOG.md], using the git commit id using git log -1. and a description of the change. And the date and time.

9. Run the debugging strategies defined in the [CONTRIBUTING.md] to ensure the system is functioning correctly.

10. Once no errors are found, update the [.ai/state/plan.md] CURRENT STATUS sections.

11. Update the documents with the changes made by altering the [docs/designs/architecture.md] and [docs/designs/use_cases.md] and the [docs/designs/gap_analysis.md] designs of the current system.

🔄 CONTINUE THE SYNC PROTOCOL UNTIL THE PLAN IS FULLY AUTOMATED.

## Recovery Commands (For Context Loss)

**MANDATORY SEQUENCE** - Execute in this exact order:

1. `read_file ./.ai/state/plan.md` - **FIRST PRIORITY** - Full project plan
2. `read_file docs/designs/use_cases.md` - **SECOND PRIORITY** - All use cases for tracking
3. `read_file ./docs/designs/*.md` - Design documents status
4. `list_dir src/` - Implementation status
5. `get_errors ["src/"]` - Current issues

**Plan & Use Case Sync Command**: Always run after context recovery:

```txt
[PLAN-SYNC] Read ./.ai/state/plan.md and docs/designs/use_cases.md, cross-reference with current session state, validate milestone progress and use case completion. Update the CHANGELOG.md.
```
