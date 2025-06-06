# AutoHotkey Script Manager

A modular script management system for Windows using [AutoHotkey v2.0](https://www.autohotkey.com/). Easily enable, disable, and edit multiple AHK scripts from a single GUI.

---

![{8004FD3C-0E60-437D-B1F2-E634A14ECF57}](https://github.com/user-attachments/assets/fd63c7a4-e65e-4c89-a184-c82b8e3bc2f8)


## Features

- **Single Tray menu** avoid having multiple traiicons and get quick access to the Script Manager, scripts folder, reload, and exit.
- **Script Manager GUI** to enable/disable, edit, or create scripts.
- **Dynamic script loading**: Only enabled scripts are loaded via a generated include list, specify a folder or single scripts.
- **Works with any portable AHK scripts**—bring your own, or use my [AHK Scripts Collection](https://github.com/magfje/ahk-scripts).

---

## Directory Structure

```
.
├── MainScript.ahk           # Main entry point, tray menu, dynamic includes
├── ScriptManager.ahk        # GUI for managing scripts
├── IncludeList.ahk          # Auto-generated list of enabled scripts
├── main.ico                 # Custom tray icon
└── Scripts/
    └── (*optional* your .ahk scripts go here)
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
    - Download ready-to-use scripts from the [AHK Scripts Collection](https://github.com/magfje/ahk-scripts).
4. **Run `MainScript.ahk`** to start the system.
5. **Use the tray icon** to open the Script Manager, scripts folder, reload scripts, or exit.
6. **Manage scripts** via the Script Manager GUI:
    - Enable/disable scripts
    - Edit scripts in Notepad
    - Create new scripts from a template
    - Open the scripts folder
    - Reloads the main script to apply changes
    - Add "external" scripts

---

## Using with the AHK Scripts Collection

- Visit the [AHK Scripts Collection](https://github.com/magfje/ahk-scripts) for a library of portable, ready-to-use scripts.
- Enable or edit them using the Script Manager GUI.

---

## Example Workflow
1. Clone this repo and the [ahk-scripts](https://github.com/magfje/ahk-scripts) repo.
2. Copy scripts from `ahk-scripts` into this repo's `Scripts/` folder.
3. Run `MainScript.ahk` and use the Script Manager to enable/disable scripts as needed.

---

## Customization

- Specify a folder to load all scripts in the folder or add your own `.ahk` scripts.
- Use the Script Manager to enable/disable or edit them.


