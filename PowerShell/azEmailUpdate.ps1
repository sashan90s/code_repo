Import-Module Az -Force

# Install if not already done
# Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph.Users
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Import your CSV
$users = Import-Csv "C:\GuestEmailUpdate.csv" # OldEmail, NewEmail

foreach ($u in $users) {
    # Find guest by old email in Mail or OtherMails
    $guest = Get-MgUser -Filter "userType eq 'Guest'" -All | Where-Object { $_.Mail -eq $u.OldEmail -or $_.OtherMails -contains $u.OldEmail }
    if ($guest) {
        Write-Host "Updating guest $($guest.DisplayName) to $($u.NewEmail)"
        # Update Mail and add to OtherMails
        Update-MgUser -UserId $guest.Id -Mail $u.NewEmail -OtherMails @($u.NewEmail, $u.OldEmail)
    } else {
        Write-Warning "Guest with email $($u.OldEmail) not found!"
    }
}