*
*    Sprite Display Routines, Mark V - A Four Hit Die Monster !!!
*
*    Copyright (c) 1988 Level 9 Computing. All Rights Reserved
*    9 Mendip Road, Crown Wood, Bracknell, Berkshire RG12 3XG - (0344) 487597
*
*    Original Author: Leon Thrane (July 1987)
*
*    Converted to ST: Mike Austin Oct/Nov/Dec 1987
*    Substantially modified Mike Austin 1987/1988
*
*
* 17/7/88 - LR reversal routines added. Substantially slower
*  than normal plot - about 2 ms/sprite -- Mike 17/7/88
*

ScreenXSize equ 256
ScreenYSize equ 192

*
*    A routine to place a sprite anywhere on the screen in four BitPlanes.
*    Note that the address for all four BitPlanes must be even for this to
*    work. If they are always odd, the code can be modified, but if they vary
*    there is nothing you can do, (short of adding some code to detect which
*    is which!)
*
*         Sprite(BitPlanes, Data, XPos, YPos, Width);
*                   A2       A3    D0    D1     D2
*
*    Format for the sprite data:
*
*    byte:    describtion
*    -----    -----------
*    00-01     height of sprite - 1 (eg. for a 16 x 16, the height would be 15)
*    02-03     transparency mask for top 16 bits
*    04-05     sprite data for bit plane 1 of the top 16 bits
*    06-07     sprite data for bit plane 2 of the top 16 bits
*    08-09     sprite data for bit plane 3 of the top 16 bits
*    0A-0B     sprite data for bit plane 4 of the top 16 bits
*     - -        -     -    -   -    -   -  -  -   -   -  -
*     - -        -     -    -   -    -   -  -  -   -   -  -
* etc.
*
*    Return value - ZILCH!!!
*
* Clock cycles now wrong but retained for approx reference:
*    Clock Cycles: 482+height*(98+(pos mod 8)*2+4*(94+2*(pos mod 8)))
*    Therefore, for a 16x16 sprite at 4,4, the time take is: 8706 cycles
*    Which, for a 7.6 MHz clock rate, is: 1.14 milli seconds
*    This is a bandwidth of approximately 112232 bytes a second.
*

Sprite:
          ext.l     D0                   (4) extend D0 to longword
          move.l    D0,D7                (4) copy the X-Position
          ext.l     D1                   (4) extend D1 to longword
          move.l    D1,D6                (4) copy the Y-Position

*    Check the boundaries
	  cmp.w #ScreenXSize,d0
          bcc     SpriteExit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

          cmp.w     #ScreenYSize,D1              (8) Ypos off the screen ?
          bcc     SpriteExit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

 move.b ScreenResolution,d3
 cmp.b #2,d3
 beq MonoSprite

*    Determine the byte offset of the sprite on the screen

         mulu      #160,D1              (<70) find the Y-Pos offset ;>>
	 btst #3,d7 ;>>left of right byte within word
	 beq.s LeftHalf ;>> left or right byte within word
	 add.l #1,d1 ;>>

LeftHalf
	 and.w #$fff0,d7 ;>> find offset of word within line
	 asr.w #1,d7 ;>>
         add.l     D7,D1                (4) add the X-Pos offset

*    Determine the bit shift of the sprite

          andi.l    #7,D0     (14) remove all but the low three bits
          bclr      #0,D1     (14) test for even-ness and clear
          beq.s     SKP1      (8) if even skip to SKP1
          addq.b    #8,D0     (4) otherwise increment the shift by 8

*    Loop preparations

SKP1
 move.w #19,d7 * height of sprite

*    The two main loops

LP1
          cmp.w     #192,D6              (8) is current Y-Pos past the bottom ?
          bcc.s     SpriteExit1             (10/8) Yes - jump to 'Exit'

          moveq     #3,D3                (4) set up our bit plane counter

          move.w    (A3)+,D4             (8) get our transparency mask
          swap      D4                   (4) put it into the top 16 bits
          move.w    #-1,D4               (8) add the normal mask
          ror.l     D0,D4             (8+2n) and shift it 0-15 bits to the right
*>> split transparency mask into left (d4) and right (d2) words
 move.w d4,d2 ;>>
 swap d4 ;>>

 move.l a2,a0 ;>>
 add.l d1,a0 ;>>

;=========================
* alternatively, do      !
* move.l (a3),d5	 !
* addq.l #2,a3		 !
* clr.w d5		 !
* Which MIGHT be faster  !
*			 !
* Use longs? (for mask at least?)
;=========================
; first bp
        move.w    (A3)+,D5             (8) get the pattern for this bitplane
        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,8(a0)
	or.w d5,8(a0)
	swap d5
	or.w d5,(a0)
	addq.l #2,a0

; second bp
        move.w    (A3)+,D5             (8) get the pattern for this bitplane
        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,8(a0)
	or.w d5,8(a0)
	swap d5
	or.w d5,(a0)
	addq.l #2,a0

; third bp
        move.w    (A3)+,D5             (8) get the pattern for this bitplane
        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,8(a0)
	or.w d5,8(a0)
	swap d5
	or.w d5,(a0)
	addq.l #2,a0

; fourth bp
        move.w    (A3)+,D5             (8) get the pattern for this bitplane
        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,8(a0)
	or.w d5,8(a0)
	swap d5
	or.w d5,(a0)
	addq.l #2,a0
          add.w     #160,D1   ;>>   (8) add bytes per row to screen pos
          addq.w    #1,D6                (8) increment the Y-Position by one

          dbra       D7,LP1            (10+4) end of sprite ?

SpriteExit1
          rts                           (16) bye bye ...

;------------------------------

LRSprite:
; plot sprite Left-RightReversed. Overwise as for normal sprite plot
          ext.l     D0                   (4) extend D0 to longword
          move.l    D0,D7                (4) copy the X-Position
          ext.l     D1                   (4) extend D1 to longword
          move.l    D1,D6                (4) copy the Y-Position

*    Check the boundaries
	  cmp.w #ScreenXSize,d0
          bcc     SpriteExit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

          cmp.w     #ScreenYSize,D1              (8) Ypos off the screen ?
          bcc     SpriteExit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

 move.b ScreenResolution,d3
 cmp.b #2,d3
 beq MonoSprite ; don't have mono LR routine yet

*    Determine the byte offset of the sprite on the screen
         mulu      #160,D1              (<70) find the Y-Pos offset ;>>
	 btst #3,d7 ;>>left of right byte within word
	 beq.s LRLeftHalf ;>> left or right byte within word
	 add.l #1,d1 ;>>

LRLeftHalf
	 and.w #$fff0,d7 ;>> find offset of word within line
	 asr.w #1,d7 ;>>
         add.l     D7,D1                (4) add the X-Pos offset

*    Determine the bit shift of the sprite
          andi.l    #7,D0     (14) remove all but the low three bits
          bclr      #0,D1     (14) test for even-ness and clear
          beq.s     LRSKP1      (8) if even skip to SKP1
          addq.b    #8,D0     (4) otherwise increment the shift by 8

*    Loop preparations
LRSKP1
 move.w #19,d7 * height of sprite
*    The two main loops
 clr.w d3 ; used as byte-index in word-index addressing mode throughout
* hence must clear bits 8-15
 lea LRTable,a1 * gives reversal table in format
* RR00 so we can extract it either as low or high-order byte of word
LRLP1
          cmp.w     #192,D6              (8) is current Y-Pos past the bottom ?
          bcc.s     SpriteExit1             (10/8) Yes - jump to 'Exit'
;          move.w    (A3)+,D4             (8) get our transparency mask
; LR reverse transparency mask using look-up table
 clr.w d4
 clr.w d3
 move.b (a3)+,d3 * get left 8 pels. bits 8-15 of d3 ARE zero.
 asl.w #1,d3 * get word-index into table
 move.b (a1,d3),d4 * get it reversed in low-order
 clr.w d3
 move.b (a3)+,d3 * get right 8 pels
 asl.w #1,d3
 or.w 0(a1,d3),d4

          swap      D4                   (4) put it into the top 16 bits
          move.w    #-1,D4               (8) add the normal mask
          ror.l     D0,D4             (8+2n) and shift it 0-15 bits to the right
*>> split transparency mask into left (d4) and right (d2) words
 move.w d4,d2 ;>>
 swap d4 ;>>
 move.l a2,a0 ;>>
 add.l d1,a0 ;>>

;=========================
* alternatively, do      !
* move.l (a3),d5	 !
* addq.l #2,a3		 !
* clr.w d5		 !
* Which MIGHT be faster  !
*			 !
* Use longs? (for mask at least?)
;=========================
LRBPMacro macro
;        move.w    (A3)+,D5             (8) get the pattern for this bitplane
; LR reverse data using look-up table
	clr.w d5
	clr.w d3
	move.b (a3)+,d3 * get left 8 pels. bits 8-15 of d3 ARE zero.
	asl.w #1,d3
	move.b (a1,d3),d5 * get it reversed in low-order
	clr.w d3
	move.b (a3)+,d3 * get right 8 pels
	asl.w #1,d3
	or.w 0(a1,d3),d5

        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,8(a0)
	or.w d5,8(a0)
	swap d5
	or.w d5,(a0)
	addq.l #2,a0
	endm

 LRBPMacro
 LRBPMacro
 LRBPMacro
 LRBPMacro

          add.w     #160,D1   ;>>   (8) add bytes per row to screen pos
          addq.w    #1,D6                (8) increment the Y-Position by one

          dbra       D7,LRLP1            (10+4) end of sprite ?
          rts                           (16) bye bye ...








;;-----------------------------
*----------
* Mono version of sprite routine...

MonoSprite
*    Determine the byte offset of the sprite on the screen
         mulu      #160,D1              (<70) find the Y-Pos offset ;>>
;	 btst #3,d7 ;>>left or right byte within word
;	 beq.s MonoLeftHalf ;>> left or right byte within word
;	 add.l #1,d1 ;>>

MonoLeftHalf
;	 and.w #$fffc,d7 ;>> find offset of word within line
	 asr.w #2,d7 ;>>
         add.l     D7,D1                (4) add the X-Pos offset

*    Determine the bit shift of the sprite

          andi.l    #7,D0     (14) remove all but the low three bits
          bclr      #0,D1     (14) test for even-ness and clear
          beq.s     MonoSKP1      (8) if even skip to SKP1
          addq.b    #8,D0     (4) otherwise increment the shift by 8

*    Loop preparations
MonoSKP1
 move.w #19,d7 * height of sprite

*    The main loop

MonoLP1
          cmp.w     #192,D6        (8) is current Y-Pos past the bottom?
          bcc     MonoSpriteExit1  (10/8) Yes - jump to 'Exit'

;;          moveq     #3,D3          (4) set up our bit plane counter
          move.w    (A3)+,D4       (8) get our transparency mask
          swap      D4             (4) put it into the top 16 bits
          move.w    #-1,D4         (8) add the normal mask
          ror.l     D0,D4          (8+2n) and shift it 0-15 bits to the right
*>> split transparency mask into left (d4) and right (d2) words
 move.w d4,d2 ;>>
 swap d4 ;>>

 move.l a2,a0 ;>>
 add.l d1,a0 ;>>

;=========================
* alternatively, do      !
* move.l (a3),d5	 !
* addq.l #2,a3		 !
* clr.w d5		 !
* Which MIGHT be faster  !
*			 !
* Use longs? (for mask at least?)
;=========================
; first bp
        move.w    (A3)+,D5             (8) get the pattern for this bitplane
        swap      D5                   (4) put it into the top 16 bits
        clr.w     D5                   (4) clear the bottom bits
        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
	and.w d4,(a0)
	and.w d2,2(a0)
	or.w d5,2(a0)
	swap d5
	or.w d5,(a0)
	add.l #6,a3 * skip unused bp data

;; second bp
;        move.w    (A3)+,D5             (8) get the pattern for this bitplane
;        swap      D5                   (4) put it into the top 16 bits
;        clr.w     D5                   (4) clear the bottom bits
;        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
;	and.w d4,2(a0)
;	and.w d2,6(a0)
;	or.w d5,6(a0)
;	swap d5
;	or.w d5,2(a0)
;;	addq.l #2,a0
;
;; third bp
;        move.w    (A3)+,D5             (8) get the pattern for this bitplane
;        swap      D5                   (4) put it into the top 16 bits
;        clr.w     D5                   (4) clear the bottom bits
;        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
;	and.w d4,80(a0)
;	and.w d2,84(a0)
;	or.w d5,84(a0)
;	swap d5
;	or.w d5,80(a0)
;;	addq.l #2,a0
;
;; fourth bp
;        move.w    (A3)+,D5             (8) get the pattern for this bitplane
;        swap      D5                   (4) put it into the top 16 bits
;        clr.w     D5                   (4) clear the bottom bits
;        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
;	and.w d4,82(a0)
;	and.w d2,86(a0)
;	or.w d5,86(a0)
;	swap d5
;	or.w d5,82(a0)

        add.w     #160,D1   ;>>   (8) add bytes per row to screen pos
        addq.w    #1,D6                (8) increment the Y-Position by one
        dbra       D7,MonoLP1            (10+4) end of sprite ?

MonoSpriteExit1
          rts                           (16) bye bye ...










*-----------
*
*    The Lattice C environment front end for the Sprite routine.
*

_Sprite:
          movem.l   D2/A2/A3,-(SP)      (32) save used registers
          move.l    16(SP),A2           (16) get the first argument
          move.l    20(SP),A3           (16) get the second argument
          move.l    24(SP),D0           (16) get the third argument
          move.l    28(SP),D1           (16) get the fourth argument
          move.l    32(SP),D2           (16) get the fifth argument
          bsr       Sprite              (20) jump to 'Sprite'
          movem.l   (SP)+,D2/A2/A3      (36) restore saved registers
          rts                           (16) bye bye ...

*
*         ReplaceBckgnd(XPos, YPos, Height, From, To);
*                        D0    D1     D2     A0   A1
*

ReplaceBckgnd:
          movem.l   D3-D4/A2-A3,-(SP)   (32) save used registers

          cmpi.b    #240,D0              (8) is it on the edge ?
          bne.s     SKP3              (10/8) NO - skip to 'SKP3'
          subq.b    #1,D0                (8) subtract one

SKP3      lsr.w     #3,D0               (12) divide by eight
          andi.l    #30,D0              (16) ignore low bit
          move.w    D1,D3                (4) copy the YPos
          mulu      #40,D1             (<70) screen Y displacement
          mulu      #36,D3             (<70) work area Y displacement
          add.l     D0,D1                (8) screen offset
          add.l     D0,D3                (8) work area offset

          moveq     #3,D0                (4) initialize the height counter

LP5       move.l    (A0)+,A3            (12) work area BitPlane pointer
          add.l     D3,A3                (8) add the offset
          addq.l    #2,A3                (8) skip the margin
          move.l    (A1)+,A2            (12) screen BitPlane pointer
          add.l     D1,A2                (8) add the offset

          move.w    D2,D4                (4) initialize the height counter

LP6       move.l    (A3),(A2)           (20) move a longword

          add.l     #40,A2              (16) next line on screen
          add.l     #36,A3              (16) next line in work area

          dbra      D4,LP6            (10+4) end of sprite height ?

          dbra      D0,LP5            (10+4) end of BitPlanes ?

          movem.l   (SP)+,D3-D4/A2-A3   (36) restore saved registers
          rts                           (16) bye bye ...

*
*    The Lattice C environment front end for the RestoreBckgnd() routine:
*

_ReplaceBckgnd:
          move.l    D2,-(SP)            (12) save used register
          move.l    8(SP),D0            (16) get the first argument
          move.l    12(SP),D1            (16) get the second argument
          move.l    16(SP),D2           (16) get the third argument
          move.l    20(SP),A0           (16) get the fourth argument
          move.l    24(SP),A1           (16) get the fifth argument
          bsr       ReplaceBckgnd       (20) jump to 'ReplaceBckgnd'
          move.l    (SP)+,D2            (12) restore saved register
          rts                           (16) bye bye ...

;-----------------
