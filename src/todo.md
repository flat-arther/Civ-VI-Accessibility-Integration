## TODO

- [x] cover compatibility with UnitFlags which are used in other modes.
- [x] cover missing info from unit flag, announce levied and relligion at the end present, look at UnitFlag.UpdateName for already localized strings.
- [x] announce hero, promotion levels, and aircraft current count / capacity. note for promotion levels show only when a unit is not levied, and the unit has promotions following vanilla
- [x] investigate if aircraft carriers show their contents to sighted players for units you don't own, so we can say it contains x, y, z
- [x] investigate goverment screen appears to disallow unlock with gold on the same turn if you've confirmed your policies already
- [x] make settler lens recommendations
- [x]make contenents named zones that change if you move in to one, E.G.: contenent of europ. in order to cover the contenent lens.
- [x] show cities with religion majority to cover the religion lens
- [x] show appeal plots grouped by their level to cover the appeal lens. Other lenses that can be useful [https://civilization.fandom.com/wiki/Lens_(Civ6)]
- [x] revise and cover info missing from the unit panel
- [ ] make  a key show a list of units with a detailed view on a tile with enter allowing you to select your own units

## Suggestions

## Informational

- [x]unit promotions interface show a promotion tree for the class of that unit
- [x]settler lens shows differently colored spots, red = can't settle, bluish gray tiles = no access to fresh water, light green = coastal waters +1 to housing, bright green = access to fresh water from a river or a lake +3 to housing. it also shows icons on plots for loyalty , The negative Loyalty pressure from other civilizations is shown with number icons. Coastal tiles that may be flooded as the sea level rises are marked by a wave icon. There are 3 levels of coastal lowland tiles, which are also shown. (The tiles that belong to the first level which may be flooded by the first sea level rise are without numbers.).
  [x]Floodplains tiles and tiles that are susceptible to volcanic eruptions are marked with their corresponding icons.

[x] Add map search accessibility
[x] Add plot info for active lenses
[x] Handle different advisor recommendations
[x]Add some flag info to unit panel selection info plottooltip
[ ] confirm that anti-air intercepter combat previews / results work as intended
[x]Make espionage shit accessible
[x] add city states to the cities category in the scanner
[x] Add districts to the scanner
[x]Fix bug in the gov screen, if you choose a policy, go to governments and back, it does not remember your selection while still excluding it from the picker
- [x] Rework the nav cursor class to send a cursor state table for events rather than splitting between jumping and regular movement
[x] Look ats in city-states, espionage, trade, and great people should move the cursor
[x] rework icon processing
[x] Add map pins to plot info and scanner
[x] city actions should not repeat the names in the tooltip
[x] add mod config
[ ] River flow direction reporting
[x] / to jump back to selection
[x] Speaking input binding next to city and unit actions if any are bound
[ ] Ad great person passive effects to map info, configurable
[x] Roads should be mentioned in plot info
-[x] Capital city should say capital
[x] turn status in chat panel
[x] hamada: the government screen has repeating Empty slot 1, Empty slot 1
[x] unit actions should not repeat name in tooltip
[x] should not stop player from moving if no combat stats are encountered. Game considers entering a city state teratory as a combat even though there is no enemy on the dest plot
[x] Dedications popup should not duplicate dedication name in tooltip
[x] governer panel is missing the biography. 
[x] Rework the diplomacy screen
[x] Recommendation types in tech and civic trees should report the correct advisor
[ ] redo the scanner categories for the tourism and power lenses. They are shit
[ ] figure out tab bar count
[x] dedup difficulty tooltip, it repeats label. 
[x] change dropdowns that have simple on off options to checkboxes
[ ] add custom locale for hotkey strings that are symbols
[x] Make quick move keys not queue movement.

[x] Change label for friends list
[ ] online status repeats in tooltip for friends list, fix it
[x] Fix mp additional content missing dialog.
[x] Popup dialog enter to commit should be disabled for edit boxes so that input can bubble to the dialog's default action
[x] Fix dropdown focus restoration
[x] Play a sound when changing volume for cursor audio
[x] Have shift announce turn blocker info

[x] offset the team numbering in team slot
[ ] Add announcements for capturing units
[x] Scanner sort should be based on cashed plot id
[x] change scanner sound and add volume setting
[x] Fix wc unknown participant string
[x] Selection cursor move should be a setting