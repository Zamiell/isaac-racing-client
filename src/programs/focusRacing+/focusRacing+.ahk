#NoTrayIcon

; Wait for Isaac to boot for at least seconds
WinWaitActive, ahk_exe isaac-ng.exe, , 30

; Now that Isaac has booted, flip the focus back to the Racing+ client
; (by default AutoHotkey will do exact title matching)
if not ErrorLevel {
	WinActivate, Racing+
}

; Otherwise, Isaac is already booted and we don't need to bother flipping the focus back
