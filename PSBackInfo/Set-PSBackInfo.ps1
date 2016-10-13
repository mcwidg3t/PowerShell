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

function Create-Wallpaper {
    [CmdletBinding()]
    Param(
        [String]$Hostname,
        [String]$Description,
        [String]$Username,
        [String]$OS,
        [String]$IPAddresses
     )
    Add-Type -AssemblyName System.Drawing

    $filename = "$home\Pictures\wallpaper.png" 
    $bmp = New-Object System.Drawing.Bitmap 500,120
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
    
    $HeaderRectangle = New-Object System.Drawing.RectangleF(0,0,$bmp.Width,(($bmp.Height/6)*2))
    $graphics.FillRectangle($brushBgBlack,$HeaderRectangle)
    $graphics.DrawString($Hostname,$HeaderFont,$brushFgWhite,$HeaderRectangle,$sf)
    
    $DescRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/6)*2),$bmp.Width,($bmp.Height/6))
    $graphics.FillRectangle($brushBgBlack,$DescRectangle)
    $graphics.DrawString($Description,$DescFont,$brushFgLightGray,$DescRectangle,$sf)

    $UserRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/6)*3),$bmp.Width,($bmp.Height/6))
    $graphics.FillRectangle($brushBgBlack,$UserRectangle)
    $UserText = $Username
    $graphics.DrawString($Usertext,$font,$brushFgLightGray,$UserRectangle,$sf)

    $OSRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/6)*4),$bmp.Width,($bmp.Height/6))
    $graphics.FillRectangle($brushBgBlack,$OSRectangle)
    $OSText = $OS
    $graphics.DrawString($OStext,$font,$brushFgLightGray,$OSRectangle,$sf)
      
    $IPRectangle = New-Object System.Drawing.RectangleF(0,(($bmp.Height/6)*5),$bmp.Width,($bmp.Height/6))
    $graphics.FillRectangle($brushBgBlack,$IPRectangle)
    $graphics.DrawString($IPAddresses,$font,$brushFgLightGray,$IPRectangle,$sf)

    $graphics.Dispose() 
    $bmp.Save($filename)
    $filename 
}

function Get-SystemInfo {
    $cs = Get-CIMInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $username = (Get-Item Env:\USERDOMAIN).Value + '\' + (Get-Item Env:\USERNAME).Value
    $ipList = Get-NetIPAddress | Where-Object {($_.addressstate -eq 'preferred') -and ($_.AddressFamily -eq 'IPv4') -and ($_.InterfaceAlias -notlike '*loopback*')} | Select -ExpandProperty ipaddress
    $ipAddresses = $ipList -join ', '
    $obj = New-Object -TypeName PSCustomObject -Property @{hostname = $cs.Name;
                                                          description = $os.Description;
                                                          username = $username;
                                                          ipaddresses = $ipAddresses;
                                                          os = $os.Caption}

    $obj
}

$systeminfo = Get-SystemInfo
$filename = Create-Wallpaper -Hostname $systeminfo.hostname -Description $systeminfo.description -Username $systeminfo.username -OS $systeminfo.os -IPAddresses $systeminfo.ipaddresses
Set-Wallpaper -Filename $filename