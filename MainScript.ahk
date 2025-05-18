#Requires AutoHotkey v2.0

#SingleInstance Force
SetWorkingDir A_ScriptDir

iconFile := A_ScriptDir . "\main.ico"
if FileExist(iconFile)
    TraySetIcon(iconFile)
else  ; Fallback to a system icon if the custom one doesn't exist
    TraySetIcon("shell32.dll", 168)  ; Windows script icon

; Setup custom tray menu
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Script Manager", (*) => Run(A_ScriptDir . "\ScriptManager.ahk"))
A_TrayMenu.Add()
A_TrayMenu.Add("Open Scripts Folder", (*) => Run(A_ScriptDir . "\Scripts"))
A_TrayMenu.Add("Reload Scripts", (*) => Reload())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show Script Manager"
A_TrayMenu.ClickCount := 1

; Update tooltip with active scripts
UpdateTooltip()

; Function to update tooltip
UpdateTooltip() {
    tooltip := "AHK Script Manager - Active Scripts:`n`n"

    ; Read the include file to find active scripts
    hasScripts := false
    try {
        includeFile := A_ScriptDir . "\IncludeList.ahk"
        if FileExist(includeFile) {
            fileContent := FileRead(includeFile)

            loop parse, fileContent, "`n", "`r" {
                if (RegExMatch(A_LoopField, "i)^\s*#Include\s+(.+)$", &match)) {
                    scriptPath := Trim(match[1])
                    SplitPath(scriptPath, &scriptName)
                    tooltip .= scriptName . "`n"
                    hasScripts := true
                }
            }
        }
    } catch {
        ; Ignore errors
    }

    if (!hasScripts)
        tooltip .= "No scripts currently running`n"

    tooltip .= "`n(Right-click for menu)"
    A_IconTip := tooltip
}

; Include all scripts from the IncludeList
#Include IncludeList.ahk