;IBM KAOS DRIVER. routines for MGA (mode 6) graphics

;MGA.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name driver

 public DoCompressedMgaPalette
 public drawmgaline
 public mgacopytoscreen
 public mgatransferrow

;In ENTRY.ASM:
 extrn screenmode:byte

;In DECOMP.ASM:
 extrn colourtable:byte

;In MENU.ASM
 extrn ModuleName:byte

;In EGA.ASM:
 extrn drawM13line:near
 extrn mode13transferrow:near

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

code segment public 'code'
 assume cs:code,ds:code

;-----

;Bitmapped Pictures:
;Trasfer one line of windowed picture from cache to Pgraphicsbuffer

mgatransferrow:
 jmp mode13transferrow

;-----

;Squashed pictures:
;Transfer data from a line of consecutive pixels stored one pixel
;per byte in a buffer at [di]

drawmgaline:
 jmp drawM13line

;-----

;Must have run DoCompressedEgaPalette first, palette is
;sorted into luminance intensity order.

DoCompressedMgaPalette:
 push si
 push di
 push ax
 push cx
 push dx

 mov si,offset colourtable
 mov di,offset intensitytable
 mov cx,16
dm01:
 mov dh,0
 mov dl,cs:[si]
 xchg si,dx
 mov al,byte ptr cs:rgbRGBintensity[si]
 xchg si,dx
 mov cs:[di],al
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz dm01

;Fill in current map for sorted order of logical colours

 mov di,offset luminancemap
 mov cx,0
dm02:
 mov cs:[di],cl
 inc di
 inc cx
 cmp cx,16
 jnz dm02

;Now sort both table of luminance values and update map for original
;logical colour to relative intensity

 mov cx,15
dm03:
 push cx

 mov si,offset intensitytable
 mov di,offset luminancemap
dm04:
 mov al,cs:0[si]
 cmp al,cs:1[si]
 jbe dm05

 mov ah,cs:1[si] ;Swap entries
 mov cs:0[si],ah
 mov cs:1[si],al
 mov al,cs:0[di]
 mov ah,cs:1[di]
 mov cs:0[di],ah
 mov cs:1[di],al
dm05:
 inc si
 inc di
 dec cx
 cmp cx,2
 jae dm04

 pop cx
 dec cx
 cmp cx,2

 jnc dm03

;Now create logical colour to luminance table

 mov cl,0
dm06:
 mov dh,0
 mov dl,cl
 mov si,dx
 mov dl,cs:luminancemap[si] ;Get logical colour of dl'th intensity
 mov di,dx
 mov byte ptr cs:luminancetable[di],cl
 inc cl
 cmp cl,16
 jnz dm06
 
 pop dx
 pop cx
 pop ax
 pop di
 pop si
 ret

iv1=12 ; B
iv2=6  ; G
iv3=3  ; R
iv4=4  ; b
iv5=2  ; g
iv6=1  ; r

rgbRGBintensity:
 db 0           ; 000000
 db iv1         ; 000001
 db iv2         ; 000010
 db iv2+iv1     ; 000011
 db iv3         ; 000100
 db iv3+iv1     ; 000101
 db iv3+iv2     ; 000110
 db iv3+iv2+iv1 ; 000111

 db iv4+0           ; 001000
 db iv4+iv1         ; 001001
 db iv4+iv2         ; 001010
 db iv4+iv2+iv1     ; 001011
 db iv4+iv3         ; 001100
 db iv4+iv3+iv1     ; 001101
 db iv4+iv3+iv2     ; 001110
 db iv4+iv3+iv2+iv1 ; 001111

 db iv5+0           ; 010000
 db iv5+iv1         ; 010001
 db iv5+iv2         ; 010010
 db iv5+iv2+iv1     ; 010011
 db iv5+iv3         ; 010100
 db iv5+iv3+iv1     ; 010101
 db iv5+iv3+iv2     ; 010110
 db iv5+iv3+iv2+iv1 ; 010111

 db iv5+iv4+0           ; 011000
 db iv5+iv4+iv1         ; 011001
 db iv5+iv4+iv2         ; 011010
 db iv5+iv4+iv2+iv1     ; 011011
 db iv5+iv4+iv3         ; 011100
 db iv5+iv4+iv3+iv1     ; 011101
 db iv5+iv4+iv3+iv2     ; 011110
 db iv5+iv4+iv3+iv2+iv1 ; 011111

 db iv6+0           ; 100000
 db iv6+iv1         ; 100001
 db iv6+iv2         ; 100010
 db iv6+iv2+iv1     ; 100011
 db iv6+iv3         ; 100100
 db iv6+iv3+iv1     ; 100101
 db iv6+iv3+iv2     ; 100110
 db iv6+iv3+iv2+iv1 ; 100111

 db iv6+iv4+0           ; 101000
 db iv6+iv4+iv1         ; 101001
 db iv6+iv4+iv2         ; 101010
 db iv6+iv4+iv2+iv1     ; 101011
 db iv6+iv4+iv3         ; 101100
 db iv6+iv4+iv3+iv1     ; 101101
 db iv6+iv4+iv3+iv2     ; 101110
 db iv6+iv4+iv3+iv2+iv1 ; 101111

 db iv6+iv5+0           ; 110000
 db iv6+iv5+iv1         ; 110001
 db iv6+iv5+iv2         ; 110010
 db iv6+iv5+iv2+iv1     ; 110011
 db iv6+iv5+iv3         ; 110100
 db iv6+iv5+iv3+iv1     ; 110101
 db iv6+iv5+iv3+iv2     ; 110110
 db iv6+iv5+iv3+iv2+iv1 ; 110111

 db iv6+iv5+iv4+0           ; 111000
 db iv6+iv5+iv4+iv1         ; 111001
 db iv6+iv5+iv4+iv2         ; 111010
 db iv6+iv5+iv4+iv2+iv1     ; 111011
 db iv6+iv5+iv4+iv3         ; 111100
 db iv6+iv5+iv4+iv3+iv1     ; 111101
 db iv6+iv5+iv4+iv3+iv2     ; 111110
 db iv6+iv5+iv4+iv3+iv2+iv1 ; 111111

intensitytable db 16 dup(0)
luminancemap db 16 dup(0)

;-----

;Plot two MGA pixels to real screen with mask 11000000

PlotMGAColumn0:
 cmp byte ptr cs:MenuFsubmode,0
 jz pm01
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 and byte ptr es:[di],03Fh ;Set pixel to black
 or es:[di],al ;Plot new pixel
 ret

;-----

;Plot two MGA pixels to real screen with mask 00110000

PlotMGAColumn1:
 cmp byte ptr cs:MenuFsubmode,0
 jz pm01
 shl al,1
 shl al,1
 shl al,1
 shl al,1
 and byte ptr es:[di],0CFh ;Set pixel to black
 or es:[di],al ;Plot new pixel
 ret

;-----

;Plot two MGA pixels to real screen with mask 00001100

PlotMGAColumn2:
 cmp byte ptr cs:MenuFsubmode,0
 jz pm01
 shl al,1
 shl al,1
 and byte ptr es:[di],0F3h ;Set pixel to black
 or es:[di],al ;Plot new pixel
 ret

;-----

;Plot two MGA pixels to real screen with mask 00000011

PlotMGAColumn3:
 cmp byte ptr cs:MenuFsubmode,0
 jz pm01
 and byte ptr es:[di],0FCh ;Set pixel to black
 or es:[di],al ;Plot new pixel
 ret

pm01:
 push cx
 shl cx,1

 push ax
 shr ax,1
 mov bx,0 ;Page 0
 mov ah,0Ch ;Write Pixel dot
 int 10h ;Video Service
 pop ax

 inc cx
 mov bx,0 ;Page 0
 mov ah,0Ch ;Write Pixel dot
 int 10h ;Video Service

 pop cx
 ret

;-----

luminancetable:
 db 16 dup (0)

EvenShadedBitMasks:
 db 0 ; 0000
 db 0 ; 0000
 db 0 ; 0010
 db 0 ; 0100
 db 3 ; 0011
 db 2 ; 0110
 db 0 ; 1100
 db 1 ; 0101
 db 2 ; 1010
 db 1 ; 0101
 db 2 ; 1010
 db 1 ; 0101
 db 3 ; 0111
 db 3 ; 1101
 db 3 ; 1111
 db 3 ; 1111

OddShadedBitMasks:
 db 0 ; 0000
 db 0 ; 0000
 db 0 ; 0010
 db 1 ; 0100
 db 0 ; 0011
 db 1 ; 0110
 db 3 ; 1100
 db 1 ; 0101
 db 2 ; 1010
 db 1 ; 0101
 db 2 ; 1010
 db 1 ; 0101
 db 1 ; 0111
 db 3 ; 1101
 db 3 ; 1111
 db 3 ; 1111

;-----

mgacopytoscreen:
 cmp ds:screenmode,6
 jnz dontcopy

 push ds
 push es

 mov ds,cs:MenuPgraphicsBuffer
 mov ax,0B800h
 mov es,ax

 mov si,0 ;ds:si is index into stored buffer
 mov di,0 ;es:di is index into screen
 mov dx,0 ;row number

;I assume height of picture is always an even-number
copyloop:
 cmp cs:ModuleName,0
 jnz check136
 cmp dx,136
 jz endcopy
check136:
 cmp dx,200
 jz endcopy

;copy line to screen, translating to b&w using even-row stipple pattern
 call TranslateEvenMGAline
 add di,2000h ;next line on screen (block B)
 inc dx

;copy line to screen, translating to b&w using odd-row stipple pattern
 call TranslateOddMGAline
 sub di,2000h-80 ;Next screen line is block A, 80 bytes per line 
 inc dx

 jmp short copyloop

endcopy:
 pop es
 pop ds

dontcopy:
 ret

;-----

;Points arrive on a 320 x 200 grid in 16 colours.
;MGA screen is 640 x 200 in 2 colours, this is
;extended by shading to 160 x 200 in 6 colours.
;Shading patterns used are:
;   0000
;   0001
;   0011
;   0101
;   0111
;   1111

;Copy a line of 320 colour pixels from ds:si to the screen at es:di
;translating to b&w using even stipple patterns for even rows.

;ds:si colour copy of picture
;es:di real screen
;dx screen row
;ds,es,di,dx must be preserved. si returned as address of next line.

TranslateEvenMGAline:
 push di
 mov cx,0 ;Column

te01:
 mov al,ds:[si] ;Get high nybble as colour pixel
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 call TranslateEvenPixel ;Plot in b&w at es:[di] bits 7,6
 call PlotMGAColumn0

 mov al,ds:[si] ;Get low nybble as colour pixel
 call TranslateOddPixel ;Plot in b&w at es:[di] bits 5,4
 call PlotMGAColumn1
 inc si

 mov al,ds:[si] ;Get high nybble as colour pixel
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 call TranslateEvenPixel ;Plot in b&w at es:[di] bits 3,2
 call PlotMGAColumn2

 mov al,ds:[si] ;Get low nybble as colour pixel
 call TranslateOddPixel ;Plot in b&w at es:[di] bits 1,0
 call PlotMGAColumn3
 inc si

 inc di

 cmp cx,320
 jc te01

 pop di
 ret

;Copy a line of 320 colour pixels from ds:si to the screen at es:di
;translating to b&w using odd stipple patterns for odd rows.

TranslateOddMGAline:
 push di
 mov cx,0 ;Column

to01:
 mov al,ds:[si] ;Get high nybble as colour pixel
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 call TranslateOddPixel ;Plot in b&w at es:[di] bits 7,6
 call PlotMGAColumn0

 mov al,ds:[si] ;Get low nybble as colour pixel
 call TranslateEvenPixel ;Plot in b&w at es:[di] bits 5,4
 call PlotMGAColumn1
 inc si

 mov al,ds:[si] ;Get high nybble as colour pixel
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 call TranslateOddPixel ;Plot in b&w at es:[di] bits 3,2
 call PlotMGAColumn2

 mov al,ds:[si] ;Get low nybble as colour pixel
 call TranslateEvenPixel ;Plot in b&w at es:[di] bits 1,0
 call PlotMGAColumn3
 inc si

 inc di

 cmp cx,320
 jc to01

 pop di
 ret

;-----

;Plot one pixel at (cx,dx) or (es:di)
;al=colour (0-15)
;cx=column, dx=row, es:di=destination byte

;Returns dx,di preserved, cx is next column

TranslateEvenPixel:
 push si

 and al,0Fh
 mov ah,0
 mov si,ax
 mov al,byte ptr cs:luminancetable[si]

 mov si,ax
 mov al,byte ptr cs:EvenShadedBitMasks[si]

 pop si
 inc cx ;next column
 ret

TranslateOddPixel:
 push si

 and al,0Fh
 mov ah,0
 mov si,ax
 mov al,byte ptr cs:luminancetable[si]

 mov si,ax
 mov al,byte ptr cs:OddShadedBitMasks[si] ;Use ODD pattern

 pop si
 inc cx ;next column
 ret

;-----

code ends

 end






