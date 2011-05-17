Function Get-DellBiosLink
{
    Param
        (
            $DellSupportPage
        )
    Begin
    {
        $Client = New-Object System.Net.WebClient
        $Client.Headers.Add("user-agent","PowerShell")
    }
    
    Process
    {
        $Data = $Client.OpenRead($DellSupportPage)
        $Reader = New-Object System.IO.StreamReader $Data
        [string]$s = $Reader.ReadToEnd()
        $marker = ($s.Substring($s.IndexOf("Dell - BIOS"),($s.Length)-($s.IndexOf("Dell - BIOS"))))
        $marker = $marker.Remove(0,$marker.IndexOf("http"))
        $BiosLink = $marker.Substring(0,$marker.IndexOf("`""))
    }
    
    End
    {
        Return $BiosLink
    }
}

$BiosRev = Get-WmiObject -Class Win32_BIOS #-ComputerName $ComputerName -Credential $Credentials

# Shortened URL for the Dell Support page, fileid=441102, appears to be the identifier for BIOS downloads
# I tested this on a few different models of Dell workstations.

$DellSupportPage = "http://support.dell.com/support/downloads/driverslist.aspx?c=us&cs=RC956904&l=en&s=hied&os=WLH&osl=en&ServiceTag=$($BiosRev.SerialNumber)"
$DellBIOSPage = Get-DellBiosLink -DellSupportPage $DellSupportPage
# This HTML code immediately preceed's the actual service tag, you can see it when you 'view source' on the page

$DellPageVersionString = "<span id=`"Version`" class=`"para`">"

If ($BiosRev.Manufacturer -match "Dell")
{
    $DellPage = (New-Object -TypeName net.webclient).DownloadString($DellBIOSPage)
    
    # Assuming that Dell BIOS rev's remain 3 characters, I find where my string starts and add the length to it
    # and the substring returns the BIOS rev.
    
    $DellCurrentBios = $DellPage.Substring($DellPage.IndexOf($DellPageVersionString)+$DellPageVersionString.Length,3)

    If (($BiosRev.SMBIOSBIOSVersion -eq $DellCurrentBios) -eq $false)
    {
        # Download the latest installer if the Rev's don't match
        
        # Assuming Dell continues to use FTP for downloads, find the download URL
        # This returns just the URL portion of the HTML code
        
        $BIOSDownloadURL = $DellPage.Substring($DellPage.IndexOf("http://ftp"),(($DellPage.Substring($DellPage.IndexOf("'http://ftp"),100)).indexof(".EXE"))+3)
        
        # Pull the filename from the end of the path, the 12's indicate 8+3 that Dell is using
        # for filenames, if that changes this should as well.
        
        $BIOSFile = $BIOSDownloadURL.Substring(($BIOSDownloadURL.Length)-12,12)

        If ((Test-Path "C:\Dell\") -eq $false)
        {
            New-Item -Path "C:\" -Name "Dell" -ItemType Directory
        }
        If ((Test-Path "C:\Dell\$($ComputerName)") -eq $false)
        {
            New-Item -Path "C:\Dell" -Name $ComputerName -ItemType Directory
        }

        (New-Object -TypeName New-Object System.Net.WebClient).DownloadFile($BIOSDownloadURL,"C:\Dell\$($ComputerName)\$($BIOSFile)")

        Write-Host "Latest BIOS for $($ComputerName) downloaded to C:\Dell\$($ComputerName)\$($BIOSFile)"
    }
    $BIOSInfo = New-Object PSobject -Property @{
        ComputerName = $ComputerName
        ServiceTag = $($BiosRev.SerialNumber)
        CurrentBIOSRev = $($BiosRev.SMBIOSBIOSVersion)
        LatestBIOSrev = $DellCurrentBios
        BIOSURL = $BIOSDownloadURL
    }
}