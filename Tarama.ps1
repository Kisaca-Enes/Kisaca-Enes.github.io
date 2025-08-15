# Registry yolunu tanımla
$firewallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Firewall"

# Registry anahtarının var olup olmadığını kontrol et
if (Test-Path $firewallKey) {

    # Anahtarı oku
    $values = Get-ItemProperty -Path $firewallKey

    Write-Host "Windows Firewall Sistem Politikaları:`n"

    # Her bir değeri kontrol et ve anlamlı şekilde yazdır
    foreach ($name in $values.PSObject.Properties.Name) {

        # PowerShell’in otomatik eklediği özellikleri atla
        if ($name -notin "PSPath","PSParentPath","PSChildName","PSDrive","PSProvider") {
            $value = $values.$name
            switch ($name) {
                "EnableFirewall" {
                    $status = if ($value -eq 1) { "Açık" } else { "Kapalı" }
                    Write-Host "$name : $status"
                }
                "DoNotAllowExceptions" {
                    $status = if ($value -eq 1) { "İstisna yapılamaz" } else { "İstisna yapılabilir" }
                    Write-Host "$name : $status"
                }
                "DisableNotifications" {
                    $status = if ($value -eq 1) { "Uyarılar kapalı" } else { "Uyarılar açık" }
                    Write-Host "$name : $status"
                }
                "LocalPolicyMerge" {
                    $status = if ($value -eq 1) { "Grup Politikası ile birleştirilir" } else { "Birleştirilmez" }
                    Write-Host "$name : $status"
                }
                default {
                    Write-Host "$name : $value"
                }
            }
        }
    }

} else {
    Write-Host "Firewall registry anahtarı bulunamadı."
}
