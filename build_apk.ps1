# AI-Track APK Build Script
Write-Host "========================================" -ForegroundColor Green
Write-Host "AI-Track APK Builder" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter not found" -ForegroundColor Red
    exit 1
}
Write-Host "Flutter found" -ForegroundColor Green
Write-Host ""

Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "Clean complete" -ForegroundColor Green
Write-Host ""

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "Building release APK..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Cyan
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK Location:" -ForegroundColor Cyan
    Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "Features Included:" -ForegroundColor Cyan
    Write-Host "  Firebase Authentication" -ForegroundColor Green
    Write-Host "  Cloud Firestore" -ForegroundColor Green
    Write-Host "  Google Maps API" -ForegroundColor Green
    Write-Host "  Location Services" -ForegroundColor Green
    Write-Host ""
    Write-Host "To install on device:" -ForegroundColor Yellow
    Write-Host "  adb install build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "BUILD FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the error messages above" -ForegroundColor Yellow
    exit 1
}
