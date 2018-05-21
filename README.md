# Prank Bootlader
Runs after bios and pretends to be errors but doesn't actually do anything bad.

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
make flashsdx
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

# Example of bootloader
![send nudes](./boot.gif)

# Requirements:
* Only works on x86 computers

* I had to enable legacy mode in the bios for my usb to be used. Might have to disable secure boot too.

* I recommend trying in qemu or virtualbox first before trying usb




