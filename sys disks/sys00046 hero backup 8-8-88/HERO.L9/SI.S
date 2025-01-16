; Space Invaders section of Hero
;
; Copyright (C) 1988 Level 9 Computing
;
; M.J.Austin 1987/1988.
;
;
; This code was written as a challenge. I was bet that
; I Couldn't write a playable version of space invaders in less
; than a day. It actually took slightly under 3 hours (and
; it shows!)
;
;
;
;
;----------------- Start of Space Invaders




;-------
SIResetMonsters
 bsr SIInitSpriteTable
 lea SIStepsToGo-S(a5),a0
 move.w #70,(a0)
 lea SIYStepsToGo-S(a5),a0
 move.w #30,(a0) * determines length of game
 lea SIXSpeed-S(a5),a0
 move.w #2,(a0)
 lea SIYSpeed-S(a5),a0
 move.w #0,(a0)

 lea ScreenXPos-S(a5),a0
 move.w #0,(a0)
 lea ScreenYPos-S(a5),a0
 move.w #32,(a0)


SpaceInvLoop
* clear the screen
 lea HeroStack-S(a5),sp

 move.l LogicalBase-S(a5),a0
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
*****should re-enable  bsr SwapPage ; display it all.
*****should re-enable  bsr DoDelayedFlip
  lea SpriteTable-S(a5),a0
  tst.l (a0) * player still alive?
  beq SIGameOver * no
  bsr HandleInvaders

 movem.l d0-d7/a0-a6,-(sp)

 bsr AbsGetCharFromBdos
; tst.b d0
; beq.s SINoKeyPress
;****** bsr HandleKeyPress
;
;SINoKeyPress

 bsr SIGetPlayerInput
 bsr CPMFinishMove * update speed pointers+do animation

 btst #FireButton,d7
 bne SIMaybeFireMissile
 bra SpaceInvLoop

SIMaybeFireMissile

; move.l Player1SpriteBlock-S(A5),a0
 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a0
 add.l d0,a0


 clr.b ViewOffset(a0)
; lea PlayerView-S(a5),a0
; clr.b (a0)
 bsr SIFireMissile
 bra SpaceInvLoop
;--------
HandleInvaders
* all invaders destroyed?
 lea SpriteTable-S(a5),a0
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
 lea SpriteTable-S(a5),a0
 move.w #MaxMovingSprites,d7
FindAttacker
 tst.l (a0) * sprite number zero?
 beq SIFA2
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d0
 bpl.s SIFA2 * not an invader
 lea RandomSeed-S(a5),a1
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
 lea SIYSpeed-S(a5),a0
 clr.w (a0)
 lea SIStepsToGo-S(a5),a0
 subq.w #1,(a0)
 bne.s SINoCHange
 move.w #70,(a0)
* change direction, move down
 lea SIXSpeed-S(a5),a0
 neg.w (a0)
 lea SIYSpeed-S(a5),a0
 move.w #6,(a0)
 lea SIYStepsToGo-S(a5),a0
 subq.w #1,(a0)
 bmi SIGameOver

SINoChange
 rts

;---------
SIFireMissile
; Initiate Fire
 move.w PlayerXPos-S(a5),d0
 move.w PlayerYPos-S(a5),d1
; add.w #4,d1 * overlap allowed for head
 clr.l d2
; move.b PlayerView-S(a5),d2

; move.l Player1SpriteBlock-S(A5),a0
 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a0
 add.l d0,a0


 move.b ViewOffset(a0),d2
 asl.w #2,d2 * 2 words per entry
 lea ViewToXYConversionTable-S(a5),a0
 add.l d2,a0
 move.w (a0)+,d2 * d2:=x speed
 move.w #12,d4
 mulu d4,d2 * missiles go at 12 pel/step
 move.w (a0)+,d3 * d3:=y speed
 mulu d4,d3 * missiles go at 12 pel/step
 move.w #6,d4 * sprite number for missile

 lea RandomSeed-S(a5),a0
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
 Lea DoYRangeKill-S(a5),a0
 move.b #1,(a0)

 lea SpriteTable-S(a5),a0
 lea SpriteTPtr-S(a5),a1
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
SIGetPlayerInput
 move.b JoystickStatus-S(a5),d7
 move.w #6,d6 * step size

 clr.w d4 * x offset requested by player
 clr.w d5 * y offset requested by player
 
 btst #LeftBit,d7
 beq.s SINotLeft
 move.w PlayerXPos-S(a5),d0
 sub.w d6,d0
 bmi SINotLeft ; Prevent Move if off screen
 clr.w d4
 sub.w d6,d4 * negative step size in x offset

SINotLeft
 btst #RightBit,d7
 beq.s SINotRight
 move.w PlayerXPos-S(a5),d0
 add.w d6,d0
 cmp.w PlayerXMax-S(a5),d0
 bge SINotRight
 move.w d6,d4 * set x offset to step size

SINotRight
 RTS
;---------







;-------------- End of Space Invaders
