
Remove-Item .\PowerShell.ps1

$NewFilePath = "E:\programming\azure_dataengineering\all codes\code_repo\PowerShell.ps1"

if (Test-Path -Path $NewFilePath -PathType Leaf) {
    Copy-Item $NewFilePath -Destination .
    Write-Host "I have copoed it into $(pwd)"
    Get-Content -Path .\PowerShell.ps1
}
else {
    Write-Host "not a copied"
}


