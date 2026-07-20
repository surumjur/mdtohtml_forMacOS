set _BUNDLE=%~dp0
set _TEMPLATES=%_BUNDLE%cs.ext.md_bundle
set _JAVA=java
set GRAPHVIZ_DOT="%_BUNDLE%bin\dot.exe"
set _PLANTUMLJAR=%_BUNDLE%plantuml.8055.jar

"%_JAVA%" -Djava.awt.headless=true -jar "%_PLANTUMLJAR%" -config "%_TEMPLATES%\tieto_templates\plantuml.cfg" -v -o "%~dp1." "%1"
