* BUILD.S
*
* Hero Screen-Builder and control logic etc.
*
* Assemble this file!
*
* Copyright(C) 1987/1988 M.J.Austin Started 26/11/87
*
*
* Position at 11/6/88: After a long break, doing Lancelot, T+M,
* exams etc., I've come back to Hero. The 68000 MC Acode compiler
* is now done, and the system will be controlled from the MC section
* of Acode -- Mike.

* Position at 16/6/88: Intermittent work interspersed with gliding.
* Acode/MC is now pretty well integrated, with the main control
* loop handled in Acode. I've done enough work to make
* the game useable in Mono, though it is not yet pretty
* enough to be demonstrated (need stippling etc.). Now need
* to transfer the monster intelligence to ACode, write the follow
* code, and write the menu section.
* (Also looked at memory useage. To my surprise, the cyclic stuff
* uses only around 30K for the standard screen. There would appear
* to be about 540K free with my standard winchester boot, without
* cyclic stuff.
* Process.tos (21K big) reports 764K for the same configuration. Thus
* Hero is using about 245K, including 32K for an extra screen.
* Thus About 25K of PlaySpr, 21K of Mapgr and 2.5K of Map data
* (total 49K) is expanded to around 210K of workspace.
* (N.B. In fact, the second screen took 64K when these figures
*  were worked out. Thus the true useage is about 178K, not 210)

**** Look at why VBLHandler needs a delay to kill
* the flicker - use a video/STFM to investigate.

 opt d+
* ,P+


S * all workspace references are relative to this (a5)

 lea S(PC),a5
 bra Start
 include 'font.s'
 include 'defns.s'
 include 'stsprite.s'
 include 'joystick.s'
 include 'stcoll.s'
 include 'int.s'
 include 'initiali.s'
 include 'si.s'
 include 'data.s'

*		Signed	Unsigned
* >=		BGE	BCC
* >		BGT	BHI
* =		BEQ	BEQ
* <>		BNE	BNE
* <=		BLS	BLS
* <		BLT	BCS


Start
; set supervisor mode
 clr.l -(sp)
 call_bdos _super
 add.l #6,sp
 lea SupervisorStack-S(a5),a0
 move.l d0,(a0)

 lea WorkSpaceStart-S(A5),a0 * must = startFile
 add.l #IntWorkSpaceSize,a0
 move.l a0,FreeWorkSpace-S(a5)

 bsr LoadAndInitGamedata * must be first file loaded

 lea HeroStack-S(a5),sp

 move.l AcodeFns,a0
 pea InstructionLoop
; pea ToMCEnd * push on return address: simulates JSR (A5)
CallAcode
 lea VarTable,a4 * set up var table block
 lea ListTbl,a3 * ptrs to lists
 moveq.w #0,d7 * kept zero for use in 0(a3,d7) accesses
 jmp (a0)

; bsr HeroOnceOnlyInit
;
;ResetMonsters
;; bsr InitSpriteTable
; bsr HeroInit
;
;MainLoop
; lea HeroStack-S(a5),sp
; bsr AllHero
; bra MainLoop
;---
;MCFrameReady
;; called from acode
; movem.l a3-a5,-(sp)
;  lea S(PC),a5
;  move.b #1,FrameReady-S(A5)
; movem.l (sp)+,a3-a5
; rts
;-----
;AllHero
; bsr MoveScreen
; bsr Specials
;
; bsr BuildBackGround
;;
; Now overlay other stuff on top of the background
; bsr DisplayDestroyedWalls
; move.l Player1SpriteBlock-S(a5),a6 *****
; bsr DisplayAllSprites
; bsr TrimEdges
; bsr DisplayTextLine
; bsr DisplayUpperTextLine
; bsr DoAllTimers
; bsr DisplayMemoryFree
; bsr DisplayHitPoints
; bsr DisplayFreeSprites
; bsr DisplayFrameTime
;
;; bsr HandlePlayerInput
;
; rts
;-------
HeroOnceOnlyInit
 bsr InitHeroVariables

 bsr SetScreenResolution

 bsr LoadDataFiles * includes title page, graphics data etc.

 bsr SetUpPalette

 bsr InitJoystick

 bsr SetUpVbl

 bsr InitLRTable
 rts
;-------
SetUpVBl
* now set up the interrupt vector
* it doesn't matter if interrupts occur during the
* following bit of code ....
* now set up MY VBL interrupt handler routine
 tst.l osvblhandler
 bne.s vblalreadysetup
 move.l $70,OSVblHandler-S(A5)

 lea irqvblhandler,a0
 move.l a0,$70			; ... and enable my routine
vblalreadysetup
 rts
;----
CloseDownVBL
 move.l OSVblHandler-S(A5),d0
 move.l d0,$70
 rts
;-----
IRQVblHandler
* Cant use A5.L relative here, remember...
 move.l d0,-(sp)
 move.b FrameReady(PC),d0
 beq.s IRQVblHandlerEnd
IV1
 movem.l a0/a5,-(sp)
  lea S(PC),a5
  bsr ActuallySwapScreen
  clr.b FrameReady-S(A5)
 movem.l (sp)+,a0/a5

IRQVblHandlerEnd
 move.l (sp)+,d0
* finished - do any suitable OS stuff
 move.l osvblhandler,-(sp)
 rts
;----
ActuallySwapScreen
; and set up to write to alternate screen...
 move.l a2,-(sp)
  move.l LogicalBase-S(a5),a2
  move.l PhysicalBase-S(a5),LogicalBase-S(A5)
  move.l a2,PhysicalBase-S(a5)
 move.l (sp)+,a2

 move.l PhysicalBase-S(A5),d0
 add.l #8,d0
* Logical base is 8 less than the value used by the display hardware
* to allow the 16 pel margin at the LHS of the logical screen to be
* displayed at the RHS of the physical screen
 asr.l #8,d0
 lea $ffff8203,a0
 move.b d0,(a0) ; $80 for $f8000
 asr.l #8,d0
 lea $ffff8201,a0
 move.b d0,(a0) ; $0f for $f8000

; move.b #1,PageSwapped-S(A5) ************
 rts

;-------
HeroInit
;; bsr InitSpriteTable
 Lea DoYRangeKill-S(a5),a0
 clr.b (a0)

 lea SpriteTable-S(a5),a0
 lea SpriteTPtr-S(a5),a1
 move.l a0,(a1)

 lea TextBuffer,a0
 move.l a0,List24Ptr-S(A5)
 move.l MapLayoutPtr-S(A5),a0
 move.l a0,List27Ptr-S(A5)
 lea SpriteTable-S(A5),a0
 move.l a0,List28Ptr-S(A5)
 lea LongWorkspace-S(A5),a0
 move.l a0,List29Ptr-S(A5)
 lea WordWorkspace-S(A5),a0
 move.l a0,List30Ptr-S(A5)
 lea ByteWorkspace-S(A5),a0
 move.l a0,List31Ptr-S(A5)

 rts
;-------
InitHeroVariables
 lea RandomSeed-S(a5),a0
 move.l #$c468d134,(a0)

 lea ScrollStep-S(a5),a0
 move.b #4,(a0)

 lea YFineScroll-S(a5),a0
 move.l #0,(a0)
 lea DoingPseudoFlip-S(a5),a0
 clr.b (a0)
 lea ScreenXPos-S(a5),a0
 move.w #0,(a0)
 lea ScreenYPos-S(a5),a0
 move.w #32,(a0)

 lea BreakPointArmed-S(a5),a0
 clr.b (a0)
 lea NumDestroyedWalls-S(a5),a0
 clr.w (a0)
 lea TimeToNextShot-S(a5),a0
 clr.b (a0)

 lea ScreenXMax-S(a5),a0
 move.w #544,(a0) ; (ScreenXBlocks-16)*16
 lea PlayerXMax-S(a5),a0
 move.w #784,(a0) * 800,(a0) ; (ScreenXBlocks-1)*16
 lea ScreenXBlocks-S(a5),a0 ; number of blocks e.g. 0..ScreenXBlocks-1
 move.w #50,(a0)
 lea ScreenYBlocks-S(A5),a0
 move.w #50,(a0)

 lea ScreenYMax-S(a5),a0
 move.w #612,(a0) * (screenYBlocks-11.75)*16
 lea PlayerYMax-S(a5),a0
 move.w #784,(a0) * (ScreenYBlocks-1)*16

 lea CurrentWeapon-S(a5),a0
 clr.b (a0)

 rts
;---
DoAllTimers
* do all special case timers
 lea TimeToNextShot-S(a5),a0
 tst.b (a0)
 beq.s DATRet
 subq.b #1,(a0)
DATRet
 rts
;-------
;MCClearScreenArea
;; called from Acode
;; clear rectangle between x0,y0 and x1,y1. Uses self-modifying code
; to setup the linear code to clear each line.
; movem.l a3-a5,-(sp)
;  bsr ClearScreenArea
; movem.l (sp)+,a3-a5
; rts
;
;ClearScreenArea
;
;---------
Clear16 Macro
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 endm

MCClearScreen
; clear the entire logical screen
 movem.l a3-a5,-(sp) * save acode pointer registers
 move.l LogicalBase(PC),a0 * A5.L not set up, so can't use relative addressing
 move.w #200*160/64,d1 * length to clear. About 500 iterations
 moveq.l #0,d0 * for use by clear16 macro
ClsLoop
 Clear16 * clear 16 bytes
 Clear16
 Clear16
 Clear16
 dbra d1,ClsLoop
 movem.l (sp)+,a3-a5
 rts
;-------
BuildBackGround
 move.l LogicalBase-S(a5),a0 * screen address (!)

 move.w ScreenYPos-S(a5),d0
 and.w #$0f,d0 * separate out fine scroll position
 move.w #160,d1
 mulu d1,d0 * calculate offset for fine scroll
 sub.l d0,a0

; lea TempStarPhase-S(a5),a3
; move.b StarPhase-S(a5),(a3) * copy across so it can be reset below
;* when it is not needed - i.e. when ScrolledLayoutPtr is in use!

* decide which layout ptr to use (depending on state of smooth scroll)
 lea MapLayoutPtr-S(a5),a2
 move.w ScreenXPos-S(a5),d0
 and.w #$0f,d0
 beq.s UseLayoutPtrA2
 lea ScrolledLayoutPtr-S(a5),a2

UseLayoutPtrA2
 move.l (a2),a2 ; a2 is now ptr to map layout

* and decide which map graphics ptr to use
* (depending on state of smooth scroll)
 lea MapGraphicsPtrs-S(a5),a3
 clr.l d0
 move.w ScreenXPos-S(a5),d0
 and.w #$0f,d0 * assumes scroll jump is multiple of 4 pels!
 add.l d0,a3 * calculate which ptr to use
 move.l (a3),a3 * get start address of graphics
 lea CurrentMapGraphicsPtr-S(a5),a1
 move.l a3,(a1)

 move.w ScreenXPos-S(a5),d0
 lsr.w #3,d0 * convert from pixel count to block count /(320/16)=/16
* but *2 because map is made up of words
 and.w #$fffe,d0 * strip off bit 0
 add.w d0,a2
 move.w ScreenYPos-S(a5),d0
 lsr.w #3,d0 * convert to number of blocks
* but *2 because map is made up of words
 and.w #$fffe,d0 * strip off bit 0
 move.w ScreenXBlocks-S(a5),d1
 mulu d1,d0 * convert to offset in map table
 add.l d0,a2

 move.b ScreenResolution,d3
 cmp.b #2,d3
 beq MonoBuildIt

BuildIt
* loop through plotting each 16x16 block in turn
* do a complete screen of lines (200/16=12.5)
 move.w #12,d3 ; including 1 only partly seen at the top

BlockRowLoop
* do a complete line of blocks (320/16=20)
 move.l a2,-(sp)
 move.l a0,-(sp)
 move.w #15,d2 * 19

BlockLineLoop
 clr.l d0
 move.w (a2)+,d0 * which block is next?
 bpl.s BlockLineNotSpecial
* a special - so add on phase
 and.w #$7fff,d0 * remove cyclic flag
 clr.l d1
 move.b TempStarPhase-S(a5),d1
 add.w d1,d0

BlockLineNotSpecial
* each block is 16x16 in 16 colours - i.e. 16x16/2=128 bytes
 asl.w #7,d0 * multiply by 128 to get index
 move.l CurrentMapGraphicsPtr-S(a5),a1
 add.l d0,a1

 move.l a0,a3 * -(sp) * save initial screen address
* copy 16 lines...
; move.w #15,d1
;
;PixelLineLoop
* now copy 4 bit planes...
; line 0
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 1
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 2
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 3
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 4
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 5
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 6
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 7
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 8
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 9
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 10
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 11
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 12
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 13
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 14
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

; line 15
 move.l (a1)+,(a0)+ * copy to screen bp1
 move.l (a1)+,(a0)+ * copy to screen bp2
 add.l #152,a0 * 160-8

 move.l a3,a0 * (sp)+,a0
 add.l #8,a0 * next block on line

 dbra d2,BlockLineLoop
* skip to screen start of next block row - 16 screen lines on
 move.l (sp)+,a0
 add.l #2560,a0
* skip to next row of blocks in map area
 move.l (sp)+,a2
 add.w ScreenXBlocks-S(a5),a2
 add.w ScreenXBlocks-S(a5),a2 * because map is word-based

; movem.l d0-d1/a0,-(sp)
;  move.b StillNeedToSwapScreen-S(a5),d0
;  beq.s NoFlip
;  move.l LogicalBase-S(a5),d0
;  add.l #130*200,d0
;  lsr.w #8,d0
;  move.b $ff8207,d1
;  cmp.b d0,d1
;  blt.s NoFlip
;  bsr SetWriteAlternate * make it display the correct buffer
;  bsr ActuallySwapScreen
;NoFlip
; movem.l (sp)+,d0-d1/a0
 dbra d3,BlockRowLoop
 rts
;-------
;MapFirstBit macro
; btst #15,d0
; beq.s \@
; bset #3,d4
;
;\@
; endm
;;---
;MapSecondBit macro
; btst #11,d0
; beq.s \@
; bset #2,d4
;
;\@
; endm
;;---
;MapThirdBit macro
; btst #7,d0
; beq.s \@
; bset #1,d4
;
;\@
; endm
;;---
;MapFourthBit macro
; btst #3,d0
; beq.s \@
; bset #0,d4
;\@
; endm
;---
MapDo4Pel macro
* do 4 pels
; MapFirstBit
; MapSecondBit
; MapThirdBit
; MapFourthBit
; asl.w #4,d4
 roxl.w #1,d0
 roxl.w #1,d4
 rol.w #3,d0

 roxl.w #1,d0
 roxl.w #1,d4
 rol.w #3,d0

 roxl.w #1,d0
 roxl.w #1,d4
 rol.w #3,d0

 roxl.w #1,d0
 roxl.w #1,d4
; rol.w #3,d0 (not needed, because d0 now discarded)
 endm

;---

MapDoBP
* do a single bit-plane of the reduced-size display
 clr.w d4 * build the reduced-size image in here

 move.w (a1)+,d0 ; first block of group
 MapDo4Pel ; convert to first four pixels
 move.w (a3)+,d0 ; second block of group
 MapDo4Pel ; convert to first four pixels
 move.w (a4)+,d0 ; third block of group
 MapDo4Pel ; convert to first four pixels
 move.w (a6)+,d0 ; last block of group
 MapDo4Pel ; convert to first four pixels

 move.w d4,(a0)+
 rts
;---
MapPLL macro
 move.l a0,-(sp)
  bsr MapDoBP
  bsr MapDoBP
  bsr MapDoBP
  bsr MapDoBP
 move.l (sp)+,a0
 add.l #160,a0 * next line of screen
* and skip over 3 stored lines of block
 add.l #24,a1
 add.l #24,a3
 add.l #24,a4
 add.l #24,a6
 endm
;-----------------------
MCMapBuildBackGround
 move.l LogicalBase-S(A5),a0
 add.l #8,a0 * allow for left margin overlap
; move.w ScreenYPos-S(a5),d0
; and.w #$0f,d0 * separate out fine scroll position
; move.w #160,d1
; mulu d1,d0 * calculate offset for fine scroll
; sub.l d0,a0

* decide which layout ptr to use (depending on state of smooth scroll)
 lea MapLayoutPtr-S(a5),a2
; move.w ScreenXPos-S(a5),d0
; and.w #$0f,d0
; beq.s UseLayoutPtrA2
; lea ScrolledLayoutPtr-S(a5),a2
;
;UseLayoutPtrA2
 move.l (a2),a2 ; a2 is now ptr to map layout

* and decide which map graphics ptr to use
* (depending on state of smooth scroll)
 lea MapGraphicsPtrs-S(a5),a3
; clr.l d0
; move.w ScreenXPos-S(a5),d0
; and.w #$0f,d0 * assumes scroll jump is multiple of 4 pels!
; add.l d0,a3 * calculate which ptr to use
 move.l (a3),a3 * get start address of graphics
 lea CurrentMapGraphicsPtr-S(a5),a1
 move.l a3,(a1)

; move.w ScreenXPos-S(a5),d0
; lsr.w #3,d0 * convert from pixel count to block count /(320/16)=/16
;* but *2 because map is made up of words
; and.w #$fffe,d0 * strip off bit 0
; add.w d0,a2
; move.w ScreenYPos-S(a5),d0
; lsr.w #3,d0 * convert to number of blocks
;* but *2 because map is made up of words
; and.w #$fffe,d0 * strip off bit 0
; move.w ScreenXBlocks-S(a5),d1
; mulu d1,d0 * convert to offset in map table
; add.l d0,a2

; move.b ScreenResolution,d3
; cmp.b #2,d3
; beq MonoBuildIt

MapBuildIt
* loop through plotting each 16x16 block in turn
* do a complete screen of lines (200/16=12.5)
 movem.l a4-a6,-(sp)
; move.w #12,d3 ; including 1 only partly seen at the top
 move.w ScreenYBlocks-S(A5),d3 * see comment below
; don't divide this one by 4 because each area plotted
; by the central loop is 4 pels high, by 64 wide (16 pel on screen)
; instead of the normal 16x16.

MapBlockRowLoop
* do a complete line of blocks (320/16=20)
 move.l a2,-(sp)
 move.l a0,-(sp)
; move.w #10,d2 * 19
 move.w ScreenXBlocks-S(A5),d2
 lsr.w #2,d2 * divide by 4, because we display four normal
; blocks to a single 16x16 in map mode.

MapBlockLineLoop
 bsr MapGetNextBlock
 move.l a1,-(sp)
; and get 3 next blocks to merge....
  bsr MapGetNextBlock
  move.l a1,a3
  bsr MapGetNextBlock
  move.l a1,a4
  bsr MapGetNextBlock
  move.l a1,a6
 move.l (sp)+,a1

* now copy 4 bit planes...

 move.l a0,-(sp)
  MapPll ; line 0
  MapPll ; line 1
  MapPll ; line 2
  MapPll ; line 3
 move.l (sp)+,a0
 add.l #8,a0 * next block on line in screen memory

 dbra d2,MapBlockLineLoop
* skip to screen start of next block row - 16 screen lines on
 move.l (sp)+,a0
 add.l #640,a0 * 2560,a0
* skip to next row of blocks in map area
 move.l (sp)+,a2
 add.w ScreenXBlocks-S(a5),a2
 add.w ScreenXBlocks-S(a5),a2 * because map is word-based

 dbra d3,MapBlockRowLoop
 movem.l (sp)+,a4-a6
 rts

;----
MapGetNextBlock
 clr.l d0
 move.w (a2)+,d0 * which block is next?
 bpl.s MapBlockLineNotSpecial
* a special - so add on phase
 and.w #$7fff,d0 * remove cyclic flag
 clr.l d1
 move.b TempStarPhase-S(a5),d1
 add.w d1,d0

MapBlockLineNotSpecial
* each block is 16x16 in 16 colours - i.e. 16x16/2=128 bytes
 asl.w #7,d0 * multiply by 128 to get index
 move.l CurrentMapGraphicsPtr-S(a5),a1
 add.l d0,a1
 rts




;---------------------
MCClearSection
* clear a rectangle of screen starting at
* (CursorXPos,CursorYPos) top left
* of size (v1=0..319,v2=0..199) pixels
 bsr CalcCurrentCharAddress
* a0.l = address of top left of screen

 move.b ScreenResolution,d0
 bne.s HClearSection
* colour version
 move.w 4(a4),d1 * y size
CClearLine0
 move.l a0,-(sp)
 move.w 2(a4),d0 * x size
 lsr.w #3,d0 * convert to number of bytes
CClearLine1
 clr.b (a0)
 clr.b 2(a0)
 clr.b 4(a0)
 clr.b 6(a0)
 subq.w #1,d0
 bmi.s CClearLine2 * end of line
 clr.b 1(a0)
 clr.b 3(a0)
 clr.b 5(a0)
 clr.b 7(a0)
 subq.w #1,d0
 bmi.s CClearLine2 * end of line
 addq.l #8,a0
 bra.s CClearLine1

CClearLine2
* skip to next line of block
 move.l (sp)+,a0
 add.l #160,a0 * next line of pels
 subq.l #1,d1
 bpl.s CClearLine0
 rts
;---
HClearSection
 rts
;-------
TrimEdges
* blat out the edges of the screen - to make
* the sprite display etc. at the sides easier

* copy in the border area from the alternate (currently displayed)
* area to preserve the border information
 move.b ScreenResolution,d0
 bne.s TERet

 move.l LogicalBase-S(a5),a0
 move.l PhysicalBase-S(a5),a1
 move.w #200,d0
TE1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 add.l #124,a0
 add.l #124,a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 add.l #28,a0
 add.l #28,a1
 dbra d0,TE1
TERet
 rts

;------

MonoBuildIt
* loop through plotting each 16x16 block in turn
* do a complete screen of lines (200/16=12.5)
 move.w #12,d3 ; including 1 only partly seen at the top

MonoBlockRowLoop
* do a complete line of blocks (320/16=20)
 move.l a2,-(sp)
 move.l a0,-(sp)
 move.w #15,d2 * 19

MonoBlockLineLoop
 clr.l d0
 move.w (a2)+,d0 * which block is next?
 bpl.s MonoBlockLineNotSpecial
* a special - so add on phase
 and.w #$7fff,d0 * remove cyclic flag
 clr.l d1
 move.b TempStarPhase-S(a5),d1
 add.w d1,d0

MonoBlockLineNotSpecial
* each block is 16x16 in 16 colours - i.e. 16x16/2=128 bytes
 asl.w #7,d0 * multiply by 128 to get index
 move.l CurrentMapGraphicsPtr-S(a5),a1
 add.l d0,a1

 move.l a0,a3 * -(sp) * save initial screen address
* copy 16 lines...
; move.w #15,d1
;
;PixelLineLoop
**************************
* Optimizations:
*   1) use registers for additions within this?
*   2) remove unnecessary auto-increments
**************************

MonoBuildMacro macro
; move.l (a1)+,(a0)+ * copy to screen bp1
; move.l (a1)+,76(a0) * copy to screen bp2
; add.l #156,a0 * 160-4

; move.w (a1)+,(a0)+
; move.w (a1)+,78(a0)
; add.l #4,a1 * skip unused bit-planes of data table
; add.l #158,a0 * 160-2

; rough approximation to final code, but mono display is doubled-up
 move.w (a1)+,(a0)+
 move.w (a1)+,(a0)
 move.w (a1)+,78(a0)
 move.w (a1)+,80(a0)
; add.l #6,a1
 add.l #158,a0
 endm

 MonoBuildMacro ;0
 MonoBuildMacro ;1
 MonoBuildMacro ;2
 MonoBuildMacro ;3
 MonoBuildMacro ;4
 MonoBuildMacro ;5
 MonoBuildMacro ;6
 MonoBuildMacro ;7
 MonoBuildMacro ;8
 MonoBuildMacro ;9
 MonoBuildMacro ;10
 MonoBuildMacro ;11
 MonoBuildMacro ;12
 MonoBuildMacro ;13
 MonoBuildMacro ;14
 MonoBuildMacro ;15

 move.l a3,a0 * (sp)+,a0
 add.l #4,a0 * next block on line

 dbra d2,MonoBlockLineLoop
* skip to screen start of next block row - 16 screen lines on
 move.l (sp)+,a0
 add.l #80*16*2,a0
* skip to next row of blocks in map area
 move.l (sp)+,a2
 add.w ScreenXBlocks-S(a5),a2
 add.w ScreenXBlocks-S(a5),a2 * because map is word-based

; movem.l d0-d1/a0,-(sp)
;  move.b StillNeedToSwapScreen-S(a5),d0
;  beq.s MonoNoFlip
;  move.l LogicalBase-S(a5),d0
;  add.l #130*200,d0
;  lsr.w #8,d0
;  move.b $ff8207,d1
;  cmp.b d0,d1
;  blt.s MonoNoFlip
;  bsr SetWriteAlternate * make it display the correct buffer
;  bsr ActuallySwapScreen
;MonoNoFlip
; movem.l (sp)+,d0-d1/a0
 dbra d3,MonoBlockRowLoop
 rts * bra TrimEdges

;-------
HeroInput
; called from acode - return joystickStatus, LastKeyPressed
; in List31
 movem.l a3-a5,-(sp)
;  bsr HandlePlayerInput
  bsr AbsGetCharFromBdos
  move.b d0,LastKeyPressed-S(A5)
 movem.l (sp)+,a3-a5
 rts
;----
;---
MCHandlePlayerInput
 movem.l a3-a6,-(sp)
  bsr HandlePlayerInput
 movem.l (sp)+,a3-a6
 rts
;---
HandlePlayerInput

;GetPlayerInput
;AbsGetPlayerInput
;; Get input from user

 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a6
 add.l d0,a6

;; move.l Player1SpriteBlock-S(a5),a6
 clr.w d6
 clr.w d7
 move.b PlayerSDS+SpeedOffset-S(a5),d6
 move.b JoystickStatus-S(a5),d7

 clr.w d4 * x offset requested by player
 clr.w d5 * y offset requested by player
 
 btst #LeftBit,d7
 beq.s NotLeft
 move.w XPosOffset(a6),d0
 sub.w d6,d0
 bmi NotLeft ; Prevent Move if off screen
 clr.w d4
 sub.w d6,d4 * negative step size in x offset

NotLeft
 btst #RightBit,d7
 beq.s NotRight
 move.w XPosOffset(a6),d0
 add.w d6,d0
 cmp.w PlayerXMax-S(a5),d0
 bge NotRight
 move.w d6,d4 * set x offset to step size

NotRight
 btst #UpBit,d7
 beq.s NotUp
; move.w PlayerYPos-S(a5),d0
 move.w YPosOffset(a6),d0
 sub.w d6,d0
 bmi NotUp
 clr.w d5
 sub.w d6,d5 * set y offset to negative step size

NotUp
 btst #DownBit,d7
 beq.s NotDown
; move.w PlayerYPos-S(a5),d0
 move.w YPosOffset(a6),d0
 add.w d6,d0
 cmp.w PlayerYMax-S(a5),d0
 bge NotDown
 move.w d6,d5 * set y offset to negative step size

NotDown
* store desire for later movement
 move.l MapLayoutPtr-S(a5),a0
 bsr CheckPlayerMove
* now d4.w=x speed and d5.w=speed requested by player + possible
 lea FireButtonHeld-S(a5),a0
 move.b JoystickStatus-S(a5),d7
 btst #FireButton,d7
 bne MaybeFireMissile
* the fire button has been released - 
 clr.b (a0) * allow another shot to be fired
 move.l MapLayoutPtr-S(a5),a0
 bsr CPMFinishMove * update speed pointers+do animation
; a6.l is player's sprite block
 move.w XPosOffset(A6),PlayerXPos-S(A5)
 move.w YPosOffset(A6),PlayerYPos-S(A5)
 rts * bra TimeLoop * can't fire whilst moving

MaybeFireMissile
 tst.b (a0) * has fire button been held down?
 beq.s FireMissile
 subq.b #1,(a0) * decrement repeat count
 rts

FireMissile
 move.b #4,(a0) * restrict rate of fire

* where is the sprite control block for this player?
;; move.l Player1SpriteBlock-S(a5),a6
 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a6
 add.l d0,a6

; Initiate Fire
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 add.w #4,d1 * overlap allowed for head
 clr.l d2
 move.b ViewOffset(a6),d2

 asl.w #2,d2 * 2 words per entry
 lea ViewToXYConversionTable-S(a5),a0
 add.l d2,a0
 move.w (a0)+,d2 * d2:=x speed
 move.w #12,d4
 mulu d4,d2 * missiles go at 12 pel/step
 move.w (a0)+,d3 * d3:=y speed
 mulu d4,d3 * missiles go at 12 pel/step

 move.b CurrentWeapon-S(a5),d6
 move.w #9,d4 * sprite number for digging missile
 cmp.b #1,d6
 beq.s FM1
 move.w #8,d4 * sprite for explosive weapon
 cmp.b #2,d6
 beq.s FM1 
 move.w #1,d4 * sprite number for non-explosive missile

FM1
 lea RandomSeed-S(a5),a0
 move.l (a0),d6
 rol.l #1,d6
 move.l d6,(a0)

 tst.w d2
 beq.s NoRandomizeXSpeed
 tst.w d3
 beq.s NoRandomizeBoth
;* and change the y speed to maintain angles of diagonals
;*  (-1,-1)           (+1,-1)
;*	  \        /
;*           \    /
;*	      \/
;*	      /\
;*	    /    \
;*         /        \
;*  (-1,+1)	     (+1,+1)

 btst #0,d6
 beq.s DecreaseSpeed
* increase speed
 add.w #1,d2
 bpl.s IncreaseSpeed1
 sub.w #2,d2
Increasespeed1
 add.w #1,d3
 bpl.s NoRandomizeXSpeed
 sub.w #2,d3
 bra.s NoRandomizeYSpeed

DecreaseSpeed
 sub.w #1,d2
 bpl.s DecreaseSpeed1
 add.w #2,d2
DecreaseSpeed1
 sub.w #1,d3
 bpl.s NoRandomizeYSpeed
 add.w #2,d3
 bra.s NoRandomizeYSpeed

NoRandomizeBoth
 add.w #1,d2
 btst #0,d6
 beq.s NoRandomizeXSpeed
; Decrease x speed
 subq.w #2,d2

NoRandomizeXSpeed
 tst.w d3
 beq.s NoRandomizeYSpeed
 btst #0,d6
 beq.s NoRandomizeYSpeed

DecreaseYSpeed
 subq.w #1,d3
 bra.s NoRandomizeYSpeed

IncreaseYSpeed
 add.w #1,d3

NoRandomizeYSpeed
 bsr SetUpNewSprite
 rts
;-------
;InitSpriteTable
; Lea DoYRangeKill-S(a5),a0
; clr.b (a0)
;
; lea SpriteTable-S(a5),a0
; lea SpriteTPtr-S(a5),a1
; move.l a0,(a1)
; move.w #MaxMovingSprites,d5 * max size of table
;IST1
; clr.l (a0)+
; clr.l (a0)+
; clr.l (a0)+
; clr.l (a0)+
; clr.l (a0)+
; dbra d5,IST1
;
;* and set up 1 player sprite....
;
; move.w #200,d1 * initial player y pos
; clr.w d2 * x speed
; clr.w d3 * y speed
; move.w #0,d4 * player-type
; move.w #128,d0 * initial player x pos
; movem.l d0-d7/a0-a6,-(sp)
; bsr SetUpNewSprite
; move.l a0,Player1SpriteBlock-S(A5)
; movem.l (sp)+,d0-d7/a0-a6
;
;* and set up 25 monster sprites....
; move.w #2,d4
;
; move.w #236,d1 * initial player y pos
;IST2
; move.w #164,d0 * top left x pos of grid of monsters
;IST3
; movem.l d0-d7/a0-a6,-(sp)
; bsr SetUpNewSprite
; movem.l (sp)+,d0-d7/a0-a6
; add.w #16,d0 * x pos
; cmp.w #244,d0
; ble.s IST3
; sub.w #16,d1
;
;* alternate between sprites 2/4 on alternate lines
;; move.w d4,d0
;; move.w #9,d4
;; sub.w d0,d4
;
; cmp.w #164,d1
; bgt.s IST2
;
;* and set up a monster below the player
; move.w #120,d1 * initial player y pos+16
; move.w #128,d0 * initial player x pos
; movem.l d0-d7/a0-a6,-(sp)
; bsr SetUpNewSprite
; movem.l (sp)+,d0-d7/a0-a6
;
; move.w #300,d0
; move.w #120,d1
; move.w #10,d4 * a bottle 
; bsr SetUpNewSprite
;
; move.w #320,d0
; move.w #120,d1
; move.w #10,d4 * a bottle 
; bsr SetUpNewSprite
;
; move.w #340,d0
; move.w #120,d1
; move.w #10,d4 * a bottle 
; bsr SetUpNewSprite
;
; move.w #332,d0
; move.w #154,d1
; move.w #11,d4 * invisible object
; bsr SetUpNewSprite
;
; rts
;----
MCFindSprite
; return the next sprite in the sprite block having name V1
; Start Search from offset V2, and return V2 as new offset
; Only used by Acode.
 movem.l a3-a6,-(sp)
 move.w (a4),d0 * var value
 lea SpriteTable-S(A5),a0
MCFS1
 cmp.w NameOffset(a0),d0
 beq.s MCFSFound
 move.l NextPtrOffset(a0),d1
 beq.s MCFSNotFound
 move.l d1,a0
 bra.s MCFS1

MCFSNotFound
 move.w #-1,d0 * error code
 bra.s MCFSFound1

MCFSFound
 lea SpriteTable,a1
 sub.l a1,a0
 move.l a0,d0 * d0.l is offset from start of spritetable.
MCFSFound1
 movem.l (sp)+,a3-a6
 move.w d0,2(a4) * return v2 as result
 rts
;----
MCSetUpNewSprite
 movem.l a3-a6,-(sp)
  move.w $02(a4),d0
  move.w $04(a4),d1
  move.w $06(a4),d2
  move.w $08(a4),d3
  move.w $0A(a4),d4
  lea S(PC),a5
  bsr SetUpNewSprite
; convert a0.l to an offet into spritetable for use by acode...
 lea SpriteTable-S(A5),a1
 sub.l a1,a0
 movem.l (sp)+,a3-a6
 move.w a0,$0c(a4) * return as v6
 move.w d7,$0e(A4) * return negative in v7 if couldn't set up sprite
 rts
;---
SetUpNewSprite
* d0,d1=initial x,y position. d2,d3 are x,y speed d4.w is sprite number
* (i.e. which entry in fixed sprite table is to be used)
* returns a0.l as pointer to temp sprite table

 lea SpriteTable-S(a5),a0
 move.w #MaxMovingSprites,d7 * max size of table
 tst.l (a0)
 beq SUNS5 * blank table - just set up sprite

SUNS1
 tst.l (a0)
 beq.s SUNS2 * got a blank entry
 add.l #SpriteCurrentSize,a0
 dbra d7,SUNS1
 RTS * can't set up sprite! (sorry...)

SUNS2
 lea TempNameStorage-S(a5),a3
 move.w d4,(a3)
 lea SpriteDataStructure-S(a5),a3
 move.w #SDSSize,d6 * size of fixed sprite information
 mulu d6,d4 * get offset of sprite structure
 add.l d4,a3 * a3.l is fixed sprite information

* decide where to put the sprite in the chain
* Items of low priority are displayed first (and therefore
* stored first in the linked list). Items of same priority are
* sorted according to y position.
 move.l SpriteTPtr-S(a5),a1
 move.w #MaxMovingSprites,d7 * max size of table - limit scan
SUNSScan0
 tst.l NextPtrOffset(a1)
 beq SUNSAddAfterCurrent * GotNewPosition * end of linked list
 move.l (a1),a2 * address of permament data for this sprite in chain
 move.b PriorityOffset(a2),d6
 cmp.b PriorityOffset(a3),d6 * compare with sprite we're setting up
 bhi.s GotPosition
 bne.s SUNSScan1
* is the new y position lower on screen than this sprite?
* If so, we have found the right place
 cmp.w YPosOffset(a1),d1
 blt.s SUNSInsertSprite

SUNSScan1
* keep on scanning
 move.l NextPtrOffset(a1),a1
 dbra d7,SUNSScan0
 bsr SafeBreakPoint * should never get here
 rts * can't add sprite for some reason

GotNewPosition
 clr.l NextPtrOffset(a0) * clear the new ptr

SUNSInsertSprite
GotPosition
* insert a sprite (a0) before (a1)
 move.l LastPtrOffset(a1),a2 * keep address of previous sprite
 move.l a2,LastPtrOffset(a0) * point back to previous link
 move.l a2,d5 * test ptr to previous sprite
 bne.s SUNS3a
* adding a new entry to start of chain
 lea SpriteTPtr-NextPtrOffset-S(a5),a2 * new start of linked list
 move.l #0,LastPtrOffset(a0) * no link back from sprite
* we've just added because its the first in the chain.

SUNS3a
 move.l a0,NextPtrOffset(a2)
 move.l a1,NextPtrOffset(a0)
 move.l a0,LastPtrOffset(a1)

SUNS3
 move.l a3,(a0) * sprite data address
 move.w d2,4(a0) * x speed
 move.w d3,6(a0) * y speed
 move.w d0,8(a0) * x pos
 move.w d1,$a(a0) * y pos
 move.l #0,$c(a0) * blank out remaining entries
 move.l #0,$18(a0)
 move.l #0,$1c(a0)
 move.l #0,$20(a0)
 move.l #0,$24(a0)
 move.l #0,$28(a0)
 move.l #0,$2c(a0)

* calc address of sprite data
 clr.w d4
; move.b ViewOffset(a6),d4
; asl.w #1,d4 * double to get index into word-wise table
 move.w MovingAnimationOffset(a3,d4),d4 * get base sprite number for view
; add.b StageOffset(a6),d4 * add on animation stage
 move.l SpriteDataPtr-S(a5),a1
 mulu #20*10,d4
 add.l d4,a1
 move.l a1,DataPtrOffset(a0) * write to storage for use by cd etc.

 move.w TempNameStorage-S(a5),NameOffset(a0) * set up default 'name'
 move.w InitialHitPointOffset(a3),HitPointOffset(a0)
 move.w InitialBlowStrengthOffset(a3),BlowStrengthOffset(a0)
 rts

;-------
SUNSAddAfterCurrent
; We found the end of the chain (a1)
; Now add the sprite (a0) at this end of the list
 move.l a0,NextPtrOffset(a1)
 move.l a1,LastPtrOffset(a0)
 clr.l NextPtrOffset(a0) ****
 bra SUNS3
;-------
SUNS5
* first entry only - just calc address and write data block
 lea SpriteDataStructure-S(a5),a3
 move.w #SDSSize,d6 * size of fixed sprite information
 mulu d6,d4 * get offset of sprite structure
 add.l d4,a3 * a0.l is sprite data
 clr.l NextPtrOffset(a0) * set up ptr to next entry
 clr.l LastPtrOffset(a0) * LastPtrOffset
 bra SUNS3
;-------
DAMSSpecials
* now do special cases for particular types of monsters...
 move.b TypeOffset(a4),d0
 bpl.s NotSI
 move.w SIXspeed-S(a5),d2
 move.w SIYSpeed-S(a5),d3

NotSi
 bra DAMSSNotMissile *****
 btst #1,d0
 beq DAMSSNotMissile
* plot 2 successive images of missile to make it go at 12 pels per frame
 bsr DAMSAnimate
; asr.w #1,d2
; asr.w #1,d3
 movem.l a0-a6,-(sp)
* how many pels to move? (also enforces true diagonal movement)
  move.w d2,d4
  bne.s DAMSMissile1
  move.w d3,d4
  beq.s DAMSDestroyMissile * not moving!
DAMSMissile1
  bpl.s DAMSMissile2 * d4 already positive
  neg.w d4
DAMSMissile2
 sub.w #3,d4 * reduce because (a) dbra does one more than we want,
* and (b) the main DISPLAYALL loop will do the final move for us
* now d4.w is the number of pels to move by

* convert speeds to +/- 1 or 0
 tst.w d2
 beq.s DAMSMissile4
 bpl.s DAMSMissile4a
 move.w #-1,d2
 bra.s DAMSMissile4
DAMSMissile4a
 move.w #1,d2
DAMSMissile4

 tst.w d3
 beq.s DAMSMissile5
 bpl.s DAMSMissile5a
 move.w #-1,d3
 bra.s DAMSMissile5
DAMSMissile5a
 move.w #1,d3
DAMSMissile5
 asl.w #2,d2 * move at 4 pels per second for speed
 asl.w #2,d3
 lsr.w #2,d4

  sub.l #8,a6 * back to start of control block
  move.w XPosOffset(a6),d0
  move.w YPosOffset(a6),d1

DAMSMissile3
* move by one pel
  add.w d2,d0
  add.w d3,d1
  move.w d0,XPosOffset(a6) * for benefit of specialmapcheck
  move.w d1,YPosOffset(a6) * for benefit of specialmapcheck
  movem.w d0-d4,-(sp)
   movem.l d5-d7/a0-a6,-(sp) *****
   bsr CheckForBackgroundCollision
   movem.l (sp)+,d5-d7/a0-a6 *****
  movem.w (sp)+,d0-d4
  tst.l (a6)
  beq DAMSSpecialMissileEnd
  dbra d4,DAMSMissile3

* final move will be made in main DISPLAYALL loop
DAMSSpecialMissileEnd
 movem.l (sp)+,a0-a6
 rts

DAMSDestroyMissile
* missile is not moving - kill it
 dc.w $4afa ; Leave in until release
 move.l a6,a0
 bsr DestroySprite
 movem.l (sp)+,a0-a6
 rts
;------
;-----



DAMSSNotMissile
 cmp.b #4,d0
 bne DAMSNotMonster
; Make Monsters move towards player
 clr.w d4 * will be direction of view
 move.w XPosOffset-8(a6),d2 * xpos
 move.w YPosOffset-8(a6),d3 * ypos
 sub.w PlayerXPos-S(a5),d2 * actually wrong way round, hence inverted logic
 beq.s aMonsNoHoriz
 bmi.s aMonsRight
* handle vertical decision for moving towards the left
 sub.w PlayerYPos-S(a5),d3
 beq.s LeftMonsNoVert
 bmi.s LeftMonsdown
 move.b #28,d4 * diagonally up left
 bra.s GotDecision

LeftMonsDown
 move.b #20,d4 * sw
 bra.s GotDecision

LeftMonsNoVert
 move.b #24,d4 * west
 bra.s GotDecision
;---
aMonsNoHoriz
 sub.w PlayerYPos-S(a5),d3
 beq GotDecisionNoMove
 bpl.s GotDecision * north - d4=0

NoHorizMonsDown
 move.b #16,d4 * down
 bra.s GotDecision

GotDecisionNoMove
 clr.w d2
 clr.w d3
 rts
;----
aMonsRight
* handle vertical decision for moving towards the right
 sub.w PlayerYPos-S(a5),d3
 beq.s RightMonsNoVert
 bmi.s RightMonsdown
 move.b #4,d4 * diagonally up right
 bra.s GotDecision

RightMonsDown
 move.b #12,d4 * se
 bra.s GotDecision

RightMonsNoVert
 move.b #8,d4 * east
; bra.s GotDecision

GotDecision
* d4.b is the direction of movement for this sprite
 add.b AddDirOffset-8(a6),d4
 ext.w d4
 bmi.s GDPos1
 sub.w #32,d4 * maybe make d4 negative
 bpl.s GDPos2

GDPos1
* d4 is negative - add 8 to it to get the equivalent positive directio
 add.w #32,d4

GDPos2
 lea ViewToXYConversionTable-S(a5),a0
 move.w 0(a0,d4),d2 * d2:=x speed
 asl.w #2,d2 * monsters move at speed 4
 move.w 2(a0,d4),d3 * d3:=y speed
 asl.w #2,d3 * monsters move at speed 4

 bra.s DamsNotPlayer * do animation, return

DAMSNotMonster
 cmp.b #1,d0
 bne DAMSNotPlayer
DAMSPlayer
; move.w PlayerXSpeed,d2
; move.w PlayerYSpeed,d3
 rts

DAMSNotPlayer
DAMSAnimate
* animate all monsters (except the player which is handled
* only when it is walking)

 move.b StageOffset-8(a6),d4
 add.b #1,d4
 cmp.b NumAnimationOffset(a4),d4
 ble.s DAMSAnimateOk
 clr.b d4
DAMSAnimateOk
 move.b d4,StageOffset-8(a6) * write new animation stage
 rts
;-------
BGDestroyWall
* using a weapon that destroys walls
* d0,d1 is approx position of explosion
 bsr SpecialMapCheck * because FindBlock needs some regies set up by this
 bsr FindBlock
 cmp.w PlayerYMax-S(a5),d1 * off the map!
 bcc.s BGNoWallToDestroy
 cmp.w PlayerXMax-S(a5),d0 * off the map!
 bcc.s BGNoWallToDestroy
  movem.w d0-d1,-(sp)
* now d0,d1 is position on grid
* calculate the position in the map
  asr.w #3,d0 * divide by 16, multiply by 2. Lowest bit is already 0
  asr.w #3,d1 * ""     ""  "     ""            ""        ""   ""
  mulu ScreenXBlocks-S(a5),d1 * also extends d1 to .l so we add to a0.l below
  add.w d0,d1 * use .w because this will always be adequate
  move.l MapLayoutPtr-S(a5),a0 * unscrolled version of course
  add.l d1,a0
  movem.w (sp)+,d0-d1

 tst.w (a0)
 beq.s BGNoWallToDestroy
 clr.w (a0)

 bsr AddDestroyedWall * set up masking sprite
BGNoWallToDestroy
 rts
;------
KillSprite
 move.l a6,a0
 bsr DestroySprite
 bra DAMSNextSprite
;-------
CheckForBackgroundCollision
; tst.w d2
; bne.s CFBC1
; tst.w d3
; bne.s CFBC1
;* no movement - don't check for collision with background
; rts

CFBC1
* collision with background?
 move.b HeightOffset(a4),d6 * offset of bottom row
 move.l MapLayoutPtr-S(a5),a0
 bsr MapCheck

* detect collisions with trap squares?
; move.w d0,-(sp)
;  btst #CDSpecialBG,SpecialFlagsOffset(a6)
;  beq.s CFBC2 * no
;* yup - do the collision
;* save map co-ordinates in case there was a collision
;  movem.l a0/d6,-(sp)
;   move.w ScreenXBlocks,d6
;   asl.w #1,d6 * double because map is word orientated
;   move.w #8,d5
;   bsr MapCheckA0D6
;  movem.l (sp)+,a0/d6
;
;CFBC2
; move.w (sp)+,d0 * restore result of MapCheck
 bne NoBGCollision

 bsr CleverMapCheck
 bne.s NoBGCollision

 move.b CDFlagsOffset(a4),d5
 btst #CDWithBG,d5
 beq NoBGCollision

* sprite collided with the background - should it actually
* be destroyed, or just be prevented from moving?
 move.b CDDestroyedOffset(a4),d5
 btst #CDWithBG,d5
 beq.s BGNoExplode

 movem.l d0-d7/a0-a6,-(sp)
  bsr SpecialMapCheck
  beq.s BGDestroy1
 movem.l (sp)+,d0-d7/a0-a6
 bra.s NoBGCollision

BGDestroy1
 movem.l (sp)+,d0-d7/a0-a6

* collision with wall - kill the sprite - the explosion
* and any other effects will be handled in the specials code.
 move.l a6,a0
 bsr DestroySprite
 move.l #1,(a6) * prevent sprite entry being reused yet.

BGNoExplode
 move.b CDSpecialsOffset(a4),d5
 btst #CDWithBG,d5
 beq.s NoBGSpecials
 bsr BGSpecials * sometimes creates new sprites, so if the sprite
* had been properly destroyed above, a new replacement for it might
* possibly have been created.

NoBGSpecials
 move.l (a6),d0
 cmp.l #1,d0
 bne.s NoBGDestroyed
* Sprite was previously marked for destruction
 move.l #0,(a6) * destroy it properly

NoBGDestroyed
 move.b CDBlockedOffset(a4),d5
 btst #CDWithBG,d5
 beq.s NoBGCollision * not blocked

* reset co-ords
 move.w XPosSave-S(a5),d0
 move.w d0,XPosOffset(a6)
 move.w YPosSave-S(a5),d1
 move.w d1,YPosOffset(a6)
 clr.w d2 * and kill movement
 clr.w d3 * clear y speed to avoid unnecessary sorting
 bra BGSpriteCantMove * randomize move for monsters. rts

NoBGCollision
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 rts
;
;BGExplode
; bsr SpecialMapCheck
; bne.s NoBGCollision
; movem.l d0-d7/a0-a6,-(sp)
;  move.w NameOffset(a6),d4 * CurrentWeapon,d4
;;  cmp.b #1,d4
;  cmp.b #9,d4 * bg destructive?
;  bne BGExplode1
;
; move.w NumDestroyedWalls,d2
; cmp.w #MaxDestroyedWalls,d2
; bcc.s BGExplode1
;
;  bsr BGDestroyWall
;* display the explosion
; bsr NoTraceBack1
; bra.s BGExplode2
;
;BGExplode1
; movem.l (sp)+,d0-d7/a0-a6
; movem.l d0-d7/a0-a6,-(sp)
;
;  bsr TraceBack * NoTraceBack1 **** TraceBack
;BGExplode2
; movem.l (sp)+,d0-d7/a0-a6
; move.l a6,a0
; bra DestroySprite * bsr, rts
;--------
FGSpecials
* a6.l,a4.l and a0.l,a1.l have just collided.
* a6.l had the appropriate special flag set.
* does it want to do anything special?
* a0-a6 should be preserved, data registers may be destroyed.
* REMEMBER - we can also use NAMEOFFSET(A6) (Yes - a6)
 move.l a6,List20Ptr-S(A5)
 move.l a4,List21Ptr-S(A5)
 move.l a0,List22Ptr-S(A5)
 move.l a1,List23Ptr-S(A5)
; bsr MCFgSpecials
 movem.l a0-a6,-(sp)
 move.l AcodeFns-S(A5),a0
 add.l #4,a0 * second jump
 bsr CallAcode * jmp (a0)
 move.w 2(a4),d4 * v1 - set to true if ok to continue with cd
 movem.l (sp)+,a0-a6
 rts
;---
;MCFgSpecials
; move.b TypeOffset(a4),d5 * player?
; cmp.b #1,d5
; bne.s FGS1NotPlayer
;* player ran into something else. A trap perhaps?
; cmp.w #11,NameOffset(a0)
; bne.s FGS1NotPlayerTrap
;
; lea TimeToNextShot-S(a5),a2
; subq.b #1,(a2)
; bpl.s FGS1NotPlayer * not ready to fire again yet
; move.b #60,(a2) * reset timer - about 2 seconds to next shot
;
;; sub.w #1,HitPointOffset(a6)
;* fire some missiles from the cunningly concealed guns...
; movem.l d0-d7/a0-a6,-(sp)
;  move.w #320,d0
;  move.w #92,d1
;  move.w #12,d4 * monster missile
;  move.w #0,d2
;  move.w #8,d3 * y speed
;  bsr SetUpNewSprite
;
;  move.w #336,d0
;  move.w #92,d1
;  move.w #12,d4 * monster missile
;  move.w #0,d2
;  move.w #8,d3 * y speed
;  bsr SetUpNewSprite
; movem.l (sp)+,d0-d7/a0-a6
;
; rts
;
;FGS1NotPlayerTrap
;FGS1NotPlayer
; rts
;;-------
;LandABlow
; subq.b #1,TimeToNextBlowOffset(a6)
;; move.b TimeToNextBlowOffset(a6),d0
;; cmp.b TimeBetweenBlowsOffset(a4),d0
; bpl.s FGSFighting1
; move.b TimeBetweenBlowsOffset(a4),TimeToNextBlowOffset(a6)
;* do damage to (a0,a1)
; move.w BlowStrengthOffset(a6),d0
; bsr DoDamageD0
;
;FGSFighting1
; rts
;-----
FGSpecialsForMovedSpriteOnly
* as above, but a6.l is guaranteed to have been the sprite that
* tried to move, and  a0.l is what it ran into.
 move.l a6,List20Ptr-S(A5)
 move.l a4,List21Ptr-S(A5)
 move.l a0,List22Ptr-S(A5)
 move.l a1,List23Ptr-S(A5)
; bsr MCFGSpecialsForMovedSpriteOnly
 movem.l a0-a6,-(sp)
 move.l AcodeFns-S(A5),a0
 add.l #8,a0 * third jump - 4 bytes each
 bsr CallAcode * jmp (a0)
 movem.l (sp)+,a0-a6
 rts
;---
;MCFGSpecialsForMovedSpriteOnly
; move.b TypeOffset(a4),d5
;* player?
; cmp.b #1,d5
; bne.s FGSNotPlayer
;* trying to fight?
; move.b TypeOffset(a1),d0
; btst #2,d0 * monster?
; beq.s FGSNotPlayerFight
;FGSFighting
;* time for another blow to land yet?
; bsr LandABlow
;* add on the fighting animation offset
; move.l DataPtrOffset(a6),d0
; clr.l d1
; move.w FightAnimationOffset(a4),d1
; ext.l d1
; add.l d1,d0
; move.l d0,DataPtrOffset(a6)
; rts
;
;FGSNotPlayerFight
;;* player ran into something else. A trap perhaps?
;; move.b TypeOffset(a1),d0
;; btst #CDWithInvisibles,d0
;; beq.s FGSNotPlayerTrap
;; sub.w #1,HitPointOffset(a6)
;; rts
;;
;;FGSNotPlayerTrap
;FGSNotPlayer
;* monster?
; btst #CDWithMonsters,d5
; beq.s FGSNotMonster
;* trying to fight?
; move.b TypeOffset(a1),d0
; btst #0,d0 * player?
; bne.s FGSFighting
;
;FGSNotMonster
; move.b TypeOffset(a4),d5 * what requested the special?
;* missile?
; btst #CDWithMissiles,d5
; beq.s FGSNotMissile
;
;* do some damage
; bsr breakIfArmed *****
; bsr LandABlow
;
;* for missiles, an explosion is also started where the OTHER sprite was.
; tst.l (a0)
; beq.s FGSNotMissile * the target was destroyed, so DODAMAGE
;* will already have started the relevant explosion
; movem.l a0-a6,-(sp)
;  bsr HandleFGExplosion
; movem.l (sp)+,a0-a6
; rts
;
;FGSNotMissile
; rts
;-------
;DoDamageD0
;* subtract D0.W hit points from sprite (a0.l,a1.l)
; move.w HitPointOffset(a0),d1 *******
; sub.w d0,HitPointOffset(a0)
; beq.s DoDamageDestroy * zero hit points left
; bmi.s DoDamageDestroy
; rts
;
;DoDamageDestroy
; clr.w HitPointOffset(a0)
; tst.l (a0)
; beq.s DDDRet
; movem.l d0-d7/a0-a6,-(sp)
;  bsr DestroySprite
;  bsr HandleFGExplosion
; movem.l (sp)+,d0-d7/a0-a6
;DDDRet
; rts
;-------
BGSpecials
* a6.l,a4.l has just collided with a wall.
* a6.l had the appropriate special flag set.
* does it want to do anything special?
* a0-a6 should be preserved, data registers may be destroyed.
* REMEMBER - we can also use NAMEOFFSET(A6) (Yes - a6)
 move.l a6,List20Ptr-S(A5)
 move.l a4,List21Ptr-S(A5)
 bsr MCBgSpecials
 movem.l a0-a6,-(sp)
 move.l AcodeFns-S(A5),a0
 add.l #12,a0 * third jump
 bsr CallAcode * jmp (a0)
 movem.l (sp)+,a0-a6
 rts
;---
MCBGSpecials
* a6.l,a4.l has just collided with a chunk of background
 move.b TypeOffset(a4),d5
 btst #CDWithMissiles,d5
 beq.s BGNotMissile
 movem.l d0-d7/a0-a6,-(sp)
  move.w NameOffset(a6),d4
  cmp.w #9,d4 * bg destructive?
  bne BGExplode1
  clr.w NameOffset(a6) * prevent it exploding again (No,
* I don't know why this is necessary either - Mike)
  move.w NumDestroyedWalls-S(a5),d2
  cmp.w #MaxDestroyedWalls,d2
  bcc.s BGExplode1
  bsr BGDestroyWall
* display the explosion
  bsr NoTraceBack1
  bra.s BGExplode2

BGExplode1
 movem.l (sp)+,d0-d7/a0-a6
 movem.l d0-d7/a0-a6,-(sp)
  bsr TraceBack * displays the explosion in the most suitable place
BGExplode2
 movem.l (sp)+,d0-d7/a0-a6
BGNotMissile
 rts
;------
FindBlock
* figure out where the explosion should be centred.
* Needs registers d4-d7 (masks etc) set up by SpecialMapCheck
* Which block did we hit?
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 clr.w d2
 move.b HeadOverlapOffset(a4),d2
 add.w d2,d1
 and.w #$fff0,d0
 and.w #$fff0,d1
* d0,d1 is now the co-ordinates of the block (a0)
* We collided with either 0(a0,d6) or 2(a0,d6)
FindBlock1
 tst.w d6
 beq.s FindBlock2
 add.w #16,d1 * add one 16x16 block's worth to y coordinate
 sub.w ScreenXBlocks-S(a5),d6
 sub.w ScreenXBlocks-S(a5),d6
 bpl.s FindBlock1

FindBlock2
* now (d0,d1) is correct for the block in the y direction
* decide which of the two possible horizontal blocks is more likely.
* d7.b is the result of the masking operation
* which decided the collision.

 clr.l d6
 move.w d7,d6
 swap d6
 move.w XPosOffset(a6),d7
 and.b #$0f,d7 * get offset of sprite within 16x16 block
 lsr.l d7,d6
* we now have a bit pattern where the population in the high
* word gives the number of bits which collided with the left sprite
* and the population in the low word gives the right sprite
 bsr PopulationCount
 move.w d7,d5 * save the right hand population
 swap d6
 bsr PopulationCount
 cmp.w d5,d7
 bge.s FindBlock3
 add.w #16,d0
FindBlock3
 rts
;---
PopulationCount
* return in d7.w the number of bits set in d6.w
* d6.w is destroyed
 move.w d5,-(sp) * loop counter
 clr.w d7
 move.w #16,d5
PC0
 tst.w d6
 bpl.s PC1
 add.w #1,d7
PC1
 asl.w #1,d6
 dbra d5,PC0
 move.w (sp)+,d5
 rts
;-------
MCMoveAllSprites
 movem.l a3-a6,-(sp)
  bsr MoveAllSprites
 movem.l (sp)+,a3-a6
 rts
;---
MoveAllSprites
; move all the sprites in the moving sprite table
 lea SpriteTable-S(a5),a6 * a6 remains as pointer to sprite table
; lea DAMSLoopCounter-S(a5),a0
 move.w #MaxMovingSprites+1,DAMSLoopCounter-S(A5)

DAMS1
 tst.l (a6) * sprite number zero?
 beq DAMSNextSprite
 movem.l a5-a6,-(sp)
  move.l a6,List20Ptr-S(A5) * set up ptrs to sprite block for acode
  move.l a6,List22Ptr-S(A5)
  move.l AcodeFns-S(A5),a0
  add.l #20,a0 * sixth jump
  bsr CallAcode * jmp (a0)
 movem.l (sp)+,a5-a6
 tst.w 2(a4) * check v1 - condition return
 bmi DAMSNextSprite
 beq.s DAMSSkipSpecials ; skip specials

 move.l (a6)+,a4 * address of sprite structure
 move.w (a6)+,d2 * x speed
 move.w (a6)+,d3 * y speed

 bsr DAMSSpecials
 tst.l -8(a6) ****
 bne DAMSNotDestroyed *****
 sub.l #8,a6
 bra DAMSNextSprite

DAMSSkipSpecials
 move.l (a6)+,a4 * address of sprite structure
 move.w (a6)+,d2 * x speed
 move.w (a6)+,d3 * y speed

DAMSNotDestroyed
 move.b LifeCounterOffset-8(a6),d0
 beq.s DAMSNotLimited
 subq.b #1,d0
 move.b d0,LifeCounterOffset-8(a6)
 bne.s DAMSNotLimited
* end of life, self-destruct
SelfDestruct
 sub.l #8,a6
 move.l a6,a0
 bsr DestroySprite
 bra DAMSNextSprite

SelfDestruct2
 sub.l #2,a6
 bra.s SelfDestruct

DamsNotLimited
; clr.w d0
; move.b ViewOffset-8(a6),d0
; asl.w #1,d0 * double to get index into word-wise table
; move.w MovingAnimationOffset(a4,d0),d4 * get base sprite number for view
; add.b StageOffset-8(a6),d4 * add on animation stage

DAMSCalc
* calc address of sprite data
 clr.w d4
 move.b ViewOffset-8(a6),d4
 bmi.s DAMSNextSprite * an invisible sprite
 asl.w #1,d4 * double to get index into word-wise table
 move.w MovingAnimationOffset(a4,d4),d4 * get base sprite number for view
 add.b StageOffset-8(a6),d4 * add on animation stage

 add.w AnimationOffset-8(a6),d4 * add on general animation offset

 move.l SpriteDataPtr-S(a5),a0
 mulu #20*10,d4
 add.l d4,a0
 move.l a0,DataPtrOffset-8(a6) * write to storage for use by cd,
* display etc.

* load co-ordinates and move sprite
 move.w (a6),d0 * x pos
 move.w d0,XPosSave-S(A5)
 add.w d2,d0
 move.w d0,(a6)+
 move.w (a6),d1 * y pos
 move.w d1,YPosSave-S(A5)
 bmi.s SelfDestruct2 * prevent missiles wrapping round.
 add.w d3,d1
 move.w d1,(a6)
 sub.l #10,a6 * back to start of control block
;
 cmp.w PlayerXMax-S(a5),d0
 bcc KillSprite
 cmp.w PlayerYMax-S(a5),d0
 bcc KillSprite

 bsr CheckForBackgroundCollision
 tst.l (a6)
 beq DAMSNextSprite

 bsr CheckForSpriteCollision
 tst.l (a6)
 beq DAMSNextSprite

 move.b DoYRangeKill-S(a5),d6
 beq.s NoRangeKill
* kill off-screen sprites for space invaders
 sub.w ScreenYPos-S(a5),d1
 cmp.w #230,d1 * special to SI
 bcc KillSprite * special to SI - kill missiles which go off screen

NoRangeKill
 move.w ySpeedOffset(A6),d3 * update y speed for benefit of CMS
 bsr ConsiderMovingSprite

DAMSNextSprite
 add.l #SpriteCurrentSize,a6
; lea DAMSLoopCounter-S(a5),a0
; subq.w #1,(a0)
 subq.w #1,DAMSLoopCounter-S(A5)
 bne DAMS1 * limit length of loop
 rts
;--------
DisplayAllSprites
; Now Display all the sprites
 move.l SpriteTPtr-S(a5),a6
 move.w #MaxMovingSprites,d7
DAS1
 tst.l (a6) * sprite number zero?
 beq DASNextSprite

 move.l (a6),a4 * address of sprite structure
 cmp.b #$20,TypeOffset(a4)
 beq.s DASNextSprite * an invisible sprite
* calc address of sprite data
 move.l DataPtrOffset(a6),a3 * address of bit pattern to use

 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 sub.w ScreenXPos-S(a5),d0
 sub.w ScreenYPos-S(a5),d1
 move.l LogicalBase-S(a5),a2
 move.w d7,-(sp)
  bsr Sprite
 move.w (sp)+,d7
DASNextSprite
 move.l NextPtrOffset(a6),a6
 move.l a6,d0
 beq.s DASEnd
 dbra d7,DAS1

DASEnd
* d7.w sprites remain.
 lea FreeSprites-S(a5),a0
 move.w d7,(a0)
 rts
;----

ConsiderMovingSprite
* sprite (a6) has moved in direction d3.w
 move.l a6,a0
 tst.w d3
 bpl.s CMSFore
CMSBack
; maybe move up the linked list
 move.w YPosOffset(a0),d1
 move.l LastPtrOffset(a0),a1
 move.l a1,d2 * at start of list already?
 beq.s CMSRet

 cmp.w YPosOffset(a1),d1
 bge.s TryForeAgain *CMSRet * no move necessary

CMSBack1
 move.l LastPtrOffset(a1),d2
 beq.s CMSBackFinished2 * got back to start of list?
 move.l d2,a1

; cmp.b PriorityOffset(a1),d0
; bne.s CMSBackFinished
 cmp.w YPosOffset(a1),d1
 blt.s CMSBack1 * moved sprite should be above this, hence earlier in list
CMSBackFinished
CMSBackFinished2
* unlink from the current position
 move.l NextPtrOffset(a0),a2
 move.l LastPtrOffset(a0),a3

;
 move.l a3,d2 * have we just moved the first entry in list?
 bne.s CMSBF2
* yup - so update ptr to start of sprite table
 lea SpriteTPtr-S(a5),a3
 move.l a2,(a3)
 bra.s CMSBF3

CMSBF2
 move.l a2,NextPtrOffset(a3)
CMSBF3

;
 move.l a3,LastPtrOffset(a2)
; move.l a2,NextPtrOffset(a3)
* and link in before the position (a1.l)
 move.l LastPtrOffset(a1),a2 * save sprite before the new position
 move.l a1,NextPtrOffset(a0)
 move.l a0,LastPtrOffset(a1)

 move.l a2,d2
 beq.s CMSStart * start of linked list
 move.l a2,LastPtrOffset(a0)
 move.l a0,NextPtrOffset(a2)
CMSRet
 rts

CMSStart
 clr.l LastPtrOffset(a0)
 lea SpriteTPtr-S(a5),a1
 move.l a0,(a1)
 rts
;----
TryForeAgain
 tst.w d3
 bmi.s CMSFore
 rts

CMSFore
; maybe move down the linked list
; move.b PriorityOffset(a0),d0
 move.l NextPtrOffset(a0),a1
 move.l a1,d2 * at end of list?
 beq.s CMSRet

 cmp.w YPosOffset(a1),d1
 ble.s CMSRet * moved sprite has greater y value, so should be further

CMSFore1
 move.l NextPtrOffset(a1),d2
 beq.s CMSEnd * got to end of list
 move.l d2,a1

; cmp.b PriorityOffset(a1),d0
; bne.s CMSForeFinished
 cmp.w YPosOffset(a1),d1
 bgt.s CMSFore1 * moved sprite should be above this, hence earlier in list
* moved sprite has greater y value, so should be further
* down in the list

CMSForeFinished
CMSForeFinished2
* unlink from the current position
 move.l NextPtrOffset(a0),a2
 move.l LastPtrOffset(a0),a3
 move.l a2,d2 ****
 beq.s CMSFF2a ****
 move.l a3,LastPtrOffset(a2)

CMSFF2a
 move.l a3,d2 * have we just moved the first entry in list?
 bne.s CMSFF2
* yup - so update ptr to start of sprite table
 lea SpriteTPtr-S(a5),a3
 move.l a2,(a3)
 bra.s CMSFF3

CMSFF2
 move.l a2,NextPtrOffset(a3)
CMSFF3
* and link in before the position (a1.l)
 move.l LastPtrOffset(a1),a2 * save sprite before the new position
 move.l a1,NextPtrOffset(a0)
 move.l a0,LastPtrOffset(a1)

 move.l a2,d2 * have we moved it to the start of the linked list
 beq.s CMSStart
 move.l a2,LastPtrOffset(a0)
 move.l a0,NextPtrOffset(a2)
 rts
;-----
CMSEnd
* moving a0.l to the end of the list - after a1.l
* unlink from the current position
 move.l NextPtrOffset(a0),a2
 move.l a2,d2
 beq.s CMSForeFinished2 * trying to move the end sprite!
 move.l LastPtrOffset(a0),a3
 move.l a3,LastPtrOffset(a2)
 move.l a3,d2 * have we just moved the first entry in list?
 bne.s CMSEFF2
* yup - so update ptr to start of sprite table
 lea SpriteTPtr-S(a5),a3
 move.l a2,(a3)
 bra.s CMSEFF3

CMSEFF2
 move.l a2,NextPtrOffset(a3)
CMSEFF3
* and link in after the position (a1.l)
 clr.l NextPtrOffset(a0)
 move.l a1,LastPtrOffset(a0)
 move.l a0,NextPtrOffset(a1)
 rts
;------------
;TryBackAgain
; tst.w d3
; bpl.s CMSBack
; rts
;
;ConsiderMovingSprite
;* sprite (a6) has moved in direction d3.w
; tst.w d3
; bpl.s CMSFore
;CMSBack
;; maybe move up the linked list
; move.w YPosOffset(a6),d1
; move.l LastPtrOffset(a6),a1
; move.l a1,d2 * at start of list already?
; beq.s CMSRet
;
; cmp.w YPosOffset(a4),d1
; bge.s TryForeAgain * no move necessary
;
;CMSBack1
; move.l LastPtrOffset(a1),d2
; beq.s CMSBackFinished2 * got back to start of list?
; move.l d2,a1
; cmp.w YPosOffset(a1),d1
; ble.s CMSBack1 * moved sprite should be above this, hence earlier in list
;CMSBackFinished
;CMSBackFinished2
;* unlink from the current position
; move.l NextPtrOffset(a6),a2
; move.l LastPtrOffset(a6),a3
;
; move.l a3,d0 * first sprite in chain?
; bne.s CMS1
; lea SpriteTPtr,a0 * link it up to start of linked list
; move.l a2,(a0)
;* a3=0, set up new first sprite in chain
; bra.s CMS2
;
;CMS1
; move.l a2,NextPtrOffset(a3)
;
;CMS2
; move.l a3,LastPtrOffset(a2)
;* and link in before the position (a1.l)
; move.l LastPtrOffset(a1),a2 * save sprite before the new position
; move.l a1,NextPtrOffset(a6)
; move.l a6,LastPtrOffset(a1)
;
; move.l a2,d2
; beq.s CMSStart * start of linked list
; move.l a2,LastPtrOffset(a6)
; move.l a6,NextPtrOffset(a2)
;CMSRet
; rts
;
;CMSStart
; clr.l LastPtrOffset(a6)
; lea SpriteTPtr,a1
; move.l a6,(a1)
; rts
;;----
;TryForeAgain
; tst.w d3
; bmi.s CMSFore
; rts
;; bsr SafeBreakpoint
;
;CMSFore
;; maybe move down the linked list
;; move.b PriorityOffset(a6),d0
; move.l NextPtrOffset(a6),a1
; move.l a1,d2 * at end of list?
; beq.s CMSRet
;
; cmp.w YPosOffset(a1),d1
; ble.s CMSRet * moved sprite has greater y value, so should be further
;
;CMSFore1
; move.l NextPtrOffset(a1),d2
; beq.s CMSForeFinished * got to end of list?
; move.l d2,a1
;
; cmp.w YPosOffset(a1),d1
; bge.s CMSFore1 * moved sprite should be above this, hence earlier in list
;* moved sprite has greater y value, so should be further
;* down in the list
;
;CMSForeFinished
;* unlink from the current position
; move.l NextPtrOffset(a6),a2
; move.l LastPtrOffset(a6),a3
;
; move.l a3,LastPtrOffset(a2)
; move.l a3,d3 * have we just moved the first entry in list?
; bne.s CMSFF2
;* yup - so update ptr to start of sprite table
; lea SpriteTPtr,a3
; move.l a2,(a3)
; bra.s CMSFF3
;
;CMSFF2
; move.l a2,NextPtrOffset(a3)
;CMSFF3
;* and link in before the position (a1.l)
;* d2 is zero if we want to add after (a1.l)
;; tst.l d2
;; beq.s CMSAfter
; move.l LastPtrOffset(a1),a2 * save sprite before the new position
; move.l a1,NextPtrOffset(a6)
; move.l a6,LastPtrOffset(a1)
;
; move.l a2,d2
; beq.s CMSStart
; move.l a2,LastPtrOffset(a6)
; move.l a6,NextPtrOffset(a2)
; rts
;;----
;CMSAfter
; move.l a6,NextPtrOffset(a1)
; move.l a1,LastPtrOffset(a6)
; clr.l NextPtrOffset(a6)
; rts
;-----
MCDestroySpriteList20
 move.l a5,-(sp)
  lea S(PC),a5
  move.l list20Ptr-S(A5),a0
  bsr DestroySprite
 move.l (sp)+,a5
 rts
;---
MCDestroySpriteList22
 move.l a5,-(sp)
  lea S(PC),a5
  move.l list22Ptr-S(A5),a0
  bsr DestroySprite
 move.l (sp)+,a5
 rts
;---
DestroySprite
* remove the sprite whose controll block is (a0.l)
 move.l LastPtrOffset(a0),a1
 move.l NextPtrOffset(a0),a2
 move.l a1,d0 * first sprite in chain?
 bne.s DS1
 lea SpriteTPtr-S(a5),a1 * link it up start of linked list
 move.l a2,(a1)
 clr.l LastPtrOffset(a2) * new first sprite in chain
 bra.s DS2

DS1
 move.l a2,NextPtrOffset(a1)
 move.l a2,d0 * last sprite in chain?
 beq.s DS2

 move.l a1,LastPtrOffset(a2)
DS2
 clr.l (a0) * remove the pointer to the fixed data
 clr.l LastPtrOffset(a0)
; clr.l NextPtrOffset(a6)
 rts
;----
;HandleFGExplosion
;* a0.l is the control block of the sprite that (a6.l) collided with
; move.w XPosOffset(a0),d0 * x pos
; move.w YPosOffset(a0),d1 * y pos
; move.b TypeOffset(a4),d4
; cmp.b #$22,d4 * explosive missile type
; beq.s StartBigExplosion
;
; clr.w d2 * x speed
; clr.w d3 * y speed
; move.w #3,d4 * sprite no. for explosion
; bsr SetupNewSprite
; tst.w d7
; bmi.s HFERet * couldn't set up sprite
; move.b #8,LifeCounterOffset(a0) * self-destructs after 8 steps
;HFERet
; rts
;-------
MCStartBigExplosion
 movem.l a3-a6,-(sp)
  move.w 2(a4),d0 * xpos
  move.w 4(a4),d1 * ypos
  bsr StartBigExplosion
 movem.l (sp)+,a3-a6
 rts
;---
StartBigExplosion
 lea BigExplosionTable-S(a5),a0
SBELoop
 move.w (a0)+,d2 * xspeed
 bne.s SBE1
 move.w (a0)+,d3 * yspeed
 bne.s SBE2
 rts * end of table

SBE1
 move.w (a0)+,d3

SBE2
 movem.l d0-d7/a0-a6,-(sp)
  move.w #1,d4 * ordinary, non-explosive missile
  bsr SetupNewSprite
  tst.w d7
  bmi.s SBE3 * couldn't set up new sprite
  move.b #3,LifeCounterOffset(a0) * self-destructs after 8 steps
SBE3
 movem.l (sp)+,d0-d7/a0-a6
 bra.s SBELoop
;-------
AddDestroyedWall
* we've just destroyed wall at (d0,d1)
* add it to the list
 move.l DestroyedWallPtr-S(a5),a0
ADW1
 move.w (a0),d2
 beq.s ADW3
 addq.w #4,a0
 bra.s ADW1

ADW3
 and.w #$fff0,d0
 beq.s DDWRet * 0,0 would terminate table so cannot be allowed
 and.w #$fff0,d1
 move.w d0,(a0)+
 move.w d1,(a0)+
 clr.w (a0)+
 lea NumDestroyedWalls-S(a5),a0
 addq.w #1,(a0)

DDWRet
 rts
;----
DisplayDestroyedWalls
 move.w ScreenXPos-S(a5),d0
 and.w #$000f,d0 * assumes scroll steps of 4!
* d0.w is amount screen is scrolled by
* find masks to use for each destroyed wall
 lea HiDDWLeftTable-S(a5),a0
 move.l 0(a0,d0),d2 * assumes horizontal scroll steps of 4
 lea LoDDWLeftTable-S(a5),a0
 move.l 0(a0,d0),d4

 lea HiDDWRightTable-S(a5),a0
 move.l 0(a0,d0),d3 * assumes horizontal scroll steps of 4
 lea LoDDWRightTable-S(a5),a0
 move.l 0(a0,d0),d5 * assumes horizontal scroll steps of 4


* now d2d4.64,d3d4.64 are masks to remove each wall

 move.l DestroyedWallPtr-S(a5),a0
 bra.s DDW1

DDWAdd2
 add.l #2,a0

DDW1
 move.w (a0)+,d0
 beq.s DDWRet
 sub.w ScreenXPos-S(a5),d0
 cmp.w #ScreenXSize,d0
 bcc DDWAdd2
 and.w #$fff0,d0 * align displayed x pos with screen

 move.w (a0)+,d1
 sub.w ScreenYPos-S(a5),d1
 cmp.w #ScreenYSize,d1
 bcc.s DDW1 * next sprite
* calculate address on screen
 mulu #160,d1
 asr.w #1,d0
 add.w d0,d1
 move.l LogicalBase-S(a5),a1
 add.l d1,a1

* now mask out all the entries
 move.w #1,d6 * loop count

DDWLoop
 and.l d2,(a1)
 and.l d4,4(a1)
 and.l d3,8(a1)
 and.l d5,12(a1)

 and.l d4,160(a1)
 and.l d4,164(a1)
 and.l d5,168(a1)
 and.l d5,172(a1)

 and.l d2,320(a1)
 and.l d4,324(a1)
 and.l d3,328(a1)
 and.l d5,332(a1)

 and.l d4,480(a1)
 and.l d4,484(a1)
 and.l d5,488(a1)
 and.l d5,492(a1)

 and.l d2,640(a1)
 and.l d4,644(a1)
 and.l d3,648(a1)
 and.l d5,652(a1)

 and.l d4,800(a1)
 and.l d4,804(a1)
 and.l d5,808(a1)
 and.l d5,812(a1)

 and.l d2,960(a1)
 and.l d4,964(a1)
 and.l d3,968(a1)
 and.l d5,972(a1)

 and.l d4,1120(a1)
 and.l d4,1124(a1)
 and.l d5,1128(a1)
 and.l d5,1132(a1)

 add.l #1280,a1
 dbra d6,DDWLoop
 bra DDW1
;----
HiDDWLeftTable
* used to mask out high 2 bits of each pel in word
 dc.l $00000000,$fff0fff0,$ff00ff00,$f000f000
; dc.l $88888888,$fff8fff0,$ff88ff80,$f888f880

LoDDWLeftTable
* used to mask out low 2 bits of each pel in word
* and the odd lines of each sprite - to give a floor pattern
 dc.l $00000000,$fff0fff0,$ff00ff00,$f000f000

HiDDWRightTable
 dc.l $ffffffff,$000f000f,$00ff00ff,$0fff0fff
; dc.l $ffffffff,$888f000f,$88ff00ff,$8fff0fff

LoDDWRightTable
 dc.l $ffffffff,$000f000f,$00ff00ff,$0fff0fff
;----
TraceBack
* now replace the sprite we moved into the background with an explosion
* find out where the point of collision is (if speed of motion>4)
 move.w #24,d6 * maximum trace-back
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 move.w XSpeedOffset(a6),d2
 move.w YSpeedOffset(a6),d3
* now reduce speed until it is less than 4
TraceBack1
 tst.w d2
 beq.s TraceBack2
 bpl.s TraceBack2a
 move.w #$ffff,d2
 bra.s TraceBack2

TraceBack2a
 move.w #1,d2

TraceBack2
 tst.w d3
 beq.s TraceBack3
 bpl.s TraceBack3a
 move.w #$ffff,d3
 bra.s TraceBack3

TraceBack3a
 move.w #1,d3

TraceBack3
* keep on retreating until we're clear of the wall...
 movem.l d0-d1/d6,-(sp)
  move.b HeightOffset(a4),d6 * offset of bottom row
  move.l MapLayoutPtr-S(a5),a0
  bsr MapCheck
 movem.l (sp)+,d0-d1/d6
 bne.s NoTraceBack0 * are clear of the wall
 sub.w d2,d0 * move back a little way in x direction
 sub.w d3,d1 * move back a little way in y direction
 dbra d6,TraceBack3
* couldn't get clear - just leave explosion at point of contact

NoTraceBack0
* now advance onto the wall
 asl.w #3,d2
 asl.w #3,d3
 add.w d2,d0
 add.w d3,d1
 bra.s NoTraceBack1

NoTraceBack
 move.w XPosOffset(a6),d0 * x pos
 move.w YPosOffset(a6),d1 * y pos
NoTraceBack1
 move.b TypeOffset(a4),d4
 cmp.b #$22,d4
 beq TraceBackStartBigExplosion

 clr.w d2 * x speed
 clr.w d3 * y speed
 move.w #3,d4 * sprite no. for explosion
 bsr SetupNewSprite
 tst.w d7
 bmi.s NTBRet * couldn't set up new sprite
 move.b #8,LifeCounterOffset(a0) * self-destructs after 8 steps
NTBRet
 rts
;----
TraceBackStartBigExplosion
 sub.w d2,d0 * move back a bit in x direction
 sub.w d3,d1 * move back a bit in y direction
 bra StartBigExplosion
;------
CleverMapCheck
* called from automove
* Make it fast guys...
* check if the sprite (a6) can move to (d0,d1) at speed d2,d3
*********** is d2 really the x speed here?
* surely it is corrupted by mapcheck
;  move.w #19,d6 * height
;  move.l MapLayoutPtr,a0
;;  add.w #4,d1 * add overlap for top of sprite
;  bsr MapCheck
; bne.s MCOk

 move.b TypeOffset(a4),d6
 cmp.b #4,d6
 bne.s MCNoChance * not a monster
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
* the monster was blocked by a collision with the map.
* if it was trying to go diagonally, try just going in each of the
* orthogonal directions
 tst.w d2 * d4
 beq.s MCNoChance
 tst.w d3 * d5
 beq.s MCNoChance

 movem.l d0-d1,-(sp)
  sub.w d2,d0 * remove horizontal move
  move.b HeightOffset(a4),d6 * height
  move.l MapLayoutPtr-S(a5),a0
;  add.w #4,d1 * add on overlap for sprite
  bsr MapCheck
 movem.l (sp)+,d0-d1
 bne.s MCVertOk

 movem.l d0-d1,-(sp)
  sub.w d3,d1 * remove vertical move
  move.b HeightOffset(a4),d6 * height
  move.l MapLayoutPtr-S(a5),a0
;  add.w #4,d1 * add on overlap for sprite
  bsr MapCheck
 movem.l (sp)+,d0-d1
 bne.s MCHorizOk

MCNoChance
 clr.b d6 * set zero flag
 rts


MCOk
 move.b #1,d6 * set nz
 rts

MCHorizOk
 sub.w d3,d1 * no vertical move
 move.w d1,YPosOffset(a6)
 move.b #1,d6 * set nz
 rts

MCVertOk
 sub.w d2,d0 * undo horiz move
 move.w d0,XPosOffset(a6)
 move.b #1,d6 * set nz
 rts

;------
;HandleKeyPress
; Key D0.B has been pressed
; cmp.b #'t',d0
; bne.s HKPNotArm
; lea BreakpointArmed-S(a5),a0
; move.b #1,(a0)
;
;HKPNotArm
; cmp.b #'(',d0
; beq SiResetMonsters
; cmp.b #')',d0
; beq ResetMonsters
; cmp.b #'*',d0
; bne.s HKPNoBreak
; dc.w $4afa
; rts
;
;HKPNoBreak
; cmp.b #'p',d0
; bne.s HKPNoPause
;HKPPause
; bsr AbsGetCharFromBdos
; tst.b d0
; beq.s HKPPause
; rts
;
;HKPNoPause
; cmp.b #'f',d0
; bne.s HKPNoFire
; bra FireMissile
;
;HKPNoFire
; cmp.b #'1',d0
; bcs.s NoChangeSpeed
; cmp.b #'9',d0
; bgt.s NoChangeSpeed
; sub.b #'0',d0
; lea PlayerStepSize-S(a5),a0
; move.b d0,(a0)
; lea ScrollStep-S(a5),a0
; and.b #$fc,d0 * scroll only in steps of 4
; cmp.b #4,d0
; bge.s ChangeSpeed1
; move.b #4,d0
;ChangeSpeed1
; move.b d0,(a0)
; rts
;
;NoChangeSpeed
; cmp.b #'a',d0
; blt.s NoChangeWeapon
; cmp.b #'c',d0
; bgt.s NoChangeWeapon
; sub.b #'a',d0
; lea CurrentWeapon-S(a5),a0
; move.b d0,(a0)
; rts
;
;NoChangeWeapon
; cmp.b #'R',d0
; beq ResetMonsters
; cmp.b #'r',d0
; beq ResetMonsters
;
;
; cmp.b #32,d0
; beq CloseDown
; RTS

MCCloseDown
CloseDown
 bsr CloseDownVBL
 bsr CloseDownJoystickHandler
 move.l SupervisorStack-S(a5),-(sp)
 move.w #$20,-(sp) * code for _super
 trap #1
 add.l #6,sp

 move.b ScreenResolution-S(A5),d0
 cmp.b #2,d0
 beq.s CloseDownHires
 bsr SetMedResolution
 bsr ReturnToGem
;-----
CloseDownHires
 bsr SetHighResolution
 bra ReturnToGem
;---
DisplayUpperTextLine
; clear text area...
 move.l LogicalBase-S(a5),a0
; add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area
 move.w #160*12/16-1,d1 * clear 12 pel lines.
 move.l #0,d0
DUTL0
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 dbra d1,DUTL0

; move.b #1,LineCleared-S(A5) ********** 
 rts
;---
MCScrollTextLine
; scroll a line of text at coords v0,v1
 movem.l a3-a6,-(sp)
  lea S(PC),a5 * set up ws pointer
  bsr CalcCurrentCharAddress
* and set up d0.w as the number of pels to shift by
  move.w 2(a4),d0
  bsr ScrollTextLineA0D0
 movem.l (sp)+,a3-a6
 rts
;---

DisplayTextLine
; clear text area...
; move.l LogicalBase-S(a5),a0
; add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area
; move.w #160*10/16,d1
; move.l #0,d0
;DTL0
; move.l d0,(a0)+
; move.l d0,(a0)+
; move.l d0,(a0)+
; move.l d0,(a0)+
; dbra d1,DTL0
;
;; On Alternate frames, increment text pointer
;; On other frame, leave pointer where it is and do a 4-pel scroll
;; on the text to make it smoother
; lea TextSmoothScroll-S(a5),a0
; addq.b #1,(a0)
; move.b (a0),d0
; and.b #3,d0
; beq IncrementTextPtr
; lea TextOffset-S(a5),a0
; clr.l d0
; move.w (a0),d0
; bsr DTL * Display text line
;* and scroll it.
; move.l LogicalBase-S(a5),a0
; add.l #(200-8)*160+8,a0 * +8 to correspond with physical screen
;
; move.b TextSmoothScroll-S(a5),d0
; and.w #3,d0
; asl.w #1,d0

ScrollTextLineA0D0
* scroll first word separately
 move.w (a0),d1
 asl.w d0,d1
 move.w d1,(a0)
* (on subsequent screen lines, it is done by the last operation of the
* previous line)
 move.b ScreenResolution,d3
 bne.s MonoDTL

 move.w #8,d3
DTLScroll0
 move.l a0,-(sp)
 move.w #19,d1
DTLScroll
 clr.l d2
 move.w 8(a0),d2
 asl.l d0,d2
 move.w d2,8(a0)
 swap d2
 or.w d2,(a0) * and write high order byte to first bit plane

 add.l #8,a0
 dbra d1,DTLScroll
 and.b #$f0,-7(a0) * blank out last nybble copied in from next line
 move.l (sp)+,a0
 add.l #160,a0
 dbra d3,DTLScroll0
 rts
;-------
MonoDTL
 move.w #15,d3
MonoDTLScroll0
 move.l a0,-(sp)
 move.w #19,d1
MonoDTLScroll
 clr.l d2
 move.w (a0),d2
 asl.l d0,d2
 move.w d2,(a0)
 swap d2
 or.w d2,-2(a0) * and write high order byte to first bit plane
 addq.l #2,a0

 dbra d1,MonoDTLScroll
 and.b #$f0,(a0) * blank out last nybble copied in from next line
 move.l (sp)+,a0
 add.l #80,a0
 dbra d3,MonoDTLScroll0
 rts
;---
;IncrementTextPtr
;; increment ptr to text message
; lea TextOffset-S(a5),a0
; clr.l d0
; move.w (a0),d0
; add.w #1,d0
;
;DTL
; cmp.w #TextLength,d0
; bls.s DTL1
; clr.w d0
;
;DTL1
; move.w d0,(a0)
; lea TextArea-S(a5),a0
; add.l d0,a0
;; Copy 40 Chars from Circular buffer at TextArea to TextBuffer
;; Are there enough chars left before end of cicular buffer?
; move.w #TextLength,d7 ; total size of buffer
; sub.w d0,d7 ; d0.w:=number of chars remaining
;; Limit d7.w to 40 chars max
; cmp.w #40,d7
; ble.s DTL1a
; move.w #40,d7
;DTL1a
;; Copy d7 chars into TextBuffer for starters
; move.w d7,d6 * save d7
; lea TextBuffer-S(a5),a1
;DTL2
; move.b (a0)+,(a1)+
; dbra d7,DTL2
;
;; Now copy 40-d6 chars into TextBuffer from the start of the string
; lea TextArea-S(a5),a0
; move.w #40,d7
; sub.w d6,d7 * d6.w is number of chars already copied
; bmi.s DTL4 * just in case it wraps round!
;DTL3
; move.b (a0)+,(a1)+
; dbra d7,DTL3
;DTL4
; move.l LogicalBase-S(a5),a0
; add.l #(200-8)*160+8,a0 +8 to correspond with physical screen
;
; lea TextBuffer-S(a5),a1
;;
; move.b ScreenResolution-S(a5),d7
; bne.s MonoDisplayTextLine
; move.w #19,d7
;DisplayD7CharPairs
;; Display D7.w characters at screen address a0.l
;; from Text string at (a1.l)
;; calc address in font
; clr.l d0
; move.b (a1)+,d0
; bsr WriteChar
; add.l #1,a0 ; write to odd addresses
; clr.l d0
; move.b (a1)+,d0
; bsr WriteChar
; add.l #7,a0 ; next address to write to
; dbra d7,displayD7CharPairs
; rts
;;---
;MonoDisplayTextLine
; move.w #19,d7
;MonoDisplayD7CharPairs
;; Display D7.w characters at screen address a0.l
;; from Text string at (a1.l)
;; calc address in font
; clr.l d0
; move.b (a1)+,d0
; bsr WriteChar
; add.l #1,a0 ; write to odd addresses
; clr.l d0
; move.b (a1)+,d0
; bsr WriteChar
; add.l #1,a0 ; next address to write to
; dbra d7,MonoDisplayD7CharPairs
; rts
;---
*-------------------
OswrchFirstVar
 move.w 2(a4),d0 * first variable - number 1

Oswrch
 move.b ByteInvertFlag(PC),d1
 bne.s InvertedOswrch
 movem.l d0-d7/a0-a6,-(sp)
  lea S(PC),a5 * set up ws pointer
  and.l #$000000ff,d0
  move.l d0,-(sp)
   bsr CalcCurrentCharAddress
  move.l (sp)+,d0
  tst.w TextBufferOffset-S(A5)
  bne.s OswrchToBuffer
  cmp.b #32,d0
  bcs.s OswrchNoPrint
  bsr WriteChar
  addq.w #8,CursorXPos-S(a5) * step on cursor position
OswrchNoPrint
 movem.l (sp)+,d0-d7/a0-a6
OswrchRet
 rts
;---
OswrchToBuffer
; used to expand text into an output buffer
  lea TextBuffer-S(A5),a0
  move.w TextBufferOffset-S(A5),d1
  move.b d0,(a0,d1)
  addq.w #1,TextBufferOffset-S(A5)
 movem.l (sp)+,d0-d7/a0-a6
 rts
*-------------------
InvertedOswrchFirstVar
 move.w 2(a4),d0 * first variable - number 1

InvertedOswrch
 movem.l d0-d7/a0-a6,-(sp)
  lea S(PC),a5 * set up ws pointer
  and.l #$000000ff,d0
  move.l d0,-(sp)
   bsr CalcCurrentCharAddress
  move.l (sp)+,d0
  cmp.b #32,d0
  bcs.s InvertedOswrchNoPrint
  bsr InvertedWriteChar
InvertedOswrchNoPrint
  addq.w #8,CursorXPos-S(a5) * step on cursor position
 movem.l (sp)+,d0-d7/a0-a6
 rts
;----
WriteChar
* display char with ascii code d0 at position (a0.l) on screen
 sub.b #32,d0
 asl.w #3,d0
 lea FontSpace-S(a5),a2
 add.l d0,a2
 move.b ScreenResolution-S(A5),d0
 cmp.b #2,d0
 beq.s WriteCharMono

; Write char to current position on screen (a0.l)
 move.b (a2)+,(a0)
 move.b (a2)+,160(a0)
 move.b (a2)+,320(a0)
 move.b (a2)+,480(a0)
 move.b (a2)+,640(a0)
 move.b (a2)+,800(a0)
 move.b (a2)+,960(a0)
 move.b (a2)+,1120(a0)
 rts
;----
WriteCharMono
; Write char to current position on screen (a0.l)
 move.b (a2),(a0)
 move.b (a2)+,80(a0)
 move.b (a2),160(a0)
 move.b (a2)+,240(a0)
 move.b (a2),320(a0)
 move.b (a2)+,400(a0)
 move.b (a2),480(a0)
 move.b (a2)+,560(a0)
 move.b (a2),640(a0)
 move.b (a2)+,720(a0)
 move.b (a2),800(a0)
 move.b (a2)+,880(a0)
 move.b (a2),960(a0)
 move.b (a2)+,1040(a0)
 move.b (a2),1120(a0)
 move.b (a2),1200(a0)
 rts
;---
InvertedWriteChar
* display char with ascii code d0 at position (a0.l) on screen
 sub.b #32,d0
 asl.w #3,d0
 lea FontSpace-S(a5),a2
 add.l d0,a2
 move.b ScreenResolution-S(A5),d0
 cmp.b #2,d0
 beq.s InvertedWriteCharMono

; Write char to current position on screen (a0.l)
 move.b (a2)+,(a0)
 eor.b #-1,(a0)
 move.b (a2)+,160(a0)
 eor.b #-1,160(a0)
 move.b (a2)+,320(a0)
 eor.b #-1,320(a0)
 move.b (a2)+,480(a0)
 eor.b #-1,480(a0)
 move.b (a2)+,640(a0)
 eor.b #-1,640(a0)
 move.b (a2)+,800(a0)
 eor.b #-1,800(a0)
 move.b (a2)+,960(a0)
 eor.b #-1,960(a0)
 move.b (a2)+,1120(a0)
 eor.b #-1,1120(a0)
 rts
;----
InvertedWriteCharMono
; Write char to current position on screen (a0.l)
 move.b (a2),(a0)
 eor.b #-1,(a0)
 move.b (a2)+,80(a0)
 eor.b #-1,80(a0)
 move.b (a2),160(a0)
 eor.b #-1,160(a0)
 move.b (a2)+,240(a0)
 eor.b #-1,240(a0)
 move.b (a2),320(a0)
 eor.b #-1,320(a0)
 move.b (a2)+,400(a0)
 eor.b #-1,400(a0)
 move.b (a2),480(a0)
 eor.b #-1,480(a0)
 move.b (a2)+,560(a0)
 eor.b #-1,560(a0)
 move.b (a2),640(a0)
 eor.b #-1,640(a0)
 move.b (a2)+,720(a0)
 eor.b #-1,720(a0)
 move.b (a2),800(a0)
 eor.b #-1,800(a0)
 move.b (a2)+,880(a0)
 eor.b #-1,880(a0)
 move.b (a2),960(a0)
 eor.b #-1,960(a0)
 move.b (a2)+,1040(a0)
 eor.b #-1,1040(a0)
 move.b (a2),1120(a0)
 eor.b #-1,1120(a0)
 move.b (a2),1200(a0)
 eor.b #-1,1200(a0)
 rts
*--------
CalcCurrentCharAddress
* Calculate in a0.l the screen address represented by
* CursorXPos,CursorYPos
* All co-ordinates are presented to this routine on the basis that
* the full screen is (x=0..319, y=0..199) with x=0,y=0 at top left
 move.b ScreenResolution-S(A5),d0
 beq.s CCalcCurrentCharAddress

HCalcCurrentCharAddress EVEN
* calculate the memory address of the current cursor position
 move.l LogicalBase-S(A5),a0
 add.l #2,a0 * allow for trimming offset
 CLR.L D0
 CLR.L D1
; MOVE.W #ScreenYSize,d0 * YScreenSize(PC),D0
; SUB.W CursorYPos(PC),D0
 move.w CursorYPos-S(A5),d0
* each LINE is 80 pels
; MOVE.B YScale(PC),D1
; BEQ.S HCalcNormalY
; MOVE.W #160,D1
; BRA.S HCalc2
;
;HCalcNormalY EVEN
 MOVE.W #160,D1 * twice length (80), because actually have
* 400 lines in mono, not 200 as the co-ords assume

;HCalc2 EVEN
 MULU D0,D1
 ADD.L D1,A0
 CLR.L D0
; MOVE.B XScale(PC),D0
; BEQ.S HCalcNormal
;* Calc for wide chars
; MOVE.W CursorXPos(PC),D0
; LSR.W #2,D0 * 8 pixels per byte
; ADD.L D0,A0
; RTS
;
;HCalcNormal
 MOVE.W CursorXPos-S(A5),D0
 lsr.w #2,d0 * 8 pixels per byte (would give a shift by 3), but
; co-ords are 0..319, not 0..639 so need to double the offset
 ADD.L D0,A0
 RTS
*---------
*--------
CCalcCurrentCharAddress EVEN
* calculate the memory address of the current cursor position
 MOVE.L LogicalBase-S(A5),a0
 add.l #8,a0 * allow for trimming offset
 CLR.L D0
 CLR.L D1
; MOVE.W #ScreenYSize,d0 * YScreenSize(PC),D0
; SUB.W CursorYPos(PC),D0
 move.w CursorYPos-S(A5),d0
;* each LINE is 160 pels
; MOVE.B YScale(PC),D1
; BEQ.S CCalcNormalY
; MOVE.W #320,D1
; BRA.S CCalc2
;
;CCalcNormalY EVEN
 MOVE.W #160,D1
CCalc2
 MULU D0,D1
 ADD.L D1,A0
 CLR.L D0
 MOVE.W CursorXPos-S(A5),D0
* LSR.W #3,D0 * 8 pixels per byte
*\ AND.W #$FE,D0
*\ ASL.W #2,D0
; MOVE.B XScale(PC),D1
; ASL.W D1,D0 * shift by XScale

 lsr.w #1,d0
 and.w #$F8,d0

 ADD.L D0,A0
 MOVE.W CursorXPos-S(A5),D0
; ASL.W D1,D0 * shift by XScale
 BTST #3,D0
 BEQ.S CDC1
 ADDQ.L #1,A0

CDC1
 RTS
*---------
;---
AdvanceA0
 move.b ScreenResolution-S(A5),d0
 cmp.b #2,d0
 beq.s MonoAdvance
 move.w a0,d0
 btst #0,d0
 beq.s Advance1
 addq.l #7,a0
 rts

MonoAdvance
Advance1
 addq.l #1,a0
 rts
;---
;DisplayHitPoints
; move.w #272,CursorXPos-S(A5)
; move.w #160,CursorYPos-S(A5)
; bsr CalcCurrentCharAddress
;; move.b #'H',d0
;; bsr OswrchD0
;; move.b #'=',d0
;; bsr OswrchD0
;; clr.l d0
;; lea SpriteTable-S(a5),a1
;; move.w HitPointOffset(A1),d0
;; bra ProperPrintDecimalD0
;
;; move.l LogicalBase-S(a5),a0
;; add.l #(200-48)*160+136,a0
;* and blank out the digits which may possibly be printed
; move.l a0,-(sp)
;  bsr PrintSpace
;  bsr PrintSpace
;  bsr PrintSpace
;  bsr PrintSpace
; move.l (sp)+,a0
;
; clr.l d0
; lea SpriteTable-S(a5),a1
; move.w HitPointOffset(a1),d0
; bra PrintDecimald0 * bsr, rts
;---
CalculateMemoryFree
; move.w #272,CursorXPos-S(A5)
; move.w #168,CursorYPos-S(A5)
; bsr CalcCurrentCharAddress

 move.l LogicalBase-S(a5),d0
 cmp.l PhysicalBase-S(a5),d0
 blt.s DMF1
 move.l PhysicalBase-S(a5),d0
DMF1
 sub.l HiUsedMemory-S(a5),d0
 lsr.l #8,d0 * divide by 1024 to convert to K
 lsr.l #2,d0
 move.w d0,2(a4)
 rts

;; move.l LogicalBase-S(a5),a0
;; add.l #(200-40)*160+136,a0
;* and blank out the digits which may possibly be printed
; movem.l d0/a0,-(sp)
;  bsr PrintSpace
;  bsr PrintSpace
;  bsr PrintSpace
;  bsr PrintSpace
; movem.l (sp)+,d0/a0
; bsr PrintDecimald0
; move.w #'K',D0
; bra WriteChar
;----
;PrintSpace
; move.w #32,d0
; bsr WriteChar
; bra AdvanceA0 * bsr,rts
;---
;CalculateFreeSprites
; move.w #272,CursorXPos-S(A5)
; move.w #176,CursorYPos-S(A5)
; bsr CalcCurrentCharAddress
;
; clr.l d0
; move.w FreeSprites-S(a5),d0
;
;; move.l LogicalBase-S(a5),a0
;; add.l #(200-32)*160+136,a0
; movem.l d0/a0,-(sp)
;* and blank out the digits which may possibly be printed
;  bsr PrintSpace
;  bsr PrintSpace
; movem.l (sp)+,d0/a0
;
; bra PrintDecimald0 * bsr, rts
;---
MCReturnFrameTime
 move.l $4ba,d0
 sub.l LastTime-S(a5),d0
 move.w d0,2(a4) * return in V1 - first variable
 rts
;---
MCUpdateFrameTime
 move.l $4ba,LastTime-S(A5)
 rts
;--- 
;DisplayFrameTime
; rts
;
; lea LastTime-S(a5),a0
; move.l $4ba,d0 * 200 Hz Timer
; move.l (a0),d1
;; move.l d0,(a0) * update last frame time
; sub.l d1,d0
;* d0.l is time in 5 ms increments
; move.w d0,FrameTime-S(A5)
; mulu #5,d0 * convert to ms
;
;; move.l LogicalBase-S(a5),a0
;; add.l #(200-24)*160+136,a0
; move.l d0,-(sp)
;  move.w #272,CursorXPos-S(A5)
;  move.w #184,CursorYPos-S(A5)
;  bsr CalcCurrentCharAddress
; move.l (sp)+,d0
;
; movem.l d0/a0,-(sp)
; bsr AdvanceA0 * first 2 chars are always printed
; bsr AdvanceA0
;* and blank out the digits which may possibly be printed
; bsr PrintSpace
; bsr PrintSpace
; bsr PrintSpace
; bsr PrintSpace
; movem.l (sp)+,d0/a0
;
; bsr PrintDecimald0
;
;
;* now restrict speed to 80 ms
;DFTDelay
; lea LastTime-S(a5),a0
; move.l $4ba,d0 * 200 Hz Timer
; move.l (a0),d1
;; move.l d0,(a0) * update last frame time
; sub.l d1,d0
;* d0.l is time in 5 ms increments
; mulu #5,d0 * convert to ms
; cmp.l #80,d0
; blt.s DFTDelay
; move.l $4ba,(a0) * update last frame time
;
;
PrintDecRet
 rts
;---
AcodePrintDecimalD0
 movem.l a3-a5,-(sp)
 lea S(PC),a5
 move.l d0,-(sp)
  bsr CalcCurrentCharAddress
 move.l (sp)+,d0
 bsr PrintDecimalD0
 movem.l (sp)+,a3-a5
 rts

printdecimald0
* print d0.l as a decimal number,
* suppressing leading zeros
 tst.l d0
 bne.s printdec1
 move.l #"0",d0
 bsr WriteChar
 bra Advancea0

printdec1
* non-zero number to print
 move.l d0,d2 ; store number somewhere more sensible
 lea numbertable-S(a5),a1
 move.b #0,d3 ; reset flag
printdec1a
* find the current digit value
 move.l (a1)+,d1 ; get value
 beq printdecret ; no more digits possible
* given d2=remainder of number, d1=value of current digit,
* find value
 move.l #"0",d0
printdec2
 sub.l d1,d2
 bcs.s printdec3
 addq.b #1,d0
 move.b #1,d3 ; set leading-zeros flag
 bra.s printdec2
printdec3
 add.l d1,d2
 tst.b d3 ; flag set yet ?
 beq.s printdec1a
 bsr WriteChar
 bsr AdvanceA0
 bra.s printdec1a 

numbertable
 dc.l 1000000000
 dc.l 100000000
 dc.l 10000000
 dc.l 1000000
 dc.l 100000
 dc.l 10000
 dc.l 1000
 dc.l 100
 dc.l 10
 dc.l 1
 dc.l 0
;----
;---
;ProperPrintDecimald0
;* print d0.l as a decimal number,
;* suppressing leading zeros
; tst.l d0
; bne.s ProperPrintdec1
; move.l #"0",d0
; bra OswrchD0 * WriteChar
;* bra Advancea0
;
;ProperPrintdec1
;* non-zero number to print
; move.l d0,d2 ; store number somewhere more sensible
; lea numbertable-S(a5),a1
; move.b #0,d3 ; reset flag
;ProperPrintdec1a
;* find the current digit value
; move.l (a1)+,d1 ; get value
; beq Printdecret ; no more digits possible
;* given d2=remainder of number, d1=value of current digit,
;* find value
; move.l #"0",d0
;ProperPrintdec2
; sub.l d1,d2
; bcs.s ProperPrintdec3
; addq.b #1,d0
; move.b #1,d3 ; set leading-zeros flag
; bra.s ProperPrintdec2
;ProperPrintdec3
; add.l d1,d2
; tst.b d3 ; flag set yet ?
; beq.s ProperPrintdec1a
; movem.l d0-d7/a0-a6,-(sp)
; bsr OswrchD0 * WriteChar
; movem.l (sp)+,d0-d7/a0-a6
;* bsr AdvanceA0
; bra.s ProperPrintdec1a 
;
;----
;TextArea
; dc.b 'This is a demonstration version of "Hero" - the animated '
; dc.b 'adventure system from Level 9 Computing.    '
; dc.b 'Copyright (C) 1988 Mike Austin.    '
; dc.b 'Release in early 1989.  Previews at Personal Computer show'
; dc.b '.   .   .   .   .   .   ',0
; even
;TextEnd
;TextLength equ TextEnd-TextArea-3
; Note double space at end to avoid hassles with wrap-around
; caused by using character pairs.
;-------
SafebreakPoint
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetMedResolution
 movem.l (sp)+,d0-d7/a0-a6
 dc.w $4afa ; leave in till release
 rts
;--------
SetScreenResolution
* get screen address
 call_ebios _physbase
 addq.l #2,sp
 move.l d0,OSScreenAddress-S(A5)

* what screen resolution are we in ?
 call_ebios _getrez ; move.w #4,-(sp)
 addq.l #2,sp
* d0.b = 0 - low resolution, 1 = medium resolution, 2 = high res
 lea screenresolution-S(a5),a0
 cmp.b #2,d0
 beq.s inithires1
 move.b #0,d0 ; always low res for graphics nowadays
 move.b d0,(a0)
 bra.s SetLowResolution

inithires1
 move.b d0,(a0)
 lea LogicalBase-S(a5),a0
 move.l #$f7ffe,(a0)
 lea PhysicalBase-S(a5),a0
 move.l #$EEFFE,(a0)

SetHighResolution
 move.w #2,-(sp) * high resolution
 move.l #$ef000,-(sp)
 move.l #$ef000,-(sp) ; logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts

;--------
SetLowResolution
* Now set low resolution for use by the game
 move.l OSScreenAddress-S(A5),d0
; now d0.l is start of current screen
 sub.l #8,d0 * allow for trimming of left hand edge
 sub.l #$1000,d0 * allow for overflow on BuildIt
 move.l d0,d1
 sub.l #$9000,d1 * >$8000 because we overflow each screen slightly
* During BuildIt

* d1.l is start of alternate screen

 move.l d1,LogicalBase-S(A5)
 move.l d0,PhysicalBase-S(a5)
 move.w #0,-(sp) ; low resolution
 move.l d0,-(sp)
 move.l d0,-(sp) ; logical base

* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts
;---
;SwapPage
;* If it will be a long time before we can swap,
;* set a flag and do it whilst building the new frame
; move.b ScreenResolution-S(A5),d0
; bne.s ActuallySwapScreen
; bra.s ActuallySwapScreen ******
;
; move.l PhysicalBase-S(a5),d0
; add.l #150*200,d0
; lsr.w #8,d0
; move.b $ff8207,d1
; cmp.b d0,d1
; bge.s ActuallySwapScreen * off screen already, so do it now!
;
; move.l PhysicalBase-S(a5),d0
; add.l #8*160,d0 * get past text line etc.
; lsr.w #8,d0
; move.b $ff8207,d1
; move.l #20000,d2
;
;WaitForOnScreen
; subq.l #1,d2
; bne.s WFOS1
; dc.w $4afa ; leave in until release
;
;WFOS1
; move.b $ff8207,d1
; cmp.b d0,d1
; blt.s WaitForOnScreen
; lea StillNeedToSwapScreen-S(a5),a0
; move.b #1,(a0)
; bra SetWriteAlternate
;;---

WaitForOffScreen
 move.l PhysicalBase-S(a5),d0
 add.l #150*200,d0
 move.l d0,d1
 lsr.l #8,d0 * make d0.b = middle of 24bit address
 and.l #$000000ff,d0
 asl.l #8,d1 * make d0.b(3) = high of 24bit address
 and.l #$00ff0000,d1
 or.l d1,d0
 move.l $ff8204,d1 * read in ff8205,ff8207
 and.l #$00ff00ff,d1
 cmp.l d1,d0
 bne.s WaitForOffScreen
 rts

;
;;WaitForOffScreen
;; move.b $ff8207,d1
;; cmp.b d0,d1
;; blt.s WaitForOffScreen
;; move.w #36,-(sp)
;; trap #14
;; addq.l #2,sp
;
; cmp.l #$f7ff8,(a0)
; beq.s SetLowerPage
; move.l #$f7ff8,(a0)
; rts
;
;SetLowerPage
; move.l #$e7ff8,(a0)
; rts
;-------
SetMedResolution
* Now set medium resolution,
* so OS will print 80 column text correctly
 move.w #1,-(sp) ; medium resolution
 move.l OSScreenAddress-S(A5),-(sp) ; retain physical base
 move.l OSScreenAddress-S(A5),-(sp) ; retail logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts
;-------
MoveScreen
; Change position of physical window onto map if appropriate
 clr.w d6
; move.b PlayerSDS+SpeedOffset,d6 * find step size
 move.b ScrollStep-S(a5),d6
 lea PlayerXpos-S(a5),a0

 move.b DoingPseudoFlip-S(a5),d0
 beq.s MoveScreen2
; in the middle of a pseudo flip
 lea DoingPseudoFlip-S(a5),a1
 subq.b #1,(a1)
 move.b PseudoFlipDirection-S(a5),d0
 beq MoveToRight
 bra MoveToLeft

; Pseudo-flip handlers...

MoveToLeft
; player tried to go off the left hand edge
 lea ScreenXPos-S(a5),a1
 move.w (a1),d0
 sub.w d6,d0
 bmi moveScreenNotLR ; stop moving off screen
 move.w d0,(a1)
 bra MoveScreenNotLR

MoveToRight
; player tried to go off the right hand edge
 lea ScreenXPos-S(a5),a1
 move.w (a1),d0
 add.w d6,d0 * d6
 cmp.w ScreenXMax-S(a5),d0
 bgt moveScreenNotLR
 move.w d0,(a1)
 bra MoveScreenNotLR

; code to detect when a flip is necessary..

MoveScreen2
 move.w PlayerXPos-S(a5),d0
 sub.w ScreenXPos-S(a5),d0
 cmp.w #86,d0 *32,d0
 bgt.s MoveScreenNotLeft
; lea DoingPseudoFlip,a0
; move.b #1,(a0) * 5
; lea PseudoFlipDirection,a0
; move.b #1,(a0)
 bra MoveToLeft * bra MoveScreenNotLR


MoveScreenNotLeft
 cmp.w #160,d0 * 130,d0 * 210,d0
 bls.s MoveScreenNotRight
; lea DoingPseudoFlip,a0
; move.b #1,(a0) * 5
; lea PseudoFlipDirection,a0
; clr.b (a0)
 bra MoveToRight * ; drop through to moveScreenNotLR

MoveScreenNotRight
moveScreenNotLR
 lea ScreenYPos-S(a5),a0
 move.w PlayerYPos-S(a5),d1
 sub.w (a0),d1
 cmp.w #120,d1 * 140,d1
 blt.s MoveScreenNotDown
; player is at the bottom of the screen - so scroll it up

 move.w (a0),d0
 add.w d6,d0 * d6
 cmp.w ScreenYMax-S(a5),d0
 bge.s MoveScreenRet ; MoveScreenNotDown
 move.w d0,(a0) ; add on step size
 rts

MoveScreenNotDown
 cmp.w #60,d1 * #32,d1
 bgt MoveScreenNotUp
; player is moving up the screen - so scroll it down
 move.w (a0),d0
 sub.w d6,d0 ; decrease screen y position * d6
 bmi.s MoveScreenRet ; MoveScreenNotUp
 move.w d0,(a0)

MoveScreenNotUp
MoveScreenRet
 rts
;----
Specials
;; handle cycling colours etc.
; lea FrameCounter-S(a5),a0
; add.l #1,(a0)
;
; lea StarCounter-S(a5),a0
; addq.b #1,(a0)
; move.b (a0),d0
; lsr.b #1,d0
;
; cmp.b #8,d0
; bne.s SpecialNotStar
; clr.b d0
; clr.b (a0)
;
;SpecialNotStar
; cmp.b #4,d0
; blt.s SNS1
; move.b #6,d2
; sub.b d0,d2
; move.b d2,d0
;
;SNS1
;* d0=phase of flashing stars
; lea StarPhase-S(a5),a0
; move.b d0,(a0)
 rts
;-----
;------
SetUpPalette
; move.l PalettePtr,-(sp)
 lea Palette-S(a5),a0
 move.l a0,-(sp)
 move.w #6,-(sp)
 trap #14
 addq.l #6,sp
 rts
;-----
MakeA0Even
 move.l a0,d0
 btst #0,d0
 beq.s MakeA0EvenRet
 addq.l #1,a0
MakeA0EvenRet
 rts
;----
;--------
;DoDelayedFlip
; movem.l d0-d1/a0,-(sp)
; move.b StillNeedToSwapScreen-S(a5),d0
; beq.s DDNoFlip
; move.l LogicalBase-S(a5),d0
; add.l #130*200,d0
; lsr.w #8,d0
;DDWait
; move.b $ff8207,d1
; cmp.b d0,d1
; blt.s DDWait
; bsr SetWriteAlternate * make it display the correct buffer
; bsr ActuallySwapScreen
;DDNoFlip
; movem.l (sp)+,d0-d1/a0
; rts
;--------
 include 'ram.s'



