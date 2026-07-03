# Copilot Configure Me Quick 🚀

An interactive PowerShell wizard for administering and configuring Microsoft 365 Copilot settings through PowerShell and Microsoft Graph APIs.

## Overview

This tool provides a **rich command-line wizard experience** that guides administrators through:

- ✅ Verifying prerequisites and permissions
- ✅ Installing required PowerShell modules
- ✅ Authenticating to Microsoft Graph
- ✅ Discovering Copilot licensing and SKUs
- ✅ Enabling/Disabling Copilot features per user or tenant
- ✅ Configuring data access and compliance policies
- ✅ Generating audit and reporting queries
- ✅ Creating bulk user assignments

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

## Features

### 1. **Interactive Menu System**
Navigate through options using arrow keys and enter selections with a beautiful colored menu interface.

### 2. **Prerequisites Check**
- Validates PowerShell version
- Checks admin elevation status
- Verifies module installation requirements

### 3. **Tenant Configuration**
- Connect to your M365 tenant
- Display organization details
- List available Copilot licenses

### 4. **User Management**
- Assign Copilot licenses to individual users
- Bulk assign licenses via CSV import
- Check user license status
- Remove Copilot access

### 5. **Compliance & Security**
- Configure data access policies
- Review audit logging settings
- Set Conditional Access rules
- Configure DLP policies for AI

### 6. **Reports & Monitoring**
- Generate Copilot adoption reports
- View usage statistics
- Export license status to CSV
- List users by license type

## Script Structure

```
copilot-configure-me-quick/
├── README.md
├── Start-CopilotConfigWizard.ps1         # Main entry point
├── modules/
│   ├── CopilotCore.psm1                  # Core Copilot functions
│   ├── CopilotLicensing.psm1             # Licensing operations
│   ├── CopilotCompliance.psm1            # Compliance & security
│   ├── CopilotReporting.psm1             # Reports & monitoring
│   └── CopilotUI.psm1                    # UI components
├── functions/
│   ├── Connect-CopilotTenant.ps1
│   ├── Get-CopilotLicenseStatus.ps1
│   ├── Set-CopilotUserLicense.ps1
│   ├── Get-CopilotAuditLogs.ps1
│   └── Export-CopilotReport.ps1
├── templates/
│   ├── bulk-import-template.csv
│   └── compliance-policy-template.json
└── logs/
    └── .gitkeep                          # Log directory
```

## Configuration Examples

### Example: Assign Copilot License to a User

```powershell
Set-CopilotUserLicense -UserPrincipalName "user@company.com" -Action Enable
```

### Example: Bulk Import User Licenses

```powershell
Import-CopilotBulkLicenses -CsvPath ".\bulk-import.csv"
```

### Example: Generate Adoption Report

```powershell
Get-CopilotAdoptionReport -OutputPath ".\Reports\" -Days 30
```

## Documentation

- **[ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md)** - Comprehensive administration guide
- **[POWERSHELL_REFERENCE.md](./docs/POWERSHELL_REFERENCE.md)** - PowerShell cmdlet reference
- **[TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[API_REFERENCE.md](./docs/API_REFERENCE.md)** - Microsoft Graph API reference

## Requirements

### PowerShell Modules

- `Microsoft.Graph` - Core Microsoft Graph SDK
- `Microsoft.Graph.Authentication` - Authentication module
- `Microsoft.Graph.Users.Functions` - User management
- `ExchangeOnlineManagement` - Exchange Online operations (optional)
- `PnP.PowerShell` - SharePoint/OneDrive operations (optional)

### Permissions Required

- `User.Read.All`
- `Directory.Read.All`
- `Organization.Read.All`
- `Reports.Read.All`
- `AuditLog.Read.All`
- `AppRoleAssignment.ReadWrite.All`

## Support & Troubleshooting

If you encounter issues:

1. Check **[TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)**
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

This project is licensed under the MIT License - see LICENSE.md for details.

## Disclaimer

This tool manages enterprise-level configurations. Always:

- ✅ Test in a non-production environment first
- ✅ Back up your current settings
- ✅ Review all changes before applying them
- ✅ Maintain audit logs of all changes
- ✅ Follow your organization's change management policies

## Resources

- [Microsoft 365 Copilot Admin Overview](https://learn.microsoft.com/en-us/microsoft-365-copilot/manage/admin-overview)
- [Microsoft Graph PowerShell](https://learn.microsoft.com/en-us/powershell/microsoftgraph/overview)
- [Microsoft 365 Copilot Licensing](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/licensing)

---

**Last Updated:** July 2024  
**Version:** 1.0.0
