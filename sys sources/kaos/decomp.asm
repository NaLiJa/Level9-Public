;Adventure System, Picture Decompression

;DECOMP.ASM

;Copyright (C) 1988 Level 9 Computing

;-----

 public checkrightkindoffile
 public colourtable
 public decompresspicture
 public GetBitMapColours
 public setuppalette
 public STtoIBM

;In EGA.ASM/EDEGA.ASM:
 extrn DoCompressedEgaPalette:near
 extrn drawegaline:near
 extrn drawM13line:near

;In CGA.ASM/MENU.ASM:
 extrn DoCompressedCgaPalette:near
 extrn drawcgaline:near

;In MENU.ASM/MGA.ASM:
 extrn DoCompressedMgaPalette:near
 extrn drawmgaline:near

;In ENTRY.ASM:
 extrn screenmode:byte 

name decomp

code segment public 'code'
 assume cs:code

; **************************************************************************
; **                                                                     ***
; **                Digitised Picture Compression                        ***
; **                                                                     ***
; **                Lars Nielsen     October 1987                        ***
; **                                                                     ***
; **************************************************************************

;These include files must be named in MAKE.TXT:
 include head.asm

; working stuff, and parameters
compressed_picture_id equ stfileid ; Identify correct kind of picture
Toolong               equ 0FFh     ; An escape value

previouspixel     db 15
huffmandatabuffer dw 0
huffmanshiftcount db 0

sourcepointer dw 0

; buffer used when decompressing the pixels
lineofpixels dw 320 dup(0)

htable dw 2 dup(0)   ; Register A3
lineofpixelsptr dw 0 ; Register A4
writeptr dw 0        ; Register A4

hshiftcount db 0     ; Register D3

pixelpointer dw 0    ; Register D4
hdatabuffer dw 0     ; Register D4

Xposition dw 0       ; Register D5

yposition dw 0       ; Register D6
ycount dw 0
rightboundary dw 0   ; Register D6

lastpixel db 0       ; Register D6

databyte db 0        ; Register D7

;----------

; Entry : Routines grab_data_byte and put_picture_line intialised
;         as required (This should be done within initdecomp)
;         (startpicture) -> Start of file AS IT WAS ON THE DISK, beginning with
;                 the header, followed by compressed data
;         (A6) -> Screen start location (locn. of top left hand corner)
;         D5.W = x offset and D6.W = y offset both in pixels
; N.B. Startpicture points byte 0 of the header, i.e. the l.s.b. of the file length
; Assumed that the Checksum and the File type have already been checked

;Register D5 = xposition
;Register D6 = yposition
;Register A6 = screenptr

decompresspicture: ;Picture at (es:si)
 mov ds:[Xposition],cx ;X
 mov ds:[yposition],dx ;Y

 mov ds:[ycount],0 ;Number of lines displayed

 push ax ; MOVEM.L D0-D7/
 push bx
 push cx
 push dx
 push si
 push di
                    ; BSR checkrightkindoffile  ; make sure file type is correct
                    ; BNE finisheddec           ; stop if not
                    ; BSR initdecomp
                    ; BSR rationaliseoffsets    ; sets D6=0 and D5<16
 call checkrightkindoffile
 jne finisheddec
 call initdecomp

 push es
 push si
 call setuppalette
 pop si
 pop es
                    ; LEA lineofpixels(PC),A4   ; buffer for line of pixels
 mov ds:[lineofpixelsptr],offset lineofpixels
decline:
                    ; CMP.W ysize(A5),D6
                    ; BGE finisheddec
 mov ah,es:ysize[si]
 mov al,es:ysize+1[si]
 cmp ds:[ycount],ax
 jge finisheddec
                    ; JSR decompress_picture_line
 call decompress_picture_line
                    ; MOVE.W xsize(A5),D4       ; number of pixels to plot
 mov ah,es:xsize+0[si]
 mov al,es:xsize+1[si]
 mov ds:[pixelpointer],ax
                    ; BRA plot_picture_line
                    ; ADDQ.W #1,D6
                    ; BRA decline
 call PlotEgaPictureLine
 call PlotEmulationPictureLine
 call PlotMgaPictureLine
 call PlotCgaPictureLine
 inc ds:[yposition] ;Coord to plot to
 inc ds:[ycount] ;Number of lines displayed
 jmp short decline

finisheddec:
 pop di             ; MOVEM.L (A7)+,D0-D7/A0-A6
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 mov dx,ds:[yposition] ;Return bottom line of screen.
 ret                ; RTS

;----------

checkrightkindoffile: ;Check picture at (es:si)
; make sure that the File type word in the header contain
; the value compressed_picture_id. Note that the word is stored
; HI BYTE FIRST as is common on the 68000

 push si
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
 cmp al,es:[si]
 pop si
 jnz checksum3 ;File has been overwritten, so ignore it.

 mov al,es:filetype[si]
 cmp al,compressed_picture_id
 jz checksum3
 cmp al,pcfileid
checksum3:
 ret

;----------

;Bitmapped pictures. Extract colour definitions from file and convert
;to IBM colour palette.

GetBitMapColours:
 mov bx,si
 add bx,offset BitmapPicColours ;Get address of palette
 mov di,offset colourtable
 mov cx,16 ;Number of colours
 jmp short su01

STtoIBM:
 mov bx,si
 add bx,offset palette ;Get address of palette
 mov di,offset colourtable
 mov cx,16 ;Number of colours

su01:
 cmp cx,0
 jnz short su02
 jmp short su03
su02:
 mov al,es:[bx]
 shr al,1
 shr al,1
 and al,1
 add al,al
 add al,al ;Red (high order bit)

 mov ah,al
 mov al,es:[bx]
 shr al,1
 and al,1
 add al,al
 add al,al
 add al,al
 add al,al
 add al,al ;Red (low order bit)

 or ah,al
 inc bx
 mov al,es:[bx]
 shr al,1
 shr al,1
 and al,1 ;Blue (high order bit)

 or ah,al
 mov al,es:[bx]
 shr al,1
 and al,1
 add al,al
 add al,al
 add al,al ;Blue (low order bit)

 or ah,al
 mov al,es:[bx]
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,1
 add al,al ;Green (high order bit)

 or ah,al
 mov al,es:[bx]
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

 mov [di],ah
 inc bx
 inc di
 dec cx
 jmp short su01

su03:
 ret

;-----

setuppalette:
 call STtoIBM
 push es

 push cs
 pop es
 mov dx,offset colourtable
 call DoCompressedEgaPalette
 mov dx,offset colourtable
 call DoCompressedCgaPalette
 mov dx,offset colourtable
 call DoCompressedMgaPalette
 pop es
 ret

colourtable:
 db 16 dup(0)
 db 0 ;Border colour

;----------

initdecomp:
; initialise decompression picture routine
                   ; LEA huffmanshiftcount(PC),A0
                   ; MOVE.W #7,(A0)             ; we will count 8 shifts
                   ; JSR initgrab_data_byte     ; initialise source of data
 mov ds:[huffmanshiftcount],7
 call initgrab_data_byte
                   ; LEA huffmandatabuffer(PC),A0
                   ; JSR grab_data_byte         ; get 1st compressed byte
                   ; MOVE.B D7,1(A0)            ; put in l.s.byte of data buffer
                   ; JSR grab_data_byte
                   ; MOVE.B D7,0(A0)            ; put in m.s.byte of data buffer
 mov bx,ds:[sourcepointer]
 mov ax,es:[bx]
 mov 0[huffmandatabuffer],ax
 add ds:[sourcepointer],2
                   ; LEA previouspixel(PC),A0
                   ; MOVE.B firstpixel(A5),(A0) ; begin chain of pixels
                                                ; with first
 mov al,es:firstpixel[si]
 mov [previouspixel],al
                   ; EXT.L D5
                   ; EXT.L D6
 ret               ; RTS

;----------

;register = pixelcount
;register D6 = lastpixel
;register D4 = hdatabuffer
;register D3 = hshiftcount
;register A3 = htable
;register A4 = lineofpixelsptr

decompress_picture_line:
                    ; MOVEM.L D0-D7/A0-A6,-(A7)
 mov ax,ds:[lineofpixelsptr]
 mov ds:[writeptr],ax
                    ; CLR.L D6                 ; so we can use it as a
                                               ; word value
                    ; LEA previouspixel(PC),A0
                    ; MOVE.B (A0),D6
                    ; MOVE.B (A0),D6
 mov al,[previouspixel]
 mov ds:[lastpixel],al                         ; set up the registers first
                    ; LEA huffmandatabuffer(PC),A0
                    ; MOVE.W (A0),D4
 mov ax,ds:[huffmandatabuffer]
 mov ds:[hdatabuffer],ax
                    ; LEA huffmanshiftcount(PC),A0
                    ; MOVE.W (A0),D3
 mov al,[huffmanshiftcount]
 mov ds:[hshiftcount],al
 mov ax,offset huffmantable
 add ax,si
 mov ds:[htable],ax
                    ; LEA huffmantable(A5),A3    ; A3 remains valid during call
                    ; MOVE.W xsize(A5),D5
 mov ah,es:xsize+0[si]
 mov al,es:xsize+1[si]
 mov cx,ax          ; count x-size pixels
 mov bh,0           ;(Thoughout routine...)

prep1:
                    ; SUBQ.W #1,D5              ; FOR D5 = xsize-1 TO 0
                    ; BCS prepexit              ; unsigned < 0
 jcxz prepexit
 dec cx
 call grabvalue                                 ; result in D7.W
                    ; ASL.B #4,D6
                    ; OR.B D7,D6                ; (last pixel)*16 + likelyhood
 mov bl,ds:[lastpixel]
 shl bl,1
 shl bl,1
 shl bl,1
 shl bl,1
 or bl,ds:[databyte]
 mov ds:[lastpixel],bl
                     ; MOVE.B nextbestpixel(A5,D6),D6
 mov al,es:nextbestpixel[si+bx] ;(thoughout bh=0)
 mov ds:[lastpixel],al
                    ; MOVE.B D6,(A4)+           ; insert next pixel into buffer
 mov di,ds:[writeptr]
 mov [di],al
 inc ds:[writeptr]
 jmp short prep1

prepexit:
                   ; LEA previouspixel(PC),A0
                   ; MOVE.B D6,(A0)
 mov al,ds:[lastpixel]
 mov [previouspixel],al                         ; update permanent copies
                                                ; of data
                   ; LEA huffmandatabuffer(PC),A0
                   ; MOVE.W D4,(A0)
 mov ax,ds:[hdatabuffer]
 mov ds:[huffmandatabuffer],ax
                   ; LEA huffmanshiftcount(PC),A0
                   ; MOVE.W D3,(A0)
 mov al,ds:[hshiftcount]
 mov [huffmanshiftcount],al
                   ; MOVEM.L (A7)+,D0-D7/A0-A6
 ret               ; RTS

;----------

grabvalue:
; Entry : htable -> start of huffman decoding tables
;               consisting of 16 bytes of length data
;               fllowed by 256 bytes of decoding data
;         D4 and D3er set up
; return next huffman encoded value in D7.W and adjusts shiftcount, data

;register D7 = result
;register D2 = length

holength     equ (huffmanlength-huffmantable)
hodecode     equ (huffmandecode-huffmantable)

                    ; CLR.W D7
                    ; MOVE.B D4,D7              ; extract low byte of data buffer
                    ; MOVE.B hodecode(A3,D7),D7 ; lookup the likelyhood index
 mov bl,byte ptr ds:[hdatabuffer]
 mov di,ds:[htable]
 mov bl,es:hodecode[di+bx] ;(thoughout bh=0)
                    ; CMP.B #Toolong,D7
                    ; BEQ.S escapesequence
 cmp bl,toolong
 je escapesequence
                    ; CLR.W D2
                    ; MOVE.B holength(A3,D7),D2   ; get length as a word value
                                                  ; fall through to...
 mov ds:[databyte],bl
 mov al,es:holength[di+bx]

 mov ah,al ;(length)
shiftbufferbyah:
 dec ah             ; SUBQ.W #1,D2              ; prepare for loop
 push cx ;Save pixel count. (cl needed for 'shr op,cl')

; ah is number-1 of bits to remove from input stream
; hshiftcount is number-1 of bits in high byte of hdatabuffer

 cmp ah,ds:[hshiftcount]
 jnc grb0 ;Number of shifts > buffer size

;Enough bits are left in high byte of hdatabuffer to complete shift in one go

 inc ah
 mov cl,ah
 sub ds:[hshiftcount],cl ;update new buffer size
 shr ds:[hdatabuffer],cl ;Junk old data/shift in new from high byte
 pop cx
 ret

;Shift until no bits left in high byte of hdatabuffer

grb0:
 mov cl,ds:[hshiftcount]
 inc cl
 sub ah,cl
 shr ds:[hdatabuffer],cl
 mov dl,7 ;(hshiftcount)

;Get next 8 bits from bit stream

 mov di,ds:[sourcepointer] ;(thoughout...)
 mov al,es:[di]
 inc ds:[sourcepointer]
 mov byte ptr ds:1[hdatabuffer],al

 cmp ah,0FFh
 jz nick01 ;(ah=length still to shift-1.)

;Complete shift on those bits after the boundary change...

 inc ah
 mov cl,ah
 sub dl,cl
 shr ds:[hdatabuffer],cl
nick01:
 pop cx
 mov ds:[hshiftcount],dl
 ret

escapesequence:
; The escape value Toolong is followed by the 4-bit value
                    ; MOVE.W #8,D2              ; get rid of escape sequence
                                                ; first of all
 mov ah,8
 call shiftbufferbyah
                    ; MOVE.W D4,D7              ; Now get our 4-bit number
                    ; AND.W #$F,D7
                    ; MOVE.W #4,D2              ; and remove it from buffer
                    ; BRA shiftbufferbylength
 mov al,byte ptr ds:[hdatabuffer]
 and al,00Fh
 mov ds:[databyte],al
 mov ah,4
 jmp short shiftbufferbyah

;----------

;grab_data_byte:
; Returns in D7 the next data byte from the source, and adjusts pointer
; Entry : No parameters.
;         BUT The SOURCE pointer must be set up correctly
; Exits with D7 = next byte
                    ; MOVEM.L A0/A1,-(A7)
                    ; LEA sourcepointer(PC),A0
                    ; MOVE.L  (A0),A1
                    ; MOVE.B (A1),D7
                                     ; Will incr. scource pointer
                    ; ADDQ.L #1,(A0) ; here by 1
                    ; MOVEM.L (A7)+,A0/A1
                    ; RTS

;----------

initgrab_data_byte:
; Initialise the source of data. Set the pointer up to the start of te
; bit stream. Perhaps open the file to be read, or load it into memory?
                    ; LEA sourcepointer(PC),A0
                    ; MOVE.L A5,(A0)   (A5 only ever holds 15 bits)
                    ; ADD.L #picturedata,(A0)
 mov ax,si
 add ax,picturedata
 mov ds:[sourcepointer],ax
 ret                ; RTS

;----------

PlotEgaPictureLine:
; Takes a line of pixels and inserts them onto the screen memory area
; making sure that only the pixels plotted are overwritten and leaving
; old data intact
; Entry : (lineofpixelsptr) points to start of pixel line (one pixel per byte)
;         (A6) points to left screen location 
;         D5 = x offset of line from left edge in pixels
;         D6 = y offset of line from top edge in pixels
;         D4 = number of pixels to plot

;register D5 = leftboundary                 ; remain valid during call
;register D6 = rightboundary
;register D4 = pixelpointer

 cmp ds:screenmode,19
 jz pe00
 cmp ds:[screenmode],14
 jnc pe01
pe00:
 ret ;Not in EGA or 640-EGA-emulation

pe01:
                    ; MOVEM.L D0-D7/A0-A6,-(A7)
 push si ;Save address of picture file.
; set A6 -> location to plot the line, and also zero D6
                    ; BSR rationaliseoffsets
                    ; MOVE.W D5,D6              ; left boundary in D5
                    ; ADD.W D4,D6               ; right boundary in D6
 mov ax,ds:[Xposition]
 add ax,ds:[pixelpointer]
 mov ds:[rightboundary],ax
                    ; MOVE.W  D5,D4             ; pixel pointer in D4
 mov cx,ds:[Xposition] ;Left column
 mov dx,ds:[yposition]
 mov di,ds:[lineofpixelsptr]
 mov bx,ds:[rightboundary]
 call drawegaline
                    ; MOVEM.L (A7)+,D0-D7/A0-A6
 pop si
 ret                ; RTS

;----------

PlotEmulationPictureLine:
; Takes a line of pixels and inserts them onto the screen memory area
; making sure that only the pixels plotted are overwritten and leaving
; old data intact
; Entry : (lineofpixelsptr) points to start of pixel line (one pixel per byte)
;         (A6) points to left screen location 
;         D5 = x offset of line from left edge in pixels
;         D6 = y offset of line from top edge in pixels
;         D4 = number of pixels to plot

;register D5 = leftboundary                 ; remain valid during call
;register D6 = rightboundary
;register D4 = pixelpointer

 cmp ds:[screenmode],13
 jz Xpe01
 cmp ds:[screenmode],19 ;MCGA 'borrows' same memory-image as EGA-emulation
 jz Xpe01
 ret ;Not in 320 emulation mode

Xpe01:
                    ; MOVEM.L D0-D7/A0-A6,-(A7)
 push si ;Save address of picture file.
; set A6 -> location to plot the line, and also zero D6
                    ; BSR rationaliseoffsets
                    ; MOVE.W D5,D6              ; left boundary in D5
                    ; ADD.W D4,D6               ; right boundary in D6
 mov ax,ds:[Xposition]
 add ax,ds:[pixelpointer]
 mov ds:[rightboundary],ax
                    ; MOVE.W  D5,D4             ; pixel pointer in D4
 mov cx,ds:[Xposition] ;Left column
 mov dx,ds:[yposition]
 mov di,ds:[lineofpixelsptr]
 mov bx,ds:[rightboundary]
 call drawM13line
                    ; MOVEM.L (A7)+,D0-D7/A0-A6
 pop si
 ret                ; RTS

;----------

PlotCgaPictureLine:
; Takes a line of pixels and inserts them onto the screen memory area
; making sure that only the pixels plotted are overwritten and leaving
; old data intact
; Entry : (lineofpixelsptr) points to start of pixel line (one pixel per byte)
;         (A6) points to left screen location 
;         D5 = x offset of line from left edge in pixels
;         D6 = y offset of line from top edge in pixels
;         D4 = number of pixels to plot

;register D5 = leftboundary                 ; remain valid during call
;register D6 = rightboundary
;register D4 = pixelpointer

 cmp byte ptr cs:[MenuFsubmode],cga_low_res
 jz pc01
 cmp byte ptr cs:[MenuFsubmode],ega_cga_low_res
 jz pc01
 cmp byte ptr cs:[MenuFsubmode],ega_full_low_res
 jz pc01
 ret ;Not in CGA
pc01:
                    ; MOVEM.L D0-D7/A0-A6,-(A7)
 push si ;Save address of picture file.
; set A6 -> location to plot the line, and also zero D6
                    ; BSR rationaliseoffsets
                    ; MOVE.W D5,D6              ; left boundary in D5
                    ; ADD.W D4,D6               ; right boundary in D6
 mov ax,ds:[Xposition]
 add ax,ds:[pixelpointer]
 mov ds:[rightboundary],ax
                    ; MOVE.W  D5,D4             ; pixel pointer in D4
 mov cx,ds:[Xposition] ;Left column
 mov dx,ds:[yposition]
 mov di,ds:[lineofpixelsptr]
 mov bx,ds:[rightboundary]
 call drawcgaline
                    ; MOVEM.L (A7)+,D0-D7/A0-A6
 pop si

 ret                ; RTS

;----------

PlotMgaPictureLine:
; Takes a line of pixels and inserts them onto the screen memory area
; making sure that only the pixels plotted are overwritten and leaving
; old data intact
; Entry : (lineofpixelsptr) points to start of pixel line (one pixel per byte)
;         (A6) points to left screen location 
;         D5 = x offset of line from left edge in pixels
;         D6 = y offset of line from top edge in pixels
;         D4 = number of pixels to plot

;register D5 = leftboundary                 ; remain valid during call
;register D6 = rightboundary
;register D4 = pixelpointer

 cmp ds:[screenmode],6
 jz pm01
 ret ;Not in MGA
pm01:
                    ; MOVEM.L D0-D7/A0-A6,-(A7)
 push si ;Save address of picture file.
; set A6 -> location to plot the line, and also zero D6
                    ; BSR rationaliseoffsets
                    ; MOVE.W D5,D6              ; left boundary in D5
                    ; ADD.W D4,D6               ; right boundary in D6
 mov ax,ds:[Xposition]
 add ax,ds:[pixelpointer]
 mov ds:[rightboundary],ax
                    ; MOVE.W  D5,D4             ; pixel pointer in D4
 mov cx,ds:[Xposition] ;Left column
 mov dx,ds:[yposition]
 mov di,ds:[lineofpixelsptr]
 mov bx,ds:[rightboundary]
 call drawmgaline
                    ; MOVEM.L (A7)+,D0-D7/A0-A6
 pop si

 ret                ; RTS

;----------
; *************************************************************************
; This is the DECOMPRESSION END. This code fits into the DRIVER, and
; decompresses and displays a high resoltion digitised picture
; onto the Atari ST screen.
;
;                                             Lars Nielsen December 1987
;
; The pictures must already have been compressed using the correct format.
; There are stages as follows:
; 1) Load picture to memory (optional - can read straight from disk)
; 2) Prepare a line of numbers from the Huffman coded data. Each number
;    is a index into the Markov Likelyhood Matrix (see Compression notes)
;    and effectivel;y copdes the pixel's value from the previous one.
; 3) Map the coded pixels to real colours (0-15).
; 4) Plot the pixels onto the screen, preserving any pixels that are not
;    directly overwrtitten. Any line length may be used.
; REPEAT (2)-(4) for all the lines of the image.
; *************************************************************************
; Extra data needed, as well as the Hufmann encoded data we need:
; Huffman length table - 16 byte table. Each entry gives the length in
;                        bits for the huffman code of the pixel's
;                        likelyhood index.
; Huffman decode table - 256 byte lookup table. The routine grabs 8 bits
;                        from its input stream, forms a byte and uses that
;                        byte as on offset into this table to drive the
;                        value which the huiffman code represents
; Next best pixel - 16*16 matrix. rows are previous pixel, columns are
;                   likelyhood levels. Entry is next pixel (byte)
; First pixel - We need to start off with the top right pixel, from which
;               derive the next one along, then the next one along, and
;               so on.
; X size - width in pixels (not bytes or words)
; Y size - height in pixels
;
; *************************************************************************
; *************************************************************************
;
;                              NOTES
;
; To establish the colour of a pixel we need to:
; 1) Get the huffman code of the pixel from a stream of bits
; 2) Decode this to obtain the "likelyhood" index of the pixel
; 3) From this likeyhood index, and the colour of the pixel that we
;    previously plotted, we obtain the colour of the pixel we want to plot
; Steps (1) - (3) are repeated until a complete line of pixels has been
; done. This line is then plotted onto the screen by a separate routine.
; Decoding the huffman codes:
; The routine grabs 8 bits from its stream into a byte. It uses that byte
; as an offset into the Huffmandecode table. This gets us our likelyhood
; index for that pixel.
; It then looks up the bit length of the huffman code, and it then throws
; away this many bits so that we are left with the huffman code of the
; next pixel in the buffer.
; Using the likelyhood index:
; Pixels are coded by how likely they are to follow from their predecessor
; A "likelyhood" index of 0 means that this pixel is the most likely
; successor to its previous one. A likelyhood index of 15 means it's the
; least likely successor. Codes 1-14 are in between.
; If we know the colour of the pixel we've plotted previously, and we know
; the likelyhood index of our current pixel, we can look up the real
; colour of the pixel in the Next best pixel table.
; This colour is used as the previous pixel for the next one, and that is
; used for the one after next, and so on in a chain.
; The Nextbestpixel matrix is addressed as:
; Nextbestpixel?(previous_pixel*16 + likelyhood)
; Each entry is one byte value 0-15
;

code ends

 end





