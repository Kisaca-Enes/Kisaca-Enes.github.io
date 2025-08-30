# qBittorrent Tamamen Kaldırma Scripti
# Yönetici yetkisiyle çalıştırmalısın!

Write-Host "[*] qBittorrent kaldırma işlemi başlatılıyor..." -ForegroundColor Cyan

# 1. Uygulama kaldırma (MSI/EXE yükleme ile kurulduysa)
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "qBittorrent*" } | ForEach-Object { 
    Write-Host "[*] Kaldırılıyor: $($_.Name)" -ForegroundColor Yellow
    $_.Uninstall() 
}

# 2. Appx (Microsoft Store) sürümü varsa kaldır
Get-AppxPackage *qBittorrent* -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "[*] Appx sürümü kaldırılıyor: $($_.Name)" -ForegroundColor Yellow
    Remove-AppxPackage $_
}

# 3. Klasörleri sil
$paths = @(
    "$env:APPDATA\qBittorrent",
    "$env:LOCALAPPDATA\qBittorrent",
    "$env:ProgramFiles\qBittorrent",
    "$env:ProgramFiles(x86)\qBittorrent"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "[*] Siliniyor: $path" -ForegroundColor Yellow
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 4. Registry temizliği
$regKeys = @(
    "HKCU:\Software\qBittorrent",
    "HKLM:\SOFTWARE\qBittorrent"
)

foreach ($key in $regKeys) {
    if (Test-Path $key) {
        Write-Host "[*] Registry temizleniyor: $key" -ForegroundColor Yellow
        Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 5. Firewall kuralları sil
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*qBittorrent*" } | ForEach-Object {
    Write-Host "[*] Firewall kuralı kaldırılıyor: $($_.DisplayName)" -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $_.DisplayName
}

# 6. Scheduled Task kontrolü
Get-ScheduledTask | Where-Object { $_.TaskName -like "*qBittorrent*" } | ForEach-Object {
    Write-Host "[*] Zamanlanmış görev kaldırılıyor: $($_.TaskName)" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
}

Write-Host "[✓] qBittorrent tamamen kaldırıldı." -ForegroundColor Green
