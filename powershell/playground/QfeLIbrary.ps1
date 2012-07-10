Function New-QfePatch
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
            New-QfePatch 
                -URL 'http://support.microsoft.com/kb/981314' 
                -KB 981314 
                -OS (Get-WmiObject -Class Win32_OperatingSystem |Select-Object -Property Caption -ExpandProperty Caption) 
                -Arch 'x64' 
                -Test '(Get-Item -Path C:\Windows\System32\wbem\cimwin32.dll).VersionInfo.FilePrivatePart' 
                -Answer 20683
        .NOTES
            FunctionName : New-QfePatch
            Created by   : jspatton
            Date Coded   : 07/09/2012 11:16:28
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#New-QfePatch
    #>
    [CmdletBinding()]
    Param
        (
        [string]$URL,
        [string]$KB,
        [string]$OS,
        [string]$Arch,
        [string]$QfeFilename,
        $Test,
        $Answer,
        [string]$QfeServer = $Global:QfeServer
        )
    Begin
    {
        Write-Verbose "Check to see if we have the QfeServer variable"
        if ($QfeServer -eq $null)
        {
            Write-Error 'Please define your QFE Server by running the Set-QfeServer cmdlet.'
            break
            }
        }
    Process
    {
        $Result = New-Object -TypeName PSobject -Property @{
            QfeId = "$($Kb.Trim())-$($Os.Trim().Replace(' ','-'))-$($Arch.Trim())"
            URL = $URL.Trim()
            KB = $KB.Trim()
            OS = $OS.Trim()
            Arch = $Arch.Trim()
            QfeFilename = $QfeFilename
            Test = $Test
            Answer = $Answer
            }
        }
    End
    {
        try
        {
            $FileName = $Result.QfeId
            Write-Verbose "Write the QFE metadata to a file: $($QfeServer)\$($FileName).xml"
            $Result |Export-Clixml "$($QfeServer)\$($FileName).xml"
            }
        catch
        {
            Write-Error $Error[0]
            Write-Error "QFE Metadata file not written to disk."
            break
            }
        }
     }
Function Test-QfePatch
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
            Test-QfePatch -QfeId '977944-Microsoft-Windows-7-Enterprise-x64'
        .NOTES
            FunctionName : Test-QfePatch
            Created by   : jspatton
            Date Coded   : 07/09/2012 11:55:03
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#Test-QfePatch
    #>
    [CmdletBinding()]
    Param
        (
        [string]$QfeId,
        [string]$QfeServer = $Global:QfeServer
        )
    Begin
    {
        Write-Verbose "Check to see if we have the QfeServer variable"
        if ($QfeServer)
        {
            try
            {
                Write-Verbose "Import the meta data file that matches $($QfeId)"
                $Qfe = Import-Clixml -Path (Get-ChildItem -Path $QfeServer -Filter "*$($QfeId)*").Fullname
                }
            catch
            {
                Write-Error $Error[0]
                break
                }
            }
        else
        {
            Write-Error 'Please define your QFE Server by running the Set-QfeServer cmdlet.'
            break
            }        
        }
    Process
    {
        try
        {
            Write-Verbose "Build a scriptblock from the Test property of the imported QFE"
            $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($Qfe.Test)
            Write-Verbose "Run the following test`r`n$($Qfe.Test)"
            $Return = Invoke-Command -ScriptBlock $ScriptBlock
            }
        catch
        {
            Write-Error $Error[0]
            break
            }
        }
    End
    {
        Write-Verbose "Return `$true or `$false based on the result of the test."
        $Return -eq $Qfe.Answer
        }
    }
Function Get-QfeList
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Get-QfeList
            Created by   : jspatton
            Date Coded   : 07/09/2012 12:10:14
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#Get-QfeList
    #>
    [CmdletBinding()]
    Param
        (
        [string]$QfeServer = $Global:QfeServer,
        [switch]$All,
        [switch]$Download,
        $LocalPath = 'C:\Hotfixes'
        )
    Begin
    {
        Write-Verbose "Check to see if we have the QfeServer variable"
        if ($QfeServer)
        {
            try
            {
                Write-Verbose "Get a list of all the QFE files stored in $($QfeServer)"
                $Qfes = Get-ChildItem $QfeServer -Filter *.xml
                }
            catch
            {
                Write-Error $Error[0]
                break
                }
            }
        else
        {
            Write-Error 'Please define your QFE Server by running the Set-QfeServer cmdlet.'
            break
            }
        if ($Download)
        {
            Write-Verbose "We're downloading, create the folder $($LocalPath)"
            if ((Test-Path $LocalPath) -eq $false)
            {
                New-Item -Path $LocalPath -ItemType Directory -Force |Out-Null
                }
            }
        }
    Process
    {
        foreach ($Qfe in $Qfes)
        {
            if ($All)
            {
                Write-Verbose "Return all QFEs"
                if ($Download)
                {
                    Write-Verbose "Download all QFEs"
                    $QfeFilename = (Import-Clixml -Path $Qfe.FullName |Select-Object -Property QfeFileName).QfeFilename
                    Write-Verbose "Copy the hotfix $($QfeFilename)"
                    Copy-Item -Path "$($QfeServer)\$($QfeFilename)" -Destination $LocalPath
                    Write-Verbose "Copy the meta file $($Qfe.FullName)"
                    Copy-Item -Path $Qfe.FullName -Destination $LocalPath
                    }
                else
                {
                    Write-Verbose "Display the QfeId, KB, URL, Os and Arch from the Qfe"
                    Import-Clixml -Path $Qfe.FullName |Select-Object -Property QfeId, KB, Url, Os, Arch
                    }
                }
            else
            {
                Write-Verbose "Return all QFEs that match the client OS"
                if ($Download)
                {
                    Write-Verbose "Download QFEs that match the client OS"
                    Write-Verbose "Ask WMI for the client OS"
                    $LocalOs = (Get-WmiObject -Class Win32_OperatingSystem |Select-Object -Property Caption -ExpandProperty Caption).Trim()
                    Write-Verbose "Display only QFEs where the client OS matches the OS property of the QFE"
                    if ((Import-Clixml -Path $Qfe.FullName |Select-Object -Property Os).Os -like $LocalOs)
                    {
                        $QfeFilename = (Import-Clixml -Path $Qfe.FullName |Select-Object -Property QfeFileName).QfeFilename
                        Write-Verbose "Copy the hotfix $($QfeFilename)"
                        Copy-Item -Path "$($QfeServer)\$($QfeFilename)" -Destination $LocalPath
                        Write-Verbose "Copy the meta file $($Qfe.FullName)"
                        Copy-Item -Path $Qfe.FullName -Destination $LocalPath
                        }
                    }
                else
                {
                    Write-Verbose "Ask WMI for the client OS"
                    $LocalOs = (Get-WmiObject -Class Win32_OperatingSystem |Select-Object -Property Caption -ExpandProperty Caption).Trim()
                    Write-Verbose "Display the QfeId, KB, URL, Os and Arch from the Qfe"
                    Import-Clixml -Path $Qfe.FullName |Where-Object {$_.Os -like $LocalOs} |Select-Object -Property QfeId, KB, Url, Os, Arch
                    }
                }
            }
        }
    End
    {
        }
    }
Function Set-QfeServer
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Set-QfeServer
            Created by   : jspatton
            Date Coded   : 07/09/2012 13:01:13
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#Set-QfeServer
    #>
    [CmdletBinding()]
    Param
        (
        $QfeServer
        )
    Begin
    {
        Write-Verbose "Check to make sure that $($QfeServer) exists as a path."
        if ((Test-Path $QfeServer))
        {
            $Global:QfeServer = $QfeServer
            }
        else
        {
            Write-Error "$($QfeServer) is not a valid path, please make sure that $($QfeServer) exists and that you have read/write access to it."
            }
        }
    Process
    {
        }
    End
    {
        }
    }
Function Install-QfePatch
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
            Get-ChildItem C:\Hotfixes\ -Filter *.msu |Install-QfePatch
        .EXAMPLE
            Install-QfePatch -QfeFilename C:\Hotfixes\977944-Microsoft-Windows-7-Enterprise-x64.xml
        .NOTES
            FunctionName : Install-QfePatch
            Created by   : jspatton
            Date Coded   : 07/09/2012 14:23:45
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#Install-QfePatch
    #>
    [CmdletBinding()]
    Param
        (
        [Parameter(ValueFromPipeline=$True)]
        $QfeFilename
        )
    Begin
    {
        Write-Verbose "Checking to see if we have piped files"
        if ($QfeFilename -and $QfeFilename.Count -eq $null)
        {
            Write-Verbose "Singleton file passed in"
            $QfeFilename = Get-Item $QfeFilename
            }
        }
    Process
    {
        foreach ($QfeFile in $QfeFilename)
        {
            Write-Verbose "Only working with XML meta data files."
            if ($QfeFile.extension -eq '.xml')
            {
                Write-Verbose "Read in the metadata before processing."
                $QfeManifest = Import-Clixml $QfeFile
                Write-Verbose "Ask WMI if this hotfix is already applied"
                if((Get-WmiObject -Class Win32_QuickFixEngineering -Filter "HotfixId like '*$($QfeManifest.KB)*'") -eq $null)
                {
                    Write-Verbose "Build the full path to the hotfix executable."
                    $QfeFilename = "$($QfeFile.Directory.FullName)\$($QfeManifest.QfeFilename)"
                    Write-Verbose "Build the logfile based on the QfeId"
                    $QfeLogFilename = "$($QfeFile.Directory.FullName)\$($QfeManifest.QfeId)-Install.evtx"
                    Write-Verbose "Build the command-line to execute the installation"
                    $CmdLine = "C:\Windows\System32\wusa.exe $($QfeFilename) /quiet /norestart /log:$($QfeLogFilename)"
                    Write-Verbose "Pass the command-line to the CMD environment for installation"
                    cmd /c $CmdLine
                    }
                }
            }
        }
    End
    {
        Write-Verbose "Return all error messages from the logfile created"
        $Message = Get-WinEvent -Oldest -FilterHashtable @{Path=$QfeLogFilename;Level=2} |Select-Object -Property Message
        if ($Message)
        {
            Write-Error "Errors found review $($QfeLogFileName) for more details"
            $Message
            }
        }
    }
Function Uninstall-QfePatch
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Uninstall-QfePatch
            Created by   : jspatton
            Date Coded   : 07/09/2012 14:23:58
        .LINK
            https://code.google.com/p/mod-posh/wiki/QfeLIbrary#Uninstall-QfePatch
    #>
    [CmdletBinding()]
    Param
        (
        [Parameter(ValueFromPipeline=$True)]
        $QfeFilename
        )
    Begin
    {
        Write-Verbose "Checking to see if we have piped files"
        if ($QfeFilename -and $QfeFilename.Count -eq $null)
        {
            Write-Verbose "Singleton file passed in"
            $QfeFilename = Get-Item $QfeFilename
            }
        }
    Process
    {
        foreach ($QfeFile in $QfeFilename)
        {
            Write-Verbose "Only working with XML meta data files."
            if ($QfeFile.extension -eq '.xml')
            {
                Write-Verbose "Read in the metadata before processing."
                $QfeManifest = Import-Clixml $QfeFile
                Write-Verbose "Ask WMI if this hotfix is already applied"
                if((Get-WmiObject -Class Win32_QuickFixEngineering -Filter "HotfixId like '*$($QfeManifest.KB)*'"))
                {
                    Write-Verbose "Build the full path to the hotfix executable."
                    $QfeFilename = "$($QfeFile.Directory.FullName)\$($QfeManifest.QfeFilename)"
                    Write-Verbose "Build the logfile based on the QfeId"
                    $QfeLogFilename = "$($QfeFile.Directory.FullName)\$($QfeManifest.QfeId)-Uninstall.evtx"
                    Write-Verbose "Build the command-line to execute the installation"
                    $CmdLine = "C:\Windows\System32\wusa.exe /uninstall $($QfeFilename) /quiet /norestart /log:$($QfeLogFilename)"
                    Write-Verbose "Pass the command-line to the CMD environment for uninstall"                    
                    cmd /c $CmdLine
                    }
                }
            }
        }
    End
    {
        Write-Verbose "Return all error messages from the logfile created"
        $Message = Get-WinEvent -Oldest -FilterHashtable @{Path=$QfeLogFilename;Level=2} |Select-Object -Property Message
        if ($Message)
        {
            Write-Error "Errors found review $($QfeLogFileName) for more details"
            $Message
            }
        }
    }