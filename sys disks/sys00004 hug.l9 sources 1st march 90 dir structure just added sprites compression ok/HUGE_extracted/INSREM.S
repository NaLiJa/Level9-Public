; INSREM.S


***************************************** 
* insert a single cell into structure.  * 
***************************************** 
 
*>>Mike 12/6/89 
InsRebuildD0 
 bsr InsCellD0 
 bsr insRebuild2
 rts

InsNARebuildD0
 bsr InsCellNAD0
Rebuild4Squares
 move.w xcord,-(sp)
 move.w zcord,-(sp)
 move.w hcord,-(sp)
 move.w ycell,-(sp)
  bsr insRebuild2 * do basic cell
  add.w #16,xcord
  bsr InsRebuild2XY
  sub.w #16,hcord
  bsr InsRebuild2XY
  sub.w #16,xcord
  bsr InsRebuild2XY
 move.w (sp)+,ycell
 move.w (sp)+,hcord
 move.w (sp)+,zcord
 move.w (sp)+,xcord
 rts
;---
InsRebuild2XY
 move.w ZCord,d1
 sub.w HCord,d1
 asr.w #4,d1 * divide by 16
 move.w d1,ycell
;
InsRebuild2
 move.w yCell,d1 
 move.w xcord,d2 * pixel x coord 
 asr.w #4,d2 * get it in cells 
 ext.l d2 
* d1.w=ycell, d2.l=xcell 
 clr.l d0 
 move.w mapXCellsTimes4,d0 
 muls d1,d0 
 movea.l g_mapPtr,a1  * a1 = ground cell map 
 add.l d0,a1 
 add.l d2,a1 * add on 4 times x coord 
 add.l d2,a1 
 add.l d2,a1 
 add.l d2,a1 
 
* d1.w=ycell, d2.l=xcell 
 muls #(ConstBytesPerBSLine*16),d1  * 160 if BS in ST Format
 ifne ST
  asl.l #3,d2 * multiply xcell by 8: bytes per cell 
 endc
 ifne Amiga
  asl.l #1,d2 * multuply xcell by 2: bytes per cell
 endc
 movea.l BufferScreen1,a0 * a0 = view map 
 add.l d1,a0 * add on y offset 
 add.l d2,a0 * add on x offset 
 
 move.w 2(a1),d0  * char no. 
 beq InsRebuildBlank  * blank 
 move.l a0,-(sp)
  bsr feature * build up structure for this square 
 move.l (sp)+,a0
 bsr CopyFeatureToLogicalScreen
InsRebuildBlank 
 rts 
;--- 
CopyFeatureToLogicalScreen:
* copy a cell from bufferscreen address a0.l
* to the corresponding address on the logical screen.
 ifne sT
 move.l a0,a3
 sub.l BufferScreen1,a3
 add.l LogicalBase,a3
 move.l (a0),(a3) * line 0 
 move.l 4(a0),4(a3) 
 move.l ConstBytesPerBSLine(a0),160(a3) * line 1 
 move.l ConstBytesPerBSLine+4(a0),164(a3) 
 move.l ConstBytesPerBSLine*2(a0),320(a3) * line 2 
 move.l ConstBytesPerBSLine*2+4(a0),324(a3) 
 move.l ConstBytesPerBSLine*3(a0),480(a3) * line 3 
 move.l ConstBytesPerBSLine*3+4(a0),484(a3) 
 move.l ConstBytesPerBSLine*4(a0),640(a3) * line 4 
 move.l ConstBytesPerBSLine*4+4(a0),644(a3) 
 move.l ConstBytesPerBSLine*5(a0),800(a3) * line 5 
 move.l ConstBytesPerBSLine*5+4(a0),804(a3) 
 move.l ConstBytesPerBSLine*6(a0),960(a3) * line 6 
 move.l ConstBytesPerBSLine*6+4(a0),964(a3) 
 move.l ConstBytesPerBSLine*7(a0),1120(a3) * line 7 
 move.l ConstBytesPerBSLine*7+4(a0),1124(a3) 
 move.l ConstBytesPerBSLine*8(a0),1280(a3) * line 8 
 move.l ConstBytesPerBSLine*8+4(a0),1284(a3) 
 move.l ConstBytesPerBSLine*9(a0),1440(a3) * line 9 
 move.l ConstBytesPerBSLine*9+4(a0),1444(a3) 
 move.l ConstBytesPerBSLine*10(a0),1600(a3) * line 10 
 move.l ConstBytesPerBSLine*10+4(a0),1604(a3) 
 move.l ConstBytesPerBSLine*11(a0),1760(a3) * line 11 
 move.l ConstBytesPerBSLine*11+4(a0),1764(a3) 
 move.l ConstBytesPerBSLine*12(a0),1920(a3) * line 12 
 move.l ConstBytesPerBSLine*12+4(a0),1924(a3) 
 move.l ConstBytesPerBSLine*13(a0),2080(a3) * line 13 
 move.l ConstBytesPerBSLine*13+4(a0),2084(a3) 
 move.l ConstBytesPerBSLine*14(a0),2240(a3) * line 14 
 move.l ConstBytesPerBSLine*14+4(a0),2244(a3) 
 move.l ConstBytesPerBSLine*15(a0),2400(a3) * line 15 
 move.l ConstBytesPerBSLine*15+4(a0),2404(a3) 
 endc * ST

 ifne Amiga
 move.l a0,a3
 sub.l BufferScreen1,a3
* a3.l is now offset into bps
 move.l a3,d0
 move.l LogicalBP0,a1
 add.l d0,a1
 move.l LogicalBP1,a2
 add.l d0,a2
 move.l LogicalBP2,a3
 add.l d0,a3
 move.l LogicalBP3,a4
 add.l d0,a4

 move.l BSPlaneSpacing,d1
 move.l d1,d2
 add.l d2,d2
 move.l d1,d3
 add.l d2,d3


* Line 0...
 move.w (a0),(a1)
 move.w (a0,d1.l),(a2)
 move.w (a0,d2.l),(a3)
 move.w (a0,d3.l),(a4)
* Line 1...
 add.l #BytesPerPixelLine,a0
 move.w 0*BytesPerPixelLine(a0),BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),BytesPerPixelLine(a4)

* Line 2...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),2*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),2*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),2*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),2*BytesPerPixelLine(a4)

* Line 3...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),3*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),3*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),3*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),3*BytesPerPixelLine(a4)

 add.l #BytesPerPixelLine*1,a0

* Line 4...
 move.w (a0),4*BytesPerPixelLine(a1)
 move.w (a0,d1.l),4*BytesPerPixelLine(a2)
 move.w (a0,d2.l),4*BytesPerPixelLine(a3)
 move.w (a0,d3.l),4*BytesPerPixelLine(a4)

* Line 5...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),5*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),5*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),5*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),5*BytesPerPixelLine(a4)

* Line 6...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),6*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),6*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),6*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),6*BytesPerPixelLine(a4)

* Line 7...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),7*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),7*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),7*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),7*BytesPerPixelLine(a4)

* Line 8...
 add.l #BytesPerPixelLine*1,a0
 move.w (a0),8*BytesPerPixelLine(a1)
 move.w (a0,d1.l),8*BytesPerPixelLine(a2)
 move.w (a0,d2.l),8*BytesPerPixelLine(a3)
 move.w (a0,d3.l),8*BytesPerPixelLine(a4)

* line 9
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),9*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),9*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),9*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),9*BytesPerPixelLine(a4)

* Line 10...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),10*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),10*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),10*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),10*BytesPerPixelLine(a4)

* Line 11...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),11*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),11*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),11*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),11*BytesPerPixelLine(a4)

 add.l #BytesPerPixelLine*1,a0
* Line 12...
 move.w (a0),12*BytesPerPixelLine(a1)
 move.w (a0,d1.l),12*BytesPerPixelLine(a2)
 move.w (a0,d2.l),12*BytesPerPixelLine(a3)
 move.w (a0,d3.l),12*BytesPerPixelLine(a4)

* Line 13...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),13*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),13*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),13*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),13*BytesPerPixelLine(a4)

 add.l #BytesPerPixelLine*1,a0
* Line 14...
 move.w 0*BytesPerPixelLine(a0),14*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),14*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),14*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),14*BytesPerPixelLine(a4)
* Line 15...
 add.l #BytesPerPixelLine*1,a0
 move.w 0*BytesPerPixelLine(a0),15*BytesPerPixelLine(a1)
 move.w 0*BytesPerPixelLine(a0,d1.l),15*BytesPerPixelLine(a2)
 move.w 0*BytesPerPixelLine(a0,d2.l),15*BytesPerPixelLine(a3)
 move.w 0*BytesPerPixelLine(a0,d3.l),15*BytesPerPixelLine(a4)

 endc * Amiga 

 rts
;---
HandleReflection
 tst.w d0 * is cell reversed?
 bpl.s HRNR1
; cell asked to be reversed. Canceled if rev_flag asks for reversal
 tst.w rev_flag
 bmi.s HRNotReversed * non-reversed
 bra.s HRReversed * reversed

HRNR1 * local label
 tst.w rev_flag  * reverse cell ? 
 bpl HRNotReversed  * no 
HRReversed:
 or.w #$8000,d0
 rts

HRNotReversed
 and.w #$7fff,d0
 rts
;------
*>>Mike 31/5/89... 
InsCellNAD0:
 bsr InsCellD0
* (A1,D0.l) is gmap cell, (a1,d7.l) is link
 tst.w d7
 beq.s insCellNaD0Ret * can only shift things above g_map.
 move.w xcord,d0
 and.w #15,d0
 move.b d0,XShiftOffset(a1,d7.l)
 move.w zcord,d0
 sub.w hcord,d0
 and.w #15,d0
 move.b d0,YShiftOffset(a1,d7.l)
insCellNaD0Ret
 rts
;---
InsCellD0: 
* d0.w is a cell with reversal flag set if appropriate. 
* the object it was called with may have been reversed as well. 
* (which will invert the effect of the reversal flag)
 bsr HandleReflection
 bra.s InsCell_a
 
InsCell: 
* d0 = cell no. to insert 
 move.w zcord,d2 
 sub.w hcord,d2 
 asr.w #4,d2 
 move.w d2,yCell * yCell=y pos in cells 
  tst.w rev_flag  * reverse cell ? 
 bpl InsCellNotReversed * InsCell_a  * no 

InsCellReversed: 
 or.w #$8000,d0 * ensure reversal flag is set
 bra.s InsCell_a

InsCellNotReversed:
 and.w #$7fff,d0

InsCell_a: 
* d0.w is cell number to insert
* All requests to insert cells come here.
* returns (a1,d7.l) as link
 move.w  xcord,d1
 and.w #$fff0,d1
 move.w zcord,d2 
 cmp.w MapXPixels,d1 *Mike9/10/89 #319,d1 ; check for off-screen 
 bcc InsCellRet *Mike9/10/89 bhi InsCellRet 
 
 move.w yCell,d7 
 bmi InsCellRet 
; cmpi.w #11,d7 
; bhi InsCellRet 
 cmp.w MapYCells,d7
 bcc InsCellRet
 
 asr.w #2,d1 
 move.w mapXCellsTimes4,d6 
 muls d6,d7 
 ext.l d1 
 add.l d1,d7  * d7 = g_map cell offset 
 movea.l g_mapPtr,a1  * a1 = g_map start 

* (a1,d7.l) is g_map square for this cell.
 movem.l d7/a1,-(sp)
  bsr InsCellOnce * normal, cell-aligned insert
 movem.l (sp)+,d0/a1 * return (a1,d0.l) as g_map cell
* and (a1,d7.l) as link
 rts
;---------------
InsCellOnce:
* d0.w is cell object num. to insert, d2.w is z coord to insert it at.
* (a1,d7.l) is g_map cell where it will go.
* Return (a1,d7.l) as the link we've added
 tst.w 2(a1,d7.l)  * is g_map cell empty ? 
 bne InsCell1  * no 
 move.w d0,2(a1,d7.l) * else new cell no. 
 clr.l d7 * not inserted in a link
 bra InsCellRet  * done 

InsCell1: 
 move.l d7,d1  * d1 = reqd offset 
 move.w LinkPtrOffset(a1,d1.l),d7 * another link ? 
 beq InsCell2  * no - insert here 
 
 cmp.w ZCoordOffset(a1,d7.l),d2 * new z > current z ? 
 bgt InsCell1  * yes - try next link 
 
InsCell2: 
* use a new link
 subq.w #1,FreeLinks
 move.w nx_f_link,d7 * d7 = free link offset 
 beq NoFreeLinks
 move.w LinkPtrOffset(a1,d7.l),nx_f_link * new free link offset 
 bne.s ICNoDebug *******
 dc.w $4afa 
ICNoDebug *******
 
 move.w LinkPtrOffset(a1,d1.l),LinkPtrOffset(a1,d7.l) * new link = next link 
 clr.w MaskPtrOffset(a1,d7.l) * clear mask pointer for new link.
 move.w d0,CellNumOffset(a1,d7.l) * put char into new link 
 move.w d2,ZCoordOffset(a1,d7.l) * put z cord into link 
 move.w d7,LinkPtrOffset(a1,d1.l) * current link = new link 

; and.w #$7fff,d0 *&&&&&&&&&&&&&&&&&&&&&&&&&&&&
; cmp.w #$3000,d0
; bcs.s insCellRet
; dc.w $4afa
; move.w #10,CellNumOffset(a1,d7.l)

InsCellRet: 
 rts   * done 
 
NoFreeLinks
 move.w #$102,d0
 bsr ErrorHandler
 rts

;-------------

;-------------

***************************************** 
* remove a single cell from structure.  * 
***************************************** 
 
* d0 = non-reversed cell no. to remove 
;--- 
RemNARebuildD0
 bsr RemCell_a
 bra Rebuild4Squares * rts
;---
RemCell: 
 move.w zcord,d2 
 sub.w hcord,d2 
 asr.w #4,d2 
 move.w d2,yCell 
 
RemCell_a: 
 bsr RemCellD0 * MikeRemCell * InsCellD0 
RemCell_a1:
 move.w yCell,d1 
 move.w xcord,d2 * pixel x coord 
 asr.w #4,d2 * get it in cells 
 ext.l d2 
* d1.w=ycell, d2.l=xcell 
 clr.l d0 
 move.w MapXCellsTimes4,d0 
 muls d1,d0 
 movea.l g_mapPtr,a1  * a1 = ground cell map 
 add.l d0,a1 
 add.l d2,a1 * add on 4 times x coord 
 add.l d2,a1 
 add.l d2,a1 
 add.l d2,a1 
 
* d1.w=ycell, d2.l=xcell 
 muls #(ConstBytesPerBSLine*16),d1 * 160 if BS in ST format 
 ifne ST
  asl.l #3,d2 * multiply xcell by 8: bytes per cell 
 endc
 ifne Amiga
  asl.l #1,d2 * multiply xcell by 2: bytes per cell 
 endc

 movea.l BufferScreen1,a0 * a0 = view map 
 add.l d1,a0 * add on y offset 
 add.l d2,a0 * add on x offset 
 
 move.w 2(a1),d0  * char no. 
 beq RemoveRebuildBlank  * blank 
 move.l a0,-(sp)
  bsr feature * build up structure for this square 
 move.l (sp)+,a0
 bsr CopyFeatureToLogicalScreen
RemoveRebuildBlank 
 rts 
;--- 
RemCellD0:
 tst.w d0 * is cell reversed?
 bpl.s remNonReversed
; cell asked to be reversed. Canceled if rev_flag asks for reversal
 tst.w rev_flag
 bmi.s RemCellNotReversed * non-reversed
 bra.s RemCellReversed * reversed

remNonReversed * local label
 tst.w rev_flag  * reverse cell ? 
 bpl RemCellNotReversed  * no 
RemCellReversed
 or.w #$8000,d0
 bra.s MikeRemCell

RemCellNotReversed
 and.w #$7fff,d0

MikeRemCell: 
 move.w zcord,d2 
 and.w #$fff0,d2 *>>mike 20/1/89 
 move.w xcord,d1 
 and.w #$fff0,d1 *>>mike 20/1/89 
 bmi RemCell4 
 cmpi.w #319,d1 
 bgt RemCell4 
 
 asr.w #2,d1 *>>Mike 20/2/89 lsl.w #2,d1 
 bmi RemCell4 
 move.w ycell,d7
 cmpi.w #11,d7 
 bhi RemCell4 
 
 muls MapXCellsTimes4-S(A5),d7 
 add.w d1,d7  * d7 = g_map cell offset 
 movea.l g_mapPtr,a1  * a1 = g_map start
 bra RemCell2 
RemCell1: 
 move.w 4(a1,d7.w),d1 * compare, ignoring reflection.
 eor.w d0,d1
 and.w #$7fff,d1
; cmp.w 4(a1,d7.w),d0 * reqd link ? 
 beq RemCell3  * yes 
RemCell2: 
 move.w d7,d2  * save previous link 
 move.w 0(a1,d7.w),d7 * next link 
 bne RemCell1  * loop if not end of chain 
 
 bra RemCell4  * error - char not found!! 
 
RemCell3: 
* got the cell we want to remove at 0(a1,d7) 
 move.l a0,-(sp) 
 clr.l d1 
 move.w 2(a1,d7),d1 * pointer to mask used 
 beq.s RemCellNullMask * null mask, in fixed workspace, 
* so don't try to delete it! 
 move.l masks_start,a0 
 add.l d1,a0 * now (a0.l) is transparency mask used 
 move.l nx_f_mask,(a0) * link existing chain to this mask 
 move.l a0,nx_f_mask * this will be the next mask used. 
 addq.w #1,FreeTransparencies 
RemCellNullMask 
 move.l (sp)+,a0 
 
* delete link, add it back into free link chain
 addq.w #1,FreeLinks
 move.w nx_f_link,d1 * next free link 
 move.w d7,nx_f_link * 'remove' link 
 move.w 0(a1,d7.w),0(a1,d2.w) * pass over old link 
 move.w d1,0(a1,d7.w) * free link chain 
 clr.l 2(a1,d7.w) * remove mask, cell ptrs
RemCell4: 
 rts   * done 

