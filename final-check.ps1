#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Final verification script to check that tasks in track.md haven't been entirely deleted.

.DESCRIPTION
    This script reads all tasks from track.md and verifies that implementations
    haven't been completely removed from the final Terraform files.
    Note: Implementation details may change during acceptance testing - this script
    only checks that the task's implementation still exists in some form, not that
    it matches the proof documentation exactly.
    Any completely missing implementations are recorded in warning.md.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TrackFile = "track.md",
    
    [Parameter(Mandatory = $false)]
    [string]$WarningFile = "warning.md",
    
    [Parameter(Mandatory = $false)]
    [int[]]$TaskNumbers = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Final Implementation Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mode: Copilot-assisted verification" -ForegroundColor Magenta
Write-Host ""

# Read track.md
if (-not (Test-Path $TrackFile)) {
    Write-Error "Track file not found: $TrackFile"
    exit 1
}

Write-Host "Reading task list from $TrackFile..." -ForegroundColor Yellow
$trackContent = Get-Content -Path $TrackFile -Raw

# Parse tasks from the markdown table (handle different line endings)
$taskLines = @($trackContent -split "`r`n|`n|`r" | Where-Object { $_ -match '^\|\s*\d+\s*\|.*\|.*\|.*\|.*\|.*\|$' })

# Filter by task numbers if specified
if ($TaskNumbers.Count -gt 0) {
    Write-Host "Filtering to check only task(s): $($TaskNumbers -join ', ')" -ForegroundColor Yellow
    $taskLines = @($taskLines | Where-Object {
        $taskNo = ($_ -split '\|')[1].Trim()
        $TaskNumbers -contains [int]$taskNo
    })
    if ($taskLines.Count -eq 0) {
        Write-Error "No tasks found matching the specified task numbers: $($TaskNumbers -join ', ')"
        exit 1
    }
}

Write-Host "Found $($taskLines.Count) task$(if ($taskLines.Count -ne 1) { 's' }) to verify" -ForegroundColor Green
Write-Host ""

# Initialize warnings collection
$warnings = @()
$verifiedCount = 0
$warningCount = 0

# Process each task
$taskNumber = 0
foreach ($line in $taskLines) {
    $taskNumber++
    
    # Parse task components
    $columns = $line -split '\|' | ForEach-Object { $_.Trim() }
    $taskNo = $columns[1]
    $taskPath = $columns[2]
    $taskType = $columns[3]
    $taskRequired = $columns[4]
    $taskStatus = $columns[5]
    $proofDocLink = $columns[6]
    
    # Extract proof document filename from markdown link
    $proofDoc = ""
    if ($proofDocLink -match '\[.*?\]\((.*?)\)') {
        $proofDoc = $matches[1]
    }
    
    Write-Host "[$taskNo] Checking: $taskPath ($taskType)" -ForegroundColor Cyan
    
    # Check if this is a special task type
    if ($taskPath -match "__.*__") {
        Write-Host "  ✓ Special task (skipped)" -ForegroundColor DarkGray
        $verifiedCount++
        continue
    }
    
    # Use Copilot for verification
    # Construct copilot prompt that delegates to sub-agent
        $verificationPrompt = "Read ``final-subcheck.md`` file and verify Task $taskNo ($taskPath) from ``track.md``"
        
        Write-Host "  Delegating verification to Copilot..." -ForegroundColor Yellow
        
        # Execute copilot command
        $copilotArgs = @(
            "-p", $verificationPrompt,
            "--allow-all-tools",
            "--model", "claude-sonnet-4.5"
        )
        
        # Print the actual command being executed
        Write-Host "  Command: copilot -p `"$verificationPrompt`" --allow-all-tools --model claude-sonnet-4.5" -ForegroundColor DarkGray
        Write-Host ""
        
        $copilotOutput = & copilot @copilotArgs 2>&1 | Out-String
        $copilotExitCode = $LASTEXITCODE
        
        if ($copilotExitCode -ne 0) {
            Write-Host "  ⚠️  Warning: Copilot verification failed (exit code $copilotExitCode)" -ForegroundColor Yellow
            $warnings += [PSCustomObject]@{
                TaskNo = $taskNo
                Path = $taskPath
                Type = $taskType
                Required = $taskRequired
                Issue = "Copilot verification failed with exit code $copilotExitCode"
            }
            $warningCount++
            continue
        }
        
        # Parse copilot response (check NOT_IMPLEMENTED first to avoid substring match)
        $verified = $false
        if ($copilotOutput -match "NOT_IMPLEMENTED") {
            Write-Host "  ⚠️  Not Implemented (verified by Copilot)" -ForegroundColor Yellow
            $warnings += [PSCustomObject]@{
                TaskNo = $taskNo
                Path = $taskPath
                Type = $taskType
                Required = $taskRequired
                Issue = "Implementation not found or commented out (verified by Copilot)"
            }
            $warningCount++
        } elseif ($copilotOutput -match "IMPLEMENTED") {
            $verified = $true
            Write-Host "  ✓ Implemented (verified by Copilot)" -ForegroundColor Green
            $verifiedCount++
        } else {
            Write-Host "  ⚠️  Warning: Unclear Copilot response" -ForegroundColor Yellow
            $warnings += [PSCustomObject]@{
                TaskNo = $taskNo
                Path = $taskPath
                Type = $taskType
                Required = $taskRequired
                Issue = "Copilot verification returned unclear response"
            }
            $warningCount++
        }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($TaskNumbers.Count -gt 0) {
    Write-Host "Filtered tasks: $($TaskNumbers -join ', ')" -ForegroundColor White
}
Write-Host "Total tasks checked: $taskNumber" -ForegroundColor White
Write-Host "Verified: $verifiedCount" -ForegroundColor Green
Write-Host "Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

# Write warnings to file if any
if ($warnings.Count -gt 0) {
    Write-Host "Writing warnings to $WarningFile..." -ForegroundColor Yellow
    
    $filteredTasksLine = ""
    if ($TaskNumbers.Count -gt 0) {
        $filteredTasksLine = "`n**Filtered Tasks**: $($TaskNumbers -join ', ')"
    }
    
    $warningContent = @"
# Final Implementation Verification Warnings

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

**Summary**: $warningCount warning(s) found during final implementation verification.$filteredTasksLine

## Warnings

"@
    
    foreach ($warning in $warnings) {
        $warningContent += @"

### Task $($warning.TaskNo): $($warning.Path)

- **Type**: $($warning.Type)
- **Required**: $($warning.Required)
- **Issue**: $($warning.Issue)

"@
    }
    
    $warningContent += @"

## Recommendations

Please review the tasks listed above to verify they haven't been completely deleted:
1. Check if the implementation still exists in any form in the Terraform files
2. Verify that variables, outputs, or resources related to these tasks are present
3. If required tasks are missing, they must be re-implemented
4. If optional tasks are missing, evaluate if they should be restored

**Note**: Implementation details may have changed during acceptance testing - that's normal.
This check only alerts you to tasks that appear to be completely missing from the final code.

If a warning is a false positive (implementation exists but wasn't detected), 
you can proceed safely. Manual verification of critical required tasks is recommended.

"@
    
    Set-Content -Path $WarningFile -Value $warningContent -Encoding UTF8
    Write-Host "Warnings written to $WarningFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  Please review the warnings before proceeding." -ForegroundColor Yellow
} else {
    Write-Host "✓ All tasks verified successfully! No warnings found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Final verification check completed." -ForegroundColor Cyan

# Exit with appropriate code
if ($warningCount -gt 0) {
    exit 0  # Warnings don't fail the build, just alert
} else {
    exit 0
}
