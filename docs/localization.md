# Localizing the mod into a new language

This guide explains how to translate the accessibility mod (CAI) into one of
Civilization VI's supported languages. It documents the workflow used to
produce the French (`fr_FR`) localization, which can be followed to add any
other language.

The mod already ships English (`en_US`) and Simplified Chinese
(`zh_Hans_CN`). Both are good reference examples: `en_US` is the source of
truth for every tag, and `zh_Hans_CN` shows the exact structure a completed
non-English language must follow.

## The language folders

Each language lives in `src/Text/<lang>/`, where `<lang>` is the Civ VI locale
code. The codes the game supports are:

`de_DE` (German), `en_US` (English), `es_ES` (Spanish), `fr_FR` (French),
`it_IT` (Italian), `ja_JP` (Japanese), `ko_KR` (Korean), `pl_PL` (Polish),
`pt_BR` (Brazilian Portuguese), `ru_RU` (Russian), `zh_Hans_CN` (Simplified
Chinese), and `zh_Hant_HK` (Traditional Chinese).

## Files to translate per language

A fully localized language contains six files. Translate them all from the
matching `en_US` file:

1. `cai_text_ui.xml` — the main string table (roughly 2300 entries). Widget
   roles, screen labels, hotkey descriptions, spoken key names, settings, and
   feedback messages.
2. `AccessibilityPediaText_CAI.xml` — the in-game Civilopedia articles that
   document the mod (navigation cursor, Surveyor, World Scanner, lenses, each
   widget type, key-binding reference).
3. `TutorialText_CAI.xml` — per-screen tutorial text.
4. `hotkey_symbol_names.sql` — spoken names for symbol keys (semicolon,
   equals, and so on).
5. `tutorial_advisor_text_CAI.sql` — advisor callout text used by the on-rails
   tutorial.
6. `modinfo_CAI.xml` — the mod's Name, Teaser, Description, and Authors as
   shown in the game's Additional Content list.

The `.xml` files hold `LocalizedText`; the `.sql` files update `LocalizedText`
rows directly.

## Rule 1: use Replace, not Row, in non-English XML

`en_US` defines each string with a `Row`:

    <Row Tag="LOC_CAI_EXAMPLE" Language="en_US">
      <Text>English text</Text>
    </Row>

Every other language overrides that field with a `Replace` and its own
`Language` code — this is the vanilla game pattern for overriding an existing
`LocalizedText` field:

    <Replace Tag="LOC_CAI_EXAMPLE" Language="fr_FR">
      <Text>Texte français</Text>
    </Replace>

Use `Replace` (never `Row`) in every non-`en_US` XML file. The tag stays
identical; only the `Language` code and the text change. A tag that is missing
from a language silently falls back to English, which breaks that translation,
so keep the full tag set identical to `en_US`.

## Rule 2: escape apostrophes in SQL

The `.sql` files use `UPDATE` statements:

    UPDATE LocalizedText SET Text = '...' WHERE Tag = '...' AND Language = 'fr_FR';

SQL uses a single quote to delimit strings, so any apostrophe inside French (or
other) text must be doubled:

    ...SET Text = 'Aujourd''hui' WHERE...

Set the `Language` column to the target locale code. A quick check: the number
of single quotes on each `UPDATE` line should be even.

## Rule 3: preserve every token verbatim

Localized strings contain markup and placeholders that the game replaces or
renders at runtime. Copy them exactly; only translate the surrounding words.

- Icon tokens: `[ICON_Gold]`, `[ICON_Faith]`, `[ICON_Production]`,
  `[ICON_Movement]`, and so on.
- Formatting tokens: `[NEWLINE]`, `[COLOR_...]`/`[ENDCOLOR]`.
- Numbered placeholders: `{1_Name}`, `{2_Cost}`, `{1}`, and similar. Keep the
  number and the underscore-name unchanged; reorder them in the sentence if the
  target grammar requires it.
- Plural syntax: `{1_Count : plural 1?item; other?items;}`. Translate the words
  inside each branch but keep the `plural`, `1?`, `other?`, and semicolons:
  `{1_Count : plural 1?élément; other?éléments;}`.

Percent signs in body text may be adjusted for local typography (French, for
example, uses a space before `%`), but never alter a placeholder itself.

## Rule 4: the spoken key-name convention

The mod defines its own translatable names for keyboard keys, because a screen
reader speaks them out loud. These must be translated consistently everywhere
they appear, so a key is always announced the same way.

They live in two places that must agree:

- The `LOC_CAI_KEY_*` block in `cai_text_ui.xml` (Enter, Escape, Space, arrows,
  Home, End, Page Up/Down, Delete, Backspace, Ctrl, Shift, Alt, and so on).
- Any prose that names keys in `AccessibilityPediaText_CAI.xml`,
  `TutorialText_CAI.xml`, and the advisor SQL.

For French the convention is:

- Enter → Entrée; Escape → Échap; Space → Espace; Tab → Tab.
- Up/Down/Left/Right → Haut/Bas/Gauche/Droite.
- Home → Début; End → Fin; Page Up → Page précédente; Page Down → Page suivante.
- Delete → Suppr; Backspace → Retour arrière.
- Ctrl → Ctrl; Shift → Maj; Alt → Alt.
- "plus" (as in "Ctrl plus S") stays "plus".
- `LOC_CAI_KEY_SLASH` stays the literal `/`.

Letter keys used as bindings (Q, E, A, D, and so on) refer to physical key
positions and stay as the Latin letter.

## Rule 5: match the game's official terminology

Game concepts must use the terms Civilization VI already uses in the target
language, not a generic translation, so the mod sounds native and consistent
with the rest of the interface.

The most reliable glossary is the game's own text. The decompiled vanilla
strings live at `decompiled/Assets/Text/Vanilla_<lang>.xml` and can be searched
for the official wording of any concept. For example, the French terms used in
this mod were taken from `Vanilla_fr_FR.xml`, including some that are not the
obvious literal translation:

- Amenities → Activités (not "Équipements").
- Housing → Habitations.
- Appeal → Attrait, with bands Époustouflant, Charmant, Moyen, Peu accueillant,
  Repoussant.
- Policy → Doctrine; Civic → Dogme.
- Great People → Personnages illustres; Great Works → Chefs-d'œuvre.
- City-States → Cités-États; World Congress → Congrès mondial.
- Governors → Gouverneurs; Grievances → Griefs; Favor → Faveur.
- Key Bindings tab → Assignations; World Builder → Éditeur de monde.
- Expansion product names (Rise and Fall, Gathering Storm) stay in English, as
  the game keeps them: "l'extension Gathering Storm".

The mod also invents names for its own features. Translate these once and reuse
them everywhere. The French choices are: navigation cursor → curseur de
navigation; Surveyor → Arpenteur; World Scanner → Scanner de monde; message
buffer → tampon de messages; map tac → marqueur de carte; bookmark → signet.

## Rule 6: never use %s or %S on localized text in Lua

This is a Lua-side rule, but worth knowing when localizing. Civ VI's Lua treats
the `%s`/`%S` pattern classes as locale-sensitive, and under some languages they
misclassify UTF-8 continuation bytes, corrupting multibyte text. The mod's code
already avoids these patterns and processes all text centrally; translators do
not need to strip or normalize anything — just provide the translated text with
its tokens intact.

## Registering the files in the modinfo

Adding the six files to `src/Text/<lang>/` is not enough; each must be listed in
`src/CivViAccess.modinfo` or the game will not load it. The `modinfo_CAI.xml`
metadata file is already listed for every language. The five content files must
be added to three `File` blocks, mirroring the existing `zh_Hans_CN` entries:

1. The top-level `<Files>` list. Add all five content files here.
2. `FrontEndActions` → `UpdateText id="CAI_LOC_FrontEnd"`. Add four files here:
   `cai_text_ui.xml`, `AccessibilityPediaText_CAI.xml`, `TutorialText_CAI.xml`,
   and `hotkey_symbol_names.sql`. Do not add `tutorial_advisor_text_CAI.sql` to
   this block — the tutorial advisor text is only needed in game, and both
   `en_US` and `zh_Hans_CN` omit it here.
3. `InGameActions` → `UpdateText id="CAI_LOC_Ingame"`. Add all five content
   files here.

The simplest approach is to copy the block of `zh_Hans_CN` lines in each of the
three places and change `zh_Hans_CN` to the new locale code.

## Verifying a completed language

After translating and registering, check each file:

- The whole `.modinfo` still parses as XML.
- Each new `.xml` parses as XML.
- The `Tag="..."` set in each translated `.xml` is identical to its `en_US`
  counterpart (no missing or extra tags).
- No `Language="en_US"` remains in a translated file.
- Every `.sql` line has an even number of single quotes (apostrophes doubled).

A quick way to confirm tag parity for one file is to compare the sorted list of
`Tag="..."` values between the `en_US` file and the translated file; the two
lists should be identical.
