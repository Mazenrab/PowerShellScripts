<#
    Скрипт для перемещения файлов из плоской структуры вида:
    0000000001
        1.dat
        2.dat
        ...
        n.dat
    ...
    000000000n
    в структуру вида:
    000
        000
            001
            ...
            999
        001
            001
            ...
            999
        ...
        999
            001
            ...
            999
    ...
    999...
#>

$log = "c:\temp\move.log"
$oldStroePath = "d:\old_folder"
$newStorePath = "d:\new_folder"

Function Get-DirNameChunks {

    param (
        [string]$DirName
    )

    if($DirName.Length -ne 9)
    {
        throw "DirName length is wrong. Must be 9."
    }

    $list = [System.Collections.Generic.List[string]]::new()
    $list.Add($DirName.Substring(0,3))
    $list.Add($DirName.Substring(3,3))
    $list.Add($DirName.Substring(6,3))

    $list
}

Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If($logfile) 
    {
        Add-Content $logfile -Value $Line
    }

    Write-Output $Line
}

Function Add-Log
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
    [string]
    $Message
    )
    
    Write-Log -logfile $log  -Message $Message
}

Function Add-Error
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
    [string]
    $Message
    )
    
    Write-Log -Level ERROR -logfile $log -Message $Message
}

Add-Log -Message "Read dir structure..."

$dirs = Get-ChildItem -Path $oldStroePath -Directory

Add-Log -Message "Process directories..."

foreach($dir in $dirs)
{
    $dirName = $dir.Name

    if($dirName.Length -ne 9)
    {
        $message = $dirName + " is not acceptible format"
        Add-Error -Message $message
        continue
    }

    $orderId = -1
    try
    {
        $orderId = [int]$dirName
        if($orderId -ge 1000000000)
        {
            Add-Error -Message "Format exceded"
            break
        }

        $chunks = Get-DirNameChunks -DirName $dirName
        $newDirName = $newStorePath
        
        foreach($chunk in $chunks)
        {
            
            $newDirName = Join-Path -Path $newDirName -ChildPath $chunk
            
            if(!(Test-Path -Path $newDirName))
            {
                New-Item -ItemType Directory -Path $newDirName -Force
                $message = "Create " + $newDirName
                Add-Log -Message $message
            }
        }

        # Write-Output $dirName $newDirName
        
        Get-ChildItem -Path $dir.FullName -File | Move-Item -Destination $newDirName -Force
        Remove-Item -Path $dir.FullName -Force -Recurse
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        Add-Error -Message $errorMessage
        continue
    }
}

Add-Log -Message "Process finished."


