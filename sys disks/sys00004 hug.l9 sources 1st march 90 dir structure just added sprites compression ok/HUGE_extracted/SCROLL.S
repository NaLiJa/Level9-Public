 ifnd MCStart
 include 'Condit.s'
 endc

; SCROLL.S
;
; Scrolling extensions to ST/Amiga system
;
; M.J.Austin, July 1989
;
; Copyright (C) 1989 Level 9 Computing
;
*               Signed  Unsigned 
* >=            BGE     BCC 
* >             BGT     BHI 
* =             BEQ     BEQ 
* <>            BNE     BNE 
* <=            BLE     BLS 
* <             BLT     BCS 
;

* 2/2/90. Finally finished (touch wood etc.) There is one kludge -
* completeMoveleft and right build the cell below the top one
* as a patch to get rid of a single pixel line which gets corrupted
* on diagonal down movement (left and right: the opposite edge).
* I suspect this may be to do with Copy Row wrapping round
* and hence dropping down a pixel line, but I can't be bothered
* to track it to its lair.

* Another slight inelegancy is that CopyRow does a complete line
* each time, but gets clipped off (it is conceivable that this
* is connected to the above).

VisibleDebugging equ 0
DebugShifts equ 0
;
;
;
; Keeps a large ground-map, of the size we wish to be able to
; scroll within. As the screen moves, we need to build up the
; links for the line of cells (horizontal and/or vertical) which
; are revealed, and destroy the links for the line(s) hidden.
; Likewise for the cumulative "BufferScreen1".

; But, for the ST at least (MAC?), we need to have a system
; for fast software scrolling. The best of these appears to
; be that used for Adept - which requires the screen be rebuilt
; from pre-scrolled cells each time.
;
; (How does this affect the building of the cumulative map?)
; - probably not at all, because cumulative cells are built
; at BuildViewMap time - for ENTIRE map, not just the visible
; area

ScrollBuildViewMap
; build cumulative cells, transparencies(?) for entire screen.
; build links for visible area.
;
; How are we to keep a record of these?
; If we store entire cell map (for each scroll position)
; this requires 4000 entries per position, i.e. 32K in total
; JUST for the pointers.
; Other options include:
; * build cumulative cells with each line.
; * keep record of main cell numbers, and which
;   combined cells are formed when a given set of adjacent
;   cells are scrolled.
;
; Complication vs Adept: we don't know which cumulative cells
; are the same (or what their 'number' is). Therefore, whenever
; we create a new cumulative cell, we'll have to do a whole heap
; of comparisons. This rather implies that we should at least
; store cumulative cells for the unscrolled position.
;
; Actually, of course, we know which cells have been used to
; construct the cumulative cells, so it might be possible to
; use this fact.
;
; Even if we do have to do bulk comparisons, in many cases, there
; will be no 3D structure, so we can just use the ground cell
; number.

; BUILD ROOM - construct cumulative cells, produce scrolled
;   versions of cumulative cells by making up a list of
;   cell number pairs (Assigning cell numbers to cumulative
;   cells).
;
; SCROLL - build new line of cells, including cumulatives. Check
;  each cumulative for equivalence with an existing one. Produce
;  scrolled version of all cells, as in BuildRoom.
;
;
;
; We need to maintain a gmap buffer of at least the following size:
;
;
;  0  1  2  3  4  ...........................   20  21
;
;     ^Displayed left limit.  DisplayedRightLimit^
;
; This is so as each line is added (moving right, 21), the new
; pairs for the previous extremity (20) can be added to produce
; its (20's) scrolled version.
; 
; Similar logic applies for vertical scrolling, where we need
; 2 more cell rows than for the non-scrolling case.
;
;
DummyColumnY equ 13 * where we build the column off-screen
* in the buffer-screen.
OffScreenRowY equ 14 * where we build the row off-screen

ScreenXFirstCell dc.w 0 * basic x position of screen within map
ScreenYFirstCell dc.w 0 * basic y position of screen within map
ScreenXLastCell dc.w 0 * last cell which is on-screen
ScreenYLastCell dc.w 0
ScreenXFirstPixel dc.w 0 * basic x position of screen within map
ScreenYFirstPixel dc.w 0 * basic y position of screen within map
ScreenXLastPixel dc.w 0 * last cell which is on-screen
ScreenYLastPixel dc.w 0
ScreenXFirstPixelSmooth dc.w 0
ScreenYFirstPixelSmooth dc.w 0
CurrentRowCell dc.w 0
CurrentColumnCell dc.w 0
ColumnXStart dc.w 0
ColumnYStart dc.w 0
RowXStart dc.w 0
RowYStart dc.w 0
ColumnMapXCell dc.w 0 * place on map actually built at
ColumnMapYCell dc.w 0
RowMapXCell dc.w 0
RowMapYCell dc.w 0
BSSizeDisplayedPlane dc.l 0
BSSizeDisplayedPlaneMinus16Lines dc.l 0

LastXDirection dc.w 0
LastYDirection dc.w 0

BSXCellPos dc.w 0

ColumnBuildAddress dc.l 0
RowBuildAddress dc.l 0
BSOneDirectionSpace equ 80 * the number of bytes over which
* the BS can move horizontally in one direction before
* needing a physical copy to scroll.

;-----
MCSetMaxFrameRate
 rts
;---------
MCScrollDirection
*  called from acode - parameters are 2(a4)=x step, 4(a4)=y step pixels
* and return is 2(a4)=actual x step, 4(a4)=actual y step.
* This subroutine should make any and all modifications needed
* to the map and bufferscreen1 so that the next DisplayRoom
* will show the correct stuff.

* Remember that we need to advance-build a line in sections
* when we're scrolling at small increments. i.e. for moving at
* 4-pixel jumps, we must build 1 quarter of the new line(s) on
* each occasion.
 ifeq ScrollingSystem
  move.w #0,2(a4) * we haven't scrolled anywhere.
  move.w #0,4(a4)
 endc

 movem.l d0-d7/a0-a6,-(sp) ****** necessary?
  move.l a4,-(sp)
   bsr BuildSomeMoreColumn
  move.l (sp)+,a4
  move.l a4,-(sp)
   bsr BuildSomeMoreRow
  move.l (sp)+,a4
 movem.l (sp)+,d0-d7/a0-a6
 move.w 2(a4),d0
 beq.s MCSDNotHorizontal
 bpl.s MCSDRight
; MCSDLeft
 add.w d0,ScrollXPos
 bpl.s MCSDNotHorizontal
 add.w #16,d0
 move.w d0,ScrollXPos
 bsr CompleteMoveLeft
 bra.s MCSDNotHorizontal

MCSDRight
 add.w d0,ScrollXPos
 move.w ScrollXPos,d0
 cmp.w #16,d0
 bcs.s MCSDNotHorizontal
 sub.w #16,d0
 move.w d0,ScrollXPos
 bsr CompleteMoveRight

MCSDNotHorizontal

 move.w 4(a4),d0
 beq.s MCSDNotVertical
 bpl.s MCSDDown
; MCSDUp
 add.w d0,ScrollYPos
 bpl.s MCSDNotVertical
 add.w #16,d0
 move.w d0,ScrollYPos
 bsr CompleteMoveUp
 bra.s MCSDNotVertical

MCSDDown
 add.w d0,ScrollYPos
 move.w ScrollYPos,d0
 cmp.w #16,d0
 bcs.s MCSDNotVertical
 sub.w #16,d0
 move.w d0,ScrollYPos
 bsr CompleteMoveDown

MCSDNotVertical
 rts
;---
CompleteMoveLeft
 movem.l d0-d7/a0-a6,-(sp)
 bsr MoveBSLeft

 move.w #11,d0 * cells of column to do-1
 move.l #0,d1 * x pos
 move.w #0,d2 * y pos
 add.w ScreenXFirstCell-S(A5),d1
 add.w ScreenYFirstCell-S(A5),d2
 bsr UnlinkColumn

 movem.l (sp)+,d0-d7/a0-a6 ******
 movem.l d0-d7/a0-a6,-(sp) *****
;; call buildcolumn with appropriate offset
; move.w #11,d0 * cells of column to do-1
; move.l #20,d1 * x pos
; add.w ScreenXFirstCell-S(A5),d1
; bsr BuildRemainingColumn

 move.l a4,-(sp)
; change map offset
 add.w #1,ScreenXFirstCell-S(A5)
 bsr CalculateScreenPos

; call buildcolumn with appropriate offset
 move.w #11,d0 * cells of column to do-1
 move.l #20,d1 * x pos
 add.w ScreenXFirstCell-S(A5),d1
 bsr BuildRemainingColumn

 move.l (sp)+,a4

; move.w ColumnXStart-S(A5),d1
; move.w ScreenYFirstCell-S(A5),d2
; add.w #1,d2
; move.w #1,d0
; bsr BuildColumnDirectly **kludge 2/2/90


 bsr PatchColumn

; move.w #1,d0 * number of cells to build-1
; move.w ScreenXFirstCell-S(A5),d1 * position within row
; add.w #19,d1
; move.w ScreenYFirstCell-S(A5),d2 * position within row
; bsr BuildRowDirectly
; move.w #0,d0 * number of cells to build-1
; move.w ScreenXFirstCell-S(A5),d1 * position within row
; add.w #19,d1
; move.w ScreenYFirstCell-S(A5),d2 * position within row
; add.w #1,d2
; bsr BuildColumnDirectly

 movem.l (sp)+,d0-d7/a0-a6
 rts
;------
CompleteMoveRight
 movem.l d0-d7/a0-a6,-(sp)
  bsr MoveBSRight

  move.w #11,d0 * cells of column to do-1
  move.l #20,d1 * x pos
  move.w #0,d2 * y pos
  add.w ScreenXFirstCell-S(A5),d1
  add.w ScreenYFirstCell-S(A5),d2
  bsr UnlinkColumn

 movem.l (sp)+,d0-d7/a0-a6 ******
 movem.l d0-d7/a0-a6,-(sp) *****
;; call buildcolumn with appropriate offset
;  move.w #1,d0 * cells of column to do-1
***  move.l #0,d1 * x pos
;  move.w #0,d2 * y pos

; move.w ScreenXFirstCell-S(A5),d1
;;  add.w ScreenYFirstCell,d2
;  bsr BuildRemainingColumn

 move.l a4,-(sp)
; change map offset
  sub.w #1,ScreenXFirstCell-S(A5)
  bsr CalculateScreenPos

 move.w ScreenXFirstCell-S(A5),d1
;  add.w ScreenYFirstCell,d2
  bsr BuildRemainingColumn
 move.l (sp)+,a4


; move.w ColumnXStart-S(A5),d1
; move.w ScreenYFirstCell-S(A5),d2
; add.w #1,d2
; move.w #1,d0
; bsr BuildColumnDirectly **kludge 2/2/90


  bsr PatchColumn

 movem.l (sp)+,d0-d7/a0-a6
 rts
;--------
CompleteMoveUp
  movem.l d0-d7/a0-a6,-(sp)
  bsr MoveBSUp

  move.w #20,d0 * cells of row to do-1
  move.l #0,d1 * x pos
  move.w #0,d2 * y pos
  add.w ScreenXFirstCell-S(A5),d1
  add.w ScreenYFirstCell-S(A5),d2
  bsr UnlinkRow

 movem.l (sp)+,d0-d7/a0-a6 ******
 movem.l d0-d7/a0-a6,-(sp) *****
;;; call buildrow with appropriate offset
;  move.w #12,d2 * y pos
;  add.w ScreenYFirstCell-S(A5),d2
;  bsr BuildRemainingRow
;  bsr CopyRow
 move.l a4,-(sp)

; change map offset
  add.w #1,ScreenYFirstCell-S(A5)
  bsr CalculateScreenPos

;; call buildrow with appropriate offset
  move.w #12,d2 * y pos
  add.w ScreenYFirstCell-S(A5),d2
  bsr BuildRemainingRow


 move.l (sp)+,a4

  bsr PatchRow
* rebuild the last column, next to last cell
* to fix a little bug, seemingly in PatchRow: when moving up, right
* the bottom right of the screen gets a single pixel line, one
* cell corrupted.
 move.w #1,d0 * number of cells to build-1
 move.w ScreenXFirstCell-S(A5),d1 * position within row
 add.w #20,d1
 move.w ScreenYFirstCell-S(A5),d2 * position within row
 add.w #11,d2
 bsr BuildRowDirectly

 movem.l (sp)+,d0-d7/a0-a6
 rts
;-------
CompleteMoveDown
  movem.l d0-d7/a0-a6,-(sp)
  bsr MoveBSDown
  move.w #20,d0 * cells of row to do-1
  move.l #0,d1 * x pos
  move.w #11,d2 * y pos
  add.w ScreenXFirstCell-S(A5),d1
  add.w ScreenYFirstCell-S(A5),d2
  bsr UnlinkRow

 movem.l (sp)+,d0-d7/a0-a6 ******
 movem.l d0-d7/a0-a6,-(sp) *****
;; call buildrow with appropriate offset
; move.w ScreenYFirstCell-S(A5),d2 * y pos
;  bsr BuildRemainingRow
;  bsr CopyRow

; change map offset
  sub.w #1,ScreenYFirstCell-S(A5)
 move.l a4,-(sp)
  bsr CalculateScreenPos

; call buildrow with appropriate offset
 move.w ScreenYFirstCell-S(A5),d2 * y pos
  bsr BuildRemainingRow
 move.l (sp)+,a4


  bsr PatchRow


; move.w #1,d0 * number of cells to build-1
; move.w ScreenXFirstCell-S(A5),d1 * position within row
; move.w ScreenYFirstCell-S(A5),d2 * position within row
; bsr BuildColumnDirectly
;
; move.w #1,d0 * number of cells to build-1
; move.w ScreenXFirstCell-S(A5),d1 * position within row
; move.w ScreenYFirstCell-S(A5),d2 * position within row
; add.w #19,d1
; bsr BuildColumnDirectly

 movem.l (sp)+,d0-d7/a0-a6
 rts

;-----------
CalculateScreenPos
 ifne ScrollingSystem
  move.w #20,d0
 endc
 ifeq ScrollingSystem
  move.w #19,d0
 endc
 add.w ScreenXFirstCell-S(A5),d0
 move.w d0,ScreenXLastCell-S(A5)
 asl.w #4,d0
 move.w d0,ScreenXLastPixel-S(A5)

 move.w #12,d0
 add.w ScreenYFirstCell-S(A5),d0
 move.w d0,ScreenYLastCell-S(A5)
 asl.w #4,d0
 move.w d0,ScreenYLastPixel-S(A5)

 move.w ScreenXFirstCell-S(A5),d0
 asl.w #4,d0
 move.w d0,ScreenXFirstPixel-S(A5)
 add.w ScrollXPos-S(A5),d0
 move.w d0,ScreenXFirstPixelSmooth-S(A5)

 move.w ScreenYFirstCell-S(A5),d0
 asl.w #4,d0
 move.w d0,ScreenYFirstPixel-S(A5)
 add.w ScrollYPos-S(A5),d0
 move.w d0,ScreenYFirstPixelSmooth-S(A5)

; move.w #16,d0
; sub.w ScrollYPos,d0
 move.w ScrollYPos-S(A5),d0
 mulu #ConstBytesPerBSLine,d0
 move.l #0,d0 *****
 ifne ST
  add.l #(ConstDisplayedYCells*16)*(ConstDisplayedXCells*BPC),d0
 endc
 ifne Amiga
  add.l #4*(ConstDisplayedYCells*16)*(ConstDisplayedXCells*BPC),d0
* 4 bit-planes
 endc
 move.l d0,BSSizeDisplayedPlane-S(A5)
 sub.l #(ConstDisplayedXCells*BPC)*16,d0
 move.l d0,BSSizeDisplayedPlaneMinus16Lines-S(A5)
 rts
;--------
BuildRoomScrolling
; extensions for buildroom for scrolling mode.
 movem.w d1-d2,-(sp)
  move.w #0,d1
  move.w #DummyColumnY,d2 * build a row (which pretends to be a column)
* after the real buffer screen i.e. at (0,13)
  bsr AbsCalcBufferScreenAddress
 movem.w (sp)+,d1-d2
 add.l #BSOneDirectionSpace,a0 * space for BS to move right
 move.l a0,ColumnBuildAddress-S(A5)

 movem.w d1-d2,-(sp)
  move.w #0,d1
  move.w #OffScreenRowY,d2 * build a row (which pretends to be a column)
* after the real buffer screen i.e. at (0,13)
  bsr AbsCalcBufferScreenAddress
 movem.w (sp)+,d1-d2
 add.l #BSOneDirectionSpace,a0 * space for BS to move right
 move.l a0,RowBuildAddress-S(A5)

 rts

;---
UnlinkColumn
* i.e. unbuild d0.w cells of a vertical column starting
* from d1.l,d2.w (cells)
* relative to the complete map.
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
* a1.l is the first g_map cell to unlink
 cmp.w MapXCells,d1
 bcc UnlinkColumnRet
UC1
 cmp.w MapYCells,d2
 bcc.s UC2
 movem.l d0-d2/a1,-(sp)
 bsr UnlinkA1
 movem.l (sp)+,d0-d2/a1
UC2
 add.l MapXCellsTimes4-2,a1 * address word as long
 add.w #1,d2 * y cell number
 dbra d0,UC1
UnlinkColumnRet
 rts
;---
UnlinkRow
* i.e. unbuild d0.w cells of a horizontal row starting
* from d1.l,d2.w (cells)
* relative to the complete map.
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
* a1.l is the first g_map cell to unlink
 cmp.w MapYCells,d2
 bcc UnlinkRowRet
UR1
 cmp.w MapXCells,d1
 bcc.s UR2
 movem.l d0-d2/a1,-(sp)
 bsr UnlinkA1
 movem.l (sp)+,d0-d2/a1
UR2
 add.l #4,a1 * next map cell
 add.w #1,d1 * x cell number
 dbra d0,UR1
UnlinkRowRet
 rts
;----
SplitTable
; for each step size (0..16), we have 2 sets of 16 values - which
; gives the numbers of cells to build for rows, columns
; each time we scroll, starting from the pixel offset.
; dc.b 1,3,4,5,6,8,9,11,12,14,15,16,17,18,19,21 * 1 pixel, row
; dc.b 1,1,2,3,4,5,6,7,8,8,9,10,11,11,12,13,13 * 1 pixel, column
; dc.b 1,3,4,5,6,8,9,11,12,14,15,16,16,16,16,16 * 1 pixel, row
; dc.b 1,1,2,3,4,5,6,7,8,8,8,8,8,8,8,8,8 * 1 pixel, column
 dc.b 1,3,4,5,6,8,9,11,12,14,15,16,17,18,19,20 * 1 pixel, row
 dc.b 1,1,2,3,4,5,6,7,8,8,9,10,11,11,12,12,12 * 1 pixel, column
 even

;-------------
BuildSomeMoreColumn
; work out which column we're trying to build...
 move.w 2(a4),d3 * x speed positive or negative?
 beq BSMCRet
 tst.w CurrentColumnCell-S(A5)
 beq.s BSMCCalc
 and.w #$8000,d3 * preserve sign bit only
 cmp.w LastXDirection-S(A5),d3
 beq.s BSMCSameDirection
 move.w d3,LastXDirection-S(a5)
BSMCCalc
* when changing direction, start building the column again.
 move.w #0,CurrentColumnCell-S(A5)
 move.w ScreenYFirstCell-S(A5),ColumnYStart-S(A5)
 move.w ScreenXFirstCell-S(A5),d1
 sub.w #1,d1 * when going right, we want the cell column left of
* the leftmost col currently displayed (i.e. the first not displayed)
 move.w 2(a4),d4
 bpl.s BSMCLeft
; scrolling to left, so build column starting at (20,0)
 add.w #20+2,d1 * x pos * width+1 to counter above sub, +1 for off-screen

BSMCLeft
 move.w d1,ColumnXStart-S(A5)

BSMCSameDirection
; move.w 2(a4),d4
; bpl.s BSMCRight
; neg d4
;
;BSMCRight
 move.w CurrentColumnCell-S(A5),d3 * position within column

 move.w ScrollXPos-S(A5),d5
 tst.w 2(a4)
 bpl.s BSMCPlus
* for going the other way, expectancy table works in reverse
 move.w #16,d5
 sub.w ScrollXPos-S(A5),d5

BSMCPlus
 lea SplitTable,a0
 clr.w d0
 move.b 16(a0,d5.w),d0 * get number of cells we should have built for
* this scroll position.
 sub.w d3,d0 * d0.w:=number of cells to build
 bmi.s BSMCRet
 beq.s BSMCRet

 move.w ColumnXStart-S(A5),d1
 move.w ColumnYStart-S(A5),d2
 add.w d3,d2
 bra BuildColumnMore

BSMCRet rts

;---
BuildSomeMoreRow
; work out which row we're trying to build...
 move.w 4(a4),d3 * y speed positive or negative?
 beq.s BSMCRet
 tst.w CurrentRowCell-S(A5)
 beq.s BSMRCalc
 and.w #$8000,d3 * preserve sign bit only
 cmp.w LastYDirection-S(A5),d3
 beq.s BSMRSameDirection
 move.w d3,LastYDirection-S(A5)
BSMRCalc
* when changing direction, must building the row again.
 move.w #0,CurrentRowCell-S(A5)
 move.w ScreenXFirstCell-S(A5),RowXStart-S(A5)
; now decide which row we're building
 move.w ScreenYFirstCell-S(A5),d2 * y pos
 sub.w #1,d2 * when going up, we want the cell row above
;* the top row currently displayed (i.e. the first not displayed)
 move.w 4(a4),d4
 bpl.s BSMRGotY
 add.w #12+2,d2 * y pos
* 12 rows on screen, so add on one to counter above subtract,
* and add on another to get the first row off-screen

BSMRGotY
 move.w d2,RowYStart-S(A5)



BSMRSameDirection
; move.w 4(a4),d4
; bpl.s BSMRDown
; neg d4
;
;BSMRDown
 move.w CurrentRowCell-S(A5),d3 * position within row for BuildRowMore
 move.w ScrollYPos-S(A5),d5
 tst.w 4(a4)
 bpl.s BSMRPlus
* for going the other way, expectancy table works in reverse
 move.w #16,d5
 sub.w ScrollYPos-S(A5),d5

BSMRPlus
 lea SplitTable,a0
 clr.w d0
 move.b (a0,d5.w),d0 * get number of cells we should have built for
* this scroll position.
 sub.w d3,d0 * d0.w:=number of cells to build
 bmi.s BSMCRet
 beq.s BSMCRet

 move.w RowXStart-S(A5),d1
 add.w d3,d1
 move.w RowYStart-S(A5),d2
 bra BuildRowMore
; move.w d1,d4 * cell we start building from relative to map.
; add.w d0,d4 * where will we finish?
; move.w d3,d4 * position relative to row
; add.w d0,d4
; cmp.w #21,d4
; bcs BuildRowMore * unsigned <, row pos goes 0..19+1
;* finish off end - so reduce the number of cells by the
;* appropriate amount
; sub.w #21,d4 * thus d3 becomes the excess amount
; sub.w d4,d0 * take off the excess amount
; beq.s BSMRRet * nothing more to do.
; bpl BuildRowMore * a positive amount to do.
;BSMRRet
 rts
;----
BuildRemainingColumn:
; move.w #0,CurrentColumnCell
; rts


 move.w 2(a4),d3
 and.w #$8000,d3 * sign bit only
 cmp.w LastXDirection-S(A5),d3
 beq.s BrCSameDirection
* when changing direction, start building the column again.
 move.w #0,CurrentColumnCell-S(A5)
 move.w ScreenYFirstCell-S(A5),d0
 move.w d0,ColumnYStart-S(A5)
; move.w ScreenXFirstCell,d0
; move.w d0,ColumnXStart
; move.w #0,ColumnMapXCell ************** unnecessary
; move.w #0,ColumnMapYCell ************** unnecessary
 move.w ScreenXFirstCell-S(A5),d1
 move.w 2(a4),d4
 bpl.s BRCRight
; scrolling to left, so build column starting at (20,0)
 add.w #20,d1

BRCRight
 move.w d1,ColumnXStart-S(A5)

BRCSameDirection
; work out y position of column to build
; move.w ColumnYStart,d2 * move.w CurrentColumnCell,d2 * position in column
; move.w ScreenYFirstCell,d2 *************
; move.w CurrentColumnCell,d3 * for columnystart
; add.w d3,d2 * for columnystart
; move.w #13,d0 * number of cells ****offset of last cell to build
; sub.w CurrentColumnCell,d0 * cells still to do
; bmi.s BRCCopy
; beq.s BRCCopy
;; sub.w #1,d0 *****
;; add.w #1,d0 *****
; move.w d1,-(sp)
;  bsr BuildColumn 
; move.w (sp)+,d1
; ifne VisibleDebugging
;  move.w #$8f08,(a0)
;  move.w #$80f8,168(a0)
;  move.w #$8f08,168*2(a0)
; endc

BRCCopy
* calculate coords on screen
 move.w ColumnYStart,d2 * move.w ScreenYFirstCell,d2

* reduce length to copy if we've shifted off
 move.w ScreenYFirstCell,d4
 sub.w ColumnYStart,d4
 bpl.s BRCCPlusReduce
 neg.w d4
BRCCPlusReduce
 move.w CurrentColumnCell,d0 * number of cells we've built
; sub.w d4,d0 * take off number of cells by which we have shifted
; bmi.s BRCCRet
* we ask copycolumn to do a whole column each time -
* some of it will be clipped off. This saves the hassle
* of working out which bits to actually copy, but is
* probably slower.
 movem.w d1-d2,-(sp)
  bsr CopyColumnCalculate
 movem.w (sp)+,d1-d2
BRCCRet
 rts
;-------
PatchColumn
* we've built cells between
* (ColumnXStart,ColumnYStart) and (ColumnXStart,ColumnYStart+CurrentColumnCell)
* These cells have also been copied from the off-screen column where
* they were built to their correct position on the screen.
* The purpose of this routine is to add cells on either side
* of this built area to avoid gaps.
 move.w ColumnYStart-S(A5),d0
 sub.w ScreenYFirstCell-S(A5),d0 * get size of gap at top, if any
 beq.s PatchColumnNoTop
 bmi.s PatchColumnNoTop
 move.w ColumnXStart-S(A5),d1
 move.w ScreenYFirstCell-S(A5),d2
 bsr BuildColumnDirectly

PatchColumnNoTop
 move.w ColumnYStart-S(A5),d0
 add.w CurrentColumnCell-S(A5),d0 * map position of cell to do next
 move.w d0,d2 * store off Y coord of first cell to build
 sub.w ScreenYFirstCell-S(A5),d0 * get column position rel. to screen
 bpl.s PCNT1
 neg.w d0
PCNT1
* d0.w is NUMBER of cells we have done
 cmp.w #14,d0
 bcc.s PatchColumnNoBottom
 move.w d0,d1 * temp
 move.w #13,d0
 sub.w d1,d0 * d0=number of cells still to build
 move.w ColumnXStart-S(A5),d1
; sub.w #1,d2
 add.w #2,d0
 bsr BuildColumnDirectly

PatchColumnNoBottom
 move.w #0,CurrentColumnCell
 move.w ScreenYFirstCell,d0
 move.w d0,ColumnYStart
 rts
;----
BuildRemainingRow
; d2.w is map y cell of row to build
; move.w #0,RowMapXCell ****
; move.w #0,CurrentRowCell ****
; rts


 move.w 4(a4),d3
 and.w #$8000,d3 * sign bit only
 cmp.w LastYDirection-S(A5),d3
 beq.s BrRSameDirection
* when changing direction, start building the column again.
 move.w #0,CurrentRowCell-S(A5)
 move.w ScreenXFirstCell-S(A5),d0
 move.w d0,RowXStart-S(A5)
 move.w ScreenYFirstCell-S(A5),d2 * y pos
 move.w 4(a4),d4
 bpl.s BRRGotY
 add.w #12,d2 * y pos

BRRGotY
 move.w d2,RowYStart-S(A5)

BRRSameDirection
;; move.w 4(a4),d3
; move.w CurrentRowCell,d3
;; work out x position to build within row
; move.w RowXStart,d1 * move.w CurrentRowCell,d1 * position in row
;; move.w ScreenXFirstCell,d1 *******
; add.w d3,d1
; move.w #21,d0 * mnumber of cells ****offset of last cell to build
; sub.w CurrentRowCell,d0 * cells still to do
; bmi.s BRRCopy
; beq.s BRRCopy
;
; move.w d2,-(sp)
;  bsr BuildRow 
; move.w (sp)+,d2
; ifne VisibleDebugging
;  move.w #$8008,(a0)
;  move.w #$8088,168(a0)
;  move.w #$0808,168*2(a0)
; endc

BRRCopy
 move.w RowXStart,d1 * copy a complete row. Starting at xcell=0
; move.w ScreenXFirstCell,d1 *********

* reduce length to copy if we#ve shifted off
 move.w ScreenXFirstCell,d4
 sub.w RowXStart,d4
 bpl.s BRRCPlusReduce
 neg.w d4
BRRCPlusReduce
; move.w #21,d0 *1/2/90 * number of cells in row to copy
 move.w CurrentRowCell-S(A5),d0 * number of cells built
; sub.w d4,d0 * reduce by number of cells we've shifted by.
; bmi.s BRREnd
* we ask copyrow to do a whole row each time -
* some of it will be clipped off. This saves the hassle
* of working out which bits to actually copy, but is
* probably slower.
 cmp.w #21,d0 * kludge ****
 bcs.s BBRCSmallEnough
 move.w #20,d0

BBRCSmallEnough
 movem.w d1-d2,-(sp)
  bsr CopyRowCalculate
 movem.w (sp)+,d1-d2

BRREnd
 rts
;-----
PatchRow
* we've built cells between
* (RowXStart,RowYStart) and (RowXStart+CurrentRowCell,RowYStart)
* These cells have also been copied from the off-screen rows where
* they were built to their correct position on the screen.
* The purpose of this routine is to add cells on either side
* of this built area to avoid gaps.
 move.w RowXStart-S(A5),d0
 sub.w ScreenXFirstCell-S(A5),d0 * get size of gap at left, if any
 beq.s PatchRowNoLeft
 bmi.s PatchRowNoLeft
 move.w ScreenXFirstCell-S(A5),d1
 move.w RowYStart-S(A5),d2
 bsr BuildRowDirectly

PatchRowNoLeft
 move.w RowXStart-S(A5),d0
 add.w CurrentRowCell-S(A5),d0 * map position of rightmost cell done
 move.w d0,d1 * store off x coord of first cell to build
 sub.w ScreenXFirstCell-S(A5),d0 * get column position rel. to screen
 bpl.s PRNL1
 neg.w d0
PRNL1
* d0.w is NUMBER of cells we have done.
 cmp.w #21,d0
 bcc.s PatchRowNoRight
 move.w d0,d2 * temp
 move.w #21,d0
 sub.w d2,d0 * d0=number of cells still to build
 move.w RowYStart-S(A5),d2
; sub.w #1,d1
; add.w #3,d0 ***********
 add.w #2,d0
 bsr BuildRowDirectly

PatchRowNoRight
 move.w #0,CurrentRowCell
 move.w ScreenXFirstCell,d0
 move.w d0,RowXStart
 move.w ScreenYFirstCell,d0
 move.w d0,RowYStart
 rts




;----
BuildColumnMore
; used by BuildSomeMore routines...
;BuildColumn:
 add.w d0,CurrentColumnCell-S(A5)
 sub.w #1,d0 * because BuildColumn uses dbra
 bmi.s BuildColumnMoreRet
; drop through to BuildColumn

* i.e. build d0.w cells of a vertical column starting from d1.l,d2.w (cells)
* relative to the complete map.
* at an off-screen column, cell d3.w within the column
 move.w d1,ColumnMapXCell
 move.w d2,ColumnMapYCell
 movem.w d0-d2,-(sp)
   bsr CalcMapAddress ; uses d1,d2 only.
  move.w d3,d1 * position within column on screen
  move.w #DummyColumnY,d2 * build a row (which pretends to be a column)
* after the real buffer screen i.e. at (0,13)
;  bsr AbsCalcBufferScreenAddress
 move.l ColumnBuildAddress,a0
 ext.l d3 * cell within column
 ifne Amiga
  add.l d3,a0
  add.l d3,a0 * 2 bytes per cell.
 endc
 ifne ST
  asl.l #3,d3 * times BPC: 8 bytes per cell
  add.l d3,a0
 endc

 movem.w (sp)+,d0-d2
; gets:
; a0.l as the buffer screen address,
; a1.l as the gmap address.

 movem.l d0-d2/a0,-(sp)
BuildColumn1
 bsr BuildRowFeature
 add.w #1,d2 * increment y position
;; add.l #BytesPerPixelLine*16,a0
 add.l #BPC,a0 * next word along (we're not exactly doing this as a column,
* remember
 add.l MapXCellsTimes4-2,a1 * treating word value as a long
 dbra d0,BuildColumn1
 movem.l (sp)+,d0-d2/a0
BuildColumnMoreRet
 rts
;-----
BuildColumnDirectly
* i.e. d0.w cells at d1.w,d2.w (cells)
* relative to the complete map.
* directly onto the screen
 movem.w d0-d2,-(sp)
;;  move.w ColumnMapXCell,d1
  bsr CalcMapAddress ; uses d1,d2 only.
 movem.w (sp)+,d0-d2
 movem.w d0-d2,-(sp)
  bsr CalcBufferScreenAddress ; from cell coords d1,d2
 movem.w (sp)+,d0-d2
; gets:
; a0.l as the buffer screen address,
; a1.l as the gmap address.

 movem.l d0-d2/a0,-(sp)
 sub.w #1,d0 * dec due to dbra
BCD1
 move.w d2,d3
 sub.w ScreenYFirstCell,d3
 cmp.w #13,d3 * greatest offset is 12 - i.e. 13 cells high
 bcc BCD2 * off-screen trap.
  bsr BuildRowFeature

 ifne VisibleDebugging
  move.w #65535,(a0)
  move.w #65535,168(a0)
  move.w #65535,168*2(a0)
 endc
BCD2
  add.w #1,d2 * increment y position
  add.l #ConstBytesPerBSLine*16,a0
  add.l MapXCellsTimes4-2,a1 * treating word value as a long
  dbra d0,BCD1
 movem.l (sp)+,d0-d2/a0
 rts


;----
BuildRowDirectly
* i.e. a cells at d1.w,d2.w (cells)
* relative to the complete map.
* directly onto the screen
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress ; uses d1,d2 only.
 movem.w (sp)+,d0-d2
 movem.w d0-d2,-(sp)
  bsr CalcBufferScreenAddress
 movem.w (sp)+,d0-d2
; gets:
; a0.l as the buffer screen address,
; a1.l as the gmap address.

; sub.l #4,a1 **********
; sub.l #2,a0 **********
; add.w #1,d0 **********

 movem.l d0-d2/a0,-(sp)
 sub.w #1,d0 * dec due to dbra
BRD1
 move.w d1,d3
 sub.w ScreenXFirstCell-S(A5),d3
 cmp.w #21,d3 * greatest offset allowed is 20: i.e. 21 cells wide
 bcc.s BRD2 * off screen
  bsr BuildRowFeature
 ifne VisibleDebugging
  move.w #$f0f0,(a0)
  move.w #$f0f0,168(a0)
  move.w #$f0f0,168*2(a0)
 endc
BRD2
  add.w #1,d1 * increment x position
  add.l #BPC,a0
  add.l #4,a1
  dbra d0,BRD1
 movem.l (sp)+,d0-d2/a0
 rts
;----
CopyColumnCalculate
; calculate the buffer screen address first
; and copy a complete column

; movem.w d1-d2,-(sp)
;  move.w #0,d1
;  move.w #DummyColumnY,d2 * build a row (which pretends to be a column)
;* after the real buffer screen i.e. at (0,13)
;  bsr AbsCalcBufferScreenAddress
; movem.w (sp)+,d1-d2
*1/2/90 move.w #ConstBSYCells-1,d0 * number of cells
 move.l ColumnBuildAddress-S(A5),a0

 ifne Amiga
CopyColumn
 tst.w d1
 bpl.s CopyColumnOnScreenX
 rts

CopyColumnOnScreenX

* now copy a row from a0.l - which is where we've built it -
* to a column at coords (d1.w,d2.w) which is the correct place
 movem.l d0/a0,-(sp)
  move.w d2,-(sp)
   bsr CalcBufferScreenAddress
  move.w (sp)+,d2 * y coord for screen.
 movem.l (sp)+,d0/a1 * number of cells, source address
 move.l BufferScreen1,a2
 move.l a2,a3
 ifne ST
 add.l #ConstBSPlaneSize-(ConstScreenXCells*2*15),a3 * 2 bytes per cell per plane
 endc
 ifne Amiga
 add.l #ConstBSPlaneSize*4-(ConstScreenXCells*2*15),a3 * 2 bytes per cell per plane
* 4 bit-planes
 endc
 ifne VisibleDebugging
  move.l a0,-(sp)
 endc

 sub.w #1,d0 * dec due to dbra
 sub.w ScreenYFirstCell,d2 * make relative to screen, not map

CopyColumn1
 cmp.l a2,a0
 bcs CopyColumn3 * off the start of the buffer screen
 cmp.l a3,a0
 bcc CopyColumn3 * off the end of the buffer screen

; move.l bufferScreen1-S(A5),a2
; add.l #(DummyColumnY*16*ConstBytesPerBSLine)+(13*2),a2 * 12 is max length of column
; cmp.l a2,a1
; bcc.s CopyColumn3 * off the end of the column

; move.w #4-1,d1 * 4 bitplanes
 tst.w d2
 bmi.s CopyColumn3

 move.w #(4*16)-5,d1 * 4 bit-planes, 16 words each
 cmp.w #13,d2
 bcc.s CopyColumn4 * 1a

 move.w #(4*16)-1,d1 * 4 bit-planes, 16 words each
CopyColumn1a
 movem.l a0-a1,-(sp)
CopyColumn2
; move.l BufferScreen1-S(A5),a2 *****
; cmp.l a2,a0
; bne.s CopyColNoBreak *****
; cmp.w #40,d1
; bcc.s CopyColNoBreak
; dc.w $4afa
;
;CopyColNoBreak *****


  move.w (a1),(a0)
  add.l BSPlaneSpacing,a0
  add.l BSPlaneSpacing,a1
  dbra d1,CopyColumn2
 movem.l (sp)+,a0-a1
CopyColumn3
 add.l #ConstBytesPerBSLine*16,a0
 add.l #2,a1
 add.w #1,d2 * increment y cell coordinate
 dbra d0,CopyColumn1
CopyColumn4
 ifne VisibleDebugging
  move.l (sp)+,a0 * place we started building at
  move.w #$c0cc,168(a0)
 endc

BuildColumnRet
BRMRet
 rts

 endc * Amiga
 ifne ST
CopyColumn
* now copy a row from a0.l - which is where we've built it -
* to a column at coords (d1.w,d2.w) which is the correct place
 movem.l d0/a0,-(sp)
  bsr CalcBufferScreenAddress
 movem.l (sp)+,d0/a1 * number of cells, source address
 move.l BufferScreen1,a2
 move.l a2,a3
 add.l #ConstBSSize-(ConstScreenXCells*BPC*15),a3 * 2 bytes per cell per plane

CopyColumn1
 cmp.l a2,a0
 bcs CopyColumn3 * off the start of the buffer screen
 cmp.l a3,a0
 bcc CopyColumn3 * off the end of the buffer screen
 movem.l a0-a1,-(sp)
CopyColumn2
  move.l (a1),(a0)
  move.l 4(a1),4(a0)
  move.l ConstBytesPerBSLine(a1),ConstBytesPerBSLine(a0)
  move.l ConstBytesPerBSLine+4(a1),ConstBytesPerBSLine+4(a0)
  move.l 2*ConstBytesPerBSLine(a1),2*ConstBytesPerBSLine(a0)
  move.l 2*ConstBytesPerBSLine+4(a1),2*ConstBytesPerBSLine+4(a0)
  move.l 3*ConstBytesPerBSLine(a1),3*ConstBytesPerBSLine(a0)
  move.l 3*ConstBytesPerBSLine+4(a1),3*ConstBytesPerBSLine+4(a0)
  move.l 4*ConstBytesPerBSLine(a1),4*ConstBytesPerBSLine(a0)
  move.l 4*ConstBytesPerBSLine+4(a1),4*ConstBytesPerBSLine+4(a0)
  move.l 5*ConstBytesPerBSLine(a1),5*ConstBytesPerBSLine(a0)
  move.l 5*ConstBytesPerBSLine+4(a1),5*ConstBytesPerBSLine+4(a0)
  move.l 6*ConstBytesPerBSLine(a1),6*ConstBytesPerBSLine(a0)
  move.l 6*ConstBytesPerBSLine+4(a1),6*ConstBytesPerBSLine+4(a0)
  move.l 7*ConstBytesPerBSLine(a1),7*ConstBytesPerBSLine(a0)
  move.l 7*ConstBytesPerBSLine+4(a1),7*ConstBytesPerBSLine+4(a0)
  move.l 8*ConstBytesPerBSLine(a1),8*ConstBytesPerBSLine(a0)
  move.l 8*ConstBytesPerBSLine+4(a1),8*ConstBytesPerBSLine+4(a0)
  move.l 9*ConstBytesPerBSLine(a1),9*ConstBytesPerBSLine(a0)
  move.l 9*ConstBytesPerBSLine+4(a1),9*ConstBytesPerBSLine+4(a0)
  move.l 10*ConstBytesPerBSLine(a1),10*ConstBytesPerBSLine(a0)
  move.l 10*ConstBytesPerBSLine+4(a1),10*ConstBytesPerBSLine+4(a0)
  move.l 11*ConstBytesPerBSLine(a1),11*ConstBytesPerBSLine(a0)
  move.l 11*ConstBytesPerBSLine+4(a1),11*ConstBytesPerBSLine+4(a0)
  move.l 12*ConstBytesPerBSLine(a1),12*ConstBytesPerBSLine(a0)
  move.l 12*ConstBytesPerBSLine+4(a1),12*ConstBytesPerBSLine+4(a0)
  move.l 13*ConstBytesPerBSLine(a1),13*ConstBytesPerBSLine(a0)
  move.l 13*ConstBytesPerBSLine+4(a1),13*ConstBytesPerBSLine+4(a0)
  move.l 14*ConstBytesPerBSLine(a1),14*ConstBytesPerBSLine(a0)
  move.l 14*ConstBytesPerBSLine+4(a1),14*ConstBytesPerBSLine+4(a0)
  move.l 15*ConstBytesPerBSLine(a1),15*ConstBytesPerBSLine(a0)
  move.l 15*ConstBytesPerBSLine+4(a1),15*ConstBytesPerBSLine+4(a0)
 movem.l (sp)+,a0-a1
CopyColumn3
 add.l #ConstBytesPerBSLine*16,a0
 add.l #BPC,a1
 dbra d0,CopyColumn1

BuildColumnRet
BRMRet
 rts

 endc * ST

;---

BuildRowMore
; used by BuildSomeMore routines...
 add.w d0,CurrentRowCell
;BuildRow:
 sub.w #1,d0 * because BuildRow uses dbra
 bmi.s BRMRet
; drop through to BuildRow

* i.e. build d0.w cells of a horizontal Row starting from d1.l,d2.w (cells)
* relative to the complete map.
; add.w #1,d2 * build one more down, should
;* be ok for scrolling the screen up.
; tst.w 4(a4) * which way are we going?
; bmi.s BR0
; sub.w #2,d2 * for going down, want one up (therefore -2)
;
;BR0
 move.w d1,RowMapXCell
 move.w d2,RowMapYCell
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
; a1.l as the gmap address.
;  move.w d3,d1 * cell within off-screen row.
;  move.w #OffScreenRowY,d2 * build a row
;* after the real buffer screen i.e. at (0,14)
;  bsr AbsCalcBufferScreenAddress
  move.l RowBuildAddress-S(A5),a0
  ext.l d3 * cell within row
  add.l d3,a0
  add.l d3,a0 * 2 bytes per cell
 ifne ST
  asl.l #3,d3 * times BPC: 8 on ST
  add.l d3,a0
 endc

 movem.w (sp)+,d0-d2
; gets:
; a0.l as the buffer screen address,

 movem.l d0-d2/a0,-(sp)
BuildRow1
 bsr BuildRowFeature
 add.w #1,d1 * increment x cell
 add.l #BPC,a0 * next word along
 add.l #4,a1
 dbra d0,BuildRow1
 movem.l (sp)+,d0-d2/a0
 rts
;------
CopyRowCalculate
; calculate the buffer screen address first
; and copy a complete row

; movem.w d1-d2,-(sp)
;  move.w #0,d1
;  move.w #OffScreenRowY,d2 * build a row
;* after the real buffer screen i.e. at (0,14)
;  bsr AbsCalcBufferScreenAddress
; movem.w (sp)+,d1-d2
 move.l RowBuildAddress-S(A5),a0

 ifne Amiga
CopyRow
* now copy a row from a0.l - which is where we've built it -
* to a Row at coords (d1.w,d2.w) which is the correct place
 tst.w d2
 bpl.s CopyRowPlus
 rts

CopyRowPlus
 movem.l d0/a0,-(sp)
  move.w d1,-(sp)
   bsr CalcBufferScreenAddress
  move.w (sp)+,d1
 movem.l (sp)+,d0/a1 * number of cells, source address
 move.l BufferScreen1,a2

; move.l a2,a3
; ifne ST
; add.l #ConstBSPlaneSize-(ConstScreenXCells*2*15),a3 * 2 bytes per cell per plane
; endc
; ifne Amiga
; add.l #(ConstBSPlaneSize*4)-(ConstScreenXCells*2*15),a3 * 2 bytes per cell per plane
;* 4 bit-planes
; endc
 ifne VisibleDebugging
  move.l a0,-(sp)
 endc

 sub.w ScreenXFirstCell,d1 * make relative to screen, not map
 sub.w #1,d0 * dec due to dbra

CopyRow1
; cmp.l a2,a0
; bcs CopyRow3 * off the start of the buffer screen
; cmp.l a3,a0
; bcc CopyRow3 * off the end of the buffer screen

; move.w #4-1,d1 * 4 bitplanes

; move.l bufferScreen1-S(A5),a2
; add.l #(OffScreenRowY*16*ConstBytesPerBSLine)+(21*2),a2 * 12 is max length of column
; cmp.l a2,a1
; bcc.s CopyRow3 * off the end of the column

 tst.w d1
 bmi.s CopyRow3

 move.w #(4*16)-5,d2 * 4 bit-planes, 16 words per cell
 cmp.w #20,d1
 bcc.s CopyRow4 *1a

 move.w #(4*16)-1,d2 * 4 bit-planes, 16 words per cell
CopyRow1a
 movem.l a0-a1,-(sp)
CopyRow2
; move.l BufferScreen1-S(A5),a2 *****
; cmp.l a2,a0
; bne.s CopyRowNoBreak *****
; cmp.w #40,d2
; bcc.s CopyRowNoBreak
; dc.w $4afa
;
;CopyRowNoBreak *****
  move.w (a1),(a0)
  add.l BSPlaneSpacing,a0
  add.l BSPlaneSpacing,a1
  dbra d2,CopyRow2
 movem.l (sp)+,a0-a1
CopyRow3
 add.l #2,a0
 add.l #2,a1
 add.w #1,d1 * increment x screen coordinate
 dbra d0,CopyRow1
CopyRow4
 ifne VisibleDebugging
  move.l (sp)+,a0 * place we copied the first cell to.
  move.w #$CCCC,168(a0)
 endc

BuildRowRet
 rts
 endc * amiga

 ifne ST
CopyRow
* now copy a row from a0.l - which is where we've built it -
* to a Row at coords (d1.w,d2.w) which is the correct place
 movem.l d0/a0,-(sp)
  bsr CalcBufferScreenAddress
 movem.l (sp)+,d0/a1 * number of cells, source address
 move.l BufferScreen1,a2
 move.l a2,a3
 add.l #ConstBSPlaneSize-(ConstScreenXCells*2*15),a3 * 2 bytes per cell per plane

CopyRow1
 cmp.l a2,a0
 bcs CopyRow3 * off the start of the buffer screen
 cmp.l a3,a0
 bcc CopyRow3 * off the end of the buffer screen

 movem.l a0-a1,-(sp)
CopyRow2
  move.l (a1),(a0)
  move.l 4(a1),4(a0)
  move.l ConstBytesPerBSLine(a1),ConstBytesPerBSLine(a0)
  move.l ConstBytesPerBSLine+4(a1),ConstBytesPerBSLine+4(a0)
  move.l 2*ConstBytesPerBSLine(a1),2*ConstBytesPerBSLine(a0)
  move.l 2*ConstBytesPerBSLine+4(a1),2*ConstBytesPerBSLine+4(a0)
  move.l 3*ConstBytesPerBSLine(a1),3*ConstBytesPerBSLine(a0)
  move.l 3*ConstBytesPerBSLine+4(a1),3*ConstBytesPerBSLine+4(a0)
  move.l 4*ConstBytesPerBSLine(a1),4*ConstBytesPerBSLine(a0)
  move.l 4*ConstBytesPerBSLine+4(a1),4*ConstBytesPerBSLine+4(a0)
  move.l 5*ConstBytesPerBSLine(a1),5*ConstBytesPerBSLine(a0)
  move.l 5*ConstBytesPerBSLine+4(a1),5*ConstBytesPerBSLine+4(a0)
  move.l 6*ConstBytesPerBSLine(a1),6*ConstBytesPerBSLine(a0)
  move.l 6*ConstBytesPerBSLine+4(a1),6*ConstBytesPerBSLine+4(a0)
  move.l 7*ConstBytesPerBSLine(a1),7*ConstBytesPerBSLine(a0)
  move.l 7*ConstBytesPerBSLine+4(a1),7*ConstBytesPerBSLine+4(a0)
  move.l 8*ConstBytesPerBSLine(a1),8*ConstBytesPerBSLine(a0)
  move.l 8*ConstBytesPerBSLine+4(a1),8*ConstBytesPerBSLine+4(a0)
  move.l 9*ConstBytesPerBSLine(a1),9*ConstBytesPerBSLine(a0)
  move.l 9*ConstBytesPerBSLine+4(a1),9*ConstBytesPerBSLine+4(a0)
  move.l 10*ConstBytesPerBSLine(a1),10*ConstBytesPerBSLine(a0)
  move.l 10*ConstBytesPerBSLine+4(a1),10*ConstBytesPerBSLine+4(a0)
  move.l 11*ConstBytesPerBSLine(a1),11*ConstBytesPerBSLine(a0)
  move.l 11*ConstBytesPerBSLine+4(a1),11*ConstBytesPerBSLine+4(a0)
  move.l 12*ConstBytesPerBSLine(a1),12*ConstBytesPerBSLine(a0)
  move.l 12*ConstBytesPerBSLine+4(a1),12*ConstBytesPerBSLine+4(a0)
  move.l 13*ConstBytesPerBSLine(a1),13*ConstBytesPerBSLine(a0)
  move.l 13*ConstBytesPerBSLine+4(a1),13*ConstBytesPerBSLine+4(a0)
  move.l 14*ConstBytesPerBSLine(a1),14*ConstBytesPerBSLine(a0)
  move.l 14*ConstBytesPerBSLine+4(a1),14*ConstBytesPerBSLine+4(a0)
  move.l 15*ConstBytesPerBSLine(a1),15*ConstBytesPerBSLine(a0)
  move.l 15*ConstBytesPerBSLine+4(a1),15*ConstBytesPerBSLine+4(a0)

 movem.l (sp)+,a0-a1
CopyRow3
 add.l #BPC,a0
 add.l #BPC,a1
 dbra d0,CopyRow1

BuildRowRet
 rts
 endc * ST
;---


;---
BuildRowFeature
 movem.w d0-d2,-(sp)
BuildRowFeatureLoop
  movem.l a0-a1,-(sp)
;* check for validity - if we're trying to build outside
;* of buffer screen, let there be a great wailing
;* and gnashing of teeth (also called a breakpoint)
; move.l BufferScreen1,a2
; cmp.l a2,a0
; bcs.s BRBreak
; ifne ST
;  add.l #ConstBSPlaneSize-(ConstScreenXCells*2*15),a2 * 2 bytes per cell per plane
; endc
; ifne Amiga
;  add.l #(ConstBSPlaneSize*4)-(ConstScreenXCells*2*15),a2 * 2 bytes per cell per plane
;* 4 bit-planes
; endc
; cmp.l a2,a0
; bcs.s BROk
;BrBreak
; bra.s BuildRowEnd2

BROk
 move.l g_mapPtr,a2
 cmp.l a2,a1
 bcc.s BROk2
 bra.s BuildRowBlank

BROk2
  cmp.w MapXCells,d1
  bcc BuildRowBlank * unsigned >=
  cmp.w MapYCells,d2
  bcc BuildRowBlank * unsigned >=

  move.w 2(a1),d0  * char no. 
  beq BuildRowBlank  * blank 
  bsr feature * build up structure for this square 

; ifne VisibleDebugging
; move.l a0,-(sp) *****************
;  move.l BufferScreen1-S(a5),a0
;  move.w #0,(a0)
;  move.w #0,ConstBSPlaneSpacing(a0)
;  move.w #0,ConstBSPlaneSpacing*2(a0)
;  move.w #0,ConstBSPlaneSpacing*3(a0)
; move.l (sp)+,a0
; endc



BuildRowEnd2
  movem.l (sp)+,a0-a1
BuildRowEnd
 movem.w (sp)+,d0-d2
BuildRowFeatureRet
 rts

BuildRowBlank 
; blank out cell in buffer screen/logical screen
 ifne Amiga
 move.w #(16*4)-1,d0 * 4 bitplanes
BlankCell1
;  clr.w (a0)
;  clr.w BytesPerPixelLine(a0)
;  clr.w 2*BytesPerPixelLine(a0)
;  clr.w 3*BytesPerPixelLine(a0)
;  clr.w 4*BytesPerPixelLine(a0)
;  clr.w 5*BytesPerPixelLine(a0)
;  clr.w 6*BytesPerPixelLine(a0)
;  clr.w 7*BytesPerPixelLine(a0)
;  clr.w 8*BytesPerPixelLine(a0)
;  clr.w 9*BytesPerPixelLine(a0)
;  clr.w 10*BytesPerPixelLine(a0)
;  clr.w 11*BytesPerPixelLine(a0)
;  clr.w 12*BytesPerPixelLine(a0)
;  clr.w 13*BytesPerPixelLine(a0)
;  clr.w 14*BytesPerPixelLine(a0)
;  clr.w 15*BytesPerPixelLine(a0)
  clr.w (a0)
  add.l BSPlaneSpacing,a0
  dbra d0,BlankCell1



 endc * Amiga

 ifne ST
BlankCell1
  clr.w (a0)
  clr.w BytesPerPixelLine(a0)
  clr.w 2*BytesPerPixelLine(a0)
  clr.w 3*BytesPerPixelLine(a0)
  clr.w 4*BytesPerPixelLine(a0)
  clr.w 5*BytesPerPixelLine(a0)
  clr.w 6*BytesPerPixelLine(a0)
  clr.w 7*BytesPerPixelLine(a0)
  clr.w 8*BytesPerPixelLine(a0)
  clr.w 9*BytesPerPixelLine(a0)
  clr.w 10*BytesPerPixelLine(a0)
  clr.w 11*BytesPerPixelLine(a0)
  clr.w 12*BytesPerPixelLine(a0)
  clr.w 13*BytesPerPixelLine(a0)
  clr.w 14*BytesPerPixelLine(a0)
  clr.w 15*BytesPerPixelLine(a0)
 endc * ST

BlankCellRet
 movem.l (sp)+,a0-a1
 movem.w (sp)+,d0-d2
 rts

BuildRowOffScreenX
; if we want to wrap then...
; if x positive, try subtracting the screen width and see if we get
; on-screen
; if x negative, try adding the screen width and see if we get
; on-screen
 bpl.s BROSXPositive
;BROSXNegative
 add.w DisplayedXCells,d1
 bmi BuildRowBlank
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
 bra BuildRowFeatureLoop

BROSXPositive
 sub.w DisplayedXCells,d1
 cmp.w ScreenXLastCell,d1
 bcc BuildRowBlank
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
 bra BuildRowFeatureLoop

BuildRowOffScreenY
; if we want to wrap then...
; if y positive, try subtracting the screen height and see if we get
; on-screen
; if y negative, try adding the screen height and see if we get
; on-screen
 bpl.s BROSYPositive
; bROSYNegative
 add.w DisplayedYCells,d2
 bmi BuildRowBlank
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
 bra BuildRowFeatureLoop

BROSYPositive
 sub.w DisplayedYCells,d2
 cmp.w ScreenYLastCell,d2
 bcc BuildRowBlank
 movem.w d0-d2,-(sp)
  bsr CalcMapAddress
 movem.w (sp)+,d0-d2
 bra BuildRowFeatureLoop * unsigned <
;---
CalcMapAddress
 ext.l d1
;;;6/11 ext.l d2 * sign extend so negative add works.
 move.w mapXCellsTimes4,d0
 muls d2,d0 
 movea.l g_mapPtr,a1  * a1 = ground cell map 
 add.l d0,a1 
 add.l d1,a1 * add on 4 times x coord 
 add.l d1,a1 
 add.l d1,a1 
 add.l d1,a1 
 rts
;----
CalcAddresses
; from d1.l=xcell, d2.w=ycell, return
; a0.l as the buffer screen address,
; a1.l as the gmap address.
* d1.w=ycell, d2.l=xcell 
 bsr CalcMapAddress 
CalcBufferScreenAddress
* now calculate buffer screen address
* d1.w=xcell, d2.l=ycell 
 sub.w ScreenXFirstCell,d1 * start of screen within map
 sub.w ScreenYFirstCell,d2 * start of screen within map
AbsCalcBufferScreenAddress
 ext.l d1
 ext.l d2
 muls BytesPerBSCellLine,d2  * 160 if BS in ST Format
 ifne ST
  asl.l #3,d1 * multiply xcell by 8: bytes per cell
 endc
 ifne Amiga
  asl.l #1,d1 * multiply xcell by 2: bytes per cell
 endc
 movea.l BufferScreen1,a0 * a0 = view map 
 add.l d1,a0 * add on x offset 
 add.l d2,a0 * add on y offset 
 rts
;---
 ifne Amiga
MoveBSLeft
* We need to shift the buffer screen over (on sixteen-pixel
* boundaries) to make room for the new column of cells
 cmp.w #BSOneDirectionSpace-2,BSXCellPos-S(A5)
 bge.s PhysicalMoveBSLeft * signed >=
 add.w #1,BSXCellPos
 add.l #BPC,BufferScreen1-S(a5)
 rts

PhysicalMoveBSLeft
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (a0),-(sp)
 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (a0),-(sp)

  move.l BufferScreen1,a0 * write pointer
  move.l a0,a1
  move.w BSXCellPos-S(A5),d0
  add.w d0,d0
  ext.l d0
  add.l d0,a1 * read pointer is this much ahead of write pointer
  add.l #2,a1
 ifne DebugShifts
  movem.l a0-a1,-(sp)
 endc
  bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
 ifne DebugShifts
  movem.l (sp)+,a0-a1
  move.w #-1,(a0) **************
  move.w #$FFFF,168(a0)
  move.w #$000F,168*2(a0)
 endc

;  bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
;  bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
;  bsr BSShift * shift the bit-plane (a1)->(a0) left one cell


 move.w BSXCellPos-S(A5),d0
 add.w d0,d0
 ext.l d0
 sub.l d0,BufferScreen1-S(A5)
 move.w #0,BSXCellPos-S(A5)


 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (sp)+,(a0)
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (sp)+,(a0)

 rts
 endc * Amiga

 ifne ST
MoveBSLeft
* We need to shift the buffer screen over (on sixteen-pixel
* boundaries) to make room for the new column of cells
 cmp.w #BSOneDirectionSpace-2,BSXCellPos-S(A5)
 bge.s PhysicalMoveBSLeft * signed >=
 add.w #1,BSXCellPos
 add.l #BPC,BufferScreen1-S(a5)
 rts

PhysicalMoveBSLeft


  move.l BufferScreen1,a0 * write pointer
  move.l a0,a1
  add.l #BPC,a1 * read pointer is one word ahead of write pointer
  bsr BSShift * shift the screen (a1)->(a0) left one cell
  rts
 endc * ST
;---
 ifne Amiga
MoveBSRight
* We need to shift the buffer screen over (on sixteen-pixel
* boundaries) to make room for the new column of cells
 cmp.w #(-BSOneDirectionSpace)+2,BSXCellPos-S(A5)
 ble.s PhysicalMoveBSRight * signed <=
 sub.w #1,BSXCellPos
 sub.l #BPC,BufferScreen1-S(A5)
 rts

PhysicalMoveBSRight
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (a0),-(sp)
 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (a0),-(sp)

 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 move.w BSXCellPos-S(A5),d0
 add.w d0,d0
 ext.l d0
 add.l d0,a1 * read pointer is this much behind write pointer

 sub.l #2,a1 * read pointer is one word behind write pointer
 add.l #(16*ConstBSYCells*42*4),a0 *+4,a0 * end of table, plus 4 cause
* 4 bit-planes
 add.l #(16*ConstBSYCells*42*4),a1 *+4,a1 * we're using predecrement.
* 4 bit-planes
 ifne DebugShifts
  movem.l a0-a1,-(sp)
 endc
 bsr BSReverseShift * shift the bit-plane (a1)->(a0) one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) one cell
 ifne DebugShifts
  movem.l (sp)+,a0-a1
 move.w #-1,(a0) ******
  move.w #$FFFF,168(a0)
  move.w #$00F0,168*2(a0)
 endc

 move.w BSXCellPos-S(A5),d0
 add.w d0,d0
 ext.l d0
 sub.l d0,BufferScreen1-S(A5) * d0.l is negative, so this gets
* the bufferScreen1 pointer back to its original starting position
* in memory

 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (sp)+,(a0)
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (sp)+,(a0)

 rts
 endc * Amig

 ifne ST
MoveBSRight
* We need to shift the buffer screen over (on sixteen-pixel
* boundaries) to make room for the new column of cells
 cmp.w #(-BSOneDirectionSpace)+2,BSXCellPos-S(A5)
 ble.s PhysicalMoveBSRight * signed <=
 sub.w #1,BSXCellPos
 sub.l #BPC,BufferScreen1-S(A5)
 rts

PhysicalMoveBSRight


 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 sub.l #BPC,a1 * read pointer is one word behind write pointer
 add.l #(16*ConstBSYCells*ConstBSXCells*BPC),a0 *+4,a0 * end of table, plus 4 cause
 add.l #(16*ConstBSYCells*ConstBSXCells*BPC),a1 *+4,a1 * we're using predecrement.
 bsr BSReverseShift * shift the screen (a1)->(a0) one cell
 rts
 endc * ST

;---
 ifne Amiga
MoveBSUp
* We need to shift the buffer screen up (on sixteen-pixel
* boundaries) to make room for the new row of cells
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (a0),-(sp)
 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (a0),-(sp)

; move.l BufferScreen1,a0 * write pointer
; add.l #(13*ConstBytesPerBSline*16)-4,a0
; move.l (a0),-(sp)

 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 add.l #42*16*4,a1 * read pointer is one cell row ahead of write pointer
* 4 bit-planes
 ifne DebugShifts
  movem.l a0-a1,-(sp)
 endc
 bsr BSShift * shift the bit-plane (a1)->(a0) left one cell

;* moving up, right corrupts the bottom pixel row of the cell row
;* which ends up one above the bottom row.
;* Copy it again here, to fix this.
; add.l #(13*ConstBytesPerBSline*16)-4,a0
; move.l a0,a1
; sub.l #(ConstBytesPerBSLine*16),a1
; move.l (sp)+,(a1)

; bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
; bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
; bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
 ifne DebugShifts
  movem.l (sp)+,a0-a1
 move.w #-1,(a0) **********
  move.w #$FFFF,168(a0)
  move.w #$0F00,168(a0)
 endc

 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (sp)+,(a0)
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (sp)+,(a0)

 rts
 endc * Amiga

 ifne ST
MoveBSUp
* We need to shift the buffer screen up (on sixteen-pixel
* boundaries) to make room for the new row of cells
 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 add.l #ConstBSXCells*BPC*16,a1 * read pointer is one cell row ahead of write pointer
 bsr BSShift * shift the bit-plane (a1)->(a0) left one cell
 rts
 endc * ST
;---
 ifne Amiga
MoveBSDown
* We need to shift the buffer screen down (on sixteen-pixel
* boundaries) to make room for the new row of cells
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (a0),-(sp)
 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (a0),-(sp)


 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 sub.l #42*16*4,a1 * read pointer is one cell row ahead of write pointer
* 4 bit-planes
 add.l #(16*ConstBSYCells*42*4),a0 *+4,a0 *(BPSize*4)+4,a0 * end of table, plus 4 cause
* 4 bit-planes
 add.l #(16*ConstBSYCells*42*4),a1 *+4,a1 *(BPSize*4)+4,a1 * we're using predecrement.
* 4 bit-planes
 ifne DebugShifts
  movem.l a0-a1,-(sp)
 endc
 bsr BSReverseShift * shift the bit-plane (a1)->(a0) left one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) left one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) left one cell
; bsr BSReverseShift * shift the bit-plane (a1)->(a0) left one cell
 ifne DebugShifts
  movem.l (sp)+,a0-a1
 move.w #-1,(a0) *********
  move.w #$FFFF,168(a0)
  move.w #$F000,168(a0)
 endc

 move.l BufferScreen1,a0
 add.l #(15*ConstBytesPerBSline*16)-4,a0
 move.l (sp)+,(a0)
 move.l BufferScreen1,a0
 add.l #13*ConstBytesPerBSline*16,a0
 move.l (sp)+,(a0)

 rts
 endc * Amiga
;---------
 ifne ST
MoveBSDown
* We need to shift the buffer screen down (on sixteen-pixel
* boundaries) to make room for the new row of cells
 move.l BufferScreen1,a0 * write pointer
 move.l a0,a1
 sub.l #ConstBSXCells*BPC*16,a1 * read pointer is one cell row ahead of write pointer
 add.l #(16*ConstBSYCells*ConstBSXCells*BPC),a0 *+4,a0 *(BPSize*4)+4,a0 * end of table, plus 4 cause
 add.l #(16*ConstBSYCells*ConstBSXCells*BPC),a1 *+4,a1 *(BPSize*4)+4,a1 * we're using predecrement.
 bsr BSReverseShift * shift the bit-plane (a1)->(a0) left one cell
 rts
 endc * ST

;---
 ifne Amiga
BSReverseShift
 WaitBlitter

 move.w #$0002,$dff042 * BLTCON1: shift off, fill off, descending, not line
 move.w #$09f0,$dff040 * BLTCON0: No Shift, dma a,d., only a affects d.
 move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
 move.w #$ffff,$dff046 * BLTAFWM Source A Last word mask
* Start addresses...
; move.l #0,$dff048 * BLTCPTH
; move.l #0,$dff04c * BLTBPTH
 move.l a1,$dff050 * BLTAPTH
 move.l a0,$dff054 * BLTDPTH: Blitter destination
* modulus added at end of each line...
; move.w #0,$dff060 * bltcMod
; move.w #0,$dff062 * bltbMod
 move.w #0,$dff064 * bltaMod
 move.w #0,$dff066 * bltdMod
 move.w #((16*ConstBSYCells*4)*64)+21,d0 * cells height, 21 cells wide
* 4 bit-planes
 move.w d0,$dff058 * BLTSIZEW. Also starts blitter
; add.l BSPlaneSize,a0
; add.l BSPlaneSize,a1
 WaitBlitter *******************
 rts






; movem.l a0-a1,-(sp)
; move.w #(16*ConstBSYCells)-1,d0 * cells height -1
;* 21 cells wide by 2 bytes = 42 bytes, which is a complete pixel line
;* (For 1 bit plane)
;* Work from top of screen downwards.
;BSRS1
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.l -(a1),-(a0)
; move.w -(a1),-(a0) * 42 bytes per line
; dbra d0,BSRS1
;* move.w -(a1),-(a0)
; movem.l (sp)+,a0-a1
; add.l BSPlaneSize,a0
; add.l BSPlaneSize,a1
; rts
 endc * Amiga

 ifne ST
BSReverseShift
 movem.l a0-a1,-(sp)
 move.w #(16*ConstBSYCells)-1,d0 * cells height -1
* 21 cells wide by 8 bytes = 168 bytes, which is a complete pixel line
* (For 1 bit plane)
* Work from top of screen downwards.
BSRS1
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)

 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)

 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)

 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)
 move.l -(a1),-(a0)

 move.l -(a1),-(a0)
 move.l -(a1),-(a0)

 dbra d0,BSRS1
* move.w -(a1),-(a0)
 movem.l (sp)+,a0-a1
 rts
 endc * ST

;----
 ifne Amiga
BSShift
 WaitBlitter
 move.w #$0000,$dff042 * BLTCON1: shift off, fill off, ascending, not line
 move.w #$09f0,$dff040 * BLTCON0: No Shift, dma a,d., only a affects d.
 move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
 move.w #$ffff,$dff046 * BLTAFWM Source A Last word mask
* Start addresses...
 move.l #0,$dff048 * BLTCPTH
 move.l #0,$dff04c * BLTBPTH
 move.l a1,$dff050 * BLTAPTH
 move.l a0,$dff054 * BLTDPTH: Blitter destination
* modulus added at end of each line...
 move.w #0,$dff060 * bltcMod
 move.w #0,$dff062 * bltbMod
 move.w #0,$dff064 * bltaMod
 move.w #0,$dff066 * bltdMod
 move.w #((16*ConstBSYCells)*64*4)+21,d0 * pixels height, 21 cells wide
* 4 bit-planes
 move.w d0,$dff058 * BLTSIZEW. Also starts blitter
; add.l BSPlaneSize,a0
; add.l BSPlaneSize,a1
 WaitBlitter ***************

 rts






; movem.l a0-a1,-(sp)
; move.w #(16*ConstBSYCells)-1,d0 * cells height -1
;* 21 by 2 bytes = 42 bytes, which is a complete pixel line
;* (For 1 bit plane)
;BSShift1
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.l (a1)+,(a0)+
; move.w (a1)+,(a0)+
; dbra d0,BSShift1
; movem.l (sp)+,a0-a1
; add.l BSPlaneSize,a0
; add.l BSPlaneSize,a1
; rts
 endc * Amiga

 ifne ST
BSShift
 movem.l a0-a1,-(sp)
 move.w #(16*ConstBSYCells)-1,d0 * cells height -1
* 21 by 2 bytes = 42 bytes, which is a complete pixel line
* (For 1 bit plane)
BSShift1
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.w (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.w (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.w (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.w (a1)+,(a0)+
 dbra d0,BSShift1
 movem.l (sp)+,a0-a1
 rts
 endc * ST
;-----

 
********************** 
* draw view map      * 
********************** 
 
MCDisplayRoom: 
 lea s(pc),a5 *&&&&&&&&&&&&&&&&&
 movem.l a3-a6,-(sp) 
 bsr DisplayRoom 
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l 0
 rts 
;----------------------------------- 
* Called with no parameters - draws view map 
* to current (logical) screen. 
DRS Macro
 move.b (a0),(a1)+ 
 move.b 7(a0),(a1)+ 
 addq.l #2,a0
 move.b (a0),(a1)+ 
 move.b 7(a0),(a1)+ 
 addq.l #2,a0
 move.b (a0),(a1)+ 
 move.b 7(a0),(a1)+ 
 addq.l #2,a0
 move.b (a0),(a1)+ 
 move.b 7(a0),(a1)+ 
 addq.l #2,a0
 endm
 
DisplayRoom: 
 move.l BufferScreen1,a0 
 ifne ST
 ifne ScrollingSystem
  move.w #16,d0
  sub.w ScrollYPos,d0
  move.l BytesPerBSLine,d1
  mulu d1,d0
  add.l d0,a0 * increase source address to shift the useful picture
 endc
* up a bit.
 movea.l GraphicsScreenBase,a1 * screen start 
 ifne ScrollingSystem
 move.w ScrollXPos,d0
 cmp.b #8,d0
 bcc DisplayRoomUnshifted
 move.w DisplayedYPixels,d0
 add.l #1,a0
 
DisplayRoomShifted1 
* copy 1 Buffer Screen line at a time
* to the logical screen (21*4 words in size: 160 bytes)
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs

 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 drs
 add.l #BPC,a0 * skip over over-scan on buffer-screen (scrolling)
 dbra d0,DisplayRoomShifted1 
 rts 

 endc * ScrollingSystem



DisplayRoomUnshifted
 move.w DisplayedYPixels,d0
 
DisplayRoom1 
* copy 1 Buffer Screen line at a time
* to the logical screen (20*4 words in size: 160 bytes)
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
 
 ifne ScrollingSystem
  add.l #BPC,a0 * skip over over-scan on buffer-screen (scrolling)
 endc
 dbra d0,DisplayRoom1 
 rts 





 ifne 0
 movea.l GraphicsScreenBase,a1 * screen start 
; move.w #(ConstMapWidth*ConstMapHeight*128/64)-1,d0 
 move.w MapCellsTimes128Div64Minus1,d0
 
DisplayRoom1 
* copy 64 bytes at a time, for speed. 
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
 move.l (a0)+,(a1)+ 
 move.l (a0)+,(a1)+ 
 move.l (a0)+,(a1)+ 
 move.l (a0)+,(a1)+ 
 move.l (a0)+,(a1)+ 
 move.l (a0)+,(a1)+ 


 dbra d0,DisplayRoom1 
 rts 
 endc * 0
 endc

 ifne Amiga
; BufferScreen1=a0
; move.l a0,-(sp)
;  CALLGRAF OwnBlitter
; move.l (sp)+,a0
; bra SoftwareDisplayRoom *******

; ifne PossessBlitter
;  WaitBlitter
;  CALLGRAF OwnBlitter * grab the blitter permamently!
; endc



; move.b GameMode,d0
; beq.s DRNoShift
 move.w #16,d0
 sub.w ScrollYPos,d0
 move.l BytesPerBSLine,d1
 mulu d1,d0
 add.l d0,a0 * reduce source address to shift the useful picture
* down a bit.


; move.w BSXCellPos,d0 * position of display start rel. to mem. area.
; add.w d0,d0 * one word per cell.
; ext.l d0
; add.l d0,a0


;DRNoShift
* Wait for the scan to leave the part of the screen we're going
* to blit over (otherwise the blitter overtakes it and
* causes the lowest sprites on this frame to flicker).
 move.w #1200,d0 * 700 is ok for Grange. 
DisplayRoomDelay
 dbra d0,DisplayRoomDelay

* add.l #(ConstBytesPerBSLine*32)+4,a0 ***** Increase source by two cells for debugging
* sub.l #(ConstBytesPerBSLine*32)+4,a0 *********
 move.l Logicalbp0,a1
* off anything before the buffer screen with the first word
* mask) so as to keep the left hand edge smooth. To compensate,
* the buffer screen is one cell wider for the scrolling code.
 bsr BlitA0ToA1
; add.l BSPlaneSize,a0
; move.l Logicalbp1,a1
; bsr BlitA0ToA1
; add.l BSPlaneSize,a0
; move.l Logicalbp2,a1
; bsr BlitA0ToA1
; add.l BSPlaneSize,a0
; move.l Logicalbp3,a1
; bsr BlitA0ToA1
 rts
;--------
BlitA0ToA1
; new Blitter stuff...
 move.l a0,-(sp)

 WaitBlitter
 move.w #$0000,$dff042 * BLTCON1: shift off, fill off, ascending, not line
 move.w #$09f0,$dff040 * BLTCON0: No Shift, dma a,d., only a affects d.
 move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
; move.w #$ffff,d0
; asl.w d1,d0 * keep all of last word if not scrolled, lose
;* one pixel if scrolled by one pel - i.e. prevent the copy from wrapping
;* round onto the next screen line.
 move.w #$ffff,$dff046 * BLTAFWM Source A Last word mask
; move.w #0,$dff046 * totally opaque
* Start addresses...
 move.l #0,$dff048 * BLTCPTH
 move.l #0,$dff04c * BLTBPTH
 move.l a0,$dff050 * BLTAPTH
 move.l a1,$dff054 * BLTDPTH: Blitter destination
* modulus added at end of each line...
* how much to add on at the end of each buffer screen line?
  move.w #0,$dff060 * bltcMod - unused here.
  move.w #0,$dff062 * bltbMod - unused here.
; move.l BytesPerBSLine,d0
; sub.w #BytesPerPixelLine,d0 * **BytesPerPixelLine+2,d0 * because we're copying one word more than
*** the actual displayed size
 move.w #0,$dff064 * bltamod
 move.w #0,$dff066 * bltdMod

; move.w #$8440,$dff096 * DMACON: Blitter has absolute priority
;* And blitter dma is on.
;* See P.84
 
 ifne ScrollingSystem
  move.w DisplayedYPixels,d0
  move.b GameMode,d1
  bne.s DRB1
 endc
  move.w Bottom,d0 * CLipping position at bottom of screen (pixels)
  add.w #1,d0 * because bottom is height, not size
  and.w #$3ff,d0
; ifeq ScrollingSystem *********KLudge 19/1/90 to stop corruption
;  move.w #100,d0 ***********
; endc
DRB1
 asl.l #6+2,d0 * Multiply by 64, and by 4 for 4 bit-planes ^^^
 ifne ScrollingSystem
  add.w #21,d0 * add in width in words (each of 16 pixels)
 endc
 ifeq ScrollingSystem
  add.w #20,d0 * add in width in words (each of 16 pixels)
 endc

 move.w d0,$dff058 * BLTSIZEW. Also starts blitter

* fill in the right hand edge
; WaitBlitter
; movem.l a0-a1,-(sp)
;  add.l #38,a0
;  add.l #40,a1
;  move.w ScrollXPos,d1
;  move.w #191,d2
;CopyEdgeLoop
;  move.l (a0),d0
;  lsr.l d1,d0
;  move.w d0,(a1)
;  add.l BytesPerBSLine,a0
;  add.l #BytesPerPixelLine,a1
;  dbra d2,CopyEdgeLoop
;  
; movem.l (sp)+,a0-a1

; move.l a0,-(sp)
;  CALLGRAF DisownBlitter
; move.l (sp)+,a0
 move.l (sp)+,a0
 rts

SoftwareDisplayRoom
; old software version...
 move.w Bottom,d0 * clipping position at bottom of screen (pixels)

;; sub.w Top,d0
 add.w #1,d0 * because 'Bottom' is the last line to be plotted
; not the size to plot. e.g. 179.
 mulu #BytesPerPixelLine,d0 * d0.l is number of bytes to copy
 asr.l #1,d0 * get number of words

 move.l LogicalBp0,a1
 move.l Logicalbp1,a2
 move.l Logicalbp2,a3
 move.l Logicalbp3,a4
 ifne Colors32
  move.l Logicalbp4,a5
 endc

 cmp.w #SizeBitPlane/2,d0 ******(320*200/16)-1,d0 * limit the amount we copy
* to the size of the bit plane
 bcs.s CR1
 move.w #SizeBitPlane/2,d0 * (320*200/16)-1,d0
CR1
; move.w (a0)+,(a1)+
; move.w (a0)+,(a2)+
; move.w (a0)+,(a3)+
; move.w (a0)+,(a4)+

 move.w (a0)+,(a1)+
 move.w (ConstBSPlaneSize-2)(a0),(a2)+
 move.w ((2*ConstBSPlaneSize)-2)(a0),(a3)+
 move.w ((3*ConstBSPlaneSize)-2)(a0),(a4)+

 dbra d0,CR1
 rts
 endc
;-------
MCInitScrolling
InitialiseScrolling
; 2(a4) * horizontal size in pixels (e.g. 0..319)
; 4(a4) * vertical size in pixels (e.g. 0..191)
; 6(a4) * game mode. 0 for non-scrolling, 1 for scrolling
;MapXCellsTimes4  dc.w	ConstMapWidth*4	* map/pic width+1 
;MapXCells dc.w ConstMapWidth
;MapXCellsMinus1 dc.w ConstMapWidth-1
;MapYCells dc.w ConstMapHeight
;MapYCellsMinus1 dc.w ConstMapHeight-1
;MapCells dc.w ConstMapWidth*ConstMapHeight
;MapCellsMinus1 dc.w ConstMapWidth*ConstMapHeight-1
;MapCellsTimes128Div4MInus1 dc.w ConstMapWidth*ConstMapHeight*128/4-1
;MapCellsTimes128Div64MInus1 dc.w ConstMapWidth*ConstMapHeight*128/64-1
 move.b #1,HaveDoneInitScrolling-S(A5)
 clr.l d0
 move.w 2(a4),d0
 asr.w #4,d0 * divide by 16 to give cells
 add.w #2,d0 * add on two cells, because my code works on 21x13 map
* values instead of 20x12, and the parameters to this routine
* are one pixel too small as well.
 clr.l d1
 move.w 4(a4),d1
 asr.w #4,d1
 add.w #1,d1 * same as for x, but my code uses correct height

 move.w d0,d2 * x
 asl.w #2,d2 * times 4
 move.w d2,mapXCellsTimes4
 asl.w #2,d2 * total of times 16
 move.w d2,MapXPixels
 move.w d0,MapXCells
 move.w d0,MapXCellsMinus1
 sub.w #1,MapXCellsMinus1
 move.w d1,MapYCells
 move.w d1,MapYCellsMinus1
 sub.w #1,MapYCellsMinus1
 move.w d0,d2
 mulu d1,d2
 move.w d2,MapCells
 move.w d2,MapCellsMinus1
 sub.w #1,MapCellsMinus1

; this block of calculations appear not to be used... *********
 move.w d2,d3
 asl.w #5,d3
 sub.w #1,d3
 move.w d3,MapCellsTimes128Div4MInus1
 move.w d2,d3
 asl.w #1,d3
 sub.w #1,d3
 move.w d3,MapCellsTimes128Div64Minus1
 asl.w #2,d2
 move.w d2,MapCellsTimes4
;... end unused block.

; move.w #19,d0
; add.w ScreenXFirstCell,d0
; move.w d0,ScreenXLastCell
; move.w #11,d0
; add.w ScreenYFirstCell,d0
; move.w d0,ScreenYLastCell
 bsr CalculateScreenPos

; move.l #22*4,BytesPerBSLine
; move.l #22*4*16,BytesPerBSLineTimes16
; move.l #20*14*128/4,BSPlaneSize
; move.l #20*14*128,BSSize
 move.w 6(a4),d0
 move.b d0,GameMode

 move.w #0,CurrentColumnCell
 move.w #0,CurrentRowCell
 move.w ScreenXFirstCell,d0
 move.w d0,ColumnXStart
 move.w d0,RowXStart
 move.w ScreenYFIrstCell,d0
 move.w d0,RowYStart
 move.w d0,ColumnXStart

 rts


;----
;\============================================


 ifne 0
;----
BuildRow
* i.e. build d0.w cells of a horizontal row starting from d1.l,d2.w (cells)
* relative to the complete map.
; cmp.w MapXCells,d1
; bcc BuildRowRet
; cmp.w MapYCells,d2
; bcc BuildRowRet
 movem.w d0-d2,-(sp)
  bsr CalcAddresses
 movem.w (sp)+,d0-d2
; gets:
; a0.l as the buffer screen address,
; a1.l as the gmap address.

BuildRow1
 bsr BuildRowFeature
 add.w #1,d1 * increment x position
 ifne Amiga
  add.l #2,a0 * next cell along horizontally
 endc
 ifne ST
  add.l #BPC,a0 * next cell along horizontally
 endc
 add.l #4,a1
 dbra d0,BuildRow1
BuildRowRet
 rts
 endc

