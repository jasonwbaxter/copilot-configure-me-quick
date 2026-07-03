<#
.SYNOPSIS
    Copilot Tenant Optimization and Recommended Settings Module
    
.DESCRIPTION
    Checks and validates all recommended Copilot tenant configuration settings
    based on Microsoft 365 official documentation.
    
.REFERENCE
    https://learn.microsoft.com/en-us/microsoft-365/copilot/optimize-microsoft-365-configuration-settings
#>

function Get-CopilotWebSearchStatus {
    <#
    .SYNOPSIS
        Check if Web Search is enabled for Copilot
    #>
    try {
        Write-Host "`nChecking Web Search Status..." -ForegroundColor Cyan
        
        $uri = "https://graph.microsoft.com/v1.0/admin/copilot/webSearchSettings"
        
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction SilentlyContinue
            
            if ($result.isEnabled) {
                Write-Host "✓ Web Search: ENABLED" -ForegroundColor Green
                return @{ Status = "Enabled"; Value = $true }
            } else {
                Write-Host "✗ Web Search: DISABLED (Recommended: ENABLED)" -ForegroundColor Red
                return @{ Status = "Disabled"; Value = $false }
            }
        } catch {
            Write-Host "⚠ Web Search: STATUS UNKNOWN" -ForegroundColor Yellow
            return @{ Status = "Unknown"; Value = $null }
        }
    } catch {
        Write-Host "✗ Error checking Web Search: $_" -ForegroundColor Red
        return @{ Status = "Error"; Value = $null }
    }
}

function Get-CopilotCoreAgentsStatus {
    <#
    .SYNOPSIS
        Check if Core 1P Agents are enabled
    #>
    try {
        Write-Host "`nChecking Core 1P Agents Status..." -ForegroundColor Cyan
        
        $uri = "https://graph.microsoft.com/v1.0/admin/copilot/agents"
        
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction SilentlyContinue
            
            if ($result.value -and $result.value.Count -gt 0) {
                Write-Host "✓ Core 1P Agents: ENABLED" -ForegroundColor Green
                Write-Host "  Found $($result.value.Count) agents" -ForegroundColor Gray
                return @{ Status = "Enabled"; Count = $result.value.Count }
            } else {
                Write-Host "✗ Core 1P Agents: NOT CONFIGURED" -ForegroundColor Red
                return @{ Status = "Disabled"; Count = 0 }
            }
        } catch {
            Write-Host "⚠ Core 1P Agents: STATUS UNKNOWN" -ForegroundColor Yellow
            return @{ Status = "Unknown"; Count = $null }
        }
    } catch {
        Write-Host "✗ Error checking agents: $_" -ForegroundColor Red
        return @{ Status = "Error"; Count = $null }
    }
}

function Get-CopilotDataSecurityStatus {
    <#
    .SYNOPSIS
        Check Data Security and Compliance settings
    #>
    try {
        Write-Host "`nChecking Data Security and Compliance Settings..." -ForegroundColor Cyan
        
        $dlpUri = "https://graph.microsoft.com/v1.0/security/dataLossPreventionPolicies"
        $dlpPolicies = @()
        
        try {
            $dlpResult = Invoke-MgGraphRequest -Method GET -Uri $dlpUri -ErrorAction SilentlyContinue
            if ($dlpResult.value) {
                $dlpPolicies = $dlpResult.value
            }
        } catch {}
        
        $labelUri = "https://graph.microsoft.com/v1.0/me/security/informationProtection/sensitivityLabels"
        $labels = @()
        
        try {
            $labelResult = Invoke-MgGraphRequest -Method GET -Uri $labelUri -ErrorAction SilentlyContinue
            if ($labelResult.value) {
                $labels = $labelResult.value
            }
        } catch {}
        
        if ($dlpPolicies.Count -gt 0 -or $labels.Count -gt 0) {
            Write-Host "✓ Data Security: CONFIGURED" -ForegroundColor Green
            Write-Host "  DLP Policies: $($dlpPolicies.Count)" -ForegroundColor Gray
            Write-Host "  Sensitivity Labels: $($labels.Count)" -ForegroundColor Gray
            return @{ Status = "Configured"; DLPCount = $dlpPolicies.Count; LabelCount = $labels.Count }
        } else {
            Write-Host "⚠ Data Security: MINIMAL CONFIGURATION" -ForegroundColor Yellow
            return @{ Status = "Minimal"; DLPCount = 0; LabelCount = 0 }
        }
    } catch {
        Write-Host "✗ Error checking data security: $_" -ForegroundColor Red
        return @{ Status = "Error"; DLPCount = $null; LabelCount = $null }
    }
}

function Get-CopilotLicensingStatus {
    <#
    .SYNOPSIS
        Check licensing and access control configuration
    #>
    try {
        Write-Host "`nChecking Licensing and Access Control..." -ForegroundColor Cyan
        
        $skus = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*COPILOT*" }
        
        if ($skus) {
            $totalLicenses = 0
            $consumedLicenses = 0
            
            foreach ($sku in $skus) {
                $totalLicenses += $sku.PrepaidUnits.Enabled
                $consumedLicenses += $sku.ConsumedUnits
            }
            
            Write-Host "✓ Licensing: CONFIGURED" -ForegroundColor Green
            Write-Host "  Total Licenses: $totalLicenses" -ForegroundColor Gray
            Write-Host "  Consumed: $consumedLicenses" -ForegroundColor Gray
            Write-Host "  Available: $($totalLicenses - $consumedLicenses)" -ForegroundColor Gray
            
            return @{ Status = "Configured"; Total = $totalLicenses; Consumed = $consumedLicenses; Available = ($totalLicenses - $consumedLicenses) }
        } else {
            Write-Host "✗ Licensing: NOT CONFIGURED" -ForegroundColor Red
            return @{ Status = "NotConfigured"; Total = 0; Consumed = 0; Available = 0 }
        }
    } catch {
        Write-Host "✗ Error checking licensing: $_" -ForegroundColor Red
        return @{ Status = "Error"; Total = $null; Consumed = $null; Available = $null }
    }
}

function Get-RecommendedTenantSettingsReport {
    <#
    .SYNOPSIS
        Generate comprehensive report on all recommended tenant settings
    #>
    param(
        [string]$OutputPath
    )
    
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "MICROSOFT 365 COPILOT RECOMMENDED TENANT SETTINGS REPORT" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $results = @()
    
    $webSearch = Get-CopilotWebSearchStatus
    $results += @{ Setting = "Web Search"; Status = $webSearch.Status; Details = $webSearch }
    
    $agents = Get-CopilotCoreAgentsStatus
    $results += @{ Setting = "Core 1P Agents"; Status = $agents.Status; Details = $agents }
    
    $dataSecurity = Get-CopilotDataSecurityStatus
    $results += @{ Setting = "Data Security & Compliance"; Status = $dataSecurity.Status; Details = $dataSecurity }
    
    $licensing = Get-CopilotLicensingStatus
    $results += @{ Setting = "Licensing & Access Control"; Status = $licensing.Status; Details = $licensing }
    
    Write-Host "`nSUMMARY" -ForegroundColor Cyan
    Write-Host "───────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
    
    $configuredCount = @($results | Where-Object { $_.Status -eq "Enabled" -or $_.Status -eq "Configured" }).Count
    $totalCount = $results.Count
    $compliancePercentage = [math]::Round(($configuredCount / $totalCount) * 100, 2)
    
    Write-Host "Settings Configured: $configuredCount / $totalCount" -ForegroundColor Green
    Write-Host "Compliance Score: $compliancePercentage%" -ForegroundColor Green
    
    if ($OutputPath) {
        $results | Export-Csv -Path $OutputPath -NoTypeInformation -Force
        Write-Host "`n✓ Report exported to: $OutputPath" -ForegroundColor Green
    }
    
    return $results
}

Export-ModuleMember -Function @(
    'Get-CopilotWebSearchStatus',
    'Get-CopilotCoreAgentsStatus',
    'Get-CopilotDataSecurityStatus',
    'Get-CopilotLicensingStatus',
    'Get-RecommendedTenantSettingsReport'
)
