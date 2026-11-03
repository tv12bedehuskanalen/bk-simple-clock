@echo off
setlocal
cd /d "%~dp0\.."
if not exist dist mkdir dist
cl /nologo /O2 /std:c++17 /EHsc /MT /utf-8 src\windows.cpp /Fe:"dist\BK Clock.exe" /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib gdiplus.lib comdlg32.lib advapi32.lib
if errorlevel 1 exit /b 1
