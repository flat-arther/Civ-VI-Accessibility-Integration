````markdown
# UI Screen Manager Summary

These files implement a lightweight, accessibility-focused UI framework for Civilization VI. The system is composed of three main parts:

- **Base widget system (`baseWidget.lua`)**
- **Screen manager (`UIScreenManager.lua`)**
- **Widget templates (`widgetTemplates.lua`)**

The goal is to provide structured UI navigation and screen-reader-friendly output via focus management and speech generation.

---

## 1. Base Widget System (`baseWidget.lua`)

### Overview
Defines the core `UIWidget` object and shared functionality for all widgets.

### Key Responsibilities
- Tree structure (parent/children relationships)
- Focus handling
- Input binding and processing
- Accessibility data generation

### Core Properties
- `Children` — child widgets
- `Parent` — parent widget
- `FocusedChild` — currently focused child
- `InputMap` — registered input bindings
- `Type` — widget type
- Optional callbacks:
  - `GetLabel`
  - `GetState`
  - `GetTooltip`
  - `OnFocusEnter / OnFocusLeave`

### Tree Management
- `AddChild`, `RemoveChild`
- `RemoveFromParent`
- `Destroy`, `ClearChildren`
- Index helpers (`GetChildIndex`, `GetSibling`, etc.)

Focus is tightly integrated with the tree. Removing a focused widget automatically reassigns focus.

### Input System
- `AddInputBinding` / `AddInputBindings`
- `OnHandleInput(input)`
  - Matches key, message type, and modifiers
  - Executes bound action if matched

### Accessibility Output
- `GetInfoStrings()` returns structured info:
  - `label`
  - `meta` (role/type)
  - `position` (index in parent)
  - `state`
  - `tooltip`

This structured data is later used by the screen manager to generate speech.

---

## 2. Screen Manager (`UIScreenManager.lua`)

### Overview
Central controller that manages:
- Widget stack
- Focus system
- Input routing
- Speech output

### Initialization
```lua
function InitUIScreenManager()
    ExposedMembers.CAI_UIManager = CreateScreenManager()
end
````

This exposes the manager globally within the UI context.

---

### Core Systems

#### Widget Creation

```lua
CreateUIWidget(type, props)
```

* Clones a template from `WidgetTemplates`
* Applies overrides from `props`
* Initializes:

  * Children
  * Input bindings
  * Focus state

---

#### Stack Management

* `Push(widget)` → Adds UI layer and focuses it
* `Pop()` → Removes top layer and restores previous focus
* `GetTop()` → Returns active root widget

---

#### Focus System

##### BuildFocusPath

Creates a full path from root → deepest focused child.

##### ApplyFocus

* Finds divergence between old and new paths
* Calls:

  * `OnFocusLeave`
  * `OnFocusEnter`
* Updates `FocusedChild` chain
* Triggers speech output

---

#### Speech System

##### BuildAnnouncement

Collects info from widgets and formats speech.

Order:

```
label → meta → position → state → tooltip
```

Controlled by settings:

```lua
CAISettings = {
    speakLabels = true,
    speakMeta = true,
    speakPosition = true
}
```

Output is passed to:

```lua
Speak(string)
```

---

#### Input Routing

```lua
HandleInput(input)
```

* Starts from deepest focused widget
* Bubbles up until handled
* Returns `true` if consumed

---

#### Context Integration

```lua
ContextPtr:SetInputHandler(...)
```

* Installed when stack is non-empty
* Removed when stack is empty

---

#### Utility Functions

* `Clear()` — destroys all widgets
* `IsEmpty()`
* `HasWidget(widget)`
* `RefreshInputHandler()`

---

## 3. Widget Templates (`widgetTemplates.lua`)

### Overview

Defines reusable widget behaviors and navigation logic.

---

### Navigation Helper

#### `NavigateSimpleList(w, direction)`

* Moves focus through children
* Skips hidden elements
* Supports wrap-around
* Prevents invalid boundary navigation

---

### Default Child Logic

```lua
GetContainerDefChild(w)
```

* Returns:

  * Focused child if exists
  * Otherwise first child

---

### Templates

#### Panel

* Navigation: Tab / Shift+Tab
* Wrap-around enabled
* Acts as general container

---

#### List

* Navigation: Up / Down
* Wrap-around enabled

---

#### HorizontalList

* Navigation: Left / Right

---

#### SubMenu

* Expand/collapse behavior:

  * Right → expand
  * Left → collapse
* Navigation only works when expanded

---

#### Button

* Enter key triggers `OnClick`

---

#### Slider

* Left/Right adjust value:

  * `Increment`
  * `Decrement`

---

#### Checkbox

* Space toggles state

---

#### GameView

Represents the main game map.

Keyboard input moves a cursor:

* Arrow keys → cardinal movement
* Numpad → hex-direction movement

Uses:

```lua
ExposedMembers.CAICursor
```

---

#### InterfaceMode

* Special template
* Disables role announcement (`AnnounceRole = false`)

---

## System Flow

1. Manager is created and exposed globally
2. UI creates widgets via templates
3. Widgets are pushed onto the stack
4. Focus is computed and updated
5. Speech is generated from widget metadata
6. Input is routed to the focused widget hierarchy

---

## Key Design Concepts

### Accessibility-First

* UI is described semantically instead of visually
* Every widget exposes structured info for speech

### Focus-Based Navigation

* Entire system revolves around focus paths
* Deepest focused widget receives input

### Template-Driven Behavior

* Navigation and input logic are defined per widget type
* No hardcoding in the manager

### Context-Bound Execution

* Manager exists per Civ VI UI context
* Communication happens via `ExposedMembers`

---

## Takeaway

This system is a compact, modular accessibility framework for Civilization VI that:

* Converts UI structure into spoken output
* Provides keyboard-driven navigation
* Cleanly separates structure (widgets), behavior (templates), and control (manager)

It is specifically designed to integrate with Civ VI’s context-based UI system rather than operate as a standalone UI framework.

```
```
