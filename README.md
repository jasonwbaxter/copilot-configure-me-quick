# Copilot Configure Me Quick 🚀

An interactive PowerShell wizard for administering and configuring Microsoft 365 Copilot settings through PowerShell and Microsoft Graph APIs.

## Overview

This tool provides a command-line wizard experience that guides administrators through:

- ✅ Verifying prerequisites and permissions
- ✅ Installing required PowerShell modules
- ✅ Authenticating to Microsoft Graph
- ✅ Discovering Copilot licensing and SKUs
- ✅ Enabling/Disabling Copilot features per user or tenant
- ✅ Configuring data access and compliance policies
- ✅ Generating audit and reporting queries
- ✅ Creating bulk user assignments (not included in this repository)

## Quick Start

### Prerequisites

- **Windows PowerShell 5.1+** or **PowerShell 7+**
- **Global Administrator** or **Copilot Service Administrator** role
- Internet connectivity to Microsoft Graph endpoints

### Installation & Usage

```powershell
# Clone the repository
git clone https://github.com/jasonwbaxter/copilot-configure-me-quick.git
cd copilot-configure-me-quick

# Run the main wizard
.\Start-CopilotConfigWizard.ps1
```

Note: The wizard uses simple numeric menus (Read-Host) for navigation rather than arrow-key driven interfaces.

## Features

### 1. Interactive Menu System
Navigate through options using numeric selections (enter the number for the menu item and press Enter).

### 2. Prerequisites Check
- Validates PowerShell version
- Checks admin elevation status
- Verifies module installation requirements

### 3. Tenant Configuration
- Connect to your M365 tenant
- Display organization details
- List available Copilot licenses

### 4. User Management
- Assign Copilot licenses to individual users (functions not bundled in this repo)
- Bulk assign licenses via CSV import (not included here)
- Check user license status
- Remove Copilot access

### 5. Compliance & Security
- Configure data access policies
- Review audit logging settings
- Set Conditional Access rules
- Configure DLP policies for AI

### 6. Reports & Monitoring
- Generate Copilot adoption and readiness reports
- View usage statistics
- Export license status to CSV
- List users by license type

## Script Structure

```
copilot-configure-me-quick/
├── README.md
├── Start-CopilotConfigWizard.ps1         # Main entry point (v2.0.0)
├── modules/
│   ├── CopilotTenantOptimization.psm1    # Tenant checks & recommended settings
│   └── CopilotVivaInsights.psm1          # Viva Insights & org data functions
└── logs/                                 # Created at runtime by the script
```

Notes:
- The repository includes the main wizard and the modules listed above. Other directories and example scripts referenced in earlier docs (e.g., `functions/`, `templates/`, `docs/`) are not included in this repository and have been removed from examples below to avoid confusion.

## Implemented Cmdlets / Functions (examples)

The modules included in this repository export the following example functions you can call directly (after importing the module or running the wizard which auto-loads modules from `./modules`):

- Get-CopilotWebSearchStatus
- Get-CopilotCoreAgentsStatus
- Get-CopilotDataSecurityStatus
- Get-CopilotLicensingStatus
- Get-RecommendedTenantSettingsReport

- Get-VivaInsightsStatus
- Get-VivaInsightsAdminRoles
- Get-OrganizationalDataStatus
- Get-CopilotBrandKitStatus
- Enable-OrganizationalData
- Assign-VivaInsightsRole
- Get-VivaInsightsHealthReport

## Configuration Examples

### Example: Check Licensing Status

```powershell
# From the module (or after running the wizard which imports modules)
Get-CopilotLicensingStatus
```

### Example: Generate Recommended Tenant Settings Report

```powershell
# Generates CLI output and can export to CSV when supported by the function
Get-RecommendedTenantSettingsReport -OutputPath ".\copilot-tenant-settings.csv"
```

### Example: Generate Viva Insights Health Report

```powershell
Get-VivaInsightsHealthReport -OutputPath ".\viva-insights-report.csv"
```

## Documentation

The repository does not include a docs/ folder in this release. Future releases will add expanded ADMIN_GUIDE and reference docs. For now, use the embedded function help and script comments.

## Requirements

### PowerShell Modules

Install the Microsoft Graph PowerShell SDK and other optional modules used by the scripts:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
# Optional (if you need Exchange or SharePoint operations):
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force
```

Note: The previously referenced module `Microsoft.Graph.Users.Functions` was incorrect and has been removed — the scripts expect the Microsoft.Graph SDK and use Get-MgContext / Invoke-MgGraphRequest / Get-MgSubscribedSku etc.

### Permissions Required

The Graph calls used by the modules require appropriate delegated or application permissions. Examples used in the code may require:

- User.Read.All
- Directory.Read.All
- Organization.Read.All
- Reports.Read.All
- AuditLog.Read.All
- AppRoleAssignment.ReadWrite.All

Always grant least-privilege and test in non-production.

## Support & Troubleshooting

If you encounter issues:

1. Use the function help and script comments inside the modules
2. Review PowerShell execution policy: `Get-ExecutionPolicy`
3. Validate Graph connection: `Get-MgContext`
4. Check module versions: `Get-Module Microsoft.Graph -ListAvailable`

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see LICENSE for details.

## Disclaimer

This tool manages enterprise-level configurations. Always:

- ✅ Test in a non-production environment first
- ✅ Back up your current settings
- ✅ Review all changes before applying them
- ✅ Maintain audit logs of all changes
- ✅ Follow your organization's change management policies

## Resources

- [Microsoft 365 Copilot Admin Overview](https://learn.microsoft.com/en-us/microsoft-365/copilot/manage/admin-overview)
- [Microsoft Graph PowerShell](https://learn.microsoft.com/en-us/powershell/microsoftgraph/overview)
- [Microsoft 365 Copilot Licensing](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/licensing)

---

**Last Updated:** July 2024  
**Version:** 2.0.0
