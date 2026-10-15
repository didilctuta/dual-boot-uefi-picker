Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
trap {
    [System.Windows.Forms.MessageBox]::Show(
        $_.ToString(), 'Windows 启动切换器', 'OK', 'Error'
    ) | Out-Null
    exit 1
}
$bcdedit = Join-Path $env:SystemRoot 'System32\bcdedit.exe'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    $arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -STA -File "{0}"' -f $PSCommandPath
    try {
        Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') `
            -ArgumentList $arguments -WindowStyle Hidden -Verb RunAs | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "需要管理员权限才能修改 UEFI 启动项。`n`n$($_.Exception.Message)",
            'Windows 启动切换器', 'OK', 'Warning'
        ) | Out-Null
    }
    exit
}

function Get-FirmwareEntries {
    $raw = @(& $bcdedit /enum firmware /v 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw (($raw | ForEach-Object { "$($_)" }) -join "`n")
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $blocks = (($raw | ForEach-Object { "$($_)" }) -join "`n") -split '(?:\r?\n){2,}'
    foreach ($block in $blocks) {
        $idMatch = [regex]::Match($block, '(?im)^\s*(?:identifier|标识符)\s+(\{[^}]+\})\s*$')
        if (-not $idMatch.Success) { continue }

        $id = $idMatch.Groups[1].Value
        if ($id -eq '{fwbootmgr}') { continue }

        $description = ''
        $descriptionMatch = [regex]::Match($block, '(?im)^\s*(?:description|描述|说明)\s+(.+?)\s*$')
        if ($descriptionMatch.Success) { $description = $descriptionMatch.Groups[1].Value.Trim() }

        $path = ''
        $pathMatch = [regex]::Match($block, '(?im)^\s*path\s+(.+?)\s*$')
        if ($pathMatch.Success) { $path = $pathMatch.Groups[1].Value.Trim() }

        $text = "$description`n$path"
        $kind = $null
        if ($id -eq '{bootmgr}' -or $text -match '(?i)Windows Boot Manager|Windows 启动管理器|Windows 引导管理器|\\EFI\\Microsoft\\Boot\\bootmgfw\.efi') {
            $kind = 'Windows 11'
        } elseif ($text -match '(?i)Ubuntu|\\EFI\\ubuntu\\') {
            $kind = 'Ubuntu'
        }

        if ($kind) {
            $entries.Add([pscustomobject]@{
                Name = $kind
                Id = $id
                Description = $description
                Path = $path
            })
        }
    }

    return @($entries | Sort-Object @{ Expression = { if ($_.Name -eq 'Windows 11') { 0 } else { 1 } } }, Id -Unique)
}

function Invoke-BcdEdit([string[]] $Arguments) {
    $result = @(& $bcdedit @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw (($result | ForEach-Object { "$($_)" }) -join "`n")
    }
    return (($result | ForEach-Object { "$($_)" }) -join "`n").Trim()
}

$form = [System.Windows.Forms.Form]::new()
$form.Text = 'Windows 启动切换器'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ClientSize = [System.Drawing.Size]::new(510, 255)
$form.Font = [System.Drawing.Font]::new('Microsoft YaHei UI', 10)

$heading = [System.Windows.Forms.Label]::new()
$heading.Text = '选择要设置的启动系统'
$heading.AutoSize = $true
$heading.Location = [System.Drawing.Point]::new(22, 20)
$form.Controls.Add($heading)

$combo = [System.Windows.Forms.ComboBox]::new()
$combo.DropDownStyle = 'DropDownList'
$combo.Location = [System.Drawing.Point]::new(24, 55)
$combo.Size = [System.Drawing.Size]::new(460, 30)
$combo.DisplayMember = 'Name'
$form.Controls.Add($combo)

$status = [System.Windows.Forms.Label]::new()
$status.Location = [System.Drawing.Point]::new(24, 95)
$status.Size = [System.Drawing.Size]::new(460, 42)
$status.Text = '正在读取 UEFI 启动项…'
$form.Controls.Add($status)

$setDefault = [System.Windows.Forms.Button]::new()
$setDefault.Text = '设为默认启动'
$setDefault.Location = [System.Drawing.Point]::new(24, 155)
$setDefault.Size = [System.Drawing.Size]::new(145, 38)
$setDefault.Enabled = $false
$form.Controls.Add($setDefault)

$setNext = [System.Windows.Forms.Button]::new()
$setNext.Text = '下次启动进入所选系统'
$setNext.Location = [System.Drawing.Point]::new(179, 155)
$setNext.Size = [System.Drawing.Size]::new(195, 38)
$setNext.Enabled = $false
$form.Controls.Add($setNext)

$restart = [System.Windows.Forms.Button]::new()
$restart.Text = '现在重启'
$restart.Location = [System.Drawing.Point]::new(384, 155)
$restart.Size = [System.Drawing.Size]::new(100, 38)
$restart.Enabled = $false
$form.Controls.Add($restart)

$footnote = [System.Windows.Forms.Label]::new()
$footnote.Text = '[下次启动]只生效一次；重启后恢复默认顺序。设置不会立即重启。'
$footnote.AutoSize = $true
$footnote.Location = [System.Drawing.Point]::new(24, 215)
$footnote.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$form.Controls.Add($footnote)

try {
    $firmwareEntries = @(Get-FirmwareEntries)
    foreach ($entry in $firmwareEntries) { [void]$combo.Items.Add($entry) }
    $setDefault.Enabled = $combo.Items.Count -gt 0
    $setNext.Enabled = $combo.Items.Count -gt 0

    $defaultIndex = -1
    for ($i = 0; $i -lt $combo.Items.Count; $i++) {
        if ($combo.Items[$i].Name -eq 'Windows 11') { $defaultIndex = $i; break }
    }
    if ($defaultIndex -lt 0 -and $combo.Items.Count -gt 0) { $defaultIndex = 0 }
    if ($defaultIndex -ge 0) { $combo.SelectedIndex = $defaultIndex }

    $foundNames = @($firmwareEntries | Select-Object -ExpandProperty Name -Unique)
    if (($foundNames -contains 'Windows 11') -and ($foundNames -contains 'Ubuntu')) {
        $status.Text = '已读取到 Windows 和 Ubuntu 的 UEFI 启动项。'
    } elseif ($firmwareEntries.Count -eq 0) {
        $status.Text = '没有识别到 Windows/Ubuntu UEFI 项；请检查启动模式和固件启动项。'
    } else {
        $status.Text = '只识别到：' + ($foundNames -join '、') + '。另一系统可能没有 UEFI 启动项。'
    }
} catch {
    $status.Text = '读取 UEFI 启动项失败。'
    [System.Windows.Forms.MessageBox]::Show(
        "无法读取固件启动项：`n`n$($_.Exception.Message)",
        'Windows 启动切换器', 'OK', 'Error'
    ) | Out-Null
}

$setDefault.Add_Click({
    if (-not $combo.SelectedItem) { return }
    $target = $combo.SelectedItem
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "将 $($target.Name) 设为 UEFI 默认启动项？此设置会持续生效，直到再次更改。",
        '确认默认启动项', 'YesNo', 'Question'
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        $result = Invoke-BcdEdit @('/set', '{fwbootmgr}', 'displayorder', $target.Id, '/addfirst')
        $status.Text = "$($target.Name) 已设为默认启动。"
        [System.Windows.Forms.MessageBox]::Show(
            "$($target.Name) 已设为默认启动。`n`n$result",
            '设置完成', 'OK', 'Information'
        ) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "设置默认启动项失败：`n`n$($_.Exception.Message)",
            '设置失败', 'OK', 'Error'
        ) | Out-Null
    }
})

$setNext.Add_Click({
    if (-not $combo.SelectedItem) { return }
    $target = $combo.SelectedItem
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "设置下次开机进入 $($target.Name)？这不会立即重启。",
        '确认下一次启动', 'YesNo', 'Question'
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        $null = Invoke-BcdEdit @('/set', '{fwbootmgr}', 'bootsequence', $target.Id)
        $status.Text = "已设置：下次启动进入 $($target.Name)。"
        $restart.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show(
            "已设置下次启动进入 $($target.Name)。`n`n你可以稍后重启，或点击[现在重启]。",
            '设置完成', 'OK', 'Information'
        ) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "设置下一次启动失败：`n`n$($_.Exception.Message)",
            '设置失败', 'OK', 'Error'
        ) | Out-Null
    }
})

$restart.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        '现在重启服务器？请确保所选系统可远程访问。',
        '确认重启', 'YesNo', 'Warning'
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\shutdown.exe') -ArgumentList '/r /t 0'
})

[void]$form.ShowDialog()
