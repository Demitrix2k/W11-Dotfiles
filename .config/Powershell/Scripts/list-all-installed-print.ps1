# Get traditional desktop apps (64-bit)
$desktopApps64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# Get traditional desktop apps (32-bit)
$desktopApps32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# Get Microsoft Store apps
$storeApps = Get-AppxPackage | Select-Object Name, PackageFullName, Publisher | ForEach-Object {
    [PSCustomObject]@{
        DisplayName    = $_.Name
        Publisher      = $_.Publisher
        DisplayVersion = "N/A"
        InstallDate    = "N/A"
    }
}

# Combine all lists, remove duplicates, and sort
$allApps = ($desktopApps64 + $desktopApps32 + $storeApps) | Where-Object {$_.DisplayName -ne $null} | Sort-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize | Out-String -Width 4096

# Output to a text file on the desktop
$allApps | Out-File C:\Users\$env:USERNAME\Desktop\All_Installed_Programs.txt -Encoding UTF8