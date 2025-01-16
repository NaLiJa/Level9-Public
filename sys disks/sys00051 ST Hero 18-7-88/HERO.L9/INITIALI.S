; Hero initialization code...
;
; Copyright (C) 1988 Level 9 Computing
; 
; M.J.Austin 1987/1988.

;---
LoadAndDisplayTitleScreen
 move.l FreeWorkSpace-S(a5),a0
 lea LoadTitleScreenDriverBlock-S(a5),a6
 bsr MakeA0Even
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 * start of screen just loaded
 add.l #$1c,a0
 move.l LogicalBase-S(a5),a1
 add.l #8,a1 * allow for 8 pel offset of physical screen from logical scre
 move.w #200,d0 * number of screen lines

 move.b ScreenResolution,d1
 cmp.b #2,d1
 beq.s MonoLADTS0

LADTS1
* display a single scan-line's worth ($28 bytes)
 add.l #160-$28,a1 * move along to right place for display
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+

 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 dbra d0,LADTS1
* and copy screen to the alternate page
 move.l LogicalBase-S(a5),a0
 move.l PhysicalBase-S(a5),a1
 move.w #200*160/4,d0
LADTS2
 move.l (a0)+,(a1)+
 dbra d0,LADTS2
 rts
;-----
Double4Bits macro
 roxl.w #1,d0
 roxl.l #1,d1
 asl.l #1,d1
 roxl.w #1,d0
 roxl.l #1,d1
 asl.l #1,d1
 roxl.w #1,d0
 roxl.l #1,d1
 asl.l #1,d1
 roxl.w #1,d0
 roxl.l #1,d1
 asl.l #1,d1
 endm

MonoTitleMacro macro
 move.w (a0),d0
* double all bits in d0.w to give d1.l
 Double4Bits
 Double4Bits
 Double4Bits
 Double4Bits

* now d1.l has double-spaced, single bits
 move.l d1,d0
 lsr.l #1,d0 * copy and shift
 or.l d1,d0 * give double-spaced, double bits
 swap d0
 move.w d0,(a1)+
 swap d0
 move.w d0,(a1)+
; move.w #0,(a1)+
; move.w (a0),76(a1)
; move.w (a0),78(a1)
 add.l #8,a0
 endm

MonoLADTS0
 subq.l #4,a1
 move.w d0,d2 * loop counter

MonoLADTS1
* display a single scan-line's worth ($14 bytes)
 add.l #160-20,a1 * move along to right place for display

 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro

 add.l #160-20,a1
 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro
 MonoTitleMacro

 dbra d2,MonoLADTS1
* and copy screen to the alternate page
 move.l LogicalBase-S(a5),a0
 move.l PhysicalBase-S(a5),a1
 move.w #200*160/4,d0
MonoLADTS2
 move.l (a0)+,(a1)+
 dbra d0,MonoLADTS2
 rts

;-----
LoadDataFiles
 bsr LoadAndDisplayTitleScreen * load in title screen

 lea LoadMapGraphicsDriverBlock-S(a5),a6
 move.l FreeWorkSpace-S(a5),a0 ; first free area (after gamedata etc.)
 bsr MakeA0Even
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of map graphics just loaded
 lea MapGraphicsPtr-S(a5),a1
 move.l a0,(a1) ; start of map area
 move.l $4(a6),a0 * free space for next load

 bsr MakeA0Even
 lea LoadPlaySprDriverBlock-S(a5),a6
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of sprite data just loaded
 lea SpriteDataPtr-S(a5),a1
 move.l a0,(a1) ; start of sprite data
 move.l $4(a6),a0 * free space for next load

 bsr MakeA0Even
 lea LoadMapLayoutDriverBlock-S(a5),a6
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of map graphics just loaded
 add.l #$1c,a0 ; skip over header put on sprite file by GENST
 move.l a0,a1
 move.l $4(a6),a0 * free space
 bsr MakeA0Even
 lea MapLayoutPtr-S(a5),a2
 move.l a0,(a2) ; start of copied map layout data
* copy map layout to free space + convert to word format
 move.l a0,d0
 sub.l a1,d0 * find length in d0.l
CopyMapLoop
 clr.l d1
 move.b (a1)+,d1
 bpl.s CopyMap1
* Set bit 15 to indicate cyclic - 128..255 remains range
* of cyclic sprites so bit 7 remains set
 or.w #$8000,d1
CopyMap1
 move.w d1,(a0)+
 dbra d0,CopyMapLoop
* a0.l = free space for next load
 move.l a0,DestroyedWallPtr-S(A5)
 clr.w (a0) * zero first table entry
 add.l #5000,a0


; bsr PreScrollMap
; dc.w $4afa
; move.l FreeWorkSpace-S(A5),a0 ******
; move.l HiUsedMemory-S(A5),a0 *******
 move.l a0,FreeWorkSpace-S(A5)
 rts
;---
MCPreScrollMap
 movem.l a3-a6,-(sp)
  move.l FreeWorkSpace-S(A5),a0
  bsr PreScrollMap
 movem.l (sp)+,a3-a6
 rts
;---
PreScrollMap
; The map data has just been loaded. There is free space at a0.l+(a0).l
; Pre-Scroll it at 4-pixel increments
; The Size of the map data is $8(a0).l
; The map data starts at (MapGraphicsPtr).l
; Then Map layout data is at (MapLayoutPtr)
; Find Free Space
 bsr MakeA0Even
 move.l a0,a2 * a2.l =start of free space
 lea ScrolledLayoutPtr-S(a5),a1
 move.l a0,(a1) * save start of map layoutptr

* now produce new blocks which represent each pair of two
* current blocks. e.g.
* a sequence    1 2 3 4 3 5 2 3 2 1 3 2
* might go to:   1 2 3 4 5 6 2 7 8 9 A (with a new set of graphics data)
* obviously this data will be quite a lot bigger - but we'll
* stick with 8 bit values. Clever map design should avoid
* the need to go bigger than this (plus the fact that maps tend to be
* repetitious)
 move.l MapLayoutPtr-S(a5),a0
 move.w #0,d7 * read ptr into table at a0
 move.w #0,d4 * current block number to write
* load in first byte specially
 move.w 0(a0,d7),d5
 add.w #2,d7

BuildNewTable
 move.w 0(a0,d7),d6
 bsr ProcessSingleEntry * do everything necessary
 move.w d6,d5 * copy back to form first part of new pair
 add.w #2,d7
 cmp.w #50*50*2,d7
 ble.s BuildNewTable

 bsr PreScrollAllGraphics
 rts
;--------
ProcessSingleEntry
* we have a read table at a0.l, a write table at a2.l
* and a current pair of entries d5/d6.
* go through and see if a block number has already been allocated
* to this pair - if not, allocate a new one.
* write the number to -1(a2,d7)

* compare with existing pairs by scanning from end of layout table
* to d7
 move.w #0,d0
 move.w d7,d1
 sub.w #2,d1 * current read ptr-1 to avoid matching with the
* data we're currently looking at!
 cmp.w d1,d0 * at end of table already?
 beq.s PSMNoMatch
PSMScan1
 move.w 0(a0,d0),d3
 and.w #$7fff,d3 * remove cyclic bit, if present
 cmp.w d3,d5
 bne.s PSMScan2
 add.w #2,d0
 move.w 0(a0,d0),d3
 and.w #$7fff,d3 * remove cyclic bit, if present
 cmp.w d3,d6
 beq.s PSMMatch
PSMScan2
* increment d0 ptr until we reach the current read position-1 (d1.w)
 add.w #2,d0
 cmp.w d1,d0
 bcs PSMScan1 * unsigned <

PSMNoMatch
* not found - so use current block number and increase it.

* are either of them cyclic?
 tst.w d5
 bmi.s PSMCyclic
 tst.w d6
 bmi.s PSMCyclic
* no - treat normally
 move.w d4,-2(a2,d7)
 add.w #1,d4
 rts

PSMCyclic
* will eventually store with bit 15 set, but leave alone for the present
* it will be set when the corresponding graphics are pre-scrolled
 move.w d4,-2(a2,d7) * current cyclic block number
 add.w #8,d4 * 8 sprites per cyclic entry
 rts
;----
PSMMatch
* block number to use is -2(a2,d0)
 move.w -2(a2,d0),d1
 move.w d1,-2(a2,d7)
 rts
;---
PreScrollAllGraphics
* prescroll D4 new sprites.
* Scan through the table (a2,0..d7) and compare with
* the original data 0(a0,d7) and 1(a0,d7) to find what
* each new block is a combination of.

* First calculate the start address of the scrolled graphics blocks
* that we are going to generate
* free space is at (a2,d7)
 move.l a2,a3
 lea 0(a2,d7),a3

 move.l a0,-(sp)
 move.l a3,a0
 bsr MakeA0Even
 move.l a0,a3
 move.l (sp)+,a0

 lea MapGraphicsPtrs-S(a5),a4
 move.l a3,$4(a4) * first block ptr

* how big is each set of data?
 move.w #16*16/2,d0 * 16x16 in 4 bit planes
 clr.l d1
 move.w d4,d1 * d4.w different new sprites were found
 mulu d1,d0
 add.l d0,a3
 move.l a3,$8(a4) * second block ptr
 add.l d0,a3
 move.l a3,$c(a4) * second block ptr

* now (a4,0..4..8..C) contain the addresses
* of the old and new sets of data respectively
* Now go through and work out which combinations to scroll - and do it!

* Scan through the table (a2,0..d7) and compare with
* the original data 0(a0,d7) and 1(a0,d7) to find what
* each new block is to be a combination of.

PSAG1
* search for combination d4.w in (a2,...)
 move.w #0,d0
 move.w #50*50,d1 * limit scan to a sensible distance
PSAG2
 cmp.w $0(a2,d0),d4
 beq.s PSAGFound
 addq.w #2,d0
 dbra d1,PSAG2 * scan through until end of table
* not found - try another (error recovery???)
 bra.s PSAGNext

PSAGFound
* the combination is 0(a0,d0) and 2(a0,d0)
 move.w 0(a0,d0),d5
 move.w 2(a0,d0),d6
 movem.l d0-d7/a0-a6,-(sp)
 bsr PreScrollSpriteD4
 movem.l (sp)+,d0-d7/a0-a6

PSAGNext
* now generate the next combination
 dbra d4,PSAG1

PSAGRet
 RTS
;---
PreScrollSpriteD4
; Generate new sets of sprite data for sprite d4 - which
; is a combination of the adjacent sprites d5.w/d6.w

* is d5 or d6 a cyclic sprite? If so, do 8 times for different stages
* of the animation
 tst.w d5
 bmi.s PreScrollLeftCyclic
 tst.w d6
 bmi.s PreScrollRightCyclic
 bra.s PreScrollNotCyclic

PreScrollLeftCyclic
 or.w #$8000,0(a2,d0) * set top bit in layout table to indicate cyclic
 tst.w d6
 bmi.s PreScrollBothCyclic
* left only cyclic
 move.w #7,d0 * stages to do
PSL1
 movem.l d0-d7/a0-a6,-(sp)
 bsr PreScrollD4
 movem.l (sp)+,d0-d7/a0-a6
 addq.w #1,d4 * next sprite
 addq.w #1,d5 * step left sprite to next stage
 dbra d0,PSL1
 RTS

PreScrolLRightCyclic
 or.w #$8000,0(a2,d0) * set top bit in layout table to indicate cyclic
 tst.w d5
 bmi.s PreScrollBothCyclic
* right only is cyclic
 move.w #7,d0 * stages to do
PSR1
 movem.l d0-d7/a0-a6,-(sp)
 bsr PreScrollD4
 movem.l (sp)+,d0-d7/a0-a6
 addq.w #1,d4 * next sprite
 addq.w #1,d6 * step right sprite to next stage
 dbra d0,PSR1
 RTS

;
;
PreScrollbothCyclic
 move.w #7,d0 * stages to do
PSB1
 movem.l d0-d7/a0-a6,-(sp)
 bsr PreScrollD4
 movem.l (sp)+,d0-d7/a0-a6
 addq.w #1,d4 * next sprite
 addq.w #1,d5 * step left sprite to next stage
 addq.w #1,d6 * step right sprite on
 dbra d0,PSB1
 RTS
;
;
;------
PreScrollnotCyclic
PreScrollD4
; move.b ScreenResolution,d2
; cmp.b #2,d2
; beq MonoPrescrollD4
 move.l CyclicOffset-S(a5),d2
 
 and.l #$7fff,d5 * clear top word & cyclic flag
 asl.w #7,d5 * multiply by 128 to get index
 move.l MapGraphicsPtr-S(a5),a0
 add.l d5,a0
* now a0.l is start of original sprite data for sprite d5

 and.l #$7fff,d6 * clear top word & cyclic flag
 asl.w #7,d6 * multiply by 128 to get index
 move.l MapGraphicsPtr-S(a5),a1
 add.l d6,a1
* and a1.l is start of original sprite data for sprite d6

* where is it to go?
 and.l #$ffff,d4
 asl.w #7,d4 * multiply by 128 to get index
 move.l MapGraphicsPtr2-S(a5),a2
 add.l d4,a2
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr3-S(a5),a3
 add.l d4,a3
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr4-S(a5),a4
 add.l d4,a4
 add.l d2,a2 * add on offset for cyclic sprites

* now combine sprites from (a0) and (a1) to
* give scrolled versions (a2),(a3),(a4)
 move.w #63,d0 * 16 lines of 4 bit planes

PSSprite1
 move.w (a0)+,d1
 swap d1 * put lhs in top word
 move.w (a1)+,d1
* now d1.l is complete 32 pel wide combined sprite - scroll it!

 asl.l #4,d1 * scroll it left 4 pels
 swap d1
 move.w d1,(a2)+
 swap d1

 asl.l #4,d1
 swap d1
 move.w d1,(a3)+
 swap d1

 asl.l #4,d1
 swap d1
 move.w d1,(a4)+
 swap d1

 dbra d0,PsSprite1
 lea HiUsedMemory-S(a5),a0
 move.l a4,(a0)
 rts
;---


MonoPrescrollD4
* can corrupt all registers at present
 move.l CyclicOffset-S(a5),d2
 
 and.l #$7fff,d5 * clear top word & cyclic flag
 asl.w #7,d5 * multiply by 128 to get index
 move.l MapGraphicsPtr-S(a5),a0
 add.l d5,a0
* now a0.l is start of original sprite data for sprite d5

 and.l #$7fff,d6 * clear top word & cyclic flag
 asl.w #7,d6 * multiply by 128 to get index
 move.l MapGraphicsPtr-S(a5),a1
 add.l d6,a1
* and a1.l is start of original sprite data for sprite d6

* where is it to go?
 and.l #$ffff,d4
 asl.w #7,d4 * multiply by 128 to get index
 move.l MapGraphicsPtr2-S(a5),a2
 add.l d4,a2
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr3-S(a5),a3
 add.l d4,a3
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr4-S(a5),a4
 add.l d4,a4
 add.l d2,a2 * add on offset for cyclic sprites

* now combine sprites from (a0) and (a1) to
* give scrolled versions (a2),(a3),(a4)
 move.w #15,d0 * 16 lines

MonoPSSprite1
* unlike colour version, this routine combines all bit-planes
* at once to give the nearest-possible monochrome equivalent
* a 16x16 sprite on the colour display becomes 32x32 in mono
* because of the higher pixel resolution available.
 move.w (a0)+,d1
 swap d1 * put lhs in top word
 move.w (a1)+,d1
* now d1.l is first bitplane of 32 pel wide combined sprite

 move.w (a0)+,d2
 swap d2 * put lhs in top word
 move.w (a1)+,d2
* now d2.l is second bitplane of 32 pel wide combined sprite

 move.w (a0)+,d3
 swap d3 * put lhs in top word
 move.w (a1)+,d3
* now d3.l is third bitplane of 32 pel wide combined sprite

 move.w (a0)+,d4
 swap d4 * put lhs in top word
 move.w (a1)+,d4
* now d4.l is fourth bitplane of 32 pel wide combined sprite

* now merge these four bitplanes together to give two 32 pixel
* lines.


 asl.l #4,d1 * scroll it left 4 pels
 swap d1
 move.w d1,(a2)+
 swap d1

 asl.l #4,d1
 swap d1
 move.w d1,(a3)+
 swap d1

 asl.l #4,d1
 swap d1
 move.w d1,(a4)+
 swap d1

 dbra d0,MonoPsSprite1
 lea HiUsedMemory-S(a5),a0
 move.l a4,(a0)
 rts
;---



; move.w $8(a0),d6
;
; move.w #2,d7 * size of right shift
; lea MapGraphicsPtr,a4 ; keep a4.l as the position in the ptr table for each
;; set of scrolled data
; move.l (a4)+,a1 ; load starting position of original data
;
;
;PreScroll1
; move.l a2,(a4)+ ; store next entry in ptr table
; move.l a1,-(sp) ; and save start of original ptr
; move.w d6,-(sp)
; bsr PreScrollOnce ; from a1 to a2 length d6.w by amount d7.w
; move.w (sp)+,d6
; move.l (sp)+,a1
; add.w #2,d7 ; shift by some more
; cmp.w #16,d7
; blt.s PreScroll1
; rts
;-----
InitLRTable
; table giving left-right bit reversal of all byte-sized bit
; patterns. Note that each entry is a word, the low-order
; being null. This avoids the need for shifting when the destination
; is the high-order byte of a word
 lea LRTable,a0
 move.b #0,d0 * byte pattern we're reversing
 move.w #0,d4 * index into table (double the above)
InitLRTableLoop
 bsr ReverseD0
 move.b d1,0(a0,d4)
 move.b #0,1(a0,d4)
 addq.w #2,d4
 addq.b #1,d0
 bne.s InitLRTableLoop * continue until wrap round to zero again
 rts

ReverseD0
; reverse the bits in d0.b,giving d1.b
; d2.b used as workspace
; must preserve d0.b
 clr.l d1 * may as well, though shouldn't be necessary
 move.b d0,d2 * make a copy to work on
 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1


 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1

 roxr.b #1,d2
 roxl.b #1,d1

 rts
