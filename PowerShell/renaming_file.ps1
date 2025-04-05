# Set the folder path where your files are and waiting for renaming
param ( [string]$folderPath, [string]$oldString, [string]$newString )


$folderPath = $folderPath

# Set the portion of the filename you want to replace
$oldString = $oldString
$newString = $newString

# Get all the files in the folder
$files = Get-ChildItem -Path $folderPath


# Loop through each file and rename it
foreach ($file in $files) {
    # Check if the old string exists in the file name
    if ($file.Name -like "*$oldString*") {
        # Create the new file name by replacing the old string with the new string
        $newName = $file.Name -replace $oldString, $newString
        
        $oldFilePath = $file
        
        Rename-Item -Path $oldFilePath  -NewName $newName
        Write-Host "Renamed '$($file.Name)' to '$newName'"
    }
}
