set SCRIPTDIR=%~dp0

:: Destroy old associations
reg IMPORT "%SCRIPTDIR%reset_extensions.reg"

:: Add file associations
Assoc .md=markdownfile
IF ERRORLEVEL 1 GOTO errorHandling
Assoc .plantuml=plantumlfile
Ftype markdownfile="%SCRIPTDIR%mdtohtml.cmd" "%%1"
IF ERRORLEVEL 1 GOTO errorHandling
Ftype plantumlfile="%SCRIPTDIR%plantuml.cmd" "%%1"
EXIT /B 0
:errorHandling
pause
EXIT /B 1
