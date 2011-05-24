 $LabComputers = Get-ADObjects -ADSPath "LDAP://OU=Eaton,OU=Labs,DC=soecs,DC=ku,DC=edu"

foreach ($LabComputer in $LabComputers)
{
    Write-Output "Updating $($LabComputer.Properties.name)"
    Add-DomainGroupToLocalGroup -ComputerName $LabComputer.Properties.name -DomainGroup "ECSStaffProfessionals" -UserDomain "SOECS"
}