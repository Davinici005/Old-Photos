
# Define chunk size in bytes (e.g., 200MB)
$chunkSizeBytes = 200 * 1024 * 1024
$currentBatchSize = 0
$fileCount = 0

# Get all files recursively, excluding .git folder and videos
$files = Get-ChildItem -Recurse -File | Where-Object { 
    $_.FullName -notmatch "\\.git\\" -and 
    $_.Extension -notmatch "^\.(mp4|mov|avi|mkv|webm)$" 
}

foreach ($file in $files) {
    try {
        $fileSize = $file.Length
        
        # Add the file (handle spaces in path)
        git add "$($file.FullName)"
        
        # Check if file was added/staged (git add returns 0 usually)
        if ($LASTEXITCODE -eq 0) {
            $currentBatchSize += $fileSize
            $fileCount++
        }

        # If batch size exceeds limit, commit and push
        if ($currentBatchSize -ge $chunkSizeBytes) {
            Write-Host "Batch limit reached ($([math]::Round($currentBatchSize / 1MB, 2)) MB). Committing..."
            
            git commit -m "Add batch of photos ($fileCount files)"
            
            # Should push if commit succeeded OR if we have pending commits from a resume
            # But checking pending commits is tricky. We'll rely on commit success first.
            
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
                # Reset counters only after successful push
                $currentBatchSize = 0
                $fileCount = 0
            } else {
                # Commit failed (empty?). We might still be accumulating size from tracked files.
                # Just reset counters to allow next chunk to form.
                # (Ideally we'd push here if we had backlog, but explicit push at start handles that).
                Write-Warning "Nothing to commit in this batch (files likely already committed)."
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
