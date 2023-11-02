# pxinst.sh
Proxmox install Script on top of a plain Debain


All neccessary steps to install proxmox on top of debian bookworm.

```
Usage: pxinst.sh [params]  Version=170 (c)2017-2023 Jan Novak, repcom@gmail.com

  params are one of that:   
  basics                   install debian basics
  packs                    show packs to install only (nothing will be done)
  installproxmox           install Proxmox System
  sanoid                   install sanoid zfs snapshot tool
  pml/pmn/pma/pmr          set proxmox [l]ocal / [n]ormal / restart [a]ll /[r]emove cluster (be careful with pmr)
  pmrestart                restart proxmox cluster daemons
  ip                       What is my public ip
```

