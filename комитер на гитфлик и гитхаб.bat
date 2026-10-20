@echo off
cd /d "%~dp0"

set HOME=C:\Users\student314

if exist ".git\index.lock" del ".git\index.lock"

echo === Add ===
git add .

echo === Commit ===
set /p msg="Commit message (Enter = Update): "
if "%msg%"=="" set msg=Update
git commit -m "%msg%"

echo === Pull --rebase GitHub ===
git pull --rebase github main
if errorlevel 1 (
    echo Error on pull --rebase GitHub!
    pause
    exit /b 1
)
echo === Push GitHub ===
git push github main
if errorlevel 1 (
    echo Error on push GitHub!
    pause
    exit /b 1
)

echo === Pull --rebase GitFlic ===
git pull --rebase gitflic main
if errorlevel 1 (
    echo Error on pull --rebase GitFlic!
    pause
    exit /b 1
)
echo === Push GitFlic ===
git push gitflic main
if errorlevel 1 (
    echo Error on push GitFlic!
    pause
    exit /b 1
)

echo.
echo === Done! Pushed to GitHub and GitFlic ===
pause