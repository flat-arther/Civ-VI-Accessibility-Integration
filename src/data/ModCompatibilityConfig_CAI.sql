UPDATE InputActionDefaultGestures
SET GestureData = ''
WHERE ActionId IN (
    -- Detailed Map Tacks
    'AddMapTack',
    'DeleteMapTack',
    'ToggleMapTackVisibility',
    -- Better Report Screen
    'ToggleReports'
);

-- Quick Deals defaults its "Open Quick Deals popup" action to the bare D key,
-- which collides with common single-key use while a screen reader is active.
-- Rebind it to Ctrl+D so it stays reachable without stealing D. Quick Deals
-- inserts the row with InsertOrIgnore, so the row exists to be updated here.
UPDATE InputActionDefaultGestures
SET GestureData = 'LOC_OPTIONS_KEY_CONTROL+LOC_OPTIONS_KEY_D'
WHERE ActionId = 'OpenQDPopup';
