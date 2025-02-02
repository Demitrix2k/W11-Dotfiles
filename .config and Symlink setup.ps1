#####################################
# Introduction #
#####################################
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host "# This script will move the .config folder to #" -ForegroundColor Cyan
Write-Host "#   your home directory and create symbolic   #" -ForegroundColor Cyan
Write-Host "#         links for various sub-folders.      #" -ForegroundColor Cyan
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host ""
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host "#   The sub-folders include Firefox, ntop,    #" -ForegroundColor Cyan
Write-Host "#  Powershell, Vencord, and Windows Terminal. #" -ForegroundColor Cyan
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host ""
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host "#   You will be prompted to create symbolic   #" -ForegroundColor Cyan
Write-Host "#          links for each sub-folder.         #" -ForegroundColor Cyan
Write-Host "###############################################" -ForegroundColor Cyan
Write-Host ""

#####################################################
# Display the user's home directory and prompt for confirmation #
#####################################################
$homeDirectory = [System.Environment]::GetFolderPath("UserProfile")
Write-Host "###############################################" -ForegroundColor Yellow
Write-Host "#   Your home directory is: $homeDirectory    #" -ForegroundColor Yellow
Write-Host "###############################################" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "### Do you want to continue? (Y/N) ###"
if ($confirmation -ne 'Y') {
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host "#             Operation cancelled.            #" -ForegroundColor Red
    Write-Host "###############################################" -ForegroundColor Red
    exit
}

#####################################
# Define the source and target paths #
#####################################
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourcePath = Join-Path $scriptDirectory ".config"
$targetPath = "$HOME\.config"

#####################################################
# Check if the .config folder already exists in the home directory #
#####################################################
if (Test-Path -Path $targetPath) {
    Write-Host "###############################################" -ForegroundColor Yellow
    Write-Host "#  .config folder already exists in the home  #" -ForegroundColor Yellow
    Write-Host "#                  directory.                 #" -ForegroundColor Yellow
    Write-Host "###############################################" -ForegroundColor Yellow
    $skipMove = $true
} else {
    $skipMove = $false
}

#####################################################
# Check if the .config folder exists in the script directory #
#####################################################
if (-Not (Test-Path -Path $sourcePath) -and -Not $skipMove) {
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host "#    .config folder not found in the script   #" -ForegroundColor Red
    Write-Host "#                  directory.                 #" -ForegroundColor Red
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host ""
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host "#  Please ensure the .config folder is in the #" -ForegroundColor Red
    Write-Host "#       same directory as this script.        #" -ForegroundColor Red
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host ""
    Write-Host "###############################################" -ForegroundColor Red
    Write-Host "#           Press any key to exit...          #" -ForegroundColor Red
    Write-Host "###############################################" -ForegroundColor Red
    [System.Console]::ReadKey() | Out-Null
    exit
}

#####################################################
# Move the .config folder to the user's home directory if not already there #
#####################################################
if (-Not $skipMove) {
    $moveFolder = Read-Host "### Do you want to move the .config folder to your home directory now? (Y/N) ###"
    if ($moveFolder -eq 'Y') {
        Move-Item -Path $sourcePath -Destination $homeDirectory -Force
        Write-Host "###############################################" -ForegroundColor Green
        Write-Host "#   .config folder moved successfully.        #" -ForegroundColor Green
        Write-Host "###############################################" -ForegroundColor Green
    } else {
        Write-Host "###############################################" -ForegroundColor Yellow
        Write-Host "#      Skipping .config folder move...        #" -ForegroundColor Yellow
        Write-Host "###############################################" -ForegroundColor Yellow
    }
}

#####################################################
# Scan the sub-folders in the .config directory #
#####################################################
$scannedSubFolders = Get-ChildItem -Directory -Path $targetPath | Select-Object -ExpandProperty Name

#####################################################
# Define the sub-folders to create symbolic links for #
#####################################################
$subFolders = @("Firefox", "ntop", "Powershell", "Vencord", "Windows Terminal")

#####################################################
# Check if the sub-folders exist in the scanned sub-folders #
#####################################################
$existingSubFolders = @()
foreach ($folder in $subFolders) {
    if ($scannedSubFolders -contains $folder) {
        $existingSubFolders += $folder
    } else {
        Write-Host "###############################################" -ForegroundColor Red
        Write-Host "#  Warning: Sub-folder $folder not found in   #" -ForegroundColor Red
        Write-Host "#             .config directory.              #" -ForegroundColor Red
        Write-Host "###############################################" -ForegroundColor Red
    }
}

#####################################################
# Ask the user if they want to create symbolic links #
#####################################################
$createLinks = Read-Host "### Do you want to create symbolic links for the sub-folders? (Y/N) ###"
if ($createLinks -ne 'Y') {
    Write-Host "###############################################" -ForegroundColor Yellow
    Write-Host "#      Skipping symbolic link creation.       #" -ForegroundColor Yellow
    Write-Host "###############################################" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "###############################################" -ForegroundColor Green
    Write-Host "#      Installation script is finished.       #" -ForegroundColor Green
    Write-Host "#         Press any key to continue...        #" -ForegroundColor Green
    Write-Host "###############################################" -ForegroundColor Green
    [System.Console]::ReadKey() | Out-Null
    exit
}

#####################################################
# Ask the user if they want to create symbolic links for all sub-folders or select specific ones #
#####################################################
$linkAll = Read-Host "### Do you want to create symbolic links for all sub-folders? (Y/N) ###"
$selectedFolders = @()

if ($linkAll -eq 'Y') {
    $selectedFolders = $existingSubFolders
} else {
    foreach ($folder in $existingSubFolders) {
        $response = Read-Host "### Do you want to create a symbolic link for ${folder}? (Y/N) ###"
        if ($response -eq 'Y') {
            $selectedFolders += $folder
        }
    }
}

#####################################################
# Function to prompt user for creating symbolic links #
#####################################################
function Prompt-SymbolicLink {
    param (
        [string]$folderName
    )
    $linkTarget = "$targetPath\$folderName"
    $linkPath = ""

    if ($folderName -eq "Firefox") {
        $profilesPath = "$HOME\AppData\Roaming\Mozilla\Firefox\Profiles"
        $profiles = Get-ChildItem -Directory -Path $profilesPath

        if ($profiles.Count -eq 0) {
            Write-Host "###############################################" -ForegroundColor Red
            Write-Host "#          No Firefox profiles found.         #" -ForegroundColor Red
            Write-Host "###############################################" -ForegroundColor Red
            return
        }

        Write-Host "###############################################" -ForegroundColor Yellow
        Write-Host "#    Found the following Firefox profiles:    #" -ForegroundColor Yellow
        Write-Host "###############################################" -ForegroundColor Yellow
        $profiles | ForEach-Object { Write-Host $_.Name }

        $selectedProfiles = @()
        foreach ($profile in $profiles) {
            $response = Read-Host "### Do you want to create a symbolic link for profile $($profile.Name)? (y/n) ###"
            if ($response -eq 'y') {
                $selectedProfiles += $profile.Name
            }
        }

        foreach ($profile in $selectedProfiles) {
            $linkPath = "$profilesPath\$profile\chrome"
            $linkTarget = "$targetPath\Firefox\chrome"
            if (Test-Path $linkPath) {
                $renameResponse = Read-Host "### The folder $linkPath already exists. Do you want to rename it? (y/n) ###"
                if ($renameResponse -eq 'y') {
                    $newName = "$linkPath-renamed"
                    Rename-Item -Path $linkPath -NewName $newName
                    Write-Host "###############################################" -ForegroundColor Yellow
                    Write-Host "#     Renamed existing folder to $newName     #" -ForegroundColor Yellow
                    Write-Host "###############################################" -ForegroundColor Yellow
                    $openResponse = Read-Host "### Do you want to open the renamed folder? (y/n) ###"
                    if ($openResponse -eq 'y') {
                        explorer.exe $newName
                    }
                }
            }
            New-Item -ItemType SymbolicLink -Target $linkTarget -Path $linkPath -Force
            Write-Host "######################################################" -ForegroundColor Green
            Write-Host "# Symbolic link created for Firefox profile $profile #" -ForegroundColor Green
            Write-Host "######################################################" -ForegroundColor Green
        }
    } elseif ($folderName -eq "ntop") {
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
        $packagesPath = "C:\Users\$userName\AppData\Local\Microsoft\WinGet\Packages"
        $ntopFolder = Get-ChildItem -Directory -Path $packagesPath | Where-Object { $_.Name -like "*NTop*" }

        if ($ntopFolder -eq $null) {
            Write-Host "###############################################" -ForegroundColor Red
            Write-Host "#            No ntop folder found.            #" -ForegroundColor Red
            Write-Host "###############################################" -ForegroundColor Red
            return
        }

        $linkPath = "$ntopFolder\ntop.conf"
        $linkTarget = "$targetPath\ntop\ntop.conf"
        if (Test-Path $linkPath) {
            $renameResponse = Read-Host "### The file $linkPath already exists. Do you want to rename it? (y/n) ###"
            if ($renameResponse -eq 'y') {
                $newName = "$linkPath-renamed"
                Rename-Item -Path $linkPath -NewName $newName
                Write-Host "###############################################" -ForegroundColor Yellow
                Write-Host "#      Renamed existing file to $newName      #" -ForegroundColor Yellow
                Write-Host "###############################################" -ForegroundColor Yellow
                $openResponse = Read-Host "### Do you want to open the location of the renamed file? (y/n) ###"
                if ($openResponse -eq 'y') {
                    explorer.exe (Split-Path -Parent $newName)
                }
            }
        }
        New-Item -ItemType SymbolicLink -Target $linkTarget -Path $linkPath -Force
        Write-Host "###############################################" -ForegroundColor Green
        Write-Host "#  Symbolic link created for ntop config file #" -ForegroundColor Green
        Write-Host "###############################################" -ForegroundColor Green
    } elseif ($folderName -eq "Powershell") {
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
        $linkTarget = "$targetPath\Powershell"
        $linkPath = "C:\Users\$userName\Documents\Powershell"
        if (Test-Path $linkPath) {
            $renameResponse = Read-Host "### The folder $linkPath already exists. Do you want to rename it? (y/n) ###"
            if ($renameResponse -eq 'y') {
                $newName = "$linkPath-renamed"
                Rename-Item -Path $linkPath -NewName $newName
                Write-Host "###############################################" -ForegroundColor Yellow
                Write-Host "#      Renamed existing folder to $newName    #" -ForegroundColor Yellow
                Write-Host "###############################################" -ForegroundColor Yellow
                $openResponse = Read-Host "### Do you want to open the renamed folder? (y/n) ###"
                if ($openResponse -eq 'y') {
                    explorer.exe $newName
                }
            }
        }
        New-Item -ItemType SymbolicLink -Target $linkTarget -Path $linkPath -Force
        Write-Host "###############################################" -ForegroundColor Green
        Write-Host "#     Symbolic link created for Powershell    #" -ForegroundColor Green
        Write-Host "###############################################" -ForegroundColor Green
    } elseif ($folderName -eq "Vencord") {
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
        $linkTarget = "$targetPath\Vencord"
        $linkPath = "C:\Users\$userName\AppData\Roaming\Vencord\settings"
        if (Test-Path $linkPath) {
            $renameResponse = Read-Host "### The folder $linkPath already exists. Do you want to rename it? (y/n) ###"
            if ($renameResponse -eq 'y') {
                $newName = "$linkPath-renamed"
                Rename-Item -Path $linkPath -NewName $newName
                Write-Host "###############################################" -ForegroundColor Yellow
                Write-Host "#     Renamed existing folder to $newName     #" -ForegroundColor Yellow
                Write-Host "###############################################" -ForegroundColor Yellow
                $openResponse = Read-Host "### Do you want to open the renamed folder? (y/n) ###"
                if ($openResponse -eq 'y') {
                    explorer.exe $newName
                }
            }
        }
        New-Item -ItemType SymbolicLink -Target $linkTarget -Path $linkPath -Force
        Write-Host "################################################" -ForegroundColor Green
        Write-Host "#  Symbolic link created for Vencord settings  #" -ForegroundColor Green
        Write-Host "################################################" -ForegroundColor Green
    } elseif ($folderName -eq "Windows Terminal") {
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]
        
        # Handle stable version
        $stableFolder = Get-ChildItem -Directory -Path "C:\Users\$userName\AppData\Local\Packages" | Where-Object { $_.Name -like "*Microsoft.WindowsTerminal*" }
        if ($stableFolder) {
            $stablePath = Join-Path $stableFolder[0].FullName "LocalState\settings.json"
            $linkTarget = "$targetPath\Windows Terminal\Stable\settings.json"
            if (Test-Path $stablePath) {
                $renameResponse = Read-Host "### The file $stablePath already exists. Do you want to rename it? (y/n) ###"
                if ($renameResponse -eq 'y') {
                    $newName = "$stablePath-renamed"
                    Rename-Item -Path $stablePath -NewName $newName
                    Write-Host "###############################################" -ForegroundColor Yellow
                    Write-Host "#      Renamed existing file to $newName      #" -ForegroundColor Yellow
                    Write-Host "###############################################" -ForegroundColor Yellow
                    $openResponse = Read-Host "### Do you want to open the location of the renamed file? (y/n) ###"
                    if ($openResponse -eq 'y') {
                        explorer.exe (Split-Path -Parent $newName)
                    }
                }
            }
            New-Item -ItemType SymbolicLink -Target $linkTarget -Path $stablePath -Force
            Write-Host "##############################################################" -ForegroundColor Green
            Write-Host "# Symbolic link created for Windows Terminal stable settings #" -ForegroundColor Green
            Write-Host "##############################################################" -ForegroundColor Green
        } else {
            Write-Host "###############################################" -ForegroundColor Red
            Write-Host "#   No stable Windows Terminal folder found.  #" -ForegroundColor Red
            Write-Host "###############################################" -ForegroundColor Red
        }

        # Handle preview version
        $previewFolder = Get-ChildItem -Directory -Path "C:\Users\$userName\AppData\Local\Packages" | Where-Object { $_.Name -like "*Microsoft.WindowsTerminalPreview*" }
        if ($previewFolder) {
            $previewPath = Join-Path $previewFolder[0].FullName "LocalState\settings.json"
            $linkTarget = "$targetPath\Windows Terminal\Preview\settings.json"
            if (Test-Path $previewPath) {
                $renameResponse = Read-Host "### The file $previewPath already exists. Do you want to rename it? (y/n) ###"
                if ($renameResponse -eq 'y') {
                    $newName = "$previewPath-renamed"
                    Rename-Item -Path $previewPath -NewName $newName
                    Write-Host "###############################################" -ForegroundColor Yellow
                    Write-Host "#      Renamed existing file to $newName      #" -ForegroundColor Yellow
                    Write-Host "###############################################" -ForegroundColor Yellow
                    $openResponse = Read-Host "### Do you want to open the location of the renamed file? (y/n) ###"
                    if ($openResponse -eq 'y') {
                        explorer.exe (Split-Path -Parent $newName)
                    }
                }
            }
            New-Item -ItemType SymbolicLink -Target $linkTarget -Path $previewPath -Force
            Write-Host "#################################################################" -ForegroundColor Green
            Write-Host "#  Symbolic link created for Windows Terminal preview settings  #" -ForegroundColor Green
            Write-Host "#################################################################" -ForegroundColor Green
        } else {
            Write-Host "###############################################" -ForegroundColor Red
            Write-Host "#  No preview Windows Terminal folder found.  #" -ForegroundColor Red
            Write-Host "###############################################" -ForegroundColor Red
        }
    }

    # Option to open the folder location of the linked file/folder
    if ($linkPath) {
        $openLinkLocation = Read-Host "### Do you want to open the folder location of the linked file/folder? (y/n) ###"
        if ($openLinkLocation -eq 'y') {
            explorer.exe (Split-Path -Parent $linkPath)
        }
    }

    Write-Host "###############################################"
    Write-Host "#     $folderName processing completed.       #"
    Write-Host "###############################################"
}

#####################################################
# Iterate over each selected sub-folder and prompt the user #
#####################################################
$totalFolders = $selectedFolders.Count
for ($i = 0; $i -lt $totalFolders; $i++) {
    $folder = $selectedFolders[$i]
    Write-Host "################################################################" -ForegroundColor Cyan
    Write-Host "              Processing folder $($i + 1) of $($totalFolders): ${folder}              " -ForegroundColor Cyan
    Write-Host "################################################################" -ForegroundColor Cyan
    Prompt-SymbolicLink -folderName $folder
}

#####################################################
# End prompt #
#####################################################
Write-Host "###########################################################" -ForegroundColor Green
Write-Host "#         Installation script is finished.                #" -ForegroundColor Green
Write-Host "#         Press any key to exit or press Enter to         #" -ForegroundColor Green
Write-Host "#         view post-installation notes...                 #" -ForegroundColor Green
Write-Host "###########################################################" -ForegroundColor Green
$key = [System.Console]::ReadKey($true)
if ($key.Key -eq 'Enter') {
    Write-Host "##############################################################" -ForegroundColor Yellow
    Write-Host "#         Post-installation notes:                           #" -ForegroundColor Yellow
    Write-Host "#         Make sure to install a c-compiler for nvim         #" -ForegroundColor Yellow
    Write-Host "#         such as zig.zig                                    #" -ForegroundColor Yellow
    Write-Host "#                                                            #" -ForegroundColor Yellow
    Write-Host "#                                                            #" -ForegroundColor Yellow
    Write-Host "##############################################################" -ForegroundColor Yellow
}
pause
exit
