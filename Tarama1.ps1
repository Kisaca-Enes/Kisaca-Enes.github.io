# USB ve Mouse Cihaz Durumları ve Hata Logları Kontrol Scripti

Write-Host "=== USB ve Mouse Aygıt Durumları ===" -ForegroundColor Cyan

# Sorunlu USB cihazları
$usbIssues = Get-PnpDevice -Class USB | Where-Object { $_.Status -ne "OK" }
if ($usbIssues) {
    Write-Host "`n[!] Sorunlu USB cihazları:" -ForegroundColor Red
    $usbIssues | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize
} else {
    Write-Host "`n[✓] USB cihazlarında sorun görünmüyor." -ForegroundColor Green
}

# Mouse aygıtları
Write-Host "`n[+] Mouse cihazları:" -ForegroundColor Yellow
Get-PnpDevice -Class Mouse | Format-Table FriendlyName, Status, InstanceId -AutoSize

# HID aygıtları
Write-Host "`n[+] HID (İnsan Arabirimi) cihazları:" -ForegroundColor Yellow
Get-PnpDevice -Class HIDClass | Format-Table FriendlyName, Status, InstanceId -AutoSize

# USB ve HID ile ilgili sistem logları (son 1 gün)
Write-Host "`n=== USB ve HID ile İlgili Sistem Olayları (Son 1 Gün) ===" -ForegroundColor Cyan

$since = (Get-Date).AddDays(-1)
$events = Get-WinEvent -LogName System | Where-Object { 
    ($_.TimeCreated -ge $since) -and 
    ($_.Message -match "USB" -or $_.Message -match "HID") 
} | Select-Object TimeCreated, Id, LevelDisplayName, Message

if ($events) {
    $events | Format-Table TimeCreated, Id, LevelDisplayName, @{Name="Mesaj";Expression={$_.Message.Substring(0,60) + "..."} } -AutoSize
} else {
    Write-Host "[✓] Son 1 gün içinde USB/HID ile ilgili sistemde hata veya uyarı yok." -ForegroundColor Green
}

# USB Root Hub güç yönetimi durumu (ilk 3 port için kontrol)
Write-Host "`n=== USB Root Hub Güç Yönetimi Durumu ===" -ForegroundColor Cyan
$usbHubs = Get-PnpDevice -FriendlyName "*USB Root Hub*" | Select-Object -First 3
foreach ($hub in $usbHubs) {
    $prop = Get-PnpDeviceProperty -InstanceId $hub.InstanceId -KeyName "DEVPKEY_Device_PowerManagementSupported" -ErrorAction SilentlyContinue
    $powerMgmt = if ($prop) { $prop.Data } else { "Bilinmiyor" }
    Write-Host "$($hub.FriendlyName): Güç Yönetimi Destekli mü? -> $powerMgmt"
}

Write-Host "`nScript tamamlandı." -ForegroundColor Cyan
