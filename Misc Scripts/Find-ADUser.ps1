Function Find-ADUser{
    <# 
    .SYNOPSIS
    Searches Active Directory for user accounts

    .DESCRIPTION
    This function searches Active Directory for user accounts.  This a string match on either the name field or the object's description.

    .EXAMPLE
    Find-ADUser -Name *andy*
    This will return a list of all users with the specified string in the name field.

    .EXAMPLE
    Find-ADUser -Description *Leavers*
    This will return a list of all users  with the specified string in the description field.
    #>
    	[cmdletbinding(DefaultParameterSetName="Username")]
    	Param(
    					[Parameter(ParameterSetName="Username",position=0)][string]$Name,
    					[Parameter(ParameterSetName="Description")][string]$Description
    	)
    	
    	If ($Name)
    		{
    			Get-ADUser -Filter {Name -like $Name} -Properties Description | Select Name, Description, SAMAccountName, UserPrincipalName, DistinguishedName, Enabled | Format-Table -AutoSize
    		}
    	If ($Description)
    		{
    			Get-ADUser -Filter {Description -like $Description} -Properties Description | Select Name, Description, SAMAccountName, UserPrincipalName, DistinguishedName, Enabled | Format-Table -AutoSize
    		}
    }