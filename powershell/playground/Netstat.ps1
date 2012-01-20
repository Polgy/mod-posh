$netstat = netstat -a -n -o | where-object { $_ -match "(UDP|TCP)" }
[regex]$regexTCP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+((?<Raddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<RAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<RPort>\d+)\s+(?<State>\w+)\s+(?<PID>\d+$)'

[regex]$regexUDP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+(?<RAddress>\*)\:(?<RPort>\*)\s+(?<PID>\d+)'
$Report = @()

foreach ($Line in $Netstat)
{
    switch -regex ($Line.Trim())
    {
        $RegexTCP
        {
            $MyProtocol = $Matches.Protocol
            $MyLocalAddress = $Matches.LAddress
            $MyLocalPort = $Matches.LPort
            $MyRemoteAddress = $Matches.Raddress
            $MyRemotePort = $Matches.RPort
            $MyState = $Matches.State
            $MyPID = $Matches.PID
            $MyProcessName = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).ProcessName
            $MyProcessPath = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).Path
            $MyUser = (Get-WmiObject -Class Win32_Process -Filter ("ProcessId = "+$Matches.PID)).GetOwner().User
        }
        $RegexUDP
        {
            $MyProtocol = $Matches.Protocol
            $MyLocalAddress = $Matches.LAddress
            $MyLocalPort = $Matches.LPort
            $MyRemoteAddress = $Matches.Raddress
            $MyRemotePort = $Matches.RPort
            $MyState = $Matches.State
            $MyPID = $Matches.PID
            $MyProcessName = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).ProcessName
            $MyProcessPath = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).Path
            $MyUser = (Get-WmiObject -Class Win32_Process -Filter ("ProcessId = "+$Matches.PID)).GetOwner().User
        }
    }
    $LineItem = New-Object -TypeName PSobject -Property @{
        Protocol = $MyProtocol
        LocalAddress = $MyLocalAddress
        LocalPort = $MyLocalPort
        RemoteAddress = $MyRemoteAddress
        RemotePort = $MyRemotePort
        State = $MyState
        PID = $MyPID
        ProcessName = $MyProcessName
        ProcessPath = $MyProcessPath
        User = $MyUser
    }
    $Report += $LineItem
}
$Report

<#
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
#>