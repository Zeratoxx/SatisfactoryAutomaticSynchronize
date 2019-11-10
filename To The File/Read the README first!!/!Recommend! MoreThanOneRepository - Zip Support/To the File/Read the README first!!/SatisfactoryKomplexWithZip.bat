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
SET whichSaved=SaveGames\
SET nameOfWorldlistFile=listOfWorlds.txt
SET counter=0
SET listOfRepos=
SET alreadyStarted=
SET workWithZip=
SET searchVal=rejected




CD %PATHTOSAVED%

IF EXIST %nameOfWorldlistFile% (
	REM Go on.
) ELSE (
	ECHO Cannot find %nameOfWorldlistFile%. Please set it up correctly.
	GOTO error
)

FOR /F %%f IN (%nameOfWorldlistFile%) DO (
	
	SET /A counter=counter+1
	CALL :concat !counter! %%f
)

IF EXIST %PATHTOSAVED%\SaveGames\common\ (
		SET whichSaved=SaveGames\common\
	) ELSE (
		SET whichSaved=SaveGames\
	)





REM KEINE DEMO.
GOTO select

ECHO Anderes Programm starten?
SETLOCAL
CHOICE /n /C "JN" /m "(J / N)"
IF errorlevel 2 GOTO nein1
IF errorlevel 1 GOTO ja1






:nein1
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
	ECHO 
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
ECHO Working with %PATHTOSAVED%\%whichSaved% ...
ECHO.
ECHO Loading files from %theChoicedRepo%...
ECHO.

ECHO Deleting current sav files...
DEL /S/Q %PATHTOSAVED%\SaveGames\
ECHO.

CD %PATHTOSAVED%\%theChoicedRepo%

IF EXIST .\.git\ (
	git pull
) ELSE (
	ECHO This is not a git repository. Cannot pull.
	ECHO Trying to use local data...
)

ECHO.


IF EXIST savpackage.zip (
	SET workWithZip=y
	ECHO Working with zip file.
	IF EXIST %PATHTOSAVED%\temp\ (
		REM Do nothing.
	) ELSE (
		MKDIR %PATHTOSAVED%\temp\
	)
	
	xcopy /q/y savpackage.zip %PATHTOSAVED%\temp\
	
	CD %PATHTOSAVED%\temp
	ECHO Decompress...
	powershell.exe -command "& { Expand-Archive savpackage.zip .\ -Force; }"
	DIR /B *.sav >%PATHTOSAVED%\Logs\%theChoicedRepo%.txt
	xcopy /q/y *.sav %PATHTOSAVED%\%whichSaved%
	CD %PATHTOSAVED%\
	RMDIR /S /Q .\temp\

) ELSE (
	ECHO Working with sav files.
	DIR /B *.sav >%PATHTOSAVED%\Logs\%theChoicedRepo%.txt
	xcopy /q/y *.sav %PATHTOSAVED%\%whichSaved%
)


ECHO.
ECHO.


CD %PATHTOSAVED%\Logs
ECHO -----
ECHO Starting the game...
START com.epicgames.launcher://apps/CrabEA?action=launch


:checkIfRunning
IF EXIST search.log (
	DEL /Q search.log
) ELSE (
	REM Do nothing.
)
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


:continue
IF EXIST search.log (
	REM Clear cache, program should not get bigger and bigger.
	DEL /Q search.log
) ELSE (
	REM Do nothing.
)
ECHO.
ECHO.
ECHO -----
ECHO Working with %PATHTOSAVED%\%whichSaved% ...
ECHO.
ECHO Saving files...
ECHO.

CD %PATHTOSAVED%\SaveGames\

IF DEFINED workWithZip (
	ECHO Working with zip file.
	IF EXIST %PATHTOSAVED%\temp\ (
		REM Do nothing.
	) ELSE (
		MKDIR %PATHTOSAVED%\temp\
	)
	
	forfiles /s /m *.sav /c "cmd /c xcopy @path %PATHTOSAVED%\temp\ /q /y"
	
	CD %PATHTOSAVED%\temp
	ECHO Compress...
	powershell.exe -command "& { Compress-Archive *.sav savpackage.zip -CompressionLevel Optimal -Update; }"
	xcopy /q/y savpackage.zip %PATHTOSAVED%\%theChoicedRepo%\
	CD %PATHTOSAVED%\
	RMDIR /S /Q .\temp\
	
	
) ELSE (
	ECHO Working with sav files.
	forfiles /s /m *.sav /c "cmd /c xcopy @path %PATHTOSAVED%\%theChoicedRepo%\ /q /y"
)



DEL %PATHTOSAVED%\Logs\%theChoicedRepo%.txt
ECHO.
ECHO.



SET gitMessage=Spielupdate %COMPUTERNAME%
IF EXIST %PATHTOSAVED%\%gitMessageFile% (
	FOR /F %%m IN (%PATHTOSAVED%\%gitMessageFile%) DO (
		SET gitMessage=!gitMessage! %%m
	)
)


CD %PATHTOSAVED%\%theChoicedRepo%
IF EXIST .\.git\ (
	git add .
	git commit -m "%gitMessage%"
	cmd /E:OFF /C "git push --porcelain --verbose" > %PATHTOSAVED%\Logs\tmp.log
	FOR /F "tokens=1*delims=:" %%G IN ('findstr /n "^" %PATHTOSAVED%\Logs\tmp.log') DO (
		IF %%G EQU 2 (
			SET VAR=!VAR!%%H
		)
	)
	DEL /Q %PATHTOSAVED%\Logs\tmp.log
	
	
	IF NOT "x!VAR:%searchVal%=!"=="x%VAR%" (
		ECHO.
		ECHO Push to external repository failed^^!
		ECHO Fix the issue manually^^!^^!
		GOTO error
	) 
	ECHO.
	ECHO.
	
) ELSE (
	ECHO This is not a git repository. Cannot commit and push.
	ECHO Saves are now only local data.
)


ECHO.
ECHO.
ECHO Complete. Closing...
timeout /T 10 /nobreak >NUL
EXIT

:error
ECHO.
ECHO An error occured^^! Cancelling...
PAUSE
EXIT







:ja1
:test
@ECHO OFF

xcopy %PATHTOSAVED%\backupBeforeTest %PATHTOSAVED%\SaveGames /s /e /i
DEL /S/Q %PATHTOSAVED%\TESTTTT
RD /S/Q %PATHTOSAVED%\backupBeforeTest
xcopy %PATHTOSAVED%\SaveGames %PATHTOSAVED%\backupBeforeTest /s /e /i

PAUSE

CD %PATHTOSAVED%\SaveGames\
forfiles /s /m *.sav /c "cmd /c xcopy @path %PATHTOSAVED%\TESTTTT\&DEL /Q @path"

PAUSE
EXIT
