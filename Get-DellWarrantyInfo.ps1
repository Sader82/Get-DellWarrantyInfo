<#
.Synopsis
    Gets the warrenty info.
.DESCRIPTION
    Gets the warrenty info for one or more ServiceTags.
.EXAMPLE
    Get warrenty of one servicetag in production (https://api.dell.com).
    Get-DellWarrantyInfo -ServiceTag ABC1234 -ApiKey 8c3135ab-83cc-4a56-bfc1-6fa43b58c6b4
.EXAMPLE
    Get warrenty of one servicetag in dev (https://sandbox.api.dell.com).
    Get-DellWarrantyInfo -ServiceTag ABC1234 -ApiKey 8c3135ab-83cc-4a56-bfc1-6fa43b58c6b4 -Dev
.EXAMPLE
    Get warrenty of multiple servicetags in production (https://api.dell.com).
    Get-DellWarrantyInfo -ServiceTag ABC1234,DEF5678 -ApiKey 8c3135ab-83cc-4a56-bfc1-6fa43b58c6b4
.EXAMPLE
    Get warrenty of one servicetag in dev (https://sandbox.api.dell.com).
    Get-DellWarrantyInfo -ServiceTag ABC1234,DEF5678 -ApiKey 8c3135ab-83cc-4a56-bfc1-6fa43b58c6b4 -Dev      
.EXAMPLE
    Get warrenty of multiple servicetags in production (https://api.dell.com). Projected in a gridview!
    Get-DellWarrantyInfo -ServiceTag ABC1234,DEF5678 -ApiKey 8c3135ab-83cc-4a56-bfc1-6fa43b58c6b4 -Gridview
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   Source script: https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-Get-Dell-d7fd6367
   Little bit modified by me :-).
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-DellWarrantyInfo {
    Param(  
        [Parameter(Mandatory=$true)]  
        [string[]]$ServiceTag, 
        [Parameter(Mandatory=$true)]  
        [String]$ApiKey, 
        [Parameter(Mandatory=$false)]  
        [switch]$GridView,        
        [Parameter(Mandatory=$false)]
        [switch]$Dev 
    ) 
    $Tags = $ServiceTag
    $TagsArr = New-Object System.Collections.ArrayList
    $Today = Get-Date -Format "yyyy-MM-dd"

    foreach ($tag in $Tags){
        #Build URL 
        If ($Dev) { 
            $URL1 = "https://sandbox.api.dell.com/support/assetinfo/v4/getassetwarranty/$tag"  
        } 
        else { 
            $URL1 = "https://api.dell.com/support/assetinfo/v4/getassetwarranty/$tag"  
        } 
        $URL2 = "?apikey=$Apikey"  
        $URL = $URL1 + $URL2  

        #Get server data
        $Request = Invoke-RestMethod -URI $URL -Method GET -contenttype 'Application/xml'
        $Warranty=$Request.AssetWarrantyDTO.AssetWarrantyResponse.AssetWarrantyResponse.AssetEntitlementData.AssetEntitlement | select enddate,servicelevelcode

        # Read first entry if available 
        $SLA=$Warranty[0].servicelevelcode  
        $EndDate=$Warranty[0].EndDate

        # Date format
        $EndDate = $EndDate.Split('T')[0]
        $Today = [convert]::ToDateTime($Today)
        $EndDate = [convert]::ToDateTime($EndDate)
        $status = $EndDate-$today

        #determine the $status (OK / Soon (with in 30 days) / Expired)
        #used 30 day for the Soon status
        if($status.Days -lt 0){$status = 'Expired'} elseif ($status.Days -lt 30){$status = 'Soon'} else {$status = 'Ok'}

        #fill your array
        $TagsArrtemp = New-Object System.Object
        $TagsArrtemp | Add-Member -MemberType NoteProperty -Name servicetag -Value $tag
        $TagsArrtemp | Add-Member -MemberType NoteProperty -Name SupportType -Value $SLA
        $TagsArrtemp | Add-Member -MemberType NoteProperty -Name Date -Value $EndDate
        $TagsArrtemp | Add-Member -MemberType NoteProperty -Name status -Value $status

        [void]$TagsArr.add($TagsArrtemp)

    }
    if($GridView){$TagsArr | Out-GridView} else{ $TagsArr }
}