@echo off
SET ARCH=%1

IF [%ARCH%]==[x86] GOTO args_checked
IF [%ARCH%]==[x64] GOTO args_checked

echo Usage: build_miney.bat ^<x86/x64^> 
exit /b

:args_checked

echo ###################################
echo ###################################
echo Bundle minetest %ARCH% with python, miney and mineysocket
echo ###################################
echo ###################################


if not exist "%ARCH%\" (
  mkdir miney_%ARCH%
)

if not exist "miney_%ARCH%\Minetest\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Copy Minetest
  echo -----------------------------------
  echo -----------------------------------
  robocopy %ARCH%/minetest_%ARCH% miney_%ARCH%/Minetest /e
)

if not exist "miney_%ARCH%\minetest\mods\mineysocket\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Add mineysocket
  echo -----------------------------------
  echo -----------------------------------
  cd miney_%ARCH%\Minetest\mods
  git clone git@github.com:miney-py/mineysocket.git
  cd ../../..
  echo secure.trusted_mods = mineysocket >> miney_%ARCH%\Minetest\minetest.conf
)

if not exist "miney_%ARCH%\Python\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download and extract Python with PIP
  echo -----------------------------------
  echo -----------------------------------
  
  if not exist "miney_%ARCH%\python_webinstaller.exe" (
    IF "%ARCH%" == "x86" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-amd64-webinstall.exe -OutFile miney_%ARCH%\python_webinstaller.exe"
    )
    IF "%ARCH%" == "x64" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-webinstall.exe -OutFile miney_%ARCH%\python_webinstaller.exe"
    )
  )
  if not exist "miney_%ARCH%\python_tmp\" (
    miney_%ARCH%\python_webinstaller.exe /quiet /layout miney_%ARCH%\python_tmp
  )
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\core.msi targetdir=%~dp0\miney_%ARCH%\Python
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\doc.msi targetdir=%~dp0\miney_%ARCH%\Python
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\exe.msi targetdir=%~dp0\miney_%ARCH%\Python
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\lib.msi targetdir=%~dp0\miney_%ARCH%\Python
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\tcltk.msi targetdir=%~dp0\miney_%ARCH%\Python
  msiexec.exe /quiet /a miney_%ARCH%\python_tmp\tools.msi targetdir=%~dp0\miney_%ARCH%\Python
  
  del miney_%ARCH%\Python\*.msi
  
  REM Install PIP
  powershell -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile miney_%ARCH%\python_tmp\get-pip.py"
  miney_%ARCH%\Python\python miney_%ARCH%\python_tmp\get-pip.py
  
  del miney_%ARCH%\python_tmp\get-pip.py
  del miney_%ARCH%\python_webinstaller.exe
  rd /s /q miney_%ARCH%\python_tmp
)
