Write-Host "Tehdit durduruluyor..."

# 1. Prosesleri durdur
try {
    Get-Process | Where-Object { $_.ProcessName -like "*agent*" -or $_.ProcessName -like "*EaseUS*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "Tehdit prosesi durduruldu."
} catch {
    Write-Host "Proses bulunamadı veya zaten çalışmıyor."
}

# 2. Dosya yolunu tanımla
$Path = "$env:USERPROFILE\Downloads\a.zip"
$Encrypted = "$env:USERPROFILE\Downloads\a.remove"

# 3. Eğer dosya varsa şifrele ve .remove uzantısı ile kaydet
if (Test-Path $Path) {
    try {
        $Key = (1..32)
        $IV = (1..16)
        $AES = [System.Security.Cryptography.Aes]::Create()
        $AES.Key = $Key
        $AES.IV = $IV
        $Encryptor = $AES.CreateEncryptor()

        $In = [System.IO.File]::OpenRead($Path)
        $Out = [System.IO.File]::Create($Encrypted)
        $Crypto = New-Object System.Security.Cryptography.CryptoStream($Out,$Encryptor,"Write")
        $In.CopyTo($Crypto)
        $Crypto.Close(); $In.Close(); $Out.Close()

        Write-Host "Dosya şifrelendi ve uzantısı değiştirildi (.remove)."
    } catch {
        Write-Host "Şifreleme sırasında hata oluştu: $_"
    }

    # 4. Orijinal dosyayı sil
    try {
        Remove-Item -Path $Path -Force
        Write-Host "Tehdit siliniyor..."
        Start-Sleep -Seconds 2
        if (-Not (Test-Path $Path)) {
            Write-Host "✅ Tehdit başarıyla silindi."
        } else {
            Write-Host "⚠️ Tehdit silinmedi, manuel kontrol gerekli."
        }
    } catch {
        Write-Host "Dosya silinemedi: $_"
    }
} else {
    Write-Host "Dosya bulunamadı: $Path"
}
