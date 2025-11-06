@echo off
echo Starting Android emulator...
start /B flutter emulators --launch flutter_emulator

echo Waiting 30 seconds for emulator to boot...
timeout /t 30 /nobreak

echo Running Flutter app...
flutter run

pause
