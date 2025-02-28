# Get the directory containing the WebM files
$webmDir = Get-Location

# Create the output directory (in the same directory as the WebMs)
$outputDir = Join-Path $webmDir "Converted MP4s"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory $outputDir
}

# Get all WebM files in the directory
$webmFiles = Get-ChildItem -Path $webmDir -Filter "*.webm"

# Array to store failed file names
$failedConversions = @()

# Loop through each WebM file
foreach ($webmFile in $webmFiles) {
    # Construct the output file path
    $outputPath = Join-Path $outputDir "$($webmFile.BaseName).mp4"

    # Run FFmpeg (with error handling and realtime output)
    #ffmpeg -i $webmFile.FullName -c:v libx264 -crf 23 -preset medium -c:a copy $outputPath 2>&1 #| Out-File -FilePath "ffmpeg_errors.txt" -Append  # Commented out logging
	ffmpeg -i $webmFile.FullName -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k $outputPath 2>&1 #| Out-File -FilePath "ffmpeg_errors.txt" -Append  # Commented out logging


    if ($LASTEXITCODE -ne 0) {
        Write-Warning "FFmpeg returned an error for $($webmFile.FullName)"
        $failedConversions += $webmFile.FullName # Add failed file to array
    } else {
      Write-Host "Converted: $($webmFile.FullName) to $($webmFile.BaseName).mp4" # Success message
    }
}

# Output failed conversions (if any)
if ($failedConversions) {
    Write-Host ""  # Add a blank line for better readability
    Write-Error "The following files failed to convert:"
    foreach ($failedFile in $failedConversions) {
        Write-Host "- $failedFile"
    }
}

Write-Host "Conversion complete. MP4 files are in: $outputDir"