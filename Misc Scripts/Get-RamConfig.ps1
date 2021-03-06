Function Get-RAMConfig {
    <# 
    .SYNOPSIS
    Gets RAM configuration information 

    .DESCRIPTION
    This script returns the RAM configuration of the computer

    .EXAMPLE
    PS C:\>Get-RAMConfig -ComputerName BobPC
    This command returns the RAM modules present in BobPC

    #>
	[cmdletbinding()]
	Param([String]$ComputerName)
	
	$colSlots = gwmi win32_PhysicalMemoryArray -computerName $ComputerName
	$colRAM = gwmi win32_PhysicalMemory -computerName $ComputerName

	Write-Host ("RAM Installed on  " + $ComputerName)
	Foreach ($objSlot In $colSlots){
		 "Total Number of DIMM Slots: " + $objSlot.MemoryDevices
	}
	Foreach ($objRAM In $colRAM) {
		 $objRAM.DeviceLocator
		 "Memory Size: " + ($objRAM.Capacity / 1GB) + " GB"
	}
}