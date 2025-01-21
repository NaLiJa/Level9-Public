;IBM KAOS DRIVER, routines for graphics/cache

;HIRES.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name driver

 public ClearTitle
 public cgapictureshown
 public currentpicture
 public displayhires
 public drawentirepicture
 public lastpicdrawn
 public picnumber
 public picturelines
 public setpictures
 public sp02
 public storedecimal
 public taskaddress

;In EDSQU.ASM/MENU.ASM:
 extrn ModuleName:byte

;In ENTRY.ASM:
 extrn screenmode:byte

;In DRIVER.ASM/ENTRY.ASM:
 extrn characterwidth:byte
 extrn filenamebuffer:byte
 extrn SafeReplaceCursor:near
 extrn setoscursor:near

;In CGA.ASM/MENU.ASM:
 extrn cgacopytoscreen:near
 extrn cgatransferrow:near

;In MENU.ASM/MGA.ASM:
 extrn mgacopytoscreen:near
 extrn mgatransferrow:near

;In CACHE.ASM/DCACHE.ASM:
 extrn cachetablefull:near
 extrn incache:near
 extrn junkoldest:near
 extrn loadintocache:near

;In DECOMP.ASM:
 extrn checkrightkindoffile:near
 extrn decompresspicture:near
 extrn GetBitMapColours:near
 extrn setuppalette:near

;In EGA/EDEQA.ASM:
 extrn DoBitmapPalette:near
 extrn egacopytoscreen:near
 extrn egafastcharacterenable:near
 extrn ega_14_16_transferrowrow:near
 extrn mode13transferrow:near

;In MENU.ASM:
 extrn savedpictureheight:word

;In GRAPHIC.ASM:
 extrn Clearbottomhalf:near

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

code segment public 'code'
 assume cs:code,ds:code

prntblpointer dw 0

picnumber dw 0

lastpicdrawn dw 0

Xoffset dw 0

Yoffset dw 0

taskaddress dw 0 ;Picture drawn by graphics task

cgapictureshown db 0 ;0=blank, 1=not shown this command, 2=shown recently

;-----


currentpicture:
 mov ax,0
 mov [si],ax
 ret

;-----

displayhires:
 push si
 call drawhires
 pop si
 mov 0[si],al
 ret

;-----

;As driver call 32, but return code is AL.

drawhires:
 mov al,cs:[MenuFgraphicPossible]
 cmp al,0
 jnz dh01
 jmp short dh10 ;Screen mode does not allow graphics

dh01:
;Picture zero never exists, but is requested by acode
;quite freqeuntly, so reduce disk accesses by ignoring it here.

 cmp word ptr ds:0[si],0
 jz dh02
 cmp word ptr ds:0[si],200
 jnz dh03
dh02:
 mov al,1 ;Return code - picture not drawn
ret

dh03:
 call centrepicture ;BX is Y offset, CX is X offset

 mov ah,0[si] ;Picture number, hi byte first
 mov al,1[si]

;Draw picture AX at (CX,BX), return code in AL

 mov ds:[Xoffset],cx
 mov ds:[Yoffset],bx
 cmp ax,ds:[lastpicdrawn]
 jz lp01 ;repeated picture request, ignored in all but CGA colour mode

 mov ds:[picnumber],ax
 call incache
 mov ds:[taskaddress],bx ;Set address of picture for task to draw next
 jz short dh07 ;Picture already in cache

;Each picture is either 13K, 21K or 33K so a cache table of 5 pictures should
;exceed 65K - larger than the cache is ever allocated.

dh04:
 call cachetablefull
 jz dh06
 jmp short dh05 ;Cache table is full. (This is unlikely)

dh06:
 call loadintocache
 cmp al,1 ;Disk missing
 jz dh10
 cmp al,2 ;File missing, (or corrupted)
 jz dh10
 cmp al,3 ;Not enough space
 jnz dh07

;Either cache table is full (unlikely) or cache itself is.

dh05:
 call junkoldest
 jz dh04
 jmp short dh10 ;Picture too big for cache ?

;Picture file missing

dh10:
 mov al,1 ;Return code - picture not drawn
 ret

dh07:
dh09:
 call drawentirepicture

 mov ax,ds:[picnumber] ;Picture loaded, so remember it
 mov ds:[lastpicdrawn],ax
 mov ds:[cgapictureshown],2 ;flag as picture now shown
lp01:
 mov al,0 ;Return code - Already on screen/Now drawing
lp02:
 ret

;-----

;Return BX as Y offset, CX as X offset.

centrepicture:
 mov ch,ds:2[si] ;Arguments stored hi-byte first.
 mov cl,ds:3[si]
 mov bh,ds:4[si]
 mov bl,ds:5[si]
 ret

;-----

;DRAWENTIREPICTURE can either run as a separate task, called
;from GRAPHICSTASK, or as a subroutine called from the end of
;DISPLAYHIRES or from the MENU.

drawentirepicture:
 mov es,cs:[MenuPcache] ;Picture cache

 mov si,ds:[taskaddress]
 cmp byte ptr es:BitmapPicWidth[si],stfileid ;Compressed picture 
 jz de00
 cmp byte ptr es:BitmapPicWidth[si],pcfileid ;Compressed picture 
 jnz de01
de00:
 jmp drawcompressed

;If a compressed picture mis-loads, it can be treated as a bit-map
;picture, this can be validated by checking that the width lies within
;the range of all those pictures previously released.

de01:
 cmp word ptr es:BitmapPicWidth[si],320
 ja de01a
 cmp word ptr es:BitmapPicWidth[si],100
 ja de01b
de01a:
 ret ;Illegal width, corrupted picture
de01b:

 call DoBitmapPalette
 mov si,ds:[taskaddress]

 cmp ds:[screenmode],6
 jnz de02
 push si
 call setuppalette
 pop si
 push si
 call GetBitMapColours
 pop si
de02:

 add si,BitmapPicData ;Offset into picture file for pixel data
 mov ah,0 ;High order byte
 mov dx,ds:[Yoffset] ;Pixel row

de03:
 mov cx,ds:[Xoffset] ;Pixel column

;Find right hand column of picture, then if on screen
;plot the entire pixture width, otherwise plot up to
;the right hand side.

 call setbxpicturewidth
 add bx,cx ;Add width to left column to give right column
 cmp bx,320
 jb short onscreen
 mov bx,320
 sub bx,ds:[Xoffset]
 jmp short de04
onscreen:
 call setbxpicturewidth

de04:
 cmp bx,320
 jbe de05
 mov bx,320
de05:

 push dx

;Colour EGA and EGA-emulation pictures 640-wide:

 cmp ds:screenmode,14
 jb de06a
 push ds
 mov ds,cs:[MenuPgraphicsBuffer]
 call ega_14_16_transferrowrow
 pop ds
 jmp short de07

;EGA-Emulation graphics 320-wide:

de06a:
 cmp ds:screenmode,13
 jb de06
 push ds
 mov ds,cs:MenuPgraphicsBuffer
 call mode13transferrow
 pop ds
 jmp short de07

;CGA and Black/White graphics:

;ah = 0 (high nybble/left pixel), 1 (low nybble/right pixel)
;bx = number of pixels to transfer in this line
;cx = Column to transfer to
;dx = Row to transfer to
;si = index into cache

de06:
 cmp byte ptr cs:[MenuFsubmode],cga_low_res
 jz cm01
 cmp byte ptr cs:[MenuFsubmode],ega_cga_low_res
 jz cm01
 cmp byte ptr cs:[MenuFsubmode],ega_full_low_res
 jz cm01
 call mgatransferrow
 jmp short de07
cm01:
 call cgatransferrow

de07:
 pop dx
 inc dx

 mov bx,dx ;Check height of picture
 push dx
 call setdxpictureheight
 cmp bx,dx
 pop dx
 jz short offend

;EGA has a limit of 64K for Copy of Graphics Screen:
 cmp cs:screenmode,13 ;EGA-emulation
 jz check200
 cmp cs:screenmode,14 ;EGA-emulation
 jz check200
 cmp cs:screenmode,19 ;MCGA
 jz check200
 cmp ds:ModuleName,0
 jnz check200

;EGA pictures must be less than 64K, or 205 scan lines,
;Title picture is displayed as 200 lines, other pictures are 1.5*height
;or 136*1.5 = 204 lines.

 cmp dx,136
 jnc short offend
 jmp de03

;b&w, CGA and EGA-emulation are 200-high screens

check200:
 cmp dx,200 ;Run off bottom of screen?
 jnc short offend
 jmp de03

drawcompressed:
 mov si,[taskaddress]
 call checkrightkindoffile ;Check compressed picture at (es:si)
 jz dc01
 ret ;picture corrupted, ignore it.

dc01:
 mov si,[taskaddress]
 mov cx,[Xoffset]
 mov dx,[Yoffset]
 call decompresspicture

offend:
;dx is number of lines (in pixels) drawn from file,
;expand this to number of pixels drawn in screen buffer memory.
 cmp ds:ModuleName,0
 jnz oe01 ;Title picture is always one pixel per line
 cmp ds:[screenmode],15
 jb oe01 ;EGA-emulation & non-ega pictures are always one pixel per line
 cmp ds:[screenmode],19
 jz oe01 ;MCGA pictures always one pixel per line
 mov ax,dx
 shr ax,1 
 and ax,01FFh
 shl dx,1 
 and dx,01FEh
 sub dx,ax ;(dx*2)-(dx/2) to give 0,2,3,5,6,8,9...
oe01:

 cmp byte ptr cs:[MenuFpicturetype],1
 jz picturesmaller ;Was in PICS, so just display new picture

;If no picture currently displayed clear top window and display it

sp02:
 call extendpicturewindow

picturesmaller:

 mov byte ptr cs:[MenuFpicturetype],1 ;Set to 136-picture size
 call cgacopytoscreen
 call egacopytoscreen
 call mgacopytoscreen
 jmp egafastcharacterenable

;-----

;Acode SCREEN G instruction. Usually when user has typed PICTURES.

setpictures:
 cmp byte ptr cs:[MenuFgraphicpossible],0
 jz sp03

;On CGA graphics picture is displayed whenever a new picture is loaded
;or on SCREEN G. Since some acode do multiple SCREEN G only the first
;SCREEN G after each INPUTLINE is used.

 cmp byte ptr cs:[MenuFsubmode],cga_low_res ;CGA colour graphics?
 jnz sp01
 cmp ds:[cgapictureshown],1 ;Picture in buffer, but not shown since last input?
 jnz sp01
 call cgacopytoscreen ;Switch to CGA colour graphics screen
 mov ds:[cgapictureshown],2
sp01:

;Other graphic screen modes SCREEN G is a null operation if a picture 
;is already displayed

 cmp byte ptr cs:[MenuFpicturetype],0 ;Was WORDS?
 jz sp02 ;then clear top window and display picture
sp03:
 ret ;Already in pictures mode

;-----

ClearTitle:
 cmp byte ptr cs:[MenuFpicturetype],2
 jnz nottitle
 
 call setoscursor
 mov word ptr cs:[MenuFpicturetype],1 ;Set to PICS
 mov dl,dh ;Row number of bottom row
 call Clearbottomhalf
 call Safereplacecursor

nottitle:
 ret

;-----

;dx is number of pixels required in a new pictures, if this results in
;the text window being smaller, the extra text lines now required are
;cleared.

extendpicturewindow:
 call newpicturelines
 cmp al,20
 jnc picsmaller
 mov bl,al
 mov al,0 ;Top line

 mov ch,al ;Top row
 mov dh,bl ;Bottom row
 mov al,0 ;Clear window
 mov cl,0 ;Left column
 mov dl,ds:[characterwidth]
 mov bh,0 ;Clear to black
 mov ah,6 ;Scroll Window Up
 int 10h ;Video Service

picsmaller:
notbigger:
 ret

;-----

;Return DX as the height of the current picture.

setdxpictureheight:
 push si
 mov dx,ds:[Yoffset]
 mov si,ds:[taskaddress]
 add dx,es:BitmapPicHeight[si]
 pop si
 ret

;-----

;Also for compressed pictures returns bx = 0xxFFh.

setbxpicturewidth:
 push si
 mov si,ds:[taskaddress]
 mov bx,es:BitmapPicWidth[si]
 pop si
 ret

;-----

;Returns AX = Number of whole picture lines allocated to picture
;EGA has 14 pixel lines/character, all other modes 8.

picturelines:
 cmp byte ptr cs:[MenuFpicturetype],0 ;Was WORDS?
 jz lines0
newpicturelines:
 cmp cs:screenmode,6
 jz lines6
 cmp cs:screenmode,13 ;EGA-emulation 40 column
 jz lines13
 cmp cs:screenmode,14 ;EGA-emulation 80 column
 jz lines14
 cmp cs:screenmode,16 ;EGA
 jz lines16
 cmp cs:screenmode,19 ;MCGA
 jz lines13           ;MCGA and EGA-emulation(40) are similar
lines0:
 mov ax,0
 ret
lines13:
lines14:
 cmp cs:ModuleName,0
 jnz title13
lines6:
 mov ax,136/8
 ret
title13:
 mov ax,200/8
 ret
lines16:
 mov ax,210/14
 ret

;-----

storedecimal:
;Display number CX in decimal
 mov di,offset filenamebuffer
 mov al,ch
 or al,cl
 jz short sd05

 mov bh,ch
 mov bl,cl

 mov cl,0 ;Reset flag
 mov dx,offset prntbl
 mov ds:[prntblpointer],dx
;Find current digit value
sd01:
 push bx
 mov bx,ds:[prntblpointer]
 mov dl,ds:[bx]
 inc bx
 mov dh,ds:[bx]
 inc bx
 mov ds:[prntblpointer],bx
 pop bx
;Check 5 digits found
 mov al,dh
 or al,dl
 jz sd06

;Find current digit
 mov ch,'0'
sd03:
 xor al,al
 sbb bx,dx
 jb short sd04
 inc ch
 mov al,1
 mov cl,al
 jmp short sd03

sd04:
 add bx,dx
 mov al,cl
 or al,cl
 jz short sd01
 mov al,ch
 call storechar
 jmp short sd01

sd05:
 mov al,'0'
 call storechar
sd06:
 mov word ptr 0[di],'P'*256+'.'
 mov word ptr 2[di],'C'*256+'I'
 mov byte ptr 4[di],0
 ret
 
;-----

storechar:
 mov [di],al
 inc di
 ret

;-----

prntbl:
 dw 10000
 dw 1000
 dw 100
 dw 10
 dw 1
 dw 0 ;end

;-----

code ENDS

 END






