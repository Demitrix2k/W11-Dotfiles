# Define the target executable and its location
$executable = "whkd.exe"
$executablePath = "C:\Program Files\whkd\bin\whkd.exe" 

# Function to kill the process
function Kill-Process {
    try {
        # Check if the process is already running
        $process = Get-Process -Name $executable -ErrorAction SilentlyContinue
        if ($process) {
            Get-Process -Name $executable | Stop-Process
            Write-Host "Process '$executable' has been killed."
        } else {
            Write-Warning "Process '$executable' is not running."
        }
    } catch {
        Write-Warning "Error occurred while killing the process."
    }
}

# Function to start the process
function Start-Process {
    Start-Process -FilePath $executablePath
    Write-Host "Process '$executable' has been started."
}

# Main loop
while ($true) {
    # Prompt the user
    Write-Host "Press 'k' to kill $executable."
    $choice = Read-Host -Prompt "Enter your choice:"

    # Check user input
    if ($choice -eq "k") {
        # Kill the process
        Kill-Process
    } 

    # Prompt the user
    Write-Host "Press 'y' to start $executable."
    $choice = Read-Host -Prompt "Enter your choice:"

    # Check user input
    if ($choice -eq "y") {
        # Start the process
        Start-Process
    } 
}

Write-Host "Script completed."