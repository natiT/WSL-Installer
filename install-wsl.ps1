#Requires -RunAsAdministrator
param(
    [CmdletBinding()]
    [Parameter(HelpMessage = "WinGet ID (see https://winget.run/pkg/Canonical) ")]
    $distroID = "Canonical.Ubuntu.2204",
    [ValidateSet('LogModule')]
    $LogMode = "LogModule"
)

if (Get-Module -ListAvailable -Name Logging)
{
    Write-Host "Loading Logging Module"
    Import-Module Logging
}
else
{
    Write-Host "Install and Loading Logging Module"
    Install-Module Logging -SkipPublisherCheck -Force -AcceptLicense
    Import-Module Logging
}

if (Get-Module -Name Logging)
{
    Set-LoggingDefaultLevel -Level 'INFO'
    Add-LoggingTarget -Name Console
    Add-LoggingTarget -Name File -Configuration @{Path = 'C:\Temp\WSL-Install_%{+%Y%m%d}.log' }
}

Write-Log -Message "Start Logging installation Process"
Write-Log -Message "Check for Winget"
Get-Command winget
if ($? -eq $false)
{
    Write-Log -Message "WinGet is not installed. Abort Execution. Please Install WinGet (https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1)" -Level ERROR
    Read-Host -Prompt "Press Key to end Install Process"
    exit 1
}

Write-Log -Message "Check for required Windows Features"
if ((Get-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online).State -eq "Disabled")
{
    $missingFeature = $true
    Write-Log -Message "VirtualMachinePlatform is not installed. Installing..."
    Enable-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -NoRestart -All
}
if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online).State -eq "Disabled")
{
    $missingFeature = $true
    Write-Log -Message "Microsoft-Windows-Subsystem-Linux is not installed. Installing..."
    Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -NoRestart -All
}
if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq "Disabled")
{
    $missingFeature = $true
    Write-Log -Message "Microsoft-Hyper-V-All is not installed. Installing..."
    Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -NoRestart -All
}

if($missingFeature -eq $true){
    Write-Log "Reboot may be required because of the installation of missing Features. If the Script failes. Restart and run again!" -Level WARNING
}

Write-Log "check for DistroID `"$distroID`" with winget search"
$wingetSearch = Start-Process winget -ArgumentList "search --id $distroID" -Wait -NoNewWindow -PassThru
if($wingetSearch -ne "0")
{
    Write-Log "Winget could not find the Distribution." -Level ERROR
    Read-Host -Prompt "Press Key to end Install Process"
}
else{
    $wingetInstall = Start-Process winget -ArgumentList "install -e --id $distroID" -Wait -NoNewWindow -PassThru
    if($wingetInstall.ExitCode -ne 0)
    {
        Write-Log "Error while installing Distro. Exitcode: $($wingetInstall.ExitCode)"
    }
}

##dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /featurename:VirtualMachinePlatform /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart