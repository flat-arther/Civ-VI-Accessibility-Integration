UPDATE InputActionDefaultGestures
SET GestureData = ''
WHERE ActionId IN (
    'AddMapTack',
    'DeleteMapTack',
    'ToggleMapTackVisibility'
);