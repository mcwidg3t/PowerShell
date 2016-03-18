# Update local computer description (in System) from the AD computer description

[CmdletBinding()]
Param(
    [String]$ComputerName
)

$ad = Get-ADComputer -Identity $ComputerName -Properties Description
$c = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
$c.Description = $ad.Description
$c.put()

