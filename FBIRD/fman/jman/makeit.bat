@echo off


if exist rsrc.obj goto over1
d:\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1


if exist %1.obj del pacman.obj
if exist %1.exe del pacman.exe

d:\MASM32\BIN\Ml.exe /c /coff pacman.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

d:\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS pacman.obj rsrc.obj
if errorlevel 1 goto errlink

goto TheEnd

:nores
d:\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS pacman.obj
if errorlevel 1 goto errlink
dir %1
goto TheEnd

:errlink
echo _
echo Link error
goto TheEnd

:errasm
echo _
echo Assembly Error
goto TheEnd

:TheEnd

pause

