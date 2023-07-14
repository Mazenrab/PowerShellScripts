function Execute-HTTPPostCommand() {
    param(
        [string] $url,
        [string] $bearerToken
    )
    
    $webRequest = [System.Net.WebRequest]::Create($url)
    $webRequest.ContentType = "text/html"
    $PostStr = [System.Text.Encoding]::Default.GetBytes("")
    $webrequest.ContentLength = $PostStr.Length
    $webRequest.Headers["Authorization"] = "Bearer " + $bearerToken
    $webRequest.Method = "POST"

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($PostStr, 0, $PostStr.length)
    $requestStream.Close()

    [System.Net.WebResponse] $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs;
    [string] $results = $sr.ReadToEnd();

    return $results;
}

function Execute-TeamCityBackup() {
    param(
        [string] $server,
        [string] $bearerToken,
        [string] $addTimestamp,
        [string] $includeConfigs,
        [string] $includeDatabase,
        [string] $includeBuildLogs,
        [string] $includePersonalChanges,
        [string] $fileName,
        [string] $backupDir,
        [string] $backupsToKeep
    )
    $TeamCityURL = [System.String]::Format("{0}/app/rest/server/backup?addTimestamp={1}&includeConfigs={2}&includeDatabase={3}&includeBuildLogs={4}&includePersonalChanges={5}&fileName={6}",
                                            $server,
                                            $addTimestamp,
                                            $includeConfigs,
                                            $includeDatabase,
                                            $includeBuildLogs,
                                            $includePersonalChanges,
                                            $fileName);

    $bckpFilename = Execute-HTTPPostCommand $TeamCityURL $bearerToken

    Write-Host $bckpFilename

    $bckpFullpath = $bckpFullpath = Join-Path -Path c:\ProgramData\JetBrains\TeamCity\backup -ChildPath $bckpFilename


    #sleep, then check again
    Start-Sleep -s 30

    While (1 -eq 1) {
        Write-Host "Checking file..."
        IF (Test-Path $bckpFullpath) {
            #file exists. break loop
            Write-Host "File found."
            break
            
        }
        Write-Host "File not found. Sleep..."
        #sleep for 60 seconds, then check again
        Start-Sleep -s 60
    }


    Move-Item -Path $bckpFullpath -Destination $backupDir -Force

    dir $backupDir -Recurse -Include *.zip | Sort-Object LastWriteTime -Descending | Select-Object -Skip $backupsToKeep | Remove-Item -Force
}

$server = "http://YOUR_SERVER"
$bearerToken = "TeamCity bearer token"
$addTimestamp = $true
$includeConfigs = $true
$includeDatabase = $true
$includeBuildLogs = $true
$includePersonalChanges = $true
$fileName = "bckp"
$backupDir = "YOUR BACKUP DIR PATH"
$backupsToKeep = 3

Execute-TeamCityBackup $server $bearerToken $addTimestamp $includeConfigs $includeDatabase $includeBuildLogs $includePersonalChanges $fileName $backupDir $backupsToKeep