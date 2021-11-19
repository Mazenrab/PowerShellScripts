<#
    Скрипт архивирования логов и ротации архивов для PASOE

    Настраивается на удаление файлов из директории ArchivePath старше DaysToStoreInLogs от Today совпадающих по шаблону с AgentLogPattern,
    SessionLogPattern, LocalhostAccessPattern и ВСЕХ директорий.

    В процессе работы скрипта проверяется и создается TempPath в который копируются файлы перед сжатием. 
    
    Для сжатия используется 7zip расположеный по пути 7zipPath. 

    !!! Внимание !!!
    После сжатия архив расположен в ArchivePath и все zip-файлы старше DaysToStoreInArchive от Today удаляются.

#>
$LogPath = "d:\pasoe\coord\logs"
$ArchivePath = "d:\logs\archive\pasoe\coord"
$TempPath = "d:\logs\archive\pasoe\coord\temp"
$AgentLogPattern = "coord.agent.*.log"
$SessionLogPattern = "coord.*.log"
$LocalhostAccessPattern = "localhost-access.*.log"
$DaysToStoreInLogs = 1
$DaysToStoreInArchive = 7
$Today = (Get-Date).Date
$MinDateToStoreInLogs = $Today.AddDays(-$DaysToStoreInLogs)
$MinDateToStoreInArchive = $Today.AddDays(-$DaysToStoreInArchive)
$7zipPath = "c:\utils\7z\7za.exe"
<# $ArchiveCompressionLevel = 0 <# 0 (none), 1, 3, 5, 7, 9 (max) #> #>

Set-Alias 7zip $7zipPath

function GetFileNameDate([string] $filename)
{
    $default = [datetime]::MinValue
    $d = New-Object DateTime
    $s = $filename.Split('.')[-2]
    
    $parsed = [datetime]::TryParseExact($s, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimestyles]::None, [ref]$d)

    if($parsed) 
    {
        $d
    }
    else
    {
        $default
    }
}

function MoveOldFilesToTemp([string] $pattern)
{
    $files = Get-Childitem $LogPath -Filter $pattern

    ForEach($file in $files)
    {
	    $x = GetFileNameDate($file.Name)
        if( $x -lt $MinDateToStoreInLogs) 
        {
            Move-Item -Path $file.FullName -Destination $TempPath -Force
        }
    }
}

Write-Host "Start cleanup logs..." -ForegroundColor Green

Write-Host "Checking archiver path $7zipPath ..." -ForegroundColor Green
if (-not (Test-Path -Path $7zipPath -PathType Leaf)) 
{
    Write-Host "Archiver path $7zipPath not found!" -ForegroundColor Red
    throw "7 zip file '$7zipPath' not found"
}

Write-Host "Checking temp dir..." -ForegroundColor Green
If(!(Test-Path $TempPath))
{
      Write-Host "Create temp dir $TempPath ..." -ForegroundColor Yellow
      New-Item -ItemType Directory -Force -Path $TempPath | Out-Null
}

Write-Host "Move any dirs from $LogPath ..." -ForegroundColor Yellow
Get-ChildItem $LogPath -Attributes D | Move-Item -Destination $TempPath -Force


<# Move old files to temp dir #>
Write-Host "Move old files from $LogPath by pattern '$AgentLogPattern'..." -ForegroundColor Yellow
MoveOldFilesToTemp($AgentLogPattern)

Write-Host "Move old files from $LogPath by pattern '$SessionLogPattern'..." -ForegroundColor Yellow
MoveOldFilesToTemp($SessionLogPattern)

Write-Host "Move old files from $LogPath by pattern '$LocalhostAccessPattern'..." -ForegroundColor Yellow
MoveOldFilesToTemp($LocalhostAccessPattern)


<# Create archive #>
$archiveName = $Today.ToString("yyyy-MM-dd") + ".zip"
$source = Join-Path -Path $TempPath -ChildPath "*"
$target = Join-Path -Path $ArchivePath -ChildPath $archiveName

Write-Host "Archiving $source to $target ..." -ForegroundColor Yellow
7zip a -tzip -mx=7 $target $source

Write-Host "Remove temp dir $TempPath ..." -ForegroundColor Yellow
Remove-Item -Path $TempPath -Recurse -Force

Write-Host "Removing archive files older than $MinDateToStoreInArchive ..." -ForegroundColor Yellow
Get-ChildItem $ArchivePath -Filter *.zip | Where-Object {$_.LastWriteTime -lt $MinDateToStoreInArchive} | Remove-Item -Force

Write-Host "Clean up logs finished" -ForegroundColor Green