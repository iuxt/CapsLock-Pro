; | !  |   alt             |
; | #  |   windows键       |
; | <# |   左边的windows键 |
; | ># |   右边的windows键 |
; | ^  |   Ctrl            |
; | +  |   Shift           |

; If the script is not elevated, relaunch as administrator and kill current instance:
; full_command_line := DllCall("GetCommandLine", "str")
; if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
; {
;     try ; leads to having the script re-launching itself as administrator
;     {
;         if A_IsCompiled
;             Run *RunAs "%A_ScriptFullPath%" /restart
;         else
;             Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
;     }
;     ExitApp
; }


#SingleInstance force
SetCapsLockState, AlwaysOff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
  ShellRun by Lexikos
    requires: AutoHotkey_L
    license: http://creativecommons.org/publicdomain/zero/1.0/

  Credit for explaining this method goes to BrandonLive:
  http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
 
  Shell.ShellExecute(File [, Arguments, Directory, Operation, Show])
  http://msdn.microsoft.com/en-us/library/windows/desktop/gg537745

  param: "Verb" (For example, pass "RunAs" to run as administrator)
  param: Suggestion to the application about how to show its window

  see the msdn link above for detail values

  useful links:
https://autohotkey.com/board/topic/72812-run-as-standard-limited-user/page-2#entry522235
https://msdn.microsoft.com/en-us/library/windows/desktop/gg537745
https://stackoverflow.com/questions/11169431/how-to-start-a-new-process-without-administrator-privileges-from-a-process-with
https://autohotkey.com/board/topic/149689-lexikos-running-unelevated-process-from-a-uac-elevated-process/#entry733408
https://autohotkey.com/boards/viewtopic.php?t=4334



*/



ShellRun(prms*)
{
    MakeExplorerForegroundProcess()
    try {
        shellWindows := ComObjCreate("Shell.Application").Windows
        VarSetCapacity(_hwnd, 4, 0)
        desktop := shellWindows.FindWindowSW(0, "", 8, ComObj(0x4003, &_hwnd), 1)
    
        ; Retrieve top-level browser object.
        if ptlb := ComObjQuery(desktop
            , "{4C96BE40-915C-11CF-99D3-00AA004AE837}"  ; SID_STopLevelBrowser
            , "{000214E2-0000-0000-C000-000000000046}") ; IID_IShellBrowser
        {
            ; IShellBrowser.QueryActiveShellView -> IShellView
            if DllCall(NumGet(NumGet(ptlb+0)+15*A_PtrSize), "ptr", ptlb, "ptr*", psv:=0) = 0
            {
                ; Define IID_IDispatch.
                VarSetCapacity(IID_IDispatch, 16)
                NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
            
                ; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
                DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", psv
                    , "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp:=0)
            
                ; Get Shell object.
                shell := ComObj(9,pdisp,1).Application
            
                ; IShellDispatch2.ShellExecute
                shell.ShellExecute(prms*)
            
                ObjRelease(psv)
            }
            ObjRelease(ptlb)
        }
    }
    catch {
        tip("run failed")
    }
}

closeToolTip() {
    ToolTip,
}

tip(message, time:=-2500) {
    tooltip, %message%
    settimer, closeToolTip, %time%
}


;无视输入法中英文状态发送中英文字符串
;原理是, 发送英文时, 把它当做字符串来发送, 就像发送中文一样
;不通过模拟按键来发送,  而是发送它的Unicode编码
text(str)
{
    charList:=StrSplit(str)
	SetFormat, integer, hex
    for key,val in charList
    out.="{U+ " . ord(val) . "}"
	return out
}



GetProcessName(id:="") {
    if (id == "")
        id := "A"
    else
        id := "ahk_id " . id
    
    WinGet name, ProcessName, %id%
    if (name == "ApplicationFrameHost.exe") {
        ;ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow, %id%
        ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow1, %id%
        if hwnd {
            WinGet name, ProcessName, ahk_id %hwnd%
        }
    }
    return name
}


ProcessExist(name)
{
    process, exist, %name%
    if (errorlevel > 0)
        return errorlevel
    else
        return false
}


HasVal(haystack, needle)
{
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}


WinVisible(id)
{
    ;WingetPos x, y, width, height, ahk_id %id%
    WinGetTitle, title, ahk_id %id%
    ;WinGet, state, MinMax, ahk_id %id%
    ;tooltip %x% %y% %width% %height%

    ;sizeTooSmall := width < 300 && height < 300 && state != -1 ; -1 is minimized
    empty :=  !trim(title)
    ;if (!sizeTooSmall && !empty)
    ;    tooltip %x% %y% %width% %height% "%title%" 

    return  empty  ? 0 : 1
    ;return  sizeTooSmall || empty  ? 0 : 1
}


GetVisibleWindows(winFilter)
{
    ids := []

    WinGet, id, list, %winFilter%,,Program Manager
    Loop, %id%
    {
        if (WinVisible(id%A_Index%))
            ids.push(id%A_Index%)
    }
    
    if (ids.length() == 0)
    {
        pos := Instr(winFilter, "ahk_exe") - StrLen(winFilter) + StrLen("ahk_exe")
        pname := Trim(Substr(winFilter, pos))
        WinGet, id, list, ahk_class ApplicationFrameWindow
        loop, %id%
        {
            get_name := GetProcessName(id%A_index%)
            if (get_name== pname)
                ids.push(id%A_index%)
        }
    }
    return ids
}


MakeExplorerForegroundProcess()
{
    ; hwnd := WinExist("Program Manager ahk_class Progman")
    ; hwnd := WinExist("ahk_class WorkerW ahk_exe Explorer.EXE")
    DetectHiddenWindows, On
    hwnd := WinExist("ahk_class ForegroundStaging")
    DetectHiddenWindows, Off
    res := DllCall("SetForegroundWindow", "uint", hwnd)
    ; tip(hwnd ", " res)
}

MakeSelfForegroundProcess()
{
    global typoTip
    res := DllCall("SetForegroundWindow", "uint", typoTip.hwnd)
    ; tip(typoTip.hwnd ", " res)
}



MyRun(target, args := "", workingdir := "")
{
    global run_target, run_args, run_workingdir, run_start
    run_start := A_TickCount
    run_target := target
    run_args := args
    run_workingdir := workingdir
    send, !{F21}
}


MyRun2(target, args := "", workingdir := "")
{
    MakeSelfForegroundProcess()
    try 
    {
        if (workingdir && args) {
            run, %target% %args%, %workingdir%
        } 
        else if (workingdir) {
            run, %target%, %workingdir%
        } 
        else if (args) {
            run, %target% %args%
        }
        else {
            run, %target%
        }
    }
    catch e 
    {
        tip(e.message)
    } 
}

ActivateOrRun(to_activate:="", target:="", args:="", workingdir:="", RunAsAdmin:=false)
{
    global run_to_activate, run_target, run_args, run_workingdir, run_start
    run_start := A_TickCount
    run_to_activate := to_activate
    run_target := target
    run_args := args
    run_workingdir := workingdir
    ActivateOrRun2(run_to_activate, run_target, run_args, run_workingdir)
}

ActivateOrRun2(to_activate:="", target:="", args:="", workingdir:="", RunAsAdmin:=false) 
{
    SetWinDelay, 0
    if !workingdir
        workingdir := A_WorkingDir
    to_activate := Trim(to_activate)
    ; WinShow, %to_activate%
    ; if (to_activate && winexist(to_activate))
    if (to_activate && firstVisibleWindow(to_activate))
        MyGroupActivate(to_activate)
    else if (target != "")
    {
        ;showtip("not exist, try to start !")
        if (RunAsAdmin)
            {
                if (substr(target, 1, 1) == "\")
                    target := substr(target, 2, strlen(target) - 1)
                Run, "%target%" %args%, %WorkingDir%
            }

        else
        {
            oldTarget := target
            target := WhereIs(target)
            if (target)
            {
                if (SubStr(target, -3) != ".lnk")
                    ShellRun(target, args, workingdir)
                else {
                    ; 检查 lnk 是否损坏
                    FileGetShortcut, %target%, OutTarget
                    ; if FileExist(OutTarget)
                    ShellRun(target, args, workingdir)
                }

            } else {
                MyRun2(oldTarget, args, workingdir)
            }
        }

    }
}

WhereIs(FileName)
{
    ; https://autohotkey.com/board/topic/20807-fileexist-in-path-environment/


	; Working Folder
	PathName := A_WorkingDir "\"
	IfExist, % PathName FileName, Return PathName FileName

    ; absolute path
	IfExist, % FileName, Return FileName

	; Parsing DOS Path variable
	EnvGet, DosPath, Path
	Loop, Parse, DosPath, `;
	{
		IfEqual, A_LoopField,, Continue
		IfExist, % A_LoopField "\" FileName, Return A_LoopField "\" FileName
	}

	; Looking up Registry
	RegRead, PathName, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%FileName%
	IfExist, % PathName, Return PathName

}


GroupAdd(ByRef GroupName, p1:="", p2:="", p3:="", p4:="", p5:="")
{
     static g:= 1
     If (GroupName == "")
        GroupName:= "AutoName" g++
     GroupAdd %GroupName%, %p1%, %p2%, %p3%, %p4%, %p5%
}

MyGroupActivate(winFilter) 
{

    winFilter := Trim(winFilter)
    if (!winactive(winFilter))
    {
        activateFirstVisible(winFilter)
        return
    }

    ; group 是窗口组对象, 这个对象无法获取内部状态, 所以用 win_group_array_form 来储存他的状态
    global win_group
    global win_group_array_form
    global last_winFilter


    ; 判断是否进入了新的窗口组
    if (winFilter != last_winFilter)
    {
        last_winFilter := winFilter
        win_group_array_form       := []
        win_group := ""    ; 建立新的分组
    }


    ; 对比上一次的状态, 获取新的窗口, 然后把新窗口添加到 win_group_array_form 状态和 win_group
    curr_group := GetVisibleWindows(winFilter)
    loop % curr_group.Length()
    {
        val := curr_group[A_Index]
        if (!HasVal(win_group_array_form, val))
        {
            win_group_array_form.push(val)
            GroupAdd(win_group, "ahk_id " . val)
        }
    }


    ; showtip( "total:"  win_group_array_form.length())
    GroupActivate, %win_group%, R
}

SwitchWindows()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow") {
        WinGetTitle, title, A
        to_check := title . " ahk_class ApplicationFrameWindow"
    }
    else
        to_check := "ahk_exe " . GetProcessName()

    MyGroupActivate(to_check)
    return
}


activateFirstVisible(windowSelector)
{
    id := firstVisibleWindow(windowSelector)
    ; WinGet, State, MinMax, ahk_id %id%
    ; if (State = -1)
    ;     WinRestore, ahk_id %id%
    WinActivate, ahk_id %id%
}

firstVisibleWindow(windowSelector)
{
    WinGet, winList, List, %windowSelector%
    loop %winList%
    {
        item := winList%A_Index%
        WinGetTitle, title, ahk_id %item%
        ; if (Trim(title) != "") {
        WingetPos x, y, width, height, ahk_id %item%
        ; tip(width "-" height)
        if (Trim(title) != "" && (height > 20 || width > 20)) {
            return item
        }
    }
}

current_monitor_index()
{
  SysGet, numberOfMonitors, MonitorCount
  WinGetPos, winX, winY, winWidth, winHeight, A
  winMidX := winX + winWidth / 2
  winMidY := winY + winHeight / 2
  Loop %numberOfMonitors%
  {
    SysGet, monArea, Monitor, %A_Index%
    ;MsgBox, %A_Index% %monAreaLeft% %winX%
    if (winMidX >= monAreaLeft && winMidX <= monAreaRight && winMidY <= monAreaBottom && winMidY >= monAreaTop)
        return A_Index
  }
}


_ShowTip(text, size)
{
    SysGet, currMon, Monitor, % current_monitor_index()
    fontsize := (currMonRight - currMonLeft) / size

    Gui,G_Tip:destroy 
    Gui,G_Tip:New
    GUI, +Owner +LastFound
    
    Font_Colour := 0xFFFFFF ;0x2879ff
    Back_Colour := 0x000000  ; 0x34495e
    GUI, Margin, %fontsize%, % fontsize / 2
    GUI, Color, % Back_Colour
    GUI, Font, c%Font_Colour% s%fontsize%, Microsoft YaHei UI
    GUI, Add, Text, center, %text%

    GUI, show, hide
    wingetpos, X, Y, Width, Height ; , ahk_id %H_Tip%
    Gui_X := (currMonRight + currMonLeft)/2.0 - Width/2.0
    Gui_Y := (currMonTop + currMonBottom) * 0.8
    GUI, show,  NoActivate  x%Gui_X% y%Gui_Y%, Tip


    GUI, +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop 
    GUI, show, Autosize NoActivate

}


ShowTip(text,  time:=2000, size:=60) 
{
    _ShowTip(text, size)
    settimer, CancelTip, -%time%
}

CancelTip()
{
    gui,G_Tip:destroy
}


IsBrowser(pname)
{
    if pname in chrome.exe,MicrosoftEdge.exe,firefox.exe,360se.exe,opera.exe,iexplore.exe,qqbrowser.exe,sogouexplorer.exe,msedge.exe
        return true
}

SmartCloseWindow()
{
    if IsDesktopWindowActive()
        return

    WinGetclass, class, A
    name := GetProcessName()
    if IsBrowser(name)
        send, ^w
    else if WinActive("- Microsoft Visual Studio ahk_exe devenv.exe")
        send, ^{f4}
    else
    {
        if (class == "ApplicationFrameWindow"  || name == "explorer.exe")
            send, !{f4}
        else
            PostMessage, 0x112, 0xF060,,, A
    }
}

dllMouseMove(offsetX, offsetY) {
    ; 需要在文件开头 CoordMode, Mouse, Screen
    ; MouseGetPos, xpos, ypos
    ; DllCall("SetCursorPos", "int", xpos + offsetX, "int", ypos + offsetY)    

    mousemove, %offsetX%, %offsetY%, 0, R
}

showMenu(window_id) {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows On
    PostMessage, 0x5555,,,, ahk_id %window_id%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
}


showXianyukangWindow() {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows 1
    id := WinExist("ahk_class xianyukang_window")
    WinActivate, ahk_id %id%
    WinShow, ahk_id %id%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
}



slowMoveMouse(key, direction_x, direction_y) {
    global slowMoveSingle, slowMoveRepeat, moveDelay1, moveDelay2 
    one_x := direction_x * slowMoveSingle
    one_y := direction_y * slowMoveSingle
    repeat_x := direction_x * slowMoveRepeat
    repeat_y := direction_y * slowMoveRepeat
    mousemove, %one_x% , %one_y%, 0, R
    keywait, %key%, %moveDelay1%
    while (errorlevel != 0)
    {
        mousemove, %repeat_x%, %repeat_y%, 0, R
        keywait,  %key%,  %moveDelay2%
    }
}

fastMoveMouse(key, direction_x, direction_y) {
    global fastMoveSingle, fastMoveRepeat, moveDelay1, moveDelay2, SLOWMODE
    SLOWMODE := true
    one_x := direction_x *fastMoveSingle 
    one_y := direction_y *fastMoveSingle 
    repeat_x := direction_x *fastMoveRepeat 
    repeat_y := direction_y *fastMoveRepeat 
    mousemove, %one_x% , %one_y%, 0, R
    keywait, %key%, %moveDelay1%
    while (errorlevel != 0)
    {
        mousemove, %repeat_x%, %repeat_y%, 0, R
        keywait,  %key%,  %moveDelay2%
    }
}


ShowDimmer()
{
    global H_DImmer
    global DimmerInitiialized
    global Trans
    Trans := 55
    if (DimmerInitiialized == "")
    {
        SysGet,monitorcount,MonitorCount
        l:=0, t:=0, r:=0, b:=0
        Loop,%monitorcount%
        {
            SysGet,monitor,Monitor,%A_Index%
            If (monitorLeft<l)
            l:=monitorLeft
            If (monitorTop<t)
            t:=monitorTop
            If (monitorRight>r)
            r:=monitorRight
            If (monitorBottom>b)
            b:=monitorBottom
        }
        resolutionRight:=r+Abs(l)
        resolutionBottom:=b+Abs(t)

        Gui,G_Dimmer:New, +HwndH_DImmer +ToolWindow +Disabled -SysMenu -Caption +E0x20 +AlwaysOnTop 
        Gui,Margin,0,0
        Gui,Color,000000
        Gui,G_Dimmer:Show, X0 Y9999 W1 H1, _____
        Gui,G_Dimmer:Show, X%l% Y%t% W%resolutionRight% H%resolutionBottom%, _____

        gui, G_Dimmer:show, NoActivate
        WinSet,Transparent,%Trans%, ahk_id %H_DImmer%
        DimmerInitiialized := true
        settimer, WaitThenCloseDimmer, -400
        }
    else
    {

        IfWinActive, __KeyboardGeekCommandBar
            return
        Gui, G_Dimmer:Default,  
        Gui, +AlwaysOnTop 
        Gui,  show, NoActivate
        ;Gui,G_Dimmer:New, +HwndH_DImmer +ToolWindow +Disabled -SysMenu -Caption +E0x20 
        WinSet,Transparent,%Trans%, ahk_id %H_DImmer%
        settimer, WaitThenCloseDimmer, -400
    }
}


WaitThenCloseDimmer() {
    settimer , WaitThenCloseDimmer, 150
    winget, pname, ProcessName, A
    if pname not in  KeyboardGeek.exe,Listary.exe
    {
        Gui, G_Dimmer:Default
        gui, +LastFound
            While ( Trans > 0) ;这样做是增加淡出效果;
            { 		
                    Trans -= 6
                    WinSet, Transparent, %Trans% ;,  ahk_id %H_DImmer%
                    Sleep, 4
            }
        Gui, hide
        settimer ,WaitThenCloseDimmer,off
    }
}




getProcessPath() 
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    winget, exeFullPath, ProcessPath, ahk_id %A_ScriptHwnd%
    winget, pid, PID, ahk_id %A_ScriptHwnd%
    DetectHiddenWindows, %old%

    pos := InStr(exeFullPath, "\",, 0)
    parentPath := substr(exeFullPath, 1, pos)
    return parentPath
}

moveActiveWindow()
{
    wingetclass, class, A
    if (class == "ApplicationFrameWindow")
        {
            sendevent {lalt down}{space down}
            sleep 10
            sendevent {space up}{lalt up}
            sleep 10
            sendevent m{left}
        }
    else 
    {
        postmessage 0x0112, 0xF010, 0,, A
        send, {left}
    }
}

exitMouseMode() 
{
    global SLOWMODE
    SLOWMODE := false
    send, {blind}{Lbutton up}
}


ShowCommandBar()
{
    old := A_DetectHiddenWindows
    DetectHiddenWindows, 1
    PostMessage, 0x8003, 0, 0, , __KeyboardGeekInvisibleWindow
    DetectHiddenWindows, %old%
    ; winshow, __KeyboardGeekCommandBar
    ; winactivate, __KeyboardGeekCommandBar
}


arrayContains(arr, target) 
{
    for index,value in arr 
        if (value == target)
            return true
    return false
}


wp_GetMonitorAt(x, y, default=1)
{
    SysGet, m, MonitorCount
    ; Iterate through all monitors.
    Loop, %m%
    {   ; Check if the window is on this monitor.
        SysGet, Mon, Monitor, %A_Index%
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
            return A_Index
    }

    return default
}

IsDesktopWindowActive()
{
    return WinActive("Program Manager ahk_class Progman") || WinActive("ahk_class WorkerW")
}

center_window_to_current_monitor(width, height)
{
    if IsDesktopWindowActive()
        return

    ; 在 mousemove 时需要 PER_MONITOR_AWARE (-3), 否则当两个显示器有不同的缩放比例时,  mousemove 会有诡异的漂移
    ; 在 winmove   时需要 UNAWARE (-1),           这样即使写死了窗口大小为 1200x800,  系统会帮你缩放到合适的大小
    DllCall("SetThreadDpiAwarenessContext", "ptr", -1, "ptr")

    ; WinExist win will set "A" to default window
    WinExist("A")
    SetWinDelay, 0
    WinGet, state, MinMax
    if state
        WinRestore
    WinGetPos, x, y, w, h
    ; Determine which monitor contains the center of the window.
    ms := wp_GetMonitorAt(x+w/2, y+h/2)
    ; Get source and destination work areas (excludes taskbar-reserved space.)
    SysGet, ms, MonitorWorkArea, %ms%
    msw := msRight - msLeft
    msh := msBottom - msTop
    ; win_w := msw * 0.67
    ; win_h := (msw * 10 / 16) * 0.7
    ; win_w := Min(win_w, win_h * 1.54)
    win_w := width
    win_h := height
    win_x := msLeft + (msw - win_w) / 2
    win_y := msTop + (msh - win_h) / 2
    winmove,,, %win_x%, %win_y%, %win_w%, %win_h%
    DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
}

winMaximizeIgnoreDesktop()
{
    if IsDesktopWindowActive()
        return
    winmaximize, A
}

winMinimizeIgnoreDesktop() 
{
    if IsDesktopWindowActive()
        return
    if (winactive("ahk_exe Rainmeter.exe"))
        return
    WinMinimize, A
}


scrollOnce(direction, scrollCount :=1)
{
    if (direction == 1) {
        MouseClick, WheelUp, , , %scrollCount%
    }
    if (direction == 2) {
        MouseClick, WheelDown, , , %scrollCount%
    }
    if (direction == 3) {
        MouseClick, WheelLeft, , , %scrollCount%
    }
    if (direction == 4) {
        MouseClick, WheelRight, , , %scrollCount%
    }
}
scrollWheel(key, direction) {
    global scrollOnceLineCount, scrollDelay1, scrollDelay2 
    scrollOnce(direction, scrollOnceLineCount)
    keywait, %key%, %scrollDelay1%
    while (errorlevel != 0)
    {
        scrollOnce(direction)
        keywait,  %key%,  %scrollDelay2%
    }
}

toggleCapslock() {
    ; 方案 2,  未测试
    send, {Blind}{Lctrl}{LAlt UP}{CapsLock}
    
    ; 方案 1,  输入法大小写指示可能不对
    ; newState := !GetKeyState("CapsLock", "T")
    ; SetCapsLockState %newState%
    ; if (newState)
    ;     tip("CapsLock 开启", -400)
    ; else
    ;     tip("CapsLock 关闭", -400)
}


surroundWithSpace(message) {
    return "   " . message . "   "
}

ToggleTopMost()
{
    winexist("A")
    WinGet, style, ExStyle
    if (style & 0x8) {
         style := "  取消置顶  "
         winset, alwaysontop, off
    }
    else {
         style := "  置顶窗口  "
         winset, alwaysontop, on
    }
    tip(style, -500)
}

getProcessList(pname)
{
   result := []
   for proc in ComObjGet("winmgmts:").ExecQuery("SELECT Name,Handle FROM Win32_Process WHERE Name='MyKeymap.exe'")
      result.push(proc.Handle)
   return result
}

moveCurrentWindow()
{
    PostMessage, 0x0112, 0xF010, 0,, A
    sleep 50
    SendInput, {right}
}

toggleAutoHideTaskBar()
{
    VarSetCapacity(APPBARDATA, A_PtrSize=4 ? 36:48)
    NumPut(DllCall("Shell32\SHAppBarMessage", "UInt", 4 ; ABM_GETSTATE
                                           , "Ptr", &APPBARDATA
                                           , "Int")
 ? 2:1, APPBARDATA, A_PtrSize=4 ? 32:40) ; 2 - ABS_ALWAYSONTOP, 1 - ABS_AUTOHIDE
 , DllCall("Shell32\SHAppBarMessage", "UInt", 10 ; ABM_SETSTATE
                                    , "Ptr", &APPBARDATA)
}


; 参考 => https://www.autohotkey.com/boards/viewtopic.php?p=255256#p255256
; 返回文件管理器中选中的文件列表
; 如果没有选中任何东西,  返回当前所在文件夹的路径 (甚至是 shell clsid,  amazing !)
Explorer_GetSelection() 
{
    WinGetClass, winClass, % "ahk_id" . hWnd := WinExist("A")
    if !(winClass ~="Progman|WorkerW|(Cabinet|Explore)WClass")
        Return

    shellWindows := ComObjCreate("Shell.Application").Windows
    if (winClass ~= "Progman|WorkerW")
        shellFolderView := shellWindows.FindWindowSW(0, 0, SWC_DESKTOP := 8, 0, SWFO_NEEDDISPATCH := 1).Document
    else {
        for window in shellWindows
            if (hWnd = window.HWND) && (shellFolderView := window.Document)
            break
    }
    ; FolerItem 对象参考 => https://docs.microsoft.com/en-us/windows/win32/shell/folderitem
    ; for item in shellFolderView.SelectedItems
    ;     result .= (result = "" ? "" : "`n") . item.Path
    ; if !result
    ;     result := shellFolderView.Folder.Self.Path
    ; Return """" StrReplace(result, "`n", """ """)  """"

    res := {}
    res.current := shellFolderView.Folder.Self.Path

    paths := ""
    for item in shellFolderView.SelectedItems
    {
        paths .= (paths == "" ? "" : " ") . ("""" item.Path """")
        res.filename := item.Name
    }
    res.selected := paths ? paths : res.current

    res.purename := res.filename
    if (res.filename && ( pos := InStr(res.filename, ".", false, 0))) {
        res.purename := SubStr(res.filename, 1 , pos - 1)
    }

    ; MsgBox, % "current: " res.current "`npaths: " res.selected "`nfilename: " res.filename "`npurename: " res.purename
    Return res
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                                    以下是按键定义                                                                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; vscode打开博客代码
CapsLock & 0::
    ActivateOrRun("zahuifan [WSL: Ubuntu] - Visual Studio Code", "wsl.exe", "bash -c ""cd $HOME/code/zahuifan && code .""", "")
    ; ActivateOrRun("窗口标识符", "程序路径/文件夹/url", "命令行参数", "工作目录")
return

; 切换大小写
CapsLock & `::
GetKeyState, CapsLockState, CapsLock, T
if CapsLockState = D
    SetCapsLockState, AlwaysOff
else
    SetCapsLockState, AlwaysOn
KeyWait, ``
return

; 短按CapsLock发送ESC
; CapsLock::Send, {ESC}


; f5 重载配置
CapsLock & F5::
    tip("Reload...")
    sleep 1000
    reload
return

; ctrl alt t 打开终端
^!t::
    ActivateOrRun("ahk_exe WindowsTerminal.exe", "wt.exe", "", "")
return

; 最大化窗口
CapsLock & q::
    winMaximizeIgnoreDesktop()
return

; 最小化窗口
CapsLock & z::
    winMinimizeIgnoreDesktop()
Return

; 当前窗口调成1366x768
CapsLock & a::
    center_window_to_current_monitor(1366, 768)
return

; 向左选择
CapsLock & h::
if GetKeyState("alt") = 0
    Send, {Left}
else
    Send, +{Left}
return


CapsLock & j::
if GetKeyState("alt") = 0
    Send, {Down}
else
    Send, +{Down}
return


CapsLock & k::
if GetKeyState("alt") = 0
    Send, {Up}
else
    Send, +{Up}
return


CapsLock & l::
if GetKeyState("alt") = 0
    Send, {Right}
else
    Send, +{Right}
return

CapsLock & u::
    Send, {Home}
return

CapsLock & i::
    Send, {End}
return

; 换行
CapsLock & o::
if GetKeyState("alt") = 0 {
    Send, {End}{Enter}
} Else {
    Send, {Home}{Enter}{Up}
}
return

CapsLock & x:: Send, {Home}+{End}^x
CapsLock & c:: Send, {Home}+{End}^{insert}
CapsLock & v:: Send, +{insert}

; 关闭程序
CapsLock & w::
    SmartCloseWindow()
return

; 移动窗口到另一个显示器
CapsLock & d::
    Send, #+{Right}
Return

; 删除一整行
CapsLock & BackSpace:: 
    Send, {Home}+{End}
    Send, {Del}
Return


; 在我的博客搜索
CapsLock & s:: Run "https://cn.bing.com/search?q=site:zahui.fan"
CapsLock & r:: Run Powershell

CapsLock & 1:: Send,+1
CapsLock & 2:: Send,+2
CapsLock & 3:: Send,+3
CapsLock & 4:: Send,+4
CapsLock & 5:: Send,+5
CapsLock & 6:: Send,+6
CapsLock & 7:: Send,+7
CapsLock & 8:: Send,+8
CapsLock & 9:: Send,+9
