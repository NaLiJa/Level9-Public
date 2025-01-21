;IBM KAOS DRIVER. driver routines common to MENU and AINT.

;ENTRY.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

NAME DRIVER

 public calcpages
 public close
 public characterwidth
 public diskbuffer
 public driver
 public entrydisplayall
 public fcbdrive
 public kbdbuffer
 public kbdbuflen
 public pagingoff
 public pagingset
 public pagingonoff
 public screenmode

;In MENU.ASM:
 extrn graphicdisplayall:near

;In DRIVER.ASM/MENU.ASM:
 extrn chain:near
 extrn checksum:near
 extrn demoenable:byte
 extrn getseed:near
 extrn inputline:near
 extrn osload:near
 extrn osrdch:near
 extrn ossave:near
 extrn resetpagecount:near
 extrn SafeReplaceCursor:near
 extrn setoscursor:near

;In MENU.ASM/GRAPHIC.ASM:
 extrn backgroundcolour:byte
 extrn settextmode:near

;In HIRES.ASM:
 extrn currentpicture:near
 extrn displayhires:near
 extrn picturelines:near
 extrn setpictures:near

;In MENU.ASM/EDSQU.ASM:
 extrn aintrestart:near
 extrn initrecall:near
 extrn ramload:near
 extrn ramsave:near

;-----

;These include files must be named in MAKE.TXT:
 include head.asm

code SEGMENT public 'code'

 ASSUME cs:code,ds:code

screenmode db 0

;-----

kbdbufsize = 64  ;Keyboard buffer during 'PRESS ANY KEY'

;Ascii/BBC control codes:
asciicr = 0Dh
asciilf = 0Ah
space = ' '

;-----

pagingonoff db 0
kbdbuffer db kbdbufsize dup(0)
kbdbuflen db 0

characterwidth db 0

diskbuffer db 80h dup (0)
 db 1024 dup (0) ;Make up to MS-DOS sector length (for trykdisk)

 db 7 dup(0) ;Extended area
sysfcb = this byte
fcbdrive db 0
fcbname  db 8  dup(0)
fcbtype  db 3  dup(0)
fcbex    db 20 dup(0)
fcbcr    db 4  dup(0)
fcbend = this byte
fcblen    = fcbend-sysfcb

;-----

pagingoff:
 xor al,al
pagingset:
 mov ds:[pagingonoff],al
 ret

;-----

driver:
 push es ;Save GAMEDATA paragraph address
 push ds
 push di
 push si
 push bx
 push dx
 push cx
 call driver1
 pop cx
 pop dx
 pop bx
 pop si
 pop di
 pop ds
 pop es ;Restore GAMEDATA paragraph address
 ret

;-----

jumptable:
 dw initialiseall  ;0
 dw checksum       ;1
 dw oswrch         ;2
 dw osrdch         ;3
 dw inputline      ;4
 dw ossave         ;5
 dw osload         ;6
 dw settextmode    ;7
 dw notimp         ;8
 dw stop           ;9
 dw notimp         ;10
 dw chain          ;11
 dw getseed        ;12
 dw returnwidth    ;13
 dw notimp         ;14
 dw partialinit    ;15
 dw setpictures    ;16
 dw notimp         ;17
 dw notimp         ;18
 dw notimp         ;19
 dw notimp         ;20
 dw notimp         ;21
 dw ramsave        ;22
 dw ramload        ;23
 dw notimp         ;24
 dw notimp         ;25
 dw notimp         ;26
 dw notimp         ;27
 dw notimp         ;28
 dw notimp         ;29
 dw notimp         ;30
 dw notimp         ;31
 dw displayhires   ;32
 dw notimp         ;32
 dw currentpicture ;34

lastcode=34 ;Maximum driver code accepted

driver1:
 cmp al,lastcode+1
 jc short driver2
notimp:
 ret
driver2:
 mov di,offset jumptable
 mov ah,0
 add ax,ax
 add di,ax
 jmp cs:[di]

;-----

stop:
 mov ah,76
 int 21h
 jmp aintrestart

;-----

returnwidth:
 mov al,ds:[characterwidth]
 mov ds:0[si],al
 ret

;-----

initialiseall:
 mov ax,cs:[MenuLautorun]
 cmp ax,0
 jz setdemoenable ;No memory allocated for auto-demo
 mov al,1 ;Auto-run memory allocated, so default to auto-run on.
setdemoenable:
 mov ds:[demoenable],al

 mov es,cs:[MenuPgraphicsBuffer]
 mov cx,cs:[MenuLgraphicsBuffer]
 mov di,0
clearmem:
 jcxz partialinit
 mov byte ptr es:[di],0
 inc di
 dec cx
 jmp short clearmem

partialinit:
;(no multi) call initialisegraphics ;(Set up multitasking)

 call initialisescreen
 
 call initrecall

 cmp word ptr cs:[MenuLrecall],0 ;Length of recall buffer
 jz short endclear ;Not enough memory for recall buffer

 mov ax,0
 mov bx,cs:[MenuLrecall] ;Length of recall buffer
 mov es,cs:[MenuPrecall] ;Paragraph address of recall buffer
clearbuffer:
 cmp bx,0
 jz short endclear
 push si
 mov si,ax
 mov byte ptr es:[si],0
 pop si
 inc ax
 dec bx
 jmp short clearbuffer

endclear:
 mov ds:[pagingonoff],1 ;Paging on

 mov ds:[kbdbuflen],0 ;Clear keyboard buffer
 call resetpagecount

 mov dx,offset diskbuffer
 mov ah,01Ah ;Set Disk Transfer Area
 int 21h ;ROM-BIOS DOS Functions

 ret

;-----

;Calculate number of pages that need to be read/written
;to ensure a minimum number of bytes are transfered.
;HL is number of bytes.
;Returns A as number of pages. Flags corrupted.
calcpages:
 push bx
 dec bx
 inc bh
 mov al,bh
 pop bx
 ret

;-----

;Open system file for reading.
;DE is the address of the file control block
;initialised by GETNAME.
;Most registers corrupted.
openread:
 mov dx,offset sysfcb
 mov ah,cpnof
 int 21h ;Dos Service
 or al,al
 jnz short dbi027
 clc
 ret
dbi027:
 stc
 ret

;-----

;Read up to 'AL' pages or untiL EOF from the
;system file into memory starting at address
;'BX'. The file must have been opened by OPENREAD
;Returns condition 'C' on disk error

readfile:
 call setoscursor ;Saves AX BX

rf01:
 mov dx,offset sysfcb
 or al,al
 jz rf03

 push ax
 call readblock
 jc rf02
 call readblock
 jc rf02
 pop ax
 dec al
 jmp short rf01

rf02:
 pop ax
 stc

rf03:
 jmp SafeReplaceCursor

readblock:
 push ax
 push bx
 mov ah,cpnrs
 int 21h ;Dos service
 pop bx
 or al,al
 jnz short rb01
 pop ax
 push dx
 mov cx,128
 mov si,offset diskbuffer
 mov di,bx
ldirfromworkspace:
 cmp cx,0
 jz short ldirfromend
 mov al,ds:0[si]
 mov es:0[di],al
 inc di
 inc si
 dec cx
 jmp short ldirfromworkspace
ldirfromend:
 mov bx,di
 pop dx
 xor al,al
 ret
rb01:
 pop ax
 stc
 ret

;-----

;Close system file previously
;opened by OPENREAD or OPENWRITE
;Registers AF,HL,DE,BC corrupted.
close:
 call setoscursor
 mov dx,offset sysfcb
 mov ah,cpncf
 int 21h ;Dos Service
 jmp SafeReplaceCursor

;-----

;Prepare system FCB for a new file. Set drive
;to current login drive.
;Registers AF,HL,DE,BC corrupted.
fcbinit:
 mov ah,cpnrst
 int 21h ;Dos Service
 mov bx,offset sysfcb
 mov dx,offset sysfcb+1
 mov cx,fcblen-1
 mov byte ptr ds:[bx],space
 xchg bx,si
 xchg dx,di
 call ldir
 xchg bx,si
 xchg dx,di
 xor al,al
 mov ds:[fcbdrive],al
 mov ds:[fcbex],al
 mov ds:[fcbcr],al
 ret

;-----

ldir:
 cmp cx,0
 jz short ldirend
 mov al,ds:0[si]
 mov ds:0[di],al
 inc di
 inc si
 dec cx
 jmp short ldir
ldirend:
 ret

;-----

oswrch:
 mov al,ds:[si]
entrydisplayall:
 cmp cs:screenmode,7
 jnz dn00
 jmp short displaymode7

dn00:
 jmp graphicdisplayall

;All output in (and only in) mode 7.
;Allow control chars are CR and BS.

displaymode7:
 cmp al,asciicls
 jz mode7cls
 push ax
 mov bl,mode7colour ;Colour white
 mov ah,0Eh ;Service 14 (Write character as tty)
 mov bh,0 ;Display page
 int 10h ;ROM-BIOS video service
 pop ax
 cmp al,asciicr
 mov al,asciilf
 jz displaymode7
 ret

;Mode 7 - Initialise and clear text

mode7cls:
 mov al,7
 mov ah,0 ;Video service 0, Set Video Mode
 int 10h ;ROM-BIOS Video Service

;Most machines will now have a clear screen, so further processing will
;not be visible. On those machines which implement CLS as HOME now quickly
;position cursor on bottom line and print 25 CR's.

 mov cx,50 ;Scroll off screen
mc01:
 push cx
 mov al,asciilf
 mov ah,0Eh ;Service 14 (Write character as TTY)
 mov bh,0 ;Display page
 int 10h ;ROM-BIOS video service
 pop cx
 dec cx
 cmp cx,0
 jnz mc01

;Position cursor at (0,0)

 mov al,7
 mov ah,0 ;Video service 0, Set Video Mode
 int 10h ;ROM-BIOS Video Service

 ret

;----

initialisescreen:
 mov ah,0Fh ;Get Current Video Mode
 int 10h ;ROM-BIOS Video Service
 mov ds:[characterwidth],ah
 mov ds:[screenmode],al

 mov ds:backgroundcolour,0 ;For MGA and EGA modes
 cmp al,13
 jnc gotcolour 
 cmp al,6
 jz gotcolour
 mov ds:backgroundcolour,textcolour ;For EGA modes
 cmp al,7
 jnz gotcolour
 mov ds:backgroundcolour,mode7colour ;For EGA modes

gotcolour:
 mov al,asciicls
 jmp short entrydisplayall

;-----

code ENDS

 END






