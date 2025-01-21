;IBM KAOS DRIVER. OOPS and RAM LOAD/SAVE routines.

;OOPS.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

NAME OOPS

 public ramload
 public ramsave

code SEGMENT public 'CODE'
 ASSUME cs:code

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

;Constants likely to change:

ramaddress db 3 dup(?)

;-----

ramsave:
 call getram ;Set up addresses and es=OOPS paragraph
 jnc short ramsave1
 ret ;Invalid position

;Copy W/S to RAM

ramsave1:
 cmp cx,0
 jnz short DBI044
 jmp commonexit
DBI044:

 mov es,cs:[MenuPgame] ;GAMEDATA/VARS paragraph
 mov al,es:[bx]
 push bx
 push ax
 mov bx,word ptr ds:[ramaddress]
 pop ax
 mov es,cs:[MenuPoops] ;OOPS paragraph
 mov es:[bx],al
 pop bx
 call incramaddress
 jmp short ramsave1

;-----

ramload:
 call getram ;Set up addresses and es=OOPS paragraph
jnc short ramload1
 ret ;Invalid position

;Copy RAM to W/S

ramload1:
 cmp cx,0
 jnz short ramload2
 jmp short commonexit
ramload2:

 mov dx,word ptr ds:[ramaddress]
 xchg si,dx
 mov es,cs:[MenuPoops] ;OOPS paragraph
 mov al,es:[SI]
 xchg si,dx
 mov es,cs:[MenuPgame] ;GAMEDATA/VARS paragraph
 mov es:[bx],al
 call incramaddress
 jmp short ramload1

;-----

getram:
 mov al,ds:6[si]
 or al,al
 jnz  getram1
 mov bx,0 ;Start of OOPS
 mov dl,ds:4[si]
 mov dh,ds:5[si]
 add bx,dx
 jb getram2 ;Address overflow
 xchg dx,bx ;DE is physical start address
 mov bl,ds:2[si]
 mov bh,ds:3[si]
 mov cl,ds:0[si]
 mov ch,ds:1[si]
 xor al,al
 sbb bx,cx ;HL=Length of save
 push bx

 add bx,dx
 jb short getram1 ;End address overflow

;Check end address 'AHL' is less than 010000h

 cmp al,cs:[MenuLoops+2] ;Hi byte of length of OOPS buffer
 jz short tempxxx
 jnc short getram1
tempxxx:

;Address between 000000h and 00FFFFh

 cmp bx,cs:[MenuLoops] ;Length of OOPS
 jnb short getram1 ;Past end limit

addressok:
 pop cx ;Length
 mov bl,ds:0[si]
 mov bh,ds:1[si]

;Operation OK, return address for copy

 mov al,ds:6[si]
 mov byte ptr ds:[ramaddress+2],al
 mov word ptr ds:[ramaddress],dx

 xor al,al
 mov ds:0[si],al ;Operation success
 ret ;Return 'NC'

getram1:
 pop bx
getram2:
 mov byte ptr ds:0[si],1 ;Fail
 stc
 ret

;-----

commonexit:
 mov byte ptr ds:0[si],0
 ret

;-----

incramaddress:
 inc bx
 dec cx
 push bx
 mov bx,word ptr ds:[ramaddress]
 inc bx
 mov word ptr ds:[ramaddress],bx
 cmp bx,0
 jnz short incram1
 mov bx,offset ramaddress+2
 inc byte ptr cs:[bx]
incram1:
 pop bx
 ret

;-----

code ENDS

 END






