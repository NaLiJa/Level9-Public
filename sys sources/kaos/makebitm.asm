;IBM KAOS uncompressed-picture bit-mapper.

;MAKEBITM.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

 include head.asm

offsetX = 0
offsetY = 0

;-----

name makebitm

code segment public 'code'
 assume cs:code,ds:code

 push cs
 pop ds

 mov ah,0 ;Set Video Mode
 mov al,16
 INT 10h ;Video Service

 MOV DX,offset diskbuffer
 MOV AH,01Ah ;Set Disk Transfer Area
 INT 21H ;ROM-BIOS DOS Functions

 jmp short skip

outofmemory:
 mov di,offset error
 call directprs
 jmp terminate

skip:
;Allocate 64k byte paragraph for picture "in" workspace:

 MOV BX,4096
 MOV AH,48H ;Allocate memory
 INT 21h ;ROM-BIOS DOS Functions
 CMP AX,8
 je short outofmemory
 mov word ptr ds:[pictureparain],ax ;Save paragraph start address...

;Allocate 64k byte paragraph for picture "out" workspace:

 MOV BX,4096
 MOV AH,48H ;Allocate memory
 INT 21h ;ROM-BIOS DOS Functions
 CMP AX,8
 je short outofmemory
 mov word ptr ds:[pictureparaout],ax ;Save paragraph start address...

 call loadpicturein

 call setcursor16

 mov di,offset messagereprocess
 call directprs
 call getyesno
 cmp al,"y"
 jnz short nn02

 mov es,word ptr ds:[pictureparain]
 mov word ptr ds:[pictureparaout],es
 jmp nn03

;Set 

nn02:
 mov es,ds:[pictureparain]
 mov bh,byte ptr es:[0022h]
 mov bl,byte ptr es:[0022h+1]
 add bx,bx
 add bx,bx
 mov ch,byte ptr es:[0026h]
 mov cl,byte ptr es:[0026h+1]
 mov es,ds:[pictureparaout]
 mov word ptr es:[BitmapPicWidth],bx
 mov word ptr es:[BitmapPicHeight],cx

;Copy and transform colour table

;ST colours are:
;    xxxxxRRRxBBBxGGG
;IBM colours are:
;    xxGRBGRB

 mov si,0 ;At start of ST picture file
 mov di,offset BitmapPicColours ;Offset into IBM file
 mov cx,16 ;Number of colours
cc01:
 cmp cx,0
 jnz short cc01a
 jmp short cc02
cc01a:

 mov es,word ptr ds:[pictureparain]

 mov al,es:[si]
 shr al,1
 shr al,1
 and al,1
 add al,al
 add al,al ;Red (high order bit)

 mov ah,al
 mov al,es:[si]
 shr al,1
 and al,1
 add al,al
 add al,al
 add al,al
 add al,al
 add al,al ;Red (low order bit)

 or ah,al
 inc si
 mov al,es:[si]
 shr al,1
 shr al,1
 and al,1 ;Blue (high order bit)

 or ah,al
 mov al,es:[si]
 shr al,1
 and al,1
 add al,al
 add al,al
 add al,al ;Blue (low order bit)

 or ah,al
 mov al,es:[si]
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,1 
 add al,al ;Green (high order bit)

 or ah,al
 mov al,es:[si]
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,1
 add al,al
 add al,al
 add al,al
 add al,al ;Green (Low order bit)

 or ah,al

 mov es,word ptr ds:[pictureparaout]
 mov es:[di],ah
 inc si
 inc di
 dec cx
 jmp cc01

cc02:
 mov es,ds:[pictureparaout]
 mov byte ptr es:[BitmapPicBackground],0

 mov di,BitmapPicData
 mov si,02Ch
 mov ax,word ptr es:[BitmapPicWidth]
 mul word ptr es:[BitmapPicHeight]
 inc ax
 shr ax,1
 mov cx,ax

copypicture:
 jcxz short copyend

 push cx ;Length count

 mov es,ds:word ptr [pictureparain]
 mov bh,byte ptr es:1[SI]
 mov bl,byte ptr es:3[SI]
 mov ch,byte ptr es:5[SI]
 mov cl,byte ptr es:7[SI]
 call transform
 mov es,ds:word ptr [pictureparaout]
 mov byte ptr es:4[DI],bh
 mov byte ptr es:5[DI],bl
 mov byte ptr es:6[DI],ch
 mov byte ptr es:7[DI],cl
 mov es,ds:word ptr [pictureparain]
 mov bh,byte ptr es:0[SI]
 mov bl,byte ptr es:2[SI]
 mov ch,byte ptr es:4[SI]
 mov cl,byte ptr es:6[SI]
 call transform
 mov es,ds:word ptr [pictureparaout]
 mov byte ptr es:0[DI],bh
 mov byte ptr es:1[DI],bl
 mov byte ptr es:2[DI],ch
 mov byte ptr es:3[DI],cl

 pop cx ;Length count

 add si,8
 add di,8
 sub cx,8
 jnc short copypicture
copyend:

 mov es,ds:[pictureparaout]
 mov word ptr es:[BitmapPicLength],di ;Store length

nn03:
 call displayentirepicture

nn04:
 call reducewidth

 call swapcolours

 call joincolours

 call forcecolours

 call adjustcolours

 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor17
 mov di,offset messageprocessagain
 call directprs
 call getyesno
 cmp al,"y"
 jz short nn04

 call savepictureout

 call setcursor17
 mov di,offset messagefinished
 call directprs

terminate:
 mov ah,76 ;Terminate
 int 21h ;Terminate program
 jmp short terminate

messageprocessagain:
 DB "Repeat options (Y/N)? "
 DB 0

messagefinished:
 DB "Finished",13,10,0

error:
 DB "Out of memory",10,10,0

;-----

transform:
 call transformbyte
 mov dh,al
 call transformbyte
 mov dl,al
 call transformbyte
 mov ah,al
 call transformbyte
 mov bx,dx
 mov cx,ax
 ret

messagereprocess:
 DB "Already IBM bit map (Y/N)? "
 DB 0


transformbyte:
 mov al,0
 call transformnybble
 add al,al
 add al,al
 add al,al
 add al,al
 call transformnybble
 ret

transformnybble:
 test bh,080h
 jz short notbit0
 or al,0001h
notbit0:
 test ch,080h
 jz short notbit1
 or al,0004h
notbit1:
 test bl,080h
 jz short notbit2a
 or al,0002h
notbit2a:
 test cl,080h
 jz short notbit3a
 or al,0008
notbit3a:
 add bh,bh
 add bl,bl
 add ch,ch
 add cl,cl
 ret

;-----

messageaskforce:
 DB "Force colour 0/7 for text/border colours (Y/N)? "
 DB 0

forcecolours:
 call setcursor16
 mov di,offset messagenullerror
 call directprs

 call setcursor16
 mov di,offset messageaskforce
 call directprs

 call getyesno
 cmp al,"y"
 jnz short fc01
 mov es,word ptr ds:[pictureparaout]
 mov al,0 ;Black
 mov byte ptr es:0[BitmapPicColours],al
 mov al,007h ;Grey
 mov byte ptr es:textcolour[BitmapPicColours],al
 call setcolours
fc01:
 ret

;-----

getyesno:
 call waitforkey
 or al,020h
 cmp al,"n"
 jz short gy01
 cmp al,13
 jz short gy01
 cmp al,"y"
 jnz short getyesno
 push ax
 mov di,offset messageyes
 jmp short gy02

gy01:
 push ax
 mov di,offset messageno
gy02:
 call directprs
 pop ax
 ret

;-----

reducewidth:
 call setcursor17
 mov di,offset messagenullerror
 call directprs

 call setcursor17
 mov di,offset messagereduce
 call directprs

 call getnumber
 jz rw00
 jmp rw10 ;Nothing entered
rw00:
 mov word ptr [newwidth],cx

 mov es,word ptr [pictureparaout]
 cmp cx,es:[BitmapPicWidth]
 jbe rw00a
 jmp rw10 ;Width too large

rw00a:
 mov di,BitmapPicData
 mov si,BitmapPicData ;Offset into picture file for data
 mov al,1 ;Read high/low nybble
 mov ah,1 ;Write high/low nybble
 mov cx,0 ;Current column
 mov dx,0 ;Current row
rw01:
 cmp dx,es:[BitmapPicHeight] ;Reached last line?
 jnc rw09
 cmp cx,es:[BitmapPicWidth] ;Reached stored width in picture file?
 jnc rw08

 cmp cx,[newwidth] ;Reached new reduced width?
 jnc rw06 ;Data no longer required so skip it

 inc cx
;Copy pixel:
 mov bl,es:[si] ;Read both nybbles
 cmp al,0 ;Reading low nybble?
 jz rw02
 shr bl,1 ;Get high nybble
 shr bl,1
 shr bl,1
 shr bl,1
 mov al,0
 jmp short rw03
rw02: ;Get low nybble
 mov al,1
 inc si
rw03:
 and bl,0Fh ;bl=nybble
 cmp ah,0 ;writing low nybble?
 jz rw04
 mov bh,es:[di] ;Replace high nybble
 add bl,bl
 add bl,bl
 add bl,bl
 add bl,bl
 and bl,0F0h ;New high nybble
 and bh,00Fh ;Old low nybble
 or bh,bl
 mov es:[di],bh
 mov ah,0
 jmp short rw01
rw04:
 mov bh,es:[di] ;Replace low nybble
 and bl,00Fh ;New low nybble
 and bh,0F0h ;Old high nybble
 or bh,bl
 mov es:[di],bh
 mov ah,1
 inc di
 jmp short rw01

rw06:
 inc cx
;Skip pixel:
 cmp al,0 ;At low nybble?
 jz rw07
 mov al,0
 jmp short rw01
rw07:
 mov al,1
 inc si
 jmp short rw01

rw08:
 mov cx,0
 inc dx
 jmp short rw01

rw09:
;Store new width and length:
 mov ax,[newwidth]
 mov es:[BitmapPicWidth],ax
 mov es:[BitmapPicLength],di

;Clear picture window
 mov al,0 ;Blank wondow
 mov bh,0 ;Clear to black
 mov cx,0 ;Top left
 mov dh,14 ;Bottom right
 mov dl,79
 mov ah,06 ;Scroll window up
 INT 10h

 call displayentirepicture

rw10:
 call setcursor17
 mov di,offset messagenullerror
 call directprs

 ret

messagereduce:
 DB "New width (225)? "
 DB 0

newwidth DW 0

;-----

swapcolours:
 call setcursor17
 mov di,offset messagenullerror
 call directprs

 call setcursor17
 mov di,offset messageswap1
 call directprs

 call getnumber
 jnz short sc01
 mov word ptr [swapfrom1],cx
 mov word ptr [swapto2],cx

 call setcursor18
 mov di,offset messagenullerror
 call directprs

 call setcursor18
 mov di,offset messageswap2
 call directprs

 call getnumber
 jnz short sc01
 mov word ptr [swapfrom2],cx
 mov word ptr [swapto1],cx

 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor18
 mov di,offset messagenullerror
 call directprs

 call setcursor18
 mov di,offset messageswap3
 call directprs
 mov bx,word ptr [swapfrom1]
 call displaynumber
 mov di,offset messageswap4
 call directprs
 mov bx,word ptr [swapfrom2]
 call displaynumber

 call rearrangecolours

 call optionalredraw

sc01:
 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor18
 mov di,offset messagenullerror
 call directprs

 ret

messageswap1:
 DB "Swap colour 1 (0-15)? "
 DB 0

messageswap2:
 DB "Swap colour 2 (0-15)? "
 DB 0

messageswap3:
 DB "Swapping "
 DB 0

messageswap4:
 DB " with "
 DB 0

swapto1 DW 0
swapto2 DW 0
swapfrom1 DW 0
swapfrom2 DW 0

;-----

joincolours:
 call setcursor17
 mov di,offset messagenullerror
 call directprs

 call setcursor17
 mov di,offset messagejoin1
 call directprs

 call getnumber
 jnz short jc01
 mov word ptr [swapfrom1],cx
 mov word ptr [swapfrom2],cx

 call setcursor18
 mov di,offset messagenullerror
 call directprs

 call setcursor18
 mov di,offset messagejoin2
 call directprs

 call getnumber
 jnz short jc01
 mov word ptr [swapto1],cx
 mov word ptr [swapto2],cx

 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor18
 mov di,offset messagenullerror
 call directprs

 call setcursor18
 mov di,offset messagejoin3
 call directprs
 mov bx,word ptr [swapfrom1]
 call displaynumber
 mov di,offset messagejoin4
 call directprs
 mov bx,word ptr [swapto1]
 call displaynumber

 call rearrangecolours

 call optionalredraw

jc01:
 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor18
 mov di,offset messagenullerror
 call directprs

 ret

messagejoin1:
 DB "Combine colour (0-15)? "
 DB 0

messagejoin2:
 DB "To colour (0-15)? "
 DB 0

messagejoin3:
 DB "Changing "
 DB 0

messagejoin4:
 DB " to "
 DB 0

;-----

rearrangecolours:
;swap the colour map entries:
 mov ah,0
 mov es,word ptr [pictureparaout]
 mov al,byte ptr [swapfrom1]
 mov si,ax
 mov bl,byte ptr es:BitmapPicColours[si]
 mov al,byte ptr [swapfrom2]
 mov si,ax
 mov bh,byte ptr es:BitmapPicColours[si]
 mov al,byte ptr [swapto1]
 mov si,ax
 mov byte ptr es:BitmapPicColours[si],bl
 mov al,byte ptr [swapto2]
 mov si,ax
 mov byte ptr es:BitmapPicColours[si],bh

 call setcolours
;Swap the colour nybbles:

 call setcolours

 mov si,BitmapPicData ;Offset into picture file for pixel data
 mov cx,0 ;Pixel column
 mov dx,0 ;Pixel row

ra01:
 cmp cx,word ptr es:[BitmapPicWidth] ;reached width of stored picture
 jnz ra02
 jmp ra08

;Process 2 pixels
ra02:
 mov al,byte ptr es:[si] ;Read pixel data
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,0Fh
 cmp al,byte ptr [swapfrom1]
 jnz short ra03
 mov al,byte ptr [swapto1]
 add al,al
 add al,al
 add al,al
 add al,al
 and al,0F0h
 mov ah,byte ptr es:[si]
 and ah,0Fh
 or al,ah
 mov byte ptr es:[si],al
 jmp short ra04
ra03:
 mov al,byte ptr es:[si] ;Read pixel data
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,0Fh
 cmp al,byte ptr [swapfrom2]
 jnz short ra04
 mov al,byte ptr [swapto2]
 add al,al
 add al,al
 add al,al
 add al,al
 and al,0F0h
 mov ah,byte ptr es:[si]
 and ah,0Fh
 or al,ah
 mov byte ptr es:[si],al
ra04:
 mov al,byte ptr es:[si] ;Read pixel data
 and al,0Fh
 cmp al,byte ptr [swapfrom1]
 jnz short ra05
 mov al,byte ptr [swapto1]
 and al,00Fh
 mov ah,byte ptr es:[si]
 and ah,0F0h
 or al,ah
 mov byte ptr es:[si],al
 jmp short ra06
ra05:
 mov al,byte ptr es:[si] ;Read pixel data
 and al,0Fh
 cmp al,byte ptr [swapfrom2]
 jnz short ra06
 mov al,byte ptr [swapto2]
 and al,00Fh
 mov ah,byte ptr es:[si]
 and ah,0F0h
 or al,ah
 mov byte ptr es:[si],al
ra06:

 inc cx
 inc si
 cmp cx,word ptr es:[BitmapPicWidth] ;reached width of stored picture
 jnz short ra07
 mov cx,0
 inc dx
ra07:
 inc cx
 jmp ra01

ra08:
 inc dx
 mov cx,0 ;Left column
 cmp dx,word ptr es:[BitmapPicHeight] ;Height of stored picture
 jz ra09
 jmp ra01

ra09:
 ret

;-----

setcursor20:
 mov ah,2 ;Set Cursor Position
 mov dh,20
 mov dl,0
 mov bh,0
 int 10h ;Video Service
 ret

;-----

;Parse a number, as a string of ascii characters

getnumber:
 call inputline
 mov si,offset inputbuffer+1
gn01:
 mov al,byte ptr [si]
 inc si
 cmp al,' '
 jz short gn01
 dec si
 MOV AL,byte ptr [si] ;Start with digit?
 CMP AL,'0'
 JB short gn03
 CMP AL,'9'+1
 JNB short gn03
 mov word ptr [numericbuffer],0
 MOV BX,si
gn02:
 MOV AL,[BX]
 CMP AL,' '
 JZ short gn04
 CMP AL,0
 JZ short gn04
 SUB AL,'0'
 JB short gn03 ;Contains a non-digit
 CMP AL,10
 JNB short gn03 ;Character > '9'
 MOV CL,AL ;Current 'carry' value
 PUSH BX
 MOV BX,offset NUMERICBUFFER
 call MULT10
 INC BX
 call MULT10
 POP BX
 cmp cl,0
 JNZ short gn03 ;Too big,Return as a garbage word
 INC BX
 JMP short gn02

gn03:
 mov cx,word ptr [numericbuffer]
 mov al,1 ;Invalid
 cmp al,0
 ret

gn04: ;Found a numeric value 0-FFFFFFh in NUMERICBUFFER
 mov cx,word ptr [numericbuffer]
 xor al,al
 cmp al,0
 ret

numericbuffer DW 0

prntblpointer DW 0

;-----

;Do one stage of V = (BX)*10 + C
; Return: (BX) = V MOD 256
;         C = V DIV 256
MULT10:
 MOV AL,[BX]
 PUSH BX
 MOV BL,AL
 MOV BH,0
 ADD BX,BX
 mov dx,bx
 ADD BX,BX
 ADD BX,BX
 ADD BX,DX
 MOV DH,0
 MOV DL,CL
 ADD BX,DX
 XCHG DX,BX
 POP BX
 MOV [BX],DL ;Return V MOD 256
 MOV CL,DH ;Return carry
 RET

;-----

displaynumber: ;Print number BX in decimal
 MOV AL,BH
 OR AL,BL
 JZ short PRNTH3
 MOV CL,0 ;Reset flag
 MOV DX,offset PRNTBL
 MOV word ptr PRNTBLPOINTER,DX
;Find current digit value
PRNTH1:
 PUSH BX
 MOV BX,word ptr PRNTBLPOINTER
 MOV DL,[BX]
 INC BX
 MOV DH,[BX]
 INC BX
 MOV word ptr PRNTBLPOINTER,BX
 POP BX
;Check 5 digits found
 MOV AL,DH
 OR AL,DL
 JNZ short AIN020
 RET
AIN020:
;Find current digit
 MOV CH,'0'
PRNTH2:
 XOR AL,AL
 SBB BX,DX
 JB short PRNTH4
 INC CH
 MOV AL,1
 MOV CL,AL
 JMP short PRNTH2

PRNTH4:
 ADD BX,DX
 MOV AL,CL
 OR AL,CL
 JZ short PRNTH1
 MOV AL,CH
 call directoutput
 JMP short PRNTH1

PRNTH3:
 MOV AL,'0'
 jmp directoutput

;-----

PRNTBL:
 DW 10000
 DW 1000
 DW 100
 DW 10
 DW 1
 DW 0 ;end

;-----

messageadjust:
 DB "Use cursor left/right to select logical colour, up/down to change"
 DB " pallette"
 DB 13,10
 DB "Press RETURN to select next option, ^C to abort."
 DB 0

adjustcolours:
 call setcursor18
 mov di,offset messageadjust
 call directprs

 mov al,0 ;Colour to adjust
 mov [adjustcolour],al
ac01:
 call displayblob
 call waitforkey
 push ax
 call removeblob
 pop ax
 cmp al,3 ;^C
 jnz short ac00a
 jmp terminate ;(Terminate)
ac00a:
 cmp al,13 ;Return
 jnz notreturn
 jmp ac02

notreturn:
 cmp al,"1" ;Toggle bit 0
 jnz short nottoggle1
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,1
 jz set1
 and al,0FEh
 jmp short reset1
set1:
 or al,01h
reset1:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp short ac01

nottoggle1:
 cmp al,"2" ;Toggle bit 2
 jnz short nottoggle2
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,2
 jz set2
 and al,0FDh
 jmp short reset2
set2:
 or al,02h
reset2:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp short ac01

nottoggle2:
 cmp al,"3" ;Toggle bit 2
 jnz short nottoggle3
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,4
 jz set3
 and al,0FBh
 jmp short reset3
set3:
 or al,04h
reset3:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01

nottoggle3:
 cmp al,"4" ;Toggle bit 3
 jnz short nottoggle4
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,8
 jz set4
 and al,0F7h
 jmp short reset4
set4:
 or al,08h
reset4:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01

nottoggle4:
 cmp al,"5" ;Toggle bit 4
 jnz short nottoggle5
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,10h
 jz set5
 and al,0EFh
 jmp short reset5
set5:
 or al,10h
reset5:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01

nottoggle5:
 cmp al,"6" ;Toggle bit 5
 jnz short nottoggle6
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 test al,20h
 jz set6
 and al,0DFh
 jmp short reset6
set6:
 or al,20h
reset6:
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01

nottoggle6:
 cmp ax,04800h ;Cursor up
 jnz short notcolourinc
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 inc al
 and al,03Fh
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01
notcolourinc:
 cmp ax,05000h ;Cursor down
 jnz short notcolourdec
 mov es,word ptr [pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 dec al
 and al,03Fh
 mov byte ptr es:[BX+BitmapPicColours],al
 call setcolours
 jmp ac01
notcolourdec:
 cmp ax,04D00h ;Cursor right
 jnz short notcolournext
 mov al,[adjustcolour]
 inc al
 and al,0Fh
 mov [adjustcolour],al
 jmp ac01
notcolournext:
 cmp ax,04B00h ;Cursor left
 jnz short notcolourprev
 mov al,[adjustcolour]
 dec al
 and al,0Fh
 mov [adjustcolour],al
 jmp ac01
notcolourprev:
 jmp ac01
ac02:
 call setcursor18
 mov di,offset messagenullerror
 call directprs
 call setcursor19
 mov di,offset messagenullerror
 call directprs
 ret

setcursor18:
 mov ah,2 ;Set Cursor Position
 mov dh,18
 mov dl,0
 mov bh,0
 int 10h ;Video Service
 ret

setcursor19:
 mov ah,2 ;Set Cursor Position
 mov dh,19
 mov dl,0
 mov bh,0
 int 10h ;Video Service
 ret

;-----

rgbtitle1:
 DB "654321"
 DB 0

rgbtitle2:
 DB "RGBRGB"
 DB 0

zero:
 DB "0"
 DB 0

one:
 DB "1"
 DB 0

;-----

displaybit:
 push ax
 jz displayzero
 mov di,offset one
 call directprs
 pop ax
 ret
displayzero:
 mov di,offset zero
 call directprs
 pop ax
 ret

;-----

displayblob:
 mov ah,2 ;Set Cursor Position
 mov dh,10
 mov dl,45
 mov bh,0
 int 10h ;Video Service

 mov di,offset rgbtitle1
 call directprs

 mov ah,2 ;Set Cursor Position
 mov dh,11
 mov dl,45
 mov bh,0
 int 10h ;Video Service

 mov di,offset rgbtitle2
 call directprs

 mov ah,2 ;Set Cursor Position
 mov dh,12
 mov dl,45
 mov bh,0
 int 10h ;Video Service

 mov es,[pictureparaout]
 mov bh,0
 mov bl,byte ptr [adjustcolour]
 mov al,byte ptr es:[BX+BitmapPicColours]
 and al,03Fh
 test al,020h
 call displaybit
 test al,010h
 call displaybit
 test al,008h
 call displaybit
 test al,004h
 call displaybit
 test al,002h
 call displaybit
 test al,001h
 call displaybit

 mov al,15
 jmp short drawblob

removeblob:
 mov al,0
drawblob:
 mov dx,180 ;Row
 mov ch,0
 mov cl,[adjustcolour]
 add cx,cx
 add cx,cx
 add cx,cx
 add cx,cx
 mov ah,16
db01:
 push ax
 push cx
 push dx
 mov ah,0Ch ;Write pixel dot
 INT 10h ;Video Service
 pop dx
 pop cx
 pop ax
 inc cx
 dec ah
 cmp ah,0
 jnz short db01
 ret

;-----

waitforkey:
 MOV AH,01 ;Service 1 (Report keyboard)
 INT 16H ;ROM-BIOD keyboard service
 jnz short getch2
 jmp short waitforkey

getch2:
 MOV AH,00H ;Service 0 (Read Next Keyboard Character)
 INT 16H ;ROM-BIOS keyboard service
 ret

;-----

adjustcolour db 0

;-----

optionalredraw:
 call setcursor17
 mov di,offset messagenullerror
 call directprs
 call setcursor17
 mov di,offset messageredraw
 call directprs
 call getyesno
 cmp al,"y"
 jnz short or01
 call displayentirepicture
or01:
 ret

messageredraw:
 DB "Draw picture (Y/N)? "
 DB 0

;-----

CPNRST = 13;Reset disk system
CPNOF = 15 ;Open File
CPNCF = 16 ;Close File
CPNRS = 20 ;Read Sequential
CPNWS = 21 ;Write Sequential
CPNMF = 22 ;Create file

;Ascii/BBC control codes:
ASCIIBS = 08h
ASCIILF = 0Ah
ASCIICLS= 0Ch
ASCIICR = 0Dh
ASCIIESC= 1Bh
ASCIIDEL=07Fh
SPACE = ' '

;-----

messagefilename:
 DB "Filename? "
 DB 0

;Return codes:
;   al = 0 ok
;   al = 1 Invalid file id
;   al = 2 Null input

askfilename:
 call INPUTLINE
 call EXAMINENAME
 jb short af01
 cmp byte ptr ds:[fcbname],space
 jz short af02
 MOV BX,offset ADVFILETYPE
 call INSERTTYPE
 XOR AL,AL ;Ok
 RET
af01:
 mov al,1 ;Invalid name
 ret
af02:
 mov al,2 ;Null input
 ret

;-----

INPUTLINE:
; RETURN IN (IY+1)
 mov bx,offset inputbuffer
 MOV CH,0 ;Number of chars
inpl1:
 PUSH BX
 PUSH DX
 PUSH CX

 mov al,05Fh ;Cursor (underline character)
 call directoutput

 call waitforkey

 push ax
 mov al,asciibs
 call directoutput
 mov al," "
 call directoutput
 mov al,asciibs
 call directoutput
 pop ax

inpl6:
 POP CX
 POP DX
 POP BX
 CMP AL,ASCIIDEL
 jz short inpl7
 CMP AL,ASCIIBS
 jnz short inpl8
inpl7:
 MOV AL,CH
 OR AL,AL
 jz short inpl1
 DEC CH
 DEC BX
 MOV AL,ASCIIBS
 call directoutput
 jmp short inpl1
inpl8:
 CMP AL,ASCIICR
 jnz short DBI024
 jmp short INPLEND
DBI024:    
 CMP AL,SPACE
 jnc short inpl8a
 jmp short inpl1
inpl8a:
 CMP AL,'a' ;Convert lower case to upper case
 JB short notlower
 CMP AL,'z'+1
 JAE short NOTLOWER
 AND AL,0DFh
notlower:
 MOV CL,AL
 MOV AL,CH
 CMP AL,INPUTBUFFERSIZE
 jnz short inpl9
 jmp short inpl1
inpl9:
 MOV AL,CL
 call directoutput
 INC BX
 INC CH
 MOV AL,CL
 MOV [BX],AL
 jmp short inpl1
INPLEND:
 INC BX
 MOV byte ptr [BX],SPACE
 INC BX
 MOV byte ptr [BX],0
 MOV AL,ASCIICR
 call directoutput
 MOV AL,SPACE
 mov byte ptr [inputbuffer],al
 RET

;-----

ADVFILETYPE:
 DB 'PIC'

;-----

;Prepare system FCB for a new file. Set drive
;to current login drive.
;Registers AF,HL,DE,BC corrupted.
FCBINIT:
 MOV AH,CPNRST
 INT 21h
 MOV BX,offset SYSFCB
 MOV DX,offset SYSFCB+1
 MOV CX,FCBLEN-1
 MOV AL,SPACE
 MOV ds:[BX],AL
 XCHG BX,SI
 XCHG DX,DI
 call ldir
 XCHG BX,SI
 XCHG DX,DI
 XOR AL,AL
 MOV byte ptr ds:[FCBDRIVE],AL
 MOV byte ptr ds:[FCBEX],AL
 MOV byte ptr ds:[FCBCR],AL
 RET

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

;Load BX with the address of a
;three byte file type (padded with spaces.)
;If the system FCB has a blank file
;type then this is stored there.
;Registers AF,HL,DE,BC corrupted.
INSERTTYPE:
 cmp byte ptr ds:[fcbtype],space
 JZ short DBI032
 RET
DBI032:;File type supplied
 MOV DX,offset FCBTYPE
 MOV CX,3
 XCHG BX,SI
 XCHG DX,DI
; CLD
; REP MOVSB
 call ldir
 XCHG BX,SI
 XCHG DX,DI
 RET

;-----

;Prompt user for a file-name which
; is returned in the system FCB.
;Returned condition 'C' indicates an invalid file name
; (too long, invalid character, bad separators.)
;(FCBNAME)=' ' if nothing is entered.
;(FCBTYPE)=' ' if no file type entered.
;Most registers corrupted.
EXAMINENAME:
 call FCBINIT
 mov dx,offset inputbuffer+1
en01:
 XCHG SI,DX
 MOV AL,ds:[si]
 XCHG SI,DX
 OR AL,AL
 jnz short DBI033
 xor al,al ;Reset Carry
 RET
DBI033:;Nothing entered
 INC DX
 CMP AL,SPACE
 JZ short en01
;If second byte is ":" then drive spec.
 XCHG SI,DX
 MOV AL,ds:[si]
 XCHG SI,DX
 DEC DX
 CMP AL,':'
 jnz short en02
;Check valid drive
 XCHG SI,DX
 MOV AL,ds:[si]
 XCHG SI,DX
 SUB AL,'A'-1
 MOV byte ptr ds:[FCBDRIVE],AL
 INC DX
 INC DX
en02:
 MOV BX,offset FCBNAME
 MOV CX,8+1
 call GETID
 CMP AL,'.'
 JZ short en03
 OR AL,AL
 jnz short DBI034
 RET
DBI034:;Ok
 STC
 RET ;Error
en03:
 INC DX
 MOV BX,offset FCBTYPE
 MOV CX,3+1
 call GETID
 OR AL,AL
 jnz short DBI035
 RET
DBI035:;Ok
 STC
 RET ;Error

GETID:
 cmp cx,0
 XCHG SI,DX
 MOV AL,ds:[si]
 XCHG SI,DX
 jnz short DBI036
 RET
DBI036:;Too long
 call UPPER
 OR AL,AL
 jnz short DBI037
 RET
DBI037:
 CMP AL,'?'
 jnz short DBI038
 RET
DBI038:
 CMP AL,'*'
 jnz short DBI039
 RET
DBI039:
 CMP AL,'.'
 jnz short DBI040
 RET
DBI040:
 MOV cs:[BX],AL
 INC BX
 INC DX
 DEC CX
 JMP short GETID

;-----

UPPER:
 CMP AL,'a'
 JNB short DBI041
 RET
DBI041:
 CMP AL,'z'+1
 JB short DBI042
 RET
DBI042:
 ADD AL,'A'-'a'
 RET

;-----

messagenullerror:
 DB "          "
 DB "          "
 DB "          "
 DB "          "
 DB "          "
 DB "          " ;Erase any error message
 DB 0

;-----

set12cursor15:
 mov dl,12
 jmp short s15
setcursor15:
 mov dl,0
s15:
 mov ah,2 ;Set Cursor Position
 mov dh,15
 mov bh,0
 int 10h ;Video Service
 ret

set12cursor16:
 mov dl,12
 jmp short s16
setcursor16:
 mov dl,0
s16:
 mov ah,2 ;Set Cursor Position
 mov dh,16
 mov bh,0
 int 10h ;Video Service
 ret

;-----

loadpicturein:
 call setcursor15
 mov di,offset messagenullerror
 call directprs

 call setcursor15
 MOV DI,offset messagefilename
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
 DB "Invalid file name"
 DB 0

lp00:
 call setcursor16
 mov di,offset messagebadfilename
 call directprs
 jmp short loadpicturein

lp01:
 mov es,ds:word ptr [pictureparain]
 MOV DX,offset sysfcb
 MOV AH,CPNOF
 INT 21h ;CP/M Entry Point.
 OR AL,AL
 jnz short OSLOAD2

 mov al,0FFh ;Length
 MOV BX,0 ;Start address
 call READFILE

 MOV DX,offset sysfcb
 MOV AH,CPNCF
 INT 21h

OSLOAD1:
 RET

messagenotfound:
 DB "File not found"
 DB 0

osload2:
 call setcursor16

 mov di,offset messagenotfound
 call directprs
 jmp loadpicturein

;-----

;Read up to 'A' pages or untiL EOF from the
;system file into memory starting at address
;'HL'. The file must have been opened by OPENREAD
;Returns condition 'C' when EOF is reached and
;HL as the address+1 of the last byte loaded
;Registers AF,BC,DE corrupted.
READFILE:
 MOV DX,offset sysfcb
 OR AL,AL
 jnz short DBI028
 RET
DBI028:
 PUSH AX
 call READBLOCK
 JC short RF01
 call READBLOCK
 JC short RF01
 POP AX
 DEC AL
 jmp short READFILE
RF01:
 POP AX
 STC
 RET

READBLOCK:
 PUSH AX
 PUSH BX
 MOV AH,CPNRS
 INT 21h
 POP BX
 OR AL,AL
 jnz short RB01
 POP AX
 PUSH DX
 MOV CX,128
 mov si,offset diskbuffer
 mov di,bx
ldirfromworkspace:
 jcxz short ldirfromend
 mov al,ds:0[si]
 mov es:0[di],al
 inc di
 inc si
 dec cx
 jmp short ldirfromworkspace
ldirfromend:
 mov bx,di
 POP DX
 XOR AL,AL
 RET
RB01:
 POP AX
 STC
 RET

;-----

setcursor17:
 mov ah,2 ;Set Cursor Position
 mov dh,17
 mov dl,0
 mov bh,0
 int 10h ;Video Service
 ret

;-----

savepictureout:
 call setcursor16
 MOV DI,offset messagenullerror
 call directprs

 call setcursor16

 MOV DI,offset messagefilename
 call directprs

 call askfilename
 push ax
 call setcursor17
 mov di,offset messagenullerror
 call directprs
 pop ax
 cmp al,1
 jz short sp01
 cmp al,2
 jnz short sp02

 call setcursor17
 mov di,offset messagequit
 call directprs
 call getyesno
 cmp al,"y"
 jz short sp00b
 jmp short savepictureout

sp00b:
 jmp terminate

messagequit:
 DB "Exit without saving (Y/N)? "
 DB 0

messageyes:
 DB "Yes"
 DB 0

messageno:
 DB "No"
 DB 0

sp01:
 call setcursor17
 mov di,offset messagebadfilename
 call directprs
 jmp short savepictureout

sp02:
 MOV DX,offset sysfcb
 MOV AH,CPNMF ;Open file
 INT 21h ;ROM-BIOS DOS CALL CPMENTRY
 cmp al,0
 jz short savingfile

 call setcursor17
 mov di,offset messagewriteerror
 call directprs
 MOV DX,offset sysfcb
 MOV AH,CPNCF
 INT 21h
 jmp savepictureout

messagewriteerror:
 DB "Error creating file"
 DB 0

savingfile:
 mov es,ds:word ptr [pictureparaout]
 mov si,0 ;Save address within ES

writefile:
 mov ax,si ;current save address
 mov cx,es:word ptr [BitmapPicLength] ;target length

 stc
 sbb ax,cx
 jnc short finished

 mov di,offset diskbuffer
 mov cx,128 ;Disk buffer size
copysector:
 jcxz short writesector
 mov al,byte ptr es:0[si]
 mov byte ptr 0[di],al
 inc si
 inc di
 dec cx
 jmp short copysector
writesector:

 MOV DX,offset sysfcb
 MOV AH,CPNWS
 INT 21h
 cmp al,0
 jnz short sp03
 jmp short writefile

messagediskfull:
 DB "Disk full"
 DB 0

sp03:
 call setcursor17
 mov di,offset messagediskfull
 call directprs
 MOV DX,offset sysfcb
 MOV AH,CPNCF
 INT 21h
 jmp savepictureout

finished:
 MOV DX,offset sysfcb
 MOV AH,CPNCF
 INT 21h

 ret ;Normal exit

;-----

;Print string at [DI]
directprs:
 MOV AL,cs:[DI]
 CMP AL,0
 jz short directprs1

 mov al,cs:0[DI]
 call directoutput
 INC DI
 jmp short directprs
directprs1:
 RET

;-----

directoutput:
 mov dl,al
 mov ah,2 ;Universal Function 2 - Display Output
 INT 21h ;Universial Function
 ret

;-----

          DB 7 DUP(0) ;Extended area
sysfcb    = this byte
fcbdrive  DB 2
fcbname   DB "        " ;5 bytes
fcbtype   DB "   "      ;3 bytes
fcbex     DB 20 DUP(0)
fcbcr     DB 4  DUP(0)
fcblen    = this byte - sysfcb

;-----

setcolours:
 mov es,ds:word ptr [pictureparaout]

;Set pallette (seems to be required)
 mov ah,11
 mov bh,0
 mov bl,0
 int 10h ;Video Service

 mov ah,10h
 mov al,2
 mov dx,BitmapPicColours ;Offset into file for colour table
 int 10h ;Video Service
 ret

;-----

displayentirepicture:
 call setcolours

 mov es,ds:word ptr [pictureparaout]
 mov si,BitmapPicData ;Offset into picture file for pixel data
 mov ah,0 ;High order byte
 mov cx,offsetX ;Pixel column
 mov dx,offsetY ;Pixel row

plotpixel:
 cmp cx,word ptr es:[BitmapPicWidth] ;reached width of stored picture
 jz short skipnextrow
 cmp cx,320 ;Reached width of screen
 jz short skipnextrow

 mov al,es:[si] ;Read pixel data
 cmp ah,0 ;High order byte?
 jnz short dontshift
 push cx
 mov cl,4
 shr al,cl
 pop cx
dontshift:
 and al,0Fh

 push ax
 push cx
 push dx
 mov ah,0Ch ;Write pixel dot
 INT 10h ;Video Service
 pop dx
 pop cx
 pop ax

 inc cx
 cmp ah,0
 jnz short nextbyte
 inc ah
 jmp short plotpixel

nextbyte:
 mov ah,0
 inc si
 jmp short plotpixel

skipnextrow:
 inc dx
 mov cx,offsetX ;Left column
 mov bx,dx ;Check height of picture
 sub bx,offsetY
 cmp bx,word ptr es:[BitmapPicHeight] ;Height of stored picture
 jz short offend
 cmp dx,200 ;Run off bottom of screen?
 jnz short plotpixel

offend:
 mov dx,150 ;Start row

displaypallette:
 cmp dx,160 ;End row
 jz short displayfinished

 mov cx,0 ;Left column
dp01:
 cmp cx,16*16 ;Number of colours * colour bar width
 jz short displaynextrow
 mov al,0 ;Black
 mov al,cl
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,0Fh
 mov ah,0Ch ;Write pixel point
 push dx
 push cx
 int 10h ;Video Service
 pop cx
 pop dx
 inc cx
 jmp short dp01
displaynextrow:
 inc dx
 jmp short displaypallette
displayfinished:
 ret

;-----

inputbuffersize = 15
inputbuffer DB inputbuffersize DUP (0)

pictureparain dw 0

pictureparaout dw 0

;Disk DMA buffer
diskbuffer DB 128 DUP(0) ;Disk I/O buffer

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


