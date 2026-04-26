---
name: phase-awareness
description: Proactively applied at session start and before any implementation work — orients the agent to the current project state and active phase
---

# Phase Awareness

Before starting any implementation work in this project, orient yourself to the current state.

## Step 1: Determine the active phase

1. Read `docs/MASTER_PLAN.md` to understand the full task breakdown
2. Scan the codebase to determine what exists:
   - Does `backend/src/simulation/atomic/` have code? → Phase 1 is at least in progress
   - Does `backend/src/simulation/molecular/` have code? → Phase 2 is at least in progress
   - And so on for organelle (3), cellular (4), tissue (5), organ (6), body (7), organism (8)
3. For the active phase, identify which stage and task you're on by checking which GATE was last passed

## Step 2: Check prerequisites

Before building anything in Phase N:
- Confirm Phase N-1 is complete (all GATE criteria met)
- Within the current phase, confirm all prerequisite tasks for your current task are done
- If prerequisites are NOT met, flag this to the user before proceeding

## Step 3: Scalability gut-check

For every implementation decision, ask: "Will this still work at the next phase's scale?"
- Phase 1 → Phase 2: Does this atom representation work when there are 10,000 atoms in a molecule?
- Phase 2 → Phase 3: Does this force field engine work with CG beads, not just atoms?
- Phase 3 → Phase 4: Does this organelle model work as a compartment in a whole cell?
- Phase 4 → Phase 5: Does this cell model work when there are 100,000 cells?
- Phase 5 → Phase 6: Does this tissue model work as part of an organ?
- Phase 6 → Phase 7: Do these organ models compose into a whole body?
- Phase 7 → Phase 8: Does the PBPK model parameterize for different species?

If the answer is "no" to any of these, redesign before implementing.

## Step 4: Reference the master plan

When the user asks you to build something, find the exact task in `docs/MASTER_PLAN.md` that corresponds to their request. Follow the task's specification for:
- **Where**: Which files to create or modify
- **Depends on**: What must already exist
- **Validates against**: How to know it's correct
- **Scalability check**: Why this approach works at later phases

If the user's request doesn't map to a task in the master plan, ask whether it should be added or if it's a deviation from the plan.