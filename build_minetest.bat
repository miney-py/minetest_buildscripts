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

echo Usage: build_minetest.bat ^<x86/x64^> 
exit /b

:args_checked

SET STARTTIME=%Time%
echo Build started at %Time%
echo ****************************************************************
echo ****************************************************************
echo Compiling a %ARCH% Minetest with luasocket and lua-cjson
echo ****************************************************************
echo ****************************************************************

if not exist "%~dp0build\" (
  mkdir %~dp0build
)

cd %~dp0build

if not exist "%~dp0build\minetest\" (
  mkdir %~dp0build\minetest
)

cd minetest

if not exist "%ARCH%\" (
  mkdir %ARCH%
)

REM We stay in this folder between building steps
cd %ARCH%

if not exist "%~dp0build\minetest\vcpkg\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download vcpkg from github
  echo -----------------------------------
  echo -----------------------------------
  mkdir %~dp0build\minetest\vcpkg
  git clone --single-branch --branch master https://github.com/microsoft/vcpkg.git %~dp0build\minetest\vcpkg
  if not exist "%~dp0build\minetest\vcpkg\vcpkg.exe" (
    cd %~dp0build\minetest\vcpkg
    call bootstrap-vcpkg.bat -disableMetrics
    cd %~dp0build\minetest\%ARCH%
  )
)


if not exist "%~dp0build\minetest\vcpkg\buildtrees\freetype\%ARCH%-windows-rel\" (
  cd %~dp0build\minetest\vcpkg
  echo -----------------------------------
  echo -----------------------------------
  echo Compiling irrlicht zlib curl[winssl] openal-soft libvorbis libogg sqlite3 freetype luajit
  echo -----------------------------------
  echo -----------------------------------
  vcpkg install irrlicht zlib curl[winssl] openal-soft libvorbis libogg sqlite3 freetype luajit --triplet %ARCH%-windows
  cd %~dp0build\minetest\%ARCH%
)
echo %Time%

if not exist "minetest\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download Minetest sources from github
  echo -----------------------------------
  echo -----------------------------------
  git clone --single-branch --branch stable-5 https://github.com/minetest/minetest.git
)

if not exist "minetest\bin\Release\minetest.exe" (
  cd minetest

  echo -----------------------------------
  echo -----------------------------------
  echo Compiling minetest
  echo -----------------------------------
  echo -----------------------------------
  IF "%ARCH%" == "x86" (
    cmake . -G "Visual Studio 16 2019" -A Win32 -DCMAKE_TOOLCHAIN_FILE=%~dp0build/minetest/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=0 -DENABLE_CURSES=0
  ) 
  IF "%ARCH%" == "x64" (
    cmake . -G "Visual Studio 16 2019" -A x64 -DCMAKE_TOOLCHAIN_FILE=%~dp0build/minetest/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=0 -DENABLE_CURSES=0
  )
  cmake --build . --config Release
  echo %Time%
  cd ..
)

if not exist "minetest_game\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download Minetest default game
  echo -----------------------------------
  echo -----------------------------------
  cd %~dp0build\minetest\%ARCH%
  git clone --single-branch --branch stable-5 https://github.com/minetest/minetest_game.git
)

if not exist "luarocks\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download and build LuaRocks
  echo -----------------------------------
  echo -----------------------------------
  git clone https://github.com/luarocks/luarocks.git luarocks_src
  cd luarocks_src
  git checkout tags/v3.2.1
  
  call install.bat /P %~dp0build/minetest/%ARCH%/luarocks /SELFCONTAINED /LUA %~dp0build/minetest/vcpkg/buildtrees/luajit/%ARCH%-windows-rel /INC %~dp0build/minetest/vcpkg/buildtrees/luajit/src/v2.0.5-970bc12ceb/src /NOADMIN /Q
  
  REM fix vs2017 call to point to correct architecture
  cd ..\luarocks
  IF "%ARCH%" == "x86" (
    powershell -Command "(gc luarocks.bat) -replace 'vcvarsall', 'vcvars32' | Out-File -encoding ASCII luarocks.bat"
  )
  IF "%ARCH%" == "x64" (
    powershell -Command "(gc luarocks.bat) -replace 'vcvarsall', 'vcvars64' | Out-File -encoding ASCII luarocks.bat"
  )
  cd ..
)

if not exist "luarocks\systree\lib\lua\5.1\cjson.dll" (
  echo -----------------------------------
  echo -----------------------------------
  echo Compiling LuaSocket and Lua-CJSON
  echo -----------------------------------
  echo -----------------------------------
  cd luarocks
  call luarocks.bat install luasocket
  call luarocks.bat install lua-cjson
  echo %Time%
  cd ..
)

if not exist "%~dp0dist" (
  mkdir "%~dp0dist"
)

if not exist "%~dp0dist\minetest_%ARCH%\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Move files to minetest_%ARCH%
  echo -----------------------------------
  echo -----------------------------------
  
  mkdir %~dp0dist\minetest_%ARCH%
  
  robocopy %~dp0build\minetest\%ARCH%\minetest\bin\Release %~dp0dist\minetest_%ARCH%\bin /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\builtin %~dp0dist\minetest_%ARCH%\builtin /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\client %~dp0dist\minetest_%ARCH%\client /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\clientmods %~dp0dist\minetest_%ARCH%\clientmods /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\doc %~dp0dist\minetest_%ARCH%\doc /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\fonts %~dp0dist\minetest_%ARCH%\fonts /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\games %~dp0dist\minetest_%ARCH%\games /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\mods %~dp0dist\minetest_%ARCH%\mods /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\po %~dp0dist\minetest_%ARCH%\po /e /NFL /NDL /NJH /nc /ns /np
  robocopy %~dp0build\minetest\%ARCH%\minetest\textures %~dp0dist\minetest_%ARCH%\textures /e /NFL /NDL /NJH /nc /ns /np
  del %~dp0dist\minetest_%ARCH%\bin\minetest.pdb
  
  robocopy %~dp0build\minetest\%ARCH%\minetest_game %~dp0dist\minetest_%ARCH%\games\minetest_game /e /NFL /NDL /NJH /nc /ns /np
  rmdir /S /Q %~dp0dist\minetest_%ARCH%\games\minetest_game\.git
  mkdir %~dp0dist\minetest_%ARCH%\worlds
  
  REM luarocks
  robocopy luarocks\systree\lib\lua\5.1 %~dp0dist\minetest_%ARCH%\bin /e /NFL /NDL /NJH /nc /ns /np
  mkdir %~dp0dist\minetest_%ARCH%\bin\lua
  robocopy luarocks\systree\share\lua\5.1 %~dp0dist\minetest_%ARCH%\bin\lua /e /NFL /NDL /NJH /nc /ns /np
  copy minetest\LICENSE.txt %~dp0dist\minetest_%ARCH%\
)

echo ###################################
echo ###################################
echo Compilation done. It's all in %~dp0dist/minetest_%ARCH%
echo ###################################
echo ###################################
echo Build started at %STARTTIME%
echo Build finished at %Time%
