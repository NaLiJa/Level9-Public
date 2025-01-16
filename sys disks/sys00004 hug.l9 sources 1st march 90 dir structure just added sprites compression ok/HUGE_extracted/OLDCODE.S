; OLDCODE.S
;
; The repository for all the stuff that will probably never
; be used again.
;
; Started Mike Austin 26/2/90.
;

 ifne 0 * ST 
boot_prog: 
*re-allow hard disc...	bra	boot_prog3 
 
;	move.w	#$19,-(sp)		* running from 
;	trap	#1		* hard disc ? 
; call_bdos $19
	addq.l	#2,sp 
*>>Mike 3/5/89	cmpi.w	#2,d0 
*>>mike 3/5/89	blt	boot_prog3		* no 
 
 
********* set up system for hard disc 
 
	move.w	#1,drive_flag-S(A5)	* 1 = hard disk 
	addi.w	#('c'-2),d0 
	move.b	d0,h_f_name		* set data file path 
	bra	boot_progx 
 
******* read disc info sector from floppy 
 
boot_prog3: 
	clr.w	drive_flag		* 0 = floppy a: 
 
	move.w	#55,sect_num	* info sector	 
	move.l	cmem_mapPtr,ld_pnt	* load buffer 
	bsr	get_sect		* read info sector 
	bsr	get_sect 
	movea.l	cmem_mapPtr-S(A5),a0	* start of data 
	lea	info_tab,a1 
	moveq	#17,d0 
boot_prog2: 
	move.l	(a0)+,(a1)+		* copy info to 
	dbra	d0,boot_prog2	* info_tab 
boot_progx: 
	rts 
 
 endc * ST	 
;=====================================================
; DEAD_CPY.S
 
 
 
	opt	d+ 
	opt	c+ 
	opt	x+ 
	opt	s- 
 
 
 
copy: 
	dc.w	$A00A		* mouse off 
 
	lea	msg0,a6		* opening 
	bsr	prn_msg		* message 
	bsr	get_key		* get reply 
	cmpi.b	#'q',d0		* quit ? 
	beq	copyx		* yes 
copy1: 
	lea	msg1,a6		* source filename 
	bsr	prn_msg		* prompt 
 
	move.b	#100,buffer		* max chars input 
	pea	buffer		* buffer start 
	move.w	#10,-(sp)		* get filename 
	trap	#1 
	addq.l	#6,sp 
 
	cmpi.b	#'q',buffer+2	* if 1st letter = 'q' 
	beq	copyx		* quit 
 
	pea	buffer+100		* room for DTA 
	move.w	#$1A,-(sp) 
	trap	#1 
	addq.l	#6,sp 
	clr.w	-(sp) 
	pea	buffer+2 
	move.w	#$4E,-(sp) 
	trap	#1 
	addq.l	#8,sp 
	tst.l	d0		* does file exist ? 
	bne	copy1		* no - try again 
 
	move.l	buffer+126,d0	* find file length 
	beq	copyx		* empty - quit 
	divu	#512,d0		* file len sectors 
	move.w	d0,srce_len		* save it 
	swap	d0		* get remainder 
	tst.w	d0		* remainder ? 
	beq	copy2		* no 
	addq.w	#1,srce_len		* else 1 more sector 
 
copy2: 
	clr.w	-(sp)		* read only 
	pea	buffer+2		* file name + path 
	move.w	#$3D,-(sp) 
	trap	#1		* open source file 
	addq.l	#8,sp 
	move.w	d0,srce_hand	* save handle 
	clr.l	srce_pnt		* srce file pointer 
 
copy3: 
	lea	msg2,a6		* floppy disc prompt 
	lea	flop_tab,a0		* 1st 2nd etc tab 
	move.w	flop_cnt,d0		* floppy disc no. 
	mulu	#3,d0		* d0 = offset 
	move.b	0(a0,d0.l),17(a6)	* alter disc 
	move.b	1(a0,d0.l),18(a6)	* prompt no. 
	move.b	2(a0,d0.l),19(a6) 
	bsr	prn_msg		* print it 
	bsr	get_key		* proceed 
	cmpi.b	#'p',d0		* with copy ? 
	bne	copyx		* no 
 
	bsr	flop_info		* find floppy info 
	bsr	do_floppy		* fill floppy with data 
	bsr	wrt_id		* put id sectors on it 
 
	addq.w	#1,flop_cnt		* no. floppies = +1 
	tst.w	c_flag		* end of copy ? 
	beq	copy3		* no - next floppy 
 
copy4: 
	lea	msg3,a6		* 1st disc message 
	bsr	prn_msg 
	bsr	get_key 
	bsr	chk_disc		* write info if 1st disc ? 
	bne	copy4		* else prompt again 
 
copyx: 
	dc.w	$A009		* mouse on 
	clr.w	-(sp) 
	trap	#1 
 
 
***************************** 
*  copy data to floppy disc * 
***************************** 
 
 
do_floppy: 
	move.l	srce_pnt,srce_strt	* save start source pointer 
do_flopy0: 
	move.w	#buflen_s,d0	* d0 = buffer len - sectors 
	cmp.w	free_sects,d0	* free sects > buffer len ? 
	blt	do_flopy1		* yes - use buffer len 
 
	move.w	free_sects,d0	* else use no. free sects 
do_flopy1: 
	cmp.w	srce_len,d0		* is read too much ? 
	ble	do_flopy2		* no 
 
	move.w	srce_len,d0		* else read until EOF 
do_flopy2: 
	move.w	d0,rw_cnt		* save read value 
 
	bsr	read_srce		* read source data to buffer 
 
	move.w	rw_cnt,d0		* d0 = length read 
	sub.w	d0,free_sects	* new free sectors count 
	sub.w	d0,srce_len		* new source remaining 
	mulu	#512,d0 
	add.l	d0,srce_pnt		* new source read pointer 
 
	lea	buffer,a0		* a0 = data start 
do_flopy3: 
	bsr	wrt_sect		* write a sector to floppy 
 
	addq.w	#1,nx_f_sect	* new free sector no. 
	adda.l	#512,a0		* next data block 
	subq.w	#1,rw_cnt		* end of data buffer ? 
	bne	do_flopy3		* no - do next sector 
 
	tst.w	srce_len		* end of copy ? 
	bne	do_flopy4		* no 
 
	move.w	#1,c_flag		* set end of copy flag 
	bra	do_flopyx		* quit 
do_flopy4: 
	tst.w	free_sects		* is floppy full ? 
	bne	do_flopy0		* no - read more data 
 
do_flopyx: 
	rts			* else exit 
 
 
 
************************************** 
* write i.d. sectors to floppy disc  * 
************************************** 
 
 
wrt_id: 
	move.l	srce_strt,d0	* data start - this disc 
	move.l	srce_pnt,d1		* data end - this disc 
	lsr.l	#7,d0		* d0 = 1st cell no.  
	lsr.l	#7,d1 
	subq.w	#1,d1		* d1 = last cell no. 
	move.w	d0,cell_1 
	move.w	d1,cell_2 
 
	lea	buffer,a0		* sector workspace 
	lea	id_msg,a1		* i.d. string 
wrt_id1: 
	move.b	(a1)+,(a0)+ 
	bne	wrt_id1 
 
	move.w	flop_cnt,(a0)+	* floppy disc no. 
	move.w	data_strt,(a0)+	* data start sector 
	move.w	d0,(a0)+		* 1st cell on this disc 
	move.w	d1,(a0)+		* last cell on this disc 
 
	lea	dead_tab,a0		* a0 = dead sector list 
wrt_id2: 
	move.w	(a0)+,d0		* dead sector no. 
	bmi	wrt_idx		* end of list 
 
	addq.l	#2,a0 
	move.l	a0,-(sp)		* save list pointer 
 
	clr.w	-(sp)		* drive a: 
	move.w	d0,-(sp)		* sector = d0 
	move.w	#1,-(sp)		* 1 sector 
	pea	buffer		* data 
	move.w	#1,-(sp)		* 'write' data 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
 
	movea.l	(sp)+,a0		* list pointer 
	bra	wrt_id2		* do all dead sectors 
wrt_idx: 
	lea	info_tab,a0		* disc info table 
	move.w	flop_cnt,d0		* floppy no. 
	mulu	#8,d0		* index 
 
	move.w	flop_cnt,0(a0,d0.l)	* disc no. 
	move.w	data_strt,2(a0,d0.l)	* data start sector 
	move.w	cell_1,4(a0,d0.l)	* 1st cell on disc 
	move.w	cell_2,6(a0,d0.l)	* last "    " 
	rts 
 
 
 
 
***************************************** 
* write 1 sector of data to floppy disc * 
***************************************** 
 
 
wrt_sect: 
	move.l	a0,-(sp)		* save buffer pointer 
 
	lea	dead_tab,a1		* a1 = dead sector list 
wrt_sect1: 
	move.w	(a1)+,d0		* d0 = list entry 
	bmi	wrt_sect2		* -ve = list end 
 
	cmp.w	nx_f_sect,d0	* is next free sector dead ? 
	bne	wrt_sect1		* no - test next one 
 
	addq.w	#1,nx_f_sect	* use next floppy sector 
	bra	wrt_sect1		* test all values 
 
wrt_sect2: 
	clr.w	-(sp)		* drive = a: 
	move.w	nx_f_sect,-(sp)	* sector no. 
	move.w	#1,-(sp)		* 1 sector 
	move.l	a0,-(sp)		* data pointer 
	move.w	#1,-(sp)		* 'write' sector 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
 
	movea.l	(sp)+,a0 
	rts 
 
 
************************************* 
* read reqd source data into buffer * 
************************************* 
 
read_srce: 
	clr.w	-(sp)		* seek from start 
	move.w	srce_hand,-(sp)	* file handle 
	move.l	srce_pnt,-(sp)	* file offset 
	move.w	#$42,-(sp) 
	trap	#1 
	adda.l	#10,sp 
 
	move.w	rw_cnt,d0		* sectors to read 
	mulu	#512,d0		* bytes to read 
 
	pea	buffer		* buffer address 
	move.l	d0,-(sp)		* bytes to read 
	move.w	srce_hand,-(sp)	* file handle 
	move.w	#$3F,-(sp) 
	trap	#1 
	adda.l	#12,sp 
	rts 
 
 
************************* 
* calc floppy disc info * 
************************* 
 
 
flop_info: 
	move.w	#1,-(sp)		* drive = A: 
	pea	buffer		* buffer 
	move.w	#$36,-(sp)		* find space on disc 
	trap	#1 
	addq.l	#8,sp 
 
	move.l	buffer,d0		* d0 = free clusters 
	move.l	buffer+4,d1		* d1 = total clusters 
	sub.l	d0,d1 
	subi.w	#10,d1		* d1 = prog clusters 
	lsl.w	#1,d1		* d1 = prog sectors 
	addi.w	#18,d1		* d1 = 1st free sector 
 move.w #514,d1 *>>Mike 11/1/89 force code to start half way through disc 
 move.w #286,d0 * 300 free sectors 
	move.w	d1,nx_f_sect	* save it 
	move.w	d1,data_strt	* 1st data sector 
	lsl.w	#1,d0		* d0 = free sectors 
	move.w	d0,free_sects	* save it 
	rts 
 
 
********************** 
* check for 1st disc * 
********************** 
 
chk_disc: 
	clr.w	-(sp)		* drive a: 
	move.w	#54,-(sp)		* sector 54 
	move.w	#1,-(sp)		* 1 sector 
	pea	buffer		* buffer 
	clr.w	-(sp)		* read it 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
 
	lea	buffer,a0		* buffer start 
	lea	id_msg,a1		* disc i.d. string 
chk_dsc1: 
	move.b	(a1)+,d0		* i.d. char 
	beq	chk_dsc2		* end of i.d. 
 
	cmp.b	(a0)+,d0		* does it match ? 
	bne	chk_dscx		* no - fail 
	bra	chk_dsc1		* else next char 
chk_dsc2: 
	tst.b	(a0)+		* a0 = disc no 
	tst.w	(a0)		* disc no. = 0 ? 
	bne	chk_dscx		* no - fail 
 
	clr.w	-(sp)		* drive a: 
	move.w	#55,-(sp)		* sector 55 
	move.w	#1,-(sp)		* 1 sector 
	pea	info_tab		* disc info tab 
	move.w	#1,-(sp)		* write it 
	move.w	#4,-(sp) 
	trap	#13 
	adda.l	#14,sp 
	clr.w	d0		* set z flag = ok 
chk_dscx: 
	rts			* exit 
 
 
 
 
********************** 
* print a message    * 
********************** 
 
prn_msg: 
	move.l	a6,-(sp)		* text start 
	move.w	#9,-(sp) 
	trap	#1 
	addq.l	#6,sp 
	rts 
 
 
********************* 
*  get a key        * 
********************* 
 
get_key: 
	move.w	#8,-(sp) 
	trap	#1 
	addq.l	#2,sp 
	rts 
 
 
 
 
 
 
 
******************* 
*  variables etc  * 
******************* 
 
 
buflen_s:	equ	250	* buffer = 128000 bytes 
 
 
srce_len:	dc.w	0	* source data file length - sectors 
srce_hand:	dc.w	0	* source file handle 
free_sects:	dc.w	0	* free sectors - floppy 
nx_f_sect:	dc.w	0	* free sector no. - floppy 
rw_cnt:	dc.w	0	* no. sectors to read 
flop_cnt:	dc.w	0	* no. floppies used 
data_strt:	dc.w	0	* 1st data sector on disc 
c_flag:	dc.w	0	* end of copy flag 
cell_1:	dc.w	0	* 1st cell no. on disc 
cell_2:	dc.w	0	* last "        " 
 
srce_pnt:	dc.l	0	* source file read offset 
srce_strt:	dc.l	0	* start of floppy pointer 
 
flop_tab:	dc.b	'1st','2nd','3rd','4th','5th' 
	dc.b	'6th','7th','8th','9th' 
 
msg0:	dc.b	27,'E' 
	dc.b	'The copy process is continuous once ' 
	dc.b	'started so' 
	dc.b	13,10,10 
	dc.b	'please ensure you have enough ' 
	dc.b	'dead sector discs before continuing.' 
	dc.b	13,10,10,10,10,27,'p' 
	dc.b	'  <Q> - to quit  ' 
	dc.b	0 
 
msg1:	dc.b	27,'E',27,'p' 
	dc.b	'  Level 9 dead sector disc copier  ' 
	dc.b	27,'q',13,10,10,10 
	dc.b	'Source data filename (inc path) :> ' 
	dc.b	0 
 
msg2:	dc.b	13,10,10 
	dc.b	'Please insert xxx floppy disc ' 
	dc.b	'into drive A:' 
	dc.b	13,10,10,27,'p' 
	dc.b	'  <P> - to continue  ' 
	dc.b	27,'q',0 
 
msg3:	dc.b	13,10,10 
	dc.b	'Please insert 1st disc again.' 
	dc.b	13,10,10,27,'p' 
	dc.b	'  <P> - to continue  ' 
	dc.b	27,'q',0 
 
id_msg:	dc.b	'Lauren.',0 
 
 
 
	even 
 
dead_tab:	dc.w	54,55,102,103,198,199,254,255 
	dc.w	334,335,406,407,478,479,554,555 
	dc.w	614,615,702,703,$FFFF 
 
	even 
 
info_tab:	ds.b	72 
 
	even 
 
buffer:	dc.l	0 
;============================================================ 
; Space Invaders section of Hero
;
; Copyright (C) 1988 Level 9 Computing
;
; M.J.Austin 1987/1988.
;
;
; This code was written as a challenge. I was bet that
; I Couldn't write a playable version of space invaders in less
; than a day. It actually took slightly under 3 hours (and
; it shows!)
;
;
;
;
;----------------- Start of Space Invaders




;-------
SIResetMonsters
 bsr SIInitSpriteTable
 lea SIStepsToGo-S(a5),a0
 move.w #70,(a0)
 lea SIYStepsToGo-S(a5),a0
 move.w #30,(a0) * determines length of game
 lea SIXSpeed-S(a5),a0
 move.w #2,(a0)
 lea SIYSpeed-S(a5),a0
 move.w #0,(a0)

 lea ScreenXPos-S(a5),a0
 move.w #0,(a0)
 lea ScreenYPos-S(a5),a0
 move.w #32,(a0)


SpaceInvLoop
* clear the screen
 lea HeroStack-S(a5),sp

 move.l LogicalBase-S(a5),a0
 move.w #1000,d0
SIL1
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+

 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 dbra d0,SIL1
 bsr DisplayAllSprites

 movem.l d0-d7/a0-a6,-(sp)
*****should re-enable  bsr SwapPage ; display it all.
*****should re-enable  bsr DoDelayedFlip
  lea SpriteTable-S(a5),a0
  tst.l (a0) * player still alive?
  beq SIGameOver * no
  bsr HandleInvaders

 movem.l d0-d7/a0-a6,-(sp)

 bsr AbsGetCharFromBdos
; tst.b d0
; beq.s SINoKeyPress
;****** bsr HandleKeyPress
;
;SINoKeyPress

 bsr SIGetPlayerInput
 bsr CPMFinishMove * update speed pointers+do animation

 btst #FireButton,d7
 bne SIMaybeFireMissile
 bra SpaceInvLoop

SIMaybeFireMissile

; move.l Player1SpriteBlock-S(A5),a0
 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a0
 add.l d0,a0


 clr.b ViewOffset(a0)
; lea PlayerView-S(a5),a0
; clr.b (a0)
 bsr SIFireMissile
 bra SpaceInvLoop
;--------
HandleInvaders
* all invaders destroyed?
 lea SpriteTable-S(a5),a0
 move.w #MaxMovingSprites,d7

AllGone1
 tst.l (a0) * sprite number zero?
 beq AllGone2
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d0
 bmi.s SomeLeft
AllGone2
 add.l #SpriteCurrentSize,a0
 dbra d7,AllGone1
SIGameOver
 move.w #0,d0
 move.w #4,d1 * controls length of delay
SIDelay
 dbra d0,SIDelay
 dbra d1,SIDelay
 bra SIResetMonsters
;
SomeLeft
 bsr GetRandom
 cmp.b #200,d0
 blt SIFA3

* find an invader to drop a missile
 lea SpriteTable-S(a5),a0
 move.w #MaxMovingSprites,d7
FindAttacker
 tst.l (a0) * sprite number zero?
 beq SIFA2
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d0
 bpl.s SIFA2 * not an invader
 lea RandomSeed-S(a5),a1
 move.l (a1),d6
 rol.l #1,d6
 move.l d6,(a1)

 btst #0,(a1)
 beq.s SIFA2 * this one won't fire
 btst #1,(a1)
 beq.s SIFA2 * only fires on a double zero
* only fires if it the highest possible
 move.w XPosOffset(a0),d0
 move.w YPosOffset(a0),d1
* check if any of the other invaders are lower...
SIFFire1
 tst.l (a0) * sprite number zero?
 beq SIFLaunch
 move.l (a0),a1 * address of sprite structure
 move.b TypeOffset(a1),d2
 bpl.s SIFFire2 * not an invader
 cmp.w YPosOffset(a0),d1
 bge.s SIFFire2
* this invader is lower
 move.w YPosOffset(a0),d1

SIFFire2
 add.l #SpriteCurrentSize,a0
 dbra d7,SIFFire1
SIFLaunch
* launch a missile starting at (d0.w,d1.w)
 add.w #4,d1 * get clear of invader
 clr.w d2 * x speed
 move.w #12,d3 * y speed
 move.w #5,d4 * sprite number for missile
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6
 bra.s SIFA3

;---
SIFA2
 add.l #SpriteCurrentSize,a0
 dbra d7,FindAttacker

SIFA3
* move dem invaders!!!
 lea SIYSpeed-S(a5),a0
 clr.w (a0)
 lea SIStepsToGo-S(a5),a0
 subq.w #1,(a0)
 bne.s SINoCHange
 move.w #70,(a0)
* change direction, move down
 lea SIXSpeed-S(a5),a0
 neg.w (a0)
 lea SIYSpeed-S(a5),a0
 move.w #6,(a0)
 lea SIYStepsToGo-S(a5),a0
 subq.w #1,(a0)
 bmi SIGameOver

SINoChange
 rts

;---------
SIFireMissile
; Initiate Fire
 move.w PlayerXPos-S(a5),d0
 move.w PlayerYPos-S(a5),d1
; add.w #4,d1 * overlap allowed for head
 clr.l d2
; move.b PlayerView-S(a5),d2

; move.l Player1SpriteBlock-S(A5),a0
 clr.l d0
 move.w Player1SpriteOffset-S(A5),d0
 lea SpriteTable-S(A5),a0
 add.l d0,a0


 move.b ViewOffset(a0),d2
 asl.w #2,d2 * 2 words per entry
 lea ViewToXYConversionTable-S(a5),a0
 add.l d2,a0
 move.w (a0)+,d2 * d2:=x speed
 move.w #12,d4
 mulu d4,d2 * missiles go at 12 pel/step
 move.w (a0)+,d3 * d3:=y speed
 mulu d4,d3 * missiles go at 12 pel/step
 move.w #6,d4 * sprite number for missile

 lea RandomSeed-S(a5),a0
 move.l (a0),d6
 rol.l #1,d6
 move.l d6,(a0)
 and.b #3,d6

 move.w d2,d5
 asr.w d6,d5
 add.w d5,d0
 move.w d3,d5
 asr.w d6,d5
 add.w d5,d1

 bsr SetUpNewSprite
 rts *  bra TimeLoop
;-------
SIInitSpriteTable
 Lea DoYRangeKill-S(a5),a0
 move.b #1,(a0)

 lea SpriteTable-S(a5),a0
 lea SpriteTPtr-S(a5),a1
 move.l a0,(a1)
 move.w #MaxMovingSprites,d5 * max size of table
SIIST1
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+

 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 dbra d5,SIIST1

* and set up 1 player sprite....

 move.w #184,d1 * initial player y pos
 clr.w d2 * x speed
 clr.w d3 * y speed
 move.w #0,d4 * player-type
 move.w #16,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

* and set up 25 monster sprites....
 move.w #4,d4
 move.w #32,d1 * top ledft y pos

SIIST2
 move.w #16,d0 * top left x pos of grid of monsters
SIIST3
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6
 add.w #16,d0 * x pos
 cmp.w #130,d0
 ble.s SIIST3
 add.w #16,d1 * y pos
 cmp.w #100,d1
 ble.s SIIST2

* and set up a monster above the player
 move.w #154,d1 * initial player y pos
 move.w #16,d0 * initial player x pos
 movem.l d0-d7/a0-a6,-(sp)
 bsr SetUpNewSprite
 movem.l (sp)+,d0-d7/a0-a6

 rts
;----
SIGetPlayerInput
 move.b JoystickStatus-S(a5),d7
 move.w #6,d6 * step size

 clr.w d4 * x offset requested by player
 clr.w d5 * y offset requested by player
 
 btst #LeftBit,d7
 beq.s SINotLeft
 move.w PlayerXPos-S(a5),d0
 sub.w d6,d0
 bmi SINotLeft ; Prevent Move if off screen
 clr.w d4
 sub.w d6,d4 * negative step size in x offset

SINotLeft
 btst #RightBit,d7
 beq.s SINotRight
 move.w PlayerXPos-S(a5),d0
 add.w d6,d0
 cmp.w PlayerXMax-S(a5),d0
 bge SINotRight
 move.w d6,d4 * set x offset to step size

SINotRight
 RTS
;---------







;-------------- End of Space Invaders
;====================================================
