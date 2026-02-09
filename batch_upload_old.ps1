
# Fixed and Cleaner Batch Script
$chunkSizeBytes = 200 * 1024 * 1024
$currentBatchSize = 0
$fileCount = 0

# Explicitly exclude video extensions using -Include/-Exclude logic or Where-Object
# Also exclude .git folder
$files = Get-ChildItem -Recurse -File | Where-Object { 
    $_.FullName -notmatch "\\.git\\" -and 
    $_.Extension -notin @(".mp4", ".mov", ".avi", ".mkv", ".webm", ".MOV", ".MP4")
}

foreach ($file in $files) {
    try {
        # Check against gitignore before adding? 
        # Easier to just try add. If ignored, git returns 1, we skip.
        # But we filtered videos above, so it should be clean.
        
        # Suppress git add output errors/warnings to keep console clean (2>$null)
        git add "$($file.FullName)" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $currentBatchSize += $file.Length
            $fileCount++
        }

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
                $currentBatchSize = 0
                $fileCount = 0
            } else {
                # Commit failed (files likely already committed). Reset counters.
                $currentBatchSize = 0
                $fileCount = 0
            }
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
