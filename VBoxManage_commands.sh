#!/usr/bin/env bash
# VBoxManage_commands.sh — Parte 2 del laboratorio U5 (VirtualBox)
# Registro de todos los comandos usados, en el orden de los pasos.
# Los comandos estan en una sola linea para funcionar igual en
# Windows (cmd/PowerShell) y en Linux/macOS.
# No esta pensado para ejecutarse de corrido: varios pasos requieren
# acciones manuales dentro de la VM (marcadas como "DENTRO DE LA VM").

VM="Lab5-Alpine"

# ---------------------------------------------------------------
# PASO 1 — Creacion de la VM
# ---------------------------------------------------------------
VBoxManage createvm --name "$VM" --ostype "Linux_64" --register
VBoxManage modifyvm "$VM" --memory 1024 --vram 16 --cpus 1 --nic1 nat
VBoxManage createmedium disk --filename "Lab5-Alpine.vdi" --size 10240 --format VDI
VBoxManage storagectl "$VM" --name "SATA" --add sata
VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "Lab5-Alpine.vdi"
VBoxManage storagectl "$VM" --name "IDE" --add ide
VBoxManage storageattach "$VM" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "alpine-standard-3.19.0-x86_64.iso"

# ---------------------------------------------------------------
# PASO 2 — Instalacion de Alpine Linux
# ---------------------------------------------------------------
VBoxManage startvm "$VM" --type gui
# DENTRO DE LA VM: setup-alpine  (teclado us, hostname lab5-vm, eth0 dhcp,
#                                 America/Bogota, chrony, openssh, disco sda, modo sys)
# DENTRO DE LA VM: poweroff
# Retirar la ISO de la unidad optica:
VBoxManage storageattach "$VM" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive
VBoxManage startvm "$VM" --type gui
# DENTRO DE LA VM: ip addr show eth0 ; ping -c 3 8.8.8.8

# ---------------------------------------------------------------
# PASO 3 — Modos de red (con la VM apagada)
# ---------------------------------------------------------------
VBoxManage controlvm "$VM" poweroff

# Modo 1: NAT (ya configurado). IP tipica 10.0.2.15, gateway 10.0.2.2

# Modo 2: Host-Only
VBoxManage hostonlyif create
VBoxManage modifyvm "$VM" --nic1 hostonly --hostonlyadapter1 "vboxnet0"
# Si la VM no obtiene IP por DHCP (rango 192.168.56.x), asignar una manualmente
# DENTRO DE LA VM: ip addr add 192.168.56.101/24 dev eth0 ; ip link set eth0 up
# Desde el anfitrion: ping <IP de la VM>     Desde la VM: ping 8.8.8.8 (debe fallar)
VBoxManage controlvm "$VM" poweroff

# Modo 3: Bridge (reemplazar "Ethernet" por el nombre real del adaptador del anfitrion)
VBoxManage modifyvm "$VM" --nic1 bridged --bridgeadapter1 "Ethernet"
# DENTRO DE LA VM: ip addr show eth0
VBoxManage controlvm "$VM" poweroff

# Volver a NAT para poder instalar paquetes con apk en el Paso 4
VBoxManage modifyvm "$VM" --nic1 nat

# ---------------------------------------------------------------
# PASO 4 — Snapshots (VM encendida)
# ---------------------------------------------------------------
VBoxManage startvm "$VM" --type gui
VBoxManage snapshot "$VM" take "snap_base" --description "Alpine Linux 3.19 recien instalado, sin modificaciones"
# DENTRO DE LA VM: apk update ; apk add curl wget nano htop
VBoxManage snapshot "$VM" take "snap_con_herramientas" --description "Alpine con curl, wget, nano y htop instalados"
VBoxManage snapshot "$VM" list
VBoxManage controlvm "$VM" poweroff
VBoxManage snapshot "$VM" restore "snap_base"
VBoxManage startvm "$VM" --type gui
# DENTRO DE LA VM: apk info curl   (no debe devolver nada)

# ---------------------------------------------------------------
# PASO 5 — Reasignacion de recursos (VM apagada)
# ---------------------------------------------------------------
VBoxManage controlvm "$VM" poweroff
VBoxManage showvminfo "$VM" | grep -i "memory\|cpus"        # Windows: ... | findstr /i "memory cpus"
VBoxManage modifyvm "$VM" --cpus 2 --memory 2048
VBoxManage startvm "$VM" --type gui
# DENTRO DE LA VM: nproc ; free -m

# ---------------------------------------------------------------
# PASO 6 — Disco fijo frente a disco dinamico
# ---------------------------------------------------------------
VBoxManage controlvm "$VM" poweroff
VBoxManage createmedium disk --filename "Lab5-Alpine-fixed.vdi" --size 4096 --format VDI --variant Fixed
VBoxManage storageattach "$VM" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "Lab5-Alpine-fixed.vdi"
VBoxManage startvm "$VM" --type gui
# DENTRO DE LA VM:
#   apk add e2fsprogs
#   fdisk /dev/sdb            (n, p, 1, Enter, Enter, w)
#   mkfs.ext4 /dev/sdb1
#   mkdir /mnt/fijo ; mount /dev/sdb1 /mnt/fijo
#   time dd if=/dev/zero of=/mnt/fijo/test.img bs=1M count=200 ; sync
#   time dd if=/dev/zero of=/root/test.img bs=1M count=200 ; sync
#   rm /mnt/fijo/test.img /root/test.img

# ---------------------------------------------------------------
# PASO 9 — Exportacion en formato OVA (VM apagada)
# ---------------------------------------------------------------
VBoxManage controlvm "$VM" poweroff
VBoxManage export "$VM" --output "Lab5-Alpine-export.ova" --manifest --options manifest
ls -lh Lab5-Alpine-export.ova        # Windows: dir Lab5-Alpine-export.ova
# Para importarla en otra instalacion:
# VBoxManage import Lab5-Alpine-export.ova
