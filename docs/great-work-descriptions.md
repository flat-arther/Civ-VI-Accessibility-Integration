# Great Works - spoken image descriptions

Authoring source for the image descriptions the Great Work Showcase appends
after the title, creator, date, and place. Edit here, then run
`scripts/Build-GreatWorkDescriptions.py` to regenerate
`src/Text/en_US/GreatworkDescStrings_CAI.xml` (`--check` verifies it is up to
date); the other language files are translated from the final English. Lint
every language with `scripts/Lint-GreatWorkDescriptions.py` before shipping.

Keys are the vanilla `GreatWorkType` for paintings, sculptures, and relics
(`LOC_CAI_GWDESC_GREATWORK_<TYPE>`), the object type for the shared writing
and music backgrounds (`LOC_CAI_GWDESC_GREATWORKOBJECT_WRITING`, `_MUSIC`),
and the texture index for the twenty-five artifact images
(`LOC_CAI_GWDESC_ARTIFACT_<1-25>`; artifact N shows texture `((N-1) mod 25)+1`).
The DLC schemes (hero symbols and epics, Secret Societies relics, Monopolies
products) are listed under Image sources. `GreatWorkShowcase_CAI.lua`
resolves the key in `GetDescriptionTag()`.

## Rules

What to describe:

- Describe the real artwork, identified by the vanilla title and artist. The
  game's image only confirms the version and crop. Describe what the game
  shows and nothing it leaves out.
- Name the subject: the sitter, the saint, the story, the place shown or the
  building the work was made for. "King Philip II of Spain", not "the Spanish
  king". Never say where a work hangs today; in the game it was made in the
  player's city.
- Add a documented fact where it helps, such as the sisters' names or the
  manuscript a page comes from. Every detail must be true of the real work.
  When unsure, leave it out.
- Do not restate the title, the date, or the city of creation; the showcase
  speaks those. The artist's name is fine where it reads better than "the
  artist".
- Prefer the details that make this work recognizable over generic features
  of its type.

Shape of an artwork entry:

- Sentence one: "This portrait is..." names the medium and the artist's real
  tradition, with a fame hook only for genuinely iconic works. Sentences two
  and three give the scene, most important element first. An optional fourth
  gives the look: color, light, material, scale, or condition.
- Three sentences is the target, four the maximum. Forty to eighty words as a
  guide; a known fact is never cut to fit.
- For scrolls, triptychs, and screens, say what the format is. For sculpture,
  give material, scale, pose, and viewpoint; the game shows every statue as a
  cut-out with no pedestal or setting, so describe the statue only.

Simple objects (artifacts, relics, hero symbols, products, backgrounds):

- Open with the object itself: "A mummified cat stands upright." Never "This
  artifact is", and never mention that the image is shared. One to three
  sentences, ten to sixty words.

Grammar and punctuation:

- Every sentence has a subject and a verb. Artwork entries open with "This"
  or "These" plus the medium noun, never a bare "This is".
- A modifier that belongs to the work, such as its alternate title or how the
  game crops it, goes right after the opening noun: "This painting, also
  titled Moscow I, is...". Never let it dangle after another noun.
- Present tense, third person. No "you" or "the viewer".
- One idea per sentence. No semicolons, dashes, parentheses, ellipses, or
  slashes. At most one colon, and it introduces a list. A sentence with more
  than three commas is split.
- At most one comparison, and no stacked hedges such as "almost seems".
- No evaluative adjectives beyond the fame hook.
- American spelling, numbers under ten spelled out, no abbreviations or
  all-caps words, plain ASCII, and a closing period.

Process:

- Write from a high-resolution reference, then check the in-game image for
  crop and version. Translate from the final English, keeping the sentence
  count. Lint every language before shipping.

## Image sources

The game's textures live in `UI_GreatWorksArt.blp` under each ruleset's
`Platforms/Windows/BLPs/UI/` folder (base, Babylon, PolandScenario). Extract
them with `scripts/Extract-GreatWorksBlp.py <file.blp> <outdir>` (Python 3
with Pillow). They are painted at display size, about 483 pixels tall, with
the paintings inside gold frames and the sculptures as cut-outs. Writing and
music works all display one background each. Artifacts cycle through
twenty-five images. Relics have one image each and are keyed by type like the
paintings.

Heroes and Legends works are 256 pixel icons from `Heroes_GreatWorks256` in
the Babylon `Icons.blp`: one per hero symbol, keyed
`LOC_CAI_GWDESC_GREATWORK_HERO_SYMBOL_<HERO>`, and one shared image for every
hero epic, keyed `LOC_CAI_GWDESC_GREATWORK_HERO_EPIC`. Secret Societies relics
25 to 48 share three icons from `GreatWorksSTK256` in the Ethiopia
`Icons.blp`, keyed `LOC_CAI_GWDESC_VOIDSINGER_RELIC_<1-3>` for relics 25 to
32, 33 to 40, and 41 to 48. Monopolies and Corporations products are drawn
with their resource's icon from `Monopolies_Resources256` in the Vietnam and
Kublai Khan pack `Icons.blp`, one per resource shared by its five products,
keyed `LOC_CAI_GWDESC_PRODUCT_<RESOURCE>`.

---

## 1. GREATWORK_ANGUISSOLA_1
Three Sisters Playing Chess, by Sofonisba Anguissola

This painting is an Italian Renaissance oil of Anguissola's three younger sisters gathered around a chessboard on a carpeted table outdoors, with hazy hills behind. Lucia, the eldest, sits at the left and has just taken a piece, looking calmly outward. Minerva at the right raises her hand in protest, and the youngest, Europa, grins at her reaction from the middle. An elderly maidservant leans in from the right to watch.

Game image: the game shows the full painting. Sisters identified from the Wikipedia article on the artist as Lucia, Minerva, and Europa with a servant, 1555, Poznan.

## 2. GREATWORK_ANGUISSOLA_2
Philip II of Spain, by Sofonisba Anguissola

This portrait is an oil of King Philip II of Spain shown from the hips up against a plain gray background. He wears a tall black cap, a black doublet and cloak, and a white lace ruff, with the Golden Fleece hanging on a thin chain at his chest. His pale face and trimmed fair beard hold a level, guarded expression. One hand rests on the arm of a red chair while the other holds a string of rosary beads.

Game image: the game shows the full painting, Prado version. Rosary and Golden Fleece confirmed from the image.

## 3. GREATWORK_ANGUISSOLA_3
A Monk, by Sofonisba Anguissola

This portrait is a Renaissance oil of a young monk standing before a nearly black background. He wears a pale cream habit with a heavy cowl draped over his shoulders and a cord tied at the waist. His head is close-shaven, his face is calm and youthful, and he gazes off to the right rather than at the painter. His hands are clasped in front of him, and a long rosary with a small cross hangs down from them.

Game image: full painting shown. The sitter and his order are not identified in the sources found, so the habit is described by color only.

## 4. GREATWORK_BEHZAD_1
Battleground of Timur and Egyptian King, by Kamal ud-Din Behzad

This miniature is a Persian manuscript page from a chronicle of Timur's conquests, with panels of calligraphy above and below. A crowded cavalry battle between Timur's army and the forces of the Egyptian sultan fills the page, as horsemen in red, blue, and gold armor charge with lances and bows across a green ground broken by rocks and small orange trees. Trumpeters and drummers ride along the top beneath a blue sky, and banners rise on both sides. Fallen men and horses lie in the lower corners.

Game image: full page shown including text panels. Folio from a Timurid Zafarnama; attribution to Behzad follows the game.

## 5. GREATWORK_BEHZAD_2
Yusef and Zuleykha, by Kamal ud-Din Behzad

This miniature is a Persian manuscript page from Sa'di's Bustan, illustrating the story of Yusuf and Zulaikha, the Persian telling of Joseph and Potiphar's wife. The palace rises as a tall stack of flat rooms and staircases, every surface covered in blue tilework and bands of calligraphy. In a chamber near the top, Zulaikha in orange lunges from her couch to seize the cloak of Yusuf in green, who twists away with a flaming halo around his head. The figures are tiny against the dazzling architecture.

Game image: full page shown. From the Bustan of Sa'di, 1488, Herat, per the Commons file description.

## 6. GREATWORK_BEHZAD_3
Timur Granting Audience on the Occasion of His Accession, by Kamal ud-Din Behzad

This miniature is a Persian manuscript page of a royal audience held in a garden, on a dark green ground scattered with flowers. Timur sits cross-legged on a low throne beneath a domed tent of blue and white, in a pale green robe and crown. Courtiers in colored robes stand around him while attendants wait below. At the upper left two men sit beside a leashed hunting cheetah, and a flowering tree rises behind the tent.

Game image: full page shown. The animal at the upper left is read from the image as a hunting cheetah and was not verified in text.

## 7. GREATWORK_BOSCH_1
The Garden of Earthly Delights, by Hieronymus Bosch

This triptych is a Netherlandish oil on three joined wooden panels, teeming with hundreds of tiny figures. The left panel shows a green paradise where God presents Eve to Adam beside a pink fountain. The center panel is a bright garden where crowds of nude figures frolic among giant fruits and strange pink structures. The dark right panel is hell, lit by a burning city, where a hollow tree man and a bird-headed monster preside over torments.

Game image: the game shows all three panels open. Prado, about 1490 to 1510.

## 8. GREATWORK_BOSCH_2
The Last Judgement, by Hieronymus Bosch

This triptych is a Netherlandish oil with Eden on the left, judgment in the center, and hell on the right. On the left Eve is created, tempted, and driven out, while rebel angels fall from a glowing God above. In the center Christ sits in a small patch of blue sky, and below him a dark scorched landscape swarms with demons roasting, spearing, and torturing the damned. The right panel is a burning hellscape ruled by devils.

Game image: the game shows the Vienna triptych, all three panels. Academy of Fine Arts Vienna, about 1482.

## 9. GREATWORK_BOSCH_3
The Haywain Triptych, by Hieronymus Bosch

This triptych is a Netherlandish oil built around a single image: an enormous hay wagon rolling toward hell. In the center panel a crowd of popes, kings, and peasants scramble for hay while demons drag the wagon forward and lovers make music on top beneath a small Christ in the clouds. The left panel shows the creation and expulsion of Adam and Eve, and the right panel shows a burning hell where devils build a tower.

Game image: the game shows all three panels, Prado version, about 1516.

## 10. GREATWORK_CASSATT_1
Lydia Leaning on Her Arms, by Mary Cassatt

This pastel, drawn in loose glowing strokes of yellow and green, is an Impressionist study of Cassatt's sister Lydia seated in a theater box. She leans forward with her folded arms resting on the plush red ledge, her bare shoulders rising from a pale evening gown. Her reddish hair is pinned up, and she turns her head to the side with a faint smile. A blazing chandelier and a mirror hang in the upper corner behind her.

Game image: full work shown. Pastel of 1879, sitter is the artist's sister.

## 11. GREATWORK_CASSATT_2
The Child's Bath, by Mary Cassatt

This painting is an Impressionist oil of a mother and child seen from above. The woman wears a dress of green, pink, and white stripes and holds a naked toddler on her lap, one arm around the child while her other hand washes its feet in a white basin. The child, wrapped in a white towel, looks down at the water with her. A flowered pitcher and a patterned carpet fill the surrounding space.

Game image: full painting shown. Art Institute of Chicago, 1893, overhead viewpoint confirmed by the Wikipedia article.

## 12. GREATWORK_CASSATT_3
The Cup of Tea, by Mary Cassatt

This painting, worked in quick brushstrokes, is an Impressionist oil of Cassatt's sister Lydia taking tea in a bright room. She sits in profile in a dark striped armchair, dressed in a pink gown and bonnet with white fur trim at the collar. Her gloved hands lift a cup and saucer edged in gold toward her lips. Behind her a green planter holds white hyacinths against a pale wall.

Game image: full painting shown. Metropolitan Museum, about 1880, sitter is the artist's sister.

## 13. GREATWORK_COLLOT_1
Portrait of Pierre-Etienne Falconet, by Marie-Anne Collot

This bust is a plaster portrait of the painter Pierre-Etienne Falconet, Collot's husband, cut off below the shoulders and set on a round black base. His hair falls loosely to his ears, and he wears an open shirt collar beneath a simply folded coat. The head turns a little to one side with a direct, slightly wary gaze, and the modeling is soft and lifelike.

Game image: cut-out illustration of the bust alone. Plaster, Nancy Museum of Fine Arts, about 1770.

## 14. GREATWORK_COLLOT_2
Portrait of Catherine II, by Marie-Anne Collot

This bust is carved in white marble and shows Catherine the Great of Russia in profile facing left. Her hair is drawn smoothly back from her forehead, and a long veil falls from the crown of her head down over her shoulders in loose folds. The face is composed and slightly smiling, with a firm chin and a straight nose. The bust ends below the shoulders and rests on a small round socle.

Game image: the game shows a side view photograph of the Hermitage marble of 1769.

## 15. GREATWORK_COLLOT_3
Portrait of Marie Cathcart, by Marie-Anne Collot

This bust is carved in white marble and shows Mary Cathcart, daughter of the British ambassador to Russia, with her head turned slightly to one side. Her hair is drawn back beneath a light head covering that falls behind her shoulders, and her calm face carries a small, private smile. The bust ends in a plain curved chest above a round socle, and the carving is smooth and delicate.

Game image: cut-out illustration of the bust alone, front view.

## 16. GREATWORK_DONATELLO_1
St. Mark, by Donatello

This statue, carved for a niche on the Orsanmichele church in Florence, is an early Italian Renaissance marble figure of Saint Mark the Evangelist, shown standing alone. He wears a long draped robe that falls in deep folds and rests his weight on one leg, holding a closed book against his hip. His face is grave and thoughtful beneath a high forehead, and the statue stands on a plain low base.

Game image: cut-out illustration of the statue alone, without the Orsanmichele niche.

## 17. GREATWORK_DONATELLO_2
Equestrian statue of Gattamelata, by Donatello

This statue, shown here without its pedestal, is a bronze equestrian monument of Erasmo da Narni, the mercenary captain nicknamed Gattamelata. The armored commander sits calmly astride a heavy warhorse that walks forward with one front hoof raised. He holds a baton of command out in his right hand and wears a long sword at his side. It is the first large bronze equestrian monument cast since ancient Rome.

Game image: cut-out illustration of horse and rider alone, without the Padua square.

## 18. GREATWORK_DONATELLO_3
Judith Slaying Holofernes, by Donatello

This statue is a bronze group of Judith at the moment of her killing, standing on a dark square base. The veiled heroine in heavy robes stands over the drunken Assyrian general Holofernes, who has slumped onto a cushion at her feet, one of his legs dangling limply. She grips his hair with one hand and raises a curved sword high in the other, ready to strike. The dark weathered bronze makes the figures stern and monumental.

Game image: cut-out illustration of the group on its base, seen from slightly below.

## 19. GREATWORK_EOP_1
Samin munnyeondo, by Jang Seung-eop

This painting is a tall, narrow Korean hanging scroll in ink and light color, illustrating a Chinese tale of three old men who each boast of being the oldest. The three white-bearded elders in blue and orange robes stand talking beside a small deer on a rocky ledge above a sea of swirling clouds. Craggy blue-tinted peaks rise behind them, a pine tree spreads beneath the ledge, and a tiny pavilion sits far below at the lower left.

Game image: Game image is the full scroll, identical to the Commons file. The tale is the Chinese "three old men asking about age" anecdote, verified against the Korean title.

## 20. GREATWORK_EOP_2
Rooster, by Jang Seung-eop

This painting is a detail from a tall Korean hanging scroll in ink and color on silk. A proud rooster stands in profile with a bright red comb and wattles, golden-brown neck feathers, and a long sweeping tail of glossy black plumes. A pale hen stands beneath him, and a small spider dangles on its thread from an ink-washed rock at the upper left. The brushwork is quick and lively against the bare tan silk.

Game image: The game crops the lower third of the scroll to the birds. The full scroll has rocks and flowering plants above and an inscription at the lower left, not shown.

## 21. GREATWORK_EOP_3
Ssangma inmuldo, by Jang Seung-eop

This painting is the lower half of a tall Korean hanging scroll in ink and color on silk. A stout, smiling groom with a beard, a black cap, and a gray-blue robe stands between two horses and grips the bridle of one. The nearer horse is a stocky tan pony patched with white, and a darker, shaggier horse waits behind him at the left. The animals have thick, solid bodies against the plain tan silk.

Game image: The game crops to the figure and horses. The full scroll has a bare, gnarled tree and a long inscription above, not shown.

## 22. GREATWORK_GIL_1
Three Girls, by Amrita Sher-Gil

This painting is a modern Indian oil of three young women seated close together against a bare brown wall. The girl at the left is wrapped in a pale green shawl, the one behind in orange-red, and the one at the right in deep crimson, their black hair drawn back beneath their coverings. All three look down and away with quiet, resigned faces, hands resting in their laps. The figures are simplified into broad flat areas of strong color.

Game image: Full painting shown. none unverified.

## 23. GREATWORK_GIL_2
Bride's Toilet, by Amrita Sher-Gil

This painting, in warm earthy browns and reds, is a modern Indian oil of a young bride being made ready on her wedding day. The pale, bare-shouldered bride sits at the center with her black hair loose, while a woman at the left combs it and another at the right in a green blouse holds out a small bowl. Two children look on, and two red clay pots stand on the floor. The rounded, simplified figures recall Indian wall painting.

Game image: Full painting shown. none unverified.

## 24. GREATWORK_GIL_3
Self Portrait, by Amrita Sher-Gil

This self-portrait is a modern oil of Amrita Sher-Gil at about eighteen, shown from the waist up in strict profile facing left. She wears a bright yellow beret over dark hair, a hoop earring, red lipstick, and a dark blue dress with a deep neckline. She leans on a table with a small brass bowl beside her hand. The background is a mottled wash of gray, blue, and green brushstrokes, and her expression is cool and self-possessed.

Game image: The game uses the untitled 1931 self-portrait in a yellow beret, matched against the Commons file. Several other self-portraits exist.

## 25. GREATWORK_GOGH_1
Starry Night, by Vincent van Gogh

This painting is a Post-Impressionist oil made during van Gogh's stay in the asylum at Saint-Remy in southern France, and it is one of the most recognized images in modern art. A churning night sky fills most of the canvas: stars blaze inside rings of light, a spiral current rolls through the middle, and a yellow moon glows at the upper right. A dark cypress flames up the left edge, and a small village with a pointed church steeple sleeps beneath the hills. Every form is built from thick, curling strokes of blue and yellow.

Game image: Full painting shown. none unverified.

## 26. GREATWORK_GOGH_2
Cafe Terrace at Night, by Vincent van Gogh

This painting is a Post-Impressionist oil of a cafe terrace on the Place du Forum in Arles at night, lit from within by a glowing yellow awning and lamp. Small figures sit at round tables beneath the awning while a waiter in white stands among them, and a few people stroll down the dark blue street beyond. Above the rooftops the deep blue sky is scattered with large yellow stars. The painting uses no black at all, only warm yellows against cool blues.

Game image: Full painting shown. none unverified.

## 27. GREATWORK_GOGH_3
The Night Cafe, by Vincent van Gogh

This painting is a Post-Impressionist oil of the inside of the Cafe de la Gare, a late-night cafe in Arles, in harsh clashing colors. Blood red walls and a green ceiling press down on a yellow wooden floor, and four hanging lamps blaze with halos of swirling yellow strokes. A green billiard table dominates the center, with the owner standing beside it in a pale suit, while a few customers slump at tables along the walls. A clock on the back wall reads past midnight.

Game image: Full painting shown. none unverified.

## 28. GREATWORK_GRECO_1
Adoration of the Magi, by El Greco

This panel, painted in a bright Venetian manner while El Greco still worked in Crete, is a small early work in tempera. The Virgin sits between tall columns with the Christ Child on her lap, while three kings gather before her: one kneels in gold to take the child's hand, one leans in with a chalice, and a dark-skinned king in a red cloak bows at the right. Behind them a camel with its rider and a horse wait beneath a cloudy sky.

Game image: The game uses the Benaki Museum version of about 1565 to 1567, tempera on wood, 40 by 45 cm, matched to the in-game image. none unverified.

## 29. GREATWORK_GRECO_2
The Assumption of the Virgin, by El Greco

This altarpiece, painted for the church of Santo Domingo el Antiguo in Toledo, is a tall Spanish Renaissance oil four meters high, showing the Virgin carried up to heaven. In the upper half she rises on a pale crescent moon with arms outstretched, wearing a red gown and a billowing blue mantle among angels and winged cherub heads. Below, the twelve apostles crowd around her empty stone tomb, gesturing upward in astonishment. The figures are elongated and the colors cold and luminous.

Game image: Game uses the 1577 Art Institute of Chicago altarpiece, full image. Height 401 cm verified from memory of the museum record only.

## 30. GREATWORK_GRECO_3
View of Toledo, by El Greco

This painting is a Spanish Renaissance oil, one of the earliest pure landscapes in Western art and one of the darkest. The Spanish city of Toledo rises on its hill of gray stone at the right beneath a violent storm sky, its cathedral spire and the Alcazar fortress lit by an eerie white light. Green hills roll down to a river crossed by an arched bridge, with small buildings scattered along the banks. The whole scene is painted in deep greens, blue-blacks, and cold whites.

Game image: Full painting shown. none unverified.

## 31. GREATWORK_HOKUSAI_1
The Great Wave off Kanagawa, by Katsushika Hokusai

This print belongs to the Thirty-six Views of Mount Fuji series and is the most famous image in Japanese art. An enormous deep-blue wave rears up on the left and curls over the whole scene, its crest breaking into claw-like fingers of white foam. Three long open boats full of rowers ride the troughs beneath it. Far in the distance, small at the center, sits the snow-capped cone of Mount Fuji.

Game image: The game uses the full print with the title cartouche at the upper left, matching the Metropolitan Museum impression.

## 32. GREATWORK_HOKUSAI_2
Lake Suwa in Shinano Province, by Katsushika Hokusai

This print is a Japanese woodblock view of Lake Suwa at dawn in soft blues and greens and pink. Two tall pines with dark twisted branches rise from a rocky point in the foreground, sheltering a small thatched shrine with a straw roof. Beyond them the pale lake stretches to a shoreline of villages and blue hills. A tiny sailboat crosses the water on the left, and the white peak of Mount Fuji shows on the far horizon.

Game image: Full print with cartouche. From the same Thirty-six Views series.

## 33. GREATWORK_HOKUSAI_3
Fine Wind, Clear Morning, by Katsushika Hokusai

This print, often called Red Fuji, is a Japanese woodblock view of Mount Fuji glowing red in early autumn light. The mountain rises as a broad smooth cone across the right two-thirds of the picture, its slope a warm reddish-brown with streaks of white snow clinging to the summit. A band of dark green forest runs along its base. Rows of small white clouds lie in flat streaks across a deep blue sky.

Game image: Full print with cartouche. The nickname Red Fuji is in the description because the game title does not include it.

## 34. GREATWORK_KANDINSKY_1
Composition 8, by Wassily Kandinsky

This painting, made while Kandinsky taught at the Bauhaus, is an abstract oil with no recognizable objects, built entirely from geometry. Circles, triangles, checkerboards, and long straight lines float and cross over a pale cream ground. A large black and violet circle with a red halo at the upper left is the heaviest shape, balanced by a red disk beside it and small blue and yellow circles below. The colors are clean and bright, and the shapes seem to hang weightless in space.

Game image: Full canvas, Guggenheim version. none unverified.

## 35. GREATWORK_KANDINSKY_2
Blue Rider, by Wassily Kandinsky

This painting is an early oil from before Kandinsky turned to abstraction, and it later gave its name to the Blue Rider group he founded in Munich. A small rider in a blue cloak gallops on a white horse across a rolling green meadow, leaning forward with the motion. Autumn trees in rust and gold stand on the hilltop behind, under a blue sky with two white clouds. The paint is laid on in thick dabs, so the field shimmers rather than sits still.

Game image: The 1903 painting in a private collection, full canvas, is the version shown.

## 36. GREATWORK_KANDINSKY_3
Red Square, by Wassily Kandinsky

This painting, also titled Moscow I, is a near abstract oil of Moscow, Kandinsky's home city. Colored fragments of the city tumble around a glowing center: a white palace with dark windows, red and green onion domes, a rainbow, and a walking couple painted as tiny figures. Flocks of small black birds scatter across a sky of blue, pink, and yellow. The whole scene tilts and spins as if the city were seen in a dream.

Game image: The game image is Moscow I from 1916, shown at full extent. The alternate title Moscow I is included because the game title alone is ambiguous.

## 37. GREATWORK_KAUFFMAN_1
Anna Maria Jenkins and Thomas Jenkins, by Angelica Kauffman

This portrait, set in wooded countryside outside Rome, is a Neoclassical oil of Anna Maria Jenkins and her uncle Thomas Jenkins, an art dealer in the city. She stands at the left in a flowing white gown with a pink sash and a wide white hat, holding up a spray of white convolvulus. He sits beside her against a tree in a dark coat and pale breeches, lifting his hat in one hand and patting a black-and-white dog with the other. Distant hills and the Colosseum fill the background.

Game image: Full canvas, National Portrait Gallery, London. The building at right is usually identified as the Colosseum, so the text says a Roman building rather than naming it.

## 38. GREATWORK_KAUFFMAN_2
Portrait of Johann Joachim Winckelmann, by Angelica Kauffman

This portrait is a Neoclassical oil of Johann Joachim Winckelmann, the German scholar who founded modern art history. He sits at a table in a loose gray coat and a mustard-yellow scarf, his hands folded over an open book and a quill pen held loosely between his fingers. His head turns to the side as if a thought has just interrupted his writing. Warm light falls on his face and hands out of a plain dark background.

Game image: Full canvas, Kunsthaus Zurich, 1764.

## 39. GREATWORK_KAUFFMAN_3
Sarah Harrop as a Muse, by Angelica Kauffman

This portrait is a Neoclassical oil of the English singer Sarah Harrop posed as the muse of lyric poetry. She sits in a rose-pink gown with a green scarf over her shoulders and a wreath of small flowers in her powdered hair, looking calmly out of the picture. One arm rests on a gilded lyre while her other hand holds a rolled sheet of music. A stormy sky and a dark wooded cliff with a waterfall fill the background.

Game image: Full canvas. The sitter later became Mrs Joah Bates.

## 40. GREATWORK_KLIMT_1
The Kiss, by Gustav Klimt

This painting, Klimt's most famous work, is a Viennese Art Nouveau oil layered with gold leaf. A couple kneels in an embrace on a flowered meadow, the man bending to kiss the woman's cheek as she tilts her face up with closed eyes. Their bodies merge into a single golden cloak, patterned with black-and-white rectangles on his side and bright colored circles on hers. Behind them lies a flat shimmering ground of gold.

Game image: Full square canvas, Belvedere, Vienna.

## 41. GREATWORK_KLIMT_2
Avenue in the Park of Schloss Kammer, by Gustav Klimt

This painting is a square oil landscape of the tree-lined avenue leading to Schloss Kammer, a country house on the Attersee in Austria. Tall trees with twisting blue-gray trunks line both sides of a paved path and meet overhead, so that a dense canopy of green leaves fills almost the whole picture. At the end of the avenue stands the yellow house with its red roof. The foliage is painted in thousands of tiny dabs of green, blue, and yellow.

Game image: Full canvas, Belvedere, Vienna.

## 42. GREATWORK_KLIMT_3
Farm Garden with Sunflowers, by Gustav Klimt

This painting is a square oil of a cottage garden so crowded with flowers that no ground shows through. Tall sunflowers with broad gray-green leaves rise on the right, their yellow heads nodding at the top. Below and around them spread masses of red, pink, and blue blossoms, scattered across the green like confetti. The picture has no sky and no horizon, only flowers from edge to edge.

Game image: Full canvas, Belvedere, Vienna.

## 43. GREATWORK_KOBER_1
Portrait of Anna Maria Vasa, by Martin Kober

This portrait is a Renaissance court oil of Anna Maria Vasa, a three-year-old Polish and Swedish princess, standing stiffly before a red curtain. She wears a silvery-white gown with red and gold embroidery, a tall white ruff, a jeweled cap on her fair hair, and a heavy gold cross set with gems on a chain. One tiny hand holds a folded handkerchief. Latin inscriptions in the upper corners give her name, her titles, and her age.

Game image: Full panel. The inscription gives the year 1596 and her age as three.

## 44. GREATWORK_KOBER_2
King Sigismund III, by Martin Kober

This portrait is a Renaissance state oil of Sigismund III Vasa, king of Poland and Sweden, shown from the knees up. He stands in a black doublet and a tall spiky white ruff, a black cap with jeweled badges on his head, and a spotted lynx fur cloak draped over his shoulders. One hand rests on a red-covered table while the other holds the hilt of a sword. A red curtain hangs behind him on the left against a dark background.

Game image: Full canvas, Bavarian State Painting Collections.

## 45. GREATWORK_KOBER_3
Portrait of Queen Anna Jagiellon, by Martin Kober

This portrait is a Renaissance oil of Anna Jagiellon, the elderly queen of Poland, in widow's dress. She stands in a plain black gown under a long white veil that falls from her head to below her waist, with a white band across her chin and throat. A gold cross hangs on a long chain at her breast, and she holds a small book in one hand. A green and gold brocade curtain is drawn back at the upper right.

Game image: Full canvas, Wawel Royal Castle, painted in 1595.

## 46. GREATWORK_LEWIS_1
The Death of Cleopatra, by Edmonia Lewis

This statue is a life-size white marble figure of Cleopatra in the moment after her death. She sits on a throne whose armrests are carved as sphinx heads, her body slumped back and her head fallen to one side with the eyes closed. She wears a pleated gown that leaves one breast bare and a royal headdress with a cobra at the brow. One hand rests limply in her lap while the other hangs over the arm of the throne.

Game image: cut-out illustration of the whole statue, front view.

## 47. GREATWORK_LEWIS_2
Marriage of Hiawatha and Minnehaha, by Edmonia Lewis

This sculpture is a small white marble group of Hiawatha and Minnehaha, the young Native American couple from Longfellow's poem, standing side by side. The man wears a feathered headdress and a fringed tunic, and the woman wears a headband and a draped shawl over a short dress. They clasp hands at the center and turn their faces toward each other with quiet smiles. The figures stand on a round base.

Game image: cut-out illustration of the group, front view.

## 48. GREATWORK_LEWIS_3
Hagar, by Edmonia Lewis

This statue is a white marble figure of the biblical servant Hagar alone in the wilderness after her banishment. She stands with her hands clasped tightly at her chest and her face lifted upward in prayer, her long hair falling loose over her shoulders. Her gown slips from one shoulder and drapes in heavy folds to her bare feet. An overturned water jug lies empty on the base beside her foot.

Game image: game image is a full-length museum photo against a gray background, front view.

## 49. GREATWORK_MICHELANGELO_1
Sistine Chapel Ceiling, by Michelangelo

This fresco is the Creation of Adam, the best-known panel of the Sistine Chapel ceiling in the Vatican. On the left a nude Adam reclines on a green bank with one arm stretched out limply toward the right. God, an old bearded figure in a pale robe, sweeps in from the right inside a swirling red cloak crowded with angels, and reaches out with his forefinger. The two fingertips almost touch at the center of the picture.

Game image: game image shows only the Creation of Adam panel, wide crop, not the whole ceiling.

## 50. GREATWORK_MICHELANGELO_2
David, by Michelangelo

This statue is a colossal white marble figure of David, over five meters tall, nude and alert before his fight with Goliath. He stands with his weight on the right leg, the head turned sharply to his left with a frowning, watchful gaze. A sling rests over his left shoulder and the stone sits in his lowered right hand. The figure stands alone on a low plain base.

Game image: cut-out illustration of the full statue in color, front view.

## 51. GREATWORK_MICHELANGELO_3
Pieta, by Michelangelo

This sculpture is a white marble group of the Virgin Mary seated with the dead body of Christ lying across her lap. She is a young woman with her head bowed, one hand supporting his shoulders while the other opens outward in a gesture of acceptance. Her robes spill in deep folds that support his limp, near-naked figure.

Game image: cut-out illustration of the group alone, front view.

## 52. GREATWORK_MONET_1
Water Lilies, by Claude Monet

This painting is a large Impressionist oil that looks straight down onto Monet's lily pond at Giverny, with no bank or sky in view. Clusters of flat lily pads drift across turquoise and blue water, and a few pink blossoms and one white flower float among them. The water reflects tall grasses and trees as loose streaks of green and gold. The brushwork is soft and blurred, so everything seems to hover on the surface.

Game image: game image is one of the late Giverny canvases, likely the 1915 painting in the Neue Pinakothek in Munich, full canvas with signature at lower left.

## 53. GREATWORK_MONET_2
Impression, Sunrise, by Claude Monet

This painting is an oil view of the harbor of Le Havre at dawn, and its title gave the Impressionist movement its name. A small orange sun hangs in a gray-blue mist and drops a broken streak of orange reflection down the water. Two small dark rowing boats drift in the foreground, while masts, cranes, and smoking chimneys of the port fade into the haze behind. The whole scene is painted in quick, thin strokes of blue, gray, and pink.

Game image: none.

## 54. GREATWORK_MONET_3
Haystack at Giverny, by Claude Monet

This painting is an Impressionist oil landscape of a single rounded haystack in a summer meadow near Monet's home at Giverny. A wide field of red poppies stretches behind it toward a row of farmhouses with red roofs and a dense line of dark green trees. Beyond the trees, low hills fade into a hazy pink and lavender sky. The paint is applied in soft dabs that blend the grass, flowers, and foliage together.

Game image: game image matches the 1886 painting in the Hermitage Museum, not the later grainstack series.

## 55. GREATWORK_ORLOVSKY_1
Mikhail Kutuzov, by Boris Orlovsky

This statue, shown here without its pedestal, is a bronze figure of Mikhail Kutuzov, the field marshal who led Russia against Napoleon in 1812. He stands in a military uniform with epaulettes and a long cloak draped over one shoulder, and he raises a baton high in his right hand. His left hand holds a sword lowered at his side. The bronze has weathered to a dark green.

Game image: cut-out illustration of the figure on a small base, without the Kazan Cathedral setting.

## 56. GREATWORK_ORLOVSKY_2
Alexander Column, by Boris Orlovsky

This sculpture, shown here on its own, is the bronze angel that crowns the tall granite column in Palace Square in Saint Petersburg. The angel stands with large feathered wings folded behind and holds a tall cross in one hand, while the other hand points upward to heaven. A serpent lies crushed beneath the cross at the angel's feet, and the figure's head bows toward it. The whole figure is colored gold.

Game image: cut-out illustration of the angel alone, rendered in gold rather than dark bronze.

## 57. GREATWORK_ORLOVSKY_3
Bust of Tsar Alexander, by Boris Orlovsky

This bust is a white marble portrait of Tsar Alexander I of Russia in the manner of an ancient Roman ruler. He wears a laurel wreath over short curled hair, and his clean-shaven face has a calm, faint smile. A heavy cloak is draped over armor at the shoulders and gathered across the chest. The bust rests on a small round marble socle.

Game image: game image is a museum photo, front view, plain wall behind.

## 58. GREATWORK_REMBRANDT_1
Andries de Graeff, by Rembrandt van Rijn

This portrait is a full-length Dutch Golden Age oil of Andries de Graeff, a wealthy Amsterdam magistrate, standing in a stone doorway. He is dressed entirely in black with a broad flat white collar and a wide-brimmed hat, his long fair hair falling loosely to his shoulders. One hand rests on his hip, a cloak hangs from his arm, and one glove lies dropped on the floor at his feet. Warm light falls on the pale stone behind him.

Game image: game image is the whole canvas, including the signature and date 1639 at lower left.

## 59. GREATWORK_REMBRANDT_2
Agatha Bas, by Rembrandt van Rijn

This portrait is a Dutch Golden Age oil of Agatha Bas, a young Amsterdam woman, standing inside a painted wooden frame along the picture's edges. She wears a black gown with a gold-embroidered bodice, a wide white lace collar, and pearls at her neck. One hand holds a folded fan, and the other rests on the edge of the frame so the thumb appears to reach out of the picture. Her pale face looks directly out from a dark background.

Game image: game image is the full canvas including the arched top and the trompe l'oeil frame.

## 60. GREATWORK_REMBRANDT_3
Abraham and Isaac, by Rembrandt van Rijn

This painting is a dramatic baroque oil of the moment an angel stops Abraham from sacrificing his son. The old bearded father presses his hand over the boy's face while a bright knife tumbles through the air, knocked from his grasp. The angel swoops in from the upper left, gripping his wrist with one hand and raising the other. Isaac lies bound and bare on the altar in the foreground, his body lit against the dark rocky landscape.

Game image: game image matches the 1635 Hermitage version, where the angel arrives from the side and the knife falls. The Munich version is different.

## 61. GREATWORK_RUBLEV_1
Annunciation, by Andrei Rublev

This icon, painted for the Dormition Cathedral in Vladimir, is a Russian panel in egg tempera on wood. The archangel Gabriel strides in from the left in a blue-green robe with golden wings, a staff in one hand and the other raised toward Mary. She sits on a bench at the right in a dark cherry-red mantle and holds a strand of red yarn, turning her head toward him. Pale towers stand behind them under a red cloth strung between the rooftops.

Game image: The game uses the 1408 Vladimir festival-tier version now in the Tretyakov Gallery, not the Kremlin Annunciation Cathedral icon. Fully verified against the game image.

## 62. GREATWORK_RUBLEV_2
Saviour in Glory, by Andrei Rublev

This icon, painted for the Dormition Cathedral in Vladimir, is a large Russian panel in tempera on wood, over three meters tall. Christ sits at the center in golden robes, one hand raised in blessing and an open book on his knee. Behind him a red diamond of light lies over a dark green oval crowded with faint angelic beings, and the faded corners hold the symbols of the four evangelists. Most of the paint has worn thin, so the figures show through a pale haze.

Game image: The game shows the 1408 Vladimir icon in the Tretyakov Gallery. The outer red square is almost entirely lost in this version, so the corners are described as faded rather than red.

## 63. GREATWORK_RUBLEV_3
Ascension, by Andrei Rublev

This icon, painted for the Dormition Cathedral in Vladimir, is a Russian panel in tempera on wood. At the top Christ sits inside a round blue disk of light that angels carry upward over a pale gold ground. Mary stands at the center in a dark red mantle with her hands raised before her chest, flanked by two angels in white who point upward. Six apostles in colored robes gather on each side, some looking up and others turning to one another.

Game image: The game shows the 1408 Vladimir festival-tier icon in the Tretyakov Gallery. Fully verified against the game image.

## 64. GREATWORK_SAMOSTRZELNIK_1
Portrait of Piotr Tomicki, by Stanislaw Samostrzelnik

This portrait is a Polish Renaissance panel painting of Piotr Tomicki, bishop of Krakow, shown full length. He stands in a tall white miter and a red and gold brocade cope, holding a gilded crozier and an open book. A gilded arch with small angels frames him against a green patterned hanging, and a second miter and a red hat rest on a table at the lower right. The face is painted with more care than the stiff body.

Game image: The panel hangs in the Franciscan church in Krakow. The game shows the full painting.

## 65. GREATWORK_SAMOSTRZELNIK_2
Saint Stanislaus, by Stanislaw Samostrzelnik

This miniature, painted in bright color and gold inside a floral border, is a full page from an illuminated catalogue of the archbishops of Gniezno. Saint Stanislaus, the patron saint of Poland, stands at the center in gold vestments and a jeweled miter, a crozier in his hand and two angels at his shoulders. Bishop Piotr Tomicki kneels at his left and King Sigismund I at his right beside a red banner with the white eagle of Poland. Two coats of arms hang in the foliage below.

Game image: full page. From the Catalogue of the Archbishops of Gniezno illuminated for Tomicki in 1531 to 1535.

## 66. GREATWORK_SAMOSTRZELNIK_3
Prayer Book of Sigismund I, by Stanislaw Samostrzelnik

This miniature is a royal prayer book page in color and gold inside a floral border. Mary stands in a blazing golden sunburst with a crescent moon at her feet, in a red gown and blue mantle, as two angels lower a crown onto her loose golden hair. She holds the naked Christ child on her arm. King Sigismund I in a red robe kneels at the lower right above a shield bearing the white eagle of Poland.

Game image: The manuscript is held in the British Library. The game shows the full page.

## 67. GREATWORK_TITIAN_1
Assunta, by Titian

This altarpiece, painted for the high altar of the Frari church in Venice, is a huge Renaissance panel in oil on wood, nearly seven meters tall and rounded at the top. The Virgin rises on a bank of clouds at the center in a red gown and blue mantle, arms spread wide and face lifted toward heaven. A ring of small angels bears her upward into a golden glow where God the Father hovers above. Below, the apostles crowd together in red and green robes, reaching up in wonder.

Game image: The game shows the full altarpiece including its carved marble frame. Verified against Wikipedia.

## 68. GREATWORK_TITIAN_2
Salome with the Head of John the Baptist, by Titian

This painting is a Venetian Renaissance oil with figures shown close to half-length. Salome, in a full red dress and loose white sleeves, holds a large platter against her hip, and on it lies the severed head of John the Baptist. She looks down and to the side with a calm face. A serving girl gazes up at her from the left, and a small winged child perches on a wall at the upper right.

Game image: The game uses the early version of about 1515 in the Galleria Doria Pamphilj, Rome. Fully verified against the game image.

## 69. GREATWORK_TITIAN_3
Equestrian Portrait of Charles V, by Titian

This portrait is a large Venetian Renaissance oil of Emperor Charles V riding out of a dark wood at dusk after his victory at Muhlberg. He sits upright on a black horse in polished plate armor, with a red sash across his chest and a long lance angled forward in his right hand. The horse wears a red and gold caparison and steps forward with one foreleg raised. A pale sunset breaks through gray clouds over a low river landscape at the right.

Game image: Commemorates the battle of Muhlberg in 1547. The game shows the full canvas.

## 70. GREATWORK_TOHAKU_1
Pine Trees, by Hasegawa Tohaku

This screen is one of a pair of six-panel Japanese folding screens painted in ink on paper. Clusters of pines stand in thick mist, some drawn in strong dark strokes and others fading to gray shadows. Two dark trunks rise near the left, a broad group fills the center, and a faint mountain peak shows at the upper right. Most of the paper is left empty, so the trees seem to drift in and out of fog.

Game image: The game shows the right-hand screen of the pair in the Tokyo National Museum, a National Treasure.

## 71. GREATWORK_TOHAKU_2
Maple Tree, by Hasegawa Tohaku

These panels, painted for the Chishaku-in temple in Kyoto, are a set of four Japanese sliding doors in color on gold leaf. A massive dark tree trunk climbs from the lower center and spreads its branches across all four panels, hung with maple leaves in red, green, and gold. Below it a bank of autumn plants, including white chrysanthemums and red cockscomb, blooms beside a stream painted in deep blue. The gold background glows behind every gap in the foliage.

Game image: The panels are at Chishaku-in temple in Kyoto, a National Treasure. The game shows all four panels.

## 72. GREATWORK_TOHAKU_3
Birds and Flowers, by Hasegawa Tohaku

This screen is a six-panel Japanese folding screen painted in ink and light color on faded gold paper. An old plum tree twists up from rocks at the left, its bark streaked with snow and its thin branches dotted with white blossoms. A pair of ducks perches on the trunk, green bamboo rises behind them, and a single small bird flies across the empty right side. Reeds and a few water plants trail along the bottom edge.

Game image: The specific screen could not be identified from references, so the description records only what the game image shows.

## 73. GREATWORK_YING_1
Spring Morning in the Han Palace, by Qiu Ying

This scroll is one section of a long Chinese handscroll painted in ink and color on silk. Palace ladies in flowing robes of white, red, and green stroll across a courtyard, while others sit on a veranda at the upper left with musical instruments. A tree grows inside a tall red lattice fence at the center, and garden rocks stand on a stone terrace below. Green pillars and paper screens frame the halls in fine, even lines.

Game image: The scroll is in the National Palace Museum, Taipei. The game shows a single section near the middle.

## 74. GREATWORK_YING_2
Fishermen in Reclusion Among the Lotus Stream, by Qiu Ying

This scroll is a tall Chinese hanging scroll painted in ink and color on silk that has aged to a warm gold. Blue-green mountains rise in soft layers through mist at the top, and a wide calm lake spreads across the middle. Terraced fields and a walled house sit among dark trees at the lower right, where two small figures stand by the water and a fishing boat is moored. Red collector seals run down the left edge.

Game image: Held in the Palace Museum, Beijing. The game shows the full scroll.

## 75. GREATWORK_YING_3
Red Cliff, by Qiu Ying

This scroll is a Chinese handscroll painted in ink and color on silk. A small boat carries the poet Su Shi, two companions, and a servant across calm water while a boatman stands at the bow with an oar. The Red Cliff rises steeply in green and ocher on the right, topped with dark pines and red-leafed trees, and pale mountains fade into the distance at the left. Red collector seals and a column of inscription mark the empty areas.

Game image: The subject is the poet Su Shi's boat trip beneath the Red Cliff. The game shows the full scroll.

## 76. GREATWORKOBJECT_WRITING
Shared background for every written work

A thick book with a dark brown cover lies open. Its two cream pages carry faded lines of small handwritten text arranged in paragraphs, curving gently up from the spine and glowing pale against a dark surround.

Game image: WRITING texture, 682 by 459.

## 77. GREATWORKOBJECT_MUSIC
Shared background for every piece of music

An open score rests on a wooden music stand. Two cream pages of handwritten sheet music sit on the stand's lip, their staves and notes faded to gray, and the stand itself is carved in ornate scrolls of golden-brown wood with a broad ledge below and a single column beneath.

Game image: MUSIC texture, 702 by 698.

## 78. ARTIFACT_1
Artifact image 1 of 25

A mummified cat stands upright. Its head is a gilded bronze cat face with pointed ears, and its body is wrapped in crisscrossing bands of brown linen.

Game image: ARTIFACT_1 texture, cut-out illustration.

## 79. ARTIFACT_2
Artifact image 2 of 25

A broken fragment of gray stone tablet is covered in rows of tiny wedge-shaped cuneiform signs. A deep crack runs across it.

Game image: ARTIFACT_2 texture, cut-out illustration.

## 80. ARTIFACT_3
Artifact image 3 of 25

A long thin spear has a slender wooden shaft and a narrow leaf-shaped iron point.

Game image: ARTIFACT_3 texture, cut-out illustration.

## 81. ARTIFACT_4
Artifact image 4 of 25

A scroll lies open between two wooden rollers with brass ends. Lines of faded handwriting run across the pale parchment.

Game image: ARTIFACT_4 texture, cut-out illustration.

## 82. ARTIFACT_5
Artifact image 5 of 25

An oval mask of dark brown wood has narrow slit eyes, a long nose, and a small mouth showing teeth. Two short horns rise from the top, and a row of white triangles runs along each edge.

Game image: ARTIFACT_5 texture, cut-out illustration.

## 83. ARTIFACT_6
Artifact image 6 of 25

A tall slender clay amphora in dark red-brown has two small handles curving from its neck to its shoulders. It tapers to a pointed base.

Game image: ARTIFACT_6 texture, cut-out illustration.

## 84. ARTIFACT_7
Artifact image 7 of 25

A fragment of floor mosaic sits on a broken plaster slab. Small cream, brown, and black tiles form a single eye with its brow and part of a face.

Game image: ARTIFACT_7 texture, cut-out illustration.

## 85. ARTIFACT_8
Artifact image 8 of 25

A gilded halberd, a long pole weapon, carries a crescent axe blade on one side. A spike rises from the top, and a curved hook projects behind the blade.

Game image: ARTIFACT_8 texture, cut-out illustration.

## 86. ARTIFACT_9
Artifact image 9 of 25

A round bronze shield has turned green with age. A raised pattern of petals radiates from a central boss.

Game image: ARTIFACT_9 texture, cut-out illustration.

## 87. ARTIFACT_10
Artifact image 10 of 25

A gold armlet forms an open ring whose two ends are shaped as facing griffin heads. Their curled wings and beaks nearly meet at the gap.

Game image: ARTIFACT_10 texture, cut-out illustration.

## 88. ARTIFACT_11
Artifact image 11 of 25

A tall brass chalice is tarnished and dented. Its flared cup sits on a stem with a rounded knob above a wide round foot.

Game image: ARTIFACT_11 texture, cut-out illustration.

## 89. ARTIFACT_12
Artifact image 12 of 25

A small silver coin is worn smooth at the edges. A head in profile is faintly visible on its face.

Game image: ARTIFACT_12 texture, cut-out illustration.

## 90. ARTIFACT_13
Artifact image 13 of 25

A long straight sword lies on a thin metal display stand. It has a plain cross guard, a round pommel, and a dark pitted blade.

Game image: ARTIFACT_13 texture, cut-out illustration.

## 91. ARTIFACT_14
Artifact image 14 of 25

A steel breastplate comes with matching shoulder pieces. The dark gray plate is shaped to the chest and marked with faint engraved lines.

Game image: ARTIFACT_14 texture, cut-out illustration.

## 92. ARTIFACT_15
Artifact image 15 of 25

A small gold ring is set with a flat red stone cut for use as a seal.

Game image: ARTIFACT_15 texture, cut-out illustration.

## 93. ARTIFACT_16
Artifact image 16 of 25

A round brass astrolabe carries pierced rotating rings and a straight pointer over a disk engraved with scales and circles.

Game image: ARTIFACT_16 texture, cut-out illustration.

## 94. ARTIFACT_17
Artifact image 17 of 25

A small gold coin is worn to a dull surface. A cross is faintly stamped on its face.

Game image: ARTIFACT_17 texture, cut-out illustration.

## 95. ARTIFACT_18
Artifact image 18 of 25

A long pike has a wooden shaft that ends in a broad triangular iron head with small wings at the base of the blade.

Game image: ARTIFACT_18 texture, cut-out illustration.

## 96. ARTIFACT_19
Artifact image 19 of 25

A fragment of wall painting on rough plaster has a scroll shape at the top. It shows a bearded man with a crown of thorns in a red robe, his eyes lifted upward.

Game image: ARTIFACT_19 texture, cut-out illustration.

## 97. ARTIFACT_20
Artifact image 20 of 25

A pair of gold drop earrings hang from slender hooks. Each ends in a faceted diamond-shaped pendant.

Game image: ARTIFACT_20 texture, cut-out illustration.

## 98. ARTIFACT_21
Artifact image 21 of 25

A tall grandfather clock stands in a carved case of dark brown wood. A round dial sits at the top, and a glass door below shows the pendulum.

Game image: ARTIFACT_21 texture, cut-out illustration.

## 99. ARTIFACT_22
Artifact image 22 of 25

A folded old newspaper has yellowed with age. Its front page shows columns of small print and one picture.

Game image: ARTIFACT_22 texture, cut-out illustration.

## 100. ARTIFACT_23
Artifact image 23 of 25

A flintlock pistol has a curved wooden stock and worn brass fittings. Its barrel and lock are dulled by rust.

Game image: ARTIFACT_23 texture, cut-out illustration.

## 101. ARTIFACT_24
Artifact image 24 of 25

A torn old map on yellowed parchment curls at the edges. Faint coastlines and route lines cross its surface.

Game image: ARTIFACT_24 texture, cut-out illustration.

## 102. ARTIFACT_25
Artifact image 25 of 25

A necklace of tan animal teeth or claws is strung on a dark cord. A small leather knot sits at the center of the strand.

Game image: ARTIFACT_25 texture, cut-out illustration.

## 103. GREATWORK_RELIC_1
Ark of the Covenant

A golden chest rides on two long wooden poles that pass through rings at its corners. Two winged figures kneel on the lid facing each other with their wings raised.

Game image: RELIC_1 texture, cut-out illustration.

## 104. GREATWORK_RELIC_2
Beard of the Evangelist

A round gold medallion bears a relief of a bearded man's face. A small clump of dark hair is set in an oval window at his chin.

Game image: RELIC_2 texture, cut-out illustration.

## 105. GREATWORK_RELIC_3
Blood of the Martyr

A folded white linen cloth with a fine woven edge is soaked through with large stains of red blood.

Game image: RELIC_3 texture, cut-out illustration.

## 106. GREATWORK_RELIC_4
Book of Thoth

An ancient papyrus scroll, brown and frayed, lies partly unrolled between its two rolls. Faint lines of writing show on the open section.

Game image: RELIC_4 texture, cut-out illustration.

## 107. GREATWORK_RELIC_5
Footprint of the Apostle

A pale gray boulder has a human footprint pressed into its top. Small stones lie scattered around it.

Game image: RELIC_5 texture, cut-out illustration.

## 108. GREATWORK_RELIC_6
Grass Cutting Sword

A Japanese sword rests in a black lacquered scabbard with gold fittings. Its hilt is wrapped in dark cord.

Game image: RELIC_6 texture, cut-out illustration.

## 109. GREATWORK_RELIC_7
Holy Grail

A small plain cup of hammered copper has a shallow bowl on a short stem and a simple round foot.

Game image: RELIC_7 texture, cut-out illustration.

## 110. GREATWORK_RELIC_8
Philosopher's Stone

A small gilded casket with a hinged lid is covered in filigree and set with green gems and pearls. A red stone forms the clasp at the front.

Game image: RELIC_8 texture, cut-out illustration.

## 111. GREATWORK_RELIC_9
Robes of the Guru

A plain white robe hangs loose, tied at the waist with a sash. The cloth is worn and faintly stained.

Game image: RELIC_9 texture, cut-out illustration.

## 112. GREATWORK_RELIC_10
Saint Aubert's Skull

A brown human skull sits on a gilded stand set with small jewels. A round hole pierces the top of the skull.

Game image: RELIC_10 texture, cut-out illustration.

## 113. GREATWORK_RELIC_11
Sandals of the Prophet

A pair of worn brown leather sandals with thin straps and small gold buckles lie side by side, toes pointing forward.

Game image: RELIC_11 texture, cut-out illustration.

## 114. GREATWORK_RELIC_12
Shroud of Turin

A long strip of pale linen carries the faint brown imprint of a bearded man's face and body. Dark burn holes mark the cloth in a row.

Game image: RELIC_12 texture, cut-out illustration.

## 115. GREATWORK_RELIC_13
Silk Texts

Narrow tattered strips of brown silk lie side by side. Columns of dark characters run down each strip.

Game image: RELIC_13 texture, cut-out illustration.

## 116. GREATWORK_RELIC_14
Splinter of the True Cross

A small cross of dark wood is set in a gold frame. A pointed gold spike extends below its foot so it can stand upright.

Game image: RELIC_14 texture, cut-out illustration.

## 117. GREATWORK_RELIC_15
Stone of Scone

A rough rectangular block of reddish sandstone is chipped along its edges. An iron ring is fixed to one end.

Game image: RELIC_15 texture, cut-out illustration.

## 118. GREATWORK_RELIC_16
Tooth of the Prophet

A tiny gold casket set with green stones stands with its lid open. A single tooth rests on red cloth inside.

Game image: RELIC_16 texture, cut-out illustration.

## 119. GREATWORK_RELIC_17
Bones of the Magi

A large golden shrine is shaped like a church with a peaked roof. Rows of small standing figures fill the arches along its sides, and round bosses and jewels stud the roof.

Game image: RELIC_17 texture, cut-out illustration.

## 120. GREATWORK_RELIC_18
Chains of the Apostle

An iron chain lies coiled on a red cushion inside a tall gold-and-glass case. The case is shaped like a lantern with a small handle on top.

Game image: RELIC_18 texture, cut-out illustration.

## 121. GREATWORK_RELIC_19
Eight-Hand Mirror

A round bronze mirror is seen from the back, its surface green-blue with age. A ring of leaf shapes surrounds a raised boss at the center.

Game image: RELIC_19 texture, cut-out illustration.

## 122. GREATWORK_RELIC_20
Gundestrup Cauldron

A large silver cauldron has two heavy handles. Panels around its sides are embossed with staring faces and small figures.

Game image: RELIC_20 texture, cut-out illustration.

## 123. GREATWORK_RELIC_21
Casket of the Evangelist

A small chest of gold and blue enamel with a sloping lid stands on four short feet. Panels of animals and winged figures decorate its sides, and a blue gem sits on top.

Game image: RELIC_21 texture, cut-out illustration.

## 124. GREATWORK_RELIC_22
Cincture of the Theotokos

A long narrow silver case with jeweled gold ends and engraved borders holds a gold cord coiled inside it.

Game image: RELIC_22 texture, cut-out illustration.

## 125. GREATWORK_RELIC_23
Grapevine Cross

Two grapevine branches bound together at the center form a cross. Strands of dark hair or cord tie the joint, and the ends of the branches droop downward.

Game image: RELIC_23 texture, cut-out illustration.

## 126. GREATWORK_RELIC_24
Holy Lance

An iron spearhead has a broken tip. A gold sheath wrapped with wire covers the middle of the blade.

Game image: RELIC_24 texture, cut-out illustration.

## 127. GREATWORK_HERO_SYMBOL_ANANSI
Drums of Anansi

Two tall African hand drums stand side by side. The taller one is pale wood laced with rope, and the shorter one is reddish-brown with a white skin head, both painted with bands of zigzags.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 128. GREATWORK_HERO_SYMBOL_ARTHUR
Chalice of Arthur

A tall golden chalice has a wide bowl. Red and green gems ring its rim and stem, and it stands on an ornate spreading foot.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 129. GREATWORK_HERO_SYMBOL_BEOWULF
Sword of Beowulf

A broad double-edged sword has a bright blade that widens toward the tip, and a curved gold crossguard sits above a leather-wrapped grip.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 130. GREATWORK_HERO_SYMBOL_HERCULES
Club of Hercules

A heavy wooden club has a thick end that bristles with bone spikes, and cord binds the narrow handle.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 131. GREATWORK_HERO_SYMBOL_HIMIKO
Crown of Himiko

A gold circlet carries a fan of tall pointed rays rising from a round sun disk at the front. Scrolling lines are engraved across the band and rays.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 132. GREATWORK_HERO_SYMBOL_HIPPOLYTA
Girdle of Hippolyta

A wide belt of dark brown leather is set with round bronze discs. It is tied with a knotted thong that hangs loose.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 133. GREATWORK_HERO_SYMBOL_HUNAHPU
Mantles of the Hero Twins

A pale cloth mantle hangs from a wooden bar. A collar of green feathers rings its neck, and the cloth falls in loose folds below.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 134. GREATWORK_HERO_SYMBOL_MAUI
Torch of Maui

A wooden torch has a bound head burning with a bright yellow flame that throws off sparks. A cord tassel with beads hangs from the handle.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 135. GREATWORK_HERO_SYMBOL_MULAN
Armor of Mulan

A set of armor lies together: a dark cuirass of overlapping plates and a round helmet trimmed with a red plume. Red cords tie the pieces.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 136. GREATWORK_HERO_SYMBOL_OYA
Knife of Oya

A dagger has two parallel steel blades rising from a single hilt. The grip is wrapped in red-brown cord.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 137. GREATWORK_HERO_SYMBOL_SINBAD
Compass of Sinbad

A brass navigator's quadrant, a quarter circle with an engraved green face, hangs a plumb line with a small weight from its corner.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 138. GREATWORK_HERO_SYMBOL_WUKONG
Staff of Sun Wukong

A long dark staff is capped with gold bands at both ends. A red cord with small rings is tied near one end.

Game image: Heroes_GreatWorks256 icon atlas, Babylon Icons.blp.

## 139. GREATWORK_HERO_EPIC
Shared image for every hero epic

A curling parchment scroll stands with a small lute leaning against it. Glowing musical notes float between the scroll and the strings.

Game image: Heroes_GreatWorks256 icon atlas index 12, shared by all twelve epics.

## 140. VOIDSINGER_RELIC_1
Secret Societies relics 25 to 32: Relic of the Devouring Angel, Fungal Spore, Fragment of Akkorokamui, Black Goat's Horn, Foundation Stone, Relic of the Sightless Worm, Shard of Yog-Sothoth, Child of Azathoth

A curved gray tusk pitted with sucker-like marks is capped with jeweled gold bands. It hangs from a heavy iron chain with a small ringed pendant.

Game image: GreatWorksSTK256 icon atlas index 0, Ethiopia Icons.blp.

## 141. VOIDSINGER_RELIC_2
Secret Societies relics 33 to 40: Chorus of the Drowned, Vessel of Nyarlathotep, Rangda's Chalice, The Singing Worm, The Dream-Eater, The Shrieking Flowers, The Loveless Ones, The Tome of Dagon

A dark vessel with a fluted rim sprouts thick tentacles that rise and coil. It stands on a rounded base of the same dark metal.

Game image: GreatWorksSTK256 icon atlas index 1, Ethiopia Icons.blp.

## 142. VOIDSINGER_RELIC_3
Secret Societies relics 41 to 48: The Book of Dead Names, The Left-Hand Sutra, Instructions for the Kumanthong, Teachings of the Worm, Memoirs of a Blind Astronomer, A Journal of Next Year's Dreams, Chronicle of Descent, Hint Guide: Civilization II

An open wooden chest with brass corners and a glass-paned lid holds rolled scrolls and old books. A bone skull sits at the front, and barnacles crust the edges.

Game image: GreatWorksSTK256 icon atlas index 2, Ethiopia Icons.blp.

## 143. PRODUCT_CITRUS
Monopolies and Corporations products of citrus: Tree-Fresh Orange Juice, No-Scurv Lime Juice, Summertime Supplements, Imperial Cross Marmalade, Meier's Oven Baking Supplies

An open cardboard shipping box holds a whole orange with a green leaf on its stem.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 144. PRODUCT_COCOA
Monopolies and Corporations products of cocoa: Fuligin Dark Chocolate Bars, Whizzo's Choco-Mix, Heidi's Alpine Hot Chocolate Mix, Xocolatl Spiced Drinking Chocolate, Island Dream Cocoa Butter Lotion

An open cardboard shipping box holds a dark chocolate bar scored into squares.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 145. PRODUCT_COFFEE
Monopolies and Corporations products of coffee: Game Designer Fuel Coffee, Neurologically Unsafe Instant Coffee, Kaffa Harrar Roast Coffee, Sopranzetti Espresso, Tampuan Roastery Cold Brew

An open cardboard shipping box holds a burlap sack of roasted coffee beans with a metal scoop resting in it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 146. PRODUCT_COTTON
Monopolies and Corporations products of cotton: Rugged Hill Jeans, Mahendradatta Batik, Fluffy Sheep Linens, Sur-Dry Diapers, Westford Textiles

An open cardboard shipping box holds a cotton branch with three white bolls.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 147. PRODUCT_DIAMONDS
Monopolies and Corporations products of diamonds: Blown Eardrum Speakers, Suvanna Gemstones, Lacero Drill Bits, Infrasound Audio Tech, Monolith All-Consuming Mining Equipment

An open cardboard shipping box holds a single large cut diamond that sparkles white and blue.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 148. PRODUCT_DYES
Monopolies and Corporations products of dyes: Litham Indigo, King's Scarlet Dyes, Monochrome Colors, Food Dye Red #5, Dai-Iro Industrial Paints

An open cardboard shipping box holds three glass bottles of dye in pink, purple, and blue.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 149. PRODUCT_FURS
Monopolies and Corporations products of furs: Arctic Moon Fashions, Marie Antoinette Headwear, Lord Steven's Stovepipe Hats, Mercury Haberdashery, Elysium Angora Yarns

An open cardboard shipping box holds an orange fox standing inside it with its tail raised.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 150. PRODUCT_HONEY
Monopolies and Corporations products of honey: Late Summer Pure Honey, Nature's Hive Royal Jelly, Whanganui Manuka Honey, Abe's Apis Probiotics, Royal Buzz Pollinators

An open cardboard shipping box holds a piece of golden honeycomb with two bees on it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 151. PRODUCT_GYPSUM
Monopolies and Corporations products of gypsum: Colossus Construction Supplies, Svadilfari Masonry Supplies, Titanic Construction Materials, Demeter Growth Chemicals, Atlas Insulated Building Material

An open cardboard shipping box holds a cluster of pale pink and white crystals.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 152. PRODUCT_INCENSE
Monopolies and Corporations products of incense: Nag Champa, Phra-jan Dara Sandalwood Aromas, Franks Incense, Love Potion #8, Stink Destroyer Air Freshener

An open cardboard shipping box holds a brass burner with a small flame and a curl of pale smoke rising from it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 153. PRODUCT_IVORY
Monopolies and Corporations products of ivory: Hattori Hanzo Hilts, Bertie Wooster's Billiard Balls, Aana Ivory Fashions, Xiangya Fashions, Tickle Piano Keys

An open cardboard shipping box holds a gray elephant's head and tusks rising from it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 154. PRODUCT_JADE
Monopolies and Corporations products of jade: Hongshan Luxury, Immortal Beauty Jade, Nuwang, Pearl Delta, Savannakhet

An open cardboard shipping box holds a carved green jade dragon.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 155. PRODUCT_MARBLE
Monopolies and Corporations products of marble: Augustine Marble Finishing, Alabaster Masonry, No-Burp Antacid, Attila's Scouring Powder, Morte Monoliths

An open cardboard shipping box holds a white marble bust of a man with curled hair.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 156. PRODUCT_MERCURY
Monopolies and Corporations products of mercury: Sur-Read Thermometers, Martine Dependable Thermometers, Centennial Light Bulbs, Metalhead Brain Wires, Fire Axis Thermostats

An open cardboard shipping box holds three rounded beads of shiny liquid mercury.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 157. PRODUCT_PEARLS
Monopolies and Corporations products of pearls: Night Tide Baubles, Setesuyara Cosmetics, Aunt Enid's Clutching Pearls, String of Stars Necklaces, Merrow Case Oysters

An open cardboard shipping box holds an open oyster shell with a white pearl inside.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 158. PRODUCT_SALT
Monopolies and Corporations products of salt: Waimanalo Huli Huli Chicken Spice, Adder's Tongue Medical Supply, Mom's Pickling Supplies, Keep-it-Down Preservative, Flayvur Seasoning

An open cardboard shipping box holds a glass salt shaker with a metal cap.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 159. PRODUCT_SILK
Monopolies and Corporations products of silk: Atas Luxury Textiles, Saratsawadi Medical Supply, Far North Field Medical Supply, Hung Vuong Fine Fabrics, Dock 2 Living Decor

An open cardboard shipping box holds a bolt of silk cloth unrolling in purple and red.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 160. PRODUCT_SILVER
Monopolies and Corporations products of silver: Dark of the Moon Silver Jewelry, Fadaka Designs, Megastorm Microcontrollers, Connecto Precision Switches, Unforgettable Photography

An open cardboard shipping box holds a polished silver pitcher with a curved handle.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 161. PRODUCT_SPICES
Monopolies and Corporations products of spices: Archipelago Nutmeg, Pueblo Kitchen Chili Powder, Gondavana Cinnamon, East Indies Nutmeg, Volcano Chili Sauce

An open cardboard shipping box holds heaps of green, red, and orange spices with two chili peppers.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 162. PRODUCT_SUGAR
Monopolies and Corporations products of sugar: Mama Theresa's Baking Sugar, Bubba Mubba Bubble Gum, Rock's Penny Candy, Sucro-Cola, Ed Teach's Homestyle Molasses

An open cardboard shipping box holds a blue bowl piled with white sugar cubes.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 163. PRODUCT_TEA
Monopolies and Corporations products of tea: Saratsawati Chai, Sea Urchin Green Tea, First Flush White Tea, Asa-no-Sencha, Sun-Never-Sets Tea

An open cardboard shipping box holds a paper tea bag with its string and tag.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 164. PRODUCT_TOBACCO
Monopolies and Corporations products of tobacco: Mountain Fresh Cigarettes, Coughing Cowboy Cigarettes, Petit Dictator Cigars, Burnt Bourbon Flavored Tobacco, Stockholm Snuff

An open cardboard shipping box holds a wooden smoking pipe beside a brown tobacco leaf.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 165. PRODUCT_TRUFFLES
Monopolies and Corporations products of truffles: Boar's Bounty Truffles, Abydos Truffle Oil, Pig Snout Truffles, Autumn Twilight, Sniffing Pig Artisinal Eats

An open cardboard shipping box holds a pink pig's head nosing at two dark truffles in earth.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 166. PRODUCT_WINE
Monopolies and Corporations products of wine: Del Sol Malbec, Kvevris Saperavi, L'Ombre Cabernet, Villa Scintillante Prosecco, Grunental Sekt

An open cardboard shipping box holds a bunch of purple grapes with leaves, a wine bottle, and a filled glass.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 167. PRODUCT_WHALES
Monopolies and Corporations products of whales: Melville's Plenty Lamp Oil, Moldywarp's Ambrosia, Whalebarf Ambergris, Ishmael's Lamp Oil, Kujirasan's Lubricants

An open cardboard shipping box holds a blue whale lying across it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 168. PRODUCT_AMBER
Monopolies and Corporations products of amber: Griffin's Plume, Tsarskoye Ambers, Namsai Perfume, Jurassic Gems Amber, Fragrant Sheep Perfume

An open cardboard shipping box holds chunks of glowing orange amber.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 169. PRODUCT_OLIVES
Monopolies and Corporations products of olives: Kalamata Dream Olive Oil, Byzantine Dawn Olive Oil, No-Granny Youth Preserving Cream, Face-Off Facial Restorer, Martinese Pickled Olives

An open cardboard shipping box holds an olive branch with black olives and silver-green leaves.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.

## 170. PRODUCT_TURTLES
Monopolies and Corporations products of turtles: Mary Shelly Eyeglass Frames, Palawan Shores Hair Accessories, Wujin Beauty Supplies, Guilinggao Turtle Jelly, Lord McConnell's Decidedly Not Mock Turtle Soup

An open cardboard shipping box holds a green sea turtle climbing out of it.

Game image: Monopolies_Resources256 icon atlas, Vietnam and Kublai Khan pack Icons.blp, shared by all five products of the resource.
