; Big Sprite Plotting Stuff
;-----------
MCUpdateScreen
; display all the sprites we've been asked for
 movem.l a3-a6,-(sp)
 bsr ClearBigSprite * Clear the big sprite buffer before
* we start to use it.
 move.l CellGroupTable,a0
* a0.l stays as the current entry in the list,
* a1.l is the "last" entry after the first time through the loop
 move.l a0,a1 * probably not used, but gives me a nice warm feeling.
 move.l #0,GoBackAddressA0
MCUpdateScreen1
  move.w 4(a0),d3 *ZCord
  move.w 6(a0),d2 *ycord. d0
  cmp.w #192-16,d2 * crude clipping
  bcc.s MCUpdateScreen2
  move.w 8(a0),d1 * XCord
  cmp.w #304,d1 **** crude clipping
  bcc.s MCUpdateScreen2
  move.w 10(a0),d0 * object number of cell to plot.
  beq.s MCUpdateScreen2
  bsr PlotCellBigSprite *DrwCellC
  bra.s MCUpdateScreen3 * PlotCellBigSprite skips onto next entry

MCUpdateScreen2
 move.l (a0),d0
 move.l a0,a1 * a1=last entry
 move.l d0,a0

MCUpdateScreen3
 move.l a0,d0
 bne.s MCUpdateScreen1  

 tst.w BigSpriteCells
 beq.s MCUpdateScreen4
* something left in buffer, so display it
 bsr PCBSDisplayBuffer

MCUpdateScreen4
 movem.l (sp)+,a3-a6

ClearCellGroupTable
; Initialise cell group table.
 move.l CellGroupTable,a0
 move.w #SizeCellGroupTable/4-1,d0
ER2
 clr.l (a0)+
 dbra d0,ER2
 move.l CellGroupTable,a0
; insert a dummy "minimum" z entry
 move.l a0,(a0)
 add.l #CellGroupEntrySize,(a0)
 move.w #-5000,4(a0) ; z
 move.w #-5000,6(a0) ; y
 move.w #-5000,8(a0) ; x
 add.l #CellGroupEntrySize,a0
 move.w #5000,4(a0)
 move.w #5000,6(a0) ; y
 move.w #5000,8(a0) ; x
 add.l #CellGroupEntrySize,a0
 move.l a0,CellGroupFreeEntry
 bsr ClearBigSprite
 rts
;------
CellGroupEntrySize equ 12
* big sprite is stored in interleaved bit plane format
* (i.e. like the sprites file on disk).
BigSpritePtr dc.l 0
BigSpriteZTablePtr dc.l 0 * within BigSpritePtr
;BigSpriteMaskPtr dc.l 0 * within BigSpritePtr area

ConstBigSpriteXCells equ 2
ConstBigSpriteYCells equ 1
ConstBigSpriteBytesPerLine equ ConstBigSpriteXCells*2
BigBPSpace equ ConstBigSpriteBytesPerLine*16*ConstBigSpriteYCells * space between bit planes
BigSpriteBytesPerLine dc.w ConstBigSpriteBytesPerLine
BigSpriteBytesPerLineDiv2Minus1 dc.w ConstBigSpriteBytesPerLine-1
BigSpriteXCells dc.w ConstBigSpriteXCells
BigSpriteYCells dc.w ConstBigSpriteYCells
BigSpriteXPixels dc.w ConstBigSpriteXCells*16
BigSpriteYPixels dc.w ConstBigSpriteYCells*16
BigSpriteMaxXCord dc.w 0
BigSpriteMaxYCord dc.w 0
BigSpriteMaxYCordPlus16 dc.w 0
BigSpriteMaxUsedXCord dc.w 0
BigSpriteMaxUsedYCord dc.w 0

ConstBigSpriteSize equ ConstBigSpriteXCells*ConstBigSpriteYCells*16*8
BigSpriteSize dc.w ConstBigSpriteSize
BigSpriteSizeMinus1 dc.w ConstBigSpriteSize-1

ConstBigSpriteZTableSize equ 0 * ConstBigSpriteXCells*ConstBigSpriteYCells*2
; ConstBigSpriteMaskSize equ ConstBigSpriteXCells*ConstBigSpriteYCells*2*16
BigSpriteAllocateSize dc.w ConstBigSpriteSize+ConstBigSpriteZTableSize * +ConstBigSpriteMaskSize

BigSpriteXCord dc.w -5000
BigSpriteYCord dc.w -5000
BigSpriteZCord dc.w -5000
BigSpriteCells dc.w 0
ConstMaxBigSpriteCells equ ConstBigSpriteXCells*ConstBigSpriteYCells

************ excess space allowed
BigSpriteSizeFGMaskBuffer equ ConstBigSpriteXCells*ConstBigSpriteYCells*16*3*2+500 ************
* (it's 3 cells wide, you see.)
BigSpriteSizeBGMaskBuffer equ ConstBigSpriteXCells*ConstBigSpriteYCells*16*2+500 *************
BigSpriteFGMaskPtr dc.l 0
BigSpriteBGMaskPtr dc.l 0

GoBackAddressA0 dc.l 0 * address of any cells we miss out whilst
GoBackAddressA1 dc.l 0 * plotting a bit sprite.

;---
ClearBigSprite
 move.l BigSpritePtr,a0
 move.w #ConstBigSpriteSize/4-1,d0
 moveq.l #0,d1
CBS1
 move.l d1,(a0)+ * faster than clr
 dbra d0,CBS1
 move.w #0,BigSpriteCells
 move.w #-5000,BigSpriteZCord * force buffer to reload
 rts
;-----------
PlotCellBigSprite
; plot cell d0.w at coords (x=d1,y=d2,z=d3)
; in whatever way we consider best.
* Preserves a0,a1 (unless it changes them deliberately)
 tst.w BigSpriteCells
 bne.s PCBS1
* buffer empty - start building a new big sprite
 movem.w d0-d3,-(sp)
  move.w d3,BigSpriteZCord
  move.w d2,BigSpriteYCord
  move.w d1,BigSpriteXCord
  move.w d1,BigSpriteMaxUsedXCord
  move.w d2,BigSpriteMaxUsedYCord
  add.w BigSpriteXPixels,d1
  add.w BigSpriteYPixels,d2
  move.w d1,BigSpriteMaxXCord
  move.w d2,BigSpriteMaxYCord
  add.w #16,d2
  move.w d2,BigSpriteMaxYCordPlus16
 movem.w (sp)+,d0-d3

PCBS1
* check if the x,y,z coords are suitable for this
* cell to go into our big sprite buffer.
 cmp.w BigSpriteZCord,d3
 bne PCBSIgnore
 cmp.w BigSpriteMaxXCord,d1
 bge PCBSIgnore
 cmp.w BigSpriteMaxYCord,d2
 bge PCBSIgnore
 sub.w BigSpriteXCord,d1
 bmi PCBSIgnore
 sub.w BigSpriteYCord,d2
 bmi PCBSIgnoreRel * y coord is relative
* d1,d2 are now relative to the big sprite buffer.

; we're processing this entry now - remove it from the linked list
 move.l (a0),(a1) * unlink.
 move.w #300,8(a0) * x coord
 move.w #0,10(a0) * x coord

* now get cell data in BigSpriteBuffer (directly if possible)
 movem.l a0-a1,-(sp)
  bsr PCBSGetAndReverseCell
 movem.l (sp)+,a0-a1
 add.w #1,BigSpriteCells
 move.w BigSpriteCells,d0
 cmp.w #ConstMaxBigSpriteCells,d0
 bcc.s PCBSDisplayBuffer * unsigned >=
PCBSNext
 move.l (a0),d0
 beq.s PCBSNextMaybeBack
 move.l a0,a1 * a1=last entry
 move.l d0,a0
 rts

PCBSNextMaybeBack
* have reached end of list - last check to see we
* haven't got some more to go back over
 move.l GoBackAddressA0,a0
 move.l GoBackAddressA1,a1
 move.l #0,GoBackAddressA0
 rts
;-----
PCBSDisplayBuffer
* plot the big sprite.
 movem.l a0-a1,-(sp)
  bsr PCBSPlotIt
  bsr ClearBigSprite * Clear the big sprite buffer
 movem.l (sp)+,a0-a1
 move.l GoBackAddressA0,d0
 beq.s PCBSNext
 move.l d0,a0
 move.l GoBackAddressA1,a1
 move.l #0,GoBackAddressA0
PCBSRet
 rts
;-----------------------
PCBSIgnoreRel
 add.w BigSpriteYCord,d2 * make it absolute again

PCBSIgnore
* don't want to plot this entry yet (e.g. because we're already
* building a big sprite, which this cell can't form part of)
* - if we haven't already
* done so for an earlier entry, save the current address and
* skip over it.
; cmp.w BigSpriteMaxYCordPlus16,d2
; ble.s PCBSIgnore1 * we'll want to come back to this one.

* no more cells can possibly go into the current buffer
 tst.w BigSpriteCells
 beq PCBSIgnore1
 movem.l a0-a1,-(sp)
 move.l GoBackAddressA0,-(sp)
  bsr PCBSDisplayBuffer
 move.l (sp)+,d0
 move.l d0,GoBackAddressA0
 movem.l (sp)+,a0-a1
 rts * try this cell again, next time we call PCBS

PCBSIgnore1
* nothing in buffer, so go back if appropriate.
 move.l GoBackAddressA0,d0
 bne.s PCBSIgnore2
 move.l a0,GoBackAddressA0
 move.l a1,GoBackAddressA1
 rts

PCBSIgnore2
 bra PCBSNext
;---
PCBSGetAndReverseCell:
* get and reverse cell number d0.
* Put the cell data into BigSpritePtr
 movem.w d1-d2,-(sp)
  bsr GetCell * sets up reqd_cell pointing to the sprite
 movem.w (sp)+,d1-d2
;; move.w BigSpriteBytesPerLine,d3 * modulus in sprite
 move.l BigSpritePtr,a3
 mulu BigSpriteBytesPerLine,d2 * multiply relative y coord
 asr.w #3,d1 * d1 was pixels, we want cells * 2
 and.l #$fffe,d1
 add.l d1,d2
 add.l d2,a3

 tst.w d0 * preserved cell number
 bpl.s PCBSGARC1
 movea.l reqd_cell,a1 * original cell data 
PCBSRevCell
 movem.l a1-a3,-(sp) 
 lea rev_tab,a2  * reverse data list 
 moveq #15,d1 
 clr.l d2 
PCBSRevCell1: 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),1(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),(a3) 

 move.b (a1)+,d2 
 move.b 0(a2,d2.l),BigBPSpace+1(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),BigBPSpace(a3) 

 move.b (a1)+,d2 
 move.b 0(a2,d2.l),2*BigBPSpace+1(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),2*BigBPSpace(a3) 

 move.b (a1)+,d2 
 move.b 0(a2,d2.l),3*BigBPSpace+1(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),3*BigBPSpace(a3) 
 
 add.l #ConstBigSpriteBytesPerLine,a3 * next line of destination sprite. addq.l #8,a3 
 dbra d1,PCBSRevCell1 
 movem.l (sp)+,a1-a3 
 rts
;------
PCBSGARC1
* copy from reqd_cell (disk sprite format: interleaved bit planes)
* to a3.l (big sprite format: separate bit planes, spaced at
* BigBPSpace)
 move.l reqd_cell,a0
 move.w (a0)+,(a3)
 move.w (a0)+,BigBPSpace(a3)
 move.w (a0)+,BigBPSpace*2(a3)
 move.w (a0)+,BigBPSpace*3(a3)

 move.w (a0)+,ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,2*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,2*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,2*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,2*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,3*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,3*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,3*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,3*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,4*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,4*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,4*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,4*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,5*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,5*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,5*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,5*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,6*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,6*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,6*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,6*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,7*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,7*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,7*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,7*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,8*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,8*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,8*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,8*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,9*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,9*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,9*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,9*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,10*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,10*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,10*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,10*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,11*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,11*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,11*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,11*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,12*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,12*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,12*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,12*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,13*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,13*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,13*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,13*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,14*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,14*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,14*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,14*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 move.w (a0)+,15*ConstBigSpriteBytesPerLine(a3)
 move.w (a0)+,15*ConstBigSpriteBytesPerLine+BigBPSpace(a3)
 move.w (a0)+,15*ConstBigSpriteBytesPerLine+BigBPSpace*2(a3)
 move.w (a0)+,15*ConstBigSpriteBytesPerLine+BigBPSpace*3(a3)

 rts
;----
PCBSPlotIt
* Plot the big sprite, at whatever size we currently have.
;;; move.w BigSpriteXCord

; move.l BigSpriteFGMaskPtr,a4
;** move.l #$ffff0000,d2
;; move.l #$ffffffff,d2 * keep all background.
; move.w #BigSpriteSizeFGMaskBuffer/4-1,d0 * height
;PlotIt1
; move.l #0,(a4)+
; dbra d0,PlotIt1

 move.l BigSpritePtr,a0 * data pointer 
 move.l BigSpriteFGMaskPtr,a4 * mask pointer 
 move.w #BigSpriteSizeFGMaskBuffer/6-1,d0
 moveq #-1,d1  * 'mask' 
makeFGmask1: 
* Do first cell horizontally....
 move.w (a0)+,d2 
 or.w BigBPSpace-2(a0),d2 
 or.w 2*BigBPSpace-2(a0),d2 
 or.w 3*BigBPSpace-2(a0),d2 
 eor.w d1,d2 
 move.w d2,(a4)+ 

* Do second cell horizontally....
 move.w (a0)+,d2 
 or.w BigBPSpace-2(a0),d2 
 or.w 2*BigBPSpace-2(a0),d2 
 or.w 3*BigBPSpace-2(a0),d2 
 eor.w d1,d2 
 move.w d2,(a4)+ 

 move.w #$FFFF,(a4)+
 dbra d0,makeFGmask1 

* Calc d0.l as offset within bit plane
 move.w BigSpriteYCord,d0  * y cord 
 add.w ScrollYPos,d0
 sub.w ScreenYFirstPixel,d0 ; scroll
 sub.w #16,d0 * because screen is offset 16 pixels upwards
* for scrolling system.
 move.w d0,-(sp)
  muls BytesPerScreenLine+2,d0

  move.w BigSpriteXcord,d1  * x cord 
  asr.w #4,d1
  sub.w ScreenXFirstCell,d1
  ext.l d1
  add.l d1,d0 ; end of scrolling additions
  add.l d1,d0 
  move.w BigSpriteXCord,d1 * shift right
  sub.w ScreenXFirstPixel,d1
  and.w #15,d1
* now d0.l is offset within bit plane.
* d1.w is shift horizontally

  movem.w d0-d3,-(sp)
   bsr GetBigSpriteBackgroundMask
  movem.w (sp)+,d0-d3

  move.l BigSpriteFGMaskPtr,a5 * sprite mask
  move.l a5,a3
  move.l BigSpriteBGMaskPtr,a1 * bg mask
 move.w (sp)+,d2 * our y cord, in pixels
 and.w #15,d2 * vertical offset within cell
 muls #(ConstBigSpriteXCells+1)*2,d2
 add.l d2,a1 * add on to bg mask to allow for us not
* being cell aligned vertically.

 movem.l d0,-(sp)
  add.l LogicalBP0,d0
  move.l BigSpritePtr,a0
  bsr BSBlit
 movem.l (sp)+,d0
 movem.l d0,-(sp)
  add.l LogicalBP1,d0
  add.l #BigBPSpace,a0 * next bit plane in source data.
  bsr BSBlit
 movem.l (sp)+,d0
 movem.l d0,-(sp)
  add.l LogicalBP2,d0
  add.l #BigBPSpace,a0 * next bit plane in source data.
  bsr BSBlit
 movem.l (sp)+,d0
 movem.l d0,-(sp)
  add.l LogicalBP3,d0
  add.l #BigBPSpace,a0 * next bit plane in source data.
  bsr BSBlit
 movem.l (sp)+,d0
 rts
;----
GetBigSpriteBackgroundMask
* Work out background mask corresponding to the z coord of this sprite.
* (Remember that all the constituent cells have the same z).
* We do this in one big chunk to keep it simple (ho ho).
* Work out offset from g_map in d2.w
 move.w BigSpriteYCord,d0
 asr.w #4,d0 * asr, to preserve sign 
 muls MapXCellsTimes4,d0 * calc d0.l=offset into table 
 move.w BigSpriteXCord,d1
; add.w ScreenXFirstPixel,d1
 andi.w #$FFF0,d1
 ext.l d1 * sign extend up to long 
 asr.l #2,d1 
 add.l d1,d0  * g_map offset 
 move.l bigspriteBGmaskPtr,a1

 move.w #ConstBigSpriteYCells,d5 * out bg mask is one cell higher
* than the sprite we're plotting.
GBSB1
 move.w #ConstBigSpriteXCells,d4 * our background mask is one
* cell wider than the sprite we're plotting - because when non-
* aligned, it spills over a cell at each end.
 movem.l d0/a1,-(sp)
GBSB2
  move.w BigSpriteZCord,d1 * pass z coord to getmask.
 move.w d0,-(sp)
  bsr GetMask * corrupts a0,d*
 move.w (sp)+,d0
* get mask starting at g_map+d2.l with z coord d1.w
* d6.l is the address of the mask
* copy the mask to (a1.l) - i.e. the current position
* in the big sprite mask.
  move.l d6,a2 * allow us to get access to it
  move.w (a2),(a1)
  move.w 2(a2),(ConstBigSpriteXCells+1)*2(a1)
  move.w 4(a2),2*(ConstBigSpriteXCells+1)*2(a1)
  move.w 6(a2),3*(ConstBigSpriteXCells+1)*2(a1)
  move.w 8(a2),4*(ConstBigSpriteXCells+1)*2(a1)
  move.w 10(a2),5*(ConstBigSpriteXCells+1)*2(a1)
  move.w 12(a2),6*(ConstBigSpriteXCells+1)*2(a1)
  move.w 14(a2),7*(ConstBigSpriteXCells+1)*2(a1)
  move.w 16(a2),8*(ConstBigSpriteXCells+1)*2(a1)
  move.w 18(a2),9*(ConstBigSpriteXCells+1)*2(a1)
  move.w 20(a2),10*(ConstBigSpriteXCells+1)*2(a1)
  move.w 22(a2),11*(ConstBigSpriteXCells+1)*2(a1)
  move.w 24(a2),12*(ConstBigSpriteXCells+1)*2(a1)
  move.w 26(a2),13*(ConstBigSpriteXCells+1)*2(a1)
  move.w 28(a2),14*(ConstBigSpriteXCells+1)*2(a1)
  move.w 30(a2),15*(ConstBigSpriteXCells+1)*2(a1)
  add.l #2,a1 * next position in big sprite mask
  add.w #4,d0 * next position on map
  dbra d4,GBSB2 * x loop
 movem.l (sp)+,d0/a1
 add.w MapXCellsTimes4,d0
 add.l #16*(ConstBigSpriteXCells+1)*2,a1 * next row in big sprite mask.
 dbra d5,GBSB1 * y loop
 rts
; move.l BigSpriteBGMaskPtr,a0
;; move.l #$0,d2 * inverted, then anded. 1s allow sprite
;* to appear at that point (i.e. background is cleared where the sprite is
; non-transparent)
; move.w #BigSpriteSizeBGMaskBuffer/4-1,d3 * height
;PlotIt2
; move.l #$ffffffff,(a0)+ **** d4
; dbra d3,PlotIt2




;----
BSBlit
* blit sprite from a0(ST-format) to a single bit plane
* at d0.l
* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
* and a3.l as sprite mask (need to shift with sprite)
* and a5.l as 32pixel-wide sprite mask (for plotting stage)
* Set up channel A as BG mask
*        channel B as sprite mask(shifteD)
*        channel C as screen
* d1.w is number of pixels by which to shift right
* d0.w is number of lines of sprite to draw.

; set up blitter to punch a hole in the background.
; (Have to do this separately, because the blitter
; only has 4 dma channels)
 move.w d1,d2
 asl.l #8,d2
 asl.l #4,d2 * get in highest nybble of word for BLTCON data
 move.w d2,$dff042 * BLTCON1: shift B, fill off, ascending, not line
 move.w #$0f8a,$dff040 * BLTCON0 minterms aBC+ABC+abC, no shift A

 move.l #$0000ffff,d2
 lsr.l d1,d2
 move.w d2,$dff044 * BLTAFWM Source A First word mask
 move.l #$FFFF0000,d2
 lsr.l d1,d2 * get right mask
 move.w d2,$dff046 * BLTAFWM Source A last word mask
; move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
; move.w #$ffff,$dff046 * BLTAFWM Source A last word mask

* Start addresses...
 move.l d0,$dff048 * BLTCPTH screen
 move.l a5,$dff04c * BLTBPTH sprite mask
 move.l a1,$dff050 * BLTAPTH background mask
 move.l d0,$dff054 * BLTDPTH: Blitter destination
* modulus added at end of each line...
BSBlitWidth equ ConstBigSpriteXCells*2 * width in bytes
 move.w #BytesPerPixelLine-BSBlitWidth-2,$dff060 * bltcMod * screen
 move.w #0,$dff062 * bltbMod * sprite mask
 move.w #0,$dff064 * bltaMod * background mask
 move.w #BytesPerPixelLine-BSBlitWidth-2,$dff066 * bltdMod screen.

 move.w #ConstBigSpriteYCells*16,d2 * number of lines ; and.w #$3ff,d2
 asl.w #6,d2 * Multiply by 64.
 add.w #BSBlitWidth/2+1,d2 * add in width in words (each of 16 pixels)
 move.w d2,$dff058 * BLTSIZEW. Also starts blitter

 movem.l d0-d1/a0-a6,-(sp)
  CALLGRAF WaitBlit
 movem.l (sp)+,d0-d1/a0-a6

; rts

; set up blitter to actually copy sprite data, masked of course
* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
* and a3.l as sprite mask (need to shift with sprite)
* Set up channel A as BG mask
*        channel B as sprite mask(shifted)
*        channel C as screen
* d1.w is number of pixels by which to shift right
 move.w d1,d2
 asl.l #8,d2
 asl.l #4,d2 * get in highest nybble of word for BLTCON data
 move.w d2,$dff042 * BLTCON1: shift B, fill off, ascending, not line
* A=screen (0 if ok to plot regardless)
* B=sprite data: plot if 1.
* C=sprite mask: transparent is 1. Plot if 0

 or.w #$0fba,d2 * ABC+AbC+Abc+aBC+aBc+abC+abc
; or.w #$0fba,d2 * ABC+AbC+Abc++aBc+
* 		      (              ) if screen 0, plot regardless
*	       ^ plot if sprite 1, transparent. Unlikely!
*	           ^ plot if sprite 0, opaque. Wrong!
*		   ^ plot if sprite 0, mask 0. Wrong!
* We want to plot if sprite 1, mask 0. i.e. ABc
; or.w #$0ff8,d2
 move.w d2,$dff040 * BLTCON0 minterms, shift A
 move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
 move.w #$ffff,$dff046 * BLTAFWM Source A last word mask

* Start addresses...
 move.l d0,$dff048 * BLTCPTH screen
 move.l a5,$dff04c * BLTBPTH sprite mask
 move.l a0,$dff050 * BLTAPTH sprite data
 move.l d0,$dff054 * BLTDPTH: Blitter destination

 move.w #BytesPerPixelLine-6,$dff060 *-BSBlitWidth-2,$dff060 * bltcMod * screen
 move.w #0,$dff062 * bltbMod * sprite mask
 move.w #0-2,$dff064 * bltaMod * sprite data
 move.w #BytesPerPixelLine-6,$dff066 *BSBlitWidth-2,$dff066 * bltdMod screen.

 move.w #ConstBigSpriteYCells*16,d2 * number of lines ; and.w #$3ff,d2
 asl.w #6,d2 * Multiply by 64.
 add.w #3,d2 *BSBlitWidth/2+1,d2 * add in width in words (each of 16 pixels)
 move.w d2,$dff058 * BLTSIZEW. Also starts blitter

 movem.l d0-d1/a0-a6,-(sp)
  CALLGRAF WaitBlit
 movem.l (sp)+,d0-d1/a0-a6

 rts

;--------
; move.l (a0),a1
;* are we above the z coord for a0, and below the z coord for a1?
; cmp.w 4(a0),d3
; blt.s CGNextEntry * haven't arrived yet
; beq.s CGCheckY
;* our previous link was less - so unless the next link
;* is equal to the one we're inserting, we want to insert it here.
; cmp.w 4(a1),d3 * insert before the next z coord?
; bne.s CGInsertBeforeNext * > -i.e. no, we're just about to go too far.
;* we're about to step onto an entry with the same z coord.
;* If the y coord of our new entry is less than the first
;* of that bin, we want to insert this entry before it.
; cmp.w 6(a1),d2
; bgt.s CGNextEntry
; blt.s CGInsertBeforeNext
;* we're about to step onto an entry with the same y coord.
;* If the x coord of our new entry is less than the y coord
;* of that bin, we want to insert this entry before it.
; cmp.w 8(a1),d1
; bgt.s CGNextEntry
; blt.s CGInsertBeforeNext
; bra.s CGNextEntry
;
;CGCheckY
;* z coord equal to current entry - so we need to check the other search parameters
;* We know that our y coord is > the first entry in the bin.
; cmp.w 6(a0),d2 * have we got to a suitable point yet?
; blt.s CGNextEntry
;* we're above the current entry.
; cmp.w 6(a1),d2 * insert before the next y coord?
; bgt.s CGNextEntry * but above the next entry as well. 
;* y is <= to the next entry.
; cmp.w 8(a1),d1 * is the next entry's x still above this one?
; bge.s CGInsertBeforeNext * no - so we want to insert before the next




