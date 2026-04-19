# Deploy-Mod.ps1

$srcDir = Join-Path $PSScriptRoot "..\src"

# Resolve Documents → Civ VI Mods
$documents = [Environment]::GetFolderPath("MyDocuments")
$modsRoot  = Join-Path $documents "My Games\Sid Meier's Civilization VI\Mods"
$destDir   = Join-Path $modsRoot "CivVi-Accessibility-Integration"

Write-Host "Source : $srcDir"
Write-Host "Dest   : $destDir"
Write-Host ""

# Ensure destination exists
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Created mod folder."
}

# Mirror files
$result = robocopy $srcDir $destDir /MIR /XD ".git" /NJH /NJS

if ($LASTEXITCODE -ge 8) {
    Write-Host "ERROR: robocopy failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

Write-Host "Deploy complete. (robocopy exit code: $LASTEXITCODE)" -ForegroundColor Green

# Resolve Steam install
$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath
$exePath   = Join-Path $steamPath "steamapps\common\Sid-Meiers-Civilization-VI\Base\Binaries\Win64Steam\CivilizationVI.exe"

if (Test-Path $exePath) {
    Write-Host "Launching Civilization VI..." -ForegroundColor Cyan
    Start-Process $exePath
} else {
    Write-Host "Could not find Civilization VI executable." -ForegroundColor Yellow
}