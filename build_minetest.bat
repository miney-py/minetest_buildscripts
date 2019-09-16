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

echo Build started at %Time%
echo ****************************************************************
echo ****************************************************************
echo Compiling a %ARCH% Minetest with luasocket and lua-cjson
echo ****************************************************************
echo ****************************************************************

if not exist "%ARCH%\" (
  mkdir %ARCH%
)

REM We stay in this folder between building steps
cd %ARCH%

if not exist "vcpkg\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download vcpkg from github
  echo -----------------------------------
  echo -----------------------------------
  git clone https://github.com/microsoft/vcpkg.git
  if not exist "vcpkg.exe" (
    cd vcpkg
    call bootstrap-vcpkg.bat
    cd ..
  )
)


if not exist "vcpkg\buildtrees\freetype\%ARCH%-windows-rel\" (
  cd vcpkg
  echo -----------------------------------
  echo -----------------------------------
  echo Compiling irrlicht zlib curl[winssl] openal-soft libvorbis libogg sqlite3 freetype luajit
  echo -----------------------------------
  echo -----------------------------------
  vcpkg install irrlicht zlib curl[winssl] openal-soft libvorbis libogg sqlite3 freetype luajit --triplet %ARCH%-windows
  cd ..
)
echo %Time%

if not exist "minetest\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Download Minetest sources from github
  echo -----------------------------------
  echo -----------------------------------
  git clone https://github.com/minetest/minetest.git
)

if not exist "minetest\bin\Release\minetest.exe" (
  cd minetest

  echo -----------------------------------
  echo -----------------------------------
  echo Compiling minetest
  echo -----------------------------------
  echo -----------------------------------
  IF "%ARCH%" == "x86" (
    cmake . -G"Visual Studio 15 2017" -DCMAKE_TOOLCHAIN_FILE=%~dp0/%ARCH%/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=0 -DENABLE_CURSES=0
  ) 
  IF "%ARCH%" == "x64" (
    cmake . -G"Visual Studio 15 2017 Win64" -DCMAKE_TOOLCHAIN_FILE=%~dp0/%ARCH%/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=0 -DENABLE_CURSES=0
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
  git clone https://github.com/minetest/minetest_game.git
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
  
  call install.bat /P %~dp0\%ARCH%\luarocks /SELFCONTAINED /LUA %~dp0\%ARCH%\vcpkg\buildtrees\luajit\%ARCH%-windows-rel /INC %~dp0\%ARCH%\vcpkg\buildtrees\luajit\src\v2.0.5-970bc12ceb\src /NOADMIN /Q
  
  REM fix vs2017 call
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

if not exist "minetest_%ARCH%\" (
  echo -----------------------------------
  echo -----------------------------------
  echo Move files to minetest_%ARCH%
  echo -----------------------------------
  echo -----------------------------------
  
  mkdir minetest_%ARCH%
  
  robocopy minetest\bin\Release minetest_%ARCH%\bin /e
  robocopy minetest\builtin minetest_%ARCH%\builtin /e
  robocopy minetest\client minetest_%ARCH%\client /e
  robocopy minetest\clientmods minetest_%ARCH%\clientmods /e
  robocopy minetest\doc minetest_%ARCH%\doc /e
  robocopy minetest\fonts minetest_%ARCH%\fonts /e
  robocopy minetest\games minetest_%ARCH%\games /e
  robocopy minetest\mods minetest_%ARCH%\mods /e
  robocopy minetest\po minetest_%ARCH%\po /e
  robocopy minetest\textures minetest_%ARCH%\textures /e
  del minetest_%ARCH%\bin\minetest.pdb
  
  robocopy minetest_game minetest_%ARCH%\games\minetest_game /e
  rmdir /S /Q minetest_%ARCH%\games\minetest_game\.git
  mkdir minetest_%ARCH%\worlds
  
  REM luarocks
  robocopy luarocks\systree\lib\lua\5.1 minetest_%ARCH%\bin /e
  mkdir minetest_%ARCH%\bin\lua
  robocopy luarocks\systree\share\lua\5.1 minetest_%ARCH%\bin\lua /e
  copy minetest\LICENSE.txt minetest_%ARCH%\
)

echo ###################################
echo ###################################
echo Compilation done. It's all in %~dp0%ARCH%\minetest_%ARCH%
echo ###################################
echo ###################################
echo Build finished at %Time%
