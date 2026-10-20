@echo off
cd /d "%~dp0"

set HOME=C:\Users\student314

if exist ".git\index.lock" del ".git\index.lock"

echo "=== Dobavlyaem... ==="
git add .

echo === Kommitim... ===
set /p msg="Commit message (Enter = Update): "
if "%msg%"=="" set msg=Update
git commit -m "%msg%"

echo === Pull --rebase dlya GitHub ===
git pull --rebase github main
if errorlevel 1 (
    echo OSHIBKA pri pull --rebase GitHub!
    pause
    exit /b 1
)
echo === Push GitHub ===
git push github main
if errorlevel 1 (
    echo OSHIBKA pri push GitHub!
    pause
    exit /b 1
)

echo === Pull --rebase dlya GitFlic ===
git pull --rebase gitflic main
if errorlevel 1 (
    echo OSHIBKA pri pull --rebase GitFlic!
    pause
    exit /b 1
)
echo === Push GitFlic ===
git push gitflic main
if errorlevel 1 (
    echo OSHIBKA pri push GitFlic!
    pause
    exit /b 1
)

echo.
echo =) VSE! Zalili obnovlenie na GitHub i GitFlic +_-
pause