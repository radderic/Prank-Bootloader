
[org 0x7c00]

start:
    jmp main

main:
    ;int 0x10 functions in use:
    ;Write character and attribute at cursor position   AH=09h  AL = Character, BH = Page Number, BL = Color, CX = Number of times to print character
    ;Set cursor position    AH=02h  BH = Page Number, DH = Row, DL = Column

    mov dh, 10              ;set row
    mov dl, 10              ;set column
    mov si, hello           ;set string to print
    call write_string
    mov dh, 11              ;set row
    mov dl, 10              ;set column
    mov si, long_string     ;set string to print
    call write_string

    cli                     ;clear interrupts
    hlt                     ;halt cpu

hello: db 'Hello world',0
long_string: db 'LISTEN HERE YOU LITTLE SHIT',0

write_string:
    ;initialize values
    mov bh, 0       ;page 0
    mov bl, 0x9     ;set starting color: https://en.wikipedia.org/wiki/BIOS_color_attributes
    mov cx, 1       ;how many characters to write
    mov ah, 0x2     ;use function to change cursor position
    int 0x10        ;change cursor position
.printloop:
    lodsb           ;loads first char into al, increments pointer using si
    mov ah, 0x9     ;use character write function with attribute
    cmp al, 0       ;check for not null
    je .end
    int 0x10        ;write character
    call move_cursor
    call change_color
    jmp .printloop
.end:
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

times 510-($-$$) db 0
dw 0xaa55


