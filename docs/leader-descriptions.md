# Leaders - spoken diplomacy scene descriptions

Authoring source for the leader descriptions read on demand with F2 in the
diplomacy and deal views and from the leader picker. Edit here, then run
`scripts/Build-LeaderDescriptions.py` to regenerate
`src/Text/en_US/LeaderDescStrings_CAI.xml` (`--check` verifies it is up to
date). Lint with `scripts/Lint-LeaderDescriptions.py`. The other language
files are translated from the final English.

Keys are the vanilla `LeaderType` (`LOC_CAI_LEADERDESC_<LEADERTYPE>`). Each
entry describes the diplomacy screen: the leader as the game models them,
standing in their painted scene.

## What the game shows

The diplomacy screen is an animated 3D leader in front of painted 2D parallax
layers. No flat image of it ships, but `scripts/Extract-LeaderImages.py`
rebuilds it from the game files: the `FALLBACK_NEUTRAL_<NAME>` cut-out (the
leader alone in the neutral idle pose) composited over the `<LEADER>_1..3`
scene layers from `UI_LeaderScenes.blp`. The fandom wiki's loading-screen
screenshots show the same model in an animated pose and catch props the idle
pose hides. The five Vikings scenario leaders are carved wooden busts with no
scene and are described from the cut-out alone.

## Rules

What goes in:

- Only what is visible in the scene, the cut-out, or the loading-screen
  render, plus the opening name and titles, the documented identity of the
  place, and a short gloss on what a piece of regalia signified. No other
  life facts.
- The pose is the idle cut-out's. A prop the fandom wiki places in the
  diplomacy screen is kept if any image shows it, and when the two poses
  cannot both be true the wiki wins (Gandhi holds his walking stick). A
  gesture only the loading screen shows and the wiki does not mention is
  left out.
- Trust the fandom wiki's scene notes for places and objects. A place the
  wiki only guesses at may be named when the image settles it (Angkor Wat's
  five towers and pool), with the reasoning in the Sources line. Otherwise
  say "a castle in a snowy forest".
- Name what a figure, animal, or emblem is when the image and the culture
  agree (a jaguar helmet, the Faravahar, quetzal feathers). "A beast" is a
  last resort. Identify a real object when record and image agree, and say
  in a few words what it signified.
- A model source is named only when the restaging of a famous work is itself
  the point (Theodora from the San Vitale mosaic). A source that merely
  supplied a face or a costume is not mentioned.
- Personas get their own entry, written to stand alone.
- Every detail must be true of the game's art. When unsure, leave it out.

The opening sentence:

- Full name and titles are the subject, then the verb and the setting:
  "Mohandas 'Mahatma' Karamchand Gandhi stands on the grassy bank of the
  Ganges in the warm light of late afternoon." One sentence, exempt from
  the comma cap, checked against Wikipedia.
- The name is the full personal name with family name, house, clan, or
  patronymic where one exists, and the regnal number folded in: "Frederick I
  of the House of Hohenstaufen". Arabic names keep Arabic order in plain
  letters: "Al-Malik al-Nasir Salah al-Din Abu al-Muzaffar Yusuf ibn Ayyub".
  A name is given once, in its native form, never twice in two languages.
  A familiar name that differs follows in apposition, "Ying Zheng, Qin Shi
  Huang", unless a title restates it ("Temüjin ..., first Great Khan").
- A "son of" clause stays only where the culture's own formal style used it
  (Gilgamesh, Hammurabi, Cyrus, Pericles, Alexander). Other parentage and
  marriage is dropped; a consort is "Queen consort of Sparta".
- An epithet goes in single quotes after the first name or regnal number
  ("Harald III 'Hardrada' Sigurdsson", "Cnut 'the Great' Sweynsson") unless
  that would split a name read as one unit, in which case it follows in
  apposition: "Simón Bolívar, the Liberator". "Called" is used only where the
  bare epithet would misread ("called the Fairy Tale King, King of Bavaria")
  or the sentence says who uses it ("called Kanuni by his subjects"). A
  throne name is "styled": "Deokman, styled Seondeok". Epithets are not
  translated, and a foreign form of the name appears only when famous
  ("known to the Greeks as Ozymandias").
- Titles are the principal ones actually held, stated precisely, with one
  title word covering a list of realms: "King of Germany, Italy, and
  Burgundy". Three to five for a long style, then "and so on". The title
  matching the leader's in-game civilization is always present, in both
  entries for a leader with two. A foreign office gets its plain equivalent,
  "toqui or war leader". A title never repeats a word the name carries
  ("Chandragupta Maurya, first Emperor of India"), and no second sentence is
  spent on names or titles.
- The setting is a few words, the place and the time of day, naming a
  documented landmark. It does not preview the background: what the
  background will describe is introduced there with "a". When the opener
  names a landmark, the background refers back to it ("the castle's Round
  Tower"), or restates the name when many sentences have passed.

The description:

- Fixed order: the person (build, skin, face, hair), dress and regalia,
  props, background from front to far, light last and folded into the
  background sentences, never a closer like "the whole scene is lit in warm
  orange". The sun or moon is named only when its disc is visible.
- Dress is described from what is most visible inward, with consecutive
  garment sentences varying their shape. A material word such as "gold" is
  repeated as often as the regalia is gold.
- An expression is what the face does, never a mood word: "his brows are
  drawn down and together, and he glares out from narrowed eyes", not "his
  eyes are angry" or "his expression is calm".
- Historical terms a well-read listener knows get no gloss: dojo, katana,
  kaftan, kimono, fleur-de-lis, polder, epaulettes, cuirass, rapier, doublet,
  diadem, torc, ziggurat, chiton, himation, baldric, vambrace. Others are
  glossed inline, term first, with "a" for a kind of thing ("a dory, a long
  Greek spear") and "the" only for one particular thing ("the mitsuuroko,
  the three-scales crest of the Hōjō clan"). A gloss says what the thing is
  or what it was for, never "of the period".
- Props are stated as plain facts, never framed by animation state.
- No metaphors: say the shape, the color, or the material.
- Prefer the details that make this leader recognizable.

Length:

- One paragraph, 150 to 300 words as a guide. A visible detail is never cut
  to fit. No sentence over about 35 words.

Grammar:

- Complete sentences, present tense, third person. No "you" or "the viewer";
  say "at the front of the scene".
- "The" only for something already introduced or unique in the scene; a new
  object enters with "a". A pronoun points only at the subject of the
  sentence before it; otherwise name the thing again ("the gown's left
  half").
- One idea per sentence. No dashes, parentheses, ellipses, or slashes. A
  semicolon only to set two short parallel observations side by side, and the
  lint warns on each one. At most one colon, introducing a list. No more
  than three commas in a sentence.
- No hedging ("as if", "seems", "almost"), no evaluative adjectives, no mood
  words. A noun introduced in a sentence is not repeated in it ("into a pool
  that drains as a river", not "into a pool, and a river flows from the
  pool"). Two "X, and Y" sentences in a row are avoided; a detail tacked on
  with ", and" that belongs to the object is folded in ("his left hand
  resting on the hilt").
- American spelling, numbers under ten spelled out, ASCII punctuation.
  Diacritics are allowed in names (João), but Vietnamese tone marks are
  written plain ("Ba Trieu") because they break screen reader output.

Process:

- Write from `composites/<LEADERTYPE>.jpg` and `cutouts/<LEADERTYPE>.png`
  produced by `scripts/Extract-LeaderImages.py`, and check the wiki loading
  screen for props. Verify every side, hand, and prop claim against the
  cut-out; left and right are the leader's own.
- After every edit, reread the changed sentence with the one before and the
  one after it for grammar, repetition, and flow, then rebuild and lint.

## Entry format

```
## N. LEADER_TYPE
Display name, civilization

Description on one line.

Sources: where the location, titles, or model source came from, and what the
composite could not show.
```

---

## 1. LEADER_GANDHI
Gandhi, India

Mohandas 'Mahatma' Karamchand Gandhi stands on the grassy bank of the Ganges in the warm light of late afternoon. He is an old man, small and very lean, with dark brown skin and large ears. His bald head is fringed with a ring of close white hair, and a white mustache droops over his lip. Small round spectacles with thin gold rims sit low on his nose. He smiles gently with his head tilted a little to one side. He wears plain undyed cotton. A coarse white shawl is draped over his left shoulder and across his bare chest, and a dark gray dhoti, a long wrapped cloth worn as a lower garment, is knotted at his waist. His chest and arms are bare and thin, the ribs showing. In his right hand he holds a rough wooden walking stick with a knobbed top, and his left hand is raised loosely before his chest. Behind him a flight of worn stone steps climbs the bank to a small white shrine half hidden by grass and shrubs. The shrine is a squat whitewashed cell with an arched doorway and a rounded dome topped by a small finial. At the foot of the steps a stone landing juts into the still water, where pink lotus flowers and round green leaves float. Wide-spreading trees line the far bank while tall grass and drooping leaves frame the front of the scene, and an orange-brown haze softens all of it.

Sources: fandom trivia says the scene is a Hindu shrine on the banks of the Ganges and that he holds a walking stick; the stick shows in the loading-screen render and is kept because the wiki places it in the diplomacy screen, and the pose follows that render since the idle cut-out's pressed-together hands cannot hold it.

## 2. LEADER_BARBAROSSA
Frederick Barbarossa, Germany

Frederick I of the House of Hohenstaufen, Barbarossa, Holy Roman Emperor and King of Germany, Italy, and Burgundy, stands in a snowy forest. He is a heavy, broad-shouldered man with fair ruddy skin and pale blue eyes under level brows. His reddish brown hair falls to his jaw, and a full red beard and thick mustache cover the lower half of his face. On his head sits a crown of red velvet with a gold band, small gold ornaments rising from its rim. He wears full plate armor of polished steel. It has a rounded breastplate, large ridged shoulder guards with rows of rivets, jointed arm pieces, and a skirt of overlapping plates below the waist. Chain mail shows at the armpits and beneath the skirt. A red cloak hangs from his shoulders, its collar fastened at the throat with a square gold clasp. In his right hand he holds a scepter with a red shaft and a knob of gold, its head resting low against his chest. Behind him bare birches at the front left carry snow on their branches, and dark fir trees climb a slope on the right. In the far distance the square tower of a castle stands on a crag in gray mist, its walls half hidden by low cloud. The sky is a cold winter gray, and pale snow lies on the ground between the trees.

Sources: fandom trivia says the scene is a castle in a snowy forest, probably Kyffhausen or Trifels, and that he carries a scepter. The loading-screen render shows the scepter held upright. The gallery names an unspecified portrait as the model source.

## 3. LEADER_CATHERINE_DE_MEDICI
Catherine de Medici (Black Queen), France

Caterina Maria Romula di Lorenzo de' Medici, Queen consort, Queen Mother, and regent of France, stands on the bank of a river at dusk. She is a slender, pale woman with a narrow face, a long nose, and a small closed mouth. Her blue eyes are shadowed with dark makeup, and a small mole sits on her cheek. Her dark brown hair is parted in the center and drawn back under a French hood, a stiff crescent-shaped headdress set back on the crown so that the front hair shows. The hood is edged with a band of large gold beads and trails a black veil behind. A single pearl drop hangs from her ear. A high white ruff of starched pleated linen circles her neck. She wears a black gown with puffed shoulders and a sheer dark yoke sewn with small pearls. Her stiff bodice carries a gold brooch set with a jewel and three clusters of pearl petals. The tight sleeves end in white lace cuffs, and a gold chain girdle hangs at her waist. A lattice of ribbon studded with black beads crosses her full black skirt. She holds a tall thin glass of champagne in her right hand, low in front of her. Behind her a château shows a central domed pavilion and long wings with rows of lit windows, with a line of clipped trees along the water. Dark willow branches hang across the top of the scene, and reeds grow at the front. A black swan swims in the still water at the lower left as dusk dims everything to a red brown.

Sources: fandom trivia says the scene is a château beside a river with a black swan and that she holds a glass of champagne. The gallery names a painting by François Clouet as the model source. The champagne glass shows in the loading-screen render and is kept because the wiki places it in the diplomacy screen.

## 4. LEADER_CLEOPATRA
Cleopatra (Egyptian), Egypt

Cleopatra VII, Thea Philopator, Queen and Pharaoh of Ptolemaic Egypt, stands on a palace terrace above the Nile at sunset. She is a slim young woman with light brown skin, an oval face, and full lips. She looks straight ahead with her mouth closed. Her eyes are painted with purple shadow and heavy black liner drawn out to the temples, under thick lashes. Straight black bangs cut across her forehead, and black hair falls to her jaw. Over her hair sits a gold headdress shaped like a close-fitting cap, crowned with a wreath of gold leaves and hung at the sides with ribbed gold panels and red tassels. Small round gold studs set with teal show at her ears. Around her neck lie tiered strands of gold beads and a broad collar of blue and gold with a border of red and white triangles. A purple scarab set in gold sits at the center of the collar, with a teardrop-shaped teal stone hanging below it. Her white sheath dress has a bodice worked with a pair of dark red wings spreading from a teal stone set in gold, and a red sash is wrapped at her waist. Gold bands with red and white triangles circle her upper arms. A gold snake coils around her right wrist and a wide gold cuff covers her left, her hands folded together at her waist. Behind her heavy gold-fringed drapes hang from the top of the scene, and a round column stands to her right. A stone balustrade runs along the terrace, with potted palms and a low couch with gilded curved arms at the left. Past the railing the Nile flows beneath an orange evening sky with a pale sun low over the far bank, where a city lies in haze with a slender obelisk rising from it. The Pyramids of Giza stand faint on the horizon.

Sources: the fandom Ptolemaic subpage says the scene shows the Nile with the Pyramids on the horizon, and a CivFanatics thread describes an obelisk with the Pyramids of Giza behind it; both are named on that authority, since in the composite only the obelisk is clear and the distance is an orange haze. Titles from history. The loading-screen render adds the chin-on-hand pose.

## 5. LEADER_GILGAMESH
Gilgamesh, Sumeria

Gilgamesh, son of Lugalbanda, King of the Sumerian city of Uruk, stands at the entrance of his palace. He is a giant of a man, thick through the chest and arms, with tan skin and pale gray eyes under a heavy brow. A dense dark beard curls down to his chest, and a thick mustache hides his upper lip above a closed, level mouth. On his head sits a gold helmet-crown with a red band and a red and gold disc at the front. His right shoulder and most of his chest are bare. A teal tunic with fine vertical stripes covers his left shoulder and arm, its sleeve edged with a band of red and cream circles. A sash in the same pattern runs from his right hip up to his left shoulder. A chain of gold discs lies across his collarbones, with a large gold medallion worked with a rayed pattern hanging at the center. A red sash is knotted at his waist. Heavy gold bracers cover both forearms, and a gold ring circles his upper right arm. He stands square with his arms at his sides. Behind him the palace wall is tall mudbrick, and two lamassu, winged bulls with human heads, flank a doorway at the left. Beyond them lie sunken garden beds, palm trees, and a temple with a red and white striped face. Mountains rise in a golden haze under a burning orange sky.

Sources: fandom trivia says the scene is his palace entrance with two lamassu statues by the doorway. Titles from the epic. The loading-screen render shows a grin and a hand on the hip, which are left out.

## 6. LEADER_GORGO
Gorgo, Greece

Gorgo, Queen consort of Sparta, stands on a dry hillside. She is a tall, lean woman with lightly tanned skin and a long face. Her cheekbones are sharp and her eyes are dark. Her dark brown hair is combed back from her forehead and gathered behind her head. Large gold hoops hang from her ears. She wears a deep red peplos, a draped wool dress of Greek women, pinned at her right shoulder with a gold brooch and leaving her left shoulder bare. A gold band embroidered with a leaf pattern runs along the edge of the dress across her chest. A leather belt with a clasp of linked silver rings circles her waist, and two gold cords hang from it across her hip. A gold band circles her left upper arm, a wide gold cuff covers her left wrist, and a leather strap wraps her right wrist. In her right hand she holds a dory, a long Greek spear, upright beside her. Its red wooden shaft is topped with a leaf-shaped bronze head above a curled bronze collar. Behind her a temple stands on the hilltop, with a row of columns and a red tiled roof, half hidden by a tree. A second temple and a small house sit on the hillside to the left, above a road of flat stones. The dry brown land fades into a dusty orange haze.

Sources: fandom trivia does not name the scene, so it is described as a temple on a hillside. It confirms the spear as a dory. Titles from history. The loading-screen render shows the same dress and spear.

## 7. LEADER_HARDRADA
Harald Hardrada (Konge), Norway

Harald III 'Hardrada' Sigurdsson, King of Norway, stands at a lakeside camp at night under the northern lights. He is a big, broad man with fair weathered skin, blue eyes, and heavy brows. His long brown hair falls to his shoulders, and his full brown beard is bound into two thin braids tipped with metal beads. A red wool cloak lies over his shoulders, fastened at the chest with a gold ring brooch. Under it he wears a purple tunic and a vest of brown leather scales, each scale fixed with brass rivets. A leather baldric crosses his chest with a silver buckle stamped with a knot pattern. A wide leather belt with an iron buckle circles his waist, and a knife hangs at his side. His right forearm is wrapped in a leather bracer. Under his left arm he tucks a rounded iron helmet with a green crest and a gold-trimmed spectacle guard, the Viking eye guard. Behind him a longboat lies beached on the shore at the left beside a wooden shelter, lit by the orange glow of a campfire among pine trees. A dark mountain rises across the water. Green bands of aurora sweep across a starry sky and reflect in the lake, the only light beyond the campfire.

Sources: fandom trivia says the scene is a beached longboat and lakeside camp below a mountain with the aurora borealis. The gallery names a window in Lerwick Town Hall as the model source. The loading-screen render shows the helmet worn.

## 8. LEADER_HOJO
Hojo Tokimune, Japan

Hōjō Tokimune, eighth shikken or regent of the Kamakura shogunate, stands inside a dojo, its wooden beams and posts framing sliding paper screens. He is a slender young man with pale skin, a long narrow face, and dark eyes that look levelly out from under straight brows. His black hair is tucked under an eboshi, a tall black lacquered cap of a nobleman, tied under his chin with a red cord. He wears a blue sleeveless over-robe with wide flat shoulders. On each shoulder sits the mitsuuroko, the three-scales crest of the Hojo clan, drawn as three white stacked triangles. A gold cord is knotted on his chest in loops. Beneath the robe the sleeves of an olive green kimono show a faint leaf pattern. A pale gray sash is tied in a wide bow at his front. A katana is thrust through the sash at his left hip, its hilt wrapped in dark cord below a gold guard. A string of red beads hangs beside it. His hands hang at his sides, the right forearm covered by a black lacquered armored sleeve bound at the wrist with red cloth. Behind him the paper screens glow orange from light beyond them, with a large round window cut into their center. A lantern hangs from the ceiling, two torches burn beside a low table with a sword and jars, and large clay pots stand at the front. Warm orange light fills the room and leaves the corners in shadow.

Sources: fandom trivia says the scene is a traditional Japanese dojo and that he carries a katana. The gallery names a photograph of actor Motoya Izumi as the model source. The loading-screen render adds the folded-hands gesture.

## 9. LEADER_MONTEZUMA
Montezuma, Aztec

Moctezuma I Ilhuicamina, Tlatoani or speaker of Tenochtitlan and second emperor of the Aztecs, stands before a stepped pyramid. He is a lean, hard-muscled man with brown skin and a long sharp face. He wears a thin goatee, turquoise studs pierce his nose and lower lip, and gold spools set with turquoise hang from his ears. His brows are drawn down and together, and he glares out from narrowed eyes. A gold helmet shaped like the open jaws of a jaguar covers his head, its eyes inlaid with turquoise. Behind it spreads a huge fan of long green quetzal feathers that frames his whole upper body. A broad gold collar with a border of turquoise diamonds covers his shoulders, with a turquoise face plaque at its center and gold tassels hanging below. His chest is bare, crossed by leather straps and marked with dark painted patterns on his arms and ribs. A gold band circles his left upper arm, and gold and turquoise bracers cover both wrists. A brown cloth is wrapped around his hips. In his right hand he holds a tall gold staff topped with a bronze eagle inlaid with green, its wings spread wide and a crest of feathers fanned above its head. At the lower left of the scene the head of a stone statue, its face under a tall carved headdress of upright feathers, rises among palm fronds. Behind him the pyramid rises in the middle distance with a temple on its summit and smoke climbing from its top. A second pyramid stands to the left, and a city spreads in the haze beyond. The pyramids stand in smoky orange light under a dusty brown sky.

Sources: fandom trivia says the scene is a Mesoamerican pyramid overlooking an Aztec city. Titles from history. The loading-screen render shows the same staff and headdress.

## 10. LEADER_MVEMBA
Mvemba a Nzinga, Kongo

Mvemba a Nzinga of the Lukeni kanda dynasty, baptized Dom Afonso I, King of Kongo, stands on a riverbank in a jungle. He is a lean older man with dark brown skin, a short gray goatee, and a thin gray mustache. He smiles broadly with bright eyes. A gold hoop hangs from his ear. On his head sits a close-fitting red woven cap patterned with rows of white shells. From its top rises a crest of yellow, green, and red feathers. Around his neck hang stacked strands of beads in red, green, yellow, and white. His chest is bare. A red cloth sash runs from his left shoulder to his right hip, with a pale cord beside it. A mustard yellow wrap covers him from waist to knee. Strands of beads set with gold discs circle both upper arms, and a red band wraps his right wrist. In his right hand he holds a tall staff banded in red and black, topped with a carved head painted red and hung with a tuft of yellow and red feathers. Behind him the brown river flows past thatched huts raised on stilts on the far bank. A rope bridge of wooden planks crosses the water at the left. Long vines loop across the top of the scene, and palms and broad leaves rise through gray mist. Under a pale hazy sky the jungle is a muted green brown.

Sources: fandom trivia says the scene is a riverside village in a jungle, possibly the Congo River. The gallery names a painting of Mvemba a Nzinga as the model source. The loading-screen render shows the same staff.

## 11. LEADER_PEDRO
Pedro II, Brazil

Dom Pedro II de Alcântara of the House of Braganza, the Magnanimous, Emperor of Brazil, stands at the waterfront of Rio de Janeiro on a cool evening. He is a tall, straight-backed man with pale skin and blue eyes, his brows raised high so that the eyes look wide open. His brown hair is swept back from his forehead, and a full brown beard and long mustache cover his jaw. He wears a dark gray military coat with heavy gold fringed epaulettes on both shoulders and gold chevrons embroidered on the cuffs. A sash striped in red and blue crosses his chest from the right shoulder. On the right side of his chest hangs a gold star badge, the star of the Imperial Order of the Southern Cross, the Brazilian empire's order of merit. A silver rope cord loops at his shoulder, and a blue jeweled badge hangs on the sash. Above white trousers a gold belt with a square buckle circles his waist, where his hands are clasped low in front of him. Behind him a paved stone quay runs down to the dark water of a bay. A three-masted ship with lit lanterns lies at anchor on the bay, and palm trees stand at the water's edge. On the far left the tower of the palace on Ilha Fiscal rises against the sky. Purple clouds hang over the bay in the dim violet of dusk.

Sources: fandom trivia says the scene is the waters of Rio de Janeiro with the tower of the Ilha Fiscal palace and that he wears the Grand Cross of the Imperial Order of the Cross on the right of his chest. The gallery names an 1850 portrait by François-René Moreaux as the model source.

## 12. LEADER_PERICLES
Pericles, Greece

Pericles, son of Xanthippus, strategos of Athens, stands on the rocky slopes of the Acropolis under a hazy amber sky. He is an old man with pale skin, a long lined face and pale blue eyes under heavy brows. A thick beard of gray curls covers his jaw and chin, and a gray mustache hangs over his lip. On his head sits a bronze Corinthian helmet, a closed Greek war helmet with eye holes and a nose guard, pushed back so that it perches on top of his head with the face opening above his brow. The helmet is decorated with a gold palmette, a fan of leaves, on the crown and a small gold lion on each cheek piece. He wears a white chiton under a white wool himation. The cloak is draped over both shoulders and pinned at the right shoulder with a gold brooch. A band of gold Greek key pattern, the meander border, runs along the edge of the cloak. A gold sash is wrapped around his waist and hangs in a long tail down his right thigh. A brown leather strap crosses his chest from the left shoulder to a plain brown leather satchel at his right hip, and his right hand rests on the strap. In his left hand at his side he holds a rolled papyrus scroll. At the left of the scene the rock of the Acropolis rises in the distance, with a columned temple on its summit and smaller buildings on the crags below. Much closer, just behind his shoulder, stands a tholos, a small round temple with a conical tiled roof. Dark cypress trees rise between the tholos and the hill.

Sources: fandom trivia names the scene as a view of the Acropolis of Athens, notes that he always wears his Corinthian helmet and carries a satchel and a scroll, and says the model follows a marble bust of Pericles. The scroll is clearest in the loading-screen render, where it hangs at his side.

## 13. LEADER_PETER_GREAT
Peter, Russia

Pyotr I Alekseyevich Romanov, the Great, Tsar and first Emperor of All Russia, stands in a shipyard under a gray overcast sky. He is a tall man with a long pale face, a high forehead, a long straight nose and a pointed chin. Dark brown hair falls in loose waves to his shoulders. Thick dark eyebrows arch over dark eyes, and a dark mustache curls upward at both ends. His coat is dark green with wide turned-back lapels and deep cuffs of red cloth edged in gold embroidery and gold buttons. A white lace cravat spills from the open collar over a brown and gold brocade waistcoat, and white ruffles show at his wrists. A pale blue sash crosses his chest from the right shoulder, the sash of the Order of Saint Andrew, the highest Russian order of chivalry, which he founded himself. His right hand rests curled at his hip, and his left arm is drawn behind his back. Behind him the ribbed hull of a ship stands under construction, its curved ribs and keel open to the sky, with wooden ladders leaning against the scaffolding and a mast and yardarms beyond. Stacked planks and timbers lie on the ground, and wooden barrels stand at the front left. A cold haze dims everything to blue-gray.

Sources: fandom trivia describes the shipyard scene, the sash and star of the Order of Saint Andrew, and the Delaroche portrait as the model source. The star is hidden by the coat lapel in the idle cut-out and shows only in the loading-screen render.

## 14. LEADER_PHILIP_II
Philip II, Spain

Philip II 'the Prudent' of the House of Habsburg, King of Spain, Portugal, Naples, and Sicily, Lord of the Seventeen Provinces of the Netherlands, and so on, stands at dusk in the gardens of El Escorial, the royal palace and monastery. He is a heavyset man with pale skin and a broad face, grinning widely with his teeth showing. Dark brown hair is brushed up from his forehead, and he wears a full dark beard trimmed to a point with a thick mustache curled up at the ends. His eyes are blue under dark brows. He wears a blackened steel breastplate with gold edges and a gold band down the center. Below it hangs a skirt of dark steel plates with a gold panel of square patterns and a patch of mail at the front. Over the armor a short white ruff of pleated linen circles his neck. His sleeves are of dark purple cloth with a diamond pattern, puffed at the shoulder and tied with red ribbons at the elbow, and gray striped fabric covers his forearms above white cuffs. A red cord around his neck holds a small golden ram, the pendant of the Order of the Golden Fleece, at the center of his chest. A rapier with a swept steel hilt and a round pommel hangs at his left hip. His right hand rests on his hip while his left grips its hilt. Behind him two domed bell towers with slender spires rise over a long pale wall lined with rows of windows, and a golden-leaved tree spreads its branches over the scene. Smaller trees and lampposts line a path at the left. The sky is a hazy orange-brown.

Sources: fandom trivia names the gardens of El Escorial, the rapier and when he brandishes it, the Golden Fleece pendant, and the Sánchez Coello portrait. The idle cut-out and loading-screen render both show the rapier sheathed.

## 15. LEADER_QIN
Qin Shi Huang (Mandate of Heaven), China

Ying Zheng, Qin Shi Huang, King of Qin and First Emperor of a united China, stands at night in a hillside village of tiled roofs below the Great Wall of China. He is a heavyset man with a broad round face, light tan skin, full cheeks and narrow dark eyes under thick black eyebrows drawn together in a frown. A thin black mustache droops past the corners of his mouth, and a long black beard hangs from his chin to his chest. On his head sits a mian, the imperial crown of the Chinese court: a flat black board balanced on a gold band, with strings of dark beads hanging from its front and back edges. A gold pin is thrust sideways through the band with small gold creatures at each end. He wears a robe of dark red-brown cloth with wide black shoulders and sleeves, and the crossed lapels of the robe are embroidered with gold cloud scrolls. A wide red sash with a raised carved pattern is wrapped around his belly and fastened at the front by a large gold buckle shaped like a coiled scaly dragon. A pale cord hangs from the sash beside the buckle. His left hand grips the gold hilt of a sword at his hip, and his right hand is hidden in the hanging sleeve. Behind him curved eaves rise in the dark, with glowing orange paper lanterns hanging from their corners, and a gnarled pine tree twists at the left. Beyond the roofs the wall climbs a pale hill and disappears into a teal night mist. Only the lanterns give light, leaving the rest dim and blue-green.

Sources: fandom trivia describes houses beneath a hill overlooking part of the Great Wall of China and names a nineteenth-century portrait as the model source. The sword hilt under his left hand shows in the idle cut-out, while the loading-screen render has his hands folded at his chest.

## 16. LEADER_T_ROOSEVELT
Teddy Roosevelt (Bull Moose), America

Theodore Roosevelt Junior, twenty-sixth President of the United States of America, stands on a lawn before the north entrance of the White House in the amber light of evening. He is a stocky, barrel-chested man with a heavy jaw, ruddy pink skin and full cheeks. His dark brown hair is parted at the side and brushed flat, with gray at the temples. Round spectacles with thin gold rims sit on his nose, and a thick gray-brown walrus mustache spreads over his upper lip. He grins broadly with his teeth showing. He wears a dark brown tweed frock coat over a gray pinstriped waistcoat closed with a row of dark buttons, a white shirt with a turned-down collar and a black necktie. A gold watch chain hangs in a loop across the waistcoat, and a small pin sits on the left lapel of the coat. His left hand grips the watch chain at his waist while his right arm hangs at his side. Behind him the mansion stretches away to the left in pale stone, with a columned portico at its entrance, tall windows, and a flag flying from the roof. A large tree with red autumn leaves rises close behind him at the right and spreads its branches across the top of the scene. A pale drive curves from the front left toward the portico past a smaller tree and low shrubs, and tall grass fills the lower right corner in front of him. The sky is thick with orange-brown haze and dark clouds.

Sources: fandom trivia names the entrance and lawn of the White House and a photograph of Roosevelt as the model source. The fist on the hip shows in the loading-screen render, while the idle cut-out has the hand on the watch chain.

## 17. LEADER_SALADIN
Saladin (Vizier), Arabia

Al-Malik al-Nasir Salah al-Din Abu al-Muzaffar Yusuf ibn Ayyub, Sultan of Egypt and Syria, and Custodian of the Two Holy Mosques, stands on a moonlit shore at night. He is a lean man with light brown skin, a long narrow face, hollow cheeks and a long hooked nose. His gray-blue eyes look out from under heavy lids and thin dark brows, and a short black beard and mustache frame a closed mouth. On his head he wears a white turban striped with thin red-brown bands, pinned at the front with a brooch of dark green stones set in gold. A pointed dark brown cap with a small gold finial rises from the center of the turban. He wears a loose white robe with wide sleeves lined in gold satin, its edges and cuffs embroidered with gold scrollwork, over a plum-colored vest fastened at the chest with two gold clasps shaped like knotted cords. A cream undershirt shows at his throat, and a tan sash striped in brown is wound around his waist. His hands are folded together in front of his chest. Behind him a walled city rises on a headland across the water, packed with flat-roofed houses, domes and slender minarets, its windows glowing and reflected in the still water below. Palm fronds are silhouetted against the sky, and a rocky cliff looms at the right. A full moon hangs at the upper left in a reddish-brown haze over a warm dark night.

Sources: the fandom page does not name the city in the scene, so it is described generically. The gallery names a 1961 sketch as the model source. The loading-screen render shows the same folded hands as the idle cut-out.

## 18. LEADER_TOMYRIS
Tomyris, Scythia

Tomyris, Queen of the Massagetae, a Saka people of the Scythian steppe, stands at a nomad tent's open doorway with green hills and grazing flocks in the sunlight beyond. She is a tall, strong-shouldered woman with tan skin and a square jaw. Her dark brows are drawn together over gray-green eyes, and her mouth is set. Her dark brown hair hangs in two long thick braids down the front of her chest. She wears a gold helmet with cheek guards and a curled ornament at each side, topped by a small gold ram's head. A short mantle of red leather covers her shoulders, held at the throat by a gold clasp, over a tunic of dark blue velvet with long sleeves. Over the tunic she wears a cuirass of gold scale armor, overlapping plates in a honeycomb pattern that reach from her chest to her hips. Bands of gold plates on red leather circle her upper arms, and her cuffs are trimmed with white cloth patterned with red triangles. A white belt with the same red triangle pattern and blue edges is tied at her waist with a red cord whose long tassels hang down the front. A sword in a red scabbard decorated with gold hangs at her left hip, its grip wrapped in leather under a gold pommel. Her arms hang at her sides. The tent around her is of tawny felt and woven cloth, with gold rings hanging from its roof and a large round golden shield covered with embossed figures leaning at the right. Outside, spears stand upright at the left of the doorway, a wooden rack stands on the grass, and a white yurt and a flock of sheep dot a green valley under rolling hills. Bright daylight fills the doorway, and the tent behind her is warm and shadowed.

Sources: the fandom page has no trivia or gallery notes, so the tent and steppe are described generically and the titles come from Herodotus. The raised fist shows in the loading-screen render; the idle cut-out has her arms at her sides.

## 19. LEADER_TRAJAN
Trajan, Rome

Marcus Ulpius Traianus, Imperator Caesar Nerva Traianus Augustus, stands at night before a Roman temple. He is a tall, lean man with pale skin, a long face, a long straight nose and sunken cheeks. His short gray hair is combed forward over his brow in the Roman fashion. A wreath of gold laurel leaves circles his head. His pale blue eyes look out from under gray brows, and his mouth is set in a thin line. He wears a polished steel muscle cuirass with a gold winged Gorgon's head at its center and gold scrollwork along the lower edge. The cuirass's shoulder guards are dark leather edged in gold, each stamped with a gold griffin above a gold rosette, and a red tunic shows at his neck and arms. Pteruges, rows of white leather strips with gold trim, hang from the shoulders over the tunic's red sleeves. A leather baldric crosses his chest from the right shoulder to the left hip. Below the cuirass hangs a skirt of leather strips studded with gold rosettes. A sword is sheathed at his left hip, its scabbard dark blue and its grip wrapped in red, his left hand resting on the hilt. His right arm hangs at his side. Behind him the temple stands on a stone platform with a row of tall columns and a red tiled roof. A statue on a pedestal stands at the far left beside a stair. Two bronze braziers stand on the edge of a still pool in front of the temple, and reeds and grasses grow at the front. Under a sky of dark blue haze the temple glows with warm light.

Sources: the fandom page gives no scene location, so the temple is described generically; its gallery names a statue of Trajan as the model source. The loading-screen render shows both arms at his sides, while the idle cut-out has his left hand on the sword hilt.

## 20. LEADER_VICTORIA
Victoria (Age of Empire), England

Alexandrina Victoria of the House of Hanover, Queen of the United Kingdom of Great Britain and Ireland, and Empress of India, stands at noon on a lawn below Windsor Castle. She is a short, plump young woman with pale skin, round cheeks and a small mouth curved in a faint smile. Her dark brown hair is parted in the middle and drawn back smoothly over her ears into a knot. Her eyes are blue, and she wears small drop earrings. On her head sits a small silver crown mirroring the small diamond crown of her widowhood, its band set with dark red stones and a jeweled cross rising from the front. She wears a formal ball gown of pale silver-white satin and lace. Its wide neckline bares her shoulders, its short puffed sleeves are edged in gold, and a full skirt spreads from the fitted waist. A pale blue riband, the broad sash of the Order of the Garter, runs from her left shoulder to her right hip. The Garter is the oldest English order of chivalry, and a jeweled badge is pinned where the riband ends at her hip. A brooch with a large rectangular red jewel in a scalloped silver mount is pinned at the center of her bodice with a smaller square jewel hanging from it on a short chain. A single row of square-cut dark stones in silver settings circles her throat with a shield-shaped drop at its center, and a matching bracelet circles her left wrist. Her hands are folded in front of her skirt around a closed fan of pink and gold silk. Behind her the castle's Round Tower rises on its mound, a broad gray stone keep with narrow windows, with a lower curtain wall and gatehouse beside it. A garden bench stands at the far left, trees and shrubs cover the slope of the mound, and low hills fade into the distance. The sky is dull orange-brown with dark clouds.

Sources: fandom trivia names Windsor Castle, the riband of the Order of the Garter, and a painting of Victoria as the model source. The trivia says the scene is at noon, but the painted sky reads as hazy orange, so no time of day is named. The open fan shows only in the loading-screen render.

## 21. LEADER_CHANDRAGUPTA
Chandragupta, India

Chandragupta Maurya, first Emperor of India, stands at night in a garden of palm trees before the domed temple of Swaminarayan Akshardham in Delhi. He is a young, muscular man with dark brown skin and a broad bare chest, smiling widely with his teeth showing. His eyes are large and bright, and a thin black mustache sits above his lip. Long black hair falls behind his shoulders. Gold hoop earrings hang from his ears. On his head he wears a turban of blue silk wound in folds and edged with gold beading, pinned at the front with a red teardrop jewel in a gold setting. A broad collar necklace of gold, worked in several tiers and set with red stones, covers his upper chest. An orange silk shawl patterned with small gold leaves is draped over his left shoulder and hangs down his left side to the belt. Gold armbands with hanging discs circle his upper arms, and gold bracelets set with red stones circle both wrists. A wide sash of blue cloth printed with small gold shapes is wound around his waist and fastened with a gold belt of square panels, the central panel set with a large round blue stone. Below the sash he wears a dark blue wrapped garment. His arms hang at his sides. Behind him the temple rises in the dark: a pale stone building of tiers and domes, its many small spires lit from within, with smaller domed pavilions to either side. Tall palm trees lean across the scene, one trunk cutting diagonally behind his head, and a row of small domed shrines stands on a path at the lower left. Dark blue moonlight lies over the garden.

Sources: fandom trivia names the temple as Swaminarayan Akshardham in Delhi and the gallery names a portrait of Chandragupta as the model source. The loading-screen render shows the same pose and dress as the idle cut-out.

## 22. LEADER_DIDO
Dido, Phoenicia

Dido, also called Elissa, princess of Tyre and legendary first Queen of Carthage, stands on a wooden quay at dusk beside a ship with a tall square sail. She is a slim woman in her prime with olive brown skin, a long straight nose, and a pointed chin. Her closed lips curve in a small smile. Her dark brown hair is pinned up in tight curls at the crown and bound with a thin gold fillet, a narrow headband, with a few curls escaping at her temples. Heavy dark eyebrows sit over her brown eyes, and gold earrings with blue stone drops hang from her ears. She wears a sleeveless magenta chiton with a loose cowl of cloth draped at the neckline. Gold brooches set with blue stones fasten it at each shoulder, and a flat gold collar worked with a zigzag pattern rests on her chest below a fine gold chain. A pale blue-gray sash wraps twice around her, once under the bust and once at the hips, and is knotted at the front with its ends hanging down. A gold bracelet with a blue stone circles her right wrist and a wide gold cuff her left. Her right hand rests on her hip with the elbow out while her left arm hangs at her side. Behind her the quay is lined with mooring posts and a barrel, and the dark hull and rigging of the ship fill the left edge of the scene. Across the water two red-orange sea stacks rise from the sea, the Rock of Raouché off Beirut. The sea has worn a tall opening through the base of the larger one, leaving a bridge of rock across its top, and a small ship with orange sails passes through the opening. To the right the open sea stretches to a low dark headland on the horizon, and pale green streaks of light play over the dark blue water. Banks of pink cloud spread across the whole sky, glowing against the deep blue of evening.

Sources: fandom trivia names the Rock of Raouché off Beirut as the scene. The idle cut-out and the loading-screen render show the same pose with the left hand on the hip, and no prop appears in either.

## 23. LEADER_ELEANOR_ENGLAND
Eleanor of Aquitaine, England

Eleanor of the House of Poitiers, Duchess of Aquitaine, Queen consort first of France and then of England, stands on a riverbank at dusk opposite the abbey of Fontevraud. She is a slender woman with pale skin, a long neck, and high cheekbones. She smiles gently with her lips closed. Her blue eyes look out from under fair brows, and her golden hair is plaited into two thick braids that are coiled over each ear. A wreath of pink roses circles her head. She wears a long gown of pale blue-gray silk with fitted sleeves. The sleeves open into wide trailing cuffs edged with gold embroidery that hang down toward her knees. A band of gold embroidery rings each upper arm. Over the gown is a sleeveless surcoat of deep red, and its round neckline carries a gold collar set with a ring of blue and green stones. A belt of linked gold disks circles her hips and hangs in a long chain of medallions down the front of her skirt. In both hands she holds a gold chalice at the level of her waist, a footed cup whose bowl is studded with small blue stones. Behind her a large dark tree fills the left of the scene, its trunk and branches black against the sky. A second tree with red autumn leaves spreads its crown directly behind her head. Beyond them a wide river reflects the last light, and two small boats float on it, one with a pale sail. On the far bank the long walls and twin towers of the abbey glow orange and gold, with the roofs of the town clustered below. To the right the far bank fades into a gray-blue haze, and dark foliage closes the right edge of the scene. Purple and pink clouds streak a blue sky that darkens toward the top.

Sources: fandom trivia says the English scene shows the land around Fontevraud Abbey, that the England outfit has the floral crown, braids, and longer sleeves, and that a painting of Eleanor knighting a follower inspired the model. The chalice shows in both the cut-out and the loading-screen render.

## 24. LEADER_ELEANOR_FRANCE
Eleanor of Aquitaine, France

Eleanor of the House of Poitiers, Duchess of Aquitaine, Queen consort first of France and then of England, stands on a garden path before the Palace of Poitiers in the evening. She is a slender woman with pale skin and high cheekbones. She smiles broadly with her teeth showing and her head tipped to one side. Her blue eyes look out from under fair brows, and her golden hair falls loose and wavy past her shoulders. On her head sits a gold crown with a large blue stone at the front, a ring of smaller blue and green stones around its band, and small fleur-de-lis points along the top. She wears a long gown of pale blue-gray silk whose fitted sleeves end at the wrist in gold embroidered cuffs. A band of gold embroidery rings each upper arm. Over the gown is a sleeveless surcoat of deep red, and its round neckline carries a gold collar set with a ring of blue and green stones. A belt of linked gold disks circles her hips and hangs in a long chain of medallions down the front of her skirt. Her right arm reaches out to the side with the palm open and turned up in welcome. Her left hand carries a gold chalice low at her side, a footed cup whose bowl is studded with small blue stones. Behind her a pale gravel path curves through a lawn with flowering shrubs in red and orange and a tall tree at the left. Beyond the garden rise the pale stone walls of the palace, with a round tower under a conical roof, a row of tall windows, and steep gabled roofs. A long wing of the palace runs off to the right behind her. A tree spreads its black silhouette above her head. The walls glow faintly pink in the last light, and the sky shades from violet at the top to a dusky purple haze on the right.

Sources: fandom trivia says the French scene shows the land around the Palace of Poitiers, that the France outfit has the gold crown, loose hair, and shorter sleeves, and that a painting of Eleanor knighting a follower inspired the model. The open right hand and the chalice in the left hand appear in both the cut-out and the loading-screen render.

## 25. LEADER_GENGHIS_KHAN
Genghis Khan, Mongolia

Temüjin of the Borjigin clan, first Great Khan of the Mongol Empire, stands on a dark hillside above a river valley on the Mongolian steppe. He is a stocky broad-shouldered man with a round face, tan skin, and narrow eyes that crinkle above a wide closed-mouth grin. A thin black mustache curves down past the corners of his mouth, and a short pointed beard sits on his chin. His hat has a wide brim of shaggy brown fur and a leather crown studded with metal, with a small metal spike at the top. Leather flaps hang down from the hat over his ears. He wears a long-sleeved tunic of dark green cloth with fur showing at the cuffs. Over it is a sleeveless brown leather cuirass with rows of dark iron plates laced onto the chest. A wide leather collar piece studded with pyramid-shaped metal points rings his shoulders, and a round iron boss sits at the center of his chest. Leather bracers with metal edges cover his forearms. A broad belt with a round iron buckle circles his waist above dark trousers. Both fists rest on his hips with the elbows thrust out. Behind him a steep slope of brown grass and rock drops away at the front left. Beyond it the river, pale in the haze, winds in wide loops across the flat valley floor, with low bare hills on the far side and a line of red-brown ridges on the horizon. A cluster of gers, round felt tents of the steppe, sits on the bank at the far bend. The haze dims the valley to a warm brown.

Sources: fandom trivia says the scene shows gers on a Mongolian steppe, and a cluster of pale dots at the far bend of the river is taken as those gers. The cut-out and the loading-screen render show the same fists-on-hips pose with no prop.

## 26. LEADER_JADWIGA
Jadwiga, Poland

Saint Jadwiga of the Capetian House of Anjou, Grand Duchess consort of Lithuania and crowned King of Poland, stands in a hazy meadow. She is a young woman with pale skin and a round soft face. She smiles slightly and tilts her head to one side. Her wavy brown hair falls to her shoulders, and her eyes are gray-blue under dark brows. On her head sits a tall gold crown set with purple stones, with pointed spikes rising around its band. A string of large pearls circles her neck. Her gown is divided down the middle in two colors. The right half is red silk with a damask pattern, and a crowned eagle worked in gold thread, the emblem of Poland, spreads its wings across the red silk. The long red sleeve flares into a wide hanging cuff. The gown's left half is purple silk covered in a repeating pattern of pale fleur-de-lis, its sleeve fitted to the wrist. A gold collar set with turquoise stones binds the neckline across both halves, and a gold belt with a large round buckle of turquoise stones sits low on her hips. A red mantle hangs behind her from her shoulders. In her right hand she holds a long gold scepter that reaches to her cheek, topped with a lotus bud, and her left hand is extended to the side with the palm turned up. Behind her the green meadow spreads under a pale overcast sky, with shrubs of red flowers in the grass, trees with orange autumn leaves, and a low white wall along its edge. In the distance the steep roofs of a manor rise beside slender towers capped with conical spires. Dark trees with red leaves crowd the right side of the scene.

Sources: fandom gallery notes name portraits by Antoni Piotrowski and Jan Matejko as the inspiration for the model. The wiki does not name the manor or meadow, so the setting is described generically. The scepter and open left hand appear in both the cut-out and the loading-screen render.

## 27. LEADER_KRISTINA
Kristina, Sweden

Kristina of the House of Vasa, Queen of Sweden, Grand Princess of Finland, Duchess of Estonia, Livonia and Karelia, and so on, stands in a firelit library with a large book in her hand. She is a pale slender woman with a long face and a long straight nose. She smiles slightly, with a knowing look. Her brown hair is parted in the middle and falls in thick ringlets past her shoulders, and her eyes are pale green under thick brows. She wears a dark gray doublet, cut in a man's style. A row of small gold buttons runs down the front. Padded rolls stand out at the shoulders. Her right sleeve ends in a deep cuff of white lace, and a small white collar shows at her throat. A dark brown skirt with a row of gold buttons down its side hangs below the doublet. Her left hand holds a large book bound in brown leather with gold corner mounts and a gold emblem on its cover, held flat against her hip. Her right hand is raised in front of her chest with the fingers loosely curled. Behind her, tall wooden bookshelves packed with books line the walls on every side and rise to a ceiling of dark beams. A stone fireplace with a pointed arch stands in the middle of the far wall, and a fire burns inside it. In front of the fireplace a desk holds a stack of books, a candlestick, an inkwell, and a quill pen. At her back a globe stands on a wooden stand, and more books lie piled on a table at the right. The room is lit only by the fire, so that everything glows orange and brown and the corners fall into shadow.

Sources: fandom gallery notes name a portrait by Sébastien Bourdon as the inspiration for the model. The wiki does not name the library, so the room is described generically. The book appears in both the cut-out and the loading-screen render.

## 28. LEADER_KUPE
Kupe, Maori

Kupe the Navigator, legendary discoverer of Aotearoa, the land of the long white cloud, stands on a green headland above a turquoise sea. He is a broad and heavily muscled man with warm brown skin and a wide face. He smiles slightly with his mouth closed. His black hair is short and swept back, standing up in tufts. His whole face is covered in moko, the Maori facial tattoo. Dark spiral and curling lines run across his forehead, around his eyes, over his nose, and down both cheeks to his chin. His eyes are light hazel. Over his shoulders he wears a shaggy cloak of brown fibers, worn open like a shawl so that his chest is bare. On a cord around his neck hangs a pendant of pale bone carved into curling shapes. Around his waist is a red cloth wrap with a black zigzag band at the top, tied with a thick rope of twisted cream cord, and rows of small cream tassels hang from the red cloth below. His right fist is pressed to the left side of his chest, and his left arm hangs at his side. Dark spiky leaves push up from both sides of the front edge, where a grassy slope falls away at the left toward the water. Across the bay rises the headland called Kupe's Sail, a pale gray cliff with a green top ending in a tall peak. Below it a pale beach curves along a bay of turquoise water, and the sea stretches away to the right until it fades into a hazy teal sky. Blue-green light lies over the water, with a pale glow on the horizon above the headland.

Sources: fandom trivia names Kupe's Sail on the North Island of New Zealand as the scene and a portrait in the Auckland Art Gallery as the model source. The cut-out and the loading-screen render show the same fist-on-chest pose with no prop.

## 29. LEADER_LAURIER
Wilfrid Laurier, Canada

Sir Henri Charles Wilfrid Laurier, seventh Prime Minister of Canada and Knight Grand Cross of the Order of Saint Michael and Saint George, stands on a winter night beside the frozen Rideau Canal below Parliament Hill. He is a tall lean elderly man with pale lined skin, a high domed forehead, and deep-set blue eyes under pale brows. His white hair is swept back from the forehead and puffs out at the sides over his ears, and his thin mouth is closed with the corners lifted a little. He wears a royal blue frock coat with long tails, satin lapels of the same blue, and gold buttons down the front. Under it is a waistcoat of tan plaid buttoned to the chest, a high white collar, and a blue silk cravat pinned with a small gold pin. A gold maple leaf is pinned to the left lapel of his coat. His trousers are gray. Raised beside his chest, his right hand holds a pair of small gold-rimmed pince-nez between thumb and fingers, spectacles that clip onto the nose. His left hand rests on his hip with the elbow out. Behind him the Gothic buildings of the hill rise against a dark blue sky, their steep roofs and turrets covered in snow and their windows lit orange. A clock tower stands tallest among them, its clock face glowing. Below the hill a stone bridge with two arches crosses the canal. In front of the bridge a path lit by glowing lamp posts runs along the snowy near bank behind an iron railing, with a flight of steps climbing the bank at the far left. Snow-covered ground with bare shrubs stretches away to the right. The sky is a pale gray-blue haze with a faint green glow above the clock tower.

Sources: fandom trivia names the frozen Rideau Canal under a bridge in front of Parliament Hill as the scene, notes the pince-nez, and names a 1906 photograph as the model source. The pince-nez appear in the hand in both the cut-out and the loading-screen render.

## 30. LEADER_LAUTARO
Lautaro, Mapuche

Lautaro, born Leftraru, toqui or war leader of the Mapuche, stands before the falls of Salto del Laja in Chile at sunset with his arms folded across his chest. He is a lean and muscular young man with warm brown skin and a broad nose. The corners of his closed mouth lift in a slight smile. His black hair falls in a straight fringe over his forehead and hangs loose to his shoulders. A trarilonko, a woven cream headband patterned with tan geometric squares, is tied around his forehead. His eyes are gray-blue. His chest is bare, and a small pendant of gray stone hangs from two loops of brown leather cord at his neck. Bands of dark leather cord are wound about his left wrist. A wrap of dark green woven cloth covers his hips, held by a narrow woven belt in cream and brown. A broad red panel runs down the front of the wrap, patterned with cream stepped crosses and diamond shapes. A toki, a stone axe with a gray stone head bound to a short wooden haft, is tucked into the belt at his right hip. Behind him the falls pour in white sheets over a curved wall of dark rock into a pool that drains toward the front of the scene as a river, catching the pink of the sky. Wooded green hills rise behind the falls, with scattered trees on a ridge. Pink and orange clouds tower over the hills against a deep blue evening sky.

Sources: fandom trivia names the Salto del Laja in Chile as the scene and a bust and a statue of Lautaro as the model sources. The trivia also says he sometimes carries a rapier and, when denouncing, a stone tomahawk, but neither the cut-out nor the loading-screen render shows the rapier, so only the axe at his belt is described.

## 31. LEADER_MANSA_MUSA
Mansa Musa, Mali

Musa I of the Keita dynasty, ninth Mansa or emperor of Mali, stands before the earthen wall of the Great Mosque of Djenné. He is a large heavy man with dark brown skin and a round face. He smiles broadly and warmly. A full curly black beard covers his chin and cheeks, and his eyes are brown. On his head sits a taqiyah, a rounded skullcap, in blue and gold with an embroidered pattern. He wears a robe of deep blue cloth with short sleeves, patterned all over with small pale circles and squares. Over it is a sleeveless tunic of lighter blue with gold embroidery at the neckline and shoulders and three large gold buttons down the chest. Two long panels of cream cloth edged in gold hang from the waist down the front of the robe. His hands are clasped together at his belly with the fingers interlaced. Gold rings sit on the fingers of both hands, one set with a red stone, and a gold bangle circles each wrist, with a broad gold cuff on the left. Behind him the mosque wall rises in orange-brown mud brick, with tall pointed towers along its top and rows of wooden beams jutting from its surface. A sandy slope and a dirt track run in front of the wall. A rocky outcrop stands at the front left. To the right the sand stretches away into a dusky haze, and a low mud wall stands at the right edge behind him. The sky shades from purple at the top to pink and orange above the wall, its warm light fading to violet on the right.

Sources: fandom trivia names the outer wall of the Great Mosque of Djenné as the scene, notes the taqiyah and the gold rings on both hands, and names an artist's depiction of a young Mansa Musa as the model source. The cut-out and the loading-screen render show the same clasped-hands pose with no prop.

## 32. LEADER_MATTHIAS_CORVINUS
Matthias Corvinus, Hungary

Matthias I 'Corvinus' Hunyadi, the Just, Duke of Austria and King of Hungary, Croatia, and Bohemia, stands at dusk on a rampart above the Danube below Visegrád Castle in Hungary. He is a man in his prime with a broad face and fair skin. He frowns faintly. Wavy light brown hair falls to his shoulders, and a wreath of gold laurel leaves rests in it above his brow. His heavy brows sit low over dark eyes that look straight ahead. He wears a blue tunic of patterned brocade, its woven floral figures showing in a slightly lighter blue. A dark cloak hangs from his shoulders and is fastened at his right shoulder with a plain gold ring clasp. His left shoulder and arm are cased in steel plate: a pauldron edged with twisted gold cord, a rounded elbow guard and a plate gauntlet. A gold bird, the raven of his house, is set into the pauldron. The gauntleted left hand rests on the round pommel of a sword that hangs at his left hip in a brown leather scabbard with gold fittings. A leather belt with pouches circles his waist. His right arm stays hidden beneath the cloak. Behind him the castle, gray stone with square towers and pointed roofs, crowns a steep green crag, and a long stone wall runs down from it to a lower fortification. The Danube fills the middle of the scene and stretches away to the right, where low blue hills line the far shore. A row of arched openings runs through the rampart at the front, and a dark clump of trees closes the right edge. An orange cloud catches the last light above the castle, while blue-gray clouds cover the rest of the sky. The light is dim and cool except on the towers and the cloud above them.

Sources: fandom trivia gives Visegrád Castle as the scene, the laurel wreath, and an equestrian statue as the model source. The river is described as the Danube because the wiki names Visegrád, which stands on that river.

## 33. LEADER_PACHACUTI
Pachacuti, Inca

Cusi Inca Yupanqui, styled Pachacuti, ninth Sapa Inca or emperor at Cusco, stands before a terraced village high in the Andes Mountains. He is a big broad-shouldered man with medium brown skin and thick arms. He grins widely, showing his teeth. Long straight black hair falls loose past his shoulders. Large flat gold disks hang from his stretched earlobes. On his head sits a gold headdress mirroring the llautu, the braided royal headband of the Inca. Its band is worked in a woven pattern, a square gold face ringed with rays stares from above the brow as Inti, the Inca sun god, and a tall fan of iridescent blue-green feathers rises from the top. Strands of green stone beads circle his neck and hold a large gold sun disk on his chest bearing the same rayed face of Inti. He wears a sleeveless tan tunic with a dark red yoke edged in gold cord and set with a turquoise stone at each shoulder. A red cloak hangs down his back, and a wide red sash is wrapped and knotted around his waist. A hinged gold band clasps his right upper arm. In his right hand he holds a halberd upright, a long wooden shaft topped with a ribbed gold head and a curved gold axe blade. His left arm hangs at his side. At the lower left a few larger houses with stone walls and peaked red-brown roofs stand beside a strip of dark water. Beyond them the village climbs a green hillside on stepped stone terraces, its small thatched houses clustered below a steep green peak wrapped in white cloud. A dark cliff face crowds in close behind his right shoulder, with pale gray mountain slopes above it and a blue summit far off at the edge of the scene. Shafts of daylight slant across the mountains from a pale blue sky of drifting white clouds.

Sources: fandom trivia gives the terrace farm village before the Andes, the gold-headed halberd, and a statue as the model source. The cliff at the right is unnamed in the trivia and is described from the composite.

## 34. LEADER_POUNDMAKER
Poundmaker, Cree

Pîhtokahânapiwiyin, chief of the Plains Cree, stands on a frozen lakeshore in the blue light after sunset. He is a slender man with light brown skin, a long narrow face and pale gray-green eyes. He smiles faintly with closed lips. Long dark hair hangs loose past his chest in thin strands and braids, and a blue-beaded ornament is tied into it beside his right temple. A stroke of white paint marks his left cheek. He wears a white shirt with a soft collar under a dark blue vest with brass buttons. Over these hangs a long coat of tan hide with a brown edge along its lapels and cuffs. Bands of red and white paint cross the shoulders and cuffs of the coat, and rows of red and blue quillwork fringe the upper sleeves. Red and blue painted motifs run along the lower edge of the coat, which closes with bone buttons. Brown trousers show below. In his left hand he holds a pipe with a long thin pale stem and a small dark bowl, raised to chest height. His right arm hangs at his side. Behind him a snow-covered lake stretches back with broken slabs of ice on it, and a single snow-laden spruce stands at his shoulder. A herd of dark buffalo grazes in a line on the white shore, with a wall of evergreens and rocky snowy hills beyond. Gray clouds hang in a deep blue sky, and the whole scene is washed in cold blue light.

Sources: fandom trivia gives the frozen tundra, lake, trees and buffalo, and the 1885 photograph as the model source. The composite and cut-out both show the pipe, so nothing hidden by the idle pose was added.

## 35. LEADER_ROBERT_THE_BRUCE
Robert the Bruce, Scotland

Robert I de Brus of the House of Bruce, King of Scots, Earl of Carrick and Lord of Annandale, stands on a green hillside in the Scottish Highlands. He is a stocky broad-chested man with fair ruddy skin and a heavy brow. A thick auburn beard covers his jaw, a wide mustache curls over his lip, and his hair of the same color falls to his shoulders. His green eyes are wide open under raised brows, and his mouth is set in a hard line. A gold crown with pointed cross-shaped finials and a red stone at the front sits on his head. He wears a yellow surcoat with a red rampant lion across the chest, the royal arms of Scotland, over a brown quilted tunic with long sleeves. A red border edges the surcoat, and a chain of silver links lies across his collar. A dark red cloak hangs from his shoulders, fastened at each side with a wide metal brooch. A brown leather belt circles his waist. A sword in a scabbard hangs at his left hip with its cross guard showing. His left hand rests on the pommel of the sword, and his right arm hangs at his side. Behind him a pale road winds up rolling green hills to a castle on a distant hill, a square keep inside a curtain wall. Dark mountains rise beyond it. Gray-teal clouds cover the sky. The near hills lie in cool shadow.

Sources: fandom trivia gives the Highlands with a castle, the hidden stool, and the Stirling Castle statue as the model source. The stool is not visible in the composite, cut-out or loading-screen render.

## 36. LEADER_SEONDEOK
Seondeok, Korea

Deokman, styled Seondeok, Queen regnant of Silla in Korea, stands at night beside a palace pond, a full moon showing through thin cloud behind tiled roofs. She is a young woman with a round face, light skin and dark eyes. She smiles brightly with her mouth open. Her dark hair is drawn back under a gold crown. The crown mirrors the Silla gold crowns from the royal tombs at Gyeongju, a band of gold set with round bosses and green jade, with tall gold uprights shaped like branching trees rising from it. Gold chains hang from each side of the crown past her cheeks, each ending in a gogok, the comma-shaped jade jewel of Silla. She wears a purple silk robe that crosses over the chest and falls to the ground. Its wide collar is deep violet worked with gold scrolling embroidery, and its long sleeves hang loose. A violet sash edged in gold wraps her waist and carries a row of square gold plaques. Her right hand is raised in a loose fist at chest height. Her left hand is closed at her side. Behind her a tall wooden gate frame stands in silhouette, and a dark pavilion with sweeping curved eaves rises at the left. A smaller pavilion with a red railing sits across the pond at the right. Lily pads float on the black water, reeds grow at the bank, and a red-railed bridge crosses at the front of the scene. Everything is in deep blue moonlight.

Sources: fandom gives the 1990 portrait as the model source and notes the final model differs from early builds. The scene location is not named, so it is described as a palace pond.

## 37. LEADER_SHAKA
Shaka, Zulu

Shaka kaSenzangakhona, King of the Zulu Kingdom, stands bare-chested on a grassy plain. He is tall and heavily muscled, with dark brown skin. He looks straight out with a faint smile. His face is clean-shaven with a strong jaw. He wears a headdress of stiff tan bristles fanning up from a band of red beads, with a dark oval plaque bearing crossed lines at the front and a single red feather rising from the top. Fringes of red beads hang over his ears. A necklace of white and red beads carries curved lion's teeth at his throat. A leopard-skin sash runs from his right shoulder across his chest to his left hip. Red cord bands circle his right upper arm, and a beaded band of red and orange chevrons circles his left. Three gold bangles ring his right wrist. A belt of red and white beads holds a leopard-skin kilt, and a beaded pouch with a red and black triangle pattern hangs at the front. In his right hand he holds an iklwa, a short stabbing spear, pointed down along his leg. In his left he holds a tall oval Nguni shield of brown hide, with a wooden stick bound up its center and topped with a tuft of fur. Behind him three domed huts of woven grass sit among flat-topped acacia trees. Red-orange grass and green scrub fill the middle ground in warm low light, and a mountain rises into white cloud under a deep blue sky.

Sources: fandom trivia gives the assegai and Nguni shield and a statue as the model source. The scene location is not named, so it is described generically.

## 38. LEADER_SULEIMAN
Suleiman (Kanuni), Ottoman

Suleiman I 'the Magnificent', called Kanuni by his subjects, Sultan of the Ottoman Empire, Custodian of the Two Holy Mosques, Caesar of Rome, and so on, stands in a garden overlooking the Hagia Sophia at sunset. He is a middle-aged man of medium build with light olive skin and heavy-lidded eyes. A trimmed dark beard and mustache frame a small satisfied smile, and his head tilts slightly to one side. He wears a tall white turban that rises straight up from his brow. A jeweled brooch with a red stone at its center is pinned to its front, chains of small gems loop across it, and a black feather plume stands up from its top. His long kaftan is of green silk damask with full sleeves gathered at gold cuffs. A collar of dark fur lies around his shoulders, and three gold frog fastenings close the chest. A dark sash with gold-striped edges wraps his waist. Below it the green robe parts over panels of gold brocade. Dark fur trims the parted edges. His right hand rests tucked against the sash, and his left arm hangs at his side. Behind him the great dome of the Hagia Sophia rises over half domes and buttressed walls, with two slender minarets beside it. Orange evening light strikes the walls, and pink and orange clouds fill a hazy sky. A row of clipped round trees and low hedges lines the garden in front of the building. At the right a dark rounded tree stands close behind him, and the brown wall of a building closes the edge of the scene.

Sources: fandom trivia gives the garden overlooking the Hagia Sophia and the 2013 television portrait as the model source. The wall at the right edge is described from the composite and is not named in the trivia.

## 39. LEADER_TAMAR
Tamar, Georgia

Tamar 'the Great' of the Bagrationi dynasty, Queen regnant of Georgia, styled King of Kings and Queen of Queens, stands at dusk on a wooded slope above a mountain lake. She is a young woman with light olive skin, a straight nose and full pink cheeks. Her dark brows arch over gray-green eyes, and her closed lips curve in a small smile. Her dark brown hair is parted in the center and falls in two long braids over the front of her shoulders. A gold crown set with green and red gems and rimmed with pearls sits on her head, and a green teardrop gem hangs from it onto her forehead. Gold earrings with green stones hang at her cheeks. A gold collar set with gems circles her throat. She wears a long gown of blue-gray brocade with narrow sleeves. A cream shoulder cape edged in gold braid lies over the gown, studded with green and red stones and crossed by bands of gold. A cream panel runs down the front of the gown, set with pearls and green and red gems in a row. Gold cuffs studded with pearls close each sleeve. Her right hand is raised in a loose fist beside her shoulder, and her left arm hangs at her side. Behind her a church of gray stone with a red dome and a round tower stands on a hill above the blue lake. Dark pines rise at her shoulder, and snow-streaked mountains fill the distance under a deep blue sky in cool fading light.

Sources: fandom gives a portrait as the model source and notes the final model has lighter skin than early builds. The scene location is not named, so it is described generically.

## 40. LEADER_WILHELMINA
Wilhelmina, Netherlands

Wilhelmina Helena Pauline Maria, Queen of the Netherlands, Princess of Orange-Nassau and Duchess of Limburg, stands on a sunny day on a polder. She is a stout woman past middle age with a round full face, rosy cheeks and a double chin. Her small gray-blue eyes crinkle above a broad closed-lipped smile. Short dark brown hair shows beneath a pale gray hat with a flat brim, trimmed with a mauve ribbon rosette. She wears a brown wool jacket fastened with a single button over a white blouse with a high collar. Three gold buttons run down the blouse front, and a round blue brooch with a gold crest is pinned at her collar. A dark skirt falls below the jacket. In her right hand she holds a furled parasol by its curved black handle, its pale folded canopy hanging down. Her left arm hangs at her side. A canal lies still at the very front of the scene, and a meadow with purple and yellow flowers stretches back from it. Behind her a tall windmill with four broad sails stands on the flat green land, with a second mill far off at the left. Low trees line the far horizon under great piled clouds in a wide sky.

Sources: fandom trivia gives the polder scene, the parasol, and the 1942 photograph as the model source. Fandom says the day is sunny, but the composite reads as overcast, so the light is described as a cloudy sky.

## 41. LEADER_ABRAHAM_LINCOLN
Abraham Lincoln, America

Abraham Lincoln, sixteenth President of the United States of America, stands in a wood-paneled office. He is very tall and thin, with pale skin and a long gaunt face. His deep-set gray eyes look out from under heavy dark brows. A dark chin beard frames a clean-shaven upper lip. His mouth is set in a firm line, and dark hair shows beneath a tall black top hat. He wears a long black frock coat over a black vest with a row of dark buttons. A white shirt collar shows at his neck with a dark red bow tie, and a gold watch chain hangs from the vest. Gray trousers show below the coat. His right hand is raised in front of his chest with the fingers half curled, and his left arm is tucked behind his back. Behind him a wooden desk holds an open book, an inkwell with a pen, a rolled paper and a loose sheet, with a plain wooden chair pushed up to it. A window at the left lets in warm daylight, and an American flag hangs from a pole leaning against the wall beside it. Paneled walls and a molded rail run across the back of the room. The right side falls into darkness.

Sources: fandom gives the 1862 Sharpsburg photograph as the model source. The scene location is not named, so it is described as an office.

## 42. LEADER_AL_HAKAM_II
Al-Hakam II, Córdoba

Abu al-As al-Mustansir bi-llah al-Hakam ibn Abd al-Rahman of the Umayyad house, second Caliph of Córdoba and Commander of the Faithful, is shown as a carved wooden bust set against a plain black background. The whole figure is cut from warm brown wood, and the grain shows across his face and his clothing. He is an old man with a lean face and heavy brows drawn down over deep-set eyes. Lines cross his forehead, and his cheeks are sunken. His nose is long and hooked. A thick mustache merges into a long full beard that hangs to his chest. A rounded turban wrapped in thick folds covers his head, with a small point at the top. His robe crosses over his chest in overlapping folds, and a loose wrap lies over his shoulders. The bust ends at the upper chest and shows no arms or props. His head turns slightly to his left with his frowning gaze directed to the front.

Sources: Vikings scenario leader with no scene, loading screen, or fandom notes; the entry is written from the cut-out alone, which is a wooden bust rather than a full figure. Titles are from general history.

## 43. LEADER_AMBIORIX
Ambiorix, Gaul

Ambiorix, King of the Eburones, a Belgic tribe of northeastern Gaul, stands in a forest clearing before a tall rough standing stone called a menhir. A smaller boulder lies at its foot. He is a lean, muscular man with pale skin and a long face. Thick red hair is swept up and back from his brow, and a single braid hangs over his right shoulder to his chest. His eyebrows are heavy and red, his eyes are blue, and a long red mustache droops past the corners of his mouth and curls at the ends. He has no beard, and his mouth is set in a slight smirk. His chest is bare. A torc of braided gold circles his neck. Blue-gray markings are painted on his skin: a jagged band across his right chest, a large spiral on his right ribs, and horizontal bars down his left upper arm. In his right hand he holds a tall spear upright, an ash shaft bound with cord below a leaf-shaped iron head. His left arm carries a large oval wooden shield with a purple field, wide gold bands with curling spiral motifs, a studded rim, and a round iron boss at the center. A fringe of reddish hide shows at his waist below the shield. Behind him bare gray tree trunks rise against an orange sky, and warm light falls on the grass at the base of the stone. Dark boughs hang over the upper right of the scene.

Sources: fandom trivia names the menhir in a forest clearing, the torc, and the Tongeren statue as the model source. Titles are from general history. The composite places the leader over the scene layers, so the exact distance to the stone is approximate.

## 44. LEADER_BASIL_II
Basil II (Vikings scenario bust), Byzantium

Basil II Porphyrogenitus, 'the Bulgar Slayer' of the Macedonian dynasty, Emperor and Autocrat of the Romans in Byzantium, is shown as a carved wooden bust set against a plain black background. The whole figure is cut from brown wood with a visible grain. He is a heavy-set man with a broad face and a wide flat nose. He scowls deeply. His thick brows press down over narrowed eyes, and creases run across his forehead. A dense full beard and heavy mustache cover his jaw. His hair is cropped close to the skull. A low flat crown sits on his head, a band studded with round bosses and a raised plaque at the front topped with three short points. His chest is covered in scale armor, rows of overlapping rounded plates. A cloak is drawn across from his left shoulder and fastened at his right shoulder with a square brooch. The bust ends at the chest and shows no arms or props. He faces the front with his head level.

Sources: Vikings scenario leader with no scene or fandom notes; the entry is written from the cut-out alone, which is a wooden bust. The loading screen on file shows the full armored Basil II model of the base game, not this bust, so it was not used. Titles are from general history.

## 45. LEADER_BASIL
Basil II, Byzantium

Basil II Porphyrogenitus, 'the Bulgar Slayer' of the Macedonian dynasty, Emperor and Autocrat of the Romans in Byzantium, stands before the Great Palace of Constantinople at sunset, its long stone front of arched windows and rounded gateway glowing orange. A square tower with a red pointed roof rises above the roofline, and dark trees frame the left edge of the scene. He is a stocky, broad-shouldered man of middle age with tanned skin, a strong nose, and heavy brows drawn down over his eyes. Gray hair falls in waves to his shoulders, and a full gray beard and mustache cover his jaw under heavy dark eyebrows. A gold crown of upright square plates sits on his head, set with blue and red stones and a small pearl at the center. Under his armor he wears a purple silk tunic patterned with darker flowers, its long sleeves ending in cuffs at the wrist. Over it sits a cuirass of small square iron plates riveted in rows, framed by brown leather straps with gold roundels at the shoulders. A guard of overlapping steel plates covers his right shoulder. A gold chain holds a quatrefoil pendant, a four-lobed gold frame around a large square blue stone, in the middle of his chest. A brown leather belt binds the plates at his waist. The purple skirt of the tunic hangs below a scalloped leather fringe. His right arm hangs at his side, and his left hand is clenched into a fist at his hip. Warm evening light falls on the palace while the emperor stands in cooler shadow.

Sources: fandom gallery names the Menologion of Basil II image as the model source. The wiki does not name the building; it is called the Great Palace of Constantinople on the strength of the long arched seaward front in the image, which matches the palace's Boukoleon wing. Titles are from general history.

## 46. LEADER_CATHERINE_DE_MEDICI_ALT
Catherine de Medici (Magnificence), France

Caterina Maria Romula di Lorenzo de' Medici, Queen consort, Queen Mother, and regent of France, stands in a formal garden at night. She is a slim woman with pale skin, a long face, and gray-blue eyes. She smiles faintly. Her dark brown hair is drawn back into a gold caul, a netted cap of gold bands. A white and gold half mask covers her eyes and the bridge of her nose, its gold scrollwork edged with small pearls and a green jewel set at her right temple. A spray of red feathers rises from the right side of her head above the mask. A tall pleated white ruff stands around her neck. Her gown is coral silk with a square neckline edged in a row of pearls and a square red jewel set in gold at the center. Above the neckline a white partlet, a light chest covering worn under the gown, is crossed by gold bands with gold studs. The gown's upper sleeves are large puffs of coral silk, and the lower sleeves are white with bands of coral and gold, ending in gold cuffs edged with white. A string of pearls hangs as a girdle at her waist over a full coral skirt. She holds a closed folding fan in both hands in front of her. Behind her a round pavilion of pale columns under a pointed roof rises above clipped hedges and dark cypress trees. Stone urns on pedestals hold pink flowers, and a still pool at the front of the scene reflects the pavilion. The sky is deep blue and full of stars, with a pale band of cloud low on the right.

Sources: fandom gallery names the Vasari wedding painting as the model source. The wiki does not name the garden, so it is described generically. Titles are from general history. The fan is visible in the cutout and the loading screen.

## 47. LEADER_CHARLEMAGNE
Charlemagne, Holy Roman Empire

Charles of the Carolingian house, Charlemagne, King of the Franks and the Lombards, Emperor of the Romans, and first of the Holy Roman Emperors, is shown as a carved wooden bust set against a plain black background. The figure is cut from brown wood with a streaked grain. He is a gaunt old man with a long narrow face and hollow cheeks. His eyes are heavy-lidded and tired under thick brows, and deep lines frame his mouth. A long mustache sweeps out to both sides and curls upward at its ends. A long full beard hangs below it. His hair falls long behind his ears. A tall crown sits on his head, a wide band topped with high rounded leaves rising to a peak at the front. A fur collar spreads over his shoulders, and a cloak with a ribbed woven texture wraps his chest and is gathered at his right shoulder by a large round medallion. The bust ends at the chest and shows no arms or props. His head is turned slightly to his left.

Sources: Vikings scenario leader with no scene, loading screen, or fandom notes; the entry is written from the cut-out alone, which is a wooden bust. Titles are from general history.

## 48. LEADER_CLEOPATRA_ALT
Cleopatra (Ptolemaic), Egypt

Cleopatra VII, Thea Philopator, Queen and Pharaoh of Ptolemaic Egypt, stands on a stone terrace above the Nile at night, with the Pyramids on the horizon. She is a slender young woman with light brown skin, an oval face, and gray eyes under heavy purple and pink eyeshadow drawn out in black wings. Her lips are full, and a small mole marks her left cheek. Her black hair is cut in a straight fringe across her brow and falls to her jaw in rows of tight corkscrew curls. A gold diadem crosses her forehead, bearing at its center a small gold bird's head with a crest of red plumes. Heavy gold earrings hang from each ear, cylinders of gold set with blue stones. Her sleeveless gown is dark olive brown, with a deep V neckline bordered by gold stripes and gold scroll clasps at the shoulders. Gold cords wrap several times around her waist and are knotted at the front. Thin gold lines radiate from them down the gown's skirt. A teal and gold band circles her right upper arm, and a wide teal and gold cuff and a bracelet circle her left wrist, with a ring on that hand. Her right hand rests on her hip while her left hand is raised to her jaw with the fingers touching her cheek. Dark pillars frame both edges of the scene, and behind her square stone posts edge the terrace. Below it dark green water carries moored boats, one with a mast and one lit by a small lantern. Palm trees stand on the far bank, and the two pyramids rise against a teal sky streaked with cloud.

Sources: fandom trivia says the scene shows the Nile with the Pyramids on the horizon. Titles are from general history. No painting or statue source is documented for this persona.

## 49. LEADER_CNUT
Cnut, Denmark

Cnut 'the Great' Sweynsson of the house of Knýtlinga, King of England, Denmark, and Norway, is shown as a carved wooden bust set against a plain black background. The figure is cut from brown wood, and the grain shows across his face and his cloak. He is a gaunt man with a long narrow face, a high forehead, and a sharp hooked nose. His deep-set eyes glare from under brows drawn down in a scowl, and his mouth is set hard. His hair is combed straight back close to the skull. A thin mustache runs into a short pointed beard on the chin, and the cheeks are bare. A thick rolled collar circles his neck. A cloak wraps his shoulders and chest and is fastened on each shoulder with a large round disc brooch. The bust ends at the chest and shows no arms or props. His head is tilted a little forward so that the eyes look up from under the brows.

Sources: Vikings scenario leader with no scene or fandom notes; the entry is written from the cut-out, which is a wooden bust, and the loading screen confirms the same bust with no added props. Titles are from general history.

## 50. LEADER_ELIZABETH
Elizabeth I, England

Elizabeth I 'Gloriana' of the House of Tudor, Queen of England and Ireland, Defender of the Faith, Supreme Governor of the Church of England, and claimant Queen of France, stands in the courtyard of Richmond Palace on a bright day. She is a pale woman with a long narrow face and a high forehead. Her brows are thin and arched, her eyes are blue, and her small mouth is closed. Her red-gold hair is tightly curled and piled high. A small gold crown sits on her curls, with blue enamel panels and pearl-tipped spikes, and a teardrop pearl hangs from it onto her forehead. Pearl drops with small red stones hang from her ears. A tall ruff of starched cream pleats stands wide around her neck above a necklace of pearls, the emblem of chastity she wore as the Virgin Queen, with a red jeweled pendant. Her gown is dark brown, near black, patterned all over with gold foliage. Its bodice front carries a vertical panel of large pearl and silver rosettes and a gold pendant set with a blue stone and a hanging pearl. Tall puffed rolls sit at the shoulders, and the gown's sleeves are slashed in diamonds to show cream lining, each slash pinned with a pearl. Cream lace cuffs cover her wrists, and her hands are folded at her waist. Her overskirt parts at the front to show a cream underskirt, and the whole skirt spreads wide over a farthingale, the hooped frame worn beneath. Behind her the palace, pale stone with battlements and a square tower, stands across a green lawn, its tall windows catching the light. A tiered stone fountain stands at the left, with clipped round bushes and a gravel path beside it. A large dark tree overhangs the top of the scene, and white clouds drift in a blue sky.

Sources: fandom trivia names the courtyard of Richmond Palace and the Steven van der Meulen portrait as the model source. Titles are from general history.

## 51. LEADER_HAMMURABI
Hammurabi, Babylon

Hammurabi, son of Sin-Muballit, King of Babylon, Sumer, and Akkad, stands on a riverbank under a hazy orange sky. He is a heavy, broad-chested man with dark brown skin. He stares out from under thick dark eyebrows drawn down in a scowl. His dark hair is bound in curls behind his ears, and a long dark beard falls in tight rows of curls to his chest below a thick mustache. A gold earring set with a turquoise bead hangs from his ear. On his head sits a gold cap with a domed top worked in a scale pattern and a small knob at the crown. Its band is a row of square panels, each holding a circle in red, white, or blue. He wears a white short-sleeved tunic patterned with gold diamonds, with a teal band across the chest bearing gold rosettes. A blue cloth is wrapped over his left shoulder and around his waist, its edge lined with a thick fringe of tan tassels that crosses his body. His arms are bare and thick, a twisted gold bracelet circles his left wrist, and his hands are closed at his sides. Behind him, tall palm trees lean over a still stretch of water edged with reeds and grass, where a small boat with a white triangular sail drifts. A ziggurat rises in terraces on the far bank with its walls lit gold by low light, and smaller palms stand at its base.

Sources: the wiki does not name the scene, so the ziggurat and river are described as seen. The gallery only cites an unnamed drawing of Hammurabi as the model source, so no source is named in the text. Titles are from general history.

## 52. LEADER_HARALD_ALT
Harald Hardrada (Varangian), Norway

Harald III 'Hardrada' Sigurdsson, King of Norway, stands on a rocky shore at sunrise. He is a tall, broad man with pale weathered skin, blue eyes, and a short brown beard and mustache. His mouth is open in a grin that shows his teeth. A conical iron helmet covers his head, topped with a slender spike and bound with a gold band engraved with knotwork, with a nasal bar down over his nose. A coif of chain mail hangs from the helmet over his neck and shoulders, and two pale bone toggles show at his throat. He wears a lamellar cuirass, rows of small rectangular iron plates laced together with leather. Layered shoulder guards edged in gold cover both shoulders, and gray quilted sleeves end in dark leather vambraces. A brown leather baldric runs from his right shoulder to his left hip, studded with gold diamond plates and a round gold medallion. A wide brown belt with a brass buckle holds a gray padded skirt at his waist. A sword hangs in a scabbard at his left hip with its red-wrapped grip and gold guard angled forward, and his hands are open at his sides. Behind him longships with tall dragon-headed prows and furled sails sit at the water's edge, pennants flying from their masts. Waves break white on dark rocks at the left of the scene, and a low hill rises beyond them. Cold morning light fills the scene under a teal green sky with a pale sun low above the ships.

Sources: fandom trivia says the scene shows many longships near a shore at sunrise. Titles are from general history. No statue or painting source is documented for this persona.

## 53. LEADER_JOAO_III
João III, Portugal

João III 'the Pious' of the House of Aviz, King of Portugal and the Algarves and Lord of Guinea, stands on a riverbank before the Torre de Belém at sunset. He is a stout round-faced man with pale skin, rosy cheeks, and gray-green eyes. He smiles warmly. His dark hair is cropped short under a flat black velvet cap that tilts to one side, trimmed with a gold cord and a jeweled gold brooch. A dark beard and mustache are trimmed close to his jaw, and his dark brows arch high. He wears a doublet of wine red silk with large puffed sleeves banded in gold embroidery at the shoulders. A wide collar of dark brown fur runs from his shoulders down both sides of the front. Beneath it shows a gray-blue brocade under-doublet fastened with a row of gold buttons and edged in gold at the neck. His cuffs are white lace, with a gold band at the left wrist, and a dark sash is knotted at his waist. In his right hand he holds a slender gold scepter angled up past his shoulder, topped with a gold bulb finial, a scepter modeled on the Sceptre of the Armillary of the Portuguese crown jewels. His left hand hangs at his side. Behind him the tower rises in pale stone, a square keep with battlements and small turrets capped by domes, above a lower bastion with round corner turrets. Green trees frame it on both sides, with one crown turning orange. In front of the tower a paved terrace is edged with stone posts linked by chains, and the ground is washed in violet shadow. The sky glows pink and orange behind the tower, while the right side of the scene falls into darkness.

Sources: fandom trivia names the Torre de Belém at sunset, the scepter modeled on the Sceptre of the Armillary, and the Coimbra statue as the model source. Titles are from general history.

## 54. LEADER_JOHN_CURTIN
John Curtin, Australia

John Joseph Ambrose Curtin, fourteenth Prime Minister of Australia and Leader of the Australian Labor Party, stands in the Australian Outback near Uluru in the late afternoon. He is a slim man with fair skin and a narrow face. His smile is wide and easy. Small round spectacles with thin gold rims sit on his nose in front of blue-gray eyes. His dark hair is hidden under a tan felt hat with a dark band and a brim turned up at the sides. He wears a pale blue shirt with fine stripes, its long sleeves full to the wrist, and a dark red tie knotted at the collar. Over the shirt is a dark brown wool vest with a row of buttons, and a gold watch chain loops from a button down into the vest pocket. He wears brown trousers and no jacket. His arms hang at his sides, and a ring shows on his left hand. Dark scrub fills the front of the scene beside a tall gum tree with a dark trunk and a sparse crown at the right. Behind him a dry plain of red earth and pale grass stretches to a low house with a broad roof and a shaded veranda, set among a stand of tall thin gum trees. Beyond the house rounded red hills rise on the horizon, the low bulk of Uluru among them. The sky is a brown-orange haze that darkens toward the top.

Sources: fandom trivia names the house near Uluru in the Outback late in the afternoon, and the gallery names the 1941 garden party photograph and a photograph with his wife Elsie as model sources. Titles are from general history. The rounded hill is taken to be Uluru on the wiki's word.

## 55. LEADER_JULIUS_CAESAR
Julius Caesar, Rome

Gaius Julius Caesar, Dictator Perpetuo of Rome, stands on a paved square before the Arch of Titus at sunset. He is a lean man with pale skin, a long face, pale blue eyes, and thin lips pressed into a skeptical frown under knitted brows. His short dark hair recedes at the temples under a gold laurel wreath. He wears a gold muscle cuirass with a round gold rosette boss on the left side. A red scarf is tucked at his neck, and a red sash is tied around his waist over the armor. Leather shoulder guards edged in gold sit on his shoulders, with strips of leather hanging from them over his upper arms. Brown leather vambraces are bound with gold bands and set with gold rosettes. Below the cuirass a skirt of studded leather strips hangs over a gray tunic. His right hand is raised in a loose fist at chest height while his left hand grips the hilt of a sword sheathed at his side. Behind him a tall column stands at the left, and beyond it the arch rises in pale stone with a bronze chariot group on top. A dark horseman, a statue in silhouette, stands in a haze behind his shoulder. The sky is rose and gold streaked with dark cloud, and the right side of the scene falls into shadow.

Sources: fandom trivia names the Arch of Titus at sunset and the Louvre statue as the model source. Titles are from general history. The horseman behind him is a dark silhouette in the scene layers and cannot be identified.

## 56. LEADER_KUBLAI_KHAN_CHINA
Kublai Khan, China

Kublai Khan of the Borjigin clan, Great Khan of the Mongol Empire and Emperor of China, stands on the shore of Taiye Lake in his winter capital of Khanbaliq. He is a heavy, broad-chested man in late middle age with light tan skin, a round face, and narrow dark eyes under thin arched brows. His gray hair is swept back from his forehead and hangs to his collar. A long gray mustache curls out past the corners of his mouth, and a full gray beard falls in two soft points onto his chest. A small gold earring hangs from his right ear. He wears a white silk robe patterned with pale gold scrolling leaves, closed across the chest by a wide band of gold brocade that runs from his left shoulder down to his right hip. Bright gold cuffs cover his forearms. A red belt with a large round pewter buckle bearing a lotus emblem cinches his waist, and a red pouch and a red panel stamped with gold hang from the belt at each hip. His hands are clasped in front of his stomach with the fingers laced together. Behind him a small pavilion with red walls and a curved gray roof stands on a spit of grass among willow trees whose long green fronds trail toward the water. Pink lotus blossoms and round green pads cover the pond at the front of the scene. A white mountain rises through a pale blue sky in the distance. The pavilion is mirrored in the still water under a soft clear light.

Sources: fandom trivia names the scene as Taiye Lake in Khanbaliq and notes the white silk robe with golden trimmings, and the gallery cites a Yuan dynasty painting of Kublai as the model source. The earring shows in the loading-screen render.

## 57. LEADER_LADY_SIX_SKY
Lady Six Sky, Maya

Wak Chanil Ajaw, Lady Six Sky, Holy Lady of Dos Pilas and Maya queen of Naranjo, stands in a jungle clearing. She is a sturdy, broad-shouldered woman with reddish brown skin and a round face. She smiles slightly with her chin raised. Three small teal dots are painted down the bridge of her nose, and darker red paint marks her cheek and shoulders. Her headdress is a tall woven cone of tan fiber, bound with a band of dark red beads and a carved jade rosette above the brow. Red plumes and long green feathers fan out around it and hang past her shoulders. Jade ear ornaments hang beside her jaw. Around her neck she wears strings of jade tube beads and gold beads with a carved jade pendant. Her top is a strapless wrap of pale tan bark cloth with a fringe along the upper edge, a dark red band, and a row of tan zigzags. A belt of upright dark red tubes circles her waist, closed by a jade buckle carved as a fanged face, and long red pendants hang from it over an olive brown skirt. Dark red bead bands ring her upper arms. Turquoise bands ring her wrists. In her right hand she holds a tall dark spear with a gold ferrule and a jade point flanked by curling jade hooks. Her left hand rests on her hip. Green shrubs and a dirt path fill the front of the scene under a tree with red foliage that spreads over the clearing. Behind her a pyramid of orange stone in steep steps climbs to a small temple with a carved face over its doorway, and a long stairway runs down its side. Two fires burn at its foot. The second pyramid rises as a reddish shape in the haze beyond. The sky is orange and turquoise, with reddish peaks hazy in the distance.

Sources: fandom trivia names the scene as step pyramids in a jungle clearing and the jade-tipped spear, and the gallery cites a stela of her standing on a prisoner as the model source. The composite shows one clear pyramid and a reddish shape behind it, taken as the second.

## 58. LEADER_LADY_TRIEU
Ba Trieu, Vietnam

Trieu Thi Trinh, Ba Trieu, leader of the Vietnamese rising against Chinese Wu rule and self-styled the Lady General in the Golden Robe, stands on a riverbank with a spear over her shoulder. She is a slender young woman with light tan skin and dark almond eyes under thin arched brows. She smiles faintly and confidently. Her black hair is pulled back under a flat round headdress of teal cloth painted with gold and white fan shapes. She wears a golden yellow silk tunic with a stiff high collar edged in teal, closed along a diagonal seam by a row of small pearl buttons running down to her right side. A wide sash circles her waist: a red band of gold triangles, a teal band of gold flying birds, and a red band of gold rings. The tunic falls in long panels over a gray green underskirt. On her right forearm she wears a brown leather bracer stamped with circles, and on her left a brown bracer laced with cord through metal eyelets. A spear with a dark wooden shaft rests on her left shoulder, held in her left hand, its broad bronze blade engraved with a curling pattern. Her right hand rests on her hip. Behind her three houses stand on wooden stilts at the water's edge under steep thatched roofs, one with a ladder up to its door. Boulders and reeds line the bank, and lily pads float on the water. Rounded hills fade into a yellow green haze behind the houses. Soft yellow light lies over the river.

Sources: fandom trivia names the scene as three stilt houses by a riverbank with water lilies, and the gallery cites the Hoang Hoa Mai painting as the model source. The right half of the composite is blank, so only the left of the scene is described.

## 59. LEADER_MENELIK
Menelik II, Ethiopia

Sahle Maryam of the Solomonic dynasty, Menelik II, King of Shewa and Emperor of Ethiopia, King of Kings and Conquering Lion of the Tribe of Judah, stands on a hillside road below Fasilides Castle in the Fasil Ghebbi palace compound at Gondar in the late afternoon. He is a lean man of middle age with dark brown skin and pale green eyes that glance sideways under a heavy brow. A thick black beard covers his jaw, and he smiles with his lips parted. On his head sits a black hat with a round crown and a wide brim, its underside a dusty pink. A white cloth hangs from beneath the hat behind his beard. He wears a long dark blue robe patterned all over with a fine floral damask. A panel of gold embroidery runs down the front of the chest around a strip of red set with small gold studs, and gold embroidery bands each cuff. A long sash of tan cloth is knotted at his waist with its tail hanging to his knee. The front slit of the robe is edged in gold. His hands are raised in front of his chest with the fingertips of each hand pressed together. Behind him the castle rises on a bare hill as a block of sandy yellow stone with round corner towers and a battlemented roofline. Arched windows pierce its walls, and a small balcony juts from one of them. A dirt road winds up from the front of the scene, where dark rocks and low bushes with purple blossoms sit under a bare dead tree. The sky glows pink and orange over hills in the distance.

Sources: fandom trivia names the scene as Fasilides Castle in Fasil Ghebbi in the afternoon, and the gallery cites a portrait of Menelik as the model source. The white cloth at the neck is only partly visible behind the beard.

## 60. LEADER_NADER_SHAH
Nader Shah, Persia

Nader Shah Afshar, born Nadr Qoli, King of Kings of Persia, stands in a garden at sunset. He is a tall, strongly built man with pale olive skin, a straight nose, and gray green eyes narrowed under brows drawn together. A thick brown beard covers his jaw and chin, and a brown mustache hides his upper lip. On his head sits the four-peaked Naderi hat, a tall red cap rising in four points. A gold band set with pearls and red and green stones binds it at the brow. A gold plume holder with a green gem stands on the front of the cap and carries a tall white feather. Around his shoulders lies a stole of long silver gray fur. Beneath it he wears a crimson cloak over a gray tunic of fine mail, with gold edging on the shoulders. A gold armlet set with red and green stones clasps his right upper arm. A chain of gold plaques set with large red stones hangs down his chest, and a gold buckle with a red stone sits at his belt above a gold-edged front panel. In his right hand he holds a gold mace with a spade-shaped head across his body. Behind him the garden of low beds and a straight path leads to a mosque, its dome pale and its tall arched gateway faced in blue tile. A tall tree with a broad dark crown rises just behind his right shoulder and shades the gateway. Smaller dark trees stand at the left and front of the scene. A dark wall closes the far right. The sky is orange from edge to edge, and warm light falls on the garden while the tree and the right side of the scene stay in shadow.

Sources: the gallery cites a 3D model by Alireza Akhbari as the model source. The scene location is not documented, so the mosque and garden are described generically.

## 61. LEADER_NZINGA_MBANDE
Nzinga Mbande, Kongo

Njinga Mbande, baptized Ana de Sousa, Queen of Ndongo and Matamba in the lands south of the Kingdom of Kongo, stands on a red dirt path above a jungle river. She is a slim young woman with dark brown skin, a long neck, full lips, and dark eyes under slightly raised brows. Her black hair is cut at the jaw in tight curls, and small gold hoops hang from her ears. On her head sits a domed red cap crossed with gold cord and studded with blue stones, rising from a gold base shaped in petals and set with red stones. Two teal plumes spring from its top. Two stacked gold collars circle her neck above a string of large green beads. A length of orange cloth is draped over her left shoulder and across a pale strapless band, leaving her right shoulder bare. A red sash is tied at her waist with its ends hanging down her front. Over it sits a belt of bead strings and curved leopard claws above a band of leopard skin with a scalloped hem, and a tassel of green fibers hangs at her right hip. A long orange skirt marked with a faint diamond lattice falls to her feet. Gold bands set with red stones ring her upper arms, and gold bracelets ring her wrists. In her raised left hand she holds a short axe with a wooden handle and a broad curved iron blade. Her right arm hangs at her side. Behind her a wide waterfall pours over a long cliff in many white sheets, and a thin bridge spans the gorge. Dense green trees and ferns crowd both banks under a dusky blue gray sky in dim cool light.

Sources: the gallery cites a colored lithograph of Queen Nzinga as the model source. The scene location is not documented, so the waterfall is described generically. The loading-screen render shows her hands folded in front of her, and the axe appears only in the idle pose.

## 62. LEADER_OLOF
Olof Skötkonung, Sweden

Olof Eriksson Skötkonung of the House of Munsö, King of Sweden, is shown as a carved wooden bust set against a plain black background. The figure is cut from brown wood with a fine grain. He is a broad-faced man with narrowed eyes, a wide nose, and a crooked grin that lifts one side of his mouth. A thick mustache and a short beard cover his chin. A rounded helmet with a brow band and a nasal, the strip that guards the nose, covers his head, and hinged cheek guards hang beside his face. Two long braids fall from beneath the helmet on either side of his face and end in tasseled tufts at his chest. A shaggy fur mantle covers his shoulders. Beneath it his tunic shows a central strip carved with a diamond pattern, and a heavy ring is set into the strip at the middle of his chest. The bust ends below the chest and shows no arms or props.

Sources: Vikings scenario leader with no scene or fandom notes; the entry is written from the cut-out, which is a wooden bust, and the loading screen confirms the same bust with no added props. Titles are from general history.

## 63. LEADER_QIN_ALT
Qin Shi Huang (Unifier), China

Ying Zheng, Qin Shi Huang, King of Qin and First Emperor of a united China, stands in full armor before the walls and gate towers of a fortified palace at sunset. He is a heavy, thick-necked man with pale skin, a broad face, and narrow pale blue eyes under thick black brows. His black hair is drawn up into a topknot pierced by a long gold pin ending in a dragon's head, with a small gold cap at its base. A black mustache droops past his mouth, and a long black beard hangs onto his chest. He wears a cuirass of square gold plates laced in rows, each plate stamped with a small chevron. Wide shoulder guards of dark gray plate edged in gold hang over his upper arms, and each guard bears a gold curling emblem. A red cord tied in a loose bow hangs at his chest. A broad leather belt circles his waist, closed by a large gold plaque and covered in gold scrollwork. Dark bracers stamped with square spirals cover his forearms. A bronze sword with a grip wrapped in red brown cord is thrust through his belt at his left hip, and his left hand grips it below the hilt. Behind him the wall runs long and crenellated across the scene, with a gate house in its center and tall pavilions with sweeping tiled roofs rising above it at each side. A ramp climbs to the gate through reddish rocks and low plants. Pink and orange clouds drift across a blue sky. The armor follows a warrior of the Terracotta Army.

Sources: the gallery cites a Terracotta Army warrior as the source of the outfit. The scene location is not documented, so the palace is described generically.

## 64. LEADER_RAMSES
Ramses II, Egypt

Ramesses II 'the Great', known to the Greeks as Ozymandias, third pharaoh of the Nineteenth Dynasty of Egypt, stands on the bank of the Nile at sundown. He is a tall and well-built man with light tan skin, a long straight nose, and blue eyes. He is clean shaven and smiles with one corner of his mouth. On his head sits a khepresh, the blue crown the pharaohs wore to war, a tall cap patterned with small gold rings and bound at the brow by a gold band. A gold uraeus, the rearing cobra of the pharaohs, rises from the front of the crown. Around his shoulders lies a broad collar of gold with bands of red, green, and turquoise ending in a fringe of turquoise points. He wears a white linen tunic with short sleeves banded in gold. Gold and blue armlets clasp his upper arms, and wide cuffs of gold and blue set with red and blue inlays cover his forearms. A gold belt with a round gold and turquoise buckle and a red cord circles his waist above a white kilt. In both hands he holds a heka, the crook the pharaohs carried as a scepter, striped in blue and gold in front of his waist. Reeds and dry grass fill the front of the scene. Behind him tall palms lean over the river, and a small stone temple with sloping walls stands on the far bank. Two pyramids rise beyond the water in a purple haze. The sky is streaked orange and violet over a river that reflects the same colors.

Sources: fandom trivia names the scene as the pyramids at sundown and notes the crook and the uraeus, and the gallery cites Champollion's reproduction of an Abu Simbel wall painting as the model source.

## 65. LEADER_SALADIN_ALT
Saladin (Sultan), Arabia

Al-Malik al-Nasir Salah al-Din Abu al-Muzaffar Yusuf ibn Ayyub, Sultan of Egypt and Syria, and Custodian of the Two Holy Mosques, stands at the mouth of a war tent looking out over a camp at sunset. He is a lean man with brown skin, hollow cheeks, a long hooked nose, and wide gray blue eyes. A thin dark beard runs along his jaw to a short pointed chin beard, and his lips are parted. On his head sits a pointed steel helmet with a spike on top, a gold band around the brow, and a gold nasal bar down his nose. An aventail, a hanging skirt of mail, falls from the helmet around his cheeks and neck. He wears a coat of gold scale armor, each scale rounded, with brown leather edging and shoulder plates. A gold vambrace set with green stones covers his left forearm, and a gold cuff with a green stone rings his right wrist. A sash of green cloth striped with white is wound around his waist over the armor. A sword hangs at his right side, its hilt topped by a round silver disc chased with scrolls, and his right hand rests on the grip while his left arm hangs at his side. Behind him the dark canvas of the tent is hung with a fringe of tassels. Its poles and guy ropes frame the scene. Beyond the tent rows of pale tents cover a plain below a mountain. Clay jars sit at the right of the scene. The sky is a deep red orange, and the light inside the tent is dim.

Sources: the gallery cites a bust of Saladin as the model source. The scene location is not documented, so the camp is described generically.

## 66. LEADER_SIMON_BOLIVAR
Simón Bolívar, Gran Colombia

Simón Bolívar, the Liberator, first President of Gran Colombia and of Bolivia, and Dictator of Peru, stands on open Andean moorland at sunset. The moorland is a high plateau of dark grass and scrub under a pink and violet sky. He is a young man, slim and straight-backed, with pale skin and a long narrow face. His black hair is thick and wavy, swept up from a high forehead, and heavy black eyebrows arch over green eyes. Long black sideburns run down past his jaw, and his chin is clean-shaven. He looks off to one side with a closed-mouth half smile and one eyebrow raised. He wears a general's dress uniform from the independence wars. The coat of the uniform has a red front panel edged in gold and embroidered with gold laurel sprays, closed by a single row of gold buttons. Its sleeves and shoulders are dark blue, and gold fringed epaulettes rest on both shoulders. A high red collar and red cuffs carry more gold embroidery, and a white shirt collar shows at his throat. A gold silk sash is wound around his waist over dark gray trousers. His right hand rests on his hip, and his left arm hangs at his side. Behind him a frailejón, a tall rosette plant of the high Andean moors, lifts its spiky gray leaves from the scrub. Far to the left a small herd of horned cattle grazes in silhouette against the horizon, where the clouds burn pink and orange, and low dark hills close the right side of the scene.

Sources: fandom trivia identifies the scene as the Andean moorland by its Espeletia plant, the frailejón, and says an unnamed portrait inspired the model. The loading screen shows the same pose with nothing in his hands.

## 67. LEADER_TOKUGAWA
Tokugawa, Japan

Tokugawa Ieyasu, born Matsudaira Takechiyo, Sei-i Taishogun, the shogun of Japan, stands at night before Himeji Castle. He is a heavyset older man with a broad face and tan skin. He stares out from under thick dark eyebrows. His head is shaved on top in the samurai fashion, with the remaining hair oiled back at the sides and tied into a short topknot that stands up from the crown. A thin mustache with pointed ends and a small pointed goatee frame a set mouth. He wears full samurai armor in dark lacquered steel. Its cuirass is built of horizontal bands laced together with red cord and trimmed in gold. Large square shoulder guards hang from each shoulder, and laced plates cover his forearms. Under the armor he wears a pale gray robe with wide sleeves. A tan sash is tied around his waist. A katana is thrust through the sash on his left side with its red-wrapped hilt forward, and his left hand rests on the dark scabbard. Loose gray trousers with a fine stripe fall below an armored skirt. At his right side he carries a gunbai, a rigid war fan of a commander, held by its long handle so the fan hangs at his hip. The fan is gold and lobed, and it is painted with the triple hollyhock crest of the Tokugawa clan in dark roundels. Behind him and to the left the white walls and tiered gray roofs of the castle rise against a cloudy night sky, warm lamplight showing in its lower windows. A full moon hangs in the sky just behind his shoulder. A large pine leans its trunk and branches in from the left. Its dark needled boughs spread across the top of the scene to the right. The ground before the castle is in shadow, and the right side of the scene is dark. Pale moonlight falls on his face and armor.

Sources: fandom trivia names Himeji Castle at night, the gunbai with the triple hollyhock mon, and a one-sixth scale model as the inspiration. The loading screen shows the same idle pose. Written from the regenerated composite without the vignette layer, which revealed the moon and the pine boughs on the right.

## 68. LEADER_T_ROOSEVELT_ROUGHRIDER
Teddy Roosevelt (Rough Rider), America

Theodore Roosevelt Junior, twenty-sixth President of the United States of America and Lieutenant Colonel of the Rough Riders, stands in a grassy field at sunset. He is a stocky and barrel-chested man with a ruddy pink face, grinning broadly with his teeth showing. A thick brown mustache shot with gray spreads across his upper lip, and small round spectacles with gold rims sit on his nose. His pale eyes crease with the grin. He wears a brown felt slouch hat with a dented crown and a wide brim turned up at the sides. His shirt is a dark blue flannel pullover with a standing collar and a short row of buttons at the chest, and an orange neckerchief is knotted at his throat. Tan canvas suspenders run over his shoulders down to khaki trousers. A wide brown leather belt with a brass buckle stamped with an eagle circles his waist. A revolver sits in a leather holster on his right hip. His left hand rests on his belt with the fingers hooked over it, and his right arm hangs at his side. Behind him a broken split-rail fence leans along a dirt track through tall dry grass. Three low houses with steep thatched roofs and wooden walls stand in the middle distance, and palm trees bend in the wind at the far left. The sky is banded orange and purple, brightest low behind the houses.

Sources: fandom trivia says the scene shows three wooden houses in a grassland behind a wooden fence and only guesses at San Juan Hill, so the place is left unnamed. It also names a photograph of Roosevelt in Rough Rider uniform as the model source. The loading screen shows the same pose.

## 69. LEADER_VICTORIA_ALT
Victoria (Age of Steam), England

Alexandrina Victoria of the House of Hanover, Queen of the United Kingdom of Great Britain and Ireland, and Empress of India, stands on the bank of the River Thames in daylight. She is a young woman with pale skin, a round face, and blue eyes, and she wears a small closed-lip smile. Her dark brown hair is swept up under a wide-brimmed hat of gray-green felt, trimmed with a white frilled band and crowned by a large bow of olive-brown silk. She wears a walking dress of the industrial age in gray-green cloth with fine dark pinstripes. Its sleeves are puffed high at the shoulder and narrow to white frilled cuffs at the wrist. A high white ruffled collar closes at her throat, and a white ruffled jabot, a lace frill at the chest, falls down the front of her bodice beneath a green oval brooch. Two black bands frame the frills in a V shape. The fitted bodice ends in a short frilled peplum at the hips, and a long full skirt spreads to the ground. In her left hand she holds an open folding fan of pale pink silk with a band of gold lace at its base. Her right hand is turned palm up at her side in an open gesture. Behind her the gray stone arches of London Bridge span the river, with lamp posts along its parapet. Rowing boats are moored on the near bank at the left, and the dome of St Paul's Cathedral rises above the far bank among chimneys and spires. Black coal smoke drifts across a pale blue sky streaked with orange cloud while haze softens the far bank.

Sources: fandom trivia names London Bridge and the River Thames by day. The dome behind the bridge is not identified there, so it is left unnamed. The loading screen shows her raising the fan in her right hand instead.

## 70. LEADER_WU_ZETIAN
Wu Zetian, China

Wu Zhao, Wu Zetian, Empress of China, stands at night in the grounds of a palace. She is a woman of middle age with a full round face, pale skin, and dark eyes under thin arched brows. Her red lips are pressed together, and her chin is lifted. Her black hair is dressed high in smooth sculpted loops. A gold crown sits across the top of her coiffure, set with red and green stones and worked into a central peak, and two long gold arms curve out from it to either side. From each arm hangs a red stone and a fringe of fine gold chains. A small gold ornament with red drops hangs at the center of her forehead. She wears earrings of red beads and gold, and a wide gold collar set with red stones lies around her throat. Her robe is yellow silk with wide sleeves, patterned with pale flowers. Over it lies a dark blue mantle bordered in red and embroidered in gold with cloud scrolls and a long-tailed bird. A gold sash binds her waist, and a dark skirt below carries a red panel embroidered in gold at the front. Her hands are clasped together at her waist, one cupped in the other. Behind her a tall wooden pavilion with upturned tiered roofs stands on the far side of a bridge, its windows lit yellow and red lanterns hung along its galleries. A great tree spreads across the top of the scene. The light from the windows falls in warm streaks across the ground. The night sky is a deep teal, and clouds glow faintly behind the roofs.

Sources: fandom trivia does not name the palace, so it is described generically, and it names an eighteenth century portrait as the model source. The loading screen shows the same pose.

## 71. LEADER_YONGLE
Yongle, China

Zhu Di, third Emperor of the Ming dynasty of China and Son of Heaven, stands with folded arms before a gate of the Forbidden City. He is a large and heavily built man with tan skin and a broad face. His black eyebrows are drawn down over narrowed dark eyes, and a full black beard covers his chin, with a long mustache curling out to points at either side. He wears a yishanguan, the black gauze winged cap of the Ming emperors, with a gold band around its brim and two stiff wings rising from the back and folding forward. His robe is imperial yellow silk with a round neck, worn over a white and red inner collar. Blue dragons in round medallions are embroidered on the chest and on each shoulder, ringed with red clouds. A red belt studded with gold plaques set with red and green stones circles his waist, and his skirt below is pale gold. A blue bracelet shows at his left wrist. His arms are crossed high on his chest, the hands tucked against his sleeves. Behind him a great hall with a sweeping yellow tiled roof and red columns stands on a high stone wall, lit warm gold from the side. A wooden railing runs along a terrace in front of the wall, and a gnarled pine branch reaches across the hazy sky. A dark tree fills the right side of the scene. The sky fades from gold to gray through warm dusty air.

Sources: fandom trivia names a gate of the Forbidden City and a hanging scroll portrait as the model source. The loading screen shows the same pose.

## 72. LEADER_ALEXANDER
Alexander, Macedon

Alexander III 'the Great', son of Philip II, King of Macedon, Hegemon of the Hellenic League, Pharaoh of Egypt, and King of Persia, stands at night on the terrace of a colonnaded hall high above a bay. He is a young man with a broad athletic build, tan skin, and bare muscular arms. His light brown hair falls loose to his shoulders, parted in the center, and he grins widely with white teeth and bright hazel eyes. He wears a bronze muscle cuirass edged in gold at the neck and hem and set with a small gold sun medallion on the chest. A brown leather baldric runs from his right shoulder across the cuirass to his left hip, where the hilt of a short sword hangs. Below the breastplate a skirt of bronze-studded leather strips falls over a dark blue tunic. A dark band circles his left upper arm. Under his right arm he holds a bronze helmet cast as a lion's head, its open jaws and mane framing the space where the face would sit. His left arm hangs at his side. Behind him a low stone parapet drops away to a wooded slope. The bay curves below in dark blue with a pale beach and calm water reaching to distant headlands. Tall gray columns of the hall rise at his right, and the sky is a deep starry blue. Cool blue night light fills the scene and glimmers on the sea.

Sources: fandom trivia does not name the place, so the terrace and bay are described generically, and it names the Alexander Sarcophagus relief as the model source. The loading screen shows the same pose with the lion helmet under his arm.

## 73. LEADER_AMANITORE
Amanitore, Nubia

Amanitore, Kandake and queen regnant of the Kingdom of Kush in Nubia, stands at night on a grassy floodplain before the Nubian pyramids. She is a short and stout woman with deep brown skin and a round face. She smiles warmly with her lips closed. Her black hair is cropped close to her head in tight curls. A gold diadem circles her brow, centered on a gold disc bearing a red inverted triangle. Large flat gold earrings shaped as triangles hang from her ears. A broad gold collar lies across her chest and shoulders, patterned with a row of triangles and studded with red stones, with gold drops hanging from its lower edge. She wears a long dress of gold satin that leaves her left shoulder bare, its single strap passing over her right shoulder. A wide belt of ribbed gold clasps her waist, and a string of white beads loops from the belt at her hip. Beneath the gold dress a pale gray-green skirt hangs in pleats, its front edge trimmed with a gold zigzag. Wide gold cuffs cover both wrists, and a gold band circles her left upper arm. A red stone ring shows on her left hand. In her right hand she holds a tall gold staff, taller than herself, topped with a red-eyed gold falcon crowned by a sun disc between two tall curving horns. Behind her three pyramids rise steep-sided from the plain, and small stone chapels with carved doorways stand at the foot of the nearer two. Tall grass covers the ground. Dim green-blue light lies over the plain under a dark night sky.

Sources: fandom trivia names a Nubian pyramid on a floodplain and a relief of Amanitore as the model source. The loading screen shows the same pose with the staff.

## 74. LEADER_CYRUS
Cyrus, Persia

Cyrus II 'the Great' of the Achaemenid dynasty, son of Cambyses I, King of Persia, Media, Lydia, and Babylon, and King of Kings, stands at dusk in a walled garden. He is a man of middle age with tan skin and a long face, one eyebrow raised over narrowed gray-green eyes. His dark hair is swept back from his brow in thick waves, and a full dark beard and mustache cover his jaw. A thin gold headband set with a blue stone at the center circles his head as a diadem. He wears a tunic of blue-violet silk with full sleeves, patterned with orange wheel-shaped rosettes. Over it he wears a cuirass of brown leather with a broad yoke across the shoulders, held by bronze fittings at the sides. Two round bronze medallions on the yoke are embossed with the Faravahar, a winged disc with a man's figure rising from it. The cuirass's chest panel is studded with rows of small bronze pyramids. A braided brown leather belt with a gold clasp binds his waist, and a sash of olive-green cloth with a fringe hangs from it at his right hip. Leather bracers with a gold disc cover each forearm. His left hand rests on his hip, and his right arm hangs loose at his side. Behind him the garden is dim and golden brown in the failing light. A long reflecting pool lies between low hedges and lawns, mirroring a sandstone gatehouse with a tall pointed arch and two smaller arches beside it. Date palms rise on the left, and a dark tree with purple leaves stands close on the right. The far edges of the scene fade into shadow.

Sources: the fandom page has no trivia on the scene or the model, so the garden and gatehouse are described generically. The loading screen shows the same pose.

## 75. LEADER_GITARJA
Gitarja, Indonesia

Tribhuwana Wijayatunggadewi, called Gitarja, queen regnant and third Maharani of Majapahit in Java, stands with her hands on her hips in a tropical garden before a stone shrine. She is a young woman with warm brown skin and a broad face. She half smiles with a knowing look. Her eyes are shadowed with dark makeup, and her dark hair is pulled back beneath a tall gold crown. The crown rises to a point in the shape of a tiered helmet, set with red stones and a blue diamond-shaped gem at the front. A white frangipani blossom with a yellow center is tucked above her right ear. Gold drop earrings hang from her ears, and a gold choker with a round pendant circles her throat. Her shoulders and arms are bare. She wears a strapless dress of dark red brocade woven with a fine diamond pattern, its scalloped neckline edged in gold and embroidered with gold leaves at its bodice. A belt of pale pink cloth and red beading circles her waist, fastened by a large gold flower from which gold leaf-shaped pendants hang. A second white frangipani is tucked into the belt at her left side. A wide gold armband is clasped around her right upper arm, and gold bangles ring her left wrist. The dress falls straight to the ground. Behind her the shrine, carved with a figure in relief, stands among tall grass and broad-leaved plants. To the left a temple with stepped stone towers rises among trees, and a large tree with hanging roots leans across the top of the scene through a green haze.

Sources: fandom trivia does not name the place, so the shrine and temple are described generically. It notes the armband on her right arm carries the Firaxis logo and that an artist's sketch inspired the model. The loading screen shows the same pose.

## 76. LEADER_JAYAVARMAN
Jayavarman VII, Khmer

Jayavarman VII of the Varman dynasty, King of the Khmer Empire and lord of Angkor, stands in a hazy green jungle before Angkor Wat, its tapering towers rising out of the mist behind him. He is a stocky middle-aged man with medium brown skin, a soft rounded belly, and a cleanly shaven head. His face is broad and warm, with thick dark eyebrows and deep-set dark eyes, and he smiles widely with his mouth closed. He wears gold ear ornaments, a ribbed gold spool in his right earlobe and a small curved gold hook at his left ear. He is bare-chested. Around his neck sit several tiers of gold chokers. Over his shoulders lies a stiff collar of beige cloth edged in red, set with two gold rosettes and a gold lotus ornament with a pendant hanging from it. A string of gold beads circles his right upper arm. A wide gold cuff with a spiral design covers that wrist. His left wrist wears a chased gold bracelet, and that hand is raised to his chest with the fingers loosely curled. His lower garment is a sampot, a Khmer wrapped cloth, in shimmering gold with a red sash folded over at the hip and knotted with beads. His right arm hangs at his side. Behind him hanging vines loop down from the top of the scene, and dark palm fronds spread across the upper right. Tall tower silhouettes stand in the haze at the left. Below them the temple's reflecting pool lies still among broad-leaved plants. The mist softens everything into a yellow-green light.

Sources: fandom trivia says the scene shows a wat in a jungle and guesses at Angkor Wat; the name is used because the five tapering towers and the reflecting pool in the image are Angkor Wat's classic view; the gallery cites a statue of Jayavarman VII in meditation as the model source. The loading-screen pose matches the idle cut-out and adds no prop.

## 77. LEADER_LUDWIG
Ludwig II, Germany

Ludwig II Otto Friedrich Wilhelm of the House of Wittelsbach, called the Fairy Tale King, King of Bavaria, Count Palatine of the Rhine, Duke of Franconia, and so on, stands on a wooded hillside below Neuschwanstein Castle in daylight. He is a young man with pale skin, blue eyes, and a long straight nose. His dark brown hair is thick and wavy, swept back from his forehead and full over the ears. A thin mustache curls up at its ends, and a small pointed tuft of beard sits on his chin. He wears a dark blue military tunic with a red front panel fastened by a double row of gold buttons, a high red collar edged in gold, and gold epaulettes on the shoulders. A white sash runs from his left shoulder to his right hip, fastened by a gold clasp bearing a crowned monogram. Two order badges hang on his chest, a pale blue and white cross and a cross with a red center. They are the badges of the Royal Order of Saint George for the Defense of the Immaculate Conception and the Order of Saint Hubert. A gold belt with ornamental plates circles his waist. The tunic's sleeves end in gold cuffs. A sword hangs at his left hip in a dark scabbard marked with a gold star, and his left hand rests on its gilt basket hilt. His right arm hangs at his side. Behind him the castle stands white with pointed dark turrets and a tall square tower, half wrapped in mist above forested slopes. A dark leafy branch reaches across the top of the scene, and dark bushes fill the lower left. The sky is pale gray and hazy over blue-gray mountains.

Sources: fandom trivia names Neuschwanstein Castle by day and the two orders worn on his chest, and the gallery cites a photograph of Ludwig II as the model source; which badge belongs to which order is not stated, so the two are listed together. The loading-screen pose matches the idle cut-out.

## 78. LEADER_SEJONG
Sejong, Korea

Yi Do, Sejong 'the Great', fourth King of Joseon, stands in a dim study at night with an open book in his hand. He is a middle-aged man with light skin, a full round face, and dark eyes under straight brows, his closed mouth lifting a little at the corners. A thin black mustache droops past the corners of his mouth, and a long narrow black beard hangs from his chin. He wears the regalia of a Joseon king. On his head sits an ikseongwan, a black silk cap with two stiff wing-like flaps standing up at the back. He also wears a gonryongpo, a red robe embroidered with dragons, with a wide round neckline over a white inner collar. A large round emblem embroidered in gold on the chest shows a coiled dragon among clouds, and the robe's sleeves carry the same gold dragon pattern. A red belt set with green jade plaques in gold mounts circles his waist. His left hand holds an open book upside down, its pages of Korean and Chinese text tilted up toward the front. His right arm is drawn back behind him and hidden in the robe's sleeve. Behind him a wall of latticed windows lets in cold blue-gray light, and rolled bamboo blinds hang above them. A low writing desk stands to the left with a sheet of paper and an oil lamp whose small flame is the only warm light in the room. A potted pine stands in silhouette on the far side of the desk, and a wooden railing runs along the left edge. The right side of the room falls away into darkness. The book is the Hunminjeongeum, the text that introduced the Korean alphabet.

Sources: fandom trivia identifies the book as the Hunminjeongeum Eonhaebon and notes he holds it upside down, which the render is too small to confirm; the gallery cites the standard portrait of Sejong as the model source. The scene location is not documented, so the study is described generically.

## 79. LEADER_SULEIMAN_ALT
Suleiman (Muhteşem), Ottoman

Suleiman I 'the Magnificent', called Kanuni by his subjects, Sultan of the Ottoman Empire, Custodian of the Two Holy Mosques, Caesar of Rome, and so on, stands inside a canopied pavilion whose columned opening looks out on domed buildings at sunset. He is an older man with light brown weathered skin, a lined face, and pale watchful eyes. His full beard and mustache are dark and streaked heavily with gray. A large white turban wound over a gold embroidered band covers his head. A jeweled aigrette, the turban pin, is fixed at its front: an emerald ringed with pearls and blue beads, with a pearl drop and a small emerald hanging below it. He wears a kaftan of blue silk patterned with gold eight-pointed stars and diamond shapes, its short sleeves trimmed in gold. Beneath it a red under-robe shows at the chest and in long sleeves with gold trim at their cuffs. Down the red front runs a column of gold brooches, each set with a green stone, the topmost the largest. A white sash wraps his waist, fastened by a large gold star-shaped buckle set with an emerald and small green stones. His left hand is closed in a fist at his belt, and his right arm is drawn behind his back. A tent canopy with a fringed lower edge stretches across the top of the scene. Behind him at the left, an orange drape is tied back to reveal a row of slender columns and a low balustrade. Through the opening, pale domed pavilions and flat-roofed buildings glow in warm evening light among trees. A dark jug stands on the sandy floor near the drape. To his left the pavilion interior falls into dim brown shadow, and a dark reddish wall closes the far edge. The only strong light comes from the opening behind him, so the interior is warm and dim.

Sources: the fandom page for the Muhteşem persona documents no scene location, so the pavilion is described generically; its gallery cites a portrait of Suleiman as the model source. The loading-screen pose matches the idle cut-out and adds no prop.

## 80. LEADER_SUNDIATA_KEITA
Sundiata Keita, Mali

Sundiata Keita, also called Mari Djata and the Lion of Mali, first Mansa or emperor of Mali, stands on sandy ground before the University of Sankoré in daylight. He is a young man with dark brown skin, a strong jaw, and a short black beard and mustache. His pale gray eyes look straight ahead under level black brows above a closed mouth. A purple turban wrapped with bands of gold covers his head, and over it sits a gold crown with pointed spikes tipped with red balls and set with red stones. He wears a purple tunic with a gold-edged neckline. Over it lies a loose robe of lilac blue patterned with orange-gold scrolls and bordered with a wide band of gold brocade. A short necklace of brown beads with red and teal stones holds a red pendant at his throat. A longer chain of gold links and red and blue beads crosses his chest and carries a gold disc stamped with a star. The chain drops to a brown leather pouch at his waist, mounted in gold and set with a red stone. In his left hand he holds a tall gold staff whose head is a disc set with a red stone at the center and blue stones around it, topped with a small diamond finial. His right arm hangs at his side. Behind him the university rises as a mud-brick mosque with tapered walls, pyramidal towers, and rows of wooden beams jutting from the walls. A dark acacia tree spreads flat over the scene from the left, and tufts of dry grass and scrub dot the sand. Pale clouds drift in a blue sky above buildings softened by a dusty haze.

Sources: fandom trivia names the University of Sankoré by day as the scene; no model source is documented. The loading-screen pose matches the idle cut-out, staff included.

## 81. LEADER_THEODORA
Theodora, Byzantium

Theodora, Augusta and Empress consort of Byzantium, stands beside a dark column on a waterfront at sunset. She is a slender woman with very pale skin, a long oval face, and gray-blue eyes under thin arched brows. Her cheeks are tinted pink and her lips are pale. Her dark brown hair is drawn up in smooth wide rolls around her head. On top sits a tall gold crown edged with rows of pearls and set with green and red stones, its points tipped with blue finials. Long earrings of gold set with red stones and blue drops hang from her ears. A broad gold collar covers her shoulders, edged in pearls and set with green and red stones, with pearl pendants hanging from its lower edge. She wears a plain gown of pale mint green with long sleeves. A gold band embroidered with a dark scroll pattern runs down the front from the collar to the hem, and a gold belt set with a green stone circles her waist. Gold cuffs finish the sleeves. Her right hand crosses her body to rest at the belt, and her left arm hangs at her side. Behind her the Hagia Sophia rises across the water with its great central dome and half domes, shown without the minarets added after the Ottoman conquest, its stone glowing orange in the evening light. The building and a dark spire are reflected in the still water in front of it. The sky is banded with orange light and heavy dark clouds. The face, crown, and collar are modeled on the mosaic of Theodora in the Basilica of San Vitale.

Sources: fandom trivia names the Hagia Sophia without its later minarets as the scene, and the gallery cites the San Vitale mosaic as the model source. The loading-screen pose matches the idle cut-out and adds no prop.

## 82. LEADER_KUBLAI_KHAN_MONGOLIA
Kublai Khan, Mongolia

Kublai Khan of the Borjigin clan, Great Khan of the Mongol Empire and Emperor of China, stands on an open steppe. He is a heavy, broad-chested man in late middle age with light tan skin, a round face, and narrow dark eyes under thin arched brows. His gray hair is swept back from his forehead and hangs to his collar. A long gray mustache curls out past the corners of his mouth, and a full gray beard falls in two soft points onto his chest. A small gold earring hangs from his right ear. He wears a golden yellow silk robe embroidered with gold scrollwork on the shoulders and chest, closed by a wide collar of thick brown fur that crosses from his left shoulder down to his right hip. Dark brown cuffs edged in orange cover his forearms. A dark leather belt with a heavy rectangular bronze buckle cinches his waist, with a sheathed knife on the right hip and a small bronze-capped flask on the left. His hands are clasped in front of his stomach with the fingers laced together. The scene is painted in loose brown and gold strokes. A river, pale in the light, curves through low grass past a rocky outcrop, with tufts of dry reeds at the front and dark hills rising behind. Two eagles soar in a hazy sky over the hills, and a dull golden light spreads through the mist across the plain.

Sources: fandom trivia names the scene as a steppe with a river and soaring eagles and notes the orange velvet robe with fur lining, and the gallery cites a Yuan dynasty painting of Kublai as the model source. The earring shows in the loading-screen render.
