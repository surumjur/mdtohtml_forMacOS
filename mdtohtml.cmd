echo %~f0 %~f1
set _BUNDLE=%~dp0
set _DOC_ROOT=%~dp1
set _PYTHON=python3
set _MDTOHTML=%_BUNDLE%mdtohtml.py
set _TEMPLATES=%_BUNDLE%cs.ext.md_bundle
set _GIT=%_BUNDLE%bin\git.exe
set _JAVA=java
set _WKHTMLTOPDF=%_BUNDLE%bin\wkhtmltopdf.exe
set GRAPHVIZ_DOT=%_BUNDLE%bin\dot.exe
set _PLANTUMLJAR=%_BUNDLE%plantuml.8055.jar
set _DOC=%~n1

cd "%_TEMPLATES%"
"%_GIT%" pull
:: change current working directory to the directory of the markdown file being processed because
:: for some reason "Run with..." launches the script with Windows/System as working dir on some Windows systems
cd "%_DOC_ROOT%"
set DEVELOPDIR_SRC
if DEFINED DEVELOPDIR_SRC GOTO :end_setDEVELOPDIR_SRC
for /f %%i in ('"%_GIT%" rev-parse --show-toplevel') do set DEVELOPDIR_SRC=%%i/..
set INTERFACEStxt=%DEVELOPDIR_SRC%/../gen/interfaces.txt
:end_setDEVELOPDIR_SRC

:: transform MD to HTML and generate required HTML chunks for PDF rendering
set "_TEMPLATES_SLASH=%_TEMPLATES:\=/%"
if "%BIBFILE%"=="" set BIBFILE=%_TEMPLATES%\local.bib
if "%OVERRIDE_BIBFILE%"=="" set OVERRIDE_BIBFILE=%_TEMPLATES%\local_override.bib
if "%EXT_BIBFILE%"=="" set EXT_BIBFILE=%_TEMPLATES%\external.bib
"%_PYTHON%" "%_MDTOHTML%" %1 ^
	-t "%_TEMPLATES%\tieto_templates\main.template.html" "%_DOC%.html" ^
	-p logo "file:///%_TEMPLATES_SLASH%/tieto_templates/tieto_logo_blue.svg" ^
	-p filename "%_DOC%.pdf" ^
	-p cssroot "file:///%_TEMPLATES_SLASH%" ^
	-t "%_TEMPLATES%\tieto_templates\header.template.html" "%_DOC%.header.html" ^
	-t "%_TEMPLATES%\tieto_templates\footer.template.html" "%_DOC%.footer.html" ^
	-t "%_TEMPLATES%\tieto_templates\cover.template.html" "%_DOC%.cover.html" ^
	-t "%_TEMPLATES%\tieto_templates\toc.template.xsl" "%_DOC%.toc.xsl" >"%_DOC%.images"
echo %ERRORLEVEL%
IF ERRORLEVEL 1 GOTO errorHandling
FOR /F "tokens=1,2 delims=:" %%I IN (%_DOC%.images) DO IF %%I==image CALL :GEN_IMAGES %%J
GOTO :END_GEN_IMAGES
:GEN_IMAGES
IF EXIST %1 EXIT /B
IF EXIST "%_TEMPLATES%\tieto_templates\%~nx1" ( MD %~dp1 & COPY "%_TEMPLATES%\tieto_templates\%~nx1" "%~dp1" & EXIT /B )
echo "aaa %~dp1 %~nx1"
FOR /F "tokens=1 delims=" %%F IN ('FINDSTR /r /C:"@startuml[ 	]*%~nx1" /M "%~dp1*.*"') DO CALL :RUN_PLANTUML "%%F"
EXIT /B
:RUN_PLANTUML
echo "plant %1"
"%_JAVA%" -Djava.awt.headless=true -jar "%_PLANTUMLJAR%" -config "%_TEMPLATES%\tieto_templates\plantuml.cfg" -v -o "%~dp1." %1
EXIT /B
:END_GEN_IMAGES

:: transform HTML to PDF
"%_WKHTMLTOPDF%" ^
    --page-size A4 ^
    --margin-top 22mm ^
    --margin-bottom 22mm ^
    --margin-left 15mm ^
    --margin-right 10mm ^
    --header-spacing 5 ^
    --footer-spacing 5 ^
    --header-html "%_DOC%.header.html" ^
    --footer-html "%_DOC%.footer.html" ^
    page "%_DOC%.cover.html" ^
    toc --xsl-style-sheet "%_DOC%.toc.xsl" ^
    page "%_DOC%.html" "%_DOC%.pdf"
IF ERRORLEVEL 1 GOTO errorHandling

:: delete temporary files
del "%_DOC%.header.html"
del "%_DOC%.footer.html"
del "%_DOC%.cover.html"
del "%_DOC%.toc.xsl"
del "%_DOC%.images"
EXIT /B 0
:errorHandling
pause
EXIT /B 1
