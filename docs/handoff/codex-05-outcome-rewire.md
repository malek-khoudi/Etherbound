# Codex task 05: consume the real outcome authority

**Branch:** `codex/outcome-rewire`
**Closes:** J10-01 (presentation half), J10-02
**Depends on:** `claude/j10-outcome-authority`, already merged.

## What changed on the core side

`Incident` is now the only authority on how an incident ends. It is backed by
`Structure` and `Etherbound`, and it decides from physics.

```gdscript
inc.set_objective(&"walkway", 3)     # who is trapped, how long extraction takes
inc.outcome()                        # {resolved: bool, failed: bool, reason: String}
inc.path_is_standing()               # is the load path over the casualty sound
```

New maintained-effect actions, each with a real lifecycle (J10-03):

| Call | Affinity | Lifecycle |
|---|---|---|
| `brace(unit, member, relief, demand)` | Kinetic | Withdrawn the moment the body drops it |
| `lighten(unit, members, factor, demand)` | Gravitic | Region returns to its own weight on drop |
| `reshape(unit, from, to, capacity, rounds, demand)` | Transmutative | Capacity follows progress; reverts if dropped early; permanent and free once complete |
| `prop(unit, member, amount)` | ordinary | No reserve, persists |

Proven in `game/tests/outcome_test.gd`. Gravitic alone resolves. A prop alone
resolves. Doing all four actions and ending one round does **not** resolve.

## Your job

1. **`vertical_slice.gd` must take its verdict from `Incident.outcome()`**, not from
   `SliceState.end_incident_round()`. Collapse, progression and the consequence branch all
   follow the physical result.
2. **Keep tutorial tracking separate and non-physical.** `SliceState.incident_actions` may
   still record which lessons were covered, and may drive hints. It must never cause a
   collapse or a win. An incomplete lesson is not a structural failure.
3. **Call the new actions** instead of setting gravity or capacity directly. Gravitic and
   Transmutative currently bypass the effect lifecycle.
4. **J10-02: preview and commit must use the same call.** The HUD must render
   `Structure.anchor_report()` computed live against the current world, never the literal
   `89%`/`111%` strings baked into `game/data/vertical_slice.json`. Changing the bracket
   capacity in data must change the displayed numbers with no dialogue edit.
5. **Retune the demands.** Gravitic 5 and Transmutative 6 against a ceiling of 9 never
   produce the advertised "all three at capacity" moment. Tune so an occupied party and an
   essential worker are genuinely produced, then show the resource decision in the HUD.
6. Update the Junctions 4–9 suite where it asserts checklist behaviour
   (`four roles complete the incident`, `complete incident advances`).

## Constraints

- **Do not edit `game/core/**` or `game/tests/outcome_test.gd`, `incident_test.gd`,
  `structure_test.gd`, `reserve_test.gd`.** Problems there go under `## For Claude` in
  `docs/TASKS.md`, as you did with the anchor_report bug. That worked and was correct.
- `./tools/test.sh` must stay green across all six suites.
- No canon invention. Names remain `[NEEDS AUTHOR]`.

## Done means

An unfamiliar player can solve the incident **three different physically valid ways**
(Gravitic-only, prop-only, Kinetic-then-prop), the game accepts all three, and doing all
four actions in one round does not skip the extraction work.
