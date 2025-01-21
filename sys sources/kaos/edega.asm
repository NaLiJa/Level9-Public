;IBM KAOS DRIVER. Routines just for EGA graphics

;EGA.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

pictureoffset=0 ;Offset into Pgraphicsbuffer of screen data

 public DoBitmapPalette
 public cgatranslate
 public drawegaline
 public egacopytoscreen
 public egafastcharacterenable
 public ega_14_16_transferrowrow
 public mappingtable
 public newpalette
 public DoCompressedEgaPalette

;In EDSQU.ASM:
 extrn ModuleName:byte

;In HIRES.ASM:
 extrn taskaddress:word

;In ENTRY.ASM:
 extrn screenmode:byte

 name ega

code segment public 'code'
 assume cs:code,ds:code

 include head.asm

;-----

cgatranslate:
;         IRGB  RrGgBb
 DB 00h ;(0000) 0 0 0
 DB 01h ;(0001) 0 0 2
 DB 02h ;(0010) 0 2 0
 DB 03h ;(0011) 0 2 2
 DB 04h ;(0100) 2 0 0
 DB 05h ;(0101) 2 0 2
 DB 06h ;(0110) 2 2 0
 DB 07h ;(0111) 2 2 2
 DB 0   ;(0001) 0 0 1 - Very dark
 DB 09h ;(1001) 0 0 3
 DB 02h ;(0010) 0 2 1
 DB 03h ;(0011) 0 2 3
 DB 04h ;(0100) 2 0 1
 DB 05h ;(0101) 2 0 3
 DB 06h ;(0110) 2 2 1
 DB 09h ;(1001) 2 2 3
 DB 0   ;(0010) 0 1 0 - Very Dark
 DB 03h ;(0011) 0 1 2
 DB 0Ah ;(1010) 0 3 0
 DB 03h ;(0011) 0 3 2
 DB 06h ;(0110) 2 1 0
 DB 05h ;(0101) 2 1 2
 DB 06h ;(0110) 2 3 0
 DB 0Ah ;(1010) 2 3 2
 DB 0   ;(0011) 0 1 1 - Very Dark
 DB 09h ;(1001) 0 1 3
 DB 0Ah ;(1010) 0 3 1
 DB 0Bh ;(1011) 0 3 3
 DB 04h ;(0100) 2 1 1
 DB 09h ;(1001) 2 1 3
 DB 0Ah ;(1010) 2 3 1
 DB 0Bh ;(1011) 2 3 3
 DB 0   ;(0100) 1 0 0 - Very Dark
 DB 05h ;(0101) 1 0 2
 DB 06h ;(0110) 1 2 0
 DB 03h ;(0011) 1 2 2
 DB 0Ch ;(1100) 3 0 0
 DB 05h ;(0101) 3 0 2
 DB 06h ;(0110) 3 2 0
 DB 0Ch ;(1100) 3 2 2
 DB 0   ;(0101) 1 0 1 - Very Dark
 DB 09h ;(1001) 1 0 3
 DB 02h ;(0010) 1 2 1
 DB 09h ;(1001) 1 2 3
 DB 0Ch ;(1100) 3 0 1
 DB 0Dh ;(1101) 3 0 3
 DB 0Ch ;(1100) 3 2 1
 DB 0Dh ;(1101) 3 2 3
 DB 0   ;(0110) 1 1 0 - Very Dark
 DB 01h ;(0001) 1 1 2
 DB 0Ah ;(1010) 1 3 0
 DB 0Ah ;(1010) 1 3 2
 DB 0Ch ;(1100) 3 1 0
 DB 0Ch ;(1100) 3 1 2
 DB 0Eh ;(1110) 3 3 0
 DB 0Eh ;(1110) 3 3 2
 DB 0   ;(0111) 1 1 1 - Very Dark
 DB 09h ;(1001) 1 1 3
 DB 0Ah ;(1010) 1 3 1
 DB 0Bh ;(1011) 1 3 3
 DB 0Ch ;(1100) 3 1 1
 DB 0Dh ;(1101) 3 1 3
 DB 0Eh ;(1110) 3 3 1
 DB 0Fh ;(1111) 3 3 3

;-----

;Update real screen with new colour palette. The normal sequence is:
;   Merge new picture palette with text/border colours
;   Draw windowed picture in Copy of Graphics Screen
;   Update screen for new palette 'SETEGAPALETTE'
;   Update screen for new pixel data

setegapalette:
 push es
 push ds
 push si

;If called from 'ega.asm' then reset segment registers:
 mov ax,cs
 mov ds,ax

 cmp ds:[screenmode],13 ;redefinable palette required EGA card
 jc se03 ;Not EGA or EGA-emulation
 cmp ds:[screenmode],16 ;Mode 16 uses 64-colour palette
 jz se02 ;EGA

;EGA-emulation, must convert palette back to IRGB
 mov si,offset newpalette
 mov cx,16
se01:
 mov al,ds:[si]
 mov bh,0
 mov bl,al
 mov al,byte ptr ds:cgatranslate[bx] ;Get xxxxIRGB
 test al,08h
 jz se01a
 and al,07h
 or al,10h
se01a: ;al is now colour xxxIxRGB

 mov ds:[si],al
 inc si
 loop se01

se02:
 push cs
 pop es
 mov dx,offset newpalette
 mov ah,10h
 mov al,2
 int 10h
se03:
 pop si
 pop ds
 pop es
 ret

;-----

;Set up colour palette with colours for text 
;and those colours used in border picture.

initpalette:
 mov si,offset MenuFpalette
 mov di,offset newpalette
 mov cx,16
cp01:
 mov al,cs:[si] ;Copy default palette (from MENU.TXT)
 mov al,99
 mov cs:[di],al
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz cp01
 ret

;-----

;Create a new palette for use when the new picture is displayed,
;This is merged from the palette contained in MENU.TXT and the
;palette from the picture loaded from disk. Bitmapped picture.

DoBitmapPalette:
 call initpalette
 mov si,[taskaddress]
 add si,offset BitmapPicColours
 mov es,cs:[MenuPcache]
 jmp short sortpalette

;-----

;Create a new palette for use when the new picture is displayed,
;This is merged from the palette contained in MENU.TXT and the
;palette from the picture loaded from disk. Compressed picture.

DoCompressedEgaPalette:
 call initpalette
 mov si,dx

;Set up palette for new picture and logical colour translation
;table so new picture can be drawn in Copy of Graphics Screen.

sortpalette:
 mov di,offset mappingtable
 mov cx,16
sp01:
 mov al,es:[si] ;Get each colour used in this picture
 push si
 push di
 push cx
 call findorcreatecolour ;Ensure the new palette to use contains this.
 pop cx
 pop di
 pop si

 mov ah,al
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 or al,ah

 mov ds:[di],al ;Save logical colour map entry
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz sp01

 mov si,offset newpalette ;Replace '99' blanks
 mov cx,16
sp02:
 cmp byte ptr cs:[si],99
 jnz sp03
 mov byte ptr cs:[si],0
sp03:

 inc si
 dec cx
 cmp cx,0
 jnz sp02

 ret

;-----

;Ensure palette used for next picture contains colour 'al'

findorcreatecolour:
 mov bx,offset newpalette
 mov cx,0
fc03:
 cmp byte ptr cs:[bx],99 ;Found empty entry
 jz fc05
 inc bx
 cmp cx,15
 jz fc04
 inc cx
 jmp short fc03

fc04:
 mov cx,0 ;Use logical colour 0
 jmp short fc06

fc05:
 mov cs:[bx],al ;Store newpalette entry
fc06:
 mov al,cl ;Return new logical colour
 ret

;-----

newpalette db 16 dup (0)
 db 0 ;Background colour

mappingtable db 16 dup (0)

;-----

;Plot one picture row, from the picture cache to the Copy of Graphics Screen

;si = start pixel
;dx = row
;cx = Length in pixels
;ah = hi/low nybble

ega_14_16_transferrowrow:
 push ds ;Save segment registers
 push es

 push es
 pop ds ;Picture cache
 mov es,cs:[MenuPgraphicsbuffer] ;Copy of Graphics Screen

 push ax
 mov ax,320 ;Bytes per screen line
 push dx
 cmp cs:ModuleName,0
 jnz egadontexpand
 push ax
 mov ax,dx
 shr ax,1
 add ax,dx
 mov dx,ax
 pop ax
egadontexpand:
 mul dx ;Start offset of screen row
 pop dx
 add ax,cx ;Column offset
 add ax,pictureoffset ;Skip parameter block
 mov di,ax
 pop ax

;di = Address if Pgraphicsbuffer.

 cmp ah,0 ;Nybble to read is high nybble/low nybble
 jnz short egaplotpixel1 ;(Not even column)

 cmp bx,0
 jnz short egaplotpixel

 jmp short et01

egaplotpixel:
 mov al,ds:[si] ;Read pixel data (ds=picture cache)

 shr al,1
 shr al,1
 shr al,1
 shr al,1
 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

 mov es:[di],al ;Set both pixels to same colour (double resolution)
 inc di

 inc cx
 dec bx
 jnz egaplotpixel1
 mov ah,1 ;Just process high nybble, next is low.

 jmp short et01

egaplotpixel1:
 mov al,ds:[si] ;Read pixel data (es=picture cache)
 and al,0Fh

 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

 mov es:[di],al ;Set both pixels to same colour (double resolultion)
 inc di

 inc cx
 inc si
 dec bx
 jnz egaplotpixel
 mov ah,0 ;Just processed low nybble, next is high.

et01:
 pop es
 pop ds
 ret

;----------

;Transfer data from a line of consecutive pixels stored one pixel
;per byte in a buffer at [di]

drawegaline:
; cx = Xposition
; dx = yposition
; di = lineofpixelsptr
; bx = rightboundary

 push ds ;Save segment registers
 push es

 push es
 pop ds ;Picture cache
 mov es,cs:[MenuPgraphicsbuffer] ;Copy of Graphics Screen

 push ax
 mov ax,320 ;Bytes per screen line
 push dx
 cmp cs:ModuleName,0
 jnz compressedegadontexpand
 push ax
 mov ax,dx
 shr ax,1
 add ax,dx
 mov dx,ax
 pop ax
compressedegadontexpand:
 mul dx ;Start offset of screen row
 pop dx
 add ax,cx ;Column offset
 add ax,pictureoffset ;Skip parameter block
 mov si,ax
 pop ax

pe02:
 cmp cx,bx
 jge pe03
 mov al,cs:[di]

 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

 mov es:[si],al ;Set both pixels to same colour (double resolution)

 inc di
 inc cx
 inc si
 jmp short pe02

pe03:
 pop es
 pop ds
 ret

;----------

;End of picture drawing, All Black and white modes draw directly to the
;screen, so nothing further is required. All Colour modes draw in
;memory, so copy this to the screen.

egacopytoscreen:
 cmp ds:[screenmode],15
 jnc copyegabuffer
 ret ;Black/White does not require copying to screen

copyegabuffer:
 call egaexpand135to200
 cmp byte ptr cs:[MenuFsubmode],ega_ultra
 jnz ce00

 jmp UltraFastEgaCopyToScreen

ce00:
 cmp byte ptr cs:MenuFsubmode,ega_okish
 jnz ce01

;Super-Fast EGA (transfers 4 pixels at a time):
 call setegapalette
 push ds
 mov ds,cs:[MenuPgraphicsbuffer]
 mov ax,64000
 mov bx,349
 call superfastegacopytoscreen
 pop ds
 ret

ce01:
 call setegapalette

 cmp ds:screenmode,13
 jz ec01 ;EGA-Emulation 320-wide

;Fast and Normal EGA (transfers pixel-by-pixel):

 mov es,cs:[MenuPgraphicsbuffer]
 mov dx,0 ;Row

 cmp cs:screenmode,16
 jz ce01b
 mov bx,136 ;normal size for pictures
 cmp cs:ModuleName,0
 jz ce01a
ce01b:
 mov bx,200 ;normal size for title
ce01a:

 mov bx,200 ;Picture height *****
 mov si,pictureoffset ;offset
ce02:
 cmp bx,0
 jz ce03

 push dx
 push bx
 mov cx,0 ;column
cl01:
 mov al,es:[si]
 and al,0Fh

 push cx
 push dx
 push si
 push es
 call egasetdoublepixel ;Fast and super-fast pixel plot
 pop es
 pop si
 pop dx
 pop cx

 inc cx
 inc si
 cmp cx,320
 jb cl01
 pop bx
 pop dx

 inc dx
 dec bx
 jmp short ce02
ce03:
 ret

;EGA-Emulation 320-wide

ec01:
 mov es,cs:[MenuPgraphicsbuffer]
 mov dx,0 ;Row

 cmp cs:screenmode,16
 jz ec01b
 mov bx,136 ;normal size for pictures
 cmp cs:ModuleName,0
 jz ec01a
ec01b:
 mov bx,200 ;normal size for title
ec01a:

 mov si,pictureoffset ;offset
ec02:
 cmp bx,0
 jz ec07

 push dx
 push bx
 mov cx,0 ;column
ec03:
 test cl,1
 jnz ec04
 mov al,es:[si]
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 jmp short ec05
ec04:
 mov al,es:[si]
ec05:
 and al,0Fh

 push cx
 push dx
 push si
 push es
 mov bx,0 ;Page 0
 mov ah,0Ch ;Write Pixel dot
 int 10h ;Video Service
 pop es
 pop si
 pop dx
 pop cx

 test cx,1
 jz ec06
 inc si
ec06:
 inc cx
 cmp cx,320
 jb ec03
 pop bx
 pop dx

 inc dx
 dec bx
 jmp short ec02
ec07:
 ret

;-----

;Plot pixel on 320x200 screen.
;AL=Colour, dx=Row, cx=Column

egasetdoublepixel:
 and al,0Fh
 cmp byte ptr cs:[MenuFsubmode],0
 jnz es01 
 jmp short setpointslowega 
es01:
 jmp short setpointfastega

;-----

;Slow EGA set one pixel

setpointslowega:
 add cx,cx
 push ax
 mov bx,0 ;Page 0
 mov ah,0Ch ;Write Pixel dot
 int 10h ;Video Service
 pop ax
 inc cx
 mov ah,0Ch ;Write Pixel dot
 int 10h ;Video Service
 ret

;-----

;Fast EGA set one pixel

setpointfastega:
 push ax
 mov ax,0050h 
 mul dx 
 push cx 
 shr cx,1 
 shr cx,1 
 add ax,cx 
 pop cx 
 mov bx,ax 
 mov al,0C0h 
 and cl,03 
 add cl,cl 
 shr al,cl 
 mov dx,03CEh 
 xchg al,ah 
 mov al,08 
 out dx,al 
 inc dx 
 xchg al,ah 
 out dx,al 
 mov ax,0A000h 
 mov es,ax 
 mov dl,0C4h 
 mov al,02 
 out dx,al 
 inc dx 
 mov al,0FFh 
 out dx,al 
 dec dx 
 mov al,es:[bx] 
 mov byte ptr es:[bx],00 
 mov al,02 
 out dx,al 
 inc dx 
 pop ax 
 and al,0Fh 
 out dx,al 
 dec dx 
 mov al,es:[bx] 
 mov al,0FFh 
 mov es:[bx],al 
 mov al,02 
 out dx,al 
 inc dx 
 mov al,0FFh 
 out dx,al 
 ret  

;-----

;In fast EGA mode, reset plotting mask from one-pixel
;mask to eight-pixel mask for for character-output.

egafastcharacterenable:
 mov dx,03CEh 
 mov al,07 
 out dx,al 
 inc dx 
 mov al,00 
 out dx,al 
 dec dx 
 mov ax,08FFh 
 xchg al,ah 
 out dx,al 
 inc dx 
 xchg al,ah 
 out dx,al 
 dec dx 
 ret  

;-----

egaexpand135to200:
 cmp ModuleName,0
 jnz ep04 ;Title picture not expanded (it would overflow segment)
 mov es,cs:[MenuPgraphicsbuffer]
 mov si,pictureoffset+1*320 ;Line 1 to line 2
 mov di,pictureoffset+2*320
ep01:
 mov cx,320
ep02:
 jcxz ep03
 mov al,es:[si]
 mov es:[di],al
 inc si
 inc di
 dec cx
 jmp short ep02
ep03:
 cmp si,64320
 jae ep04
 add si,640 ;then line 4
 add di,640 ;to line 5...
 jmp short ep01
ep04:
 ret

;-----

UltraBitPlaneLength dw 0

MinimumCopy=80*16/2 ;words transfered per bit-plane

UltraFastEgaCopyToScreen:
 cmp cs:screenmode,13
 jz setultra13
 cmp cs:screenmode,14
 jz setultra14
 mov ax,Mode16Screen/4
 jmp short setultra
setultra13:
 cmp cs:ModuleName,0
 jnz SetUltraT13
 mov ax,Mode13Screen/4 ;EGA-emulation mode 13 
 jmp short setultra
SetUltraT13:
 mov ax,32000/4 ;EGA-emulation mode 13 
 jmp short setultra
Setultra14:
 cmp cs:ModuleName,0
 jnz SetUltraT14
 mov ax,Mode14Screen/4 ;EGA-emulation mode 14
 jmp short setultra
SetUltraT14:
 mov ax,64000/4 ;EGA-emulation mode 14

setultra:
 mov cs:UltraBitPlaneLength,ax

 sub si,si
 mov bp,cs:UltraBitPlaneLength
 mov es,cs:MenuPgraphicsBuffer

transform:

 mov ax,es:[si+0]
 mov bx,es:[si+2]

 rept 2 ;1st then 2nd pixel
 rcl al,1 ;bit 3
 rcl ch,1

 rcl al,1 ;bit 2
 rcl cl,1

 rcl al,1 ;bit 1
 rcl dh,1

 rcl al,1 ;bit 0
 rcl dl,1
 endm ;rept

 rept 2 ;3rd then 4th pixel
 rcl ah,1 ;bit 3
 rcl ch,1

 rcl ah,1 ;bit 2
 rcl cl,1

 rcl ah,1 ;bit 1
 rcl dh,1

 rcl ah,1 ;bit 0
 rcl dl,1
 endm ;rept

 rept 2 ;5th then 6th pixel
 rcl bl,1 ;bit 3
 rcl ch,1

 rcl bl,1 ;bit 2
 rcl cl,1

 rcl bl,1 ;bit 1
 rcl dh,1

 rcl bl,1 ;bit 0
 rcl dl,1
 endm ;rept

 rept 2 ;7th then 8th pixel
 rcl bh,1 ;bit 3
 rcl ch,1

 rcl bh,1 ;bit 2
 rcl cl,1

 rcl bh,1 ;bit 1
 rcl dh,1

 rcl bh,1 ;bit 0
 rcl dl,1
 endm ;rept

 mov es:[si+0],dx ;bit 0
 mov es:[si+2],cx ;bit 2

 add si,4
 dec bp
 jnz next
 jmp short transferit
next:
 jmp transform

;--

transferit:
 call setegapalette

 mov ds,cs:MenuPgraphicsBuffer
 mov ax,0A000h
 mov es,ax

 mov bx,cs:UltraBitPlaneLength
 shr bx,1      ;words to transfer
 mov dx,03C4h  ;port address

repeat:
 mov ax,0102h ;bit 0
 sub si,si
 call transferplane

 mov ax,0202h ;bit 1
 mov si,1
 call transferplane

 mov ax,0402h ;bit 2
 mov si,2
 call transferplane

 mov ax,0802h ;bit 3
 mov si,3
 call transferplane

 mov ax,ds
 add ax,MinimumCopy/16*4*2
 mov ds,ax

 mov ax,es
 add ax,MinimumCopy/16*2
 mov es,ax

 sub bx,MinimumCopy ;words 
 ja repeat

 mov ax,cs  ; reset ds and es
 mov ds,ax
 mov es,ax

;--

 sub si,si
 mov bp,cs:UltraBitPlaneLength
 mov es,cs:MenuPgraphicsBuffer

untransform:
 mov dx,es:[si+0] ;bit 0/1
 mov cx,es:[si+2] ;bit 2/3

 rept 2 ;pixel 6/7
 rcr dl,1
 rcr bh,1 ;bit 0

 rcr dh,1
 rcr bh,1 ;bit 1

 rcr cl,1
 rcr bh,1 ;bit 2

 rcr ch,1
 rcr bh,1 ;bit 3
 endm ;rept

 rept 2 ;pixel 4/5
 rcr dl,1
 rcr bl,1 ;bit 0

 rcr dh,1
 rcr bl,1 ;bit 1

 rcr cl,1
 rcr bl,1 ;bit 2

 rcr ch,1
 rcr bl,1 ;bit 3
 endm ;rept

 rept 2 ;pixel 2/3
 rcr dl,1
 rcr ah,1 ;bit 0

 rcr dh,1
 rcr ah,1 ;bit 1

 rcr cl,1
 rcr ah,1 ;bit 2

 rcr ch,1
 rcr ah,1 ;bit 3
 endm ;rept

 rept 2 ;pixel 0/1
 rcr dl,1
 rcr al,1 ;bit 0

 rcr dh,1
 rcr al,1 ;bit 1

 rcr cl,1
 rcr al,1 ;bit 2

 rcr ch,1
 rcr al,1 ;bit 3
 endm ;rept

 mov es:[si+0],ax ;pixels 0/1
 mov es:[si+2],bx ;pixels 4/5

 add si,4
 dec bp
 jnz unext
 ret
unext:
 jmp untransform

;-----

transferplane:

 out dx,ax

 sub di,di
 mov cx,bx

 cmp cx,MinimumCopy
 jc tp01
 mov cx,MinimumCopy

tp01:
 mov al,ds:[si]
 mov ah,ds:[si+4]
 stosw
 add si,8
 loop tp01

 ret
 
;-----

data0046 dw 0

data004c dw 0
data004a dw 0
data0048 dw 0
data0045 db 0

data000e dw 0
data000a dw 0

data00b0 dw 0
data00ae dw 0

data005a dw 0

data0052 dw 0
data0058 dw 0

data006c db 0
data0064 dw 0
data0062 dw 0
data0054 dw 0

halfaddress dw 0 ;Address of top/middle of pixel data.

storedlength dw 0
blocklength dw 00h

L025c dw 00h
L025e dw 00h

;-----

superfastegacopytoscreen:
 cmp byte ptr cs:MenuFsubmode,0
 jnz show1
 ret

show1:
 mov cs:[blocklength],64640

 mov ax,015Eh
 mov cs:[data000e],ax

 mov ax,cs:[data000e]
 mov cs:[L025c],ax

 mov dx,0
 mov ax,cs:[blocklength]
 push bx
 mov bx,320
 div bx ;(bx=320)
 shr ax,1h
 mov cs:[L025e],ax
 mul bx ;(bx=320)
 pop bx
 mov cx,ax
 sub cs:[blocklength],ax

 mov ax,cs:[L025c]
 sub ax,350
 shr ax,1h
 sub ax,cs:[L025c]
 neg ax
 dec ax
 mov cs:[data000a],ax

 mov cs:[halfaddress],offset pictureoffset
 mov ax,640-1
 mov ax,cs:[L025e]
 dec ax
 neg ax
 mov cs:[data000e],ax
 mov cs:storedlength,ax
 call entrydraw ;Draw

 mov ax,cs:[L025e]
 sub cs:[data000a],ax
 mov ax,350
 sub ax,cs:[L025e]
 dec ax
 neg ax
 mov ax,cs:[storedlength]
 mov cs:[data000e],ax
 mov cs:[halfaddress],offset pictureoffset+32320
 call entrydraw ;Draw
 ret

;-----
  
L14C3:
 mov cs:[data00ae],0000h
 mov cs:[data00b0],0000h
 mov ax,0
 cmp cs:[data004a],ax
 jl L14F7 
 mov si,015dh
 cmp cs:[data004c],si
 jg L14F7 

 mov cx,640-1
 cmp cs:[data0046],cx
 jg L14F7 
 mov dx,5Eh
 cmp cs:[data0048],dx
 jge L14F8 
L14F7:
 ret 

L14F8:
 cmp cs:[data0046],ax
 jge L151B
 xchg ax,cs:[data0046]
 test cs:[data0045],20h
 jnz L151B
 sub ax,cs:[data0046]
 neg ax
 mov cs:[data00ae],ax
L151B:
 cmp cs:[data0048],si
 jle L1534
 xchg si,cs:[data0048]
 test cs:[data0045],10h
 jnz L1534
 sub si,cs:[data0048]
 mov cs:[data00b0],si
L1534:
 cmp cs:[data004a],cx
 jle L154D 
 xchg cx,cs:[data004a]
 test cs:[data0045],20h
 jz L154D
 sub cx,cs:[data004a]
 mov cs:[data00ae],cx
L154D:
 cmp cs:[data004c],dx
 jge L1568 
 xchg DX,cs:[data004c]
 test cs:[data0045],10h
 jz L154D
 sub dx,cs:[data004c]
 neg dx
 mov cs:[data00b0],dx
L1568:
 ret 

;-----

ENTRYDRAW:
 mov cs:[data0045],81h

 mov ax,0

 mov cs:[data0046],ax
 mov ax,cs:[data000a]
 neg ax 
 add ax,015Dh
 mov cs:[data0048],ax
 mov ax,640-1
 add ax,cs:[data0046]
 cmp ax,cs:[data0046]
 jge L140C 
 xchg ax,cs:[data0046]
 or cs:[data0045],20h
L140C:
 mov cs:[data004a],ax
 mov ax,cs:[data000e]
 neg ax 
 add ax,cs:[data0048]
 cmp ax,cs:[data0048]
 jle L1423 
 xchg ax,cs:[data0048]
 or cs:[data0045],10h
L1423:
 mov cs:[data004c],ax
 test cs:[data0045],40h
 jz L1433 
 call L14C3 
L1433:
 mov ax,cs:[data004a]
 sub ax,cs:[data0046]
 inc ax 
 mov cs:[data0058],ax
 mov cx,cs:[data0046]
 mov cs:[data0052],0001h
 test cs:[data0045],02h
 jnz L1456 
 test cs:[data0045],08h
 jnz L145C 
 jmp short L1466 
L1456:
 test cs:[data0045],20h
 jz L1466 
L145C:
 mov cx,cs:[data004a]
 neg cs:[data0052]
L1466:
 mov ax,cs:[data0048]
 sub ax,cs:[data004c]
 inc ax 
 mov cs:[data005a],ax

 mov ax,80
 neg ax 
 mov cs:[data0054],ax
 mov ax,cs:[data0048]
 test cs:[data0045],01h
 jnz L148D 
 test cs:[data0045],04h
 jnz L1493 
 jmp short L1499 

L148D:
 test cs:[data0045],10h
 jz L1499 
L1493:
 mov ax,cs:[data004c] 
 neg cs:[data0054]
L1499:
 push bx
 mov bx,80
 mul bx
 pop bx
 mov bp,ax 
 mov cs:[data0064],bp
 mov di,cx 
 and cx,0007h 
 mov ch,80h 
 shr ch,cl 
 shr di,1 
 shr di,1 
 shr di,1 
 mov cs:[data006c],ch
 mov cs:[data0062],di

 mov dx,03CEH ; Graphics 1 & 2 Address

 mov ax,0205h
 out dx,ax ; Register 5 - Mode register
 mov ax,0003h
 out dx,ax ; Set Write mode 3 (turn off writing)
 mov al,08h
 out dx,al
 inc dx

 push ax
 mov ax,0A000h
 mov es,ax
 pop ax

 mov si,cs:[halfaddress]
 mov bp,cs:[data0062]
 add bp,cs:[data0064]
L19F8:
 mov cx,cs:[data0058]
 mov al,cs:[data006c]
 call L1A1C
 add si,320
 add bp,cs:[data0054]
 dec cs:[data005a]
 jg L19F8

 mov dx,03CEh ; Graphics 1 & 2 Address
 mov ax,0FF08h
 out dx,ax ;Register 8 - Bit mask

 mov ax,0005
 out dx,ax
 mov ax,0003h ; Only alter lower two bits ???
 out dx,ax
 ret

L1A1C:
 push si
 push bp
L1A1E:
 mov bh,[si]
 shr bh,1
 shr bh,1
 shr bh,1
 shr bh,1
 out dx,al
 mov ah,es:[bp+00h]
 mov es:[bp+00h],bh
 dec cx
 jle L1A52
 ror al,1
 jnb L1A39
 inc bp
L1A39:
 mov bh,[si]
 inc si
 out dx,al
 mov ah,es:[bp+00h]
 mov es:[bp+00h],bh
 dec cx
 jle l1A52
 ror al,1
 jnb L1A1E
 inc bp
 jmp short L1A1E
L1A52:
 pop bp
 pop si
 ret

;-----

;CRT Control Registers:

controlregisters:
 db 5Bh      ;Register 0, Horizontal total
 db 4Fh      ;Register 1, Horizontal display end
 db 53h ;3C  ;Register 2, Start horizontal blank
 db 37h      ;Register 3, End horizontal blank
 db 52h      ;Register 4, Start horizontal retrace
 db 00h      ;Register 5, End horizontal retrace
 db 6Ch ;40  ;Register 6, Vertical total
 db 1Fh      ;Register 7, Overflow
 db 00h      ;Register 8, Preset row scan
 db 00h      ;Register 9, Max scan line
 db 00h ;44  ;Register A, Cursor start
 db 00h      ;Register B, Cursor end
 db 00h      ;Register C, Start address hi
 db 00h      ;Register D, Start address lo
 db 00h ;48  ;Register E, Cursor location hi
 db 00h      ;Register F, Cursow location lo
 db 5Eh      ;Register 10, Vertical retrace start
 db 2Bh      ;Register 11, Vertical retrace end
 db 5Dh ;4C  ;Register 12, Vertical display end
 db 28h      ;Register 13, Offset
 db 0Fh      ;Register 14, Underline location
 db 5Fh      ;Register 15, Start vertical blank
 db 0Ah ;50  ;Register 16, End vertical blank
 db 0E3h     ;Register 17, Mode control 
 db 0FFh     ;Register 18, Line compare

 db 0

;-----

;Graphics Controller Registers:
;Graphics 1 & 2 Address Registers (Page 47):

graphicsregisters:
 db 00h          ;(Register 0, Set/Reset mode)
 db 00h          ;(Register 1, Enable set/reset)
 db 00h ;84      ;(Register 2, Colour Compare)
 db 00h          ;(Register 3, Data Rotate, Rotate=0, Unmodified)
 db 00h          ;(Register 4, Read map select. Use screen page 0)
 db 00h          ;(Register 5, Mode - Write mode 0)
 db 00h ;88      ;(Register 6, Misc - Map at A000. Graphics mode)
 db 05h          ;(Register 7, Colour don't care - Colour planes 2,0)
 db 0Fh          ;(Register 8, Bit mask - Allow all four planes)

endegatable:
code ENDS

 END






