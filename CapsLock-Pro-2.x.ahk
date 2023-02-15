; | !  |   alt             |
; | #  |   windows键       |
; | <# |   左边的windows键 |
; | ># |   右边的windows键 |
; | ^  |   Ctrl            |
; | +  |   Shift           |


#SingleInstance force
SetCapsLockState "AlwaysOff"

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

tip(message, time:=-5000) {
    ToolTip message
    SetTimer () => ToolTip(), time
}

; f5 重载配置
CapsLock & F5:: {
    tip("Reload...")
    sleep 1500
    reload
}

; 使用capslock+esc切换大写锁定
; 废除capslock直接切换大小写锁定的功能
Capslock & Esc::{
    If GetKeyState("CapsLock", "T") = 1
        SetCapsLockState "AlwaysOff"
    Else 
        SetCapsLockState "AlwaysOn"
    KeyWait "Esc"
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

CapsLock & u:: {
    Send "{Home}"
}

CapsLock & i:: {
    Send "{End}"
}

; 新建一行，光标移到下一行
CapsLock & o:: {
    Send "{End}"
    Send "{Enter}"
}

; 切换到另一个显示器
CapsLock & d:: {
    Send "#+{Left}"
}

; bing搜索博客
CapsLock & s:: Run "https://cn.bing.com/search?q=site:zahui.fan"
