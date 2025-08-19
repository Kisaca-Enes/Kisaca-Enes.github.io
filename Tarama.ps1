# ======== Mouse & Touchpad Tarama Scripti ========

# 1️⃣ Mouse ve Touchpad cihazlarını listele
Write-Host "Tüm Mouse / Touchpad cihazları taranıyor..."
$devices = Get-PnpDevice -Class Mouse | Select-Object FriendlyName, Status, Manufacturer, InstanceId

# 2️⃣ Rapor oluştur
$report = @()
foreach ($dev in $devices) {
    $status = if ($dev.Status -eq "OK") { "Sağlıklı" } else { "Sorunlu" }
    $reportObj = [PSCustomObject]@{
        CihazAdı     = $dev.FriendlyName
        Üretici      = $dev.Manufacturer
        DeviceID     = $dev.InstanceId
        Durum        = $status
        Zaman        = Get-Date
    }
    $report += $reportObj
}

# 3️⃣ Raporu ekrana yazdır
Write-Host "`n========== TARAMA RAPORU =========="
$report | Format-Table -AutoSize

# 4️⃣ Opsiyonel: raporu dosyaya kaydet
$logPath = "$env:USERPROFILE\Desktop\Mouse_Touchpad_Rapor.txt"
$report | Out-File -FilePath $logPath -Encoding UTF8
Write-Host "`nRapor kaydedildi: $logPath"

# 5️⃣ Özet mesaj
Write-Host "`nTarama tamamlandı. Cihazların durumu yukarıda listelendi."
