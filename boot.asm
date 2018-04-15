;--------------------------------------------------------------
; This is not meant to be a serious thing.
; It's not really even a bootloader.
; Just proof of concept things for me to try out in real mode.
; The more I lean the more fun this becomes.
;--------------------------------------------------------------

[bits 16]
[org 0x7c00]

start:
    cli     ;prevent interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    jmp main

main:
    sti
    ;set ds
;    xor ax, ax
;    mov ax, 0x7c0
;    mov ds, ax
;    mov es, ax
;    mov ax, 0x7c0
;    mov ss, ax

    ;save drive id
    mov byte [drive], dl

    call clear_screen

    call set_video_mem

    ;testing color printing
    mov dh, 10              ;set row
    mov dl, 10              ;set column
    mov si, hello           ;set string to print
    call print_rainbow_string

    mov al, 8               ;2 seconds
    call delay

    ;more color printing
    mov dh, 11
    mov dl, 10
    mov si, lil_shit
    call print_rainbow_string

    mov al, 16              ;4 seconds
    call delay

    ;this doesn't work irl. Only works in qemu
    ;probably will need to mess with 0xb8000
;    mov al, 3               ;cyan
;    call set_background_color

    ;testing hex printing
    mov dh, 12
    mov dl, 10
    call move_cursor
    mov ax, 0xbeef
    call print_hex

    ;EVEN MORE TESTING
    mov dh, 12
    mov dl, 18
    call move_cursor
    mov ax, 0xdead
    call print_hex

    ;testing reading, will load seg2
    mov [read_sector], byte 2
    mov [read_loc], word seg2
    call read_drive

    ;if read, this string will be printable
    mov dh, 13
    mov dl, 10
    call move_cursor
    mov si, read_success
    call print_rainbow_string

    ;seg2 is still in memory
    ;change byte value in memory then write back
    mov [write_here], word 'hi'
;    mov [write_here], word 0

    ;write back seg2 to second segment on drive
    mov [write_sector], byte 2
    mov [write_from], word seg2
    call write_drive

    ;see our newly written word in drive
    mov dh, 14
    mov dl, 10
    mov si, write_here
    call print_rainbow_string

    cli                     ;clear interrupts
    hlt                     ;halt cpu

drive:          db 0
hello:          db 'Hello world',0
lil_shit:       db 'LISTEN HERE YOU LITTLE SHIT',0
hex_table:      db '0123456789ABCDEF',0

print_rainbow_string:
    ;initialize values
    mov bh, 0       ;page 0
    mov bl, 0x9     ;set starting color: https://en.wikipedia.org/wiki/BIOS_color_attributes
    mov cx, 1       ;how many characters to write
    mov ah, 0x2     ;use function to change cursor position
    int 0x10        ;change cursor position
.printLoop:
    lodsb           ;loads first char into al, increments pointer using si
    mov ah, 0x9     ;use character write function with attribute
    cmp al, 0       ;check for not null
    je .endPrint
    int 0x10        ;write character
    call move_cursor
    call change_color
    jmp .printLoop
.endPrint:
    ret

; move cursor one position
move_cursor:
    ; page number is already set to 0 (in reg bh)
    mov ah, 0x2
    ;inc dl twice for spacing lulz
    inc dl
    inc dl
    int 0x10
    ret

;change color for each character to make a rainbow
change_color:
    ;see if color is highest possible value
    cmp bl, 0xf
    ;if color is the highest value (0xf) reduce it back to 1 otherwise increment it and end
    jne .incColor
    mov bl, 0x1
    jmp .colorEnd
.incColor:
    inc bl
.colorEnd:
    ret

;initial value comes in at ax
print_hex:
    mov cx, 0       ;count number of hex chars
.hexLoop:
    cmp cx, 4
    je .hexPrint
    mov dx, ax      ;save hex value in dx
    and dx, 0xf     ;and with 15 to get first char
    push dx         ;save hex value on stack
    shr ax, 4       ;shift right 4 bits
    inc cx
    jmp .hexLoop
.hexPrint:
    cmp cx, 0
    je .endHexPrint
    mov bx, hex_table
    pop ax          ;hex char will be in al only
    add bx, ax      ;add with pointer to array to get char
    mov al, [bx]    ;move char to register
    xor bx, bx      ;make 0
    mov ah, 0x0e    ;get ready to print
    int 0x10
    dec cx
    jmp .hexPrint
.endHexPrint:
    ret

read_sector:    db 0
read_loc:       dw 0

read_drive:
    mov ah, 0
    int 0x13        ;reset drive
    mov ah, 0x02
    mov dl, [drive]  ;select the drive
    mov ch, 0       ;cylinder
    mov dh, 0       ;head
    mov cl, [read_sector];sector
    mov al, 1       ;num of sectors to read
    xor bx, bx
    mov es, bx
    mov bx, [read_loc]
    int 0x13
    jc drive_error
    cmp al, 1
    jne drive_error
    ret

drive_error:
    mov ah, 1
    int 0x13
    mov si, error
    call print_rainbow_string
    ret

write_sector:   db 0
write_from:     dw 0

write_drive:
    mov ah, 0
    int 0x13        ;reset drive
    mov ah, 0x03
    mov dl, [drive]
    mov ch, 0
    mov dh, 0
    mov cl, [write_sector]
    mov al, 1
    xor bx, bx
    mov es, bx
    mov bx, [write_from]
    int 0x13
    jc drive_error
    cmp al, 1
    jne drive_error
    ret

;waits a quarter second, though is looped to do greater values
;argument al = repeat count, max value is 0xff
delay:
    mov ah, 0x86
    ;quarter second = 0x3D090
    mov cx, 0x0003  ;upper
    mov dx, 0xD090  ;lower
    xor bx, bx      ;counter
.waitLoop:
    cmp al, bl
    je .waitDone
    int 0x15
    inc bl
    jmp .waitLoop
.waitDone:
    ret

;set by al
set_background_color:
    ;change background color
    mov bl, al  ;set color
    mov ah, 0x0b
    mov bh, 0
    int 0x10
    ret

;sets colors via video memory at 0xb8000 aka 0xb800:0000
;first byte is char, next byte is colors
;second byte: background is top 4 bits, foreground is last 4 bits
;colors in al
set_video_mem:
    push ds
    mov bx, 0xb800
    mov ds, bx
    ;change 4000/2 bytes
    ;for now just change a single byte
    mov [ds:0x1], byte 0xe1  ;bg: blue, fg: yellow
    mov [ds:0x3], byte 0xe1  ;bg: blue, fg: yellow
    mov [ds:0x5], byte 0xe1  ;bg: blue, fg: yellow
    ;fix ds
    pop ds
    ret

;doesn't work or something
;in video mode 3(default) the dimensions are 80x25
clear_screen:
    mov ah, 0x6
    mov al, 0       ;clear all rows
    mov bh, 0x07    ;attributes, black/grey
    xor cx, cx      ;0x0 upper left
    mov dh, 0x18    ;bottom right row
    mov dl, 0x4f    ;bottom right column
    int 0x10
    ret

set_video_mode:
    xor ax, ax
    mov al, 0x3 ;80x25, text mode
    int 0x10
    ret

error: db 'error',0

times 510-($-$$) db 0
dw 0xaa55
seg2:
read_success:       db 'Read successful',0
write_here: dw 0

;makes sure there is enough to read from
;otherwise it will fail on boot
times 2048-($-$$) db 0

