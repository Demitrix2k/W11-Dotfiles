$Env:KOMOREBI_CONFIG_HOME =             "$HOME\.config\komerebi"
$Env:WHKD_CONFIG_HOME =                 "$HOME\.config\whkd"
$Env:NTop_CONFIG_HOME=                  "$HOME\.config\ntop"
$Env:YAZI_CONFIG_HOME=                  "$HOME\.config\yazi"
$Env:XDG_CONFIG_HOME=                   "$HOME\.config"
$Env:POSHY=                             "$HOME\.config\posh"
$Env:YAZI_FILE_ONE=                     "C:\Program Files\Git\usr\bin\file.exe"
$Env:nvim=                              "C:\Program Files\Neovim\bin\nvim.exe"
$Env:conv_webm_to_mp4=                  "$HOME\.config\Powershell\Scripts\Convert-webm-to-mp4.ps1"
$Env:pad0=                              "$HOME\.config\Powershell\Scripts\Komorebic-padding-0.ps1"
$Env:pad1=                              "$HOME\.config\Powershell\Scripts\Komorebic-padding-10.ps1"
$Env:pad2=                              "$HOME\.config\Powershell\Scripts\Komorebic-padding-20.ps1"


Set-Alias       "ff"                    "fastfetch"
Set-Alias       "q"                     "Quit"
Set-Alias       "obm"                   "OnboardMemoryManager"
Set-Alias       "winget-local"          "WingetLocal"
Set-Alias       "open-exp"              "Open-In-Explorer"
Set-Alias       "aliasp"                "profile-aliases"
Set-PSReadlineKeyHandler -Key           "shift+Tab" -Function MenuComplete
Set-PSReadLineKeyHandler -Chord         "Tab" -Function AcceptSuggestion
# Set-PSReadLineKeyHandler -Chord       "RightArrow" -Function ForwardWord


# Store information that doesn't change frequently outside the prompt function
$WindowTitle = "PowerShell" # Initial window title
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[1] # Get user only once
$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$LastPath = $pwd # Initialize last path

function prompt {
    ## Update Window title only if the path has changed
    $currentPath = $pwd
    if ($currentPath -ne $LastPath) {
        $host.ui.RawUI.WindowTitle = "Current Folder: $currentPath"
        $LastPath = $currentPath # Update last path
    }

    $CmdPromptCurrentFolder = Split-Path -Path $currentPath -Leaf
    $Date = Get-Date -Format 'HH:mm:ss' # Simplified date format

    ## Decorate the CMD Prompt (simplified)
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
} # end prompt function

# custom prompt Functions
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath $cwd
    }
    Remove-Item -Path $tmp
}
function Quit {
    [System.Environment]::Exit(0)
}

function WingetLocal {
    Set-Location -Path $Env:LocalAppdata\Microsoft\WinGet\Packages\
}

function Open-In-Explorer {
    Invoke-item .
}



function reboot {
    Restart-Computer
}


function shell-colors {
	$colors = [System.Enum]::GetValues([System.ConsoleColor])
foreach ($color in $colors) {
    Write-Host "This is $color" -ForegroundColor $color
	}
}

function profile-aliases {
	Write-Host "ff              - Fastfetch"
	Write-Host "q               - quit terminal"
	Write-Host "obm             - OnBoardMemoryManager mouse"
	Write-Host "winget-local    - shows winget path"
	Write-Host "open-exp        - opens explorer in current path"
	Write-Host "Tab             - autocomplete"
	Write-Host "Shift+Tab       - Show Suggestions"
}

function Convert-WebmToMp4 {
  # Get the path to the conversion script from the environment variable
  $conversionScriptPath = $Env:conv_webm_to_mp4

  # Check if the path is valid
  if (-not (Test-Path $conversionScriptPath)) {
    Write-Error "Conversion script not found at: $conversionScriptPath"
    return  # Exit the function if the script is not found
  }

  # Execute the conversion script
  & $conversionScriptPath @args  # Pass any arguments to the script
}


# Measure initialization time
$InitializationStartTime = Get-Date

# Simulate initialization delay
# Start-Sleep -Milliseconds 3000

# Calculate initialization time
$InitializationEndTime = Get-Date
$InitializationTime = [math]::Round(($InitializationEndTime - $InitializationStartTime).TotalMilliseconds)

# Display initialization time once at startup
Write-Host "[Initialized in $InitializationTime ms] " -NoNewline -ForegroundColor Green





