---
name: pre-commit
description: Final sequential gate before committing — runs 7 checks and reports a verdict
---

Final gate before committing. Run through each check sequentially — do not skip ahead. If a check fails, report it but continue to the next check so the user gets the full picture.

## Check 1: Test suite

- Find all test files in `backend/tests/`
- Determine how to run them (pytest, with what flags)
- Report: how many tests exist, do they pass, is there any simulation module without tests?
- If no tests exist yet, flag as **critical** — do not commit simulation code without tests

## Check 2: Code review

Run the logic from `/review` on all changed files (via `git diff`):
- AGENTS.md coding standards compliance
- Architecture principle adherence
- Security (no secrets in diff)
- Scalability consideration

## Check 3: SAST / security

Mirrors the CI `sast` stage locally (the contract is the `<security>` section of AGENTS.md):
- Backend: `cd backend && uv run ruff check .` (includes the `S` bandit rules) `&& semgrep scan --config auto --error . && uv run pip-audit`
- Frontend: `cd frontend && pnpm lint && semgrep scan --config auto --error . && pnpm audit --audit-level=high`
- Repo root: `gitleaks detect --no-git --redact`
- Report: zero HIGH/CRITICAL findings? Every MEDIUM finding either fixed or suppressed inline with a written justification?
- For every input boundary touched in the diff (endpoint, WebSocket handler, file loader, env var, worker decoder): is it in the `<security>` boundary inventory with its injection class(es) and defense? A new boundary missing from the table is **critical**.

## Check 4: Validation status

Run the logic from `/validate` scoped to changed simulation modules:
- Do changed simulation modules have reference validation tests?
- Are any hard-coded constants introduced?
- Are any Python for-loops over particles introduced?

## Check 5: Unit consistency

For any changed simulation code:
- Are units documented on new variables and functions?
- Are unit conversions at scale boundaries explicit and correct?
- Is the canonical unit system for this scale documented?

## Check 6: Multi-scale interface integrity

If any simulation engine interface changed:
- Does the engine above still receive the correct output format?
- Does the engine below still provide the correct input format?
- Are the timestep and spatial resolution still documented?

## Check 7: Documentation

- Is `backend/src/constants.py` updated if new physical constants were introduced?
- Are new API endpoints documented (FastAPI auto-docs should work if Pydantic models are correct)?
- Are any new data models or engine interfaces documented in docstrings?

## Output format

| Check | Status | Issues |
|-------|--------|--------|
| Tests | PASS/FAIL | Details |
| Code review | PASS/FAIL | Details |
| SAST | PASS/FAIL | Details |
| Validation | PASS/FAIL | Details |
| Units | PASS/FAIL | Details |
| Interfaces | PASS/FAIL | Details |
| Documentation | PASS/FAIL | Details |

**Verdict**: READY TO COMMIT / NOT READY

If NOT READY, list the critical issues that must be resolved first, ordered by priority.