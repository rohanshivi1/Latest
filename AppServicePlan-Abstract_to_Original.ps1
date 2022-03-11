



### New Plan to New Plan with Original Name
$appservicename_Source2 = "persister"
$appservicename_Destination2 = "persister"
### Old Plan to New Plan with Abstract Name
$appservicename_Source1 = "persister1"
$appservicename_Destination1 = "persister-p3v3"



$AppServicePlan_Source1 = "pac-serviceplan"
$AppServicePlan_Destination1 = "pac-serviceplan-p3v3t"

$AppServicePlan_Source2 = "pac-serviceplan-p3v3-uat"
$AppServicePlan_Destination2 = "pac-serviceplan"



$AzureResourceGroup_Source = "12-aa-rg"
$AzureResourceGroup_Destination = "12-bb-rg"

$VaultName = "pac-key-vault-uat"


####### Capture the Object ID of the App Service
$ID_Source = (Get-AzResource -Name $appservicename_Source1 -ResourceType Microsoft.Web/sites).Identity.PrincipalId
echo $ID_Source

###### Remove the Web App from the Access Policy
Remove-AzKeyVaultAccessPolicy -VaultName $VaultName -ObjectID $ID_Source

###### Remove the Webapp
Remove-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Source1


$srcapp = Get-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Source2
Write-Output "Cloning  "$appservicename_Source2"  Creating  "$appservicename_Destination2

New-AzWebApp -ResourceGroupName $AzureResourceGroup_Destination -Name $appservicename_Destination2 -Location "North Europe" -AppServicePlan $AppServicePlan_Destination2 -SourceWebApp $srcapp
Timeout 5
Set-AzWebApp -AssignIdentity $true -Name $appservicename_Destination2 -ResourceGroupName $AzureResourceGroup_Destination 
Write-Output "Identity Service Enabled"


$ID = (Get-AzResource -Name $appservicename_Destination2 -ResourceType Microsoft.Web/sites).Identity.PrincipalId
echo $ID
Timeout 15
Set-AzKeyVaultAccessPolicy -VaultName $VaultName -ObjectId $ID -PermissionsToKeys create,import,delete,list -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge -PassThru
Write-Output "New App Service Added to KeyVault"
Timeout 5

Restart-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Destination2


####### Capture the Object ID of the App Service
$ID_Source = (Get-AzResource -Name $appservicename_Source2 -ResourceType Microsoft.Web/sites).Identity.PrincipalId
echo $ID_Source

###### Remove the Web App from the Access Policy
Remove-AzKeyVaultAccessPolicy -VaultName $VaultName -ObjectID $ID_Source
Timeout 5
###### Remove the Webapp
Remove-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Source2
