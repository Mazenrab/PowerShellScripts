$LogPath = "c:\inetpub\logs\LogFiles"
$maxDaystoKeep = -31
$outputPath = "c:\utils\iis\cleanup-iis-logs.log" 
  
$itemsToDelete = dir $LogPath -Recurse -Include *.log | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays($maxDaystoKeep)}

if ($itemsToDelete.Count -gt 0){ 
    ForEach ($item in $itemsToDelete){ 
        Remove-Item $item -Force
    } 
} 
ELSE{ 
    "No items to be deleted today $($(Get-Date).DateTime)"  | Add-Content $outputPath 
    } 
   
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..." 