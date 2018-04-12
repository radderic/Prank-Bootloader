
[org 0x7c00]
[bits 16]

start:
    mov [disk], dl
    jmp main

main:
    ;int 0x10 functions in use:
    ;Write character and attribute at cursor position   AH=09h  AL = Character, BH = Page Number, BL = Color, CX = Number of times to print character
    ;Set cursor position    AH=02h  BH = Page Number, DH = Row, DL = Column

    mov dh, 10              ;set row
    mov dl, 10              ;set column
    mov si, hello           ;set string to print
    call print_color_string

    mov dh, 11              ;set row
    mov dl, 10              ;set column
    mov si, lil_shit        ;set string to print
    call print_color_string

    mov dh, 15
    mov dl, 10
    call move_cursor
    mov si, test
    call print_color_string

;    mov dh, 12
;    mov dl, 10
;    call move_cursor
;    mov ax, hello
;    call print_hex

;    mov dh, 12
;    mov dl, 10
;    call move_cursor
;    mov ax, test
;    call print_hex

;    mov dh, 13
;    mov dl, 10
;    call move_cursor
;    mov ax, disk
;    call print_hex

;    mov dh, 14
;    mov dl, 10
;    call move_cursor
;    mov si, test
;    call print_color_string

;    jmp stage2

    call read_disk

    mov dh, 15
    mov dl, 10
    call move_cursor
    mov si, test
    call print_color_string


    cli                     ;clear interrupts
    hlt                     ;halt cpu

disk:           db 0
hello:          db 'Hello world',0
lil_shit:       db 'LISTEN HERE YOU LITTLE SHIT',0
hex_table:      db '0123456789ABCDEF',0

print_color_string:
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

read_disk:
    mov ah, 0
    int 0x13        ;reset disk
    mov ah, 0x02
    mov dl, [disk]  ;select the disk
    mov ch, 0       ;cylinder
    mov dh, 0       ;head
    mov cl, 2       ;sector
    mov al, 1       ;num of sectors to read
    mov bx, test
    int 0x13
    jc disk_error
    cmp al, 1
    jne disk_error
;    jmp stage2
    ret

disk_error:
    mov ah, 1
    int 0x13
    mov si, error
    call print_color_string
    call print_hex
    ret

;test: db 'test',0
error: db 'error',0

times 510-($-$$) db 0
dw 0xaa55
test:   db  'test',0
test2:  db  4

times 2048-($-$$) db 0
