# lets do some simple common if statement exercise

$number = Read-Host @("What is your number?")

if ($number -gt 5) {
    Write-Host "$number is greather than 5"
}
else {
    Write-Host "Number is less or equal to 5"
}