# Manual deployment script for AI-Track to GitHub Pages
Write-Host "Deploying AI-Track to GitHub Pages..." -ForegroundColor Green

# Build web version
Write-Host "Building Flutter web..." -ForegroundColor Yellow
flutter build web --release -t lib/main_web.dart --base-href "/AI-Track/"

# Switch to gh-pages branch
Write-Host "Switching to gh-pages branch..." -ForegroundColor Yellow
git checkout gh-pages

# Copy essential files
Write-Host "Copying web files..." -ForegroundColor Yellow
Copy-Item "build\web\*" -Destination "." -Recurse -Force

# Commit and push
Write-Host "Committing changes..." -ForegroundColor Yellow
git add .
git commit -m "Deploy AI-Track web app"
git push origin gh-pages --force

# Switch back to main
git checkout main

Write-Host "Deployment complete! Visit: https://jascons.github.io/AI-Track/" -ForegroundColor Green