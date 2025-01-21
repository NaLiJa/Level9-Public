;IBM KAOS compressed-picture bit-mapper.

;PALETTE.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name palette

code segment public 'code'
 assume cs:code,ds:vars

;Ascii/BBC control codes:
asciibs = 08h
asciilf = 0Ah
asciicls= 0Ch
asciicr = 0Dh
asciiesc= 1Bh
asciidel=07Fh
space = ' '

stfileid equ 0FFh ;third byte of picture file.
pcfileid equ 0FEh

filetype equ 2
palette equ 4

;-----

 push cs
 pop ds

 mov bx,01000h ;Request 64K bytes of memory
 mov ah,048h ;Allocate memory
 int 21h ;Universal DOS function
 cmp ax,8 ;Check that DOS has refused to allocate
 jnz allocationOK
 mov di,offset miniature
 call directprs
 jmp short terminate

miniature:
 db "Out of memory",13,10,0

allocationOK:
 mov ds,ax
 mov es,ax

 mov di,offset copyright
 call directprs

 call ConvertPicture

terminate:
 mov ah,76 ;Terminate
 int 21h ;Terminate program
 jmp short terminate

copyright:
 db "Convert ST picture file to contain",13,10
 db "separate palettes for B&W/CGA/VGA/EGA",13,10,0

;-----

ConvertPicture:
 mov di,offset filename
 call directprs

 call inputline

 cmp ds:FileNameBuffer,0
 jnz cp02
 ret ;null input

filename:
 db "Filename? ",0

cp02:
 mov cx,0FFFFh ;length
 mov dx,offset FileNameBuffer
 mov si,offset PictureBuffer
 call loadupfile
 cmp al,0
 jz cp02a

 mov si,offset FileNameBuffer
 mov cx,FileNameBuffersize-4
osload3b:
 cmp byte ptr ds:[si],0
 jz osload3a
 inc si
 loop osload3b
 jmp short osload4 ;File not found (non-fatal)

osload3a:
 mov word ptr ds:0[si],'P'*256+'.'
 mov word ptr ds:2[si],'C'*256+'I'
 mov byte ptr ds:4[si],0

 mov cx,0FFFFh ;length
 mov dx,offset FileNameBuffer
 mov si,offset PictureBuffer
 call loadupfile
 cmp al,0
 jz cp02a

osload4:
 mov di,offset DiskError
 call directprs
 jmp ConvertPicture

DiskError:
 db "File not found/Read error",13,10,0

cp02a:
 call checkfile
 jz cp03

 mov di,offset checksumerror
 call directprs

cp03:
 cmp byte ptr ds:filetype[picturebuffer],stfileid
 jz cp06a
 cmp byte ptr ds:filetype[picturebuffer],pcfileid
 jz cp04

 mov di,offset wrongfile
 call directprs
 jmp ConvertPicture

cp06a:
 jmp cp06

checksumerror:
 db "Warning: Checksum incorrect",13,10,0

wrongfile:
 db "Not a recognisable ST/PC squashed picture",13,10,0

cp04:
 mov bh,byte ptr ds:0[picturebuffer]
 mov bl,byte ptr ds:1[picturebuffer]
 add bx,offset PictureBuffer
 sub bx,3*32+5 ;Move back to start of added parameters
 cmp byte ptr ds:0[bx],'('
 jnz cp05
 cmp byte ptr ds:1[bx],'C'
 jnz cp05
 cmp byte ptr ds:2[bx],')'
 jnz cp05
 cmp byte ptr ds:3[bx],'L'
 jnz cp05
 cmp byte ptr ds:4[bx],'9'
 jz cp05a ;parameter area OK

cp05:
 mov di,offset badfile
 call directprs
 jmp ConvertPicture

badfile:
 db "File already marked as PC-squashed.",13,10
 db "Missing Parameter block sequence.",13,10,0

cp05a: ;parameter area OK
 mov di,offset AlreadyOK
 call directprs
 jmp ConvertPicture

AlreadyOK:
 db "Picture already correct format",13,10,0

cp06:
 mov byte ptr ds:filetype[picturebuffer],pcfileid
 mov bh,byte ptr ds:0[picturebuffer]
 mov bl,byte ptr ds:1[picturebuffer]
 add bx,offset PictureBuffer+1
 mov byte ptr ds:0[bx],'(' ;append to EOF new data
 mov byte ptr ds:1[bx],'C'
 mov byte ptr ds:2[bx],')'
 mov byte ptr ds:3[bx],'L'
 mov byte ptr ds:4[bx],'9'
 mov si,offset PictureBuffer+palette
 mov di,5
 add di,bx
 mov cx,32
 rep movsb ;reserved for b&w palette
 mov si,offset PictureBuffer+palette
 mov cx,32
 rep movsb ;reserved for CGA palette
 mov si,offset PictureBuffer+palette
 mov cx,32 ;VGA palette - hopefully the original ST palette
 rep movsb

 mov bh,byte ptr ds:0[picturebuffer]
 mov bl,byte ptr ds:1[picturebuffer]
 add bx,3*32+6
 mov byte ptr ds:0[picturebuffer],bh
 mov byte ptr ds:1[picturebuffer],bl

 call setchecksum

 mov ch,es:0[PictureBuffer]
 mov cl,es:1[PictureBuffer]
 inc cx
 mov dx,offset FileNameBuffer
 mov si,offset PictureBuffer
 call writefile
 jmp ConvertPicture

;-----

;Load a file, maximum length CX, name in DX, to address ES:0
;Returns AL=0 if OK (cx=bytes loaded)
;        AL=1 if file not found
;        AL=3 if file can't load

LoadUpFile:
 push cx ;Length
 push si ;Load address

 mov al,0 ;non-private/compatable/read-only
 mov ah,61 ;Open file
 int 21h   ;extended DOS function

 pop si ;Load address
 pop cx ;Length

 jnc le01
 mov al,1  ;File not found
 ret

le01:
 push ax   ;File handle
 push cx   ;length
 push si   ;Load address
 mov bx,ax
 mov al,0  ;relative to start of file
 mov cx,0  ;relative position (high)
 mov dx,0  ;relative position (low)
 mov ah,66 ;move file pointer
 int 21h   ;extended DOS function
 pop si    ;Load address
 pop cx    ;length
 pop ax    ;file handle

 push ax   ;File handle
 push ds

 mov bx,ax ;file handle
; cx=length
 mov ax,es
 mov ds,ax
 mov dx,si ;address DS:DX = ES:SI
 mov ah,63 ;Read from file
 int 21h   ;extended DOS function
 jnc le02

;Error
 pop ds
 pop bx    ;File handle
 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,3  ;File can't load
 ret

le02:
 mov cx,ax ;Number of bytes loaded
 pop ds
 pop bx    ;File handle
 push cx

 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 pop cx    ;number of bytes read
 mov al,0  ;File can't load
 ret

;-----

;Save a file, length CX, name in DX, to address ES:0
;Returns AL=0 if OK (cx=bytes loaded)
;        AL=1 if file not found
;        AL=3 if file can't load

writefile:
 push cx   ;Length

 push dx   ;filename
 mov ah,65 ;Delete file
 int 21h   ;extended DOS function
 pop dx    ;filename

 mov cx,0  ;non-archive, non-system, non-hidden, writeable.
 mov ah,60 ;Create file
 int 21h   ;extended DOS function

 pop cx ;Length

 jnc wf01
 mov al,1  ;can't create
 ret

wf01:
 push ax   ;File handle
 push cx   ;length
 mov bx,ax
 mov al,0  ;relative to start of file
 mov cx,0  ;relative position (high)
 mov dx,0  ;relative position (low)
 mov ah,66 ;move file pointer
 int 21h   ;extended DOS function
 pop cx    ;length
 pop ax    ;file handle

 push ax   ;File handle
 push ds

 mov bx,ax ;file handle
; cx=length
 mov ax,es
 mov ds,ax
 mov dx,offset PictureBuffer ;address DS:DX = ES:0
 mov ah,64 ;Write to file
 int 21h   ;extended DOS function
 jnc wf02

;Error
 pop ds
 pop bx    ;File handle
 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,3  ;Can't write file
 ret

wf02:
 mov cx,ax ;Number of bytes loaded
 pop ds
 pop bx    ;File handle

 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,0  ;File written
 ret

;-----

waitforkey:
 mov ah,01 ;Service 1 (Report keyboard)
 int 16h ;ROM-BIOD keyboard service
 jz waitforkey

 mov ah,00h ;Service 0 (Read Next Keyboard Character)
 int 16h ;ROM-BIOS keyboard service
 ret

;-----

inputline:
; RETURN IN (IY+1)
 mov bx,offset FileNameBuffer
 mov ch,0 ;Number of chars
inpl1:
 push bx
 push dx
 push cx

 call waitforkey
 cmp al,3
 jnz inpl1a
 jmp terminate

inpl1a:

inpl6:
 pop cx
 pop dx
 pop bx
 cmp al,asciidel
 jz short inpl7
 cmp al,asciibs
 jnz short inpl8
inpl7:
 mov al,ch
 or al,al
 jz short inpl1
 dec ch
 dec bx
 mov al,asciibs
 call directoutput
 jmp short inpl1
inpl8:
 cmp al,asciicr
 jnz short dbi024
 jmp short inplend
dbi024:    
 cmp al,space
 jnc short inpl8a
 jmp short inpl1
inpl8a:
 cmp al,'a' ;Convert lower case to upper case
 jb short notlower
 cmp al,'z'+1
 jae short notlower
 and al,0DFh
notlower:
 mov cl,al
 mov al,ch
 cmp al,FileNameBuffersize
 jnz short inpl9
 jmp short inpl1
inpl9:
 mov al,cl
 call directoutput
 inc ch
 mov al,cl
 mov [bx],al
 inc bx
 jmp short inpl1
inplend:
 mov byte ptr [bx],0
 mov al,asciicr
 call directoutput
 mov al,asciilf
 call directoutput
 ret

;-----

;Print string at [DI]
directprs:
 mov al,cs:[di]
 cmp al,0
 jz short directprs1

 mov al,cs:0[di]
 call directoutput
 inc di
 jmp short directprs
directprs1:
 ret

;-----

directoutput:
 mov dl,al
 mov ah,2 ;Universal Function 2 - Display Output
 int 21h ;Universial Function
 ret

;-----

checkfile: ;Check picture at (es:si)
; make sure that the File type word in the header contain
; the value compressed_picture_id. Note that the word is stored
; HI BYTE FIRST as is common on the 68000

 mov si,offset PictureBuffer

 push si
 mov bh,es:0[si] ;hi length
 mov bl,es:1[si] ;lo
 sub bx,2 ;Exclude length bytes
 add si,2 ;Exclude length
 mov al,0 ;Checksum total
checksum1:
 cmp bx,0
 jz checksum2
 add al,es:[si]
 inc si
 dec bx
 jmp short checksum1
checksum2:
 cmp al,es:[si]
 pop si
 jnz checksum3 ;File has been overwritten, so ignore it.

 mov al,es:filetype[si]
 cmp al,stfileid
 jz checksum3
 cmp al,pcfileid
checksum3:
 ret

;-----

;Set checksum:

setchecksum:
 mov si,offset PictureBuffer

 mov bh,es:0[si] ;hi length
 mov bl,es:1[si] ;lo
 sub bx,2 ;Exclude length bytes
 add si,2 ;Exclude length
 mov al,0 ;Checksum total
SetChecksum1:
 cmp bx,0
 jz SetChecksum2
 add al,es:[si]
 inc si
 dec bx
 jmp short SetChecksum1
SetChecksum2:
 mov es:[si],al ;write new checksum
 ret

code ends

;-----

vars segment word public 'data'

FileNameBuffersize = 80
FileNameBuffer db FileNameBuffersize dup (0)

PictureBuffer db 0

vars ends

;-----

;Folowing way of defining stack is recognised by linker and generates
;a code file which auto sets-up stack:

stacks segment stack 'stack'
 assume ss:stacks

 db 256 dup (0)

stacks ends

;-----

 end





