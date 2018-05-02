[bits 16]
[org 0x7c00]

;first 3 bytes
jmp start
nop
;---------------------------+
;bios parameter block       |
;---------------------------+
OEMIdentifier:              db  'POOPBUTT'
BytesPerSector:             dw  512
SectorsPerCluster:          db  1
ReservedSectorsNum:         dw  1
FATNum:                     db  2
RootEntries:                dw  224 ;???
TotalSectors:               dw  2880
MediaDescriptorType:        db  0xf8 ;hard disk = f8, floppies = f0
SectorsPerFAT:              dw  9
SectorsPerTrack:            dw  18
HeadNum:                    dw  2
HiddenSectorNum:            dd  0
LargeSectorNum:             dd  0
DriveNumber:                db  0
Reserved:                   db  0
Signature:                  db  0x29
VolumeID:                   dd  0xdeadbeef
VolumeLabel:                db  'hello world'
FileSystem:                 db  'FAT12   '

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00  ;sets stack below

    mov [drive], byte dl

    call clear_screen

    mov [read_sector], byte 2
    mov [sectors_num], byte 3
    mov [read_loc], word seg2
    call read_all_sectors

    jmp main

    cli                     ;clear interrupts
    hlt                     ;halt cpu

color_print:
;    mov di, word [color]
;    mov bl, byte [di]   ;set color
    mov bl, byte [color]   ;set color
    mov bh, 0           ;page 0
    mov cx, 1           ;chars to write
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

clear_screen:
    pusha
    mov ah, 0x6
    mov al, 0       ;clear all rows
    mov bh, 0x07    ;attributes, black/grey
    xor cx, cx      ;0x0 upper left
    mov dh, 0x18    ;bottom right row
    mov dl, 0x4f    ;bottom right column
    int 0x10
    popa
    ret

read_all_sectors:
    mov ah, 0x02
    mov dl, byte [drive]        ;select the drive
    mov ch, 0                   ;cylinder
    mov dh, 0                   ;head
    mov cl, byte [read_sector]  ;sector
    mov al, byte [sectors_num]  ;num of sectors to read
    xor bx, bx
    mov es, bx
    mov bx, word [read_loc]     ;read sectors into read_loc
    int 0x13
    jc drive_error
    cmp al, 1
    jne drive_error
    ret

drive_error:
    mov ah, 1
    int 0x13
    mov [row], byte 0
    mov [column], byte 0
;    mov [color], word red
    mov [color], byte 0x9
    mov si, drive_error_msg
    call color_print
    ret

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

;colors
black:              db 0x0
blue:               db 0x1
green:              db 0x2
cyan:               db 0x3
red:                db 0x4
magenta:            db 0x5
brown:              db 0x6
light_grey:         db 0x7
dark_grey:          db 0x8
light_blue:         db 0x9
light_green:        db 0xa
light_cyan:         db 0xb
light_red:          db 0xc
light_magenta:      db 0xd
yellow:             db 0xe
white:              db 0xf

drive:              db 0
read_sector:        db 0
sectors_num:        db 0
read_loc:           db 0
drive_error_msg:    db 'Read Error',0

row:            db 0
column:         db 0
color:          dw 0

delay_time:     db 0

times 510-($-$$) db 0
dw 0xaa55
seg2:
;remaining sectors go here
main:
    call clear_screen

    mov [row], byte 1
    mov [column], byte 0
;    mov [color], word light_green
    mov [color], byte 0x9
    mov si, success
    call color_print

print_hex:
    mov cx, 0               ;count number of hex chars
.hexLoop:
    cmp cx, 4
    je .hexPrint
    mov dx, ax              ;save hex value in dx
    and dx, 0xf             ;and with 15 to get first char
    push dx                 ;save hex value on stack
    shr ax, 4               ;shift right 4 bits
    inc cx
    jmp .hexLoop
.hexPrint:
    cmp cx, 0
    je .endHexPrint
    mov bx, hex_table
    pop ax                  ;hex char will be in al only
    add bx, ax              ;add with pointer to array to get char
    mov al, [bx]            ;move char to register
    xor bx, bx              ;make 0
    mov ah, 0x0e            ;get ready to print
    int 0x10
    dec cx
    jmp .hexPrint
.endHexPrint:
    ret

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
    and al, 0xfc
    out 0x61, al
    in  al, 0x61
    and al, 0xfd    ;try both
    out 0x61, al
    call delay
    inc cx
    jmp .beepLoop
.endBeep:
    popa
    ret

;comapares two memory locations which hold strings
;bx = index
;si = location 1
;di = location 2
;returns 1 in al if equal, 0 if not
compare_str:
    pusha
    xor bx, bx
.compareLoop:
    mov al, byte [si+bx]
    mov ah, byte [di+bx]
    cmp al, ah
    jne .notEqual
    or al, 0
    jz .end
    inc bx
    jmp .compareLoop
.end:
    popa
    mov al, 1
    ret
.notEqual:
    popa
    mov al, 0
    ret

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

set_video_mode:
    pusha
    xor ax, ax
    mov al, 0x3     ;80x25, text mode
    int 0x10
    ret

beep_count: db 1

key_pressed:    db 0
input_color:    db 0
input_bound:    dw 0
input:          times 20 db 0
hex_table:      db '0123456789ABCDEF',0
success:        db  'We did it',0
times 2048-($-$$) db 0






