---
name: localize-language
description: >
  Translate the Civilization VI accessibility mod (CAI) into one of the game's
  supported languages, or verify/repair an existing language. Use whenever the
  task is to localize, translate, or add a language folder under src/Text/, to
  fill in missing translated strings, or to check a translated language for
  errors. Locale codes: de_DE, en_US, es_ES, fr_FR, it_IT, ja_JP, ko_KR, pl_PL,
  pt_BR, ru_RU, zh_Hans_CN, zh_Hant_HK.
---

# Localizing the CAI mod into a language

`docs/localization.md` is the full reference. This skill is the working
procedure and the guardrails; read the doc for the rationale and the French
glossary example. `en_US` is the source of truth; `zh_Hans_CN` and `fr_FR` are
complete examples to copy structure from.

## Before starting

1. Confirm the target locale code (from the list in the description).
2. Confirm the terminology quality bar with the user if unstated. Default:
   **match the game's official terms**, not a generic translation.
3. The official glossary is the game's own text at
   `decompiled/Assets/Text/Vanilla_<lang>.xml`. Grep it for the official wording
   of any game concept before inventing one. Some terms are not the literal
   translation (French examples: Amenities = Activités, Housing = Habitations,
   Policy = Doctrine, Civic = Dogme). Expansion product names (Rise and Fall,
   Gathering Storm) stay in English, as the game keeps them.

## The six files per language (all under src/Text/<lang>/)

Translate each from the matching `en_US` file:

1. `cai_text_ui.xml` — main string table (~2300 entries).
2. `AccessibilityPediaText_CAI.xml` — in-game Civilopedia articles (~289).
3. `TutorialText_CAI.xml` — per-screen tutorial text (~260).
4. `hotkey_symbol_names.sql` — spoken symbol-key names (12).
5. `tutorial_advisor_text_CAI.sql` — advisor callouts (104).
6. `modinfo_CAI.xml` — mod Name/Teaser/Description/Authors.

## Hard rules (these are where mistakes happen)

- **Replace, not Row.** In every non-`en_US` XML file, override each string with
  `<Replace Tag="..." Language="<lang>">` — never `<Row>`. Keep the tag identical
  to `en_US`; only `Language` and the inner text change. The translated tag set
  must exactly equal `en_US`'s (missing tags silently fall back to English).
- **Escape apostrophes in SQL.** In the `.sql` files, double every apostrophe
  inside the text (`'` becomes `''`) because single quotes delimit the string.
  Set the `Language` column to the target locale. Each `UPDATE` line must have an
  even number of single quotes.
- **Preserve every token verbatim.** Icon tokens (`[ICON_Gold]`), `[NEWLINE]`,
  `[COLOR_...]`/`[ENDCOLOR]`, numbered placeholders (`{1_Name}`, `{2_Cost}`,
  `{1}`), and plural syntax `{1_Count : plural 1?item; other?items;}` — translate
  only the surrounding words and the words inside each plural branch; keep the
  markup, numbers, `plural`, `1?`, `other?`, and semicolons intact.
- **Spoken key names are a translated, reused convention.** The `LOC_CAI_KEY_*`
  block in `cai_text_ui.xml` and any prose that names keys (in the pedia,
  tutorial, and advisor SQL) must announce each key the same way everywhere.
  `LOC_CAI_KEY_SLASH` stays the literal `/`. Letter keys used as bindings
  (Q, E, A, D, …) stay as the Latin letter. French convention is documented in
  `docs/localization.md`.
- **Never introduce %s/%S handling.** That is a Lua-side hazard the code already
  avoids; translators only supply text with tokens intact — do not strip or
  normalize anything.

## Writing large files without breakage

`cai_text_ui.xml` is ~7000 lines. Do not build it with a shell heredoc — heredocs
break on apostrophes in the translated text. Instead:

1. Read a section of the `en_US` file.
2. Write the translated block to a scratch file with the Write tool (it handles
   UTF-8 and apostrophes natively).
3. Append it with `cat scratch/chunkN.xml >> src/Text/<lang>/cai_text_ui.xml`
   (a plain filename `cat`, no quoting of the content).

Start the file with the header (`<?xml ...>`, `<GameData>`, `<LocalizedText>`)
and a `<!-- LANGUAGE -->` comment; end the last chunk with
`</LocalizedText></GameData>`. Keep the `en_US` section comments in place,
translated or left as English headers, so the files stay diff-able.

## Registering the files in the modinfo

Files not listed in `src/CivViAccess.modinfo` do not load. `modinfo_CAI.xml` is
already listed for every language. Add the five content files to three `<File>`
blocks, mirroring the existing `zh_Hans_CN` lines:

1. Top-level `<Files>` list — all five content files.
2. `FrontEndActions` → `UpdateText id="CAI_LOC_FrontEnd"` — four files only:
   `cai_text_ui.xml`, `AccessibilityPediaText_CAI.xml`, `TutorialText_CAI.xml`,
   `hotkey_symbol_names.sql`. **Do not** add `tutorial_advisor_text_CAI.sql`
   here (both `en_US` and `zh_Hans_CN` omit it — advisor text is in-game only).
3. `InGameActions` → `UpdateText id="CAI_LOC_Ingame"` — all five content files.

Easiest: copy each `zh_Hans_CN` block and change the locale code.

## Verify before calling it done

Run the bundled checker from the repo root:

    python .claude/skills/localize-language/scripts/verify_language.py <lang>

It checks, for the language: XML well-formedness of the four XML files and the
modinfo; tag parity of each translated XML against `en_US`; zero
`Language="en_US"` leftovers; even apostrophe-quote parity on every SQL line; and
that all five content files are registered in the three modinfo blocks (with the
`tutorial_advisor` FrontEnd omission treated as correct). It exits non-zero and
lists problems if anything fails.

The mod cannot be launched from here, so end by telling the user the one thing
that still needs a human: an in-game check with the game set to the target
language, confirming screens, tutorials, and spoken key/command names read
correctly and nothing falls back to English.

## When adding new LOC_CAI_ tags to the mod

If en_US gains a new tag, add it to **every** shipped language folder (use
`<Replace>` in non-`en_US`), not just en_US — a tag missing from a language falls
back to English and breaks that translation.
