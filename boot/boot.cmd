setenv bootargs earlyprintk /boot/vmlinuz-4.16.0-rc7-sunxi64 modules=loop,squashfs,sd-mod,usb-storage modloop=/boot/modloop-sunxi64 console=${console}
fdt addr 0x50000000
fdt get value bootargs /chosen bootargs
setenv kernel_addr_r 0x41000000
setenv ramdisk_addr_r 0x48000000
load mmc 0:1 ${kernel_addr_r} boot/vmlinuz-4.16.0-rc7-sunxi64
load mmc 0:1 ${ramdisk_addr_r} boot/initramfs-sunxi64
setenv initrdsize $filesize
load mmc 0:1 ${fdt_addr_r} boot/dtb/sun50i-h5-orangepi-primie.dtb
booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrdsize} ${fdt_addr_r}
