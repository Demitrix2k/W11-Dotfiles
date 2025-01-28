$Env:KOMOREBI_CONFIG_HOME = 	"$HOME\.config\komerebi"
$Env:WHKD_CONFIG_HOME = 	"$HOME\.config\whkd"
$Env:NTop_CONFIG_HOME= 		"$HOME\.config\ntop"
$Env:YAZI_CONFIG_HOME= 		"$HOME\.config\yazi"
$Env:XDG_CONFIG_HOME=		"$HOME\.config"
$Env:YAZI_FILE_ONE= 		"C:\Program Files\Git\usr\bin\file.exe"
$Env:nvim= 			"C:\Program Files\Neovim\bin\nvim.exe"

# Set-Variable -Name HOME -Value "C:\Users\rando" -Scope Global

Set-Alias	"ff"			"fastfetch"
Set-Alias	"q"			"Quit"
Set-Alias	"obm"			"Logitech.OnboardMemoryManager"
Set-Alias 	"winget.local" 		"Winget-Packages-Local"
Set-Alias 	"openw" 		"Open-In-Explorer"
Set-PSReadlineKeyHandler -Key 		"shift+Tab" -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 	"Tab" -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 	"RightArrow" -Function ForwardWord

function prompt {

    #Assign Windows Title Text
    $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

    #Configure current user, current folder and date outputs
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Date = Get-Date -Format 'dddd hh:mm:ss tt'

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    #Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    $LastCommand = Get-History -Count 1
    if ($lastCommand) { $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds }

    # if ($RunTime -ge 60) {
        # $ts = [timespan]::fromseconds($RunTime)
        # $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
        # $ElapsedTime = -join ($min, " min ", $sec, " sec")
    # }
    # else {
        # $ElapsedTime = [math]::Round(($RunTime), 2)
        # $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
    # }

    #Decorate the CMD Prompt
    Write-Host ""
    Write-host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " USER:$($CmdPromptUser.Name.split("\")[1]) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    If ($CmdPromptCurrentFolder -like "*:*")
        {Write-Host " $CmdPromptCurrentFolder "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline}
        else {Write-Host ".\$CmdPromptCurrentFolder\ "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline}

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
	
	
	
} #end prompt function

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

function Winget-Packages-Local {
    Set-Location -Path $Env:LocalAppdata\Microsoft\WinGet\Packages\
}

function Open-In-Explorer {
    Invoke-item .
}


fastfetch
