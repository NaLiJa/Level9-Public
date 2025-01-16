
drw_obj:
	move.w	x_pos,d0
	move.w	y_pos,d1

	andi.w	#$FFF0,d0
	andi.w	#$FFF0,d1
	lsr.w	#2,d0
	lsr.w	#2,d1
	mulu	#map_wdth,d1
	add.w	d1,d0		* d0 = gmap offset		

	move.w	y_pos,d1		* head z = y cord
	addi.w	#16,d1		* feet z cord
	bsr	get_mask		* find reqd mask
	move.l	d6,mask1		* save it

	addq.w	#4,d0		* 2nd cell
	bsr	get_mask
	move.l	d6,mask2

	addi.w	#map_wdth*4-4,d0	* 3rd cell
	bsr	get_mask
	move.l	d6,mask3

	addq.w	#4,d0		* 4th cell
	bsr	get_mask
	move.l	d6,mask4

*		calc top mask offsets and line counts
	move.w	y_pos,d0
	andi.w	#15,d0		* d0 = y shift
	move.w	d0,lo_cnt		* bottom line count
	moveq	#16,d1
	sub.w	d0,d1
	move.w	d1,hi_cnt		* top line count

	lsl.w	#1,d1		* p_mask offset
	move.l	d1,pm_off		* save it
	lsl.w	#2,d1		* p_data offset
	move.l	d1,pd_off		* save it
	ext.l	d0
	lsl.w	#1,d0		* d0 = top mask offset
	add.l	d0,mask1		* adjust top mask
	add.l	d0,mask2		* pointers

*		calc screen addrs of 4 quadrants
	move.w	y_pos,d0		* y cord
	mulu	#160,d0		* d0 = no. scrn lines
	move.w	x_pos,d1		* x cord
	andi.w	#$FFF0,d1
	lsr.w	#1,d1		* d1 = x offset
	add.w	d1,d0
	movea.l	scrn,a0		* a0 = scrn start
	adda.l	d0,a0		* a0 = top left sprite bit
	move.l	a0,scrn1		* 1st quadrant
	addq.l	#8,a0
	move.l	a0,scrn2		* 2nd quadrant
	move.w	hi_cnt,d0
	mulu	#160,d0
	adda.l	d0,a0
	move.l	a0,scrn4		* 4th quadrant
	subq.l	#8,a0
	move.l	a0,scrn3		* 3rd quadrant

*		draw sprite to screen
	move.w	x_pos,d1		* d1 = x cord
	andi.w	#15,d1		* d1 = x shift

	lea	p_data,a0		* a0 = sprite data
	movea.l	mask1,a1		* a1 = 1st quad. mask
	movea.l	scrn1,a2		* a2 = 1st quad. screen
	lea	p_mask,a3		* a3 = sprite mask
	move.w	hi_cnt,d0		* d0 = line count
	bsr	drw_left		* draw top left

	tst.w	d1		* is there a right bit ?
	beq	drw_obj1		* no
	lea	p_data,a0
	movea.l	mask2,a1
	movea.l	scrn2,a2
	lea	p_mask,a3
	move.w	hi_cnt,d0
	bsr	drw_rght		* draw top right
drw_obj1:
	tst.w	lo_cnt		* is there a bottom bit ?
	beq	drw_objx		* no
	lea	p_data,a0
	adda.l	pd_off,a0		* spr data offset
	movea.l	mask3,a1
	movea.l	scrn3,a2
	lea	p_mask,a3
	adda.l	pm_off,a3
	move.w	lo_cnt,d0
	bsr	drw_left		* draw bottom left

	tst.w	d1
	beq	drw_objx
	lea	p_data,a0
	adda.l	pd_off,a0
	movea.l	mask4,a1
	movea.l	scrn4,a2
	lea	p_mask,a3
	adda.l	pm_off,a3
	move.w	lo_cnt,d0
	bsr	drw_rght		* draw bottom right
drw_objx:
	rts			* exit




* draw right bit of sprite

drw_rght:
	subq.w	#1,d0
drw_rght1:
	moveq	#-1,d2		* mask = all 1's
	move.w	(a3)+,d2		* d2 = sprite mask word
	swap	d2
	lsr.l	d1,d2		* d2 = right side of sprite
	move.w	(a1)+,d3		* d3 = backgrnd mask word
	eori.w	#$FFFF,d3		* invert it
	or.w	d2,d3		* d3 = new bg mask
	move.w	d3,d2
	eori.w	#$FFFF,d2		* d2 = new spr mask

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data word
	swap	d4
	clr.w	d4
	lsr.l	d1,d4		* d4 = shifted spr word
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data word
	swap	d4
	clr.w	d4
	lsr.l	d1,d4		* d4 = shifted spr word
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data word
	swap	d4
	clr.w	d4
	lsr.l	d1,d4		* d4 = shifted spr word
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data word
	swap	d4
	clr.w	d4
	lsr.l	d1,d4		* d4 = shifted spr word
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	adda.l	#152,a2		* next scrn line
	dbra	d0,drw_rght1
	rts


* draw left bit of sprite

drw_left:
	subq.w	#1,d0
drw_left1:
	moveq	#-1,d2		* mask = all 1's
	move.w	(a3)+,d2		* spr mask word
	lsr.l	d1,d2		* only left bit
	move.w	(a1)+,d3		* bg mask word
	eori.w	#$FFFF,d3		* invert it
	or.w	d2,d3		* d3 = new bg mask
	move.w	d3,d2
	eori.w	#$FFFF,d2		* d2 = new spr mask

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data
	lsr.w	d1,d4		* shift it
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data
	lsr.w	d1,d4		* shift it
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data
	lsr.w	d1,d4		* shift it
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	and.w	d3,(a2)		* make hole in bg
	move.w	(a0)+,d4		* d4 = spr data
	lsr.w	d1,d4		* shift it
	and.w	d2,d4		* mask it
	or.w	d4,(a2)+		* put it onto screen

	adda.l	#152,a2		* next scrn line
	dbra	d0,drw_left1
	rts


* find reqd mask pointer

get_mask:
	clr.l	d7
	clr.l	d2
	move.w	d0,d2		* d2 = current link pntr
	lea	g_map,a0		* a0 = link base
	move.w	0(a0,d2.l),d3	* d3 = next link pntr
	bne	gt_msk1a		* 1st link exists
	bra	get_mask5
get_mask1:
	move.w	d3,d2		* d2 = new link pntr
	move.w	0(a0,d2.l),d3	* d3 = next link
	beq	get_mask3		* end of chain
gt_msk1a:
	cmp.w	6(a0,d3.l),d1	* plyr z >= link z ?
	bgt	get_mask1		* yes - next link
get_mask2:
	move.w	2(a0,d3.l),d7	* d7 = mask pntr
	bra	get_mask5
get_mask3:
	cmp.w	6(a0,d2.l),d1	* plyr z < last link ?
	ble	get_mask2		* yes - get mask pntr
get_mask5:
	move.l	#null_mask,d6
	tst.w	d7
	beq	get_mask6
	move.l	#masks,d6
	add.l	d7,d6
get_mask6:
	rts			* null mask pntr


