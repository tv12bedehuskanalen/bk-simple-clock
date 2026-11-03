@echo off
setlocal
cd /d "%~dp0\.."
if not exist dist mkdir dist
pushd src
rc /nologo /fo ..\dist\Clock.res windows.rc
if errorlevel 1 exit /b 1
popd
cl /nologo /O2 /std:c++17 /EHsc /MT /utf-8 src\windows.cpp dist\Clock.res /Fe:"dist\BK Big Clock.exe" /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib gdiplus.lib comdlg32.lib advapi32.lib
if errorlevel 1 exit /b 1
