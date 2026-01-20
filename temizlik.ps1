# ================================
# Malware Cleaner - PowerShell
# ================================

$Log = "$PSScriptRoot\temizlik_raporu.txt"

"Malware Temizlik Raporu" | Out-File $Log -Encoding UTF8
"Tarih: $(Get-Date)" | Out-File $Log -Append
"----------------------------------------" | Out-File $Log -Append

Write-Host "========================================"
Write-Host "  MALWARE TEMİZLEME VE ONARIM ARACI"
Write-Host "========================================"
Write-Host ""

# ADMIN KONTROL (EN STABIL YÖNTEM)
net session >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[HATA] Yönetici olarak çalıştırılmalı!" -ForegroundColor Red
    Pause
    exit
}

Write-Host "[+] Yönetici yetkisi doğrulandı"
"Yönetici yetkisi OK" | Out-File $Log -Append

# 1) TCP/IP PARAMETRELERİ
Write-Host ""
Write-Host "[1/7] TCP/IP Registry temizleniyor..."

$TcpParams = @(
    "DefaultTTL",
    "TcpMaxDataRetransmissions",
    "TcpNumConnections",
    "TcpTimedWaitDelay",
    "KeepAliveTime",
    "KeepAliveInterval",
    "EnablePMTUDiscovery",
    "EnablePMTUBHDetect",
    "DisableIPSourceRouting",
    "SackOpts",
    "Tcp1323Opts"
)

foreach ($key in $TcpParams) {
    Remove-ItemProperty `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        -Name $key `
        -ErrorAction SilentlyContinue

    Write-Host " - $key temizlendi"
    "TCP/IP: $key silindi" | Out-File $Log -Append
}

# 2) AĞ KARTI REGISTRY
Write-Host ""
Write-Host "[2/7] Ağ kartı tweakleri temizleniyor..."

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" |
ForEach-Object {
    Remove-ItemProperty `
        -Path $_.PSPath `
        -Name TCPNoDelay,TcpAckFrequency,TcpDelAckTicks,TcpWindowSize `
        -ErrorAction SilentlyContinue
}

"Network Interface tweakleri temizlendi" | Out-File $Log -Append
Write-Host "[+] Ağ kartı registry ayarları temizlendi"

# 3) SERVİSLER
Write-Host ""
Write-Host "[3/7] Sistem servisleri onarılıyor..."

Set-Service DPS -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service DPS -ErrorAction SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT" -Name Start -Value 1
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\lmhosts" -Name Start -Value 2

"Servisler onarıldı (DPS, NetBT, lmhosts)" | Out-File $Log -Append
Write-Host "[+] Servisler düzeltildi"

# 4) DNS CACHE
Write-Host ""
Write-Host "[4/7] DNS cache ayarları temizleniyor..."

$DnsKeys = @(
    "NegativeCacheTime",
    "NetFailureCacheTime",
    "NegativeSOACacheTime",
    "CacheHashTableSize"
)

foreach ($k in $DnsKeys) {
    Remove-ItemProperty `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" `
        -Name $k `
        -ErrorAction SilentlyContinue
}

ipconfig /flushdns | Out-Null
"DNS cache temizlendi" | Out-File $Log -Append
Write-Host "[+] DNS temizlendi"

# 5) QoS / Multimedia
Write-Host ""
Write-Host "[5/7] QoS ve Multimedia ayarları sıfırlanıyor..."

Remove-ItemProperty `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" `
    -Name NonBestEffortLimit `
    -ErrorAction SilentlyContinue

Remove-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
    -Name NetworkThrottlingIndex,SystemResponsiveness `
    -ErrorAction SilentlyContinue

"QoS / Multimedia registry temizlendi" | Out-File $Log -Append
Write-Host "[+] QoS ve Multimedia temizlendi"

# 6) NETWORK RESET
Write-Host ""
Write-Host "[6/7] Ağ yapılandırması sıfırlanıyor..."

netsh int tcp reset | Out-Null
netsh int ip reset | Out-Null
netsh winsock reset | Out-Null

"Network reset uygulandı" | Out-File $Log -Append
Write-Host "[+] Network reset tamamlandı"

# 7) TEMP DOSYALARI
Write-Host ""
Write-Host "[7/7] Geçici dosyalar temizleniyor..."

Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

"Temp klasörleri temizlendi" | Out-File $Log -Append
Write-Host "[+] Temp klasörleri temizlendi"

# DEFENDER
Write-Host ""
Write-Host "[+] Windows Defender tam tarama başlatılıyor..."

"Defender tam tarama başlatıldı" | Out-File $Log -Append
& "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

# SON
Write-Host ""
Write-Host "========================================"
Write-Host "  KÖTÜ AMAÇLI İŞLEMLER TEMİZLENDİ"
Write-Host "========================================"
Write-Host ""
Write-Host "Rapor: $Log"

"Kötü Amaçlı işlemler temizlendi" | Out-File $Log -Append
"Temizlik tamamlandı" | Out-File $Log -Append

Pause
