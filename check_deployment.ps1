#!/usr/bin/env pwsh
# Check deployment status for AI-Track

Write-Host "AI-Track Deployment Status Check" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$repoUrl = "https://github.com/JasCons/AI-Track"
$ghPagesUrl = "https://jascons.github.io/AI-Track/"

Write-Host ""
Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
Write-Host "Live Site: $ghPagesUrl" -ForegroundColor Cyan

Write-Host ""
Write-Host "Checking GitHub Actions status..." -ForegroundColor Yellow

try {
    # Check if the site is accessible
    $response = Invoke-WebRequest -Uri $ghPagesUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "Site is live and accessible!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "Site may still be deploying or not yet accessible" -ForegroundColor Yellow
    Write-Host "   This is normal for the first deployment" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Magenta
Write-Host "1. Check GitHub Actions at: $repoUrl/actions" -ForegroundColor White
Write-Host "2. Enable GitHub Pages at: $repoUrl/settings/pages" -ForegroundColor White
Write-Host "3. Wait 5-10 minutes for first deployment" -ForegroundColor White
Write-Host "4. Visit: $ghPagesUrl" -ForegroundColor White

Write-Host ""
Write-Host "Manual GitHub Pages Setup:" -ForegroundColor Magenta
Write-Host "1. Go to repository Settings > Pages" -ForegroundColor White
Write-Host "2. Source: Deploy from a branch" -ForegroundColor White
Write-Host "3. Branch: gh-pages / (root)" -ForegroundColor White
Write-Host "4. Save and wait for deployment" -ForegroundColor White