$Env:KOMOREBI_CONFIG_HOME = 	"$HOME\.config\komerebi"
$Env:WHKD_CONFIG_HOME = 		"$HOME\.config\whkd"
$Env:NTop_CONFIG_HOME= 			"$HOME\.config\ntop"
$Env:YAZI_CONFIG_HOME= 			"$HOME\.config\yazi"
$Env:XDG_CONFIG_HOME=			"$HOME\.config"
$Env:YAZI_FILE_ONE= 			"C:\Program Files\Git\usr\bin\file.exe"
$Env:nvim= 						"C:\Program Files\Neovim\bin\nvim.exe"



# Set-Variable -Name HOME -Value "C:\Users\rando" -Scope Global

Set-Alias	"ff"					"fastfetch"
Set-Alias	"q"						"Quit"
Set-Alias	"obm"					"OnboardMemoryManager"
Set-Alias 	"winget-local" 			"Winget-Local"
Set-Alias 	"open-exp" 				"Open-In-Explorer"
Set-PSReadlineKeyHandler -Key 		"shift+Tab" -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 	"Tab" -Function AcceptSuggestion
# Set-PSReadLineKeyHandler -Chord 	"RightArrow" -Function ForwardWord


# Store information that doesn't change frequently outside the prompt function
$WindowTitle = "PowerShell" # Initial window title
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[1] # Get user only once
$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$LastPath = $pwd # Initialize last path

function prompt {
    # Update Window title only if the path has changed
    $currentPath = $pwd
    if ($currentPath -ne $LastPath) {
        $host.ui.RawUI.WindowTitle = "Current Folder: $currentPath"
        $LastPath = $currentPath # Update last path
    }

    $CmdPromptCurrentFolder = Split-Path -Path $currentPath -Leaf
    $Date = Get-Date -Format 'HH:mm:ss' # Simplified date format

    #Decorate the CMD Prompt (simplified)
    Write-Host ""
    Write-host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " USER:$CurrentUser " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    If ($CmdPromptCurrentFolder -like "*:*") {
        Write-Host " $CmdPromptCurrentFolder "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    } else {
        Write-Host ".\$CmdPromptCurrentFolder\ "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }

    Write-Host " $Date " -ForegroundColor White

    return "> "
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

function Winget-Local {
    Set-Location -Path $Env:LocalAppdata\Microsoft\WinGet\Packages\
}

function Open-In-Explorer {
    Invoke-item .
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

ff


