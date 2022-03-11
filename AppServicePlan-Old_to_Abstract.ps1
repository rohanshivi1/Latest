
### Old Plan to New Plan with Abstract Name
$appservicename_Source1 = "persister-uat"
$appservicename_Destination1 = "persister-p3v3"

$AppServicePlan_Source1 = "serviceplan-uat"
$AppServicePlan_Destination1 = "serviceplan-p3v3"



$AzureResourceGroup_Source = "11-aa-rg"
$AzureResourceGroup_Destination = "12-bb-rg"

$VaultName = "aa-key-vault-env"

$srcapp = Get-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Source1
Write-Output "Cloning  "$appservicename_Source1"  Creating  "$appservicename_Destination1

New-AzWebApp -ResourceGroupName $AzureResourceGroup_Destination -Name $appservicename_Destination1 -Location "North Europe" -AppServicePlan $AppServicePlan_Destination1 -SourceWebApp $srcapp
Timeout 5
Set-AzWebApp -AssignIdentity $true -Name $appservicename_Destination1 -ResourceGroupName $AzureResourceGroup_Destination
Write-Output "Identity Service Enabled"

Timeout 15
$ID = (Get-AzResource -Name $appservicename_Destination1 -ResourceType Microsoft.Web/sites).Identity.PrincipalId
echo $ID
Timeout 5
Set-AzKeyVaultAccessPolicy -VaultName $VaultName -ObjectId $ID -PermissionsToKeys create,import,delete,list -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge -PassThru
Write-Output "New App Service Added to KeyVault"

Timeout 5
Restart-AzWebApp -ResourceGroupName $AzureResourceGroup_Source -Name $appservicename_Destination1

