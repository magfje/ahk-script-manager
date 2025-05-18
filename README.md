# AutoHotkey Script Manager

A modern, modular script management system for Windows using [AutoHotkey v2.0](https://www.autohotkey.com/). Easily enable, disable, and edit multiple AHK scripts from a single GUI.

---

## Features

- **Tray menu** for quick access to the Script Manager, scripts folder, reload, and exit.
- **Script Manager GUI** to enable/disable, edit, or create scripts.
- **Dynamic script loading**: Only enabled scripts are loaded via a generated include list.
- **Works with any portable AHK scripts**—bring your own, or use our [AHK Scripts Collection](https://github.com/yourusername/ahk-scripts).

---

## Directory Structure

```
.
├── MainScript.ahk           # Main entry point, tray menu, dynamic includes
├── ScriptManager.ahk        # GUI for managing scripts
├── IncludeList.ahk          # Auto-generated list of enabled scripts
├── main.ico                 # Custom tray icon
└── Scripts/
    └── (your .ahk scripts go here)
```

---

## Getting Started

### Requirements
- **AutoHotkey v2.0** (https://www.autohotkey.com/)
- Windows 10 or later

### Installation & Usage
1. **Install AutoHotkey v2.0** if you haven't already.
2. **Copy this project** to a folder (e.g., `C:\Users\<YourName>\Documents\AutoHotkey`).
3. **Add scripts** to the `Scripts/` folder. You can:
    - Write your own scripts, or
    - Download ready-to-use scripts from the [AHK Scripts Collection](https://github.com/yourusername/ahk-scripts).
4. **Run `MainScript.ahk`** to start the system.
5. **Use the tray icon** to open the Script Manager, scripts folder, reload scripts, or exit.
6. **Manage scripts** via the Script Manager GUI:
    - Enable/disable scripts (updates `IncludeList.ahk`)
    - Edit scripts in Notepad
    - Create new scripts from a template
    - Open the scripts folder
    - Reloads the main script to apply changes

---

## Using with the AHK Scripts Collection

- Visit the [AHK Scripts Collection](https://github.com/yourusername/ahk-scripts) for a library of portable, ready-to-use scripts.
- Copy or symlink any scripts you want into your `Scripts/` folder.
- Enable or edit them using the Script Manager GUI.

---

## Example Workflow
1. Clone this repo and the [ahk-scripts](https://github.com/yourusername/ahk-scripts) repo.
2. Copy scripts from `ahk-scripts` into this repo's `Scripts/` folder.
3. Run `MainScript.ahk` and use the Script Manager to enable/disable scripts as needed.

---

## Customization

- Add your own `.ahk` scripts to the `Scripts/` folder.
- Use the Script Manager to enable/disable or edit them.
- The Script Manager will update `IncludeList.ahk` and reload the main script as needed.
