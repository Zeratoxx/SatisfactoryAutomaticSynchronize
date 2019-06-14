@echo off

REM Die Befehle 'REM' und '::' sind Kommentare!
::  Das hier ist also auch ein Kommentar!
REM Das hier ist also auch ein Kommentar!
:: Unterschied:
:: '::'-Kommentare werden auch bei @ECHO ON ausgeblendet!!
:: 'REM'-Kommentare werden bei @ECHO ON nicht ausgeblendet!!
:: @echo off





SETLOCAL EnableExtensions
set EXE=FactoryGame.exe
set GITMESSAGE="Spielupdate Nils"
set PATHTOSAVED=C:\Users\%username%\AppData\Local\FactoryGame\Saved







cd %PATHTOSAVED%\ZZMartinSpielstand
git pull
dir /B *.sav >..\Logs\martinSav.txt
xcopy /q/y *.sav %PATHTOSAVED%\SavedGames



cd %PATHTOSAVED%\ZZJonasSpielstand
git pull
dir /B *.sav >..\Logs\jonasSav.txt
xcopy /q/y *.sav %PATHTOSAVED%\SavedGames






cd ..\Logs
START com.epicgames.launcher://apps/CrabEA?action=launch
timeout /T 5 /nobreak>nul


:SEARCH
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO (

IF %%x == %EXE% goto LOOP
)

echo Satisfactory has been closed! Starting to synchronize!
goto CONTINUE


:LOOP
echo Satisfactory is running!
timeout /T 2 /nobreak >nul
goto SEARCH







:CONTINUE
del search.log

for /F %%I in (jonasSav.txt) do (
xcopy /q/y ..\SavedGames\%%I %PATHTOSAVED%\ZZJonasSpielstand\
)
del jonasSav.txt


for /F %%I in (martinSav.txt) do (
xcopy /q/y ..\SavedGames\%%I %PATHTOSAVED%\ZZMartinSpielstand\
)
del martinSav.txt




cd %PATHTOSAVED%\ZZMartinSpielstand
git add .
git commit -m %GITMESSAGE%
git push

cd %PATHTOSAVED%\ZZJonasSpielstand
git add .
git commit -m %GITMESSAGE%
git push

exit