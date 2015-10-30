Function Search-ADUsers
{
# This script searches for AD users using a string.
#
# Author: Andy McKnight
# Created: 05/01/2015
# Last Edit: 05/01/2015
#
<# 
.SYNOPSIS
Searches Active Directory for user accounts

.DESCRIPTION
This script will search Active Directory for user accounts

.EXAMPLE
Search-ADUsers -UserName *Bob*
#>
	
[cmdletbinding()]
Param(
		[string]$UserName
)
	
If ($UserName)
	{
		Get-ADUser -Filter {Name -like $UserName} | Select Name, DistinguishedName, Enabled | Format-Table -AutoSize
	}

}