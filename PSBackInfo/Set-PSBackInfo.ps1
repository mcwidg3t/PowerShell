function Set-Wallpaper {
    [CmdletBinding()]
    Param(
      [String]$Filename
    )

    $code = @'
    using System.Runtime.InteropServices;
    using Microsoft.Win32;

    namespace Win32{
        
        public class Wallpaper{

          [DllImport("user32.dll", CharSet=CharSet.Auto)]
          static  extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ;

          public static void SetWallpaper(string thePath){
            SystemParametersInfo(20,0,thePath,3);
        
            RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
            key.SetValue(@"WallpaperStyle", "0") ; 
            key.SetValue(@"TileWallpaper", "0") ; 
            key.Close();

          }
        }
    }
'@
    add-type $code

    [Win32.Wallpaper]::SetWallpaper($filename)
}

function Get-SystemInfo {
    param(
        [Switch]$Hostname,
        [Switch]$Description,
        [Switch]$OS,
        [Switch]$Username,
        [Switch]$IPAddress
    )

    $props = @{}

    if ($Hostname) {
        $wmiCS = Get-CIMInstance Win32_ComputerSystem
        $props.Add("hostname", $wmiCS.Name)
    }
    if ($os -or $Description) {
        $wmiOS = Get-CimInstance Win32_OperatingSystem
        if ($os) {
            $props.Add("os", $wmiOS.Caption)
        }
        if ($Description) {
            $props.Add("description", $wmiOS.Description)
        }
    }

    if ($Username) {
        $loggonOnUser = (Get-Item Env:\USERDOMAIN).Value + '\' + (Get-Item Env:\USERNAME).Value
        $props.Add("username", $loggonOnUser)
    }

    if ($IPAddress) {
        $ipList = Get-NetIPAddress | Where-Object {($_.addressstate -eq 'preferred') -and ($_.AddressFamily -eq 'IPv4') -and ($_.InterfaceAlias -notlike '*loopback*')} | Select -ExpandProperty ipaddress
        $ipAddresses = $ipList -join ', '
        $props.Add("ipaddresses", $ipAddresses)
    }

    $obj = New-Object -TypeName PSCustomObject -Property $props
    $obj
}

function Create-Wallpaper {
    [CmdletBinding()]
    Param(
        [psobject]$systeminfo
     )
    Add-Type -AssemblyName System.Drawing

    $numRows = ($systeminfo.psobject.properties | measure-object | select -expandproperty count)+1
    $filename = "$home\Pictures\wallpaper.png" 
    $bmp = New-Object System.Drawing.Bitmap 500,($numRows*20)
    $bold = [System.Drawing.FontStyle]::Bold 
    $HeaderFont = new-object System.Drawing.Font Consolas,20,$bold
    $DescFont = new-object System.Drawing.Font Consolas,11,$bold
    $font = New-Object System.Drawing.Font Consolas,11
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $brushBgBlack = [System.Drawing.Brushes]::Black
    $brushFgWhite = [System.Drawing.Brushes]::White
    $brushFgLightGray = [System.Drawing.Brushes]::LightGray 
    $graphics = [System.Drawing.Graphics]::FromImage($bmp) 
    
    $HostnameRectangle = New-Object System.Drawing.RectangleF(0,0,$bmp.Width,(($bmp.Height/$numRows)*2))
    $graphics.FillRectangle($brushBgBlack,$HostnameRectangle)
    $graphics.DrawString($systeminfo.hostname,$HeaderFont,$brushFgWhite,$HostnameRectangle,$sf)
    $currentRow = 2
    
    if ($systeminfo.description) {
        $DescRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/$numRows)*$currentRow),$bmp.Width,($bmp.Height/$numRows))
        $graphics.FillRectangle($brushBgBlack,$DescRectangle)
        $graphics.DrawString($systeminfo.description,$DescFont,$brushFgLightGray,$DescRectangle,$sf)
        $currentRow++
    }

    if ($systeminfo.username) {
        $UserRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/$numRows)*$currentRow),$bmp.Width,($bmp.Height/$numRows))
        $graphics.FillRectangle($brushBgBlack,$UserRectangle)
        $graphics.DrawString($systeminfo.username,$font,$brushFgLightGray,$UserRectangle,$sf)
        $currentRow++
    }

    if ($systeminfo.os) {
        $OSRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/$numRows)*$currentRow),$bmp.Width,($bmp.Height/$numRows))
        $graphics.FillRectangle($brushBgBlack,$OSRectangle)
        $graphics.DrawString($systeminfo.os,$font,$brushFgLightGray,$OSRectangle,$sf)
        $currentRow++
    }

    if ($systeminfo.ipaddresses) {  
        $IPRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/$numRows)*$currentRow),$bmp.Width,($bmp.Height/$numRows))
        $graphics.FillRectangle($brushBgBlack,$IPRectangle)
        $graphics.DrawString($systeminfo.ipaddresses,$font,$brushFgLightGray,$IPRectangle,$sf)
        $currentRow++
    }

    $graphics.Dispose() 
    $bmp.Save($filename)
    $filename 
}

$systeminfo = Get-SystemInfo -Hostname -Description -OS -Username -IPAddress
$filename = Create-Wallpaper -systeminfo $systeminfo 
Set-Wallpaper -Filename $filename