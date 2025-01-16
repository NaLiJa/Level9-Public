
*
*    Sprite Display Routines, Mark III - A Four Hit Die Monster !!!
*
*    Copyright (c) 1987 Level 9 Computing & Leon Thrane. All Rights Reserved
*    9 Mendip Road, Crown Wood, Bracknell, Berkshire RG12 3XG - (0344) 487597
*
*    Author: Leon Thrane (July 1987)
*

ScreenXSize equ 256
ScreenYSize equ 192

;          IDNT      "Sprite.o"
;
;          XDEF      _Sprite
;          XDEF      Sprite
;          XDEF      _ReplaceBckgnd
;          XDEF      ReplaceBckgnd

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
*    Clock Cycles: 482+height*(98+(pos mod 8)*2+4*(94+2*(pos mod 8)))
*    Therefore, for a 16x16 sprite at 4,4, the time take is: 8706 cycles
*    Which, for a 7.6 MHz clock rate, is: 1.14 milli seconds
*    This is a bandwidth of approximately 112232 bytes a second.
*

Sprite:
;>>          movem.l   D3-D7/A0-A1,-(SP)   (96) save the vulnerable registers

          ext.l     D0                   (4) extend D0 to longword
          move.l    D0,D7                (4) copy the X-Position
          ext.l     D1                   (4) extend D1 to longword
          move.l    D1,D6                (4) copy the Y-Position

*    Check the boundaries

*>>(redundant) tst.w     D0                   (4) test the XPos
*>>(redundant) bmi.s     Exit1                (8) if negative jump to 'Exit'
*          cmp.w     #304,D0              (8) end of line ?
 cmp.w #ScreenXSize,d0
          bcc     Exit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

          cmp.w     #ScreenYSize,D1              (8) Ypos off the screen ?
          bcc     Exit1   *>> unsigned >=  (8) Yes - jump to 'Exit'

*    Determine the byte offset of the sprite on the screen

;>>          mulu      d2,D1              (<70) find the Y-Pos offset
          mulu      #160,D1              (<70) find the Y-Pos offset ;>>
;>>          lsr.l     #3,D7               (14) find the X-Pos byte offset
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
;      move.w    (A3)+,D7             (8) set up our height counter
 move.w #19,d7 * height of sprite

*    The two main loops

LP1
*>>redundant          tst.w     D6                   (4) is current Y-Pos negative ?
*>>Redundant          bmi.s     SKP2              (10/8) Yes - skip to SKP2
          cmp.w     #192,D6              (8) is current Y-Pos past the bottom ?
          bcc.s     Exit1             (10/8) Yes - jump to 'Exit'

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

LP2
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
;        move.w    (A3)+,D5             (8) get the pattern for this bitplane
;        swap      D5                   (4) put it into the top 16 bits
;        clr.w     D5                   (4) clear the bottom bits
;        lsr.l     D0,D5    (8+2n) and shift it 0-15 bits to the right
;	and.w d4,(a0) ;>>
;	and.w d2,8(a0) ;>>
;	or.w d5,8(a0) ;>>
;	swap d5 ;>>
;	or.w d5,(a0) ;>>
;	addq.l #2,a0 ;>>
;        dbra       D3,LP2            (10+4) end of current Y-Position ?

          add.w     #160,D1   ;>>   (8) add bytes per row to screen pos
SKP2      addq.w    #1,D6                (8) increment the Y-Position by one

          dbra       D7,LP1            (10+4) end of sprite ?

*    Exit from sprite routine

Exit1
;>>     movem.l   (SP)+,D3-D7/A0-A1   (52) restore the vulnerable registers
          rts                           (16) bye bye ...

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
          jsr       Sprite              (20) jump to 'Sprite'
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
          jsr       ReplaceBckgnd       (20) jump to 'ReplaceBckgnd'
          move.l    (SP)+,D2            (12) restore saved register
          rts                           (16) bye bye ...

