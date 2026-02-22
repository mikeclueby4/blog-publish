@echo off
REM publish.bat (place in vault root on Windows)
REM Auto-solves all path problems, only assumes "~/blog-publish/publish.sh" exists in WSL.
setlocal

REM Start WSL with working directory set to this folder (vault root)
REM Requires: WSL installed and a default distro configured.
wsl.exe --cd "%~dp0" bash -lc "export VAULT_ROOT=""$PWD""; cd ~/blog-publish && ./publish.sh"

endlocal