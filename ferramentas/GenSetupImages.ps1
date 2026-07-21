Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Imaging

$root = "C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador"
$src  = Join-Path $root "deploy\assets\setup-banner.png"
$out  = Join-Path $root "deploy\assets"

function Make-Side {
    # Recorte central da imagem src para 164x314 (proporcao da barra lateral do Inno)
    $img = [System.Drawing.Image]::FromFile($src)
    $tw = 164; $th = 314
    $ratio = [Math]::Max($tw / $img.Width, $th / $img.Height)
    $dw = [int]($img.Width * $ratio); $dh = [int]($img.Height * $ratio)
    $tmp = New-Object System.Drawing.Bitmap($dw, $dh)
    $g = [System.Drawing.Graphics]::FromImage($tmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $dw, $dh)
    $g.Dispose(); $img.Dispose()

    $bmp = New-Object System.Drawing.Bitmap($tw, $th)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($tmp, (($tw - $dw)/2), (($th - $dh)/2))
    $g.Dispose(); $tmp.Dispose()

    # Vinheta sutil para combinar com o tema escuro
    $bmp.Save((Join-Path $out "wizard-side.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wizard-side.png gerado"
}

function Make-Top {
    # Banner superior 490x58: fundo gradiente preto/cinza + marca + disco branco com logo
    $tw = 490; $th = 58
    $bmp = New-Object System.Drawing.Bitmap($tw, $th)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle(0,0,$tw,$th)),
        [System.Drawing.Color]::FromArgb(12,12,14),
        [System.Drawing.Color]::FromArgb(28,28,33), 90)
    $g.FillRectangle($brush, 0, 0, $tw, $th)
    $g.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60,60,66))), 0, $th-1, $tw, $th-1)

    # Disco branco com a imagem do app (logo) a esquerda
    $disc = 40
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddEllipse(14, ($th-$disc)/2, $disc, $disc)
    $g.FillPath([System.Drawing.Brushes]::White, $gp)
    try {
        $logo = [System.Drawing.Image]::FromFile((Join-Path $root "deploy\icon.ico"))
        $g.SetClip($gp)
        $g.DrawImage($logo, 14+4, ($th-$disc)/2+4, $disc-8, $disc-8)
        $g.ResetClip(); $logo.Dispose()
    } catch {}

    # Texto da marca
    $fnt = New-Object System.Drawing.Font("Segoe UI Semibold", 16, [System.Drawing.FontStyle]::Bold)
    $brush2 = [System.Drawing.Brushes]::White
    $g.DrawString("TL OPTIMIZER", $fnt, $brush2, 64, 10)
    $fnt2 = New-Object System.Drawing.Font("Segoe UI", 9)
    $brush3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150,150,156))
    $g.DrawString("Otimização · Plus", $fnt2, $brush3, 65, 34)

    $bmp.Save((Join-Path $out "wizard-top.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wizard-top.png gerado"
}

Make-Side
Make-Top
