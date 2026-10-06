# Native UI layering and CAI synchronization

Investigation completed 2026-10-06 using checked-in vanilla/DLC Lua, XML,
Forge documentation and IDE stubs. This is a design investigation, not a runtime
fix. The configured Steam installation path was unavailable in this environment;
no engine execution or reproduction of the reported occurrence was performed.

## Findings

Civ VI uses several mechanisms together:

1. **Normal control hierarchy.** Declaration/sibling order determines ordinary
   rendering and mouse/touch precedence. Parent placement matters, and native
   reparenting can change it. A panel does not rise simply because it opened later.
2. **Popup queue.** QueuePopup applies priority and parameters. Some queued
   screens deliberately retain their parent placement for rendering and input.
   Delayed popups can enter the queue before they become visible.
3. **Modal stack.** PushModal/PopModal provide another native ownership mechanism.
   Control modality and ModalBlocksInput also affect input.
4. **Input contexts and handlers.** Reveal/Shell/World action contexts and native
   Lua handlers affect keyboard handling. Visual order alone is not a complete
   description of keyboard ownership, especially with tutorials and multiplayer.

Representative cases:

- ResearchChooser and EspionageChooser are ordinary animated TopLevelHUD
  children; ProductionPanel is a PartialScreens child. Their base open paths do
  not QueuePopup. TechTree also opens by unhiding its normal Screens context.
- GovernmentScreen queues at Low but explicitly retains normal rendering and
  input placement, and stays visible in the queue. ReligionScreen and multiple
  expansion screens use the same pattern.
- EspionagePopup queues at Low. TechCivicCompletedPopup queues at Low with
  DelayShow. ReportScreen queues at Medium without the parent-placement flags.
- InGamePopup uses PushModal. Frontend kick and hotseat-edit confirmations also
  use the modal stack.

Screen names and CAI widget types cannot determine native placement. A screen
called Popup can retain hierarchy placement; a normal screen can use QueuePopup.

## Why CAI diverges

CAI maintains an independent total order using priority, stickyTop and push
serial. A Low chooser pushed after a Low popup wins in CAI regardless of native
placement. Deferred population and animation callbacks make this timing-sensitive.
The EspionageChooser below-popup workaround is evidence of this existing mismatch,
but does not generalize to other screen pairs.

Popup wrappers can compound the mismatch. EspionagePopup and
TechCivicCompletedPopup only call the manager when their own CAI dialog is top;
otherwise they call the original handler. Native input can therefore act on the
popup while CAI focus describes a different screen. HandleInput itself uses
CurrentPath, not a native context owner. Push with ignoreFocus can also leave
CurrentPath and GetTop disagreeing temporarily.

Native queued contexts may be hidden temporarily and later shown again; CAI can
retain their roots. Keeping that state is useful, but being registered must be
distinct from currently eligible to receive input. Native context visibility is
not automatically linked to CAI widget IsHidden.

## Recommended design

Associate every native screen root with its owning ContextPtr. Keep registered
roots and their return focus alive independently of which root is eligible now.
Replace push-time approximation with a central resolver of current native
placement and input ownership. Proposed resolution process:

1. Snapshot native popup/modal state and the relevant live context hierarchy.
   Establish engine array direction, identity and flags first; do not guess them.
2. Resolve modal and popup placement using actual native state and parameters.
   RenderAtCurrentParent and InputAtCurrentParent must be considered separately.
   Queue membership alone must not promote a screen above normal hierarchy.
3. Resolve normal contexts by their current ancestor/sibling positions and live
   visibility. Account for temporary popup hiding, bulk hide and closing animation
   state. Do not hard-code a universal category order from one expansion XML.
4. Place CAI-only dialogs, lists and search views relative to their owner root.
   They inherit that owner's native placement and cannot outrank an unrelated
   native popup merely by receiving a later push serial or inherited priority.
5. Reconcile selected root and CurrentPath together before dispatch and speech,
   restoring cached focus only when ownership changes. Recheck ownership after
   synchronous activation changes it; retain down/up key ownership safeguards.
6. Use a common screen input bridge so the native context that receives an event
   can route it to the matching CAI owner. Define native fallback for unhandled
   input centrally and preserve CAI-inactive behavior. Merely consuming every
   event or dropping original callbacks would change vanilla behavior.

The engine may legitimately offer input to several contexts. The resolver should
model those exceptions explicitly while CAI chooses one accessible focus owner.
An unrepresented blocking native modal/popup must not silently grant background
CAI interaction; its owner needs an adapter or an explicit diagnostic.

Reconciliation should run at relevant lifecycle changes and immediately before
input, using cached context references and cheap live checks. Avoid scanning every
control on every key or rebuilding widgets just to refresh order. The existing
popup-change callback belongs to InGame's delayed-popup release logic; chain it
if used, and keep ordinary panel/modal lifecycle hooks too.

## Evidence and runtime questions

The native TunerUtilities already reads GetPopupStack entries as ID/Priority/Flags
and traverses GetRootContexts/GetChildren. GetModalContexts exists, but the vanilla
utility leaves its interpretation unfinished. The following need engine capture:

- Which end of popup/modal arrays is top, including equal-priority insertion?
- What object/path uniquely identifies a queued context? ID alone may collide.
- How do Flags expose parent placement, delayed showing and always-input behavior?
  Does GetPopupParameters expose those queue options as well as caller parameters?
- How are Current and Default priorities resolved in the native queue?
- What are the relative render/input rules for explicit modals and queued popups?
- Does IsVisible include hidden ancestors and popup suppression in these contexts?
- How do tutorials' always-input controls and multiplayer pause exceptions affect
  input traversal? Which root/context receives each key before it is consumed?

A focused debug capture should record native popup/modal state, owning context
paths/visibility, CAI stack/CurrentPath and the handler receiving each event during
popup-plus-late-chooser, chooser-plus-popup, modal-over-popup and close/restore
sequences. This is the proposed next implementation stage. It should establish
the unknown API contracts before building the resolver or migrating all screens.

Source anchors:

- [Base hierarchy](../decompiled/Assets/UI/InGame.xml) and
  [XP2 hierarchy](../decompiled/DLC/Expansion2/UI/Replacements/InGame.xml).
- [Government placement parameters](../decompiled/Assets/UI/Screens/GovernmentScreen.lua),
  [panel animation](../decompiled/Assets/UI/AnimSidePanelSupport.lua),
  [native introspection](../decompiled/Assets/UI/Utilities/TunerUtilities.lua).
- [Native popup lock/input context](../decompiled/Assets/UI/PopupManager.lua),
  [Forge control and input reference](Civ-6-Documentation/Civ6Docs.html).
- [CAI stack and dispatch](../src/UI/uiManager/CAIUIScreenManager.lua),
  [popup wrapper](../src/UI/inGame/EspionagePopup_CAI.lua),
  [chooser workaround](../src/UI/inGame/EspionageChooser_CAI.lua).
