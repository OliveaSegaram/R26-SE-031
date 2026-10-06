# Component 4 — Adaptive Tutoring and Item Selection

Component 4 is implemented as one capability-driven tutoring system shared by
all 25 Grade 1 Sinhala activities. Activities retain their own teaching task,
but no activity owns a separate adaptation policy.

## Runtime architecture

```text
Activity task
  -> stable item/option IDs + first-attempt telemetry
  -> unified learning API
  -> BKT mastery update + Rasch/IRT ability update
  -> deterministic capability policy
  -> semantic scaffold commands
  -> task-family adapter
  -> filtered/reflowed Grade 1 UI + fidelity record
```

The backend sends semantic actions such as `REMOVE_OPTIONS`,
`HIGHLIGHT_OPTIONS`, `REPLAY_INSTRUCTION`, or `REVEAL_FIRST_TOKEN`. It never
sends pixel positions, colours, or layout instructions. The frontend advertises
only the actions the current task can safely render.

## Activity-family coverage

| Family | Skills/activities | Shared behavior |
|---|---|---|
| Choice, image, audio, fill blank | Skills 2–5 | Safe distractor removal, hinting, stable IDs, responsive reflow |
| Matching | Skills 1–2 | Correct destination/option guidance |
| Sequence | Skill 3 activity 5; Skill 4 activity 4 | First-token guidance without removing required tokens |
| Visual search | Skill 1 activity 1 | Target guidance after a search miss |
| Sorting | Skill 1 activity 3 | Correct destination guidance |
| Pattern and memory | Skill 1 activities 4–5; Skill 2 activity 5 | Target guidance and replay support |
| Oral reading | Skill 6 | Replay, slower presentation, and worked-example capability |

Removed answers are filtered before `Wrap` layout. The remaining answers are
therefore re-centered automatically, with no invisible placeholder or
activity-specific post-removal coordinates. At least two visible alternatives
are retained, and a correct target cannot be removed.

## Item bank

Run a non-database validation summary:

```bash
cd app/backend/adaptive-tutoring-v1
python -c "from item_bank_builder import build_items, validation_summary; print(validation_summary(build_items()))"
```

Current generated bank:

- 157 traceable item records;
- 113 core items and 44 equivalent/remedial records;
- 143 active records;
- 0 unknown knowledge components;
- 20 deterministic runtime-generated visual-task records;
- 14 historical Skill 2 variants detected as exact duplicates and marked
  inactive until an educator supplies genuinely equivalent Sinhala content.

Each record includes canonical item ID, KC, activity, template, difficulty,
IRT parameters, stable option IDs, target/distractor role, equivalent group,
allowed scaffolds, content hash, age/language validation, and calibration
status.

Seed MongoDB idempotently after setting the connection environment variable:

```bash
export MONGODB_URI='mongodb://...'
python app/backend/api/scripts/seed_item_bank.py

# After the validation summary is reviewed, explicitly write to MongoDB:
python app/backend/api/scripts/seed_item_bank.py --apply
```

No database credential is stored in the seeding script.

## Models and scientific status

The production decision pipeline uses three complementary mechanisms:

1. **Bayesian Knowledge Tracing (BKT)** updates mastery per Sinhala knowledge
   component. Current priors are explicitly provisional.
2. **Rasch/1PL IRT** updates learner ability online and selects a nearby active
   item on the logit difficulty scale.
3. **Deterministic scaffold policy** escalates support using attempts and the
   task's declared capabilities. Determinism makes a research run auditable.

There is deliberately no synthetic-data model presented as child-validated.
Item difficulties begin as `expert_provisional`. After enough consented real
first-attempt observations exist, run the offline calibrator in dry-run mode:

```bash
cd app/backend/adaptive-tutoring-v1
MONGODB_URI='mongodb://...' python calibrate_item_bank.py
```

The default minimum is 30 independent responses per item. Inspect the report,
data quality, subgroup coverage, and held-out behavior before applying:

```bash
MONGODB_URI='mongodb://...' python calibrate_item_bank.py \
  --min-item-responses 30 --apply
```

`--apply` is required intentionally. Assisted final answers are not treated as
independent correct responses when a first-attempt result is unavailable.

## Research event fields

Every scored task records:

- student/session/event identifiers;
- canonical item, skill, activity, KC, difficulty and anchor status;
- first-attempt correctness, final correctness, total and incorrect attempts;
- selected, visible, correct and removed stable option IDs;
- latency, hesitation, correction, replay and hint counts;
- scaffold level, policy version, reason codes and application result;
- requested/applied IDs, before/after pool size and rejected-command reasons.

This separates independent performance from assisted success and allows
treatment-fidelity analysis rather than merely logging that a hint was sent.

## Verification

```bash
# Adaptive backend
app/backend/adaptive-tutoring-v1/venv/bin/pytest -q \
  app/backend/adaptive-tutoring-v1/tests

# Flutter Component 4 and navigation
cd app/frontend
flutter test test/adaptive_choice_controller_test.dart \
  test/canonical_resolver_test.dart \
  test/adaptive_navigation_test.dart

# Static analysis
dart analyze
```

The tests cover deterministic escalation, capability boundaries, correct-target
protection, the two-choice minimum, idempotency, visual pool reflow, canonical
metadata resolution, item-bank integrity, adaptive navigation, and Rasch
calibration behavior.

## Research limitations

This is a research tutoring component, not a diagnostic medical system. BKT
priors and initial item difficulty values must be recalibrated on representative
real Grade 1 Sinhala learner data. Before study deployment, obtain ethics and
guardian consent, minimize identifiers, define retention/deletion policy, audit
Sinhala content with primary teachers, and report confidence intervals and
missing-data handling.
