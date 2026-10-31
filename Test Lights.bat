@echo off
title CS2 Bomb Lights - effect tester
:menu
cls
echo.
echo   CS2 Bomb Lights - effect tester
echo   ===============================
echo.
echo     1  Bomb countdown
echo     2  Hit flash (you get shot)
echo     3  Death
echo     4  Flashbang
echo     5  Smoke
echo     6  Headshot kill
echo     7  Kill (body shot)
echo     8  Hit marker (you damage someone)
echo     9  Round won
echo     D  Bomb defused
echo     A  All of them, one after another
echo     Q  Quit
echo.
choice /c 123456789DAQ /n /m "  Pick one: "
set pick=%errorlevel%
if %pick%==12 goto :eof
if %pick%==1 set fx=bomb
if %pick%==2 set fx=hit
if %pick%==3 set fx=death
if %pick%==4 set fx=flash
if %pick%==5 set fx=smoke
if %pick%==6 set fx=headshot
if %pick%==7 set fx=kill
if %pick%==8 set fx=hitmarker
if %pick%==9 set fx=win
if %pick%==10 set fx=defuse
if %pick%==11 set fx=all
echo.
"%~dp0CS2BombLights.exe" --test %fx%
echo.
pause
goto menu
