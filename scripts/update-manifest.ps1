param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $Version,

    [string] $Revision,

    [string] $Repository = 'walterrezende12-tech/osrs-translate-translations'
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Revision)) {
    $Revision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
}
if ($Revision -notmatch '^[a-fA-F0-9]{40}$') {
    throw 'Revision deve ser o SHA completo de um commit que contenha os JSONs publicados.'
}
if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    throw 'Repository deve usar o formato proprietario/repositorio.'
}

$requiredFiles = @(
    'translations.json',
    'translations_skills.json',
    'translations_quests.json',
    'translations_items.json',
    'translations_menu.json',
    'translations_overhead.json',
    'translations_game_message.json',
    'translations_welcome.json',
    'translations_settings.json'
)

$languages = [ordered]@{}
$languageDirectories = Get-ChildItem -LiteralPath $repositoryRoot -Directory |
    Where-Object { $_.Name -ne 'scripts' } |
    Sort-Object Name

foreach ($languageDirectory in $languageDirectories) {
    $files = [ordered]@{}
    foreach ($fileName in $requiredFiles) {
        $filePath = Join-Path $languageDirectory.FullName $fileName
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "Arquivo obrigatorio ausente: $filePath"
        }

        $files[$fileName] = [ordered]@{
            url = "https://raw.githubusercontent.com/$Repository/$Revision/$($languageDirectory.Name)/$fileName"
            sha256 = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }

    $languages[$languageDirectory.Name] = [ordered]@{
        files = $files
    }
}

if ($languages.Count -eq 0) {
    throw 'Nenhuma pasta de idioma encontrada.'
}

$manifest = [ordered]@{
    schemaVersion = 1
    version = $Version
    languages = $languages
}

$json = ($manifest | ConvertTo-Json -Depth 8) -replace "`r`n", "`n"
$manifestPath = Join-Path $repositoryRoot 'manifest.json'
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, "$json`n", $utf8WithoutBom)

Write-Host "Manifesto atualizado: $manifestPath"
