$adb = "C:\Users\bashi\AppData\Local\Android\platform-tools\adb.exe"
$apk = "build\app\outputs\flutter-apk\app-release.apk"

Write-Host "Waiting for Infinix device with USB debugging enabled..." -ForegroundColor Cyan

while ($true) {
    $devices = & $adb devices
    $match = $devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" }
    if ($match) {
        Write-Host "Device detected: $match" -ForegroundColor Green
        Write-Host "Installing $apk..." -ForegroundColor Yellow
        & $adb install -r -d --user 0 $apk
        Write-Host "Launching Moha Lab Optimization..." -ForegroundColor Green
        & $adb shell am start --user 0 -n com.mohalab.optimization/.MainActivity
        Write-Host "Done!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
}
