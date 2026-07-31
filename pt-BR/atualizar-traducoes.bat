@echo off
setlocal EnableExtensions

set "REPO_ROOT=%~dp0.."
cd /d "%REPO_ROOT%"

echo ========================================
echo Atualizacao das traducoes PT-BR
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ERRO: Git nao foi encontrado no PATH.
    goto :fail
)

if not exist "scripts\update-manifest.ps1" (
    echo ERRO: scripts\update-manifest.ps1 nao foi encontrado.
    goto :fail
)

set "JSON_CHANGED=1"
git diff --quiet -- "pt-BR/*.json"
if not errorlevel 1 (
    git diff --cached --quiet -- "pt-BR/*.json"
    if not errorlevel 1 set "JSON_CHANGED=0"
)

for /f "usebackq delims=" %%R in (`git log -1 --format^=%%H -- "pt-BR/*.json"`) do set "JSON_REVISION=%%R"

if "%JSON_CHANGED%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$m = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText('manifest.json')); if ($m.languages.'pt-BR'.files.'translations_settings.json'.url -match '%JSON_REVISION%') { exit 0 } else { exit 1 }"
    if not errorlevel 1 (
        echo Nenhuma alteracao de JSON ou manifesto encontrada.
        goto :done
    )
)

if "%JSON_CHANGED%"=="1" (
    echo Alteracoes encontradas:
    git status --short -- "pt-BR/*.json"
    echo.

    git add -A -- "pt-BR/*.json"
    if errorlevel 1 (
        echo ERRO: nao foi possivel preparar os JSONs.
        goto :fail
    )

    git commit -m "feat: atualiza traducoes pt-br"
    if errorlevel 1 (
        echo ERRO: nao foi possivel criar o commit das traducoes.
        goto :fail
    )
)

if "%JSON_CHANGED%"=="0" echo Manifesto desatualizado; corrigindo agora.

for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$m = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText('manifest.json')); $parts = $m.version.Split('.'); $last = $parts.Length - 1; $parts[$last] = ([int]$parts[$last] + 1); $parts -join '.'"`) do set "NEXT_VERSION=%%V"

if not defined NEXT_VERSION (
    echo ERRO: nao foi possivel calcular a proxima versao.
    goto :fail
)

for /f "usebackq delims=" %%R in (`git log -1 --format^=%%H -- "pt-BR/*.json"`) do set "REVISION=%%R"

echo Atualizando manifesto para %NEXT_VERSION%...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\update-manifest.ps1" -Version "%NEXT_VERSION%" -Revision "%REVISION%"
if errorlevel 1 (
    echo ERRO: nao foi possivel atualizar o manifesto.
    goto :fail
)

git add -- manifest.json
git commit -m "chore: atualiza manifesto das traducoes"
if errorlevel 1 (
    echo ERRO: nao foi possivel criar o commit do manifesto.
    goto :fail
)

git push origin main
if errorlevel 1 (
    echo ERRO: o push falhou. Os commits foram mantidos localmente.
    goto :fail
)

echo.
echo Atualizacao concluida com sucesso.
echo Versao publicada: %NEXT_VERSION%
goto :done

:fail
echo.
echo A atualizacao nao foi concluida.
pause
exit /b 1

:done
echo.
pause
exit /b 0
