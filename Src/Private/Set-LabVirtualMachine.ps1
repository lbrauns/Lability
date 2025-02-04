function Set-LabVirtualMachine {
<#
    .SYNOPSIS
        Invokes the current configuration a virtual machine.
    .DESCRIPTION
        Invokes/sets a virtual machine configuration using the xVMHyperV DSC resource.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $SwitchName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Media,

        [Parameter(Mandatory)]
        [System.UInt64] $StartupMemory,

        [Parameter(Mandatory)]
        [System.UInt64] $MinimumMemory,

        [Parameter(Mandatory)]
        [System.UInt64] $MaximumMemory,

        [Parameter(Mandatory)]
        [System.Int32] $ProcessorCount,

        [Parameter()]
        [AllowNull()]
        [System.String[]] $MACAddress,

        [Parameter()]
        [System.Boolean] $SecureBoot,

        [Parameter()]
        [System.Boolean] $GuestIntegrationServices,

        [Parameter()]
        [System.Boolean] $AutomaticCheckpoints,

        ## xVMProcessor options
        [Parameter()]
        [System.Collections.Hashtable] $ProcessorOption,

        ## xVMHardDiskDrive options
        [Parameter()]
        [System.Collections.Hashtable[]] $HardDiskDrive,

        ## xVMDvdDrive options
        [Parameter()]
        [System.Collections.Hashtable] $DvdDrive,

        ## xVMNetWorkAdapter options
        [Parameter()]
        [System.Collections.Hashtable[]] $NetAdapterConfiguration,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {

        ## Store additional options for when we have a VM
        $vmProcessorParams = $PSBoundParameters['ProcessorOption'];
        $vmDvdDriveParams = $PSBoundParameters['DvdDrive'];
        $vmHardDiskDriveParams = $PSBoundParameters['HardDiskDrive'];
        $vmNetAdapterConfiguration = $PSBoundParameters['NetAdapterConfiguration'];
        [ref] $null = $PSBoundParameters.Remove('ProcessorOption');
        [ref] $null = $PSBoundParameters.Remove('DvdDrive');
        [ref] $null = $PSBoundParameters.Remove('HardDiskDrive');
        [ref] $null = $PSBoundParameters.Remove('NetAdapterConfiguration');


        ## Resolve the xVMHyperV resource parameters
        $vmHyperVParams = Get-LabVirtualMachineProperty @PSBoundParameters;
        Write-Verbose -Message ($localized.CreatingVMGeneration -f $vmHyperVParams.Generation);
        Import-LabDscResource -ModuleName HyperVDsc -ResourceName DSC_VMHyperV -Prefix VM;

        Invoke-LabDscResource -ResourceName VM -Parameters $vmHyperVParams;

        if ($null -ne $vmProcessorParams) {

            ## Ensure we have the node's name
            $vmProcessorParams['VMName'] = $Name;
            Write-Verbose -Message ($localized.SettingVMConfiguration -f 'VM processor', $Name);
            Import-LabDscResource -ModuleName HyperVDsc -ResourceName DSC_VMProcessor -Prefix VMProcessor;
            Invoke-LabDscResource -ResourceName VMProcessor -Parameters $vmProcessorParams;
        }

        if ($null -ne $vmDvdDriveParams) {

            ## Ensure we have the node's name
            $vmDvdDriveParams['VMName'] = $Name;
            Write-Verbose -Message ($localized.SettingVMConfiguration -f 'VM DVD drive', $Name);
            Import-LabDscResource -ModuleName HyperVDsc -ResourceName DSC_VMDvdDrive -Prefix VMDvdDrive;
            Invoke-LabDscResource -ResourceName VMDvdDrive -Parameters $vmDvdDriveParams;
        }

        if ($null -ne $vmHardDiskDriveParams) {

            $setLabVirtualMachineHardDiskDriveParams = @{
                NodeName = $Name;
                VMGeneration = $vmHyperVParams.Generation;
                HardDiskDrive = $vmHardDiskDriveParams;
            }
            Set-LabVirtualMachineHardDiskDrive @setLabVirtualMachineHardDiskDriveParams;
        }

        if ($null -ne $vmNetAdapterConfiguration) {

            ## Ensure we have the node's name and splat params
            $setLabVirtualMachineNetworkAdapterParams = @{
                Nodename = $Name;
                NetAdapterConfiguration = $vmNetAdapterConfiguration
                ConfigurationData = $ConfigurationData
            }
            
            Set-LabVirtualMachineNetworkAdapter @setLabVirtualMachineNetworkAdapterParams
            
        }

    } #end process
} #end function
