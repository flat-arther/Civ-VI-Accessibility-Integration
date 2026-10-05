# Deferred game-test checklist

User instruction, 2026-10-04: collect game tests here until the entire refactor is complete. These checks do not block implementation. Automated checks continue during each stage; stage summaries remain separate decision points for the user.

Unchecked means unverified in game, not failed. Add or revise checks as later stages change the same area. Previously confirmed tests remain closed unless a subsequent change warrants another check.

## Trade consolidation

Run the common checks with vanilla trade screens and with Better Trade Screen where available.

- [ ] Change a trader's origin city; confirm the intended city is selected and the chooser closes.
- [ ] Browse destinations and inspect yield, trading-post, quest and distance information. With BTS, also check turns to completion.
- [ ] Change route filters; confirm the selected filter and destination list agree.
- [ ] Select a route, cancel its confirmation, then select and confirm a route. Confirm cancellation starts no route and confirmation starts the intended route once.
- [ ] Visit My Routes, Routes To My Cities and Available Routes in the overview. Check headers, route details and trader selection.
- [ ] Close/reopen the trade screens and check focus after a list refresh.
- [ ] With BTS, change overview grouping and filters; confirm the resulting groups and routes agree with the selections.
- [ ] With BTS, change sort keys, priority and direction; check route ordering.
- [ ] With BTS, test repeat route, repeat best route with the selected sort, and cancel automation from the overview.
- [ ] Where available, open the overview with BBG and in the Indonesia/Khmer scenario; check grouping and route actions.

## Plot/banner descriptors and column helpers

- [ ] Read plot information on ordinary terrain and on tiles with conditional details, such as resources, improvements and rivers. Check that details remain in their usual order without omissions or extra repetitions.
- [ ] Read city, district and barbarian-clan banner details where available; confirm each announces the appropriate information.
- [ ] Check sort choices in City-States, the diplomacy ribbon/action view, Governors, Great People/Heroes, Global Resources and the unit browser. Verify labels, available directions and natural order where offered; change a sort and check the resulting order and focus.
- [ ] In Reports, check city sorting. With Better Reports installed, check unit, policy and city-state sorting; policy type and city-state category should remain grouping choices rather than redundant sort choices.
- [ ] With Extended Policy Cards installed, check sorting in the policy picker/viewer. With Quick Deals installed, check its sort choices and return to natural order.
- [ ] After a live data change, reopen or refresh an affected list and check updated column labels, usable focus and retained sort selection.
- [ ] In City-States, diplomacy, Governors, Great People/Heroes, Global Resources and the unit browser, change sort direction and switch views or refresh. Confirm the sort dropdown follows the current sort without extra speech or stealing focus. Return to natural order where available.

## WorldInput plot interactions

- [ ] In selection mode, use Enter on a tile with one owned unit, an owned city and multiple available actions. Confirm direct selection for one action and the correct choices for multiple actions.
- [ ] Close a plot-action list with Escape, reopen it, and select an action. Check return focus and that the action runs once. Suspend/resume accessibility while the list is open and confirm it closes cleanly.
- [ ] On met foreign cities, check diplomacy/city-state actions. Where espionage visibility permits city inspection, check the view-city choice and Ctrl+Enter shortcut.
- [ ] Where available, inspect a revealed barbarian clan, city/district strike actions and missile-silo targeting choices. Check that targeting opens with the intended source and cancel it normally.
- [ ] During an active targeting mode or tutorial restriction, confirm plot actions do not take over the mode or offer prohibited selections.

## World Builder input

- [ ] Place and remove using Enter/Delete with single-tile and larger brushes. Check river/cliff direction where applicable and that undo reverses the intended edit.
- [ ] Mark a source with M, move the cursor, and confirm manual placement and F3 still use the mark. Unmark and confirm they follow the cursor again.
- [ ] Toggle brush lock with L and move/jump the cursor. Confirm automatic painting follows the destination even with another tile marked; stationary events and suspended accessibility should not paint.
- [ ] Check Ctrl+Z/Ctrl+Y with available and unavailable history. After owner changes or successful undo/redo, check visibility and Valid Targets refresh correctly.
- [ ] With Set Visibility armed, add/remove visibility for the selected player and confirm the readout follows successful edits.
- [ ] Use Ctrl+G with absolute, relative and mixed coordinates, including an omitted first coordinate. Check invalid/out-of-bounds feedback, correction, Escape cancellation and a single jump on Enter.
- [ ] Check number-row/Shift tool selection, arrow quick navigation, Tab tools, F1/F2/F3 editors and Escape pause. Confirm map editing shortcuts stay inactive while another panel owns focus.
- [ ] Reload a World Builder map and confirm an old marked tile is not retained by the scanner or tooltip.

## Other outstanding game checks

These existing checks are retained alongside the refactor checklist so they are not lost. Cloud-save recovery itself is already user-confirmed.

- [ ] In a multiplayer client lobby, have the host change map size while focus is on a player slot, slot submenu and dropdown. Check updated controls and retained usable focus.
- [ ] Listen to a message-buffer location entry and its history entry; confirm the localized equivalent of “at” introduces the direction/distance naturally.
- [ ] Press B on a tile touching multiple named rivers; confirm one “Rivers” header followed by each river's edges and flow.

## WorldInput interface modes

- [ ] Enter/cancel Move To and confirm valid movement, including combat/war confirmation and cancellation. Verify movement readiness clears on mode exit.
- [ ] Check valid and invalid unit, city and district ranged targets; invalid targets should announce rejection without attacking.
- [ ] Check available air/rebase/deploy, formation, special ability and WMD/ICBM modes. Confirm the intended target once, preserve native confirmation dialogs, then cancel normally.
- [ ] Place/cancel districts and wonders, including purchases and tutorial restrictions. Check city-management navigation and city-scope position after leaving placement.
- [ ] Change interface mode while a popup is open; confirm old targeting widgets close and focus/input remain usable. World Builder should retain its own map widget.
- [ ] Where available, check Red Death Grieving Gift and Pirates targeting abilities, including invalid targets and Escape cancellation.

## Scanner and return-focus contracts

- [ ] Open/close Settings and scanner category management from the map and from a menu. Confirm the original item is announced and usable on return; repeat after that menu refreshes or removes the original item.
- [ ] Change enabled categories and custom category rules, close management, and confirm scanner ordering and selected items remain usable. Check search, quick slots and return-from-jump.
- [ ] Check ordinary categories, Valid Targets and hidden/revealed tiles, then change local player where available. Confirm no stale items or reveal leaks.
- [ ] With Detailed Map Tacks available, check pin names, yields and placement information. Without it, check ordinary map tack labels.
- [ ] Open another popup while Settings/category management is open; closing the underlying view should not steal the popup's focus. Repeat suspend/resume and reopen Settings.

## Reports sections

Run with vanilla Reports and Better Reports where available.

- [ ] Open Reports after loading a game, then close/reopen and visit Resources and Gossip. Check tab selection and return to the map.
- [ ] Check ordinary resource totals and amenity recipients. In Gathering Storm, check stockpile-only resources, accumulation, reserve, unit/power consumption, named sources and miscellaneous amounts.
- [ ] Refresh Resources while focused on an expanded detail; confirm usable focus and updated amounts.
- [ ] Filter Gossip by player and type, refresh it, then close/reopen. Check the retained filters, newest-first entries and dropdown focus.
- [ ] Smoke-check Yields, City Status and city cycling; with Better Reports also visit its Deals, Units, Policies and City-States tabs.

## World Rankings presenters

- [ ] Check Score in tree and table views, including team totals, player/category contributions and sorting. Switch views while focused on a competitor and confirm the same team remains selected.
- [ ] Refresh, close and reopen Rankings; confirm focus remains usable and native player/team ordering is respected. Check unmet-player names and multiplayer team membership.
- [ ] In Gathering Storm, check diplomatic points and requirement details, including changed progress after a refresh.
- [ ] With BBG, check Traditional Domination percentage, captured details/tooltips and the configured victory threshold.
- [ ] Where available, check a custom victory or scenario Score view. Confirm native objectives and player/team entries remain present.
- [ ] Smoke-check Overall, Science, Culture, Domination and Religion tabs and tutorial-controlled closing.

## ProductionPanel queue

Run with ordinary ProductionPanel and with BBG/Babylon content where available.

- [ ] Open Queue with current production and several queued units, buildings, districts and projects. Check names and current-production details, including an empty queue.
- [ ] Use Shift+Up/Down to reorder queued items and exchange the first item with current production. Check first/last feedback and focus after each refresh.
- [ ] Delete a queued item and current production; confirm the intended item is removed once and focus remains usable. Repeat quick reorder/delete inputs as the queue updates.
- [ ] Close/reopen, switch cities and switch between Production, Gold, Faith and Queue. Confirm fresh queue contents and no focus jump left over from an earlier operation.
- [ ] Smoke-check ordinary production, corps/army choices, gold/faith purchases and Ctrl+Enter queueing. Place/cancel a district or wonder and confirm the normal panel/focus return behavior.
- [ ] In the tutorial, confirm only the allowed production choices are exposed and successful production still closes the panel normally.

## Final utility audit

- [ ] In Advanced Setup, Scenario Setup, Host Game and multiplayer staging, check parameter order, selected dropdown values and invalid-option reasons. Change a setting that rebuilds available options and confirm selection and focus stay usable.
- [ ] Check leader descriptions in Advanced/Scenario Setup, game summaries and Lobby friend-status text.
- [ ] In game-summary and end-game replay graphs, check numeric values, toggle grouping and reopen; confirm the grouping preference is retained.
- [ ] Open Settings, change an audio-tag setting, close/reopen and confirm its saved value is retained.
- [ ] Expand several nested tree/submenu levels, collapse the parent and reopen it; confirm descendants start collapsed and navigation remains usable.
- [ ] Check religion lens plot information and scanner religion labels, including unnamed/unavailable religion data where possible.

Implementation stages finished on 2026-10-05. This is the complete deferred checklist for handoff; unchecked items remain unverified. The known missing audio manifest asset is a separate packaging decision.
