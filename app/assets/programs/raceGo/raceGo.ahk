IfWinNotActive, ahk_exe isaac-ng.exe
{
	WinActivate, ahk_exe isaac-ng.exe
	WinWaitActive, ahk_exe isaac-ng.exe
}
Send {Enter down}
Sleep 50
Send {Enter up}
