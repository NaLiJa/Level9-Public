
 
 
	opt	c+ 
***	opt	d+ 
	opt	s+ 
	opt	x+ 
 
main: 
	movea.l	test_pnt,a0 
	move.w	(a0)+,d0 
	bmi	mainx 
	move.w	(a0)+,d1 
	move.l	a0,test_pnt 
	bsr	m_load_u 
 
	addi.w	#12,sys_clock 
	bra	main 
mainx: 
	clr.w	-(sp) 
	trap	#1 
 
 
 
 
 
********************************* 
*   load data into memory pool  * 
********************************* 
 
* d0 = 1st cell to load 
* d1 = last cell to load 
 
 
m_load_p: 
	move.w	sys_clock,d2	* d0 = clock 
	bset	#15,d2		* protect it 
	bra	m_load0 
 
m_load_u: 
	move.w	sys_clock,d2	* d0 = clock 
 
m_load0: 
	move.w	d2,timer		* save timer value 
 
	sub.w	d0,d1		* d1 = no. cells -1 
	subi.w	#cell_index,d0 
	move.w	d0,cell_1		* save 1st cell no. 
	move.w	d1,cell_cnt		* save cells counter 
	addq.w	#1,d1		* d1 = no. cells to load 
	mulu	#128,d1		* x cell length 
	move.l	d1,data_len		* save data length 
	cmp.l	sz_f_cmem,d1	* will data fit ? 
	ble	m_load3		* yes 
m_load1: 
	move.w	sys_clock,d0	* d0 = time now 
	subi.w	#36,d0		* d0 = 5 mins ago 
m_load2: 
	bsr	m_purge		* lose old data 
	move.l	data_len,d1 
	cmp.l	sz_f_cmem,d1	* will it fit now ? 
	ble	m_load3		* yes 
	addi.w	#12,d0		* 1 minute later 
	bra	m_load2		* loop 
 
m_load3: 
	bsr	rd_data		* read data from disk 
 
	move.w	cell_1,d0		* d0 = 1st cell no. 
	mulu	#6,d0		* cell_tab offset 
	lea	cell_tab,a0 
	adda.l	d0,a0		* a0 = 1st cell rec 
	movea.l	nx_f_cmem,a1	* a1 = data start 
	move.w	cell_cnt,d0		* d0 = counter 
	move.l	#128,d1		* pointer add 
	move.w	timer,d2		* timer value 
m_load4: 
	move.w	d2,(a0)		* write timer 
	move.l	a1,2(a0)		* write data pntr 
	adda.l	d1,a1		* next cell 
	addq.l	#6,a0		* next cell_tab rec 
	dbra	d0,m_load4		* do all 
 
	move.l	a1,nx_f_cmem	* new free mem 
	suba.l	#cmem_pool,a1	* mem pool offset 
	move.l	#cmem_size,d0	* total mem pool size 
	sub.l	a1,d0		* d0 = new free mem len 
	move.l	d0,sz_f_cmem	* save it 
	rts			* done 
 
 
 
 
****************************** 
*    memory purge code       * 
****************************** 
 
*			map out memory pool 
m_purge: 
	lea	cmem_map,a0 
	move.w	#499,d2 
	moveq	#-1,d1 
m_purge0: 
	move.l	d1,(a0)+ 
	move.l	d1,(a0)+ 
	move.l	d1,(a0)+ 
	move.l	d1,(a0)+ 
	dbra	d2,m_purge0 
 
	lea	cell_tab,a0		* a0 = hit table 
	lea	cmem_map,a1		* a1 = map table 
	movea.l	a1,a5		* a5 = "     " 
	lea	cmem_pool,a6		* a6 = memory pool 
	clr.w	d6		* cell_tab rec no. 
	move.w	#3999,d7		* cell_tab len 
m_purge1: 
	move.l	2(a0),d2		* is rec using mem. ? 
	beq	m_purge3		* no 
 
	move.w	(a0),d1		* d1 = flags/timer 
	bmi	m_purge2		* purge proof 
	andi.w	#$1FFF,d1		* d1 = timer 
	cmp.w	d0,d1		* too old ? 
	bgt	m_purge2		* no 
 
	clr.l	2(a0)		* else purge it 
	bra	m_purge3 
m_purge2: 
	sub.l	a6,d2		* d2 = mem block offest 
	lsr.l	#6,d2		* d2 = mem block no. 
	move.w	d6,0(a1,d2.l)	* d6 = cell_tab rec no. 
m_purge3: 
	addq.w	#1,d6 
	addq.l	#6,a0 
	dbra	d7,m_purge1 
 
*			consolidate memory pool 
	lea	cell_tab,a0 
	moveq	#-1,d7 
m_purge4: 
	addq.l	#1,d7 
	tst.w	(a1)+ 
	bmi	m_purge5 
	cmpi.w	#3999,d7 
	blt	m_purge4 
 
m_purgex: 
	move.l	a2,nx_f_cmem 
	suba.l	a6,a2 
	move.l	#cmem_size,d2 
	sub.l	a2,d2 
	move.l	d2,sz_f_cmem 
	rts 
 
m_purge5: 
	move.l	d7,d1		* d1 = free mem slot no. 
	lsl.l	#7,d1		* offset 
	movea.l	a6,a2		* a2 = cmem_pool 
	adda.l	d1,a2		* a2 = free mem slot 
 
	movea.l	a1,a3		* a3 = word after free slot 
	move.w	d7,d6		* d6 = counter 
m_purge6: 
	addq.l	#1,d6		* find 1st used 
	tst.w	(a3)+		* slot after free 
	bpl	m_purge7		* slot 
	cmpi.w	#3999,d6 
	blt	m_purge6 
	bra	m_purgex		* end 
 
m_purge7: 
	lsl.w	#1,d6		* d6 = cmem_map offset 
	move.w	0(a5,d6.l),d1	* d1 = cell no using slot 
	move.w	#-1,0(a5,d6.l)	* mark slot as free 
	mulu	#6,d1		* d1 = cell_tab rec offset 
	movea.l	2(a0,d1.l),a3	* a3 = curerent data pntr 
	move.l	a2,2(a0,d1.l)	* a2 = new data pntr 
 
	moveq	#7,d1 
m_purge8: 
	move.l	(a3)+,(a2)+		* copy data 
	move.l	(a3)+,(a2)+		* to new 
	move.l	(a3)+,(a2)+		* memory 
	move.l	(a3)+,(a2)+		* slot 
	dbra	d1,m_purge8 
 
	bra	m_purge4		* next free slot 
 
 
******************************* 
*    load data from disk      * 
******************************* 
 
 
rd_data: 
	move.w	#1,d_flag		* check disc flag 
 
	move.w	cell_cnt,ld_cnt	* copy load count 
 
	lea	info_tab-8,a0	* disc info table 
	move.w	cell_1,d0		* 1st cell to load 
rd_dat01: 
	addq.l	#8,a0		* is 1st cell 
	cmp.w	6(a0),d0		* on this disc ? 
	bgt	rd_dat01		* no - try next 
 
	move.l	a0,info_pnt		* save info pntr 
	move.w	(a0),disc_num	* reqd disc no. 
	clr.l	d1 
	sub.w	4(a0),d0 
	move.w	d0,d1 
	lsr.w	#2,d0 
	add.w	2(a0),d0		* d0 = 1st sector no. 
	move.w	d0,sect_num		* save it 
	andi.w	#3,d1		* in-sect offset 
	beq	rd_dat02		* no offset 
 
	moveq	#4,d2 
	sub.w	d1,d2		* d2 = chars in 1st sector 
	sub.w	d2,ld_cnt		* adjust load counter 
	mulu	#128,d1		* d1 = load offset 
rd_dat02: 
	move.l	d1,-(sp)		* save offset 
	move.l	#cmem_map,ld_pnt	* set load pointer 
	bsr	rd_sect		* read data 
	lea	cmem_map,a1	* data start 
	movea.l	nx_f_cmem,a2	* free memory 
	move.l	(sp)+,d0		* offset 
	move.l	#512,d1		* sect len 
	sub.l	d0,d1 
	lsr.w	#2,d1 
	subq.w	#1,d1		* data counter 
	adda.l	d0,a1 
rd_dat03: 
	move.l	(a1)+,(a2)+		* copy data to 
	dbra	d1,rd_dat03		* free memory 
 
	move.l	a2,ld_pnt		* next free mem 
	bsr	inc_sect		* next sector no. 
	move.w	ld_cnt,d0		* chars to load 
	move.w	d0,d1 
	lsr.w	#2,d0		* whole sectors 
	andi.w	#3,d1 
	move.w	d1,ld_rem		* save remainder 
	move.w	d0,ld_cnt		* whole sectors to load 
	beq	rd_dat05		* no whole sectors 
 
rd_dat04: 
	bsr	rd_sect		* read sector 
	bsr	inc_sect		* next sector 
	subq.w	#1,ld_cnt		* done all ? 
	bne	rd_dat04		* no 
rd_dat05: 
	tst.w	ld_rem		* any bits to do ? 
	beq	rd_dat07		* no 
 
	move.l	ld_pnt,-(sp)	* save free mem 
	move.l	#cmem_map,ld_pnt	* use buffer 
	bsr	rd_sect		* read last sector 
	lea	cmem_map,a1	* data start 
	movea.l	(sp)+,a0		* free memory 
	move.w	ld_rem,d0		* chars to read 
	lsl.w	#5,d0		* data len 
	subq.w	#1,d0		* counter 
rd_dat06: 
	move.l	(a1)+,(a0)+		* copy data to 
	dbra	d0,rd_dat06		* free mem 
rd_dat07: 
	move.w	sect_num,last_sect	* save last sector read 
	rts 
 
 
*********************************** 
*        read a sector            * 
*********************************** 
 
rd_sect: 
	lea	dead_tab,a0		* dead sector list 
	move.w	sect_num,d0		* sector to read 
rd_sect1: 
	tst.w	(a0)		* end of list ? 
	bmi	rd_sect2		* yes 
 
	cmp.w	(a0)+,d0		* this sector dead ? 
	bne	rd_sect1		* no 
 
	bsr	inc_sect		* next sector 
	move.w	sect_num,d0		* into d0 
	bra	rd_sect1		* loop 
rd_sect2: 
	bsr	get_disc		* ensure reqd disc 
 
	clr.w	-(sp)		* drive a: 
	move.w	sect_num,-(sp)	* sector no. 
	move.w	#1,-(sp)		* 1 sector 
	move.l	ld_pnt,-(sp)	* load pointer 
	clr.w	-(sp)		* 'read' 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
 
	addi.l	#512,ld_pnt		* next block addr 
	rts 
 
 
************************************ 
*  ensure correct disc in drive a: * 
************************************ 
 
get_disc: 
	tst.w	d_flag		* disc check reqd ? 
	beq	get_discx		* no 
 
	clr.w	d_flag		* clear disc flag 
	bsr	calc_id		* calc id sector no. 
get_disc1: 
	bsr	get_id		* check id sector 
	beq	get_discx		* ok - exit 
 
	move.w	disc_num,d0		* d0 = reqd disc 
	addi.b	#'1',d0 
	lea	msg1,a6 
	move.b	d0,msg_off(a6) 
	bsr	prn_msg 
	bsr	get_key 
	bsr	d_force 
 
	bra	get_disc1 
get_discx: 
	rts 
 
 
 
*********************************** 
* calculate id sector no. to read * 
*********************************** 
 
calc_id: 
	lea	dead_tab,a0		* dead sectors 
	lea	cmem_map,a1	* work area 
	move.w	last_sect,d0	* last sector read 
	moveq	#9,d2		* counter 
calc_id1: 
	move.w	d0,d1		* d1 = reqd sector 
	sub.w	(a0),d1		* d1 = diff 
	bpl	calc_id4 
 
	neg.w	d1		* ensure +ve 
calc_id4: 
	move.w	d1,(a1)+		* save it 
	addq.l	#4,a0		* calc all 
	dbra	d2,calc_id1		* id sector diffs 
 
	lea	cmem_map,a1 
	lea	dead_tab,a0 
	moveq	#8,d1		* counter 
	clr.l	d2 
	move.w	(a1)+,d0		* d0 = 1st diff 
calc_id2: 
	cmp.w	(a1)+,d0		* new diff < ? 
	ble	calc_id3		* no 
 
	move.l	d2,d3		* d3 = lowest diff no. 
	move.w	-2(a1),d0		* d0 = new lowest diff 
calc_id3: 
	addq.w	#1,d2 
	dbra	d1,calc_id2 
 
	lsl.w	#2,d3		* sector no. offset 
	move.w	0(a0,d3.l),id_sect	* save id sector no. 
	rts 
 
 
 
************************************ 
*     increment sector number      * 
************************************ 
 
inc_sect: 
	move.l	a0,-(sp) 
 
	addq.w	#1,sect_num		* sector no. +1 
	cmpi.w	#799,sect_num	* still on disc ? 
	ble	inc_sectx		* yes 
 
	movea.l	info_pnt,a0		* a0 = disc info tab 
	addq.l	#8,a0		* next disc 
	move.w	(a0),disc_num	* new disc no. 
	move.w	2(a0),sect_num	* new sect no. 
	move.l	a0,info_pnt		* save pointer 
	move.w	#1,d_flag		* set 'check disc flag' 
inc_sectx: 
	movea.l	(sp)+,a0 
	rts 
 
 
************************************* 
*        check disc identity        * 
************************************* 
 
get_id: 
	clr.w	-(sp)		* drive a: 
	move.w	id_sect,-(sp) 
	move.w	#1,-(sp) 
	pea	cmem_map 
	clr.w	-(sp) 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
	 
	lea	cmem_map,a0	* buffer start 
	lea	id_msg,a1		* disc i.d. string 
get_id1: 
	move.b	(a1)+,d0		* i.d. char 
	beq	get_id2		* end of i.d. 
 
	cmp.b	(a0)+,d0		* does it match ? 
	bne	get_idx		* no - fail 
	bra	get_id1		* else next char 
get_id2: 
	addq.l	#1,a0		* a0 = actual disc 
	move.w	disc_num,d0		* d0 = reqd disc 
	cmp.w	(a0),d0		* match ? 
get_idx: 
	rts 
 
 
************************************* 
*  force change of disc acknowledge * 
************************************* 
 
d_force: 
	clr.w	-(sp) 
	move.w	#2,-(sp) 
	move.w	#2,-(sp) 
	move.l	#0,-(sp) 
	move.w	#2,-(sp) 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
 
	pea	cmem_map 
	move.w	#$1A,-(sp) 
	trap	#1 
	addq.l	#6,sp 
 
	move.w	#$10,-(sp) 
	pea	cmem_map 
	move.w	#$4E,-(sp) 
	trap	#1 
	addq.l	#8,sp 
	rts 
 
 
 
******************************* 
*    print a message          * 
******************************* 
 
prn_msg: 
	move.l	a6,-(sp) 
	move.w	#9,-(sp) 
	trap	#1 
	addq.l	#6,sp 
	rts 
 
 
get_key: 
	move.w	#8,-(sp) 
	trap	#1 
	addq.l	#2,sp 
	rts 
	 
 
 
 
 
******************************* 
*         data areas	      * 
******************************* 
 
 
test_tab: 
	dc.w	1000,1300 
	dc.w	3500,3700 
	dc.w	3000,3200 
	dc.w	$FFFF 
 
test_pnt:	dc.l	test_tab 
 
******************************** 
 
 
	even 
 
cmem_size:	equ	128000		* mem pool size 
cell_index:	equ	0		* 1st cell no. 
msg_off:	equ	21		* message switch offset 
 
 
sys_clock:	dc.w	36		* clock 
handle:	dc.w	0		* file handle 
timer:	dc.w	0		* flags/clock 
cell_1:	dc.w	0		* 1st cell to load 
cell_cnt:	dc.w	0		* no. cells counter 
 
ld_cnt:	dc.w	0		* load counter 
d_flag:	dc.w	0		* disc flag 
disc_num:	dc.w	0		* reqd disc no. 
sect_num:	dc.w	0		* reqd sector no. 
ld_rem:	dc.w	0		* load remainder 
id_sect:	dc.w	0		* id sector no. 
last_sect:	dc.w	0		* last sector read 
 
 
info_pnt:	dc.l	0		* disc info pointer 
ld_pnt:	dc.l	0		* load pointer 
data_len:	dc.l	0		* data block len 
nx_f_cmem:	dc.l	cmem_pool		* next free cell mem 
sz_f_cmem:	dc.l	cmem_size		* free cell mem size left 
 
 
dead_tab:	dc.w	54,55,102,103,198,199,254,255 
	dc.w	334,335,406,407,478,479,554,555 
	dc.w	614,615,702,703,$FFFF 
 
info_tab:	dc.w	0,$16,0,$0BD7 
	dc.w	1,$16,$0BD8,$0F9F 
	ds.b	7*8 
 
 
 
msg1:	dc.b	27,'E','Please insert disc x into drive.',0 
 
id_msg:	dc.b	'Lauren.',0 
	even 
 
cmem_map:	dc.l	0		* mem mapping table 
cell_tab:	equ	cmem_map+8000	* cell pointers 
cmem_pool:	equ	cell_tab+24000	* memory pool 
 
 
