$username = $args[0]
$processes = $args[1]

foreach ($process in $processes.Split(','))
{
    $p = $process.Trim();

    try
    {
    Get-Process $p -IncludeUserName | Where UserName -Match $username | ForEach-Object {Stop-Process -InputObject $_ -Force}
    }
    catch
    {
    $ErrorMessage = $_.Exception.Message
    Write-Output $ErrorMessage
    }    
}