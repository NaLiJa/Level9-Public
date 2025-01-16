;NAFeatur.s

 move.l a1,d0
 sub.l g_mapPtr,d0 * get offset within links
 move.l g_mapPtr,a2
* any overlap from cell to the left?
 move.w d0,d1
 sub.w #4,d1
 bsr FindNextShiftedD1
 move.l d1,d4
* any overlap from cell above, left?
 move.w d0,d1
 sub.w MapXCellsTimes4,d1
 sub.w #4,d1
 bsr FindNextShiftedD1
 move.l d1,d5
* any overlap from cell above?
 move.w d0,d1
 sub.w MapXCellsTimes4,d1
 bsr FindNextShiftedD1
 move.l d1,d6

; cmp.l g_mapPtr,a1 **** trial bug fix.
; bcs.s AbortLink
 bsr UnlinkA1

 move.l a1,d0
 sub.l g_mapPtr,d0 * get d0.l as relative mask ptr
 move.w (a2,d0.l),d0
 bne.s GotBaseLink
AbortLink
 move.w DummyLink,d0 * needed for comparisons etc. below

GotBaseLink:
* Work up thru linked list, making up the
* cumulative cell as we go.
* We don't really need to get the order right for this
* part of the process (I'm thinking about the cells shifted in
* from left/above, here), but for the mask generation which comes
* later, we'll need to have a sorted list. And that's fairly
* easy to do here, at the same time.
* The only problem is to find a VERY fast way to sort four
* numbers without really doing a sort (because I don't want
* to use any more registers). And where not all of the pointers
* are necessarily real!
 lea LinkSortTable,a6
Feature2: * local loop from bra below 
* which of our 4 cells comes next?
* current = (a2,d0), left=(a2,d4), topleft=(a2,d5), topright=(a2,d6)
* We also keep a record of how far the cell has to be shifted - 
* imagining for consistency that it starts from the current
* position: i.e.  4 cells     D5 - D6
*			      |    |
*			      D4 - D0
* Starting from D0.
* This if cell D5 is chosen, it will have a basic shift
* of -16, plus any offset it has within cell D5.
* If cell D0 is chosen, it has a minimum shift of 0,
* plus any offset it has within cell D0.
* This maps relaively nicely onto the actual shifts we do
* when we build the composite cells/masks.
 move.w d4,d1 * result of first comparison
 move.w XShiftOffset(a2,d4),XShift1 * bottom left square xshift,yshift
 sub.b #16,XShift1
 move.w zcoordOffset(a2,d4),d3
 cmp.w zcoordOffset(a2,d0),d3
 blt.s GotComparisond1 * signed <
 move.w d0,d1
 move.w XShiftOffset(a2,d0),XShift1 * "current" square xshift+yshift

GotComparisonD1
* D1.w as lesser of two z's
 move.w d6,d2 * result of second comparison TOP RIGHT square
 move.w XShiftOffset(a2,d6),XShift2 * xshift, yshift
 sub.b #16,YShift2
 move.w ZCoordOffset(a2,d6),d3
 cmp.w zcoordOffset(a2,d5),d3
 blt.s GotComparisond2 * signed <
 move.w d5,d2
 move.w XShiftOffset(a2,d5),XShift2 * TOP LEFT square xshift,yshift
 sub.b #16,XShift2
 Sub.b #16,YShift2
GotComparisonD2
* now compare these two to find the lesser
* result is implied to be d1.w
 move.w ZCoordOffset(a2,d1),d3
 cmp.w zcoordOffset(a2,d2),d3
 blt.s GotComparison3 * signed <
 move.w d2,d1
 move.w XShift2,XShift1 * does bot xshift and yshift at once.

GotComparison3:
* Next link upwards in chain is 0(a2,d1)
* This requires a shift of XShift1.w,YShift1.w
* to get the cell/mask into the right position within
* the "current" square.
 cmp.b #$f0,XShift1
 beq.s GotLinkNoGood * shifted off so it won't be plotted
 cmp.b #$f0,YShift1
 beq.s GotLinkNoGood * shifted off so it won't be plotted
 move.w d1,(a6)+
 move.w XShift1,(a6)+ * Writes xshift1.b, yshift1.b
GotLinkNoGood
* Find out which cell this was, and step on its pointer
 move.l d1,d2 * keep a record
GComp0
 cmp.w DummyLink,d1
 beq MakeMasksRet * first links must all have been dummys!
 cmp.w d0,d2 * current link?
 bne.s GComp1
 move.w 0(a2,d2.l),d0
 bne.s GComp1
 move.w DummyLink,d0

GComp1
 cmp.w d4,d2 * lh link?
 bne.s GComp2
 bsr FindNextShiftedD1
 move.l d1,d4
GComp2
 cmp.w d5,d2 * top left link?
 bne.s GComp3
 bsr FindNextShiftedD1
 move.l d1,d5
GComp3
 cmp.w d6,d2 * top right link?
 bne.s GComp4
 bsr FindNextShiftedD1
 move.l d1,d6
GComp4
* Have we finished - i.e. are all links at dummylink?
 move.w DummyLink,d1
 cmp.w d0,d1
 bne Feature2 * not yet finished
 cmp.w d4,d1
 bne Feature2 * not yet finished
 cmp.w d5,d1
 bne Feature2 * not yet finished
 cmp.w d6,d1
 bne Feature2 * not yet finished
* We've finished - and have generated a sorted
* table of links, with their shifts, between
* LinkSortTable and a6.l

* NOW HEAR THIS!
* Let's now produce the composite cells.
* We could have done this in amongst the loop above,
* but it's PDC (Pretty damn complex) already.
* So let's make all our lives easier, and do it separately.
;; move.l a6,LinkSortTableEnd
* Each entry in linksorttable gives link.w, xshift.b, yshift.b
* Where the shift values can be signed, in the range -16..16
* a2.l is g_mapPtr
 lea LinkSortTable,a5
MakeCompositeLoop:
 clr.l d0
 move.w (a5)+,d0
 cmp.l a6,a5
 bcc.s MakeCompositeEnd
 move.w CellNumOffset(a2,d0.l),reqd_cell * char number for this link.
 beq.s MakeCompositeNoCell

 movem.l d0-d7/a0-a6,-(sp) ******11/12/89
 bsr GetAndReverseCell
 movem.l (sp)+,d0-d7/a0-a6 *****
* in (reqd_cell)=ReversedCellBufferPtr
 move.l a0,-(sp)
  bsr NewCell  * make new char at (a0) from reqd_cell
 move.l (sp)+,a0
MakeCompositeNoCell:
 addq.l #2,a5 * skip over shift values for the present.
 bra.s MakeCompositeLoop

MakeCompositeEnd
* Now work down the list of links, from -6(a6.l) down to
* LinkSortTable and produce the composite masks we need.
* WOW!
 move.l a6,a5 * work pointer
 clr.w d6 * d6 is used throughout MakeMasks to represent
* the last link processed. We start at the end, and
* work backwards, linking them all together.
 lea InitialMask,a4
MakeMasks:
 sub.l #4,a5 * go to previous link request
 cmp.l #LinkSortTable,a5
 bcs MakeMasksEnd
 move.w (a5),d0 * link offset
 move.w CellNumOffset(a2,d0.l),reqd_cell
 beq.s MakeMasks * null cell - don't bother doing anything
 movem.l d0-d7/a0-a6,-(sp) ********** 11/12/89
 bsr GetAndReverseCell
 movem.l (sp)+,d0-d7/a0-a6

 addq.l #2,a5 * make a5.l point to x,y shifts
 move.l a5,-(sp)
 movem.l d0-d7/a0-a6,-(sp) ********
  bsr CreMask * Make mask from reqd_cell and previous mask: a4.l
 movem.l (sp)+,d0-d7/a0-a6 *******
 move.l (sp)+,a5
 subq.l #2,a5
* in current mask: nx_f_mask -> WSMaskPtr on exit
* returns d5.w as all parts of mask or'd together.
 tst.w d5
 beq.s AllOpaque
* put this mask into the link, if it was a link
* from this square. If it wasn't, we'll need to create a new
* link specially for it.
 move.l WSMaskPtr,a0
 move.l a0,a4 * keep record of "last" mask
 sub.l masks_start,a0 * get offset of mask
 move.l a0,d1
* (a2,d0.l) is link, d1.w is mask offset
 tst.b 2(a5) * xshift.
 bmi.s NeedNewLink
 tst.b 3(a5) * yshift.
 bmi.s NeedNewLink
* this link was from the square we're processing,
* so worry not.
 move.w d6,LinkPtrOffset(a2,d0.l) * link into link above us.
 move.w d1,MaskPtrOffset(a2,d0.l)
 move.l d0,d6 * set 'last link' to be this one.
 bra.s MakeMasks

NeedNewLink:
 clr.l d2
 move.w nx_f_link,d2
 beq NoFreeLinks
 move.w LinkPtrOffset(a2,d2.l),nx_f_link
 subq.w #1,FreeLinks
* d2.w is the link we're going to create.
 move.w d6,LinkPtrOffset(a2,d2.l) * link into link above us.
 move.w d1,MaskPtrOffset(a2,d2.l)
 clr.w CellNumOffset(a2,d2.l)
 move.w ZCoordOffset(a2,d0.l),ZCoordOffset(a2,d2.l)
 clr.w XShiftOffset(a2,d2.l)
 move.l d2,d6 * set 'last link' ptr to be this one.
 bra MakeMasks

AllOpaque
* We generated a completely opaque mask. This
* is represented by a 0 mask, for speed whilst plotting.
 move.l WSMaskPtr,a1
 move.l nx_f_mask,(a1)
 move.l a1,nx_f_mask
 addq.l #1,FreeTransparencies
* With "back pointer" system, we would have had to
* go back and zero masks higher than this one in the chain.
* But this is unnecessary here, because they're 0 anyway.
* It does occur to me that we should maybe release these links,
* to speed up the scanning slightly. ?????????? Later attention?
MakeMasksEnd:
 move.w d6,(a1) * write end of our new chain into g_map
MakeMasksRet:
 rts

FindNextShiftedD1:
* Find the next shifted cell along the chain (a2,d1.l)
* and return its offset in d1.l
* If end of chain found, return d1.l=DummyOffset
 and.l #$0000ffff,d1
 tst.w d1
 bmi.s FNSDummy * simple clipping
 cmp.w DummyLink,d1
 beq FNSDummy

FindNextShiftedD1b:
 tst.w (a2,d1.l) ********** TOTALLY UNNECESSARY!
 bmi.s FNSDummy ****

 move.w (a2,d1.l),d1
 beq.s FNSDummy
 tst.w XShiftOffset(a2,d1.l) * tests x shift, yshift at once.
 beq.s FindNextShiftedD1b
 rts

FNSDummy
 move.w DummyLink,d1
 rts

