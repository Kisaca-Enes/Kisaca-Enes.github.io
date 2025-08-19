# Sistem Genel Sorun Tespit Scripti
# Yönetici olarak çalıştırmanı öneririm.

Write-Host "=== Sistem Sağlık Kontrolü Başlıyor ===`n"

# 1. Problemli cihazları listele
Write-Host "`n[1] Problemli Aygıtlar:" -ForegroundColor Cyan
pnputil /enum-devices /problem 2>$null

# 2. Son 50 sistem hatası (Event Viewer - System log)
Write-Host "`n[2] Son 50 Sistem Hatası:" -ForegroundColor Cyan
Get-WinEvent -LogName System -MaxEvents 50 | 
    Where-Object { $_.LevelDisplayName -eq "Error" } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Format-Table -AutoSize

# 3. Sürücü sorunları
Write-Host "`n[3] Yüklü Sürücüler (Tarih ve Durum):" -ForegroundColor Cyan
Get-WmiObject Win32_PnPSignedDriver | 
    Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer | 
    Sort-Object DeviceName |
    Format-Table -AutoSize

# 4. Disk sağlığı
Write-Host "`n[4] Disk Durumu (SMART):" -ForegroundColor Cyan
Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus, Size | Format-Table -AutoSize

# 5. Sistem dosyası bozukluk taraması (SFC Preview)
Write-Host "`n[5] Sistem Dosyası Kontrolü:" -ForegroundColor Cyan
$sfc = sfc /verifyonly
if ($LASTEXITCODE -eq 0) {
    Write-Host "SFC: Sistem dosyaları sağlam görünüyor." -ForegroundColor Green
} else {
    Write-Host "SFC: Bazı bozukluklar tespit edildi, 'sfc /scannow' çalıştır." -ForegroundColor Red
}

Write-Host "`n=== Kontrol Tamamlandı ==="
