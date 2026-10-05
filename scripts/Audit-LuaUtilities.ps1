# Read-only candidate inventory, not proof that a function is safe to extract.
# Parameters are normalized; captured state, call contracts and string literals
# still require review. Includes top-level private helpers, including one-liners.
$sourceRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'src/UI'
$functions = foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.lua') {
    $source = [System.IO.File]::ReadAllText($file.FullName)
    if ($file.FullName -match '[\\/]Replacements[\\/]') { continue }
    $block = $source.IndexOf('--#Accessibility integration')
    if ($block -ge 0) { $source = $source.Substring($block) }
    $pattern = '(?ms)^local function (?<name>\w+)\((?<args>[^\r\n]*?)\)(?<body>[^\r\n]*?\bend[ \t]*(?=\r?\n)|.*?^end[ \t]*(?=\r?\n))'
    foreach ($match in [regex]::Matches($source, $pattern)) {
        $body = $match.Groups['body'].Value
        $index = 0
        foreach ($parameter in $match.Groups['args'].Value.Split(',')) {
            $parameter = $parameter.Trim()
            if ($parameter -match '^\w+$') {
                $body = [regex]::Replace($body, "\b$parameter\b", "ARG$index")
                $index++
            }
        }
        $body = [regex]::Replace($body, '--[^\r\n]*', '')
        $body = [regex]::Replace($body, '\s+', '')
        [pscustomobject]@{
            Key = $body
            File = $file.FullName.Substring($sourceRoot.Length + 1)
            Name = $match.Groups['name'].Value
        }
    }
}
$groups = @($functions | Group-Object Key | Where-Object Count -gt 1)
foreach ($group in $groups) {
    ($group.Group | ForEach-Object { "$($_.File):$($_.Name)" }) -join ', '
}
Write-Host "$($functions.Count) private helper definitions inspected; $($groups.Count) candidate groups. Review dispositions in docs/utility-audit.md."
