# Distribution Guide

How to package, license, and publish your accessibility mod.

---

## Preparing Your Mod for Release

### What End Users Need to Install

Your mod requires these components on the user's machine:

1. **MelonLoader** - The mod loader (user installs once)
   - Download: https://github.com/LavaGang/MelonLoader.Installer/releases
2. **Tolk DLLs** - Screen reader communication (included in your release)
   - `Tolk.dll`
   - `nvdaControllerClient64.dll` or `nvdaControllerClient32.dll` (matching game architecture)
3. **Your mod DLL** - The actual mod file

### Creating a Release Package

Create a ZIP file containing:

```
YourModName-v1.0.0.zip
├── Mods/
│   └── YourModName.dll          (your compiled mod)
├── Tolk.dll                      (screen reader library)
├── nvdaControllerClient64.dll    (or 32-bit version)
├── README.txt                    (installation instructions)
└── LICENSE.txt                   (your license)
```

**Why include Tolk DLLs?** Most users won't have Tolk installed. Including the DLLs makes installation much easier - they just copy everything to the game folder.

### End-User README Template

Write a simple README.txt (plain text, no markdown - accessible to everyone):

```
[ModName] - Accessibility Mod for [GameName]
Version: 1.0.0
Author: [Your Name]

WHAT THIS MOD DOES
==================
Makes [GameName] playable with a screen reader (NVDA, JAWS).
- Keyboard navigation for all menus
- Screen reader announcements for game events
- [List key features]

REQUIREMENTS
============
- [GameName] (Steam version tested, others may work)
- MelonLoader (https://github.com/LavaGang/MelonLoader.Installer/releases)
- A screen reader (NVDA recommended, JAWS also works)

INSTALLATION
============
1. Install MelonLoader for your game (run the installer, select your game)
2. Start the game once to create the Mods folder, then close it
3. Copy ALL files from this ZIP into your game folder:
   - YourModName.dll goes into the Mods subfolder
   - Tolk.dll goes into the main game folder (where the .exe is)
   - nvdaControllerClient64.dll goes into the main game folder
4. Start the game - you should hear "Mod loaded" from your screen reader

CONTROLS
========
F1 - Help (shows all key bindings)
[List your key bindings here]

TROUBLESHOOTING
===============
- No sound from screen reader: Check that Tolk.dll is in the game folder
- Mod doesn't load: Check MelonLoader/Latest.log for errors
- Wrong architecture: If game is 32-bit, use nvdaControllerClient32.dll instead

KNOWN ISSUES
============
[List any known issues]

CONTACT
=======
[Your contact info, GitHub issues page, etc.]
```

---

## Versioning

Use Semantic Versioning (SemVer): **MAJOR.MINOR.PATCH**

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, major rewrite
- **MINOR** (1.0.0 → 1.1.0): New features, new menus accessible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, announcement improvements

Update the version in:
- `MelonInfo` attribute in Main.cs
- Your release/tag on GitHub
- README and changelog

### Changelog

Keep a CHANGELOG.md in your project:

```
# Changelog

## 1.1.0 - 2025-03-15
- Added: Inventory navigation with arrow keys
- Added: Shop menu accessibility
- Fixed: Main menu skipping first item

## 1.0.0 - 2025-02-01
- Initial release
- Main menu navigation
- Basic status announcements (F2)
```

---

## Publishing on GitHub

### Why GitHub?

- Free hosting for your code and releases
- Issue tracker for bug reports
- Accessible with screen readers
- Game developers can review your code directly
- Community can contribute improvements

### Setting Up Your Repository

See `docs/git-github-guide.md` for the basics of Git and GitHub.

Once your git repo is initialized and pushed to GitHub:

1. **Write a good repository description:**
   - "[GameName] accessibility mod - makes the game playable with screen readers (NVDA/JAWS)"

2. **Create a README.md for GitHub** (different from the end-user README):
   - What the mod does
   - Current status (which features work)
   - How to install
   - How to build from source
   - How to contribute
   - License info

3. **Create a Release:**
   - Go to your repository on GitHub
   - Click "Releases" (right side or via `gh release create`)
   - Click "Create a new release"
   - Tag: `v1.0.0` (always prefix with v)
   - Title: `v1.0.0 - Initial Release`
   - Description: Copy relevant changelog entries
   - Attach your ZIP file (the release package from above)
   - Click "Publish release"

   Or via command line:
   ```
   gh release create v1.0.0 YourModName-v1.0.0.zip --title "v1.0.0 - Initial Release" --notes "Initial release with main menu navigation and status announcements"
   ```

### Other Publishing Platforms

- **audiogames.net forum** - Post in the appropriate game forum. The blind gaming community is active here. Link to your GitHub release.
- **NexusMods** - Popular mod hosting site. Create an account, upload your mod. Good for visibility with the general modding community.
- **Game-specific forums/Discord** - Many games have modding communities. Post there too.

---

## Licensing

### Why a License Matters

Without a license, your code is technically "all rights reserved" - nobody can legally use, modify, or distribute it. A license tells people what they're allowed to do.

This is especially important if:
- You want game developers to be able to integrate your code
- You want others to improve and maintain the mod
- You use code from other projects (you must respect their license)

### License Options

#### MIT License (Recommended for most mods)

**What it says:** "Do whatever you want with this code, just keep the copyright notice."

Advantages:
- Very simple and short
- Maximum freedom for everyone
- Game developers can integrate without legal concerns
- Compatible with almost every other license
- Most popular license on GitHub

Disadvantages:
- Others can make closed-source versions (if that bothers you)
- No "share-alike" requirement

**Best for:** Mods where you want maximum adoption and easy integration by game developers.

#### GNU GPL v3 (Copyleft)

**What it says:** "You can use and modify this, but any distributed derivative work must also be GPL."

Advantages:
- Ensures modifications stay open source
- Strong community protection

Disadvantages:
- Game developers often cannot integrate GPL code into proprietary games
- More complex to understand
- May discourage some contributors

**Best for:** Large projects where you want to ensure all improvements are shared back.

#### Apache License 2.0

**What it says:** Like MIT, but also includes a patent grant.

Advantages:
- Clear patent protection
- Corporate-friendly
- Permissive like MIT

Disadvantages:
- Longer and more complex text
- Overkill for small mods

#### Creative Commons (CC BY 4.0)

**Not recommended for code** - designed for creative works (art, documentation, text). Sometimes used for the non-code parts of a project.

### My Recommendation

**For accessibility mods: Use MIT.** The whole point is to make games accessible. You want game developers to look at your code and think "we can integrate this." MIT makes that as easy as possible legally.

### Applying a License

1. Create a `LICENSE` file in your project root
2. Copy the full license text (search for "MIT license text")
3. Fill in your name and year
4. Add a license badge or note in your README

MIT License template:
```
MIT License

Copyright (c) [YEAR] [YOUR NAME]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Respecting Other Licenses

Your mod uses third-party components:
- **MelonLoader**: Apache 2.0 - note in your README
- **Harmony** (included in MelonLoader): MIT
- **Tolk**: LGPL 2.1 - you can distribute the DLLs alongside your mod
- **The game itself**: You're modding it, not distributing it. Your mod should never include game code or assets.

---

## Handling Game Updates

Games get updated, and updates can break mods. Here's how to handle it:

### When a Game Update Drops

1. **Test first** - Launch the game with your mod. It might still work.
2. **Check the log** - If it doesn't work, read MelonLoader/Latest.log for errors.
3. **Re-decompile** - Get the new Assembly-CSharp.dll and decompile it.
4. **Compare** - Look for renamed classes, changed method signatures, moved fields.
5. **Fix and release** - Update your mod, bump the PATCH version.

### Proactive Measures

- **Use Reflection fallbacks** (see unity-reflection-guide.md) - Try multiple field names
- **Don't hardcode string constants** from the game - Use the game's own constants
- **Log useful debug info** - So you can quickly identify what changed
- **Keep your game-api.md updated** - Makes finding changes easier

### Communicating with Users

When an update breaks your mod:
- Post in your GitHub Issues that you're aware
- Release a fix as soon as possible
- If you can't fix it immediately, release a note saying which version of the game works with your current mod version

---

## Submitting Code to Game Developers

If you want to propose your accessibility features for integration into the main game:

### Before Approaching Developers

- Make sure your code is **clean and well-documented** (XML docs on every public method)
- Follow the game's existing code style as closely as possible
- Keep your changes **modular** - easy to review and integrate piece by piece
- Have a working mod that demonstrates the features
- Get feedback from blind players first

### How to Approach

1. Check if the developer has an official channel for mod submissions or feature requests
2. Start with a polite message explaining what your mod does and why it matters
3. Offer to help with integration
4. Link to your GitHub repository so they can review the code
5. Be patient - developers are busy and integration takes time

### What Developers Look For

- Clean, consistent code style
- No hacks or workarounds (or well-documented ones)
- Minimal impact on existing code
- Good performance (no frame drops)
- No new dependencies if possible (Tolk is a small dependency)
- Tests or at least clear testing instructions
