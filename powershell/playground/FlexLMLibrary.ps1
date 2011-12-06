Function Get-FlexLMStatus
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Get-FlexLMStatus
            Created by   : jspatton
            Date Coded   : 11/21/2011 13:02:14
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/Untitled2#Get-FlexLMStatus
    #>
    [cmdletBinding()]
    Param
        (
            [string]$LicenseServer
        )
    Begin
    {
        Write-Verbose "Check to see if LMTools are installed."
        try 
        {
            $LicenseStatus = lmutil lmstat -c $LicenseServer
            $LicenseStatus = $LicenseStatus -match '(\w:)'
            }
        catch
        {
            $Error[0].Exception.Message
            }
        }
    Process
    {   
        foreach ($line in $LicenseStatus)
        {
            if ($line.trim() |Select-String -Pattern "License file")
            {
                $LicenseFile = $line.Trim()
                $LicenseFile = $LicenseFile.Substring(19,$LicenseFile.Length-19)
                $LicenseFile = ($LicenseFile.Substring(($LicenseFile.IndexOfAny(":")+1),$LicenseFile.Length-($LicenseFile.IndexOfAny(":")+2))).Trim()
                }
            if ($line.Trim() |Select-String -Pattern " license server ")
            {
                $LicenseServerStatus = $line.Trim()
                $LicenseServerStatus = $LicenseServerStatus.Substring($LicenseServerStatus.IndexOfAny(":")+1,$LicenseServerStatus.Length-($LicenseServerStatus.IndexOfAny(":")+1)).Trim()
                }
            }
        }
    End
    {
        }
}

$Listening = netstat -an |Select-String -Pattern Listening
$Report = @()
foreach ($line in $Listening)
{
    [string]$thisline = $line
    $csv = (($thisline.Trim() -replace "\s *",",") -replace ":",",").Split(",")
    $LineItem = New-Object -TypeName PSObject -Property @{
        Protocol = $csv[0]
        LocalAddress = $csv[1]
        LocalPort = $csv[2]
        ForeignAddress = $csv[3]
        ForeignPort = $csv[4]
        State = $csv[5]
        }
    $Report += $LineItem
    }
$PortReport = @()
foreach ($port in ($Report |Select-Object -Property LocalPort))
{
    cmd /c echo lmstat -c "$($port.LocalPort)@license1"
    $Scan = cmd /c lmutil lmstat -c "$($port.LocalPort)@license1"
    $PortSCan = New-Object -TypeName PSObject -Property @{
        Report = $Scan
        Port = $Port.LocalPort
        Server = 'license1'
        }
    $PortReport += $PortSCan
    }
Function Get-FlexLMLicenses
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Get-FlexLMLicenses
            Created by   : jspatton
            Date Coded   : 12/06/2011 13:29:34
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/FlexLMLibrary#Get-FlexLMLicenses
    #>
    [CmdletBinding()]
    Param
        (
            $Ports,
            $Servers
        )
    Begin
    {
        $FlexLMLicenses = @()
        try
        {
            $Expression = '(&lmutil)'
            $null = Invoke-Expression $Expression -ErrorAction Stop
            }
        catch [System.Management.Automation.CommandNotFoundException]
        {
            Write-Host "LMUTIL not found. Please visit"
            Write-Host "http://www.globes.com/support/fnp_utilities_download.htm"
            Write-Host
            Write-Host $Error[0].Exception.Message
            }
        }
    Process
    {
        Foreach ($Port in $Ports)
        {
            Write-Verbose $port
            Write-Host $port
            Foreach ($Server in $Servers)
            {
                Write-Verbose $server
                [string]$LicenseFile = (&lmutil lmstat -c "$($Port)@$($server)") |Select-String 'License file' -CaseSensitive
                Write-Verbose $LicenseFile
                if ($LicenseFile -ne "")
                {
                    $LicenseFile = $LicenseFile.Substring(($LicenseFile.IndexOfAny(":\")+2),($LicenseFile.Length)-$LicenseFile.IndexOfAny(":\")-3)
                    $License = Get-Content $LicenseFile -ErrorAction SilentlyContinue
                    [string]$ServerInfo = Get-Content $LicenseFile -ErrorAction SilentlyContinue|Select-String '^SERVER' -CaseSensitive
                    $ServerData = $ServerInfo.Split(" ")
                    if ($ServerData.Count -eq 4)
                    {
                        $ServerName = $ServerData[1]
                        $ID = $ServerData[2]
                        $ListeningPort = $ServerData[3]
                        }
                    if ($ServerData.Count -eq 3)
                    {
                        $ServerName = $ServerData[1]
                        $ID = $ServerData[2]
                        }
                    [string]$DaemonInfo = Get-Content $LicenseFile -ErrorAction SilentlyContinue|Select-String '^DAEMON' -CaseSensitive
                    if ($DaemonInfo -ne "")
                    {
                        $VendorData = $DaemonInfo.Substring($DaemonInfo.IndexOfAny(" "),($DaemonInfo.Length-$DaemonInfo.IndexOfAny(" "))).Trim().Replace("`"","")
                        if ($VendorData.IndexOfAny(" ") -gt 0)
                        {
                            $VendorDaemon = $VendorData.Substring(0,$VendorData.IndexOfAny(" "))
                            $Daemonpath = $VendorData.Substring($VendorData.IndexOfAny(" "),$VendorData.Length - $VendorData.IndexOfAny(" ")).trim()
                            }
                        else
                        {
                            $VendorDaemon = $VendorData
                            }
                        }
                    [string]$VendorInfo = Get-Content $LicenseFile -ErrorAction SilentlyContinue|Select-String '^VENDOR' -CaseSensitive
                    $VendorData = $VendorInfo.Split(" ")
                    if ($VendorData.Count -eq 3)
                    {
                        $Vendor = $VendorData[1]
                        $VendorPort = $VendorData[2]
                        }
                    if ($VendorData.Count -eq 2)
                    {
                        $Vendor = $VendorData[1]
                        }
                    $FlexLMLicense = New-Object -TypeName PSObject -Property @{
                        LicensePort = $ListeningPort
                        LicenseServer = $ServerName
                        HostID = $ID
                        LicenseFile = $LicenseFile
                        VendorDaemon = $VendorDaemon
                        DaemonPath = $Daemonpath
                        Vendor = $Vendor
                        VendorPort = $VendorPort
                        }
                    $FlexLMLicenses += $FlexLMLicense
                    }
                }
            }
        }
    End
    {
        Return $FlexLMLicenses
        }
    }