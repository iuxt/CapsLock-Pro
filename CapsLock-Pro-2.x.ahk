; | !  |   alt             |
; | #  |   windows键       |
; | <# |   左边的windows键 |
; | ># |   右边的windows键 |
; | ^  |   Ctrl            |
; | +  |   Shift           |

#SingleInstance force

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


; #n::
; {
;     if WinExist("ahk_class Notepad")
;         WinActivate  ; Activate the window found above
;     else
;         Run "notepad"  ; Open a new Notepad window
; }

; 向左选择
CapsLock & h:: Left
CapsLock & l:: Right
CapsLock & j:: Down
CapsLock & k:: up


