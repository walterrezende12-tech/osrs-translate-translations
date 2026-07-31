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

git diff --quiet -- "pt-BR/*.json"
if not errorlevel 1 (
    git diff --cached --quiet -- "pt-BR/*.json"
    if not errorlevel 1 (
        echo Nenhuma alteracao de JSON encontrada em pt-BR.
        goto :done
    )
)

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

for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$m = Get-Content 'manifest.json' -Raw ^| ConvertFrom-Json; if ($m.version -notmatch '^(.*\.)([0-9]+)$') { throw 'Formato de versao invalido' }; '{0}{1}' -f $Matches[1], ([int]$Matches[2] + 1)"`) do set "NEXT_VERSION=%%V"

if not defined NEXT_VERSION (
    echo ERRO: nao foi possivel calcular a proxima versao.
    goto :fail
)

for /f "usebackq delims=" %%R in (`git rev-parse HEAD`) do set "REVISION=%%R"

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
