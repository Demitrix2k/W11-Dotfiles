<#
.SYNOPSIS
    A Matrix-like animation with continuous movement and rainbow color option.
.DESCRIPTION
    Creates a Matrix-style falling characters effect in your PowerShell terminal
    with optimized continuous movement and color customization, including rainbow mode.
.PARAMETER Color
    The color of the characters (default: Green).
    Available options: Green, Cyan, Red, Yellow, Magenta, White
.PARAMETER Speed
    The speed of the animation from 1-10 (default: 5).
.PARAMETER Density
    The density of falling characters from 1-10 (default: 5).
.PARAMETER Rainbow
    Enable rainbow coloring of matrix characters (overrides -Color parameter).
.PARAMETER RainbowSpeed
    Controls the speed of rainbow color cycling when in rainbow mode (default: 3).
.PARAMETER TrueColor
    Use 24-bit true color for more vibrant rainbow effects (requires compatible terminal).
.PARAMETER Help
    Display detailed help information about the script.
.EXAMPLE
    .\Matrix-Continuous.ps1
    Runs the Matrix animation with default settings (green color).
.EXAMPLE
    .\Matrix-Continuous.ps1 -Color Cyan -Speed 8 -Density 7
    Runs a faster, denser Matrix animation with cyan colored characters.
.EXAMPLE
    .\Matrix-Continuous.ps1 -Rainbow -TrueColor
    Runs the Matrix animation with vibrant true color rainbow effects.
.NOTES
    Press any key to exit the animation.
#>
param (
    [ValidateSet('Green', 'Cyan', 'Red', 'Yellow', 'Magenta', 'White')]
    [string]$Color = 'Green',
    
    [ValidateRange(1, 10)]
    [int]$Speed = 5,
    
    [ValidateRange(1, 10)]
    [int]$Density = 5,
    
    [switch]$Rainbow,
    
    [ValidateRange(1, 10)]
    [int]$RainbowSpeed = 3,
    
    [switch]$TrueColor,
    
    [switch]$Help
)

# Display help if requested
if ($Help) {
    Clear-Host
    Write-Host "Matrix Animation - PowerShell Edition" -ForegroundColor $Color -BackgroundColor Black
    Write-Host "=================================" -ForegroundColor $Color -BackgroundColor Black
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor White
    Write-Host "  This script creates a Matrix-style animation in your console with" -ForegroundColor Gray
    Write-Host "  customizable falling characters that simulate the iconic 'digital rain'" -ForegroundColor Gray
    Write-Host "  effect from 'The Matrix' movie." -ForegroundColor Gray
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  .\Matrix-Continuous.ps1 [OPTIONS]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor White
    Write-Host "  -Color <name>     Character color (default: Green)" -ForegroundColor Gray
    Write-Host "                    Available colors: Green, Cyan, Red, Yellow, Magenta, White" -ForegroundColor Gray
    Write-Host "  -Speed <1-10>     Animation speed (default: 5)" -ForegroundColor Gray
    Write-Host "                    1 = slowest, 10 = fastest" -ForegroundColor Gray
    Write-Host "  -Density <1-10>   Density of falling characters (default: 5)" -ForegroundColor Gray
    Write-Host "                    1 = sparse, 10 = very dense" -ForegroundColor Gray
    Write-Host "  -Rainbow          Enable rainbow coloring of characters" -ForegroundColor Gray
    Write-Host "  -RainbowSpeed <1-10> Speed of rainbow color cycling (default: 3)" -ForegroundColor Gray
    Write-Host "  -TrueColor        Use 24-bit true color for more vibrant rainbow effects" -ForegroundColor Gray
    Write-Host "  -Help             Show this help information" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor White
    Write-Host "  .\Matrix-Continuous.ps1" -ForegroundColor Gray
    Write-Host "    Run with default green color at medium speed and density" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  .\Matrix-Continuous.ps1 -Rainbow" -ForegroundColor Gray
    Write-Host "    Run with rainbow colored characters" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  .\Matrix-Continuous.ps1 -Speed 8 -Density 7" -ForegroundColor Gray
    Write-Host "    Run a faster animation with more characters" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  .\Matrix-Continuous.ps1 -Rainbow -RainbowSpeed 7" -ForegroundColor Gray
    Write-Host "    Run with faster cycling rainbow colors" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  .\Matrix-Continuous.ps1 -Rainbow -TrueColor" -ForegroundColor Gray
    Write-Host "    Run with vibrant true color rainbow effects" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "CONTROLS:" -ForegroundColor White
    Write-Host "  Any key            Exit the animation" -ForegroundColor Gray
    Write-Host ""
    return
}

# Save original console settings
$originalBackgroundColor = $host.UI.RawUI.BackgroundColor
$originalCursorSize = $host.UI.RawUI.CursorSize
$originalWindowTitle = $host.UI.RawUI.WindowTitle

# Escape character for ANSI sequences
$ESC = [char]27

# Function for writing with TrueColor ANSI sequences
function Write-TrueColorCharacter {
    param (
        [char]$Character,
        [int]$R,
        [int]$G,
        [int]$B
    )
    
    # Ensure values are in valid range
    $R = [Math]::Max(0, [Math]::Min(255, [int]$R))
    $G = [Math]::Max(0, [Math]::Min(255, [int]$G))
    $B = [Math]::Max(0, [Math]::Min(255, [int]$B))
    
    # Output character with foreground color using ANSI escape sequence
    Write-Host "$ESC[38;2;$R;$G;${B}m$Character$ESC[0m" -NoNewline
}

# Function to get the appropriate dark color based on the selected color
function Get-DarkColor {
    param([string]$BrightColor)
    
    switch ($BrightColor) {
        'Green'   { return 'DarkGreen' }
        'Cyan'    { return 'DarkCyan' }
        'Red'     { return 'DarkRed' }
        'Yellow'  { return 'DarkYellow' }
        'Magenta' { return 'DarkMagenta' }
        'White'   { return 'Gray' }
        default   { return 'DarkGreen' }
    }
}

# Generate rainbow colors - improved with darker, more subdued colors
function Get-RainbowColor {
    param(
        [int]$position, 
        [int]$speed = 3,
        [switch]$ReturnRGB,
        [double]$Brightness = 0.7  # Add brightness control (0.0-1.0)
    )
    
    # Use proven values from Core.ps1
    $freq = 1.1 * ($speed / 3)
    $spread = 30
    
    # Calculate base RGB components using sine waves with proper phase shifts
    $r = [Math]::Sin($freq * ($position / $spread) + 0) 
    $g = [Math]::Sin($freq * ($position / $spread) + 2 * [Math]::PI / 3)
    $b = [Math]::Sin($freq * ($position / $spread) + 4 * [Math]::PI / 3)
    
    # Apply lower amplitude and center point for darker colors
    # Use 80-90 for amplitude and 60-80 for center point for more subdued colors
    $amplitude = 90 * $Brightness
    $center = 70 * $Brightness
    
    # Apply Matrix green tint - slightly boost green channel
    $r = $r * $amplitude + $center
    $g = $g * $amplitude + $center + (15 * $Brightness)  # Boost green slightly
    $b = $b * $amplitude + $center
    
    # Ensure values are in valid range
    $r = [Math]::Max(0, [Math]::Min(255, [int]$r))
    $g = [Math]::Max(0, [Math]::Min(255, [int]$g))
    $b = [Math]::Max(0, [Math]::Min(255, [int]$b))
    
    if ($ReturnRGB) {
        return @($r, $g, $b)
    } else {
        # Find closest ConsoleColor if not using TrueColor
        $closestColor = Get-ClosestConsoleColor -r $r -g $g -b $b
        return $closestColor
    }
}

# Map RGB values to closest console color
function Get-ClosestConsoleColor {
    param([int]$r, [int]$g, [int]$b)
    
    # Define RGB values for the ConsoleColors
    $consoleColors = @{
        'Black'       = @(0, 0, 0)
        'DarkBlue'    = @(0, 0, 128)
        'DarkGreen'   = @(0, 128, 0)
        'DarkCyan'    = @(0, 128, 128)
        'DarkRed'     = @(128, 0, 0)
        'DarkMagenta' = @(128, 0, 128)
        'DarkYellow'  = @(128, 128, 0)
        'Gray'        = @(192, 192, 192)
        'DarkGray'    = @(128, 128, 128)
        'Blue'        = @(0, 0, 255)
        'Green'       = @(0, 255, 0)
        'Cyan'        = @(0, 255, 255)
        'Red'         = @(255, 0, 0)
        'Magenta'     = @(255, 0, 255)
        'Yellow'      = @(255, 255, 0)
        'White'       = @(255, 255, 255)
    }
    
    $closestColor = 'White'
    $minDistance = [double]::MaxValue
    
    # Find closest color by Euclidean distance in RGB space
    foreach ($colorName in $consoleColors.Keys) {
        $colorRGB = $consoleColors[$colorName]
        $distance = [Math]::Sqrt(
            [Math]::Pow($r - $colorRGB[0], 2) +
            [Math]::Pow($g - $colorRGB[1], 2) +
            [Math]::Pow($b - $colorRGB[2], 2)
        )
        
        if ($distance -lt $minDistance) {
            $minDistance = $distance
            $closestColor = $colorName
        }
    }
    
    return $closestColor
}

# Get the dark version of the selected color (for non-rainbow mode)
$DarkColor = Get-DarkColor -BrightColor $Color

try {
    # Set console properties
    $host.UI.RawUI.BackgroundColor = 'Black'
    Clear-Host
    $host.UI.RawUI.CursorSize = 0  # Hide cursor
    
    # Set window title based on mode
    if ($Rainbow) {
        if ($TrueColor) {
            $host.UI.RawUI.WindowTitle = "The Matrix - True Color Rainbow Flow (Press any key to exit)"
        } else {
            $host.UI.RawUI.WindowTitle = "The Matrix - Rainbow Flow (Press any key to exit)"
        }
    } else {
        $host.UI.RawUI.WindowTitle = "The Matrix - Continuous Flow (Press any key to exit)"
    }
    
    # Setup key press detection using direct method for better reliability
    $exitRequested = $false
    
    # Get console dimensions
    $width = $host.UI.RawUI.WindowSize.Width
    $height = $host.UI.RawUI.WindowSize.Height
    
    # Adjust speed
    $delay = [Math]::Max(1, 80 - ($Speed * 7))
    
    # Matrix characters - mix of Katakana and Latin characters
    $chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ'
    
    # Initialize active columns with ArrayList for better management
    $columns = New-Object System.Collections.ArrayList
    $maxColumns = [Math]::Max(5, [Math]::Ceiling($width * $Density / 10)) # Scale based on density
    
    # Keep track of column usage
    $columnInUse = @{ }
    
    # Counter for rainbow color cycling
    $rainbowPosition = 0
    
    # Animation loop
    while (-not $exitRequested) {
        # Check for key press to exit
        if ([Console]::KeyAvailable) {
            [Console]::ReadKey($true) | Out-Null  # Consume the key press
            $exitRequested = $true
            continue
        }
        
        # Calculate how many new columns we need
        $activeColumns = $columns.Count
        $neededColumns = $maxColumns - $activeColumns
        
        # Create new columns if needed
        for ($i = 0; $i -lt $neededColumns; $i++) {
            # Find an unused column position
            $attempts = 0
            do {
                $x = Get-Random -Minimum 0 -Maximum $width
                $attempts++ 
            } while ($columnInUse.ContainsKey($x) -and $attempts -lt 20)
            
            # If we found an unused column (or tried enough times), create a new drop
            if (-not $columnInUse.ContainsKey($x) -or $attempts -ge 20) {
                $columnInUse[$x] = $true
                
                # Create a drop with varying properties
                [void]$columns.Add(@{
                    X = $x
                    Y = (Get-Random -Minimum -5 -Maximum 10) # Some start above screen for staggered effect
                    Length = Get-Random -Minimum 4 -Maximum 25
                    Speed = (Get-Random -Minimum 1 -Maximum 4)
                    LastChar = @{}  # Track last character at each position to avoid redrawing same
                    MaxAge = Get-Random -Minimum 50 -Maximum 150  # Maximum life of drop
                    Age = 0  # Current life counter
                    ColorOffset = Get-Random -Minimum 0 -Maximum 100  # More variation in initial colors
                })
            }
        }
        
        # Track columns to remove
        $columnsToRemove = New-Object System.Collections.ArrayList
        
        # Process each column - only update positions that need to change
        foreach ($col in $columns) {
            $x = $col.X
            
            # Clear the old character at the tail
            $tailPos = $col.Y - $col.Length
            if ($tailPos -ge 0 -and $tailPos -lt $height) {
                # Only redraw if we've changed the position
                [System.Console]::SetCursorPosition($x, $tailPos)
                [System.Console]::Write(' ')
                $col.LastChar.Remove("$x,$tailPos")
            }
            
            # Randomize characters in the trail occasionally for more dynamic effect
            $randomizePos = Get-Random -Minimum 0 -Maximum $col.Length
            if ($randomizePos -gt 0 -and $randomizePos -lt $col.Length) {
                $randY = $col.Y - $randomizePos
                if ($randY -ge 0 -and $randY -lt $height) {
                    [System.Console]::SetCursorPosition($x, $randY)
                    $newChar = $chars[(Get-Random -Maximum $chars.Length)]
                    $col.LastChar["$x,$randY"] = $newChar
                    
                    # Choose color based on position in trail and mode
                    if ($Rainbow) {
                        $colorPos = $col.ColorOffset + $randomizePos * 5
                        
                        # Adjust brightness based on position in trail
                        # Characters further down the trail should be darker
                        $trailBrightness = 0.7 - ($randomizePos / $col.Length * 0.3)
                        
                        if ($TrueColor) {
                            $rgb = Get-RainbowColor -position $colorPos -speed $RainbowSpeed -ReturnRGB -Brightness $trailBrightness
                            Write-TrueColorCharacter -Character $newChar -R $rgb[0] -G $rgb[1] -B $rgb[2]
                        } else {
                            [System.Console]::ForegroundColor = [System.ConsoleColor](Get-RainbowColor -position $colorPos -speed $RainbowSpeed -Brightness $trailBrightness)
                            [System.Console]::Write($newChar)
                        }
                    } else {
                        # Standard color mode
                        if ($randomizePos -lt 3) {
                            [System.Console]::ForegroundColor = [ConsoleColor]::$Color
                        } else {
                            [System.Console]::ForegroundColor = [ConsoleColor]::$DarkColor
                        }
                        [System.Console]::Write($newChar)
                    }
                }
            }
            
            # Draw all characters in the column
            for ($i = 0; $i -lt $col.Length; $i++) {
                $y = $col.Y - $i
                if ($y -ge 0 -and $y -lt $height) {
                    $newChar = $chars[(Get-Random -Maximum $chars.Length)]
                    $posKey = "$x,$y"
                    
                    # Only update if character changed or position is head/near head
                    $lastChar = $col.LastChar[$posKey]
                    if ($i -lt 3 -or $lastChar -eq $null -or (Get-Random -Minimum 0 -Maximum 10) -eq 0) {
                        [System.Console]::SetCursorPosition($x, $y)
                        $col.LastChar[$posKey] = $newChar
                        
                        # Set appropriate color based on mode
                        if ($Rainbow) {
                            # Rainbow mode uses position-based color cycling
                            $colorPos = $col.ColorOffset + $i * 5
                            
                            # Adjust brightness based on position in trail
                            $trailBrightness = $i -eq 0 ? 1.0 : (0.7 - ($i / $col.Length * 0.5))
                            
                            if ($i -eq 0) {
                                # Head is always white for better visibility
                                if ($TrueColor) {
                                    # Slightly dimmed white for better integration with the theme
                                    Write-TrueColorCharacter -Character $newChar -R 230 -G 230 -B 230
                                } else {
                                    [System.Console]::ForegroundColor = [ConsoleColor]::White
                                    [System.Console]::Write($newChar)
                                }
                            } else {
                                # Rest use rainbow colors
                                if ($TrueColor) {
                                    $rgb = Get-RainbowColor -position $colorPos -speed $RainbowSpeed -ReturnRGB -Brightness $trailBrightness
                                    Write-TrueColorCharacter -Character $newChar -R $rgb[0] -G $rgb[1] -B $rgb[2]
                                } else {
                                    [System.Console]::ForegroundColor = [System.ConsoleColor](Get-RainbowColor -position $colorPos -speed $RainbowSpeed -Brightness $trailBrightness)
                                    [System.Console]::Write($newChar)
                                }
                            }
                        } else {
                            # Standard color mode
                            if ($i -eq 0) { 
                                [System.Console]::ForegroundColor = [ConsoleColor]::White
                            } elseif ($i -lt 5) {
                                [System.Console]::ForegroundColor = [ConsoleColor]::$Color
                            } else {
                                [System.Console]::ForegroundColor = [ConsoleColor]::$DarkColor
                            }
                            [System.Console]::Write($newChar)
                        }
                    }
                }
            }
            
            # Move column down
            $col.Y += $col.Speed
            
            # Increment age
            $col.Age += 1
            
            # Mark column for removal if it's gone off screen or too old
            if (($col.Y - $col.Length -gt $height) -or ($col.Age -gt $col.MaxAge)) {
                [void]$columnsToRemove.Add($col)
                # Free up the column position
                $columnInUse.Remove($col.X)
            }
        }
        
        # Remove columns that are off-screen
        foreach ($col in $columnsToRemove) {
            [void]$columns.Remove($col)
        }
        
        # Increment the rainbow position counter for continuous color cycling
        if ($Rainbow) {
            $rainbowPosition += 1
            # Reset to prevent integer overflow on very long runs
            if ($rainbowPosition -gt 10000) { 
                $rainbowPosition = 0 
            }
        }
        
        # Pause between frames
        Start-Sleep -Milliseconds $delay
    }
}
finally {
    # Restore console settings
    $host.UI.RawUI.BackgroundColor = $originalBackgroundColor
    $host.UI.RawUI.CursorSize = $originalCursorSize
    $host.UI.RawUI.WindowTitle = $originalWindowTitle
    Clear-Host
    Write-Host "Matrix animation terminated." -ForegroundColor ($Rainbow ? "White" : $Color)
}
