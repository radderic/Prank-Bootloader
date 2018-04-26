;--------------------------------------------------------------
; Testing reading and writing text
;--------------------------------------------------------------

[bits 16]
[org 0x7c00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00  ;sets stack below
    jmp main

main:
    call clear_screen

    mov [row], byte 8
    mov [column], byte 25
    call move_cursor
    mov [input_bound], byte 25
    call user_input

    mov [delay_time], byte 1
    mov [row], byte 9
    mov [column], byte 25
    call move_cursor
    mov al, [light_blue]
    mov byte [color], al
    mov si, input
    call color_print

    cli                     ;clear interrupts
    hlt                     ;halt cpu

;colors
black:          db 0x0
blue:           db 0x1
green:          db 0x2
cyan:           db 0x3
red:            db 0x4
magenta:        db 0x5
brown:          db 0x6
light_grey:     db 0x7
dark_grey:      db 0x8
light_blue:     db 0x9
light_green:    db 0xa
light_cyan:     db 0xb
light_red:      db 0xc
light_magenta:  db 0xd
yellow:         db 0xe
white:          db 0xf

row:            db 0
column:         db 0
color:          db 0
delay_time:     db 0

;prints at specified location with color and delay
color_print:
    mov bl, byte [color]
    mov bh, 0       ;page 0
    mov cx, 1       ;chars to write
.cPrintLoop:
    call move_cursor
    mov ah, [column]
    inc ah
    mov [column], ah
    lodsb
    mov ah, 0x9
    cmp al, 0
    je .cEndPrint
    int 0x10
    call delay
    jmp .cPrintLoop
.cEndPrint:
    ret

;waits a quarter second, though is looped to do greater values
delay:
    pusha
    mov al, byte [delay_time]
    mov ah, 0x86
    ;1/4th  = 0x3D090
    ;1/8th  = 1E848
    ;1/16th = F424
    mov cx, 0x0000  ;upper
    mov dx, 0xf424  ;lower
    xor bx, bx      ;counter
.waitLoop:
    cmp al, bl
    je .waitDone
    int 0x15
    inc bl
    jmp .waitLoop
.waitDone:
    popa
    ret

; move cursor one position
move_cursor:
    pusha
    mov dh, byte [row]
    mov dl, byte [column]
    xor bx, bx
    mov ah, 0x2
    int 0x10
    popa
    ret

;sets colors via video memory at 0xb8000 aka 0xb800:0000
;first byte is char, next byte is colors
;second byte: background is top 4 bits, foreground is last 4 bits
set_video_mem:
    push ds
    mov bx, 0xb800
    mov ds, bx
    ;change 4000/2 bytes
    ;for now just change a few bytes for now
    mov [ds:0x1], byte 0xe1  ;bg: blue, fg: yellow
    mov [ds:0x3], byte 0xe1  ;bg: blue, fg: yellow
    mov [ds:0x5], byte 0xe1  ;bg: blue, fg: yellow
    pop ds
    ret

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
    mov al, 0x3     ;80x25, text mode
    int 0x10
    ret

key_pressed:    db 0
input_color:    db 0
input_bound:    dw 0
input:          times 30 db 0

;Write character and attribute at cursor position   AH=09h  AL = Character, BH = Page Number, BL = Color, CX = Number of times to print character
write_char:
    pusha
    mov ah, 0x9
    mov al, byte [key_pressed]
    mov bh, 0
    mov bl, byte [white]
    mov cx, 1
    int 0x10
    mov bl, byte [column]
    inc bl
    mov [column], byte bl
    call move_cursor
    popa
    ret

;press enter to confirm
;delete with backspace
;display chars to screen and progress cursor
user_input:
    mov bx, 0                   ;position
.inputLoop:
    mov ah, 0
    int 0x16                    ;get char
    cmp al, byte 0xd            ;pressed enter?
    ;pressed enter
    jne .notEnter               ;if they pressed enter continue without jmp
    mov [input+bx], byte 0      ;mov null byte into last position
    ret
.notEnter:
    cmp al, byte 0x8            ;pressed backspace?
    jne .notBackspace           ;if they pressed backspace continue forward
    ;is a backspace
    cmp bx, 0                   ;if they tried to delete more beyond 0 position ignore
    je .inputLoop
    dec bx                      ;otherwise move position back
    mov [input+bx], byte 0
    call delete_char            ;and delete the char
    jmp .inputLoop              ;they deleted get next input
.notBackspace:
    ;check bound
    cmp bx, word [input_bound]
    je .inputLoop               ;if is at bound jump restart
    mov [input+bx], byte al     ;is writable, put in input buffer
    mov [key_pressed], byte al  ;store keypressed
    call write_char
    inc bx                      ;increment the buffer position
    jmp .inputLoop

delete_char:
    pusha
    mov cl, byte [column]
    dec cl
    mov [column], cl
    call move_cursor
    mov ah, 0x9
    mov bh, 0
    mov al, 0x20
    mov bl, byte [white]
    mov cx, 1
    int 0x10
    popa
    ret

;found on internet
beep:
    pusha
    mov cx, 0
.beepLoop:
    cmp cx, [beep_count]
    je .endBeep
    in al, 0x61
    or al, 3
    out 0x61, al
    mov [delay_time], byte 0x1
    call delay
    in  al, 0x61
    and al, 0xFC
    out 0x61, al
    call delay
    inc cx
    jmp .beepLoop
.endBeep:
    popa
    ret

beep_count: db 1

times 510-($-$$) db 0
dw 0xaa55

