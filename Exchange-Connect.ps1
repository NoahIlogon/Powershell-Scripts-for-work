<#
.SYNOPSIS
    Connects to Exchange Online using the admin account you supply.

.EXAMPLE
    .\Connect-EXO.ps1 -AdminAccount admin@contoso.com

.EXAMPLE
    # Partner/GDAP access to a client tenant
    .\Connect-EXO.ps1 -AdminAccount you@msp.com -DelegatedOrganization client.onmicrosoft.com
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Admin UPN, e.g. admin@contoso.com")]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$AdminAccount,

    # Optional: client tenant domain when connecting via delegated (GDAP) access
    [string]$DelegatedOrganization,

    # Optional: use device code auth (handy over SSH/remote sessions)
    [switch]$Device
)

# Make sure the ExchangeOnlineManagement module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install ExchangeOnlineManagement: $_"
        exit 1
    }
}

Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Drop any existing session so you don't end up in the wrong tenant
if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
    Write-Host "Disconnecting existing Exchange Online session..." -ForegroundColor Yellow
    Disconnect-ExchangeOnline -Confirm:$false
}

# Build connection parameters
$connectParams = @{
    UserPrincipalName = $AdminAccount
    ShowBanner        = $false
}
if ($DelegatedOrganization) { $connectParams.DelegatedOrganization = $DelegatedOrganization }
if ($Device)                { $connectParams.Device = $true }

try {
    Write-Host "Connecting to Exchange Online as $AdminAccount..." -ForegroundColor Cyan
    Connect-ExchangeOnline @connectParams -ErrorAction Stop

    $info = Get-ConnectionInformation | Select-Object -First 1
    Write-Host "Connected to tenant: $($info.TenantID) as $($info.UserPrincipalName)" -ForegroundColor Green
}
catch {
    Write-Error "Connection failed: $_"
    exit 1
}
