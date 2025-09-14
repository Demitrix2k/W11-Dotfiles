# Run as administrator
Start-Sleep -Seconds 5
$device = Get-PnpDevice | Where-Object { $_.FriendlyName -like "NVIDIA GeForce RTX 3070 Laptop GPU" }
Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
Start-Sleep -Seconds 1
Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
