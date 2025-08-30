# -----------------------------
# Sistem ve Yazılım Güncelleme Kontrol Scripti
# -----------------------------
Write-Host "=== Güncelleme Kontrol Başlatıldı ===" -ForegroundColor Cyan

# 1. Windows Update Durumu
Write-Host "`n[*] Windows Update Durumu:" -ForegroundColor Yellow
try {
    $updates = Get-WindowsUpdateLog -ErrorAction Stop
    Write-Host "Windows Update logları hazır." -ForegroundColor Green
} catch {
    Write-Host "Windows Update loglarına erişilemedi veya Windows Update module eksik." -ForegroundColor Red
}

# Alternatif: Windows Update Service açık mı kontrol
$wu = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if ($wu.Status -eq "Running") {
    Write-Host "Windows Update servisi çalışıyor." -ForegroundColor Green
} else {
    Write-Host "Windows Update servisi çalışmıyor." -ForegroundColor Red
}

# 2. Yüklü Programları Listele
Write-Host "`n[*] Yüklü Programlar (ProgramFiles ve Registry):" -ForegroundColor Yellow

# Registry'den 32-bit ve 64-bit programlar
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedPrograms = @()

foreach ($path in $registryPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -ne $null } | Select-Object DisplayName, DisplayVersion, Publisher
    $installedPrograms += $apps
}

$installedPrograms | Sort-Object DisplayName | Format-Table -AutoSize

Write-Host "`n[*] Kontrol tamamlandı. Program versiyonlarını güncel sürümlerle karşılaştırarak eksik olanları güncelleyebilirsiniz." -ForegroundColor Cyan
