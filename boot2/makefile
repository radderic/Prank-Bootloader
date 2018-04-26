
filename = print
flags = -f bin -o
debug = -s -S
gdbflags = -q -x

.PHONY: read

all : $(filename).asm
	nasm $(filename).asm $(flags) $(filename).bin

debug : $(filename).bin
	konsole -e gdb $(gdbflags) gdbcommands.txt
	qemu-system-i386 $(debug) $(filename).bin

flash : $(filename).bin
	sudo dd if=./$(filename).bin of=/dev/sdb

read :
	sudo dd if=/dev/sdb of=./output.txt bs=1024 count=5
