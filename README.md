# Compile Kernel and AlpineLinux for OrangePi

# Install packages

u-boot-tools, gcc-aarch64-linux-gnu, g++-aarch64-linux-gnu device-tree-compiler libncurses-dev
apt install git
apt install make
apt install gcc
libncurses-dev

apt install u-boot-tools
gcc-arm-linux-gnueabi

# Compile u-boot

git clone  https://github.com/apritzel/arm-trusted-firmware.git
git clone git://git.denx.de/u-boot.git
cd arm-trusted-firmware
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4 PLAT=sun50iw1p1 DEBUG=1 bl31
cp build/sun50iw1p1/debug/bl31.bin ../u-boot/
cd ../u-boot
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4 orangepi_pc2_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j4
cat spl/sunxi-spl.bin u-boot.itb > u-boot-sunxi-with-spl.bin
dd if=u-boot-sunxi-with-spl.bin of=/dev/sdX bs=8k seek=1

# Compile kernel and dtb

Get a copy of the linux kernel source
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

Verify and add the following to arch/arm64/boot/dts/allwinner/Makefile if it doesnt exist:
    dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-orangepi-pc2.dtb
If the allwinner folder doesn't exist, get the patches necessary to create it (and its friends) from mainline kernel, linux-sunxi:
	git clone https://github.com/linux-sunxi/linux-sunxi/tree/mirror/master/arch/arm
Verify the dts, dtsi and defconfig files to the locations specified below:
dts & dtsi --> arch/arm64/boot/dts/allwinner/
defconfig --> arch/arm64/config/
Run the following (from the root of the kernel tree):
    export TOOLS=aarch64-linux-gnu-
    mkdir -p output
    make ARCH=arm64 CROSS_COMPILE=$TOOLS orangepi_pc2_defconfig
    make ARCH=arm64 CROSS_COMPILE=$TOOLS menuconfig (This is optionaljust to verify if the following options are set: Device Drivers -> Common Clock Framework -> Clock support for Allwinner SoCs -> Support for the Allwinner H3 CCU; Device Drivers -> Reset Controller Support)
Now continue with the following commands (the first will take a while as its the kernel compilation):
    make ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 Image dtbs
    make ARCH=arm64 CROSS_COMPILE=$TOOLS INSTALL_MOD_PATH=output modules modules_install
    mkimage -A arm -n "OrangePiH5" -O linux -T kernel -C none -a 0x40080000 -e 0x40080000 -d arch/arm64/boot/Image output/uImage
    cp arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-pc2.dtb output/
	
# Compile firmware

# Compile Alpine initramfs and modloop


mkdir temp
cd temp
gunzip -c /boot/root/initrams-grsec | cpio -i
