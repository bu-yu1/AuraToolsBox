Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

$root = $PSScriptRoot
$cfgPath = Join-Path $root "config.json"
$cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$script:root = $root
$script:cfgPath = $cfgPath
$script:cfg = $cfg

$bg = [System.Drawing.Color]::FromArgb(16, 19, 28)
$panelColor = [System.Drawing.Color]::FromArgb(24, 30, 42)
$accent = [System.Drawing.Color]::FromArgb(90, 150, 220)
$textColor = [System.Drawing.Color]::FromArgb(232, 236, 244)
$dimColor = [System.Drawing.Color]::FromArgb(150, 160, 175)

$script:groups = $cfg.groups
$script:items = @{}

$form = New-Object System.Windows.Forms.Form
$form.Text = $cfg.title
$form.Size = New-Object System.Drawing.Size(920, 640)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $bg
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI Light", 9)

$banner = New-Object System.Windows.Forms.Panel
$banner.Location = New-Object System.Drawing.Point(0, 0)
$banner.Size = New-Object System.Drawing.Size(920, 92)
$banner.BackColor = [System.Drawing.Color]::FromArgb(22, 34, 56)
$form.Controls.Add($banner)

$bannerText = New-Object System.Windows.Forms.Label
$bannerText.AutoSize = $false
$bannerText.Location = New-Object System.Drawing.Point(28, 16)
$bannerText.Size = New-Object System.Drawing.Size(700, 32)
$bannerText.Font = New-Object System.Drawing.Font("Microsoft YaHei UI Light", 16)
$bannerText.ForeColor = [System.Drawing.Color]::White
$bannerText.Text = "工具箱"
$banner.Controls.Add($bannerText)

$bannerSub = New-Object System.Windows.Forms.Label
$bannerSub.AutoSize = $false
$bannerSub.Location = New-Object System.Drawing.Point(30, 54)
$bannerSub.Size = New-Object System.Drawing.Size(760, 24)
$bannerSub.ForeColor = [System.Drawing.Color]::FromArgb(198, 218, 255)
$banner.Controls.Add($bannerSub)

$clock = New-Object System.Windows.Forms.Label
$clock.AutoSize = $false
$clock.Location = New-Object System.Drawing.Point(770, 28)
$clock.Size = New-Object System.Drawing.Size(120, 30)
$clock.TextAlign = 'MiddleRight'
$clock.Font = New-Object System.Drawing.Font("Consolas", 12)
$clock.ForeColor = [System.Drawing.Color]::White
$banner.Controls.Add($clock)

$side = New-Object System.Windows.Forms.FlowLayoutPanel
$side.Location = New-Object System.Drawing.Point(0, 92)
$side.Size = New-Object System.Drawing.Size(186, 508)
$side.BackColor = $panelColor
$side.FlowDirection = 'TopDown'
$side.Padding = New-Object System.Windows.Forms.Padding(10, 14, 10, 10)
$form.Controls.Add($side)

$content = New-Object System.Windows.Forms.FlowLayoutPanel
$content.Location = New-Object System.Drawing.Point(186, 92)
$content.Size = New-Object System.Drawing.Size(718, 508)
$content.BackColor = $bg
$content.Padding = New-Object System.Windows.Forms.Padding(14)
$content.AutoScroll = $true
$form.Controls.Add($content)

function Launch-Tool([string]$id) {
    $it = $script:items[$id]
    if (-not $it) { return }
    try {
        if ($it.args) { Start-Process -FilePath $it.path -ArgumentList $it.args }
        else { Start-Process -FilePath $it.path }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("打不开：$($it.path)`n$($_.Exception.Message)", "出错了")
    }
}

function Save-Config {
    $script:cfg.groups = $script:groups
    ($script:cfg | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $script:cfgPath -Encoding UTF8
}

function Add-ToolDialog([int]$gi) {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = "选一个程序或快捷方式"
    $ofd.Filter = "程序|*.exe;*.lnk;*.bat;*.cmd|所有文件|*.*"
    if ($ofd.ShowDialog() -ne 'OK') { return }
    $picked = $ofd.FileName
    if ([IO.Path]::GetExtension($picked) -eq '.lnk') {
        $sh = New-Object -ComObject WScript.Shell
        $sc = $sh.CreateShortcut($picked)
        $name = [IO.Path]::GetFileNameWithoutExtension($picked)
        $target = $sc.TargetPath
        $toolArgs = $sc.Arguments
    } else {
        $name = [IO.Path]::GetFileNameWithoutExtension($picked)
        $target = $picked
        $toolArgs = ""
    }
    $newName = [Microsoft.VisualBasic.Interaction]::InputBox("给它起个名字", "添加工具", $name)
    if ([string]::IsNullOrWhiteSpace($newName)) { return }
    $item = [pscustomobject]@{ name = $newName.Trim(); path = $target }
    if ($toolArgs) { $item | Add-Member -NotePropertyName args -NotePropertyValue $toolArgs }
    $script:groups[$gi].items += $item
    Save-Config
    Show-GroupAt $gi
}

function Remove-Tool([int]$gi, [int]$ii) {
    $name = $script:groups[$gi].items[$ii].name
    $r = [System.Windows.Forms.MessageBox]::Show("把「$name」从工具箱移除？（不会删除文件）", "确认", 'YesNo')
    if ($r -ne 'Yes') { return }
    $list = @()
    for ($k = 0; $k -lt $script:groups[$gi].items.Count; $k++) {
        if ($k -ne $ii) { $list += $script:groups[$gi].items[$k] }
    }
    $script:groups[$gi].items = $list
    Save-Config
    Show-GroupAt $gi
}

function Add-GroupDialog {
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("新板块的名字", "新建板块", "新板块")
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $script:groups += [pscustomobject]@{ name = $name.Trim(); items = @() }
    Save-Config
    # 重建左侧列表
    $side.Controls.Clear()
    Build-Side
    Show-GroupAt ($script:groups.Count - 1)
}

function Show-GroupAt([int]$i) {
    $g = $script:groups[$i]
    if (-not $g) { return }
    $content.SuspendLayout()
    $content.Controls.Clear()
    foreach ($b in $side.Controls) {
        if ($b -is [System.Windows.Forms.Button]) {
            $b.BackColor = $panelColor
            $b.ForeColor = $textColor
        }
    }
    $side.Controls[$i].BackColor = $accent
    $side.Controls[$i].ForeColor = [System.Drawing.Color]::White

    $bannerText.Text = $g.name
    $ready = 0
    foreach ($it in $g.items) {
        if ($it.path -and (Test-Path -LiteralPath $it.path)) { $ready++ }
    }
    $bannerSub.Text = "共 $($g.items.Count) 个，$ready 个可用"

    foreach ($it in $g.items) {
        $id = "t" + [guid]::NewGuid().ToString("N").Substring(0, 8)
        $path = [string]$it.path
        $script:items[$id] = @{ path = $path; args = [string]$it.args }

        $btn = New-Object System.Windows.Forms.Button
        $btn.Width = 150
        $btn.Height = 96
        $btn.FlatStyle = 'Flat'
        $btn.FlatAppearance.BorderSize = 0
        $btn.BackColor = $panelColor
        $btn.ForeColor = $textColor
        $btn.TextAlign = 'BottomCenter'
        $btn.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
        $btn.Cursor = 'Hand'
        $btn.Margin = New-Object System.Windows.Forms.Padding(6)

        if ($path -and (Test-Path -LiteralPath $path)) {
            try {
                $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
                if ($ico) {
                    $btn.Image = New-Object System.Drawing.Bitmap($ico.ToBitmap(), 40, 40)
                    $btn.ImageAlign = 'TopCenter'
                }
            } catch { }
            $btn.Text = "`n`n" + [string]$it.name
            $btn.Add_MouseEnter({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(44, 48, 58) })
            $btn.Add_MouseLeave({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(32, 35, 43) })
            $btn.Add_Click([scriptblock]::Create("Launch-Tool '$id'"))
        } else {
            $btn.Text = "`n`n" + [string]$it.name + "`n(未安装)"
            $btn.ForeColor = $dimColor
            $btn.Enabled = $false
        }

        $idx = $i
        $itemIndex = $content.Controls.Count
        $script:itemIndex = $itemIndex
        $menu = New-Object System.Windows.Forms.ContextMenuStrip
        $delItem = $menu.Items.Add("从工具箱移除")
        $delItem.Tag = @($idx, $itemIndex)
        $delItem.Add_Click({ param($s, $e) Remove-Tool $s.Tag[0] $s.Tag[1] })
        $btn.ContextMenuStrip = $menu

        $content.Controls.Add($btn)
    }

    # 添加按钮
    $add = New-Object System.Windows.Forms.Button
    $add.Width = 150
    $add.Height = 96
    $add.FlatStyle = 'Flat'
    $add.FlatAppearance.BorderSize = 0
    $add.BackColor = [System.Drawing.Color]::FromArgb(38, 42, 52)
    $add.ForeColor = $dimColor
    $add.Text = "＋`n添加工具"
    $add.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11)
    $add.Cursor = 'Hand'
    $add.Margin = New-Object System.Windows.Forms.Padding(6)
    $gi = $i
    $add.Add_Click([scriptblock]::Create("Add-ToolDialog $gi"))
    $add.Add_MouseEnter({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(52, 58, 72) })
    $add.Add_MouseLeave({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(38, 42, 52) })
    $content.Controls.Add($add)

    $content.ResumeLayout()
}

function Build-Side {
    for ($i = 0; $i -lt $script:groups.Count; $i++) {
        $b = New-Object System.Windows.Forms.Button
        $b.Width = 164
        $b.Height = 40
        $b.Text = $script:groups[$i].name
        $b.TextAlign = 'MiddleLeft'
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.BackColor = $panelColor
        $b.ForeColor = $textColor
        $b.Cursor = 'Hand'
        $b.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
        $b.Add_Click([scriptblock]::Create("Show-GroupAt $i"))
        $side.Controls.Add($b)
    }

    $ng = New-Object System.Windows.Forms.Button
    $ng.Width = 164
    $ng.Height = 34
    $ng.Text = "＋ 新建板块"
    $ng.TextAlign = 'MiddleLeft'
    $ng.FlatStyle = 'Flat'
    $ng.FlatAppearance.BorderSize = 0
    $ng.BackColor = $panelColor
    $ng.ForeColor = $dimColor
    $ng.Cursor = 'Hand'
    $ng.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
    $ng.Add_Click({ Add-GroupDialog })
    $side.Controls.Add($ng)
}

Build-Side

$tips = @(
    "记得吃饭，白米饭也不错",
    "工具再多，不如把一个练熟",
    "今天的漏洞，明天就是经验",
    "桌面干净了，脑子也会轻一点",
    "累了就歇会儿，没人催你"
)
$script:tipIndex = 0
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({
    $script:tipIndex = ($script:tipIndex + 1) % 5
    $bannerSub.Text = $tips[$script:tipIndex]
})
$timer.Start()
$clock.Text = (Get-Date).ToString("HH:mm")

if ($script:groups.Count -gt 0) { Show-GroupAt 0 }

[void]$form.ShowDialog()
