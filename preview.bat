@echo off
REM preview.bat — place in Obsidian vault root alongside publish.bat
REM Starts Astro dev server reading live from this vault (drafts included).
REM Nothing is committed or pushed.

set "VAULT_ROOT=%~dp0"
REM Remove trailing backslash
if "%VAULT_ROOT:~-1%"=="\" set "VAULT_ROOT=%VAULT_ROOT:~0,-1%"

wsl --cd "%~dp0" -e bash -c "VAULT_ROOT='$(wslpath -u ""%VAULT_ROOT%"")' ~/blog-publish/preview.sh"
pause
