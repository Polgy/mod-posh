. ..\production\includes\ActiveDirectoryManagement.ps1
$LabComputers = Get-ADObjects -ADSPath "LDAP://OU=labs,DC=soecs,DC=ku,DC=edu"
foreach ($LabComputer in $LabComputers)
    {
        $ThisComputer = $LabComputer.Properties
        Get-LocalGroupMembers -ComputerName $ThisComputer.name -GroupName Administrators
        }