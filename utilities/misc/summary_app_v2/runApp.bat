@ECHO off

ECHO ################################################
ECHO SUMMARIZE MODEL RESULTS - SR11 OME MODEL
ECHO.
ECHO Ashish Kulshrestha (ashish.kulshrestha@wsp.com)
ECHO WSP
ECHO %Date%
ECHO ################################################

SET rPath="C:\Program Files\R\R-3.3.2\bin\x64"

::SET codePath=%~dp0

%rPath%\Rscript.exe "%~dp0\run.R" "%codePath%"