# Deploy-Mod.ps1
# Copies src/ contents to the Civ VI mods folder, preserving directory structure.
# Run from anywhere; script resolves its own location.

$srcDir  = Join-Path $PSScriptRoot "..\src"
$destDir = "C:\Users\amine\OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\CivVi-Accessibility-Integration"

Write-Host "Source : $srcDir"
Write-Host "Dest   : $destDir"
Write-Host ""

# Create destination if it doesn't exist
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Created mod folder."
}

# Robocopy mirrors src/ to dest/, excluding .git
# /MIR  = mirror (adds, updates, removes)
# /XD   = exclude .git directory
# /NJH /NJS /NDL = suppress summary headers, less noise
$result = robocopy $srcDir $destDir /MIR /XD ".git" /NJH /NJS

# Robocopy exit codes: 0-7 = success (8+ = errors)
if ($LASTEXITCODE -ge 8) {
    Write-Host "ERROR: robocopy failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Deploy complete. (robocopy exit code: $LASTEXITCODE)" -ForegroundColor Green
}
