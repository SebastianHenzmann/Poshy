Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global drag state store: control -> state
$dragStates = @{}

function New-DraggableControl {
    param($ctrl)

    $dragStates[$ctrl] = @{ Dragging = $false; StartPoint = $null; OrigLocation = $null }

    $ctrl.Add_MouseDown({
            param($send, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                $dragStates[$send].Dragging = $true
                $dragStates[$send].StartPoint = [System.Windows.Forms.Cursor]::Position
                $dragStates[$send].OrigLocation = $send.Location
            }
        })

    $ctrl.Add_MouseMove({
            param($send, $e)
            if ($dragStates[$send].Dragging) {
                $currentPoint = [System.Windows.Forms.Cursor]::Position
                $dx = $currentPoint.X - $dragStates[$send].StartPoint.X
                $dy = $currentPoint.Y - $dragStates[$send].StartPoint.Y
                $newX = $dragStates[$send].OrigLocation.X + $dx
                $newY = $dragStates[$send].OrigLocation.Y + $dy

                # Clamp within canvas boundaries
                $parent = $send.Parent
                if ($null -ne $parent) {
                    $maxX = $parent.ClientSize.Width - $send.Width
                    $maxY = $parent.ClientSize.Height - $send.Height

                    $newX = [Math]::Max(0, [Math]::Min($newX, $maxX))
                    $newY = [Math]::Max(0, [Math]::Min($newY, $maxY))
                }

                $send.Location = New-Object System.Drawing.Point($newX, $newY)
            }
        })

    $ctrl.Add_MouseUp({
            param($send, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                $dragStates[$send].Dragging = $false
            }
        })
}
function Register-SelectableControl {
    param(
        [System.Windows.Forms.Control]$ctrl,
        [System.Windows.Forms.PropertyGrid]$propertyGrid
    )

    New-DraggableControl $ctrl

    $ctrl.Add_Click({
            param($send, $e)
            if ($null -ne $propertyGrid) {
                $propertyGrid.SelectedObject = $send
            }
        })

    # Right-click handler to show context menu and select the control
    $ctrl.Add_MouseUp({
        param($send, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            # Select the control
            if ($null -ne $propertyGrid) {
                $propertyGrid.SelectedObject = $send
            }
            # Show context menu at cursor position
            $contextMenu.Show($send, $e.Location)
        }
    })
}
function Export-GUILayout {
    param(
        [System.Windows.Forms.Panel]$canvas
    )

    $sb = [System.Text.StringBuilder]::new()

    $sb.AppendLine('Add-Type -AssemblyName System.Windows.Forms') | Out-Null
    $sb.AppendLine('Add-Type -AssemblyName System.Drawing') | Out-Null
    $sb.AppendLine('')
    $sb.AppendLine('$form = New-Object System.Windows.Forms.Form') | Out-Null
    $sb.AppendLine('$form.Text = "Exported Form"') | Out-Null
    $sb.AppendLine('$form.Size = New-Object System.Drawing.Size(800,600)') | Out-Null
    $sb.AppendLine('') | Out-Null

    $i = 0
    foreach ($ctrl in $canvas.Controls) {
        $typeName = $ctrl.GetType().Name
        if ($typeName -notin @("Label", "TextBox", "Button", "CheckBox", "RadioButton", "ComboBox", "ListBox", "PictureBox", "ProgressBar")) { continue }


        $ctrlName = "$($typeName.ToLower())$i"
        $varLine = "`$${ctrlName}"

        switch ($typeName) {
            'Label' {
                $text = $ctrl.Text -replace '"', '\"'
                $loc = $ctrl.Location
                $backColor = $ctrl.BackColor.Name

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.Label") | Out-Null
                $sb.AppendLine("$varLine.Text = `"$text`"") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                if ($null -ne $autoSize) { $sb.AppendLine("$varLine.AutoSize = $($autoSize.ToString().ToLower())") | Out-Null }
                if ($backColor -ne 'Transparent') {
                    $sb.AppendLine("$varLine.BackColor = [System.Drawing.Color]::FromName(`"$backColor`")") | Out-Null
                }
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'TextBox' {
                $text = $ctrl.Text -replace '"', '\"'
                $loc = $ctrl.Location
                $width = $ctrl.Width

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.TextBox") | Out-Null
                $sb.AppendLine("$varLine.Text = `"$text`"") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine("$varLine.Width = $width") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'Button' {
                $text = $ctrl.Text -replace '"', '\"'
                $loc = $ctrl.Location

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.Button") | Out-Null
                $sb.AppendLine("$varLine.Text = `"$text`"") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'CheckBox' {
                $text = $ctrl.Text -replace '"', '\"'
                $loc = $ctrl.Location

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.CheckBox") | Out-Null
                $sb.AppendLine("$varLine.Text = `"$text`"") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'RadioButton' {
                $text = $ctrl.Text -replace '"', '\"'
                $loc = $ctrl.Location

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.RadioButton") | Out-Null
                $sb.AppendLine("$varLine.Text = `"$text`"") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'ComboBox' {
                $loc = $ctrl.Location
                $width = $ctrl.Width

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.ComboBox") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine("$varLine.Width = $width") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'ListBox' {
                $loc = $ctrl.Location
                $size = $ctrl.Size

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.ListBox") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine("$varLine.Size = New-Object System.Drawing.Size($($size.Width), $($size.Height))") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'PictureBox' {
                $loc = $ctrl.Location
                $size = $ctrl.Size
                $backColor = $ctrl.BackColor.Name

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.PictureBox") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine("$varLine.Size = New-Object System.Drawing.Size($($size.Width), $($size.Height))") | Out-Null
                $sb.AppendLine("$varLine.BackColor = [System.Drawing.Color]::FromName(`"$backColor`")") | Out-Null
                $sb.AppendLine("$varLine.BorderStyle = 'FixedSingle'") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
            'ProgressBar' {
                $loc = $ctrl.Location
                $size = $ctrl.Size
                $value = $ctrl.Value

                $sb.AppendLine("$varLine = New-Object System.Windows.Forms.ProgressBar") | Out-Null
                $sb.AppendLine("$varLine.Location = New-Object System.Drawing.Point($($loc.X), $($loc.Y))") | Out-Null
                $sb.AppendLine("$varLine.Size = New-Object System.Drawing.Size($($size.Width), $($size.Height))") | Out-Null
                $sb.AppendLine("$varLine.Value = $value") | Out-Null
                $sb.AppendLine('$form.Controls.Add(' + $varLine + ')') | Out-Null
                $sb.AppendLine('') | Out-Null
            }
        }
        $i++
    }

    $sb.AppendLine('$form.ShowDialog()') | Out-Null

    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "PowerShell Script|*.ps1"
    $saveFileDialog.Title = "Export GUI Layout"
    $saveFileDialog.FileName = "ExportedForm.ps1"

    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $sb.ToString() | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Export complete:`n$($saveFileDialog.FileName)", "Export")
    }
}
function LoadGUILayout {
    param(
        [string]$filePath,
        [System.Windows.Forms.Panel]$canvas,
        [System.Windows.Forms.PropertyGrid]$propertyGrid
    )

    # Clear existing controls from canvas
    $canvas.Controls.Clear()

    # Read all lines from the file
    $lines = Get-Content $filePath

    # We will parse control creation blocks
    # Each control block starts with: $xxx = New-Object System.Windows.Forms.<Type>
    # Followed by property assignments
    # End with adding control to form: $form.Controls.Add($xxx)

    # Simple state machine
    $currentCtrl = $null
    $ctrlVars = @{}

    foreach ($line in $lines) {
        if ($line -match '^\$(\w+) = New-Object System\.Windows\.Forms\.(\w+)$') {
            $varName = $matches[1]
            $ctrlType = $matches[2]

            # Create the actual control object skip unknown types
            switch ($ctrlType) {
                'Label' { $ctrlVars[$varName] = New-Object System.Windows.Forms.Label }
                'TextBox' { $ctrlVars[$varName] = New-Object System.Windows.Forms.TextBox }
                'Button' { $ctrlVars[$varName] = New-Object System.Windows.Forms.Button }
                'CheckBox' { $ctrlVars[$varName] = New-Object System.Windows.Forms.CheckBox }
                'RadioButton' { $ctrlVars[$varName] = New-Object System.Windows.Forms.RadioButton }
                'ComboBox' { $ctrlVars[$varName] = New-Object System.Windows.Forms.ComboBox }
                'ListBox' { $ctrlVars[$varName] = New-Object System.Windows.Forms.ListBox }
                'PictureBox' { $ctrlVars[$varName] = New-Object System.Windows.Forms.PictureBox }
                'ProgressBar' { $ctrlVars[$varName] = New-Object System.Windows.Forms.ProgressBar }
                default { continue }
            }
            
            $currentCtrl = $varName
        }
        elseif ($currentCtrl -and $line -match '^\$\w+\.(\w+) = (.+)$') {
            $prop = $matches[1]
            $val = $matches[2].Trim()

            # Try to interpret $val
            # Remove trailing comment if any
            $val = $val -replace '#.*$', ''

            # Handle some common types (string, Point, int, bool, Color)
            # String: "text" with quotes
            if ($val -match '^"(.+)"$') {
                $propVal = $matches[1]
            }
            elseif ($val -match '^"#([0-9a-fA-F]{6})"$') {
                $hex = $matches[1]
                $propVal = [System.Drawing.ColorTranslator]::FromHtml("#$hex")
            }
            elseif ($val -match "^\$[\w]+$") {
                $varName = $val.Substring(1)
                if (Get-Variable -Name $varName -Scope 1 -ErrorAction SilentlyContinue) {
                    $propVal = Get-Variable -Name $varName -Scope 1 -ValueOnly
                    if ($propVal -is [string] -and $propVal -match '^#([0-9a-fA-F]{6})$') {
                        $propVal = [System.Drawing.ColorTranslator]::FromHtml($propVal)
                    }
                }
            }
            elseif ($val -match '\[System\.Drawing\.Color\]::FromName\("(\w+)"\)') {
                $colorName = $matches[1]
                $propVal = [System.Drawing.Color]::FromName($colorName)
            }
            # BorderStyle as string in single quotes
            elseif ($prop -eq 'BorderStyle' -and $val -match "^'(\w+)'$") {
                $styleName = $matches[1]
                $propVal = [System.Windows.Forms.BorderStyle]::$styleName
            }
            # BorderStyle as enum (full namespace)
            elseif ($val -match '\[System\.Windows\.Forms\.BorderStyle\]::(\w+)$') {
                $styleName = $matches[1]
                $propVal = [System.Windows.Forms.BorderStyle]::$styleName
            }
            # Handle FlatStyle as string
            elseif ($prop -eq 'FlatStyle' -and $val -match "^'(\w+)'$") {
                $styleName = $matches[1]
                $propVal = [System.Windows.Forms.FlatStyle]::$styleName
            }
            <# Handle FlatStyle as enum
            elseif ($val -match '\[System\.Windows\.Forms\.FlatStyle\]::(\w+)$') {
                $styleName = $matches[1]
                $propVal = [System.Windows.Forms.FlatStyle]::$styleName
            }#>
            elseif ($val -match 'New-Object System\.Drawing\.Point\((\d+),\s*(\d+)\)') {
                $x = [int]$matches[1]
                $y = [int]$matches[2]
                $propVal = New-Object System.Drawing.Point($x, $y)
            }
            elseif ($val -match 'New-Object System\.Drawing\.Size\((\d+),\s*(\d+)\)') {
                $x = [int]$matches[1]
                $y = [int]$matches[2]
                $propVal = New-Object System.Drawing.Size($x, $y)
            }
            elseif ($val -match '^\d+$') {
                $propVal = [int]$val
            }
            elseif ($val -match '^(True|False)$') {
                $propVal = [bool]::Parse($val)
            }
            elseif ($val -match '\[System\.Drawing\.Color\]::FromName\("(\w+)"\)') {
                $colorName = $matches[1]
                $propVal = [System.Drawing.Color]::FromName($colorName)
            }
            else {
                $propVal = $val # fallback: raw string
            }

            # Set the property on the control object if it exists
            $ctrlObj = $ctrlVars[$currentCtrl]
            if ($ctrlObj -and $ctrlObj.PSObject.Properties.Match($prop)) {
                $ctrlObj.$prop = $propVal
            }
        }
        elseif ($line -match '^\$form\.Controls\.Add\(\$(\w+)\)') {
            $varName = $matches[1]

            if ($ctrlVars.ContainsKey($varName)) {
                $ctrl = $ctrlVars[$varName]
                # Register draggable and selectable
                Register-SelectableControl -ctrl $ctrl -propertyGrid $propertyGrid
                $canvas.Controls.Add($ctrl)
            }

            # Reset current control block
            $currentCtrl = $null
        }
    }
}
# === GUI Designer UI ===

$form = New-Object System.Windows.Forms.Form
$form.Text = "Poshy a PowerShell GUI Designer"
$form.Size = New-Object System.Drawing.Size(1095, 655)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"

# === Menu Bar ===
$menuStrip = New-Object System.Windows.Forms.MenuStrip

# File Menu
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

# Open
$openItem = New-Object System.Windows.Forms.ToolStripMenuItem
$openItem.Text = "Open"
$openItem.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "PowerShell Script (*.ps1)|*.ps1"
        $openFileDialog.Title = "Open Layout Script"

        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                LoadGUILayout -filePath $openFileDialog.FileName -canvas $canvas -propertyGrid $propertyGrid
                [System.Windows.Forms.MessageBox]::Show("Layout loaded successfully.", "Open File")
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to load layout.`n$($_.Exception.Message)", "Error", "OK", "Error")
                write-host $_.Exception.Message
            }
        }
    })
# Save (Export)
$saveItem = New-Object System.Windows.Forms.ToolStripMenuItem
$saveItem.Text = "Save (Will overwrite file!!!)"
$saveItem.Add_Click({
        Export-GUILayout -canvas $canvas
    })
# Exit
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Exit"
$exitItem.Add_Click({
        $form.Close()
    })
# Assemble File Menu
$fileMenu.DropDownItems.AddRange(@($openItem, $saveItem, $exitItem))

# Add to MenuStrip
$menuStrip.Items.Add($fileMenu)

# Add MenuStrip to Form
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

$toolbox = New-Object System.Windows.Forms.ListBox
$toolbox.Items.AddRange(@("Label", "TextBox", "Button", "CheckBox", "RadioButton", "ComboBox", "ListBox", "PictureBox", "ProgressBar"))
$toolbox.Location = New-Object System.Drawing.Point(10, 30)
$toolbox.Size = New-Object System.Drawing.Size(250, 300)
$form.Controls.Add($toolbox)

$propertyGrid = New-Object System.Windows.Forms.PropertyGrid
$propertyGrid.Location = New-Object System.Drawing.Point(10, 330)
$propertyGrid.Size = New-Object System.Drawing.Size(250, 280)
$form.Controls.Add($propertyGrid)

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$deleteMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$deleteMenuItem.Text = "Delete"
$contextMenu.Items.Add($deleteMenuItem)

$deleteMenuItem.Add_Click({
    $selectedCtrl = $propertyGrid.SelectedObject
    if ($selectedCtrl -and $canvas.Controls.Contains($selectedCtrl)) {
        $canvas.Controls.Remove($selectedCtrl)
        $propertyGrid.SelectedObject = $null
        $dragStates.Remove($selectedCtrl)
    }
})

$form.KeyPreview = $true
$form.Add_KeyDown({
    param($send, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Delete) {
        $selectedCtrl = $propertyGrid.SelectedObject
        if ($selectedCtrl -and $canvas.Controls.Contains($selectedCtrl)) {
            $canvas.Controls.Remove($selectedCtrl)
            $propertyGrid.SelectedObject = $null
            $dragStates.Remove($selectedCtrl)
        }
    }
})

$canvas = New-Object System.Windows.Forms.Panel
$canvas.Location = New-Object System.Drawing.Point(270, 30)
$canvas.Size = New-Object System.Drawing.Size(800, 580)
$canvas.BorderStyle = 'FixedSingle'
$canvas.BackColor = 'White'
$canvas.Tag = @{ SelectedType = $null }
$form.Controls.Add($canvas)

$toolbox.Add_MouseDown({
        if ($toolbox.SelectedItem) {
            $toolbox.DoDragDrop($toolbox.SelectedItem, [System.Windows.Forms.DragDropEffects]::Copy)
        }
    })

$canvas.AllowDrop = $true
$canvas.Add_DragEnter({
        if ($_.Data.GetDataPresent("Text")) {
            $_.Effect = "Copy"
        }
    })

$canvas.Add_DragDrop({
        $type = $_.Data.GetData("Text")
        $point = $canvas.PointToClient([System.Windows.Forms.Cursor]::Position)

        switch ($type) {
            "Label" {
                $ctrl = New-Object System.Windows.Forms.Label
                $ctrl.Text = "Label"
                $ctrl.Location = $point
                $ctrl.AutoSize = $true
                $ctrl.BackColor = "Transparent"
            }
            "TextBox" {
                $ctrl = New-Object System.Windows.Forms.TextBox
                $ctrl.Location = $point
                $ctrl.Width = 120
            }
            "Button" {
                $ctrl = New-Object System.Windows.Forms.Button
                $ctrl.Text = "Button"
                $ctrl.Location = $point
            }
            "CheckBox" {
                $ctrl = New-Object System.Windows.Forms.CheckBox
                $ctrl.Text = "CheckBox"
                $ctrl.Location = $point
            }
            "RadioButton" {
                $ctrl = New-Object System.Windows.Forms.RadioButton
                $ctrl.Text = "RadioButton"
                $ctrl.Location = $point
            }
            "ComboBox" {
                $ctrl = New-Object System.Windows.Forms.ComboBox
                $ctrl.Location = $point
                $ctrl.Width = 120
                $ctrl.Items.AddRange(@("Item1", "Item2", "Item3"))
            }
            "ListBox" {
                $ctrl = New-Object System.Windows.Forms.ListBox
                $ctrl.Location = $point
                $ctrl.Size = New-Object System.Drawing.Size(120, 60)
                $ctrl.Items.AddRange(@("Item1", "Item2", "Item3"))
            }
            "PictureBox" {
                $ctrl = New-Object System.Windows.Forms.PictureBox
                $ctrl.Location = $point
                $ctrl.Size = New-Object System.Drawing.Size(100, 100)
                $ctrl.BackColor = [System.Drawing.Color]::LightGray
                $ctrl.BorderStyle = 'FixedSingle'
            }
            "ProgressBar" {
                $ctrl = New-Object System.Windows.Forms.ProgressBar
                $ctrl.Location = $point
                $ctrl.Size = New-Object System.Drawing.Size(120, 20)
                $ctrl.Value = 50
            }
        }
        if ($ctrl) {
            Register-SelectableControl -ctrl $ctrl -propertyGrid $propertyGrid
            $canvas.Controls.Add($ctrl) 
        }
    })

$toolbox.Add_SelectedIndexChanged({
        $canvas.Tag.SelectedType = $toolbox.SelectedItem
    })

$form.ShowDialog()