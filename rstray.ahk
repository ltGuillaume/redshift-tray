; Redshift Tray - https://github.com/ltGuillaume/Redshift-Tray
;@Ahk2Exe-SetFileVersion 2.2.3

; AHK 32-bit keybd hook with #If breaks if other apps slow down keybd processing (https://www.autohotkey.com/boards/viewtopic.php?t=82158)
;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-SetDescription Redshift Tray
;@Ahk2Exe-SetMainIcon Icons\redshift.ico
;@Ahk2Exe-AddResource Icons\redshift-6500k.ico, 160
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

#NoEnv
#SingleInstance Off

#MaxHotkeysPerInterval 200
#MenuMaskKey vk07	; Use unassigned key instead of Ctrl to mask Win/Alt keyup
Process Priority,, High
SetKeyDelay -1
SetTitleMatchMode 2
SetWorkingDir %A_ScriptDir%

; Global variables (when also used in functions)
Global exe = "redshift.exe", ini = "rstray.ini", s = "Switches", v = "Values", taskname = "Redshift Tray (" A_UserName ")"
Global colorizecursor, customtimes, fullscreenmode, hotkeys, extrahotkeys, keepbrightness, keepcalibration, nofading, remotedesktop, rdpnumlock, runasadmin, startdisabled, traveling	; Switches
Global lat, lon, day, night, brightness, fullscreen, fullscreenignore, pauseminutes, daytime, nighttime, keepaliveseconds, ctrlwforralt	; Values
Global mode, prevmode, temperature, restorebrightness, timer, endtime, customnight, isfullscreen, pid, ralt, rctrl, rdpclient, remote, rundialog, shell, ver, winchange, withcaption := Object()	; Internal
FileGetVersion ver, %A_ScriptFullPath%
ver := SubStr(ver, 1, -2)
; Settings from .ini
IniRead lat, %ini%, %v%, latitude, 0.0
IniRead lon, %ini%, %v%, longitude, 0.0
IniRead day, %ini%, %v%, daytemp, 6500
IniRead night, %ini%, %v%, nighttemp, 3500
IniRead brightness, %ini%, %v%, brightness, 1
IniRead ctrlwforralt, %ini%, %v%, ctrlwforralt, |
IniRead fullscreen, %ini%, %v%, fullscreentemp, 6500
IniRead fullscreenignore, %ini%, %v%, fullscreenignore, |
IniRead pauseminutes, %ini%, %v%, pauseminutes, 10
IniRead daytime, %ini%, %v%, daytime, HHmm
IniRead nighttime, %ini%, %v%, nighttime, HHmm
IniRead keepaliveseconds, %ini%, %v%, keepaliveseconds, 0
IniRead colorizecursor, %ini%, %s%, colorizecursor, 0
IniRead customtimes, %ini%, %s%, customtimes, 0
IniRead fullscreenmode, %ini%, %s%, fullscreenmode, 0
IniRead hotkeys, %ini%, %s%, hotkeys, 1
IniRead extrahotkeys, %ini%, %s%, extrahotkeys, 0
IniRead keepbrightness, %ini%, %s%, keepbrightness, 0
IniRead keepcalibration, %ini%, %s%, keepcalibration, 0
IniRead nofading, %ini%, %s%, nofading, 0
IniRead remotedesktop, %ini%, %s%, remotedesktop, 0
IniRead rdpnumlock, %ini%, %s%, rdpnumlock, 0
IniRead runasadmin, %ini%, %s%, runasadmin, 0
IniRead startdisabled, %ini%, %s%, startdisabled, 0
IniRead traveling, %ini%, %s%, traveling, 0

; Initialize
If !A_IsAdmin And (runasadmin Or keepcalibration) {
	Try {
		Run *RunAs "%A_ScriptFullPath%" /r
	}
	ExitApp
}

; Close other instances
DetectHiddenWindows On
WinGet self, List, %A_ScriptName% ahk_exe %A_ScriptName%
Loop %self%
	If (self%A_Index% != A_ScriptHwnd)
		PostMessage 0x0010,,,, % "ahk_id" self%A_Index%
DetectHiddenWindows Off

OnExit("Exit")

; Set up tray menu
Menu Tray, NoStandard
Menu Tray, Tip, Redshift Tray %ver%
Menu Tray, Add, &Enabled, Enable, Radio
Menu Tray, Add, &Forced, Force, Radio
Menu Tray, Add, &Paused, Pause, Radio
Menu Tray, Add, &Disabled, Disable, Radio
Menu Tray, Add
Menu Tray, Add, &Help, Help
Menu Settings, Add, &Autorun, Autorun
Menu Settings, Add, &Colorize cursor, ColorizeCursor
Menu Settings, Add, &Custom times, CustomTimes
Menu Settings, Add, &Full-screen mode, FullScreen
Menu Settings, Add, &Hotkeys, Hotkeys
Menu Settings, Add, &Extra hotkeys, ExtraHotkeys
Menu Settings, Add, &Keep brightness when disabled, KeepBrightness
Menu Settings, Add, Keep &Windows calibration, KeepCalibration
Menu Settings, Add, &No fading, NoFading
Menu Settings, Add, &Remote Desktop support, RemoteDesktop
Menu Settings, Add, Set Num&Lock on RDP disconnect, RDPNumLock
Menu Settings, Add, &Run as administrator, RunAsAdmin
Menu Settings, Add, &Start disabled, StartDisabled
Menu Settings, Add, &Traveling, Traveling
Menu Settings, Add
Menu Settings, Add, &More settings..., Settings
Menu Tray, Add, &Settings, :Settings
Menu Tray, Add
Menu Tray, Add, &Restart, Restart
Menu Tray, Add, E&xit, Exit

If A_Args.Length() > 0
	Autorun(A_Args[1])
If AutorunOn()
	Menu Settings, Check, &Autorun
ColorizeCursor()
If customtimes
	Menu Settings, Check, &Custom times
if fullscreenmode
	Menu Settings, Check, &Full-screen mode
If keepbrightness
	Menu Settings, Check, &Keep brightness when disabled
If nofading
	Menu Settings, Check, &No fading
If hotkeys
	Menu Settings, Check, &Hotkeys
If extrahotkeys {
	PrepRunGui()
	Gui RunGui:Show, x9999 y9999
	Gui RunGui:Cancel
	Menu Settings, Check, &Extra hotkeys
} Else {
	Hotkey RAlt & `,, Off
	Hotkey RAlt & ., Off
}
If keepbrightness
	Menu Settings, Check, &Keep brightness when disabled
If keepcalibration
	Menu Settings, Check, Keep &Windows calibration
If nofading
	Menu Settings, Check, &No fading
If remotedesktop
	Menu Settings, Check, &Remote Desktop support
If rdpnumlock
	Menu Settings, Check, Set Num&Lock on RDP disconnect
If runasadmin
	Menu Settings, Check, &Run as administrator
If startdisabled
	Menu Settings, Check, &Start disabled
If traveling
	Menu Settings, Check, &Traveling

; Set mode
If remotedesktop
	PrepWinChange()
If customtimes {
	If (daytime = "HHmm" Or nighttime = "HHmm") {
		MsgBox 64, Custom Times, Please fill in nighttime and daytime (use military times),`nthen save and close the settings file.
		Goto Settings
	}
	SetTimer CustomTimesMode, 60000
	If !startdisabled
		Goto CustomTimesMode
}
If startdisabled
	Goto Disable
If RemoteSession()
	Goto RemoteDesktopMode

; Or else, Enable:
Enable:
	If keepaliveseconds
		SetTimer CheckRunning, Off
	mode = enabled
	timer = 0
	Menu Tray, Uncheck, &Disabled
	Menu Tray, UnCheck, &Forced
	Menu Tray, Uncheck, &Paused
	Menu Tray, Check, &Enabled
	Menu Tray, Default, &Disabled
	TrayIcon()
	If (traveling Or lat = 0.0 Or lon = 0.0)
		GetLocation()
	If (lat = 0.0 Or lon = 0.0)
		Goto Settings
	If !keepbrightness And restorebrightness {
		brightness = %restorebrightness%
		restorebrightness =
	}
	Run()
	If fullscreenmode And !winchange
		PrepWinChange()
	If keepaliveseconds
		SetTimer CheckRunning, % keepaliveseconds * 1000
Return

Force:
	If mode = forced
		Return
	prevmode = %mode%
	mode = forced
	timer = 0
	temperature = %night%
	Menu Tray, UnCheck, &Enabled
	Menu Tray, Uncheck, &Disabled
	Menu Tray, Uncheck, &Paused
	Menu Tray, Check, &Forced
	Menu Tray, Default, &Enabled
	TrayIcon()
	Run()
Return

EndForce:
	If mode <> forced
		Return
	If prevmode = disabled
		Goto Disable
	Else
		Goto Enable

Disable:
	If isfullscreen <> 1
		mode = disabled
	timer = 0
	If !keepbrightness {
		restorebrightness = %brightness%
		brightness = 1
	}
	Menu Tray, Uncheck, &Enabled
	Menu Tray, UnCheck, &Forced
	Menu Tray, Uncheck, &Paused
	Menu Tray, Check, &Disabled
	Menu Tray, Default, &Enabled
	TrayIcon(0)
	Restore()
	If keepbrightness
		Run()
	TrayTip()
	ClearMem()
Return

Pause:
	mode = paused
	timer := pauseminutes * 60
	endtime =
	endtime += timer, seconds
	FormatTime endtime, %endtime%, HH:mm:ss
	If !keepbrightness {
		restorebrightness = %brightness%
		brightness = 1
	}
	Menu Tray, Uncheck, &Enabled
	Menu Tray, Uncheck, &Disabled
	Menu Tray, UnCheck, &Forced
	Menu Tray, Check, &Paused
	Menu Tray, Default, &Enabled
	TrayIcon(0)
	Restore()
	If keepbrightness
		Run()
	TrayTip()
	timer -= 10
	SetTimer Paused, 10000
Return

Paused:
	If (timer > 0 And mode = "paused") {
		timer -= 10
	} Else {
		SetTimer,, Delete
		If mode = paused
			Goto Enable
	}
Return

Help:
	Gui Add, ActiveX, w800 h600 vBrowser, Shell.Explorer
	browser.Navigate("file://" A_ScriptDir "/readme.htm")
	Gui Show,, Help
Return

GuiClose:
GuiEscape:
	Gui Destroy
	ClearMem()
Return

Autorun:
	Autorun()
Return

ColorizeCursor:
	Toggle("colorizecursor")
	ColorizeCursor()
Return

CustomTimes:
	Toggle("customtimes")
Goto Restart

FullScreen:
	Toggle("fullscreenmode")
	Menu Settings, ToggleCheck, &Full-screen mode
	If fullscreenmode And !winchange
			PrepWinChange()
Return

Hotkeys:
	Toggle("hotkeys")
	Menu Settings, ToggleCheck, &Hotkeys
Return

ExtraHotkeys:
	Toggle("extrahotkeys")
	Menu Settings, ToggleCheck, &Extra hotkeys
	If extrahotkeys {
		PrepRunGui()
		Hotkey RAlt & `,, On
		Hotkey RAlt & ., On
	} Else {
		Hotkey RAlt & `,, Off
		Hotkey RAlt & ., Off
	}
Return

KeepBrightness:
	Toggle("keepbrightness")
	Menu Settings, ToggleCheck, &Keep brightness when disabled
Return

KeepCalibration:
	Toggle("keepcalibration")
	Menu Settings, ToggleCheck, Keep &Windows calibration
	If AutorunOn()
		Autorun(TRUE)
	If keepcalibration And !A_IsAdmin
		Reload
Return

NoFading:
	Toggle("nofading")
	Menu Settings, ToggleCheck, &No fading
Return

RemoteDesktop:
	Toggle("remotedesktop")
	Menu Settings, ToggleCheck, &Remote Desktop support
	If remotedesktop And !winchange
		PrepWinChange()
Return

RDPNumLock:
	Toggle("rdpnumlock")
	Menu Settings, ToggleCheck, Set Num&Lock on RDP disconnect
Return

RunAsAdmin:
	Toggle("runasadmin")
	If AutorunOn()
		Autorun(TRUE)
Goto Restart

StartDisabled:
	Toggle("startdisabled")
	Menu Settings, ToggleCheck, &Start disabled
Return

Traveling:
	Toggle("traveling")
Goto Restart

Settings:
	WriteSettings()
	FileGetTime modtime, %ini%
	RunWait %ini%
	FileGetTime newmodtime, %ini%
	If (newmodtime <> modtime) {
		OnExit("Exit", 0)
		Reload
	}
Return

CheckRunning:
	If mode <> enabled
		SetTimer,, Delete
	Else {
		Process Exist, %exe%
		If !ErrorLevel
			Run(TRUE)
	}
Return

CustomTimesMode:
	FormatTime time,, HHmm
	If (daytime <= time And time < nighttime) {
		If customnight Or !mode {
			customnight = 0
			Goto Enable
		}
	} Else If !customnight {
		customnight = 1
		Goto Enable
	}
Return

FullScreenMode:
	If mode <> enabled
		Return
	WinGet fsid, ID, A
	If !fsid
		Return
	If fullscreenignore <> |
		Loop parse, fullscreenignore, |
			If WinExist(A_LoopField " ahk_id" fsid)
				Return
	WinGet fsstyle, Style, ahk_id %fsid%
	WinGetClass fscls, ahk_id %fsid%
	WinGetPos ,,, width, height, ahk_id %fsid%
	; 0x800000 is WS_BORDER
	; 0x20000000 is WS_MINIMIZE
	If ((fsstyle & 0x20800000) Or height < A_ScreenHeight Or width < A_ScreenWidth Or fscls = "TscShellContainerClass") {	; Not full-screen or remote desktop
		If isfullscreen = 1	; Was full-screen
		{
;			Tip("Disable full-screen:" fscls " | " fsstyle, 10000)
			isfullscreen = 2	; Full-screen is done
			Gosub Enable
			isfullscreen = 0	; Full-screen is off
		}
	} Else If (isfullscreen <> 1 And fscls <> "Progman" And fscls <> "WorkerW" And fscls <> "TscShellContainerClass") {	; Full-screen and not (remote) desktop
;		Tip("Enable full-screen:" fscls " | " fsstyle, 10000)
		isfullscreen = 1	; Full-screen is on
		If fullscreen = 6500
			Goto Disable
		Else
			Goto Enable
	}
Return

RemoteDesktopMode:
	IfWinActive ahk_class TscShellContainerClass
	{
		If !rdpclient {
			Suspend On
			Send {Alt Up}{Ctrl Up}{RAlt Up}{RCtrl Up}
			Hotkey RAlt & `,, Off
			Hotkey RAlt & ., Off
;			Sleep, 250
			rdpclient = 1
			Suspend Off
			ClearMem()
		}
	} Else {
		If rdpclient {
			Suspend On
			Send {Alt Up}{Ctrl Up}{RAlt Up}{RCtrl Up}
			If extrahotkeys {
				Hotkey RAlt & `,, On
				Hotkey RAlt & ., On
			}
;			Sleep, 250
			Suspend Off
			ClearMem()
		}
		rdpclient = 0
	}

	If !remote And RemoteSession() {
		Suspend On
		Menu Tray, Disable, &Enabled
		Menu Tray, Disable, &Forced
		Menu Tray, Disable, &Paused
		Menu Tray, Disable, &Disabled
		Menu Tray, Tip, Redshift Tray %ver%`nDisabled (Remote Desktop)
		TrayIcon(0)
		Restore()
		If extrahotkeys
			PrepRunGui()
		PrepWinChange()
		remote = 1
		Suspend Off
		ClearMem()
	} Else If remote And !RemoteSession() {
		Menu Tray, Enable, &Enabled
		Menu Tray, Enable, &Forced
		Menu Tray, Enable, &Paused
		Menu Tray, Enable, &Disabled
		Sleep 2000
		If rdpnumlock
			SetNumLockState On
		If extrahotkeys
			PrepRunGui()
		If !mode Or mode = "enabled"
			Gosub Enable
		If mode = forced
		{
			mode = %prevmode%
			Gosub Force
		}
		PrepWinChange()
		remote = 0
		ClearMem()
	}
Return

NoToolTip:
	ToolTip
Return

Restart:
	Reload

Exit:
	ExitApp

Exit() {
	If restorebrightness And (mode = "disabled" Or mode = "paused")
		brightness = %restorebrightness%
	IniRead br, %ini%, %v%, brightness, 1
	If (brightness <> br)
		IniWrite %brightness%, %ini%, %v%, brightness
	Restore()
}

GetLocation() {
	Try {
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", "https://ipapi.co/latlong", FALSE)
		whr.Send()
		response := whr.ResponseText
		ObjRelease(whr)
	}
	If !response Or InStr(response, "Undefined") {
		If (lat = 0.0 Or lon = 0.0) {
			MsgBox 308, Location Error
				, An error occurred while determining your location!`nChoose Yes to retry, or No to manually specify latitude and longitude.
			IfMsgBox Yes
				GetLocation()
			Else {
				Gosub Settings
				ExitApp
			}
		}
		Return
	}
	StringSplit latlon, response, `,
	lat = %latlon1%
	lon = %latlon2%
	IniWrite %lat%, %ini%, %v%, latitude
	IniWrite %lon%, %ini%, %v%, longitude
}

PrepWinChange() {
	Gui +LastFound
	hwnd := WinExist()
	DllCall("RegisterShellHookWindow", "uint", hwnd)
	MsgNum := DllCall("RegisterWindowMessage", "str", "ShellHook")
	winchange := OnMessage(MsgNum, "WinChange")
}

WinChange(w, l) {
;	Tip("WinChange: w =" w, 10000)
	If fullscreenmode And (w = 53 Or w = 54 Or w = 32772)
		SetTimer FullScreenMode, -150
	If rdpclient Or (remotedesktop And (w = 2 Or w = 53 Or w = 54 Or w = 32772))
		SetTimer RemoteDesktopMode, -150
}

Toggle(setting) {
	%setting% ^= 1
	IniWrite % %setting%, %ini%, %s%, %setting%
}

WriteSettings() {
	IniWrite %lat%, %ini%, %v%, latitude
	IniWrite %lon%, %ini%, %v%, longitude
	IniWrite %day%, %ini%, %v%, daytemp
	IniWrite %night%, %ini%, %v%, nighttemp
	If restorebrightness And (mode = "disabled" Or mode = "paused")
		brightness = %restorebrightness%
	IniWrite %brightness%, %ini%, %v%, brightness
	IniWrite %ctrlwforralt%, %ini%, %v%, ctrlwforralt
	IniWrite %fullscreen%, %ini%, %v%, fullscreentemp
	IniWrite %fullscreenignore%, %ini%, %v%, fullscreenignore
	IniWrite %pauseminutes%, %ini%, %v%, pauseminutes
	IniWrite %daytime%, %ini%, %v%, daytime
	IniWrite %nighttime%, %ini%, %v%, nighttime
	IniWrite %keepaliveseconds%, %ini%, %v%, keepaliveseconds
	IniWrite %colorizecursor%, %ini%, %s%, colorizecursor
	IniWrite %customtimes%, %ini%, %s%, customtimes
	IniWrite %keepbrightness%, %ini%, %s%, keepbrightness
	IniWrite %fullscreenmode%, %ini%, %s%, fullscreenmode
	IniWrite %nofading%, %ini%, %s%, nofading
	IniWrite %hotkeys%, %ini%, %s%, hotkeys
	IniWrite %extrahotkeys%, %ini%, %s%, extrahotkeys
	IniWrite %keepcalibration%, %ini%, %s%, keepcalibration
	IniWrite %remotedesktop%, %ini%, %s%, remotedesktop
	IniWrite %rdpnumlock%, %ini%, %s%, rdpnumlock
	IniWrite %runasadmin%, %ini%, %s%, runasadmin
	IniWrite %startdisabled%, %ini%, %s%, startdisabled
	IniWrite %traveling%, %ini%, %s%, traveling
}

Autorun(force = FALSE) {
	If !A_IsAdmin
	Try {
		Run *RunAs "%A_ScriptFullPath%" /r %force%
	}

	sch := ComObjCreate("Schedule.Service")
	sch.Connect()
	root := sch.GetFolder("\")

	; Backwards compatibility with old task name
	enableAutorun := !AutorunOn()
	RunWait schtasks.exe /query /tn "Redshift Tray",, Hide
	If !ErrorLevel {
		root.DeleteTask("Redshift Tray", 0)
		deleteTask := False
	}

	If enableAutorun Or force {
		task := sch.NewTask(0)
		If runasadmin Or keepcalibration
			task.Principal.RunLevel := 1	; 1 = Highest
		task.Triggers.Create(9)	; 9 = Trigger on logon
		action := task.Actions.Create(0)	; 0 = Executable
		action.ID := taskname
		action.Path := A_ScriptFullPath
		task.Settings.DisallowStartIfOnBatteries := FALSE
		task.Settings.ExecutionTimeLimit := "PT0S"
		task.Settings.StopIfGoingOnBatteries := FALSE
		root.RegisterTaskDefinition(taskname, task, 6, "", "", 3)	; 6 = TaskCreateOrUpdate
		If AutorunOn()
			Menu Settings, Check, &Autorun
	} Else {
		If deleteTask
			root.DeleteTask(taskname, 0)
		Menu Settings, Uncheck, &Autorun
	}

	ObjRelease(sch)
}

AutorunOn() {
	RunWait schtasks.exe /query /tn "%taskname%",, Hide
	If ErrorLevel
		RunWait schtasks.exe /query /tn "Redshift Tray",, Hide
	Return !ErrorLevel
}

ColorizeCursor() {
	RegRead mousetrails, HKCU\Control Panel\Mouse, MouseTrails
	If colorizecursor And mousetrails <> -1
		RegWrite REG_SZ, HKCU\Control Panel\Mouse, MouseTrails, -1
	Else If !colorizecursor And mousetrails = -1
		RegDelete HKCU\Control Panel\Mouse, MouseTrails
	If !ErrorLevel
		Menu Settings, ToggleCheck, &Colorize cursor
}

Close() {
	Loop {
		Process Close, %exe%
		Process Exist, %exe%
	} Until !ErrorLevel
}

Restore() {
	Close()
	If keepcalibration
		RunWait schtasks /run /tn "\Microsoft\Windows\WindowsColorSystem\Calibration Loader",, Hide
	Else
		RunWait %exe% -x,,Hide
}

Run(adjust = FALSE) {
	br := brightness>1 ? "-g " brightness : "-b " brightness
	ntmp := isfullscreen = 1 ? fullscreen : (customtimes And !customnight ? day : night)
	notr := adjust Or isfullscreen Or nofading ? "-r" : ""
	If mode = enabled
	{
		If customtimes
			cfg = -O %ntmp% %br%
		Else
			cfg = -l %lat%:%lon% -t %day%:%ntmp% %br% %notr%
	}
	Else If mode = forced
		cfg = -O %temperature% %br%
	Else If mode = paused
		cfg = -O 6500 %br%
	Else If mode = disabled
		cfg = -O 6500 %br%
	Close()
	If adjust And keepcalibration
		RunWait schtasks /run /tn "\Microsoft\Windows\WindowsColorSystem\Calibration Loader",, Hide
	If !adjust
		Restore()
	If !keepcalibration
		cfg .= " -P"
	Run %exe% %cfg%,, Hide, pid
	TrayTip()
	SetTimer ClearMem, -1000
}

Tip(text, time = 1000) {
	ToolTip %text%
	SetTimer NoToolTip, -%time%
}

TrayIcon(enabled = 1) {
	If A_IsCompiled
		Menu Tray, Icon, %A_ScriptFullPath%, % enabled ? 1 : 2, 1
	Else
		Menu Tray, Icon, % A_ScriptDir "\Icons\redshift" (enabled ? "" : "-6500k") ".ico", 1
}

TrayTip() {
	If mode = enabled
	{
		If customtimes
		{
			If customnight
				status := "Night mode until " SubStr(daytime, 1, 2) ":" SubStr(daytime, 3) " (" night "K)"
			Else
				status := "Day mode until " SubStr(nighttime, 1, 2) ":" SubStr(nighttime, 3) " (" day "K)"
		}
		Else {
			latitude := Round(Abs(lat), 2) "°" (lat > 0 ? "N" : "S")
			longitude := Round(Abs(lon), 2) "°" (lon > 0 ? "E" : "W")
			status = Enabled: %night%K/%day%K`nLocation: %latitude% %longitude%
		}
	}
	Else If mode = forced
		status = Forced: %temperature%K
	Else If mode = paused
		status = Paused until %endtime%
	Else {
		status = Disabled
		if customtimes
			status .= " until " SubStr(nighttime, 1, 2) ":" SubStr(nighttime, 3)
	}
	br := Round(brightness * 100, 0)
	Menu Tray, Tip, Redshift Tray %ver%`n%status%`nBrightness: %br%`%
	If !isfullscreen And (A_ThisHotkey <> A_PriorHotkey Or InStr(A_ThisHotkey, "Pg") Or InStr(A_ThisHotkey, "Home")) And A_TimeSinceThisHotkey < 2500
		Tip(status "`nBrightness: " br `%)
}

Brightness(value) {
	If value = 1
		brightness = 1
	Else {
		newbrightness := brightness + value
		If (newbrightness > .09 And newbrightness < 10.01)
			brightness = %newbrightness%
		Else
			Return
	}
	Run(TRUE)
	If mode = enabled
	{
		Process Wait, %exe%, .5
		If !ErrorLevel {
			brightness -= value
			Run(TRUE)
		}
	}
}

Temperature(value) {
	If mode <> forced
		Gosub Force
	If value = 1
		temperature = night
	Else {
		temp := temperature + value
		If (temp > 999 And temp < 25001)
			temperature = %temp%
		Else
			Return
	}
	Run(TRUE)
	If mode = enabled
	{
		Process Wait, %exe%, .25
		If !ErrorLevel {
			temperature -= value
			Run(TRUE)
		}
	}
}

; Default hotkeys
#If hotkeys And !RemoteSession()
!Home::
	If (brightness <> 1 And mode = "enabled")
		Brightness(1)
	Goto Enable
!Pause::
	If mode = paused
		Goto Enable
	Else
		Goto Pause
!End::Goto Disable
!PgUp::Brightness(.05)
!PgDn::Brightness(-.05)
RAlt & Home::
	If (brightness <> 1 And mode = "forced")
		Brightness(1)
	Goto Force
RAlt & End::Goto EndForce
RAlt & PgUp::Temperature(100)
RAlt & PgDn::Temperature(-100)

; Extra hotkeys
; RAlt & ,/. have to be manually enabled/disabled somehow
RAlt & ,::ShiftAltTab
RAlt & .::AltTab

#If extrahotkeys And MouseOnTaskbar()
~LButton::ShowDesktop()
~^LButton::HideTaskbar()
MButton::TaskMgr()
WheelUp::
	If WinActive("ahk_class TscShellContainerClass") Or WinActive("ahk_exe VirtualBoxVM.exe")
		SetVolume("+2")
	Else
		Send {Volume_Up}
Return
WheelDown::
	If WinActive("ahk_class TscShellContainerClass") Or WinActive("ahk_exe VirtualBoxVM.exe")
		SetVolume("-2")
	Else
		Send {Volume_Down}
Return

#If extrahotkeys And !rdpclient
RAlt & 9::ClickThroughWindow()
RAlt & 0::WinSet, AlwaysOnTop, Toggle, A
RAlt & -::Opacity(-5)
RAlt & =::Opacity(5)
RAlt::
	If !ralt {
		ralt = 1
		If remotedesktop And WinActive("ahk_class TscShellContainerClass")
			WinActivate ahk_class Shell_TrayWnd
	} Else If (A_PriorHotkey = A_ThisHotkey And A_TimeSincePriorHotkey < 400) {
		ralt = 0
		WinGet raid, ID, A
		If ctrlwforralt <> |
			Loop parse, ctrlwforralt, |
				If WinExist(A_LoopField " ahk_id" raid) {
					Send ^w
					Return
				}
		Loop parse, % "Chrome_WidgetWin_1|IEFrame|MozillaWindowClass", |
			If WinActive("ahk_class" A_LoopField) {
				Send ^{F4}
				Return
			}
		Send !{F4}
	}
Return
AppsKey & Up::Send #{Up}
AppsKey & Down::Send #{Down}
AppsKey & Left::Send #{Left}
AppsKey & Right::Send #{Right}
AppsKey & Pause::
	KeyWait AppsKey
	DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
Return
AppsKey & Home::Shutdown, 2
AppsKey & End::
	KeyWait AppsKey
	DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)
Return
AppsKey & ,::Send {Media_Prev}
AppsKey & .::Send {Media_Next}
AppsKey & /::Send {Media_Stop}
AppsKey & Shift::Send {Media_Play_Pause}
AppsKey & m::Send {Volume_Mute}
AppsKey & p::Send #p
AppsKey::Send {AppsKey}
RWin & RAlt::Send {RWin}	; Needed to allow RWin & combi's
>^Up::Send {Volume_Up}
>^Down::Send {Volume_Down}
<^LWin::
RWin::
>^RAlt::
>^AppsKey::
	If !WinExist("ahk_id" rundialog) And !WinActive("ahk_id" rungui)
		Gui RunGui:Show, Center
	Else {
		Gui RunGui:Cancel
		WinRunDialog()
	}
Return

#If extrahotkeys And rdpclient
>^Up::SetVolume("+1")
>^Down::SetVolume("-1")

#If remotedesktop And !RemoteSession()
RCtrl::
	KeyWait RCtrl
	If !rctrl
		rctrl = 1
	Else If (A_PriorHotkey = A_ThisHotkey And A_TimeSincePriorHotkey < 400) {
		rctrl = 0
		IfWinActive ahk_class TscShellContainerClass
		{
			_rdpid := "ahk_id" WinExist("A")
			PostMessage 0x112, 0xF020	; Minimize full-screen
			Sleep 50
			WinMinimize, %_rdpid%	; Minimize window (needed for ExStyle below)
			WinSet ExStyle, +0x80, %_rdpid%	; Force to end of Alt-Tab list by temporarily adding WS_EX_TOOLWINDOW
			Sleep 50
			WinSet ExStyle, -0x80, %_rdpid%
		}
		Else IfWinExist ahk_class TscShellContainerClass
			WinActivate
	}
Return

Run:
	Gui Submit
	If (runcmd <> "")
		PrepRun(runcmd)
RunGuiGuiEscape:
	Gui RunGui:Cancel
	GuiControl,, runcmd
	ClearMem()
Return

RunGuiGuiSize:
	Gui +MaxSizex%A_GuiHeight%
	GuiControl Move, Runcmd, % "w" A_GuiWidth+4
Return

MouseOnTaskbar() {
	MouseGetPos,,, id
	Return WinExist("ahk_class Shell_TrayWnd ahk_id" id) Or WinExist("ahk_class Shell_SecondaryTrayWnd ahk_id" id)
}

SetVolume(value) {
	SoundSet %value%
	SoundGet volume
	Tip("Volume: " Round(volume) `%, 1000)
	SoundGet mute,, mute
	If mute = On
		SoundSet 0,, mute
}

RemoteSession() {
	SysGet isremote, 4096
	Return isremote > 0
}

PrepRunGui() {
	Gui RunGui:new, AlwaysOnTop -Caption +HwndRungui MinSize ToolWindow 0x40000
	Gui Margin, -2, -2
	Gui Add, Edit, Center vRuncmd
	Gui Color,, fafbfc
	Gui Add, Button, w0 h0 Default gRun
	If !shell And !PrepShell()
		PrepShell()
}

WinRunDialog() {
	If (rundialog <> "" And WinExist("ahk_id" rundialog)) {
		IfWinNotActive ahk_id %rundialog%
			WinActivate ahk_id %rundialog%
		Else {
			Send !{Esc}
			WinClose ahk_id %rundialog%
			rundialog =
		}
	} Else {
		Send #r
		WinWait ahk_class #32770 ahk_exe explorer.exe,, 2
		If ErrorLevel
			Return
		WinActivate
		WinGet rundialog, ID, A
	}
}

ClickThroughWindow() {
	WinGetClass cls, A
	If cls = WorkerW
		Return
	WinGet id, ID, A
	_id = ahk_id %id%
	WinGet exstyle, ExStyle, %_id%
	If (exstyle & 0x20) {	; Clickthrough
		If withcaption.HasKey(id) {
			max := withcaption.Delete(id)
			if max = 1
				WinSet Style, -0x1000000, %_id%	; -Maximize
			WinSet Style, +0xC00000, %_id%	; +Caption
		}
		WinSet AlwaysOnTop, Off, %_id%
		WinSet ExStyle, -0x20, %_id%	; -Clickthrough
	} Else {
		WinGet tr, Transparent, %_id%
		If !tr
			WinSet Transparent, 255, %_id%
		WinGet style, Style, %_id%
		If (style & 0xC00000) {	; Has caption
			WinGet maximized, MinMax, %_id%
			If (maximized = 1 Or WinExist(_id " ahk_class ApplicationFrameWindow")) {
				max = 0
			} Else {
				max = 1
				WinSet Style, +0x1000000, %_id%	; +Maximize (lose shadow)
			}
			withcaption[id] := max
			WinSet Style, -0xC00000, %_id%	; -Caption
		}
		WinSet AlwaysOnTop, On, %_id%
		WinSet ExStyle, +0x20, %_id%	; +Clickthrough
	}
}

Opacity(value) {
	WinGet tr, Transparent, A
	If !tr
		tr = 255
	tr += value
	WinGet exstyle, ExStyle, A
	If (tr > 254 And !exstyle & 0x20)
		tr = Off
	Else If tr < 15
		tr = 15
	WinSet Transparent, %tr%, A
	Return
}

ShowDesktop() {
	If (A_PriorHotkey = A_ThisHotkey And A_TimeSincePriorHotkey < 400 And (WinActive("ahk_class Shell_TrayWnd") Or WinActive("ahk_class Shell_SecondaryTrayWnd"))) {
		MouseGetPos,,,, control
		If control = MSTaskListWClass1
			Send #d
		Sleep 250
	}
}

HideTaskbar() {	; https://www.autohotkey.com/boards/viewtopic.php?t=39123
	VarSetCapacity(taskbar, A_PtrSize=4 ? 36:48)
	NumPut(DllCall("Shell32\SHAppBarMessage", "UInt", 4, "Ptr", &taskbar, "Int") ? 2 : 1, taskbar, A_PtrSize=4 ? 32:40)	; 4 = ABM_GETSTATE; 2 = ABS_ALWAYSONTOP, 1 = ABS_AUTOHIDE
	DllCall("Shell32\SHAppBarMessage", "UInt", 10, "Ptr", &taskbar)	; 10 = ABM_SETSTATE
}

TaskMgr() {	; Don't show Task Manager when clicking on buttons
	WinGetClass before, A
	If Instr(before, "TrayWnd",, 0) {
		Send !{Esc}
		WinGetClass before, A
	}
	Click Middle
	WinGetClass after, A
	If Instr(after, "TrayWnd",, 0) And before <> after
		Send ^+{Esc}
}

PrepShell() {	; From Installer.ahk
	windows := ComObjCreate("Shell.Application").Windows
	VarSetCapacity(_hwnd, 4, 0)
	desktop := windows.FindWindowSW(0, "", 8, ComObj(0x4003, &_hwnd), 1)
	Try {
		ptlb := ComObjQuery(desktop
			, "{4C96BE40-915C-11CF-99D3-00AA004AE837}"	; SID_STopLevelBrowser
			, "{000214E2-0000-0000-C000-000000000046}")	; IID_IShellBrowser
		If DllCall(NumGet(NumGet(ptlb+0)+15*A_PtrSize), "ptr", ptlb, "ptr*", psv:=0) = 0 {
			VarSetCapacity(IID_IDispatch, 16)
			NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
			DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", psv
				, "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp:=0)
			shell := ComObj(9,pdisp,1).Application
			ObjRelease(psv)
		}
		ObjRelease(ptlb)
		Return TRUE
	} Catch
		Return FALSE
}

PrepRun(cmd) {
	If InStr(cmd, "%")
		cmd := ExpandEnvVars(cmd)
	If !InStr(cmd, " ") Or Instr(cmd, "reg:") = 1
		Return ShellRun(cmd, "", A_Temp)
	If SubStr(cmd, 1, 1) <> """" {
		cmd := StrSplit(cmd, " ",, 2)
		Return ShellRun(cmd[1], cmd[2], A_Temp)
	}
	cmd := StrSplit(SubStr(cmd, 2), """",, 2)
	ShellRun("""" cmd[1] """", cmd[2], A_Temp)
}

ExpandEnvVars(in) {
	VarSetCapacity(out, 2048)
	DllCall("ExpandEnvironmentStrings", "str", in, "str", out, int, 2047, "cdecl int")
	Return out
}

ShellRun(prms*) {
	If !shell
		PrepShell()
	WinActivate ahk_exe explorer.exe
	Try {
		shell.ShellExecute(prms*)
	} Catch {
		If !PrepShell()
			PrepShell()
		If shell
			Try {
				shell.ShellExecute(prms*)
			} Catch
				shell =
	}
	WinSet Bottom,, ahk_exe explorer.exe
	If !shell
		MsgBox 16, Redshift Tray, Explorer.exe needs to be running
}

ClearMem:
	ClearMem(pid)
	ClearMem()
Return

ClearMem(pid = "this") {	; http://www.autohotkey.com/forum/topic32876.html
	If pid = this
		pid := DllCall("GetCurrentProcessId")
	h := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
	DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
	DllCall("CloseHandle", "Int", h)
}