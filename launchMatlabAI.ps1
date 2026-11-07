param([switch]$Install, [string]$MatlabPath, [switch]$ListOnly)
$ErrorActionPreference = 'Stop'
try {
    $matlabExecutable = $MatlabPath
    $installations = @()
    $available = Get-Command matlab.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($available) { $installations += $available.Source }
        $registryRoots = @('HKLM:\SOFTWARE\MathWorks\MATLAB', 'HKCU:\SOFTWARE\MathWorks\MATLAB', 'HKLM:\SOFTWARE\WOW6432Node\MathWorks\MATLAB')
        foreach ($registryRoot in $registryRoots) {
            $releases = Get-ChildItem -LiteralPath $registryRoot -ErrorAction SilentlyContinue | Sort-Object PSChildName -Descending
            foreach ($release in $releases) {
                $properties = Get-ItemProperty -LiteralPath $release.PSPath -ErrorAction SilentlyContinue
                foreach ($propertyName in @('MATLABROOT', 'InstallPath', 'InstallDir')) {
                    $installationRoot = $properties.$propertyName
                    if ($installationRoot) {
                        $candidate = Join-Path $installationRoot 'bin\matlab.exe'
                        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                            $installations += $candidate
                        }
                    }
                }
            }
        }
    foreach ($programRoot in @($env:ProgramFiles,${env:ProgramFiles(x86)})) {
        if (-not $programRoot) { continue }
        foreach ($directory in Get-ChildItem -LiteralPath (Join-Path $programRoot 'MATLAB') -Directory -ErrorAction SilentlyContinue) {
            $candidate = Join-Path $directory.FullName 'bin\matlab.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $installations += $candidate }
        }
    }
    $installations = @($installations | Sort-Object -Unique)
    if ($ListOnly) { $installations; exit 0 }
    if (-not $matlabExecutable) {
        Add-Type -AssemblyName System.Windows.Forms
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'MATLAB AI - Select installed MATLAB'
        $form.Width = 780; $form.Height = 310; $form.StartPosition = 'CenterScreen'
        $label = New-Object System.Windows.Forms.Label
        $label.Text = 'Select your MATLAB installation. One AI package works across releases.'
        $label.SetBounds(15,15,735,35)
        $list = New-Object System.Windows.Forms.ListBox
        $list.SetBounds(15,55,735,145)
        foreach ($item in $installations) { [void]$list.Items.Add($item) }
        $browse = New-Object System.Windows.Forms.Button
        $browse.Text = 'Browse matlab.exe'; $browse.SetBounds(15,215,160,30)
        $browse.Add_Click({
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Select installed MATLAB bin\matlab.exe'
        $picker.Filter = 'MATLAB executable (matlab.exe)|matlab.exe'
        if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $position = $list.Items.IndexOf($picker.FileName)
            if ($position -lt 0) { $position = $list.Items.Add($picker.FileName) }
            $list.SelectedIndex = $position
        }
        $picker.Dispose()
        })
        $ok = New-Object System.Windows.Forms.Button
        $ok.Text='Start'; $ok.SetBounds(550,215,95,30)
        $ok.Add_Click({ if ($list.SelectedItem) { $form.DialogResult=[System.Windows.Forms.DialogResult]::OK; $form.Close() } })
        $cancel=New-Object System.Windows.Forms.Button
        $cancel.Text='Cancel'; $cancel.SetBounds(655,215,95,30)
        $cancel.DialogResult=[System.Windows.Forms.DialogResult]::Cancel
        $form.Controls.AddRange(@($label,$list,$browse,$ok,$cancel))
        $form.CancelButton=$cancel
        if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { $form.Dispose(); exit 0 }
        $matlabExecutable=[string]$list.SelectedItem
        $form.Dispose()
    }
    if ((Split-Path -Leaf $matlabExecutable) -ine 'matlab.exe' -or -not (Test-Path -LiteralPath $matlabExecutable -PathType Leaf)) { throw 'Please select an existing matlab.exe.' }
    $scriptName = 'startMatlabAI.m'
    if ($Install) { $scriptName = 'setupMatlabAI.m' }
    $scriptPath = (Join-Path $PSScriptRoot $scriptName).Replace('\', '/').Replace("'", "''")
    $matlabCommand = "run('$scriptPath');"
    Start-Process -FilePath $matlabExecutable -ArgumentList @('-desktop', '-r', ('"' + $matlabCommand + '"')) -WorkingDirectory $PSScriptRoot
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'Fallback: open MATLAB, select this folder as Current Folder, then run setupMatlabAI.'
    Read-Host 'Press Enter to close'
    exit 1
}
