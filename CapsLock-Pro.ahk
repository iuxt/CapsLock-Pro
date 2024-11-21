; | !  |   alt             |
; | #  |   windows键       |
; | <# |   左边的windows键 |
; | ># |   右边的windows键 |
; | ^  |   Ctrl            |
; | +  |   Shift           |

CapsLock::Return  ; 禁用 CapsLock 默认行为
#SingleInstance force
SetCapsLockState "AlwaysOff"

; 管理员权限运行
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


tip(message, time := 5000) { ; 默认显示 5 秒
    ToolTip message
    SetTimer () => ToolTip(), -time ; 确保 time 为负值，以执行一次性定时器
}


; f5 重载配置
CapsLock & F5:: {
    tip("Reload...")
    Sleep 3000
    reload
}

; 切换CapsLock状态
CapsLock & Esc:: {
    static Toggle := false  ; 静态变量，初始值为 false
    Toggle := !Toggle        ; 切换状态
    SetCapsLockState (Toggle ? "AlwaysOn" : "AlwaysOff")
}


; 使用windows terminal
CapsLock & t::
{
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
    else
        Run "runas /trustlevel:0x20000 wt.exe"
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
