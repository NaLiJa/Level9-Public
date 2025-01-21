;IBM KAOS DRIVER. CGA low-res graphics routines.

;CGA.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name driver

 public cgacopytoscreen
 public cgaforceoff
 public cgatransferrow
 public DoCompressedCgaPalette
 public drawcgaline

;In DRIVER.ASM:
 extrn demoenable:byte
 extrn pushreadkeyboard:near
 extrn readkeyboard:near

;In ENTRY.ASM:
 extrn kbdbuflen:byte

;In DRIVER.ASM:
 extrn screenmode:byte

;In HIRES.ASM:
 extrn taskaddress:word

;In DECOMP.ASM:
 extrn colourtable:byte

;In EGA.ASM:
 extrn cgatranslate:byte

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

toplimit = 36
leftlimit = 80
horizontalstep=2
verticalstep=4

code segment public 'code'
 assume cs:code,ds:code

cgaon db 0

cgaleftmargin db 40 ;Left margin (in bytes, 0-80)

cgatopmargin db 18 ;Top margin (in pixels, 0-36)

cgarefresh db 0 ;Flag set to re-draw screen if margins have changed

cgacursor dw 0

;-----

;Uses a modified screen mode 3, with blink alltibute bit replaced by an
;intensity bit for the background colour, and with 6845 register 9 (scan
;lines/character) set to 1.

;This then allocates screen memory as 80-column 100-rows of
;pairs of bytes (ascii-code then attribute-byte)
;pixel rows 1,2 are rows 1,2 of character row 1.
;pixel rows 3,4 are rows 3,4 of character row 2.
;etc...
;pixel rows 9,10 are rows 1,2 of character row 9.

;All ascii codes are 222 (left block of 8x4 pixels off, right block of 8x4
;pixels on) so backgound colour is the left pixel in each character column,
;foreground colour is the right pixel.

;A copy of the entire screen including border, but excluding ascii-code
;bytes is store in a separate segment, as two pixels per byte.
;Since this is only a 160 by 100 screen and the pictures are designed for
;320 by 136 screen, only a window is displayed, and the area not displayed
;may be changed using cursor keys.

;-----

;Switch to CGA colour graphics screen.

cgacopytoscreen:
;0 =                  ;All modes legal
;1 = ega_not_so       ;EGA not-so-fast & MGA fast
;2 = ega_okish        ;EGA normal
;3 = ega_ultra        ;EGA fast
;4 = cga_low_res      ;CGA low-res
;5 = ega_cga_low_res  ;EGA low-res 40
;6 = ega_full_low_res ;EGA low-res 80

 cmp byte ptr cs:[MenuFsubmode],cga_low_res
 jz mc01
 cmp byte ptr cs:[MenuFsubmode],ega_cga_low_res
 jz mc01
 cmp byte ptr cs:[MenuFsubmode],ega_full_low_res
 jz mc01
 ret ;Not a CGA colour mode

mc01:
 cmp ds:[CgaOn],0 ;Already switched to PICTURE screen, so just re-copy pixels

 jz nick01
 jmp cgaredisplay
nick01:
 mov ds:[CgaOn],1

;Save KAOS cursor

 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 mov ds:[cgacursor],dx

 mov al,3 ;80x25 16-colour
 mov ah,0 ;Video Service - Set Video Mode
 int 10h ;ROM-BIOS Video Service

 call disablescreen ;Avoid flicker and screen disturbance

;EGA card does not upset its vertical-scan size when the scan-lines count
;is twiddled, so set-up is much simpler.

 cmp byte ptr cs:MenuFsubmode,ega_cga_low_res
 jz dontupsetEGA
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jz dontupsetEGA

;Registers 0 thru 3 are set by MS-DOS

 mov ax,4 ;(CGA card/6845 only) Register 4 = 7F
 mov dx,03D4h
 out dx,ax
 inc dx
 mov ax,7Fh
 out dx,ax

;Register 5 is set by MS-DOS

 mov ax,6 ;(CGA card/6845 only) Register 6 = 64
 mov dx,03D4h
 out dx,ax
 inc dx
 mov ax,64h
 out dx,ax

 mov ax,7 ;(CGA card/6845 only) Register 7 = 70
 mov dx,03D4h
 out dx,ax
 inc dx
 mov ax,70h
 out dx,ax

;Register 8 is set by MS-DOS

dontupsetEGA:
 mov ax,9 ;Register 9 = 01
 mov dx,03D4h
 out dx,ax
 inc dx
 mov ax,01h
 out dx,ax

;Registers 9 thru 18 are set by MS-DOS

;Set all ascii codes to 222 (left 8x4 pixels off, right 8x4 pixels on)

 mov ax,0B800h ;Display page
 mov es,ax
 mov di,0

;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.

 mov cx,8000 ;Number of bytes
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jnz heightset1
 mov cx,14000 ;Number of bytes
heightset1:

initcga:
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res ;Full-screen in EGA
 jnz heightset2
 mov cs:cgatopmargin,0
heightset2:

 mov byte ptr es:[di],222 ;(ascii)
 inc di
 mov byte ptr es:[di],0 ;(attribute)
 inc di
 dec cx
 cmp cx,0
 jnz initcga
 jmp short cc01 ;... (remove for screen blanking)

cgaredisplay:
;... call disablescreen ;(add for screen blanking)
cc01:
 mov bh,0
 mov bl,ds:[cgaleftmargin] ;Bytes in left-margin.
 mov dh,0
 mov dl,ds:[cgatopmargin] ;Pixels in top margin

;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.

 mov cx,100 ;Number of lines
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jnz heightset3
 mov cx,175 ;Number of lines
heightset3:

cc02:
 jcxz cc03
 push bx
 push dx
 push cx
 call cgacopyline
 pop cx
 pop dx
 pop bx
 dec cx
 inc dx
 jmp short cc02

cc03:
;Display screen in its new position, and ensure screen remains visible
;for 0.1 sec which is long enough for repeated cursor moves to judge
;where the screen is currently positioned.

 call enablescreen
 mov cx,5 ;5/60 second
 call framedelay
 mov ds:[cgarefresh],0
cc04:

;In demo mode hold screen for 5 seconds, then revert back to text. Do not
;allow window to be positioned.

 cmp ds:[demoenable],0
 jz cc05
 mov cx,5*60 ;5 seconds
 call framedelay
 jmp cgaforceoff

;If the keyboard buffer contains cursor keystrokes then reposition the window
;coords (but do not redisplay) until either the buffer is empty or a non-
;cursor key os found.

cc05:
 cmp ds:[kbdbuflen],kbdbufsize
 jnz cc06
 jmp cgaforceoff ;Buffer full, so exit picture mode

cc06:
 call readkeyboard
 cmp al,0
 jnz cc07 ;Character is waiting, so check if it is cursor move
 cmp ds:[cgarefresh],0
 jnz cgaredisplay ;Window moved since last refresh
 jmp short cc05

cc07:
 cmp al,4 ;Cursor down
 jnz notdown
 mov al,ds:[cgatopmargin]
 cmp ds:[cgatopmargin],0
 jz cc04
 cmp al,verticalstep-1
 jc cd01
 sub al,verticalstep
 jmp short cd02
cd01:
 mov al,0
cd02:
 mov ds:[cgatopmargin],al
 mov ds:[cgarefresh],1
 jmp short cc04

notdown:
 cmp al,6 ;Cursor right
 jnz notright
 mov al,ds:[cgaleftmargin]
 cmp ds:[cgaleftmargin],0
 jz cc04
 cmp al,horizontalstep-1
 jc nd01
 sub al,horizontalstep
 jmp short nd02
nd01:
 mov al,0
nd02:
 mov ds:[cgaleftmargin],al

 mov ds:[cgarefresh],1
 jmp short cc04

notright:
 cmp al,2 ;Cursor left
 jnz notleft
 mov al,ds:[cgaleftmargin]
 cmp al,leftlimit
 jnc cc04
 cmp al,leftlimit-horizontalstep
 jnc nr01
 add al,horizontalstep
 jmp short nr02
nr01:
 mov al,leftlimit
nr02:
 mov ds:[cgaleftmargin],al
 mov ds:[cgarefresh],1
 jmp cc04

notleft:
 cmp al,21 ;Cursor up
 jnz notup

;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.

 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jz nl03

 mov al,ds:[cgatopmargin]
 cmp al,toplimit
 jnc nl03
 cmp al,toplimit-verticalstep
 jnc nl01
 add al,verticalstep
 jmp short nl02
nl01:
 mov al,toplimit
nl02:
 mov ds:[cgatopmargin],al
 mov ds:[cgarefresh],1
nl03:
 jmp cc04

notup:
 cmp al,9 ;TAB or Reverse TAB
 jz cgaforceoff ;TAB toggles back to text screen

 call pushreadkeyboard ;Return that code to keyboard buffer

;If running in CGA colour graphics mode and the graphics screen is currently
;switched in, then switch back to the text screen.

cgaforceoff:
 cmp byte ptr cs:[MenuFsubmode],cga_low_res
 jz co01
 cmp byte ptr cs:[MenuFsubmode],ega_cga_low_res
 jz co01
 cmp byte ptr cs:[MenuFsubmode],ega_full_low_res
 jz co01
 jmp short notcga
co01:

 cmp ds:[CgaOn],0
 jz notcga ;Currently text displayed

 mov ds:[CgaOn],0

;Switch back to a 40/80 screen mode (this clears the screen, turn off the
;cursor, then wait to allow sync to re-lock with the screen blank. then
;replot ascii-attribute screen.

 mov ah,0 ;Video Service - Set Video Mode
 mov al,ds:[screenmode]
 int 10h ;ROM-BIOS Video Service

 mov dh,25 ;Invalid row position
 mov dl,90 ;Column
 mov bh,0 ;Display page 0 (text mode only)
 mov ah,2 ;Service 2 - Set Cursor Position
 int 10h ;ROM-BIOS video service

 mov cx,10 ;1/6 sec delay to allow monitor to lock to new sync
 call framedelay

 push ds
 mov ds,cs:[MenuPtextmap]
 mov ax,0B800h
 mov es,ax
 mov si,0
 mov di,0
 mov cx,cs:[MenuLtextmap]
setcolours:
 jcxz cf02

;There is enough time on the slowest of IBMs to plot 3 character rows
;(6 in 40-column mode) during frame sync. Then wait until start of next sync
;to avoid screen flicker.

 mov al,cl
 and al,3Fh ;3*80
 cmp al,0
 jnz cf01
 call waitidle ;Wait until next frame sync
cf01:

 mov al,ds:[si]
 mov es:[di],al ;set ascii code
 inc si
 inc di
 mov byte ptr es:[di],charactercolour ;Set attribute
 inc di
 dec cx
 jmp short setcolours
cf02:
 pop ds

;Re-position KAOS cursor

 mov dx,ds:[cgacursor]
 mov bh,0 ;Display page 0 (text mode only)
 mov ah,2 ;Service 2 - Set Cursor Position
 int 10h ;ROM-BIOS video service

notcga:
 ret

;-----

enablescreen: ;Set to 160x100 graphics with video
;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.
 cmp byte ptr cs:MenuFsubmode,cga_low_res
 jz cgaenablescreen
 cmp byte ptr cs:MenuFsubmode,ega_cga_low_res
 jz es00
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jnz es02

es00:
 mov dx,03DAh
 in al,dx   ;Reset flip-flop
 mov dx,03C0h
 mov al,30h ;Enable palette, Register 10 = Mode Control Register
 out dx,al
 mov al,0   ;Disable blink, Disable line graphics, Enable colour 
            ;attributes, set alphanumeric mode
 out dx,al
es02:
 ret

disablescreen: ;Set to 160x100 graphics with no video
;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.

 mov ax,1
 cmp byte ptr cs:MenuFsubmode,cga_low_res
 jz es01
 ret

cgaenablescreen: ;Set to 160x100 graphics with video
 mov ax,9 ;Change to 80x25 with 16-colour background (i.e. disable blink)
es01:
 mov dx,03D8h
 out dx,ax
 ret

;-----

;Wait until start of next frame sync. To avoid flicker we must not read
;or write screen memory between displaying the top character row and the
;bottom character row.

waitidle:
 push ax
 push dx
 mov dx,03DAh
wi01:
 in ax,dx
 test al,8
 jz wi01 ;Wait for sync to start
 pop dx
 pop ax
 ret

;-----

;Wait approx cx frames (i.e. fields, or 1/60 sec.)

framedelay: ;cx=Number of frames to wait.
 push ax
 push dx
 mov dx,03DAh
fd01:
 jcxz fd04
fd02:
 in ax,dx
 test al,8
 jz fd02 ;Wait for sync to start
fd03:
 in ax,dx
 test al,8
 jnz fd03 ;Wait for sync to end
 dec cx
 jmp short fd01
fd04:
 pop dx
 pop ax
 ret

;-----

;bx = Bytes in left-margin.
;dx = current row (in picture)
;cx = Lines left undisplayed (on screen)

cgacopyline:
 mov ax,100 ;Number of lines

;4 = cga_low_res      ;CGA card, 100 pixels high
;5 = ega_cga_low_res  ;EGA card with CGA monitor, 100 pixels high
;6 = ega_full_low_res ;EGA card 175 pixels high.
 cmp byte ptr cs:MenuFsubmode,ega_full_low_res
 jnz heightset4
 mov ax,175 ;Number of lines
heightset4:

 sub ax,cx
 mov cx,ax ;row on screen

 mov ax,160
 mul dx
 add ax,bx
 mov si,ax ;Index into picture file

 mov ax,160 ;(160 pixels stored as ascii-attribute)
 mul cx
 inc ax ;(Skip ascii byte)
 mov di,ax ;Index onto screen

 push ds
 mov es,cs:[MenuPgraphicsBuffer]
 mov ax,0B800h
 mov ds,ax

 mov bx,80 ;160-wide screen
cl01:
 cmp bx,0
 jz cl02

 mov al,es:[si]
 mov ds:[di],al ;screen is blanked, so this doesn't flicker
 inc si
 inc di
 inc di
 dec bx
 jmp short cl01

cl02:
 pop ds
 ret

;-----

;Bitmapped Pictures:
;Trasfer one line of windowed picture from cache to Pgraphicsbuffer

;ah = 0 (high nybble/left pixel), 1 (low nybble/right pixel)
;bx = number of pixels to transfer in this line
;cx = Column to transfer to
;dx = Row to transfer to
;si = index into cache

cgatransferrow:
 push dx
 push ds
 push es

 push es
 pop ds
 mov es,cs:[MenuPgraphicsBuffer]

;ds = Picture Cache
;es = Copy of Graphic Screen

 push ax
 push cx
 shr cx,1 ;Store as two pixels per byte
 mov ax,160 ;320 pixels=160 bytes
 mul dx
 add ax,cx
 mov di,ax ;Index into Copy of Graphic Screen
 pop cx
 pop ax

 cmp bx,0
 jz cgatransferend ;zero width

 cmp ah,0 ;Indicates low/high nybble to use for first pixel of line
 jnz short transferlownybble

transferhighnybble: ;(ah=0) Plot pixel from high nybble
 mov al,ds:[si] ;Read pixel data (from cache)

 shr al,1
 shr al,1
 shr al,1
 shr al,1 ;(2 clock cycles each)

 call cgasetpoint

 inc cx ;Next column
 test cl,1
 jnz tr01
 inc di
tr01:
 dec bx ;pixels left
 jz cgatransferendhigh ;End of line

transferlownybble: ;(ah=1) ;Plot pixel from low nybble
 mov al,ds:[si] ;Read pixel data
 and al,0Fh

 call cgasetpoint

 inc cx
 test cl,1 ;Every two pixels change to next byte
 jnz tr02
 inc di
tr02:

 inc si ;done both nybbles so get next byte
 dec bx ;pixels left
 jnz transferhighnybble ;still more pixels on this line

 mov ah,0 ;Ended with low nybble, so next line starts with high nybble
 jmp short cgatransferend

cgatransferendhigh:
 mov ah,1 ;Ended with high nybble, so next line starts with low nybble

cgatransferend: ;No pixels plotted, (so return original si,bx,ah)
 pop es
 pop ds
 pop dx
 ret

;-----

;Must have done DoCompressedEgaPalette first. Translates rbgRGB pallette
;used in EGA modes to an IRGB palette table for CGA mode. 

DoCompressedCgaPalette:
 push di
 push cx
 mov si,offset colourtable ;rgbRGB palette
 mov di,offset irgbpalette ;coverted IRGB palette
 mov cx,16
pc00:
 mov al,cs:[si]
 push si
 mov si,offset cgatranslate
 mov ah,0
 add si,ax
 mov al,cs:[si] ;Get converted IRGB
 pop si
 mov cs:[di],al

 inc si
 inc di
 dec cx
 cmp cx,0
 jnz pc00

 pop cx
 pop di
 ret

;-----

;Squashed pictures:
;A line of up to 320 pixels store one pixel per byte at [di] to be copied 
;to Copy of Graphics Screen, two pixels per byte. 'colourtable' stores the 
;colour palette

; cx = Xposition
; dx = yposition
; di = lineofpixelsptr
; bx = rightboundary

drawcgaline:
 push ds
 push es

 push es
 pop ds
 mov es,cs:[MenuPgraphicsBuffer]

;ds = Picture Cache
;es = Copy of Graphic Screen

;Calculate di=destination address for first pixel to copy

 push ax
 push cx
 shr cx,1 ;Store as two pixels per byte
 mov ax,160 ;320 pixels=160 bytes
 mul dx
 add ax,cx
 mov si,ax ;Index into Copy of Graphic Screen
 pop cx
 pop ax

 mov dx,bx ;Save end of line coord

;Destination stores two pixels per byte. Start with second pixel?

 test cl,1
 jnz pc02 ;(Low nybble)

pc01:
 cmp cx,dx ;reached right edge of picture
 jge pc03

;Copy high nybble as next pixel

 mov al,cs:[di] ;read from pixel buffer (lineofpixels)
 mov ah,0 ;Change logical colour to IRGB
 mov bx,ax
 mov al,cs:irgbpalette[bx]

 shl al,1
 shl al,1
 shl al,1
 shl al,1
 and byte ptr es:[si],000Fh ;Change current pixel to black.
 or es:[si],al ;Set pixel to new colour

 inc di ;adjust pointers
 inc cx

pc02:
 cmp cx,dx ;reached right edge of picture
 jge pc03

 mov al,cs:[di] ;read from pixel buffer (lineofpixels)

 mov ah,0 ;Change logical colour to IRGB
 mov bx,ax
 mov al,cs:irgbpalette[bx]

 and byte ptr es:[si],0F0h ;Change current pixel to black.
 or es:[si],al ;Set pixel to new colour

 inc di ;adjust pointers
 inc cx
 inc si ;Next pixel is high nybble so move to next byte

 jmp short pc01

pc03:
 pop es
 pop ds
 ret

irgbpalette db 16

;-----

;CGA colour graphics. Set pixel in Copy of Graphics Screen

;Plot pixel in Copy of Graphics Screen on 320x200 pixel grid.
;AL=Colour, dx=Row, cx=Column
;ds=cache, es=graphics buffer.

cgasetpoint:
 push si

;Change logical colour to IRGB
 mov si,cs:[taskaddress] ;Get address of picture (as loaded from disk) in cache
 add si,offset BitmapPicColours
 mov ah,0
 add si,ax
 mov al,ds:[si] ;Fetch RGBrgb colour stored in file
 mov si,offset cgatranslate
 add si,ax
 mov al,cs:[si] ;Get converted IRGB

 mov ah,0F0h
 test cl,1
 jnz cp01
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 mov ah,00Fh
cp01:
 and es:[di],ah ;Change current pixel to black.
 or es:[di],al ;Set pixel to new colour

 pop si
 ret

;-----

code ends

 end





