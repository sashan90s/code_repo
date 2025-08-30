# Azure VM Start/Stop Script for PowerShell 7.5
# Requires Az PowerShell module

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VMName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "Hybernate", "Restart", "Status")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Function to install Az module if not present
<#
function Install-AzModuleIfNeeded {
    if (-not (Get-Module -ListAvailable -Name Az)) {
        Write-Host "Az module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
    }
}
#>

# Function to connect to Azure
function Connect-ToAzure {
    try {
        # Check if already connected
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Cyan
            Connect-AzAccount
        } else {
            Write-Host "Already connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        }
        
        # Set subscription if provided
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            Write-Host "Set subscription context to: $SubscriptionId" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        return $false
    }
}

# Function to get VM status
function Get-VMStatus {
    param($ResourceGroup, $Name)
    
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $powerState = ($vm.Statuses | Where-Object {$_.Code -like "PowerState/*"}).DisplayStatus
        
        Write-Host "VM Status Information:" -ForegroundColor Cyan
        Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
        Write-Host "  VM Name: $Name" -ForegroundColor White
        Write-Host "  Power State: $powerState" -ForegroundColor Yellow
        Write-Host "  Location: $($vm.Location)" -ForegroundColor White
        Write-Host "  VM Size: $($vm.HardwareProfile.VmSize)" -ForegroundColor White
        
        return $powerState
    }
    catch {
        Write-Error "Failed to get VM status: $($_.Exception.Message)"
        return $null
    }
}

# Function to start VM
function Start-AzureVM {
    param($ResourceGroup, $Name)
    
    Write-Host "Starting VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Yellow
    
    try {
        $result = Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name
        
        if ($result.IsSuccessStatusCode) {
            Write-Host "✓ VM '$Name' started successfully!" -ForegroundColor Green
        } else {
            Write-Warning "VM start operation completed with status: $($result.StatusCode)"
        }
        
        # Show final status
        Start-Sleep -Seconds 5
        Get-VMStatus -ResourceGroup $ResourceGroup -Name $Name
    }
    catch {
        Write-Error "Failed to start VM: $($_.Exception.Message)"
    }
}

# Function to Stop VM
function Stop-AzureVM {
    param($ResourceGroup, $Name)

    Write-Host "Stopping VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Yellow

    try {
        $result = Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force

        if ($result.IsSuccessStatusCode) {
            Write-Host "✓ VM '$Name' stopped successfully!" -ForegroundColor Green
        } else {
            Write-Warning "VM stop operation completed with status: $($result.StatusCode)"
        }
        
        # Show final status
        Start-Sleep -Seconds 5
        Get-VMStatus -ResourceGroup $ResourceGroup -Name $Name
    }
    catch {
        Write-Error "Failed to stop VM: $($_.Exception.Message)"
    }
}

# Function to hybernate VM
function Hybernate-AzureVM {
    param($ResourceGroup, $Name)

    Write-Host "Hybernating VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Yellow
    Write-Host "Note: This will deallocate the VM to save costs." -ForegroundColor Cyan
    
    try {
        $result = Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Hibernate
        
        if ($result.IsSuccessStatusCode) {
            Write-Host "✓ VM '$Name' hybernated and deallocated successfully!" -ForegroundColor Green
        } else {
            Write-Warning "VM hybernate operation completed with status: $($result.StatusCode)"
        }
        
        # Show final status
        Start-Sleep -Seconds 5
        Get-VMStatus -ResourceGroup $ResourceGroup -Name $Name
    }
    catch {
        Write-Error "Failed to hybernate VM: $($_.Exception.Message)"
    }
}

# Function to restart VM
function Restart-AzureVM {
    param($ResourceGroup, $Name)
    
    Write-Host "Restarting VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Yellow
    
    try {
        $result = Restart-AzVM -ResourceGroupName $ResourceGroup -Name $Name
        
        if ($result.IsSuccessStatusCode) {
            Write-Host "✓ VM '$Name' restarted successfully!" -ForegroundColor Green
        } else {
            Write-Warning "VM restart operation completed with status: $($result.StatusCode)"
        }
        
        # Show final status
        Start-Sleep -Seconds 5
        Get-VMStatus -ResourceGroup $ResourceGroup -Name $Name
    }
    catch {
        Write-Error "Failed to restart VM: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "=== Azure VM Management Script ===" -ForegroundColor Magenta
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray


# Import Az module
Import-Module Az -Force

# Connect to Azure
if (-not (Connect-ToAzure)) {
    Write-Error "Cannot proceed without Azure connection. Exiting."
    exit 1
}

# Execute the requested action
switch ($Action.ToLower()) {
    "start" {
        Start-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName
    }
    "stop" {
        Stop-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName
    }
    "Hybernate" {
        Hybernate-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName
    }
    "restart" {
        Restart-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName
    }
    "status" {
        Get-VMStatus -ResourceGroup $ResourceGroupName -Name $VMName
    }
}

Write-Host "`n=== Script completed ===" -ForegroundColor Magenta