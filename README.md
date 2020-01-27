# Minetest/Miney Buildscripts

This build_minetest script downloads all source codes and compiles them to Minetest 5.X (stable-5 branch) extended with luasocket and lua-cjson.

**WARNING: This takes 1h and 2.5 GB on my PC (Intel i5-8250U) per architecture, so double that for x86 and x64!**

The build_miney script creates a minetest distribution with python and the miney library (*soon*), so you need to build minetest first.  
Miney is a Minetest distribution, so you need to build minetest first. 

## Requirements 

- Visual Studio 2019 Build Tools
- git
- cmake

## Usage

Place this file in an empty directory and run it.

Run: build_<minetest/miney>.bat <x86/x64>

## LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
