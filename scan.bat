@echo off
chcp 65001 >nul
title Malware Cleaner - Sistem Temizleyici
color 0A

:: LOG DOSYASI
set LOG=%~dp0temizlik_raporu.txt
echo Malware Temizlik Raporu > "%LOG%"
echo Tarih: %date%  Saat: %time% >> "%LOG%"
echo ---------------------------------------- >> "%LOG%"

cls
echo ========================================
echo   MALWARE TEMİZLEME VE ONARIM ARACI
echo ========================================
echo.

:: ADMIN KONTROL
net session >nul 2>&1
if %errorlevel% neq 0 (
 echo [HATA] Yönetici olarak çalıştırılmalı!
 pause
 exit
)

echo [+] Yönetici yetkisi doğrulandı
echo Yönetici yetkisi OK >> "%LOG%"
echo.

:: 1) TCP/IP PARAMETRELERİ TEMİZLE
echo [1/7] TCP/IP Registry temizleniyor...
for %%A in (
 DefaultTTL
 TcpMaxDataRetransmissions
 TcpNumConnections
 TcpTimedWaitDelay
 KeepAliveTime
 KeepAliveInterval
 EnablePMTUDiscovery
 EnablePMTUBHDetect
 DisableIPSourceRouting
 SackOpts
 Tcp1323Opts
) do (
 reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v %%A /f >nul 2>&1
 echo    - %%A temizlendi
 echo TCP/IP: %%A silindi >> "%LOG%"
)
echo [+] TCP/IP ayarları temizlendi
echo.

:: 2) AĞ KARTI BAZLI REGISTRY TEMİZLİĞİ
echo [2/7] Ağ kartı tweakleri temizleniyor...
for /f %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"') do (
 reg delete "%%i" /v TCPNoDelay /f >nul 2>&1
 reg delete "%%i" /v TcpAckFrequency /f >nul 2>&1
 reg delete "%%i" /v TcpDelAckTicks /f >nul 2>&1
 reg delete "%%i" /v TcpWindowSize /f >nul 2>&1
)
echo [+] Ağ kartı registry ayarları temizlendi
echo Network Interface tweakleri temizlendi >> "%LOG%"
echo.

:: 3) SERVİSLERİ ESKİ HALİNE AL
echo [3/7] Sistem servisleri onarılıyor...
sc config DPS start= auto >nul
sc start DPS >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT" /v Start /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lmhosts" /v Start /t REG_DWORD /d 2 /f >nul
echo [+] Servisler düzeltildi
echo Servisler (DPS, NetBT, lmhosts) onarıldı >> "%LOG%"
echo.

:: 4) DNS VE CACHE SABOTAJINI GERİ AL
echo [4/7] DNS cache ayarları temizleniyor...
for %%D in (
 NegativeCacheTime
 NetFailureCacheTime
 NegativeSOACacheTime
 CacheHashTableSize
) do (
 reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v %%D /f >nul 2>&1
 echo DNS: %%D silindi >> "%LOG%"
)
ipconfig /flushdns >nul
echo [+] DNS temizlendi
echo.

:: 5) QoS / Multimedia GERİ AL
echo [5/7] QoS ve Multimedia ayarları sıfırlanıyor...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /f >nul 2>&1
echo [+] QoS ve Multimedia temizlendi
echo QoS / Multimedia registry temizlendi >> "%LOG%"
echo.

:: 6) AĞ STACK RESET
echo [6/7] Ağ yapılandırması sıfırlanıyor...
netsh int tcp reset >nul
netsh int ip reset >nul
netsh winsock reset >nul
echo [+] Network reset tamamlandı
echo Network reset uygulandı >> "%LOG%"
echo.

:: 7) TEMP DOSYALARI TEMİZLE
echo [7/7] Geçici dosyalar temizleniyor...
del /s /f /q %temp%\* >nul 2>&1
del /s /f /q C:\Windows\Temp\* >nul 2>&1
echo [+] Temp klasörleri temizlendi
echo Temp klasörleri temizlendi >> "%LOG%"
echo.

:: DEFENDER TARAMA
echo ---------------------------------------- >> "%LOG%"
echo Defender tam tarama başlatıldı >> "%LOG%"
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

:: SON
echo.
echo ========================================
echo   KÖTÜ AMAÇLI İŞLEMLER TEMİZLENDİ
echo ========================================
echo.
echo Temizlik raporu kaydedildi:
echo %LOG%
echo.

echo Kötü Amaçlı işlemler temizlendi >> "%LOG%"
echo Temizlik tamamlandı >> "%LOG%"

pause
