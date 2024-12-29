# Specify the registry key and value to modify
$RegistryKey = "Registry::HKEY_CLASSES_ROOT\batfile\shell\edit\command" 
$ValueName = "(Default)"
$NewValue = '"C:\programs\Notepad++\notepad++.exe"' + " " + '"%1"' 

# Create a backup of the original registry value (optional)
$OriginalValue = Get-ItemProperty -Path $RegistryKey -Name $ValueName
if ($OriginalValue) {
    Set-ItemProperty -Path $RegistryKey -Name $ValueName -Value $OriginalValue -Force | Out-Null
    Write-Host "Original value backed up to '$RegistryKey\$ValueName'."
}

# Set the new registry value
Set-ItemProperty -Path $RegistryKey -Name $ValueName -Value $NewValue -Force

# Confirm successful modification
Write-Host "Registry value '$ValueName' in '$RegistryKey' set to '$NewValue'."