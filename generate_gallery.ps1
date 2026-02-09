
$rootPath = Get-Location
$folders = Get-ChildItem -Path $rootPath.Path -Directory -Exclude ".git"

# Root README content
$rootReadmeContent = "# Old Photos Collection`n`n"
$rootReadmeContent += "Collection of photos from 2023-2024.`n`n"

foreach ($folder in $folders) {
    # Get all subfolders (recursive gallery)
    $subFolders = Get-ChildItem -Path $folder.FullName -Recurse -Directory
    # Include the folder itself
    $allFolders = @($folder) + $subFolders

    foreach ($f in $allFolders) {
        $images = Get-ChildItem -Path $f.FullName -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|gif|webp)$' }
        # Videos skipped as per user request
        $videos = @()
        
        if ($images.Count -eq 0 -and $videos.Count -eq 0) {
            continue
        }

        # Calculate relative path for the root README
        $relativeFolderPath = $f.FullName.Replace($rootPath.Path, "").TrimStart("\").Replace("\", "/")
        $urlSafePath = $relativeFolderPath.Replace(" ", "%20")
        $imgCount = $images.Count
        $vidCount = $videos.Count
        
        $line = "- [**$relativeFolderPath**]($urlSafePath/README.md) ($imgCount Photos)`n"
        $rootReadmeContent += $line

        $readmePath = Join-Path $f.FullName "README.md"
        $folderName = $f.Name
        $content = "# $folderName`n`n"
        $content += "---`n`n"
        
        if ($images.Count -gt 0) {
            $content += "## Photos`n`n"
            $content += "<div align='center'>`n`n"
            foreach ($img in $images) {
                $name = $img.Name
                $urlEncodedName = $name.Replace(" ", "%20")
                $content += "<a href='$urlEncodedName'><img src='$urlEncodedName' width='400' alt='$name' /></a>`n"
            }
            $content += "</div>`n`n"
        }

        # Calculate back link dynamically based on depth
        $depth = $relativeFolderPath.Split('/').Count
        $backLink = "../" * $depth + "README.md"
        $content += "---`n[Back to Home]($backLink)`n"

        Set-Content -Path $readmePath -Value $content -Encoding UTF8
        Write-Host "Updated gallery in: $relativeFolderPath"
    }
}

Set-Content -Path (Join-Path $rootPath.Path "README.md") -Value $rootReadmeContent -Encoding UTF8
Write-Host "Root README.md updated."
