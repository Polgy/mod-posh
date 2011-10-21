<#
    .SYNOPSIS
        Get the MAC address of computers that have been denied a lease.
    .DESCRIPTION
        This script processes the 'Microsoft-Windows-Dhcp-Server/FilterNotifications' log
        and returns an XML file that contains the MAC of the machine that was denied.
        
        This script is part of an event trigger, and is triggered on the following two events 
        200097 and 20100. Both of these events are a DHCP deny event, where the MAC listed
        is not in the allowed list of MAC addresses.
    .PARAMETER EventID
        The EventID to pull data from, this will be either 20097 or 20100
    .EXAMPLE
        Get-DHCPDenies -EventID 20097 -LogPath 'C:\Logs'
        
        Description
        -----------
        There is no visible output, an XML file is created in the LogPath 
        directory.
    .NOTES
        ScriptName : Get-DHCPDenies
        Created By : jspatton
        Date Coded : 10/21/2011 11:17:30
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
    .LINK
        http://scripts.patton-tech.com/wiki/PowerShell/Production/Get-DHCPDenies
#>
[CmdletBinding()]
Param
    (
        $EventID,
        $LogPath = "C:\LogFiles"
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME
 
        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
 
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
 
        #	Dotsource in the functions you need.
        }
Process
    {
        Write-Verbose "Grab the event that triggered the script to run, $($EventID)"
        $TriggeredEvent = Get-WinEvent -LogName Microsoft-Windows-Dhcp-Server/FilterNotifications |Where-Object {$_.id -eq $EventID}
        if ($TriggeredEvent.Count -eq $null)
        {
            Write-Verbose "Only one $($EventID) returned"
            $Report = New-Object -TypeName PSObject -Property @{
                EventID = $TriggeredEvent.Id
                MAC = $TriggeredEvent.Properties[0].Value
                HostName = $TriggeredEvent.Properties[1].Value
                HWType = $TriggeredEvent.Properties[2].Value
                Message = $TriggeredEvent.Message
                }
            }
        else
        {
            Write-Verbose "More than one $($EventID) returned, take the first"
            $Report = New-Object -TypeName PSObject -Property @{
                EventID = $TriggeredEvent.Id
                MAC = $TriggeredEvent[0].Properties[0].Value
                HostName = $TriggeredEvent[0].Properties[1].Value
                HWType = $TriggeredEvent[0].Properties[2].Value
                Message = $TriggeredEvent.Message
                }            
            }
        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
        if ((Test-Path -LiteralPath $LogPath) -eq $false)
        {
            Write-Verbose "$($LogPath) doesn't exist, creating"
            New-Item -Path $LogPath -ItemType Directory -Force
            }
        if ((Test-Path -Path "$($LogPath)\Denied-$($Report.MAC).xml") -eq $false)
        {
            Write-Verbose "This is a new host that is being denied."
            Export-Clixml -Path "$($LogPath)\Denied-$($Report.MAC).xml" -InputObject $Report
            }
        }