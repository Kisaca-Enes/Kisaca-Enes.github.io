Write-Host "=== SYSTEM DIAGNOSTIC REPORT ===" -ForegroundColor Cyan

# -------------------------
# OS INFO
# -------------------------
Write-Host "`n--- Windows Information ---" -ForegroundColor Yellow
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

# -------------------------
# CPU INFO
# -------------------------
Write-Host "`n--- CPU ---" -ForegroundColor Yellow
Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors

# -------------------------
# RAM INFO
# -------------------------
Write-Host "`n--- RAM ---" -ForegroundColor Yellow
Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory

# -------------------------
# DISK INFO
# -------------------------
Write-Host "`n--- DISK ---" -ForegroundColor Yellow
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
Select-Object DeviceID, Size, FreeSpace

# -------------------------
# GPU INFO
# -------------------------
Write-Host "`n--- GPU ---" -ForegroundColor Yellow
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion

# -------------------------
# BIOS INFO
# -------------------------
Write-Host "`n--- BIOS ---" -ForegroundColor Yellow
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate

# -------------------------
# SECURITY STATUS
# -------------------------
Write-Host "`n--- SECURITY ---" -ForegroundColor Yellow
Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled, RealTimeProtectionEnabled

# -------------------------
# INSTALLED ANTIVIRUS
# -------------------------
Write-Host "`n--- INSTALLED SECURITY PRODUCTS ---" -ForegroundColor Yellow
Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct |
Select-Object displayName, productState

# -------------------------
# NETWORK
# -------------------------
Write-Host "`n--- NETWORK ADAPTERS ---" -ForegroundColor Yellow
Get-NetAdapter | Select-Object Name, Status, LinkSpeed

# -------------------------
# SYSTEM LOAD QUICK CHECK
# -------------------------
Write-Host "`n--- CURRENT LOAD ---" -ForegroundColor Yellow
Get-CimInstance Win32_Processor | Select-Object LoadPercentage

Write-Host "`n=== REPORT COMPLETE ===" -ForegroundColor Green
