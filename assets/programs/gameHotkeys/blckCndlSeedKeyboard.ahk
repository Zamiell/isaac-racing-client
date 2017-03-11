#NoTrayIcon
SetKeyDelay, 0

; Configuration
Delay1 = 50
Delay2 = 5

; Don't do anything if Isaac is not open
IfWinNotExist, ahk_exe isaac-ng.exe
{
	return
}

; Activate Isaac
IfWinNotActive, ahk_exe isaac-ng.exe
{
	WinActivate, ahk_exe isaac-ng.exe
	WinWaitActive, ahk_exe isaac-ng.exe
}

; Put "BLCK CNDL in the clipboard"
old_clipboard = %clipboard%
clipboard = BLCK CNDL

; Enter the BLCK CNDL easter egg
Send {Tab down}
Sleep %Delay1%
Send {Tab up}
Sleep %Delay2%
Send {Ctrl down}
Sleep %Delay2%
Send {v down}
Sleep %Delay1%
Send {v up}
Sleep %Delay2%
Send {Ctrl up}
Sleep %Delay2%
Send {Enter down}
Sleep %Delay1%
Send {Enter up}
Sleep %Delay2%

; Restore the clipboard
clipboard = %old_clipboard%

; Paste in the seed
Sleep %Delay1%
Send {Tab down}
Sleep %Delay1%
Send {Tab up}
Sleep %Delay2%
Send {Ctrl down}
Sleep %Delay2%
Send {v down}
Sleep %Delay1%
Send {v up}
Sleep %Delay2%
Send {Ctrl up}
Sleep %Delay2%
Send {Enter down}
Sleep %Delay1%
Send {Enter up}
Sleep %Delay2%

; Enter the game
Sleep %Delay1%
Send {Enter down}
Sleep %Delay1%
Send {Enter up}
Sleep %Delay2%
