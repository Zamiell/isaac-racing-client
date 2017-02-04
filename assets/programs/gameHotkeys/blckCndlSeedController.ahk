SetKeyDelay, 0

; Configuration
Delay1 = 50
Delay2 = 5

; Activate Isaac
IfWinNotActive, ahk_exe isaac-ng.exe
{
	WinActivate, ahk_exe isaac-ng.exe
	WinWaitActive, ahk_exe isaac-ng.exe
}

; Enter the BLCK CNDL easter egg
Send {Tab down}
Sleep %Delay1%
Send {Tab up}
Sleep %Delay2%
Send {b down}
Sleep %Delay1%
Send {b up}
Sleep %Delay2%
Send {l down}
Sleep %Delay1%
Send {l up}
Sleep %Delay2%
Send {c down}
Sleep %Delay1%
Send {c up}
Sleep %Delay2%
Send {k down}
Sleep %Delay1%
Send {k up}
Sleep %Delay2%
Send {c down}
Sleep %Delay1%
Send {c up}
Sleep %Delay2%
Send {n down}
Sleep %Delay1%
Send {n up}
Sleep %Delay2%
Send {d down}
Sleep %Delay1%
Send {d up}
Sleep %Delay2%
Send {l down}
Sleep %Delay1%
Send {l up}
Sleep %Delay2%
Send {Enter down}
Sleep %Delay1%
Send {Enter up}
Sleep, %Delay2%

; Paste in the seed
Send {Tab down}
Sleep %Delay1%
Send {Tab up}
Sleep %Delay2%
Send {Ctrl down}{v down}
Sleep %Delay1%
Send {v up}{Ctrl up}
Sleep %Delay2%
Send {Enter down}
Sleep %Delay1%
Send {Enter up}
Sleep, %Delay2%
