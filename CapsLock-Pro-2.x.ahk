; | !  |   alt             |
; | #  |   windows键       |
; | <# |   左边的windows键 |
; | ># |   右边的windows键 |
; | ^  |   Ctrl            |
; | +  |   Shift           |


#SingleInstance force

full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; 短按CapsLock发送ESC
CapsLock:: ESC


SetCapsLockState "AlwaysOff"
; 使用capslock+esc切换大写锁定
; 废除capslock直接切换大小写锁定的功能
Capslock & Esc::{
    If GetKeyState("CapsLock", "T") = 1
        SetCapsLockState "AlwaysOff"
    Else 
        SetCapsLockState "AlwaysOn"
}

; 使用windows terminal
CapsLock & t::
{
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
    else
        Run "wt.exe"
}

; 方向
CapsLock & h:: Left
CapsLock & l:: Right
CapsLock & j:: Down
CapsLock & k:: up

; 切换到另一个显示器
CapsLock & d:: {
    Send "#+{Left}"
}
