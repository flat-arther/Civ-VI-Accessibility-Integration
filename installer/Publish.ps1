[CmdletBinding()]
param(
    [string]$ProjectPath = ".\CivVIAccessInstaller.csproj",
    [string]$OutputDirectory = ".\publish",
    [switch]$SkipClean
)

$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

try {
    $projectFullPath = Resolve-FullPath $ProjectPath
    $outputFullPath = Resolve-FullPath $OutputDirectory

    if (-not (Test-Path -LiteralPath $projectFullPath -PathType Leaf)) {
        throw "Project file not found: $projectFullPath"
    }

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        throw "The .NET SDK was not found. Install the .NET 8 SDK and ensure 'dotnet' is available in PATH."
    }

    $projectDirectory = Split-Path -Parent $projectFullPath
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFullPath)
    $expectedExe = Join-Path $outputFullPath "$projectName.exe"

    Write-Host "Project: $projectFullPath"
    Write-Host "Output:  $outputFullPath"
    Write-Host ""

    if (-not $SkipClean) {
        Write-Host "Cleaning previous build output..."

        Push-Location $projectDirectory
        try {
            & dotnet clean $projectFullPath --configuration Release
            if ($LASTEXITCODE -ne 0) {
                throw "dotnet clean failed with exit code $LASTEXITCODE."
            }
        }
        finally {
            Pop-Location
        }

        foreach ($directory in @(
            (Join-Path $projectDirectory "bin"),
            (Join-Path $projectDirectory "obj"),
            $outputFullPath
        )) {
            if (Test-Path -LiteralPath $directory) {
                Remove-Item -LiteralPath $directory -Recurse -Force
            }
        }
    }

    Write-Host "Restoring packages..."
    & dotnet restore $projectFullPath
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed with exit code $LASTEXITCODE."
    }

    Write-Host "Publishing Release build..."
    & dotnet publish $projectFullPath `
        --configuration Release `
        --output $outputFullPath `
        --no-restore

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $expectedExe -PathType Leaf)) {
        $exe = Get-ChildItem -LiteralPath $outputFullPath -Filter "*.exe" -File |
            Select-Object -First 1

        if (-not $exe) {
            throw "Publish completed, but no executable was found in $outputFullPath."
        }

        $expectedExe = $exe.FullName
    }

    $file = Get-Item -LiteralPath $expectedExe

    Write-Host ""
    Write-Host "Publish succeeded."
    Write-Host "Executable: $($file.FullName)"
    Write-Host "Size:       $([Math]::Round($file.Length / 1MB, 2)) MB"
}
catch {
    Write-Error $_
    exit 1
}
