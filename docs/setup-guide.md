# Setup Guide for New Accessibility Mod Projects

This guide is only needed for the initial project setup.

---

## Setup Interview

When the user first interacts with Claude in this directory (e.g., "Hello", "New project", "Let's go"), conduct this interview.

**Ask these questions ONE AT A TIME. Wait for the answer after EACH question.**

### Step 1: Experience Level

Question: How much experience do you have with programming and modding? (Little/None or A Lot)

- Remember the answer for the rest of the interview
- If "Little/None": Explain concepts contextually in the following steps (see "For Beginners" notes)
- If "A Lot": Brief, technical communication without detailed explanations

### Step 2: Game Name

Question: What is the name of the game you want to make accessible?

### Step 2b: Game Familiarity

Question: How well do you know this game? (Very well / Somewhat / Not at all)

- **"Very well"**: The user can guide feature prioritization and explain mechanics. Note this in project_status.md.
- **"Somewhat"**: The user has some knowledge but may need help understanding game systems. Note for later.
- **"Not at all"**: Mark for tutorial text extraction after decompilation (see Step 7b). During feature planning, Claude should explain discovered game mechanics in more detail.

Remember the answer - it affects Step 7b and Phase 1.5 (feature planning).

### Step 2c: Open Source Check

After learning the game name, **automatically** search for publicly available source code:

**Searches to perform:**
- Web search: "[Game Name] source code site:github.com"
- Web search: "[Game Name] open source game"
- Web search: "[Game Name] gitlab source"

**If the game has publicly available source code:**

Tell the user:

> Great news! [Game Name] appears to be open source. The source code is available at [URL]. This is a big advantage for accessibility modding:
>
> - We have the real source code with proper variable names, comments, and documentation — much easier to work with than decompiled output
> - We can potentially contribute our accessibility features directly to the game via a pull request
> - No decompilation needed — the code is easier to read and understand
> - We can build and test the game ourselves

**Ask:** "Do you want to work with the source code directly (recommended), or create a separate mod?"

#### Option A: Direct source modification (recommended)

**Advantages:**
- Real source with comments and documentation
- Can submit accessibility features as PR to the original project
- No decompiler, no MelonLoader/BepInEx needed
- Better integration, fewer compatibility issues with game updates
- Developers may review your code and help improve it

**Workflow changes:**
- Clone the repository instead of decompiling
- Set up the build environment following the project's own build instructions
- Skip Steps 5-7 (mod loader, Tolk setup, decompilation) — revisit as needed based on the game's architecture
- Screen reader integration depends on the game's audio/UI architecture
- Phase 1 analysis is much easier with real source code
- `decompiled/` directory is not needed — use the cloned source directly

**Important: License check!**

Read the repository's LICENSE file before starting work. Common licenses:
- **MIT, Apache, BSD:** Permissive — can modify freely, must include original license
- **GPL:** Must share modifications under same license (fine for accessibility mods — they should be open anyway)
- **Custom / "source available":** Read carefully — may restrict modifications or redistribution

If the license is unclear, note this in `project_status.md` and suggest the user ask the developers.

**Adapted setup steps for direct source work:**
1. Clone the repository to a local directory
2. Follow the project's README/build instructions to set up the development environment
3. Verify you can build and run the game from source
4. Identify how the game handles audio output and UI (this replaces the decompilation analysis)
5. Create a branch for accessibility work
6. Continue with Phase 1 analysis (much easier with real source)

#### Option B: Separate mod (if game has a plugin/mod system)

Sometimes useful even for open-source games:
- Game has an existing mod/plugin API
- Easier to distribute (users install a mod instead of building the game)
- Don't need to maintain a fork across game updates

If user chooses this: continue with normal setup flow (Step 3+), but use the source code for analysis instead of decompiling.

**If the game is NOT open source:** Continue with Step 3 normally. No action needed.

For beginners: "Open source" means the game developers have published the program's source code publicly. Think of it like getting the recipe instead of just the finished dish — we can see exactly how everything works, which makes adding accessibility features much easier. Some developers also accept contributions from the community, so our accessibility work could end up in the official game for everyone to benefit from.

---

### IMPORTANT: Limit Internet Research During Setup!

After learning the game name, **do NOT research game internals online** (UI systems, game mechanics, code structure, how specific features work). A rough genre/overview understanding is fine ("it's a turn-based RPG", "it's a city builder"), but detailed analysis of game systems **MUST wait for the decompiled source code** (Phase 1).

**Allowed internet research during setup:**
- Is the game open source? (Step 2c)
- What engine does it use? (Step 4)
- What mod loader does the community use? (Step 4b/4e)
- Is modding feasible for non-Unity engines? (Step 4d)

**NOT allowed before decompilation:**
- How the game's UI/menu system works
- What classes or systems the game uses internally
- Game architecture, state management, event systems
- Anything that belongs in Phase 1 analysis

**Why?** Internet information about game internals is unreliable — it may be outdated, wrong, or describe a different version. The decompiled source code is the only trustworthy source. Premature research wastes tokens and can lead to wrong assumptions that are hard to shake later.

---

### Step 3: Installation Path

Question: Where is the game installed? (e.g., `C:\Program Files (x86)\Steam\steamapps\common\GameName`)

### Step 4: Offer Automatic Check

After the game path is known, offer:

Question: Should I automatically check the game directory? I can detect the game engine, architecture (32/64-bit), and existing modding infrastructure.

**If yes:**

Perform these checks and collect the results:

1. **Detect game engine:**
   - Check if `UnityPlayer.dll` exists → Unity game
   - Check if `[GameName]_Data\Managed` directory exists → Unity game
   - Check for `.pak` files or `UnrealEngine`/`UE4` in filenames → Unreal Engine
   - Check for `libgodot` or `.pck` files → Godot
   - Check for `data.win` or `audiogroup` files → GameMaker
   - If unclear: Note as "Unknown engine"

2. **Detect architecture:**
   - `MonoBleedingEdge` directory present → 64-bit
   - `Mono` directory (without "BleedingEdge") → 32-bit
   - Files with "x64" in name → 64-bit
   - `.exe` file properties can also indicate architecture

3. **Check for existing modding infrastructure:**
   - `MelonLoader` directory → MelonLoader installed (Unity)
   - `BepInEx` directory → BepInEx installed (Unity)
   - `Mods` or `plugins` directory → Possible mod support
   - `UE4SS` or similar → Unreal modding tools
   - Workshop folder or Steam Workshop integration

4. **For Unity with mod loader - Read log (if present):**
   - **MelonLoader** (`MelonLoader/Latest.log`): Extract Game Name, Developer, Runtime Type (net35/net6), Unity Version
   - **BepInEx** (`BepInEx/LogOutput.log`): Check for successful initialization, Unity version, any errors

4b. **If no mod loader is installed — Search for community consensus:**
   - Web search: "[Game Name] mods"
   - Web search: "[Game Name] MelonLoader OR BepInEx"
   - Check Nexus Mods, Thunderstore, or game-specific mod sites
   - Note which mod loader other mods for this game use
   - If no existing mods found, note this — mod loader choice will be based on heuristics (see Step 4e)

5. **Check Unity Version (for Unity games):**
   - If Unity version is 4.x or older (3.x, 2.x): **Critical warning** - MelonLoader and BepInEx do NOT work, only Assembly-Patching possible. Games this old are rare but exist.
   - If Unity version is 5.x: **Warning** - MelonLoader may not work, try BepInEx 5.x first
   - If Unity version is 2017-2018: Usually works, but may need older MelonLoader version
   - If Unity version is 2019+: Full support, no issues expected
   - See `docs/legacy-unity-modding.md` for details on older Unity versions

5b. **Check Known Issues (`docs/known-issues.md`):**
   - Read `docs/known-issues.md` and check ALL categories against the detected configuration (engine, version, mod loader)
   - If any entry matches: **immediately warn the user** with the issue description and workaround
   - Log any matched warnings in `project_status.md` under a "Known Issues" section
   - If a match has no workaround, discuss alternatives with the user before continuing setup

6. **Check Tolk DLLs:**
   - For 64-bit: Check if `Tolk.dll` and `nvdaControllerClient64.dll` are in game directory
   - For 32-bit: Check if `Tolk.dll` and `nvdaControllerClient32.dll` are in game directory

**Summarize results:**

Show a summary of what was detected:
- Game engine: Unity / Unreal / Godot / GameMaker / Unknown
- Architecture: 64-bit / 32-bit / Unknown
- Mod loader: MelonLoader / BepInEx / Neither installed (+ community recommendation if searched)
- Mod loader log info: Game name, developer, runtime, Unity version (if available)
- Tolk DLLs: Present / Missing

Question: Is this correct? (Wait for confirmation)

**Next steps depend on the engine - see Step 4d below.**

**If no (manual check preferred):**

Continue with manual steps 4a-4c.

---

### Step 4d: Engine-Specific Next Steps

Based on the detected engine, proceed differently:

#### If Unity Game

Continue with Step 4e (Mod Loader). Unity games have the best modding support for accessibility mods.

#### If NOT a Unity Game

**Don't give up immediately!** But be honest about what is realistic. The feasibility depends heavily on the engine and on whether an active modding community exists for this specific game.

**First, always do these general checks:**

1. **Search for official modding support:**
   - Does the game have Steam Workshop integration?
   - Did the developer release modding tools or an SDK?
   - Is there a `Mods` folder or similar in the game directory?

2. **Search for community modding resources:**
   - Web search: "[Game Name] modding guide"
   - Web search: "[Game Name] mod loader"
   - Check Nexus Mods, Thunderstore, ModDB for existing mods
   - Look for game-specific Discord servers or forums

3. **Check what language the game code is written in:**
   - C# / .NET / Mono → Very moddable (see .NET games below)
   - Java → Moddable with Java-specific tools
   - Lua scripts in game directory → Moddable by editing scripts
   - Python scripts in game directory → Moddable by editing scripts
   - C++ only → Difficult (see sections below)

For beginners: Different games use different "engines" (the underlying technology). Each engine needs different tools for modding. Games written in C# or with scripting languages (Lua, Python) are generally much easier to mod than pure C++ games.

**Then proceed based on the detected engine:**

---

##### Unreal Engine (UE4 / UE5)

**NOTE: The information in this section is based on research, not on proven accessibility modding experience. No established pattern for screen reader accessibility mods in Unreal games exists yet. Use this as a starting point for investigation, not as a guaranteed workflow.**

**How to identify:** `.pak` files, `UE4` or `UE5` in filenames, `Engine/Binaries` directory structure.

**What exists:**
- **UE4SS** (RE-UE4SS) is the community-standard modding framework for Unreal games. It injects into the game and provides a Lua scripting layer and C++ mod API. Comparable in role to MelonLoader/BepInEx, but for Unreal.
- UE4SS can hook reflected game functions (similar concept to Harmony, but only for functions tagged as UFUNCTION in the engine's reflection system — not arbitrary C++ functions).
- Lua mods can read/write game object properties, hook function execution, and react to game events.
- C++ mods compiled as DLLs can in theory call Tolk for screen reader output.

**Analysis tools:**
- UE4SS generates SDK/header dumps showing class names, properties, and function signatures — this is the closest equivalent to Unity decompilation, but gives only API structure, not implementation code.
- FModel extracts and browses game assets from .pak files.
- KismetKompiler can decompile Blueprint bytecode (for Blueprint-heavy games).

**Accessibility barriers for blind modders:**
- FModel and the UE4SS Live Property Viewer are visual GUI tools — **not accessible with a screen reader**.
- The SDK/header dump output is text-based and could be searched with CLI tools — this part is accessible.
- There are **no existing screen reader accessibility mods** for any Unreal game to learn from. This would be uncharted territory.
- Game code analysis is harder than Unity because you only get API signatures, not full source code.

**Realistic assessment:**
- **Feasible if:** The game has an active UE4SS modding community with documented hooks and APIs. Other mods exist that demonstrate how to access the game's data. A sighted collaborator could help with the initial analysis using visual tools.
- **Not feasible if:** No modding community exists, the game doesn't work with UE4SS, or key game logic is in non-reflected native C++ functions.
- **Our template is NOT directly applicable.** The mod language is Lua or C++ (not C#), the patching system is different, and the project structure is completely different. The accessibility patterns (Handler classes, ScreenReader wrapper, Loc system) could be adapted conceptually, but the code would need to be rewritten.

**If proceeding:** Research UE4SS compatibility for this specific game first. Check the UE4SS Discord and documentation. Document findings in `docs/game-api.md`.

---

##### Godot Engine

**NOTE: The information in this section is based on research, not on proven accessibility modding experience. Use this as a starting point, not as a guaranteed workflow.**

**How to identify:** `.pck` files, `libgodot` files, Godot splash screen.

**What exists:**
- **Godot Mod Loader** is the primary modding framework — but it **must be integrated by the game developer**. It cannot be injected from outside (unlike MelonLoader/BepInEx). If the game doesn't include it, script-level modding is very limited.
- Without the Mod Loader: mods work by replacing game files via PCK packages. Decompile game scripts, modify them, repack as PCK. This is fragile and breaks on game updates.
- **Godot 4.5+** (released September 2025) has built-in AccessKit screen reader support. If the game uses Godot 4.5+ and standard UI nodes, the UI may already be partially accessible to screen readers without any modding.
- Godot is fully open source (MIT license), so the engine internals are documented.

**Analysis tools:**
- **gdsdecomp / GDRE Tools** can decompile GDScript bytecode back to readable source — similar to dnSpy for .NET. This is a CLI tool and should be usable with a screen reader.
- **GdTool** is a CLI tool for compiling/decompiling GDScript and managing PCK files.

**Accessibility barriers for blind modders:**
- If the game lacks the Godot Mod Loader: only PCK file replacement works, which is labor-intensive and fragile.
- The mod language is GDScript (not C#), requiring learning a new language.
- No known accessibility mods exist for any Godot game yet.

**Realistic assessment:**
- **Best case:** Game uses Godot 4.5+ (AccessKit may be built in) AND has the Godot Mod Loader integrated. Then GDScript mods with TTS calls are possible.
- **Moderate case:** Game can be decompiled with gdsdecomp, scripts modified, and repacked. Works but is fragile.
- **Worst case:** Game uses Godot 3.x without Mod Loader. Limited to script replacement, no built-in accessibility support.
- **Our template is NOT directly applicable** (different language, different mod structure), but the accessibility patterns (modular handlers, localization, screen reader wrapper) transfer conceptually.

---

##### .NET Games (XNA, MonoGame, FNA, other .NET frameworks)

**How to identify:** Game DLLs can be opened with dnSpy/ILSpy and show readable C# code. Look for `MonoGame.Framework.dll`, `FNA.dll`, `Microsoft.Xna.Framework.dll`, or other .NET assemblies in the game directory.

**Good news: These games are moddable with the same tools as Unity games.**

- **BepInEx** explicitly supports .NET framework games beyond Unity, including XNA, MonoGame, and FNA games.
- **Harmony** patching works the same way as with Unity — runtime IL patching of any .NET method.
- **dnSpy / ILSpy** decompile the game code to readable C#, just like with Unity.
- **Tolk** integration works identically.

**Proven examples:**
- Stardew Valley (MonoGame) has SMAPI, a dedicated mod loader with thousands of mods
- Celeste (MonoGame) has the Everest mod loader

**Realistic assessment:**
- **Our template is largely applicable.** The accessibility patterns, Handler structure, ScreenReader wrapper, and Loc system all work. The main differences are in project setup (different DLL references, no MelonLoader/Unity-specific lifecycle) and potentially different entry points.
- **Feasibility is similar to Unity** — if you can decompile the DLLs and BepInEx works, the full workflow applies.

**If proceeding:** Try BepInEx first. Use dnSpy to analyze the game code. Adapt the template's Main.cs to use BepInEx's `BaseUnityPlugin` pattern (or the appropriate base class for the specific .NET framework). The rest of the template (Handlers, ScreenReader, Loc) needs minimal changes.

---

##### Java Games

**NOTE: Java game modding is well-established (Minecraft is the largest modding community in gaming), but uses completely different tooling than our C#-based template.**

**How to identify:** `.jar` files, Java Runtime required, `jre` or `jdk` directories.

**What exists:**
- Java bytecode preserves metadata (class names, method names) similar to .NET — decompilation gives readable code.
- **Minecraft** has mature mod loaders: Fabric (lightweight, uses Mixin for bytecode injection) and NeoForge (comprehensive APIs). The Mixin system is conceptually similar to Harmony.
- Other Java games may not have established mod loaders, but Java decompilers (JD-GUI, Fernflower, CFR) and bytecode manipulation libraries exist.

**Accessibility barriers:**
- Our template (C#, .NET, Tolk) is not applicable — Java uses a different ecosystem.
- Tolk has no Java bindings (would need JNI or JNA to call the native DLL).
- The development workflow, build tools, and project structure are completely different.

**Realistic assessment:**
- **Feasible for Minecraft** and other Java games with established mod loaders — but requires Java development knowledge and game-specific tools.
- **Our template is NOT applicable** in terms of code, but the accessibility concepts (modular handlers, screen reader integration, localization) transfer to any language.
- If someone wanted to create a Java accessibility modding template, it would be a separate project.

---

##### Games with Embedded Lua Scripting

**How to identify:** Look for `lua51.dll`, `lua52.dll`, `lua53.dll`, `lua54.dll`, or `luajit.dll` in the game directory. Also look for `.lua` or `.luac` files.

**What exists:**
- Many custom engines embed Lua as a scripting layer. If the game loads Lua scripts from files, these can be modified or extended.
- Games with comprehensive Lua APIs include: World of Warcraft (UI addons), Factorio (full gameplay mods), Don't Starve, Garry's Mod.
- LuaJIT's FFI (Foreign Function Interface) can call native DLLs — meaning Tolk could potentially be called from Lua mods.

**Realistic assessment:**
- **Highly game-specific.** Some Lua-scripted games have rich APIs and active communities (Factorio, WoW). Others just use Lua for internal configuration with no modding surface.
- **If Lua scripts are editable and documented:** This can be a viable path. The mod would be written in Lua instead of C#, and Tolk could be called via FFI.
- **If Lua bytecode is compiled (`.luac` files only):** Decompilation is possible but less reliable than GDScript or .NET decompilation.
- **Our template is NOT directly applicable** (different language), but the patterns transfer.

---

##### Games with Embedded Python

**How to identify:** Look for `python*.dll` in the game directory, or `.py` / `.pyc` files.

**What exists:**
- **Ren'Py** (visual novel engine): Built on Python, open source, easy to mod by editing `.rpy` script files. Has a community.
- Some custom engines embed Python for scripting.
- Python's `ctypes` library can call native DLLs — Tolk integration is straightforward from Python.
- `.pyc` files (compiled Python bytecode) can be decompiled with tools like `uncompyle6` or `decompyle3`.

**Realistic assessment:**
- **Ren'Py games:** Relatively easy to mod. Scripts are often shipped as readable `.rpy` files. Accessibility mods could add TTS calls.
- **Other Python-scripted games:** Depends on how much of the game logic is in Python and whether scripts are accessible.
- **Our template is NOT directly applicable** (different language), but the patterns transfer.

---

##### Custom or Proprietary Engines

**NOTE: This section describes the general investigation process when a game uses an unfamiliar, custom, or proprietary engine. The goal is to systematically assess whether accessibility modding is feasible before investing significant time.**

**How to identify:** The game doesn't match any of the known engines above (no UnityPlayer.dll, no .pak files, no Godot markers, no .NET assemblies, no Java). The game may use a lesser-known open-source engine (Torque, OGRE, Irrlicht, etc.), a heavily modified version of a known engine, or something entirely custom-built.

**Step 1: Identify the engine**

Search systematically:
- Web search: "[Game Name] game engine"
- Web search: "[Game Name] what engine"
- Web search: "[Game Name] technology" or "[Game Name] made with"
- Check PCGamingWiki (often lists the engine)
- Check Wikipedia article for the game
- Check developer interviews or devblogs
- Look at DLL files in the game directory for engine-specific names

**Step 2: Check if the engine is open source**

If you identified the engine name:
- Web search: "[Engine Name] open source"
- Web search: "[Engine Name] github"
- Check the engine's license (MIT, GPL, proprietary?)

**Important distinction:** An open-source engine does NOT mean the game is open source. The game may be a commercial product built on an open-source engine. The engine source helps understand internals, but you still can't access the game's specific source code unless the developer shares it.

**Step 3: Investigate the scripting layer**

This is the most critical question for accessibility modding. Search for:
- Web search: "[Engine Name] scripting language"
- Web search: "[Game Name] modding scripting"
- Look in the game directory for script files (.lua, .py, .cs, .js, .gd, .sq, .nut, or engine-specific extensions)
- Check if scripts are plain text (readable) or compiled bytecode

**Key question: Can the scripting language call external DLLs (like Tolk)?**

- **Yes, natively** (e.g., Lua with FFI, Python with ctypes): Screen reader integration is possible from within mods
- **No native FFI**: Screen reader output requires either engine modification (C++ level) or workarounds (file-based, clipboard-based) — both fragile or requiring sighted help
- **No scripting layer at all**: Falls into the "Pure C++ Games" category below

**Step 4: Check for existing modding support**

- Web search: "[Game Name] modding support"
- Web search: "[Game Name] mods"
- Check Nexus Mods, ModDB, Steam Workshop
- Check if the developer released modding tools or documentation
- Look for a `mods/` folder or similar in the game directory

**Step 5: Assess the modding surface**

If modding exists, determine what can be modified:
- **Content only** (textures, levels, translations): Not sufficient for accessibility mods
- **Game logic via scripts** (combat, AI, events, dialogs): Useful, but need screen reader bridge
- **UI/GUI modification possible**: Critical for menu accessibility
- **Plugin/DLL loading**: Best case — could load a native DLL with Tolk

**Step 6: Evaluate feasibility for accessibility**

Rate the situation honestly:

**Feasible (proceed with caution):**
- Game has script-level modding AND the scripting language can call native DLLs (Tolk)
- OR: Game loads native plugins/DLLs that can hook into game events
- Active modding community with documentation

**Partially feasible (significant limitations):**
- Script-level modding exists but no way to call Tolk from scripts
- Workarounds possible (file-based TTS bridge, clipboard monitoring) but add latency and fragility
- Engine is open source so Tolk integration could theoretically be added at the engine level, but this requires C++ compilation and likely sighted assistance
- UI/game logic can be modified but screen reader output requires external tools

**Not feasible (be honest with the user):**
- No modding support and no way to inject code
- Engine is closed-source C++ with no scripting layer
- The only "modding" is asset replacement (textures, sounds)

**When partially feasible, discuss options with the user:**

> This game uses [Engine Name], which has [scripting/modding support], but there's no direct way to send text to your screen reader from within a mod. Here are the realistic options:
>
> 1. **Contact the developer** — Ask if they'd add screen reader support or share their engine build so we can add Tolk integration. This is the most sustainable path.
> 2. **External bridge tool** — We write a small companion program that monitors a file or the clipboard for text from the mod and speaks it via the screen reader. This works but adds latency and complexity.
> 3. **Engine modification** (if open source) — Add a native function to the engine's scripting language that calls Tolk. Requires C++ development and someone who can compile the engine.
> 4. **Community help** — Check if sighted modders or developers would collaborate on the screen reader integration piece.

**Our template is NOT directly applicable** for custom engines (different language, different architecture), but the accessibility patterns (modular handlers, screen reader wrapper concept, localization, state tracking) transfer conceptually to any language.

---

##### Pure C++ Games (No Scripting Layer)

If the game is written purely in C++ without any scripting layer (Lua, Python, C#), be upfront with the user:

> **Important notice:** Games written purely in C++ are extremely difficult to mod for accessibility — especially for blind modders. Here's why:
>
> The tools that sighted reverse engineers use (Cheat Engine, ReClass, Frida, x64dbg) are fundamentally **not accessible with a screen reader**. They require visually navigating the game, inspecting memory layouts on screen, and cross-referencing visual game state with memory addresses. A blind user cannot independently perform these steps.
>
> Even if someone sighted helped find memory addresses, the results are **unreliable**: addresses change between game sessions, game updates, and system configurations. Building stable accessibility features on shifting memory addresses is not a viable foundation.
>
> **Realistically, a pure C++ game is moddable for accessibility only if:**
>
> 1. **An established modding community exists** with documented tools and APIs. If other mods exist, we can study their approach and build on proven methods.
> 2. **The game has official modding support** — an SDK, plugin API, or scripting interface that provides stable, named access to game data.
> 3. **The game stores data in accessible formats** — readable config files, save files, or APIs that can be parsed externally.
>
> **If none of these apply:**
>
> Be honest: this game is currently not moddable for accessibility by a blind modder. This is not a skill issue — it's a tooling and access barrier.
>
> Suggest alternatives:
> - Contact the game developer directly and request accessibility features or an accessibility API
> - Check if there's a community accessibility project already underway (sighted volunteers sometimes lead these)
> - Look for a different game with similar gameplay that uses a moddable engine
> - Check if the developer is open-source-friendly — even partial access (game data files, documentation) can help

---

##### Games with Official Modding SDKs

Some games ship with official modding tools regardless of engine. If the auto-check or community search found an SDK, mod editor, or documented mod API:

- **This is always the preferred path.** Official tools are more stable and better documented than reverse engineering.
- Check what the SDK allows: content/asset mods only, or also code/logic mods?
- For accessibility, we need code-level access (to add screen reader calls). Asset-only SDKs (level editors, texture swaps) are not sufficient.
- If the SDK provides a scripting interface (Lua, Python, C#), accessibility mods may be feasible. Evaluate on a case-by-case basis.

---

##### If No Modding Path Is Found

Be honest with the user — some games cannot be modded. Factors that make modding difficult or impossible:
- No established modding community or tools for this specific game
- Heavy DRM or anti-cheat (blocks DLL injection and memory access)
- Fully compiled C++ without scripting layer or modding API
- Online-only games with server-side logic
- Very obscure or proprietary engines

**Important:** Do not suggest approaches that require tools inaccessible to screen reader users (Cheat Engine, memory scanners, visual debuggers) without clearly stating this limitation. Recommending inaccessible tools wastes time and creates frustration.

**Disclaimer:** The engine-specific information above is based on research and may be incomplete or outdated. Game modding ecosystems evolve rapidly. Always verify current compatibility for the specific game.

---

### Manual Steps (only if automatic check was declined)

#### Step 4a: Game Engine (manual)

Question: Do you know which game engine the game uses?

- Hints for identifying Unity: `UnityPlayer.dll` in game directory or a `[GameName]_Data\Managed` directory
- Hints for Unreal Engine: `UnrealEngine` or `UE4` in filenames, `.pak` files
- Hints for Godot: `libgodot` files or `.pck` files
- Hints for GameMaker: `data.win` file
- If unclear: User can look in game directory or you help with identification

**If NOT a Unity game:** See Step 4d above for how to proceed.

#### Step 4b: Architecture (manual)

Question: Do you know if the game is 32-bit or 64-bit?

Hints for finding out:
- `MonoBleedingEdge` directory = usually 64-bit
- `Mono` directory = usually 32-bit
- Files with "x64" in name = 64-bit

**IMPORTANT:** The architecture determines which Tolk DLLs are needed!

#### Step 4c: Mod Loader (manual, Unity only)

Question: Is a mod loader (MelonLoader or BepInEx) already installed?

Hints for finding out:
- `MelonLoader` directory in game folder → MelonLoader is installed
- `BepInEx` directory in game folder → BepInEx is installed
- Neither → Need to install one (see Step 4e)

For beginners: A mod loader is a program that loads our mod code into the game. Both MelonLoader and BepInEx come with "Harmony", a library for hooking into game functions. We don't need to download Harmony separately.

---

### Step 4e: Mod Loader Selection (Unity only)

**Goal:** Determine which mod loader to use for this game. This is critical — using the wrong mod loader can mean the mod won't work at all.

**If a mod loader was already detected (auto-check or manual):**

Use the one that's installed. If both are installed, ask which one the user prefers (usually stay with whatever the game's modding community uses).

**If no mod loader is installed yet:**

1. **Search for community consensus:**
   - Web search: "[Game Name] mods"
   - Web search: "[Game Name] modding guide"
   - Check Nexus Mods, Thunderstore, or game-specific mod sites
   - Look at what other mods for this game use

2. **Evaluate the results:**
   - If the community uses **MelonLoader**: Use MelonLoader
   - If the community uses **BepInEx**: Use BepInEx
   - If **both** are used: Either works — ask user preference or recommend what the majority uses
   - If **no mods exist** for this game: See guidance below

3. **General heuristics (when no community guidance exists):**
   - Il2Cpp games (no `[Game]_Data\Managed` folder, or MelonLoader log says "Il2Cpp"): **MelonLoader** is generally more reliable
   - Mono games (classic `[Game]_Data\Managed` folder with `Assembly-CSharp.dll`): Both work, BepInEx has more community resources
   - Very old Unity versions (5.x): Try **BepInEx 5.x** first, MelonLoader may not support it

**Key differences for the user:**

- **MelonLoader:** Installs via an installer EXE. Mods go in the `Mods/` folder. Has its own log file (`MelonLoader/Latest.log`).
- **BepInEx:** Installs by extracting a ZIP into the game folder. Mods (plugins) go in the `BepInEx/plugins/` folder. Has its own log file (`BepInEx/LogOutput.log`).
- **Both:** Include Harmony for patching. Both support Tolk for screen reader output. The core mod code (Handler classes, ScreenReader wrapper, Loc system) is nearly identical.

For beginners: Think of mod loaders like different brands of power adapters — they both deliver electricity (load your mod), just with slightly different plugs (setup and structure). The important part — your mod's actual features — works the same way with either one.

**If no mods exist for this game at all:**

This is not necessarily a blocker, but it means:
- No one has verified that a mod loader works with this game
- There may be anti-cheat, DRM, or other obstacles
- Installation might require troubleshooting

Suggest trying the mod loader that matches the game's runtime (MelonLoader for Il2Cpp, either for Mono). If it doesn't work, try the other one. Document the findings.

**Installation instructions:**

**MelonLoader:**
- Download: https://github.com/LavaGang/MelonLoader.Installer/releases
- Run the installer and point it at the game's EXE
- After installation there should be a `MelonLoader` directory in the game directory
- Start game once to create directory structure and generate the log file

**BepInEx:**
- Download: https://github.com/BepInEx/BepInEx/releases
- For Unity Mono games: Download the appropriate build (x64 or x86, matching game architecture)
- For Unity Il2Cpp games: Download the Il2Cpp build (though MelonLoader is usually better for Il2Cpp)
- Extract the ZIP contents into the game directory (where the game EXE is located)
- Start game once to create directory structure (`BepInEx/plugins/`, `BepInEx/config/`, etc.)

**After installation:** Continue with Step 5 (Tolk).

**Record the chosen mod loader** in `project_status.md` — it affects the project structure, build configuration, and code templates.

**Template selection based on mod loader:**

Templates are organized into three directories:
- `templates/melonloader/` — MelonLoader-specific files (Main.cs, DebugLogger.cs, ModConfig.cs, ScreenReader.cs, csproj)
- `templates/bepinex/` — BepInEx-specific files (same set, adapted for BepInEx APIs)
- `templates/shared/` — Mod-loader-independent files (Handler.cs, Loc.cs, AccessStateManager.cs, ReflectionHelper.cs, project_status.md, game-api.md)

When creating project files later, **always use the templates matching the chosen mod loader** plus all shared templates. The key differences:
- **MelonLoader:** `MelonMod` base class, `MelonLogger`, `MelonPreferences`, output to `Mods/`
- **BepInEx:** `BaseUnityPlugin` base class, `ManualLogSource`, `ConfigFile`, output to `BepInEx/plugins/`

---

### Step 5: Tolk (if reported as missing during automatic check)

If Tolk DLLs are missing, explain:
- Download: https://github.com/ndarilek/tolk/releases
- **IMPORTANT: You need BOTH DLLs — not just Tolk.dll!**
- For 64-bit: `Tolk.dll` + `nvdaControllerClient64.dll` from the x64 directory
- For 32-bit: `Tolk.dll` + `nvdaControllerClient32.dll` from the x86 directory
- Copy BOTH DLLs to the game directory (where the .exe is located)
- Without `nvdaControllerClient*.dll`, NVDA will get no output! (JAWS works via COM, no extra DLL needed)

For beginners: Tolk is a library that can communicate with various screen readers (NVDA, JAWS, etc.). Our mod uses Tolk to send text to your screen reader. Tolk.dll is the bridge, and nvdaControllerClient*.dll is specifically needed so NVDA can receive the text.

### Step 6: .NET SDK

Question: Do you have the .NET SDK already installed?

Check with: `dotnet --version` in PowerShell.

If no, install via WinGet (preferred — Claude Code can run this automatically):

```powershell
winget install Microsoft.DotNet.SDK.8
```

After installation, **restart the terminal** so the `dotnet` command is available.

If WinGet is not available, manual download: https://dotnet.microsoft.com/download (recommended: .NET 8 SDK or newer).

For beginners: The .NET SDK is a development tool from Microsoft. We need it to compile our C# code into a DLL file that the mod loader (MelonLoader or BepInEx) can then load.

### Step 7: Decompilation

Question: Do you have a decompiler tool (dnSpy or ILSpy) installed?

If no, explain options:

**ILSpy (recommended):**

Install the command-line tool via dotnet (preferred — Claude Code can run this automatically):

```powershell
dotnet tool install ilspycmd -g
```

After installation, **restart the terminal** so the `ilspycmd` command is available.

- **Advantage:** Fully command-line controlled, Claude Code can automate the entire decompilation
- Command-line usage: `ilspycmd -p -o decompiled "[Game]_Data\Managed\Assembly-CSharp.dll"`
- This makes the entire decompilation process automatable — Claude Code can do it for you

Optionally, also install the GUI version via WinGet:

```powershell
winget install icsharpcode.ILSpy
```

If neither WinGet nor dotnet tool is available, manual download: https://github.com/icsharpcode/ILSpy/releases

**dnSpy (alternative):**
- Download: https://github.com/dnSpy/dnSpy/releases
- Not available via WinGet (discontinued project)
- GUI-based tool with manual workflow
- Use it to decompile `Assembly-CSharp.dll` from `[Game]_Data\Managed\`
- The decompiled code should be copied to `decompiled/` in this project directory

**Screen reader instructions for dnSpy:**
1. Open DnSpy.exe
2. Use Ctrl+O to select the DLL (e.g., Assembly-CSharp.dll)
3. In the "File" menu, select "Export to Project"
4. Press Tab once - lands on an unlabeled button for target directory selection
5. There, select the target directory (best to create a "decompiled" subdirectory in this project directory beforehand, so Claude Code can easily find the source code)
6. After confirming the directory selection, press Tab repeatedly until you reach the "Export" button
7. The export takes about half a minute
8. Then close dnSpy

For beginners: Games are written in a programming language and then "compiled" (translated into machine code). Decompiling reverses this - we get readable code. We need this to understand how the game works and where to hook in our accessibility features.

### Step 7b: Tutorial Text Extraction (if user is not familiar with the game)

If the user indicated in Step 2b that they don't know the game well ("Somewhat" or "Not at all"):

**Offer:** "I can search the decompiled code and game files for tutorial texts, help texts, and gameplay instructions. I'll write them to a file so you can read through the game mechanics before or while we start modding. Should I do that?"

**If yes:**

1. **Search decompiled code for tutorial/help text:**
   ```
   Grep pattern: Tutorial
   Grep pattern: [Hh]elp[Tt]ext
   Grep pattern: [Ii]nstruction
   Grep pattern: [Hh]ow[Tt]o
   Grep pattern: [Tt]ip[Ss]
   Grep pattern: [Hh]int
   Grep pattern: [Gg]uide
   ```

2. **Search for localization/resource files:**
   - Look in `[Game]_Data/StreamingAssets/` for JSON, XML, CSV, or TXT files
   - Look in `[Game]_Data/Resources/` for text assets
   - Search for files containing "tutorial", "help", "tips" in their names
   - Check localization files for keys containing these terms

3. **Language preference:**
   - Try to find texts in the user's language first
   - Fall back to English if the user's language is not available
   - If multiple languages exist, extract the user's language + English

4. **Write findings to `docs/tutorial-texts.md`:**
   - Organize by topic/game mechanic where possible
   - Include context (which class/file the text came from)
   - Mark unclear or fragmentary texts as such
   - Add a note that these are extracted game texts, not mod documentation

5. **Summarize for the user:**
   - Brief overview of what was found
   - Which game mechanics are covered
   - Any gaps (mechanics that seem to exist but have no tutorial text)

**If no:** Continue with Step 8. The user can always request this later.

For beginners: Game tutorials explain the basic mechanics step by step. Reading these texts helps you understand what the game does, which is useful for deciding which features need accessibility support first.

### Step 8: Languages

**IMPORTANT: Localization is NOT optional.** All strings that the screen reader announces MUST go through `Loc.Get()` from the very first feature. `Loc.cs` is created as part of the basic framework in Phase 2. This is non-negotiable because:
- Retrofitting localization later means touching every single handler - a massive waste of time
- Even a "monolingual" mod benefits from having all strings in one place
- Adding a new language later is trivial when the system is already in place

Question: Which languages should the mod support? Recommend starting with 1-3:

1. **English** (always - serves as fallback and reaches the most users)
2. **Your native language** (if different from English)
3. **Optionally:** One more language if you or someone you know can translate

**Advice for the user:**
- Start with 1-2 languages. You can always add more later.
- Adding a new language is straightforward: add a dictionary, extend the `Add()` method, then fill in all strings at once. This can even be done by someone who doesn't code - they just need the list of keys and English strings.
- Focus on getting the mod working first. Don't spend weeks translating before the features are done.
- If the game has its own translation system, use the game's translations for game-specific terms (item names, menu labels) where possible. Only translate your own mod strings.
- 5+ languages is a lot of maintenance. Consider that only after the mod is stable and you have translators willing to help.

If the mod will support more than one language:
- The game's language system must be analyzed during decompilation
- Search for: `Language`, `Localization`, `I18n`, `currentLanguage`, `getAlias()`
- See `localization-guide.md` for complete instructions

Use `templates/shared/Loc.cs.template` as starting point (always, regardless of language count).

### Step 9: Set Up Project Directory

After the interview:
- **Determine mod name:** `[GameName]Access` - abbreviate if 3+ words (e.g., "PetIdleAccess", "DsaAccess" for "Das Schwarze Auge")
- Create `project_status.md` from `templates/shared/project_status.md.template` - fill in all collected information and check off completed setup steps. **This is the central tracking document for the entire project.** Update it at every significant milestone: features completed, bugs discovered, architecture decisions, notes for the next session.
- Create `docs/game-api.md` from `templates/shared/game-api.md.template` as placeholder for game discoveries
- Enter the concrete paths in CLAUDE.md under "Environment"

#### Trim CLAUDE.md after setup

Once `project_status.md` is created, trim CLAUDE.md to save tokens for the rest of the project:

1. **Replace the "Project Start" section** with:
   ```
   ## Session Start
   On greeting:
   1. Read `project_status.md` — summarize phase, last work, pending tests, notes
   2. If pending tests exist, ask user for results before continuing
   3. Suggest next steps or ask what to work on
   Update `project_status.md` on significant progress and before session end.
   ```

2. **Remove from References:**
   - `docs/setup-guide.md` — no longer needed
   - `docs/legacy-unity-modding.md` — remove if this game is NOT an old Unity version (5.x or earlier)

This saves tokens per message for the entire project lifetime.

---

## User Checklist (to read aloud)

After the interview, read this checklist:

- Game architecture known (32-bit or 64-bit)
- Mod loader installed and tested: MelonLoader (game starts with MelonLoader console) or BepInEx (BepInEx log file created)
- Tolk DLLs in game directory (matching the architecture!)
- Decompiler tool ready
- Assembly-CSharp.dll decompiled and code copied to `decompiled/` directory

**Tip:** The validation script checks all points automatically:
```powershell
.\scripts\Test-ModSetup.ps1 -GamePath "C:\Path\to\Game" -Architecture x64
```

---

## Token Management and Conversations

**Explain this to the user early (during or after setup):**

Claude Code re-reads the entire conversation every time you send a message. This means long conversations cost increasingly more tokens. To be efficient:

- **Start a new conversation** whenever you finish a feature or a distinct task. Don't keep going in the same conversation for hours.
- **Roughly 30-40 messages** is a good point to consider starting fresh.
- **Before starting a new conversation:** Claude should always update `project_status.md` so the next conversation knows exactly where things stand.
- **When you come back:** Just say "hello" or "let's continue" - Claude reads `project_status.md` and picks up where you left off.

This is not a limitation but a workflow advantage: fresh conversations have a clear context and make fewer mistakes.

---

## Session 2+ Workflow

**Explain this to the user at the end of the first session (or when they ask about the workflow):**

### What you need to do

- **Starting a session:** Just say "hello", "let's continue", or jump straight in with "I tested the menu, here's what happened: ..."
- **You don't need to repeat** the game name, the project setup, what was done before, or technical details. Claude reads `project_status.md` and knows all of that.
- **Reporting test results:** Just describe what happened naturally. "The menu works but item 3 is skipped" or "Nothing happens when I press F2" is enough. Claude will ask follow-up questions if needed.
- **Requesting features:** "Let's do the inventory next" or "Can we add health announcements?" — Claude checks the feature plan and starts working.
- **If something feels wrong:** "I think X broke since last time" — Claude will investigate.

### What Claude does automatically

1. Reads `project_status.md` — knows current phase, all features, issues, and notes from last session
2. If there are pending tests, asks you about the results
3. Suggests what to work on next (or asks)
4. Before the session ends, updates `project_status.md` with everything that happened

### The cycle

```
Session start → Claude reads project_status.md → summarizes → asks what to do
  → You say what to work on (or Claude suggests)
  → Claude codes → builds → you test in game → report results
  → Repeat until feature is done
  → Claude updates project_status.md → suggests new session
```

### When things go wrong between sessions

- **Game updated and mod broke:** Tell Claude, it will check what changed
- **You forgot what was planned:** Just say "hello" — Claude tells you
- **You want to change direction:** Just say so, Claude adapts the plan
- **You lost your test notes:** Claude can rebuild context from `project_status.md` and the code

---

## Next Steps

After completing setup, proceed in this order:

0. **Read ACCESSIBILITY_MODDING_GUIDE.md** - Read `docs/ACCESSIBILITY_MODDING_GUIDE.md` completely, especially the "Source Code Research Before Implementation" section. This guide defines the patterns and rules for the entire project.

0b. **For older Unity versions (5.x or earlier):** Read `docs/legacy-unity-modding.md` for important information about compatibility issues, alternative mod loaders, and Assembly-Patching as fallback. Keep this in mind during analysis - some patterns may need adaptation.

1. **Source code analysis** (Phase 1 below) - Tier 1 is mandatory before any coding
2. **Search/analyze tutorial** (Section 1.10) - Understand mechanics, often high priority
3. **Create feature plan** (Phase 1.5) - Most important features in detail, rest roughly
4. **Fill game-api.md** - Document findings from the analysis (ongoing, but Tier 1 results MUST be in before Phase 2)

---

## CRITICAL: Before First Build - Check Log!

**These values MUST be read from the mod loader's log, NEVER guess!**

### For MelonLoader

#### Automatically with Script (recommended)

```powershell
.\scripts\Get-MelonLoaderInfo.ps1 -GamePath "C:\Path\to\Game"
```

The script extracts all values and displays the finished MelonGame attribute.

#### Manually (if script not available)

**Step 1:** Start game once with MelonLoader (creates the log).

**Step 2:** Log path: `[GameDirectory]\MelonLoader\Latest.log`

Search for these lines and note the EXACT values:

```
Game Name: [COPY EXACTLY]
Game Developer: [COPY EXACTLY]
Runtime Type: [net35 or net6]
```

#### Enter Values in Code/Project (MelonLoader)

**MelonGame Attribute (Main.cs):**
```csharp
[assembly: MelonGame("DEVELOPER_FROM_LOG", "GAME_NAME_FROM_LOG")]
```
- Capitalization MUST match exactly
- Spaces MUST match exactly
- With wrong name, the mod will load but NOT initialize!

**TargetFramework (csproj):**
- If log says `Runtime Type: net35` → use `<TargetFramework>net472</TargetFramework>`
- If log says `Runtime Type: net6` → use `<TargetFramework>net6.0</TargetFramework>`
- Reference MelonLoader DLLs from the matching subdirectory (net35/ or net6/)

**WARNING:** Do NOT use `netstandard2.0` for net35 games!
netstandard2.0 is only an API specification, not a runtime. Mono has compatibility issues with it - the mod will load but not initialize (no error message, just silence).

**Why is this so important?**
1. **Developer name wrong** = Mod loads but OnInitializeMelon() is never called. No error in log, just silence.
2. **Framework wrong** = Mod loads but cannot execute. No error in log, just silence.

**For crashes or silent failures:** Read `technical-reference.md` section "CRITICAL: Accessing Game Code".

### For BepInEx

#### Log and Configuration

**Step 1:** Start game once with BepInEx (creates config and log files).

**Step 2:** Log path: `[GameDirectory]\BepInEx\LogOutput.log`

Check the log for:
- Successful BepInEx initialization
- Unity version
- Any errors or warnings

#### Enter Values in Code/Project (BepInEx)

**BepInPlugin Attribute (Main.cs):**
```csharp
[BepInPlugin("com.author.modname", "ModName", "1.0.0")]
```
- The first parameter (GUID) is a unique identifier — use reverse domain notation
- This does NOT need values from the log — you choose these yourself
- But the GUID must be unique across all mods for this game

**TargetFramework (csproj):**
- Most BepInEx Mono games: `<TargetFramework>net472</TargetFramework>` or `<TargetFramework>net35</TargetFramework>`
- Check what other BepInEx mods for this game use, or check the `BepInEx/core/` DLLs
- Reference BepInEx DLLs: `BepInEx/core/BepInEx.dll` and relevant Unity DLLs from `[Game]_Data/Managed/`

**Project references (csproj) for BepInEx:**
```xml
<Reference Include="BepInEx">
    <HintPath>[GameDirectory]\BepInEx\core\BepInEx.dll</HintPath>
</Reference>
<Reference Include="0Harmony">
    <HintPath>[GameDirectory]\BepInEx\core\0Harmony.dll</HintPath>
</Reference>
<Reference Include="UnityEngine">
    <HintPath>[GameDirectory]\[Game]_Data\Managed\UnityEngine.dll</HintPath>
</Reference>
<Reference Include="UnityEngine.CoreModule">
    <HintPath>[GameDirectory]\[Game]_Data\Managed\UnityEngine.CoreModule.dll</HintPath>
</Reference>
<Reference Include="Assembly-CSharp">
    <HintPath>[GameDirectory]\[Game]_Data\Managed\Assembly-CSharp.dll</HintPath>
</Reference>
```

**Output directory:** The built DLL goes into `BepInEx/plugins/` (not `Mods/`).

### Common to Both Mod Loaders

**Exclude decompiled directory (csproj):**
The csproj MUST contain these lines, otherwise the decompiled files will be compiled (hundreds of errors!):
```xml
<ItemGroup>
  <Compile Remove="decompiled\**" />
  <Compile Remove="templates\**" />
</ItemGroup>
```

**Build command - ALWAYS with project file!**
```
dotnet build [ModName].csproj
```
Do NOT just use `dotnet build`! The `decompiled/` directory often contains its own `.csproj` file from the decompiled game. If MSBuild finds multiple project files, it aborts.

---

## Project Start Workflow

### Phase 1: Codebase Analysis (before coding)

**PREREQUISITE: Decompiled source code MUST be in `decompiled/` before starting this phase!**

Phase 1 works EXCLUSIVELY with the decompiled source code — not with internet research, not with guesses, not with wiki articles. If `decompiled/` is empty or doesn't exist, STOP and go back to Step 7 (Decompilation). All Grep/Glob commands in this phase target the `decompiled/` directory.

Goal: Understand all accessibility-relevant systems BEFORE starting mod development.

**How to approach this phase - don't try to do everything at once!**

The analysis is divided into tiers:

- **Tier 1 (Essential - do before ANY coding):** Steps 1.1, 1.2, 1.3, 1.4, 1.5 - Structure, Input, UI, State Management decision, and Localization (if multilingual). Without these, you can't build anything.
- **Tier 2 (Do just-in-time - before implementing a specific feature):** Steps 1.6, 1.7, 1.8 - Analyze game mechanics, status systems, and events only when you're about to build a feature that needs them. For example, analyze the inventory system right before building the InventoryHandler, not months in advance.
- **Tier 3 (When relevant):** Steps 1.9, 1.10, 1.11 - Documentation, tutorial analysis. Do these when the project is ready for them.

This just-in-time approach prevents information overload and means you always analyze with a specific goal in mind.

#### 1.1 Structure Overview (Tier 1 - Essential)

**Namespace Inventory:**
```
Grep pattern: ^namespace\s+
```
Categorize into: UI/Menus, Gameplay, Audio, Input, Save/Load, Network, Other.

**Find singleton instances:**
```
Grep pattern: static.*instance
Grep pattern: \.instance\.
```
Singletons are the main access points to the game. List all with class name, what they manage, important properties.

#### 1.2 Input System (Tier 1 - Essential, CRITICAL!)

**Find all key bindings:**
```
Grep pattern: KeyCode\.
Grep pattern: Input\.GetKey
Grep pattern: Input\.GetKeyDown
Grep pattern: Input\.GetKeyUp
```
For EVERY find, document: File/line, which key, what happens, in which context.

**Mouse input:**
```
Grep pattern: Input\.GetMouseButton
Grep pattern: OnClick
Grep pattern: OnPointerClick
Grep pattern: OnPointerEnter
```

**Input controllers:**
```
Grep pattern: class.*Input.*Controller
Grep pattern: class.*InputManager
```

**Result:** Create list of which keys are NOT used by the game → safe mod keys.

**MANDATORY OUTPUT — do this NOW, not later:**
1. Write ALL found key bindings to `docs/game-api.md` section "Game Key Bindings"
2. Write the safe mod keys list to `docs/game-api.md` section "Safe Mod Keys"
3. Update `project_status.md` — check off "Input system" items

**Do NOT proceed to 1.3 until both sections are written in game-api.md!** This is the single most common source of bugs (mod keys conflicting with game controls) and the step most often skipped.

#### 1.3 UI System (Tier 1 - Essential, CRITICAL for Accessibility Mods!)

**Why this is the most important analysis step:**
UI systems are the heart of accessibility mods. Understanding how the game builds its menus, buttons, and lists determines the entire mod architecture. Invest time here - it pays off for every feature later.

**UI base classes:**
```
Grep pattern: class.*Form.*:
Grep pattern: class.*Panel.*:
Grep pattern: class.*Window.*:
Grep pattern: class.*Dialog.*:
Grep pattern: class.*Menu.*:
Grep pattern: class.*Screen.*:
Grep pattern: class.*Canvas.*:
```

Find out: Common base class? How are windows opened/closed? Central UI management?

**Text display:**
```
Grep pattern: \.text\s*=
Grep pattern: SetText\(
Grep pattern: TextMeshPro
```

**Tooltips:**
```
Grep pattern: Tooltip
Grep pattern: hover
Grep pattern: description
```

**IMPORTANT - Check for private fields (Unity):**

Many Unity games use this pattern:
```csharp
[SerializeField]
private TextMeshProUGUI title;
```

This means: The text is NOT accessible via public properties or UI paths!

**Search for this pattern:**
```
Grep pattern: \[SerializeField\]
Grep pattern: private.*Text
Grep pattern: private.*TMP
Grep pattern: private.*Button
```

**If many private fields are found:**
- UI data must be accessed via Reflection
- See `docs/unity-reflection-guide.md` for patterns and solutions
- Plan to create a `ReflectionHelper` utility class early

**Document UI findings in game-api.md:**
- List all UI base classes with their text access method
- Note which fields are private (need Reflection)
- Document the naming convention (m_PascalCase or camelCase)
- Create example code snippets for common access patterns

**Result of UI Analysis:**

After this step, you should know:
1. How to get text from any UI element (public property, method, or Reflection)
2. How navigation/selection works (Focus system? Highlight events?)
3. Which base classes exist and how they relate
4. Whether you need ReflectionHelper (if many private fields)

#### 1.4 State Management Decision (Tier 1 - Essential)

Based on the results of 1.2 (Input) and 1.3 (UI), assess:

**How many handlers will share the same keys?**

Count the screens/features from the UI analysis where the same keys (especially arrow keys, Enter, Escape) need to do different things. Examples:
- Arrow keys: menu navigation vs. world map movement vs. inventory browsing
- Enter: confirm menu item vs. interact with object vs. advance dialog
- Escape: close inventory vs. close shop vs. open pause menu

**Decision:**
- **3+ handlers sharing keys** → Use `AccessStateManager` (create from `templates/shared/AccessStateManager.cs.template` in Phase 2)
- **1-2 handlers** → Simple boolean flags are enough (see `state-management-guide.md`)

**Document the decision** in `project_status.md` under "Architecture Decisions" with the reasoning.

#### 1.5 Localization System (Tier 1 - If multilingual)

**Skip this step if the mod will only support one language.** Loc.cs still gets created in Phase 2 (all strings in one place is always good), but you don't need to analyze the game's language system.

**If the mod will support multiple languages (decided in Step 8):**

The game's language detection must be understood BEFORE building Loc.cs, so the mod can auto-detect which language to use.

```
Grep pattern: Locali
Grep pattern: Language
Grep pattern: Translate
Grep pattern: GetString
Grep pattern: currentLanguage
Grep pattern: getAlias
```

**What to find:**
- How does the game store/detect its current language?
- Is there a singleton or static property for the current language? (e.g., `LocalizationManager.CurrentLanguage`)
- What format are the language codes? (e.g., "en", "de", "English", "German")
- Where are the game's translation files? (for reusing game terms like item names)

**Document in game-api.md** section "Localization": the class/property for current language and the language code format.

See `docs/localization-guide.md` for complete instructions on building multilingual Loc.cs.

---

### TIER 1 COMPLETION GATE

**STOP! Before proceeding to Tier 2 or Phase 1.5, verify ALL of these are done:**

1. `docs/game-api.md` has a complete "Game Key Bindings" section with ALL keys the game uses
2. `docs/game-api.md` has a "Safe Mod Keys" section listing keys the mod can safely use
3. `docs/game-api.md` has UI base classes and text access patterns documented
4. `project_status.md` has all Tier 1 checkboxes checked
5. `project_status.md` "Game Key Bindings (Original)" section is filled in
6. State management decision documented in `project_status.md` "Architecture Decisions"
7. If multilingual: game's language detection documented in `docs/game-api.md`

**If any of these are missing, go back and do them now.** Every single mod bug from key conflicts could have been prevented by completing this gate properly.

---

#### 1.6 Game Mechanics (Tier 2 - Analyze before implementing related features)

**Player class:**
```
Grep pattern: class.*Player
Grep pattern: class.*Character
Grep pattern: class.*Controller.*:.*MonoBehaviour
```

**Inventory:**
```
Grep pattern: class.*Inventory
Grep pattern: class.*Item
Grep pattern: class.*Slot
```

**Interaction:**
```
Grep pattern: Interact
Grep pattern: OnUse
Grep pattern: IInteractable
```

**Other systems (depending on game):**
- Quest: `class.*Quest`, `class.*Mission`
- Dialog: `class.*Dialog`, `class.*Conversation`, `class.*NPC`
- Combat: `class.*Combat`, `class.*Attack`, `class.*Health`
- Crafting: `class.*Craft`, `class.*Recipe`
- Resources: `class.*Currency`, `Gold`, `Coins`

#### 1.7 Status and Feedback (Tier 2 - Analyze before implementing status announcements)

**Player status:**
```
Grep pattern: Health
Grep pattern: Stamina
Grep pattern: Mana
Grep pattern: Energy
```

**Notifications:**
```
Grep pattern: Notification
Grep pattern: Message
Grep pattern: Toast
Grep pattern: Popup
```

#### 1.8 Event System (Tier 2 - Analyze before implementing Harmony patches)

**Find events:**
```
Grep pattern: delegate\s+
Grep pattern: event\s+
Grep pattern: Action<
Grep pattern: UnityEvent
Grep pattern: \.Invoke\(
```

**Good patch points:**
```
Grep pattern: OnOpen
Grep pattern: OnClose
Grep pattern: OnShow
Grep pattern: OnHide
Grep pattern: OnSelect
```

#### 1.9 Document Results (Ongoing - update after each analysis)

After analysis, `docs/game-api.md` should contain:
1. Overview - Game description, engine version
2. Singleton access points
3. Game key bindings (ALL!)
4. Safe mod keys
5. **UI system (detailed!):**
   - All UI base classes and their hierarchy
   - How to access text (public property, method, or Reflection field name)
   - Naming convention used (m_PascalCase or camelCase)
   - Code examples for common UI access patterns
   - Which classes need ReflectionHelper
6. Game mechanics
7. Status systems
8. Event hooks for Harmony

**Why detailed UI documentation matters:**
Every menu feature will need to read text from UI elements. If you document the access pattern once, you (and Claude Code) can reuse it everywhere without re-analyzing each time.

#### 1.10 Search and Analyze Tutorial (Tier 3 - When planning tutorial accessibility)

**Why the tutorial is important:**
- Tutorials explain game mechanics step by step - ideal for understanding what needs to be made accessible
- Often simpler structure than the rest of the game - good entry point for mod development
- If the tutorial is accessible, blind players can actually learn the game in the first place
- Tutorial code often reveals which UI elements and interactions exist

**Search in decompiled code:**
```
Grep pattern: Tutorial
Grep pattern: class.*Tutorial
Grep pattern: FirstTime
Grep pattern: Introduction
Grep pattern: HowToPlay
Grep pattern: Onboarding
```

**Search in game directory:**
- For files with "tutorial", "intro", "howto" in name
- Often organized in separate scenes or levels

**Analysis questions:**
1. Is there a tutorial? If yes, how is it started?
2. Which game mechanics are introduced in the tutorial?
3. How are instructions displayed (text, popups, voice output)?
4. Are there interactive elements that need to be made accessible?
5. Can the tutorial be skipped?

**Result:**
- Document tutorial existence and start method in game-api.md
- Put tutorial on feature list (typically high priority)
- Use recognized mechanics as basis for further features

### Phase 1.5: Create Feature Plan

**Create a structured plan before coding:**

Based on codebase analysis and tutorial findings, create a feature list.

**Plan structure:**

Most important features (document in detail):
- What exactly should the feature do?
- Which game classes/methods are used?
- Which keys are needed?
- Dependencies on other features?
- Known challenges?

Example for detailed feature:
```
Feature: Main Menu Navigation
- Goal: All menu items navigable with arrow keys, announce current selection
- Classes: MainMenu, MenuButton (from Analysis 1.3)
- Harmony hook: MainMenu.OnOpen() for initialization
- Keys: Arrow keys (already used by game), Enter (confirm)
- Dependencies: None (first feature)
- Challenge: Menu items have no uniform text property
```

Less important features (document roughly):
- Brief description in 1-2 sentences
- Estimated complexity (simple/medium/complex)
- Dependencies if any

Example for rough feature:
```
Feature: Achievement Announcements
- Brief: Intercept achievement popups and read aloud
- Complexity: Simple
- Depends on: Basic announcement system
```

**Set priorities:**

Question to user: Which feature should we start with?

Guiding principle: Best to start with the things you interact with first in the game. This enables early testing and the player can experience the game from the beginning.

Typical order (adapt contextually!):
1. Main menu - Usually the first contact with the game
2. Basic status announcements - Health, resources, etc.
3. Tutorial (if present) - Introduces game mechanics
4. Core gameplay navigation
5. Inventory and submenus
6. Special features (Crafting, Trading, etc.)
7. Optional features (Achievements, Statistics)

This order is just a suggestion. Depending on the game, it may make sense to prioritize differently:
- Some games start directly in gameplay without main menu
- In some games the tutorial is mandatory and comes before everything else
- Status announcements can also be developed parallel to other features

**Advantages of a well-thought-out plan:**
- Dependencies are recognized early
- Common utility classes can be identified
- Architecture decisions made once instead of ad-hoc
- Better overview of total scope

**Note:** The plan may and will change. Some features prove to be easier or harder than expected.

**If AccessStateManager was decided in Step 1.4:** Use the feature plan to define the State enum entries. Each feature that needs exclusive input gets one enum value.

### Phase 2: Basic Framework

**PREREQUISITE: Tier 1 Completion Gate MUST be passed!** (See above)

1. Create C# project from the **mod-loader-specific csproj template** (`templates/melonloader/csproj.template` or `templates/bepinex/csproj.template`)
2. Create Main.cs from the matching mod-loader template (`templates/melonloader/Main.cs.template` or `templates/bepinex/Main.cs.template`)
3. Create ScreenReader.cs, DebugLogger.cs from the matching mod-loader templates
4. Create localization system from `templates/shared/Loc.cs.template` — this is part of the basic framework, NOT a later addition. If multilingual: use the game language detection analyzed in Step 1.5.
5. If AccessStateManager was decided in Step 1.4: Create from `templates/shared/AccessStateManager.cs.template`
6. Create basic mod that announces `Loc.Get("mod_loaded")` at startup
7. Test if basic framework works

#### Build-Test Workflow

**IMPORTANT: Explain this workflow to the user the first time a build-test cycle happens (typically during Phase 2 when testing the basic "Mod loaded" announcement). This is the fundamental cycle that will be repeated hundreds of times throughout the project.**

The development workflow for testing mod changes:

1. **Write/modify code** - Claude writes or modifies the mod source code
2. **Build** - Run `dotnet build [ModName].csproj` to compile the mod into a DLL
3. **Auto-copy** - The DLL is automatically copied to the game's mod folder: `Mods/` for MelonLoader or `BepInEx/plugins/` for BepInEx (if the CopyToMods target is set up in the csproj)
4. **Start the game** - Launch the game normally (the mod loader loads the mod automatically)
5. **Test** - Check if the new feature works as expected
6. **Close the game** - **Always close the game completely before the next build!** The DLL file is locked while the game is running.
7. **Report back** - Tell Claude what worked and what didn't. Be specific: "It says X but should say Y" or "Nothing happens when I press F2"
8. **Repeat** - Claude fixes issues based on your feedback, then build and test again

**Important notes for the user:**
- You will need to close and restart the game for every code change - there is no "hot reload"
- If the mod doesn't seem to load at all, check the log for errors: `MelonLoader/Latest.log` (MelonLoader) or `BepInEx/LogOutput.log` (BepInEx)
- If you hear nothing from the screen reader but the log shows the mod loaded: Check if Tolk DLLs are in the right place and matching the architecture
- Build errors (compilation failures) are shown in the terminal - Claude can read and fix them directly
- Runtime errors (crashes during gameplay) appear in the MelonLoader log

For beginners: Think of it like editing a document and printing it. You make changes, "print" (build), then check the printout (test in game). If something is wrong, you go back and edit again.

**Note:** The first build uses `dotnet build` directly. After Phase 2.5, build/deploy scripts are created — from that point on, always use the scripts.

### Phase 2.5: Build/Deploy Scripts and CLAUDE.md Update (after first successful build)

After the first successful manual build, create PowerShell scripts so that build and deploy are always one command away. Then update CLAUDE.md to reference these scripts.

#### Step 1: Create Build/Deploy Scripts

Create these scripts in the `scripts/` directory:

**`scripts/Build-Mod.ps1`** — Builds the mod:
- Runs `dotnet build [ModName].csproj`
- Reports success/failure clearly
- Shows the output DLL path

**`scripts/Deploy-Mod.ps1`** — Builds and copies to game directory:
- Calls `Build-Mod.ps1`
- Copies the output DLL to the game's mod folder (`Mods/` for MelonLoader, `BepInEx/plugins/` for BepInEx)
- Optionally copies any additional files (e.g., localization files, config files)
- Reports what was copied and where

**Script requirements:**
- Use parameters for paths so the scripts work without hardcoded values (e.g., `-GamePath`, `-Configuration Debug/Release`)
- Default values should match the project setup so the user can just run `.\scripts\Deploy-Mod.ps1` without arguments
- Include error handling: if build fails, don't copy. If game directory doesn't exist, warn clearly.
- Keep scripts simple — no over-engineering. These are convenience wrappers.

**Example structure for Deploy-Mod.ps1:**
```powershell
param(
    [string]$Configuration = "Debug",
    [string]$GamePath = "C:\Path\to\Game"  # Fill in during setup
)

# Build
& "$PSScriptRoot\Build-Mod.ps1" -Configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed."
    exit 1
}

# Copy DLL to game
$dllPath = "bin\$Configuration\net472\ModName.dll"
$targetDir = "$GamePath\Mods"  # Adjust for BepInEx: BepInEx\plugins

Copy-Item $dllPath $targetDir -Force
Write-Host "Deployed to $targetDir"
```

#### Step 2: Update CLAUDE.md

Update the "Environment" section with:
- Game directory path
- Architecture (32-bit/64-bit)
- Mod loader (MelonLoader or BepInEx)

**Replace the `Build` placeholder in the Coding Rules section** with a reference to the scripts:

```markdown
## Build & Deploy

- Build: `.\scripts\Build-Mod.ps1`
- Build + copy to game: `.\scripts\Deploy-Mod.ps1`
```

**Do NOT put raw `dotnet build` commands in CLAUDE.md.** Always use the scripts — they are the single source of truth for how to build and deploy.

Add any project-specific notes:
- Engine version (e.g., Unity 2021.3)
- Special considerations for this game
- Deviations from template patterns
- Known quirks or workarounds

**Keep CLAUDE.md short and concise** - it's only for Claude Code, not documentation.

Example addition:
```markdown
## Build & Deploy

- Build: `.\scripts\Build-Mod.ps1`
- Build + copy to game: `.\scripts\Deploy-Mod.ps1`

## Notes

- Unity 2021.3.5f1
- Uses legacy Input system
- MainMenu has no base class, access via MainMenuManager.instance
```

### Phase 3: Feature Development

**BEFORE each new feature:**
1. Consult `docs/game-api.md`:
   - Check game key bindings (no conflicts!)
   - Use already documented classes/methods
   - Reuse known patterns
   - **Check UI Analysis section** - How to access text for this UI type?
2. Check feature plan entry (dependencies fulfilled?)
3. For menus: Work through `menu-accessibility-checklist.md`
4. **For UI features:** Check if Reflection is needed (see `docs/unity-reflection-guide.md`)
5. **For 3+ handlers on same keys:** Consider state management (see `docs/state-management-guide.md`)

**Why API docs first?**
- Prevents key conflicts with the game
- Avoids duplicate work (don't search for methods again)
- Consistency between features is maintained
- Documented patterns can be directly reused
- **UI access patterns are already solved** - don't reinvent the wheel

See `ACCESSIBILITY_MODDING_GUIDE.md` for code patterns.

**Feature order:** Build accessibility features in the order a player encounters them in the game:

1. **Main menu** - First contact with the game, basic navigation
2. **Settings menu** - If accessible from main menu
3. **General status announcements** - Health, money, time, etc.
4. **Tutorial / Starting area** - First game experience
5. **Core gameplay** - The most frequent actions
6. **Inventory / In-game menus** - Pause menu, inventory, map
7. **Special features** - Crafting, trading, dialogs
8. **Endgame / Optional** - Achievements, statistics

---

## Helper Scripts

### Get-MelonLoaderInfo.ps1

Reads the MelonLoader log and extracts all important values:
- Game Name and Developer (for MelonGame attribute)
- Runtime Type (for TargetFramework)
- Unity Version

**Usage:**
```powershell
.\scripts\Get-MelonLoaderInfo.ps1 -GamePath "C:\Path\to\Game"
```

**Output:** Ready-to-copy code snippets.

### Test-ModSetup.ps1

Validates if everything is set up correctly:
- Mod loader installation (MelonLoader or BepInEx)
- Tolk DLLs (also checks correct architecture!)
- Project file and references
- Mod loader attributes (MelonGame or BepInPlugin)
- Decompiled directory

**Usage:**
```powershell
.\scripts\Test-ModSetup.ps1 -GamePath "C:\Path\to\Game" -Architecture x64
```

Parameter `-Architecture` can be `x64` or `x86`.

**Output:** List of all checks with OK, WARNING or ERROR, plus solution suggestions.

---

## Important Links

- MelonLoader GitHub: https://github.com/LavaGang/MelonLoader
- MelonLoader Installer: https://github.com/LavaGang/MelonLoader.Installer/releases
- BepInEx GitHub: https://github.com/BepInEx/BepInEx
- BepInEx Releases: https://github.com/BepInEx/BepInEx/releases
- Tolk (Screen reader): https://github.com/ndarilek/tolk/releases
- dnSpy (Decompiler): https://github.com/dnSpy/dnSpy/releases
- .NET SDK: https://dotnet.microsoft.com/download
