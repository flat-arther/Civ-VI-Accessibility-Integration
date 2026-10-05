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

## Other outstanding game checks

These existing checks are retained alongside the refactor checklist so they are not lost. Cloud-save recovery itself is already user-confirmed.

- [ ] In a multiplayer client lobby, have the host change map size while focus is on a player slot, slot submenu and dropdown. Check updated controls and retained usable focus.
- [ ] Listen to a message-buffer location entry and its history entry; confirm the localized equivalent of “at” introduces the direction/distance naturally.
- [ ] Press B on a tile touching multiple named rivers; confirm one “Rivers” header followed by each river's edges and flow.
