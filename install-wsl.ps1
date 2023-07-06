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

Write-Log -Message "Check for Winget"
Get-Command winget
if ($? -eq $false)
{
    Write-Log -Message "WinGet is not installed. Abort Execution. Please Install WinGet (https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1)" -Level ERROR
    Read-Host -Prompt "Press Key to end Install Process"
    exit 1
}


Write-Log "check for DistroID `"$distroID`" with winget search"
$wingetSearch = Start-Process winget -ArgumentList "search --id $distroID" -Wait -NoNewWindow -PassThru
if($wingetSearch.ExitCode -ne "0")
{
    Write-Log "Winget could not find the Distribution." -Level ERROR
    Read-Host -Prompt "Press Key to end Install Process"
    Exit 1
}
else{
    Write-Log "Install Distro with ID $distroID"
    $wingetInstall = Start-Process winget -ArgumentList "install -e --id $distroID" -Wait -NoNewWindow -PassThru
    if(0,-1978335189 -notcontains $wingetInstall.ExitCode )
    {
        Write-Log "Error while installing Distro. Exitcode: $($wingetInstall.ExitCode)"
    }
    else {
        Write-Log "Seems its already installed."
    }
}