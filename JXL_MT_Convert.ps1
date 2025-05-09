#Point $InputPath to the folder your images are stored in.
$InputPath   = "D:\imagestoconvert"
#Download cjxl.exe from https://github.com/libjxl/libjxl/releases/tag/v0.11.1, and extract the archive for your OS to the path you set as the variable below.
#i.e. change "D:\apps\jxl\cjxl.exe" to the path you choose for the extract.
$CjxlPath    = "D:\apps\jxl\cjxl.exe"
#Set max threads to speed up the process. For best results recommend you logical thread count -2, so if you have an 8 core processor with two logical threads each, that's 16 threads. You'd want to set it to 14.
#Set max threads lower if you plan to use your PC for more than simple web browsing at the same time.
$MaxThreads  = 14
$VerboseOutput = $true

# COLLECT FILES
#Change which of the two lines below is commented out to include or exclude png files from compression. This only reduces quality for jpg & jpeg, but compresses both jpeg/jpg and png.
#$files = Get-ChildItem -Path $InputPath -Recurse -Include *.jpg, *.jpeg -File
$files = Get-ChildItem -Path $InputPath -Recurse -Include *.jpg, *.jpeg, *.png -File
$total = $files.Count
$counter = 0

# RUNSPACE POOL SETUP
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $host)
$runspacePool.Open()

# Use a .NET generic list to track runspaces
$runspaces = New-Object 'System.Collections.Generic.List[Object]'

foreach ($file in $files) {
    $filePath = $file.FullName
    $outputPath = Join-Path $file.DirectoryName ($file.BaseName + ".jxl")
    $isPng = $file.Extension -match '\.png$'

    $ps = [powershell]::Create()
    $ps.AddScript({
        param($filePath, $outputPath, $isPng, $cjxlPath, $verbose)

        $quotedFile = '"' + $filePath + '"'
        $quotedOutput = '"' + $outputPath + '"'

        $args = @($quotedFile, $quotedOutput)
        if ($isPng) {
#PNG's are lossless so the quality should always be 100. Do not change this. Converting to jxl witll still compress png files to save space.		
            $args += "--quality 100"
        } else {
#Change the number 90 to your preferred quality. 90 is recommend. The lower the number the more errors and failed conversions will occur. Even 80 is often too low, with no visul difference between 80 and 90. Setting this to 100 will just compress the jpg or jpeg, witch saves less spach than reducing quality too.
            $args += "--quality 90"
            $args += "--lossless_jpeg=0"
        }

        if ($verbose) {
            Write-Host "▶ Compressing: $filePath"
        }

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $cjxlPath
        $startInfo.Arguments = $args -join ' '
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $process.Start() | Out-Null
        $stdOut = $process.StandardOutput.ReadToEnd()
        $stdErr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($process.ExitCode -eq 0 -and (Test-Path $outputPath)) {
            Remove-Item $filePath -Force
            if ($verbose) {
                Write-Host "✔ Converted: $filePath"
            }
        } else {
            Write-Host "❌ Failed: $filePath"
            if ($stdErr) {
                Write-Host "stderr: $stdErr" -ForegroundColor Yellow
            }
        }
    }) | Out-Null

    $ps.AddArgument($filePath)       | Out-Null
    $ps.AddArgument($outputPath)     | Out-Null
    $ps.AddArgument($isPng)          | Out-Null
    $ps.AddArgument($CjxlPath)       | Out-Null
    $ps.AddArgument($VerboseOutput) | Out-Null

    $ps.RunspacePool = $runspacePool
    $asyncResult = $ps.BeginInvoke()
    [void]$runspaces.Add([PSCustomObject]@{ Pipe = $ps; Status = $asyncResult })
}

# Wait for threads to complete
while ($runspaces.Count -gt 0) {
    $completed = @()

    foreach ($r in $runspaces) {
        if ($r.Status.IsCompleted) {
            $r.Pipe.EndInvoke($r.Status)
            $r.Pipe.Dispose()
            $completed += $r

            $counter++
            Write-Progress -Activity "Compressing images" -Status "$counter of $total" -PercentComplete (($counter / $total) * 100)
        }
    }

    foreach ($r in $completed) {
        $runspaces.Remove($r) | Out-Null
    }

    Start-Sleep -Milliseconds 100
}

# Cleanup
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "`n✅ Done. Compressed $counter images." -ForegroundColor Cyan
