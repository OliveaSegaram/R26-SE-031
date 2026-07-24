# Independent Activity — Level Step-Up Flow
## Addition to Component 4 Intervention Cycle

---

## 0. WHAT'S CHANGING

Currently: Independent Activity repeats the same template + same level as
Guided Practice. This wastes a stage — the child just does the same
thing twice.

New behavior: Independent Activity uses the SAME tag, but ONE LEVEL
HIGHER than what Guided Practice just used (falls back to same level if
higher-level content doesn't exist yet). If the content instance at the
higher level is a real word, show a picture alongside it as passive
visual context (not a response mechanism — the child's task/response
type stays the same, e.g. still tap same/different, still pick-the-sound).

This is NOT the picture-matching/vocabulary task idea (that stays
deferred, unchanged). This is purely: reuse existing templates, but with
richer, level-appropriate content, plus an optional picture for
engagement/context when the content is a real word.

---

## 1. FLOW DIAGRAM

```
GUIDED_PRACTICE completes (pass or fail, max 3 attempts either way)
        |
        v
[determine Independent Activity level]
        |
        |-- guided_level = level used in Guided Practice (e.g. 1)
        |-- target_level = guided_level + 1  (e.g. 2)
        |-- does content exist at target_level for this
        |   (tag, specific_instance)?
        |
        |-- YES --> use target_level content
        |-- NO  --> fall back to guided_level content
        v
[select_question() called again]
        |   same tag, new level, exclude_instance = instance just
        |   used in Guided Practice (force a fresh example)
        v
[is the returned content instance a real word (Level 3-4)?]
        |
        |-- YES --> look up picture_ref for this word from
        |           grade1_word_list.json --> attach to question
        |           payload as passive visual context
        |-- NO  --> no picture, proceed as normal (Level 1-2, letter
        |           only)
        v
[Independent Activity runs]
        same template/response mechanism as Guided Practice
        (same/different, pick-the-sound, etc.) — ONLY the level/
        content/picture context changed, not the interaction type
        |
        v
[always completes regardless of correctness - no scoring gate here,
 same rule as before]
        |
        v
REINFORCEMENT stage (unchanged)
```

---

## 2. LEVEL STEP-UP LOGIC (pseudocode)

```python
def get_independent_activity_content(tag, specific_instance,
                                       guided_level, exclude_instance,
                                       table, word_list):
    target_level = min(guided_level + 1, 4)  # cap at Level 4

    candidates = get_candidates(tag, target_level, table, word_list)
    if not candidates:
        # no content at target_level yet (e.g. word list incomplete) -
        # fall back to same level as Guided Practice
        target_level = guided_level
        candidates = get_candidates(tag, target_level, table, word_list)

    candidates = [c for c in candidates if c != exclude_instance]
    if not candidates:
        candidates = get_candidates(tag, target_level, table, word_list)

    content_instance = random.choice(candidates)
    picture_ref = None
    if target_level in (3, 4):
        picture_ref = word_list.get_picture(content_instance.get("word"))

    return {
        "level": target_level,
        "content_instance": content_instance,
        "picture_ref": picture_ref,  # None if not applicable
    }
```

Reuse the EXACT same `template_registry` and engine response-handling
code already built for Guided Practice — only the content source and
level differ. Do not build a separate "Independent Activity template"
system.

---

## 3. PICTURE CONTEXT — WHAT IT IS AND ISN'T

- IS: a static image shown alongside a word-level question, purely for
  engagement/context (e.g. word "බෝට්ටුව" shown with a boat picture
  while the child still does the normal same/different or
  pick-the-sound task).
- IS NOT: a new response type. The child does not tap the picture to
  answer. Do not build picture-selection logic here — that is the
  deferred `word_unfamiliar` idea, out of scope for this addition.
- Picture is optional per word — if `grade1_word_list.json` has no
  `picture_ref` for a given word, just skip showing a picture, do not
  block the activity.

---

## 4. DATA ADDITION NEEDED

`grade1_word_list.json` entries gain one optional field:
```json
{
  "word": "...",
  "tags_present": ["visual_confusion"],
  "relevant_pair_or_letter": ["ට", "ඨ"],
  "grade1_safe": true,
  "picture_ref": "images/boat.png"
}
```
If you don't have images ready yet, leave `picture_ref` as `null` — the
system should treat this as "no picture available," not an error.

---

## 5. BUILD ORDER

1. Implement `get_independent_activity_content()` exactly as above,
   unit test the fallback logic (target_level has no content -> falls
   back correctly).
2. Wire it into the existing cycle state machine at the
   INDEPENDENT_ACTIVITY stage, replacing the current "repeat same
   level" behavior.
3. Confirm existing templates render correctly when fed Level 3-4 word
   content (they should — same template, same response mechanism,
   just longer audio/text).
4. Add `picture_ref` field to `grade1_word_list.json` schema (can stay
   null for all entries initially — wire the display logic so it's
   ready whenever picture assets exist).
5. Test end-to-end: Guided Practice at Level 1 -> Independent Activity
   automatically at Level 2 (or falls back to 1 if 2 unavailable) ->
   confirm picture appears only when content is Level 3-4 and a
   picture_ref exists.
