Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
$script:root = $root
$cfg = Get-Content (Join-Path $root "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$script:groups = $cfg.groups
$script:index = 0
$script:items = @{}
$script:posFile = Join-Path $root "widget_pos.txt"

$cLine = [System.Drawing.Color]::FromArgb(70, 130, 190, 255)
$cText = [System.Drawing.Color]::FromArgb(233, 240, 250)
$cSub = [System.Drawing.Color]::FromArgb(150, 172, 200)

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'
$form.Size = New-Object System.Drawing.Size(300, 250)
$form.Opacity = 0.86
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.KeyPreview = $true
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI Light", 9)

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Left = $screen.Right - $form.Width - 30
$form.Top = $screen.Bottom - $form.Height - 40
if (Test-Path $script:posFile) {
    try { $p = (Get-Content $script:posFile -Raw).Trim() -split ','; $form.Left = [int]$p[0]; $form.Top = [int]$p[1] } catch { }
}

function Set-Rounded {
    $r = 16
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $r, $r, 180, 90)
    $path.AddArc($form.Width - $r - 1, 0, $r, $r, 270, 90)
    $path.AddArc($form.Width - $r - 1, $form.Height - $r - 1, $r, $r, 0, 90)
    $path.AddArc(0, $form.Height - $r - 1, $r, $r, 90, 90)
    $path.CloseFigure()
    $form.Region = New-Object System.Drawing.Region($path)
}
$form.Add_Resize({ Set-Rounded })
$form.Add_HandleCreated({ Set-Rounded })
$head = New-Object System.Windows.Forms.Panel
$head.Dock = 'Top'
$head.Height = 46
$head.BackColor = [System.Drawing.Color]::FromArgb(34, 44, 64)
$form.Controls.Add($head)

$title = New-Object System.Windows.Forms.Label
$title.Dock = 'Fill'
$title.TextAlign = 'MiddleLeft'
$title.Padding = New-Object System.Windows.Forms.Padding(18, 0, 0, 0)
$title.Font = New-Object System.Drawing.Font("Microsoft YaHei UI Light", 11)
$title.ForeColor = $cText
$head.Controls.Add($title)

$body = New-Object System.Windows.Forms.FlowLayoutPanel
$body.Dock = 'Fill'
$body.FlowDirection = 'TopDown'
$body.WrapContents = $false
$body.AutoScroll = $true
$body.Padding = New-Object System.Windows.Forms.Padding(8)
$body.BackColor = [System.Drawing.Color]::FromArgb(16, 20, 30)
$form.Controls.Add($body)
$body.BringToFront()

function Launch([string]$id) {
    $it = $script:items[$id]
    if (-not $it) { return }
    try {
        if ($it.args) { Start-Process -FilePath $it.path -ArgumentList $it.args }
        else { Start-Process -FilePath $it.path }
    } catch { }
}

function Render {
    if ($script:groups.Count -eq 0) { return }
    $g = $script:groups[$script:index]
    $title.Text = "  " + $g.name + "    " + ($script:index + 1) + " / " + $script:groups.Count
    $body.SuspendLayout()
    $body.Controls.Clear()
    $script:items = @{}
    $n = 0
    foreach ($it in $g.items) {
        $path = [string]$it.path
        $ok = $path -and (Test-Path -LiteralPath $path)
        $row = New-Object System.Windows.Forms.Button
        $row.Width = 264
        $row.Height = 32
        $row.FlatStyle = 'Flat'
        $row.FlatAppearance.BorderSize = 0
        $row.BackColor = [System.Drawing.Color]::FromArgb(26, 32, 46)
        $row.ForeColor = if ($ok) { $cText } else { $cSub }
        $row.TextAlign = 'MiddleLeft'
        $row.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
        $row.TextImageRelation = 'ImageBeforeText'
        $row.Text = "   " + [string]$it.name
        $row.Margin = New-Object System.Windows.Forms.Padding(2, 3, 2, 3)
        $row.Cursor = 'Hand'
        if ($ok) {
            try {
                $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
                if ($ico) {
                    $row.Image = New-Object System.Drawing.Bitmap($ico.ToBitmap(), 18, 18)
                    $row.ImageAlign = 'MiddleLeft'
                }
            } catch { }
            $id = "w" + [guid]::NewGuid().ToString("N").Substring(0, 8)
            $script:items[$id] = @{ path = $path; args = [string]$it.args }
            $row.Add_Click([scriptblock]::Create("Launch '$id'"))
            $row.Add_MouseEnter({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(44, 58, 82) })
            $row.Add_MouseLeave({ param($s, $e) $s.BackColor = [System.Drawing.Color]::FromArgb(26, 32, 46) })
        } else {
            $row.Enabled = $false
        }
        $body.Controls.Add($row)
        $n++
        if ($n -ge 5) { break }
    }
    $body.ResumeLayout()
}

$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 60000
$script:timer.Add_Tick({
    $script:index = ($script:index + 1) % $script:groups.Count
    Render
})
$script:timer.Start()

$script:dragging = $false
$script:offset = New-Object System.Drawing.Point 0, 0
$startDrag = {
    param($s, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:dragging = $true
        $p = [System.Windows.Forms.Cursor]::Position
        $script:offset = New-Object System.Drawing.Point (($p.X - $form.Left), ($p.Y - $form.Top))
    }
}
$form.Add_MouseDown($startDrag)
$head.Add_MouseDown($startDrag)
$title.Add_MouseDown($startDrag)

$dragTimer = New-Object System.Windows.Forms.Timer
$dragTimer.Interval = 15
$dragTimer.Add_Tick({
    if ($script:dragging) {
        $p = [System.Windows.Forms.Cursor]::Position
        $form.Left = $p.X - $script:offset.X
        $form.Top = $p.Y - $script:offset.Y
        if ([System.Windows.Forms.Control]::MouseButtons -ne [System.Windows.Forms.MouseButtons]::Left) {
            $script:dragging = $false
            try { ("{0},{1}" -f $form.Left, $form.Top) | Set-Content -LiteralPath $script:posFile -Encoding ASCII } catch { }
        }
    }
})
$dragTimer.Start()

$wheel = {
    param($s, $e)
    if ($e.Delta -gt 0) { $script:index = ($script:index - 1 + $script:groups.Count) % $script:groups.Count }
    else { $script:index = ($script:index + 1) % $script:groups.Count }
    Render
}
$form.Add_MouseWheel($wheel)
$body.Add_MouseWheel($wheel)

$form.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq 'Down' -or $e.KeyCode -eq 'Right' -or $e.KeyCode -eq 'PageDown') {
        $script:index = ($script:index + 1) % $script:groups.Count
        $script:timer.Stop(); $script:timer.Start(); Render
    } elseif ($e.KeyCode -eq 'Up' -or $e.KeyCode -eq 'Left' -or $e.KeyCode -eq 'PageUp') {
        $script:index = ($script:index - 1 + $script:groups.Count) % $script:groups.Count
        $script:timer.Stop(); $script:timer.Start(); Render
    } elseif ($e.KeyCode -eq 'Escape') {
        $form.Close()
    }
})

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$mi1 = $menu.Items.Add("打开完整工具箱")
$mi1.Add_Click({ Start-Process 'wscript.exe' -ArgumentList ('"' + (Join-Path $script:root '启动工具箱.vbs') + '"') })
$mi2 = $menu.Items.Add("跳到下一个")
$mi2.Add_Click({ $script:index = ($script:index + 1) % $script:groups.Count; Render })
$mi3 = $menu.Items.Add("关闭浮窗")
$mi3.Add_Click({ $form.Close() })
$form.ContextMenuStrip = $menu

$form.Add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = 'AntiAlias'
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 130, 190, 255), 1)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 16
    $path.AddArc(0, 0, $r, $r, 180, 90)
    $path.AddArc($s.Width - $r - 1, 0, $r, $r, 270, 90)
    $path.AddArc($s.Width - $r - 1, $s.Height - $r - 1, $r, $r, 0, 90)
    $path.AddArc(0, $s.Height - $r - 1, $r, $r, 90, 90)
    $path.CloseFigure()
    $e.Graphics.DrawPath($pen, $path)
    $pen.Dispose()
})

Render
[void]$form.ShowDialog()
