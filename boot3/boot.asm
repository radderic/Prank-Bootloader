;-----------------------------------
; An amalgamation of previous bootloaders
; Soon to be a prank bootloader
;-----------------------------------

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
VolumeLabel:                db  'legit usb  '
FileSystem:                 db  'FAT12   '

start:
    xor ax, ax                  ;clear all segment registers
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00              ;sets stack below

    mov [drive], byte dl        ;save drive id

    call set_default_video_mode
    call clear_screen

    mov [read_sector], byte 2   ;read the remaining sectors into memory
    mov [sectors_num], byte 3   ;can only be ((total sectors used-512)/512)
    mov [read_loc], word seg2
    call read_all_sectors

    jmp main                    ;go to our real code

    cli                         ;clear interrupts
    hlt                         ;halt cpu

;-------------------------------------------------------------------
; Prints color text at specific location
; Arguments:
;   fg_color: Color of the text, pass the address into color
;   row: row which to start text on
;   column: Column which to start text on
;   delay_time: Time between each character written, default 1/4th second
;       for each 1 value, it is 1/4th a second, therefore 4 is an entire second
;-------------------------------------------------------------------
color_print:
    pusha
    mov di, word [fg_color]
    mov bl, byte [di]   ;set color
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
    popa
    ret

;-------------------------------------------------------------------
; Moves cursor to specified row and column
; Arguments:
;   row: Row to set cursor to
;   column: Colmun to set cursor to
;-------------------------------------------------------------------
move_cursor:
    pusha
    mov dh, byte [row]
    mov dl, byte [column]
    xor bx, bx
    mov ah, 0x2
    int 0x10
    popa
    ret

;-------------------------------------------------------------------
; Clears the screen
;-------------------------------------------------------------------
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

;-------------------------------------------------------------------
; Sets to default video mode (3), which is 80x25 text mode
;-------------------------------------------------------------------
set_default_video_mode:
    pusha
    xor ax, ax
    mov al, 0x3
    int 0x10
    popa
    ret

;-------------------------------------------------------------------
; Reads remaining code into memory from the drive
; Arguments:
;   drive: the drive is passed from dl on boot
;   read_sector: generally is always 2, as it starts reading after 512 bytes
;   sectors_num: the amount of sectors to be read into memory
;   read_loc: the location which the read is put into memory
;-------------------------------------------------------------------
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
    cmp al, byte [sectors_num]
    jne drive_error
    ret

;-------------------------------------------------------------------
; Prints error message if the drive was unable to read or write from drive
;-------------------------------------------------------------------
drive_error:
    mov ah, 1
    int 0x13
    mov [row], byte 0
    mov [column], byte 0
    mov [fg_color], word red
    mov si, drive_error_msg
    call color_print
    ret

;-------------------------------------------------------------------
; Delays cpu for a 1/4th a second. Can be delayed for longer with delay_time
; Arguments:
;   delay_time: for each 1 value, it is 1/4th a second, therefore 4 is an entire second
;-------------------------------------------------------------------
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

;drive variables
drive:              db 0
read_sector:        db 0
sectors_num:        db 0
read_loc:           dw 0
drive_error_msg:    db 'Read/Write Error',0

;text varibles
row:            db 0
column:         db 0
fg_color:       dw 0
bg_color:       dw 0

delay_time:     db 1

times 510-($-$$) db 0
dw 0xaa55               ;boot signature

;------------------------------------------
; Start of purpose here
;------------------------------------------
seg2:
turnoff1:        db 0 ;checks if they turn off the computer to avoid
turnoff2:        db 0 ;checks if they turn off the computer twice to avoid
turnoff3:        db 0 ;checks if they turn off the computer thrice to avoid

;remaining sectors go here
main:
    cmp [turnoff1], byte 1
    je .turnedOff1

    mov [turnoff1], byte 1
    mov [write_sector], byte 2
    mov [write_from], word seg2
    call write_drive

    mov [row], byte 0
    mov [column], byte 0
    mov [fg_color], word red
    mov si, msg1
    call color_print

    mov [row], byte 1
    mov [column], byte 0
    mov [fg_color], word white
    mov si, msg2
    call color_print

    mov [fg_color], word cyan
    call move_cursor
    mov [input_bound], byte 1
    mov [ignore_case], byte 1
    call user_input

    mov si, input
    mov di, ans1
    call compare_str

    mov [row], byte 2
    mov [column], byte 0
    mov [fg_color], word light_green
    mov si, equalStr
    cmp al, 1
    jne .strNotEqual
.compareEnd:
    jmp .theEnd
.strNotEqual:
    mov [fg_color], word light_red
    mov si, notEqual
    jmp .compareEnd
.theEnd:
    call color_print

    jmp .final

.turnedOff1:
    mov [row], byte 0
    mov [column], byte 0
    mov [fg_color], word light_red
    mov si, turnOffMsg1
    call color_print

.final:
    call enable_bg_intensity
    mov [bg_color], word yellow
    call set_bg_only
    cli
    hlt

;-------------------------------------------------------------------
; Prints a value as hex
; Arguments:
;   Word (2 bytes) to be printed in the variable hex
;-------------------------------------------------------------------
print_hex:
    pusha
    mov cx, 0               ;count number of hex chars
    mov ax, word [hex]
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
    xor bx, bx
    mov ah, 0x0e            ;get ready to print
    int 0x10
    dec cx
    jmp .hexPrint
.endHexPrint:
    popa
    ret

;-------------------------------------------------------------------
; Beeps through speaker at specified time interval
; Arguments:
;   beep_count: Times to loop all beeps
;   delay_time: Duration of each beep, for every 1 is 1/4 a second
;-------------------------------------------------------------------
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
    call delay
    inc cx
    jmp .beepLoop
.endBeep:
    popa
    ret

;-------------------------------------------------------------------
; Compares two memory locations which hold strings
; Arguments:
;   si = location 1
;   di = location 2
;   ignore_case: If set to 1, case is ignored, if 0, case is significant
; Return:
;   returns 1 in al if equal, 0 if not
;-------------------------------------------------------------------
compare_str:
    pusha
    xor bx, bx
.compareLoop:
    mov al, byte [si+bx]
    mov ah, byte [di+bx]
    cmp [ignore_case], byte 1 ;if greater than or equal to 0x61 (a) subtract 32
    jne .caseSensitive
    cmp al, 0x61
    jl .keepFirstCase
    sub al, 32
.keepFirstCase:
    cmp ah, 0x61
    jl .keepSecondCase
    sub ah, 32
.keepSecondCase:
.caseSensitive:
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


;-------------------------------------------------------------------
; Writes a character, generally a helper function for printing functions
; Arguments:
;   key_pressed: Character to be printed
;   fg_color: color of text
;-------------------------------------------------------------------
write_char:
    pusha
    mov ah, 0x9
    mov al, byte [key_pressed]
    mov bh, 0
    mov di, word [fg_color]
    mov bl, byte [di]
    mov cx, 1
    int 0x10
    mov bl, byte [column]
    inc bl
    mov [column], byte bl
    call move_cursor
    popa
    ret

;-------------------------------------------------------------------
; Gets user input of specified length and writes it as they type
;   Bacspace for deletion, enter for submission
; Arguments:
;   input_bound: the bound which defines how many characters the user can input
;       This value cannot be larger than the input buffer
;-------------------------------------------------------------------
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


;-------------------------------------------------------------------
; Helper function for user input. Removes character from screen
;-------------------------------------------------------------------
delete_char:
    pusha
    mov cl, byte [column]
    dec cl
    mov [column], cl
    call move_cursor
    mov ah, 0x9
    mov bh, 0
    mov al, 0x20
    mov di, word [fg_color]
    mov bl, byte [di]
    mov cx, 1
    int 0x10
    popa
    ret

;-------------------------------------------------------------------
; Writes a singe sector back to the drive
; Arguments:
;   write_sector: Which sector on the drive to write to
;   write_from: Where to write from memory
;-------------------------------------------------------------------
write_drive:
    pusha
    mov ah, 0x03
    mov dl, byte [drive]
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
    popa
    ret


;-------------------------------------------------------------------
; Changes the background color but preserves foreground color (text color)
; Arguments:
;   bg_color: sets background color
;-------------------------------------------------------------------
set_bg_only:
    pusha
    mov di, word [bg_color]
    mov cx, word [di]       ;save color before we change ds
    shl cx, 4               ;move it to bg bits location
    push ds
    mov bx, 0xb800
    mov ds, bx:
    mov bx, 1               ;start at offset of 1 to select colors
    xor ax, ax
.bgOnlyLoop:
    cmp bx, 4000
    jg .bgOnlyEnd
    mov al, byte [ds:bx]
    and al, 0b00001111      ;clear bottom half of byte
    or al, cl
    mov [ds:bx], byte al
    add bx, 2
    jmp .bgOnlyLoop
.bgOnlyEnd:
    pop ds
    popa
    ret


;-------------------------------------------------------------------
; Disables blinking text and allows more background colors to be used
;-------------------------------------------------------------------
enable_bg_intensity:
    pusha
    mov ax, 0x1003
    mov bl, 0x0
    mov bh, 0x0
    int 0x10
    popa
    ret

;-------------------------------------------------------------------
; Disables certain background colors where the highest bit is 1.
;   It instead makes the text blink
;-------------------------------------------------------------------
enable_blinking:
    pusha
    mov ax, 0x1003
    mov bl, 0x1
    mov bh, 0x0
    int 0x10
    popa
    ret

;beep variables
beep_count: db 1

;input variables
input:          times 20 db 0
key_pressed:    db 0
input_color:    db 0
input_bound:    dw 0
ignore_case:    db 0

hex_table:      db '0123456789ABCDEF',0
hex:            dw 0

;test strings
equalStr:       db 'Success',0
notEqual:       db 'Failure',0
ans1:           db 'y',0
msg1:           db 'DISK BOOT FAILURE, ATTEMPT TO FIX?',0
msg2:           db 'Choose (y/n):',0
turnOffMsg1:    db 'Computer was turned off midway through last session, doing something else',0

;write variables
write_sector:   db 0
write_from:     dw 0

times 2048-($-$$) db 0      ;total of 4, 512 byte sectors

