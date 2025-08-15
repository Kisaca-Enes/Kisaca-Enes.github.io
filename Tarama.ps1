# Registry yolunu tanımla
$firewallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Firewall"

# Registry anahtarını oku
if (Test-Path $firewallKey) {
    $values = Get-ItemProperty -Path $firewallKey

    # Her bir değeri anlamlı şekilde yazdır
    Write-Host "Windows Firewall Politikaları (Sistem Seviyesi):"
    foreach ($name in $values.PSObject.Properties.Name) {
        if ($name -ne "PSPath" -and $name -ne "PSParentPath" -and $name -ne "PSChildName" -and $name -ne "PSDrive" -and $name -ne "PSProvider") {
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
