# Cursor Prompt — Independent Activity Level Step-Up

Copy this into Cursor.

---

Implement the Independent Activity redesign described in
`independent_activity_stepup_spec.md` (already in this repo). Summary
of what to build:

1. Add `get_independent_activity_content(tag, specific_instance,
   guided_level, exclude_instance, table, word_list)` to the content
   generation module (alongside the existing `select_question()` and
   generator functions from `question_content_spec.md`). It should:
   - Try `guided_level + 1` first (capped at Level 4)
   - Fall back to `guided_level` if no candidates exist at the higher
     level
   - Exclude the exact content instance just used in Guided Practice,
     with a fallback if exclusion empties the candidate pool
   - If the resulting content is a Level 3-4 word, attach a
     `picture_ref` looked up from `grade1_word_list.json` (null if not
     present — do not treat missing picture as an error)

2. Update the INDEPENDENT_ACTIVITY stage in the shared 5-stage state
   machine (`intervention_cycle.py`) to call this new function instead
   of repeating the same level/content used in Guided Practice. Reuse
   the exact same template rendering and response-handling code already
   built for Guided Practice — do not create a separate template system
   for this stage. The child's task/interaction type (same/different,
   pick-the-sound, echo, etc.) stays identical; only content level and
   optional picture context change.

3. Add `picture_ref` as an optional field to the `grade1_word_list.json`
   schema (default null). Update whatever loads this file to pass
   `picture_ref` through into the question payload sent to the UI layer
   when present.

4. This stage still always completes regardless of correctness — no
   scoring/gating logic here, same as before.

5. Write a unit test confirming: (a) fallback to guided_level works
   when target_level has no candidates, (b) exclude_instance is
   respected, (c) picture_ref is None when level < 3 or when the word
   has no picture entry.

Do NOT build any picture-tap/picture-selection response mechanism —
the picture is passive visual context only. That is a separate,
deferred feature (`word_unfamiliar` picture-matching task) and is out
of scope here.

Reference files already in the repo: question_content_spec.md,
independent_activity_stepup_spec.md, grade1_akshara_table.json,
grade1_word_list.json, intervention_cycle.py, mastery_tracker.py.
