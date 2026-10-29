# Linux Minimal Debug

## Contents
- default root user with home at /root
- script `force_pid` to allow easy reproduction of experiments if it depends on specific PIDs
- DHCP client configurated to automatically fetch an IP address
- telnet and SSH servers automatically started
  - the public keys of the user running the `build.sh` script are automatically added as authorized keys for the root user

## Build the kernel
- Clone the Linux kernel source tree
- Configure it using `make menuconfig` or whatever you prefer
- Disable everything you don't need (see the section below for a list of useful config options)
- Compile the kernel with `make -j $(nproc)`

### Useful kernel config
- `CONFIG_GDB_SCRIPTS=y`
- `CONFIG_DEBUG_INFO=y`
- `CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y`
- `CONFIG_DEBUG_INFO_REDUCED=n`
- `CONFIG_RANDOMIZE_BASE=n`
- `CONFIG_CHECKPOINT_RESTORE=y`
  - This is needed if you want to use the `force_pid` script
- `CONFIG_EXT4_DEBUG=y`
  - Or whatever is best to debug the specific kernel module you want
- `CONFIG_DYNAMIC_DEBUG=y`
  - Can be used to get more detailed logging
- `CONFIG_MESSAGE_LOGLEVEL_DEFAULT=7`
  - Most verbose kernel logging

## Create the initramfs
- Clone this repository and the submodules (busybox and dropbear)
- Configure BusyBox to remove all useless stuff using `make menuconfig`
  - Don't forget to turn on the static build stuff
- Build BusyBox using `make -j $(nproc)`
- Configure dropbear to also make it as minimal as possible (see the doc)
- Build dropbear with `make PROGRAMS=dropbear -j $(nproc)`
- Run the initramfs building routing using `./build.sh`

## Run a VM
### Interactive mode (attach TTY)
```sh
qemu-system-amd64 \
	-kernel "$kernel_path" \
	-initrd "$initramfs_path" \
	-append "console=ttyS0" \
	-s \
	-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2223-:23,hostfwd=tcp::2222-:22 \
	-nographic
```
Explanation:
- `-s` is to enable GDB debugging (on port 1234 by default)
- `-append "console=ttyS0"` is to append an option to the kernel cmdline that tells to make the console on the first serial port
- `-device ... -netdev ...` is to create a network device and forward the ports 2222 and 2223 on the host to the ports 22 and 23 on the guest
- `-nographic` tells QEMU not to create a window and instead create a serial device and attach to it right away

Once you run this command, the VM will start and your terminal will be attached to the console, multiplexed with QEMU monitor. Use Ctrl+A; C to switch to and from QEMU monitor, where you can write e.g. `quit` to exit.

### In the background
```sh
qemu-system-amd64 \
	-kernel "$kernel_path" \
	-initrd "$initramfs_path" \
	-append "console=ttyS0" \
	-serial file:/tmp/qemu.log \
	-s \
	-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2223-:23,hostfwd=tcp::2222-:22 \
	-daemonize -display none
```

In this case, the `qemu` call will return after the VM has started. You can see the logs in `/tmp/qemu.log`.

To stop the VM, either connect to it (see below) or kill the qemu process:
```sh
pkill qemu-system-amd
```

## Connect to the VM
### SSH
```sh
ssh root@localhost -p 2222 -o "StrictHostKeyChecking no"
```
We use `-o "StrictHostKeyChecking no"` since the host key will change everytime you'll reboot the VM.

You can also use SSH to directly send commands and get results, allowing **easy automation**.

### Telnet
```sh
telnet localhost 2223
```

## Debug the VM
You'd better find dedicated tutorials online.

Necessary to begin (the first time it will probably ask you to do something with your gdb config file, do it):
```sh
gdb "$linux_dir/vmlinux"
GNU gdb (Ubuntu 15.1-1ubuntu1~24.04.1) 15.1
Copyright (C) 2024 Free Software Foundation, Inc.
...
Reading symbols from vmlinux...
(gdb) target remote :1234
Remote debugging using :1234
...
(gdb)
```

## Use in a Notebook
If you intend to do the same experiment over and over (e.g. to trace specific things in the kernel), you might benefit from
using a Jupyter Notebook. An example is given in [example_notebook.ipnyb](./example_notebook.ipynb).

## Sources
- https://nickdesaulniers.github.io/blog/2018/10/24/booting-a-custom-linux-kernel-in-qemu-and-debugging-it-with-gdb/
- https://docs.kernel.org/admin-guide/quickly-build-trimmed-linux.html
- https://www.techveda.live/2026/09/24/boot-linux-kernel-qemu-initramfs/ 

## Similar repos
I just found out about https://github.com/bluedragon1221/minlinux2. It is less automated but very detailed about the kernel and initramfs creation (also a bit better), you might want to take a look.