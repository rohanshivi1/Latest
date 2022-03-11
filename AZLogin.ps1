
######## Login Stub for Azure
###########  Rohan Sharma (25th Aug 2019)  ##########

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
######## Login Stub Ends
