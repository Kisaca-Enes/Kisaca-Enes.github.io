# LNK dosyasının yolunu belirt
$lnkPath = "C:\path\to\malware.lnk"

# WScript.Shell COM objesi oluştur
$WshShell = New-Object -ComObject WScript.Shell

# LNK dosyasını aç
$Shortcut = $WshShell.CreateShortcut($lnkPath)

# Hedef exe yolunu yazdır
$Shortcut.TargetPath
