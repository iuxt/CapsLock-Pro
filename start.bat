@echo off
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

start "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" C:\Users\iuxt\OneDrive\1\CapsLock-Pro\CapsLock-Pro-2.x.ahk
