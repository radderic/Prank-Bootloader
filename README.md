# Bootloader-Hello-World
Runs after bios as if a bootloader. The 3rd bootloader is being designed as a prank bootloader.

Use make to compile.
```bash
make all
```
use qemu to test
```
make qemu
```
Use make flashsdx, where x is the specific drive
Check lsblk or dmesg to ensure you're writing to the correct drive!
```bash
make flashsdc
```


Or you can do it yourself
use nasm to compile:
```bash
nasm filename.asm -f bin -o filename.bin
```
use dd to put on usb(whether it is /dev/sdb or what):
```bash
sudo dd if=./filename.bin of=/dev/sdx
```

# Example of boot3
![send nudes](./boot.gif)

* I recommend trying in qemu or virtualbox first before trying usb

* I had to enable legacy mode in the bios for my usb to be used. Might have to disable secure boot too.

* Only works on x86 computers


