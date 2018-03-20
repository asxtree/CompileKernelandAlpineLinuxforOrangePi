# Compile Kernel and AlpineLinux for OrangePi

NOTICE: This was tested only on Ubuntu 16!!!!

# Install packages

In order to compile all the things some additional packages will need to be installed.

This list neds to be revised because there are many packages that need to be installed.

To install them just issue this command:
```
apt install git make gcc gcc-arm-linux-gnueabi u-boot-tools gcc-aarch64-linux-gnu g++-aarch64-linux-gnu device-tree-compiler 
```
# Compile u-boot

To compile the u-boot file just issue the following commands (if any error is received is because of the lack of compiling packages installed on the machine):
```
git clone  https://github.com/apritzel/arm-trusted-firmware.git
git clone git://git.denx.de/u-boot.git
cd arm-trusted-firmware
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4 PLAT=sun50iw1p1 DEBUG=1 bl31
cp build/sun50iw1p1/debug/bl31.bin ../u-boot/
cd ../u-boot
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4 orangepi_pc2_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4
cat spl/sunxi-spl.bin u-boot.itb > u-boot-sunxi-with-spl.bin
```

After you followed all the steps you should have the "u-boot-sunxi-with-spl.bin" file in the u-boot directory tree, just type ll to list the contents of u-boot and locate the file.
Now make a folder where to store all the output files and start to copy the newly created u-boot
```
mkdir lxsources/OrangePiPrime_v1
cp -rp u-boot/u-boot-sunxi-with-spl.bin lxsources/OrangePiPrime_v1/
```

# Compile kernel and dtb

Get a copy of the linux kernel source
```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```

Verify and add the following to arch/arm64/boot/dts/allwinner/Makefile if it doesnt exist:
```
dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-orangepi-prime.dtb
```

If the allwinner folder doesn't exist, get the patches necessary to create it (and its friends) from mainline kernel, linux-sunxi:
```
git clone https://github.com/linux-sunxi/linux-sunxi/tree/mirror/master/arch/arm
```

Verify the dts, dtsi files to the locations specified below:
```
dts & dtsi --> arch/arm64/boot/dts/allwinner/
```

Add the attached defconfig orangepi_prime_defconfig files to the locations specified below:
```
defconfig --> arch/arm64/config/
```

Run the following (from the root of the kernel tree):
 ```
export TOOLS=aarch64-linux-gnu-
mkdir -p output
make ARCH=arm64 CROSS_COMPILE=$TOOLS orangepi_prime_defconfig
make ARCH=arm64 CROSS_COMPILE=$TOOLS menuconfig (This is optional just to verify if the following options are set: Device Drivers -> Common Clock Framework -> Clock support for Allwinner SoCs -> Support for the Allwinner H3 CCU; Device Drivers -> Reset Controller Support)
```
NOTE: In the menuconfig you can configure lots of things for your board but you need to research first what you can configure. 

For further reading on the kernel: https://www.kernel.org/doc/html/v4.15/index.html

Now continue with the following commands (the first will take a while as its the kernel compilation):
```
make ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 Image dtbs
make ARCH=arm64 CROSS_COMPILE=$TOOLS INSTALL_MOD_PATH=output modules modules_install
mkimage -A arm -n "OrangePiH5" -O linux -T kernel -C none -a 0x40080000 -e 0x40080000 -d arch/arm64/boot/Image output/vmlinuz-4.16.0-rc6-sunxi64
cp arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-prime.dtb output/
```

Now copy the contents of the output folder to your building folder and go back to root:
```
cp -rp output/* /root/lxsources/OrangePiPrime_v1/
cd
```

# Compile firmware

```
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/ lxsources/OrangePiPrime_v1/lib/modules/firmware
```

# Compile Alpine initramfs and modloop

Download the latest Alpine uboot archive

Un-archive the initramfs-vanilla
```
mkdir temp
cd temp
gunzip -c /root/alpine/initramfs-vanilla | cpio -i
```

Copy the modules folder and archive it:
```
cp -rp /root/lxsources/OrangePiPrime_v1/lib/* lib/
find . | cpio -H newc -o | gzip -9 > /root/initramfs-sunxi-new
```

Change back to /root and make the initramfs image:
```
cd
mkimage -n initramfs-sunxi -A arm -O linux -T ramdisk -C none -d initramfs-sunxi-new initramfs-sunxi
cp -rp initramfs-sunxi lxsources/OrangePiPrime_v1/
```









