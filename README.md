# Linux Minimal Debug

## Contents
- default root user with home at /root
- script force_pid to allow easy reproduction of experiments if it depends on specific PIDs
- DHCP client configurated to automatically fetch an IP address
- telnet and SSH servers automatically started

## Create the initramfs
- Clone this repository and the submodules (busybox and dropbear)
- Configure BusyBox to remove all useless stuff using `make menuconfig`
  - Don't forget to turn on the static build stuff
- Build BusyBox using `make -j $(nproc)`
- Configure dropbear to also make it as minimal as possible (see the doc)
- Build dropbear with `make PROGRAMS=dropbear -j $(nproc)`
- Run the initramfs building routing using `./build.sh`
