foreach($line in Get-Content c:\temp\filelist.txt) {
    echo $line

    $content = Get-Content $line
    Set-Content -Path $line -Value $content -Encoding UTF8
}