#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Copilot Configure Me Quick - Interactive PowerShell Wizard
    
.DESCRIPTION
    An interactive command-line wizard for managing Microsoft 365 Copilot connectors,
    licensing, compliance, and reporting through PowerShell and Microsoft Graph.
    
.EXAMPLE
    .\Start-CopilotConfigWizard.ps1
    
.NOTES
    Author: Jason Baxter
    Version: 1.0.0
    Requires: Global Admin or Copilot Service Admin role
#>

param(
    [switch]$NonInteractive = $false,
    [string]$LogPath = "$PSScriptRoot\logs"
)

# ===================================
# Initialize Environment
# ===================================
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

$Script:ScriptRoot = $PSScriptRoot
$Script:LogPath = $LogPath
$Script:ModulesPath = Join-Path $PSScriptRoot "modules"
$Script:FunctionsPath = Join-Path $PSScriptRoot "functions"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# ===================================
# Load Modules and Functions
# ===================================
function Import-CopilotModules {
    param()
    
    Write-Host "Loading Copilot modules..." -ForegroundColor Cyan
    
    $modules = @(
        "CopilotUI.psm1",
        "CopilotCore.psm1",
        "CopilotConnectors.psm1",
        "CopilotLicensing.psm1",
        "CopilotCompliance.psm1",
        "CopilotReporting.psm1",
        "CopilotFrontier.psm1"
    )
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $Script:ModulesPath $module
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Loaded: $module" -ForegroundColor Green
        } else {
            Write-Host "⚠ Module not found: $modulePath" -ForegroundColor Yellow
        }
    }
}

function Import-CopilotFunctions {
    param()
    
    Write-Host "Loading Copilot functions..." -ForegroundColor Cyan
    
    if (Test-Path $Script:FunctionsPath) {
        Get-ChildItem -Path $Script:FunctionsPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Host "✓ Loaded: $($_.BaseName)" -ForegroundColor Green
        }
    }
}

# ===================================
# Main Menu System
# ===================================
function Show-MainMenu {
    param()
    
    Write-Host "" 
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         COPILOT CONFIGURE ME QUICK - Main Menu                    ║" -ForegroundColor Cyan
    Write-Host "║         Microsoft 365 Copilot Administration Wizard               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $menuOptions = @(
        "1. Check Prerequisites & Requirements",
        "2. Connect to Microsoft Graph",
        "3. Manage Copilot Connectors",
        "4. Check Frontier Configuration",
        "5. Check Add-Ins Deployment Status",
        "6. Manage User Licensing",
        "7. Configure Compliance & Security",
        "8. Generate Reports & Monitoring",
        "9. Advanced Options",
        "10. Exit Wizard"
    )
    
    foreach ($option in $menuOptions) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-10)"
    
    return $selection
}

# ===================================
# Menu Handlers
# ===================================
function Invoke-PrerequisitesCheck {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "CHECKING PREREQUISITES" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Check PowerShell version
    Write-Host "`n[1/4] Checking PowerShell Version..." -ForegroundColor Yellow
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-Host "✓ PowerShell $($psVersion.Major).$($psVersion.Minor) - Compatible" -ForegroundColor Green
    } else {
        Write-Host "✗ PowerShell $($psVersion.Major).$($psVersion.Minor) - Requires 5.1 or higher" -ForegroundColor Red
    }
    
    # Check Admin Status
    Write-Host "`n[2/4] Checking Administrator Status..." -ForegroundColor Yellow
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        Write-Host "✓ Running as Administrator" -ForegroundColor Green
    } else {
        Write-Host "✗ Not running as Administrator - Restart PowerShell as Admin" -ForegroundColor Red
    }
    
    # Check Execution Policy
    Write-Host "`n[3/4] Checking Execution Policy..." -ForegroundColor Yellow
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
        Write-Host "✓ Execution Policy: $execPolicy" -ForegroundColor Green
    } else {
        Write-Host "⚠ Execution Policy: $execPolicy - May need adjustment" -ForegroundColor Yellow
        Write-Host "  Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
    }
    
    # Check Microsoft.Graph Module
    Write-Host "`n[4/4] Checking Microsoft.Graph Module..." -ForegroundColor Yellow
    $graphModule = Get-Module Microsoft.Graph -ListAvailable -ErrorAction SilentlyContinue
    if ($graphModule) {
        Write-Host "✓ Microsoft.Graph installed (v$($graphModule.Version | Select-Object -First 1))" -ForegroundColor Green
    } else {
        Write-Host "✗ Microsoft.Graph not installed" -ForegroundColor Red
        Write-Host "  Run: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Gray
    }
    
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ConnectorManagement {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "COPILOT CONNECTORS MANAGEMENT" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $connectorMenu = @(
        "1. List All Available Connectors",
        "2. Get Connector Details",
        "3. Enable/Disable Connector",
        "4. Configure Connector Settings",
        "5. Assign Connector to Group",
        "6. Create Custom Connector",
        "7. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $connectorMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-7)"
    
    switch ($selection) {
        "1" { Get-CopilotConnectorList }
        "2" { Get-CopilotConnectorDetails }
        "3" { Set-CopilotConnectorStatus }
        "4" { Configure-CopilotConnectorSettings }
        "5" { Set-CopilotConnectorGroupAssignment }
        "6" { New-CopilotCustomConnector }
        "7" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

function Invoke-FrontierCheck {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "COPILOT FRONTIER CONFIGURATION CHECK" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $frontierMenu = @(
        "1. Check Frontier Status for All Users",
        "2. Check Frontier Status for Specific User",
        "3. Enable Frontier for All Users",
        "4. Enable Frontier for Specific Group",
        "5. Get Frontier Configuration Report",
        "6. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $frontierMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-6)"
    
    switch ($selection) {
        "1" { Get-CopilotFrontierStatus -AllUsers }
        "2" { Get-CopilotFrontierStatus }
        "3" { Enable-CopilotFrontierAllUsers }
        "4" { Enable-CopilotFrontierForGroup }
        "5" { Get-CopilotFrontierReport }
        "6" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

function Invoke-AddInsCheck {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "MICROSOFT 365 ADD-INS DEPLOYMENT STATUS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $addInsMenu = @(
        "1. Check Sales Add-In Deployment",
        "2. Check Service Add-In Deployment",
        "3. Check Finance Add-In Deployment",
        "4. Check All Add-Ins Deployment Status",
        "5. Deploy Sales Add-In",
        "6. Deploy Service Add-In",
        "7. Deploy Finance Add-In",
        "8. Generate Add-Ins Report",
        "9. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $addInsMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-9)"
    
    switch ($selection) {
        "1" { Get-CopilotAddInDeploymentStatus -AddInName "Sales" }
        "2" { Get-CopilotAddInDeploymentStatus -AddInName "Service" }
        "3" { Get-CopilotAddInDeploymentStatus -AddInName "Finance" }
        "4" { Get-CopilotAddInDeploymentStatus -AllAddIns }
        "5" { Deploy-CopilotAddIn -AddInName "Sales" }
        "6" { Deploy-CopilotAddIn -AddInName "Service" }
        "7" { Deploy-CopilotAddIn -AddInName "Finance" }
        "8" { Get-AddInDeploymentReport }
        "9" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

function Invoke-LicensingManagement {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "USER LICENSING MANAGEMENT" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $licensingMenu = @(
        "1. Check Available Licenses",
        "2. Assign License to User",
        "3. Bulk Assign Licenses (CSV Import)",
        "4. Remove License from User",
        "5. Get User License Status",
        "6. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $licensingMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-6)"
    
    switch ($selection) {
        "1" { Get-CopilotAvailableLicenses }
        "2" { Set-CopilotUserLicense }
        "3" { Import-CopilotBulkLicenses }
        "4" { Remove-CopilotUserLicense }
        "5" { Get-CopilotLicenseStatus }
        "6" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

function Invoke-ComplianceManagement {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "COMPLIANCE & SECURITY CONFIGURATION" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $complianceMenu = @(
        "1. Configure Data Access Policies",
        "2. Review Audit Logging Settings",
        "3. Set Conditional Access Rules",
        "4. Configure DLP Policies for Copilot",
        "5. Review Compliance Boundaries",
        "6. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $complianceMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-6)"
    
    switch ($selection) {
        "1" { Configure-DataAccessPolicies }
        "2" { Review-AuditLogging }
        "3" { Set-ConditionalAccessRules }
        "4" { Configure-DLPPolicies }
        "5" { Review-ComplianceBoundaries }
        "6" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

function Invoke-ReportingMonitoring {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "REPORTING & MONITORING" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $reportMenu = @(
        "1. Copilot Adoption Report",
        "2. License Usage Report",
        "3. Connector Usage Report",
        "4. Audit Logs Report",
        "5. Export All Reports to CSV",
        "6. Back to Main Menu"
    )
    
    Write-Host ""
    foreach ($option in $reportMenu) {
        Write-Host $option -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Select an option (1-6)"
    
    switch ($selection) {
        "1" { Get-CopilotAdoptionReport }
        "2" { Get-LicenseUsageReport }
        "3" { Get-ConnectorUsageReport }
        "4" { Get-AuditLogsReport }
        "5" { Export-AllCopilotReports }
        "6" { return }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
}

# ===================================
# Main Loop
# ===================================
function Start-WizardLoop {
    do {
        $selection = Show-MainMenu
        
        switch ($selection) {
            "1" { Invoke-PrerequisitesCheck }
            "2" { Invoke-GraphConnection }
            "3" { Invoke-ConnectorManagement }
            "4" { Invoke-FrontierCheck }
            "5" { Invoke-AddInsCheck }
            "6" { Invoke-LicensingManagement }
            "7" { Invoke-ComplianceManagement }
            "8" { Invoke-ReportingMonitoring }
            "9" { Invoke-AdvancedOptions }
            "10" { 
                Write-Host "`nExiting Copilot Configure Me Quick..." -ForegroundColor Green
                Write-Host "Thank you for using the wizard!" -ForegroundColor Green
                exit 0
            }
            default { 
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# ===================================
# Placeholder Functions (To be implemented)
# ===================================
function Invoke-GraphConnection {
    Write-Host "`nConnecting to Microsoft Graph..." -ForegroundColor Cyan
    try {
        $requiredScopes = @(
            "User.Read.All",
            "Directory.Read.All",
            "Organization.Read.All",
            "Reports.Read.All",
            "AuditLog.Read.All"
        )
        
        Connect-MgGraph -Scopes $requiredScopes -ErrorAction Stop
        Write-Host "✓ Successfully connected to Microsoft Graph" -ForegroundColor Green
        Get-MgContext
    } catch {
        Write-Host "✗ Failed to connect: $_" -ForegroundColor Red
    }
    
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-AdvancedOptions {
    Write-Host "`nAdvanced options not yet implemented" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

# Stub functions - to be moved to modules
function Get-CopilotConnectorList { Write-Host "Getting connector list..." -ForegroundColor Cyan }
function Get-CopilotConnectorDetails { Write-Host "Getting connector details..." -ForegroundColor Cyan }
function Set-CopilotConnectorStatus { Write-Host "Setting connector status..." -ForegroundColor Cyan }
function Configure-CopilotConnectorSettings { Write-Host "Configuring connector settings..." -ForegroundColor Cyan }
function Set-CopilotConnectorGroupAssignment { Write-Host "Assigning connector to group..." -ForegroundColor Cyan }
function New-CopilotCustomConnector { Write-Host "Creating custom connector..." -ForegroundColor Cyan }
function Get-CopilotFrontierStatus { Write-Host "Getting Frontier status..." -ForegroundColor Cyan }
function Enable-CopilotFrontierAllUsers { Write-Host "Enabling Frontier for all users..." -ForegroundColor Cyan }
function Enable-CopilotFrontierForGroup { Write-Host "Enabling Frontier for group..." -ForegroundColor Cyan }
function Get-CopilotFrontierReport { Write-Host "Generating Frontier report..." -ForegroundColor Cyan }
function Get-CopilotAddInDeploymentStatus { Write-Host "Checking Add-In deployment status..." -ForegroundColor Cyan }
function Deploy-CopilotAddIn { Write-Host "Deploying Add-In..." -ForegroundColor Cyan }
function Get-AddInDeploymentReport { Write-Host "Generating Add-In deployment report..." -ForegroundColor Cyan }
function Get-CopilotAvailableLicenses { Write-Host "Getting available licenses..." -ForegroundColor Cyan }
function Set-CopilotUserLicense { Write-Host "Setting user license..." -ForegroundColor Cyan }
function Import-CopilotBulkLicenses { Write-Host "Importing bulk licenses..." -ForegroundColor Cyan }
function Remove-CopilotUserLicense { Write-Host "Removing user license..." -ForegroundColor Cyan }
function Get-CopilotLicenseStatus { Write-Host "Getting license status..." -ForegroundColor Cyan }
function Configure-DataAccessPolicies { Write-Host "Configuring data access policies..." -ForegroundColor Cyan }
function Review-AuditLogging { Write-Host "Reviewing audit logging..." -ForegroundColor Cyan }
function Set-ConditionalAccessRules { Write-Host "Setting conditional access rules..." -ForegroundColor Cyan }
function Configure-DLPPolicies { Write-Host "Configuring DLP policies..." -ForegroundColor Cyan }
function Review-ComplianceBoundaries { Write-Host "Reviewing compliance boundaries..." -ForegroundColor Cyan }
function Get-CopilotAdoptionReport { Write-Host "Getting adoption report..." -ForegroundColor Cyan }
function Get-LicenseUsageReport { Write-Host "Getting license usage report..." -ForegroundColor Cyan }
function Get-ConnectorUsageReport { Write-Host "Getting connector usage report..." -ForegroundColor Cyan }
function Get-AuditLogsReport { Write-Host "Getting audit logs report..." -ForegroundColor Cyan }
function Export-AllCopilotReports { Write-Host "Exporting all reports..." -ForegroundColor Cyan }

# ===================================
# Entry Point
# ===================================
if ($PSBoundParameters.Count -eq 0) {
    # Import all modules and functions
    # Import-CopilotModules
    # Import-CopilotFunctions
    
    # Start main wizard loop
    Start-WizardLoop
}
