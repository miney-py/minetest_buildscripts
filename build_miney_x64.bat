@echo off
SET ARCH=x64

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

REM if not exist "miney_%ARCH%\python\" (
  REM echo -----------------------------------
  REM echo -----------------------------------
  REM echo Add python
  REM echo -----------------------------------
  REM echo -----------------------------------
  REM if not exist "miney_%ARCH%\python.zip" (
    REM IF "%ARCH%" == "x86" (
      REM powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-embed-amd64.zip -OutFile miney_%ARCH%\python.zip"
    REM )
    REM IF "%ARCH%" == "x64" (
      REM powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.7.4/python-3.7.4-embed-win32.zip -OutFile miney_%ARCH%\python.zip"
    REM )
  REM )
  REM powershell -Command "Expand-Archive -Path miney_%ARCH%\python.zip -DestinationPath miney_%ARCH%\Python"
  REM del miney_%ARCH%\python.zip
  REM powershell -Command "(gc miney_%ARCH%\Python\python37._pth) -replace '#import site', 'import site' | Out-File -encoding ASCII miney_%ARCH%\Python\python37._pth"
  REM powershell -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile miney_%ARCH%\get-pip.py"
  REM miney_%ARCH%\Python\python miney_%ARCH%\get-pip.py
  REM del miney_%ARCH%\get-pip.py
  REM miney_%ARCH%\Python\python -m pip install thonny
REM )
