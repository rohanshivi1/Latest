#########################################################################################################################################################################################
# Aug 14th 2019 -- Rohan Sharma
#  Script Name         : webappaccessrestrict-nonprod.ps1 
#  Script Objective:
#  For Restricting and Unrestricting the Access to Webpps and Functions through Application Gateway as well as office IP as Part of the Resource Group
#       a) Checks the Resource Group 
#       b) Creates a Temp Blob to Store the WebApp of a Particular Resource Group.
#       c) Restrict : Enforces All restrictions allowing Access ONLY via Application Gateway and Office IP. 
#       d) Unrestrict : Removes all Access Restrictions.
#       d) Outputs the Current State of the Applications
#
#Prompt1               : Resource Group Name
#Prompt2               : Action (RESTRICT/restrict , UNRESTRICT,unrestrict)
#
#Command Usage: webappaccessrestrict-nonprod.ps1 <ResourceGroup> <Restrict/Unrestrict> 

#(e.g. ./webappaccessrestrict-nonprod.ps1 aa restrict)  - Adds all DEV Webapps and Functions to "Deny All" and Allow Access only through "network-vnet-nonprod/network-subnetaad"
#      ./webappaccessrestrict-nonprod.ps1.ps1 pbb-rg unrestrict)  - Removes all Restrictions
##########################################################################################################################################################################################



#Requires -Version 4.0

param (
[Parameter(Mandatory=$true)][string]$resourceGroupName,
[Parameter(Mandatory=$true)][string]$action
)

 $vnetresourceGroupName = "network-aad-rg"
 $vnetName = "network-vnetabcd-vnet"
 $subnetName = "network-bb-subnet"

function Add-AzureIpRestrictionRule
{
    [CmdletBinding()]
    Param
    (
        # Name of the resource group that contains the App Service.
        [Parameter(Mandatory=$true, Position=0)]
        $ResourceGroupName, 

        # Name of your Web or API App.
        [Parameter(Mandatory=$true, Position=1)]
        $AppServiceName, 

        # rule to add.
        [Parameter(Mandatory=$true, Position=2)]
        [PSCustomObject]$rule 
    )

    $ApiVersions = Get-AzResourceProvider -ProviderNamespace Microsoft.Web | Select-Object -ExpandProperty ResourceTypes | Where-Object ResourceTypeName -eq 'sites' | Select-Object -ExpandProperty ApiVersions

    $LatestApiVersion = $ApiVersions[0]

    $WebAppConfig = Get-AzResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion


    $WebAppConfig.Properties.ipSecurityRestrictions =  $WebAppConfig.Properties.ipSecurityRestrictions + @($rule) | Group-Object name | ForEach-Object { $_.Group | Select-Object -Last 1 }
    
        Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $LatestApiVersion -Force    
}

function Add-AzureVnetRestrictionRule
{
    [CmdletBinding()]
    Param
    (
        # Name of the resource group that contains the App Service.
        [Parameter(Mandatory=$true, Position=0)]
        $ResourceGroupName, 

        # Name of your Web or API App.
        [Parameter(Mandatory=$true, Position=1)]
        $AppServiceName, 

        # rule to add.
        [Parameter(Mandatory=$true, Position=2)]
        [PSCustomObject]$rule 
    )

    $ApiVersions = Get-AzResourceProvider -ProviderNamespace Microsoft.Web | Select-Object -ExpandProperty ResourceTypes | Where-Object ResourceTypeName -eq 'sites' | Select-Object -ExpandProperty ApiVersions

    $LatestApiVersion = $ApiVersions[0]

    $WebAppConfig = Get-AzResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion


    $WebAppConfig.Properties.ipSecurityRestrictions =  $WebAppConfig.Properties.ipSecurityRestrictions + @($rule) | Group-Object name | ForEach-Object { $_.Group | Select-Object -Last 1 }
    
    Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $LatestApiVersion -Force    
}

function Remove-AzureIpRestrictionRule
{
    [CmdletBinding()]
    Param
    (
        # Name of the resource group that contains the App Service.
        [Parameter(Mandatory=$true, Position=0)]
        $ResourceGroupName, 

        # Name of your Web or API App.
        [Parameter(Mandatory=$true, Position=1)]
        $AppServiceName

    )

    $ApiVersions = Get-AzResourceProvider -ProviderNamespace Microsoft.Web | Select-Object -ExpandProperty ResourceTypes | Where-Object ResourceTypeName -eq 'sites' | Select-Object -ExpandProperty ApiVersions

    $LatestApiVersion = $ApiVersions[0]

    $WebAppConfig = Get-AzResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion


        $WebAppConfig.Properties.ipSecurityRestrictions =  @()
        Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $LatestApiVersion -Force 
}

<###############################


Get Storage Context function

################################>

function Get-StorageObject 

{ param($resourceGroupName, $srcURI, $srcName) 

 

 $split = $srcURI.Split('/')

 $strgDNS = $split[2]

 $splitDNS = $strgDNS.Split('.')

 $storageAccountName = $splitDNS[0]

 # add uri and storage account name to custom PSobject

 $PSobjSourceStorage = New-Object -TypeName PSObject

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcStorageAccount -Value $storageAccountName  

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $srcURI

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcName -Value $srcName

 # retrieve storage account key and storage context

 $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName).Value[0]

 $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

 # add storage context to psObject

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageContext -Value $StorageContext 

 # get storage account and add other attributes to psCustom object

 $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageEncryption -Value $storageAccount.Encryption

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageCustomDomain -Value $storageAccount.CustomDomain

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageKind -Value $storageAccount.Kind

 $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageAccessTier -Value $storageAccount.AccessTier

 # get storage account sku and convert to string that is required for creation

 $skuName = $storageAccount.sku.Name



 switch ($skuName) 

     { 

         'StandardLRS'   {$skuName = 'Standard_LRS'}

         'Standard_LRS'   {$skuName = 'Standard_LRS'}  

         'StandardZRS'   {$skuName = 'Standard_ZRS'} 

         'StandardGRS'   {$skuName = 'Standard_GRS'} 

         'StandardRAGRS'{$skuName = 'Standard_RAGRS'} 

         'PremiumLRS'   {$skuName = 'Premium_LRS'} 

         'Premium_LRS'   {$skuName = 'Premium_LRS'} 

         default {$skuName = 'Standard_LRS'}

     }

  

  $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcSkuName -Value $skuName

 

 return $PSobjSourceStorage



} # end of Get-StorageObject function


<###############################

get available resources function

################################>

function Get-AvailableResources

{ param($resourceType, $location)



 $resource = Get-AzVMUsage -Location $location | Where-Object{$_.Name.value -eq $resourceType}

 [int32]$availabe = $resource.limit - $resource.currentvalue

 return $availabe 



}


<###############################

get blob copy status

################################>

function Get-BlobCopyStatus

{ param($context, $containerName, $blobName)

 

 if($blobName)

 {

     write-verbose "Checking VHD blob copy for $blobName" -verbose

     $blob = Get-AzStorageBlob -Context $context -container $containerName -Blob $blobName

 }

 else

 {

     write-verbose "Checking VHD blob copy for container $containerName" -verbose 

     $blob = Get-AzStorageBlob -Context $context -container $containerName 

 }



 do

 {

     $rtn = $blob | Get-AzStorageBlobCopyState

     $rtn | Select-Object Source, Status, BytesCopied, TotalBytes | Format-List

     if($rtn.status  -ne 'Success')

     {

         write-warning "VHD blob copy is not complete"

         $rh = read-host "Press <Enter> to refresh or type EXIT and press <Enter> to quit copy status updates and resume later"

         if(($rh.ToLower()) -eq 'exit')

         {

             write-output "Run script with -resume switch to continue creating VMs after file copy has completed."

             BREAK

         }

     }

 }

 while($rtn.status  -ne 'Success')



 # exit script if user breaks out of above loop   

 if($rtn.status  -ne 'Success'){EXIT}



}



<###############################

Copy blob function

################################>

function copy-azureBlob 

{  param($srcUri, $srcContext, $destContext, $containerName)





 $split = $srcURI.Split('/')

 $blobName = $split[($split.count -1)]

 $blobSplit = $blobName.Split('.')

 $extension = $blobSplit[($blobSplit.count -1)]

 if($($extension.tolower()) -eq 'status' ){Write-Output "Status file blob $blobname skipped";return}



 if(! $containerName){$containerName = $split[3]}



 # add full path back to blobname 

 if($split.count -gt 5) 

   { 

     $i = 4

     do

     {

         $path = $path + "/" + $split[$i]

         $i++

     }

     while($i -lt $split.length -1)



     $blobName= $path + '/' + $blobName

     $blobName = $blobName.Trim()

     $blobName = $blobName.Substring(1, $blobName.Length-1)

   }

 

# create container if doesn't exist    

 if (!(Get-AzStorageContainer -Context $destContext -Name $containerName -ea SilentlyContinue)) 

 { 

      try

      {

         $newRtn = New-AzStorageContainer -Context $destContext -Name $containerName -Permission Off -ea Stop 

         Write-Output "Container $($newRtn.name) was created." 

      }

      catch

      {

          $_ ; break

      }

 } 





try 

{

     $blobCopy = Start-AzStorageBlobCopy -ea Stop `

         -srcUri $srcUri `

         -SrcContext $srcContext `

         -DestContainer $containerName `

         -DestBlob $blobName `

         -DestContext $destContext 



      write-output "$srcUri is being copied to $containerName"

 

}

catch

{ 

   $_ ; write-warning "Failed to copy to $srcUri to $containerName"

}





} # end of copy-azureBlob function



if(! $resume)

{

 # create export JSON for backup purposes

 #$RGexport = Export-AzResourceGroup -ResourceGroupName $resourceGroupName -Path $jsonBackupPath -IncludeParameterDefaultValue -Force -wa SilentlyContinue



 # get configuration details for different resources

 [string] $location = $sourceResourceGroup.location

 $resourceGroupStorageAccounts = Get-AzStorageAccount -ResourceGroupName $resourceGroupName


 $resourceGroupWebApps = Get-AzWebApp -ResourceGroupName $resourceGroupName
 
 $resourceGroupsqlServer =  Get-AzSqlServer -ResourceGroupName $ResourceGroupName

 $resourceGroupsqldb = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $resourceGroupsqlServer.ServerName

 # display what we found

 write-host "The following Webapps are Present:" -f DarkGreen

 
 #write-host "Storage Accounts:" -f DarkGreen

 #$resourceGroupStorageAccounts.StorageAccountName

 #if(! $resourceGroupStorageAccounts){write-host "None" -ForegroundColor Red}

 write-host "Web Apps:" -f DarkGreen

 $resourceGroupWebApps.Name

 #write-host "SQL Server:" -f DarkGreen

 #$resourceGroupsqlServer.ServerName

 #if(! $resourceGroupsqlServer){write-host "None" -ForegroundColor Red}

 #write-host "Database:" -f DarkGreen

 $resourceGroupsqldb.DatabaseName

 if(! $resourceGroupsqldb){write-host "None" -ForegroundColor Red}


 # create temporary blob storage account to stage managed disks that will be copied 

 if($newLocation -and $location -ne $srcLocation -and $resourceGroupManagedDisks)

 {

     $cleanResourceGroupName = $resourceGroupName -replace "[^a-z0-9]", ""

     if($resourceGroupName.Length -gt 16){$first16 = $cleanResourceGroupName.Substring(0,16)}else{$first16 = $cleanResourceGroupName }

     [string] $guid = (New-Guid).Guid

     [string] $tempStorageAccountName = "$($first16.ToLower())"+($guid.Substring(0,8))


     $storageParams = @{

     "ResourceGroupName" = $resourceGroupName 

     "Name" = $tempstorageAccountName 

     "location" = $location

     "SkuName" = 'Standard_LRS'

     }

         

     # Create new storage account

     do
     {
         try
         {
             # create new storage account
             write-verbose "Creating temmporary storage account $tempstorageAccountName in resource group $resourceGroupName at location $location" -verbose
             $newStorageAccount = New-AzStorageAccount @storageParams -ea Stop -wa SilentlyContinue 
             write-output "The storage account $tempstorageAccountName was created"
         }
         catch
         {
             $_
             write-warning "Failed to create temporary storage account. Storage account name $DeststorageAccountName may already exists."
             $tempstorageAccountName = read-host   'Enter a different Temporary Storage Account Name. This is used to stage managed disks.'
         }
     }
     while(! $newStorageAccount)
     try 
     {
         # get key and storage context of newly created storage account
         $tempStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $tempStorageAccountName -ea Stop).Value[0] 
         $tempStorageContext = New-AzStorageContext -StorageAccountName $tempStorageAccountName -StorageAccountKey $tempStorageAccountKey -ea Stop -wa SilentlyContinue
         $tempContainer = New-AzStorageContainer -Name 'vhdblobs' -Context $tempStorageContext -Permission Blob  -ea Stop -wa SilentlyContinue
     }
     catch 
     {
         write-warning "Could not retrieve storage account key or storage context for $tempStorageAccountName . Exiting the script."
         break
     }
 }

$clientIp = "77.233.236.145"

# The IP Address is for Developers to Access Swagger within Office Network in CIDR Format



$rule1 = [PSCustomObject]@{
    vnetSubnetResourceId= "/subscriptions/$SubscriptionId/resourceGroups/$vnetresourceGroupName/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnetName"
    action = "Allow"
    tag= "Default"  
    priority = 1 
    name = "Access2AppGW" 
    description = "Access2AppGW"
}

$rule2 = [PSCustomObject]@{
    ipAddress = "$($clientIp)/32"
    action = "Allow"
    tag= "Default"  
    priority = 2 
    name = "SwaggerAccess" 
    description = "Access4Developers"
}



# Restrict/Unrestrict WebApps

      
if($action -eq "restrict" -and $action -eq "Restrict")
{
   
    foreach($srcWebApps in $resourceGroupWebApps)
 
   {
     $WebAppName = $srcWebApps.name     
     
     try

     {
         if($WebAppName -match "function")
     {
                 Add-AzureVnetRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName -rule $rule1
                 Add-AzureIpRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName -rule $rule2
     }
         else 
         {
                 Add-AzureVnetRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName -rule $rule1
                 Add-AzureIpRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName -rule $rule2
        }

     }

     catch
     {
         $_
         write-warning "Failed to Restrict $WebAppName"
     }
     
 }
 Write-Host "All App Services part of $resourceGroupName are Restricted to Allow Traffic only through Application Gateway VNet as well as Office IP"  -ForegroundColor DarkGreen
}
elseif($action -eq "unrestrict" -and $action -eq "Unrestrict")  
{
    foreach($srcWebApps in $resourceGroupWebApps)
 
    {
      $WebAppName = $srcWebApps.name     
      
      try
 
      {
          if($WebAppName -match "function")
      {
        Remove-AzureIpRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName
      }
          else 
          {
                  Remove-AzureIpRestrictionRule -ResourceGroupName $resourceGroupName -AppServiceName $WebAppName
         }
 
      }
 
      catch
      {
          $_
          write-warning "Failed to Remove Rule from $WebAppName"
      }
 
  }
  Write-Host "All App Services restrictions part of $resourceGroupName are removed"  -ForegroundColor DarkGreen
}
else 
{
    Write-Output "Please Input Action: Restrict/Unrestrict"
}


    
 



 
} 







