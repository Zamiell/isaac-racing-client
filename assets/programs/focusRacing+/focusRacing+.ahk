; Wait for Isaac to boot
WinWaitActive, ahk_exe isaac-ng.exe


; Now that Isaac has booted, flip the focus back to the Racing+ client
; (by default AutoHotkey will do exact title matching)
WinActivate, Racing+
