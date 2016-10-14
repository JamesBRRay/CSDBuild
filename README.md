# CSDBuild
Scripts to create NetworkManager profile for connecting to OpenConnect VPNs

You'll need to get the AnyConnect PreDeploy tarball from your organisation. For UCL students/staff that is available here: 
https://www.ucl.ac.uk/isd/how-to/remote-working/connecting-vpn-linux

## How to ...
Get the CSDBuild.sh script and run - it downloads the tarball from a URL provided

## Tested on...
### Distro Version
* Ubuntu 16.10
* Ubuntu 16.04

### AnyConnect Version
* 4.3.02039-k9

## Pre-requisuites
* network-manager-openconnect
* network-manager-openconnect-gnome
* openconnect
* curl

## Example run
```
$ ./CSDBuild.sh
Where would you like the CSD Wrapper and associated code to end up
[default: /home/jamesr/CSDWrapper]: 
Name of the VPN Connection to create in NetworkManager
[default: UCLVPN]: 
URL to predeploy tarball
[default: https://www.ucl.ac.uk/isd/how-to/remote-working/resources/linux/anyconnect-predeploy-linux-64-4.3.02039-k9.tar] 
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 9746k  100 9746k    0     0  1193k      0  0:00:08  0:00:08 --:--:-- 1541k
Connection 'UCLVPN' (69be6557-66a2-481a-b817-ef60f0c0d9fe) successfully added.
A password is required to connect to 'UCLVPN'.
Warning: password for 'vpn.secrets.gateway' not given in 'passwd-file' and nmcli cannot ask without '--ask' option.
VPN connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/222)
```
