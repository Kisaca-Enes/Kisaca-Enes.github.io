# ================================
# Malware Cleaner - PowerShell
# ================================

$Log = "$PSScriptRoot\temizlik_raporu.txt"

"Malware Temizlik Raporu" | Out-File $Log -Encoding UTF8
"Tarih: $(Get-Date)" | Out-File $Log -Append
"----------------------------------------" | Out-File $Log -Append

Write-Host "========================================"
Write-Host "  MALWARE TEMİZLEME VE ONARIM ARACI"
Write-Host "========================================`n"

# ADMIN KONTROL
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "[HATA] Yönetici olarak çalıştırılmalı!" -ForegroundColor Red
    Pause
    exit
}

Write-Host "[+] Yönetici yetkisi doğrulandı"
"Yönetici yetkisi OK" | Out-File $Log -Append

# 1) TCP/IP PARAMETRELERİ
Write-Host "`n[1/7] TCP/IP Registry temizleniyor..."
$TcpParams = @(
"DefaultTTL","TcpMaxDataRetransmissions","TcpNumConnections",
"TcpTimedWaitDelay","KeepAliveTime","KeepAliveInterval",
"EnablePMTUDiscovery","EnablePMTUBHDetect",
"DisableIPSourceRouting","SackOpts","Tcp1323Opts"
)

foreach ($key in $TcpParams) {
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        -Name $key -ErrorAction SilentlyContinue
    Write-Host " - $key temizlendi"
    "TCP/IP: $key silindi" | Out-File $Log -Append
}

# 2) AĞ KARTI REGISTRY
Write-Host "`n[2/7] Ağ kartı tweakleri temizleniyor..."
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" |
ForEach-Object {
    Remove-ItemProperty $_.PSPath -Name TCPNoDelay,TcpAckFrequency,TcpDelAckTicks,TcpWindowSize `
        -ErrorAction SilentlyContinue
}
"Network Interface tweakleri temizlendi" | Out-File $Log -Append
Write-Host "[+] Ağ kartı registry ayarları temizlendi"

# 3) SERVİSLER
Write-Host "`n[3/7] Sistem servisleri onarılıyor..."
Set-Service DPS -StartupType Automatic
Start-Service DPS -ErrorAction SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT" -Name Start -Value 1
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\lmhosts" -Name Start -Value 2
"Servisler onarıldı (DPS, NetBT, lmhosts)" | Out-File $Log -Append
Write-Host "[+] Servisler düzeltildi"

# 4) DNS CACHE
Write-Host "`n[4/7] DNS cache ayarları temizleniyor..."
$DnsKeys = @(
"NegativeCacheTime","NetFailureCacheTime",
"NegativeSOACacheTime","CacheHashTableSize"
)

foreach ($k in $DnsKeys) {
    Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" `
        -Name $k -ErrorAction SilentlyContinue
}
ipconfig /flushdns | Out-Null
"DNS cache temizlendi" | Out-File $Log -Append
Write-Host "[+] DNS temizlendi"

# 5) QoS / Multimedia
Write-Host "`n[5/7] QoS ve Multimedia ayarları sıfırlanıyor..."
Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" `
    -Name NonBestEffortLimit -ErrorAction SilentlyContinue
Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
    -Name NetworkThrottlingIndex,SystemResponsiveness -ErrorAction SilentlyContinue
"QoS / Multimedia registry temizlendi" | Out-File $Log -Append
Write-Host "[+] QoS ve Multimedia temizlendi"

# 6) NETWORK RESET
Write-Host "`n[6/7] Ağ yapılandırması sıfırlanıyor..."
netsh int tcp reset | Out-Null
netsh int ip reset | Out-Null
netsh winsock reset | Out-Null
"Network reset uygulandı" | Out-File $Log -Append
Write-Host "[+] Network reset tamamlandı"

# 7) TEMP
Write-Host "`n[7/7] Geçici dosyalar temizleniyor..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
"Temp klasörleri temizlendi" | Out-File $Log -Append
Write-Host "[+] Temp klasörleri temizlendi"

# DEFENDER
Write-Host "`n[+] Windows Defender tam tarama başlatılıyor..."
"Defender tam tarama başlatıldı" | Out-File $Log -Append
& "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

# SON
Write-Host "`n========================================"
Write-Host "  KÖTÜ AMAÇLI İŞLEMLER TEMİZLENDİ"
Write-Host "========================================"
Write-Host "`nRapor: $Log"

"Kötü Amaçlı işlemler temizlendi" | Out-File $Log -Append
"Temizlik tamamlandı" | Out-File $Log -Append
Pause
