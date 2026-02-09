
# Define chunk size in bytes (e.g., 200MB)
$chunkSizeBytes = 200 * 1024 * 1024
$currentBatchSize = 0
$fileCount = 0

# Get all files recursively, excluding .git folder
$files = Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch "\\.git\\" }

foreach ($file in $files) {
    try {
        # Check if file needs to be added (simplified - just add everything, git handles the rest efficiently)
        # For a more robust check we could parse git status, but for initial push this is fine.
        
        $fileSize = $file.Length
        
        # Add the file
        git add $file.FullName
        
        if ($LASTEXITCODE -eq 0) {
            $currentBatchSize += $fileSize
            $fileCount++
            
            # Write-Host "Added: $($file.Name) ($([math]::Round($fileSize / 1MB, 2)) MB)"
        }

        # If batch size exceeds limit, commit and push
        if ($currentBatchSize -ge $chunkSizeBytes) {
            Write-Host "Batch limit reached ($([math]::Round($currentBatchSize / 1MB, 2)) MB). Committing..."
            
            git commit -m "Add batch of photos ($fileCount files)"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Pushing batch..."
                git push origin main
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Push failed. Retrying in 5 seconds..."
                    Start-Sleep -Seconds 5
                    git push origin main
                    if ($LASTEXITCODE -ne 0) {
                         Write-Error "Push failed again. Exiting."
                         exit 1
                    }
                }
                Write-Host "Batch pushed successfully."
            } else {
                Write-Warning "Nothing to commit in this batch."
            }
            
            # Reset counters
            $currentBatchSize = 0
            $fileCount = 0
        }
    }
    catch {
        Write-Warning "Failed to process $($file.FullName): $_"
    }
}

# Process remaining files
if ($currentBatchSize -gt 0) {
    Write-Host "Committing remaining files ($([math]::Round($currentBatchSize / 1MB, 2)) MB)..."
    git commit -m "Add remaining photos"
    if ($LASTEXITCODE -eq 0) {
        git push origin main
    }
}

Write-Host "All files processed."
