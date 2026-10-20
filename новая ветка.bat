@echo off
cd /d "%~dp0"

set HOME=C:\Users\student314

if exist ".git\index.lock" del ".git\index.lock"

echo === Current branch ===
git branch --show-current

echo.
set /p br="Enter new branch name: "
if "%br%"=="" (
    echo Branch name is empty. Abort.
    pause
    exit /b 1
)

echo === Creating branch "%br%" ===
git checkout -b "%br%"
if errorlevel 1 (
    echo Error: cannot create branch "%br%". Maybe it already exists.
    pause
    exit /b 1
)

echo.
echo === Done! You are now on branch "%br%" ===
echo To push it to remotes, run:
echo   git push -u github %br%
echo   git push -u gitflic %br%
pause