# =============================================
# Zararlı Kaldırma Betiği (Kopyala + Sil)
# BetterUi.jar / halo.jar / Nativery / halos
# =============================================

# Yönetici kontrolü
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[!] Yönetici olarak çalıştırmadınız! Betik düzgün çalışmayabilir." -ForegroundColor Red
    Read-Host "Devam etmek için Enter'a bas..."
}

# 1. Karantina klasörü oluştur
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$QuarantinePath = "$env:LOCALAPPDATA\Quarantine_$timestamp"
Write-Host "[*] Karantina klasörü: $QuarantinePath" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $QuarantinePath -Force | Out-Null

# 2. Zararlı süreçleri durdur
Write-Host "[*] Zararlı süreçler sonlandırılıyor..." -ForegroundColor Cyan
Stop-Process -Name "javaw" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue

# 3. Dosyaları KARANTİNAYA KOPYALA (orijinalleri bozulmadan kalır)
Write-Host "[*] Dosyalar karantinaya kopyalanıyor..." -ForegroundColor Cyan

# a) halo.jar
$source1 = "$env:LOCALAPPDATA\halo.jar"
if (Test-Path $source1) {
    Copy-Item -Path $source1 -Destination $QuarantinePath -Force
    Write-Host "[+] Kopyalandı: $source1 -> $QuarantinePath" -ForegroundColor Green
} else { Write-Host "[-] Bulunamadı: $source1" -ForegroundColor Yellow }

# b) Nativery klasörü
$source2 = "$env:LOCALAPPDATA\Nativery"
if (Test-Path $source2) {
    $dest2 = Join-Path $QuarantinePath "Nativery"
    Copy-Item -Path $source2 -Destination $dest2 -Recurse -Force
    Write-Host "[+] Kopyalandı: $source2 -> $dest2" -ForegroundColor Green
} else { Write-Host "[-] Bulunamadı: $source2" -ForegroundColor Yellow }

# c) halos klasörü
$source3 = "$env:LOCALAPPDATA\halos"
if (Test-Path $source3) {
    $dest3 = Join-Path $QuarantinePath "halos"
    Copy-Item -Path $source3 -Destination $dest3 -Recurse -Force
    Write-Host "[+] Kopyalandı: $source3 -> $dest3" -ForegroundColor Green
} else { Write-Host "[-] Bulunamadı: $source3" -ForegroundColor Yellow }

# 4. ORİJİNALLERİ KALICI OLARAK SİL (geri dönüşüme gitmez)
Write-Host "[*] Orijinal dosyalar siliniyor..." -ForegroundColor Cyan
if (Test-Path $source1) { Remove-Item -Path $source1 -Force; Write-Host "[+] Silindi: $source1" }
if (Test-Path $source2) { Remove-Item -Path $source2 -Recurse -Force; Write-Host "[+] Silindi: $source2" }
if (Test-Path $source3) { Remove-Item -Path $source3 -Recurse -Force; Write-Host "[+] Silindi: $source3" }

# 5. Geçici dosyaları temizle
Write-Host "[*] %TEMP%'deki kalıntılar siliniyor..." -ForegroundColor Cyan
Remove-Item "$env:TEMP\sqlitejdbc*.dll" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\jnidispatch*.dll" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\abe_extractor*.bin" -Force -ErrorAction SilentlyContinue

# =============================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "[✔] İŞLEM TAMAMLANDI!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "[!] Kopyalanan dosyalar KARANTİNA'da saklanıyor:"
Write-Host "    $QuarantinePath" -ForegroundColor Yellow
Write-Host "`n[!] ORİJİNALLER KALICI OLARAK SİLİNDİ." -ForegroundColor Red
Write-Host "[!] Bilgisayarınızı YENİDEN BAŞLATIN (RAM'deki yük temizlensin)." -ForegroundColor Red
Write-Host "[!] Minecraft mods klasöründeki 'BetterUi.jar' dosyasını MANUEL silin!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Magenta

# Karantina klasörünü açmak ister misin?
$secim = Read-Host "`nKarantina klasörünü açmak ister misiniz? (E/H)"
if ($secim -eq 'E' -or $secim -eq 'e') {
    Invoke-Item $QuarantinePath
}
