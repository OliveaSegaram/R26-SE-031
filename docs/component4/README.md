# Component 4 — Adaptive Tutoring and Item Selection

Component 4 now uses one shared adaptive protocol across every task in Skills
1–4 (19 activities). Each activity keeps its own Grade 1 Sinhala interaction,
but item identity, evidence updates, remediation, confirmation, selection, and
research logging are common services rather than 19 separate policies.

## End-to-end runtime

```text
Grade 1 task UI
  -> stable item ID + first-attempt telemetry + supported scaffold capabilities
  -> API gateway stores one idempotent raw evidence event
  -> adaptive service resolves canonical item/KC/difficulty
  -> BKT updates KC mastery from the first independent response
  -> Rasch/IRT updates ability for that KC and reports measurement uncertainty
  -> bounded policy chooses core, exact V1 remediation, or exact V2 confirmation
  -> shared Flutter navigation contract renders that exact item's distinct content
  -> progress remains on the original core dot during V1/V2
  -> one adaptive decision is stored with model and stopping evidence
```

Assisted final success is useful instructional evidence, but it is not counted
as independent mastery. A stale or duplicated mobile completion cannot bypass a
pending remediation or confirmation item.

## Equivalent-task protocol

Every Skill 1–4 core item has two unseen equivalents in the same KC and
equivalent group. V1 is reduced in task load when a valid easier task can be
authored; V2 preserves the core load and difficulty for independent evidence.

| Result on displayed item | Next item | Purpose |
|---|---|---|
| Clean independent core success | Next unseen core | Continue measurement |
| Correct on the first attempt with normal Grade 1 thinking time | Next unseen core | Do not create an unnecessary repeat |
| Strong, multi-signal independent struggle | Exact `V2` | Independent confirmation |
| Assisted or failed core with a valid lower-load task | Exact `V1` | Easier remediation |
| Assisted or failed floor task | Exact `V2` only | One different same-level retry; do not invent an invalid easier task |
| `V1` completed | Exact `V2` | Remove assistance and confirm |
| `V2` completed | Next unseen core | Bounded exit; no loop/reuse |

If V2 still requires help, the child continues without an endless loop and the
state records a teacher-review recommendation. V1/V2 use different task
content—not the failed task and not a previously completed task. The progress
dot stays attached to the source core task throughout the sequence.

A 3–5 second pause is normal for this age group. The app records latency for
research, but uses an 8-second hesitation event threshold and requires strong,
combined evidence before labelling an independently correct response as
struggled. A high fatigue proxy is recorded with a recommendation to offer a
break after the activity; it cannot masquerade as successful completion.

## Task-family scaffolds

The backend sends semantic commands, never colors or pixel coordinates. Each
screen advertises only actions it can safely implement.

| Family | Safe behavior |
|---|---|
| Choice/image/audio/fill blank | Remove only identified distractors, highlight, replay |
| Pair matching | Highlight/replay; never remove a letter needed by another pair |
| Sequence | Reveal the first required token; never remove a future required token |
| Hidden search | Guide a remaining target |
| Sorting | Guide the correct destination |
| Pattern/memory | Highlight/replay while retaining required choices |

Choice pools are rebuilt from visible options with `Wrap`, so remaining answers
re-center and close the removed space automatically. The correct target is
protected and at least two visible choices remain.

## Item-bank status

The deterministic source generator is
`app/backend/adaptive-tutoring-v1/generate_component4_curriculum.py`.
Do not hand-edit generated V1/V2 blocks without updating that generator.

Current validation result:

- Skills 1–4: 97 core tasks + 194 distinct equivalents = 291 active items;
- whole bank: 115 core + 194 equivalents = 309 active items;
- zero duplicate equivalents;
- zero unknown KCs;
- zero runtime-generated placeholder items.

Validate without a database:

```bash
cd app/backend/adaptive-tutoring-v1
source venv/bin/activate
python -c "from item_bank_builder import build_items, validation_summary; print(validation_summary(build_items()))"
```

After reviewing the output, seed the new records idempotently:

```bash
export MONGODB_URI='your-real-connection-string'
python seed_item_bank.py
python seed_item_bank.py --apply
```

The first command is a dry run. `--apply` performs the database write.

## Models and scientific status

Component 4 uses complementary, auditable models:

1. **BKT** estimates mastery separately for each Sinhala knowledge component.
2. **Rasch/1PL IRT** maintains KC-scoped learner ability, matches item
   difficulty, and records test information and standard error.
3. **Deterministic bounded policy** converts model evidence and task
   capabilities into reproducible instructional actions.

Initial BKT and difficulty values are explicitly expert-provisional. They must
not be described as validated or trained on children. The offline calibrator
uses only deduplicated independent first attempts and refuses to estimate a
parameter below its evidence threshold.

Dry-run real-data calibration:

```bash
cd app/backend/adaptive-tutoring-v1
source venv/bin/activate
export MONGODB_URI='your-real-connection-string'
python calibrate_item_bank.py --min-item-responses 30 --min-kc-responses 200 --min-kc-students 30
```

After educator/researcher review of coverage, subgroup balance, Rasch fit, BKT
holdout log loss, and data quality, activate the estimates explicitly:

```bash
python calibrate_item_bank.py --min-item-responses 30 --min-kc-responses 200 --min-kc-students 30 --apply
```

`--apply` updates eligible item difficulties and registers eligible BKT models.
The service loads only registry entries marked `active`; under-supported KCs
continue using documented provisional priors.

## Research evidence

Each completion preserves student/session/event IDs, exact core/V1/V2 item ID,
KC, difficulty, anchor status, first and final correctness, attempts, latency,
errors, scaffold applications, mastery before/after, KC-scoped theta
before/after, information, standard error, selection reason, policy version,
progress, and stopping reason.

The stopping rule is explicit:

- complete only after all core items have evidence and any pending V1/V2 flow
  has ended;
- never convert fatigue into mid-activity completion; retain it as an
  observational signal and recommend a break after the activity;
- do not claim a psychometric precision threshold from a short Grade 1
  activity—the recorded SE is reported for analysis, not used to manufacture
  false certainty.

## Verification

```bash
cd app/backend/adaptive-tutoring-v1
source venv/bin/activate
pytest -q

cd ../../frontend
flutter test test/adaptive_choice_controller_test.dart test/canonical_resolver_test.dart test/adaptive_task_coordinator_test.dart
```

Current Component 4 result: 50 backend tests and 20 focused Flutter tests pass.
The repository-wide frontend/backend suites still contain unrelated existing
parent-dashboard PP2 assertions; they are outside Component 4 and are recorded
separately rather than hidden.

## Research deployment requirements

Before a study, obtain ethics and guardian consent, minimize identifiers,
define retention/deletion rules, audit every Sinhala prompt and equivalent task
with Grade 1 teachers, lock model/content versions, predefine outcome measures,
and report missing data, confidence intervals, calibration sample sizes, and
subgroup performance. The software is an adaptive learning system, not a
clinical diagnostic tool.
