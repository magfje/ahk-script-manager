#Requires AutoHotkey v2.0

#SingleInstance Force
SetWorkingDir A_ScriptDir

; Configuration
configFile := A_ScriptDir "\config.ini"
scriptsFolder := IniRead(configFile, "Settings", "ScriptsFolder", "")
if (scriptsFolder = "")
    scriptsFolder := A_ScriptDir "\Scripts\"
if !RegExMatch(scriptsFolder, "\\$")  ; Ensure trailing backslash
    scriptsFolder := scriptsFolder . "\\"
includeFile := A_ScriptDir "\IncludeList.ahk"
mainScriptFile := A_ScriptDir "\MainScript.ahk"

; Global variables
global scriptsList := Map()
global enabledScripts := Map()
global externalScripts := Map()  ; New map for external scripts
global mainScriptPID := 0

; Create GUI
mainGui := Gui("+Resize +MinSize600x400", "AHK Script Manager")

; Set window icon if available
iconFile := A_ScriptDir "\main.ico"
if FileExist(iconFile)
    mainGui.TitleBarIcon := iconFile

; Title
mainGui.SetFont("s14 w700")
lblTitle := mainGui.Add("Text", "x20 y15 w560 Center +0x200", "AutoHotkey Script Manager")
mainGui.SetFont()

; Group: Scripts Folder
gbFolder := mainGui.Add("GroupBox", "x10 y45 w580 h70", "Scripts Folder")
mainGui.Add("Text", "x25 y70", "Location:")
scriptsFolderEdit := mainGui.Add("Edit", "x90 y68 w400 ReadOnly", scriptsFolder)
changeFolderBtn := mainGui.Add("Button", "x500 y66 w80", "Change Folder")
changeFolderBtn.OnEvent("Click", ChangeScriptsFolder)
changeFolderBtn.ToolTip := "Select a different scripts folder"

; Group: Script List
gbScripts := mainGui.Add("GroupBox", "x10 y125 w580 h180", "Scripts")
scriptListView := mainGui.Add("ListView", "x20 y145 w560 h150", ["Status", "Name", "File Path"])
scriptListView.OnEvent("DoubleClick", ScriptListClick)

; Action Buttons (row below script list)
reloadBtn := mainGui.Add("Button", "x20 y305 w100", "Reload Scripts")
reloadBtn.OnEvent("Click", ReloadScripts)
reloadBtn.ToolTip := "Scan and reload all scripts in the folder"
toggleBtn := mainGui.Add("Button", "x130 y305 w100", "Toggle Script")
toggleBtn.OnEvent("Click", ToggleScript)
toggleBtn.ToolTip := "Enable or disable the selected script"
editBtn := mainGui.Add("Button", "x240 y305 w100", "Edit Script")
editBtn.OnEvent("Click", EditScript)
editBtn.ToolTip := "Edit the selected script in Notepad"
createScriptBtn := mainGui.Add("Button", "x350 y305 w100", "Create New Script")
createScriptBtn.OnEvent("Click", CreateNewScript)
createScriptBtn.ToolTip := "Create a new script from a template"
includeExternalBtn := mainGui.Add("Button", "x460 y305 w100", "Include External")
includeExternalBtn.OnEvent("Click", IncludeExternalScript)
includeExternalBtn.ToolTip := "Include a script from any location"
removeScriptBtn := mainGui.Add("Button", "x570 y305 w100", "Remove Script")
removeScriptBtn.OnEvent("Click", RemoveScript)
removeScriptBtn.ToolTip := "Remove the selected external script"
openFolderBtn := mainGui.Add("Button", "x680 y305 w100", "Open Folder")
openFolderBtn.OnEvent("Click", OpenScriptsFolder)
openFolderBtn.ToolTip := "Open the scripts folder in Explorer"

; Status bar (already present, but ensure it's visually separated)
statusBar := mainGui.AddStatusBar()

; Make controls resize with window
ResizeControls(*) {
    x := 0, y := 0, w := 0, h := 0
    mainGui.GetClientPos(&x, &y, &w, &h)

    ; Calculate button positions
    buttonWidth := 100
    buttonSpacing := 10
    buttonY := h - 90
    totalButtons := 7
    totalWidth := (buttonWidth * totalButtons) + (buttonSpacing * (totalButtons - 1))
    startX := (w - totalWidth) / 2  ; Center the buttons

    ; Update positions
    lblTitle.Move(, , w - 40)
    gbFolder.Move(, , w - 20)
    scriptsFolderEdit.Move(, , w - 200)
    changeFolderBtn.Move(w - 90)
    gbScripts.Move(, , w - 20, h - 230)
    scriptListView.Move(, , w - 40, h - 260)

    ; Position buttons with equal spacing
    reloadBtn.Move(startX, buttonY)
    toggleBtn.Move(startX + buttonWidth + buttonSpacing, buttonY)
    editBtn.Move(startX + (buttonWidth + buttonSpacing) * 2, buttonY)
    createScriptBtn.Move(startX + (buttonWidth + buttonSpacing) * 3, buttonY)
    includeExternalBtn.Move(startX + (buttonWidth + buttonSpacing) * 4, buttonY)
    removeScriptBtn.Move(startX + (buttonWidth + buttonSpacing) * 5, buttonY)
    openFolderBtn.Move(startX + (buttonWidth + buttonSpacing) * 6, buttonY)

    statusBar.Move(, h - 30, w)
}
mainGui.OnEvent("Size", ResizeControls)

; Initialize
statusBar.SetText("Starting up...")
CheckMainScript()
LoadExternalScriptsFromConfig()  ; Load external scripts before scanning
ScanScripts()
LoadEnabledScriptsFromIncludeFile()
UpdateListView()
mainGui.Show()

; === MAIN FUNCTIONS ===

CheckMainScript() {
    ; Check if MainScript.ahk exists, create it if not
    if (!FileExist(mainScriptFile)) {
        ; try {
        ;     scriptContent := "#Requires AutoHotkey v2.0`n"
        ;     scriptContent .= "`n; AHK Main Script - Host for all scripts`n"
        ;     scriptContent .= "; Author: Claude`n"
        ;     scriptContent .= "; Created: May 18, 2025`n`n"
        ;     scriptContent .= "#SingleInstance Force`n"
        ;     scriptContent .= "SetWorkingDir A_ScriptDir`n`n"

        ;     scriptContent .= "; Setup custom tray menu`n"
        ;     scriptContent .= "A_TrayMenu.Delete()`n"
        ;     scriptContent .= "A_TrayMenu.Add(`"Show Script Manager`", (*) => Run(A_ScriptDir . `"\ScriptManager.ahk`"))`n"
        ;     scriptContent .= "A_TrayMenu.Add()`n"
        ;     scriptContent .= "A_TrayMenu.Add(`"Open Scripts Folder`", (*) => Run(A_ScriptDir . `"\Scripts`"))`n"
        ;     scriptContent .= "A_TrayMenu.Add(`"Reload Scripts`", (*) => Reload())`n"
        ;     scriptContent .= "A_TrayMenu.Add()`n"
        ;     scriptContent .= "A_TrayMenu.Add(`"Exit`", (*) => ExitApp())`n"
        ;     scriptContent .= "A_TrayMenu.Default := `"Show Script Manager`"`n"
        ;     scriptContent .= "A_TrayMenu.ClickCount := 1`n`n"

        ;     scriptContent .= "; Update tooltip with active scripts`n"
        ;     scriptContent .= "UpdateTooltip()`n`n"

        ;     scriptContent .= "; Function to update tooltip`n"
        ;     scriptContent .= "UpdateTooltip() {`n"
        ;     scriptContent .= "    tooltip := `"AHK Script Manager - Active Scripts:`n`n`"`n"
        ;     scriptContent .= "    `n"
        ;     scriptContent .= "    ; Read the include file to find active scripts`n"
        ;     scriptContent .= "    hasScripts := false`n"
        ;     scriptContent .= "    try {`n"
        ;     scriptContent .= "        includeFile := A_ScriptDir . `"\IncludeList.ahk`"`n"
        ;     scriptContent .= "        if FileExist(includeFile) {`n"
        ;     scriptContent .= "            fileContent := FileRead(includeFile)`n"
        ;     scriptContent .= "            `n"
        ;     scriptContent .= "            Loop Parse, fileContent, `"`n`", `"`r`" {`n"
        ;     scriptContent .= "                if (RegExMatch(A_LoopField, `"i)^\\s*#Include\\s+(.+)$`", &match)) {`n"
        ;     scriptContent .= "                    scriptPath := Trim(match[1])`n"
        ;     scriptContent .= "                    SplitPath(scriptPath, &scriptName)`n"
        ;     scriptContent .= "                    tooltip .= scriptName . `"`n`"`n"
        ;     scriptContent .= "                    hasScripts := true`n"
        ;     scriptContent .= "                }`n"
        ;     scriptContent .= "            }`n"
        ;     scriptContent .= "        }`n"
        ;     scriptContent .= "    } catch {`n"
        ;     scriptContent .= "        ; Ignore errors`n"
        ;     scriptContent .= "    }`n"
        ;     scriptContent .= "    `n"
        ;     scriptContent .= "    if (!hasScripts)`n"
        ;     scriptContent .= "        tooltip .= `"No scripts currently running`n`"`n"
        ;     scriptContent .= "        `n"
        ;     scriptContent .= "    tooltip .= `"`n(Right-click for menu)`"`n"
        ;     scriptContent .= "    A_IconTip := tooltip`n"
        ;     scriptContent .= "}`n`n"

        ;     scriptContent .= "; Include all scripts from the IncludeList`n"
        ;     scriptContent .= "#Include IncludeList.ahk`n"

        ;     FileAppend(scriptContent, mainScriptFile)
        ;     statusBar.SetText("Created MainScript.ahk")
        ; } catch as e {
        ;     MsgBox("Error creating main script: " . e.Message, "Error", "Icon!")
        ; }
    }

    ; Make sure the include file exists too
    if (!FileExist(includeFile)) {
        try {
            FileAppend("; Dynamically generated include file`n; Don't edit manually`n", includeFile)
        } catch {
            ; Ignore errors
        }
    }
}

LoadEnabledScriptsFromIncludeFile() {
    enabledScripts.Clear()

    if FileExist(includeFile) {
        try {
            fileContent := FileRead(includeFile)

            loop parse, fileContent, "`n", "`r" {
                if (RegExMatch(A_LoopField, "i)^\s*#Include\s+(.+)$", &match)) {
                    scriptPath := Trim(match[1])

                    SplitPath(scriptPath, &scriptName)

                    if (scriptName != "") {
                        enabledScripts[scriptName] := true
                    }
                }
            }

            statusBar.SetText("Loaded " . enabledScripts.Count . " enabled scripts from include file")
        } catch as e {
            statusBar.SetText("Error reading include file: " . e.Message)
        }
    }
}

OpenScriptsFolder(*) {
    if !FileExist(scriptsFolder) {
        DirCreate(scriptsFolder)
    }
    Run(scriptsFolder)
}

ScanScripts() {
    scriptsList.Clear()
    statusBar.SetText("Scanning for scripts in: " . scriptsFolder)

    if !FileExist(scriptsFolder) {
        try {
            DirCreate(scriptsFolder)
            statusBar.SetText("Created Scripts folder at: " . scriptsFolder)
        }
        catch as e {
            MsgBox("Could not create Scripts folder: " . e.Message, "Error", "Icon!")
            return
        }
    }

    scriptCount := 0
    try {
        loop files, scriptsFolder . "*.ahk" {
            scriptPath := A_LoopFileFullPath
            scriptName := A_LoopFileName
            scriptCount++

            name := scriptName

            try {
                scriptContent := FileRead(scriptPath)

                nameMatch := ""
                if RegExMatch(scriptContent, "i); Name:(.*)", &nameMatch) {
                    extractedName := Trim(nameMatch[1])
                    if (extractedName != "")
                        name := extractedName
                }
            } catch {
                ; If we can't read the file, just use the filename
            }

            scriptsList[scriptName] := { name: name, path: scriptPath }
        }
    } catch as e {
        MsgBox("Error scanning scripts: " . e.Message, "Error", "Icon!")
    }

    if (scriptCount = 0) {
        statusBar.SetText("No scripts found. Create one or add .ahk files to the Scripts folder.")
    } else {
        statusBar.SetText("Found " . scriptCount . " script(s)")
    }
}

UpdateListView() {
    scriptListView.Delete()

    ; Add scripts from main folder
    for scriptName, scriptInfo in scriptsList {
        status := enabledScripts.Has(scriptName) ? "Enabled" : "Disabled"
        scriptListView.Add("", status, scriptInfo.name, scriptInfo.path)
    }

    ; Add external scripts
    for scriptName, scriptInfo in externalScripts {
        status := enabledScripts.Has(scriptName) ? "Enabled (External)" : "Disabled (External)"
        scriptListView.Add("", status, scriptInfo.name, scriptInfo.path)
    }

    loop 3
        scriptListView.ModifyCol(A_Index, "AutoHdr")

    statusBar.SetText("Displaying " . (scriptsList.Count + externalScripts.Count) . " script(s)")
}

UpdateIncludeFile() {
    includeContent := "; Dynamically generated include file`n"
    includeContent .= "; Don't edit manually - managed by Script Manager`n`n"

    ; Include enabled scripts from main folder
    for scriptName, isEnabled in enabledScripts {
        if (isEnabled) {
            if (scriptsList.Has(scriptName)) {
                scriptPath := scriptsList[scriptName].path
                includeContent .= "#Include " . scriptPath . "`n"
            }
            else if (externalScripts.Has(scriptName)) {
                scriptPath := externalScripts[scriptName].path
                includeContent .= "#Include " . scriptPath . "`n"
            }
        }
    }

    try {
        if FileExist(includeFile)
            FileDelete(includeFile)
        FileAppend(includeContent, includeFile)
        statusBar.SetText("Updated include file with " . enabledScripts.Count . " enabled scripts")
    } catch as e {
        MsgBox("Error updating include file: " . e.Message, "Error", "Icon!")
    }
}

RestartMainScript() {
    ; Find and close the existing MainScript process
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='AutoHotkey.exe'") {
            commandLine := process.CommandLine
            if (InStr(commandLine, mainScriptFile)) {
                ProcessClose(process.ProcessId)
                break
            }
        }
    } catch {
        ; Ignore errors
    }

    ; Start MainScript
    try {
        Run(mainScriptFile, , "Hide", &newPID)
        mainScriptPID := newPID
        statusBar.SetText("Restarted Main Script")
    } catch as e {
        MsgBox("Error starting main script: " . e.Message, "Error", "Icon!")
    }
}

ScriptListClick(*) {
    ToggleScript()
}

ToggleScript(*) {
    row := scriptListView.GetNext()
    if (row = 0)
        return

    status := scriptListView.GetText(row, 1)
    path := scriptListView.GetText(row, 3)

    SplitPath(path, &scriptName)

    if (scriptName = "")
        return

    ; Check if it's an external script
    isExternal := externalScripts.Has(scriptName)

    if (status = "Disabled" || status = "Disabled (External)") {
        enabledScripts[scriptName] := true
        scriptListView.Modify(row, "", isExternal ? "Enabled (External)" : "Enabled")
        statusBar.SetText("Enabled script: " . scriptName)
    } else {
        enabledScripts.Delete(scriptName)
        scriptListView.Modify(row, "", isExternal ? "Disabled (External)" : "Disabled")
        statusBar.SetText("Disabled script: " . scriptName)
    }

    UpdateIncludeFile()
    RestartMainScript()
}

EditScript(*) {
    row := scriptListView.GetNext()
    if (row = 0)
        return

    path := scriptListView.GetText(row, 3)

    if (path != "")
        Run("notepad.exe " . path)
}

CreateNewScript(*) {
    result := InputBox("Enter name for the new script (without .ahk extension):", "Create New Script", "w400 h100")
    if (result.Result = "Cancel")
        return

    scriptName := result.Value
    if !scriptName
        return

    if !InStr(scriptName, ".ahk")
        scriptName := scriptName . ".ahk"

    newScriptPath := scriptsFolder . scriptName

    if FileExist(newScriptPath) {
        MsgBox("A script with this name already exists!", "Error", "Icon!")
        return
    }

    template := "; Name: " . RegExReplace(scriptName, "\.ahk$", "") . "`n"
    template .= "; Description: Add your description here`n`n"
    template .= "; Your hotkey definition`n"
    template .= "#z::MsgBox(`"Hotkey was pressed!`")`n"

    try {
        FileAppend(template, newScriptPath)
        Run("notepad.exe " . newScriptPath)
        ReloadScripts()
    }
    catch as e {
        MsgBox("Error creating script: " . e.Message, "Error", "Icon!")
    }
}

ReloadScripts(*) {
    ScanScripts()
    ; Note: We don't clear externalScripts on reload
    LoadEnabledScriptsFromIncludeFile()
    UpdateListView()
    UpdateIncludeFile()
    RestartMainScript()
}

ChangeScriptsFolder(*) {
    global scriptsFolder
    newFolder := DirSelect("*" . scriptsFolder, 1, "Select Scripts Folder")
    if newFolder {
        scriptsFolder := newFolder
        if !RegExMatch(scriptsFolder, "\\$")  ; Ensure trailing backslash
            scriptsFolder := scriptsFolder . "\\"
        IniWrite scriptsFolder, configFile, "Settings", "ScriptsFolder"
        scriptsFolderEdit.Value := scriptsFolder
        ReloadScripts()
    }
}

LoadExternalScriptsFromConfig() {
    externalScripts.Clear()

    try {
        ; Read all sections from config file
        sections := IniRead(configFile)
        loop parse, sections, "`n" {
            if (RegExMatch(A_LoopField, "^ExternalScript_(.+)$", &match)) {
                scriptName := match[1]
                scriptPath := IniRead(configFile, "ExternalScript_" . scriptName, "Path", "")
                if (scriptPath != "" && FileExist(scriptPath)) {
                    externalScripts[scriptName] := { name: scriptName, path: scriptPath }
                }
            }
        }
        statusBar.SetText("Loaded " . externalScripts.Count . " external scripts from config")
    } catch as e {
        statusBar.SetText("Error loading external scripts: " . e.Message)
    }
}

SaveExternalScriptsToConfig() {
    try {
        ; First, remove all existing external script sections
        sections := IniRead(configFile)
        loop parse, sections, "`n" {
            if (RegExMatch(A_LoopField, "^ExternalScript_(.+)$", &match)) {
                IniDelete(configFile, "ExternalScript_" . match[1])
            }
        }

        ; Then save current external scripts
        for scriptName, scriptInfo in externalScripts {
            IniWrite(scriptInfo.path, configFile, "ExternalScript_" . scriptName, "Path")
        }
    } catch as e {
        MsgBox("Error saving external scripts: " . e.Message, "Error", "Icon!")
    }
}

IncludeExternalScript(*) {
    scriptPath := FileSelect(, , "Select AutoHotkey Script", "AutoHotkey Scripts (*.ahk)")
    if !scriptPath
        return

    SplitPath(scriptPath, &scriptName)
    if !scriptName
        return

    ; Check if script is already included
    if (externalScripts.Has(scriptName)) {
        MsgBox("This script is already included!", "Warning", "Icon!")
        return
    }

    ; Check if script exists in the main folder
    if (scriptsList.Has(scriptName)) {
        MsgBox("A script with this name already exists in the main folder!", "Warning", "Icon!")
        return
    }

    ; Add to external scripts
    externalScripts[scriptName] := { name: scriptName, path: scriptPath }

    ; Enable the script by default
    enabledScripts[scriptName] := true

    ; Save to config
    SaveExternalScriptsToConfig()

    UpdateListView()
    UpdateIncludeFile()
    RestartMainScript()
    statusBar.SetText("Added external script: " . scriptName)
}

RemoveScript(*) {
    row := scriptListView.GetNext()
    if (row = 0)
        return

    path := scriptListView.GetText(row, 3)
    SplitPath(path, &scriptName)

    if (scriptName = "")
        return

    ; Only allow removing external scripts
    if (!externalScripts.Has(scriptName)) {
        MsgBox("You can only remove external scripts. To remove scripts from the main folder, delete them manually.",
            "Information", "Icon!")
        return
    }

    ; Confirm removal
    result := MsgBox("Are you sure you want to remove the external script '" . scriptName . "'?", "Confirm Removal",
        "YesNo Icon!")
    if (result = "No")
        return

    ; Remove from external scripts and enabled scripts
    externalScripts.Delete(scriptName)
    enabledScripts.Delete(scriptName)

    ; Update config
    SaveExternalScriptsToConfig()

    UpdateListView()
    UpdateIncludeFile()
    RestartMainScript()
    statusBar.SetText("Removed external script: " . scriptName)
}
