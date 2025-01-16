* Just build a screen, directly from the block-based form onto the display
*
* Copyright(C) 1987/1988 M.J.Austin Started 26/11/87
*
*
* Question:
* Why does Move.l (a0)+,a1 set z flag differently to TST.L (a0) ?
* ( The former always sets Zero! )

 opt d+
 opt p+
 bra Start
 include 'defns.s'
 include 'stsprite.s'
 include 'joystick.s'
 include 'font.s'
 include 'stcoll.s'

*		Signed	Unsigned
* >=		BGE	BCC
* >		BGT	BHI
* =		BEQ	BEQ
* <>		BNE	BNE
* <=		BLS	BLS
* <		BLT	BCS


Start
 lea Random(PC),a0
 move.l #$c468d134,(a0)

 lea ScrollStep,a0
 move.b #4,(a0)

 lea YFineScroll,a0
 move.l #0,(a0)
 lea DoingPseudoFlip,a0
 clr.b (a0)
 lea ScreenXPos,a0
 move.w #0,(a0)
 lea ScreenYPos,a0
 move.w #32,(a0)

 lea BreakPointArmed,a0
 clr.b (a0)
 lea NumDestroyedWalls,a0
 clr.w (a0)
 lea TimeToNextShot,a0
 clr.b (a0)

 lea ScreenXMax,a0
 move.w #544,(a0) ; (ScreenXBlocks-16)*16
 lea PlayerXMax,a0
 move.w #784,(a0) * 800,(a0) ; (ScreenXBlocks-1)*16
 lea ScreenXBlocks,a0 ; number of blocks e.g. 0..ScreenXBlocks-1
 move.w #50,(a0)

 lea ScreenYMax,a0
 move.w #612,(a0) * (screenYBlocks-11.75)*16
 lea PlayerYMax,a0
 move.w #784,(a0) * (ScreenYBlocks-1)*16

 lea CurrentWeapon,a0
 clr.b (a0)

; set supervisor mode
 clr.l -(sp)
 call_bdos _super
 add.l #6,sp
 lea SupervisorStack,a0
 move.l d0,(a0)

 bsr SetLowResolution

 bsr LoadDataFiles

 bsr SetUpPalette

 bsr InitJoystick

ResetMonsters
 bsr InitSpriteTable

TimeLoop
 bsr MoveScreen
 bsr Specials

 lea HeroStack,sp

 move.l LogicalBase,a0 * screen address (!)
 move.w ScreenYPos,d0
 and.w #$0f,d0 * separate out fine scroll position
 move.w #160,d1
 mulu d1,d0 * calculate offset for fine scroll
 sub.l d0,a0

 lea TempStarPhase,a3
 move.b StarPhase,(a3) * copy across so it can be reset below
* when it is not needed - i.e. when ScrolledLayoutPtr is in use!

* decide which layout ptr to use (depending on state of smooth scroll)
 lea MapLayoutPtr,a2
 move.w ScreenXPos,d0
 and.w #$0f,d0
 beq.s UseLayoutPtrA2
 lea ScrolledLayoutPtr,a2

UseLayoutPtrA2
 move.l (a2),a2 ; a2 is now ptr to map layout

* and decide which map graphics ptr to use
* (depending on state of smooth scroll)
 lea MapGraphicsPtrs,a3
 clr.l d0
 move.w ScreenXPos,d0
 and.w #$0f,d0 * assumes scroll jump is multiple of 4 pels!
 add.l d0,a3 * calculate which ptr to use
 move.l (a3),a3 * get start address of graphics
 lea CurrentMapGraphicsPtr,a1
 move.l a3,(a1)

 move.w ScreenXPos,d0
 lsr.w #3,d0 * convert from pixel count to block count /(320/16)=/16
* but *2 because map is made up of words
 and.w #$fffe,d0 * strip off bit 0
 add.w d0,a2
 move.w ScreenYPos,d0
 lsr.w #3,d0 * convert to number of blocks
* but *2 because map is made up of words
 and.w #$fffe,d0 * strip off bit 0
 move.w ScreenXBlocks,d1
 mulu d1,d0 * convert to offset in map table
 add.l d0,a2

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
 move.b TempStarPhase,d1
 add.w d1,d0

BlockLineNotSpecial
* each block is 16x16 in 16 colours - i.e. 16x16/2=128 bytes
 asl.w #7,d0 * multiply by 128 to get index
 move.l CurrentMapGraphicsPtr(PC),a1
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
 add.w ScreenXBlocks,a2
 add.w ScreenXBlocks,a2 * because map is word-based

 movem.l d0-d1/a0,-(sp)
  move.b StillNeedToSwapScreen,d0
  beq.s NoFlip
  move.l LogicalBase,d0
  add.l #130*200,d0
  lsr.w #8,d0
  move.b $ff8207,d1
  cmp.b d0,d1
  blt.s NoFlip
  bsr SetWriteAlternate * make it display the correct buffer
  bsr ActuallySwapScreen
NoFlip
 movem.l (sp)+,d0-d1/a0
 dbra d3,BlockRowLoop

; Now overlay other stuff on top of the background
 bsr DisplayDestroyedWalls
 move.l Player1SpriteBlock,a6 *****
 bsr DisplayAllSprites
 bsr TrimEdges
 bsr DisplayTextLine
 bsr DisplayUpperTextLine
 bsr DoAllTimers
 bsr DisplayMemoryFree
 bsr DisplayHitPoints
 bsr DisplayFreeSprites
 bsr DisplayFrameTime
 movem.l d0-d7/a0-a6,-(sp)
  bsr SwapPage ; display it all.
 movem.l (sp)+,d0-d7/a0-a6

 bsr AbsGetCharFromBdos
 tst.b d0
 beq.s NoKeyPress
 bsr HandleKeyPress

NoKeyPress
; Is (are) player(s) still alive?
 move.l Player1SpriteBlock,a6
 move.w NameOffset(a6),d0
 cmp.w #0,d0
 bne.s Player1Dead
 tst.l (a6)
 beq.s Player1Dead
 move.w hitPointOffset(a6),d0
 bne.s Player1Alive
Player1Dead
 dc.w $4afa
 bra TimeLoop

Player1Alive
NoKeyPress1
 bsr GetPlayerInput
 bra TimeLoop
;-------
DoAllTimers
* do all special case timers
 lea TimeToNextShot,a0
 tst.b (a0)
 beq.s DATRet
 subq.b #1,(a0)
DATRet
 rts
;-------
TrimEdges
* blat out the edges of the screen - to make
* the sprite display etc. at the sides easier

* copy in the border area from the alternate (currently displayed)
* area to preserve the border information
 move.l LogicalBase,a0
 move.l AlternateLogicalBase,a1
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
 rts
;-------
GetPlayerInput
AbsGetPlayerInput
; Get input from user
 move.l Player1SpriteBlock,a6
 move.b PlayerSDS+SpeedOffset,d6
 move.b JoystickStatus,d7

 clr.w d4 * x offset requested by player
 clr.w d5 * y offset requested by player
 
 btst #LeftBit,d7
 beq.s NotLeft
; move.w PlayerXPos,d0
 move.w XPosOffset(a6),d0
 sub.w d6,d0
 bmi NotLeft ; Prevent Move if off screen
 clr.w d4
 sub.w d6,d4 * negative step size in x offset

NotLeft
 btst #RightBit,d7
 beq.s NotRight
; move.w PlayerXPos,d0
 move.w XPosOffset(a6),d0
 add.w d6,d0
 cmp.w PlayerXMax,d0
 bge NotRight
 move.w d6,d4 * set x offset to step size

NotRight
 btst #UpBit,d7
 beq.s NotUp
; move.w PlayerYPos,d0
 move.w YPosOffset(a6),d0
 sub.w d6,d0
 bmi NotUp
 clr.w d5
 sub.w d6,d5 * set y offset to negative step size

NotUp
 btst #DownBit,d7
 beq.s NotDown
; move.w PlayerYPos,d0
 move.w YPosOffset(a6),d0
 add.w d6,d0
 cmp.w PlayerYMax,d0
 bge NotDown
 move.w d6,d5 * set y offset to negative step size

NotDown
* store desire for later movement
 move.l MapLayoutPtr,a0
 bsr CheckPlayerMove
* now d4.w=x speed and d5.w=speed requested by player + possible
 lea FireButtonHeld,a0
 move.b JoystickStatus,d7
 btst #FireButton,d7
 bne MaybeFireMissile
* the fire button has been released - 
 clr.b (a0) * allow another shot to be fired
 move.l MapLayoutPtr,a0
 bsr CPMFinishMove * update speed pointers+do animation
 rts * bra TimeLoop * can't fire whilst moving

MaybeFireMissile
 tst.b (a0) * has fire button been held down?
 beq.s FireMissile
 subq.b #1,(a0) * decrement repeat count
 rts

FireMissile
 move.b #4,(a0) * restrict rate of fire

* where is the sprite control block for this player?
 move.l Player1SpriteBlock,a6

; Initiate Fire
 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 add.w #4,d1 * overlap allowed for head
 clr.l d2
 move.b ViewOffset(a6),d2

 asl.w #2,d2 * 2 words per entry
 lea ViewToXYConversionTable,a0
 add.l d2,a0
 move.w (a0)+,d2 * d2:=x speed
 move.w #12,d4
 mulu d4,d2 * missiles go at 12 pel/step
 move.w (a0)+,d3 * d3:=y speed
 mulu d4,d3 * missiles go at 12 pel/step

 move.b CurrentWeapon,d6
 move.w #9,d4 * sprite number for digging missile
 cmp.b #1,d6
 beq.s FM1
 move.w #8,d4 * sprite for explosive weapon
 cmp.b #2,d6
 beq.s FM1 
 move.w #1,d4 * sprite number for non-explosive missile

FM1
 lea Random,a0
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
InitSpriteTable
 Lea DoYRangeKill,a0
 clr.b (a0)

 lea SpriteTable,a0
 lea SpriteTPtr,a1
 move.l a0,(a1)
 move.w #MaxMovingSprites,d5 * max size of table
IST1
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 dbra d5,IST1

* and set up 1 player sprite....

 move.w #200,d1 * initial player y pos
 clr.w d2 * x speed
 clr.w d3 * y speed
 move.w #0,d4 * player-type
 move.w #128,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 lea Player1SpriteBlock,a1
 move.l a0,(a1)
 movem.l (sp)+,d0-d7/a0-a6

* and set up 25 monster sprites....
 move.w #2,d4

 move.w #236,d1 * initial player y pos
IST2
 move.w #164,d0 * top left x pos of grid of monsters
IST3
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6
 add.w #16,d0 * x pos
 cmp.w #244,d0
 ble.s IST3
 sub.w #16,d1

* alternate between sprites 2/4 on alternate lines
; move.w d4,d0
; move.w #9,d4
; sub.w d0,d4

 cmp.w #164,d1
 bgt.s IST2

* and set up a monster below the player
 move.w #120,d1 * initial player y pos+16
 move.w #128,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

 move.w #300,d0
 move.w #120,d1
 move.w #10,d4 * a bottle 
 bsr SetUpNewSprite

 move.w #320,d0
 move.w #120,d1
 move.w #10,d4 * a bottle 
 bsr SetUpNewSprite

 move.w #340,d0
 move.w #120,d1
 move.w #10,d4 * a bottle 
 bsr SetUpNewSprite

 move.w #332,d0
 move.w #154,d1
 move.w #11,d4 * invisible object
 bsr SetUpNewSprite

 rts
;----
SetUpNewSprite
* d0,d1=initial x,y position. d2,d3 are x,y speed d4.w is sprite number
* (i.e. which entry in fixed sprite table is to be used)
* returns a0.l as pointer to temp sprite table

 lea SpriteTable,a0
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
 lea TempNameStorage,a3
 move.w d4,(a3)
 lea SpriteDataStructure,a3
 move.w #SDSSize,d6 * size of fixed sprite information
 mulu d6,d4 * get offset of sprite structure
 add.l d4,a3 * a3.l is fixed sprite information

* decide where to put the sprite in the chain
* Items of low priority are displayed first (and therefore
* stored first in the linked list). Items of same priority are
* sorted according to y position.
 move.l SpriteTPtr,a1
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
 lea SpriteTPtr-NextPtrOffset,a2 * new start of linked list
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
 move.l SpriteDataPtr,a1
 mulu #20*10,d4
 add.l d4,a1
 move.l a1,DataPtrOffset(a0) * write to storage for use by cd etc.

 move.w TempNameStorage,NameOffset(a0) * set up default 'name'
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
 lea SpriteDataStructure,a3
 move.w #SDSSize,d6 * size of fixed sprite information
 mulu d6,d4 * get offset of sprite structure
 add.l d4,a3 * a0.l is sprite data
 clr.l NextPtrOffset(a0) * set up ptr to next entry
 clr.l LastPtrOffset(a0) * LastPtrOffset
 bra SUNS3
;-------
DAMSSpecials
* now do special cases for particular types of monsters...
 move.b TypeOffset(a5),d0
 bpl.s NotSI
 move.w SIXspeed,d2
 move.w SIYSpeed,d3

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
 dc.w $4afa
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
 sub.w PlayerXPos,d2 * actually wrong way round, hence inverted logic
 beq.s aMonsNoHoriz
 bmi.s aMonsRight
* handle vertical decision for moving towards the left
 sub.w PlayerYPos,d3
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
 sub.w PlayerYPos,d3
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
 sub.w PlayerYPos,d3
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
 lea ViewToXYConversionTable,a0
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
GotDecisionRet
 rts

DAMSNotPlayer
DAMSAnimate
* animate all monsters (except the player which is handled
* only when it is walking)

 move.b StageOffset-8(a6),d4
 add.b #1,d4
 cmp.b NumAnimationOffset(a5),d4
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
 cmp.w PlayerYMax,d1 * off the map!
 bcc.s BGNoWallToDestroy
 cmp.w PlayerXMax,d0 * off the map!
 bcc.s BGNoWallToDestroy
  movem.w d0-d1,-(sp)
* now d0,d1 is position on grid
* calculate the position in the map
  asr.w #3,d0 * divide by 16, multiply by 2. Lowest bit is already 0
  asr.w #3,d1 * ""     ""  "     ""            ""        ""   ""
  mulu ScreenXBlocks,d1 * also extends d1 to .l so we add to a0.l below
  add.w d0,d1 * use .w because this will always be adequate
  move.l MapLayoutPtr,a0 * unscrolled version of course
  add.l d1,a0
  movem.w (sp)+,d0-d1

 tst.w (a0)
 beq.s BGNoWallToDestroy
 clr.w (a0)

 bsr AddDestroyedWall * set up masking sprite
BGNoWallToDestroy
 rts
;------
CheckForSpriteCollision
* collision with other sprites?
 tst.w d2
 bne.s CFSC1
 tst.w d3
 bne CFSC1
* no movement
 cmp.w #0,NameOffset(a6)
 bne CFSCRet * no movement - don't bother checking
* for player - always check

CFSC1
  bsr CDWithAllSprites
  bne NoSpriteCollision * collision with another sprite?
* yes - we collided with sprite having control block (a0.l)
 move.l (a0),a1 * sprite fixed data block

* should the sprite we just moved be destroyed?
  move.b CDDestroyedOffset(a5),d5
  and.b TypeOffset(a1),d5 * the sprite we collided with.
  beq.s NoDestroy1
* yup.
* first do an accurate check. This is mainly for the benefit
* of fast-moving missiles etc.
 movem.l a0-a6,-(sp)
  bsr SpecialCheck
 movem.l (sp)+,a0-a6
 tst.b d0
 bne CFSCRet * no collision

* kill the sprite just moved
 movem.l a0-a1,-(sp)
  move.l a6,a0
  bsr destroySprite
 movem.l (sp)+,a0-a1

NoDestroy1
* should the sprite we collided with be destroyed?
 move.b CDDestroyedOffset(a1),d5
 and.b TypeOffset(a5),d5
 beq.s NoDestroy2
* yup.
 movem.l a0-a1,-(sp)
  bsr DestroySprite * kill sprite we collided with
 movem.l (sp)+,a0-a1

NoDestroy2

* activate any specials for the sprite we collided with?
 move.b CDSpecialsOffset(a1),d5
 and.b TypeOffset(a5),d5
 beq.s NoSpecials1
* yes.
 exg a0,a6 * swap over so we act on the right sprite.
 exg a1,a5
 bsr FGSpecials
 exg a0,a6 * and restore them.
 exg a1,a5

NoSpecials1
* activate any specials for the sprite we just moved?
 move.b CDSpecialsOffset(a5),d5
 and.b TypeOffset(a1),d5
 beq.s NoSpecials2
 bsr FGSpecials
 bsr FGSpecialsForMovedSpriteOnly

NoSpecials2

* should the sprite we just moved be blocked?
 move.b CDBlockedOffset(a5),d5
 and.b TypeOffset(a1),d5
 beq.s NoSpriteCollision
* reset co-ords
 move.w XPosSave,d0
 move.w d0,XPosOffset(a6)
 move.w YPosSave,d1
 move.w d1,YPosOffset(a6)
 clr.w d2 * clear x speed
 clr.w d3 * clear y speed to avoid unnecessary sorting
 bra FGSpriteCantMove

NoSpriteCollision
* sprite can move ok - add to distance travelled, and
* if AddDirOffset is set, eventually stop moving in that direction
 lea DistanceOffset(a6),a0
 addq.b #1,(a0)
 move.b AddDirOffset(a6),d4
 beq.s NSCRet
 move.b DistanceOffset(a6),d4
 cmp.b #9,d4 * max distance monster can move in a direction
* not directly towards the player without reconsidering.

 blt.s NSCRet
 lea AddDirOffset(a6),a0
 clr.b (a0) * try moving in desired direction again
; bra SpriteCantMove * change direction

NSCRet
CFSCRet
 rts ; display normally

;FGExplode
;
; movem.l a0-a6,-(sp)
; move.l (a0),a1
;  bsr SpecialCheck
; movem.l (sp)+,a0-a6
; tst.b d0
; bne.s NSCRet * no collision
;
;* now replace the sprite we ran into with an explosion
;  bsr HandleFGExplosion
;* kill the sprite just moved
; move.l a6,a0
; bra destroySprite
;-----
FGSpriteCantMove
; sprite (a6) was blocked from moving in the direction it intended to
; Change the direction of moving
; Unless it is fighting the player
; What was the sprite we were blocked by?
 move.l (a0),a1
 move.b TypeOffset(a1),d4
 cmp.b #1,d4 * Player type
 beq.s SCMRet

; move.b InCombatOffset(a6),d4
; bne.s SCMRet

BGSpriteCantMove
; Unless it is really close to the player
; move.w XPosOffset(a6),d4
; sub.w PlayerXPos,d4
; bpl.s SCM1
; neg.w d4
;
;SCM1
; move.w YPosOffset(a6),d5
; sub.w PlayerYPos,d5
; bpl.s SCM2
; neg.w d5
;
;SCM2
;* d4,d5 are x,y distances from player
; add.w d5,d4
; cmp.w #49,d4
; ble.s SCMNearby
;
 clr.w d4
 move.b AddDirOffset(a6),d4
 ext.w d4
 lea NextAddDirTable,a0
 move.b 0(a0,d4),d4
 lea AddDirOffset(a6),a0
 move.b d4,(a0)
 clr.b DistanceOffset(a6)
SCMRet
 rts
;----
;SCMNearby
;* this sprite is close to the player - don't ever go away from it!
; clr.w d4
; move.b AddDirOffset(a6),d4
; ext.w d4
; lea NearbyAddDirTable,a0
; move.b 0(a0,d4),d4
; lea AddDirOffset(a6),a0
; move.b d4,(a0)
; clr.b DistanceOffset(a6)
; rts
;-----
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
 move.b HeightOffset(a5),d6 * offset of bottom row
 move.l MapLayoutPtr,a0
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

 move.b CDFlagsOffset(a5),d5
 btst #CDWithBG,d5
 beq NoBGCollision

* sprite collided with the background - should it actually
* be destroyed, or just be prevented from moving?
 move.b CDDestroyedOffset(a5),d5
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
 move.b CDSpecialsOffset(a5),d5
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
 move.b CDBlockedOffset(a5),d5
 btst #CDWithBG,d5
 beq.s NoBGCollision * not blocked

* reset co-ords
 move.w XPosSave,d0
 move.w d0,XPosOffset(a6)
 move.w YPosSave,d1
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
* a6.l,a5.l and a0.l,a1.l have just collided.
* a6.l had the appropriate special flag set.
* does it want to do anything special?
* a0-a6 should be preserved, data registers may be destroyed.
* REMEMBER - we can also use NAMEOFFSET(A6) (Yes - a6)
 move.b TypeOffset(a5),d5 * player?
 cmp.b #1,d5
 bne.s FGS1NotPlayer
* player ran into something else. A trap perhaps?
 cmp.w #11,NameOffset(a0)
 bne.s FGS1NotPlayerTrap

 lea TimeToNextShot(pc),a2
 subq.b #1,(a2)
 bpl.s FGS1NotPlayer * not ready to fire again yet
 move.b #60,(a2) * reset timer - about 2 seconds to next shot

; sub.w #1,HitPointOffset(a6)
* fire some missiles from the cunningly concealed guns...
 movem.l d0-d7/a0-a6,-(sp)
  move.w #320,d0
  move.w #92,d1
  move.w #12,d4 * monster missile
  move.w #0,d2
  move.w #8,d3 * y speed
  bsr SetUpNewSprite

  move.w #336,d0
  move.w #92,d1
  move.w #12,d4 * monster missile
  move.w #0,d2
  move.w #8,d3 * y speed
  bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

 rts

FGS1NotPlayerTrap
FGS1NotPlayer
 rts
;-------
LandABlow
 subq.b #1,TimeToNextBlowOffset(a6)
; move.b TimeToNextBlowOffset(a6),d0
; cmp.b TimeBetweenBlowsOffset(a5),d0
 bpl.s FGSFighting1
 move.b TimeBetweenBlowsOffset(a5),TimeToNextBlowOffset(a6)
* do damage to (a0,a1)
 move.w BlowStrengthOffset(a6),d0
 bsr DoDamageD0

FGSFighting1
 rts
;-----
FGSpecialsForMovedSpriteOnly
* as above, but a6.l is guaranteed to have been the sprite that
* tried to move, and  a0.l is what it ran into.

 move.b TypeOffset(a5),d5
* player?
 cmp.b #1,d5
 bne.s FGSNotPlayer
* trying to fight?
 move.b TypeOffset(a1),d0
 btst #2,d0 * monster?
 beq.s FGSNotPlayerFight
FGSFighting
* time for another blow to land yet?
 bsr LandABlow
* add on the fighting animation offset
 move.l DataPtrOffset(a6),d0
 clr.l d1
 move.w FightAnimationOffset(a5),d1
 ext.l d1
 add.l d1,d0
 move.l d0,DataPtrOffset(a6)
 rts

FGSNotPlayerFight
;* player ran into something else. A trap perhaps?
; move.b TypeOffset(a1),d0
; btst #CDWithInvisibles,d0
; beq.s FGSNotPlayerTrap
; sub.w #1,HitPointOffset(a6)
; rts
;
;FGSNotPlayerTrap
FGSNotPlayer
* monster?
 btst #CDWithMonsters,d5
 beq.s FGSNotMonster
* trying to fight?
 move.b TypeOffset(a1),d0
 btst #0,d0 * player?
 bne.s FGSFighting

FGSNotMonster
 move.b TypeOffset(a5),d5 * what requested the special?
* missile?
 btst #CDWithMissiles,d5
 beq.s FGSNotMissile

* do some damage
 bsr breakIfArmed *****
 bsr LandABlow

* for missiles, an explosion is also started where the OTHER sprite was.
 tst.l (a0)
 beq.s FGSNotMissile * the target was destroyed, so DODAMAGE
* will already have started the relevant explosion
 movem.l a0-a6,-(sp)
  bsr HandleFGExplosion
 movem.l (sp)+,a0-a6
 rts

FGSNotMissile
 rts
;-------
DoDamageD0
* subtract D0.W hit points from sprite (a0.l,a1.l)
 move.w HitPointOffset(a0),d1 *******
 sub.w d0,HitPointOffset(a0)
 beq.s DoDamageDestroy * zero hit points left
 bmi.s DoDamageDestroy
 rts

DoDamageDestroy
 clr.w HitPointOffset(a0)
 tst.l (a0)
 beq.s DDDRet
 movem.l d0-d7/a0-a6,-(sp)
  bsr DestroySprite
  bsr HandleFGExplosion
 movem.l (sp)+,d0-d7/a0-a6
DDDRet
 rts
;-------
BGSpecials
* a6.l,a5.l has just collided with a chunk of background
 move.b TypeOffset(a5),d5
 btst #CDWithMissiles,d5
 beq.s BGNotMissile
 movem.l d0-d7/a0-a6,-(sp)
  move.w NameOffset(a6),d4
  cmp.w #9,d4 * bg destructive?
  bne BGExplode1
  clr.w NameOffset(a6) * prevent it exploding again (No,
* I don't know why this is necessary either - Mike)
  move.w NumDestroyedWalls,d2
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
 move.b HeadOverlapOffset(a5),d2
 add.w d2,d1
 and.w #$fff0,d0
 and.w #$fff0,d1
* d0,d1 is now the co-ordinates of the block (a0)
* We collided with either 0(a0,d6) or 2(a0,d6)
FindBlock1
 tst.w d6
 beq.s FindBlock2
 add.w #16,d1 * add one 16x16 block's worth to y coordinate
 sub.w ScreenXBlocks,d6
 sub.w ScreenXBlocks,d6
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
DisplayAllSprites
; Display and move the sprites in the moving sprite table
 lea SpriteTable,a6 * a6 remains as pointer to sprite table
 lea DAMSLoopCounter,a0
 move.w #MaxMovingSprites+1,(a0)

DAMS1
 tst.l (a6) * sprite number zero?
 beq DAMSNextSprite
 move.l (a6)+,a5 * address of sprite structure
 move.w (a6)+,d2 * x speed
 move.w (a6)+,d3 * y speed

 bsr DAMSSpecials
 tst.l -8(a6) ****
 bne DAMSNotDestroyed *****
 sub.l #8,a6
 bra DAMSNextSprite

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
; move.w MovingAnimationOffset(a5,d0),d4 * get base sprite number for view
; add.b StageOffset-8(a6),d4 * add on animation stage

* calc address of sprite data
 clr.w d4
 move.b ViewOffset-8(a6),d4
 bmi.s DAMSNextSprite * an invisible sprite
 asl.w #1,d4 * double to get index into word-wise table
 move.w MovingAnimationOffset(a5,d4),d4 * get base sprite number for view
 add.b StageOffset-8(a6),d4 * add on animation stage
 move.l SpriteDataPtr,a0
 mulu #20*10,d4
 add.l d4,a0
 move.l a0,DataPtrOffset-8(a6) * write to storage for use by cd,
* display etc.

* load co-ordinates and move sprite
 move.w (a6),d0 * x pos
 lea XPosSave,a0 ***
 move.w d0,(a0) ***
 add.w d2,d0
 move.w d0,(a6)+
 move.w (a6),d1 * y pos
 move.w d1,2(a0) ******* save y position
 bmi.s SelfDestruct2 * prevent missiles wrapping round.
 add.w d3,d1
 move.w d1,(a6)
 sub.l #10,a6 * back to start of control block
;
 cmp.w PlayerXMax,d0
 bcc KillSprite
 cmp.w PlayerYMax,d0
 bcc KillSprite

 bsr CheckForBackgroundCollision
 tst.l (a6)
 beq DAMSNextSprite

 bsr CheckForSpriteCollision
 tst.l (a6)
 beq DAMSNextSprite

 move.b DoYRangeKill,d6
 beq.s NoRangeKill
* kill off-screen sprites for space invaders
 sub.w ScreenYPos,d1
 cmp.w #230,d1 * special to SI
 bcc KillSprite * special to SI - kill missiles which go off screen

NoRangeKill
 bsr ConsiderMovingSprite

DAMSNextSprite
 add.l #SpriteCurrentSize,a6
 lea DAMSLoopCounter,a0
 subq.w #1,(a0)
 bne DAMS1 * limit length of loop



; Now Display all the sprites
 move.l SpriteTPtr,a6
 move.w #MaxMovingSprites,d7
DAS1
 tst.l (a6) * sprite number zero?
 beq DASNextSprite

 move.l (a6),a5 * address of sprite structure
 cmp.b #$20,TypeOffset(a5)
 beq.s DASNextSprite * an invisible sprite
* calc address of sprite data
 move.l DataPtrOffset(a6),a3 * address of bit pattern to use

 move.w XPosOffset(a6),d0
 move.w YPosOffset(a6),d1
 sub.w ScreenXPos,d0
 sub.w ScreenYPos,d1
 move.l LogicalBase,a2
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
 lea FreeSprites,a0
 move.w d7,(a0)
 rts
;----

ConsiderMovingSprite
* sprite (a0) has moved in direction d3.w
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
 lea SpriteTPtr,a3
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
 lea SpriteTPtr,a1
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
 lea SpriteTPtr,a3
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
 lea SpriteTPtr,a3
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
; cmp.w YPosOffset(a5),d1
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
;; bsr SafeBreakpoint ;  dc.w $4afa
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
DestroySprite
* remove the sprite whose controll block is (a0.l)
 move.l LastPtrOffset(a0),a1
 move.l NextPtrOffset(a0),a2
 move.l a1,d0 * first sprite in chain?
 bne.s DS1
 lea SpriteTPtr,a1 * link it up start of linked list
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
HandleFGExplosion
* a0.l is the control block of the sprite that (a6.l) collided with
 move.w XPosOffset(a0),d0 * x pos
 move.w YPosOffset(a0),d1 * y pos
 move.b TypeOffset(a5),d4
 cmp.b #$22,d4 * explosive missile type
 beq.s StartBigExplosion

 clr.w d2 * x speed
 clr.w d3 * y speed
 move.w #3,d4 * sprite no. for explosion
 bsr SetupNewSprite
 tst.w d7
 bmi.s HFERet * couldn't set up sprite
 move.b #8,LifeCounterOffset(a0) * self-destructs after 8 steps
HFERet
 rts
;-------
StartBigExplosion
 lea BigExplosionTable,a0
SBELoop
 move.w (a0)+,d2
 bne.s SBE1
 move.w (a0)+,d3
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
 move.l DestroyedWallPtr,a0
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
 lea NumDestroyedWalls,a0
 addq.w #1,(a0)

DDWRet
 rts
;----
DisplayDestroyedWalls
 move.w ScreenXPos,d0
 and.w #$000f,d0 * assumes scroll steps of 4!
* d0.w is amount screen is scrolled by
* find masks to use for each destroyed wall
 lea HiDDWLeftTable,a0
 move.l 0(a0,d0),d2 * assumes horizontal scroll steps of 4
 lea LoDDWLeftTable,a0
 move.l 0(a0,d0),d4

 lea HiDDWRightTable,a0
 move.l 0(a0,d0),d3 * assumes horizontal scroll steps of 4
 lea LoDDWRightTable,a0
 move.l 0(a0,d0),d5 * assumes horizontal scroll steps of 4


* now d2d4.64,d3d4.64 are masks to remove each wall

 move.l DestroyedWallPtr,a0
 bra.s DDW1

DDWAdd2
 add.l #2,a0

DDW1
 move.w (a0)+,d0
 beq.s DDWRet
 sub.w ScreenXPos,d0
 cmp.w #ScreenXSize,d0
 bcc DDWAdd2
 and.w #$fff0,d0 * align displayed x pos with screen

 move.w (a0)+,d1
 sub.w ScreenYPos,d1
 cmp.w #ScreenYSize,d1
 bcc.s DDW1 * next sprite
* calculate address on screen
 mulu #160,d1
 asr.w #1,d0
 add.w d0,d1
 move.l LogicalBase,a1
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
  move.b HeightOffset(a5),d6 * offset of bottom row
  move.l MapLayoutPtr,a0
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
 move.b TypeOffset(a5),d4
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

 move.b TypeOffset(a5),d6
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
  move.b HeightOffset(a5),d6 * height
  move.l MapLayoutPtr,a0
;  add.w #4,d1 * add on overlap for sprite
  bsr MapCheck
 movem.l (sp)+,d0-d1
 bne.s MCVertOk

 movem.l d0-d1,-(sp)
  sub.w d3,d1 * remove vertical move
  move.b HeightOffset(a5),d6 * height
  move.l MapLayoutPtr,a0
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
HandleKeyPress
; Key D0.B has been pressed
 cmp.b #'t',d0
 bne.s HKPNotArm
 lea BreakpointArmed,a0
 move.b #1,(a0)

HKPNotArm
 cmp.b #'(',d0
 beq SiResetMonsters
 cmp.b #')',d0
 beq ResetMonsters
 cmp.b #'*',d0
 bne.s HKPNoBreak
 dc.w $4afa
 rts

HKPNoBreak
 cmp.b #'p',d0
 bne.s HKPNoPause
HKPPause
 bsr AbsGetCharFromBdos
 tst.b d0
 beq.s HKPPause
 rts

HKPNoPause
 cmp.b #'f',d0
 bne.s HKPNoFire
 bra FireMissile

HKPNoFire
 cmp.b #'1',d0
 bcs.s NoChangeSpeed
 cmp.b #'9',d0
 bgt.s NoChangeSpeed
 sub.b #'0',d0
 lea PlayerStepSize,a0
 move.b d0,(a0)
 lea ScrollStep,a0
 and.b #$fc,d0 * scroll only in steps of 4
 cmp.b #4,d0
 bge.s ChangeSpeed1
 move.b #4,d0
ChangeSpeed1
 move.b d0,(a0)
 rts

NoChangeSpeed
 cmp.b #'a',d0
 blt.s NoChangeWeapon
 cmp.b #'c',d0
 bgt.s NoChangeWeapon
 sub.b #'a',d0
 lea CurrentWeapon,a0
 move.b d0,(a0)
 rts

NoChangeWeapon
 cmp.b #'R',d0
 beq ResetMonsters
 cmp.b #'r',d0
 beq ResetMonsters


 cmp.b #32,d0
 beq CloseDown
 RTS

CloseDown
 bsr CloseDownJoystick
 move.l SupervisorStack,-(sp)
 move.w #$20,-(sp) * code for _super
 trap #1
 add.l #6,sp

 bsr SetMedResolution
 bsr ReturnToGem
 dc.w $4afa
;-----
DisplayUpperTextLine
; clear text area...
 move.l LogicalBase,a0
; add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area
 move.w #160*12/16-1,d1 * clear 12 pel lines.
 move.l #0,d0
DUTL0
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 dbra d1,DUTL0

 rts
;---
DisplayTextLine
; clear text area...
 move.l LogicalBase,a0
 add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area
 move.w #160*10/16,d1
 move.l #0,d0
DTL0
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 dbra d1,DTL0

; On Alternate frames, increment text pointer
; On other frame, leave pointer where it is and do a 4-pel scroll
; on the text to make it smoother
 lea TextSmoothScroll,a0
 addq.b #1,(a0)
 move.b (a0),d0
 and.b #3,d0
 beq.s IncrementTextPtr
 lea TextOffset,a0
 clr.l d0
 move.w (a0),d0
 bsr DTL * Display text line
* and scroll it.
 move.l LogicalBase,a0
 add.l #(200-8)*160+8,a0 * +8 to correspond with physical screen

 move.b TextSmoothScroll,d0
 and.w #3,d0
 asl.w #1,d0

* scroll first word separately
 move.w (a0),d1
 asl.w d0,d1
 move.w d1,(a0)
* (on subsequent screen lines, it is done by the last operation of the
* previous line)

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
IncrementTextPtr
; increment ptr to text message
 lea TextOffset,a0
 clr.l d0
 move.w (a0),d0
 add.w #1,d0

DTL
 cmp.w #TextLength,d0
 bls.s DTL1
 clr.w d0

DTL1
 move.w d0,(a0)
 lea TextArea,a0
 add.l d0,a0
; Copy 40 Chars from Circular buffer at TextArea to TextBuffer
; Are there enough chars left before end of cicular buffer?
 move.w #TextLength,d7 ; total size of buffer
 sub.w d0,d7 ; d0.w:=number of chars remaining
; Limit d7.w to 40 chars max
 cmp.w #40,d7
 ble.s DTL1a
 move.w #40,d7
DTL1a
; Copy d7 chars into TextBuffer for starters
 move.w d7,d6 * save d7
 lea TextBuffer,a1
DTL2
 move.b (a0)+,(a1)+
 dbra d7,DTL2

; Now copy 40-d6 chars into TextBuffer from the start of the string
 lea TextArea,a0
 move.w #40,d7
 sub.w d6,d7 * d6.w is number of chars already copied
 bmi.s DTL4 * just in case it wraps round!
DTL3
 move.b (a0)+,(a1)+
 dbra d7,DTL3
DTL4
 move.l LogicalBase,a0
 add.l #(200-8)*160+8,a0 +8 to correspond with physical screen

 lea TextBuffer,a1
;
 move.w #19,d7
DisplayD7CharPairs
; Display D7.w characters at screen address a0.l
; from Text string at (a1.l)
; calc address in font
 clr.l d0
 move.b (a1)+,d0
 bsr WriteChar
 add.l #1,a0 ; write to odd addresses
 clr.l d0
 move.b (a1)+,d0
 bsr WriteChar
 add.l #7,a0 ; next address to write to
 dbra d7,displayD7CharPairs
 rts
;---
WriteChar
* display char with ascii code d0 at position (a0.l) on screen
 sub.b #32,d0
 asl.w #3,d0
 lea FontSpace,a2
 add.l d0,a2
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
;---
AdvanceA0
 move.w a0,d0
 btst #0,d0
 beq.s Advance1
 addq.l #7,a0
 rts

Advance1
 addq.l #1,a0
 rts
;----
DisplayHitPoints
 move.l LogicalBase,a0
 add.l #(200-48)*160+136,a0
* and blank out the digits which may possibly be printed
 move.l a0,-(sp)
  bsr PrintSpace
  bsr PrintSpace
  bsr PrintSpace
  bsr PrintSpace
 move.l (sp)+,a0
 clr.l d0
 lea SpriteTable,a1
 move.w HitPointOffset(a1),d0
 bra PrintDecimald0 * bsr, rts
;---
DisplayMemoryFree
 move.l LogicalBase,d0
 cmp.l AlternateLogicalBase,d0
 blt.s DMF1
 move.l AlternateLogicalBase,d0
DMF1
 sub.l HiUsedMemory,d0
 move.l LogicalBase,a0
 add.l #(200-40)*160+136,a0
* and blank out the digits which may possibly be printed
 movem.l d0/a0,-(sp)
  bsr PrintSpace
  bsr PrintSpace
  bsr PrintSpace
  bsr PrintSpace
 movem.l (sp)+,d0/a0
 bra PrintDecimald0 * bsr, rts

;----
PrintSpace
 move.w #32,d0
 bsr WriteChar
 bra AdvanceA0 * bsr,rts
;---
DisplayFreeSprites
 clr.l d0
 move.w FreeSprites,d0

 move.l LogicalBase,a0
 add.l #(200-32)*160+136,a0
 movem.l d0/a0,-(sp)
* and blank out the digits which may possibly be printed
  bsr PrintSpace
  bsr PrintSpace
 movem.l (sp)+,d0/a0

 bra PrintDecimald0 * bsr, rts
;---
DisplayFrameTime
 lea LastTime,a0
 move.l $4ba,d0 * 200 Hz Timer
 move.l (a0),d1
; move.l d0,(a0) * update last frame time
 sub.l d1,d0
* d0.l is time in 5 ms increments
 mulu #5,d0 * convert to ms

 move.l LogicalBase,a0
 add.l #(200-24)*160+136,a0
 movem.l d0/a0,-(sp)
 bsr AdvanceA0 * first 2 chars are always printed
 bsr AdvanceA0
* and blank out the digits which may possibly be printed
 bsr PrintSpace
 bsr PrintSpace
 bsr PrintSpace
 bsr PrintSpace
 movem.l (sp)+,d0/a0

 bsr PrintDecimald0


* now restrict speed to 80 ms
DFTDelay
 lea LastTime,a0
 move.l $4ba,d0 * 200 Hz Timer
 move.l (a0),d1
; move.l d0,(a0) * update last frame time
 sub.l d1,d0
* d0.l is time in 5 ms increments
 mulu #5,d0 * convert to ms
 cmp.l #80,d0
 blt.s DFTDelay
 move.l $4ba,(a0) * update last frame time


PrintDecRet
 rts
;---
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
 lea numbertable(pc),a1
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
TextArea
 dc.b 'This is a demonstration version of "Hero" - the animated '
 dc.b 'adventure system from Level 9 Computing.    '
 dc.b 'Copyright (C) 1987 Mike Austin.    '
 dc.b 'Release in Autumn 1988.  Previews at June CES show'
 dc.b '.   .   .   .   .   .   ',0
 even
TextEnd
TextLength equ TextEnd-TextArea-3
; Note double space at end to avoid hassles with wrap-around
; caused by using character pairs.
;-------
SafebreakPoint
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetMedResolution
 movem.l (sp)+,d0-d7/a0-a6
 dc.w $4afa
 rts
;--------
SetLowResolution
* Now set low resolution for use by the game
 move.w #0,-(sp) ; low resolution
 lea LogicalBase,a0
 move.l #$f7ff8,(a0)
 lea AlternateLogicalBase,a0
 move.l #$e7ff8,(a0)
 move.l #$f8000,-(sp)
 move.l #$f8000,-(sp) ; logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts
;---
SwapPage
* If it will be a long time before we can swap,
* set a flag and do it whilst building the new frame

 move.l LogicalBase,d0
 add.l #150*200,d0
 lsr.w #8,d0
 move.b $ff8207,d1
 cmp.b d0,d1
 bge.s ActuallySwapScreen * off screen already, so do it now!

 move.l LogicalBase,d0
 add.l #20*200,d0
 lsr.w #8,d0
 move.b $ff8207,d1

WaitForOnScreen
 move.b $ff8207,d1
 cmp.b d0,d1
 blt.s WaitForOnScreen
 lea StillNeedToSwapScreen,a0
 move.b #1,(a0)
 bra SetWriteAlternate
 rts
;---

;WaitForOffScreen
; move.b $ff8207,d1
; cmp.b d0,d1
; blt.s WaitForOffScreen
; move.w #36,-(sp)
; trap #14
; addq.l #2,sp

ActuallySwapScreen
 lea StillNeedToSwapScreen,a0
 move.b #1,(a0)

 move.l LogicalBase,d0
 add.l #8,d0
* physical base is 8 less than the value used by the display hardware
* to allow the 16 pel margin at the LHS of the logical screen to be
* displayed at the RHS of the physical screen
 asr.l #8,d0
 lea $ffff8203,a0
 move.b d0,(a0) ; $80 for $f8000
 asr.l #8,d0
 lea $ffff8201,a0
 move.b d0,(a0) ; $0f for $f8000
 
SetWriteAlternate
; and write to alternate page...
 movem.l a1-a2,-(sp)
 move.l AlternateLogicalBase,a1
 move.l LogicalBase,a2
 lea LogicalBase,a0
 move.l a1,(a0)
 lea AlternateLogicalBase,a0
 move.l a2,(a0)
 movem.l (sp)+,a1-a2
 rts
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
 move.l #$f8000,-(sp) ; retain physical base
 move.l #$f8000,-(sp) ; retail logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts
;-------
MoveScreen
; Change position of physical window onto map if appropriate
 clr.w d6
; move.b PlayerSDS+SpeedOffset,d6 * find step size
 move.b ScrollStep,d6
 lea PlayerXpos,a0

 move.b DoingPseudoFlip,d0
 beq.s MoveScreen2
; in the middle of a pseudo flip
 lea DoingPseudoFlip,a1
 subq.b #1,(a1)
 move.b PseudoFlipDirection,d0
 beq MoveToRight
 bra MoveToLeft

; Pseudo-flip handlers...

MoveToLeft
; player tried to go off the left hand edge
 lea ScreenXPos,a1
 move.w (a1),d0
 sub.w d6,d0
 bmi moveScreenNotLR ; stop moving off screen
 move.w d0,(a1)
 bra MoveScreenNotLR

MoveToRight
; player tried to go off the right hand edge
 lea ScreenXPos,a1
 move.w (a1),d0
 add.w d6,d0 * d6
 cmp.w ScreenXMax,d0
 bgt moveScreenNotLR
 move.w d0,(a1)
 bra MoveScreenNotLR

; code to detect when a flip is necessary..

MoveScreen2
 move.w PlayerXPos,d0
 sub.w ScreenXPos,d0
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
 lea ScreenYPos,a0
 move.w PlayerYPos,d1
 sub.w (a0),d1
 cmp.w #120,d1 * 140,d1
 blt.s MoveScreenNotDown
; player is at the bottom of the screen - so scroll it up

 move.w (a0),d0
 add.w d6,d0 * d6
 cmp.w ScreenYMax,d0
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
; handle cycling colours etc.
 lea FrameCounter,a0
 add.l #1,(a0)

 lea StarCounter,a0
 addq.b #1,(a0)
 move.b (a0),d0
 lsr.b #1,d0

 cmp.b #8,d0
 bne.s SpecialNotStar
 clr.b d0
 clr.b (a0)

SpecialNotStar
; cmp.b #4,d0
; blt.s SNS1
; move.b #6,d2
; sub.b d0,d2
; move.b d2,d0

SNS1
* d0=phase of flashing stars
 lea StarPhase,a0
 move.b d0,(a0)
 rts
;-----
LoadAndDisplayTitleScreen
 lea WorkSpace,a0
 lea LoadTitleScreenDriverBlock,a6
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 * start of screen just loaded
 add.l #$1c,a0
 move.l LogicalBase,a1
 add.l #8,a1 * allow for 8 pel offset of physical screen from logical scre
 move.w #200,d0 * number of screen lines

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
 move.l LogicalBase,a0
 move.l AlternateLogicalBase,a1
 move.w #200*160/4,d0
LADTS2
 move.l (a0)+,(a1)+
 dbra d0,LADTS2
 rts

;-----
LoadDataFiles
 bsr LoadAndDisplayTitleScreen * load in title screen

 lea LoadMapGraphicsDriverBlock,a6
 lea WorkSpace,a0
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of map graphics just loaded
 lea MapGraphicsPtr,a1
 move.l a0,(a1) ; start of map area
 move.l $4(a6),a0 * free space for next load

 bsr MakeA0Even
 lea LoadPlaySprDriverBlock,a6
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of sprite data just loaded
 lea SpriteDataPtr,a1
 move.l a0,(a1) ; start of sprite data
 move.l $4(a6),a0 * free space for next load

 bsr MakeA0Even
 lea LoadMapLayoutDriverBlock,a6
 move.l a0,(a6)
 bsr LoadFile
 move.l (a6),a0 ; set a0.l = start of map graphics just loaded
 add.l #$1c,a0 ; skip over header put on sprite file by GENST
; lea MapLayoutPtr,a1
; move.l a0,(a1) ; start of map layout data
 move.l a0,a1
 move.l $4(a6),a0 * free space
 bsr MakeA0Even
 lea MapLayoutPtr,a2
 move.l a0,(a2) ; start of copied map layout data
* copy map layout to free space + convert to word format
 move.l a0,d0
 sub.l a1,d0 * find length in d0.l
CopyMapLoop
 clr.l d1
 move.b (a1)+,d1
 bpl.s CopyMap1
* Set bit 15 to indicate cyclic - 128..255 remains range of cyclic sprites
* so bit 7 remains set
 or.w #$8000,d1
CopyMap1
 move.w d1,(a0)+
 dbra d0,CopyMapLoop
* a0.l = free space for next load

; lea DestroyedWallSpace,a0
 lea DestroyedWallPtr,a1
 move.l a0,(a1)
 clr.w (a0) * zero first table entry
 add.l #5000,a0


 bsr PreScrollMap

 rts
;------
SetUpPalette
; move.l PalettePtr,-(sp)
 lea Palette,a0
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

PreScrollMap
; The map data has just been loaded. There is free space at a0.l+(a0).l
; Pre-Scroll it at 4-pixel increments
; The Size of the map data is $8(a0).l
; The map data starts at (MapGraphicsPtr).l
; Then Map layout data is at (MapLayoutPtr)
; Find Free Space

; move.l (a0),a2
; add.l a0,a2 ; a2.l=start of free space
; move.l a2,a0
 bsr MakeA0Even
 move.l a0,a2 * a2.l =start of free space
 lea ScrolledLayoutPtr,a1
 move.l a0,(a1) * save start of map layoutptr

* now produce new blocks which represent each pair of two
* current blocks. e.g.
* a sequence    1 2 3 4 3 5 2 3 2 1 3 2
* might go to:   1 2 3 4 5 6 2 7 8 9 A (with a new set of graphics data)
* obviously this data will be quite a lot bigger - but we'll
* stick with 8 bit values. Clever map design should avoid
* the need to go bigger than this (plus the fact that maps tend to be
* repetitious)
 move.l MapLayoutPtr,a0
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

 lea MapGraphicsPtrs,a4
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


;------
PreScrollnotCyclic
PreScrollD4
 move.l CyclicOffset,d2
 
 and.l #$7fff,d5 * clear top word & cyclic flag
 asl.w #7,d5 * multiply by 128 to get index
 move.l MapGraphicsPtr(PC),a0
 add.l d5,a0
* now a0.l is start of original sprite data for sprite d5

 and.l #$7fff,d6 * clear top word & cyclic flag
 asl.w #7,d6 * multiply by 128 to get index
 move.l MapGraphicsPtr(PC),a1
 add.l d6,a1
* and a1.l is start of original sprite data for sprite d6

* where is it to go?
 and.l #$ffff,d4
 asl.w #7,d4 * multiply by 128 to get index
 move.l MapGraphicsPtr2(PC),a2
 add.l d4,a2
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr3(PC),a3
 add.l d4,a3
 add.l d2,a2 * add on offset for cyclic sprites
 move.l MapGraphicsPtr4(PC),a4
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
 lea HiUsedMemory,a0
 move.l a4,(a0)
 rts
;---
; move.w $8(a0),d6
;
; move.w #2,d7 * size of right shift
; lea MapGraphicsPtr,a5 ; keep a5.l as the position in the ptr table for each
;; set of scrolled data
; move.l (a5)+,a1 ; load starting position of original data
;
;
;PreScroll1
; move.l a2,(a5)+ ; store next entry in ptr table
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
;----------------- Start of Space Invaders




;-------
SIResetMonsters
 bsr SIInitSpriteTable
 lea SIStepsToGo,a0
 move.w #70,(a0)
 lea SIYStepsToGo,a0
 move.w #30,(a0) * determines length of game
 lea SIXSpeed,a0
 move.w #2,(a0)
 lea SIYSpeed,a0
 move.w #0,(a0)

 lea ScreenXPos,a0
 move.w #0,(a0)
 lea ScreenYPos,a0
 move.w #32,(a0)


SpaceInvLoop
* clear the screen
 lea HeroStack,sp

 move.l LogicalBase,a0
 move.w #1000,d0
SIL1
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+

 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 dbra d0,SIL1
 bsr DisplayAllSprites

 movem.l d0-d7/a0-a6,-(sp)
  bsr SwapPage ; display it all.
  bsr DoDelayedFlip
  lea SpriteTable,a0
  tst.l (a0) * player still alive?
  beq SIGameOver * no
  bsr HandleInvaders

 movem.l d0-d7/a0-a6,-(sp)

 bsr AbsGetCharFromBdos
 tst.b d0
 beq.s SINoKeyPress
 bsr HandleKeyPress

SINoKeyPress

 bsr SIGetPlayerInput
 bsr CPMFinishMove * update speed pointers+do animation

 btst #FireButton,d7
 bne SIMaybeFireMissile
 bra SpaceInvLoop

SIMaybeFireMissile
 lea PlayerView,a0
 clr.b (a0)
 bsr SIFireMissile
 bra SpaceInvLoop
;--------
HandleInvaders
* all invaders destroyed?
 lea SpriteTable,a0
 move.w #MaxMovingSprites,d7

AllGone1
 tst.l (a0) * sprite number zero?
 beq AllGone2
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d0
 bmi.s SomeLeft
AllGone2
 add.l #SpriteCurrentSize,a0
 dbra d7,AllGone1
SIGameOver
 move.w #0,d0
 move.w #4,d1 * controls length of delay
SIDelay
 dbra d0,SIDelay
 dbra d1,SIDelay
 bra SIResetMonsters
;
SomeLeft
 bsr GetRandom
 cmp.b #200,d0
 blt SIFA3

* find an invader to drop a missile
 lea SpriteTable,a0
 move.w #MaxMovingSprites,d7
FindAttacker
 tst.l (a0) * sprite number zero?
 beq SIFA2
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d0
 bpl.s SIFA2 * not an invader
 lea Random,a1
 move.l (a1),d6
 rol.l #1,d6
 move.l d6,(a1)

 btst #0,(a1)
 beq.s SIFA2 * this one won't fire
 btst #1,(a1)
 beq.s SIFA2 * only fires on a double zero
* only fires if it the highest possible
 move.w XPosOffset(a0),d0
 move.w YPosOffset(a0),d1
* check if any of the other invaders are lower...
SIFFire1
 tst.l (a0) * sprite number zero?
 beq SIFLaunch
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d2
 bpl.s SIFFire2 * not an invader
 cmp.w YPosOffset(a0),d1
 bge.s SIFFire2
* this invader is lower
 move.w YPosOffset(a0),d1

SIFFire2
 add.l #SpriteCurrentSize,a0
 dbra d7,SIFFire1
SIFLaunch
* launch a missile starting at (d0.w,d1.w)
 add.w #4,d1 * get clear of invader
 clr.w d2 * x speed
 move.w #12,d3 * y speed
 move.w #5,d4 * sprite number for missile
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6
 bra.s SIFA3

;---
SIFA2
 add.l #SpriteCurrentSize,a0
 dbra d7,FindAttacker

SIFA3
* move dem invaders!!!
 lea SIYSpeed,a0
 clr.w (a0)
 lea SIStepsToGo,a0
 subq.w #1,(a0)
 bne.s SINoCHange
 move.w #70,(a0)
* change direction, move down
 lea SIXSpeed,a0
 neg.w (a0)
 lea SIYSpeed,a0
 move.w #6,(a0)
 lea SIYStepsToGo,a0
 subq.w #1,(a0)
 bmi SIGameOver

SINoChange
 rts

;---------
SIFireMissile
; Initiate Fire
 move.w PlayerXPos,d0
 move.w PlayerYPos,d1
; add.w #4,d1 * overlap allowed for head
 clr.l d2
 move.b PlayerView,d2
 asl.w #2,d2 * 2 words per entry
 lea ViewToXYConversionTable,a0
 add.l d2,a0
 move.w (a0)+,d2 * d2:=x speed
 move.w #12,d4
 mulu d4,d2 * missiles go at 12 pel/step
 move.w (a0)+,d3 * d3:=y speed
 mulu d4,d3 * missiles go at 12 pel/step
 move.w #6,d4 * sprite number for missile

 lea Random,a0
 move.l (a0),d6
 rol.l #1,d6
 move.l d6,(a0)
 and.b #3,d6

 move.w d2,d5
 asr.w d6,d5
 add.w d5,d0
 move.w d3,d5
 asr.w d6,d5
 add.w d5,d1

 bsr SetUpNewSprite
 rts *  bra TimeLoop
;-------
SIInitSpriteTable
 Lea DoYRangeKill,a0
 move.b #1,(a0)

 lea SpriteTable,a0
 lea SpriteTPtr,a1
 move.l a0,(a1)
 move.w #MaxMovingSprites,d5 * max size of table
SIIST1
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+

 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 dbra d5,SIIST1

* and set up 1 player sprite....

 move.w #184,d1 * initial player y pos
 clr.w d2 * x speed
 clr.w d3 * y speed
 move.w #0,d4 * player-type
 move.w #16,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

* and set up 25 monster sprites....
 move.w #4,d4
 move.w #32,d1 * top ledft y pos

SIIST2
 move.w #16,d0 * top left x pos of grid of monsters
SIIST3
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6
 add.w #16,d0 * x pos
 cmp.w #130,d0
 ble.s SIIST3
 add.w #16,d1 * y pos
 cmp.w #100,d1
 ble.s SIIST2

* and set up a monster above the player
 move.w #154,d1 * initial player y pos
 move.w #16,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

 rts
;----
;--------
DoDelayedFlip
 movem.l d0-d1/a0,-(sp)
 move.b StillNeedToSwapScreen,d0
 beq.s DDNoFlip
 move.l LogicalBase,d0
 add.l #130*200,d0
 lsr.w #8,d0
DDWait
 move.b $ff8207,d1
 cmp.b d0,d1
 blt.s DDWait
 bsr SetWriteAlternate * make it display the correct buffer
 bsr ActuallySwapScreen
DDNoFlip
 movem.l (sp)+,d0-d1/a0
 rts
;--------
SIGetPlayerInput
 move.b JoystickStatus,d7
 move.w #6,d6 * step size

 clr.w d4 * x offset requested by player
 clr.w d5 * y offset requested by player
 
 btst #LeftBit,d7
 beq.s SINotLeft
 move.w PlayerXPos,d0
 sub.w d6,d0
 bmi SINotLeft ; Prevent Move if off screen
 clr.w d4
 sub.w d6,d4 * negative step size in x offset

SINotLeft
 btst #RightBit,d7
 beq.s SINotRight
 move.w PlayerXPos,d0
 add.w d6,d0
 cmp.w PlayerXMax,d0
 bge SINotRight
 move.w d6,d4 * set x offset to step size

SINotRight
 RTS
;---------







;-------------- End of Space Invaders
BGMinXTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BGMaxXTable equ *-16
* for each background block, record here the max x
* value which should be cd'd with.
* start with block 16....
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

BGMinYTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BGMaxYTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

;-------
BigExplosionTable
* table giving the x,y speeds for the elements of a big explosion
* up, right quarter
 dc.w 0,-12 * north
 dc.w 6,-11
 dc.w 12,-12
 dc.w 11,-6

* down, right quarter
 dc.w 12,0 * east
 dc.w 11,6
 dc.w 12,12
 dc.w 6,11

* down, left quarter
 dc.w 0,12 * south
 dc.w -6,11
 dc.w -12,12
 dc.w -12,6

* down, right quarter
 dc.w -12,0 * west
 dc.w -11,-6
 dc.w -12,-12
 dc.w -6,-11

 dc.w 0,0 * terminates table
;--------------
ViewConversionTable
; Table to convert from joystick status values to view of player to use
 dc.b 0 ; 0000 dummy entry
 dc.b 0 ; 0001 north
 dc.b 4 ; 0010 south
 dc.b 0 ; 0011 -
 dc.b 6 ; 0100 west
 dc.b 7 ; 0101 northwest
 dc.b 5 ; 0110 southwest
 dc.b 0 ; 0111 -
 dc.b 2 ; 1000 east
 dc.b 1 ; 1001 east-north
 dc.b 3 ; 1010 east-south
 dc.b 0 ; 1011 -
 dc.b 0 ; 1100 -
 dc.b 0 ; 1101 -
 dc.b 0 ; 1110 -
 dc.b 0 ; 1111 -
;---
 even
ViewToXYConversionTable
; Table to convert from player view to XY offset (used for
; firing missiles etc.)
 dc.w 0,-1 * north
 dc.w 1,-1 * ne
 dc.w 1,0 * e
 dc.w 1,1 * se
 dc.w 0,1 * s
 dc.w -1,1 * sw
 dc.w -1,0 * w
 dc.w -1,-1 * nw
;-----
 even
 dc.b 0*4 * -3 - sixth attempt
 ds.b 3
 dc.b 3*4 * -2 - fifth attempt
 ds.b 3
 dc.b 2*4 * -1 - fourth attempt
 ds.b 3
NextAddDirTable
; byte-wise table that, given the current addition to the
; movement direction, gives the new addition
 dc.b 1*4 * 0 - first altered direction
 ds.b 3
 dc.b -1*4 * 1 - second attempt
 ds.b 3
 dc.b -2*4 * 2 - third attempt
 ds.b 3
 dc.b -3*4 * 3 - seventh attempt
 ds.b 3
 dc.b 0 * 4 - eighth attempt - start sequence again
 ds.b 3

;----
 even
 dc.b 0*4 * -3
 ds.b 3
 dc.b 0*4 * -2
 ds.b 3
 dc.b 0*4 * -1
 ds.b 3
NearbyAddDirTable
; byte-wise table that, given the current addition to the
; movement direction, gives the new addition
 dc.b 1*4 * 0
 ds.b 3
 dc.b -1*4 * 1
 ds.b 3
 dc.b 0*4 * 2
 ds.b 3
 dc.b 0*4 * 3
 ds.b 3
 dc.b 0 * 4
 ds.b 3
;---
; Driver Blocks etc...
 even
LoadSpritesDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'Sprites.Dat',0
 even

LoadPlaySprDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'PlaySpr.Dat',0
 even


LoadMapLayoutDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'map.dat',0
 even

LoadMapGraphicsDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'mapgraph.dat',0
 even
;---
LoadTitleScreenDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'SideScr.dat',0
;-------
Palette
 dc.w $000,$333,$555,$777,$300,$500,$700
 dc.w $030,$050,$070,$003,$005,$007,$330,$550,$770
;-----
SpriteDataStructure
PlayerSDS
; 0 is left player
StationaryAnimationOffset equ *-SpriteDataStructure
 dc.w 0	* animation offset range when stationary ( from current view)
MovingAnimationOffset equ *-SpriteDataStructure
 dc.w 0	* animation range when moving north
 dc.w 8	* animation range when moving ne
 dc.w 16	* animation range when moving e
 dc.w 24	* animation range when moving se
 dc.w 32	* animation range when moving s
 dc.w 40	* animation range when moving sw
 dc.w 48	* animation range when moving w
 dc.w 56	* animation range when moving nw

FightAnimationOffset equ *-SpriteDataStructure
 dc.w 2 * roughly change the colour of the player.
* added to above animation ranges when in hand to hand combat
* ( this is the actual offset in bytes )

ThrowAnimationOffset equ *-SpriteDataStructure
 dc.w 256 * added to above animation ranges when player is throwing
* something.

InitialHitPointOffset equ *-SpriteDataStructure
 dc.w 1000 * initial hit points

InitialBlowStrengthOffset equ *-SpriteDataStructure
 dc.w 30 * damage done

TimeBetweenBlowsOffset equ *-SPriteDataStructure
 dc.b 5

MaxAnimationStage
NumAnimationOffset equ *-SpriteDataStructure
 dc.b 7 * max animation offset

TypeOffset equ *-SpriteDataStructure
 dc.b 1 * player type
* type is 1 bit, corresponding to those
* specified by the collision detection flags

PlayerStepSize
SpeedOffset equ *-SpriteDataStructure
 dc.b 8 	* speed of movement (pels)
NullMovesOffset equ *-SpriteDataStructure
 dc.b 0 	* number of null moves per real move

* bit assignments for use in typeoffset, and
* the various cd fields below
CDWithPlayer equ 0 * bit 0
CDWithMissiles equ 1
CDWithMonsters equ 2
CDWithBG equ 3 * bit 3
CDWithObject equ 4
CDWithInvisibles equ 5
CDWithMonsterMissile equ 6

CDFlagsOffset equ *-SpriteDataStructure
 dc.b $fd 	* which collisions are detected?
CDSpecialsOffset equ *-SpriteDataStructure
 dc.b $34 	* which collisions activate specials?
CDDestroyedOffset equ *-SpriteDataStructure
 dc.b $00	* does THIS sprite explode on these collisions
CDBlockedOffset equ *-SpriteDataStructure
 dc.b $0f	* is this sprite blocked by these collisions

PriorityOffset equ *-SpriteDataStructure
 dc.b 100 * 128	* priority of sprite. 255 appears on top, 0 at bottom
* sprites of equal priority are sorted vertically
HeightOffset equ *-SpriteDataStructure
 dc.b 19 * offset of bottom row used in cd
HeadOverlapOffset equ *-SpriteDataStructure
 dc.b 4 * number of rows at top of sprite not cd'd
 even

SDS1End
SDSSize equ SDS1End-SpriteDataStructure

;-
; 1 is missile
 dc.w 112 *64	* animation offset range when stationary ( from current view)
 dc.w 112 *64	* animation range when moving north
 dc.w 112 *64	* animation range when moving ne
 dc.w 112 *64	* animation range when moving e
 dc.w 112 *64	* animation range when moving se
 dc.w 112 *64	* animation range when moving s
 dc.w 112 *64	* animation range when moving sw
 dc.w 112 *64	* animation range when moving w
 dc.w 112 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 20 * damage done
 dc.b 0 * continuous blows

 dc.b 7 * max animation offset
 dc.b 2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $cc 	* collision detect?
 dc.b $cc 	* specials?
 dc.b $cc	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 2 is  an animated skull monster
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 99	* animation range when moving north
 dc.w 99	* animation range when moving ne
 dc.w 99	* animation range when moving e
 dc.w 99	* animation range when moving se
 dc.w 99	* animation range when moving s
 dc.w 99	* animation range when moving sw
 dc.w 99	* animation range when moving w
 dc.w 99	* animation range when moving nw
 dc.w -200*19 * fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 2 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 3 is  an explosion effect
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 88	* animation range when moving north
 dc.w 88	* animation range when moving ne
 dc.w 88	* animation range when moving e
 dc.w 88	* animation range when moving se
 dc.w 88	* animation range when moving s
 dc.w 88	* animation range when moving sw
 dc.w 88	* animation range when moving w
 dc.w 88	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * blows per second

 dc.b 8 * max animation offset
 dc.b 0 * no type - will not cd with anything
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00 	* destroyed?
 dc.b $0f	* blocked?
 dc.b 105	* priority
 dc.b 15 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;-------
; 4 is  an animated skull monster for space invaders
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 96	* animation range when moving north
 dc.w 96	* animation range when moving ne
 dc.w 96	* animation range when moving e
 dc.w 96	* animation range when moving se
 dc.w 96	* animation range when moving s
 dc.w 96	* animation range when moving sw
 dc.w 96	* animation range when moving w
 dc.w 96	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 2 * max animation offset
 dc.b $84 * monster type, but not auto-moving, hence bit 7 set
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $02 	* collision detect?
 dc.b $00 	* specials?
 dc.b $02	* destroyed?
 dc.b $00	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;------
; 5 is missile for space invaders to fire
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 25 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $40 * si missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $01	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 6 is missile to fire at space invaders
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $c4 	* collision detect?
 dc.b $00 	* specials?
 dc.b $c4	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;-----
; 7 is  a Rainbird monster
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 104	* animation range when moving north
 dc.w 104	* animation range when moving ne
 dc.w 104	* animation range when moving e
 dc.w 104	* animation range when moving se
 dc.w 104	* animation range when moving s
 dc.w 104	* animation range when moving sw
 dc.w 104	* animation range when moving w
 dc.w 104	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 0 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0f	* blocked?
 dc.b 100	* priority
 dc.b 15 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

;-----
; 8 is the explosive missile fired by the player
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 50 * damage done
 dc.b 0 * continuous blows

 dc.b 7 * max animation offset
 dc.b $22 * $02=missile type, $20=explosive missile
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $cc 	* collision detect?
 dc.b $cc 	* specials?
 dc.b $cc	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;------
; 9 is digging missile.
 dc.w 112 *64	* animation offset range when stationary ( from current view)
 dc.w 112 *64	* animation range when moving north
 dc.w 112 *64	* animation range when moving ne
 dc.w 112 *64	* animation range when moving e
 dc.w 112 *64	* animation range when moving se
 dc.w 112 *64	* animation range when moving s
 dc.w 112 *64	* animation range when moving sw
 dc.w 112 *64	* animation range when moving w
 dc.w 112 *64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $c8 	* collision detect?
 dc.b $c8 	* specials?
 dc.b $c8	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;------
; 10 is bottle
 dc.w 120 *64	* animation offset range when stationary ( from current view)
 dc.w 120 *64	* animation range when moving north
 dc.w 120 *64	* animation range when moving ne
 dc.w 120 *64	* animation range when moving e
 dc.w 120 *64	* animation range when moving se
 dc.w 120 *64	* animation range when moving s
 dc.w 120 *64	* animation range when moving sw
 dc.w 120 *64	* animation range when moving w
 dc.w 120 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 11 is invisible object
 dc.w -1	* animation offset range when stationary ( from current view)
 dc.w -1	* animation range when moving north
 dc.w -1	* animation range when moving ne
 dc.w -1	* animation range when moving e
 dc.w -1	* animation range when moving se
 dc.w -1	* animation range when moving s
 dc.w -1	* animation range when moving sw
 dc.w -1	* animation range when moving w
 dc.w -1	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $20 * trap type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 15 * offset of bottom row - used by rough cd
 dc.b 0 * head overlap
 even
;-----
; 12 is missile for space invaders to fire
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 25 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $44 * monster missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0b 	* collision detect?
 dc.b $0b 	* specials?
 dc.b $0b	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

;----
 even
SpriteTable
SpriteCurrentInfo
; Space for temporary values for missiles/players etc.

InfoPtrOffset equ *-SpriteCurrentInfo
 dc.l 0 * ptr to permament sprite info for this sprite
* (must be the first entry)

XSpeedOffset equ *-SpriteCurrentInfo
 dc.w 0 ; Current X Speed

YSpeedOffset equ *-SpriteCurrentInfo
 dc.w 0 ; Current Y Speed

XPosOffset equ *-SpriteCurrentInfo
PlayerXPos	 ds.w 1

YPosOffset equ *-SpriteCurrentInfo
PlayerYPos	 ds.w 1

DataPtrOffset equ *-SpriteCurrentInfo
 ds.l 1 * ptr to currently displayed bit pattern

NextPtrOffset equ *-SpriteCurrentInfo
 ds.l 1 * ptr to next entry in sprite table

LastPtrOffset equ *-SpriteCurrentInfo
 ds.l 1 * ptr to last entry in sprite table

NameOffset equ *-SpriteCurrentInfo
 ds.w 1 * the 'name' of the monster.
* This is equal to the sprite number for ordinary monsters. For humans,
* and if we allow players to christen monsters, this will change.
* Its purpose is to allow the special case handlers to distinguish
* between monsters with the same fixed data blocks.

HitPointOffset equ *-SpriteCurrentInfo
 ds.w 1 * the number of hit points remaining for the monster

BlowStrengthOffset equ *-SpriteCurrentInfo
 ds.w 1 * number of hit points of damage done by blows.

TimeToNextBlowOffset equ *-SpriteCurrentInfo
 ds.b 1

ViewOffset equ *-SpriteCurrentInfo
PlayerView	 ds.b 1

StageOffset equ *-SpriteCurrentInfo
PlayerAnimationStage ds.b 1

NullMovesMadeOffset equ *-SpriteCurrentInfo
PlayerNullMovesMade ds.b 1

OnScreenOffset equ *-SpriteCurrentInfo
PlayerOnScreenFlag  ds.b 1

DistanceOffset equ *-SpriteCurrentInfo
PlayerDistanceTravelled ds.b 1

LifeCounterOffset equ *-SpriteCurrentInfo
 ds.b 1 * counts down until 0, when sprite self-destructs

AddDirOffset equ *-SpriteCurrentInfo
 ds.b 1 * adds to view when sprite trying to unblock itself

SpriteCurrent1End
SpriteCurrentSize equ 48 * SpriteCurrent1End-SpriteCurrentInfo


; data for missiles etc (set up at runtime)...
; It is in the same format as the above, and uses the same offsets

 even
MaxMovingSprites equ 75
 ds.b SpriteCurrentSize*(MaxMovingSprites+1)

EndSpriteTable
;---
;Long workspace....
 even

LogicalBase
 ds.l 1 * holds address 8 less than the real physical base
* to allow the leftmost 16 pels to be clipped in an elegant fashion

AlternateLogicalBase
 ds.l 1

FrameCounter
 ds.l 1

YFineScroll ds.l 1

SpriteDataPtr ds.l 1

MapGraphicsPtrs
MapGraphicsPtr ds.l 1
MapGraphicsPtr2 ds.l 1
MapGraphicsPtr3 ds.l 1
MapGraphicsPtr4 ds.l 1

CurrentMapGraphicsPtr ds.l 1

MapLayoutPtr ds.l 1

* There are 8 ScrolledLayoutPtrs because the order of sprites
* is scrambled compared to the original - MapLayoutPtr
* Therefore these 8 copies are made which are cycled through instead
* The only difference between them is that they have different
* sprite values for the cyclical blocks
ScrolledLayoutPtr ds.l 1
ScrolledLP2 ds.l 1
ScrolledLP3 ds.l 1
ScrolledLP4 ds.l 1
ScrolledLP5 ds.l 1
ScrolledLP6 ds.l 1
ScrolledLP7 ds.l 1
ScrolledLP8 ds.l 1

SupervisorStack ds.l 1

PalettePtr ds.l 1

CyclicOffset ds.l 1

Random ds.l 1

RandomSeed ds.l 1

SpriteTPtr ds.l 1

LastTime ds.l 1

DestroyedWallPtr ds.l 1

Player1SpriteBlock ds.l 1

HiUsedMemory ds.l 1
;---
;Wordwise workspace...
;PlayerXSpeed ds.w 1
;PlayerYSpeed ds.w 1
ScreenXPos ds.w 1
ScreenYPos ds.w 1
ScreenXMax ds.w 1
ScreenYMax ds.w 1
PlayerXMax ds.w 1
PlayerYMax ds.w 1

ScreenXBlocks ds.w 1

TextOffset ds.w 1

SIXspeed ds.w 1
SIYSpeed ds.w 1
SIStepsToGo ds.w 1
SIYStepsToGo ds.w 1

DAMSLoopCounter ds.w 1

FreeSprites ds.w 1

NumDestroyedWalls ds.w 1

XPosSave ds.w 1
YPosSave ds.w 1

TempNameStorage ds.w 1
;---
; Bytewise workspace...
StarPhase ds.b 1

StarCounter ds.b 1

DoingPseudoFlip ds.b 1

PseudoFlipDirection ds.b 1

JoystickStatus ds.b 1

TextSmoothScroll ds.b 1

TempStarPhase ds.b 1

FireButtonHeld ds.b 1

ScrollStep ds.b 1

StillNeedToSwapScreen ds.b 1

DoYRangeKill ds.b 1

CurrentWeapon ds.b 1

BreakPointArmed ds.b 1

TimeToNextShot ds.b 1

;---
 even

VectorSaveTable
* used to save kbd processor jump table
 ds.b 40 * 32 bytes are used

TextBuffer ds.b 120 * 40 bytes are used

MaxDestroyedWalls equ 100
;DestroyedWallSpace
; ds.b 5000 * temporary space
;---
 even

 ds.b 512 ; used for system stack as well - so need plenty of space
HeroStack
;---
; Transient workspace - loaded from data files etc.
 even

WorkSpace
