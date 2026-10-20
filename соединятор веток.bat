@echo off
cd /d "%~dp0"

set HOME=C:\Users\student314

if exist ".git\index.lock" del ".git\index.lock"

echo === Current branch ===
git branch --show-current
echo.

set /p src="Enter branch to merge INTO current: "
if "%src%"=="" (
    echo Branch name is empty. Abort.
    pause
    exit /b 1
)

echo === Merging "%src%" into current branch ===
git merge "%src%"
if errorlevel 1 (
    echo.
    echo Merge error or conflict!
    echo Resolve conflicts manually, then:
    echo   git add .
    echo   git commit -m "Merge %src%"
    pause
    exit /b 1
)

echo.
echo === Merge done ===
echo To push the result, run:
echo   git push github main
echo   git push gitflic main
pause