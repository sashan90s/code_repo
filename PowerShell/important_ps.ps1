# this file will hold some of the weirdly important command
#Get-Date | gm

$datevar = Get-Date

$datevar.Date #There is no way you can get just the date. 

$datevar.DayOfWeek

Write-Host "Today's date $($datevar)"
Write-Host "90 days before today $($datevar.AddDays(-90))"



$pw = Get-ChildItem $pshome/powershell.exe

Write-host $pw

# $pw|gm

# $pw|gm -MemberType Property

$pw.CreationTime

$pw.CreationTime

$justdate = $pw.CreationTime

$justdate.ToShortDateString() # it is a method so you gotta use bracket







