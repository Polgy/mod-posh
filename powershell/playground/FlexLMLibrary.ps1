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