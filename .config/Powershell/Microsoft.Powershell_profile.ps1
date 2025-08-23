$Env:KOMOREBI_CONFIG_HOME =             "$HOME\.config\komerebi"
$Env:WHKD_CONFIG_HOME =                 "$HOME\.config\whkd"
$Env:NTop_CONFIG_HOME=                  "$HOME\.config\ntop"
$Env:YAZI_CONFIG_HOME=                  "$HOME\.config\yazi"
$Env:XDG_CONFIG_HOME=                   "$HOME\.config"
$Env:MPV_HOME=                          "$HOME\.config\mpv"

$Env:YAZI_FILE_ONE=                     "C:\Program Files\Git\usr\bin\file.exe"
$Env:nvim=                              "C:\Program Files\Neovim\bin\nvim.exe"
$Env:BSArch=                            "D:\Modding\MO2-FNV\External-tools\BSArch.exe"
$Env:mpv=                               "C:\Programs\mpv\mpv.exe"

$Env:komorebi_start=                    "$HOME\.config\Powershell\Scripts\komorebi\Komorebi-start.ps1"
$Env:komorebi_stop=                     "$HOME\.config\Powershell\Scripts\komorebi\Komorebi-stop.ps1"

$Env:app_list=                          "$HOME\.config\Powershell\Scripts\list-all-installed.ps1"
$Env:matrix=                            "$HOME\.config\Powershell\Scripts\Matrix.ps1"
$Env:meow=                              "$HOME\.config\Powershell\Scripts\Meow\meow.ps1"
$Env:conv_webm_to_mp4=                  "$HOME\.config\Powershell\Scripts\Convert-webm-to-mp4.ps1"
$Env:w4ch=                              "$HOME\.config\Powershell\Scripts\Python\webm_for_4chan.py"



#############################################################################

Set-Alias       "app"                   "$env:app_list"
Set-Alias       "mpv"                   "$env:mpv"
Set-Alias       "bsarch"                "$env:BSArch"
Set-Alias       "kstart"                "$env:komorebi_start"
Set-Alias       "kstop"                 "$env:komorebi_stop"
Set-Alias       "meow"                  "$env:meow"
Set-Alias       "ff"                    "fastfetch"
Set-Alias       "q"                     "Quit"
Set-Alias       "obm"                   "OnboardMemoryManager"
Set-Alias       "wlocal"                "Winget-Local"
Set-Alias       "open"                  "Open-In-Explorer"
Set-Alias       "reload"                "_Reload-profile"
Set-PSReadlineKeyHandler -Key           "shift+Tab" -Function MenuComplete
Set-PSReadLineKeyHandler -Chord         "Tab" -Function AcceptSuggestion
# Set-PSReadLineKeyHandler -Chord       "RightArrow" -Function ForwardWord

#############################################################################


#################### Terminal color and appearance begin ####################
$WindowTitle = "PowerShell" 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[1] 
$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$LastPath = $pwd 

function prompt {
    $currentPath = $pwd
    if ($currentPath -ne $LastPath) {
        $host.ui.RawUI.WindowTitle = "Current Folder: $currentPath"
        $LastPath = $currentPath 
    }

    $CmdPromptCurrentFolder = Split-Path -Path $currentPath -Leaf
    $Date = Get-Date -Format 'HH:mm:ss' 

    Write-Host ""
    Write-host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host "  " -BackgroundColor DarkCyan -ForegroundColor White -NoNewline
	# Write-Host " USER:$CurrentUser " -BackgroundColor DarkCyan -ForegroundColor White -NoNewline
    If ($CmdPromptCurrentFolder -like "*:*") {
        Write-Host "  $CmdPromptCurrentFolder "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    } else {
        Write-Host "  .\$CmdPromptCurrentFolder\ "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }

    Write-Host " $Date " -ForegroundColor White

    return "󱞩 "
}
##################### Terminal color and appearance end #####################

############################################################################# 
####################### CUSTOM PROMPT FUNCTIONS BEGIN #######################
#############################################################################

function _Reload-profile {
    # This is an internal function, typically not called directly by the user
    # unless aliased. The underscore convention suggests it's internal.
    Write-Host "Reloading PowerShell profile..." -ForegroundColor Cyan
    try {
        . $PROFILE
        Write-Host "Profile reloaded successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to reload profile: $($_.Exception.Message)"
        Write-Host "Please check your $PROFILE file for errors." -ForegroundColor Red
    }
}

function y { # For Yazi, exit yazi to viewed folder
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath $cwd
    }
    Remove-Item -Path $tmp
}

function Quit { # quit terminal
    [System.Environment]::Exit(0)
}

function Winget-Local { # show winget packages location
    Set-Location -Path $Env:LocalAppdata\Microsoft\WinGet\Packages\
}

function Open-In-Explorer { # opens explorer window
    Invoke-item .
}

function reboot { # reboot computer
    Restart-Computer
}

function shell-colors { # displays all supported terminal colors
	$colors = [System.Enum]::GetValues([System.ConsoleColor])
foreach ($color in $colors) {
    Write-Host "This is $color" -ForegroundColor $color
	}
}

function commands {
Write-Host "kstart/kstop        - Komorebi start/stop"           -ForegroundColor Blue
Write-Host "meow                - used to print colored text"    -ForegroundColor Green
Write-Host "mpv                 - mpv video player" -ForegroundColor Blue
Write-Host "app                 - lists installed programs" -ForegroundColor Green
Write-Host "ff                  - Fastfetch" -ForegroundColor Blue
Write-Host "q                   - quit terminal" -ForegroundColor Green
Write-Host "obm                 - OnBoardMemoryManager mouse" -ForegroundColor Blue
Write-Host "w-local             - shows winget path" -ForegroundColor Green
Write-Host "open                - opens explorer in current path" -ForegroundColor Blue
Write-Host "Tab                 - autocomplete" -ForegroundColor Green
Write-Host "Shift+Tab           - Show Suggestions" -ForegroundColor Blue
Write-Host "chan                - 4chan webm script" -ForegroundColor Green
}


function Convert-WebmToMp4 { # script that can handle mass conversion
  $conversionScriptPath = $Env:conv_webm_to_mp4

  if (-not (Test-Path $conversionScriptPath)) {
    Write-Error "Conversion script not found at: $conversionScriptPath"
    return 
  }
  
  & $conversionScriptPath @args 
}

function matrix { # cmatrix effects
    param(
        [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
        [string[]]$ScriptArguments
    )

    $MXPath = $Env:matrix

    if (-not $MXPath) {
        Write-Error "Error: Environment variable 'matrix' is not defined."
        return
    }

    if (-not (Test-Path -Path $MXPath -PathType Leaf)) {
        Write-Error "Error: Script not found at '$MXPath'."
        return
    }

    & pwsh -File "$MXPath" @ScriptArguments
}

function chan { # webm-for-4ch
    param (
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$args
    )
    python $Env:w4ch @args
}

# Example: Try with -quality 85% instead of 90% in your Optimize-JpgFiles function
# Modify the existing function definition directly in your PowerShell profile:

function Convert-PngToJpg {
    param(
        [ValidateRange(1, 100)]
        [int]$Quality = 90 # Default JPEG quality
    )
    
    # Get all PNG files in the current directory
    $pngFiles = Get-ChildItem -Path . -Filter "*.png"
    $totalFiles = $pngFiles.Count
    $currentFile = 0

    # Check if any PNG files were found
    if ($totalFiles -eq 0) {
        Write-Host "No PNG files found in the current directory to convert." -ForegroundColor Yellow
        return # Exit the function if no files are found
    }

    Write-Host "Starting PNG to JPG conversion ($Quality% quality) for $totalFiles file(s) in the current directory..." -ForegroundColor Green

    # Loop through each PNG file
    foreach ($file in $pngFiles) {
        $currentFile++
        # Calculate percentage complete for the progress bar
        $percentage = [int](($currentFile / $totalFiles) * 100)

        # Define the output JPG filename
        $outputJpgPath = Join-Path -Path $file.DirectoryName -ChildPath "$($file.BaseName).jpg"

        # Update the PowerShell progress bar
        Write-Progress -Activity "Converting PNG to JPG" `
                       -Status "Processing $($file.Name)" `
                       -CurrentOperation "Converting to '$($file.BaseName).jpg' (File $currentFile of $totalFiles)" `
                       -PercentComplete $percentage

        try {
            # Build argument string for ImageMagick
            $arguments = @(
                "`"$($file.FullName)`"", # Input file path (double-quoted)
                "-strip",
                "-interlace", "Plane",
                "-quality", "$($Quality)%", # Quality needs to be a string like "90%"
                "-colorspace", "sRGB",
                "-sampling-factor", "4:2:0",
                "`"$outputJpgPath`"" # Output file path (double-quoted)
            )

            # Join arguments into a single string for Start-Process -ArgumentList
            $argumentString = $arguments -join ' '

            # Execute ImageMagick using Start-Process
            Start-Process -FilePath "magick" `
                          -ArgumentList $argumentString `
                          -NoNewWindow `
                          -Wait `
                          -ErrorAction Stop # Ensure errors are caught by PowerShell's try/catch
            
            # --- NEW: Check if JPG was created and delete original PNG ---
            if (Test-Path $outputJpgPath) {
                try {
                    Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                    Write-Verbose "Deleted original PNG: $($file.Name)"
                }
                catch {
                    Write-Warning "Failed to delete original PNG $($file.Name): $($_.Exception.Message)"
                }
            } else {
                Write-Warning "JPG file '$($outputJpgPath)' was not created for '$($file.Name)'. Original PNG not deleted."
            }
            # --- END NEW ---
        }
        catch {
            # Catch and display any errors during ImageMagick execution
            Write-Error "An error occurred while converting $($file.Name): $($_.Exception.Message)"
            Write-Host "Please ensure ImageMagick is installed and in your system's PATH." -ForegroundColor Yellow
            # Continue to the next file even if one fails
        }
    }
    
    # Complete the progress bar once all files are processed
    Write-Progress -Activity "Converting PNG to JPG" -Completed
    Write-Host "PNG to JPG conversion complete. New JPG files are in the current directory." -ForegroundColor Green
    Write-Host "Note: Successfully converted PNG files have been deleted." -ForegroundColor Yellow
}

function Optimize-JpgFiles {
    param()

    Write-Host "Optimizing JPG files in the current directory..." -ForegroundColor Green
    $jpgFiles = Get-ChildItem -Path . -Filter "*.jpg", "*.jpeg" # Support both extensions
    $totalFiles = $jpgFiles.Count
    $currentFile = 0

    if ($totalFiles -eq 0) {
        Write-Host "No JPG/JPEG files found in the current directory to optimize." -ForegroundColor Yellow
        return
    }

    foreach ($file in $jpgFiles) {
        $currentFile++
        $percentage = [int](($currentFile / $totalFiles) * 100)

        Write-Progress -Activity "Optimizing JPG Images" `
                       -Status "Processing $($file.Name)" `
                       -CurrentOperation "File $currentFile of $totalFiles" `
                       -PercentComplete $percentage
        try {
            magick mogrify `
                -strip `
                -interlace Plane ` # Progressive JPEG
                -quality 85% `    # Changed to 85%
                -path . `
                $file.FullName
        }
        catch {
            Write-Error "An error occurred during JPG optimization: $($_.Exception.Message)"
            Write-Host "Please ensure ImageMagick is installed and in your system's PATH." -ForegroundColor Yellow
        }
    }
    Write-Progress -Activity "Optimizing JPG Images" -Completed
    Write-Host "JPG optimization complete." -ForegroundColor Green
}

function Optimize-PngFiles {
    param()
    
    # Get all PNG files in the current directory
    $pngFiles = Get-ChildItem -Path . -Filter "*.png"
    $totalFiles = $pngFiles.Count
    $currentFile = 0

    # Check if any PNG files were found
    if ($totalFiles -eq 0) {
        Write-Host "No PNG files found in the current directory to optimize." -ForegroundColor Yellow
        return # Exit the function if no files are found
    }

    Write-Host "Starting PNG optimization for $totalFiles file(s) in the current directory..." -ForegroundColor Green

    # Loop through each PNG file
    foreach ($file in $pngFiles) {
        $currentFile++
        # Calculate percentage complete for the progress bar
        $percentage = [int](($currentFile / $totalFiles) * 100)

        # Update the PowerShell progress bar
        Write-Progress -Activity "Optimizing PNG Images" `
                       -Status "Processing $($file.Name)" `
                       -CurrentOperation "File $currentFile of $totalFiles" `
                       -PercentComplete $percentage

        try {
            # Execute ImageMagick mogrify command for the current file
            magick mogrify `
                -strip `
                -define png:compression-filter=5 `
                -define png:compression-level=9 `
                -define png:compression-strategy=1 `
                -path . ` # Save to the current directory
                $file.FullName # Process the individual file
        }
        catch {
            # Catch and display any errors during ImageMagick execution
            Write-Error "An error occurred while processing $($file.Name): $($_.Exception.Message)"
            Write-Host "Please ensure ImageMagick is installed and in your system's PATH." -ForegroundColor Yellow
            # Continue to the next file even if one fails
        }
    }
    
    # Complete the progress bar once all files are processed
    Write-Progress -Activity "Optimizing PNG Images" -Completed
    Write-Host "PNG optimization complete." -ForegroundColor Green
}

############################################################################# 
######################## CUSTOM PROMPT FUNCTIONS END ########################
#############################################################################


#############################################################################
# Measure initialization time
$InitializationStartTime = Get-Date

# Simulate initialization delay
# Start-Sleep -Milliseconds 3000

# Calculate initialization time
$InitializationEndTime = Get-Date
$InitializationTime = [math]::Round(($InitializationEndTime - $InitializationStartTime).TotalMilliseconds)

# Display initialization time once at startup
Write-Host "[Initialized in $InitializationTime ms] " -NoNewline -ForegroundColor Green

#############################################################################

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
