$my_ip = Invoke-RestMethod -Uri "http://ifconfig.me".Trim()

Write-Output $my_ip



Connect-AzAccount -Tenant '1f4a5522-5f5a-4974-8d95-9a032f4cf2e5' -SubscriptionId 'dfcc6a4f-cc2d-4290-9191-84f570d94744'
Set-AzContext -SubscriptionId "dfcc6a4f-cc2d-4290-9191-84f570d94744"

$RGname="Live"
$rulename="SibbirSihan"
$nsgname="nsg-diis-live-managedinstance"




Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname | 
Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow DE Computer" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority 1016 -SourceAddressPrefix $my_ip -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3342" | Set-AzNetworkSecurityGroup


