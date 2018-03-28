# Compile Kernel and AlpineLinux for OrangePi

NOTICE: This was tested only on Ubuntu 16!!!!
Prerequisites: Ubuntu 16 machine!!!!!

# Install packages

In order to compile all the things some additional packages will need to be installed.

First modify the source list from `/etc/apt/sources.list` and add the following lines (press `i` to edit then after youve copied the lines in the file press `ESC` key then write `:wq` and press `ENTER` key to save and exit the file):
```
vi /etc/apt/sources.list
```

```
deb http://cz.archive.ubuntu.com/ubuntu artful main
deb http://security.ubuntu.com/ubuntu artful-security main
deb http://security.ubuntu.com/ubuntu artful main
```

This list needs to be revised because there are many packages that need to be installed.

To install them just issue this command:
```
apt install git make gcc u-boot-tools gcc-aarch64-linux-gnu g++-aarch64-linux-gnu device-tree-compiler \
 binutils swig python python-dev python3-dev bison flex bc bridge-utils build-essential cpufrequtils \
 device-tree-compiler figlet fbset fping iw fake-hwclock wpasupplicant psmisc ntp parted rsync sudo curl linux-base \
 dialog crda wireless-regdb ncurses-term python3-apt sysfsutils toilet u-boot-tools unattended-upgrades \
 usbutils wireless-tools console-setup unicode-data openssh-server initramfs-tools \
 ca-certificates resolvconf expect rcconf iptables automake bison flex libwrap0-dev \
 libssl-dev libnl-3-dev libnl-genl-3-dev alsa-utils btrfs-tools dosfstools hddtemp iotop \
 iozone3 stress sysbench screen ntfs-3g vim pciutils evtest htop pv lsof apt-transport-https \
 libfuse2 libdigest-sha-perl libproc-processtable-perl aptitude dnsutils f3 haveged \
 hdparm rfkill vlan sysstat bash-completion hostapd git ethtool network-manager unzip ifenslave command-not-found \
 libpam-systemd iperf3 software-properties-common libnss-myhostname f2fs-tools avahi-autoipd iputils-arping
```
# Compile u-boot

To compile the `u-boot` file just issue the following commands (if any error is received is because of the lack of compiling packages installed on the machine):
```
git clone  https://github.com/apritzel/arm-trusted-firmware.git
git clone git://git.denx.de/u-boot.git #or use git clone http://git.denx.de/u-boot.git
cd arm-trusted-firmware
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4 PLAT=sun50iw1p1 DEBUG=1 bl31
cp build/sun50iw1p1/debug/bl31.bin ../u-boot/
cd ../u-boot
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4 orangepi_prime_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4
cat spl/sunxi-spl.bin u-boot.itb > u-boot-sunxi-with-spl.bin
```

After you followed all the steps you should have the `u-boot-sunxi-with-spl.bin` file in the `u-boot` directory tree, just type `ll` to list the contents of `u-boot` and locate the file.

Now make a folder where to store all the output files and start to copy the newly created `u-boot`
```
cd
mkdir lxsources/
mkdir lxsources/boot
cp -rp u-boot/u-boot-sunxi-with-spl.bin lxsources/
```

# Compile kernel and dtb

Get a copy of the linux kernel source
```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```

Verify and add the following to `arch/arm64/boot/dts/allwinner/Makefile` if it doesnt exist:
```
dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-orangepi-prime.dtb
```

If the allwinner folder doesn't exist, get the patches necessary to create it (and its friends) from mainline kernel, linux-sunxi:
```
git clone https://github.com/linux-sunxi/linux-sunxi/tree/mirror/master/arch/arm
```

Verify the `dts`, `dtsi` files to the locations specified below:
```
dts & dtsi --> arch/arm64/boot/dts/allwinner/
```

Add the attached defconfig `orangepi_prime_defconfig` files to the locations specified below:
```
defconfig --> arch/arm64/config/
```

Run the following (from the root of the kernel tree):
 ```
export TOOLS=aarch64-linux-gnu-
mkdir -p output
make ARCH=arm64 CROSS_COMPILE=$TOOLS orangepi_prime_defconfig
make ARCH=arm64 CROSS_COMPILE=$TOOLS menuconfig 
```

The last command is optional just to verify if the following options are set: Device Drivers -> Common Clock Framework -> Clock support for Allwinner SoCs -> Support for the Allwinner H3 CCU; Device Drivers -> Reset Controller Support

NOTE: In the menuconfig you can configure lots of things for your board but you need to research first what you can configure. 

For further reading on the kernel: https://www.kernel.org/doc/html/v4.15/index.html

Now continue with the following commands (the first will take a while as its the kernel compilation):
```
make ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 Image dtbs
make ARCH=arm64 CROSS_COMPILE=$TOOLS INSTALL_MOD_PATH=output modules modules_install
cp -r arch/arm64/boot/Image output/vmlinuz-4.16.0-rc7-sunxi64 #the version may differ 
cp -r arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-prime.dtb output/
cp -r System.map output/System.map-4.16.0-rc7-sunxi64
cp -r arch/arm64/config/orangepi_prime_defconfig output/config-4.16.0-rc7-sunxi64
```

Now copy the contents of the output folder to your building folder and go back to `root`:
```
cp -rp output/* /root/lxsources/boot/
cd
```

# Compile Alpine initramfs and modloop

Download the latest Alpine uboot archive and untar it:
```
wget http://dl-2.alpinelinux.org/alpine/v3.7/releases/aarch64/alpine-uboot-3.7.0_rc3-aarch64.tar.gz #the version may differ
mkdir alpineuboot
tar -xvzf alpine-uboot-3.7.0_rc3-aarch64.tar.gz -C alpineuboot 
```

Un-archive the `initramfs-vanilla`
```
mkdir initramfs-temp
cd initramfs-temp
gunzip -c /root/alpineuboot/boot/initramfs-vanilla | cpio -i
```

Copy the `modules` folder and archive the new `initramfs`:
```
rm -rf lib/modules/* #there should be already a kernel modules folder there so delete it first then copy the new kernel modules
cp -rp /root/lxsources/boot/lib/modules/* lib/modules
find . | cpio -H newc -o | gzip -9 > /root/initramfs-sunxi-new
```

Change back to `/root` and make the initramfs image:
```
cd
mkimage -n initramfs-sunxi64 -A arm64 -O linux -T ramdisk -C none -d initramfs-sunxi-new initramfs-sunxi64
cp -rp initramfs-sunxi64 lxsources/boot/
```

Now to compile the `modloop` file we need to create another temporary folder and copy here the `modules` folder, which we will delete along with the temp folder created for initramfs afterwords:
```
mkdir squashfs-temp
cp -rp lxsources/boot/lib/* squashfs-temp
mksquashfs squashfs-temp/ modloop-sunxi64 -b 1048576
cp -rp modloop-sunxi64 lxsources/boot/
```

Create the boot.cmd file:
```
vi lxsources/boot/boot.cmd
```

And add the following lines (press `i` to edit then after youve copied the lines in the file press `ESC` key then write `:wq` and press `ENTER` key to save and exit the file):

```
setenv bootargs earlyprintk /boot/vmlinuz-4.16.0-rc7-sunxi64 modules=loop,squashfs,sd-mod,usb-storage modloop=/boot/modloop-sunxi64 console=${console}
setenv kernel_addr_r 0x41000000
setenv ramdisk_addr_r 0x48000000
setenv fdt_addr_r 0x50000000
load mmc 0:1 ${kernel_addr_r} boot/vmlinuz-4.16.0-rc7-sunxi64
load mmc 0:1 ${ramdisk_addr_r} boot/initramfs-sunxi64
setenv initrdsize $filesize
load mmc 0:1 ${fdt_addr_r} boot/dtb/sun50i-h5-orangepi-prime.dtb
booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrdsize} ${fdt_addr_r}
```

Move the `sun50i-h5-orangepi-primedtb` file, remove the `lib` directory from `lxsources` and make the `boot.scr` file:
```
mkdir lxsources/boot/dtb
mv lxsources/boot/sun50i-h5-orangepi-prime.dtb lxsources/boot/dtb/
rm -rf lxsources/boot/lib/
cp -rp alpineuboot/apks lxsources/
cd lxsources/boot/
```
Insert the SD card into the linux machine and find it:
```
fdisk -l
```

And you should see it like this:

```
Disk /dev/mmcblk0: 14.9 GiB, 15931539456 bytes, 31116288 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xa37b3cc1
```

Go back to lxsources, format the SD card and write the `u-boot` on it:
```
cd ..
dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=1
dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8
```

Create a partition and copy the sources on the SD card:
```
fdisk /dev/mmcblk0
```

```
root@ubuntu:~# fdisk /dev/mmcblk0

Welcome to fdisk (util-linux 2.30.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x4a91164d.

Command (m for help): n #### Type "n" for new partition
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): #### Press ENTER to use default

Using default response p.
Partition number (1-4, default 1): #### Press ENTER to use default
First sector (2048-31116287, default 2048): #### Press ENTER to use default
Last sector, +sectors or +size{K,M,G,T,P} (2048-31116287, default 31116287): #### Press ENTER to use default

Created a new partition 1 of type 'Linux' and of size 14.9 GiB.
Partition #1 contains a vfat signature.

Do you want to remove the signature? [Y]es/[N]o: y #### Type "y" if this question appear

The signature will be removed by a write command.

Command (m for help): t #### Type "t" to change the partition type
Selected partition 1
Hex code (type L to list all codes): 83 #### Type "83" to change the partition type to LINUX
Changed type of partition 'Linux' to 'Linux'.

Command (m for help): w #### Type "w" to write changes to the partition
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

Format the new partition and copy the sources:
```
cd
mkfs.ext4 /dev/mmcblk0p1
mount /dev/mmcblk0p1 /mnt/
cp -r lxsources/* /mnt/
```

Create the boot.scr file and unmount the partition:
```
cd /mnt/boot
mkimage -C none -A arm64 -T script -d boot.cmd boot.scr
cd
umount /mnt
```

Remove the SD card from the Linux machine insert it in the Orange Pi Prime board and power on the board.

Alpine linux 3.7 should start now but be aware that in this state you are booting from ram to make a persistent install follow the steps from OrangePiAlpineLinux github page.


