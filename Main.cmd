@echo off
rem SunMan.cmd
pushd "%~dp0"
cmd /c "ftype MyLab.SunMan="%~f0" %%1"
cmd /c "assoc .MyLab=MyLab.SunMan"
cls

@echo on
echo "Hello World!!!"
"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -ExecutionPolicy Bypass -NoLogo -Command "./Start-Lab.ps1"