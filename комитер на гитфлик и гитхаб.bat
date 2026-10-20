@echo off
chcp 65001 >nul
cd /d "%~dp0"

set HOME=C:\Users\student314

echo АВТО КОМИТТЕР РПГ НА ГОДОТ
git add .

echo === Коммит ===
set /p msg="Введите сообщение коммита (Enter — 'Update'): "
if "%msg%"=="" set msg=Update
git commit -m "%msg%"

echo === Push на GitHub ===
git push github main
if errorlevel 1 (
    echo Ошибка при push на GitHub!
    pause
    exit /b 1
)

echo === Push на GitFlic ===
git push origin main
if errorlevel 1 (
    echo Ошибка при push на GitFlic!
    pause
    exit /b 1
)

echo.
echo Готово! Изменения залиты на GitHub и GitFlic
pause