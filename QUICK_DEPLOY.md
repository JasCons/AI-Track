# Quick Deployment Guide - Get Your Shareable Link

## Option 1: Automated (Recommended)

If you have GitHub CLI installed:

```powershell
# Run the deployment script
.\deploy.ps1
```

## Option 2: Manual Setup

### Step 1: Create GitHub Repository
1. Go to [github.com/new](https://github.com/new)
2. Repository name: `AI-Track`
3. Make it **Public**
4. Click "Create repository"

### Step 2: Push Your Code
```powershell
# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/AI-Track.git
git branch -M main
git push -u origin main
```

### Step 3: Enable GitHub Pages
1. Go to your repository on GitHub
2. Click **Settings** tab
3. Scroll to **Pages** section
4. Under "Source", select **Deploy from a branch**
5. Select branch: **gh-pages**
6. Click **Save**

### Step 4: Wait for Deployment
- The GitHub Action will automatically build and deploy your Flutter web app
- Check the **Actions** tab to see deployment progress
- Your app will be available at: `https://YOUR_USERNAME.github.io/AI-Track`

## Your Shareable Links

After deployment, you'll have:

1. **GitHub Repository**: `https://github.com/YOUR_USERNAME/AI-Track`
2. **Live Web App**: `https://YOUR_USERNAME.github.io/AI-Track`

## Troubleshooting

If the deployment fails:
1. Check the **Actions** tab for error details
2. Ensure your Flutter app builds locally: `flutter build web`
3. Make sure GitHub Pages is enabled in repository settings

## Next Steps

- The app will auto-deploy whenever you push to the `main` branch
- You can add a custom domain in GitHub Pages settings
- Consider setting up Firebase Hosting for additional features