
<# This powershell contains important powershell cmdlets and codes
This will be used in the future to copy and paste #>

Get-ChildItem -path *.txt | Format-Table -Property Mode, LastWriteTime | Where-Object {$_.LastWriteTime -lt
 $impo}


<# Copyright Sibbir Sihan #>




