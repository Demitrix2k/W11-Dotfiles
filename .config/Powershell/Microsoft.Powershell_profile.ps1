$Env:KOMOREBI_CONFIG_HOME =             "$HOME\.config\komerebi"
$Env:WHKD_CONFIG_HOME =                 "$HOME\.config\whkd"
$Env:NTop_CONFIG_HOME=                  "$HOME\.config\ntop"
$Env:YAZI_CONFIG_HOME=                  "$HOME\.config\yazi"
$Env:XDG_CONFIG_HOME=                   "$HOME\.config"

$Env:YAZI_FILE_ONE=                     "C:\Program Files\Git\usr\bin\file.exe"
$Env:nvim=                              "C:\Program Files\Neovim\bin\nvim.exe"
$Env:BSArch=                            "D:\Modding\MO2-FNV\External-tools\BSArch.exe"

$Env:komorebi_start=                    "$HOME\.config\Powershell\Scripts\komorebi\Komorebi-start.ps1"
$Env:komorebi_stop=                     "$HOME\.config\Powershell\Scripts\komorebi\Komorebi-stop.ps1"

$Env:matrix=                            "$HOME\.config\Powershell\Scripts\Matrix.ps1"
$Env:meow=                              "$HOME\.config\Powershell\Scripts\Meow\meow.ps1"
$Env:conv_webm_to_mp4=                  "$HOME\.config\Powershell\Scripts\Convert-webm-to-mp4.ps1"
$Env:w4ch=                              "$HOME\.config\Powershell\Scripts\Python\webm_for_4chan.py"



#############################################################################

Set-Alias       "bsarch"                "$env:BSArch"
Set-Alias       "kstart"                "$env:komorebi_start"
Set-Alias       "kstop"                 "$env:komorebi_stop"
Set-Alias       "meow"                  "$env:meow"
Set-Alias       "ff"                    "fastfetch"
Set-Alias       "q"                     "Quit"
Set-Alias       "obm"                   "OnboardMemoryManager"
Set-Alias       "wlocal"                "WingetLocal"
Set-Alias       "open"                  "Open-In-Explorer"
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

function WingetLocal { # show winget packages location
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

function palias {
	Write-Host "ff              - Fastfetch"
	Write-Host "q               - quit terminal"
	Write-Host "obm             - OnBoardMemoryManager mouse"
	Write-Host "winget-local    - shows winget path"
	Write-Host "open-exp        - opens explorer in current path"
	Write-Host "Tab             - autocomplete"
	Write-Host "Shift+Tab       - Show Suggestions"
	Write-Host "chan       		- 4chan webm script"
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
