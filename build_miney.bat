@echo off
REM Copyright (C) 2019 Robert Lieback <robertlieback@zetabyte.de>

REM This program is free software; you can redistribute it and/or modify
REM it under the terms of the GNU Lesser General Public License as published by
REM the Free Software Foundation; either version 3 of the License, or
REM (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU Lesser General Public License for more details.

REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.

SET ARCH=%1

IF [%ARCH%]==[x86] GOTO args_checked
IF [%ARCH%]==[x64] GOTO args_checked

echo Usage: build_miney.bat ^<x86/x64^> 
exit /b

:args_checked

SET STARTTIME=%Time%
echo Build started at %Time%
echo ###################################
echo ###################################
echo Bundle minetest %ARCH% with python, miney and mineysocket
echo ###################################
echo ###################################

if not exist "dist\minetest_%ARCH%" (
  echo You need to compile minetest first!
)

cd dist


if not exist "miney_%ARCH%\" (
  mkdir miney_%ARCH%
)

cd miney_%ARCH%

if not exist "%~dp0dist/miney_%ARCH%/Minetest/" (
  echo -----------------------------------
  echo -----------------------------------
  echo Copy Minetest
  echo -----------------------------------
  echo -----------------------------------
  robocopy %~dp0dist/minetest_%ARCH% %~dp0dist/miney_%ARCH%/Minetest /e /NFL /NDL /NJH /nc /ns /np
)

if not exist "Minetest\mods\mineysocket\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Add mineysocket
  echo -----------------------------------
  echo -----------------------------------
  cd %~dp0dist/miney_%ARCH%/Minetest/mods
  git clone git@github.com:miney-py/mineysocket.git
  cd %~dp0dist/miney_%ARCH%
  echo secure.trusted_mods = mineysocket >> Minetest\minetest.conf
)

if not exist "%~dp0dist/miney_%ARCH%/Python/" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download and extract Python with PIP
  echo -----------------------------------
  echo -----------------------------------
  
  mkdir %~dp0dist\miney_%ARCH%\Python
  
  if not exist "%~dp0build/miney_%ARCH%/" (
    mkdir %~dp0build\miney_%ARCH%
  )
  
  if not exist "%~dp0build/miney_%ARCH%/python_webinstaller.exe" (
    IF "%ARCH%" == "x86" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-amd64-webinstall.exe -OutFile %~dp0build/miney_%ARCH%/python_webinstaller.exe"
    )
    IF "%ARCH%" == "x64" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-webinstall.exe -OutFile %~dp0build/miney_%ARCH%/python_webinstaller.exe"
    )
  )
  if not exist "%~dp0build/miney_%ARCH%/python_tmp/" (
    %~dp0build/miney_%ARCH%/python_webinstaller.exe /quiet /layout %~dp0build/miney_%ARCH%/python_tmp
  )
  echo Installing python msi files in %~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\core.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\doc.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\exe.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\lib.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\tcltk.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  msiexec.exe /quiet /a %~dp0build\miney_%ARCH%\python_tmp\tools.msi targetdir=%~dp0dist\miney_%ARCH%\Python
  
  echo cleanup msi's
  del %~dp0dist\miney_%ARCH%\Python\*.msi
  
  echo Install pip
  REM Install PIP
  powershell -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile %~dp0build/miney_%ARCH%/python_tmp/get-pip.py"
  %~dp0dist\miney_%ARCH%\Python\python %~dp0build/miney_%ARCH%/python_tmp/get-pip.py
)

echo Build started at %STARTTIME%
echo Build finished at %Time%
