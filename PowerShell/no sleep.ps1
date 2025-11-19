#Add-Type -AssemblyName System.Windows.Forms

# Delay between key presses in milliseconds
$delay = 500  

Write-Host "Press Ctrl + C to stop the script."

while ($true) {
    # Press keys
    #[System.Windows.Forms.SendKeys]::SendWait('+{F15}')  # Ctrl(^) + Alt(%) # + Pause(BREAK)
    # New-Object -ComObject WScript.Shell.Sendkeys('{F7}')
    (New-Object -ComObject WScript.Shell).SendKeys('{F15}')
    Start-Sleep -Milliseconds $delay
}
