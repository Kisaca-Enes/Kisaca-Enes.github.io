Add-Type -AssemblyName System.IO.Compression.FileSystem

$ZipPath = "$env:USERPROFILE\Downloads\serevsiz.zip"
$TempDir = "$env:TEMP\serevsiz_temp"
$EncryptedZip = "$env:USERPROFILE\Downloads\serevsiz.remove"

Write-Host "Tehdit silme işlemi başladı..."

# 1. ZIP'i geçici dizine aç
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempDir)
    Write-Host "ZIP başarıyla açıldı."
} catch {
    Write-Host "ZIP açılamadı: $_"
    exit
}

# 2. EXE dosyalarını bul
$ExeFiles = Get-ChildItem -Path $TempDir -Recurse -Include *.exe
if ($ExeFiles.Count -eq 0) {
    Write-Host "⚠️ ZIP içinde exe dosyası bulunamadı."
} else {
    Write-Host "$($ExeFiles.Count) adet exe dosyası bulundu."
}

# 3. EXE dosyalarına karşılık gelen prosesleri kapat
foreach ($Exe in $ExeFiles) {
    $ProcName = [System.IO.Path]::GetFileNameWithoutExtension($Exe.Name)
    try {
        Get-Process -Name $ProcName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "✅ Proses durduruldu: $ProcName"
        } else {
            Write-Host "⚠️ Proses bulunamadı veya durdurulamadı: $ProcName"
        }
    } catch {
        Write-Host "❌ Proses kapatılırken hata: $ProcName"
    }
}

# 4. EXE dosyalarını şifrele
$Key = (1..32)
$IV = (1..16)
$AES = [System.Security.Cryptography.Aes]::Create()
$AES.Key = $Key
$AES.IV = $IV
$Encryptor = $AES.CreateEncryptor()

foreach ($Exe in $ExeFiles) {
    try {
        $EncPath = "$($Exe.FullName).enc"
        $In = [System.IO.File]::OpenRead($Exe.FullName)
        $Out = [System.IO.File]::Create($EncPath)
        $Crypto = New-Object System.Security.Cryptography.CryptoStream($Out,$Encryptor,"Write")
        $In.CopyTo($Crypto)
        $Crypto.Close(); $In.Close(); $Out.Close()
        Remove-Item $Exe.FullName -Force
        Write-Host "🔐 Şifrelendi ve orijinali silindi: $($Exe.Name)"
    } catch {
        Write-Host "❌ Şifreleme hatası: $($Exe.Name)"
    }
}

# 5. ZIP'i şifrele
try {
    $InZip = [System.IO.File]::OpenRead($ZipPath)
    $OutZip = [System.IO.File]::Create($EncryptedZip)
    $CryptoZip = New-Object System.Security.Cryptography.CryptoStream($OutZip,$Encryptor,"Write")
    $InZip.CopyTo($CryptoZip)
    $CryptoZip.Close(); $InZip.Close(); $OutZip.Close()
    Write-Host "ZIP dosyası şifrelendi ve .remove uzantısı ile kaydedildi."
} catch {
    Write-Host "❌ ZIP şifreleme sırasında hata: $_"
}

# 6. Orijinal ZIP'i sil
try {
    Remove-Item -Path $ZipPath -Force
    Write-Host "✅ Tehdit başarıyla silindi."
} catch {
    Write-Host "❌ Tehdit silinemedi, manuel müdahale gerekli."
}

# 7. Geçici dizini temizle
Remove-Item $TempDir -Recurse -Force
Write-Host "Temizlik işlemi tamamlandı."
