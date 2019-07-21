@ECHO OFF

REM Die Befehle 'REM' und '::' sind Kommentare!
::  Das hier ist also auch ein Kommentar!
REM Das hier ist also auch ein Kommentar!
:: Unterschied:
:: '::'-Kommentare werden auch bei @ECHO ON ausgeblendet!!
:: 'REM'-Kommentare werden bei @ECHO ON nicht ausgeblendet!!
:: @ECHO OFF





SETLOCAL EnableExtensions
SETLOCAL enabledelayedexpansion
SET checkInterval=2
SET exeName=FactoryGame.exe
SET gitMessageFile=gitMessage.txt
SET PATHTOSAVED=C:\Users\%username%\AppData\Local\FactoryGame\Saved
SET nameOfWorldlistFile=listOfWorlds.txt
SET counter=0
SET listOfRepos=
SET alreadyStarted=





CD %PATHTOSAVED%
FOR /F %%f IN (%nameOfWorldlistFile%) DO (
	
	SET /A counter=counter+1
	CALL :concat !counter! %%f
)


:select


ECHO Please enter the number of the map you want to play.
ECHO.
ECHO The List:
SET b=%listOfRepos:,=^&ECHO.%
ECHO %b%
ECHO.
SET /p theChoice=Number: 
SET /a theChoice-=1

ECHO.


SET theChoicedRepo=none


IF %theChoice% EQU 0 (
	FOR /F %%l IN (%nameOfWorldlistFile%) DO SET theChoicedRepo=%%l&GOTO nextline
) ELSE (
	IF %theChoice% GTR 0 (
		FOR /F "skip=%theChoice%" %%l IN (%nameOfWorldlistFile%) DO SET theChoicedRepo=%%l&GOTO nextline
	)
)


:nextline
IF "%theChoicedRepo%"=="none" (
	ECHO Invalid input^^!^^!
	ECHO.
	ECHO.
	echo 
	GOTO select
)
ECHO.
GOTO start


:concat
IF "%listOfRepos%"=="" (
	SET listOfRepos=%1: %2
) ELSE (
	SET listOfRepos=!listOfRepos!,%1: %2
)
::callback EXIT /B
EXIT /B





:start

ECHO -----
ECHO Loading files from %theChoicedRepo%...
ECHO.

CD %PATHTOSAVED%\SaveGames
DEL /Q *


CD %PATHTOSAVED%\%theChoicedRepo%

if exist .\.git\ (
	git pull
)
DIR /B *.sav >%PATHTOSAVED%\Logs\%theChoicedRepo%.txt
ECHO.
xcopy /q/y *.sav %PATHTOSAVED%\SaveGames\
ECHO.
ECHO.

CD %PATHTOSAVED%\Logs
ECHO -----
ECHO Starting the game...
START com.epicgames.launcher://apps/CrabEA?action=launch


:checkIfRunning
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %exeName%"') DO (
	IF %%x == %exeName% (
	
		IF NOT DEFINED alreadyStarted (
			ECHO.
			SET alreadyStarted=y
		)
		
		ECHO Satisfactory is running^^!
		timeout /T %checkInterval% /nobreak >NUL
		GOTO checkIfRunning
		
	) ELSE IF DEFINED alreadyStarted (
		ECHO.
		ECHO Satisfactory has been closed^^! Starting to synchronize^^!
		GOTO continue
		
	) ELSE (
		ECHO Satisfactory was not started yet..
		timeout /T %checkInterval% /nobreak >NUL
		GOTO checkIfRunning
	)
)

IF EXIST search.log (
	DEL /Q search.log
) ELSE (
	REM Do nothing.
)


:continue
ECHO.
ECHO.
ECHO -----
ECHO Saving files...
ECHO.
CD %PATHTOSAVED%\SaveGames
xcopy /q/y *.sav %PATHTOSAVED%\%theChoicedRepo%
DEL %PATHTOSAVED%\Logs\%theChoicedRepo%.txt
ECHO.
ECHO.



SET gitMessage=Spielupdate %COMPUTERNAME%
if exist %PATHTOSAVED%\%gitMessageFile% (
FOR /F %%m IN (%PATHTOSAVED%\%gitMessageFile%) DO (
SET gitMessage=!gitMessage! %%m
)
)


CD %PATHTOSAVED%\%theChoicedRepo%
if exist .\.git\ (
git add .
git commit -m "%gitMessage%"
git push
)


ECHO.
ECHO.
ECHO Complete. Closing...
timeout /T 5 /nobreak >NUL
EXIT



