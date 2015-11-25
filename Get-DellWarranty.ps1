<#
Author: Andy McKnight
Created: 25/11/2015
Last Edit: 25/11/2015
#>

Function Get-DellWarranty {
<# 
.SYNOPSIS
    Returns warranty details for a Service Tag or an array of Service Tags

.DESCRIPTION
    Get-DellWarranty takes a Service Tag or an array of Service Tags and queries the Dell API for the warranties associated with that tag. 
    It does not return any Dell Digital Delivery Warranties, Code 'D'.

.EXAMPLE
    C:\> Get-DellWarranty -ServiceTags 47L6YY1
    
ServiceTag Description    ShipDate   ProSupport          NBD
---------- -----------    --------   ----------          ---
47L6YY1    Latitude E7240 2014-03-18 19/03/2017 18:59:59 19/03/2017 18:59:59

.EXAMPLE
    C:\> Get-DellWarranty -ServiceTags "47L6YY1,1YF725J"

ServiceTag Description    ShipDate   ProSupport          NBD
---------- -----------    --------   ----------          ---
47L6YY1    Latitude E7240 2014-03-18 19/03/2017 18:59:59 19/03/2017 18:59:59
1YF725J    OptiPlex 380   2011-02-28                     01/03/2014 17:59:59

.EXAMPLE
    C:\> Get-DellWarranty -ServiceTags "47L6YY1" -All

ServiceTag         : 47L6YY1
Description        : Latitude E7240
ShipDate           : 2014-03-18
ProSupport 1 Start : 18/03/2014 19:00:00
ProSupport 1 End   : 19/03/2017 18:59:59
NBD 1 Start        : 18/03/2014 19:00:00
NBD 1 End          : 19/03/2017 18:59:59

.PARAMETER ServiceTag
    Specify the service tag to use to query the warranty. This can be a single tag or array of tags.

.PARAMETER All
    Shows all warranty data associated with the service tag, instead of only the most recent.
#>
    [Cmdletbinding()]
    Param( 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [String[]]$ServiceTags,
        [Switch]$All
        )
    #$testtag = "12M6YY1", "1YL905J", "DOM905J"
    
    $uri = 'https://sandbox.api.dell.com/support/assetinfo/v4/getassetwarranty'
    # $uri = 'https://brokenurl.com/'
    
    $ID = $ServiceTags.trim() -join ","

    $headers = @{
        apikey = "<your api key>"
        'Content-Type' = "application/x-www-form-urlencoded"
        'Accept' = "application/json"
        }

    $body = @{
        ID = $ID
        }


    try {
        $response = Invoke-RestMethod -Uri $uri -Method POST -Header $headers -Body $body 
        # $response object will contain properties AssetHeaderData, ProductHeaderData & AssetEntitlementData
        # which have all the useful information plus ExcessTags, InvalidFormatAssets and InvalidBILAssets which contain
        # information on service tags with errors during checking.

        if ($response) {
            $allWarranties = @()
            $warrantyFound = $false
            # Create object to return the warranty details 
            If ($response.AssetWarrantyResponse.Count -gt 0) {
                $warrantyFound = $true
                Foreach ($ServiceTag in $response.AssetWarrantyResponse) {
                    $properties = @{
                        ServiceTag = $ServiceTag.AssetHeaderData.ServiceTag
                        ShipDate = ($ServiceTag.AssetHeaderData.ShipDate -split "T")[0]
                        Description = $ServiceTag.AssetHeaderData.MachineDescription
                    }
                    $warranty = New-Object psobject -Property $properties

                    $prosupportNum = 1
                    $nbdNum = 1
                    
                    Foreach ($e in $ServiceTag.AssetEntitlementData) {
                        If ($e.ServiceLevelCode -ne 'D') {
                            switch ($e.ServiceLevelCode) {
                                "NU" {
                                    If ($All) {
                                        $warranty | Add-Member -MemberType NoteProperty -Name "ProSupport $prosupportNum Start" -Value ([datetime]($e.StartDate))
                                        $warranty | Add-Member -MemberType NoteProperty -Name "ProSupport $prosupportNum End" -Value ([datetime]($e.EndDate))
                                        $prosupportNum++                                            
                                    }
                                    else {
                                        If ($warranty."ProSupport") {
                                            If (([datetime]($e.EndDate)) -gt $warranty."ProSupport") {
                                                $warranty.PSObject.Properties.Remove('ProSupport')
                                                $warranty | Add-Member -MemberType NoteProperty -Name "ProSupport" -Value ([datetime]($e.EndDate))
                                            } #End If
                                        } #End if
                                        else {
                                            $warranty | Add-Member -MemberType NoteProperty -Name "ProSupport" -Value ([datetime]($e.EndDate))
                                        } #End else
                                    } #End else
                                } #End case
                                "ND" {
                                    If ($All) {
                                        $warranty | Add-Member -MemberType NoteProperty -Name "NBD $nbdNum Start" -Value ([datetime]($e.StartDate))
                                        $warranty | Add-Member -MemberType NoteProperty -Name "NBD $nbdNum End" -Value ([datetime]($e.EndDate))
                                        $nbdNum++
                                    }
                                    else {
                                        If ($warranty."NBD") {
                                            If (([datetime]($e.EndDate)) -gt $warranty."NBD") {
                                                $warranty.PSObject.Properties.Remove('NBD')
                                                $warranty | Add-Member -MemberType NoteProperty -Name "NBD" -Value ([datetime]($e.EndDate))
                                            } #End If
                                        } #End if
                                        else {
                                            $warranty | Add-Member -MemberType NoteProperty -Name "NBD" -Value ([datetime]($e.EndDate))
                                        } #End else
                                    } #End else        
                                } #End Case
                            } #End Switch
                        } #End If
                    } #End Foreach

                    $allWarranties += $warranty
                } #End Foreach
            } #End If
            
            If ($All) {
                $allWarranties | Format-List *       
            }
            else {
                $allWarranties | Select-Object 'ServiceTag', 'Description', 'ShipDate', 'ProSupport', 'NBD' | Format-Table -Autosize
            }        

            $invalidBILAssetFound = $false
            $invalidFormatAssetFound = $false
            $excessTagsFound = $false
            
            If ($response.InvalidBILAssets.BadAssets.Count -gt 0) {
                $invalidBILAssetFound = $true
                Write-Output ""
                Write-Output "The following tags do not exist in BIL:"
                $response.InvalidBILAssets.BadAssets
            }
            
            If ($response.InvalidFormatAssets.BadAssets.Count -gt 0) {
                $invalidFormatAssetFound = $true
                Write-Output ""
                Write-Output "The following tags have an invalid format:"
                $response.InvalidFormatAssets.BadAssets
            }
            
            If ($response.ExcessTags.BadAssets.Count -gt 0) {
                $excessTagsFound = $true
                Write-Output ""
                Write-Output "The following tags exceeded the 80 tags checked limit:"
                $response.ExcessTags.BadAssets
            }
            
            If (!$warrantyFound -and !$invalidBILAssetFound -and !$invalidFormatAssetFound -and !$excessTagsFound) {
                Write-Output 'Empty response received from Dell APi. This should not happen'
                Write-Output 'If this is the first time you have seen this error, please try again.'
                Write-Output 'Otherwise, please report this to Dell support'
                Write-Output 'Valid JSON response received but not data in AssetWarrantyResponse, InvalidBILAssets, InvalidFormatAssets or ExcessTags'
            }
        } #End If ($response)  
            }
    catch {
        $_.Exception.Message
    }
}