# Define folder names to search for, in order (first to last)
$folderNamesToFind = @(
    "YUP - Base Game and All DLC",
    "3rd Person Animation Fixpack",
    "New Vegas Mesh Improvement Mod",
    "skinned mesh improvement mod",
    "PipBoyOn Node Fixes SMIM",
    "MAC-TEN",
    "Items Transformed - Enhanced ",
    "Assorted Voice Popping Fixes",
    "Elijah Missing Distortion Fix"
)

# Subfolders to extract
$subfoldersToExtract = @("meshes", "sound", "textures")

# Get the start folder
function Get-StartFolder {
    $startFolder = Read-Host "Select Mod Organizer 2 mods folder, enter path (or press Enter to select in GUI)"
    if ([string]::IsNullOrWhiteSpace($startFolder)) {
        Add-Type -AssemblyName System.Windows.Forms
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select the folder to search in"
        $folderBrowser.ShowNewFolderButton = $false
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $folderBrowser.SelectedPath
        } else {
            Write-Host "No folder selected. Exiting script." -ForegroundColor Red
            exit
        }
    }
    return $startFolder
}

# Create timestamp for output folder
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFolderName = "Bug Fixes Compiled $timestamp"

# Main script execution
try {
    # Get the start folder
    $startFolder = Get-StartFolder
    Write-Host "Using start folder: $startFolder" -ForegroundColor Cyan

    # Create the output folder
    $outputPath = Join-Path $startFolder $outputFolderName
    if (-not (Test-Path -Path $outputPath)) {
        New-Item -Path $outputPath -ItemType Directory | Out-Null
        Write-Host "Created output folder: $outputPath" -ForegroundColor Green
    }

    # Dictionary to store found folders
    $foundFoldersPaths = @{}
    $notFoundFolders = @()
    
    # Create tracking for copied files
    $fileCopyCounts = @{}
    $totalFilesCopied = 0
    
    # First find all matching folders
    Write-Host "Searching for all folders..." -ForegroundColor Yellow
    foreach ($folderName in $folderNamesToFind) {
        Write-Host "  Looking for folders containing: $folderName" -ForegroundColor Yellow
        
        # Find folders that contain the keyword
        $matchingFolders = Get-ChildItem -Path $startFolder -Directory -Recurse | 
                           Where-Object { $_.Name -like "*$folderName*" } | 
                           Select-Object -First 1
        
        if ($matchingFolders) {
            $foundFoldersPaths[$folderName] = $matchingFolders.FullName
            Write-Host "    Found: $($matchingFolders.FullName)" -ForegroundColor Green
        } else {
            $notFoundFolders += $folderName
            Write-Host "    Not found: $folderName" -ForegroundColor Red
        }
    }
    
    # Now copy files in the defined order
    Write-Host "`nCopying files in defined order..." -ForegroundColor Cyan
    foreach ($folderName in $folderNamesToFind) {
        if ($foundFoldersPaths.ContainsKey($folderName)) {
            $folderPath = $foundFoldersPaths[$folderName]
            Write-Host "  Processing: $folderName" -ForegroundColor Green
            
            # Initialize counts for this folder
            $fileCopyCounts[$folderName] = @{}
            
            # Process each subfolder (meshes, sound, textures)
            foreach ($subfolderName in $subfoldersToExtract) {
                $subfolderPath = Join-Path $folderPath $subfolderName
                
                if (Test-Path -Path $subfolderPath) {
                    $destinationPath = Join-Path $outputPath $subfolderName
                    
                    # Create destination subfolder if it doesn't exist
                    if (-not (Test-Path -Path $destinationPath)) {
                        New-Item -Path $destinationPath -ItemType Directory | Out-Null
                    }
                    
                    # Count files before copying
                    $filesToCopy = Get-ChildItem -Path $subfolderPath -Recurse -File
                    $fileCount = $filesToCopy.Count
                    
                    # Copy files, overwriting any existing ones
                    Write-Host "    Copying $subfolderName ($fileCount files)..." -ForegroundColor Cyan
                    Copy-Item -Path "$subfolderPath\*" -Destination $destinationPath -Recurse -Force
                    
                    # Store the count
                    $fileCopyCounts[$folderName][$subfolderName] = $fileCount
                    $totalFilesCopied += $fileCount
                } else {
                    $fileCopyCounts[$folderName][$subfolderName] = 0
                    Write-Host "    Subfolder $subfolderName not found in $folderName" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Report summary
    Write-Host "`nProcess completed!" -ForegroundColor Green
    Write-Host "Files compiled to: $outputPath" -ForegroundColor Green
    
    Write-Host "`nFolders found ($(($foundFoldersPaths.Keys).Count)):" -ForegroundColor Cyan
    foreach ($folder in $foundFoldersPaths.Keys) {
        Write-Host "  - $folder" -ForegroundColor Green
    }
    
    if ($notFoundFolders.Count -gt 0) {
        Write-Host "`nFolders not found ($($notFoundFolders.Count)):" -ForegroundColor Yellow
        foreach ($folder in $notFoundFolders) {
            Write-Host "  - $folder" -ForegroundColor Yellow
        }
    }
    
    # Display detailed copy information
    Write-Host "`nCopied files by folder:" -ForegroundColor Cyan
    foreach ($folderName in $folderNamesToFind) {
        if ($foundFoldersPaths.ContainsKey($folderName)) {
            Write-Host "$folderName" -ForegroundColor Green
            
            $copyDetails = @()
            foreach ($subfolderName in $subfoldersToExtract) {
                $count = $fileCopyCounts[$folderName][$subfolderName]
                if ($count -gt 0) {
                    # Capitalize first letter of subfolder name
                    $displayName = $subfolderName.Substring(0,1).ToUpper() + $subfolderName.Substring(1)
                    $copyDetails += "$displayName($count)"
                }
            }
            
            if ($copyDetails.Count -gt 0) {
                Write-Host "Copied: $($copyDetails -join ',')" -ForegroundColor Yellow
            } else {
                Write-Host "Copied: No files" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nTotal files copied: $totalFilesCopied" -ForegroundColor Green
    
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")