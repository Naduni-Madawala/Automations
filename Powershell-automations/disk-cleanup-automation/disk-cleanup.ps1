# ===============================
# Automated Disk Cleanup & Report
# Author: Naduni Madawala
# ===============================

$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = "$BasePath\..\logs\cleanup.log"
$ReportPath = "$BasePath\..\reports\disk-report.txt"
$DaysOld = 30

function Write-Log {
    param($Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" |
        Out-File -Append $LogPath
}

Write-Log "Script started"

# Disk usage
"Disk Usage Report - $(Get-Date)" | Out-File $ReportPath
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $used = [math]::Round($_.Used / 1GB, 2)
    $free = [math]::Round($_.Free / 1GB, 2)
    "Drive $($_.Name): Used $used GB | Free $free GB" |
        Out-File -Append $ReportPath
}

# Top folders
"`nTop 5 largest folders on C:\" | Out-File -Append $ReportPath

Get-ChildItem C:\ -Directory -ErrorAction SilentlyContinue |
ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
    [PSCustomObject]@{
        Folder = $_.FullName
        SizeGB = [math]::Round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending |
Select-Object -First 5 |
Format-Table -AutoSize |
Out-String | Out-File -Append $ReportPath

# Cleanup temp
Write-Log "Cleaning temp files"
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Cleanup old logs
Write-Log "Cleaning old log files"
$LogDirectories = @(
    "C:\Windows\Logs",
    "C:\ProgramData",
    "$env:TEMP"
)

foreach ($dir in $LogDirectories) {
    if (Test-Path $dir) {
        Get-ChildItem $dir -Recurse -Include *.log -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) } |
        Remove-Item -WhatIf -Force -ErrorAction SilentlyContinue
    }
}


Write-Log "Script completed successfully"
