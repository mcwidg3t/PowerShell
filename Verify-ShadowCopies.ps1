# This script lists Shadow Copies on specified servers created over past 7 days and emails a report
#
# Author: Andy McKnight
# Created: 08/12/2014
# Last Edit: 17/04/2015
#

$servers = @("list", "of", "servers")
$daystocheck = 7

#region CheckShadowCopies
# Uses WMI Win32_Volume to get drive letter from device id
Function Get-DriveLetters($server)
{
    $volumes = @{}
    $allvolumes = Get-WmiObject win32_volume -ComputerName $server -Property DeviceID, Name
    foreach ($v in $allvolumes)
        {
            $volumes.add($v.DeviceID, $v.Name)
        }
    $volumes
}

Function Check-ShadowCopies
{
<#
.SYNOPSIS
Checks Shadow Copy Status of specified servers for past 7 days.

.DESCRIPTION
Checks Shadow Copy Status on specified servers for past 7 days.  Script designed to be ran as a scheduled task.

.EXAMPLE
powershell.exe Check-ShadowCopies.ps1

No parameters required.  Run the script to return the content of the various backup locations.
#>
    $allshadowcopies = @()
    Foreach ($server in $servers)
        {
            $driveletters = Get-DriveLetters $server
            $shadowcopies = Get-WmiObject -Class "Win32_ShadowCopy" -ComputerName $server -Property InstallDate, VolumeName
                Foreach ($copy in $shadowcopies)
                    {
                        $shadowcopy = New-Object System.Object

                        $date = [datetime]::ParseExact($copy.InstallDate.Split(".")[0], "yyyyMMddHHmmss", $null)

                        $shadowcopy | Add-Member -Type NoteProperty -Name Server -Value $server
                        $shadowcopy | Add-Member -Type NoteProperty -Name Date -Value $date
                        $shadowcopy | Add-Member -Type NoteProperty -Name Drive -Value $driveletters.Item($copy.VolumeName)

                        If ($date -gt (Get-Date).AddDays(-$daystocheck))
                            {
                                $allshadowcopies += $shadowcopy
                            }
                    }
        }
    $allshadowcopies
}
#endregion CheckShadowCopies


#region Generate Report
# Everything below here for HTML report
$date = Get-Date
$logo = '\\path\to\\logo.png'
$logoforemail = '<img src="cid:logo.png">'
$heading = "Shadow Copy Report - " + $date
$beginning = {
 @'
    <html>
    <head>
    <title>Report</title>
    <STYLE type="text/css">
        h1 {font-family:SegoeUI, sans-serif; font-size:16}
        h3 {font-family:SegoeUI, sans-serif; font-size:12}
        th {font-family:SegoeUI, sans-serif; font-size:15}
        td {font-family:Consolas, sans-serif; font-size:12}
    </STYLE>

    </head>
'@
$logoforemail
@'
    <h1>Shadow Copy Report -
'@
$date
@'
    </h1>
'@
    "<h1>Servers: $servers</h1>"
@'
    <table>
    <tr><th>Server</th><th>Copy Date/Time</th><th>Drive Letter</th></tr>
'@
}

$process = {
	If ($currentserver -eq $_.server)
		{
			'<tr>'
			'<td bgcolor="#00FF00">{0}</td>' -f  ' '
			'<td bgcolor="#00FF00">{0}</td>' -f $_.date
			'<td bgcolor="#00FF00">{0}</td>' -f $_.drive
			'</tr>'
		}
	Else
		{
			'<tr>'
			'<td bgcolor="#00CC00">{0}</td>' -f $_.server
			'<td bgcolor="#00CC00">{0}</td>' -f  ' '
			'<td bgcolor="#00CC00">{0}</td>' -f  ' '
			'</tr>'
			'<tr>'
			'<td bgcolor="#00FF00">{0}</td>' -f  ' '
			'<td bgcolor="#00FF00">{0}</td>' -f $_.date
			'<td bgcolor="#00FF00">{0}</td>' -f $_.drive
			'</tr>'
			$currentserver = $_.server
		}

}

$end = {
@'
    </table>
    <h3>This reports runs as a scheduled task on <servername></h3>
    </html>
    </body>
'@
}


# Write results as hta file and display  | Sort Date -Descending | Format-Table -AutoSize
$path = "$env:temp\report.hta"
$currentserver = " "
$shadowcopylist = Check-ShadowCopies
$shadowcopylist | Sort Server, Date -Descending | ForEach-Object -Begin $beginning -Process $process -End $end | Out-File -FilePath $path -Encoding utf8
# Invoke-Item -Path $path
#endregion Generate Report


#region Send email
$toaddress = "to@address.com""
$fromaddress = '<sendingserver>@address.com'
$shortdate = Get-Date -format d
$subject = "Shadow Copy Report for " + $shortdate
[string]$body = Get-Content $path
$smtpserver = 'smtpserver.com'
Send-Mailmessage -to $toaddress -from $fromaddress -subject $subject -BodyAsHtml -body $body -smtpServer $smtpserver -Attachments $logo

#endregion Send Email

Remove-Item $path
