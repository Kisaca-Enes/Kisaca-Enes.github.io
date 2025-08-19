Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "USB" } | Disable-PnpDevice -Confirm:$false
Start-Sleep -Seconds 2
Get-PnpDevice -Class "USB" | Enable-PnpDevice -Confirm:$false
