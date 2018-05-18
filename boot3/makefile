
filename = boot
flags = -f bin -o
debug = -s -S
gdbflags = -q -x

.PHONY: read

all : $(filename).asm
	nasm $(filename).asm $(flags) $(filename).bin

debug : $(filename).bin
#	konsole -e gdb $(gdbflags) gdbcommands.txt
	qemu-system-i386 $(debug) $(filename).bin

flashsdb : $(filename).bin
	sudo dd if=./$(filename).bin of=/dev/sdb

flashsdc : $(filename).bin
	sudo dd if=./$(filename).bin of=/dev/sdc

read :
	sudo dd if=/dev/sdb of=./output.txt bs=1024 count=5

$(filename).bin : $(filename).asm
	nasm $(filename).asm $(flags) $(filename).bin

qemu : $(filename).bin
	qemu-system-i386 $(filename).bin
