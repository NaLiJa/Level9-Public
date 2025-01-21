;IBM KAOS compressed-picture bit-mapper.

;MAKEBITM.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

 include head.asm

;-----

 public aintrestart
 public cursorcr
 public cursordown
 public cursorup
 public drawM13line
 public error
 public initrecall
 public LoadUpFile
 public lsttbl
 public MCcontinue
 public mode13transferrow
 public ModuleName
 public ramsave
 public ramload
 public start

;In EDEGA.ASM:
 extrn newpalette:byte
 extrn mappingtable:byte

;In ENTRY.ASM:
 extrn screenmode:byte

;In HIRES.ASM:
 extrn drawentirepicture:near
 extrn taskaddress:word

;In DECOMP.ASM:
 extrn colourtable:byte
 extrn STtoIBM:near

name makebitm

code segment public 'code'
 assume cs:code,ds:code

csoffsetzero:
 jmp short aintrestart

paramaterarea:
 db (MenuHeaderLength-(paramaterarea-csoffsetzero)) dup (0)

;-----

row15 = 15
row16 = 16
row17 = 17
row18 = 18
row20 = 18 ;error messages/prompts
row23 = 23

column0 = 0
column30 = 37
column63 = 63
column73 = 73

row226 = 226
column524 = 524
column604 = 604

;-----

aintrestart:
 push cs
 pop ds

 mov ah,0 ;Set Video Mode
 mov al,16
 mov ds:[screenmode],al
 int 10h ;Video Service

 mov dx,offset diskbuffer
 mov ah,01Ah ;Set Disk Transfer Area
 int 21h ;ROM-BIOS DOS Functions

 jmp short skip

outofmemory:
 mov di,offset error
 call directprs
 jmp short terminate

skip:
;Allocate 64k byte paragraph for picture workspace:

 mov bx,4096
 mov ah,48h ;Allocate memory
 int 21h ;ROM-BIOS DOS Functions
 cmp ax,8
 je short outofmemory
 mov cs:[MenuPcache],ax ;Save paragraph start address...

;Allocate 64k byte paragraph for screen workspace:

 mov bx,4096
 mov ah,48h ;Allocate memory
 int 21h ;ROM-BIOS DOS Functions
 cmp ax,8
 je short outofmemory
 mov cs:[MenuPgraphicsbuffer],ax ;Save paragraph start address...
 mov cs:[MenuLgraphicsbuffer],0FFF0h ;Length

 mov byte ptr cs:[MenuFgraphicpossible],1
 mov byte ptr cs:[MenuFsubmode],ega_ultra ;Fast-EGA

again:
 call loadpicturein

 mov si,0 ;Change length from 68000 to 8086 format
 mov ah,es:0[si]
 mov al,es:1[si]
 inc ax
 mov es:0[si],ax

 call setcursor16

 call refresh

 call displaypalette

 call displaymenu

nn04:
 call ProcessMenu
 cmp al,'N'
 jz again

terminate:
 mov ah,76 ;Terminate
 int 21h ;Terminate program
 jmp short terminate

error:
 db "Out of memory",10,10,0

;-----

cursorcr:
cursorup:
cursordown:
drawM13line:
mode13transferrow:
initrecall:
lsttbl:
MCContinue:
ramload:
ramsave:
start:
 ret

;31/8/88. I should allow an option to toggle the value of ModuleName
;So that the editor can switch between normal pictures and Title screens

ModuleName db 0 ;0=AINT, 1=MENU. (0=normal pic, 1=loading pic)

;-----

;Input:
;   es:si address
;   ds:bx name
;   dx,cx max length

;Return code:
;   al=0, ok
;   al=1, missing
;   al=2, other error (e.g. read error)

GeneralLoadFile proc near

 push cx                    ;Length
 push dx
 push es                    ;Load address
 push si

 mov dx,bx                  ;filename
 mov al,0                   ;non-private/compatable/read-only
 mov ah,61                  ;Open file
 int 21h                    ;extended DOS function

 jnc le01                   ;file exists

 pop si                     ;correct stack
 pop es
 pop dx
 pop cx

 mov al,1                   ;File not found
 ret

le01:
 push ax                    ;File handle

 mov bx,ax
 mov al,0                   ;relative to start of file
 mov cx,0                   ;relative position (high)
 mov dx,0                   ;relative position (low)
 mov ah,66                  ;move file pointer
 int 21h                    ;extended DOS function

 pop ax                     ;file handle
 pop si                     ;Load address
 pop es
 pop dx                     ;Length
 pop cx

le02:
 push ax                    ;File handle
 push ds

 cmp cx,0
 jnz le03                   ;length not a multiple of 64K
 cmp dx,0
 jz le06                    ;length=0, reached limit of number of bytes to load

;set CX as actual number of bytes (1 thru 65535) loaded this time...

 cmp cx,0 ;18/9/89... handle 64k
 je le02a
 cmp cx,8000h
 jc le03                    ;first, make remainder of file a multiple of 32K

le02a:
 push cx                    ;save requested length
 push dx
 mov cx,8000h               ;instead, load 32K bytes
 jmp short le04

le03:                       ;length not a multiple of 64K/32K
 push cx                    ;length
 push dx
le04:

;Load CX bytes

 mov bx,ax                  ;file handle
                            ;cx=length
 mov ax,es
 mov ds,ax
 mov dx,si                  ;address DS:DX
 mov ah,63                  ;Read from file
 int 21h                    ;extended DOS function
 jnc le05

;Error

 pop dx                     ;correct stack
 pop cx
 pop ds
 pop bx                     ;File handle

 mov ah,62                  ;Close file handle
 int 21h                    ;extended DOS function

 mov al,2                   ;read error
 ret

;OK

le05:
 pop dx                     ;length
 pop cx

 cmp ax,0
 jz le06                    ;Reached EOF before 'max length'
 
 sub cx,ax                  ;Number of bytes loaded
 jnc le05a
 dec cx
le05a:
 pop ds
 pop ax                     ;File handle
 jmp short le02

;End of file

le06:
 pop ds
 pop bx                     ;File handle

 mov ah,62                  ;Close file handle
 int 21h                    ;extended DOS function

 mov al,0                   ;OK!
 ret

GeneralLoadFile endp

;-----

;Input:
;   es:si address
;   ds:bx name
;   dx,cx length

;Return code:
;   al=0, ok
;   al=1, can't create
;   al=2, other error (e.g. read/write error)

GeneralSaveFile proc near

 push cx                    ;Length
 push dx
 push es                    ;Load address
 push si

 mov dx,bx                  ;filename
 mov cl,0                   ;File attribute
 mov ah,60                  ;Create file
 int 21h                    ;extended DOS function

 jnc se01                   ;Create OK

 pop si                     ;correct stack
 pop es
 pop dx
 pop cx

 mov al,1                   ;Can't create
 ret

se01:
 pop si                     ;Load address
 pop es
 pop dx                     ;Length
 pop cx

se02:
 push ax                    ;File handle
 push ds

 cmp cx,0
 jnz se03                   ;length not a multiple of 64K
 cmp dx,0
 jz se06                    ;length=0, saved all

;set CX as actual number of bytes (1 thru 65535) to save this this time...

 cmp cx,8000h
 jc se03                    ;Make length 32K

 push cx                    ;save requested length
 push dx
 mov cx,8000h               ;instead, load 32K bytes
 jmp short se04

se03:                       ;length not a multiple of 64K/32K
 push cx                    ;length
 push dx
se04:

;Load CX bytes

 mov bx,ax                  ;file handle
                            ;cx=length
 mov ax,es
 mov ds,ax
 mov dx,si                  ;address DS:DX
 mov ah,64                  ;Write to file
 int 21h                    ;extended DOS function
 jnc se05

;Error

se04b:
 pop dx                     ;correct stack
 pop cx
 pop ds
 pop bx                     ;File handle

 mov ah,62                  ;Close file handle
 int 21h                    ;extended DOS function

 mov al,2                   ;Write error
 ret

;OK

se05:
 pop dx                     ;length
 pop cx

 cmp ax,0
 jz se04b                   ;Did not write anything
 
 sub cx,ax                  ;Number of bytes written
 jnc se05a
 dec cx
se05a:
 pop ds
 pop ax                     ;File handle
 jmp short se02

;ALl data written

se06:
 pop ds
 pop bx                     ;File handle

 mov ah,62                  ;Close file handle
 int 21h                    ;extended DOS function

 mov al,0                   ;OK!
 ret

GeneralSaveFile endp

;-----

;Load a file, maximum length CX, name in DX, to address ES:0
;Returns AL=0 if OK (cx=bytes loaded)
;        AL=1 if file not found
;        AL=3 if file can't load

LoadUpFile:
 ret

;-----

clearscreen:
 mov es,cs:[MenuPgraphicsbuffer]
 mov bx,cs:[MenuLgraphicsbuffer]
cs01:
 cmp bx,0
 jz cs02
 dec bx
 mov byte ptr es:[bx],0
 jmp short cs01
cs02:
 ret

;-----

highlight db 0
attribute db 15

;-----

displaymenu:
 call setcursor17
 mov di,offset messagemenu
 jmp directprs

messagemenu:
 db "left/right ... select ST colour."
 db 13,10
 db "up/down ...... select IBM colour."
 db 13,10
 db "7 8 9/R G B .. increase level."
 db 13,10
 db "1 2 3/T H N .. decrease level."
 db 13,10
 db "F ............ Toggle 136/Title screen"
 db 13,10
 db "A .. text colour.  M .. re-map display."
 db 13,10
 db "S ......... save.  X ........... abort."
 db 0

;-----

em01:
 db "Compressed palette:"
 db 0

em02:
 db "Colour "
 db 0

em03:
 db " Value "
 db 0

invertcurrent: ;ah 0=off/1=on.
 mov bl,[adjustSTcolour] ;Find current logical colour in file to adjust
 mov bh,0
 mov cl,colourtable[bx] ;convert to IBM colour value

cc01:
 push bx
 push ax
 mov bl,bh
 mov bh,0
 mov si,bx
 mov ah,newpalette[si] ;scan displayed colour number 'ax'
 cmp ah,cl ;is this the colour requested by disk file.
 jnz cc02
 pop ax
 pop bx

 push bx
 push ax ;get ah=on/off highlight
 mov al,bh
 call highlightcolour

cc02: 
 pop ax
 pop bx

 inc bh
 cmp bh,16
 jnz cc01
 ret

;-----

displaycurrent:
 mov ah,1
 call invertcurrent

 mov ah,2 ;Set Cursor Position
 mov dh,row16
 mov dl,column30
 mov bh,0
 int 10h ;Video Service
 mov di,offset em02
 call directprs
 mov al,[adjustSTcolour]
 cmp al,10
 jb dc01
 sub al,10
 push ax
 mov al,'1'
 call directoutput
 pop ax
 jmp short dc02
dc01:
 push ax
 mov al,' '
 call directoutput
 pop ax
dc02:
 add al,'0'
 call directoutput
 mov di,offset em03
 call directprs
 call findcompressedcolour ;Get original ST colour
 and bh,7
 add bh,'0'
 mov al,bh
 push bx
 call directoutput
 pop bx
 mov al,bl
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,7
 add al,'0'
 push bx
 call directoutput
 pop bx
 mov al,bl
 and al,7
 add al,'0'
 call directoutput
 ret

;-----

removehighlight:
 mov ah,0
 jmp invertcurrent

;-----

ProcessMenu:
 mov [adjustSTcolour],0 ;Colour (before merge) to adjust
 mov [adjustIBMcolour],0 ;Colour (after merge) to adjust

ac01:
 mov ah,2 ;Set Cursor Position
 mov dh,row15
 mov dl,column30
 mov bh,0
 int 10h ;Video Service
 mov di,offset em01
 call directprs

 call displaycurrent
ac02:
 call waitforkey

 cmp ax,04B00h ;cursor left
 jnz notleft
 call removehighlight
 cmp [adjustSTcolour],0
 jz ac03
 dec [adjustSTcolour]
 jmp short ac01 ;new colour
ac03:
 mov [adjustSTcolour],15
 jmp short ac01 ;new colour

notleft:
 cmp ax,04D00h ;cursor right
 jnz notright
 call removehighlight
 cmp [adjustSTcolour],15
 jae ac04
 inc [adjustSTcolour]
 jmp short ac01 ;new colour
ac04:
 mov [adjustSTcolour],0
 jmp short ac01 ;new colour

notright:
 cmp ax,04800h ;cursor up
 jnz notup
 call removehighlight
nr01:
 cmp [adjustIBMcolour],0
 jnz short nr03
 mov [adjustIBMcolour],16
nr03:
 dec [adjustIBMcolour]
 mov cl,16
nr04:
 mov bh,0
 mov bl,byte ptr [adjustSTcolour]
 mov al,byte ptr mappingtable[bx]
 and al,0Fh
 cmp al,byte ptr [adjustIBMcolour]
 jz nr06
 dec byte ptr [adjustSTcolour]
 cmp byte ptr [adjustSTcolour],0FFh
 jnz nr05
 mov byte ptr [adjustSTcolour],15
nr05:
 dec cl
 cmp cl,0
 jnz nr04
 jmp short nr01
nr06:
 jmp ac01 ;new colour

notup:
 cmp ax,05000h ;cursor down
 jnz notdown
 call removehighlight
nu01:
 cmp [adjustIBMcolour],15
 jnz short nu02
 mov [adjustIBMcolour],0
 jmp short nu03
nu02:
 inc [adjustIBMcolour]
nu03:
 mov cl,16
nu04:
 mov bh,0
 mov bl,byte ptr [adjustSTcolour]
 mov al,byte ptr mappingtable[bx]
 and al,0Fh
 cmp al,byte ptr [adjustIBMcolour]
 jz nu06
 inc byte ptr [adjustSTcolour]
 cmp byte ptr [adjustSTcolour],16
 jnz nu05
 mov byte ptr [adjustSTcolour],0
nu05:
 dec cl
 cmp cl,0
 jnz nu04
 jmp short nu01
nu06:
 jmp ac01 ;new colour

notdown:
 cmp al,'A'
 jb NotAscii
 and al,0DFh ;Convert to upper case
NotAscii:

 cmp al,'A' ;'Attribute' step logical text colour
 jnz nota
 inc cs:attribute
 cmp cs:attribute,16
 jb Newatt
 mov cs:attribute,0
NewAtt:
 jmp ac01

nota:
 cmp al,'M' ;'Remap' refresh screen
 jnz notm
remap:
 mov ah,0 ;Set Video Mode
 mov al,16
 int 10h ;Video Service
 call displaymenu
 call setcursor15
 mov di,offset messagefilename
 call directprs
 mov si,offset inputbuffer+1 ;file name
 mov cl,8
nk01:
 mov al,[si]
 cmp al,' '
 jbe nk02
 call directoutput
 inc si
 dec cl
 jmp short nk01
nk02:
nk04:
 call refresh
 call displaypalette
 call displaycurrent
 jmp ac01

notm:
 cmp al,'S'
 jnz notsave
 call savepictureout
 jmp ac02

notsave:
 cmp al,3
 jz quit
 cmp al,'X'
 jnz notagain
quit:
 mov di,offset ns01
 call askquestion
 cmp al,'N'
 jz jmp1ac02
;Drop out of menu with al='N' to cause re-entry
 mov ah,0 ;Set Video Mode
 mov al,16
 int 10h ;Video Service
 mov al,'N'
 ret
ns01:
 db "Abandon pic (Y/N) ? _"
 db 0

jmp1ac02:
 jmp ac02

notagain:
 cmp al,'F'
 jnz notF
 mov al,ds:ModuleName
 and al,al
 jz FlipTitle
 mov ds:ModuleName,0
 jmp short FlipNormal
FlipTitle:
 mov ds:ModuleName,1
FlipNormal:
 jmp remap

notF:
 cmp al,'7' ;keypad
 je KeyF
 cmp al,'R'
 jnz notr
KeyF:
 call findcompressedcolour
 mov al,bh
 and al,06h
 cmp al,6
 jae jmp1ac02 ;red near maximum
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 and bh,06h
 add bh,02h ;increase red
 call setcompressedcolour
 jmp ac01

notr:
 cmp al,'8' ;keypad
 je KeyG
 cmp al,'G'
 jnz notg
KeyG:
 call findcompressedcolour
 mov al,bl
 and al,60h
 cmp al,60h
 jae jmp1ac02 ;green near maximum
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 mov al,bl
 and al,60h
 cmp al,60h
 add al,20h ;increase green
 and bl,07h
 or bl,al
 call setcompressedcolour
 jmp ac01

notg:
 cmp al,'9' ;keypad
 je KeyB
 cmp al,'B'
 jnz notb
KeyB:
 call findcompressedcolour
 mov al,bl
 and al,06h
 cmp al,6
 jb ng01
 jmp ac02 ;blue near maximum
ng01:
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 mov al,bl
 and al,06h
 add al,02h ;increase blue
 and bl,70h
 or bl,al
 call setcompressedcolour
 jmp ac01

notb:
 cmp al,'1' ;keypad
 je KeyT
 cmp al,'T'
 jnz nott
KeyT:
 call findcompressedcolour
 cmp bh,02
 jb jmp2ac02 ;near near minumum
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 and bh,06h
 sub bh,02h ;decrease red
 call setcompressedcolour
 jmp ac01

nott:
 cmp al,'2' ;keypad
 je KeyH
 cmp al,'H'
 jnz noth
KeyH:
 call findcompressedcolour
 mov al,bl
 and al,60h
 cmp al,20h
 jb jmp2ac02 ;green near minimum
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 mov al,bl
 and al,60h
 sub al,20h ;decrease green
 and bl,07h
 or bl,al
 call setcompressedcolour
 jmp ac01

noth:
 cmp al,'3' ;keypad
 je KeyN
 cmp al,'N'
 jnz notn
KeyN:
 call findcompressedcolour
 mov al,bl
 and al,06h
 cmp al,02
 jb jmp2ac02 ;blue near minimum
 call removehighlight
 call findcompressedcolour
;al=logical, bx=value (0-2047)
 mov al,bl
 and al,06h
 sub al,02h ;decrease blue
 and bl,70h
 or bl,al
 call setcompressedcolour
 jmp ac01

notn:
 mov cs:16[newpalette],15 ;Invalid key, so flash border.
 call setcolours
 mov cs:16[newpalette],0
 call setcolours
jmp2ac02:
 jmp ac02 ;Invalid key

;-----

askquestion:
 push di ;Question to ask
 mov ah,2 ;Set Cursor Position
 mov dh,row20
 mov dl,column30
 mov bh,0
 int 10h ;Video Service
 pop di ;display question
 call directprs
aq01:
 call waitforkey
 and al,0DFh
 cmp al,'N'
 jz aq02
 cmp al,3
 jz aq02
 cmp al,'Y'
 jnz aq01
aq02:
 push ax ;Save key value
 mov ah,2 ;Set Cursor Position
 mov dh,row20
 mov dl,column30
 mov bh,0
 int 10h ;Video Service
 mov di,offset aq05 ;remove question
 call directprs
 pop ax ;Return key value
 ret
aq05: db "                       "
 db 0 

;-----

findcompressedcolour:
 mov al,[adjustSTcolour]
 mov bl,al
 mov bh,0
 add bx,bx
 mov si,bx
 mov es,cs:[MenuPcache]
 mov bh,es:palette+0[si]
 mov bl,es:palette+1[si]
 ret ;al=logical, bx=value (0-2047)

;-----

setcompressedcolour:
;al=logical, bx=value (0-2047)
 mov al,[adjustSTcolour]
 mov ah,0
 push ax

 add al,al
 mov si,ax
 mov es,cs:[MenuPcache]
 mov es:palette+0[si],bh
 mov es:palette+1[si],bl

 mov si,0 ;Picture as (es:si)
 call STtoIBM ;Keep existing mapping, do ST to IBM colour conversion
 pop ax
 mov si,ax
 mov al,colourtable[si] ;Get converted IBM colour
 mov bl,mappingtable[si] ;Get IBM palette number
 and bl,0Fh
 mov bh,0
 mov si,bx
 mov newpalette[si],al
 call setcolours
 ret

;-----

waitforkey:
; mov ah,01 ;Service 1 (Report keyboard)
; int 16h ;ROM-BIOD keyboard service
; jz waitforkey

 mov ah,00h ;Service 0 (Read Next Keyboard Character)
 int 16h ;ROM-BIOS keyboard service
 ret

;-----

adjustSTcolour db 0
adjustIBMcolour db 0

;-----

cpnrst = 13;Reset disk system
cpnof = 15 ;Open File
cpncf = 16 ;Close File
cpnrs = 20 ;Read Sequential
cpnws = 21 ;Write Sequential
cpnmf = 22 ;Create file

;Ascii/BBC control codes:
asciibs = 08h
asciilf = 0Ah
asciicls= 0Ch
asciicr = 0Dh
asciiesc= 1Bh
asciidel=07Fh
space = ' '

;-----

messagefilename:
 db "Picture ? "
 db 0

;Return codes:
;   al = 0 ok
;   al = 1 Invalid file id
;   al = 2 Null input

askfilename:
 call inputline
 call examinename
; jb short af01
; cmp byte ptr ds:[fcbname],space
; jz short af02
; mov bx,offset advfiletype
; call inserttype
; xor al,al ;Ok
; ret
;af01:
; mov al,1 ;Invalid name
; ret
;af02:
; mov al,2 ;Null input
 ret

;-----

inputline:
; RETURN IN (IY+1)
 mov bx,offset inputbuffer
 mov ch,0 ;Number of chars
inpl1:
 push bx
 push dx
 push cx

 mov al,05Fh ;Cursor (underline character)
 call directoutput

 call waitforkey
 cmp al,3
 jnz inpl1a
 jmp terminate

inpl1a:
 push ax
 mov al,asciibs
 call directoutput
 mov al," "
 call directoutput
 mov al,asciibs
 call directoutput
 pop ax

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
 cmp al,inputbuffersize
 jnz short inpl9
 jmp short inpl1
inpl9:
 mov al,cl
 call directoutput
 inc bx
 inc ch
 mov al,cl
 mov [bx],al
 jmp short inpl1
inplend:
 inc bx
 mov byte ptr [bx],space
 inc bx
 mov byte ptr [bx],0
 mov al,asciicr
 call directoutput
 mov al,space
 mov byte ptr [inputbuffer],al
 ret

;-----

advfiletype:
 db 'PIC'

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

;Prompt user for a file-name which
; is returned in the system FCB.
;Returned condition 'C' indicates an invalid file name
; (too long, invalid character, bad separators.)
;(FCBNAME)=' ' if nothing is entered.
;(FCBTYPE)=' ' if no file type entered.
;Most registers corrupted.
examinename:
 mov bx,offset inputbuffer+1
 mov al,[bx]
 cmp al,' '
 jne en01
 mov al,2 ;null filename
 ret

en01:
 mov al,ds:[bx]
 cmp al,' '
 jbe Noextension
 cmp al,'.'
 je gotextension
 inc bx
 jmp short en01

NoExtension:
 mov ds:0[bx],'P.' ;put in '.PIC'
 mov ds:2[bx],'CI'
 mov byte ptr ds:4[bx],0
 mov bx,offset inputbuffer+1
 mov al,0 ;path name OK
 ret

gotextension:
 mov cx,4
en02:
 mov al,ds:[bx]
 cmp al,' '
 jbe foundend
 inc bx
 loop en02
foundend:
 mov byte ptr ds:[bx],0
 mov bx,offset inputbuffer+1
 mov al,0 ;path name OK
 ret

;-----

upper:
 cmp al,'a'
 jnb short dbi041
 ret
dbi041:
 cmp al,'z'+1
 jb short dbi042
 ret
dbi042:
 add al,'A'-'a'
 ret

;-----

messagenullerror:
 db "          "
 db "          "
 db "          "
 db "          "
 db "          "
 db "          " ;Erase any error message
 db 0

;-----

set12cursor15:
 mov dl,12
 jmp short s15
setcursor15:
 mov dl,0
s15:
 mov ah,2 ;Set Cursor Position
 mov dh,row15
 mov bh,column0
 int 10h ;Video Service
 ret

set12cursor16:
 mov dl,12
 jmp short s16
setcursor16:
 mov dl,0
s16:
 mov ah,2 ;Set Cursor Position
 mov dh,row16
 mov bh,column0
 int 10h ;Video Service
 ret

;-----

loadpicturein:
 call setcursor15
 mov di,offset messagenullerror
 call directprs

 call setcursor15
 mov di,offset messagefilename
 call directprs

 call askfilename
 push ax
 call setcursor16
 mov di,offset messagenullerror
 call directprs
 pop ax
 cmp al,1
 jz short lp00
 cmp al,2
 jnz short lp01
 jmp terminate

messagebadfilename:
 db "Invalid file name"
 db 0

lp00:
 call setcursor16
 mov di,offset messagebadfilename
 call directprs
 jmp short loadpicturein

lp01:
 mov es,cs:[MenuPcache]
 mov si,0                    ; es:si address
 mov bx,offset inputbuffer+1 ; ds:bx filename
 mov cx,0                    ; dx,cx = 00010000h 64K max
 mov dx,1
 call GeneralLoadFile
 cmp al,0
 jnz osload2
 ret

messagenotfound:
 db "File not found"
 db 0

osload2:
 call setcursor16

 mov di,offset messagenotfound
 call directprs
 jmp loadpicturein

;-----

setcursor17:
 mov ah,2 ;Set Cursor Position
 mov dh,row17
 mov dl,column0
 mov bh,0
 int 10h ;Video Service
 ret

;-----

savepictureout:
sp02:
 mov es,cs:[MenuPcache]
 call setchecksum
 mov si,0
 mov cx,es:0[si]       ; Lo file length
 mov ax,es:0[si]
 dec ax
 mov es:0[si],ah
 mov es:1[si],al

 mov es,cs:[MenuPcache]
 mov si,0                    ; es:si address
 mov bx,offset inputbuffer+1 ; ds:bx file name
 mov dx,0                    ; Hi length
 call GeneralSaveFile
 cmp al,0
 jz finished

 mov ah,2 ;Set Cursor Position
 mov dh,row20
 mov dl,column30
 mov bh,0
 int 10h ;Video Service
 mov di,offset messagewriteerror
 call directprs
 ret

messagewriteerror:
 db "Error creating file"
 db 0

savingfile:
; mov es,cs:[MenuPcache]
; call setchecksum

; mov si,0
; mov cx,es:0[si] ;file length
; mov ax,es:0[si]
; dec ax
; mov es:0[si],ah
; mov es:1[si],al

; mov si,0 ;Save address within ES

;writefile:
; mov ax,si ;current save address
; sub ax,cx
; jnc short finished

; push cx ;Length od file
; mov di,offset diskbuffer
; mov cx,128 ;Disk buffer size
;copysector:
; jcxz short writesector
; mov al,byte ptr es:0[si]
; mov byte ptr 0[di],al
; inc si
; inc di
; dec cx
; jmp short copysector
;writesector:

; mov dx,offset sysfcb
; mov ah,cpnws
; int 21h
; pop cx ;Length of file
; cmp al,0
; jnz short sp03
; jmp short writefile

;messagediskfull:
; db "Disk full"
; db 0

;sp03:
; mov ah,2 ;Set Cursor Position
; mov dh,row20
; mov dl,column30
; mov bh,0
; int 10h ;Video Service
; mov di,offset messagediskfull
; call directprs
; mov dx,offset sysfcb
; mov ah,cpncf
; int 21h
; ret

finished:
; mov dx,offset sysfcb
; mov ah,cpncf
; int 21h

;Put back checksum:
 mov si,0
 mov ah,es:0[si]
 mov al,es:1[si]
 inc ax
 mov es:0[si],ax

 ret ;Normal exit

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
 cmp al,' '
 jae do01

 mov dl,al
 mov ah,2 ;Universal Function 2 - Display Output
 int 21h ;Universial Function
 ret

do01:
 push ax
 push bx
 push cx
 push dx

 mov bh,0 ;page
 mov bl,cs:attribute 
 mov cx,1 ;count
 mov ah,10 ;Write character
 int 10h ;ROM-BIOS video service

 mov ah,3 ;Read Cursor Position
 mov bh,0
 int 10h ;Video Service
 inc dl

 mov ah,2 ;Set Cursor Position
 mov bh,0
 int 10h ;Video Service

 pop dx
 pop cx
 pop bx
 pop ax
 ret

;-----

setcolours:
 push cs
 pop es
 mov ah,10h
 mov al,2
 mov dx,offset newpalette ;Merged colour map
 int 10h ;Video Service
 ret

;-----

;Redraw entire picture window from copy of disk file.

setchecksum:
 mov es,cs:[MenuPcache]

;Set checksum:

 mov si,0
 mov bx,es:0[si] ;lo-hi (reversed by cache loader)
 sub bx,3 ;Exclude length and checksum bytes
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
 mov es:[si],al ;write new checksum
 ret

;-----

refresh:
 call setchecksum

 mov byte ptr cs:0[MenuFpalette],0 ;Black
 mov byte ptr cs:1[MenuFpalette],99 ;Default palette
 mov byte ptr cs:2[MenuFpalette],99 ;Default palette
 mov byte ptr cs:3[MenuFpalette],99 ;Default palette
 mov byte ptr cs:4[MenuFpalette],99 ;Default palette
 mov byte ptr cs:5[MenuFpalette],99 ;Default palette
 mov byte ptr cs:6[MenuFpalette],99 ;Default palette
 mov byte ptr cs:7[MenuFpalette],7 ;White
 mov byte ptr cs:8[MenuFpalette],99 ;Default palette
 mov byte ptr cs:9[MenuFpalette],99 ;Default palette
 mov byte ptr cs:10[MenuFpalette],99 ;Default palette
 mov byte ptr cs:11[MenuFpalette],99 ;Default palette
 mov byte ptr cs:12[MenuFpalette],99 ;Default palette
 mov byte ptr cs:13[MenuFpalette],99 ;Default palette
 mov byte ptr cs:14[MenuFpalette],99 ;Default palette
 mov byte ptr cs:15[MenuFpalette],99 ;Default palette

 call clearscreen
 mov word ptr cs:[MenuFpicturetype],0 ;Force real screen to be cleared

 mov ds:[taskaddress],0
 call drawentirepicture
 ret

;-----

dp00:
 db "IBM palette:"
 db 0

displaypalette:
;al = logical colour
;bh = Cursor row
;bl = Cursor column
;dx = Pixel row
;cx = Pixel start column

 mov ah,2 ;Set Cursor Position
 mov dh,row15
 mov dl,column63
 mov bh,0
 int 10h ;Video Service
 mov di,offset dp00
 call directprs

 mov al,0
 mov bh,row16
 mov bl,column63
 mov cx,column524
 mov dx,row226
dp01:
 push ax
 push bx
 push cx
 push dx
 call paletteentry
 pop dx
 pop cx
 pop bx
 pop ax
 inc al
 inc bh
 add dx,14
 cmp al,8
 jnz dp01

 mov al,8
 mov bh,row16
 mov bl,column73
 mov dx,row226
 mov cx,column604
dp02:
 push ax
 push bx
 push cx
 push dx
 call paletteentry
 pop dx
 pop cx
 pop bx
 pop ax
 inc al
 inc bh
 add dx,14
 cmp al,16
 jnz dp02

 ret

;-----

;al = logical colour
;bh = Cursor row
;bl = Cursor column
;dx = Pixel row
;cx = Pixel start column

paletteentry:
 push ax
 push bx
 push cx
 push dx

 push ax
 mov ah,2 ;Set Cursor Position
 mov dh,bh ;row
 mov dl,bl ;column
 mov bh,0 ;page
 int 10h ;Video Service
 pop ax
 cmp al,10 ;Values 10-15 are two-digit
 jb pe01

 push ax
 mov al,'1'
 call directoutput
 pop ax
 sub al,10
pe01:
 add al,'0'
 call directoutput

 pop dx
 pop cx
 pop bx
 pop ax

;Now print block of one logical colour

 push ax
 push bx
 push cx
 push dx

 mov bh,10 ;Number of lines
pe02:
 cmp bh,0
 jz pe05
 mov bl,10 ;Number of columns
pe03:
 cmp bl,0
 jz pe04

 push ax
 push bx
 mov ah,0Ch ;Write pixel point
 mov bx,0 ;page/screen 0
 int 10h ;Video Service
 pop bx
 pop ax

 inc cx
 dec bl
 jmp short pe03
pe04:
 dec bh
 inc dx
 sub cx,10 ;reset column
 jmp short pe02

pe05:
 pop dx
 pop cx
 pop bx
 pop ax
 ret

;-----

highlightcolour: ;al = logical colour, ah=0 remove/1 add
 mov [highlight],ah
 cmp al,8
 jae dn01

 mov bh,row16
 add bh,al ;row
 mov bl,column63 ;left column
 jmp short dn02

dn01:
 mov bh,row16-8
 add bh,al ;row
 mov bl,column73 ;right column

dn02:
 push ax
 push bx

 push ax
 push bx
 mov ah,2 ;Set Cursor Position
 mov dh,bh ;row
 mov dl,bl ;column
 mov bh,0 ;page
 int 10h ;Video Service
 mov al,219 ;all-foreground character
 mov ah,14 ;write character as TTY
 cmp [highlight],0
 jz dn03
 mov bl,7 ;(white)
 jmp short dn04
dn03:
 mov bl,0 ;(black)
dn04:
 mov bh,0 ;turn off screen switching
 int 10h
 pop bx
 push bx
 mov ah,2 ;Set Cursor Position
 mov dh,bh ;row
 mov dl,bl ;column
 inc dl
 mov bh,0 ;page
 int 10h ;Video Service
 mov al,219 ;all-foreground character
 mov ah,14 ;write character as TTY
 cmp [highlight],0
 jz dn05
 mov bl,7 ;(white)
 jmp short dn06
dn05:
 mov bl,0 ;(black)
dn06:
 mov bh,0 ;turn off screen switching
 int 10h
 pop bx
dn07:
 mov ah,2 ;Set Cursor Position
 mov dh,bh ;row
 mov dl,bl ;column
 mov bh,0 ;page
 int 10h ;Video Service
 pop ax
 cmp al,10 ;Values 10-15 are two-digit
 jb dn08

 push ax
 mov al,'1'
 call invertcharacter
 pop ax
 sub al,10
dn08:
 add al,'0'
 call invertcharacter

 pop bx
 pop ax
 ret

invertcharacter:
 mov ah,14 ;write character as TTY
 cmp [highlight],0
 jz ic01
 mov bl,128+7 ;Invert existing colour
 jmp short ic02
ic01:
 mov bl,7 ;(white)
ic02:
 mov bh,0 ;turn off screen switching
 int 10h
 ret

;-----

inputbuffersize = 15
inputbuffer db inputbuffersize dup (0)

;Disk DMA buffer
diskbuffer db 128 dup(0) ;Disk I/O buffer

code ends

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





