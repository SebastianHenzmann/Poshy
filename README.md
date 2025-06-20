# Poshy a PowerShell GUI Designer

This project is a **PowerShell-based GUI Designer** using Windows Forms. It allows you to visually create, drag, select, and export GUI components into reusable PowerShell scripts.

![image](https://github.com/user-attachments/assets/680584fb-c308-4f6d-a70d-0a21dc9625fc)


## Features

- 🖱️ **Draggable Controls**: Add and move controls like Labels, TextBoxes, Buttons, etc.
- 🛠️ **Property Editing**: Select controls and edit their properties in a PropertyGrid.
- 💾 **Export Layout**: Save the current GUI as a PowerShell script.
- 📂 **Load Layout**: Reopen previously saved GUI scripts and continue editing.
- 🔒 **Clamped Movement**: Controls stay within the canvas bounds.
- ❌ **Control Deletion**: Easily remove unwanted controls from your canvas.
- 🌙 **Dark Mode Support**: Light and Dark themes for a more comfortable design experience.

### 🚧 Coming Soon
- 🔀 **Multi-Select & Group Movement**: Select and move multiple controls at once for faster layout adjustments.

## Supported Controls

- Label
- TextBox
- Button
- CheckBox
- RadioButton
- ComboBox
- ListBox
- PictureBox
- ProgressBar

- More will be added if required

## Getting Started

1. **Run the Designer**

   - Open PowerShell.
   - Execute the main script to launch the GUI Designer:
     ```powershell
     .\Poshy.ps1
     ```

2. **Design Your UI**

   - Use the toolbox to add controls.
   - Click and drag controls to position them.
   - Click a control to edit its properties in the property grid.

3. **Export Your Design**

   - Go to `File -> Save` to export the layout.
   - A `.ps1` script will be generated with your GUI components.

4. **Load a Design**

   - Go to `File -> Open` to load a previously exported GUI layout script.

## How It Works

### Draggable Controls

Each control added becomes draggable within the canvas. Mouse events (`MouseDown`, `MouseMove`, `MouseUp`) are used to update position while preserving the control within the parent boundaries.

### Property Grid Integration

Clicking on any control assigns it to the `PropertyGrid`, where you can modify properties in real-time.

### Export Logic

The `Export-GUILayout` function loops through all controls in the canvas, and for each supported type, it generates corresponding PowerShell code to recreate them with their current properties (location, size, text, etc.).

### Import Logic

The `LoadGUILayout` function parses a saved script using a basic state machine to identify control declarations and re-instantiates them onto the canvas.

## Requirements

- Windows 10 (should work on Windows 11 but not tested)
- PowerShell 5.x+
- .NET Framework (required for `System.Windows.Forms`)

## Notes

- Saving will **overwrite the selected file**. Use with caution.
- Ensure your saved scripts are compatible and were generated by the designer.
