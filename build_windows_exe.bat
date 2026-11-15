@echo off
rem ===========================================================================
rem  IED Doctor - build a single IEDDoctor.exe for Windows
rem
rem  Run this ONCE on a Windows PC that has Python 3.9+ (python.org installer,
rem  "Add python.exe to PATH" ticked). Internet access to pypi.org is needed
rem  the first time to download PyInstaller.
rem
rem  Result: dist\IEDDoctor.exe  - copy that one file to any Windows 10/11
rem  PC. It runs WITHOUT Python. (Live capture / GOOSE publishing still needs
rem  the Npcap driver on the target PC: https://npcap.com)
rem ===========================================================================
setlocal
cd /d "%~dp0"

rem ---- find Python ----------------------------------------------------------
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY ( where python >nul 2>nul && set "PY=python" )
if not defined PY (
  echo [ERROR] Python 3.9+ was not found. Install it from https://www.python.org/downloads/
  echo         and tick "Add python.exe to PATH". Python is only needed for building.
  goto :fail
)
%PY% -c "import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)" || (
  echo [ERROR] Python 3.9 or newer is required.
  goto :fail
)

rem ---- isolated build environment ------------------------------------------
if not exist ".build-venv\Scripts\python.exe" (
  echo Creating build environment .build-venv ...
  %PY% -m venv .build-venv || goto :fail
)
set "VPY=.build-venv\Scripts\python.exe"
echo Installing / updating PyInstaller ...
"%VPY%" -m pip install --disable-pip-version-check --quiet --upgrade pip || goto :fail
"%VPY%" -m pip install --disable-pip-version-check --quiet "pyinstaller>=6.3" "pywebview>=5.0" || goto :fail

rem ---- build ------------------------------------------------------------------
echo Building IEDDoctor.exe ...
if exist build rmdir /s /q build
if exist dist\IEDDoctor.exe del /q dist\IEDDoctor.exe
"%VPY%" -m PyInstaller --noconfirm --clean --onefile --console ^
  --name IEDDoctor ^
  --icon "assets\IEDDoctor.ico" ^
  --add-data "ied_doctor\web;ied_doctor\web" ^
  --add-data "ied_doctor\examples;ied_doctor\examples" ^
  --add-data "ied_doctor\assets;ied_doctor\assets" ^
  --hidden-import webview.platforms.edgechromium ^
  --hidden-import webview.platforms.winforms ^
  --collect-data webview ^
  --collect-binaries webview ^
  --collect-all clr_loader ^
  --collect-all pythonnet ^
  --hidden-import clr ^
  --collect-submodules ied_doctor ^
  run.py || goto :fail

rem ---- package next to the exe ---------------------------------------------------
copy /y README.md dist\README.md >nul
if not exist dist\examples mkdir dist\examples
copy /y ied_doctor\examples\*.scd dist\examples\ >nul
if exist build rmdir /s /q build
if exist IEDDoctor.spec del /q IEDDoctor.spec

echo.
echo ===========================================================================
echo  Done:  %cd%\dist\IEDDoctor.exe
echo  Copy this single file to the target PC and double-click it.
echo  A start dialog asks: desktop window or web browser (IEDDoctor.exe --gui / --web skip it).
echo  Desktop mode uses Microsoft Edge WebView2 (built into Windows 10/11).
echo.
echo  Checking the desktop mode of the new exe:
dist\IEDDoctor.exe --diag
echo  Options:  IEDDoctor.exe --help
echo ===========================================================================
pause
exit /b 0

:fail
echo.
echo Build FAILED - see the messages above.
pause
exit /b 1
