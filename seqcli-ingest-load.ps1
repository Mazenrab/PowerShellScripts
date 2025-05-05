$logFolders = Get-ChildItem -Path e:\inetpub\s-03\LogFiles\ -Filter "*W3SVC*" -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
$seqli = "c:\Program Files\Seq\Client\seqcli.exe"

if ($logFolders.Count -gt 0){ 
    ForEach ($item in $logFolders){         
        echo $item.FullName
        
        $str = 'ingest -i ' + $item.FullName + '\u_ex*.log --invalid-data=ignore -x "{@t:w3cdt} {SiteName} {ComputerName} {ServerIP} {RequestMethod} {RequestPath} {Query} {ServerPort:nat} {Username} {ClientIP} {Version} {UserAgent} {Referer} {Host} {StatusCode:nat} {Substatus:nat} {Win32Status:nat} {ScBytes:nat} {Bytes:nat} {Elapsed:nat}{:n}" -m "IIS {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed} ms"'
        
        Start-Process -FilePath $seqli -ArgumentList $str -Wait
    } 
} 
