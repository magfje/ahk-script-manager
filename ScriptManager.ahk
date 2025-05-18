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
reloadBtn := mainGui.Add("Button", "x20 y305 w110", "Reload Scripts")
reloadBtn.OnEvent("Click", ReloadScripts)
reloadBtn.ToolTip := "Scan and reload all scripts in the folder"
toggleBtn := mainGui.Add("Button", "x140 y305 w110", "Toggle Script")
toggleBtn.OnEvent("Click", ToggleScript)
toggleBtn.ToolTip := "Enable or disable the selected script"
editBtn := mainGui.Add("Button", "x260 y305 w110", "Edit Script")
editBtn.OnEvent("Click", EditScript)
editBtn.ToolTip := "Edit the selected script in Notepad"
createScriptBtn := mainGui.Add("Button", "x380 y305 w140", "Create New Script")
createScriptBtn.OnEvent("Click", CreateNewScript)
createScriptBtn.ToolTip := "Create a new script from a template"
openFolderBtn := mainGui.Add("Button", "x530 y305 w60", "Open Folder")
openFolderBtn.OnEvent("Click", OpenScriptsFolder)
openFolderBtn.ToolTip := "Open the scripts folder in Explorer"

; Status bar (already present, but ensure it's visually separated)
statusBar := mainGui.AddStatusBar()

; Make controls resize with window
ResizeControls(*) {
    x := 0, y := 0, w := 0, h := 0
    mainGui.GetClientPos(&x, &y, &w, &h)
    lblTitle.Move(, , w - 40)
    gbFolder.Move(, , w - 20)
    scriptsFolderEdit.Move(, , w - 200)
    changeFolderBtn.Move(w - 90)
    gbScripts.Move(, , w - 20, h - 230)
    scriptListView.Move(, , w - 40, h - 260)
    reloadBtn.Move(20, h - 90)
    toggleBtn.Move(140, h - 90)
    editBtn.Move(260, h - 90)
    createScriptBtn.Move(380, h - 90)
    openFolderBtn.Move(w - 70, h - 90)
    statusBar.Move(, h - 30, w)
}
mainGui.OnEvent("Size", ResizeControls)

; Initialize
statusBar.SetText("Starting up...")
CheckMainScript()
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

    for scriptName, scriptInfo in scriptsList {
        status := enabledScripts.Has(scriptName) ? "Enabled" : "Disabled"
        scriptListView.Add("", status, scriptInfo.name, scriptInfo.path)
    }

    loop 3
        scriptListView.ModifyCol(A_Index, "AutoHdr")

    statusBar.SetText("Displaying " . scriptsList.Count . " script(s)")
}

UpdateIncludeFile() {
    includeContent := "; Dynamically generated include file`n"
    includeContent .= "; Don't edit manually - managed by Script Manager`n`n"

    for scriptName, isEnabled in enabledScripts {
        if (isEnabled && scriptsList.Has(scriptName)) {
            scriptPath := scriptsList[scriptName].path
            includeContent .= "#Include " . scriptPath . "`n"
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

    if (status = "Disabled") {
        enabledScripts[scriptName] := true
        scriptListView.Modify(row, "", "Enabled")
        statusBar.SetText("Enabled script: " . scriptName)
    } else {
        enabledScripts.Delete(scriptName)
        scriptListView.Modify(row, "", "Disabled")
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
