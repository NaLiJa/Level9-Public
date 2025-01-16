; 3D.S
;
; structure handler and 3D display code
;
; Lauren Roberts September 1988
;
; Copyright (C) 1988 Level 9 Computing
;
;
;--------
MCInit3D
 movem.l a3-a6,-(sp)
	bsr	initial		* set up screen
	bsr	make_masks		* create char masks
	bsr	clr_scrn		* clear screen

*********** 	set up empty ground cell map

	lea	g_map,a1		* g_cell map
	move.w	#map_cells-1,d0	* no. map cells
MCmake_pic1:
	clr.l	(a1)+		* clear g_cell
	dbra	d0,MCmake_pic1	* map


*********** 	set up empty link list

	movea.l	a1,a0		* a0 = link list start
	move.l	a1,d0		* d0 = link offset
	subi.l	#g_map,d0		* d0 = 1st link offset
	move.w	#num_links-1,d7	* d7 = no. links in list
	move.w	d0,nx_f_link	* set free link pointer
MCmake_pic2:
	addq.w	#8,d0		* d0 = pointer to next
	move.w	d0,(a0)+		* forward pointer
	clr.w	(a0)+		* clear rest of
	clr.l	(a0)+		* link
	dbra	d7,MCmake_pic2	* do all links
	clr.w	-8(a0)		* last link = null


*********** 	set up next free char etc

	move.w	#max_char+1,d0	* d0 = nxt free char no.
	move.w	d0,nx_f_cnum	* save it
	ext.l	d0
	lsl.l	#5,d0
	lea	masks,a0
	adda.l	d0,a0
	move.l	a0,nx_f_mask
	lsl.l	#2,d0
	movea.l	cell_pnt,a0
	adda.l	d0,a0
	move.l	a0,nx_f_char

 movem.l (sp)+,a3-a6
 rts
;------------------------
MCDrawObject
 movem.l a3-a6,-(sp)
  bsr AbsDrawObject
 movem.l (sp)+,a3-a6
 rts
;---
AbsDrawObject
 move.w 2(a4),d0 ; V1
 move.w	4(a4),xcord		* initial
 move.w	6(a4),zcord		* values
 move.w	8(a4),hcord
;;	move.w	obj_num,d0		* init obj num
	bsr	find_obj		* find it
	move.w	d2,list_len		* data list length
;;	pea	make_pic3		* ret addr
	ext.l	d1
	lsl.w	#2,d1
	lea	MCjmp_tab-4,a1
	move.l	0(a1,d1.l),-(sp)
	rts


*********** 	jump table to routines

MCjmp_tab:	dc.l	do_raster
	dc.l	do_comps
	dc.l	do_cell
	dc.l	do_cntrl0
	dc.l	do_animat
;-------------------
MCBuildViewMap
*********** 	create final view map
 movem.l a3-a6,-(sp)
	bsr	do_vmap		* set up view map
 movem.l (sp)+,a3-a6
 rts
;--------------------
MCDisplayViewMap
 movem.l a3-a6,-(sp)
	bsr	drw_vmap		* draw view map
 movem.l (sp)+,a3-a6
 rts
;------------------
MCDisplay3DSprite
 movem.l a3-a6,-(sp)
	bsr	drw_obj
 movem.l (sp)+,a3-a6
 rts
;------------------





;----------------------

make_pic0:
	clr.w	xcord		* save all
	move.b	d0,xcord		* initial
	clr.w	zcord		* passed
	move.b	d1,zcord		* values
	clr.w	hcord
	move.b	d2,hcord
	move.w	d3,obj_num

	bsr	initial		* set up screen
	bsr	make_masks		* create char masks
	bsr	clr_scrn		* clear screen



*********** 	set up empty ground cell map

	lea	g_map,a1		* g_cell map
	move.w	#map_cells-1,d0	* no. map cells
make_pic1:
	clr.l	(a1)+		* clear g_cell
	dbra	d0,make_pic1	* map


*********** 	set up empty link list

	movea.l	a1,a0		* a0 = link list start
	move.l	a1,d0		* d0 = link offset
	subi.l	#g_map,d0		* d0 = 1st link offset
	move.w	#num_links-1,d7	* d7 = no. links in list
	move.w	d0,nx_f_link	* set free link pointer
make_pic2:
	addq.w	#8,d0		* d0 = pointer to next
	move.w	d0,(a0)+		* forward pointer
	clr.w	(a0)+		* clear rest of
	clr.l	(a0)+		* link
	dbra	d7,make_pic2	* do all links
	clr.w	-8(a0)		* last link = null


*********** 	set up next free char etc

	move.w	#max_char+1,d0	* d0 = nxt free char no.
	move.w	d0,nx_f_cnum	* save it
	ext.l	d0
	lsl.l	#5,d0
	lea	masks,a0
	adda.l	d0,a0
	move.l	a0,nx_f_mask
	lsl.l	#2,d0
	movea.l	cell_pnt,a0
	adda.l	d0,a0
	move.l	a0,nx_f_char


*********** 	process passed data

	move.w	obj_num,d0		* init obj num
	bsr	find_obj		* find it
	move.w	d2,list_len		* data list length
	pea	make_pic3		* ret addr
	ext.l	d1
	lsl.w	#2,d1
	lea	jmp_tab-4,a1
	move.l	0(a1,d1.l),-(sp)
	rts


*********** 	jump table to routines

jmp_tab:	dc.l	do_raster
	dc.l	do_comps
	dc.l	do_cell
	dc.l	do_cntrl0
	dc.l	do_animat

do_comps:
	rts
do_animat:
	rts

*********** 	create final view map
***********		return point for all routines

make_pic3:
	bsr	do_vmap		* set up view map

make_pic5:
	bsr	drw_vmap		* draw view map
	bsr	drw_obj
make_pic6:
	bsr	wait_key		* get a key
	subi.b	#'0',d0
	bmi	make_pic6
	beq	make_picx
	cmpi.b	#4,d0
	bgt	make_pic6
	bsr	move_plyr
	bra	make_pic5


make_picx:
	move.w	scrn_res,-(sp)
	move.l	#-1,-(sp)
	move.l	#-1,-(sp)
	move.w	#5,-(sp)
	trap	#14
	adda.l	#12,sp		* set original res

	clr.w	-(sp)
	trap	#1



********************************
* process control list	       *
********************************


do_cntrl0:
	move.w	xcord,-(sp) 	* save xcord
	move.w	zcord,-(sp) 	* save zcord
	move.w	hcord,-(sp) 	* save hcord
	move.l	a0,-(sp)		* save list pointer

	clr.w	d0
	move.b	4(a0),d0		* d0 = xcord add
	add.w	d0,xcord		* new xcord
	move.b	5(a0),d0
	add.w	d0,zcord
	move.b	6(a0),d0
	add.w	d0,hcord
	move.b	8(a0),d0
	lsl.w	#8,d0
	move.b	9(a0),d0		* d0 = object no.

	bsr	find_obj
	cmpi.w	#4,d1		* object = control ?
	bne	do_cntrla		* no

	move.w	list_len,-(sp)	* save list length
	move.w	d2,list_len 	* new list length
	bsr	do_cntrl0		* recursive call
	move.w	(sp)+,list_len	* get list len

do_cntrl1:
	movea.l	(sp)+,a0		* get list pointer
	addq.l	#6,a0		* next data set
	move.w	(sp)+,hcord
	move.w	(sp)+,zcord
	move.w	(sp)+,xcord

	subq.w	#1,list_len 	* end of data ?
	bne	do_cntrl0		* no
	rts			* else return to ?


do_cntrla:
	cmpi.w	#1,d1		* raster block ?
	bne	do_cntrlb		* no

	bsr	do_raster		* process it
	bra	do_cntrl1		* loop
do_cntrlb:
	cmpi.w	#3,d1		* cell block ?
	bne	do_cntrl1		* no

	bsr	do_cell		* process it
	bra	do_cntrl1		* loop



********************************
* process a raster block       *
********************************


do_raster:
	move.w	zcord,d2
	sub.w	hcord,d2
	sub.w	d3,d2
	move.w	d2,ycord		* ycord = top left raster
	clr.w	d6
	move.b	2(a0),d6		* d6 = block x size - tiles
	move.w	d6,xsize		* save it
	subq.w	#1,d6		* d6 = tile width counter
	move.w	d6,xcnt		* save it
	addq.l	#4,a0		* a0 = data list start
do_rastr1:
	move.w	(a0)+,d0		* d0 = tile no.
	bmi	do_rastr2		* -ve = end
	beq	do_rastr3		* null cell
	bsr	do_cell_a		* process it
do_rastr3:
	addi.w	#1,xcord		* next tile along
	dbra	d6,do_rastr1	* do 1 row of block

	move.w	xcnt,d6		* reset count
	move.w	xsize,d0
	sub.w	d0,xcord		* reset xcord
	addi.w	#1,ycord		* next line down
	bra	do_rastr1		* loop
do_rastr2:
	rts





********************************
* deal with a single cell no.  *
********************************


do_cell:
	move.w	zcord,d2
	sub.w	hcord,d2
	subq.w	#1,d2
	move.w	d2,ycord

do_cell_a:
	move.w	zcord,d2
	mulu	#16,d2
	move.w	xcord,d1
	lsl.w	#2,d1
	move.w	ycord,d7
	mulu	#(map_wdth*4),d7
	add.w	d1,d7		* d7 = g_map cell offset
	lea	g_map,a1		* a1 = g_map start

	tst.w	2(a1,d7.l)		* is g_map cell empty ?
	bne	do_cell1		* no
	move.w	d0,2(a1,d7.l)	* else new cell no.
	bra	do_cell3		* done
do_cell1:
	move.l	d7,d1		* d1 = reqd offset
	move.w	0(a1,d1.l),d7	* another link ?
	beq	do_cell2		* no - insert here

	cmp.w	6(a1,d7.l),d2	* new z > current z ?
	bgt	do_cell1		* yes - try next link

do_cell2:
	move.w	nx_f_link,d7		* d7 = free link offset
	move.w	0(a1,d7.l),nx_f_link		* new free link offset

	move.w	0(a1,d1.l),0(a1,d7.l)		* new link = next link
	move.w	d0,4(a1,d7.l)		* put char into new link
	move.w	d2,6(a1,d7.l)		* put z cord into link
	move.w	d7,0(a1,d1.l)		* current link = new link
do_cell3:
	rts				* done


*********************************
* find an object                *
*********************************

find_obj:
	move.w	d0,-(sp)		* save obj no.

	clr.l	d7
	lea	rstr_pnt,a1		* 1st data pointer
	movea.l	(a1)+,a0		* a0 = rasters start
	cmp.w	(a1)+,d0		* obj = raster ?
	bgt	find_obj1		* no

*		object is a raster block
	moveq	#1,d1		* d1 = object id
	subq.w	#1,d0		* 1st obj ?
	beq	find_rst2		* yes
	subq.w	#1,d0
find_rst1:
	move.w	(a0),d7
	adda.l	d7,a0
	dbra	d0,find_rst1
find_rst2:
	move.w	(a0),d2
	subq.w	#4,d2
	lsr.w	#1,d2
	move.l	d2,-(sp)
	move.b	2(a0),d3
	ext.w	d3
	divu	d3,d2
	move.w	d2,d3
	move.l	(sp)+,d2
	bra	find_objx

find_obj1:
	movea.l	(a1)+,a0		* a0 = compresseds
	cmp.w	(a1)+,d0		* obj = comp ?
	bgt	find_obj2		* no

*		object is compressed type

	nop
	bra	find_objx

find_obj2:
	movea.l	(a1)+,a0		* a0 = controls
	cmp.w	(a1)+,d0		* obj = control ?
	bgt	find_obj3		* no

*		object is 'x,z,h,#' type
	moveq	#4,d1
	sub.w	-8(a1),d0
	subq.w	#1,d0
	beq	find_ctr2
	subq.w	#1,d0
find_ctr1:
	move.w	(a0),d7
	adda.l	d7,a0
	dbra	d0,find_ctr1
find_ctr2:
	move.w	(a0),d2
	subq.w	#4,d2
	ext.l	d2
	divu	#6,d2
	bra	find_objx

find_obj3:
	movea.l	(a1)+,a0		* a0 = animats pointer
	cmp.w	(a1)+,d0
	bgt	find_obj4

	nop
	bra	find_objx


find_obj4:
	movea.l	(a1),a0		* a0 = cell data

*		object is a cell
	moveq	#3,d1		* cell id
	sub.w	-2(a1),d0
	subq.w	#1,d0		* d0 = cell no.
	mulu	#128,d0
	adda.l	d0,a0		* a0 = data
	bra	find_objx

*		a0 = object start
*		d1 = object id
*		d2 = object data list length
*		d3 = object y height (raster)

find_objx:
	move.w	(sp)+,d0		* d0 = obj no.
	rts



	

*********************************
* create final view map         *
*********************************


do_vmap:
	lea	v_map,a0		* a0 = view map
	lea	g_map,a1		* a1 = ground cell map
	move.w	#map_cells-1,d7	* no. map cells
do_vmap1:
	move.w	2(a1),(a0)		* g_map char > v_map
	tst.w	(a1)		* null pointer ?
	beq	do_vmap2		* yes

	bsr	feature		* make new char
do_vmap2:
	addq.l	#2,a0		* next v_map cell
	addq.l	#4,a1		* next g_map cell
	dbra	d7,do_vmap1 	* do all cells
	rts



*********************************
* make composite char and masks *
*********************************


feature:
	move.w	(a0),d0		* d0 = g_map cell no.
	subi.w	#200,d0
	mulu	#128,d0		* char offset
	movea.l	cell_pnt,a2		* a2 = chars start
	adda.l	d0,a2		* a2 = reqd char
	movea.l	nx_f_char,a3	* a3 = free char area
	moveq	#7,d0		* counter
feature_1:
	move.l	(a2)+,(a3)+
	move.l	(a2)+,(a3)+
	move.l	(a2)+,(a3)+
	move.l	(a2)+,(a3)+
	dbra	d0,feature_1

	lea	g_map,a2		* a2 = links base
	clr.l	d0
	move.w	(a1),d0		* d0 = next link offset
	clr.w	2(a2,d0.l)		* null back pointer
feature_2:
	move.w	4(a2,d0.l),d1	* d1 = this link char no.
	bsr	new_cell		* make new char

	clr.l	d1
	move.w	0(a2,d0.l),d1	* d1 = next link offset
	beq	feature_3		* end of chain

	move.w	d0,2(a2,d1.l)	* next link back pointer
	move.w	d1,d0		* point to next link
	bra	feature_2		* process it

feature_3:
	move.w	4(a2,d0.l),d1	* top link mask no.
	subi.w	#200,d1
	mulu	#32,d1		* mask offset
	lea	masks,a3		* a3 = masks start
	adda.l	d1,a3		* a3 = reqd mask
	moveq	#15,d2		* d2 = counter
	clr.w	d1
feature_4:
	add.w	(a3)+,d1		* add all mask parts
	dbra	d2,feature_4

	move.w	4(a2,d0.l),(a0)	* top link char > v_map
	tst.w	d1		* was that right ?
	beq	feature_5		* yes - mask = all 0's

	move.w	nx_f_cnum,(a0)	* new char no. > v_map
	addi.w	#200,(a0)
	addq.w	#1,nx_f_cnum	* counter +1
	addi.l	#128,nx_f_char	* move free char pointer

feature_5:
	move.w	4(a2,d0.l),d2	* top link mask no.
	subi.w	#200,d2
	mulu	#32,d2		* d2 = mask offset
feature_6:
	move.w	2(a2,d0.l),d1	* d1 = back pointer
	move.w	d2,2(a2,d0.l)	* link mask pointer

	lea	masks,a3		* masks start
	adda.l	d2,a3		* a3 = reqd mask
	moveq	#15,d6		* d6 = counter
	clr.l	d3
feature_7:
	add.w	(a3)+,d3		* add all mask parts
	dbra	d6,feature_7

	tst.w	d3		* mask = all 0's ?
	beq	feature_9		* yes - rest are null

	move.w	d1,d0		* d0 = next link offset
	beq	feature_x		* end of chain

	move.w	4(a2,d0.l),d1	* new link mask no.
	subi.w	#200,d1
	mulu	#32,d1		* d1 = mask offset
	lea	masks,a3		* masks start
	movea.l	nx_f_mask,a4	* a4 = free mask area
	move.l	a4,-(sp)		* save it
	moveq	#15,d3		* d3 = counter
feature_8:
	move.w	0(a3,d1.l),(a4)	* mask data > mask area
	move.w	0(a3,d2.l),d4	* new mask data
	and.w	d4,(a4)+		* AND old mask > new mask
	addq.l	#2,a3		* next mask data
	dbra	d3,feature_8

	move.l	a4,nx_f_mask	* new free mask area
	move.l	(sp)+,d2		* d2 = new mask start
	subi.l	#masks,d2		* d2 = new mask offset
	bra	feature_6		* do next link

feature_9:
	move.w	d1,d0		* d0 = next back link
	beq	feature_x		* end of chain
	move.w	2(a2,d0.l),d1	* d1 = next back pointer
	clr.w	2(a2,d0.l)		* null pointer
	bra	feature_9		* all chain = null
feature_x:
	rts			* done




*****************************
*     merge two cells	    *
*****************************


new_cell:
	movea.l	nx_f_char,a3	* a3 = work area
	subi.w	#200,d1
	ext.l	d1
	lsl.w	#5,d1		* d1 = mask offset
	lea	masks,a5
	adda.l	d1,a5		* a5 = reqd mask
	lsl.w	#2,d1		* d1 = char offset
	movea.l	cell_pnt,a4
	adda.l	d1,a4		* a4 = reqd char
	moveq	#15,d6		* d6 = counter
new_cell1:
	move.w	(a5)+,d1		* d1 = mask word
	and.w	d1,(a3)		* AND mask > work area
	move.w	(a4)+,d2		* d2 = char word
	or.w	d2,(a3)+		* OR char > work area
	and.w	d1,(a3)		* AND mask > work area
	move.w	(a4)+,d2		* d2 = char word
	or.w	d2,(a3)+		* OR char > work area
	and.w	d1,(a3)		* AND mask > work area
	move.w	(a4)+,d2		* d2 = char word
	or.w	d2,(a3)+		* OR char > work area
	and.w	d1,(a3)		* AND mask > work area
	move.w	(a4)+,d2		* d2 = char word
	or.w	d2,(a3)+		* OR char > work area
	dbra	d6,new_cell1	* do all
	rts			* done



*********************
* create char masks *
*********************

make_masks:
	move.w	#max_flr+1,d0
make_mask1:
	move.w	d0,d1
	movea.l	cell_pnt,a0
	mulu	#128,d1
	adda.l	d1,a0

	move.w	d0,d1
	lea	masks,a1
	mulu	#32,d1
	adda.l	d1,a1

	moveq	#15,d2
make_mask2:
	move.w	(a0)+,d1
	or.w	(a0)+,d1
	or.w	(a0)+,d1
	or.w	(a0)+,d1
	eori.w	#$FFFF,d1
	move.w	d1,(a1)+
	dbra	d2,make_mask2

	addq.w	#1,d0
	cmpi.w	#max_char,d0
	ble	make_mask1
*				make player mask
	lea	p_data,a0
	lea	p_mask,a1
	moveq	#15,d0
make_mask3:
	move.w	(a0)+,d1
	or.w	(a0)+,d1
	or.w	(a0)+,d1
	or.w	(a0)+,d1
	eori.w	#$FFFF,d1
	move.w	d1,(a1)+
	dbra	d0,make_mask3
	rts



**********************
* draw view map      *
**********************

drw_vmap:
	lea	v_map,a0
	clr.w	d0
drw_vmap1:
	clr.w	d1
drw_vmap3:
	move.w	(a0)+,d2
	subi.w	#200,d2
	mulu	#128,d2
	movea.l	cell_pnt,a1
	adda.l	d2,a1

	movea.l	scrn,a2
	move.w	d0,d2
	mulu	#2560,d2
	move.w	d1,d3
	mulu	#8,d3
	adda.l	d2,a2
	adda.l	d3,a2

	moveq	#15,d2
drw_vmap2:
	move.l	(a1)+,(a2)
	move.l	(a1)+,4(a2)
	adda.l	#160,a2
	dbra	d2,drw_vmap2

	addq.w	#1,d1
	cmpi.w	#map_wdth,d1
	blt	drw_vmap3

	addq.w	#1,d0
	cmpi.w	#map_hgt,d0
	blt	drw_vmap1

	rts



wait_key:
	move.w	#8,-(sp)
	trap	#1
	addq.l	#2,sp
	rts


clr_scrn:
	movea.l	scrn,a0
	move.w	#$1FFF,d0
clr_scrn1:
	clr.l	(a0)+
	dbra	d0,clr_scrn1
	rts


move_plyr:
	subq.b	#1,d0
	bne	mv_plyr1

	move.w	y_pos,d0
	cmpi.w	#ymin,d0
	ble	mv_plyrx
	subq.w	#step,y_pos
	bra	mv_plyrx
mv_plyr1:
	subq.b	#1,d0
	bne	mv_plyr2

	cmpi.w	#x_max,x_pos
	bge	mv_plyrx
	addq.w	#step,x_pos
	bra	mv_plyrx
mv_plyr2:
	subq.b	#1,d0
	bne	mv_plyr3

	cmpi.w	#y_max,y_pos
	bge	mv_plyrx
	addq.w	#step,y_pos
	bra	mv_plyrx
mv_plyr3:
	move.w	x_pos,d0
	beq	mv_plyrx
	subq.w	#step,x_pos
mv_plyrx:
	rts



initial:
	move.w	#2,-(sp)
	trap	#14
	addq.l	#2,sp
	move.l	d0,scrn		* screen start

	move.w	#4,-(sp)
	trap	#14
	addq.l	#2,sp
	move.w	d0,scrn_res 	* save original res

	clr.w	-(sp)
	move.l	#-1,-(sp)
	move.l	#-1,-(sp)
	move.w	#5,-(sp)
	trap	#14
	adda.l	#12,sp		* set low res

	pea	palet
	move.w	#6,-(sp)
	trap	#14
	addq.l	#6,sp		* set palette
	rts




