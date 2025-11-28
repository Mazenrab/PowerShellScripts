# Export IIS configuration
function Export-IISConfiguration {
    param([string]$ExportPath = "C:\IISExport")
    
    # Create export directory
    New-Item -ItemType Directory -Path $ExportPath -Force
    
    # Export sites
    Get-IISSite | ForEach-Object {
        $siteName = $_.Name
        $siteConfig = @{
            Name = $_.Name
            Id = $_.Id
            State = $_.State
            Bindings = $_.Bindings
            Applications = $_.Applications
        }
        $siteConfig | ConvertTo-Json -Depth 5 | Out-File "$ExportPath\site_$($siteName).json"
    }
    
    # Export application pools
    Get-IISAppPool | ForEach-Object {
        $poolConfig = @{
            Name = $_.Name
            State = $_.State
            ManagedRuntimeVersion = $_.ManagedRuntimeVersion
            Enable32BitAppOnWin64 = $_.Enable32BitAppOnWin64
            ProcessModel = $_.ProcessModel
            Recycling = $_.Recycling
        }
        $poolConfig | ConvertTo-Json -Depth 5 | Out-File "$ExportPath\apppool_$($_.Name).json"
    }
    
    # Backup applicationHost.config
    Copy-Item "$env:WINDIR\System32\inetsrv\config\applicationHost.config" $ExportPath
}

# Import IIS configuration
function Import-IISConfiguration {
    param([string]$ImportPath = "C:\IISExport")
    
    # Import application pools first
    Get-ChildItem "$ImportPath\apppool_*.json" | ForEach-Object {
        $poolConfig = Get-Content $_ | ConvertFrom-Json
        
        # Check if app pool exists
        if (-not (Get-IISAppPool -Name $poolConfig.Name -ErrorAction SilentlyContinue)) {
            New-IISAppPool -Name $poolConfig.Name
        }
        
        # Configure app pool settings
        $appPool = Get-IISAppPool -Name $poolConfig.Name
        $appPool.ManagedRuntimeVersion = $poolConfig.ManagedRuntimeVersion
        $appPool.Enable32BitAppOnWin64 = $poolConfig.Enable32BitAppOnWin64
        $appPool | Set-Item
    }
    
    # Import sites
    Get-ChildItem "$ImportPath\site_*.json" | ForEach-Object {
        $siteConfig = Get-Content $_ | ConvertFrom-Json
        
        # Create site
        if (-not (Get-IISSite -Name $siteConfig.Name -ErrorAction SilentlyContinue)) {
            New-IISSite -Name $siteConfig.Name -BindingInformation $siteConfig.Bindings[0].BindingInformation -PhysicalPath "C:\inetpub\wwwroot"
        }
    }
}