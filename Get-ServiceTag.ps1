# This script uses an WMI query to find service tags and serial numbers from computers.
#
# Author: Andy McKnight
# Last Edit: 17/11/2014

Function Get-ServiceTag
{
<# 
    .SYNOPSIS
    Script to find service tag from local or remote computers

    .DESCRIPTION
    Finds a service tag or serial number using WMI query of the WIn32_Bios class.  Can be used without a paramter for local machine or
    with a paramter for remote machine.

    .PARAMETER ComputerName
    Specifies remote computer to query for service tag

    .EXAMPLE
    Get-ServiceTag.ps1 -ComputerName BobPC
    
#>
    Param(
        [String]
        $ComputerName
    )

    If ($ComputerName) {
        Write-Host (Get-WMIObject -Class "Win32_BIOS" -ComputerName $ComputerName | select SerialNumber).SerialNumber
        }
    Else {
        Write-Host (Get-WMIObject -Class "Win32_BIOS" | select SerialNumber).SerialNumber
        }
}
Set-Alias gst Get-ServiceTag
