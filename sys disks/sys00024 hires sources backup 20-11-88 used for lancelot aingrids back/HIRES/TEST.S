;
;
; Standalone version to mess around with squashed pics
;
;
;
;
; OPT C+,N-
***************************************************************************
***                   							***
***                Digitised Picture Compression                        ***
***									***
***                Lars Nielsen     October 1987                        ***
***								        ***
***************************************************************************
* comment out this label when you want debugging off
;debuggingon 
; bra debug
 bra Debug


* working stuff, and parameters which may change later
compressed_picture_id EQU  $FFFF	* Identify correct kind of picture
Toolong               EQU  $FF		* An escape value 
N                     EQU  16 		* no. of pixels per unit on screen
bytes_per_screen_line EQU  160
SP                    EQUR A7

* Offsets into compressed picture file header 
* Can change these if you want		
filelength    EQU 0			* length of file - 1 (LSB FIRST)
filetype      EQU filelength+2		* identify file as comp. picture
palette       EQU filetype+2		* 16 words one for each colour
XSizeOffset         EQU palette+32		* width in pixels
YSizeOffset         EQU XSizeOffset+2		* height in pixels
firstpixel    EQU YSizeOffset+2		* colour of top left pixel (0-15)
nextbestpixel EQU firstpixel+2		* complicated 16x16 matrix
huffmantable  EQU nextbestpixel+256
huffmanlength EQU huffmantable		* lookup table of lengths of codes
huffmandecode EQU huffmantable+16	* lookup table of codes
picturedata   EQU huffmandecode+256

  EVEN
* lookup tables used when plotting the line
leftmask        DC.W $FFFF,$7FFF,$3FFF,$1FFF,$0FFF,$07FF,$03FF,$01FF,$00FF
		DC.W       $007F,$003F,$001F,$000F,$0007,$0003,$0001,$0000
rightmask       DC.W $FFFF,$FFFE,$FFFC,$FFF8,$FFF0,$FFE0,$FFC0,$FF80,$FF00
                DC.W       $FE00,$FC00,$F800,$F000,$E000,$C000,$8000,$0000

***************************************************************************


  EVEN
;---
;SafeBreakIfArmed
; move.l d0,-(sp)
; move.b Arming,d0
; beq.s SBIAEnd
; move.l a0,-(sp)
;  lea Arming,a0
;  clr.b (a0)
; move.l (sp)+,a0
; bsr SafeBreakPoint
;SBIAEnd
; move.l (sp)+,d0
; rts
;-----
;ArmBreakPoint
; move.l a0,-(sp)
; lea Arming,a0
; move.b #1,(a0)
; move.l (sp)+,a0
; rts
;Arming dc.b 1
; even
;----
*************Start of debug stuff
f_open equ $3d

readf	macro
;	addq.w	#1,suspendtaskswap
	 move.l	#\1,-(sp)
	 move.l	#\2,-(sp)
	 move.w	\3,-(sp)
	 move.w	#$3f,-(sp)
	 trap	#1
	 lea	12(sp),sp
;	subq.w	#1,suspendtaskswap
	endm


nonspecific equ 15
AutoRunSize equ 2000
DriverIBuffSize equ 1000
 include 'ram.s'

 ds.b 25000



do_scroll
 rts

GintFatalError
 dc.w $4afa
 rts

SetUpPaletteA0
 rts

ColorMap
 ds.l 20
ColorMap2
 ds.l 20
handle ds.w 1
filename dc.b "\games.l9\timelord.l9\st.l9\19.squ",0
 even

SetUpPalette
 rts


XOffset ds.w 1
YOffset ds.w 1


Debug

;	addq.w	#1,suspendtaskswap
	 move.w	#0,-(sp)	*read
	 move.l	#filename,-(sp)
	 move.w	#f_open,-(sp)
	 trap	#1
	 add.l	#8,sp
;	subq.w	#1,suspendtaskswap
	tst.w	d0
	bmi	filereaderror
okopenedit
	move.w	d0,handle
 move.l #$e8000,a0
 lea CompressedCacheAddress,a1
 move.l a0,(a1)
 lea UseCompressedCache,a0
 clr.b (a0)

 move.l #$f8000,a0
 bsr CompressedLoadDisplay
 dc.w $4afa




 dc.w $4afa


FileReaderror
 dc.w $4afa
 bra FileReadError

*************End of debug stuff




decompresspicture
* Entry : Routines grab_data_byte and put_picture_line intialised 
*         as required (This should be done within initdecomp)
*         (A5) -> Start of file AS IT WAS ON THE DISK, beginning with the
*                 header, followed by compressed data
*         (A6) -> Screen start location (locn. of top left hand corner)
*         D5.W = x offset and D6.W = y offset both in pixels
* N.B. A5 points byte 0 of the header, i.e. the l.s.b. of the file length
* Assumed that the Checksum and the File type have already been checked

xposition EQUR D5
yposition EQUR D6
screenptr EQUR A6
  MOVEM.L D0-D7/A0-A6,-(SP)
*  BSR     checkrightkindoffile		* make sure file type is correct
*  BNE     finisheddec			* stop if not
  BSR     initdecomp
  BSR     rationaliseoffsets		* sets D6=0 and D5<16
  LEA     lineofpixels(PC),A4		* buffer for line of pixels
decline
  CMP.W   YSizeOffset(A5),yposition
  BGE     finisheddec

; move.b IsPictureValid,d0
; beq.s finishedDec

  bsr     decompress_picture_line
  MOVE.W  XSizeOffset(A5),D4	* numbert of pixels to plot
  bsr     plot_picture_line
  bsr do_scroll * allow picture to be slid up and down whilst
* we're decompressing the picture.
  ADDQ.W  #1,yposition
  BRA     decline
finisheddec
; check checksum...
 move.b CheckSumFound,d0
 move.w d0,-(sp)
  bsr grab_data_byte
; d7.b is checksum stored with picture
 move.w (sp)+,d0
 dc.w $4afa

***
 move.w LengthToCheckSum,d0
DebugCLD3
 bsr Grab_data_byte
 dbra d0,DebugCLD3

 move.b CheckSumFound,d0
 dc.w $4afa
 bsr Grab_data_byte
 move.b CheckSumFound,d0
 dc.w $4afa
***


 cmp.b d7,d0
 bne.s DecompError

DecompOk
 MOVEM.L (SP)+,D0-D7/A0-A6
 clr.b d0 * ok!
 RTS

DecompError
  MOVEM.L (SP)+,D0-D7/A0-A6
 move.b #$ff,d0 * error
 rts


**************************************************************************

;checkrightkindoffile
;* make sure that the File type word in the header contain
;* the value compressed_picture_id. Note that the word is stored 
;* HI BYTE FIRST as is common on the 68000
;  MOVE.W  filetype(A5),D7
;  CMP.W   #compressed_picture_id,D7
;  RTS					* with Z=1 if O.K.

******************** 

initdecomp
* initialise decompression picture routine
  lea EndDecompDiskBuffer,a2 * a2 is not used by rest of decomp code
* Set to end of buffer to force loading buffer on first grab_data_byte

  move.l #-1,a2
  LEA     huffmanshiftcount(PC),A0
  MOVE.W  #7,(A0)			* we will count 8 shifts
;  bsr     initgrab_data_byte		* initialise source of data
  LEA     huffmandatabuffer(PC),A0
  bsr     grab_data_byte		* get 1st compressed byte
  MOVE.B  D7,1(A0)			* put in l.s.byte of data buffer
  bsr     grab_data_byte		
  MOVE.B  D7,0(A0)			* put in m.s.byte of data buffer
  LEA     previouspixel(PC),A0
  MOVE.B  firstpixel(A5),(A0)	* begin chain of pixels with first
  EXT.L   xposition
  EXT.L   yposition 
  RTS


***************************************************************************


rationaliseoffsets
* Take as arguments:
* Screen start address in screenptr
* x offset in D5 (xposition)
* y offset in D6 (yposition)
* Return with y offset=0 , x offset=(x offset) AND $F
* and A6 contains the location of the first byte affected by the picture
* i.e. location of its top left pixel in memory.
  MULU   #bytes_per_screen_line,yposition	* calculate vertical adjust
  ADD.L  yposition,screenptr			* adjust vertically
  MOVE.W xposition,D6
  LSR.W  #1,D6				* (x offset DIV 16) * 8 as the
  AND.W  #$FFF8,D6				* horizontal adjust
  EXT.L  D6
  ADD.L  D6,screenptr
  AND.W  #$F,xposition				* correct x offset
  CLR.W  yposition				* correct y offset
  RTS


***************************************************************************


pixelcount      EQUR D5
lastpixel       EQUR D6
hdatabuffer     EQUR D4
hshiftcount     EQUR D3
htable          EQUR A3
lineofpixelsptr EQUR A4
decompress_picture_line
  MOVEM.L D0-D7/A0-A6,-(SP)
  CLR.L   lastpixel			* so we can use it as a word value
  LEA     previouspixel(PC),A0
  MOVE.B  (A0),lastpixel		* set up the registers first
  LEA     huffmandatabuffer(PC),A0
  MOVE.W  (A0),hdatabuffer
  LEA     huffmanshiftcount(PC),A0
  MOVE.W  (A0),hshiftcount
  LEA     huffmantable(A5),htable	* A3 remains valid during call
  MOVE.W  XSizeOffset(A5),pixelcount		* count x-size pixels
prep1
  SUBQ.W  #1,pixelcount			* FOR pixelcount = XSizeOffset-1 TO 0
  BCS     prepexit			* unsigned < 0
  BSR     grabvalue			* result in D7.W
  ASL.B   #4,lastpixel			
  OR.B    D7,lastpixel			* (last pixel)*16 + likelyhood
  MOVE.B  nextbestpixel(A5,lastpixel),lastpixel	* use of offset
  MOVE.B  lastpixel,(lineofpixelsptr)+	* insert next pixel into buffer
  BRA     prep1				* NEXT pixelcount
prepexit
  LEA     previouspixel(PC),A0
  MOVE.B  lastpixel,(A0)		* update permanent copies of data
  LEA     huffmandatabuffer(PC),A0
  MOVE.W  hdatabuffer,(A0)
  LEA     huffmanshiftcount(PC),A0
  MOVE.W  hshiftcount,(A0)
  MOVEM.L (SP)+,D0-D7/A0-A6
  RTS


***************************************************************************


grabvalue
* Entry : htable -> start of huffman decoding tables
*               consisting of 16 bytes of length data
*               fllowed by 256 bytes of decoding data
*         hdatabuffer and hshiftcounter set up
* return next huffman encoded value in D7.W and adjusts shiftcount, data
result       EQUR D7
length       EQUR D2
holength     EQU (huffmanlength-huffmantable)
hodecode     EQU (huffmandecode-huffmantable)
  CLR.W   result
  MOVE.B  hdatabuffer,result		* extract low byte of data buffer
  MOVE.B  hodecode(htable,result),result * lookup the likelyhood index
  CMP.B   #Toolong,result
  BEQ.S   escapesequence
  CLR.W   length
  MOVE.B  holength(htable,result),length * get length as a word value
* fall through to... 
shiftbufferbylength
  SUBQ.W  #1,length			* prepare for loop
grb1
  LSR.W   #1,hdatabuffer		* shift ENTIRE WORD down
  DBRA    hshiftcount,grb2		* check if we need a new byte yet
  MOVE.W  result,-(SP)			* this is corrupted by s/r call
  BSR     grab_data_byte
  ASL.W   #8,D7
  OR.W    D7,hdatabuffer		* insert m.s.byte in data buffer
  MOVEQ   #7,hshiftcount		* reset to count 8 shifts
  MOVE.W  (SP)+,result
grb2
  DBRA    length,grb1
  RTS

escapesequence
* The escape value Toolong is followed by the 4-bit value
  MOVE.W  #8,length			* get rid of escape sequence
  BSR     shiftbufferbylength		* first of all
  MOVE.W  hdatabuffer,result		* Now get our 4-bit number
  AND.W   #$F,result			* 
  MOVE.W  #4,length			* and remove it from buffer
  BRA     shiftbufferbylength		



***************************************************************************
***************************************************************************

grab_data_byte
* Atari ST specific routine
* Returns in D7 the next data byte from the source, and adjusts pointer
* Currenlt the source is memory, a buffer, but it could be disk too.
* Entry : No parameters.
*         BUT The SOURCE pointer must be set up correctly
* Exits with D7 = next byte
* a2.l is the ptr to the current position in DecompDiskBuffer
 movem.l d0-d6/a0-a6,-(sp)
 move.w BufferOffset,d0
 cmp.w #256,d0
 bcc.s GBDFillBuffer
GBDGotBuffer
 lea DecompDiskBuffer,a0
 move.b 0(a0,d0),d7
 lea BufferOffset,a0
 addq.w #1,(a0)

 lea LengthToCheckSum,a0
 subq.w #1,(a0)
 bmi.s GBDNC1 ; reached the end of the file
 lea ChecksumFound,a0
 add.b d7,(a0)
 movem.l (sp)+,d0-d6/a0-a6
 rts


GBDNC1
 movem.l (sp)+,d0-d6/a0-a6
**** kills pic load if enabled!!!! clr.w d7
 rts

GBDFillBuffer
 lea DecompDiskBuffer,a1
 move.w #64,d0
GBDFB1
 clr.l (a1)+
 dbra d0,GBDFB1

* load data from cache?
  move.b UseCompressedCache,d0
  beq.s LFB1
* loading from cache...
 lea DecompDiskBuffer,a1 * TempBuffer,a1
 move.w #256,d0
 bsr CopyFromCache
 tst.w d1
 bne.s LFB2
* no cache available (Bug!!!)

LFB1
 readf DecompDiskBuffer,256,handle

* copy to cache.
  lea DecompDiskBuffer,a0
  move.w #256,d0
  bsr SaveToCache

LFB2
 lea BufferOffset,a0
 clr.w (a0)
 clr.w d0
 bra GBDGotBuffer

;------
;initgrab_data_byte
;* Initialise the source of data. Set the pointer up to the start of te
;* bit stream. Perhaps open the file to be read, or load it into memory?
; rts ****

***************************************************************************


plot_picture_line

* Atari ST specific routine
* Takes a line of pixels and inserts them onto the screen memory area
* making sure that only the pixels plotted are overwritten and oleaving
* old data intact
* it plots in "units" which are 8-byte or 16-pixel groups, but can plot
* any width at all.
* Entry : (A4) points to start of pixel line (one pixel per byte)
*         (screenptr) points to left screen location  
*         D5 = x offset of line from left edge in pixels
*         D6 = y offset of line from top edge in pixels
*         D4 = number of pixels to plot
leftboundary    EQUR D5			* remain valid during call
rightboundary   EQUR D6
pixelpointer    EQUR D4
lineofpixelsptr EQUR A4
  MOVEM.L D0-D7/A0-A6,-(SP)
* set screenptr -> location to plot the line, and also zero D6
  BSR     rationaliseoffsets	
  MOVE.W  leftboundary,rightboundary	* left boundary in D5
  ADD.W   D4,rightboundary		* right boundary in D6
  MOVE.W  leftboundary,pixelpointer	* pixel pointer in D4
  AND.W   #$FFF0,pixelpointer		* round back to unit boundary
ptl
  CMP.W   rightboundary,pixelpointer
  BGE     ptdone
  BSR     plotoneunit			* will adjust pointers too
  BRA     ptl  
ptdone
  MOVEM.L (SP)+,D0-D7/A0-A6 
  RTS

*****************

plotoneunit

* given D5 = left hand boundary in pixels
*       D6 = right hand boundary in pixels
*       D4 = pixel where we are plotting to, on a unit boundary
*       A4 -> start of pixel buffer, containing new data in bytes
*       screenptr -> location on screen where we wish to start 
*       while D4 is oustide range D5->D6 , no data is plotted
* Exits with registers set up for next call:
*       D4 incremented by 16
*       screenptr incremented by 8
*       A4 incremented by however many pixels were plotted 
*       D5,D6 preserevd
* Plots a 16 pixel unit of the line, without overunning line edges
pixel           EQUR D2
wordnumber      EQUR D3
accumulator     EQUR D0
pmask           EQUR D7

  MOVE.W   #$FFFF,pmask			* initially assume plot everywhere
  CLR.W    wordnumber			* count 4 words on screen
  MOVE.L   lineofpixelsptr,A1		* remember position in line data
  BSR      maskforleft			* adjust mask for left hand edge
  BSR      maskforright			* ditto right hand edge
  CMP.W    #$FFFF,pmask			* have we clashed with either edge?
  BEQ      plotwithoutmask              * No, so forget about the mask
plotwithmask
  MOVE.W   #15,pixel		  	* count through 16 pixels
  CLR.W    accumulator			* accumulator for data
  MOVE.L   A1,lineofpixelsptr		* point back to line data
assbleword
  BTST     pixel,pmask			* see if we need to do this pixxel
  BEQ.S    assblenext			* no, so go to the next one
  BTST     wordnumber,(lineofpixelsptr)+
  BEQ.S    assblenext
  BSET     pixel,accumulator
assblenext
  DBRA     pixel,assbleword
  AND.W    pmask,accumulator		* plotting data
  NOT.W	   pmask
  AND.W    pmask,(screenptr)		* old screen data masked
  NOT.W    pmask
  OR.W     accumulator,(screenptr)+	* insert new data to screen
  ADDQ.W   #1,wordnumber
  CMP.W    #4,wordnumber
  BLT      plotwithmask
  ADD.W    #16,pixelpointer		* adjust pixel pointer
  RTS

***********

makeapixel MACRO
  BTST.B   wordnumber,(lineofpixelsptr)+
  BEQ.S    nmassblenext\1
  BSET     #\1,accumulator
nmassblenext\1
  ENDM

plotwithoutmask
* In this case we know that we have 16 pixels to plot, and they will 
* fully overwrite what was on the screen.
  CLR.W    accumulator			* accumulator for data
  MOVE.L   A1,lineofpixelsptr		* point back to line data
nmassbleword
  makeapixel 15
  makeapixel 14
  makeapixel 13
  makeapixel 12
  makeapixel 11
  makeapixel 10
  makeapixel 9
  makeapixel 8
  makeapixel 7
  makeapixel 6
  makeapixel 5
  makeapixel 4
  makeapixel 3
  makeapixel 2
  makeapixel 1
  makeapixel 0
  MOVE.W   accumulator,(screenptr)+	* plot the new data onto screen
  ADDQ.W   #1,wordnumber
  CMP.W    #4,wordnumber
  BLT      plotwithoutmask
  ADD.W    #16,pixelpointer		* adjust pixel pointer
  RTS


*********

maskforleft
* given D5 = left hand boundary and D6 = right hand boundary
*       D4 = pixel pointer (on a unit boundary)
*       D7 = current mask
* Returns D7 altered if necessary to account for left hand edge
  MOVE.W   leftboundary,D0
  SUB.W    pixelpointer,D0
  BLS      mlexit			* stop if lhs <= pixel ptr.
  ASL.W    #1,D0			* 0 < D0 < 16
  LEA      leftmask(PC),A0		* look up mask adjustment
  AND.W    0(A0,D0),pmask		* zero some of the msb's of mask
mlexit
  RTS
 
**********

maskforright
* entry same as maskforleft
  MOVE.W   pixelpointer,D0
  ADD.W    #16,D0			* get to next unit boundary			
  SUB.W    rightboundary,D0
  BLS      mrexit			* don't if (pixel ptr+16) <= rhs
  ASL.W    #1,D0
  LEA      rightmask(PC),A0
  AND.W    0(A0,D0),pmask		* zero lsb's of mask
mrexit
  RTS

ClearAll
 clr.l d0
 clr.l d1
 clr.l d2
 clr.l d3
 clr.l d4
 clr.l d5
 clr.l d6
 clr.l d7
 move.l d0,a0
 move.l d1,a1
 move.l d2,a2
 move.l d3,a3
 move.l d4,a4
 move.l d5,a5
 move.l d6,a6
 rts
;-----
compressedLoadDisplay
* file is open - reference by workspace location HANDLE.B
* a0.l is address of screen to decompress picture to
; Load in the first #PICTUREDATA bytes into (a5)
 move.l a0,-(sp)

  bsr ClearAll
  lea BufferOffset,a0
  move.w #$ffff,(a0)

* load data from cache?
  move.b UseCompressedCache,d0
  beq.s CLD1
* loading from cache...
  lea TempBuffer,a1
  move.w #PictureData+1,d0
  bsr CopyFromCache
  tst.w d1
  bne.s CLD3
* no cache available (Bug!!!)
 bra GintFatalError ;>>mike 17/2/88

CLD1
* loading from disk, saving to cache
;  readf TempBuffer,PictureData,handle
 lea TempBuffer,a0
 lea TempBuffer+PictureData,a1
* load length word
 bsr Grab_data_byte
 move.b d7,(a0)+
 asl.w #8,d7 * high-order part of length word
 move.w d7,-(sp)
  bsr Grab_data_byte
  move.b d7,(a0)+
  lea CheckSumFound,a2
  clr.b (a2) * disregard length word for purposes of checksum
  lea LengthToCheckSum,a2
 move.w (sp)+,d0
 or.b d7,d0 * merge with high-order of length
 sub.w #2,d0 * discount checksum byte and length word >>>>>>
 move.w d0,(a2)

CLD1a
 bsr Grab_data_byte
 move.b d7,(a0)+
 cmp.l a0,a1
 bne.s CLD1a

 lea TempBuffer,a0
 move.w #PictureData+1,d0
 bsr SaveToCache

CLD3
;; calculate of checksum on header...
; clr.b d1 ; value of checksum so far.
; lea TempBuffer+2,a0 * header, excluding length word
; lea TempBuffer+PictureData,a1 * first byte we don't want to checksum
;CLD3a
; add.b (a0)+,d1
; cmp.l a1,a0
; bcs.s CLD3a
; lea CheckSumFound,a0
; move.b d1,(a0)
;
;  bsr ClearAll
;  lea BufferOffset,a0
;  move.w #$ffff,(a0)
 move.l (sp)+,a6 * destination
 lea TempBuffer,a5
 move.w XOffset,d5
 move.w YOffset,d6
 BSR    decompresspicture
 tst.b d0 * was there a load error?
 bne.s FLDRet
 move.w d0,-(sp) * save status

* copy palette for use by split screen
 lea ColorMap,a1
 lea ColorMap2,a2
 lea TempBuffer,a5
 lea palette(a5),a0
 movem.l a0-a6,-(sp)
  bsr SetUpPalettea0
 movem.l (sp)+,a0-a6
 move.w #15,d1
CopyPalette1
 move.w (a0)+,d0
 move.w d0,(a1)+
 move.w d0,(a2)+
 dbra d1,CopyPalette1
 move.w (sp)+,d0 * restore error return
FLDRet
 rts
;---
SaveToCache
* copy from a0.l to cache length d0.w
 lea CompressedCacheAddress,a2
 move.l (a2),d1
 beq.s STCRet * no cache
 move.l d1,a1

 add.l d0,(a2) * increase cache pointer
; lsr.w #4,d0 * convert to length in longs
STC1
 move.b (a0)+,(a1)+
 dbra d0,STC1
STCRet
 rts
;-------
CopyFromCache
* copy from cache to a1.l length d0.w
 lea CompressedCacheAddress,a2
 move.l (a2),d1
 beq.s CFCRet * no cache
 move.l d1,a0

 add.l d0,(a2) * increase cache pointer
; lsr.w #4,d0 * convert to length in longs
CFC1
 move.b (a0)+,(a1)+
 dbra d0,CFC1
CFCRet
 rts
;----
 EVEN
;WorkSpace
;rawdata
;  DS.W    20				* some space
;
;data_byte ds.b 1
;
;xwidth            ds.w 1 * DC.W 10
;ywidth            ds.w 1 * DC.W 10
;previouspixel     ds.b 1 * DC.B 15
; even
;huffmandatabuffer ds.l 1 * DC.L 0
;huffmanshiftcount ds.l 1 * DC.L 0
;sourcepointer     ds.l 1 * DC.L 0
;
;lineofpixels    DS.W 320
;
;EndWorkSpace
 even

**************************************************************************
**************************************************************************
* This is the DECOMPRESSION END. This code fits into the DRIVER, and 
* decompresses and displays a high resoltion digitised picture
* onto the Atari ST screen.
*
*                                             Lars Nielsen December 1987
*
* The pictures must already have been compressed using the correct format.
* There are stages as follows:
* 1) Load picture to memory (optional - can read straight from disk)
* 2) Prepare a line of numbers from the Huffman coded data. Each number
*    is a index into the Markov Likelyhood Matrix (see Compression notes)
*    and effectivel;y copdes the pixel's value from the previous one.
* 3) Map the coded pixels to real colours (0-15).
* 4) Plot the pixels onto the screen, preserving any pixels that are not
*    directly overwrtitten. Any line length may be used.
* REPEAT (2)-(4) for all the lines of the image.
**************************************************************************
* Extra data needed, as well as the Hufmann encoded data we need:
* Huffman length table - 16 byte table. Each entry gives the length in
*                        bits for the huffman code of the pixel's 
*                        likelyhood index.
* Huffman decode table - 256 byte lookup table. The routine grabs 8 bits
*                        from its input stream, forms a byte and uses that
*                        byte as on offset into this table to drive the
*                        value which the huiffman code represents
* Next best pixel - 16*16 matrix. rows are previous pixel, columns are 
*                   likelyhood levels. Entry is next pixel (byte)
* First pixel - We need to start off with the top right pixel, from which
*               derive the next one along, then the next one along, and 
*               so on.
* X size - width in pixels (not bytes or words)
* Y size - height in pixels
*
**************************************************************************
**************************************************************************
*
*                              NOTES
*
* To establish the colour of a pixel we need to:
* 1) Get the huffman code of the pixel from a stream of bits
* 2) Decode this to obtain the "likelyhood" index of the pixel
* 3) From this likeyhood index, and the colour of the pixel that we
*    previously plotted, we obtain the colour of the pixel we want to plot
* Steps (1) - (3) are repeated until a complete line of pixels has been 
* done. This line is then plotted onto the screen by a separate routine.
* Decoding the huffman codes:
* The routine grabs 8 bits from its stream into a byte. It uses that byte 
* as an offset into the Huffman decode table. This gets us our likelyhood
* index for that pixel.
* It then looks up the bit length of the huffman code, and it then throws
* away this many bits so that we are left with the huffman code of the 
* next pixel in the buffer.
* Using the likelyhood index:
* Pixels are coded by how likely they are to follow from their predecessor
* A "likelyhood" index of 0 means that this pixel is the most likely
* successor to its previous one. A likelyhood index of 15 means it's the
* least likely successor. Codes 1-14 are in between.
* If we know the colour of the pixel we've plotted previously, and we know
* the likelyhood index of our current pixel, we can look up the real
* colour of the pixel in the Next best pixel table.
* This colour is used as the previous pixel for the next one, and that is
* used for the one after next, and so on in a chain.
* The Nextbestpixel matrix is addressed as:
* Nextbestpixel?(previous_pixel*16 + likelyhood)
* Each entry is one byte value 0-15 

;TempBuffer
; ds.b PictureData+2
; even
;
;DecompDiskBuffer
; ds.b 256
;EndDecompDiskBuffer
; even

BufferOffset dc.w $ffff



