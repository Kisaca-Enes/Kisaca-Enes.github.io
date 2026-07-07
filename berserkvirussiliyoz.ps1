<#
.SYNOPSIS
    Loglardan tespit edilen şüpheli dosyaları, hile yazılımlarını ve güvenlik açıklarını tarar/temizler.
.DESCRIPTION
    FRST, FSS ve SecurityCheck loglarından elde edilen verilere göre hazırlanmıştır.
    - Windows Defender istisnalarını (KMS, hack-agent vb.) kaldırır.
    - Şüpheli klasör/dosyaları karantinaya alır (taşır).
    - RDP (Uzaktan Masaüstü) bağlantısını kapatır.
    - Windows Defender'ı yeniden etkinleştirir ve başlatır.
.PARAMETER Clean
    Bu parametre kullanılırsa, bulunan öğeler otomatik olarak temizlenir/karantinaya alınır.
    Kullanılmazsa sadece raporlama yapar.
.EXAMPLE
    .\CleanMySystem.ps1               (Sadece tarar, rapor sunar)
    .\CleanMySystem.ps1 -Clean        (Tarama yapar ve temizleme işlemlerini uygular)
#>

#requires -RunAsAdministrator

# ---- Değişkenler ----
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm"
$LogFile = "$env:USERPROFILE\Desktop\Guvenlik_Temizlik_Raporu_$ReportDate.txt"
$QuarantineRoot = "C:\Quarantine_$ReportDate"

# ---- Tespit Edilen Şüpheli Öğeler (Loglardan derlenmiştir) ----
$SuspiciousItems = @(
    "C:\Users\RBminor\Desktop\hack-agent",                    # Açıkça "hack" ismi
    "C:\Users\RBminor\Desktop\c",                              # Tarihi 05.07.2026, içeriği belirsiz
    "C:\Users\RBminor\Downloads\KMSAuto_Lite_v1.7.3.FP",      # KMS crack aracı
    "C:\Windows\System32\SECOPatcher.dll",                    # Bilinmeyen DLL
    "C:\Users\RBminor\AppData\Local\Temp\dControl.exe",       # Geçici klasördeki EXE
    "C:\Program Files (x86)\xmodhub"                          # Çin yapımı hile/mod yazılımı
)

# ---- Tespit Edilen Riskli Yazılımlar (Program ekle/kaldır listesinde görülenler) ----
$RiskliYazilimlar = @(
    "Cheat Engine",
    "WeMod",
    "Wand",
    "xmodhub"
)

# ---- Defender İstisnaları (Exclusions) ----
$DefenderExclusionPaths = @(
    "C:\Users\RBminor\Downloads\KMSAuto_Lite_v1.7.3.FP",
    "C:\Windows\System32\SECOPatcher.dll",
    "C:\Users\RBminor\AppData\Local\Temp\dControl.exe",
    "C:\Users\RBminor\Desktop\hack-agent"
)

# ---- Başlangıç ----
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  GUVENLIK TEMIZLIK BETIGI (Log Tabanli Tespit)" -ForegroundColor Yellow
Write-Host "  Tarih: $ReportDate" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Log başlığı
"============================================" | Out-File -FilePath $LogFile
" GUVENLIK TEMIZLIK RAPORU - $ReportDate"    | Out-File -FilePath $LogFile -Append
"============================================" | Out-File -FilePath $LogFile -Append
"Kullanici: $env:USERNAME"                    | Out-File -FilePath $LogFile -Append
"Bilgisayar: $env:COMPUTERNAME"               | Out-File -FilePath $LogFile -Append
"============================================" | Out-File -FilePath $LogFile -Append
""                                            | Out-File -FilePath $LogFile -Append

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    $LogEntry = "[$TimeStamp] $Message"
    Write-Host $LogEntry -ForegroundColor $Color
    $LogEntry | Out-File -FilePath $LogFile -Append
}

# ---- 1. Defender İstisnalarını Temizleme ----
function Clear-DefenderExclusions {
    Write-Log "[1/5] Windows Defender Istisnalari taranıyor..." "Cyan"
    
    try {
        $CurrentExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
        if ($CurrentExclusions) {
            Write-Log "   Mevcut Istisnalar:" "Yellow"
            $CurrentExclusions | ForEach-Object { Write-Log "     - $_" "Yellow" }
        } else {
            Write-Log "   Hiçbir istisna bulunamadı." "Green"
        }

        if ($Clean) {
            Write-Log "   [TEMIZLIK] Bilinen zararlı istisnalar kaldırılıyor..." "Magenta"
            foreach ($Excl in $DefenderExclusionPaths) {
                if (Get-MpPreference | Where-Object { $_.ExclusionPath -like "*$Excl*" }) {
                    # Remove-MpPreference belirli bir yolu kaldırmaz, tümünü sıfırlamak daha güvenlidir.
                    # Ancak tüm istisnaları kaldırmak yerine sadece bizim listemizdekileri hedefleyelim.
                    # PowerShell'de belirli bir ExclusionPath'i kaldırmanın direkt yolu yok. 
                    # Biz mevcut istisnaları alıp, bizim listemizdekileri filtreleyerek yeniden atayalım.
                    $NewExclusions = $CurrentExclusions | Where-Object { $_ -notin $DefenderExclusionPaths }
                    Set-MpPreference -ExclusionPath $NewExclusions
                    Write-Log "     [+] Kaldırıldı: $Excl" "Green"
                } else {
                    Write-Log "     [-] Zaten mevcut degil: $Excl" "Gray"
                }
            }
        } else {
            Write-Log "   [UYARI] Tarama modu. Istisnalari kaldirmak icin -Clean parametresini kullanin." "Yellow"
        }
    } catch {
        Write-Log "   [!] Defender istisnaları işlenirken hata: $_" "Red"
    }
}

# ---- 2. Şüpheli Dosya/Klasörleri Karantinaya Alma ----
function Move-SuspiciousItems {
    Write-Log "[2/5] Şüpheli dosya/klasörler taranıyor..." "Cyan"

    if ($Clean) {
        # Karantina klasörünü oluştur
        if (-not (Test-Path $QuarantineRoot)) {
            New-Item -ItemType Directory -Path $QuarantineRoot -Force | Out-Null
            Write-Log "   [+] Karantina klasörü oluşturuldu: $QuarantineRoot" "Gray"
        }
    }

    foreach ($Item in $SuspiciousItems) {
        if (Test-Path $Item) {
            Write-Log "   [!] BULUNDU: $Item" "Red"
            
            if ($Clean) {
                try {
                    $Destination = Join-Path $QuarantineRoot (Split-Path $Item -Leaf)
                    # Eğer aynı isim varsa tarih ekle
                    if (Test-Path $Destination) {
                        $Destination = "$Destination`_$ReportDate"
                    }
                    Move-Item -Path $Item -Destination $Destination -Force
                    Write-Log "     [+] Karantinaya alındı: $Destination" "Green"
                } catch {
                    Write-Log "     [-] Taşıma başarısız: $_" "Red"
                }
            } else {
                Write-Log "     [UYARI] Silmek/Taşımak için -Clean kullanın." "Yellow"
            }
        } else {
            Write-Log "   [-] Bulunamadı: $Item" "Gray"
        }
    }
}

# ---- 3. Riskli Yazılımları Kaldırma (Opsiyonel, elle yapmak daha iyidir ama listeler) ----
function Check-RiskySoftware {
    Write-Log "[3/5] Riskli yazılımlar (Hile/Cheat) taranıyor..." "Cyan"
    
    $Installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                 Where-Object { $_.DisplayName -ne $null } | 
                 Select-Object -ExpandProperty DisplayName
    $Installed += Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                  Where-Object { $_.DisplayName -ne $null } | 
                  Select-Object -ExpandProperty DisplayName

    foreach ($Risk in $RiskliYazilimlar) {
        $Found = $Installed | Where-Object { $_ -like "*$Risk*" }
        if ($Found) {
            Write-Log "   [!] BULUNDU (Yüklü): $Risk" "Red"
            Write-Log "     [UYARI] Program ekle/kaldır'dan manuel olarak kaldırmanız önerilir." "Yellow"
        } else {
            Write-Log "   [-] Bulunamadı: $Risk" "Gray"
        }
    }
}

# ---- 4. Uzaktan Masaüstü (RDP) Kapatma ----
function Disable-RDP {
    Write-Log "[4/5] Uzaktan Masaüstü (RDP) durumu kontrol ediliyor..." "Cyan"
    
    $RDPKey = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
    $CurrentValue = (Get-ItemProperty -Path $RDPKey -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections

    if ($CurrentValue -eq 0) {
        Write-Log "   [!] UYARI: Uzaktan Masaüstü ACIK durumda!" "Red"
        if ($Clean) {
            Set-ItemProperty -Path $RDPKey -Name "fDenyTSConnections" -Value 1
            Write-Log "   [+] RDP kapatıldı." "Green"
        } else {
            Write-Log "   [UYARI] Kapatmak için -Clean kullanın." "Yellow"
        }
    } else {
        Write-Log "   [+] RDP zaten kapalı (güvenli)." "Green"
    }
}

# ---- 5. Windows Defender'ı Yeniden Etkinleştirme ----
function Enable-Defender {
    Write-Log "[5/5] Windows Defender etkinleştiriliyor..." "Cyan"

    try {
        # Kayıt defterindeki devre dışı bırakma anahtarını kaldır
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
        if (Get-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $RegPath -Name "DisableAntiSpyware" -Force
            Write-Log "   [+] Kayıt defteri anahtarı kaldırıldı (DisableAntiSpyware)." "Green"
        } else {
            Write-Log "   [-] Kayıt defterinde engelleyici anahtar bulunamadı." "Gray"
        }

        # Servisleri Ayarla
        Set-Service -Name WinDefend -StartupType Automatic -ErrorAction SilentlyContinue
        Set-Service -Name WdNisSvc -StartupType Manual -ErrorAction SilentlyContinue
        Set-Service -Name MDCoreSvc -StartupType Manual -ErrorAction SilentlyContinue
        
        # Servisleri Başlat
        Start-Service -Name WinDefend -ErrorAction SilentlyContinue
        Start-Service -Name WdNisSvc -ErrorAction SilentlyContinue
        Start-Service -Name MDCoreSvc -ErrorAction SilentlyContinue

        $DefStatus = (Get-Service -Name WinDefend).Status
        if ($DefStatus -eq "Running") {
            Write-Log "   [+] Windows Defender başarıyla başlatıldı! Durum: $DefStatus" "Green"
        } else {
            Write-Log "   [!] Windows Defender başlatılamadı. Durum: $DefStatus. Bilgisayarı yeniden başlatmayı deneyin." "Yellow"
        }
    } catch {
        Write-Log "   [!] Defender etkinleştirilirken hata: $_" "Red"
    }
}

# ---- ANA AKIŞ ----
try {
    # Parametre kontrolü (Eğer -Clean yoksa sadece tarama modu)
    if (-not $Clean) {
        Write-Log "****************** TARAMA MODU ******************" "Yellow"
        Write-Log "Hiçbir dosya silinmeyecek veya taşınmayacak." "Yellow"
        Write-Log "Aktif temizlik için betiği '-Clean' parametresiyle çalıştırın." "Yellow"
        Write-Log "Örnek: .\CleanMySystem.ps1 -Clean" "Cyan"
        Write-Log "***********************************************" "Yellow"
        ""
    } else {
        Write-Log "****************** TEMİZLİK MODU ******************" "Magenta"
        Write-Log "Tespit edilen zararlı öğeler karantinaya alınacak." "Magenta"
        Write-Log "***********************************************" "Magenta"
        ""
    }

    Clear-DefenderExclusions
    Move-SuspiciousItems
    Check-RiskySoftware
    Disable-RDP
    Enable-Defender

    Write-Log "" "Cyan"
    Write-Log "================================================" "Green"
    Write-Log " TARAMA/TEMİZLİK TAMAMLANDI!" "Green"
    Write-Log " Rapor dosyası: $LogFile" "Gray"
    Write-Log "================================================" "Green"
    
    if ($Clean) {
        Write-Log "Not: Bilgisayarınızı yeniden başlatmanız önerilir." "Yellow"
    }

} catch {
    Write-Log "Beklenmeyen bir hata oluştu: $_" "Red"
}
