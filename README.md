# randomscripts
### server.sh
openvpn server configuration scripts for debian
Usage (as root):
```bash
./server.sh 
```
and follow interactive commands 

### client.sh
Pass client names as arguments, generate .ovpn files for each user 
Usage (as root):
```bash
client.sh jkowalski tsmith admin1
```

### wifi password recovery
```powershell
netsh wlan show profile | findstr All | % { $_.substring(27); Write-Host ($_.substring(27)) } 2> $null | % { netsh wlan show profile $_ key=clear} | findstr Key | % { $_.substring(29) }
```
