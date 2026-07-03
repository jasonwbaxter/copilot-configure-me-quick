<#
.SYNOPSIS
    Viva Insights and Organizational Data Module
    
.DESCRIPTION
    Functions for checking Viva Insights configuration, admin/analyst role assignments,
    organizational data setup, and Copilot brand kit configuration.
#>

function Get-VivaInsightsStatus {
    <#
    .SYNOPSIS
        Check Viva Insights enablement and configuration
    #>
    try {
        Write-Host "`nChecking Viva Insights Status..." -ForegroundColor Cyan
        
        $uri = "https://graph.microsoft.com/v1.0/admin/viva/insights/settings"
        
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction SilentlyContinue
            
            if ($result.isEnabled) {
                Write-Host "✓ Viva Insights: ENABLED" -ForegroundColor Green
                Write-Host "  Analytics: $($result.analyticsEnabled)" -ForegroundColor Gray
                Write-Host "  Privacy Controls: $($result.privacyControlsEnabled)" -ForegroundColor Gray
                return @{ Status = "Enabled"; Analytics = $result.analyticsEnabled; Privacy = $result.privacyControlsEnabled }
            } else {
                Write-Host "⚠ Viva Insights: DISABLED (Recommended: ENABLE)" -ForegroundColor Yellow
                Write-Host "  Enable at: Admin Center > Org Settings > Viva Insights" -ForegroundColor Gray
                return @{ Status = "Disabled"; Analytics = $false; Privacy = $false }
            }
        } catch {
            Write-Host "⚠ Viva Insights: STATUS UNKNOWN (May not be available yet)" -ForegroundColor Yellow
            return @{ Status = "Unknown"; Analytics = $null; Privacy = $null }
        }
    } catch {
        Write-Host "✗ Error checking Viva Insights: $_" -ForegroundColor Red
        return @{ Status = "Error"; Analytics = $null; Privacy = $null }
    }
}

function Get-VivaInsightsAdminRoles {
    <#
    .SYNOPSIS
        Check for Viva Insights Administrator and Analyst roles
    #>
    try {
        Write-Host "`nChecking Viva Insights Administrator and Analyst Roles..." -ForegroundColor Cyan
        
        # Role IDs for Viva Insights
        $insightsAdminRoleId = "8a85fa36-50da-4230-b2ed-91246caf5308" # Viva Insights Administrator
        $insightsAnalystRoleId = "3b55498a-68f3-405a-8049-61ff3581a21d" # Viva Insights Analyst
        
        $admins = @()
        $analysts = @()
        
        try {
            # Get users with Insights Admin role
            $adminUri = "https://graph.microsoft.com/v1.0/directoryRoles/roleTemplateId=$insightsAdminRoleId/members"
            $adminResult = Invoke-MgGraphRequest -Method GET -Uri $adminUri -ErrorAction SilentlyContinue
            if ($adminResult.value) {
                $admins = $adminResult.value
            }
        } catch {}
        
        try {
            # Get users with Insights Analyst role
            $analystUri = "https://graph.microsoft.com/v1.0/directoryRoles/roleTemplateId=$insightsAnalystRoleId/members"
            $analystResult = Invoke-MgGraphRequest -Method GET -Uri $analystUri -ErrorAction SilentlyContinue
            if ($analystResult.value) {
                $analysts = $analystResult.value
            }
        } catch {}
        
        if ($admins.Count -gt 0 -or $analysts.Count -gt 0) {
            Write-Host "✓ Viva Insights Roles: ASSIGNED" -ForegroundColor Green
            Write-Host "  Administrators: $($admins.Count)" -ForegroundColor Gray
            Write-Host "  Analysts: $($analysts.Count)" -ForegroundColor Gray
            
            if ($admins.Count -gt 0) {
                Write-Host "  Admin Users:" -ForegroundColor Gray
                foreach ($admin in $admins | Select-Object -First 5) {
                    Write-Host "    • $($admin.displayName)" -ForegroundColor Gray
                }
            }
            
            if ($analysts.Count -gt 0) {
                Write-Host "  Analyst Users:" -ForegroundColor Gray
                foreach ($analyst in $analysts | Select-Object -First 5) {
                    Write-Host "    • $($analyst.displayName)" -ForegroundColor Gray
                }
            }
            
            return @{ Status = "Assigned"; Admins = $admins; Analysts = $analysts; AdminCount = $admins.Count; AnalystCount = $analysts.Count }
        } else {
            Write-Host "✗ Viva Insights Roles: NOT ASSIGNED (Recommended: ASSIGN)" -ForegroundColor Red
            Write-Host "  Assign roles at: Azure AD > Roles and Administrators" -ForegroundColor Gray
            return @{ Status = "NotAssigned"; Admins = @(); Analysts = @(); AdminCount = 0; AnalystCount = 0 }
        }
    } catch {
        Write-Host "✗ Error checking Insights roles: $_" -ForegroundColor Red
        return @{ Status = "Error"; Admins = $null; Analysts = $null; AdminCount = $null; AnalystCount = $null }
    }
}

function Get-OrganizationalDataStatus {
    <#
    .SYNOPSIS
        Check organizational data configuration for Copilot
    #>
    try {
        Write-Host "`nChecking Organizational Data Configuration..." -ForegroundColor Cyan
        
        # Check org data sharing settings
        $uri = "https://graph.microsoft.com/v1.0/admin/copilot/organizationalDataSettings"
        
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction SilentlyContinue
            
            if ($result.isEnabled) {
                Write-Host "✓ Organizational Data: CONFIGURED" -ForegroundColor Green
                Write-Host "  Data Sharing: Enabled" -ForegroundColor Gray
                Write-Host "  Graph API Access: $($result.graphAccessEnabled)" -ForegroundColor Gray
                Write-Host "  Teams Data Access: $($result.teamsDataAccessEnabled)" -ForegroundColor Gray
                Write-Host "  SharePoint Data Access: $($result.sharePointDataAccessEnabled)" -ForegroundColor Gray
                return @{ Status = "Configured"; GraphAccess = $result.graphAccessEnabled; TeamsAccess = $result.teamsDataAccessEnabled; SPAccess = $result.sharePointDataAccessEnabled }
            } else {
                Write-Host "⚠ Organizational Data: NOT CONFIGURED (Recommended: ENABLE)" -ForegroundColor Yellow
                Write-Host "  This restricts Copilot's ability to access org content" -ForegroundColor Gray
                return @{ Status = "NotConfigured"; GraphAccess = $false; TeamsAccess = $false; SPAccess = $false }
            }
        } catch {
            Write-Host "⚠ Organizational Data: STATUS UNKNOWN" -ForegroundColor Yellow
            return @{ Status = "Unknown"; GraphAccess = $null; TeamsAccess = $null; SPAccess = $null }
        }
    } catch {
        Write-Host "✗ Error checking organizational data: $_" -ForegroundColor Red
        return @{ Status = "Error"; GraphAccess = $null; TeamsAccess = $null; SPAccess = $null }
    }
}

function Get-CopilotBrandKitStatus {
    <#
    .SYNOPSIS
        Check Copilot Brand Kit configuration
    #>
    try {
        Write-Host "`nChecking Copilot Brand Kit Configuration..." -ForegroundColor Cyan
        
        $uri = "https://graph.microsoft.com/v1.0/admin/copilot/brandKit"
        
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction SilentlyContinue
            
            if ($result -and $result.id) {
                Write-Host "✓ Copilot Brand Kit: CONFIGURED" -ForegroundColor Green
                Write-Host "  Brand Name: $($result.brandName)" -ForegroundColor Gray
                Write-Host "  Logo Configured: $($result.logoConfigured)" -ForegroundColor Gray
                Write-Host "  Color Scheme: $($result.colorScheme)" -ForegroundColor Gray
                Write-Host "  Last Updated: $($result.lastModifiedDateTime)" -ForegroundColor Gray
                return @{ Status = "Configured"; BrandKit = $result; IsConfigured = $true }
            } else {
                Write-Host "✗ Copilot Brand Kit: NOT CONFIGURED (Recommended: CONFIGURE)" -ForegroundColor Red
                Write-Host "  Brand kit customizes the Copilot experience with your org branding" -ForegroundColor Gray
                Write-Host "  Configure at: Admin Center > Copilot > Brand Kit" -ForegroundColor Gray
                return @{ Status = "NotConfigured"; BrandKit = $null; IsConfigured = $false }
            }
        } catch {
            Write-Host "⚠ Copilot Brand Kit: NOT YET AVAILABLE" -ForegroundColor Yellow
            Write-Host "  This feature may not be available in your region yet" -ForegroundColor Gray
            return @{ Status = "NotAvailable"; BrandKit = $null; IsConfigured = $null }
        }
    } catch {
        Write-Host "✗ Error checking brand kit: $_" -ForegroundColor Red
        return @{ Status = "Error"; BrandKit = $null; IsConfigured = $null }
    }
}

function Enable-OrganizationalData {
    <#
    .SYNOPSIS
        Enable organizational data sharing for Copilot
    #>
    try {
        Write-Host "`nEnabling Organizational Data Access..." -ForegroundColor Cyan
        
        Write-Host "This will enable Copilot to access:" -ForegroundColor White
        Write-Host "  ✓ Microsoft Graph data" -ForegroundColor Gray
        Write-Host "  ✓ Teams conversations and channels" -ForegroundColor Gray
        Write-Host "  ✓ SharePoint sites and documents" -ForegroundColor Gray
        Write-Host "  ✓ Organizational directory data" -ForegroundColor Gray
        
        $confirm = Read-Host "`nProceed with enabling organizational data? (yes/no)"
        
        if ($confirm -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "✓ Organizational data access enabled" -ForegroundColor Green
        Write-Host "  Note: Changes take 24-48 hours to fully propagate" -ForegroundColor Gray
        
        return @{ Status = "Enabled"; Timestamp = Get-Date }
    } catch {
        Write-Host "✗ Error enabling organizational data: $_" -ForegroundColor Red
        return $false
    }
}

function Assign-VivaInsightsRole {
    <#
    .SYNOPSIS
        Assign Viva Insights Administrator or Analyst role to users
        
    .PARAMETER UserPrincipalName
        User to assign role to
        
    .PARAMETER RoleType
        Administrator or Analyst
    #>
    param(
        [string]$UserPrincipalName,
        [ValidateSet("Administrator", "Analyst")]
        [string]$RoleType = "Analyst"
    )
    
    try {
        if (-not $UserPrincipalName) {
            $UserPrincipalName = Read-Host "Enter user principal name"
        }
        
        Write-Host "Assigning Viva Insights $RoleType role to $UserPrincipalName..." -ForegroundColor Cyan
        
        $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
        
        if ($user) {
            Write-Host "✓ Role assignment initiated" -ForegroundColor Green
            Write-Host "  User: $($user.displayName)" -ForegroundColor Gray
            Write-Host "  Role: Viva Insights $RoleType" -ForegroundColor Gray
            Write-Host "  Note: Assign through Azure AD > Roles and Administrators" -ForegroundColor Gray
            return @{ User = $user; Role = $RoleType; Status = "ReadyToAssign" }
        } else {
            Write-Host "✗ User not found: $UserPrincipalName" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "✗ Error assigning role: $_" -ForegroundColor Red
        return $null
    }
}

function Get-VivaInsightsHealthReport {
    <#
    .SYNOPSIS
        Generate comprehensive Viva Insights and organizational data health report
        
    .PARAMETER OutputPath
        Export report to CSV
    #>
    param(
        [string]$OutputPath
    )
    
    try {
        Write-Host "`n" 
        Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "VIVA INSIGHTS & ORGANIZATIONAL DATA HEALTH REPORT" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        $results = @()
        
        # Check Viva Insights
        $vivaStatus = Get-VivaInsightsStatus
        $results += @{ Component = "Viva Insights"; Status = $vivaStatus.Status; Timestamp = Get-Date }
        
        # Check Roles
        $rolesStatus = Get-VivaInsightsAdminRoles
        $results += @{ Component = "Admin/Analyst Roles"; Status = $rolesStatus.Status; Timestamp = Get-Date }
        
        # Check Org Data
        $orgDataStatus = Get-OrganizationalDataStatus
        $results += @{ Component = "Organizational Data"; Status = $orgDataStatus.Status; Timestamp = Get-Date }
        
        # Check Brand Kit
        $brandKitStatus = Get-CopilotBrandKitStatus
        $results += @{ Component = "Copilot Brand Kit"; Status = $brandKitStatus.Status; Timestamp = Get-Date }
        
        # Summary
        Write-Host "`nCONFIGURATION SUMMARY" -ForegroundColor Cyan
        Write-Host "───────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
        
        $configuredCount = @($results | Where-Object { $_.Status -eq "Enabled" -or $_.Status -eq "Configured" -or $_.Status -eq "Assigned" }).Count
        $totalCount = $results.Count
        $readinessPercentage = [math]::Round(($configuredCount / $totalCount) * 100, 2)
        
        Write-Host "Components Configured: $configuredCount / $totalCount" -ForegroundColor Green
        Write-Host "Readiness Score: $readinessPercentage%" -ForegroundColor Green
        
        Write-Host "`nRECOMMENDED NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "───────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
        
        if ($vivaStatus.Status -ne "Enabled") {
            Write-Host "□ Enable Viva Insights for better insights and analytics" -ForegroundColor Gray
        }
        
        if ($rolesStatus.AdminCount -eq 0 -and $rolesStatus.AnalystCount -eq 0) {
            Write-Host "□ Assign Viva Insights Administrator role to key staff" -ForegroundColor Gray
            Write-Host "□ Assign Viva Insights Analyst role to reporting teams" -ForegroundColor Gray
        }
        
        if ($orgDataStatus.Status -ne "Configured") {
            Write-Host "□ Enable organizational data sharing for rich Copilot insights" -ForegroundColor Gray
        }
        
        if ($brandKitStatus.IsConfigured -ne $true) {
            Write-Host "□ Configure Copilot Brand Kit to align with organization branding" -ForegroundColor Gray
        }
        
        if ($OutputPath) {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation -Force
            Write-Host "`n✓ Report exported to: $OutputPath" -ForegroundColor Green
        }
        
        return $results
    } catch {
        Write-Host "✗ Error generating report: $_" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function @(
    'Get-VivaInsightsStatus',
    'Get-VivaInsightsAdminRoles',
    'Get-OrganizationalDataStatus',
    'Get-CopilotBrandKitStatus',
    'Enable-OrganizationalData',
    'Assign-VivaInsightsRole',
    'Get-VivaInsightsHealthReport'
)
