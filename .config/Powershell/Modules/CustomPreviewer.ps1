# Based on:
#   https://github.com/ahrm/dotfiles/blob/main/lf-windows/lf_scripts/lf_preview.py

function Get-MimeType {
    param(
        [string]$FilePath
    )
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    switch ($extension) {
        '.txt' { return 'text/plain' }
        '.jpg' { return 'image/jpeg' }
        '.jpeg' { return 'image/jpeg' }
        '.png' { return 'image/png' }
        '.gif' { return 'image/gif' }
        '.pdf' { return 'application/pdf' }
        Default { return 'none' }
    }
}

function Show-Text {
    param(
        [string]$FilePath
    )
    $content = Get-Content -Path $FilePath
    Write-Output $content
}

function Write-Divider {
    Write-Output ('-' * 20)
}

function Show-Image {
    param(
        [string]$FilePath,
        [int]$PreviewerWidth,
        [int]$PreviewerHeight
    )
    Add-Type -AssemblyName System.Drawing
    $resolvedPath = (Resolve-Path -Path $FilePath).Path
    $img = [System.Drawing.Image]::FromFile($resolvedPath)
    $width = $img.Width
    $height = $img.Height
    Write-Output "Image Size: ${width}x${height}"
    try {
        chafa $resolvedPath --view-size=$PreviewerWidth"x"$PreviewerHeight --optimize 9
    }
    catch {
        Write-Output "chara must be installed to preview the image."
    }
}

function Format-FileSize {
    param(
        [int64]$size_in_bytes
    )
    if ($size_in_bytes -lt 1KB) {
        return "${size_in_bytes} B"
    }
    elseif ($size_in_bytes -lt 1MB) {
        return "{0:F2} KB" -f ($size_in_bytes / 1KB)
    }
    elseif ($size_in_bytes -lt 1GB) {
        return "{0:F2} MB" -f ($size_in_bytes / 1MB)
    }
    else {
        return "{0:F2} GB" -f ($size_in_bytes / 1GB)
    }
}

function Format-Text
{
    param(
        [string]$text,
        [int]$width = 80
    )
    $words = $text -split "\s+"
    $col = 0
    foreach ( $word in $words )
    {
        $col += $word.Length + 1
        if ( $col -gt $width )
        {
            Write-Host ""
            $col = $word.Length + 1
        }
        Write-Host -NoNewline "$word "
    }
    Write-Host ""
}

$file_path = $args[1]
$previewer_width = $args[2]
$previewer_height = $args[3]
$mimeType = Get-MimeType $file_path

if (-not $mimeType) {
    $mimeType = 'none'
}

try {
    $fileInfo = Get-Item -LiteralPath $file_path
    $size = $fileInfo.Length
    Write-Output $(Format-Text "File Name: $($fileInfo.Name)" $previewer_width)
    Write-Output "File Size: $(Format-FileSize $size)"
    Write-Output "Modify Time: $($fileInfo.LastWriteTime)"

    if ($mimeType -eq 'none') {
        if ($size -lt 100KB) {
            Write-Divider
            Show-Text $file_path
        }
    }
    if ($mimeType -eq 'text/plain') {
        Write-Divider
        Show-Text $file_path
    }
    if ($mimeType -match 'image/') {
        Write-Divider
        Show-Image $file_path $previewer_width $previewer_height
    }
}
catch {
    Write-Output $_.Exception.Message
}
