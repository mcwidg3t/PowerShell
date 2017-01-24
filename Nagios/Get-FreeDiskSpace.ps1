$letter = $args[0]
$drv = Get-PSDrive -Name $letter
$used = "{0:N2}" -f ($drv.used / 1GB)
$free = "{0:N2}" -f ($drv.free / 1GB)
$msg = "{0}: Used {1}GB; Free {2}GB" -f $letter, $used, $free
Write-Output $msg
exit 0