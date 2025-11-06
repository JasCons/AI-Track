# AI-Track Deployment Script
# This script helps you deploy your Flutter app to GitHub and get a shareable link

Write-Host "AI-Track Deployment Helper" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Check if GitHub CLI is installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "GitHub CLI not found. Please install it from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "Or create the repository manually at: https://github.com/new" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in to GitHub CLI
$ghAuth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to GitHub CLI first:" -ForegroundColor Yellow
    Write-Host "gh auth login" -ForegroundColor Cyan
    exit 1
}

# Create GitHub repository
Write-Host "Creating GitHub repository..." -ForegroundColor Blue
$repoName = "AI-Track"
gh repo create $repoName --public --description "AI-Track Flutter app with authentication and Firebase integration"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Repository created successfully!" -ForegroundColor Green
    
    # Add remote and push
    Write-Host "Adding remote and pushing code..." -ForegroundColor Blue
    git remote add origin "https://github.com/$(gh api user --jq .login)/$repoName.git"
    git branch -M main
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Code pushed successfully!" -ForegroundColor Green
        
        # Enable GitHub Pages
        Write-Host "Enabling GitHub Pages..." -ForegroundColor Blue
        gh api repos/$(gh api user --jq .login)/$repoName/pages -X POST -f source='{"branch":"gh-pages","path":"/"}'
        
        $username = gh api user --jq .login
        $githubPagesUrl = "https://$username.github.io/$repoName"
        
        Write-Host ""
        Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
        Write-Host "======================" -ForegroundColor Green
        Write-Host "Repository URL: https://github.com/$username/$repoName" -ForegroundColor Cyan
        Write-Host "GitHub Pages URL: $githubPagesUrl" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Note: GitHub Pages may take a few minutes to become available." -ForegroundColor Yellow
        Write-Host "The web app will be automatically deployed when you push to main branch." -ForegroundColor Yellow
        
        # Update DEPLOYMENT.md with the live link
        $deploymentContent = Get-Content "DEPLOYMENT.md" -Raw
        $updatedContent = $deploymentContent -replace "Live site: UPDATED_LINK.*", "Live site: $githubPagesUrl"
        Set-Content "DEPLOYMENT.md" $updatedContent
        
        git add DEPLOYMENT.md
        git commit -m "Update DEPLOYMENT.md with GitHub Pages URL"
        git push
        
        Write-Host ""
        Write-Host "✅ DEPLOYMENT.md updated with live URL!" -ForegroundColor Green
    }
} else {
    Write-Host "Failed to create repository. It may already exist." -ForegroundColor Red
    Write-Host "Please check: https://github.com/$(gh api user --jq .login)/$repoName" -ForegroundColor Yellow
}