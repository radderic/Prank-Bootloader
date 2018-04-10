# Bootloader-Hello-World
Runs after bios as if a bootloader and prints colorful text to screen.

use nasm to compile:
```bash
nasm filename.asm -f bin -o filename.bin
```
use dd to put on usb(whether it is /dev/sdb or what):
```bash
sudo dd if=./filename.bin of=/dev/sdx
```

*I recommend trying in qemu or virtualbox first before trying usb

*I had to enable legacy mode in the bios for my usb to be used. Might have to disable secure boot too.

*Only works on x86 computers


