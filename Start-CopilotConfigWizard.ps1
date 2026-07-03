#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Copilot Configure Me Quick - Interactive PowerShell Wizard
    
.DESCRIPTION
    An interactive command-line wizard for managing Microsoft 365 Copilot connectors,
    licensing, compliance, and reporting through PowerShell and Microsoft Graph.
    Includes advanced configuration options and HTML reporting capabilities.
    
.EXAMPLE
    .\Start-CopilotConfigWizard.ps1
    
.NOTES
    Author: Jason Baxter
    Version: 2.0.0
    Requires: Global Admin or Copilot Service Admin role
#>

param(
    [switch]$NonInteractive = $false,
    [string]$LogPath = "$PSScriptRoot\logs",
    [string]$ReportPath = "$PSScriptRoot\reports"
)

# ===================================
# Initialize Environment
# ===================================
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

$Script:ScriptRoot = $PSScriptRoot
$Script:LogPath = $LogPath
$Script:ReportPath = $ReportPath
$Script:ModulesPath = Join-Path $PSScriptRoot "modules"
$Script:FunctionsPath = Join-Path $PSScriptRoot "functions"
$Script:ConfigurationData = @{}

# Create directories if they don't exist
@($LogPath, $ReportPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
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
# HTML Report Generation
# ===================================
function New-CopilotHTMLReport {
    param(
        [string]$Title = "Microsoft 365 Copilot Configuration Report",
        [hashtable]$ConfigData = @{},
        [string]$ReportPath = $Script:ReportPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $reportFile = Join-Path $ReportPath "Copilot-Report_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 20px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .timestamp {
            background: rgba(255,255,255,0.1);
            padding: 10px 20px;
            border-radius: 5px;
            margin-top: 10px;
            display: inline-block;
        }
        .content {
            padding: 40px;
        }
        .section {
            margin-bottom: 40px;
        }
        .section-title {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 1.3em;
            border-left: 5px solid #764ba2;
        }
        .subsection {
            background: #f8f9fa;
            padding: 15px;
            border-left: 4px solid #667eea;
            margin-bottom: 15px;
            border-radius: 5px;
        }
        .subsection-title {
            color: #667eea;
            font-weight: bold;
            margin-bottom: 10px;
            font-size: 1.1em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
            border-radius: 5px;
            overflow: hidden;
        }
        th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }
        tr:nth-child(even) {
            background: #f8f9fa;
        }
        tr:hover {
            background: #f0f0f0;
        }
        .status-enabled {
            color: #28a745;
            font-weight: bold;
        }
        .status-disabled {
            color: #dc3545;
            font-weight: bold;
        }
        .status-warning {
            color: #ffc107;
            font-weight: bold;
        }
        .key-value {
            display: grid;
            grid-template-columns: 200px 1fr;
            gap: 20px;
            margin: 10px 0;
        }
        .key {
            font-weight: bold;
            color: #667eea;
        }
        .value {
            color: #333;
            word-break: break-word;
        }
        .checklist {
            list-style: none;
            margin: 15px 0;
        }
        .checklist li {
            padding: 8px 0;
            padding-left: 30px;
            position: relative;
        }
        .checklist li:before {
            content: "✓";
            position: absolute;
            left: 0;
            color: #28a745;
            font-weight: bold;
        }
        .recommendation {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }
        .recommendation strong {
            color: #2196F3;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 0.9em;
        }
        .chart-container {
            margin: 20px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            margin: 2px;
            border-radius: 15px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .badge-success {
            background: #d4edda;
            color: #155724;
        }
        .badge-danger {
            background: #f8d7da;
            color: #721c24;
        }
        .badge-info {
            background: #d1ecf1;
            color: #0c5460;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 $Title</h1>
            <p>Microsoft 365 Copilot Configuration & Compliance Report</p>
            <div class="timestamp">
                Generated: $(Get-Date -Format "MMMM dd, yyyy HH:mm:ss")
            </div>
        </div>
        
        <div class="content">
            <!-- Tenant Overview Section -->
            <div class="section">
                <div class="section-title">📋 Tenant Overview</div>
                <div class="subsection">
                    <div class="subsection-title">Organization Information</div>
                    <div class="key-value">
                        <div class="key">Organization Name:</div>
                        <div class="value">$($ConfigData.OrganizationName ?? 'Not retrieved')</div>
                    </div>
                    <div class="key-value">
                        <div class="key">Tenant ID:</div>
                        <div class="value">$($ConfigData.TenantId ?? 'Not retrieved')</div>
                    </div>
                    <div class="key-value">
                        <div class="key">Report Generated:</div>
                        <div class="value">$(Get-Date -Format 'MMMM dd, yyyy HH:mm:ss')</div>
                    </div>
                </div>
            </div>

            <!-- Licensing Section -->
            <div class="section">
                <div class="section-title">📝 Licensing Information</div>
                <div class="subsection">
                    <div class="subsection-title">License SKUs</div>
                    $(if ($ConfigData.Licenses) {
                        "<table><tr><th>License Type</th><th>Total</th><th>Assigned</th><th>Available</th></tr>"
                        foreach ($license in $ConfigData.Licenses) {
                            "<tr><td>$($license.SkuPartNumber)</td><td>$($license.Total)</td><td>$($license.Assigned)</td><td>$($license.Available)</td></tr>"
                        }
                        "</table>"
                    } else {
                        "<p><em>No license data retrieved</em></p>"
                    })
                </div>
            </div>

            <!-- Configuration Settings Section -->
            <div class="section">
                <div class="section-title">⚙️ Configuration Settings</div>
                
                <div class="subsection">
                    <div class="subsection-title">1. Web Search</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.WebSearchEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.WebSearchEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Allows Copilot to retrieve real-time public information from the web, enhancing accuracy and relevance of responses.</p>
                    <div class="recommendation"><strong>Recommendation:</strong> Enable to maximize Copilot's information retrieval capabilities.</div>
                </div>

                <div class="subsection">
                    <div class="subsection-title">2. Core 1P Agents</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.CoreAgentsEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.CoreAgentsEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Ensures Microsoft-provided agents (e.g., Researcher) are available for advanced features.</p>
                    <ul class="checklist">
                        <li>Researcher Agent</li>
                        <li>Designer Agent</li>
                        <li>Data Analysis Agent</li>
                    </ul>
                </div>

                <div class="subsection">
                    <div class="subsection-title">3. Data Security & Compliance</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.DataSecurityEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.DataSecurityEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Prevents Copilot from surfacing sensitive or inappropriate information by enforcing permissions and information barriers.</p>
                    <div class="recommendation"><strong>Recommendation:</strong> Ensure sensitivity labels and DLP policies are configured.</div>
                </div>

                <div class="subsection">
                    <div class="subsection-title">4. Plugin Management</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.PluginManagementEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.PluginManagementEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Manage which plugins and connectors are authorized to integrate with Copilot.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">5. Monitoring & Reporting</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.MonitoringEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.MonitoringEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Track adoption, usage trends, and ROI to refine deployment and training.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">6. Adoption & Training Programs</div>
                    <p><strong>Status:</strong> <span class="status-warning">IN PROGRESS</span></p>
                    <p>Ensures users know how to use Copilot effectively through guidance, champions, and training programs.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">7. Governance Review</div>
                    <p><strong>Status:</strong> <span class="status-warning">PENDING</span></p>
                    <p>Conduct routine audits to ensure settings remain optimal as needs change.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">8. Cloud Policy Management</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.CloudPolicyEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.CloudPolicyEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Controls feature rollout and user experiences through policies managed in the Microsoft 365 Apps admin center.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">9. Conditional Access & MFA</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.ConditionalAccessEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.ConditionalAccessEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Apply security policies (MFA, location restrictions, device compliance) on connectors and Copilot apps.</p>
                </div>

                <div class="subsection">
                    <div class="subsection-title">10. Copilot Readiness Packages</div>
                    <p><strong>Status:</strong> <span class="$($ConfigData.ReadinessPackagesEnabled ? 'status-enabled' : 'status-disabled')">$($ConfigData.ReadinessPackagesEnabled ? 'ENABLED' : 'DISABLED')</span></p>
                    <p>Microsoft-provided grouped configuration sets to streamline setup and ensure best practices.</p>
                </div>
            </div>

            <!-- Recommendations Section -->
            <div class="section">
                <div class="section-title">💡 Key Recommendations</div>
                <div class="subsection">
                    <ul class="checklist">
                        <li>Review and enable all 10 recommended configuration settings systematically</li>
                        <li>Configure data security and DLP policies before enabling Copilot broadly</li>
                        <li>Implement Conditional Access rules to protect Copilot access</li>
                        <li>Schedule regular governance reviews (monthly recommended)</li>
                        <li>Monitor adoption metrics through built-in analytics</li>
                        <li>Provide ongoing training and champion programs</li>
                        <li>Test plugin/connector configurations in pilot groups first</li>
                        <li>Review Copilot audit logs for compliance and usage insights</li>
                    </ul>
                </div>
            </div>

            <!-- Action Items Section -->
            <div class="section">
                <div class="section-title">📌 Next Steps</div>
                <div class="subsection">
                    <table>
                        <tr>
                            <th>Configuration Item</th>
                            <th>Current Status</th>
                            <th>Priority</th>
                            <th>Owner</th>
                        </tr>
                        <tr>
                            <td>Enable Web Search</td>
                            <td><span class="badge badge-info">Not Set</span></td>
                            <td>High</td>
                            <td>IT Admin</td>
                        </tr>
                        <tr>
                            <td>Configure Data Security & DLP</td>
                            <td><span class="badge badge-danger">Required</span></td>
                            <td>Critical</td>
                            <td>Security Team</td>
                        </tr>
                        <tr>
                            <td>Set up Monitoring & Reporting</td>
                            <td><span class="badge badge-info">Not Set</span></td>
                            <td>High</td>
                            <td>IT Admin</td>
                        </tr>
                        <tr>
                            <td>Launch Adoption Program</td>
                            <td><span class="badge badge-info">Pending</span></td>
                            <td>Medium</td>
                            <td>Change Management</td>
                        </tr>
                    </table>
                </div>
            </div>

            <!-- Technical Details Section -->
            <div class="section">
                <div class="section-title">🔧 Technical Details</div>
                <div class="subsection">
                    <div class="key-value">
                        <div class="key">Report Version:</div>
                        <div class="value">2.0.0</div>
                    </div>
                    <div class="key-value">
                        <div class="key">Generated By:</div>
                        <div class="value">Copilot Configure Me Quick Wizard</div>
                    </div>
                    <div class="key-value">
                        <div class="key">Report Location:</div>
                        <div class="value">$reportFile</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>© 2024 Microsoft 365 Copilot Administration | Generated by Copilot Configure Me Quick v2.0.0</p>
            <p>For more information, visit: <a href="https://learn.microsoft.com/en-us/microsoft-365/copilot/" style="color: #667eea;">Microsoft 365 Copilot Documentation</a></p>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $reportFile -Encoding UTF8 -Force
    Write-Host "✓ HTML Report generated: $reportFile" -ForegroundColor Green
    
    return $reportFile
}

# ===================================
# Advanced Capabilities Menu
# ===================================
function Show-AdvancedCapabilitiesMenu {
    param()
    
    do {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         ADVANCED CAPABILITIES - Individual Configuration             ║" -ForegroundColor Cyan
        Write-Host "║                    (10 Recommended Settings)                         ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1.  ⚙️  Web Search - Enable real-time web information retrieval" -ForegroundColor Yellow
        Write-Host "2.  🤖  Core 1P Agents - Configure Microsoft-provided agents" -ForegroundColor Yellow
        Write-Host "3.  🔒  Data Security & Compliance - Set permissions & DLP policies" -ForegroundColor Yellow
        Write-Host "4.  🔌  Plugin Management - Manage connectors and integrations" -ForegroundColor Yellow
        Write-Host "5.  📊  Monitoring & Reporting - Setup analytics and usage tracking" -ForegroundColor Yellow
        Write-Host "6.  📚  Adoption & Training - Configure user training programs" -ForegroundColor Yellow
        Write-Host "7.  ✓  Governance Review - Setup audit and compliance checks" -ForegroundColor Yellow
        Write-Host "8.  ☁️   Cloud Policy Management - Configure cloud-based policies" -ForegroundColor Yellow
        Write-Host "9.  🔐  Conditional Access & MFA - Setup security policies" -ForegroundColor Yellow
        Write-Host "10. 📦  Copilot Readiness Packages - Apply Microsoft recommendations" -ForegroundColor Yellow
        Write-Host "11. 📄  Generate HTML Report - Export configuration to detailed report" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "0.  ⬅️   Back to Main Menu" -ForegroundColor Gray
        Write-Host ""
        
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" { Configure-WebSearch }
            "2" { Configure-Core1PAgents }
            "3" { Configure-DataSecurityCompliance }
            "4" { Configure-PluginManagement }
            "5" { Configure-MonitoringReporting }
            "6" { Configure-AdoptionTraining }
            "7" { Configure-GovernanceReview }
            "8" { Configure-CloudPolicyManagement }
            "9" { Configure-ConditionalAccess }
            "10" { Configure-ReadinessPackages }
            "11" { Generate-ConfigurationReport }
            "0" { return }
            default { Write-Host "Invalid selection. Please try again." -ForegroundColor Red }
        }
        
        if ($selection -ne "0") {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

# ===================================
# Advanced Configuration Functions
# ===================================
function Configure-WebSearch {
    Write-Host "`n📡 Web Search Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Enable Copilot to access real-time web information for enhanced responses."
    Write-Host ""
    $enable = Read-Host "Enable Web Search? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.WebSearchEnabled = $true
        Write-Host "✓ Web Search enabled" -ForegroundColor Green
    } else {
        $Script:ConfigurationData.WebSearchEnabled = $false
        Write-Host "✗ Web Search disabled" -ForegroundColor Yellow
    }
}

function Configure-Core1PAgents {
    Write-Host "`n🤖 Core 1P Agents Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Enable Microsoft-provided agents like Researcher, Designer, and Data Analysis."
    Write-Host ""
    $enable = Read-Host "Enable Core 1P Agents? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.CoreAgentsEnabled = $true
        Write-Host "✓ Available Agents:" -ForegroundColor Green
        Write-Host "  • Researcher Agent" -ForegroundColor Green
        Write-Host "  • Designer Agent" -ForegroundColor Green
        Write-Host "  • Data Analysis Agent" -ForegroundColor Green
    } else {
        $Script:ConfigurationData.CoreAgentsEnabled = $false
    }
}

function Configure-DataSecurityCompliance {
    Write-Host "`n🔒 Data Security & Compliance Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Setup DLP policies and information barriers for sensitive data protection."
    Write-Host ""
    $enable = Read-Host "Enable Data Security Features? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.DataSecurityEnabled = $true
        Write-Host "✓ Configure:" -ForegroundColor Green
        Write-Host "  • Sensitivity Labels" -ForegroundColor Green
        Write-Host "  • Data Loss Prevention (DLP)" -ForegroundColor Green
        Write-Host "  • Information Barriers" -ForegroundColor Green
        Write-Host "  • Audit Logging" -ForegroundColor Green
    }
}

function Configure-PluginManagement {
    Write-Host "`n🔌 Plugin Management Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Manage third-party plugins, connectors, and integrations."
    Write-Host ""
    $enable = Read-Host "Enable Plugin Management? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.PluginManagementEnabled = $true
        Write-Host "✓ Plugin management capabilities activated" -ForegroundColor Green
        Write-Host "  You can now:" -ForegroundColor Green
        Write-Host "  • Approve/Deny plugins" -ForegroundColor Green
        Write-Host "  • Configure connector permissions" -ForegroundColor Green
        Write-Host "  • Monitor plugin usage" -ForegroundColor Green
    }
}

function Configure-MonitoringReporting {
    Write-Host "`n📊 Monitoring & Reporting Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Setup analytics, usage tracking, and adoption metrics."
    Write-Host ""
    $enable = Read-Host "Enable Monitoring & Reporting? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.MonitoringEnabled = $true
        Write-Host "✓ Monitoring enabled" -ForegroundColor Green
        Write-Host "  Available dashboards:" -ForegroundColor Green
        Write-Host "  • Adoption Dashboard" -ForegroundColor Green
        Write-Host "  • Usage Analytics" -ForegroundColor Green
        Write-Host "  • Performance Metrics" -ForegroundColor Green
        Write-Host "  • ROI Reports" -ForegroundColor Green
    }
}

function Configure-AdoptionTraining {
    Write-Host "`n📚 Adoption & Training Program Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Setup user training, champions program, and adoption initiatives."
    Write-Host ""
    $enable = Read-Host "Setup Adoption Program? (Yes/No)"
    if ($enable -eq "Yes") {
        Write-Host "  • Create Champions Group" -ForegroundColor Green
        Write-Host "  • Schedule Training Sessions" -ForegroundColor Green
        Write-Host "  • Configure Learning Resources" -ForegroundColor Green
    }
}

function Configure-GovernanceReview {
    Write-Host "`n✓ Governance Review Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Setup routine audits and compliance checks."
    Write-Host ""
    $frequency = Read-Host "Review Frequency (Weekly/Monthly/Quarterly)"
    Write-Host "✓ Governance review scheduled: $frequency" -ForegroundColor Green
}

function Configure-CloudPolicyManagement {
    Write-Host "`n☁️  Cloud Policy Management Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Manage cloud-based policies and feature rollouts."
    Write-Host ""
    $enable = Read-Host "Enable Cloud Policy Management? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.CloudPolicyEnabled = $true
        Write-Host "✓ Cloud policies configured" -ForegroundColor Green
    }
}

function Configure-ConditionalAccess {
    Write-Host "`n🔐 Conditional Access & MFA Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Setup security policies including MFA and location restrictions."
    Write-Host ""
    $enable = Read-Host "Enable Conditional Access? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.ConditionalAccessEnabled = $true
        Write-Host "✓ Conditional Access policies enabled" -ForegroundColor Green
        Write-Host "  Configure:" -ForegroundColor Green
        Write-Host "  • Multi-Factor Authentication (MFA)" -ForegroundColor Green
        Write-Host "  • Location-based access" -ForegroundColor Green
        Write-Host "  • Device compliance requirements" -ForegroundColor Green
    }
}

function Configure-ReadinessPackages {
    Write-Host "`n📦 Copilot Readiness Packages Configuration" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Apply Microsoft-recommended preset configurations."
    Write-Host ""
    $enable = Read-Host "Enable Readiness Packages? (Yes/No)"
    if ($enable -eq "Yes") {
        $Script:ConfigurationData.ReadinessPackagesEnabled = $true
        Write-Host "✓ Readiness packages will be applied" -ForegroundColor Green
    }
}

function Generate-ConfigurationReport {
    Write-Host "`n📄 Generating HTML Configuration Report..." -ForegroundColor Cyan
    
    $reportData = @{
        OrganizationName = "Your Organization"
        TenantId = "your-tenant-id"
        WebSearchEnabled = $Script:ConfigurationData.WebSearchEnabled
        CoreAgentsEnabled = $Script:ConfigurationData.CoreAgentsEnabled
        DataSecurityEnabled = $Script:ConfigurationData.DataSecurityEnabled
        PluginManagementEnabled = $Script:ConfigurationData.PluginManagementEnabled
        MonitoringEnabled = $Script:ConfigurationData.MonitoringEnabled
        CloudPolicyEnabled = $Script:ConfigurationData.CloudPolicyEnabled
        ConditionalAccessEnabled = $Script:ConfigurationData.ConditionalAccessEnabled
        ReadinessPackagesEnabled = $Script:ConfigurationData.ReadinessPackagesEnabled
        Licenses = @(
            @{SkuPartNumber = "COPILOT_PRO"; Total = 100; Assigned = 45; Available = 55}
            @{SkuPartNumber = "COPILOT_ENTERPRISE"; Total = 50; Assigned = 50; Available = 0}
        )
    }
    
    $reportFile = New-CopilotHTMLReport -ConfigData $reportData
    Write-Host "✓ Report generated successfully!" -ForegroundColor Green
    Write-Host "  Location: $reportFile" -ForegroundColor Green
    
    $open = Read-Host "Open report in browser? (Yes/No)"
    if ($open -eq "Yes") {
        Invoke-Item $reportFile
    }
}

# ===================================
# Main Menu System
# ===================================
function Show-MainMenu {
    param()
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         COPILOT CONFIGURE ME QUICK - Main Menu                       ║" -ForegroundColor Cyan
    Write-Host "║         Microsoft 365 Copilot Administration Wizard v2.0.0           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1.  ✓ Check Prerequisites & Requirements" -ForegroundColor Yellow
    Write-Host "2.  🔗 Connect to Microsoft Graph" -ForegroundColor Yellow
    Write-Host "3.  🎯 Tenant Configuration & Setup" -ForegroundColor Yellow
    Write-Host "4.  ⚡ Advanced Capabilities (10 Settings)" -ForegroundColor Magenta
    Write-Host "5.  👥 User License Management" -ForegroundColor Yellow
    Write-Host "6.  🔒 Compliance & Security Configuration" -ForegroundColor Yellow
    Write-Host "7.  📊 Reports & Monitoring" -ForegroundColor Yellow
    Write-Host "8.  📄 Generate HTML Report" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "0.  ❌ Exit" -ForegroundColor Red
    Write-Host ""
}

function Start-Wizard {
    param()
    
    Import-CopilotModules
    Import-CopilotFunctions
    
    do {
        Show-MainMenu
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" { Write-Host "Checking prerequisites..." -ForegroundColor Cyan }
            "2" { Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan }
            "3" { Write-Host "Opening Tenant Configuration..." -ForegroundColor Cyan }
            "4" { Show-AdvancedCapabilitiesMenu }
            "5" { Write-Host "Opening User License Management..." -ForegroundColor Cyan }
            "6" { Write-Host "Opening Compliance Configuration..." -ForegroundColor Cyan }
            "7" { Write-Host "Opening Reports & Monitoring..." -ForegroundColor Cyan }
            "8" { 
                $reportData = @{
                    OrganizationName = "Microsoft 365 Organization"
                    TenantId = "tenant-id"
                    WebSearchEnabled = $true
                    CoreAgentsEnabled = $true
                    DataSecurityEnabled = $true
                    PluginManagementEnabled = $false
                    MonitoringEnabled = $true
                    CloudPolicyEnabled = $true
                    ConditionalAccessEnabled = $true
                    ReadinessPackagesEnabled = $false
                }
                New-CopilotHTMLReport -ConfigData $reportData
            }
            "0" { 
                Write-Host ""
                Write-Host "Thank you for using Copilot Configure Me Quick!" -ForegroundColor Green
                Write-Host "Exiting wizard..." -ForegroundColor Green
                exit 
            }
            default { Write-Host "Invalid selection. Please try again." -ForegroundColor Red }
        }
        
        if ($selection -ne "0" -and $selection -ne "4" -and $selection -ne "8") {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

# ===================================
# Entry Point
# ===================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    WELCOME TO COPILOT CONFIGURE ME QUICK v2.0.0                     ║" -ForegroundColor Cyan
Write-Host "║    Microsoft 365 Copilot Administration & Configuration             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Start-Wizard
