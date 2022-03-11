####################################################################################################################################################
# June 19th 2019  -- Rohan Sharma
#  Script Name         : webappsstopstartrestart.ps1 
#  Script Objective:
#  For Stop, Start or Restart the Webpps as Part of the Resource Group
#       a) Checks the Resource Group 
#       b) Creates a Temp Blob to Store the WebApp of a Particular Resource Group.
#       c) Starts, Stops or Restarts the Applications
#       d) Outputs the Current State of the Applications
#
#Prompt1               : Credentials for Connecting to Azure (UserName/Password)
#Prompt2               : Conditional Prompt invoked if the User has Multiple Subscriptions
#
#Command Usage: ./webappsstopstartrestart.ps1 <ResourceGroup> <Stop/Start/Restart> (e.g. ./webappsstopstartrestart payments_clearing-prod-rg restart)
######################################################################################################################################################



#Requires -Version 4.0

param (
#[Parameter(Mandatory=$true)][string]$resourceGroupName,
#[Parameter(Mandatory=$true)][string]$action
)

$resourceGroupName = "aa-rg"
$LogFile = "api-20210829.log"



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





<###############################



Read resource group from old Sub



################################>



# Verify specified Environment

if($Environment -and (Get-AzEnvironment -Name $Environment) -eq $null)

{

write-warning "The specified -Environment could not be found. Specify one of these valid environments."

$Environment = (Get-AzEnvironment | Select-Object Name, ManagementPortalUrl | Out-GridView -title "Select a valid Azure environment for your subscription" -OutputMode Single).Name

}



# get Azure creds for source

write-host "Enter credentials for your Azure Subscription..." -f Yellow

if($Environment)

{

$login= Connect-AzAccount -EnvironmentName $Environment

}

else

{

$login= Connect-AzAccount 

} 

$loginID = $login.context.account.id

$sub = Get-AzSubscription 

$SubscriptionId = $sub.Id





# check for multiple subs under same account and force user to pick one

if($sub.count -gt 1) 

{

 $SubscriptionId = (Get-AzSubscription | Select-Object * | Out-GridView -title "Select Target Subscription" -OutputMode Single).Id

 Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null

 $sub = Get-AzSubscription -SubscriptionId $SubscriptionId

}







# check for valid sub

if(! $SubscriptionId) 

{

write-warning "The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."

break

}



$SubscriptionName = $sub.Name



write-host "Logged into $SubscriptionName with subscriptionID $SubscriptionId as $loginID" -f Green



# check for valid source resource group

if(-not ($sourceResourceGroup = Get-AzResourceGroup  -ResourceGroupName $resourceGroupName)) 

{

write-warning "The provided resource group $resourceGroupName could not be found. Exiting the script."

break

}



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

# Action to WebApps



    Write-Output "Failover!!!!"  

    foreach($srcWebApps in $resourceGroupWebApps)

    {
    
        $WebAppName = $srcWebApps.name     
     
     try

     {
         if($WebAppName -match "function")
         {
         $DownloadFileName = "C:\temp\$WebAppName$LogFile"
         $ErrorFileName = "$DownloadFileName_Error.log"
         $WebApp = Get-AzWebApp -Name $WebAppName -ResourceGroupName $resourceGroupName
         [xml]$publishingProfile = Get-AzWebAppPublishingProfile -WebApp $WebApp
         $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingProfile.publishData.publishProfile[0].userName,$publishingProfile.publishData.publishProfile[0].userPWD)))
         $apiUrl = "https://$WebAppName.scm.azurewebsites.net/api/vfs/LogFiles/$LogFile"
         Invoke-WebRequest -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method GET -OutFile $DownloadFileName -ContentType "multipart/form-data"
         Get-Content -Path $DownloadFileName | Where-Object {$_.Contains("[ERR]") } #>> $ErrorFileName
         Remove-Item $DownloadFileName
         }
     
         else {
            $DownloadFileName = "C:\temp\$WebAppName$LogFile"
            $ErrorFileName = "$DownloadFileName_Error.log"
            $WebApp = Get-AzWebApp -Name $WebAppName -ResourceGroupName $resourceGroupName
            [xml]$publishingProfile = Get-AzWebAppPublishingProfile -WebApp $WebApp
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingProfile.publishData.publishProfile[0].userName,$publishingProfile.publishData.publishProfile[0].userPWD)))
            $apiUrl = "https://$WebAppName.scm.azurewebsites.net/api/vfs/LogFiles/$LogFile"
            Invoke-WebRequest -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method GET -OutFile $DownloadFileName -ContentType "multipart/form-data"
            Get-Content -Path $DownloadFileName | Where-Object {$_.Contains("[ERR]") } #>> $ErrorFileName
            Remove-Item $DownloadFileName
         }
     }

     catch
     {
         $_
         #write-warning "Failed to Stop $WebAppName"
     }


 }
    







 
} 







