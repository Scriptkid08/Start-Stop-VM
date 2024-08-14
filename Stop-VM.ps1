<#
.SYNOPSIS
    Connect to Azure using a managed identity and start all VMs in a specific resource group, skipping VMs that are already running.

.DESCRIPTION
    This script connects to Azure using a managed identity and iterates over each VM in the provided resource group.
    For each VM, it checks if the VM is already in a running state and skips it if it is. Otherwise, it will attempt to start the VM.

.PARAMETER ResourceGroupName
    The name of the resource group containing the VMs.

.NOTES
    Author: Aman Paswan
    Date: 2024-07-08
    Usage: Run the script with necessary permissions to manage Azure resources.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

# Enable strict mode for better scripting practices
Set-StrictMode -Version Latest

# Connect to Azure using managed identity
Connect-AzAccount -Identity

# Check if the resource group exists
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $ResourceGroup) {
    Write-Error "Resource group '$ResourceGroupName' does not exist. Exiting script."
    exit
}

# Get all VMs in the specified resource group
$VMs = Get-AzVM -ResourceGroupName $ResourceGroupName

foreach ($VM in $VMs) {
    # Get the status of the VM
    $VMStatus = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VM.Name -Status).Statuses | Where-Object Code -like 'PowerState/*'

    if ($VMStatus.Code -eq 'PowerState/deallocated' -or $VMStatus.Code -eq 'PowerState/stopped') {
        try {
            Write-Output "Starting VM: $($VM.Name)"
            Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VM.Name -ErrorAction Stop
            Write-Output "VM $($VM.Name) started successfully."
        } catch {
            Write-Error "Failed to start VM: $($VM.Name). Error: $_"
        }
    } else {
        Write-Output "VM $($VM.Name) is already running. Skipping."
    }
}
