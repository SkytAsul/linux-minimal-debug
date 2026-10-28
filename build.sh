#!/bin/bash

set -euo pipefail
shopt -s nullglob

archive_path="initramfs.cpio.gz"

base_dir="./rootfs-base"
busybox_path="./busybox"
dropbear_path="./dropbear"


# We build in a temp dir in XDG_RUNTIME_DIR since it's (usually) in a tmpfs
# filesystem, thus we avoid putting pressure on the disk by creating lot of
# small files that will be deleted right afterwards.
build_dir="$(mktemp -d --tmpdir="$XDG_RUNTIME_DIR" initramfs.XXXXX)"
trap 'rm -rf -- "$build_dir"' EXIT


##### BASE FILES
echo "Copying base files..."
cp -a "$base_dir"/* "$build_dir"


##### SSH KEYS
for ssh_key in ~/.ssh/*.pub; do
	echo "Copying $ssh_key as an authorized key for the root user."
	cat "$ssh_key" >> "$build_dir"/root/.ssh/authorized_keys
done


##### SPECIAL FILES
echo "Creating special files..."
mkdir "$build_dir"/{dev,proc,sys}
sudo mknod -m 666 "$build_dir"/dev/tty c 5 0
sudo mknod -m 666 "$build_dir"/dev/null c 1 3
sudo mknod -m 644 "$build_dir"/dev/console c 5 1
sudo mknod -m 644 "$build_dir"/dev/loop0 b 7 0


##### BUSYBOX
echo "Installing busybox..."
pushd "$busybox_path"

make CONFIG_PREFIX="$build_dir" install

echo Copying udhcpc default configuration...
mkdir -p "$build_dir"/usr/share/udhcpc

cp "examples/udhcp/simple.script" "$build_dir"/usr/share/udhcpc/default.script
popd


##### DROPBEAR
echo "Installing dropbear SSH server..."
pushd "$dropbear_path"

make install DESTDIR="$build_dir"

popd


##### ARCHIVE CREATION
echo "Creating the initramfs CPIO archive..." 
archive_path="$(realpath $archive_path)"
pushd $build_dir
find . -print0 | cpio --null --create --format=newc | gzip > "$archive_path"
