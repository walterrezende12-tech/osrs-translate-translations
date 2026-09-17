$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
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

$languageDirectories = Get-ChildItem -LiteralPath $repositoryRoot -Directory |
    Where-Object { $_.Name -notin @('scripts', 'correcao') } |
    Sort-Object Name

if ($languageDirectories.Count -eq 0) {
    throw 'Nenhuma pasta de idioma encontrada.'
}

$invalidFiles = New-Object System.Collections.Generic.List[string]

foreach ($languageDirectory in $languageDirectories) {
    foreach ($fileName in $requiredFiles) {
        $filePath = Join-Path $languageDirectory.FullName $fileName
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            [void]$invalidFiles.Add("$filePath - arquivo obrigatorio ausente")
            continue
        }

        try {
            $content = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
            $json = ConvertFrom-Json -InputObject $content

            if ($json -isnot [pscustomobject]) {
                throw 'a raiz deve ser um objeto JSON'
            }

            foreach ($property in $json.PSObject.Properties) {
                if ($property.Value -isnot [string]) {
                    throw "o valor da chave '$($property.Name)' deve ser texto"
                }
            }
        } catch {
            [void]$invalidFiles.Add("$filePath - $($_.Exception.Message)")
        }
    }
}

if ($invalidFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'ERRO: foram encontrados JSONs invalidos ou ausentes:' -ForegroundColor Red
    foreach ($invalidFile in $invalidFiles) {
        Write-Host "  - $invalidFile" -ForegroundColor Red
    }
    throw 'A publicacao foi cancelada. Corrija os arquivos listados antes de continuar.'
}

Write-Host 'Validacao dos JSONs concluida: todos os arquivos estao no formato aceito pelo plugin.' -ForegroundColor Green
