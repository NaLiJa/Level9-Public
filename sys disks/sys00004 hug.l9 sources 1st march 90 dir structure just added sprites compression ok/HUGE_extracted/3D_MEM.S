 ifnd MCStart
 include 'Condit.s'
 endc

; 3d_MEM.S
;
; MIke Austin. 26/2/90
;--------------------------------
;   load data into memory pool
********* Check ST seek-preventor. Why disabled now?

 
*>>Mike 26/1/89 check for excessive disc request added. 

CellAddressMask equ $00FFFFFE * could make last byte 80
; if we restricted the addresses at which pool could start.

* Cell table entry: one long per cell
* XXXXXXXX AAAAAAAA AAAAAAAA AXXXXXXX for 128 bytes/cell
* XXXXXXXX AAAAAAAA AAAAAAAA AAAXXXXX for 160 bytes/cell
* Top bit is protection flag, then a 7 bit timer.
* Bottom 5/7 bits are currently unused

; old bits of code moved to "OLDST.S" 12/9/89.

 ifne Amiga
DiskRequestor
RequestorX equ $500000
RequestorY equ $40
 move.b RequestorDisplayed,d0
 bne DiskRequestorRet
 movem.l d0-d7/a0-a6,-(sp)
 move.l TextScreenBase,-(sp)
 move.l PhysicalBase,TextScreenBase
 move.l CursorXPos,-(sp) * x and y
 move.l #RequestorX+RequestorY,CursorXPos * x and y pos:  middle of screen
 lea S(PC),a5 * for benefit of text printing code.

 move.l InfoBlockPtr-S(A5),a4 * temp buffer
 move.w #20*8,2(a4) * width to clear
 move.w #3*8,4(a4) * height to clear
; bsr ClearRectangle * clear area of requestor.
 bsr PhysicalClearRectangle

 bsr prs
 dc.b "-------------------- ",0
 even
 move.l #RequestorX+RequestorY+8,CursorXPos * x and y pos:  middle of screen
 move.w DiskNum,d0
 add.b #'0',d0
 move.b d0,DiskNumText
 bsr prs
 dc.b "Please insert disk "
DiskNumText: dc.b " ",0
 even
 move.l #RequestorX+RequestorY+16,CursorXPos * x and y pos:  middle of screen
 bsr prs
 dc.b "-------------------- ",0
 even
 move.l (sp)+,CursorXPos
 move.l (sp)+,TextScreenBase
 move.b #1,RequestorDisplayed
 movem.l (sp)+,d0-d7/a0-a6
DiskRequestorRet:
 rts * yes
 rts
;---
DiskError:
* We've noticed that the wrong disk is in the drive
* - request its immediate return!
 movem.l d0-d7/a0-a6,-(sp)
  move.b #0,RequestorDisplayed * force display of requestor
  bsr DiskRequestor * display requestor immediately
  bra.s DiskChangeLoop
;---
CheckForDiskChange
; we want disk d1.w. Do disk change stuff if it's needed
 cmp.w DiskNum,d1
 bne.s CFDC1
 rts

CFDC1:
 move.w d1,DiskNum
* drop through to DiskChange

DiskChange:
* we need to open sprites file on DiskNum:w
* If it isn't there, display a requestor and keep
* on retrying until it is.
 movem.l d0-d7/a0-a6,-(sp)
  move.b #0,RequestorDisplayed
DiskChangeLoop:
  bsr DiskChange2
* d1.w is the disk found in the drive...
  cmp.w DiskNum,d1 * is it what we wanted?
  beq.s DiskChangeExit
  bsr DiskRequestor
  bra.s DiskChangeLoop

DiskChangeExit
 movem.l (sp)+,d0-d7/a0-a6
 rts

DiskChange2:
* We're trying to change to disk DiskNum:
* wait until the user puts in a new disk, and return
* d1.w as its number. Don't do any requestors or anything
* else.
* Close current sprites file ( to avoid running out of handles)
 move.l SpritesHandle,d1
 beq OpenDiskForTheFirstTime ; not opened, or something
 bsr CheckForDiskInDrive
 CALLDOS Close
 move.l #0,SpritesHandle

; ignore any errors on close: doesn't access disk at all
; So it can't be any problem we're interested in now (May not
; have opened the sprites file correctly in the first place, I
; guess, but it's too late now...)

OpenDiskForTheFirstTime
* Open sprites file for the disk we want
 move.w DiskNum,d0
 add.b #'0',d0
 move.b d0,SpritesFileNum * "SpritesN.DAT"

* have we decided whether to use compressed or uncompressed
* sprites files yet?
 move.b SpritesFileType-S(A5),d0
 cmp.b #CompressedType,d0
 beq ODFTFTCompressed
* either uncompressed, or we don't know yet.

* open sprites file (hard disk/cheaty floppy)
 movem.l a3-a6,-(sp)
  move.l #SpritesFilename,d1 * address of filename
  move.l #MODE_OLDFILE,d2 * access mode - read existing file. 1006. is create new
  bsr CheckForDiskInDrive
  CALLDOS Open
* d0 is file handle
 movem.l (sp)+,a3-a6
* we get an error which pushes us back to diskError2
 tst.l d0
 beq ODFTFTNoUncompressed * didn't find file.
 bmi ODFTFTNoUncompressed
 move.l d0,SpritesHandle		* save handle 
 move.b #UncompressedType,SpritesFileType-S(A5)
 bra.s ODFTFTOpenOk

ODFTFTNoUncompressed
ODFTFTCompressed
* patch filename to try a compressed version...
 move.l #ConstCompressedExtension,SpritesFileDot-S(A5)
* open sprites file (hard disk/cheaty floppy)
 movem.l a3-a6,-(sp)
  move.l #SpritesFilename,d1 * address of filename
  move.l #MODE_OLDFILE,d2 * access mode - read existing file. 1006. is create new
  bsr CheckForDiskInDrive
  CALLDOS Open
* d0 is file handle
 movem.l (sp)+,a3-a6
 move.l #ConstUncompressedExtension,SpritesFileDot-S(A5)

 tst.l d0
 beq DiskChangeNoDisk * didn't find file.
 bmi DiskChangeNoDisk
 move.l d0,SpritesHandle		* save handle 
 move.b #CompressedType,SpritesFileType-S(A5)

ODFTFTOpenOk
 bra GotDiskParameters ************* debug: disable checking.

* Now (and only after Open), try to get the disk info
* (If we try GetDiskParameters: which does a lock: without
* the disk present, it always then returns the error code 0,
* even when the disk is re-inserted).
 move.w DiskNum,d2
 asl.w #1,d2 * disk number times 2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is max cell number within this file
 move.w 0(a0,d2.w),d3
 cmp.w #$ffff,d3 * default (null) value
 bne GotDiskParameters
GetDiskParameters
; and make a note of the size of the sprites file,
; if we haven't already
 move.l #SpritesFilename,d1 * address of filename
 bsr GetDiskInfo
 tst.w d1
 beq DiskChangeNoDisk

GotDiskParameters
* If we displayed a requestor, change it to say
* "Loading" to obliterate the "please insert" message
 move.b RequestorDisplayed,d0
 beq.s GDPNoRequestor
 move.l TextScreenBase,-(sp)
 move.l PhysicalBase,TextScreenBase
 move.l CursorXPos,-(sp) * x and y
 move.l #RequestorX+RequestorY+8,CursorXPos * x and y pos:  middle of screen
 bsr prs
 dc.b "     Loading...     ",0
 even
 move.l (sp)+,CursorXPos
 move.l (sp)+,TextScreenBase
 move.b #0,RequestorDisplayed
GDPNoRequestor:
 move.l #0,DiskCacheOffset * void cache (which is now from wrong
* sprites file).
 move.w DiskNum,d1 * disk number in drive.

;;GotDiskParameters:
 move.w #0,LastCellRead * void this cell in case it's
* been corrupted
 move.w DiskNum,d1 * return disk number in error return
 rts

DiskChangeNoDisk
GDINoDisk
 move.w #0,d1 * disk number in drive
 rts
;----
GDINoDiskPop
 move.l (sp)+,d1
 rts
;---
GetDiskInfo
* Get disk info for DiskNum.w with filename (d1.l)
* Returns error code d1.w=0 or the disk read.

* Must ensure that disk is in drive before doing lock,
* else it will always return 0, even when disk is
* re-inserted.
 move.l #ACCESS_READ,d2
 movem.l a0-a6,-(sp)
  bsr CheckForDiskInDrive
  CALLDOS Lock
 movem.l (sp)+,a0-a6
 tst.l d0 * does it exist?
 beq GDINoDisk * didn't find file.
 bmi GDINoDisk

 move.l d0,-(sp) * lock
  move.l d0,d1 * lock as parameter to examine
  move.l InfoBlockPtr-S(A5),d2 * a 256-byte temporary buffer.
* For FileInfoBlock.
* d2.l must be long-aligned
 add.l #4,d2
 and.l #$FFFFFFFC,d2
 move.l d2,-(sp) * buffer address
  bsr CheckForDiskInDrive
  CALLDOS EXAMINE
* gives information on file structure. See P.342 in Amiga System Programmers
 move.l (sp)+,a0 * buffer address
 tst.l d0
 beq GDINoDiskPop
;; bmi GDINoDiskPop
 move.l 124(a0),d0 * size
 lsr.l #7,d0 * get number of cells. Assumes cell is 128 bytes
 move.w DiskNum,d2
 asl.w #1,d2 * disk number times 2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is min, max cell numbers within this file
 move.w -2(a0,d2.w),d1 * get highest cell in previous file
 add.w d0,d1
 move.w d1,0(a0,d2.w) * last cell in this file

 move.l (sp)+,d1 * lock value
 movem.l a0-a6,-(sp)
  bsr CheckForDiskInDrive
  CALLDOS Unlock * I don't want the lock any more.
 movem.l (sp)+,a0-a6

 rts
;----
 endc * Amiga.
;===================================
;-------

 ifne ST
DiskRequestor:
* display a request for disk DiskNum.w
RequestorX equ $500000
RequestorY equ $40
 move.b RequestorDisplayed,d0
 bne DiskRequestorRet
 movem.l d0-d7/a0-a6,-(sp)
 move.l TextScreenBase,-(sp)
 move.l PhysicalBase,TextScreenBase
 move.l CursorXPos,-(sp) * x and y
 move.l #RequestorX+RequestorY,CursorXPos * x and y pos:  middle of screen
 lea S(PC),a5 * for benefit of text printing code.

; move.l InfoBlockPtr-S(A5),a4
 lea ReversedCellBuffer,a4 * temporary workspace
 move.w #20*8,2(a4) * width to clear
 move.w #3*8,4(a4) * height to clear
; bsr ClearRectangle * clear area of requestor.
 bsr PhysicalClearRectangle

 bsr prs
 dc.b "-------------------- ",0
 even
 move.l #RequestorX+RequestorY+8,CursorXPos * x and y pos:  middle of screen
 move.w DiskNum,d0
 add.b #'0',d0
 move.b d0,DiskNumText
 bsr prs
 dc.b "Please insert disk "
DiskNumText: dc.b " ",0
 even
 move.l #RequestorX+RequestorY+16,CursorXPos * x and y pos:  middle of screen
 bsr prs
 dc.b "-------------------- ",0
 even
 move.l (sp)+,CursorXPos
 move.l (sp)+,TextScreenBase
 move.b #1,RequestorDisplayed
 movem.l (sp)+,d0-d7/a0-a6
DiskRequestorRet:
 rts * yes
;---
DiskError:
* We've noticed that the wrong disk is in the drive
* - request its immediate return!
 movem.l d0-d7/a0-a6,-(sp)
  move.b #0,RequestorDisplayed * force display of requestor
  bsr DiskRequestor * display requestor immediately
  bra.s DiskChangeLoop
;---
CheckForDiskChange
; we want disk d1.w. Do disk change stuff if it's needed
 cmp.w DiskNum,d1
 bne.s CFDC1
 rts

CFDC1:
 move.w d1,DiskNum
* drop through to DiskChange

DiskChange:
* we need to open sprites file on DiskNum:w
* If it isn't there, display a requestor and keep
* on retrying until it is.
 movem.l d0-d7/a0-a6,-(sp)
  move.b #0,RequestorDisplayed
DiskChangeLoop:
  bsr DiskChange2
* d1.w is the disk found in the drive...
  cmp.w DiskNum,d1 * is it what we wanted?
  beq.s DiskChangeExit
  bsr DiskRequestor
  bra.s DiskChangeLoop

DiskChangeExit
 movem.l (sp)+,d0-d7/a0-a6
 rts

DiskChange2:
* We're trying to change to disk DiskNum:
* wait until the user puts in a new disk, and return
* d1.w as its number. Don't do any requestors or anything
* else.

* Close current sprites file ( to avoid running out of handles)
 move.l SpritesHandle,d0
 beq OpenDiskForTheFirstTime ; not opened, or something
 move.w d0,-(sp)
 call_bdos $3e * close
 addq.l #4,sp
; ignore any errors on close: doesn't access disk at all
; So it can't be any problem we're interested in now (May not
; have opened the sprites file correctly in the first place, I
; guess, but it's too late now...)

OpenDiskForTheFirstTime
* Open sprites file for the disk we want
 move.w DiskNum,d0
 add.b #'0',d0
 move.b d0,SpritesFileNum * "SpritesN.DAT"
 move.l #0,SpritesHandle * don't try to reclose it if
* we get an error which pushes us back to diskError2
 move.l #0,LastSeekPos

* have we decided whether to use compressed or uncompressed
* sprites files yet?
 move.b SpritesFileType-S(A5),d0
 cmp.b #CompressedType,d0
 beq ODFTFTCompressed
* either uncompressed, or we don't know yet.

 move.w #2,-(sp) * open for read+write
 pea	SpritesFilename
 call_bdos $3d * open
 addq.l	#8,sp 
 tst.l d0
 bpl.s ODFTFTOpenUncompressed
* open failed. Two possible actions. 1: print a requestor
* 2: If we don't yet know whether to use compressed files or
*    not, try them. i.e.
 move.b SpritesFileType-S(A5),d0
 bne DiskChangeNoDisk * we've decided, and it was compressed type.

ODFTFTCompressed
* patch filename to try a compressed version...
 move.l #ConstCompressedExtension,SpritesFileDot-S(A5)
 move.w #2,-(sp) * open for read+write
 pea	SpritesFilename
 call_bdos $3d * open
 addq.l	#8,sp 
 move.l #ConstUncompressedExtension,SpritesFileDot-S(A5)
 tst.l d0
 bmi DiskChangeNoDisk
 move.b #CompressedType,SpritesFileType-S(A5)
 bra.s ODFTFT2

ODFTFTOpenUncompressed
 move.b #UncompressedType,SpritesFileType-S(A5)

ODFTFT2
 move.l	d0,SpritesHandle		* save handle 
 bra GotDiskParameters *************** disable checking.


 move.w DiskNum,d2
 asl.w #1,d2 * disk number times 2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is max cell number within this file
 move.w 0(a0,d2.w),d3
 cmp.w #$ffff,d3 * default (null) value
 bne.s GotDiskParameters
GetDiskParameters
; and make a note of the size of the sprites file,
; if we haven't already
 move.w #0,-(sp) * attribute (may prevent use of write-protected
; files, but I'm not sure.)
 move.l #SpritesFilename,-(sp)
 call_bdos $4e * SFIRST
 addq.l #8,sp
 tst.l d0
 bmi DiskChangeNoDisk * this error is likely to be fatal
 move.l DTABuffer+26,d0 * d0.l is length of file
 lsr.l #7,d0 * get number of cells. Assumes cell is 128 bytes
 move.w DiskNum,d2
 asl.w #1,d2 * disk number times 2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is min, max cell numbers within this file
 move.w -2(a0,d2.w),d1 * get highest cell in previous file
 add.w d0,d1
 move.w d1,0(a0,d2.w) * last cell in this file

GotDiskParameters:
 move.w #0,LastCellRead * void this cell in case it's
* been corrupted
* If we displayed a requestor, change it to say
* "Loading" to obliterate the "please insert" message
 move.b RequestorDisplayed,d0
 beq.s GDPNoRequestor
 move.l TextScreenBase,-(sp)
 move.l PhysicalBase,TextScreenBase
 move.l CursorXPos,-(sp) * x and y
 move.l #RequestorX+RequestorY+8,CursorXPos * x and y pos:  middle of screen
 bsr prs
 dc.b "     Loading...     ",0
 even
 move.l (sp)+,CursorXPos
 move.l (sp)+,TextScreenBase
 move.b #0,RequestorDisplayed
GDPNoRequestor:
 move.l #0,DiskCacheOffset * void cache (which is now from wrong
* sprites file).
 move.w DiskNum,d1 * disk number in drive.
 rts

DiskChangeNoDisk
 move.w #0,d1 * disk number in drive
 rts
;----

 endc * ST
;-----
MCLoadCells: 
 movem.l a3-a6,-(sp) 
 move.w 2(a4),d0 
 move.w 4(a4),d1 
 bsr m_load_u 
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l clear
 rts 
 
*------------------------ 
 
* d0 = 1st cell to load 
* d1 = last cell to load 
 
 
m_load_p: 
 move.w sys_clock,d2 * d2 = clock 
 bset #15,d2  * protect it 
 bra m_load0 
 
m_load_u: 
* enter with d0=first cell, d1=last cell
 move.w sys_clock,d2 * d2 = clock 
 
m_load0: 
; move.w d2,timer  * save timer value 
 move.b d2,timer
 
 sub.w d0,d1  * d1 = no. cells -1 
 addq.w #1,d1  * counter 
 sub.w pntrs_tab+28,d0 * - cell base 
 move.w d0,cell_1  * save 1st cell no. 
; move.w d1,cell_cnt  * save cells counter 
 
 cmp.w #4000,d1 *>>Mike 31/5/89 
 bcc.s m_loadBug 
 cmp.w #32000,d0 *>>MIke 31/5/89 
 bcs.s m_loadOk *>>Mike 31/5/89 
m_loadBug: 
 move.l #$106,d0 * bug in cell load request
 bsr ErrorHandler
 bra CloseDown * this error is fatal, unless corrected by acode.
  
m_loadOk: 
 mulu #128,d1  * x cell length 
 move.l d1,data_len  * save data length 

* don't bother doing a big purge
* - let the linked pool handle it, with small+frequent purges
* Drop through to h_rd_data

h_rd_data: 
* read cells from cell_1 onwards into cell pool
 movem.l d0-d7/a0-a6,-(sp)
  bsr AbsH_Rd_Data
 movem.l (sp)+,d0-d7/a0-a6
ARDRet
 rts

AbsH_Rd_data
; want to load cell cell_1
; Is it contained within the sprites file we
; curently have open?
 bra AHRDNoCheck * disable disk checking ***************


 move.w cell_1,d0
 move.w DiskNum,d1
WhichDisk:
 move.w d1,d2
 asl.w #1,d2 * disk number times 2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is max cell number within this file
 move.w 0(a0,d2.w),d3 * do we know where this sprites file ends?
 cmp.w #$ffff,d3
 bne.s WhichDiskGotParameters
; don't have parameters for this disk: so
; we don't know the size of the sprites file or anything:
; so we need to request its insertion and read its size
 movem.w d0-d1,-(sp)
  move.w d1,DiskNum * prompt user for disk d1.
  bsr DiskChange
 movem.w (sp)+,d0-d1
 move.w 0(a0,d2.w),d3 * end of this sprites file.

WhichDiskGotParameters
 cmp.w -2(a0,d2.w),d0 * last number in previous file.
 bgt.s NotPreviousDisk
; must be in the file before this one
 sub.w #1,d1 * DiskNum
 bne.s WhichDisk

NotPreviousDisk
 cmp.w d3,d0 * d3.w is last cell in this file
 ble.s WhichDiskOk
; must be in the file after this one
 add.w #1,d1 * DiskNum
 bra.s WhichDisk

WhichDiskOk:
; sprite is on disknum D1: request change if necessary
 bsr CheckForDiskChange

WhichDiskOk2:
* Do we need to check if the disk has been changed
 move.b CheckDiskFlag,d0
 beq AHRDNoCheck
 bsr ABSCheckDisk1

AHRDNoCheck
 move.l data_len,d3 * load length 
 move.w cell_1,d2 * cell number to load
 move.w d2,LastCellRead
 ext.l d2
 lsl.l #2,d2 * times 4 to get cell_tab entry
 move.l cell_tabPtr,a1
 add.l d2,a1

AHRDLoop
 move.l PoolFSLL,d2
 bne.s AHRDOk
 move.w #150,d3 * don't purge more than 150 cells
 bsr PurgeD3Cells
 move.l PoolFSLL,d2
 bne.s AHRDOk
 move.w #$104,d0 * Purge Error
 bsr ErrorHandler
 bsr PurgeAllCells
 bra.s AHRDLoop

AHRDOk
 move.l d2,a0
* AHRDA0
* loading a cell at a0.l
* set up its cell table entry (at a1.l)
 move.l a0,(a1)
 move.b timer,(a1)
* remove from linked list
 move.l (a0),PoolFSLL
; bsr CheckPoolFSLL
* and load it at d2.l=a0.l...
 bra LoadNoCache ************** for debugging compressed load

 ifeq AllowCache
  move.l #128,d3 ******* force load of 1 cell only
  bra LoadNoCache * no cache allowed
 endc
 move.l DiskCachePtr,d1
 beq LoadNoCache * haven't got a cache! (e.g. not enough memory)
;
 ifne AllowCache
* Simple disk caching code...
* Timings for Rocket Ranger demo, from pressing '1'
* to the game appearing:
*  No cache: 8.5 sec 
* 2048 byte: 10.42 sec
* 4096 byte: 6.4 sec
* 8000 byte: 4.45 sec (5.8 sec with -16 cell offset)
* 16000 byte: 3.4 sec

* Off floppy:
* No cache:  55.8 sec
* 4K cache:  35.3 sec
* 16K cache: 21.2 sec

* is it in our track buffer
 movem.l d0-d7/a0-a6,-(sp)
  bsr TryCache
 movem.l (sp)+,d0-d7/a0-a6
 rts
;---
TryCache
 move.l DiskCacheOffset,d0 * start of the part of sprites file we have
* in memory
 beq LoadCache * no cache available
 move.w cell_1,d1 * 1st cell to load 
 ext.l d1
 lsl.l #7,d1  * 1st cell offset 
 sub.l d0,d1 * return d1=offset within our buffer
 cmp.l #DiskCacheSize-300,d1
 bcc.s LoadCache
* in cache at DiskCache+d1 - copy it in.
 move.l DiskCachePtr,a1
 add.l d1,a1
DiskCacheCopy
* copy 128 bytes from (a1) to (a0)
 move.w #(128/4)-1,d0
DiskCacheLoop
 move.l (a1)+,(a0)+
 dbra d0,DiskCacheLoop
 rts
;----
LoadCache
 move.w cell_1,d1 * 1st cell to load 
 beq LoadNoCache * asked for a silly cell number
 ext.l d1
* before the current one, in case we're hopping around a bit.
CacheNearStart
 bsr SeekCellD1 * change file pointer to cell d1
* load a new block into cache
 movem.l d0-d7/a0-a6,-(sp) * save pool cell address
  bsr SpecificLoadCache
 movem.l (sp)+,d0-d7/a0-a6 * restore pool cell address
 bra TryCache
;--------
 endc * AllowCache

;---
;=============================================== 
 
 
 
;--------------------------------
;    memory purge code
MCPurgeAllCells
 movem.l a3-a6,-(sp)
  bsr PurgeAllCells
 movem.l (sp)+,a3-a6
 rts
;------- 
PurgeAllCells
 lea PoolFSLL,a1
 move.l cell_tabPtr,a0
 move.w NumCells,d7  * cell_tab len 
 subq.w #1,d7 

PACLoop
 tst.l (a0) * is cell using mem?
 beq PACNoCell
* link cell onto free space linked list.
 move.l (a0),d2
 and.l #CellAddressMask,d2
 move.l d2,a2 * a2:=address of this cell.
 move.l (a1),(a2) * make this cell point to free space chain
 move.l a2,(a1) * become the first entry in chain
 clr.l (a0) * remove its pointer
 
PACNoCell
 add.l #4,a0 * step on through cell table
 dbra d7,PACLoop
 rts
;---

 rts
;------------------
*   map out memory pool 
m_purge: 
* lose all cells which are older than d0.w timer increments
* up to a maximum of d3.w cells

* For the purge timing, we have two possible maps, depending
* on whether the timer wraps round or not:
*
*       +-+   +-+
* | | Purge  | | Keep
* | |<- d4  | |<- Current Time d5
* | | Keep  | |
* | |<- Current Time d5 | | Purge
* | |   | |
* | | Purge  | |
* | |   | |<- d4
* +-+   +-+ Keep
 movem.l d0-d7/a0-a6,-(sp)
  bsr m_purge1
 movem.l (sp)+,d0-d7/a0-a6
 rts
;---
m_purge1
 move.w sys_clock,d4
 and.w #$7f,d4
 move.w d4,d5
 sub.w d0,d4
 bpl m_purgeNoWrap
 and.w #$7f,d4
* purge cells with timers between d5 and d4

 lea PoolFSLL,a1
 move.l cell_tabPtr,a0
 move.w CurrentPurgeCell,d0
 move.w NumCells,d7  * cell_tab len 
 sub.w d0,d7
 ext.l d0
 add.l d0,d0
 add.l d0,d0 * 4 bytes per cell table entry.
 add.l d0,a0
 subq.w #1,d7 

PurgeLoop
 tst.l (a0) * is cell using mem?
 beq PurgeNoCell
 move.b (a0),d1 * d1=protect flag/timer
 bmi PurgeNoCell  * -ve = protected cell 
 and.w #$7f,d1
 cmp.w d5,d1  * outside purge range?
 bcs.s PurgeNoCell  * yup
 cmp.w d4,d1 * outside purge range?
 bgt.s PurgeNoCell *> cc.s PurgeNoCell * yes
* link cell onto free space linked list.
 move.l (a0),d2
 and.l #CellAddressMask,d2
 move.l d2,a2 * a2:=address of this cell.
 move.l (a1),(a2) * make this cell point to free space chain
 move.l a2,(a1) * become the first entry in chain
 clr.l (a0) * remove its pointer
 subq.w #1,d3 * number of cells we're allowed to lose
 bmi.s PurgeEnd
 
PurgeNoCell
 add.l #4,a0 * step on through cell table
 dbra d7,PurgeLoop
 move.l cell_tabPtr,a0
 move.w CurrentPurgeCell,d7 * some more cells to look
* at at the start of the table
 bne.s PurgeLoop

PurgeEnd
 sub.l cell_tabPtr,a0
 move.l a0,d0
 asr.w #2,d0
 move.w d0,CurrentPurgeCell * next time, start purging from here.
 rts
;---
m_purgeNoWrap
 and.w #$7f,d4
* keep timer values between d4 and d5
 lea PoolFSLL,a1
 move.l cell_tabPtr,a0
 move.w NumCells,d7  * cell_tab len 
 subq.w #1,d7 

PurgeNoWrapLoop
 tst.l (a0) * is cell using mem?
 beq PurgeNoWrapNoCell
 move.b (a0),d1 * d1=protect flag/timer
 bmi PurgeNoWrapNoCell  * -ve = protected cell 
 and.w #$7f,d1
 cmp.w d4,d1  * too old ? 
 bcs.s PurgeNoWrapPurge * yes 
 cmp.w d5,d1 * within keep range?
 ble.s PurgeNoWrapNoCell * yubet (was bcs)

PurgeNoWrapPurge
* link cell onto free space linked list.
 move.l (a0),d2
 and.l #CellAddressMask,d2
 move.l d2,a2 * a2:=address of this cell.
 move.l (a1),(a2) * make this cell point to free space chain
 move.l a2,(a1) * become the first entry in chain
 clr.l (a0) * remove its pointer

 subq.w #1,d3 * number of cells we're allowed to lose
 bmi.s PurgeEnd
 
PurgeNoWrapNoCell
 add.l #4,a0 * step on through cell table
 dbra d7,PurgeNoWrapLoop
 rts
;------

 
 
;--------------------------------
; Pre-load cells reqd for this picture
 
MCpre_load_cells: 
 move.w UseVm,d0 * tst.w UseVm(PC) * -S(A5) *>>Mike 18/1/89 
 beq.s MCPreLoadRet *>>mike 18/1/89 
 movem.l a3-a6,-(sp) 
 bsr IncrementClock
 bsr pre_load 
 bsr IncrementClock
 bsr ResetPreload
 movem.l (sp)+,a3-a6 
MCPreLoadRet 
 clr.l d0 * return high word of d0.l clear
 rts 
*--------------------------------------- 
cell_limit: equ 11  * load pairs diff 
 
pre_load: 
* go through load_list, which is a bitwise table
* with a bit set for each cell we want to load.
 move.l load_list,a0
 move.w #0,d3 * offset into list
 move.w #0,d5 * cell number to load
 move.w #0,d6 * number of cells preloaded
pre_loadByteLoop
 move.w #$80,d4 * bit pattern to and with
pre_loadBitLoop
 move.b 0(a0,d3),d0
 and.b d4,d0
 beq.s pre_loadNo
* load cell number d5.w
 movem.l d0-d7/a0-a6,-(sp) *  movem.l d3-d6/a0,-(sp)

; bsr CheckPoolChain ********


  move.w d5,d0
  add.w pntrs_tab+28,d0 * - cell base 
  move.w d0,d1
  bsr m_load_u * enter with d0=first cell, d1=last cell
 movem.l (sp)+,d0-d7/a0-a6 * movem.l (sp)+,d3-d6/a0
 addq.w #1,d6 * number of cells preloaded in one go
 cmp.w PoolSizeCells,d6
 bcc.s pre_loadEnd * don't pre_load more cells than will
* fit in the pool - that's pointless!
 move.w d6,d0
 and.w #$7f,d0
 cmp.w #$7f,d0
 bne.s pre_loadNo
* change timer value every 128 cells, to make sure m_purge
* can always find something without the current timer value
 bsr IncrementClock

pre_loadNo
 addq.w #1,d5 * increase cell number
 cmp.w NumCells,d5
 bcc.s pre_loadEnd
 lsr.b #1,d4 * shift bit pattern
 bne.s pre_loadBitLoop
 addq.l #1,d3 * increase byte offset
 bra.s pre_loadByteLoop

pre_loadEnd
 bsr ResetPreload
 rts


 
;------ 
;GetFreeCell:
;* get a0.l as the address of an unused cell data block
; move.l PoolFSLL,d2
; bne.s GFCRet
; movem.l d0-d7/a1-a6,-(sp)
;  move.w #25,d3
;  bsr PurgeD3Cells
; movem.l (sp)+,d0-d7/a1-a6
;GFCRet
; move.l d2,a0
; move.l (a0),PoolFSLL * take cell out of pool.
;; bsr CheckPoolFSLL
; rts
;---
PurgeD3Cells:
* no free cells, have to purge (somehow!)
* And return d2.l as the next free cell to use
;  move.w sys_clock,d0 * d0 = time now 
;  subi.w #36,d0  * d0 = 5 mins ago 
 move.w #10,d0 * purge anything older than 10 vm's or 5 preloads.
 bsr m_purge
 move.l PoolFSLL,d2
 bne PurgeCellsOk

* oh dear - try purging stuff with current time
;  move.w sys_clock,d0 * d0 = time now 
  move.w #0,d0 * purge anything
  bsr m_purge
 move.l PoolFSLL,d2
 bne.s PurgeCellsOk

* couldn't purge anything
 move.w #$104,d0 * purge error
 bsr ErrorHandler
 bsr PurgeAllCells
 rts * bra CloseDown * fatal, unless corrected by acode.

PurgeCellsOk
 rts
;-=-----------
* check if same disk is in by re-reading the last cell.
ABSCheckDisk1
 ifne ST
  move.w DriveLetter,d0
  cmp.w #'C',d0
  bcs.s ACD2
  rts * don't check for disk changes on hard disk!

ACD2
 endc
 move.w LastCellRead,d1
 beq acdNoCheck * haven't read anything yet!
 cmp.w NumCells,d1
 bcc acdNoCheck * silly value
 move.b #0,CheckDiskFlag * we've checked the disk
 bsr SeekCellD1 * seek cell number d1
 move.w LastCellRead,d1
 beq acdNoCheck * in case seekcell did a disk change
 move.l #LastCellBuffer,d2
 move.l #128,d3 * load one cell
 bsr LoadNoCacheNoSeek ; read one cell @d2
; where is cell in memory?
 move.w LastCellRead,d2
 beq acdNoCheck * in case LoadNoCache did a disk change
 ext.l d2
 lsl.l #2,d2 * times 4 to get cell_tab entry
 move.l cell_tabPtr,a1
 add.l d2,a1
 move.l (a1),d2
 and.l #CellAddressMask,d2
* d2.l is address of cell in memory
 bne.s CheckDisk2
* cell must have been purged, somehow! (Surely can't happen,
* 'cause this was the last cell loaded, so what would
* cause it to vanish?)
 add.w #1,LastCellRead
 bra ABSH_Rd_Data

CheckDisk2:
* is it the same?
 move.w #(128/4)-1,d0
 lea LastCellBuffer,a0
 move.l d2,a1
CheckDisk3:
 cmp.l (a0)+,(a1)+
 bne.s CheckDiskChanged
 dbra d0,CheckDisk3
acdNoCheck:
 rts * disk is still the same: return to caller. bra acdNoCheck

CheckDiskChanged:
 bsr DiskError
 bra ABSCheckDisk1
;------
MarkDiskForChecking:
; we want to check that the right disk is in before
; we do any more vm
 move.b #1,CheckDiskFlag
 rts
;---
 ifne sT
SpecificLoadCache
 lsl.l #7,d1  * 1st cell offset 
 move.l d1,DiskCacheOffset
 move.l DiskCachePtr,a0
LoadCacheRead:
 move.l SpritesHandle,d1
  move.l a0,-(sp) * free memory 
  move.l #DiskCacheSize,-(sp) * load length 
  move.w d1,-(sp) * file 
 call_bdos $3f * read data
 adda.l #12,sp 
 tst.w d0
 bpl.s LoadCacheOk
 bsr DiskError * prompt user to put the disk back in.
 bra.s LoadCacheRead

LoadCacheOk:
 rts
;-----
SeekCellD1:
* seek cell d1.w in current file, allowing
* for which is the first cell in this file.
* Must preserve d1
 movem.l d0-d7/a0-a6,-(sp)
  bsr SpecificLoadCacheLSeek
 movem.l (sp)+,d0-d7/a0-a6
 rts
;---
SpecificLoadCacheLSeek
 clr.l d0
 move.w d1,d0  * 1st cell to load 

 move.w DiskNum,d2
 asl.w #1,d2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is max cell number within this file
 sub.w -2(a0,d2.w),d0 * last sprite in previous file
 sub.w #1,d0 * first sprite in this file->0.

 lsl.l #7,d0  * 1st cell offset 

* The ST absolute seek function is very slow (circa .4 seconds)
* even off hard disk, and even when the same cell is requested
* twice in succession. We keep a record here of our position
* within the file.
* Seek to absolute position d0
; move.l d0,d1
; sub.l LastSeekPos-S(A5),d0
; sub.l #128,d0 * and allow for the fact that we read a cell last time
;* which advanced the ST's pointer a little
; move.l d1,LastSeekPos-S(A5)

SeekToPosD0
 move.w #0,-(sp)  * 0=abs, 1=move file pointer relative to last pos
 move.l SpritesHandle,d3
 move.w d3,-(sp) 
 move.l d0,-(sp) * position to seek to.
 call_bdos $42
 tst.l d0
 bpl.s LoadCacheOk2
* failed - restore arguments, and display a requestor
 move.l (sp)+,d0 * position to seek to
 move.w (sp)+,d3
 adda.l #4,sp  * pop 0 and function number
 bsr DiskError * prompt user to put the disk back in.
 bra.s SeekToPosD0 * SpecificLoadCacheLSeek

LoadCacheOk2:
 add.l #10,sp * discard parameters to bdos LSEEK
 rts
;---
LoadNoCache:
; load cell_1 at address d2.l
 cmp.b #CompressedType,SpritesFileType-S(A5)
 bne.s LNCUncompressed
 bsr HuffmanLoadCell
 rts

LNCUncompressed
 move.w cell_1,d1  * 1st cell to load 
 bsr SeekCellD1 * preserves all reggies

LoadNoCacheNoSeek
 movem.l d3/a1,-(sp)
  move.l #128,d3 * read in one cell
  move.l SpritesHandle,d1
  bsr ReadLoop ; read data @ d2 of max length d3.l with file handle d1
 movem.l (sp)+,d3/a1 * amount still to do, cell table ptr
 add.l #4,a1 * 4 bytes per cell_tab entry
 sub.l #128,d3
 beq.s AHRDRet
 bpl AHRDLoop
AHRDRet
ReadLoopOk
 rts
;---
;---
ReadLoop
* read data @ d2 of max length d3.l with file handle d1
 move.l d2,-(sp) * free memory 
 move.l d3,-(sp) * load length 
 move.w d1,-(sp) * file 
 call_bdos $3f * read data
 adda.l #12,sp 
 tst.l d0
 bpl.s ReadLoopOk
 bsr DiskError * prompt user to put the disk back in.
 bra.s ReadLoop
;----------------------------
 endc * ST
;=============================
 ifne Amiga

SpecificLoadCache
 lsl.l #7,d1  * 1st cell offset 
 move.l d1,DiskCacheOffset
LoadCacheRead:
 move.l SpritesHandle,d1
 move.l DiskCachePtr,d2 * area to load stuff into.
 move.l #DiskCacheSize,d3 * load length
 bsr ReadLoop
 tst.l d0 * amount read/error code
 bpl.s LoadCacheOk

 bsr DiskError * prompt user to put the disk back in.
 bra.s LoadCacheRead

LoadCacheOk:
 rts
;-----
SeekCellD1: * Amiga
* seek cell d1.w in current file, allowing
* for which is the first cell in this file.
* Must preserve d1
 movem.l d0-d7/a0-a6,-(sp)
 move.w DiskNum,d2
 asl.w #1,d2
 lea SpriteFileTable,a0
; 0(a0,d2.w) is max cell number within this file
 sub.w -2(a0,d2.w),d1 * last sprite in previous file
 sub.w #1,d1 * first sprite in this file->0.

 move.w d1,d2
 ext.l d2
 lsl.l #7,d2 * 1st cell offset  * Assumes 128 bytes per cell
 move.l d2,d0 * position to seek to.
 bsr SeekToPosD0
 movem.l (sp)+,d0-d7/a0-a6
 rts
;---
SeekToPosD0
 move.l d0,d2 * AmigaDos likes seek position in d2
 move.l SpritesHandle,d1 * from OPEN in MCInitSpritesFile
* d2.l is position within file
 move.l #-1,d3 * OFFSET_BEGINNING.
 move.l d2,-(sp)
  bsr CheckForDiskInDrive
  CALLDOS SEEK
 move.l (sp)+,d2 * position we asked for.
* d0.l is old file pointer, or -ve for errors
* (e.g. disk out)
 tst.l d0
 bpl.s SeekCellOk

SeekCellError2:
 bsr DiskError ;>>Mike18/9/89
; movem.l (sp)+,d0-d7/a0-a6
 bra SeekCellD1

SeekCellError:
SeekCellOk
; movem.l (sp)+,d0-d7/a0-a6
 rts
;---
;SeekCellD2
; move.l SpritesHandle,d1 * from OPEN in MCInitSpritesFile
; movem.l d1-d2,-(sp)
;  ext.l d2
;  lsl.l #7,d2 * 1st cell offset  * Assumes 128 bytes per cell
;* d2.l is position within file
;  move.l #-1,d3 * OFFSET_BEGINNING.
;  CALLDOS SEEK
; movem.l (sp)+,d1-d2 * d1.l is file handle
; rts
;---
;---
LoadNoCache:
 cmp.b #CompressedType,SpritesFileType-S(A5)
 bne.s LNCUncompressed
 bsr HuffmanLoadCell
 rts

LNCUncompressed
 move.w cell_1,d1  * 1st cell to load 
 bsr SeekCellD1

LoadNoCacheNoSeek
 movem.l d3/a1,-(sp)
  move.l #128,d3 * read in one cell
  move.l SpritesHandle,d1
  bsr ReadLoop ; read data @ d2 of max length d3.l with file handle d1
 movem.l (sp)+,d3/a1 * amount still to do, cell table ptr
 add.l #4,a1 * 4 bytes per cell_tab entry
 sub.l #128,d3
 beq.s AHRDRet
 bpl AHRDLoop
AHRDRet
ReadLoopOk
 rts
;---
;---
;ReadLoop
;* read data @ d2 of max length d3.l with file handle d1
; move.l d2,-(sp) * free memory 
; move.l d3,-(sp) * load length 
; move.w d1,-(sp) * file 
; call_bdos $3f * read data
; adda.l #12,sp 
; tst.l d0
; bpl.s ReadLoopOk
; bsr DiskError * prompt user to put the disk back in.
; bra.s ReadLoop
;----------------------------
CheckForDiskInDrive:
 movem.l d0-d7/a0-a6,-(sp)
  move.b $bfe001,d0 * CIA-A port register A
  btst #2,d0 * is disk in drive? See P.19,21 Amiga System Programmers
* Could also maybe do this with input events, or using
* the disktrack device. But this seems simplest!
  bne.s CFDID1 * disk is in drive
  bsr DiskRequestor

CFDID1:
 movem.l (sp)+,d0-d7/a0-a6
 rts


 endc * Amiga

;====================================

MCSaveProtected
; save all cells which have protection flag set
; (To sprites.dat file on hard disk)
 ifne ST
 movem.l a3-a6,-(sp)
  move.l #0,d7 * cell number
;  move.w #0,d6 * offset in cell table
  move.l cell_tabPtr,a1
MCSaveProtectedLoop
;  move.w 0(a1,d6),d0
  tst.l (a1)
  bpl.s MCNotMarked
  movem.l d6-d7/a1,-(sp)
   bsr SaveCell
  movem.l (sp)+,d6-d7/a1

MCNotMarked
  addq.w #1,d7 * increase cell number
;  addq.w #6,d6 * offset in cell table
  addq.l #4,a1 * next cell table entry
  cmp.w NumCells,d7
  bcs.s MCSaveProtectedLoop
 movem.l (sp)+,a3-a6
 clr.l d0 * return high word of d0.l clear
 endc
 rts
;---
 ifne ST
SaveCell
; save cell number d7.l, whose data is at (a1) * 2(a1,d6)
 movem.l d6-d7/a1,-(sp)
SaveCell1:
 move.l d7,d0
 lsl.l #7,d0  * 1st cell offset 
 move.l SpritesHandle,d3
 clr.w -(sp)  * move file pointer 
 move.w d3,-(sp) 
 move.l d0,-(sp) 
 call_bdos $42
 adda.l #10,sp 
 tst.l d0
 bpl.s SaveCellOk1
 bsr DiskError * prompt user to put the disk back in.
 bra.s SaveCell1

SaveCellOk1:
 movem.l (sp)+,d6-d7/a1

; move.l 2(a1,d6),a0 * saving a cell at a0.l
; move.w timer,(a1,d6) * clear protection flag
 move.l (a1),d0
 and.l #CellAddressMask,d0
 move.l d0,a0
 bclr #15,(a1) * clear protection flag
* and save it...
SaveCell2
 move.l SpritesHandle,d1
 move.l a0,-(sp) * save address
 move.l #128,-(sp) * save length 
 move.w d1,-(sp) * file 
 call_bdos $40 * write data
 adda.l #12,sp 
 tst.w d0
 bpl.s SaveCellOk2
 bsr DiskError * prompt user to put the disk back in.
 bra.s SaveCell2

SaveCellOk2
 rts
;----------
 endc
;CheckPoolFSLL: 
; move.l d0,-(sp)
; move.l PoolFSLL,d0
; btst #0,d0
; beq.s CPFS1
; dc.w $4afa
;CPFS1
; move.l (sp)+,d0
; rts
;---
;CheckPoolChain
; movem.l d0/a0,-(sp)
; move.l PoolFSLL,d0
; beq.s CPCEnd
; move.l d0,a0
;CPCLoop
; move.l (a0),d0
; beq.s CPCEnd
; btst #0,d0
; bne.s CPCFault
; cmp.l #$80000,d0
; bcc.s CPCFault
; bra.s CPCOk
;
;CPCFault
; dc.w $4afa
;CPCOk
; move.l d0,a0
; bra.s CPCLoop
;
;CPCEnd
; movem.l (sp)+,d0/a0
; rts

;=========================================
; 3d_BOOT.S 26/2/90
;
;
* ***** Check assignment of V_Map space - looks funny to me. -- Mike 22/1/89 
*>>Mike 9/2/89 - Init_Memory error-trapping added. 
*>>Mike 26/6/89 - setup_ptrs changed to use signed addressing 
*>>Mike26/6/89Amiga 
*>>Mike2/7/89Amiga - ADDED MASKS_END etc.

MCSetUpPtrs: 
	movem.l	a3-a6,-(sp) 
	bsr	setup_ptrs 
	movem.l	(sp)+,a3-a6 
	clr.l d0 * return high word of d0.l clear
	rts 
 
 
* copy across structure ptrs, converting 
* from relative to absolute etc. 
 
* calc a0.l as address of list# passed in v1. 
 
setup_ptrs: 
	move.w	2(a4),d0		* V1 
	asl.w	#2,d0 
	lea	List0Ptr-S(a5),a0 
	ext.l	d0 
	add.l	d0,a0 
	move.l	(a0),a0 
setup_ptrsA0
* a0.l is structure buffer
;>>Mike26/6/89Amiga	lea	SBStart-S(A5),a1 *>>Mike 29/1/89 
;>>mike26/6/89Amiga	move.l	a0,(a1) *>>Mike 29/1/89 
* (a0).l is ptr to list. 
	lea	SBStart-S(A5),a1 *>>Mike 29/1/89 >>Mike26/6/89Amiga
	move.l	a0,(a1) *>>Mike 29/1/89 >>Mike26/6/89Amiga
 
	lea	pntrs_tab-S(A5),a1 
	move.l	a0,a2 *>>Mike 26/6/89 
	moveq	#4,d0 
setup_ptrs1: 
	move.l	(a0)+,d2 
;;	add.l	d1,d2 
	lea 0(a2,d2.l),a3 *>>mike 26/6/89 
	move.l	a3,(a1)+ *>>Mike 26/6/89 
	move.w	(a0)+,(a1)+ 
	dbra	d0,setup_ptrs1 

 move.w #0,d0
 lea FastFindObjectTable-S(A5),a1 * start with object 0.
 move.l SBStart-S(A5),a0
 add.l #32,a0
 clr.l d1
SetUpFastFindObject:
* given d0.w as object number, return 
* a0.l as pointer to structure. >>Mike 28/5/89 (comment) 
 move.l a0,(a1)+

 move.w #16-1,d3
SUFFO1
 move.w (a0),D1
 add.l d1,a0
 dbra d3,SUFFO1

 add.w #16,d0 * next object number
 cmp.w #4000,d0
 bcs.s SetUpFastFindObject
 rts 
 
FastFindObjectTable
 ds.l 4010/16*4 
;------------------------------------- 
 
*  sets up flag etc according to which disk type is 
* being used (floppy or hard) 
 
 ifne Amiga
MCInitSpritesFile:  * used to be Boot_prg
* open sprites file (hard disk/cheaty floppy)
 rts
 endc * Amiga
;---
 ifne ST
MCInitSpritesFile:  * used to be Boot_prg
 call_bdos $19 * which drive are we running off?
 addq.l	#2,sp 
 add.w #'A',d0 * get the drive letter
 move.w d0,DriveLetter

;; open sprites file on hard disk...
; move.w #2,-(sp) * open for read+write
; pea	SpritesFilename
; call_bdos $3d * open
; addq.l	#8,sp 
; tst.l d0
; bmi SpritesOpenError
; move.l	d0,SpritesHandle-S(A5)		* save handle 

; set dta buffer address, for "SFIRST" to find
; file lengths etc.
 move.l #DTABuffer,-(sp)
 call_bdos $1a * SETDTA
 addq.l #6,sp
 move.l #0,LastSeekPos-S(A5)
 rts

SpritesOpenError
 move.w #$300,d0 * can't open sprites
 bra ErrorHandler
 endc * ST

;------------------------------------------------
 
*---------------------------------- 
* set up memory used by drawing and memory 
* management etc 
* 2(a4) - max cell no. 
* 4(a4) - no. links reqd 
* 6(a4) - no. comp cells reqd 
* 8(a4) - no. masks reqd 
 
MCSetUpVariablePtrs: 
	movem.l	a3-a6,-(sp) 
* must initialise the huffman code before we put all the memory
* into the pool.
	move.l a4,-(sp)
	move.l a6,-(sp)
	 bsr OpenDiskForTheFirstTime
	move.l (sp)+,a6
	bsr InitHuffman
	move.l (sp)+,a4
	bsr	init_memory 
	movem.l	(sp)+,a3-a6 
	clr.l d0 * return high word of d0.l clear
	rts 
*---------------------------------- 
 ifne ST
 
init_memory: 
 lea Mask_buff-S(A5),a0
 move.l a0,Mask_buffPtr-S(A5)
 lea null_mask-S(A5),a0
 move.l a0,Null_maskPtr-S(A5)
 lea ReversedCellBuffer-S(A5),a0
 move.l a0,ReversedCellBufferPtr-S(A5)

* clear memory... 
*>>Mike 20/1/89 - added to try to eliminate 
* strange crashes which happened at random when 
* using preview mode. (Appeared to happen more often if 
* machine had been used before running editor) 
	move.l	FreeWorkSpace-S(A5),a0	* free memory start 
	move.l	EndUserMemory-S(A5),d1 
ClearMem1: 
 clr.l (a0)+ 
 cmp.l d1,a0 
 bcs.s ClearMem1 

; lea ShiftedCellTablePtr,a0
; move.l FreeWorkSpace-S(A5),(a0)
;; 6(a4).w shifted cells are to be allowed
; clr.l d0
; move.w 6(a4),d0
; add.l d0,FreeWorkSpace-S(A5) * one word per pair of shifted cells
 
	move.l	FreeWorkSpace-S(A5),a0	* free memory start 
	move.l	EndUserMemory-S(A5),d0 
	move.l	d0,a1 * ptr to end of user memory 
	sub.l	a0,d0		* free memory size 
 
* Cell table area 
	move.l	a0,cell_tabPtr-S(A5)	* cell_tab start 
	move.w	2(a4),d1 
	addq.w	#1,d1		* no. cells 
	move.w	d1,NumCells-S(A5)		* 1st comp cell no. 
	move.w	d1,d2 
;	add.w	6(a4),d2		* cells + comps 
;	move.w d2,MaxShiftedCell-S(A5)
;	mulu	#6,d2 
	mulu #4,d2
	adda.l	d2,a0		* free mem now 
	sub.l	d2,d0		* free mem left 
 
* Memory map area 
* For bitwise preload table.
	move.l a0,cmem_mapPtr-S(A5) * start of memory map
	clr.l d2
	move.w	NumCells-S(A5),d2 * number of cells 
	lsr.w	#3,d2 * bitwise preload table
	addq.w	#2,d2
	and.w #$fffe,d2 * make it even, and slightly too big
	add.w #2,d2
	adda.l	d2,a0		* free mem now 
	sub.l	d2,d0		* free mem left 
	move.w d2,SizePreloadTable-S(A5)
 
* Set virtual memory pool start 
	move.l	a0,cmem_strtPtr-S(A5)	* memory  pool start 
	move.l	a0,cmem_poolPtr-S(A5) 
	move.l	a0,FreeWorkSpace-S(A5) 
 
* Links and G_map space 
* a0.l points to start of pool. Add on the free space, 
* less the size of links and g_map areas... 
 
* Allocate memory from the top down... 
 
 move.l EndUserMemory-S(A5),a1 
	move.w	4(a4),d1		* no. links reqd 
	move.w	d1,num_links-S(A5)	* save it 
	mulu	#10,d1		* space reqd 
;	addi.w	#(ConstMapWidth*ConstMapHeight*4),d1	* + g_map space 
	add.w	MapCellsTimes4-S(A5),d1
	sub.l	d1,d0		* reduce mem pool 
	sub.l	d1,a1	* End of mem pool - space for links+g_map 
	move.l	a1,g_mapPtr-S(A5)		* set up pointer 
 
* now keep a1 as pointer to top of pool, 
* d0.l as size of pool. 
 
* was v_map space... 
	move.l a1,-(sp)
	sub.l #(ConstScreenXCells*2*15*4),a1 * 4 bit-planes
	move.l a1,BufferScreen1End-S(A5)
	move.l (sp)+,a1

	move.l BSSize-S(A5),d1
	add.l #BSOneDirectionSpace*2,d1 * the number of bytes over which
	sub.l d1,d0
	sub.l d1,a1
	move.l a1,d2
	add.l #BSOneDirectionSpace,d2 * allow to scroll 64 cells left.
	move.l d2,BufferScreen1-S(A5) * same name as PC
 
* Masks area 
	move.l a1,masks_end-S(A5)
	move.w	8(a4),d1		* no. masks 
	mulu	#32,d1 
	sub.l	d1,d0		* allow for masks 
	sub.l	d1,a1	* move ptr backwards 
	move.l	a1,masks_start-S(A5)	* start of masks 
 
	move.l a1,EndFreeMemory-S(A5) * all the above was allocated 
* starting at the top of memory. This allows future 
* memory reservations to be checked. 
 move.l FreeWorkSpace-S(A5),a0 *>>Mike 16/6/89 
 cmp.l a1,a0 
 bcs.s CCOk 
; out of memory 
CCOutOfMemory
 move.l d0,-(sp) 
  move.l #$901,d0 * out of memory error 
  bsr ErrorHandler 
 move.l (sp)+,d0 
 bra MCCloseDown
 
CCOk 
* Ok, we've got d0.l bytes left for the cell pool.
* If we've got ample space,
* allocate an 8K disk buffer to speed things up.
 move.l #0,DiskCachePtr-S(A5)
 cmp.l #128000,d0
 bcs.s CCNoCache
 move.l a0,DiskCachePtr-S(A5)
 add.l #DiskCacheSize,a0
 sub.l #DiskCacheSize,d0

CCNoCache	 
* Set virtual memory pool size 
 move.l d0,d6
 move.l d6,4(a4) * return pool size in bytes
 lsr.l #7,d6 * get pool size in cells
 move.w d6,PoolSizeCells-S(A5)
 move.w d6,2(a4) * return v1 SetUpVariablePtrs

	move.l	d0,cmem_sizePtr-S(A5)	* set max size 
	move.l	d0,sz_f_cmemPtr-S(A5)	* set starting size 
	bmi	CCOutOfMemory ; no space for pool
	move.l	cmem_poolPtr-S(A5),a0 
	move.l #0,PoolFSLL-S(A5) * no cells in pool, yet.
	bsr LinkPoolList 
	rts 
 endc

;----------------

 ifne Amiga

init_memory: 
* Note: composite cells no longer allocated.
 move.l #192+128+192*2,d0 * space for mask_buff(32) and null_mask(32) and
* wideMaskPtr(64*4) and WideSpriteMaskPtr(64*4)
* and ReversedCellBuffer(128)

 move.l #MEMF_CHIP,d1
 bsr MikeAllocMem
 move.l d0,null_maskPtr-S(A5)
 beq OutOfMemory
 add.l #32,d0 * skip over null_mask.
 move.l d0,mask_buffPtr-S(A5)
 add.l #32,d0 * skip over mask_buff
 move.l d0,WideMaskPtr-S(A5)
 add.l #64*4,d0 * skip over widemask * 4 = 4 bit-planes
 move.l d0,WideSpriteMaskPtr-S(A5)
 add.l #64*4,d0 * skip over WideSpriteMaskPtr * 4=4 bit-planes
 move.l d0,ReversedCellBufferPtr-S(A5)
 move.l null_maskPtr-S(A5),a0
 move.w #(32/4)-1,d0
imL1
; set up null_mask
 move.l #-1,(a0)+
 dbra d0,imL1


 ifne AmigaCellGrouping
  move.l #SizeCellGroupTable,d0 * number of cells plottable*12
  move.l #MEMF_FAST,d1
  bsr MikeAllocMem
  move.l d0,CellGroupFreeEntry-S(A5)
  move.l d0,CellGroupTable-S(A5)
  beq OutOfMemory
 
  clr.l d0
  move.w BigSpriteAllocateSize-S(A5),d0 * size of big sprites in bytes
  move.l #MEMF_CHIP,d1
  bsr MikeAllocMem
  move.l d0,BigSpritePtr-S(A5)


* mask buffers for grouped sprites...
 move.l #BigSpriteSizeFGMaskBuffer+BigSpriteSizeBGMaskBuffer,d0
 move.l #MEMF_CHIP,d1
 bsr MikeAllocMem
 move.l d0,BigSpriteFGMaskPtr-S(A5)
 beq OutOfMemory
 add.l #BigSpriteSizeFGMaskBuffer,d0
 move.l d0,BigSpriteBGMaskPtr-S(A5)
 endc


* Cell table area 
	move.w	2(a4),d0 
	addq.w	#1,d0		* no. cells 
	move.w	d0,NumCells-S(A5)		* 1st comp cell no. 
	move.w d0,d2 * save number of cells
;	mulu	#6,d0 
	mulu #4,d0
; we need d0.l bytes
; add.l #8000,d0 ****************************
	move.l #MEMF_CLEAR,d1
 	bsr MikeAllocMem
* allocated at d0
	move.l d0,cell_tabPtr-S(A5) * start of cell table.
	beq OutOfMemory

* Memory map area 
* For bitwise preload table.
	clr.l d0
	move.w	d2,d0 * number of cells 
	lsr.w	#3,d0 * bitwise preload table
	addq.l	#2,d0
	move.w d0,SizePreloadTable-S(A5)
	move.l d0,d3 * save bytes used
* we need d0.l bytes
	move.l #MEMF_FAST,d1
 	bsr MikeAllocMem
* allocated at d0
	move.l d0,cmem_mapPtr-S(A5) * start of memory map 
* for bitwise preload table.
	beq OutOfMemory
;	move.l d0,a0
;	move.w	#-1,-2(a0,d3)	* end of cmem_map 
 
* pool was once allocated here.

* Links and G_map space 
	move.w	4(a4),d0		* no. links reqd 
	move.w	d0,num_links-S(A5)	* save it 
	mulu	#10,d0		* space reqd 
;	addi.w	#(ConstMapWidth*ConstMapHeight*4),d0 * + g_map space 
	add.w MapCellsTimes4,d0
	move.l #MEMF_FAST,d1
 	bsr MikeAllocMem
* allocated at d0
	move.l d0,g_mapPtr-S(A5) * pointer to ground map
	beq OutOfMemory
 
* was v_map space... 
;	move.l #(ConstMapWidth*ConstMapHeight*128),d0
; clr.l d0
; move.w MapCells,d0
; asl.l #7,d0 * times 128
 move.l BSSize-S(A5),d0
; add.l #8000,d0 *****
 add.l #BSOneDirectionSpace*2,d0 * the number of bytes over which
* we are allowed to scroll, *2 because left/right
	move.l #MEMF_CHIP,d1 * Blitter used for DisplayRoom
 	bsr MikeAllocMem
* allocated at d0
	add.l #BSOneDirectionSpace,d0 * allow to scroll 64 cells left.
	move.l d0,BufferScreen1-S(A5) * same name as pc!
	beq OutOfMemory
	add.l BSSize-S(A5),d0
	sub.l #(ConstScreenXCells*2*15),d0
	move.l d0,BufferScreen1End-S(A5)
 
* Masks area 
	move.w	8(a4),d0		* no. masks 
	mulu	#32,d0 
	move.l d0,-(sp) * save amount of memory to allocate
	 move.l #MEMF_CHIP,d1 * Now accessed by blitter plot
 	 bsr MikeAllocMem
	move.l (sp)+,d1 * amount of memory allocated
* allocated at d0
	move.l d0,masks_start-S(A5) * start of masks
	beq OutOfMemory
	add.l d1,d0
	move.l d0,masks_end-S(A5) * end of masks

	bsr CalcFreeMem
	move.l d0,4(a4) * return in v2,v3 
* Set virtual memory pool size 
	move.l #0,DiskCachePtr-S(A5) * no disk cache at present



	bsr AllocatePool
* d6.l is total size allocated
	move.l	d6,cmem_sizePtr-S(A5)	* set max size 
	move.l	d6,sz_f_cmemPtr-S(A5)	* set starting size 
* the above two probably not used now
* d6.l is size of pool in bytes
 lsr.l #7,d6 * get pool size in cells
 move.w d6,PoolSizeCells-S(A5)
 move.w d6,2(a4) * return v1 SetUpVariablePtrs

 ifeq ReleaseGame
 movem.l d0-d7/a0-a6,-(sp)
 move.l d6,d0
 lea PoolSizeNumber,a0
 bsr FormHexLong * poke in size of memory we asked for
 lea PoolSizeText,a0

 ifne PossessBlitter
 CALLGRAF DisownBlitter
 endc

 bsr DOSText
 ifne PossessBlitter
 CALLGRAF OwnBlitter
 endc
 movem.l (sp)+,d0-d7/a0-a6
 endc
 	rts 

PoolSizeText
	dc.b "Pool size     "
PoolSizeNumber ds.l 1
	dc.b 10,10,10,10,0,0,0
 even

OutOfMemory
 rts
;---
AllocatePool
 move.l #0,PoolFSLL * empty linked list

* allocate any workspace we haven't used for MCReserveMemory
* calls to the pool
 move.l FreeWorkSpace-S(A5),a0
 move.l EndFreeMemory-S(A5),d0
 sub.l FreeWorkSpace-S(A5),d0
 and.l #$FFFFFF80,d0 * round down to a whole number of cells
 move.l FreeWorkSpace,a0
 move.l d0,-(sp)
  bsr LinkPoolList * add in (a0.l, size d0.l)
 move.l (sp)+,d6 * total size of pool so far.

* try allocating decreasing chunks of memory.
; ifnd ChipPoolOnly
  move.l #FirstPoolChunk,d7 * start with 256K (for big machines)
 ifne UseFastMem
  move.l #MEMF_FAST!MEMF_CLEAR,d1
  bsr AllocatePoolD1 * try fast mem
 endc
; endc * CHipPoolOnly
 move.l #FirstPoolChunk,d7 * start with 256K (for big machines)
 move.l #MEMF_CHIP!MEMF_CLEAR,d1
 bsr AllocatePoolD1 * now try chip memory
 rts
;---
AllocatePoolD1
* allocate pool using all the memory we can get of type d1.l

AllocatePoolLoop
 move.l AllocMemPtr-S(A5),a0
 lea AllocMemTableEnd-16-S(A5),a1
 cmp.l a1,a0
 bcs.s APLOk
 rts *  Don't use all the allocation record entries (else
* we won't be able to free memory again)

APLOk
 movem.l d1/d6-d7,-(sp)
  move.l d7,d0 * size to allocate
  move.l AllocMemPtr-S(A5),a0
  move.l d0,(a0) * record size of memory to allocate
  CALLEXEC AllocMem * do all the allocation stuff
  tst.l d0
  beq.s AllocatePoolFail
  move.l d0,-(sp)
   bsr MikeRecordAllocation
  move.l (sp)+,a0 * start of memory allocated
 movem.l (sp)+,d1/d6-d7
 movem.l d1/d6-d7,-(sp)
  move.l a0,-(sp)
   move.l d7,d0 * size of pool allocated
   bsr LinkPoolList * add in (a0.l, size d0.l)
  move.l (sp)+,a0
* try another area of same size: d7.l
 movem.l (sp)+,d1/d6-d7
 add.l d7,d6 * total size allocated
 cmp.l #MaxPoolSize,d6
 bcs.s AllocatePoolLoop
 rts * have got enough pool already
;----
AllocatePoolFail
* halve size, and try again.
 movem.l (sp)+,d1/d6-d7
 lsr.l #1,d7
 cmp.l #SmallestPoolChunk,d7 * don't go below 4K, because system needs
* some memory for e.g. disk handlers etc.
 bcc.s AllocatePoolLoop * give up when we get to silly amounts
* total size allocated was d6.l
 rts


; code to allocate a fixed-size pool. Please Keep!
;	move.l #AmigaPoolSize,d0 * grab pool for debugging
;	move.l #MEMF_FAST,d1
; move.l d0,-(sp) * save amount allocated
; 	bsr MikeAllocMem
;* allocated at d0
;	move.l	d0,cmem_strtPtr	* memory  pool start 
;	move.l	d0,cmem_poolPtr 
;	move.l d0,SpriteDataPtr **8** Mike26/6/89Amiga
; move.l (sp)+,d1 * restore amount allocated
; 	beq OutOfMemory
;	move.l d0,a0 * parameter to LoadFile
;	move.l d1,d0 * amount of memory allocated
;	movem.l d1/a0,-(sp)
;	move.l #0,PoolFSLL * end of LL
;	bsr LinkPoolList * add in (a0.l, size d0.l)
;	movem.l (sp)+,d1/a0
; add.l d1,a0 * find d0=end of area
; move.l a0,EndSpriteDataPtr * end of table
; move.l a0,cmem_endPtr
; rts
;---
;PoolAlloc
;;  move.l #MEMF_FAST!MEMF_CLEAR,d1
;  CALLEXEC AllocMem * do all the allocation stuff
;  tst.l d0
;  bne.s PoolAllocRet
; move.l (sp)+,d0
; rts
;; move.l #MEMF_CHIP!MEMF_CLEAR,d1
;; CALLEXEC AllocMem * do all the allocation stuff
;PoolAllocRet
; rts
;-----
 endc

;----
LinkPoolList
* link in a pool starting at a0.l, of length d0.l bytes
 lea PoolFSLL-S(A5),a1
 sub.l #128,d0 * because we use bpl
LPL1
 move.l (a1),(a0) * make new cell point to the existing one.
 move.l a0,(a1) * add it in as the first cell to be used.
 add.l #128,a0
 sub.l #128,d0
 bpl.s LPL1
 rts
;---- 
;InitPoolFSLinks 
;* initialise free space linked-list 
;* in pool cells 
;* d0.l is size of pool (in bytes) 
; rts **** 
; 
; dc.w $4afa 
;	move.l cmem_strtPtr,a0 
;	move.l a0,PoolFSLL * write in free space pointer. 
;	move.l a0,a1 
;IPFL1 
;* a1.l is "next cell" pointer which moves 128 
;* bytes ahead of the "write" pointer 
;	add.l #128,a1 * cell size 
;	move.l a1,(a0) 
;	add.l #128,a0 
;	sub.l #128,d0 
;	bpl.s IPFL1 
;	rts 
;-=---- 
* ***** Check assignment of V_Map space - looks funny to me. -- Mike 22/1/89 
*>>Mike 9/2/89 - Init_Memory error-trapping added. 
*>>Mike 26/6/89 - setup????????* ***** Check assignment of V_Map space - looks funny to me. -- Mike 22/1/89 

*>>Mike 9/2/89 - Init_Memory error-trapping added. 

*>>Mike 26/6/89 - s
