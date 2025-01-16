*>>mike 22/12/88 All BGT changed to BHI (i.e. unsigned variety)
*>>mike 22/12/88 and BLT changed to BCS (ditto)
*>>Mike 18/1/89 Raster blocks can now be reversed when called by xzh objects
 
*>>Mike 26/1/89 Error trapping added for rasters and in GetCell
*>>Mike 26/1/89 Error trapping added in Find_obj:
*>>Mike 28/1/89 - code added for negative xzh coords in xzh objects
*>>Mike 29/1/89 - code added to call acode Animation handler.
*>>Mike 29/1/89 - Find_Obj: fixed for ani/compr objects:
*        now returns object type.
*>>Mike 29/1/89 - Find_obj: now works for animation objects.
*>>Mike 9/2/89 - UseVm test moved.+Moved back: didn't work
*   for reversed cells being inserted into structure.
 
*>>Mike 9/2/89 - My added code no longer uses a5. (corrupted
* by some routines: espec 3d_mem.s
*>>Mike 13/2/89 - Rasteroffset code added (one line!)
*>>Mike 13/2/89 - GetCell changed to prevent reversed
* cell requests from doing loads of seeks.
*>>Mike 20/2/89 - RemCell fixed: asr not lsr.
*>>Mike 21/2/89 - find_rst: changed in two places so it doesn't crash
*  if a zero-xsize raster is displayed.
*>>mike 27/2/89 - translation table part-added.
*>>Mike 27/2/89 - zmask removed from InsCell
*>>mike 4/3/89 - ResetPreLoad call added to allow
*   multiple calls to preload, without doing other Init3d's 
*>>Mike 19/3/89 - ScreenYClip constant added 
*>>Mike 19/3/89 - GraphicsScreenBase now used instead of LogicalBase 
*>>mike 28/3/89 - InsCell, RemCell changed to use signed compares 
*  again. 
;>>Mike 13/4/89... more changes to GetCell to help editor. 
*>>MIke 21/4/89 - BHI changed back to BGT to make -ve z coords work 
*    (Oops - my fault!) 
*>>Mike 1/5/89 - change to drw_vmap to prevent some crashes 
*>>Mike 28/5/89 - comments to find_obj:, acode entry. 
*>>Mike 28/5/89 - find_obj3 and 4 swapped to allow 
* machine code to find animation objects. 
*>>MIke 28/5/89 - find_ani changed to use find_rst for actual object itself. 
*>>Mike 31/5/89 - changes to way m_load_u called 
* to avoid calling it with reflected cells (which hung  up  
* the machine). Also error trapping for this in m_load_u. 
 
*>>MIke 31/5/89 - changes to make reversed inserted cells 
*   work properly (fix to my earlier code) 
*>>Mike 16/6/89 - 3D_boot.s: out of memory error added, 
*  list of errors (below) updated 
*>>Mike 18/6/89 - error trapping for reversed cells added. 
*>>Mike 26/6/89 - trap for out of range xzh objects added 
*  to avoid infinite loops when empty objects called up. 
*>>Mike 2/7/89 - EmptyRoom1b added to clear rest of links
  
* Interesting points on converting back from Amiga
* to ST:
* (1) space allocated to preload table may not be adequate

*>>Mike 16/8/89 - non-cell-aligned inserts now allowed.

;========================================================== 
; Error Codes Returned to Acode 
 
 
; Error codes returned in AX; AH is the error source, AL is the internal 
;  error number 
; 
;   AH Error Source AL  Error Code  Type    Action 
; 
;   0 Disc system XX  Disc error codes Advice    None 
; 
;   1 Driver  00  Heap error  Warning/Fatal Grab more 
;    01  No Transparencies Warning  Grab more 
;    02  No MapLinks  Warning  Grab more  
;    03  Cell out of range Warning  Grab more  
;    04  Purging Error Warning/Fatal Grab more  
;    05  No more reversed cells 
;    06  Bug in cell load request
;
;   2  Driver  XX  Requestor drawn Advice  (1) 
; 
;   3  Disc system XX  Sprites not found   Fatal  Restart! 
;    01  Please insert disc V1 (ST)
;
;   4 Driver: 00 map too tall: Warning: resize
;	01: map too large. Warning: resize
;
;   9  Memory   01  Out of memory (3D)
;   9    02  MCReserve memory failed
; 
; 
; (1) If requestor has been drawn in the current window, then ignore as 
; the screen will be updated; however if the requestor is outside 
; the current window then the top window will have to be redrawn to 
; erase the requestor 
; 
; 
NoTransparenciesError equ $101 
NoReversedCellsError equ $105 


LinkPtrOffset equ 0
MaskPtrOffset equ 2
CellNumOffset equ 4
ZCoordOffset equ 6
XShiftOffset equ 8 * within link
YShiftOffset equ 9

;--------------
TopReqd_cell dc.l 0
TopMask_BuffPtr dc.l 0


 ifne AmigaCellGrouping
  include BigSprite.s
 endc
 include InsRem.s
 include sprite.s
 
MCFindObj: 
 movem.l a3-a6,-(sp) 
  move.w 2(a4),d0 * v1 is object number to find. 
  bsr find_obj 
 movem.l (sp)+,a3-a6 
* a0.l is object found 
* list v2 is start of structure buffer 
 move.w 4(a4),d0 ; V2 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a1 
 ext.l d0 
 add.l d0,a1 
 move.l (a1),a1 ; start of structure buffer list. 
 
 sub.l a1,a0 * get offset from start of structure buffer 
 move.l a0,d0 
 move.w d0,6(a4) * return v3 as offset in structure buffer 
 clr.l d0 * return high word of d0.l 0
 rts 
 
MCmake_pic0: 
 movem.l a3-a6,-(sp) 
 bsr make_pic0 
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l 0
 rts 
 
IncrementClock:
 move.w sys_clock-S(A5),d0
 addq.w #1,d0
 and.w #$7f,d0
 move.w d0,sys_clock
 rts
 
* called from acode - with: 
* 
*  v1: object number 
*  V2: x coord in pixels 
*  V3: z   " 
*  V4: h   " 
*  V5: flag = -1 for remove object from structure 
*    0 for insert object into structure 
*   +1 for draw to screen directly (as a sprite) 
InsertRebuild equ  2 * insert/rebuild 
*   +3 for dummy draw to do pre-loading of cells 
*   +4 set protection mark 
*   +5 unset protection mark 
*   +6 purge object 
*   +7 non-aligned insert
*   +8 non-aligned remove

*  V6: reverse flag  (-ve for reversal) 
* 
* No return value. 
*--------------------------------------------------------- 
dDraw equ 1
dMarkPreload equ 3
dSetProtect equ 4
dinsertNonAligned equ 7
dremoveNonAligned equ 8
 
dummy_draw: equ 3 * dummy draw flag value for 
*     cell pre-loading 
make_pic0: 
 addq.l #2,a4  * skip on to V1 
 move.w (a4)+,d0  * object number 
 move.w (a4)+,xcord  * xcord 
 move.w (a4)+,zcord * zcord 
 move.w (a4)+,hcord  * hcord 
 move.w (a4)+,drw_flag * draw flag 
 move.w (a4),rev_flag * reverse flag 
*  process passed data 
 
make_pic1: 
 tst.w d0  * object 0 ? 
 beq make_picx 
 bsr find_obj  * find initial object 
 move.w d2,list_len-S(A5)  * data list length 
 beq make_picx  * dummy object exit 
 pea make_picx  * ret addr 
 ext.l d1 
 lsl.w #2,d1 
 lea jmp_tab-4-S(A5),a1 
 move.l 0(a1,d1.l),-(sp) 
 rts 
 
*  jump table to routines 
 
jmp_tab: dc.l DoRaster 
 dc.l do_comps 
 dc.l DoCell 
 dc.l DoXZH0 
 dc.l do_animat 
 
do_comps: 
 rts 
do_animat: 
;*>>Mike 29/1/89 
;; (a0) is header for animation object 
; sub.l SBStart-S(A5),a0 
; move.l a0,d0 
; move.w d0,AniHeader-S(A5) 
; movem.l a5-a6,-(sp) 
;  move.l AcodeFns-S(A5),a0 
;  add.l #52,a0 ; call acode animation object handler 
;  bsr CallAcode 
; movem.l (sp)+,a5-a6 
 rts 
 
*  return point for all routines 
 
make_picx: 
DoXZHRet
 rts 
 
 
 
;------------------------------------
; process control list
 
DoXZH0: 
 tst.w list_len-S(A5)
 beq.s DoXZHRet * null-length object
 tst.w rev_flag-S(A5) 
 bpl DoXZH0a 
 
 clr.w d0 
 move.b 2(a0),d0 * xsize in cells 
 lsl.w #4,d0 
 add.w d0,xcord-S(A5) 
DoXZH0a: 
 move.w xcord,-(sp)  * save xcord 
 move.w zcord,-(sp)  * save zcord 
 move.w hcord,-(sp)  * save hcord 
 move.l a0,-(sp)  * save list pointer 
 
 clr.w d0 
 move.b 4(a0),d0  * d0 = xcord add 
 ext.w d0 * >>Mike 28/1/89 
 lsl.w #2,d0 * convert from cels to pels 
 add.w d0,xcord-S(A5) 
 tst.w rev_flag-S(A5)  * reversing ? 
 bpl DoXZH0b  * no 
 
 lsl.w #1,d0  * double add 
 sub.w d0,xcord-S(A5)  * subtract it 
DoXZH0b: 
 clr.w d0 
 move.b 5(a0),d0 
 ext.w d0 * >>Mike 28/1/89 
 lsl.w #2,d0 * convert from cels to pels 
 add.w d0,zcord-S(A5) 
 move.b 6(a0),d0 
 ext.w d0 * cope with negative h coords >>MIke 28/1/89 
 lsl.w #2,d0 * convert from cels to pels 
 add.w d0,hcord-S(A5) 
 move.b 7(a0),d0 
 lsl.w #8,d0 
 move.b 8(a0),d0  * d0 = object no. 
 
 bsr find_obj 
* calculate lhs of structures for reversal... 
 tst.w rev_flag-S(A5) 
 bpl DoXZH2 
 
 moveq #16,d4  * cell width 
 cmpi.w #3,d1 
 beq DoXZH3 
 
 clr.w d4 
 move.b 2(a0),d4 * xsize 
 lsl.w #4,d4 
DoXZH3: 
 sub.w d4,xcord-S(A5) 
DoXZH2: 
 cmpi.w #4,d1  * object = control ? 
 bne DoXZHa  * no 
 
 move.w rev_flag-S(A5),-(sp) * save old flag 
 eor.w d0,rev_flag-S(A5) 
 
 move.w list_len-S(A5),-(sp) * save list length 
 move.w d2,list_len-S(A5)  * new list length 
 bsr DoXZH0  * recursive call 
 move.w (sp)+,list_len-S(A5) * get list len 
 move.w (sp)+,rev_flag-S(A5) * get rev flag 
 
DoXZH1: 
 movea.l (sp)+,a0  * get list pointer 
 addq.l #5,a0  * next data set 
 move.w (sp)+,hcord-S(A5) 
 move.w (sp)+,zcord-S(A5) 
 move.w (sp)+,xcord-S(A5) 
 
 subq.w #1,list_len-S(A5)  * end of data ? 
 bmi.s DoXZHExit *>>Mike 26/6/89 
 bne DoXZH0a  * no 
DoXZHExit 
 rts   * else return to ? 
 
 
DoXZHa: 
 cmpi.w #1,d1  * raster block ? 
 bne DoXZHb  * no 
 
 move.w rev_flag-S(A5),-(sp) * save old flag *>>Mike 18/1/89 
  eor.w d0,rev_flag-S(A5)   *>>Mike 18/1/89 
  bsr DoRaster  * process it 
 move.w (sp)+,rev_flag-S(A5)   *>>Mike 18/1/89 
 bra DoXZH1  * loop 
DoXZHb: 
 cmpi.w #3,d1  * cell block ? 
 bne DoXZH1  * no 
 
 bsr DoCell 
 bra DoXZH1 
 
;------------------------------------
; process a raster block
 
DoRaster: 
 move.w zcord-S(A5),d2   
 sub.w hcord-S(A5),d2 
 move.w d2,ypos-S(A5)  * drawing y position 
 asr.w #4,d2 
 move.w d2,yCell-S(A5)  * tile ycord 
 move.w d3,ycnt-S(A5)  * height in tiles 
 clr.w d6 
 move.b 2(a0),d6  * d6 = x width tiles 
 move.w d6,xcnt-S(A5)  * x counter 
 move.w d6,xsize-S(A5)  * x size 
 addq.l #4,a0  * data list start 
 
 tst.w rev_flag-S(A5) 
 bmi DoRevRast  * reverse raster 
 bra DoNormRast 
 
DoRasterx: 
 rts 
 
;------------------------------------
* process a normal raster block 
 
DoNormRast: 
DoNormRastXLoop:
 move.w (a0)+,d0  * d0 = cell no. 
 beq DoNormRast2b * 0 = space 
 ifne SafeMode
  cmp.w pntrs_tab+28-S(A5),d0 
  bcs DoNormRastRet *>>mike 26/1/89 
 endc 
 move.l a0,-(sp) * save position in raster
 move.w drw_flag-S(A5),d1  * what to do ? 
 cmp.w #ddraw,d1
 beq.s DoNormRastDraw

 pea DoNormRast2 * return addr. 
 tst.w d1 * sprite plotting is far more time critical,
* so it's more efficient in this order.
 bmi RemCell_a  * -1 = remove cell 
 beq InsCellD0
 cmp.w #InsertRebuild,d1 
 beq InsRebuildD0 
 cmp.w #dinsertNonAligned,d1
 beq insNARebuildD0 * insCellNAD0 * beq InsCellNonAligned
 cmp.w #dRemoveNonAligned,d1
 beq RemNARebuildD0 * CellNonAligned
 cmpi.w #dummy_draw,d1  * dummy draw ? 
 beq fake_draw  * yes 
 cmp.w #dSetProtect,d1
 beq SetProtect

 addq.l #4,sp * junk return address 

DoNormRastDraw
 bsr DrwCellD0
 
DoNormRast2: 
 move.l (sp)+,a0 * restore position in raster
DoNormRast2b: 
 addi.w #16,xcord-S(A5)  * xcord = +1 tile 
 subq.w #1,xcnt-S(A5)  * end of row ? 
 bne DoNormRastXLoop  * no 
 
 move.w xsize-S(A5),d0  * d0 = width 
 move.w d0,xcnt-S(A5)  * reset counter 
 lsl.w #4,d0 
 sub.w d0,xcord-S(A5)  * reset xcord 
 addq.w #1,yCell-S(A5)  * yCell = +1 tile 
 addi.w #16,ypos-S(A5) 
 subq.w #1,ycnt-S(A5)  * done ? 
 bne DoNormRast  * no - loop 
DoNormRastRet 
 rts 
 
;------------------------------------
* process a reverse raster block 
 
DoRevRast: 
 ext.l d6 
 lsl.w #1,d6  * list offset 
 adda.l d6,a0  * end of row +1 
DoRevRast3: 
 move.w -(a0),d0  * d0 = cell no. 
 beq DoRevRast2b * 0 = space 
 cmp.w pntrs_tab+28-S(A5),d0 
 bcs DoNormRastRet *>>mike 26/1/89 
 
 move.l a0,-(sp)
 move.w drw_flag-S(A5),d1  * what to do ? 
 cmp.w #ddraw,d1
 beq.s DoRevRastDraw

 pea DoRevRast2 * ret addr 
 tst.w d1
 bmi RemCell_a * -1 =remove rev cell 
 beq InsCellD0 * 0 = insert rev cell 
 cmp.w #InsertRebuild,d1 
 beq InsRebuildD0 
 cmp.w #dinsertNonAligned,d1
 beq insNARebuildD0 * insCellNAD0 * beq InsCellNonAligned
 cmp.w #dRemoveNonAligned,d1
 beq RemNARebuildD0 * CellNonAligned
 cmpi.w #dummy_draw,d1  * dummy draw ? 
 beq fake_draw  * yes 
 cmp.w #dSetProtect,d1
 beq SetProtect


 addq.l #4,sp * junk return address 
 
DoRevRastDraw
 bsr DrwCellD0 *>>11/7/89
 
DoRevRast2: 
 move.l (sp)+,a0
DoRevRast2b: 
 add.w #16,xcord-S(A5)  * xcord = +1 tile 
 subq.w #1,xcnt-S(A5)  * end of row ? 
 bne DoRevRast3  * no 
 
 move.w xsize-S(A5),d5  * d5 = width 
 move.w d5,d6 
 move.w d5,xcnt-S(A5)  * reset counter 
 lsl.w #1,d5 
 adda.l d5,a0  * next row start 
 
 lsl.w #3,d5 
 sub.w d5,xcord-S(A5)  * reset xcord 
 addq.w #1,yCell-S(A5)  * yCell = +1 tile 
 addi.w #16,ypos-S(A5) 
 subq.w #1,ycnt-S(A5)  * done ? 
 bne DoRevRast  * no - loop 
 rts 
 
;------------------------------------
; process a single cell
 
DoCell: 
 tst.w drw_flag-S(A5)  * what to do ? 
 bmi RemCell  * -1 = remove 
 cmp.w #ddraw,drw_flag-S(A5)
 beq DrwCell  * +1 = draw 
 cmpi.w #dummy_draw,drw_flag-S(A5)  * dummy draw ? 
 beq fake_draw  * yes 
 cmp.w #dSetProtect,drw_flag-S(A5)
 beq SetProtect
 cmp.w #dinsertNonAligned,d1
 beq insNARebuildD0 * insCellNAD0 * beq InsCellNonAligned
 cmp.w #dRemoveNonAligned,d1
 beq RemNARebuildD0 * CellNonAligned
; cmp.w #dinsertNonAligned,drw_flag
; beq InsCellNonAligned
; cmp.w #dRemoveNonAligned,drw_flag
; beq RemCellNonAligned
 bra InsCell  * 0 = insert 
 
 
 ifeq AmigaCellGrouping
MCUpdateScreen
 rts
 endc
 
SetProtect
* set protection flag for object number d0 (always a cell)
 and.l #$7fff,d0 *>>Mike 31/5/89 - in case it was reflected. 
 move.w d0,d1  * is cell already 
 sub.w pntrs_tab+28-S(A5),d1 * in memory ? 
 ext.l d1 
; lsl.w #1,d1  * 6, to get cell table entry.
; move.w d1,d2 
; lsl.w #1,d1 
; add.w d2,d1 
; movea.l cell_tabPtr,a0 
; bset #15,0(a0,d1) * set protection flag in timer.
 lsl.l #2,d1 * 4, to get cell table entry
 move.l cell_tabPtr-S(A5),a0
 add.l d1,a0
 bset #15,(a0) * set protection flag in timer
 rts
;---
fake_draw: 
 and.l #$7fff,d0 *>>Mike 31/5/89 - in case it was reflected. 
 move.w d0,d1  * is cell already 
 sub.w pntrs_tab+28-S(A5),d1 * in memory ? 
 ext.l d1 
; lsl.w #1,d1  * 6, to get cell table entry.
; move.w d1,d2 
; lsl.w #1,d1 
; add.w d2,d1 
; movea.l cell_tabPtr,a0 
; tst.l 2(a0,d1.l) 
 lsl.l #2,d1 * *4 to get cell table entry
 move.l cell_tabPtr-S(A5),a0
 add.l d1,a0
 tst.l (a0)
 bne DrwCellx 
 
 move.w d0,d1  * else write cell no. 
 sub.w pntrs_tab+28-S(A5),d1 
; ext.l d1  * to primary load 
; lsl.w #1,d1  * list 
; movea.l load_list,a0 
; move.w d0,0(a0,d1.l) 
* calculate index into bitwise table
 move.w d1,d2
 and.w #$0007,d2
 lea BitwiseOrTable-S(A5),a0
 move.b (a0,d2),d2 * get bit-or value
 asr.w #3,d1 * get byte offset into table
 move.l load_list-S(A5),a0
 cmp.w SizePreLoadTable-S(A5),d1
 bcc CellOutOfRangeError
 or.b d2,0(a0,d1)
 rts
;----
BitwiseOrTable
 dc.b $80,$40,$20,$10,$08,$04,$02,$01

 
; find a reversed cell
; 
;find_rev: 
; lea rev_list-4,a4 
;find_rev_1: 
; addq.l #4,a4 
; cmp.w (a4),d0 
; bne find_rev_1 
; 
; move.w 2(a4),d0 
; rts 
 
;-------------------------------
; find an object
 
MikeFindObj * find_obj: 
* given d0.w as object number, return 
* a0.l as pointer to structure. >>Mike 28/5/89 (comment) 
 sub.w #1,d2 * convert object numbering from 1..n to 0..n-1
 move.w d2,d0 * original object number
 asr.w #2,d0 * divide by 16 (address of every 16th object is stored)
 and.w #$FFFC,d0 * and multiply by 4 (4 bytes per entry)
 ext.l d0
 lea FastFindObjectTable-S(A5),a0
 add.l d0,a0
 move.l (a0),a0
 asl.w #2,d0 * regain the object number whose address is a0
 move.w d0,d1
 sub.w d1,d2 * now get difference between our fast entry and
* the actual object we want to find.
 beq.s FastFindObjectRet
 sub.w #1,d2 * -1 for dbra
 clr.l d7 * clear high word.
MikeFindObjZ
 ifne SafeMode
  move.w a0,d7 *>> 
  btst #0,d7 *>> 
  bne Mikefind_objError *>>Mike 26/1/89 
 endc
 move.w (a0),d7 
 adda.l d7,a0 
 dbra d2,MikeFindObjZ
FastFindObjectRet
 rts
;---

find_obj:
SearchingFindObject:
 move.w d0,-(sp)  * save obj no. 
 bclr #15,d0  * lose flag bit 
 move.w d0,d2 * pass d0 as parameter to MikeFindObj
 clr.l d7 
 lea pntrs_tab-S(A5),a1 * 1st data pointer 
 movea.l (a1)+,a0  * a0 = x,z,h,#'s 
 cmp.w (a1)+,d0  * obj = x,z,h,# ? 
; bgt find_obj1  * no 
 bhi find_obj1  * no 
 
*  object is 'x,z,h,#' type 
 moveq #4,d1 * object type 
 subq.w #1,d0 
 beq find_ctr2 
 bsr TranslateD0 *>>Mike 27/2/89 
 subq.w #1,d0 
find_ctr1: 
 move.l d1,-(sp) 
  bsr MikeFindObj 
 move.l (sp)+,d1 
 
find_ctr2: 
 move.w (a0),d2 
 subq.w #4,d2 
 ext.l d2 
 divu #5,d2 
 bra find_objx 
 
 
find_obj1: 
 movea.l (a1)+,a0  * a0 = rasters 
 cmp.w (a1)+,d0  * obj = raster ? 
; bgt find_obj2  * no 
 bhi find_obj2  * no 
 
*  object is a raster block 
 add.w RasterOffset-S(A5),d0 *>>Mike 13/2/89 
 bsr TranslateD0 *>>Mike 27/2/89 
 move.w d0,d2 * store off new real object number for
* MikeFindObject
 
 moveq #1,d1  * d1 = object id 
find_rst: 
 sub.w -8(a1),d0 
 subq.w #1,d0  * 1st obj ? 
 beq find_rst2  * yes 
 subq.w #1,d0 
find_rst1: 
 move.l d1,-(sp) * keep object type 
  bsr MikeFindObj 
 move.l (sp)+,d1 
find_rst2: 
 move.w (a0),d2 
 subq.w #4,d2 
 beq.s find_objError * null-length raster object >>mike 21/2/89 
 lsr.w #1,d2 
 ext.l d2 
 move.l d2,-(sp) 
 move.b 2(a0),d3 
 ext.w d3 
 beq.s find_objError2 * zero x size raster object. >>Mike 21/2/89 
 divu d3,d2 
 move.w d2,d3 
 move.l (sp)+,d2 
 bra find_objx 
 
find_obj2: 
 movea.l (a1)+,a0  * a0 = animats pointer 
 cmp.w (a1)+,d0 
; bgt find_obj4 
 bhi find_obj4 
 
 
; sub.w -8(a1),d0 
; subq.w #1,d0  * 1st obj ? 
; beq find_rst2  * yes 
; subq.w #1,d0 
;find_Ani1: 
; move.w a0,d7 *>> 
; btst #0,d7 *>> 
; bne find_objError *>>Mike 26/1/89 
; move.w (a0),d7 
; adda.l d7,a0 
; dbra d0,find_Ani1 
 bsr TranslateD0 *>>Mike 27/2/89 
 moveq #2,d1 * animation type >>Mike 29/1/89 
 bra find_rst *>>mike 28/5/89 - find actual object. bra find_objx 
 
find_obj4: 
 movea.l (a1)+,a0  * a0 = compresseds 
 cmp.w (a1)+,d0  * obj = comp ? 
; bgt find_obj3  * no 
 bhi find_obj3  * no 
 
*  object is compressed type 
 bsr TranslateD0 *>>Mike 27/2/89 
 
; nop 
 moveq #5,d1 * compressed type *>>mike 29/1/89 
 bra find_objx 
 
 
find_obj3: 
 movea.l (a1)+,a0  * a0 = cell data 
 
*  object is a cell 
 moveq #3,d1  * cell id 
 moveq #-1,d2 
 sub.w (a1),d0 * take off mincell 
 subq.w #1,d0  * d0 = cell no. 
 mulu #128,d0 
 adda.l d0,a0  * a0 = data 
 bra find_objx 
 
*  a0 = object start 
*  d1 = object id 
*  d2 = object data list length 
*  d3 = object y height (raster) 
find_objError2: 
 move.l (sp)+,d2 *>>mike 21/2/89 
 
find_objError: 
 move.w #0,d2 * return null length 
 
find_objx: 
 move.w (sp)+,d0  * d0 = obj no. 
 rts 
 
TranslateD0 
; MC has an xzh, raster or animation object d0.w 
; Run it through the translation table (which gives, e.g. 
; different facial expressions whilst walking along. 
 rts 
;------ 
;MikeFindObj:
; find object by following the linked list along 
 move.w a0,d7 *>> 
 btst #0,d7 *>> 
 bne Mikefind_objError *>>Mike 26/1/89 
 move.w (a0),d7 
 adda.l d7,a0 
 dbra d0,MikeFindObj
 
; follow linked list using signed arithmetic, like 
; acode. 
; a0.l is start of the appropriate block of objects
; move.l a0,d7
; sub.l SBStart,d7
; move.l SBStart,a0
;
;* find current offset within structure buffer
;MFO1 
; move.w (a0,d7),d1 
; btst #0,d1 
; bne MikeFind_objError 
; add.w d1,d7 
; dbra d0,MFO1 
; lea (a0,d7),a0 * return a0.l as actual address we've found... 
;
; clr.l d0
; move.w (a0),d0
; tst.w d7
;
;MFNoDebug
 rts 
 
MikeFind_objError 
 addq.l #8,sp * lose return address, saved a1.l 
 bra find_objError 
;-----  
; create final view map
 
MCBuildRoom: 
 movem.l a3-a6,-(sp) 
 bsr BuildRoom 
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l 0
 rts 
 
*----------------------- 
 
* Called with no parameters to create the view 
* map from the 3D structure. 
 
BuildRoom: 
 movea.l BufferScreen1-S(A5),a0 * a0 = view map 
 movea.l g_mapPtr-S(A5),a1  * a1 = ground cell map 
; ifeq ScrollingSystem
;  add.l #4,a1
; endc
 move.b GameMode-S(A5),d0
 beq.s BuildRoomOrigin * non-scrolling, so ignore parameters
* what coordinates were specified?
 move.w 2(a4),d0 * x coord in pixels
 asr.w #2,d0 * /4*2
 and.w #$fffc,d0 * mask off bottom two bits
 ext.l d0
 add.l d0,a1
 move.w 4(a4),d0 * y coord in pixels
 asr.w #4,d0 * /4
 move.w d0,ScreenYFirstCell-S(A5)
 muls MapXCellsTimes4-S(A5),d0
 add.l d0,a1
 move.w 2(a4),d0 * x coord in pixels
 asr.w #4,d0
 move.w d0,ScreenXFirstCell-S(A5)

BuildRoomOrigin:
 move.w DisplayedYCellsMinus1-S(A5),d6 * height counter 
; ifeq ScrollingSystem
;  sub.w #1,d6
; endc

BuildRoomYLoop 
 move.w DisplayedXCells-S(A5),d7 * width counter (Scroll: was Minus1)
 ifne ScrollingSystem
  sub.w #1,d7
 endc
 ifeq ScrollingSystem
  sub.w #1,d7
 endc
 movem.l a0-a1,-(sp)
BuildRoomXLoop: 
  move.w 2(a1),d0  * char no. 
  beq BuildRoom3  * blank 
  movem.l d6-d7/a0-a1,-(sp) 
   bsr feature  * process a 3D feature 
  movem.l (sp)+,d6-d7/a0-a1
 
BuildRoom3: 
; movem.l d0-d7/a0-a6,-(sp)
;  lea s(pc),a5
;  move.l LogicalBase,GraphicsScreenBase
;  bsr DisplayRoom
;  bsr ActuallySwapScreen
; movem.l (sp)+,d0-d7/a0-a6
 
 
  ifne ST
  addq.l #8,a0  * next BufferScreen address 
  addq.l #4,a1  * next g_map cell 
  dbra d7,BuildRoomXLoop 
  movem.l (sp)+,a0-a1
 add.l BytesPerBSLineTimes16-S(A5),a0 *  add.l #(160*15)-8,a0 * skip onto next cell row in BufferScreen1 
 add.l MapXCellsTimes4-2-S(A5),a1 * go on to next map line (Accessing
 dbra d6,BuildRoomYLoop 
 endc
 
  ifne Amiga
  addq.l #2,a0  * next BufferScreen address 
  addq.l #4,a1  * next g_map cell 
  dbra d7,BuildRoomXLoop 
;;  add.l #(BytesPerPixelLine*15)-2,a0 * skip onto next cell row in BufferScreen1 
 movem.l (sp)+,a0-a1
 add.l MapXCellsTimes4-2-S(A5),a1 * go on to next map line (Accessing
* a word as a long, ok cause previous word is zero)
 add.l BytesPerBSLineTimes16-S(A5),a0 * skip onto next cell row in BufferScreen1 
 dbra d6,BuildRoomYLoop 
 endc

 ifne ScrollingSystem
 bsr BuildRoomScrolling * some other things the scrolling
* system must do at this point in time
 endc
 bra CalculateScreenPos * bsr, rts
 
 
;-------------------------------
;       process a 3d feature

InitialMask * used to start off chain.
* Totally transparent.
 dc.w $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
 dc.w $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff

DummyLink dc.w 0 * offset of a link specially set
* up to have a large z coord, and no other features.
XShift1 dc.b 0
YShift1 dc.b 0
XShift2 dc.b 0
YShift2 dc.b 0
LinkSortTable ds.b 6*64
* 6 bytes per entry. MUST contain
* enough entries for the largest possible number of levels within
* a cell, including any intrusions from above/left/above left.
* Think about it - this could be quite large if say 4 people are
* inserted very close together. Each cell they touch
* can potentially incorporate 4 or their cells. Thus these measely
* 4 people give an extra 16 levels to the structure.
 even
 
feature: 
* given a g_map linked list for cell with link (a1) and number 2(a1)
* with cell number d0.b
* produce the image at the current position in BufferScreen1: a0 
 cmp.l BufferScreen1-S(A5),a0
 bcc.s featureRange1Ok
; move.l BufferScreen1-S(A5),a2
; move.w BSXCellPos-S(A5),d2
; ext.l d2
; add.l d2,d2 * one word per cell
; add.l d2,a2
; cmp.l a2,a0
; bcc.s featureRange1Ok
 rts

FeatureRange1Ok
; bne.s MMMDEBUG2 *******
;;; dc.w $4afa ********
; move.w d0,reqd_cell * pass parameter to getandreversecell
;  move.l a0,-(sp) *****************
;   move.l BufferScreen1-S(a5),a0
;   move.w #(16)-1,d0
;MMDebug2
;  move.w #$ffff,(a0)
;   add.l #ConstBSPlaneSpacing,a0
;  move.w #$ffff,(a0)
;   add.l #ConstBSPlaneSpacing,a0
;  move.w #$0,(a0)
;   add.l #ConstBSPlaneSpacing,a0
;  move.w #0,(a0)
;   add.l #ConstBSPlaneSpacing,a0
;   dbra d0,MMDebug2
;  move.l (sp)+,a0
; movem.l d0-d7/a0-a6,-(sp) **********11/12/89
;  bsr getAndReverseCell * get cell data in reqd_cell
; movem.l (sp)+,d0-d7/a0-a6
; dc.w $4afa
;; movea.l reqd_cell-S(A5),a2 * a2 = cell data 
;; move.l a0,a3 * copy into BufferScreen1 
;; move.l BSPlaneSpacing-S(A5),d1
;; move.l d1,d2
;; add.l d2,d2
;; move.l d1,d3
;; add.l d2,d3
;;* Line 0...
;; move.w (a2)+,(a3)
;; move.w (a2)+,(a3,d1.l)
;; move.w (a2)+,(a3,d2.l)
;; move.w (a2)+,(a3,d3.l)
; rts
;;
MMMDebug2 ******
 cmp.l BufferScreen1End-S(A5),a0
 bcs.s FeatureRange2Ok

 move.l BufferScreen1End-S(A5),a2
 move.w BSXCellPos-S(A5),d2
 ext.l d2
 add.l d2,d2 * one word per cell
 add.l d2,a2
 cmp.l a2,a0
 bcs.s featureRange2Ok
 rts
;
FeatureRange2Ok
 move.w d0,reqd_cell * pass parameter to getandreversecell
 movem.l d0-d7/a0-a6,-(sp) **********11/12/89
 bsr getAndReverseCell * get cell data in reqd_cell
 movem.l (sp)+,d0-d7/a0-a6
* in (reqd_cell)=ReversedCellBufferPtr
FeatureGotCell
  movea.l reqd_cell-S(A5),a2 * a2 = cell data 
 move.l a0,a3 * copy into BufferScreen1 
Feature1: * local loop from dbra below 
* build cumulative cell on BufferScreen1 
 ifne sT
 move.l (a2)+,(a3) * line 0 
 move.l (a2)+,4(a3) 
 move.l (a2)+,ConstBytesPerBSLine(a3) * line 1 
 move.l (a2)+,ConstBytesPerBSLine+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*2(a3) * line 2 
 move.l (a2)+,ConstBytesPerBSLine*2+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*3(a3) * line 3 
 move.l (a2)+,ConstBytesPerBSLine*3+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*4(a3) * line 4 
 move.l (a2)+,ConstBytesPerBSLine*4+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*5(a3) * line 5 
 move.l (a2)+,ConstBytesPerBSLine*5+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*6(a3) * line 6 
 move.l (a2)+,ConstBytesPerBSLine*6+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*7(a3) * line 7 
 move.l (a2)+,ConstBytesPerBSLine*7+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*8(a3) * line 8 
 move.l (a2)+,ConstBytesPerBSLine*8+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*9(a3) * line 9 
 move.l (a2)+,ConstBytesPerBSLine*9+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*10(a3) * line 10 
 move.l (a2)+,ConstBytesPerBSLine*10+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*11(a3) * line 11 
 move.l (a2)+,ConstBytesPerBSLine*11+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*12(a3) * line 12 
 move.l (a2)+,ConstBytesPerBSLine*12+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*13(a3) * line 13 
 move.l (a2)+,ConstBytesPerBSLine*13+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*14(a3) * line 14 
 move.l (a2)+,ConstBytesPerBSLine*14+4(a3) 
 move.l (a2)+,ConstBytesPerBSLine*15(a3) * line 15 
 move.l (a2)+,ConstBytesPerBSLine*15+4(a3) 
 endc * ST

 ifne Amiga
 move.l BSPlaneSpacing-S(A5),d1
 move.l d1,d2
 add.l d2,d2
 move.l d1,d3
 add.l d2,d3
* Line 0...
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)
* Line 1...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 2...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 3...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 4...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 5...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 6...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 7...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 8...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 9...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 10...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 11...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 12...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 13...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 14...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

* Line 15...
 add.l BytesPerBSLine-S(A5),a3
 move.w (a2)+,(a3)
 move.w (a2)+,(a3,d1.l)
 move.w (a2)+,(a3,d2.l)
 move.w (a2)+,(a3,d3.l)

 endc * Amiga 

 ifne 0
  bra AlignedFeature * feature routine for aligned cells only.
  include NAFeature.s
 endc


AlignedFeature
; Now code we can use for aligned-cells only.
	clr.l	d0 
	move.w	(a1),d0		* d0 = next link offset 
	beq AlignedBackDropOnly * no 3d structure there. 
 bsr UnlinkA1 * unlink any existing chain from this cell.

* Create the 3D structure - i.e. cumulative cell,
* masks etc.
	movea.l	g_mapPtr-S(A5),a2		* a2 = links base 
	clr.w	2(a2,d0.l)		* null back pointer 
 
AlignedFeature2: * local loop from bra below 
 move.w CellNumOffset(a2,d0.l),reqd_cell * char number for this link.
 movem.l d0/a2,-(sp)
  bsr GetAndReverseCell
* in (reqd_cell)=ReversedCellBufferPtr
  lea LinkSortTable-S(A5),a6
  clr.w (a6) * zero x and y shifts.
  bsr NewCell  * make new char at (a0) from reqd_cell
 movem.l (sp)+,d0/a2
 clr.l d1 
 move.w LinkPtrOffset(a2,d0.l),d1 * d1 = next link offset 
 beq AlignedFeature3  * end of chain 
 move.w d0,2(a2,d1.l) * next link back pointer 
 move.w d1,d0  * point to next link 
 bra AlignedFeature2  * process it 
 
AlignedFeature3: * just jumped to from AlignedFeature2 loop above 
* Have finished making the cumulative cell,
* now work backwards using the back pointers (which
* set in 2(a2,d0) where the mask pointers usually reside.
* We want to create a set of masks, each of which includes
* all of those above it on the pile.
 move.w 4(a2,d0.l),d1
 move.w d1,reqd_cell-S(A5) * cell no. to find 
 movem.l d0/a2,-(sp)
  bsr GetAndReverseCell
 movem.l (sp)+,d0/a2
 move.l nx_f_mask-S(A5),d7 * free mask area 
 beq NoFreeMasks *>>Mike11/6/89 
 move.l d7,a3 
 move.l a3,WSMaskPtr-S(A5) * keep a record of the mask
* we may be only using temporarily
 move.l (a3),d7 * pointer to next free transparency 
 move.l d7,nx_f_mask-S(A5) * unlink the mask
 subq.w #1,FreeTransparencies-S(A5)
 
 move.l a3,d4 * keep record of mask address.
 movea.l reqd_cell-S(A5),a4 * data pointer 
 moveq #-1,d1 
 moveq #15,d2 
 clr.w d5 
AlignedFeature4: * just a local loop (dbra below) 
* build mask at a3.l = d4.l(d4 preserved)
 move.w (a4)+,d3 
 or.w (a4)+,d3 
 or.w (a4)+,d3 
 or.w (a4)+,d3 
 eor.w d1,d3 
 move.w d3,(a3)+ 
 or.w d3,d5 
 dbra d2,AlignedFeature4 
 
 move.w 2(a2,d0.l),d1 * d1 = back pointer 
 tst.w d5  * top mask all 0's ? 
 beq AlignedFeature7  * yes 
 
*>>Mike 11/6/89 move.l a3,nx_f_mask * new free mask 
; subq.w #1,FreeTransparencies 
 
;21/8 move.l nx_f_mask,a4 * mask we just created for CreMask 
;21/8 move.l d7,nx_f_mask * unlink the mask we just 
* created from the free space chain by making the free space 
* pointer point to the next one. 
 move.l d4,a4
 sub.l masks_start-S(A5),d4 * d4 = mask offset 
 move.w d4,2(a2,d0.l) * save mask pointer 
* make d7.l point to the transparency after the one 
* we'll create. 
;21/8 move.l d7,a3 * scratch a3.l 
;21/8 move.l (a3),d7 
 
AlignedFeature5: 
* a4.l is the mask we created last. 
* a3.l is a scratch address register 
 move.w d1,d0  * end of chain ? 
 beq AlignedFeaturex  * yes 
 
 move.w 4(a2,d0.l),d1
 move.w d1,reqd_cell-S(A5) * reqd char no. 
 movem.l d0/a2,-(sp)
  bsr GetAndReverseCell
  bsr CreMask * make comp mask from (reqd_cell) and (a4) 
 movem.l (sp)+,d0/a2
 move.w 2(a2,d0.l),d1 * back pointer 
 tst.w d5  * mask all 0's ? 
 beq AlignedFeature7 *>>Mike 16/6/89. AlignedFeature6a * yes - masks all null 
 
 move.l WSMaskPtr-S(A5),d2 * start of the mask we've just created 
 beq NoFreeMasks 
 move.l d2,a4 * keep record of the mask we just created 
* for access by CreMask next time round the loop 
 sub.l masks_start-S(A5),d2 * d2 = mask offset 
 move.w d2,2(a2,d0.l) * mask pointer 
  bra AlignedFeature5  * do next link 
;--- 
AlignedFeature7: 
* the mask we just created was all-zero 
* Link it back into fs chain
 move.l WSMaskPtr-S(A5),a3
 move.l nx_f_mask-S(A5),(a3)
 move.l a3,nx_f_mask-S(A5)
 addq.w #1,FreeTransparencies-S(A5)
 bra AlignedFeature6a  * masks all null 

AlignedFeature6: 
 move.w d1,d0  * d0 = next back link 
 beq AlignedFeaturex  * end of chain 
 move.w 2(a2,d0.l),d1 * d1 = next back pointer 
AlignedFeature6a: 
* enter here with (a2,d0) as current link. And d1=2(a2,d0).w 
 clr.w 2(a2,d0.l)  * null pointer 
 bra AlignedFeature6  * all chain = null 
 
AlignedFeaturex: 
AlignedBackDropOnly 
 rts   * done 
;------------------ 
 
NoFreeMasks 
 move.l #NoTransparenciesError,d0 
 bsr ErrorHandler  * do NOT do bra - makes debugging harder.
 rts

;-------------------------------
;     merge two cells
 
NewCell: 
* merge (reqd_cell) with cell (a0) in BufferScreen1 
* Shift (reqd_cell) by (x5).b=xshift, (x5+1).b=yshift
 move.l a0,a3 
 movea.l reqd_cell-S(A5),a4 * char data 
 moveq #-1,d1 
 clr.l d0
 move.b 1(a6),d0 * y shift
 bpl.s NewCellPositiveYShift
* y shift is negative: i.e. the shifted cell
* starts within the map cell above, and only
* overlays the top of this map cell. So add
* on to source address, and get appropriate number
* of lines
 clr.l d0
 move.b 1(a6),d0 * y shift
 add.b #16,d0 * get number of lines that overlay
 move.w d0,d2 * number of lines to do
 move.w #16,d0
 sub.w d2,d0 * get number of lines to skip
 lsl.l #3,d0 * 8 bytes per line of the cell
 add.l d0,a4 * add on to reqd_cel address
 sub.b #1,d2 * number of lines to do. -1 for dbra
 bra.s NewCellGotYShift

NewCellPositiveYShift
* y shift is positive: i.e. the shifted cell
* starts within this map cell, and overlays the next
* cell below. Here, we're just doing the bit that covers
* this map cell only. So add on to destination address,
* and get appropriate number of lines.
 move.w #16,d2
 sub.b d0,d2 * d0.b=yshift=1(a6)
 sub.b #1,d2 * number of lines to do -1 for dbra.
 mulu #BytesPerPixelLine,d0
 add.l d0,a3

NewCellGotYShift:
* now shift it right.

 ifne ST

 clr.l d0
 move.b (a6),d0 * x shift
 bpl NewCellPosXShift
* Negative shift, so we only want the d0
* rightmost pixels, shifted along to the left of the cell.
* We could swap into high word, then shift
* right by d0+16 steps.
* Instead, let's shift left by
 move.b #16,d3
 add.b (a6),d3 * add on the negative number: e.g. F4 for
* a 4-pixel offset, which gives d0.b=4
* shift left by d0.b pixels
 move.w #16,d0
 sub.b d3,d0
 cmp.b #16,d0
 bne.s NCGYSNotBlank
* x shift takes it completely out of this cell.
 rts

NCGYSNotBlank
NewCell1: 
 move.w (a4),d3 
 or.w 2(a4),d3 
 or.w 4(a4),d3 
 or.w 6(a4),d3 
 lsl.w d0,d3 * shift mask down into position.
 eor.w d1,d3 
 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,(a3)+ 
 add.l #ConstBytesPerBSLine-8,a3 * skip on to next row of cell 
 dbra d2,NewCell1 
 rts 
;---
NewCellPosXShift
* shift right by d0.w pixels
 move.w (a4),d3 
 or.w 2(a4),d3 
 or.w 4(a4),d3 
 or.w 6(a4),d3 
 lsr.w d0,d3 * shift mask down into position.
 eor.w d1,d3 
 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,(a3)+ 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,(a3)+ ************ and missing here/???????
 add.l #ConstBytesPerBSLine-8,a3 * skip on to next row of cell 
 dbra d2,NewCellPosXShift 
 rts 
 endc * ST


; ifne Amiga
;NewCell1: 
;* merging at (a3)
;* Can corrupt a3.l
; move.w (a4),d3 
; or.w 2(a4),d3 
; or.w 4(a4),d3 
; or.w 6(a4),d3 
; eor.w d1,d3 
; and.w d3,(a3) 
; move.w (a4)+,d4 
; or.w d4,(a3)
; and.w d3,BPSize(a3) 
; move.w (a4)+,d4 
; or.w d4,BPSize(a3) 
; and.w d3,2*BPSize(a3) 
; move.w (a4)+,d4 
; or.w d4,2*BPSize(a3) 
; and.w d3,3*BPSize(a3) 
; move.w (a4)+,d4 
; or.w d4,3*BPSize(a3) 
; add.l #BytesPerPixelLine,a3 * skip on to next row of cell 
; endc * Amiga
;;;;
 ifne Amiga
 clr.l d0
 move.b (a6),d0 * x shift
 bpl NewCellPosXShift
* Negative shift, so we only want the d0
* rightmost pixels, shifted along to the left of the cell.
* We could swap into high word, then shift
* right by d0+16 steps.
* Instead, let's shift left by
 move.b #16,d3
 add.b (a6),d3 * add on the negative number: e.g. F4 for
* a 4-pixel offset, which gives d0.b=4
* shift left by d0.b pixels
 move.w #16,d0
 sub.b d3,d0
 cmp.b #16,d0
 bne.s NCGYSNotBlank
* x shift takes it completely out of this cell.
 rts

NCGYSNotBlank
NewCell1: 
 move.w (a4),d3 
 or.w 2(a4),d3 
 or.w 4(a4),d3 
 or.w 6(a4),d3 
 lsl.w d0,d3 * shift mask down into position.
 eor.w d1,d3 
 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,(a3)

 and.w d3,ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,ConstBSPlaneSpacing(a3)

 and.w d3,2*ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,2*ConstBSPlaneSpacing(a3)

 and.w d3,3*ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsl.l d0,d4
 or.w d4,3*ConstBSPlaneSpacing(a3) 
 add.l BytesPerBSLine-S(A5),a3 * skip on to next row of cell 
 dbra d2,NewCell1 
 rts 
;---
NewCellPosXShift
* shift right by d0.w pixels
 move.w (a4),d3 
 or.w 2(a4),d3 
 or.w 4(a4),d3 
 or.w 6(a4),d3 
 lsr.w d0,d3 * shift mask down into position.
 eor.w d1,d3 
 
 and.w d3,(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,(a3)

 and.w d3,ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,ConstBSPlaneSpacing(a3)

 and.w d3,2*ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,2*ConstBSPlaneSpacing(a3)

 and.w d3,3*ConstBSPlaneSpacing(a3) 
 move.w (a4)+,d4 
 lsr.w d0,d4
 or.w d4,3*ConstBSPlaneSpacing(a3)
 add.l BytesPerBSLine-S(A5),a3 * skip on to next row of cell 
 dbra d2,NewCellPosXShift 
 rts 
 endc * Amiga

; dbra d2,NewCell1 
; rts 
;-------- 
 
;-------------------------------
;  create composite mask
 
CreMask: 
* a4.l is the previous mask along the chain 
* and reqd_cell is the char to combine with it 
* returns d1.l as 0 if ok, 1 on error 
* Transparent pixels are represented as 1s,
* so 0 is totally opaque.
* Shift (reqd_cell) by (x5).b=xshift, (x5+1).b=yshift
 move.l nx_f_mask-S(A5),d4 
 beq CreNoMask * no free masks 
 move.l d4,WSMaskPtr-S(A5) * keep address of mask we're corrupting
 move.l d4,a3 * new mask area 
 move.l (a3),nx_f_mask-S(A5) * unlink mask
 subq.w #1,FreeTransparencies-S(A5)
* Make this mask initially the same as the one above
* it one the chain. (we could of course do this
* as we generate it, but I can't be bothered).
* assumes 32 bytes per mask
 move.l a4,a2 * copy previous mask into current
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+

 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l d4,a3 * mask area
 movea.l reqd_cell-S(A5),a2 * char data 
 clr.w d5 

* stuff to do with shifting...
 clr.l d0
 move.b 1(a6),d0 * y shift
 bpl.s CreMaskPositiveYShift
* y shift is negative: i.e. the shifted cell
* starts within the map cell above, and only
* overlays the top of this map cell. So add
* on to source address, and get appropriate number
* of lines
 add.b #16,d0 * get number of lines that overlay
 move.w d0,d2 * number of lines to do
 move.w #16,d0
 sub.w d2,d0 * get number of lines to skip
 sub.b #1,d2 * -1 for dbra
 lsl.l #3,d0 * 8 bytes per line of the cell.
 add.l d0,a2 * add on to reqd_cel address
 bra.s CreMaskGotYShift

CreMaskPositiveYShift
* y shift is positive: i.e. the shifted cell
* starts within this map cell, and overlays the next
* cell below. Here, we're just doing the bit that covers
* this map cell only. So add on to destination address,
* and get appropriate number of lines.
 move.w #16,d2
 sub.b d0,d2 * d0.b=yshift=1(a6)
 sub.b #1,d2 * number of lines to do -1 for dbra.
 asl.l #1,d0 * 2 bytes per row of mask.
 add.l d0,a3 * add on to mask ptr

CreMaskGotYShift:
* now shift it right.
 moveq #-1,d3 * For inverting
 clr.l d0
 move.b (a6),d0 * x shift
 bpl CreMaskPositiveXShift
* Negative shift, so we only want the d0
* rightmost pixels, shifted along to the left of the cell.
* We could swap into high word, then shift
* right by d0+16 steps.
* Instead, let's shift left by
 move.b #16,d3
 add.b (a6),d3 * add on the negative number: e.g. F4 for
* a 4-pixel offset, which gives d0.b=4
* shift left by d0.b pixels
 move.w #16,d0
 sub.b d3,d0
 cmp.b #16,d0
 bne.s CMGYSNotBlank
* x shift takes it completely out of this cell.
 rts

CMGYSNotBlank
 moveq #-1,d3 * for inverting
CreMask1
* shift left by d0.w pixels
 move.w (a2)+,d4 
 or.w (a2)+,d4 
 or.w (a2)+,d4 
 or.w (a2)+,d4 
 lsl.w d0,d4
 eor.w d3,d4  * new mask word 
;; move.w (a4)+,(a3)  * old mask -> new mask 
 and.w d4,(a3)  * create new mask word 
 or.w (a3)+,d5  * or it 
 dbra d2,CreMask1 
 move.l #0,d1 * no error 
 rts 

CreMaskPositiveXShift: 
* shift right by d0.w pixels
 move.w (a2)+,d4 
 or.w (a2)+,d4 
 or.w (a2)+,d4 
 or.w (a2)+,d4 
 lsr.w d0,d4
 eor.w d3,d4  * new mask word 
;; move.w (a4)+,(a3)  * old mask -> new mask 
 and.w d4,(a3)  * create new mask word 
 or.w (a3)+,d5  * or it 
 dbra d2,CreMaskPositiveXShift 
 move.l #0,d1 * no error 
 rts 

 
CreNoMask 
 move.l d0,-(sp) 
  move.l #NoTransparenciesError,d0 
  bsr ErrorHandler 
 move.l (sp)+,d0 
 moveq.l #1,d1 * error code 
 rts 
 
;-------------------------------
;  Find the reqd cell address

GetAndReverseCell:
* get and reverse cell number reqd_cell.
* Put the cell data in reqd_cell
 move.l d0,-(sp) * preserve d0 (used for links etc)
 move.w reqd_cell-S(A5),d0
 bsr GetCell_a
 tst.w d0 * preserved cell number
 bpl.s GARC1
 bsr RevCell * get reversed data
GARC1
 move.l (sp)+,d0
 rts
;-----
GetCellError
 bsr CellOutOfRangeError
 bra GetCellBad

CellOutOfRangeError
 move.l #$103,d0 * cell out of range
 move.l a4,-(sp)
 move.w 2(a4),-(sp)
  lea S(PC),a5
  move.l List0Ptr-S(A5),a4 * vartable ptr
  move.w reqd_cell-S(A5),2(a4)
  bsr ErrorHandler
 move.w (sp)+,2(a4)
 move.l (sp)+,a4
 rts
;---- 
GetCell: 
; get cell D0.w
 move.w d0,reqd_cell-S(A5) 
GetCell_a: 
; get cell d0=reqd_cell
 move.l a0,-(sp) 
 move.l d0,-(sp) 
GetCell1: 
 and.l #$7fff,d0
 sub.w pntrs_tab+28-S(A5),d0
 cmp.w NumCells-S(A5),d0
 bcc GetCellError * OutOfRange

 add.l d0,d0 * doing 2 adds is faster than lsl 2
 add.l d0,d0
 move.l cell_tabPtr-S(A5),a0
 add.l d0,a0
 
; ifne ST
;  move.w UseVm-S(A5),d1 * tst.w UseVm(PC) * -S(A5) *>>Mike 18/1/89 9/2/89 
;  bne.s GetCellVM *>>mike 18/1/89 9/2/89 
; endc
 
GetCellVM 
 move.l (a0),d1 * valid ponter?
 and.l #CellAddressMask,d1
 bne GetCellx  * yes 
 move.w reqd_cell-S(A5),d0 * reqd cell no. 
 and.w #$7fff,d0 *>>Mike 31/5/89 
 move.w d0,d1  * to load 
 movem.l d0-d7/a1-a6,-(sp) * save regs 
  bsr m_load_u  * load it in 
  bsr IncrementClock * corrupts d0, but who cares
 movem.l (sp)+,d0-d7/a1-a6 * get regs 
 bra GetCell1  * get pointer 

GetCellx: 
 ifne SafeMode
  btst #0,d1
  beq.s gcok
 endc

GetCellBad: 
 ifne SafeMode
  move.l null_maskPtr-S(A5),d1 * actually a cell address,
* but it shouldn't happen - only to avoid system crashing.
 endc
gcok: 
 move.l d1,reqd_cell-S(A5) * set pointer 
* update time-stamp
 move.b (a0),d0
 and.b #$80,d0 * preserve protection flag
 or.w sys_clock-S(A5),d0 * guaranteed not to have top bit set
 move.b d0,(a0)

 move.l (sp)+,d0 
 movea.l (sp)+,a0 
 rts 

;---- 
;GetCellNoVM 
;* for cell with cell number d2.w (not object number, please note)
;* return (a0) as the pointer to the cell data 
;  clr.l d1 
;  move.w d2,d1 * cell number
;  cmp.w #16000,d1 * in case we're asked for a stupid value 
;  bcs.s gcNoVMOk 
;  move.w #0,d1 
; 
;gcNoVMOk: 
;;>>MIke 30/5/89  move.l SpriteDataPtr(PC),a3 * -S(a5),a3 
;  move.l SpriteDataPtr,a3 * -S(a5),a3 
;  mulu #LinesPerSprite*8,d1 
;  add.l a3,d1 
;
; ifne Amiga
;  move.l d2,-(sp)
;   move.l EndSpriteDataPtr,d2
;   cmp.l d2,d1
;   bcs.s AmigaWithinCellTable
;   move.l SpriteDataPtr,d1 * mustn't read off end of sprites memory
;   add.l #20*128,d1 * step on a few cells to something (probably) visible
;AmigaWithinCellTable
;  move.l (sp)+,d2
; endc
;
;;  move.l d1,2(a0,d0.l) 
; move.l d1,(a0)
;  bra GetCellx 
;---- 
; initialise 3d structure and lists
 
MCEmptyRoom: 
 movem.l a3-a6,-(sp) 
 bsr EmptyRoom 
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l 0
 rts 
 
*-------------------------- 
ClearMasks 
*>>MIke 11/6/89... 
* set up free-space LL for transparencies... 
 movea.l masks_start-S(A5),a1 * mask area start 
 move.l a1,a0 
 add.l #32,a1 * next mask pointer 
 move.l masks_end-S(A5),a2 * start of next area 
* skip over mask 0, because this is used as "null mask" 
* value (this wastes 32 bytes, but who cares) 
 add.l #32,a0 
 add.l #32,a1 
 move.l a0,nx_f_mask-S(A5) 
 move.w #0,d7 * count number of free transparencies 
InitLL: 
 move.l a1,(a0) 
 add.l #32,a0 
 add.l #32,a1 
 addq.w #1,d7 * number of free transparencies 
 cmp.l a2,a1 * has "next" ptr reached start of next area? 
 bcs.s InitLL 
 move.l #0,(a0) * zero terminates transparency LL 
 move.w d7,FreeTransparencies-S(A5)
 rts 
 
*---- 
EmptyRoom: 
* g_map contains 4 word entries for each cell on the 
* screen, laid out in a raster format. Each entry 
* is a link list 
 movea.l g_mapPtr-S(A5),a1  * ground cell map 
;; movea.l v_mapPtr,a2  * view map 
; move.w #ConstScreenXCells*ConstScreenYCells-1,d0  * no. map cells 
 move.w MapCellsMinus1-S(A5),d0
EmptyRoom1: 
 clr.l (a1)+  * clear ground cell 
;; clr.w (a2)+  * clear view cell 
 dbra d0,EmptyRoom1 

*>>MIKE2/7/89 - clear all links as well
* 10 bytes per link now, not 8 as it used to be.
 move.w num_links-S(A5),d1
 mulu #10/2,d1  * words in link space
 subq.w #2,d1 * one for dbra, one for luck
 move.l a1,-(sp)
EmptyRoom1b
  clr.w (a1)+
  dbra d1,EmptyRoom1b
 move.l (sp)+,a1 * restore start of links area.
 
 
*  set up empty link list 
 
 movea.l a1,a0  * a0 = link list start 
 move.l a1,d0  * d0 = link offset 
 sub.l g_mapPtr-S(A5),d0 * d0 = 1st link offset 
 move.w num_links-S(A5),d7 * d7 = no. links in list 
 move.w d7,FreeLinks-S(A5)
 subq.w #1,d7 
 move.w d0,nx_f_link-S(A5) * set free link pointer 
EmptyRoom2: 
 add.w #10,d0  * d0 = pointer to next 
 move.w d0,(a0)+  * forward pointer 
 clr.l (a0)+  * clear rest of 
 clr.l (a0)+  * link 
 dbra d7,EmptyRoom2  * do all links 
 clr.w -10(a0)  * last link = null 

* take one link, and put in a very large z value, with
* a null cell and a null mask for use by non-aligned
* feature code.
 move.w nx_f_link-S(A5),d0
 move.l g_mapPtr-S(A5),a1
 move.w 0(a1,d0.l),nx_f_link-S(A5)
 move.w d0,DummyLink-S(A5)
 move.w #32000,ZCoordOffset(a1,d0.l)

 
 move.l cmem_mapPtr-S(A5),load_list-S(A5) * dummy load list area 
; move.l #rev_list,rev_ptr-S(A5) * reversal stuff 
 movea.l masks_start-S(A5),a1 * mask area start 
 clr.l (a1)+  * clear 1st mask 
 clr.l (a1)+  * to use for 
 clr.l (a1)+  * null mask to have 
 clr.l (a1)+  * an offset of 0 
 clr.l (a1)+ 
 clr.l (a1)+ 
 clr.l (a1)+ 
 clr.l (a1)+ 
;; move.l a1,nx_f_mask * free mask pointer 
 
 bsr ClearMasks 

* clear background screen, which contains the cumulative effect 
* of the 3d structure... 
 move.l BufferScreen1-S(A5),a0 
; move.w #(ConstScreenXCells*ConstScreenYCells*128/4)-1,d0 * 128 bytes per cell 
; move.w MapCellsTimes128Div4Minus1,d0
 move.l BSSize-S(A5),d0
 lsr.l #2,d0 * convert to longs
EmptyRoom1a 
 clr.l (a0)+ 
 dbra d0,EmptyRoom1a 

 ifne AmigaCellGrouping
  bsr ClearCellGroupTable
 endc
 
ResetPreload
 movea.l cmem_mapPtr-S(A5),a0 * clear memory map 
 move.w NumCells-S(A5),d0  * no. cells 
; move.w d0,CurrentShiftedCell * reset pointer to the
* current cell number we can use for shifted cells.
 lsr.w #3,d0 * one bit per cell. 
 subq.w #1,d0 
EmptyRoom3: 
 clr.b (a0)+ 
 dbra d0,EmptyRoom3  
 rts 
 
;------------
UnlinkA1
* unlink all the links starting at ground cell (a1.l)
 move.w (a1),d0  * d0 = first 'link' for the cell we're rebuilding.
 beq Feature2AllMasksUnlinkedSir * no 3d structure there. 
 movea.l g_mapPtr-S(A5),a2  * a2 = links base 
* So go through the links and zero all their masks, adding any
* masks back into the free mask linked list.
 movem.l d0/a3,-(sp)
 move.l a1,d3
 sub.l g_mapPtr-S(A5),d3
Feature2MaskLoop:
* d0.w is the link to inspect. 0(a2,d3.l) is the
* last link (g_map entry if appropriate)
 move.w 2(a2,d0.l),d1 * any current mask ptr?
 beq.s Feature2NoMask
* link this mask into free space chain.
 ext.l d1
 move.l masks_start-S(A5),a3
 add.l d1,a3 * address of mask
 move.l nx_f_mask-S(A5),(a3)
 move.l a3,nx_f_mask-S(A5)
 addq.w #1,FreeTransparencies-S(A5)

Feature2NoMask
* zero mask pointer - becomes a mask pointer
 clr.w 2(a2,d0.l)  * null mask pointer 
* is this link used for a real cell - or was it generated
* just to hold a mask from a cell shifted in to this one?
 move.w LinkPtrOffset(a2,d0.l),d2
 move.w CellNumOffset(a2,d0.l),d1
 bne.s feature2Cell
* we can lose this link - it will be recreated in the
* remainder of feature routine if it's still needed.
 move.w LinkPtrOffset(a2,d0.l),LinkPtrOffset(a2,d3.l) * maintain
* chain for this cell.
 move.w nx_f_link,LinkPtrOffset(a2,d0.l)
 move.w d0,nx_f_link-S(A5)
 addq.w #1,FreeLinks-S(A5)
 move.w d3,d0 * keep same last link - i.e. not
* the link we've just added to the free space chain.

feature2Cell:
 move.w d0,d3 * keep "last link"
 move.w d2,d0 * move.w 0(a2,d0.l),d0
 bne.s Feature2MaskLoop
 movem.l (sp)+,d0/a3
;;;;;;;;;;;;;;;;;;;;;;;

Feature2AllMasksUnlinkedSir:
 rts
;------------ 
 
 
Last_cell: dc.l 0 
 
;;ClipMask dc.w 0 
