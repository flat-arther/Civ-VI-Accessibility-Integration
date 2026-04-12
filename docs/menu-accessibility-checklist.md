MENU ACCESSIBILITY CHECKLIST
==============================

Quick checklist BEFORE implementing keyboard navigation for a menu.
For detailed patterns and code examples, see: `menu-accessibility-patterns.md`


1. UNDERSTAND STRUCTURE
-----------------------
- How is the menu structured? (Linear, grid, hierarchical, tabbed)
- What element types exist? (Buttons, sliders, toggles, dropdowns, tabs)
- What parent-child relationships exist?
- Are there modal dialogs that need priority handling?


2. ANALYZE INTERACTION PATTERNS
-------------------------------
- How is each element activated? (Click, double-click, hover)
- How are values changed? (scrollBy, increment, toggle, dropdown cycle)
- What events/handlers already exist? (clickReleased, scrollBy, keyPressed)

IMPORTANT: Reuse existing methods, don't reinvent!


3. CHECK EXISTING ACCESSIBILITY SYSTEMS
---------------------------------------
- Is there already a FocusManager, IFocusable, or similar?
- Which elements are already registered?
- How are announcements already made? (ScreenReader class)


4. DEFINE NAVIGATION CONCEPT
----------------------------
Standard keys (adjust to game if needed):
- Up/Down: Navigate between elements
- Left/Right: Change values (sliders, dropdowns) or navigate within groups
- Enter/Space: Activate/Toggle
- Home/End: Jump to first/last item
- Backspace: Go back (e.g., from tab content to tab list)
- Escape: Close menu (usually handled by game)


5. CHECK LABEL TEXTS
--------------------
- [ ] All labels are meaningful (not empty, not "item123")
- [ ] Labels come from game localization where possible
- [ ] Fallback hierarchy defined for missing labels
      (see `menu-accessibility-patterns.md` → Label Resolution)


6. VERIFY KEY CAPTURE
---------------------
- [ ] Navigation keys don't "fall through" to the game
- [ ] Keys are captured BEFORE the game processes them
- [ ] Only capture keys when menu is actually active


7. PANEL/SCREEN CHECKLIST
-------------------------
For each new panel/screen, verify:

- [ ] Opening announced (screen name)
- [ ] Navigation announces current item
- [ ] Empty states handled explicitly (never silence)
- [ ] Actions confirmed ("Enabled", "Changed to X")
- [ ] Wraparound announces "First item" / "Last item"
- [ ] State tracking for change detection
- [ ] Closing announced if relevant


8. EMPTY STATE HANDLING
-----------------------
NEVER leave the user in silence. Always announce:

- "No items available" (empty list)
- "No selection" (nothing selected)
- "Inventory empty" (no content)
- "No results found" (search/filter returned nothing)


9. TEST INCREMENTALLY
---------------------
- Test after each change, not all at once
- Make one element type fully functional first, then the next
- Use debug mode to verify item collection (see state-management-guide.md)


RELATED DOCUMENTATION
=====================
- `menu-accessibility-patterns.md` - Detailed patterns, code examples, label resolution
- `state-management-guide.md` - Handler architecture, debug mode
- `ACCESSIBILITY_MODDING_GUIDE.md` - General accessibility patterns
