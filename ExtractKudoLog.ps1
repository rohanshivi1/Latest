<#
    .DESCRIPTION
        Extracts Kudu log file from an Azure App Service to local disk
    .NOTES
        AUTHOR: David P
        LASTEDIT: 25 May 2021

        Please complete the parameters  
        $ResourceGroupName : The resource group that the app service is in
        $AppName           : The name of the app service
        $LogFile           : The log file you wish to extract It will be in the format "api-yyyyMMdd.log"
        $DownloadFileName  : The local folder where you want to download the file
#>
Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# ********* you may need to install these. You will need admin permissions on your VD
#Install-Module -Name Az.WebSites -AllowClobber -Force
#Install-Module -Name Az.Accounts -AllowClobber -Force


# Parameters
$ResourceGroupName = "11-rg"
$AppName = "aa-app"
$LogFile = "api-20210804.log"
$DownloadFileName = "C:\temp\$AppName-$LogFile"
# EOF Parameters

# Do NOT touch the code below on pain of death
$SubscriptionID = "ID"
$TenantID = "Tenant"

#$User = "rohanshivi1@gmail.com"
#$PWord = ConvertTo-SecureString –String "" –AsPlainText -Force
#$Credential = New-Object –TypeName "System.Management.Automation.PSCredential" –ArgumentList $User, $PWord

#Connect-AzAccount -Subscription $SubscriptionID -Tenant $TenantID -Credential $Credential 

$WebApp = Get-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroupName
[xml]$publishingProfile = Get-AzWebAppPublishingProfile -WebApp $WebApp
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingProfile.publishData.publishProfile[0].userName,$publishingProfile.publishData.publishProfile[0].userPWD)))
$apiUrl = "https://$AppName.scm.azurewebsites.net/api/vfs/LogFiles/$LogFile"

#Download the file
Invoke-WebRequest -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method GET -OutFile $DownloadFileName -ContentType "multipart/form-data"


#Get-Content -Path $DownloadFileName | Where-Object {$_.Contains("[ERR]") }

Get-Content -Path $DownloadFileName | Where-Object {$_.Contains("MicroService stopped") }
#Get-Content -Path $DownloadFileName | Where-Object {$_.Contains("MicroService started") }

Remove-Item $DownloadFileName
