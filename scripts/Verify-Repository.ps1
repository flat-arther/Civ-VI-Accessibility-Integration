[CmdletBinding()]
param(
    [string]$LuaPath,
    [switch]$StaticOnly,
    [switch]$WithoutVanillaRiverFixture
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = Join-Path $repoRoot 'src'
$failures = [System.Collections.Generic.List[string]]::new()
function Fail([string]$Message) { $failures.Add($Message) }
function Read-Xml([string]$Path) {
    try { return [xml][System.IO.File]::ReadAllText($Path) }
    catch { Fail "Invalid XML: $Path : $_"; return $null }
}

# Parse every authored XML file, including contexts, localization and hotkeys.
$xmlCount = 0
foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.xml') {
    $null = Read-Xml $file.FullName
    $xmlCount++
}
$manifest = Read-Xml (Join-Path $sourceRoot 'CivViAccess.modinfo')
$registered = @{}
$replacementCount = 0
if ($null -ne $manifest) {
    foreach ($context in @('CAIFrontEnd', 'CAIInGame')) {
        foreach ($helper in @('CAIControl.lua', 'CAICollection.lua', 'CAISetupParameters.lua', 'CAIModSupport.lua', 'CAICapturedDropdown.lua', 'CAIDescriptors.lua', 'CAIColumns.lua', 'textProcessing.lua')) {
            $imports = $manifest.SelectNodes("//ImportFiles[@id='$context']/File")
            if (@($imports | Where-Object { $_.InnerText.Trim() -eq "UI/shared/$helper" }).Count -ne 1) {
                Fail "Shared helper must be imported exactly once in ${context}: $helper"
            }
        }
    }
    foreach ($node in $manifest.SelectNodes('/Mod/Files/File')) {
        $path = $node.InnerText.Trim().Replace('\', '/')
        if ($registered.ContainsKey($path)) { Fail "Duplicate VFS file: $path" }
        $registered[$path] = $true
        if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $path) -PathType Leaf)) {
            # Pre-existing missing asset; see docs/verification.md. No general ignore list.
            if ($path -eq 'Platforms/Windows/Audio/English(US)/225557858.wem') {
                Write-Warning "Known packaging exception: $path is absent; its intended source remains unresolved."
            } else { Fail "Missing VFS file: $path" }
        }
    }
    foreach ($node in $manifest.SelectNodes('//File[not(parent::Files)] | //LuaReplace')) {
        $path = $node.InnerText.Trim().Replace('\', '/')
        if (-not $registered.ContainsKey($path)) { Fail "Action references an unregistered VFS file: $path" }
    }
    foreach ($node in $manifest.SelectNodes('//ReplaceUIScript')) {
        $replacementCount++
        if (-not $node.SelectSingleNode('Properties/LuaContext') -or
            -not $node.SelectSingleNode('Properties/LuaReplace')) {
            Fail "Incomplete ReplaceUIScript: $($node.GetAttribute('id'))"
        }
    }
}

# Complete translations have cai_text_ui.xml; other locales intentionally contain only mod metadata.
$textRoot = Join-Path $sourceRoot 'Text'
$locales = @{}
foreach ($directory in Get-ChildItem -LiteralPath $textRoot -Directory) {
    $tags = @{}
    foreach ($file in Get-ChildItem -LiteralPath $directory.FullName -Filter '*.xml') {
        $document = Read-Xml $file.FullName
        if ($null -eq $document) { continue }
        foreach ($row in $document.SelectNodes('//LocalizedText/Row | //LocalizedText/Replace')) {
            $tag = $row.GetAttribute('Tag')
            if ($tags.ContainsKey($tag)) { Fail "Duplicate localized tag: $($directory.Name) $tag" }
            if ($row.GetAttribute('Language') -ne $directory.Name) {
                Fail "Wrong language on $tag in $($file.FullName)"
            }
            $value = $row.SelectSingleNode('Text')
            if ($null -eq $value) { Fail "Missing Text element: $($directory.Name) $tag"; continue }
            # Compare numbered parameter identities, allowing translated names and pluralization syntax.
            $parameters = @([regex]::Matches($value.InnerText, '\{(\d+)[^{}]*\}') |
                ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique) -join ','
            $tags[$tag] = $parameters
        }
    }
    $locales[$directory.Name] = $tags
}
$english = $locales['en_US']
foreach ($directory in Get-ChildItem -LiteralPath $textRoot -Directory) {
    if ($directory.Name -eq 'en_US') { continue }
    $tags = $locales[$directory.Name]
    foreach ($tag in $tags.Keys) {
        if (-not $english.ContainsKey($tag)) { Fail "Translation has no English tag: $($directory.Name) $tag" }
        elseif ($tags[$tag] -ne $english[$tag]) { Fail "Placeholder mismatch: $($directory.Name) $tag" }
    }
    if (Test-Path -LiteralPath (Join-Path $directory.FullName 'cai_text_ui.xml')) {
        foreach ($tag in $english.Keys) {
            if (-not $tags.ContainsKey($tag)) { Fail "Missing translation: $($directory.Name) $tag" }
        }
    }
}

# Fail on retired manager calls in shipped, authored in-game Lua. Vendored originals are excluded.
$retired = ':(?:CreateUIWidget|HasWidget|SetFocusedChild)\s*\(|\.WidgetTemplateHelpers\b'
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'UI/inGame') -Recurse -Filter '*.lua') {
    $relative = $file.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
    if (-not $registered.ContainsKey($relative)) { continue }
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        $lineNumber++
        if ($line -match $retired -and $line -notmatch '^\s*--') {
            Fail "Retired widget API: ${relative}:${lineNumber}"
        }
    }
}
if ($failures.Count -gt 0) {
    foreach ($failure in $failures | Select-Object -First 20) { Write-Host "FAIL: $failure" }
    if ($failures.Count -gt 20) { Write-Host "... $($failures.Count - 20) additional failures." }
    throw "$($failures.Count) repository validation failure(s)."
}
Write-Host "Static checks passed: $xmlCount XML files, $($registered.Count) VFS files, $replacementCount replacements, $($locales.Count) locale directories."
if ($StaticOnly) {
    Write-Warning 'StaticOnly: Lua behavior tests were NOT run.'
    return
}
if (-not $LuaPath) { $LuaPath = Join-Path $repoRoot 'obj/test-lua/lua.exe' }
if (-not (Test-Path -LiteralPath $LuaPath -PathType Leaf)) {
    throw 'Test interpreter missing. Run scripts/Install-TestLua.ps1 or pass -LuaPath with an absolute Lua 5.4 executable path.'
}
$LuaPath = (Resolve-Path -LiteralPath $LuaPath).Path
Push-Location $repoRoot
try {
    foreach ($test in @('Test-TextProcessing.lua', 'Test-SharedUtilities.lua', 'Test-GameState.lua', 'Test-ResearchChooser.lua', 'Test-ResearchTrees.lua', 'Test-ResearchData.lua', 'Test-DescriptorColumns.lua', 'Test-ViewLifecycle.lua', 'Test-PlotInteractions.lua', 'Test-WorldBuilderInput.lua', 'Test-WorldInputModes.lua', 'Test-ScannerContracts.lua', 'Test-ScannerCore.lua', 'Test-ReportSections.lua', 'Test-WorldRankings.lua', 'Test-ProductionQueue.lua', 'Test-FinalUtilityAudit.lua', 'Test-TradeData.lua', 'Test-TradeScreens.lua', 'Test-MinimapLens.lua', 'Test-UnitBrowser.lua', 'Test-StagingLifecycle.lua', 'Test-RealEraTracker.lua', 'Test-RiverDownstream.lua')) {
        $testArgs = @()
        if ($test -eq 'Test-TextProcessing.lua') {
            $testArgs = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'UI') -Recurse -Filter '*.lua' |
                Where-Object { [System.IO.File]::ReadAllText($_.FullName) -match 'CAI(Text|Control|Collection|GameState|ModSupport|ResearchChooser|ResearchTree|ResearchData|TradeData|TradeOrigin|TradeOverview|CapturedDropdown|Descriptors|Columns|PlotInteractions|WorldBuilderInput)\.' } |
                ForEach-Object { $_.FullName })
        }
        if ($test -eq 'Test-RiverDownstream.lua' -and $WithoutVanillaRiverFixture) { $testArgs += '--without-vanilla' }
        if ($test -eq 'Test-SharedUtilities.lua') {
            $testArgs = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'UI/inGame') -Recurse -Filter '*.lua' |
                Where-Object { [System.IO.File]::ReadAllText($_.FullName) -match 'include\("CAI(Control|Collection)"\)' } |
                ForEach-Object { $_.FullName })
        }
        & $LuaPath (Join-Path $PSScriptRoot $test) @testArgs
        if ($LASTEXITCODE -ne 0) { throw "Lua test failed: $test" }
    }
} finally { Pop-Location }
Write-Host 'Repository verification passed (known audio packaging exception reported above).'
