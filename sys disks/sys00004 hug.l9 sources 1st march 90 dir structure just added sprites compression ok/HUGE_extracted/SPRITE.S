; SPRITE.S
 
;-------------------------------
;       draw a cell



DrwCell: 
 move.w zcord-S(a5),d2 
 sub.w hcord-S(a5),d2 
 bmi DrwCellx1 
 
 move.w d2,ypos-S(a5)  * pixel ycord 

DrwCellD0
 tst.w d0 * is cell reversed?
 bpl.s drwNonReversed
; cell asked to be reversed. Canceled if rev_flag asks for reversal
 tst.w rev_flag-S(A5)
 bmi.s DrwCellNotReversed * non-reversed
 bra.s DrwCellReversed * reversed

drwNonReversed * local label
 tst.w rev_flag-S(a5)  * reverse cell ? 
 bpl DrwCellNotReversed  * no 

DrwCellReversed: 
* draw cell reversed
 ifeq AmigaCellGrouping
  bsr GetCell  * find cell 
  bsr RevCell_a  * reverse it 
 endc
 ifne AmigaCellGrouping
  or.w #$8000,d0
 endc
 bra DrwCellB 

DrwCellNotReversed: 
* draw cell non-reversed
 ifeq AmigaCellGrouping
  bsr GetCell 
 endc
 ifne AmigaCellGrouping
  and.w #$7fff,d0
 endc
 
DrwCellB: 
 ifne AmigaCellGrouping
; grouping cells together - we're building a linked list
; with cells sorted in bins of equal z coord, first bin is lowest z.
; Within each bin, sort in y coord (lowest first) then within
; equal y coords, sort in x coord (lowest first)
; This should allow us to later plot several adjacent cells
; in one go.
; We're using a linked list, but it's simplified cause we get
; free entries off the end. We have a pointer to the next free entry:
; CellGroupFreeEntry.l
; Each entry in our linked list has the form:
;  .l pointer to next entry in list.
;  .w z coord
;  .w y coord
;  .w x coord
;  .w cell number: top bit set if reflected.
 move.w xcord,d1
 move.w ypos,d2
 move.w zcord,d3 ; to complete the set of things to search for
 move.l CellGroupFreeEntry,a2
 move.l #0,(a2) * null "next" pointer, unless we write one in
 move.w d3,4(a2) * z coord
 move.w d2,6(a2) * y coord
 move.w d1,8(a2) * x coord
 move.w d0,10(a2) * cell number
 add.l #CellGroupEntrySize,a2
 move.l a2,CellGroupFreeEntry
 sub.l #CellGroupEntrySize,a2 * leave a2 as the new entry
 move.l CellGroupTable,a0

* May be possible to code this instead by forming shifting
* all coordinates  to make them positive, then merging
* to give a 48 bit number, and doing the sort on that number.

CG2
 move.l (a0),a1
 cmp.w 4(a0),d3 * Z
 blt.s CG3
 cmp.w 4(a1),d3
 bgt.s CG3
* (Z>=Zc & Z<=Zn)
 cmp.w 4(a1),d3
 beq.s CG2a
* no existing entries with this z coord?
 cmp.w 4(a0),d3
 bgt.s CGInsertBeforeNext

CG2a
 cmp.w 6(a0),d2 * y
 blt.s CG3
 cmp.w 6(a1),d2
 bgt.s CG3
* (Y>=Yc & Y<=Yn)
 cmp.w 6(a1),d2
 beq.s CG2b
* no existing entries with this y coord?
 cmp.w 6(a0),d2
 bgt.s CGInsertBeforeNext

CG2b
 cmp.w 8(a1),d1 * X
 blt.s CG3
 cmp.w 8(a1),d1
 bgt.s CG3
* ok, (Z>=Zc & Z<=Zn) & (Y>=Yc & Y<=Yn) & (X>=Xc & X<=Xn)
 bra.s CGInsertBeforeNext

CG3
 cmp.w 4(a0),d3 * Z
 bne.s CG4
 cmp.w 4(a1),d3 * Z
 beq.s CG4
* ok, Z=Zc & Z<>Zn
 bra.s CGInsertBeforeNext

CG4
 cmp.w 6(a0),d2 * Y
 bne.s CG5
 cmp.w 6(a1),d2
 beq.s CG5
* ok, Y=Yc & Y<>Yn
 bra.s CGInsertBeforeNext

CG5


CGnextEntry
 move.l a1,a0
 bra.s CG2

CGInsertBeforeNext
 move.l a1,(a2)
 move.l a2,(a0)
 rts
 endc * AmigaCellGrouping




DrwCellC
 bsr make_mask  * reqd_cell = sprite data 
 move.w MapXCellsTimes4-S(a5),d0 
 move.w ypos-S(a5),d1 
 asr.w #4,d1 * asr, to preserve sign 
 muls d1,d0 * calc d0.l=offset into table 
 move.w xcord-S(a5),d1 
 
* which of four quadrants do we want to clip: 
* top left, top right, bottom left, bottom right. 
* Set ClipMask=0000TTBB 
*     LRLR 
tl equ 3 
tr equ 2 
bl equ 1 
br equ 0 

tlMask equ $FFF7
trMask equ $FFFB
blMask equ $FFFD
brMask equ $FFFE


;LHMinus16 equ -16 
;RH equ 319 
;RHMinus15 equ 304 
;TopMinus16 equ -16 
;Bottom equ 191 
;BottomMinus15 equ 176 
* Set the appropriate bit if its quadrant is to be plotted 
* (Thus 0=plot nothing). Built mask byte in d3.b initially 
*  * d1.w=x coord in pixels 
 
 
*               Signed  Unsigned 
* >=            BGE     BCC 
* >             BGT     BHI 
* =             BEQ     BEQ 
* <>            BNE     BNE 
* <=            BLE     BLS 
* <             BLT     BCS 
 move.w ypos-S(a5),d2 * d2.w=y coord in pixels 
; add.w ScrollYPos,d2
; add.w ScrollXPos,d1 *1/11
 sub.w ScreenXFirstPixel-S(a5),d1
 sub.w ScreenYFirstPixel-S(a5),d2 

 move.b #15,d3 * plot all quadrants unless otherwise set 
 cmp.w LHMinus16-S(a5),d1 
 ble DrwCellEnd * < completely off left hand side.
 cmp.w LH3d-S(a5),d1 
 bge.s NoClipLeft 
; just off left hand side 
; bclr #tl,d3 
; bclr #bl,d3 * remove left hand square 
 and.w #tlmask&blMask,d3
 bra.s NoClipRight 
 
NoClipLeft 
 cmp.w RH-S(a5),d1 
 bgt DrwCellEnd * completely off the right of the screen 
 cmp.w RHMinus15-S(a5),d1 
 blt.s NoClipRight * bcs.s NoClipRight * no way this cell can be clipped 
; bclr #tr,d3 * clip top and bottom right hand 
; bclr #br,d3 
 and.w #trMask&brMask,d3
 
NoClipRight 
; cmp.w #176,d2 * bottom margin-16 
; bcs NoClipBottom 
 cmp.w TopMinus16-S(a5),d2
 ble DrwCellEnd * <= completely off the top. * bcs.s NoClipTop 
 cmp.w Top-S(A5),d2 
 bge.s NoClipTop 
; just off top 
; bclr #tl,d3 
; bclr #tr,d3 * remove top squares 
 and.w #tlmask&trmask,d3
 bra.s NoClipBottom 
 
NoClipTop 
 cmp.w Bottom-S(a5),d2 
 bge DrwCellEnd * bcc DrwCellEnd * completely off the bottom of the screen 
 cmp.w BottomMinus15-S(a5),d2 
 blt.s NoClipBottom * bcs.s NoClipBottom * no way this cell can be clipped 
; bclr #bl,d3 * clip bottom left and right 
; bclr #br,d3 
 and.w #blMask&brMask,d3
 
NoClipBottom 
 move.b d3,ClipMask-S(A5) 
 
; cmp.w #319,d1 * >>Mike 11/1/89 - prevent crashes due to wrap-round 
; bcc DrwCellx 


;****
; move.w MapXCellsTimes4,d0 
; move.w ypos,d1 
; add.w ScrollYPos,d1
; sub.w #16,d1
; asr.w #4,d1 * asr, to preserve sign 
; muls d1,d0 * calc d0.l=offset into table 
;****
; 
 move.w xcord-S(a5),d1 ;1/11 add.w ScreenXFirstPixel,d1 * restore map-based coord
 add.w ScreenYFirstPixel-S(a5),d2 **************** Scuzey - shouldn't
* this be ScreenXFirstPixel,d1 ?????

* d1.w is x coord 
* d0.l is offset into gmap 
 andi.l #$FFF0,d1 
 ext.l d1 * sign extend up to long 
 asr.l #2,d1 
 add.l d1,d0  * g_map offset 
 move.w zcord-S(a5),d1  * sprite zcord 
;>>Mike 19/3/89 cmpi.w #176,ypos  * off screen ? 
; cmp.w #ScreenYClip,ypos *>>Mike 19/3/89 
;; bge DrwCellx  * yes - no draw 
; bcc DrwCellx  * yes - no draw 
 
 btst #tl,ClipMask-S(A5) 
 beq.s NoMaskTL 
 bsr GetMask  * 1st cell mask (TL) 
 move.l d6,mask1-S(a5) 
NoMaskTL 
 addq.w #4,d0 
 btst #tr,ClipMask-S(A5) 
 beq.s NoMaskTR 
 bsr GetMask  * 2nd cell mask (TR) 
 move.l d6,mask2-S(a5) 
NoMaskTR 
 move.w MapXCellsTimes4-S(a5),d2 
 add.w d2,d0  * 4th cell mask (BR) 
 btst #br,ClipMask-S(A5) 
 beq.s NoMaskBr 
 bsr GetMask 
 move.l d6,mask4-S(a5) 
NoMaskBr 
 subq.w #4,d0  * 3rd cell mask (BL) 
 btst #bl,ClipMask-S(A5) 
 beq.s NoMaskBl 
 bsr GetMask 
 move.l d6,mask3-S(a5) 
NoMaskBl 
 
* calc top mask offsets and line counts 
 move.w ypos-S(a5),d0 
; add.w ScrollYPos-S(a5),d0
; add.w ScrolLYPos-S(a5),d0
* normal, traditional calculation of quadrant data sizes
 andi.w #15,d0  * d0 = y shift 
 move.w d0,lo_cnt-S(a5)  * bottom line count 
 moveq #16,d1 
 sub.w d0,d1 
 move.w d1,hi_cnt-S(a5)  * top line count 
 
; lsl.w #1,d1  * p_mask offset 
 add.w d1,d1 * add is faster than lsl
 move.l d1,pm_off-S(a5)  * save it 
; lsl.w #2,d1  * p_data offset 
 add.w d1,d1 * add twice is still faster than lsl #2,d1
 add.w d1,d1
 move.l d1,pd_off-S(a5)  * save it 
 ext.l d0 
 lsl.w #1,d0  * d0 = top mask offset 
 add.l d0,mask1-S(a5)  * adjust top mask 
 add.l d0,mask2-S(a5)  * pointers 
 
;;;;;;;;;;;
 ifne ST
*  calc screen addrs of 4 quadrants 
 move.w ypos-S(a5),d0  * y cord 
 add.w ScrollYPos-S(a5),d0
 sub.w ScreenYFirstPixel-S(a5),d0 ; scroll
 sub.w #16,d0 ************ST
 muls #BytesPerPixelLine,d0  * d0 = no. scrn lines 
 move.w xcord-S(a5),d1  * x cord 
;STSTSTST add.w ScrollXPos,d1
 sub.w ScreenXFirstPixel-S(a5),d1
 andi.l #$FFF0,d1 
 ext.l d1 
 asr.l #1,d1  * d1 = x offset 
 add.l d1,d0 
 movea.l GraphicsScreenBase-S(a5),a0 * -S(a5),a0 * a0 = screen 
 adda.l d0,a0  * a0 = top left sprite bit 
 move.l a0,scrn1-S(a5)  * 1st quadrant 
 addq.l #8,a0 
 move.l a0,scrn2-S(a5)  * 2nd quadrant 
 move.w hi_cnt-S(a5),d0 
 mulu BytesPerScreenLine+2-S(a5),d0 *#BytesPerPixelLine,d0 
 adda.l d0,a0 
 move.l a0,scrn4-S(a5)  * 4th quadrant 
 subq.l #8,a0 
 move.l a0,scrn3-S(a5)  * 3rd quadrant 
 
*  draw sprite to screen 
 move.w xcord-S(a5),d1  * d1 = x cord 
 andi.w #15,d1  * d1 = x shift 
 
 btst #tl,ClipMask-S(A5) 
 beq.s NoDrawTL 
 movea.l reqd_cell-S(a5),a0 * a0 = sprite data 
 move.l mask_buffPtr-S(a5),a3 * a3 = sprite mask 
 movea.l mask1-S(a5),a1  * a1 = 1st quad. mask 
 movea.l scrn1-S(a5),a2  * a2 = 1st quad. screen 
 move.w hi_cnt-S(a5),d0  * d0 = line count 
 bsr drw_left  * draw top left 
NoDrawTL 
 
 tst.w d1  * is there a right bit ? 
 beq DrwCell1  * no 
 btst #tr,ClipMask-S(A5) 
 beq.s NoDrawTr 
 movea.l reqd_cell-S(a5),a0 
 move.l mask_buffPtr-S(a5),a3 
 movea.l mask2-S(a5),a1 
 movea.l scrn2-S(a5),a2 
 move.w hi_cnt-S(a5),d0 
 bsr drw_rght  * draw top right 
NoDrawTr 
DrwCell1: 
 tst.w lo_cnt-S(a5)  * is there a bottom bit ? 
 beq DrwCellx  * no 
 
 btst #bl,ClipMask-S(A5) 
 beq.s NoDrawBl 
 movea.l reqd_cell-S(a5),a0 
 adda.l pd_off-S(a5),a0  * sprite offset 
 move.l mask_buffPtr-S(a5),a3 
 adda.l pm_off-S(a5),a3  * mask offset 
 movea.l mask3-S(a5),a1 
 movea.l scrn3-S(a5),a2 
 move.w lo_cnt-S(a5),d0 
 bsr drw_left  * draw bottom left 
NoDrawBl 
 
 tst.w d1 
 beq DrwCellx 
 
 btst #br,ClipMask-S(A5) 
 beq.s NoDrawBR 
 movea.l reqd_cell-S(a5),a0 
 adda.l pd_off-S(a5),a0 
 move.l mask_buffPtr-S(a5),a3 
 adda.l pm_off-S(a5),a3 
 movea.l mask4-S(a5),a1 
 movea.l scrn4-S(a5),a2 
 move.w lo_cnt-S(a5),d0 
 bsr drw_rght  * draw bottom right 
NoDrawBR 
 endc ; ST sprite plotting code
;;;;;;;;;;


;;;;;;;;;;;
 ifne Amiga
* calc screen addrs of 4 quadrants 
 move.w ypos-S(a5),d0  * y cord 
 add.w ScrollYPos-S(a5),d0
 sub.w ScreenYFirstPixel-S(a5),d0 ; scroll
 sub.w #16,d0 * because screen is offset 16 pixels upwards
* for scrolling system.
 muls BSLineSpacing+2-S(a5),d0

 move.w xcord-S(a5),d1  * x cord 
 asr.w #4,d1
 sub.w ScreenXFirstCell-S(a5),d1
 ext.l d1
 add.l d1,d0 ; end of scrolling additions
 add.l d1,d0 

; d0.l is offset within each bit plane
 move.l d0,scrn1-S(a5)  * 1st quadrant 
 addq.l #2,d0 
 move.l d0,scrn2-S(a5)  * 2nd quadrant 
 move.w hi_cnt-S(a5),d1 
 mulu BSLineSpacing+2-S(a5),d1
 add.l d1,d0 
 move.l d0,scrn4-S(a5)  * 4th quadrant 
 subq.l #2,d0 
 move.l d0,scrn3-S(a5)  * 3rd quadrant

* additional clipping calculations for scrolling system...
 move.l reqd_cell-S(a5),d0
 move.l d0,TopReqd_cell-S(a5)
 move.l Mask_buffPtr-S(a5),d0
 move.l d0,TopMask_buffPtr-S(a5)

*  draw sprite to screen 
 move.w xcord-S(a5),d1  * d1 = x cord 
 andi.w #15,d1  * d1 = x shift 
 
 btst #tl,ClipMask-S(A5) 
 beq.s NoDrawTL
* Ok, at least the top left of the cell is on screen.
* Can we use the blitter to speed things up a bit?

  movea.l reqd_cell-S(a5),a0 * a0 = sprite data
 ifeq UseBlitter
  bra UseSoftware
 endc
  cmp.l #TopChipMemory,a0 ******* we should probably change this.
  bcc.s UseSoftware
  cmp.b #$0f,ClipMask-S(a5)
  bne.s UseSoftware * can only use blitter for intact sprites

 ifne ScrollingSystem
* If close to the top of the visible screen, we may
* have scrolled off so as to be off the top - the blitter
* code does not handle this, and tramples off the top
  tst.l scrn1-S(A5)
  bmi.s UseSoftware
 endc

 move.l d5,-(sp)
  bsr BlitterDrwCell 
 move.l (sp)+,d5
  bra DrwCellEnd

UseSoftware
 movea.l Topreqd_cell-S(a5),a0 * a0 = sprite data 
 move.l Topmask_buffPtr-S(a5),a3 * a3 = sprite mask 
 movea.l mask1-S(a5),a1  * a1 = 1st quad. mask 
 movea.l scrn1-S(a5),a2  * a2 = 1st quad. screen 
 move.w hi_cnt-S(a5),d0  * d0 = line count 
 bsr drw_left  * draw top left 

NoDrawTL 
 tst.w d1  * is there a right bit ?
 beq DrwCell1  * no
 btst #tr,ClipMask-S(A5)
 beq.s NoDrawTr
 movea.l Topreqd_cell-S(a5),a0
 move.l Topmask_buffPtr-S(a5),a3
 movea.l mask2-S(a5),a1
 movea.l scrn2-S(a5),a2
 move.w hi_cnt-S(a5),d0
 bsr drw_rght  * draw top right
NoDrawTr
DrwCell1:
 tst.w lo_cnt-S(a5)  * is there a bottom bit ?
 beq DrwCellx  * no
 
 btst #bl,ClipMask-S(A5)
 beq.s NoDrawBl
 movea.l reqd_cell-S(a5),a0
 adda.l pd_off-S(a5),a0  * sprite offset
 move.l mask_buffPtr-S(a5),a3
 adda.l pm_off-S(a5),a3  * mask offset
 movea.l mask3-S(a5),a1
 movea.l scrn3-S(a5),a2
 move.w lo_cnt-S(a5),d0 
 bsr drw_left  * draw bottom left 
NoDrawBl 
 
 tst.w d1 
 beq DrwCellx 
 
 btst #br,ClipMask-S(A5) 
 beq.s NoDrawBR 
 movea.l reqd_cell-S(a5),a0 
 adda.l pd_off-S(a5),a0 
 move.l mask_buffPtr-S(a5),a3 
 adda.l pm_off-S(a5),a3 
 movea.l mask4-S(a5),a1 
 movea.l scrn4-S(a5),a2 
 move.w lo_cnt-S(a5),d0 
 bsr drw_rght  * draw bottom right 
NoDrawBR 
 endc
;;;;;;;;;;

DrwCellx: 
DrwCellEnd 
; movea.l (sp)+,a0 
DrwCellx1: 
 rts 
;-------
 ifne Amiga
BlitterDrwCell
* First do top part of cell (Both left and right together)
* To do this, we need to merge the top left and top right
* masks together to form one, 32pixel wide mask.
* We know top left cell is to be drawn, because
* this is one criterion for calling this code
 move.l mask1-S(a5),a1 * top left mask
 move.l mask2-S(a5),a2 * top right mask
* set up background mask....
 move.l WideMaskPtr-S(a5),a4 * 32bit wide mask (in chip memory)
 move.l #$0000ffff,d2
 lsr.l d1,d2 * keep rh part of screen not affected by 16pixel sprite
 move.w #$ffff,d7 * completely transparent: use to detect if
* background mask is entirely transparent. &&&&&&&&&&

* do jump table index into our mask builder, to only do the right amount
* TIMING: Calculating this index takes about 13 uS, wheras
* doing a dbra loop 8 times adds an overhead of 18uS
 clr.l d0
 move.w hi_cnt-S(a5),d0 * height
* multiply by $14
 add.w d0,d0
 add.w d0,d0
 move.w d0,d6 * keep times 4
 add.w d0,d0
 add.w d0,d0 * got times $10
 add.w d6,d0
 lea BDC1End-S(A5),a0
 sub.l d0,a0
 jmp (a0)

BDC1
BDC1Macro macro * if you change this, you must change the multiply above
 move.w (a1)+,d3
 and.w d3,d7
 swap d3
 move.w (a2)+,d3
 and.w d3,d7
 or.w d2,d3 * ensure that rh part is not affected
 move.l d3,(a4)+
 move.l d3,(a4)+
 move.l d3,(a4)+
 move.l d3,(a4)+

 endm

 BDC1Macro
 BDC1Macro
 BDC1Macro
 BDC1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

BDC1End
* and copy in the mask from the cells we overlap at the bottom...
 move.l mask3-S(a5),a1 * top left mask
 move.l mask4-S(a5),a2 * top right mask
 move.w lo_cnt-S(a5),d0 * height of bottom bit
 beq BDC1b * no bottom bit
* multiply by $14
 add.w d0,d0
 add.w d0,d0
 move.w d0,d6 * keep times 4
 add.w d0,d0
 add.w d0,d0 * got times $10
 add.w d6,d0

 lea BDC2End,a0
 sub.l d0,a0
 jmp (a0)

 BDC1Macro
 BDC1Macro
 BDC1Macro
 BDC1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

 bdc1Macro
 bdc1Macro
 bdc1Macro
 bdc1Macro

BDC2End

BDC1b
* expand the sprite mask up to 32 pixels wide
 move.l Mask_buffPtr-S(a5),a3 * a3 = sprite mask 
 move.l WideSpriteMaskPtr-S(a5),a0
 move.w #$ffff,d2 * inverted, then anded. 1s allow existing
* screen to come through unchanged.
 move.l #$ffff0000,d3 * leave the high word set up as mask
BDCMacro macro
 move.w (a3)+,d3 * gives d3.l=FFFFxxxx
 move.w d3,(a0)+
 move.l d3,(a0)+ ; move.w d2,(a0)+ ; move.w d3,(a0)+
 move.l d3,(a0)+ ; move.w d2,(a0)+ ; move.w d3,(a0)+
 move.l d3,(a0)+ ; move.w d2,(a0)+ ; move.w d3,(a0)+
 move.w d2,(a0)+
 endm

 BDCMacro
 BDCMacro
 BDCMacro
 BDCMacro

 BDCMacro
 BDCMacro
 BDCMacro
 BDCMacro

 BDCMacro
 BDCMacro
 BDCMacro
 BDCMacro

 BDCMacro
 BDCMacro
 BDCMacro
 BDCMacro

BDC3
* Now use the blitter to draw the first hi_cnt lines
* of reqd_cell using (WideMaskPtr) as background mask
 movea.l reqd_cell-S(a5),a0 * a0 = sprite data 
 move.l Mask_buffPtr-S(a5),a3 * a3 = sprite mask 
 move.l WideSpriteMaskPtr-S(a5),a6 * a6=expanded version of sprite mask
 movea.l WideMaskPtr-S(a5),a1 * a1= bg mask (32 pixels wide: two adjacent map cells)

 movea.l scrn1-S(a5),a2  * a2 = leftmost screen 
; move.w #16,d0 * number of lines to draw
; bsr BlitterDrwFrag * draw top left 
; rts
; fall through to blitterDrwFrag

;-------- 
BlitterDrwFrag
* called from above.
 move.w d1,d3
 asl.l #8,d3
 asl.l #4,d3 * get in highest nybble of word for BLTCON data
 move.l #$0000ffff,d4
 lsr.l d1,d4
 move.l #$FFFF0000,d5
 lsr.l d1,d5 * get right mask
 cmp.w #$ffff,d7
 beq NonOpaquePlot

* now combine the background mask and foreground mask
* BG mask: 1=transparent, therefore ok to plot sprites here.
* FG mask: 0 = opaque,    therefore ok to plot sprites here.
 WaitBlitter
 lea $dff040,a4 * start of blitter address
 move.w #$0D30,(a4)+	* $dff040 * BLTCON0 minterms, no shift A
 move.w d3,(a4)+	* $dff042 * BLTCON1: shift B, fill off, ascending, not line
* and channels a,b,d only
 move.w #$ffff,d2
 lsr.w d1,d2 * keep rhs of first word only.
 move.w d2,(a4)+	* $dff044 * BLTAFWM Source A First word mask
 eor.w #$ffff,d2 * and keep lhs
 move.w d2,(a4)	* $dff046 * BLTAFWM Source A last word mask
* Start addresses...
 add.l #$c-$6,a4
 move.l a6,(a4)+	* $dff04c * BLTBPTH Sprite mask. 32 pixels wide.
 move.l a1,(a4)+	* $dff050 * BLTAPTH 32 pixel wide background mask. 1=transparent
 move.l a1,(a4)	* $dff054 * BLTDPTH: Blitter destination
* modulus added at end of each line...
 add.l #$62-$54,a4

 move.l #0,(a4)+	* $dff062 and 64 * bltbMod * sprite mask (16 bits wide)
; move.w #0,$dff064 * bltaMod * bg mask (32 bits wide)
 move.w #0,(a4)	* $dff066 * bg mask
; sub.l #$66-$58,a4
 move.w #(16*64*4)+2,$58-$66(a4) *$dff058 * BLTSIZEW. Also starts blitter 4=4 bit-planes
;
;
; sub.l #$58-$44,a4
; move.l #$FFFFffff,(a4)	* $dff044 * BLTAFWM Source A First word mask
;; move.w #$ffff,$dff046 * BLTAFWM Source A last word mask




;* modulus added at end of each line...

; move.w #0,$dff062 * bltbMod * sprite mask (16 bits wide)
; move.w #0,$dff064 * bltaMod * bg mask (32 bits wide)
; move.w #0,$dff066 * bg mask
; move.w #(16*64*4)+2,$dff058 * BLTSIZEW. Also starts blitter 4=4 bit-planes

 move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
 move.w #$ffff,$dff046 * BLTAFWM Source A last word mask




 move.l LogicalBP0-S(a5),a4
 add.l a2,a4
;
BlitSpriteA0A4
* blit sprite from a0(ST-format) to all bit planes
* at a4.l
* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
* and a3.l as sprite mask (need to shift with sprite)
* and a5.l as 32pixel-wide sprite mask (for plotting stage)
* Set up channel A as BG mask
*        channel B as sprite mask(shifteD)
*        channel C as screen
* d1.w is number of pixels by which to shift right
* d0.w is number of lines of sprite to draw.

* The masks have the following, definitive, tested, meanings...
* Sprite mask: 0=plot data here. 1-transparent
* Background mask: 0=use background (i.e. opaque). 1=transparent,
*    i.e. use sprite here.
 lea $dff040,a3
 WaitBlitter
* set up blitter to actually copy sprite data, masked of course
* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
* and a3.l as sprite mask (need to shift with sprite)
* d1.w is shift
* d0.w is number of lines of sprite to draw.
* minterms: ABx+xBC
 move.w #$0fca,(a3)+	*$dff040 * BLTCON0 minterms, no shift A
 move.w d3,(a3)	*$dff042 * BLTCON1: shift B, fill off, ascending, not line

* Start addresses...
 add.l #$48-$42,a3
 move.l a4,(a3)+	*$dff048 * BLTCPTH screen
 move.l a0,(a3)+	*$dff04c * BLTBPTH sprite data
 move.l a1,(a3)+	*$dff050 * BLTAPTH combined background/sprite mask. 1=plot here.
 move.l a4,(a3)	*$dff054 * BLTDPTH: Blitter destination
* modulus added at end of eich line...
 add.l #$60-$54,a3
 move.w #(BytesPerPixelLine/4)-4,(a3)+	*$dff060 * bltcMod * screen
 move.w #-2,(a3)+	*$dff062 * bltaMod * sprite data (16 bits wide) & ST
* format, so 8 bytes between each valid data word
; move.w #0,(a3)+	$dff064 * bltbMod * combined background/sprite mask (32 bits wide)
 move.l #(BytesPerPixelLine/4)-4,(a3)	*$dff066 * bltdMod screen.
 move.w #(16*64*4)+2,$58-$64(a3)	*$dff058 * 16 lines of 2 words each: BLTSIZEW.
* Times 4 because 4 bit-planes
*		   Also starts blitter
 rts





; WaitBlitter
;
;; set up blitter to punch a hole in the background.
;; (Have to do this separately, because the blitter
;; only has 4 dma channels)
; move.w d3,$dff042 * BLTCON1: shift B, fill off, ascending, not line
; move.w #$0f8a,$dff040 * BLTCON0 minterms aBC+ABC+abC, no shift A
;
; move.w d4,$dff044 * BLTAFWM Source A First word mask
; move.w d5,$dff046 * BLTAFWM Source A last word mask
;* Start addresses...
; move.l a4,$dff048 * BLTCPTH logical screen bit-plane
; move.l a3,$dff04c * BLTBPTH Sprite mask.
; move.l a1,$dff050 * BLTAPTH 32 pixel wide background mask. 1=transparent
; move.l a4,$dff054 * BLTDPTH: Blitter destination
;* modulus added at end of each line...
; move.w #BytesPerPixelLine-4,$dff060 * bltcMod * screen
; move.w #-2,$dff062 * bltbMod * sprite mask (16 bits wide)
; move.w #0,$dff064 * bltaMod * bg mask (32 bits wide)
; move.w #BytesPerPixelLine-4,$dff066 * bltdMod screen.
; move.w d6,$dff058 * BLTSIZEW. Also starts blitter
;
; WaitBlitter
;; set up blitter to actually copy sprite data, masked of course
;* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
;* and a3.l as sprite mask (need to shift with sprite)
;* Set up channel A as BG mask
;*        channel B as sprite mask(shifteD)
;*        channel C as screen
;* d1.w is number of pixels by which to shift right
;* d0.w is number of lines of sprite to draw.
; move.w d3,$dff042 * BLTCON1: shift B, fill off, ascending, not line
; move.w d3,d2
; or.w #$0fba,d2
; move.w d2,$dff040 * BLTCON0 minterms, shift A
; move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
; move.w #$ffff,$dff046 * BLTAFWM Source A last word mask
;
;* Start addresses...
; move.l a4,$dff048 * BLTCPTH screen
; move.l a6,$dff04c * BLTBPTH sprite mask
; move.l a0,$dff050 * BLTAPTH sprite data
; move.l a4,$dff054 * BLTDPTH: Blitter destination
;* modulus added at end of eich line...
;; move.w #BytesPerPixelLine-4,$dff060 * bltcMod * screen
; move.w #0,$dff062 * bltbMod * sprite mask (32 bits wide)
; move.w #(8-4),$dff064 * bltaMod * sprite data (16 bits wide) & ST
;* format, so 8 bytes between each valid data word
;; move.w #BytesPerPixelLine-4,$dff066 * bltdMod screen.
; move.w d6,$dff058 * BLTSIZEW. Also starts blitter
; rts
;========================
NonOpaquePlot
 WaitBlitter
 lea $dff042,a3
 move.w d3,(a3)+	*$dff042 * BLTCON1: shift B, fill off, ascending, not line
 or.w #$0fb8,d3
 move.w d3,-4(a3)	*$dff040 * BLTCON0 minterms, shift A
; move.w #$ffff,$dff044 * BLTAFWM Source A First word mask
; move.w #$ffff,$dff046 * BLTAFWM Source A last word mask
 move.l #$FFFFFFFF,(a3) *dff044
* modulus added at end of eich line...
 add.l #$60-$44,a3
 move.l #(((BytesPerPixelLine/4)-4)<<16),(a3)+ *$dff060 * bltcMod * screen
; move.w #0,$dff062 * bltbMod * sprite mask (32 bits wide)
 move.l #(-2<<16)+((BytesPerPixelLine/4)-4),(a3)+	*$dff064 * bltaMod * sprite data (16 bits wide) & ST
* format, so 8 bytes between each valid data word
; move.w #(BytesPerPixelLine/4)-4,$dff066 * bltdMod screen.
 move.l #$ffff0000,d2
 lsr.l d1,d2

 move.l LogicalBP0-S(a5),a4
 add.l a2,a4
; bsr FastBlitSpriteA0A4
; move.l LogicalBP1-S(a5),a4
; add.l a2,a4
; add.l #2,a0 * next bit plane
; bsr FastBlitSpriteA0A4
; move.l LogicalBP2-S(a5),a4
; add.l a2,a4
; add.l #2,a0 * next bit plane
; bsr FastBlitSpriteA0A4
; move.l LogicalBP3-S(a5),a4
; add.l a2,a4
; add.l #2,a0 * next bit plane
; drop through to FastBlitSpriteA0A0 for the last time.
; bsr FastBlitSpriteA0A4
; rts
;---
FastBlitSpriteA0A4
* blit sprite from a0(ST-format) to a single bit plane
* at a4.l
* With a1.l as 32-pixel-wide background mask (fixed on screen word boundary)
* and a3.l as sprite mask (need to shift with sprite)
* and a5.l as 32pixel-wide sprite mask (for plotting stage)
* d1.w is number of pixels by which to shift right
* d0.w is number of lines of sprite to draw.

* The masks have the following, definitive, tested, meanings...
* Sprite mask: 0=plot data here. 1-transparent
* Background mask: 0=use background (i.e. opaque). 1=transparent,
*    i.e. use sprite here.
; movem.l a3-a4/a6,-(sp)
;  CALLGRAF WaitBlit
; movem.l (sp)+,a3-a4/a6
 WaitBlitter

* set up blitter to actually copy sprite data, unmasked
* a3.l as sprite mask (need to shift with sprite)
* d1.w is number of pixels by which to shift right
* d0.w is number of lines of sprite to draw.
* Start addresses...
 move.w (a4),d0
 move.l a4,$dff048 * BLTCPTH screen
 move.l a6,$dff04c * BLTBPTH sprite mask
 move.l a0,$dff050 * BLTAPTH sprite data
 move.l a4,$dff054 * BLTDPTH: Blitter destination
 move.w #(16*64*4)+2,$dff058 * 16 lines of 2 words each: BLTSIZEW.
* times 4 because 4 bit-planes
*		   Also starts blitter

* patch back in the first word, which the blitter
* tends to trample over. 
 nop * wait for blitter to do this word, particularly
 nop * on machines with fast mem on which we'll be running
 nop * alongside the blitter, even though it's in exclusive
 nop * mode
 nop
 and.w d2,d0
 or.w d0,(a4)
 rts
 endc * Amiga


;-----

;;;;;;;;;;;;
 ifne ST 
 
;-----------------------------
;   draw right bit of cell
 
drw_rght: 
; A3.L is sprite mask
; A2.L IS address to plot at on screen
; A1.L is background mask
; A0.L is sprite data
 subq.w #1,d0 

 ifne ScrollingSystem
drw_rght0:
 move.l a2,d2
 sub.l GraphicsScreenBase,d2
 bpl.s drw_rght0a
; off the top of the screen - skip over some lines first
; Not terribly speed critical
 add.l #8,a0
 add.l #2,a1 * background mask
 add.l BytesPerScreenLine,a2 *#BytesPerPixelLine,a2  * next scrn line 
 add.l #2,a3 * mask
 subq.w #1,d0
 bmi.s drw_rret
 bne.s drw_rght0
drw_rret
 rts

drw_rght0a:
* clip at bottom of screen
 cmp.l BSSizeDisplayedPlaneMinus16Lines,d2
 bcs.s drw_rght1
 move.w d0,d3
 mulu #ConstBytesPerBSLine,d3
 add.l d3,d2
 cmp.l BSSizeDisplayedPlane,d2
 bcs.s drw_rght1 * end of segment we're drawing is on screen
* we're off the end - count back until we're completely on screen
DRClipBottom1
 sub.l #ConstBytesPerBSLine,d2
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
 bcs.s drw_rght1 * end of segment we're drawing is on screen
; sub.l #ConstBytesPerBSLine,d2
 sub.w #1,d0
 bpl.s DRClipBottom1
* size to plot has shrunk to nothing.
 rts

 endc * ScrollingSystem
drw_rght1: 
 moveq #-1,d2  * mask = all 1's 
 move.w (a3)+,d2  * d2 = sprite mask word 
 swap d2 
 lsr.l d1,d2  * d2 = right side of sprite 
 move.w (a1)+,d3  * d3 = backgrnd mask word 
 eori.w #$FFFF,d3  * invert it 
 or.w d2,d3  * d3 = new bg mask 
 move.w d3,d2 
 eori.w #$FFFF,d2  * d2 = new spr mask 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 adda.l #152,a2  * next scrn line 
 dbra d0,drw_rght1 
 rts 


;-----------------------------
;   draw left bit of cell ----ST-----

drw_left: 
 subq.w #1,d0 

 ifne ScrollingSystem * ST Scrolling
drw_left0:
 move.l a2,d2
 sub.l GraphicsScreenBase,d2
 bpl.s drw_left0a
; off the top of the screen - skip over some lines first
; Not terribly speed critical
 add.l #8,a0
 add.l #2,a1 * background mask
 add.l BytesPerScreenLine,a2 *#BytesPerPixelLine,a2  * next scrn line 
 add.l #2,a3 * mask
 subq.w #1,d0
 bmi.s drw_lret
 bne.s drw_left0
drw_lret
 rts

drw_left0a:
* clip at bottom of screen
 cmp.l BSSizeDisplayedPlaneMinus16Lines,d2
 bcs.s drw_left1
 move.w d0,d3
 mulu #ConstBytesPerBSLine,d3
 add.l d3,d2
 cmp.l BSSizeDisplayedPlane,d2
 bcs.s drw_left1 * end of segment we're drawing is on screen
* we're off the end - count back until we're completely on screen
DLClipBottom1
 sub.l #ConstBytesPerBSLine,d2
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
 bcs.s drw_left1 * end of segment we're drawing is on screen
; sub.l #ConstBytesPerBSLine,d2
 sub.w #1,d0
 bpl.s DLClipBottom1
* size to plot has shrunk to nothing.
 rts



 endc * ScrollingSystem


drw_left1: 
 moveq #-1,d2  * mask = all 1's 
 move.w (a3)+,d2  * spr mask word 
 lsr.l d1,d2  * only left bit 
 move.w (a1)+,d3  * bg mask word 
 eori.w #$FFFF,d3  * invert it 
 or.w d2,d3  * d3 = new bg mask 
 move.w d3,d2 
 eori.w #$FFFF,d2  * d2 = new spr mask 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 and.w d3,(a2)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a2)+  * put it onto screen 
 
 adda.l #152,a2  * next scrn line 
 dbra d0,drw_left1 
 rts 
 endc ; ST drw_left routine
;;;;;;;;; 
 

;;;;;;;;;;;;
 ifne Amiga 
 
;-----------------------------
;   draw right bit of cell
 
drw_rght: 
; A3.L is sprite mask
; A2.L IS OFFSET within the bit planes
; A1.L is background mask
; A0.L is sprite data
 subq.w #1,d0 

 ifne ScrollingSystem
drw_rght0:
 move.l a2,d2
 bpl.s drw_rght0a
; off the top of the buffer screen - skip over some lines first
; Not terribly speed critical
 add.l #8,a0
 add.l #2,a1 * background mask
 add.l BytesPerScreenLine,a2 *#BytesPerPixelLine,a2  * next scrn line 
 add.l #2,a3 * mask
 subq.w #1,d0
 bmi.s drw_rret
 bne.s drw_rght0
drw_rret
 rts

drw_rght0a:
* clip at bottom of screen
 cmp.l BSSizeDisplayedPlaneMinus16Lines,d2
 bcs.s drw_rght1
 move.w d0,d2
 mulu #ConstBytesPerBSLine,d2
 add.l a2,d2
 cmp.l BSSizeDisplayedPlane,d2
 bcs.s drw_rght1 * end of segment we're drawing is on screen
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
* we're off the end - count back until we're completely on screen
DRClipBottom1
 sub.l #ConstBytesPerBSLine,d2
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
 bcs.s drw_rght1 * end of segment we're drawing is on screen
; sub.l #ConstBytesPerBSLine,d2
 sub.w #1,d0
 bpl.s DRClipBottom1
* size to plot has shrunk to nothing.
 rts

 endc * ScrollingSystem
drw_rght1: 
 moveq #-1,d2  * mask = all 1's 
 move.w (a3)+,d2  * d2 = sprite mask word 
 swap d2 
 lsr.l d1,d2  * d2 = right side of sprite 
 move.w (a1)+,d3  * d3 = backgrnd mask word 
 eori.w #$FFFF,d3  * invert it 
 or.w d2,d3  * d3 = new bg mask 
 move.w d3,d2 
 eori.w #$FFFF,d2  * d2 = new spr mask 
 
; now write the sprite data out to all five bit planes

; LogicalBP0
 move.l LogicalBP0,a4
 add.l a2,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a4)  * put it onto screen 
 
; LogicalBP1
; move.l LogicalBP1,a4
; add.l a2,a4
 add.l BSPlaneSpacing,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a4)  * put it onto screen 

; LogicalBP2
; move.l LogicalBP2,a4
; add.l a2,a4
 add.l BSPlaneSpacing,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a4)  * put it onto screen 

; LogicalBP3
; move.l LogicalBP3,a4
; add.l a2,a4
 add.l BSPlaneSpacing,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data word 
 swap d4 
 clr.w d4 
 lsr.l d1,d4  * d4 = shifted spr word 
 and.w d2,d4  * mask it 
 or.w d4,(a4)  * put it onto screen 

 add.l BytesPerScreenLine,a2 *#BytesPerPixelLine,a2  * next scrn line 

 dbra d0,drw_rght1 
 rts 


;-----------------------------
;   draw left bit of cell

drw_left: 
 subq.w #1,d0 

 ifne ScrollingSystem
drw_left0:
 move.l a2,d2
 bpl.s drw_left0a
; off the top of the buffer screen - skip over some lines first
; Not terribly speed critical - because not much is clipped.
 add.l #8,a0
 add.l #2,a1 * background mask
 add.l BytesPerScreenLine,a2 *#BytesPerPixelLine,a2  * next scrn line 
 add.l #2,a3 * mask
 subq.w #1,d0
 bmi.s drwlret
 bne.s drw_left0
drwlret
 rts

drw_left0a:
* clip at bottom of screen
 cmp.l BSSizeDisplayedPlaneMinus16Lines,d2 * BSDisplayedPlaneSizeMinus16Lines,d2
 bcs.s drw_left1
 move.w d0,d2
 mulu #ConstBytesPerBSLine,d2
 add.l a2,d2
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
 bcs.s drw_left1 * end of segment we're drawing is on screen
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
* we're off the end - count back until we're completely on screen
DLClipBottom1
 sub.l #ConstBytesPerBSLine,d2
 cmp.l BSSizeDisplayedPlane,d2 *BSDisplayedPlaneSize,d2
 bcs.s drw_left1 * end of segment we're drawing is on screen
; sub.l #ConstBytesPerBSLine,d2
 sub.w #1,d0
 bpl.s DLClipBottom1
* size to plot has shrunk to nothing.
 rts

 endc * ScrollingSystem
drw_left1: 
 moveq #-1,d2  * mask = all 1's 
 move.w (a3)+,d2  * spr mask word 
 lsr.l d1,d2  * only left bit 
 move.w (a1)+,d3  * bg mask word 
 eori.w #$FFFF,d3  * invert it 
 or.w d2,d3  * d3 = new bg mask 
 move.w d3,d2 
 eori.w #$FFFF,d2  * d2 = new spr mask 
 
; LogicalBP0
 move.l LogicalBP0,a4
 add.l a2,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a4)+  * put it onto screen 

; LogicalBP1
 move.l LogicalBP1,a4
 add.l a2,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a4)+  * put it onto screen 

; LogicalBP2
 move.l LogicalBP2,a4
 add.l a2,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a4)+  * put it onto screen 

; LogicalBP3
 move.l LogicalBP3,a4
 add.l a2,a4
 and.w d3,(a4)  * make hole in bg 
 move.w (a0)+,d4  * d4 = spr data 
 lsr.w d1,d4  * shift it 
 and.w d2,d4  * mask it 
 or.w d4,(a4)+  * put it onto screen 

 add.l BytesPerScreenLine,a2 * adda.l #BytesPerPixelLine,a2  * next scrn line 
 dbra d0,drw_left1 
 rts 
 endc ; Amiga drw_left routine
;;;;;;;;; 


;-----------------------------
;    make sprite mask
 
MM macro
 move.w (a0)+,d2 
 or.w (a0)+,d2 
 or.w (a0)+,d2 
 or.w (a0)+,d2 
 eor.w d1,d2 
 move.w d2,(a1)+ 
 endm

make_mask: 
 move.l reqd_cell,a0 * data pointer 
make_mask_a: 
 move.l mask_buffPtr,a1 * mask pointer 
 moveq #-1,d1  * 'mask' 
make_mask1: 
 MM
 MM
 MM
 MM

 MM
 MM
 MM
 MM

 MM
 MM
 MM
 MM

 MM
 MM
 MM
 MM

 rts 
 
 
 
 
;-----------------------------
; find reqd mask pointer
 
GetMask: 
* get mask starting at g_map+d0.l with z coord d1.w
 clr.l d7 
 clr.l d2 
 clr.l d3
 move.w d0,d2  * d2 = current link pntr 
 movea.l g_mapPtr,a0  * a0 = link base 
 move.w 0(a0,d2.l),d3 * d3 = next link pntr 
 beq GetMask5  * no chain exists 
* 1st link exists 

GetMask1a
 cmp.w 6(a0,d3.l),d1 * plyr z >= link z ? 
 blt GetMask2
* yes - next link 

GetMask1: 
 move.w d3,d2  * d2 = new link pntr 
 move.w 0(a0,d2.l),d3 * d3 = next link 
 bne GetMask1a

GetMask3: 
* end of chain 
 cmp.w 6(a0,d2.l),d1 * plyr z < last link ? 
 bge GetMask5

* yes - get mask pntr 
GetMask2: 
 move.w 2(a0,d3.l),d7 * d7 = mask pntr 
; move.l masks_start,d6 
; add.l d7,d6 
; rts
 bra.s GetMask5a
GetMask5: 
 move.l null_maskPtr,d6 
 tst.w d7 
 beq GetMask6 
GetMask5a: 
 ifne SafeMode
  btst #0,d7
  beq.s GetMask6a
  dc.w $4afa
GetMask6a
 endc * SafeMode

 move.l masks_start,d6 
 add.l d7,d6 
GetMask6: 
 rts 
;------------ 
;-----------------------------
;      reverse a cell
 
RevCell: 
RevCell_a: 
 moveq.l #8,d3 * modulus on desination
 movea.l reqd_cell-S(A5),a1 * original cell data 
 move.l ReversedCellBufferPtr-S(A5),a3
 move.l a3,reqd_cell-S(A5) * = reversed cell 

RevCellD3
 movem.l a1-a3,-(sp) 
 lea rev_tab-S(A5),a2  * reverse data list 
 moveq #15,d1 
 clr.l d2 
RevCell_1: 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),1(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),(a3) 
 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),3(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),2(a3) 
 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),5(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),4(a3) 
 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),7(a3) 
 move.b (a1)+,d2 
 move.b 0(a2,d2.l),6(a3) 
 
 add.l d3,a3 * next line of destination sprite. addq.l #8,a3 
 dbra d1,RevCell_1 
 movem.l (sp)+,a1-a3 
 rts 
 

