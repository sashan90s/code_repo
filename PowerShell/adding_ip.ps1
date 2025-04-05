$rulename= 'SibbirSihan'


$my_ip = Invoke-RestMethod -Uri "http://ifconfig.me".Trim()

Write-Output $my_ip

$tenantId = '1f4a5522-5f5a-4974-8d95-9a032f4cf2e5'
$AppId = 'e21dd96b-3201-4268-b0de-5910e3e4b6b5'

$User = $AppId
$PWord = Read-Host -Prompt 'Enter a the app secret' -AsSecureString
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$pscredential = $Credential
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

<#
Connect-AzAccount -Tenant '1f4a5522-5f5a-4974-8d95-9a032f4cf2e5' -SubscriptionId 'dfcc6a4f-cc2d-4290-9191-84f570d94744'
Set-AzContext -SubscriptionId "dfcc6a4f-cc2d-4290-9191-84f570d94744"
#>


$RGname= 'Live'
$nsgname= 'nsg-diis-live-managedinstance'

Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname | 
Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow DE Computer" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority 1016 -SourceAddressPrefix $my_ip -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3342" | Set-AzNetworkSecurityGroup | Out-File -FilePath .\log.txt -Append


