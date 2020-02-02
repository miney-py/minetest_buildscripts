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
echo ###################################
echo ###################################
echo Bundle minetest %ARCH% with python, miney and mineysocket
echo ###################################
echo ###################################

if not exist "dist\minetest_%ARCH%" (
  echo You need to compile minetest first!
)


if not exist "%~dp0dist\miney_%ARCH%/" (
  mkdir %~dp0dist\miney_%ARCH%
)

if not exist "%~dp0build\miney_%ARCH%/" (
  mkdir %~dp0build\miney_%ARCH%
)

if not exist "%~dp0dist\miney_%ARCH%/Minetest/" (
  echo -----------------------------------
  echo -----------------------------------
  echo Copy Minetest
  echo -----------------------------------
  echo -----------------------------------
  robocopy %~dp0dist\minetest_%ARCH% %~dp0dist\miney_%ARCH%\Minetest /e /NFL /NDL /NJH /nc /ns /np
)

if not exist "%~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Add mineysocket
  echo -----------------------------------
  echo -----------------------------------

  cd %~dp0build\miney_%ARCH%
  if exist "%~dp0build\miney_%ARCH%\mineysocket\" (
    cd %~dp0build\miney_%ARCH%\mineysocket\
    git pull
  )
  if not exist "%~dp0build\miney_%ARCH%\mineysocket\" (
    git clone git@github.com:miney-py/mineysocket.git
    cd %~dp0build\miney_%ARCH%\mineysocket\
  ) 
  if not exist "%~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\" (
    mkdir %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket
  )
  copy /B LICENSE %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\
  copy /B README.md %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\
  copy /B init.lua %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\
  copy /B mod.conf %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\
  copy /B settingtypes.txt %~dp0dist\miney_%ARCH%\Minetest\mods\mineysocket\
  
  echo secure.trusted_mods = mineysocket >> %~dp0dist\miney_%ARCH%\Minetest\minetest.conf
  
  cd %~dp0
)

if not exist "%~dp0dist\miney_%ARCH%\Python\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download and extract Python from webinstaller
  echo -----------------------------------
  echo -----------------------------------
  
  mkdir %~dp0dist\miney_%ARCH%\Python
  
  if not exist "%~dp0build\miney_%ARCH%\python_webinstaller.exe" (
    IF "%ARCH%"=="x86" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.8.1/python-3.8.1-webinstall.exe -OutFile %~dp0build\miney_%ARCH%\python_webinstaller.exe"
    )
    IF "%ARCH%"=="x64" (
      powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.8.1/python-3.8.1-amd64-webinstall.exe -OutFile %~dp0build\miney_%ARCH%\python_webinstaller.exe"
    )
  )
  if not exist "%~dp0build\miney_%ARCH%\python_tmp\" (
    %~dp0build\miney_%ARCH%\python_webinstaller.exe /quiet /layout %~dp0build\miney_%ARCH%\python_tmp
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
)

if not exist "%~dp0dist\miney_%ARCH%\Python\Lib\site-packages\pip\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Installing pip
  echo -----------------------------------
  echo -----------------------------------

  powershell -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile %~dp0build\miney_%ARCH%\python_tmp\get-pip.py"
  %~dp0dist\miney_%ARCH%\Python\python %~dp0build\miney_%ARCH%\python_tmp\get-pip.py
)

if not exist "%~dp0dist\miney_%ARCH%\Python\Lib\site-packages\miney" (
  echo -----------------------------------
  echo -----------------------------------
  echo Installing miney
  echo -----------------------------------
  echo -----------------------------------
  %~dp0dist\miney_%ARCH%\Python\python -m pip install miney
)

if not exist "%~dp0dist\miney_%ARCH%\miney_launcher.exe" (
  echo -----------------------------------
  echo -----------------------------------
  echo Installing launcher
  echo -----------------------------------
  echo -----------------------------------
  cd %~dp0build\miney_%ARCH%
  if exist "%~dp0build\miney_%ARCH%\launcher\" (
    cd %~dp0build\miney_%ARCH%\launcher\
    git pull
  )
  if not exist "%~dp0build\miney_%ARCH%\launcher\" (
    git clone https://github.com/miney-py/launcher.git
    cd %~dp0build\miney_%ARCH%\launcher\
  )
  if not exist "%~dp0dist\miney_%ARCH%\Miney\" (
    mkdir %~dp0dist\miney_%ARCH%\Miney
  )
  if not exist "%~dp0dist\miney_%ARCH%\Miney\examples\" (
    mkdir %~dp0dist\miney_%ARCH%\Miney\examples
  )
  copy /B %~dp0build\miney_%ARCH%\launcher\win32\launcher.exe %~dp0dist\miney_%ARCH%\miney_launcher.exe
  copy /B %~dp0build\miney_%ARCH%\launcher\launcher.py %~dp0dist\miney_%ARCH%\Miney\launcher.py
  copy /B %~dp0build\miney_%ARCH%\launcher\quickstart.py %~dp0dist\miney_%ARCH%\Miney
  copy /B %~dp0build\miney_%ARCH%\launcher\LICENSE %~dp0dist\miney_%ARCH%\Miney\LICENSE.txt
  robocopy %~dp0build\miney_%ARCH%\launcher\res %~dp0dist\miney_%ARCH%\Miney\res /e /NFL /NDL /NJH /nc /ns /np
)

if not exist "%~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Creating default world
  echo -----------------------------------
  echo -----------------------------------
  if not exist "%~dp0dist\miney_%ARCH%\Minetest\worlds\" (
    mkdir %~dp0dist\miney_%ARCH%\Minetest\worlds
  )
  if not exist "%~dp0dist\miney_%ARCH%\Minetest\worlds\miney\" (
    mkdir %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney
  )
  
  echo enable_damage = true >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo creative_mode = false >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo gameid = minetest >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo player_backend = sqlite3 >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo backend = sqlite3 >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo auth_backend = sqlite3 >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo load_mod_mineysocket = true >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  echo server_announce = false >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\world.mt
  
  echo seed = 746036489947438842 >> %~dp0dist\miney_%ARCH%\Minetest\worlds\Miney\map_meta.txt
)

cd %~dp0

echo Build started at %STARTTIME%
echo Build finished at %Time%
