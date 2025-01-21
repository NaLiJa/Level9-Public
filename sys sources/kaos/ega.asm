;IBM KAOS DRIVER. Routines just for EGA graphics

;EGA.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

pictureoffset=0 ;Offset into Pgraphicsbuffer of screen data

 public DoBitmapPalette
 public cgatranslate
 public drawegaline
 public drawM13line
 public egacopytoscreen
 public egafastcharacterenable
 public ega_14_16_transferrowrow
 public DoCompressedEgaPalette
 public mode13transferrow

;In ENTRY.ASM:
 extrn screenmode:byte

;In MENU.ASM
 extrn ModuleName:byte

;In HIRES.ASM:
 extrn picnumber:word
 extrn taskaddress:word

 name ega

code segment public 'code'
 assume cs:code,ds:code

;These include files must be named in MAKE.TXT:
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

;(Mode 6 requires pallette set-up in memory
; as RGBrgb, but not written to screen.)

 cmp ds:[screenmode],19 ;MCGA
 jz se04

 cmp ds:[screenmode],13 ;redefinable palette required EGA card
 jc se04 ;Not EGA or EGA-emulation
 cmp ds:[screenmode],16 ;Mode 16 uses 64-colour palette
 jz se03 ;EGA
 test byte ptr ds:newpalette,080h ;Already converted to IRGB?
 jnz se03

;EGA-emulation, must convert palette back to IRGB
 mov si,offset newpalette
 mov cx,16
se01:
 mov al,ds:[si]
 mov bh,0
 mov bl,al
 mov al,byte ptr ds:cgatranslate[bx] ;Get xxxxIRGB
 test al,08h
 jz se02
 and al,07h
 or al,10h
se02: ;al is now colour xxxIxRGB

 mov ds:[si],al
 inc si
 loop se01

se03:
 and byte ptr ds:newpalette,07Fh ;Reset translation bit

 push cs
 pop es
 mov dx,offset newpalette
 mov ah,10h
 mov al,2
 int 10h

 or byte ptr ds:newpalette,080h ;Set top bit to indicate translation

 call PossibleVgaDACsetup

se04:
 pop si
 pop ds
 pop es
 ret

;-----

;The picture has now been displayed as EGA.
;If VGA-analogue colours were selected from the menu, and

PossibleVgaDACsetup:
 push cs
 pop ds

 cmp byte ptr cs:MenuFsubmode,vga_illegal
 jnz pv02

;*nick 21/9/89...
 push cs
 pop es
 mov dx,offset vgapaletteptrs
 mov ah,10h
 mov al,2
 int 10h
;*

 mov es,cs:MenuPcache
 mov si,ds:taskaddress

;The cache loader flips the length bytes to be low-high (and increments it)  
 mov bx,es:0[si]
 add bx,si
 sub bx,3*32+6 ;Move back to start of added parameters

;es:[bx] is non-EGA picture parameter area

 cmp byte ptr es:0[bx],'('
 jnz pv02
 cmp byte ptr es:1[bx],'C'
 jnz pv02
 cmp byte ptr es:2[bx],')'
 jnz pv02
 cmp byte ptr es:3[bx],'L'
 jnz pv02
 cmp byte ptr es:4[bx],'9'
 jnz pv02

 add bx,5+2*32 ;Get last palette table for programming into to DAC

;es:[bx] is our VGA palette
;cs:mappingtable is indexed by the logical colour in the picture file
; and the lower 4 bits of the result is the logical colour to display it as.

;We want to take each of the 16 colours and program the DAC.

 mov cx,16 ;number of colours
 mov dl,0 ;logical colour (index into es:[bx])
pv01:
 push bx
 push cx
 push dx
 call DoOneVgaColour
 pop dx
 pop cx
 pop bx
 inc dl
 add bx,2
 loop pv01

pv02:
 ret

;-----

;In VGA palette (ega) registers are still used but value (0..3F)
;is index to colour DAC register. This table turns off the EGA palette
;so the logical colour directialy selects the same DAC register
vgapaletteptrs:
 db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0 ;16 dac reg numbers + border value

;-----

;es:[bx] is the current VGA value
;dl is the logical colour in the cache.

DoOneVGAcolour:
 mov ah,es:0[bx]             ;VGA value (ST-lookalike)
 mov al,es:1[bx]

 mov bh,0
 mov bl,dl
 mov bl,cs:mappingtable[bx] ;get logical colour on display
 and bl,15
 
 push ax ;ST-look alike colour (9 bits)

 mov ax,1007h ;ah=10 for Video Service, al=7 Read palette register
 mov bh,0     ; high byte of palette register number (even thou only 16)
 int 10h

;bh=The value programmed for an EGA display. On a VGA card this will be
;used as bits 5-0 of the DAC index. (Bits 7-6 are the ColourSelectRegister)
;* and bh,3Fh

 pop ax    ;ST look-alike colour
 mov bl,bh ;DAC register

SetDAC_AXBL:
 and ax,777h ;....rrr.ggg.bbb
 jnz NotVgaBlack

 xor cx,cx
 mov dh,ch
 jmp short VgaBlack

NotVgaBlack:
 mov cl,al
 rol cl,1
 rol cl,1
 rol cl,1
 and cl,38h ;Mask to give bbb000 DAC blue value
 or cl,7

 mov ch,al
 ror ch,1
 and ch,38h ;Mask to give ggg000 DAC green value
 or ch,7

 rol ax,1
 rol ax,1
 rol ax,1
 mov dh,ah ;Red
 and dh,38h ;Mask to give rrr000 DAC red value
 or dh,7
VgaBlack:

 xor bh,bh
 mov ax,1010h ;ah=10 for Video Service, al=10 for Set DAC register
 int 10h
 ret

;-----

;Set up colour palette with colours for text 
;and those colours used in border picture.

;*initpalette:
;* mov si,offset MenuFpalette
;* mov di,offset newpalette
;* mov cx,16
;*cp01:
;* mov al,cs:[si] ;Copy default palette (from PALETTE.PIC)
;* mov cs:[di],al
;* inc si
;* inc di
;* dec cx
;* cmp cx,0
;* jnz cp01
;* ret

;-----

;Create a new palette for use when the new picture is displayed,
;This is merged from the palette contained in PALETTE.PIC and the
;palette from the picture loaded from disk. Bitmapped picture.

DoBitmapPalette:
;* call initpalette
 mov si,[taskaddress]
 add si,offset BitmapPicColours
 mov es,cs:[MenuPcache]
 jmp short sortpalette

;-----

;Create a new palette for use when the new picture is displayed,
;This is merged from the palette contained in PALETTE.PIC and the
;palette from the picture loaded from disk. Compressed picture.

DoCompressedEgaPalette:
;* call initpalette
 mov si,dx

;Set up palette for new picture and logical colour translation
;table so new picture can be drawn in Copy of Graphics Screen.

sortpalette:
;* push es
;* push si
;* mov si,offset MenuFborder
;* mov cx,30 ;Number of pictures in MenuFborder list
;*nick00:
;* mov al,cs:[si]
;* or al,al
;* jz nick01 ;End of picture list
;* cmp al,byte ptr cs:picnumber
;* jz nick02  ;Got a picture which sets the border colours
;* inc si
;* loop nick00
;* jmp short nick01 ;picture list full.
;*
;*nick02:
;* pop si
;*
;*;Save all the colours used in this picture, for use if the next
;*;picture loaded is not a 'border' picture
;* push si
;* mov di,offset BorderPalette
;* mov cx,16
;* mov ax,cs
;* mov ds,ax
;* mov es,ax
;* rep movsb
;*nick01:
;* pop si
;*
;*;newpalette is now set to all 99's, except those logical colours
;*;which are fixed (text colours), see if any border colours need to
;*;be added to this list
;*
;* push si
;* mov si,offset newpalette
;* mov di,offset borderpalette 
;* mov bx,cs:MenuFlogical ;bit-list for which colours are border
;*
;* mov dx,1 ;Mask for colour 0
;* mov cx,16
;*
;*nick04:
;* test bx,dx ;This colour should be border?
;* jz nick03 ;No - use picture colour
;* mov al,cs:[di] ;Yes - put border colour in this logical colour position
;* cmp al,99 ;No border loaded yet
;* jz nick03
;* mov cs:[si],al ;Write to 'newpalette' position
;*nick03:
;* rol dx,1 ;Next mask
;* inc si
;* inc di
;* loop nick04
;*
;* pop si
;* pop es

;* mov di,offset mappingtable
;* mov cx,16
;*sp01:
;* mov al,es:[si] ;Get each colour used in this picture
;* push si
;* push di
;* push cx
;* call findorcreatecolour ;Ensure the new palette to use contains this.
;* pop cx
;* pop di
;* pop si
;*
;* mov ah,al
;* shl al,1
;* shl al,1
;* shl al,1
;* shl al,1
;* or al,ah
;*
;* mov ds:[di],al ;Save logical colour map entry
;* inc si
;* inc di
;* dec cx
;* cmp cx,0
;* jnz sp01
;*
;* mov si,offset newpalette ;Replace '99' blanks
;* mov cx,16
;*sp02:
;* cmp byte ptr cs:[si],99
;* jnz sp03
;* mov byte ptr cs:[si],0
;*sp03:
;*
;* inc si
;* dec cx
;* cmp cx,0
;* jnz sp02

;es:[si] is EGA-adjusted palette from picture file

 push es
 push ds
 push si
 mov ax,es
 mov ds,ax
 mov ax,cs
 mov es,ax
 mov di,offset newpalette
 mov cx,16
 rep movsb
 pop si
 pop ds
 pop es

;Some Scapeghost pictures have two whites, so check for pics 1..29 before
;title pic.
 push es
 cmp byte ptr es:12[si],03Fh ;colour 12 = white
 je UseOtherMap
 cmp byte ptr es:11[si],03Fh ;colour 11 = white
 je UseTitleMap

 mov si,offset BadMap
 jmp SetMap
UseTitleMap:
 mov al,byte ptr cs:newpalette+11
 xchg al,byte ptr cs:newpalette+7
 mov byte ptr cs:newpalette+11,al
 mov si,offset TitleMap
 jmp SetMap
UseOtherMap:
 mov al,byte ptr cs:newpalette+12
 xchg al,byte ptr cs:newpalette+7
 mov byte ptr cs:newpalette+12,al
 mov si,offset OtherMap
SetMap:
 mov ax,cs
 mov ds,ax
 mov es,ax
 mov di,offset mappingtable
 mov cx,16
 rep movsb
 pop es
 ret

BadMap:
 db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
TitleMap:
 db 0,11h,22h,33h,44h,55h,66h,0BBh,88h,99h,0AAh,77h,0CCh,0DDh,0EEh,0FFh
OtherMap:
 db 0,11h,22h,33h,44h,55h,66h,0CCh,88h,99h,0AAh,0BBh,77h,0DDh,0EEh,0FFh

;-----

;Ensure palette used for next picture contains colour 'al'

;*findorcreatecolour:
;* mov bx,offset newpalette+15
;* mov cx,15
;*fc01:
;* cmp cs:[bx],al
;* jz fc05 ;palette already contains this colour
;* dec bx
;* cmp cx,0
;* jz fc02
;* dec cx
;* jmp short fc01
;*
;*fc02:
;* mov bx,offset newpalette
;* mov cx,15
;*fc03:
;* cmp byte ptr cs:[bx],99 ;Found empty entry
;* jz fc05
;* inc bx
;* cmp cx,0
;* jz fc04
;* dec cx
;* jmp short fc03
;*
;*fc04:
;* mov cx,0 ;Use logical colour 0
;* jmp short fc06
;*
;*fc05:
;* mov cs:[bx],al ;Store newpalette entry
;*fc06:
;* mov al,cl ;Return new logical colour
;* ret

;-----

;*borderpalette db 16 dup (99) ;Colours used in border, 99=not set

;Colour palette of current display.
;bit 7 if first byte=0 for 64-colour table, =0 for IxRGB values.
newpalette db 16 dup (0)
 db 0 ;Background colour

mappingtable db 16 dup (0)

;-----

;Bitmapped Pictures:
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

;Title picture fits in 64k, all other pictures are displayed height*1.5
;but only in EGA modes 15/16.

 cmp cs:ModuleName,0
 jnz egadontexpand
 cmp cs:screenmode,13 ;EGA-emulation
 jz egadontexpand
 cmp cs:screenmode,14 ;EGA-emulation
 jz egadontexpand
 cmp cs:screenmode,19 ;MCGA
 jz egadontexpand

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

;Bitmapped Pictures:
;Plot one picture row, from the picture cache to the Copy of Graphics Screen
 
;si = start pixel
;bx = length
;cx/dx = start column/row
;ah = hi/low nybble

;Mode 13. 320-wide 64 colour.

Mode13transferrow:
 push ds ;Save segment registers
 push es

 push es
 pop ds ;Picture cache
 mov es,cs:[MenuPgraphicsbuffer] ;Copy of Graphics Screen

 push ax
 mov ax,160 ;Bytes per screen line
 push dx

 mul dx ;Start offset of screen row
 pop dx
 push cx
 shr cx,1 ;two-pixels per byte
 add ax,cx ;Column offset
 pop cx
 add ax,pictureoffset ;Skip parameter block
 mov di,ax
 pop ax

;di = Address if Pgraphicsbuffer.

 cmp ah,0 ;Nybble to read is high nybble/low nybble
 jnz short M13PlotLow ;(Not even column)

 cmp bx,0
 jnz short M13plotHigh

 jmp short M13PlotEnd

M13plotHigh:
 mov al,ds:[si] ;Read pixel data (ds=picture cache)

 shr al,1
 shr al,1
 shr al,1
 shr al,1 ;Get high nybble
 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

 test cl,1
 jnz M13HighEven
 and al,0F0h
 and byte ptr es:[di],00Fh
 or es:[di],al
 jmp short M13HighOdd
M13HighEven:
 and al,00Fh
 and byte ptr es:[di],0F0h
 or es:[di],al
 inc di
M13HighOdd:
;mov es:[di],al ;Set both pixels to same colour (double resolution)
;inc di

 inc cx
 dec bx
 jnz M13PlotLow
 mov ah,1 ;Just process high nybble, next is low.

 jmp short M13PlotEnd

M13PlotLow:
 mov al,ds:[si] ;Read pixel data (es=picture cache)
 and al,0Fh

 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

;Ega 40-column Emulation does not double width
 test cl,1
 jnz M13LowEven
 and al,0F0h
 and byte ptr es:[di],00Fh
 or es:[di],al
 jmp short M13LowOdd
M13LowEven:
 and al,00Fh
 and byte ptr es:[di],0F0h
 or es:[di],al
 inc di
M13LowOdd:

 inc cx
 inc si
 dec bx
 jnz M13plotHigh
 mov ah,0 ;Just processed low nybble, next is high.

M13PlotEnd:
 pop es
 pop ds
 ret

;----------

;Squashed pictures:
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

;Title picture fits in 64k, all other pictures are displayed height*1.5
;but only in EGA modes 15/16.

 cmp cs:ModuleName,0
 jnz compressedegadontexpand
 cmp cs:screenmode,13 ;EGA-emulation
 jz compressedegadontexpand
 cmp cs:screenmode,14 ;EGA-emulation
 jz compressedegadontexpand
 cmp cs:screenmode,19 ;MCGA
 jz compressedegadontexpand

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

;Squashed pictures:
;Transfer data from a line of consecutive pixels stored one pixel
;per byte in a buffer at [di]

drawM13line:
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
 mov ax,160 ;40-column EGA emulation - Bytes per screen line
 push dx

;Title picture fits in 64k, all other pictures are displayed height*1.5
;but only in EGA modes 15/16.

 mul dx ;Start offset of screen row
 pop dx
 push cx
 shr cx,1
 add ax,cx ;Column offset
 pop cx
 add ax,pictureoffset ;Skip parameter block
 mov si,ax
 pop ax

Xpe02:
 cmp cx,bx
 jge Xpe03
 mov al,cs:[di]

 xchg ax,bx
 mov bh,0
 mov bl,cs:mappingtable[bx]
 xchg ax,bx

;Ega 40-column Emulation does not double width
 test cl,1
 jnz yeven
 and al,0F0h
 and byte ptr es:[si],00Fh
 or es:[si],al
 jmp short yoff
yeven:
 and al,00Fh
 and byte ptr es:[si],0F0h
 or es:[si],al
 inc si
yoff:

 inc di
 inc cx
 jmp short Xpe02

Xpe03:
 pop es
 pop ds
 ret

;----------

;End of picture drawing, All Black and white modes draw directly to the
;screen, so nothing further is required. All Colour modes draw in
;memory, so copy this to the screen.

egacopytoscreen:
 cmp ds:screenmode,19
 jnz ec01
 jmp mcgacopy

ec01:
 cmp ds:screenmode,13
 jnc copyegabuffer
 ret ;Black/White does not require copying to screen

copyegabuffer:
 call egaexpand135to200

 cmp byte ptr cs:MenuFsubmode,vga_illegal
 jz ec02

 cmp byte ptr cs:[MenuFsubmode],ega_ultra
 jnz ec03

ec02:
 jmp UltraFastEgaCopyToScreen

ec03:
 cmp byte ptr cs:MenuFsubmode,ega_okish
 jnz ec04

;Super-Fast EGA (transfers 4 pixels at a time):
 call setegapalette
 push ds
 mov ds,cs:[MenuPgraphicsbuffer]
 mov ax,64000
 mov bx,349
 call superfastegacopytoscreen
 pop ds
 ret

ec04:
 call setegapalette

 cmp ds:screenmode,13
 jz ec10 ;EGA-Emulation 320-wide

;Fast and Normal EGA (transfers pixel-by-pixel):

 mov es,cs:[MenuPgraphicsbuffer]
 mov dx,0 ;Row

 cmp cs:screenmode,16
 jz ec05
 mov bx,136 ;normal size for pictures
 cmp cs:ModuleName,0
 jz ec06
ec05:
 mov bx,200 ;normal size for title
ec06:

 mov si,pictureoffset ;offset
ec07:
 cmp bx,0
 jz ec09

 push dx
 push bx
 mov cx,0 ;column
ec08:
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
 jb ec08
 pop bx
 pop dx

 inc dx
 dec bx
 jmp short ec07
ec09:
 ret

;EGA-Emulation 320-wide

ec10:
 mov es,cs:[MenuPgraphicsbuffer]
 mov dx,0 ;Row

 cmp cs:screenmode,16
 jz ec11
 mov bx,136 ;normal size for pictures
 cmp cs:ModuleName,0
 jz ec12
ec11:
 mov bx,200 ;normal size for title
ec12:

 mov si,pictureoffset ;offset
ec13:
 cmp bx,0
 jz ec18

 push dx
 push bx
 mov cx,0 ;column
ec14:
 test cl,1
 jnz ec15
 mov al,es:[si]
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 jmp short ec16
ec15:
 mov al,es:[si]
ec16:
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
 jz ec17
 inc si
ec17:
 inc cx
 cmp cx,320
 jb ec14
 pop bx
 pop dx

 inc dx
 dec bx
 jmp short ec13
ec18:
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
;Title picture fits in 64k, all other pictures are displayed height*1.5
;but only in EGA modes 15/16.

 cmp screenmode,13 ;EGA-Emulation
 jz ep04
 cmp screenmode,14 ;EGA-Emulation
 jz ep04
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
 cmp si,Mode16Screen-320
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

 mov ax,0F02h ;Reset register 2 to process all four bit-planes.
 out dx,ax

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

;Copy stored mode-13 like screen to MCGA 256-colour screen
;MCGA colours used are 16-31, to avoid conflict with colours
;used for text.

mcgacopy:
 mov es,cs:MenuPcache
 mov si,cs:taskaddress

;The cache loader flips the length bytes to be low-high (and increments it)  
 mov bx,es:0[si]
 add bx,si
 sub bx,3*32+6 ;Move back to start of added parameters

;es:[bx] is non-EGA picture parameter area

 cmp byte ptr es:0[bx],'('
 jnz oldSquash
 cmp byte ptr es:1[bx],'C'
 jnz oldSquash
 cmp byte ptr es:2[bx],')'
 jnz oldSquash
 cmp byte ptr es:3[bx],'L'
 jnz oldSquash
 cmp byte ptr es:4[bx],'9'
 jnz oldSquash

 add bx,5+2*32 ;Get last palette table for programming into to DAC
 jmp short NewSquash

OldSquash:
 mov si,cs:taskaddress
;The cache loader flips the length bytes to be low-high (and increments it)  
 mov bx,es:0[si]
 add bx,si
 add bx,palette

NewSquash:
 mov cx,16 ;Number of colours
 mov dl,0 ;Logical colour
mcgaloop:
 push bx
 push cx
 push dx

;es:[bx] is our VGA palette
 mov ah,es:0[bx]
 mov al,es:1[bx] ;ST look-alike colour

 mov bh,0
 mov bl,dl
 mov bl,cs:mappingtable[bx] ;get logical colour on display
 and bl,15
 or bl,10h
 
 call SetDAC_AXBL

 pop dx
 pop cx
 pop bx
 inc dl
 add bx,2
 loop mcgaloop

;Put picture on screen.

 mov ax,0A000h
 mov es,ax
 mov ds,cs:MenuPgraphicsBuffer
 mov si,0 ;Index into 32K of 320x200 pixels
 mov di,0 ;Index into 64K 256-colour MCGA screen

 mov cx,320*136/2 ;Number of double-pixels to process
 cmp cs:ModuleName,0
 jz mc01
 mov cx,320*200/2 ;Number of double-pixels to process

mc01: 
 mov al,ds:[si]
 ror al,1
 ror al,1
 ror al,1
 ror al,1
 and al,0Fh
 or al,10h
 stosb ; mov es:[di],al : inc di

 mov al,ds:[si]
 and al,0Fh
 or al,10h
 stosb ; mov es:[di],al : inc di

 inc si
 loop mc01

 push cs
 pop ds
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
 cmp cs:ModuleName,0
 jnz size16
 cmp cs:screenmode,14
 jz size14
 cmp cs:screenmode,13
 jz size13
;EGA mode 15/16
size16:
 mov cs:blocklength,Mode16Screen ;EGA mode 15/16 (350 high)
 jmp short sizeset
size13:
 cmp cs:ModuleName,0
 jnz sizeT13
 mov cs:blocklength,Mode13Screen ;EGA-emulation mode 13 
 jmp short sizeset
sizeT13:
 mov cs:blocklength,32000 ;EGA mode 13 Title
 jmp short sizeset
size14:
 cmp cs:ModuleName,0
 jnz sizeT14
 mov cs:blocklength,Mode14Screen ;EGA-emulation mode 14
 jmp short sizeset
sizeT14:
 mov cs:blocklength,64000 ;EGA mode 14 title
sizeset:

 mov ax,015Eh
 mov cs:[data000e],ax

 mov ax,cs:[data000e]
 mov cs:[L025c],ax

 mov dx,0
 mov ax,cs:blocklength
 push bx
 mov bx,320
 div bx ;(bx=320)
 shr ax,1h
 mov cs:[L025e],ax
 mul bx ;(bx=320)
 pop bx
 mov cx,ax
 sub cs:blocklength,ax

 mov ax,cs:[L025c]
 sub ax,350
 shr ax,1h
 sub ax,cs:[L025c]
 neg ax
 dec ax
 mov cs:[data000a],ax

 mov cs:halfaddress,pictureoffset
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

 cmp cs:ModuleName,0
 jnz midpoint16
 cmp cs:screenmode,13
 jz midpoint13
 cmp cs:screenmode,14
 jz midpoint14
;EGA mode 15 or 16.
midpoint16:
 mov cs:halfaddress,pictureoffset+32320 ;EGA mode 15/16 (350 high)
 jmp short midpoint

midpoint13:
 cmp cs:ModuleName,0
 jnz midpointT13
 mov cs:halfaddress,pictureoffset+10880 ;EGA-emulation mode 13 
 jmp short midpoint
midpointT13:
 mov cs:halfaddress,pictureoffset+16000 ;EGA-emulation mode 13 
 jmp short midpoint

midpoint14:
 cmp cs:ModuleName,0
 jnz midpointT14
 mov cs:halfaddress,pictureoffset+21760 ;EGA-emulation mode 14
 jmp short midpoint
midpointT14:
 mov cs:halfaddress,pictureoffset+32000 ;EGA-emulation mode 14
midpoint:

 jmp entrydraw ;Draw

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

 mov si,cs:halfaddress
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

code ENDS

 END






