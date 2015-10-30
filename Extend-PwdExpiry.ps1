# This script resets the expiry timer on AD passwords.  
# 
# Author: Andy McKnight
# Created: 18/12/2014
# Last Edit: 18/12/2014
#

Function Extend-PwdExpiry
{
    <# 
    .SYNOPSIS
    Extends expiry of AD Account Passwords

    .DESCRIPTION
    This scripts resets the Password last set attribute of an AD User account to the date and time the script is ran.  
    This gives the user a further 28 days before their password will expire.  The user's password does not need to be known for this.

    .EXAMPLE
    PS C:\>Extend-PwdExpiry -Username test.account
    This command changes the last set date of test.account's password to today and restarts the 28 day expiry countdown.

    #>

    Param([String]$Username)

    # Attribute must firstly be set to 0 then to -1 for it to take today's date.
    $user = Get-ADUser -Identity $username -Properties PwdLastSet
    $user.PwdLastSet = 0
    Set-ADUser -Instance $user
    $user.PwdLastSet = -1
    Set-ADUser -Instance $user

}