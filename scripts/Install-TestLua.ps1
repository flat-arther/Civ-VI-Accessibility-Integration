# Builds a pinned standalone test interpreter; does not change PATH or the game.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$buildRoot = Join-Path $repoRoot 'obj/test-lua'
$version = '5.4.8'
# Published at https://www.lua.org/ftp/
$expectedHash = '4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae'
$archive = Join-Path $buildRoot "lua-$version.tar.gz"
$sourceRoot = Join-Path $buildRoot "lua-$version/src"
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) {
    throw 'Install Visual Studio Build Tools with Desktop development with C++ first.'
}
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $installation) { throw 'No Visual Studio installation with the C++ toolchain was found.' }
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
if (-not (Test-Path -LiteralPath $archive)) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://www.lua.org/ftp/lua-$version.tar.gz" -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    throw "Lua archive checksum mismatch: $archive"
}
& tar.exe -xzf $archive -C $buildRoot
if ($LASTEXITCODE -ne 0) { throw 'Lua source extraction failed.' }
Push-Location $sourceRoot
try {
    $sources = (Get-ChildItem -Filter '*.c' | Where-Object Name -ne 'luac.c' | ForEach-Object Name) -join ' '
    $vcvars = Join-Path $installation 'VC/Auxiliary/Build/vcvars64.bat'
    $buildScript = Join-Path $sourceRoot 'build-test-lua.cmd'
    [System.IO.File]::WriteAllLines($buildScript, @(
        '@echo off',
        ('call "{0}"' -f $vcvars),
        'if errorlevel 1 exit /b 1',
        ('cl.exe /nologo /O2 /MD /DLUA_COMPAT_5_3 {0} /Fe:lua.exe' -f $sources),
        'exit /b %errorlevel%'
    ))
    & cmd.exe /d /c $buildScript
    if ($LASTEXITCODE -ne 0) { throw 'Lua compilation failed.' }
    Copy-Item -LiteralPath 'lua.exe' -Destination (Join-Path $buildRoot 'lua.exe') -Force
} finally {
    Pop-Location
}
Write-Host "Test interpreter: $(Join-Path $buildRoot 'lua.exe')"
