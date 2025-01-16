MCInitSound 
 ifne Amiga
  rts
 endc

 movem.l a3-a6,-(sp) 
  bsr init_snd 
 movem.l (sp)+,a3-a6 
 rts 
;---- 
MCStartSound 
; play sound at listV1(v2) of length v3 samples 
 movem.l a3-a6,-(sp) 
 
 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
; (a0).l is ptr to list. 
 move.l (a0),a0 
 move.w 4(a4),d0 
 add.l d0,a0 
* now a0.l is the address of the sound to start playing. 
 move.w 6(a4),d7 * length of sound in samples. 
  bsr StartSound 
 movem.l (sp)+,a3-a6 
 rts 
 
;--- 
 
do_sound: 
* decides which sound to do. 
	lea	c_flags,a0 
	moveq	#19,d0 
	clr.l	d1 
do_snd1: 
	tst.b	(a0)+ 
	bne	do_snd2 
	addq.w	#1,d1 
	dbra	d0,do_snd1 
	bra	do_sndx 
do_snd2: 
	lea	spr_tab,a0 
	lsl.w	#1,d1 
	move.w	0(a0,d1.l),d2 
	cmp.w	snd_pty,d2 
	bge	do_sndx 
 
	move.w	d2,snd_pty 
	lea	snd_offs,a0 
	lsl.w	#1,d1 
	move.l	0(a0,d1.l),d0 
	move.l	4(a0,d1.l),d1 
	sub.w	d0,d1 
;>>mike	lea	snd_data,a0 
	adda.l	d0,a0 
 
StartSound 
* starts playing sound data in memory at a0.l 
* of length d7.w 
	move.w	sr,d0 
	move.w	#$2700,sr 
*	move.w	d1,snd_len 
*	move.l	a0,snd_lst 
	move.l	#play_snd,int_vec 
 
;>>Mike	move.l	#snd_data,snd_lst 
	move.l a0,snd_lst *>>Mike 
	move.w	d7,snd_len * length of sound. 
 
	move.w	d0,sr 
do_sndx: 
	lea	c_flags,a0 
	clr.l	(a0)+ 
	clr.l	(a0)+ 
	clr.l	(a0)+ 
	clr.l	(a0)+ 
	clr.l	(a0)+ 
	rts 
 
 
 
init_snd: 
* sets up sound chip for 5KHz 
	move.w	sr,d0 
	move.w	#$2700,sr 
	move.l	int_vec,PreSoundInt_Vec-S(A5) * save existing. 
	move.l	#no_play,int_vec 
 
	move.b	#0,tacr * timer stop 
	move.b	#$06,tacr * delay mode, subdivider=100 
	move.b	#$05,tadr * countdown from 5 to 1 
 
	or.b	#$20,imra * interrupt mask: timer a only 
;	move.b	#$40,imrb * interrupt mask: I/O port bit 4. 
	or.b	#$20,iera * enable timer a source 
;	move.b	#$40,ierb * enable i/o port bit 4 
	bclr	#3,mfp_vec * automatic end of interrupt mode, 
* which automatically clears the interrupt pending bit, 
* so a new interrupt can occur before the existing one 
* has finished. 
 
* Now set up psg registers: each one by writing 
* the register number to sc_reg, then immediately the 
* value to write to that data to sc_data 
 
* reg 0,1 determine the period length. 
	move.b	#0,sc_reg * set up register number 
	move.b	#0,sc_data * write value to register 
	move.b	#1,sc_reg 
	move.b	#0,sc_data 
 
* reg 2,3 same as registers 0,1 for channel B. 
	move.b	#2,sc_reg 
	move.b	#0,sc_data 
	move.b	#3,sc_reg 
	move.b	#0,sc_data 
 
* reg 4,5 same as registers 0,1 for channel C. 
	move.b	#4,sc_reg 
	move.b	#0,sc_data 
	move.b	#5,sc_reg 
	move.b	#0,sc_data 
 
* turn all channels off 
	move.b	#7,sc_reg 
	move.b	#$FF,sc_data 
 
* set volume of channel A,B,C to 0. 
	move.b	#8,sc_reg  * volume A 
	move.b	#0,sc_data 
	move.b	#9,sc_reg  * volume B 
	move.b	#0,sc_data 
	move.b	#10,sc_reg * volume C 
	move.b	#0,sc_data 
 
	move.w	d0,sr 
	rts 
 
 
play_snd: 
* Interrupt-driven. 
	movem.l	d0-d1/a0,-(sp) 
	clr.w	d0 
	movea.l	snd_lst,a0 
	move.b	(a0)+,d0 
	move.l	a0,snd_lst 
	add.b	#$80,d0 
	lsl.w	#3,d0 
	lea	snd_tab,a0 
	move.l	0(a0,d0.w),d1 
	move.w	4(a0,d0.w),d0 
	lea	sc_reg,a0 
	movep.l	d1,0(a0) 
	movep.w	d0,0(a0) 
 
	subq.w	#1,snd_len 
	bne	ply_sndx 
	move.w	#19,snd_pty 
	move.l	#no_play,int_vec 
ply_sndx: 
	movem.l	(sp)+,d0-d1/a0 
no_play: 
	rte 
 
 
 
*************************************** 
*    Internal sound lookup table.     * 
*************************************** 
 
	even 
 
snd_tab: 
	dc.w	$80c,$90b,$a09,0,$80c,$90b,$a09,0 
	dc.w	$80d,$908,$a08,0,$80b,$90b,$a0b,0 
	dc.w	$80d,$909,$a05,0,$80c,$90b,$a08,0 
	dc.w	$80d,$909,$a02,0,$80d,$908,$a06,0 
	dc.w	$80c,$90b,$a07,0,$80d,$907,$a07,0 
	dc.w	$80c,$90b,$a06,0,$80c,$90a,$a09,0 
	dc.w	$80b,$90b,$a0a,0,$80c,$90b,$a02,0 
	dc.w	$80c,$90b,$a00,0,$80c,$90a,$a08,0 
 
	dc.w	$80d,$906,$a04,0,$80d,$905,$a05,0 
	dc.w	$80d,$905,$a04,0,$80c,$909,$a09,0 
	dc.w	$80d,$904,$a03,0,$80b,$90b,$a09,0 
	dc.w	$80c,$90a,$a05,0,$80b,$90a,$a0a,0 
	dc.w	$80c,$909,$a08,0,$80b,$90b,$a08,0 
	dc.w	$80c,$90a,$a00,0,$80c,$90a,$a00,0 
	dc.w	$80c,$909,$a07,0,$80b,$90b,$a07,0 
	dc.w	$80c,$909,$a06,0,$80b,$90b,$a06,0 
 
	dc.w	$80b,$90a,$a09,0,$80b,$90b,$a05,0 
	dc.w	$80a,$90a,$a0a,0,$80b,$90b,$a02,0 
	dc.w	$80b,$90a,$a08,0,$80c,$907,$a07,0 
	dc.w	$80c,$908,$a04,0,$80c,$907,$a06,0 
	dc.w	$80b,$909,$a09,0,$80c,$906,$a06,0 
	dc.w	$80a,$90a,$a09,0,$80c,$907,$a03,0 
	dc.w	$80b,$90a,$a05,0,$80b,$909,$a08,0 
	dc.w	$80b,$90a,$a03,0,$80a,$90a,$a08,0 
 
	dc.w	$80b,$90a,$a00,0,$80b,$909,$a07,0 
	dc.w	$80b,$908,$a08,0,$80a,$90a,$a07,0 
	dc.w	$80a,$909,$a09,0,$80c,$901,$a01,0 
	dc.w	$80a,$90a,$a06,0,$80b,$908,$a07,0 
	dc.w	$80a,$90a,$a05,0,$80a,$909,$a08,0 
	dc.w	$80a,$90a,$a02,0,$80a,$90a,$a01,0 
	dc.w	$80a,$90a,$a00,0,$809,$909,$a09,0 
	dc.w	$80a,$908,$a08,0,$80b,$908,$a01,0 
 
	dc.w	$80a,$909,$a06,0,$80b,$907,$a04,0 
	dc.w	$80a,$909,$a05,0,$809,$909,$a08,0 
	dc.w	$80a,$909,$a03,0,$80a,$908,$a06,0 
	dc.w	$80a,$909,$a00,0,$809,$909,$a07,0 
	dc.w	$809,$908,$a08,0,$80a,$908,$a04,0 
	dc.w	$809,$909,$a06,0,$80a,$908,$a01,0 
	dc.w	$809,$909,$a05,0,$809,$908,$a07,0 
	dc.w	$808,$908,$a08,0,$809,$909,$a02,0 
 
	dc.w	$809,$908,$a06,0,$809,$909,$a00,0 
	dc.w	$809,$907,$a07,0,$808,$908,$a07,0 
	dc.w	$809,$907,$a06,0,$809,$908,$a02,0 
	dc.w	$808,$908,$a06,0,$809,$906,$a06,0 
	dc.w	$808,$907,$a07,0,$808,$908,$a04,0 
	dc.w	$808,$907,$a06,0,$808,$908,$a02,0 
	dc.w	$807,$907,$a07,0,$808,$906,$a06,0 
	dc.w	$808,$907,$a04,0,$807,$907,$a06,0 
 
	dc.w	$808,$906,$a05,0,$808,$906,$a04,0 
	dc.w	$807,$906,$a06,0,$807,$907,$a04,0 
	dc.w	$808,$905,$a04,0,$806,$906,$a06,0 
	dc.w	$807,$906,$a04,0,$807,$905,$a05,0 
	dc.w	$806,$906,$a05,0,$806,$906,$a04,0 
	dc.w	$806,$905,$a05,0,$806,$906,$a02,0 
	dc.w	$806,$905,$a04,0,$805,$905,$a05,0 
	dc.w	$806,$905,$a02,0,$805,$905,$a04,0 
 
	dc.w	$805,$904,$a04,0,$805,$905,$a02,0 
	dc.w	$804,$904,$a04,0,$804,$904,$a03,0 
	dc.w	$804,$904,$a02,0,$804,$903,$a03,0 
	dc.w	$803,$903,$a03,0,$803,$903,$a02,0 
	dc.w	$803,$902,$a02,0,$802,$902,$a02,0 
	dc.w	$802,$902,$a01,0,$801,$901,$a01,0 
	dc.w	$802,$901,$a00,0,$801,$901,$a00,0 
	dc.w	$801,$900,$a00,0,$800,$900,$a00,0 
 
	dc.w	$80e,$90d,$a0c,0,$80f,$903,$a00,0 
	dc.w	$80f,$903,$a00,0,$80f,$903,$a00,0 
	dc.w	$80f,$903,$a00,0,$80f,$903,$a00,0 
	dc.w	$80f,$903,$a00,0,$80e,$90d,$a0b,0 
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0 
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0 
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0 
	dc.w	$80e,$90d,$a0a,0,$80e,$90d,$a0a,0 
 
	dc.w	$80e,$90d,$a0a,0,$80e,$90d,$a0a,0 
	dc.w	$80e,$90c,$a0c,0,$80e,$90d,$a00,0 
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0 
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0 
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0 
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0 
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0 
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0 
 
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0 
	dc.w	$80e,$90c,$a0a,0,$80e,$90c,$a0a,0 
	dc.w	$80e,$90c,$a0a,0,$80e,$90c,$a0a,0 
	dc.w	$80d,$90d,$a0c,0,$80d,$90d,$a0c,0 
	dc.w	$80e,$90c,$a09,0,$80e,$90c,$a09,0 
	dc.w	$80e,$90c,$a05,0,$80e,$90c,$a00,0 
	dc.w	$80e,$90c,$a00,0,$80e,$90b,$a0b,0 
	dc.w	$80e,$90b,$a0b,0,$80e,$90b,$a0b,0 
 
	dc.w	$80e,$90b,$a0b,0,$80e,$90b,$a0a,0 
	dc.w	$80e,$90b,$a0a,0,$80e,$90b,$a0a,0 
	dc.w	$80d,$90d,$a0b,0,$80d,$90d,$a0b,0 
	dc.w	$80d,$90d,$a0b,0,$80e,$90b,$a09,0 
	dc.w	$80e,$90b,$a09,0,$80e,$90b,$a09,0 
	dc.w	$80d,$90c,$a0c,0,$80d,$90d,$a0a,0 
	dc.w	$80e,$90b,$a07,0,$80e,$90b,$a00,0 
	dc.w	$80e,$90b,$a00,0,$80d,$90d,$a09,0 
 
	dc.w	$80d,$90d,$a09,0,$80e,$90a,$a09,0 
	dc.w	$80d,$90d,$a08,0,$80d,$90d,$a07,0 
	dc.w	$80d,$90d,$a04,0,$80d,$90d,$a00,0 
	dc.w	$80e,$90a,$a04,0,$80e,$909,$a09,0 
	dc.w	$80e,$909,$a09,0,$80d,$90c,$a0b,0 
	dc.w	$80e,$909,$a08,0,$80e,$909,$a08,0 
	dc.w	$80e,$909,$a07,0,$80e,$908,$a08,0 
	dc.w	$80e,$909,$a01,0,$80c,$90c,$a0c,0 
 
	dc.w	$80d,$90c,$a0a,0,$80e,$908,$a06,0 
	dc.w	$80e,$907,$a07,0,$80e,$908,$a00,0 
	dc.w	$80e,$907,$a05,0,$80e,$906,$a06,0 
	dc.w	$80d,$90c,$a09,0,$80e,$905,$a05,0 
	dc.w	$80e,$904,$a04,0,$80d,$90c,$a08,0 
	dc.w	$80d,$90b,$a0b,0,$80e,$900,$a00,0 
	dc.w	$80d,$90c,$a06,0,$80d,$90c,$a05,0 
	dc.w	$80d,$90c,$a02,0,$80c,$90c,$a0b,0 
 
	dc.w	$80c,$90c,$a0b,0,$80d,$90b,$a0a,0 
	dc.w	$80d,$90b,$a0a,0,$80d,$90b,$a0a,0 
	dc.w	$80d,$90b,$a0a,0,$80c,$90c,$a0a,0 
	dc.w	$80c,$90c,$a0a,0,$80c,$90c,$a0a,0 
	dc.w	$80d,$90b,$a09,0,$80d,$90b,$a09,0 
	dc.w	$80d,$90a,$a0a,0,$80d,$90a,$a0a,0 
	dc.w	$80d,$90a,$a0a,0,$80c,$90c,$a09,0 
	dc.w	$80c,$90c,$a09,0,$80c,$90c,$a09,0 
 
	dc.w	$80d,$90b,$a06,0,$80c,$90b,$a0b,0 
	dc.w	$80c,$90c,$a08,0,$80d,$90b,$a00,0 
	dc.w	$80d,$90b,$a00,0,$80c,$90c,$a07,0 
	dc.w	$80c,$90c,$a06,0,$80c,$90c,$a05,0 
	dc.w	$80c,$90c,$a03,0,$80c,$90c,$a01,0 
	dc.w	$80c,$90b,$a0a,0,$80d,$90a,$a05,0 
	dc.w	$80d,$90a,$a04,0,$80d,$90a,$a02,0 
	dc.w	$80d,$909,$a08,0,$80d,$909,$a08,0 
 
 
 
 
*** sound labels *** 
 
 
mfp:	equ	$FFFA00 
iera:	equ	mfp+$07 
ierb:	equ	mfp+$09 
imra:	equ	mfp+$13 
imrb:	equ	mfp+$15 
mfp_vec:	equ	mfp+$17 
tacr:	equ	mfp+$19 
tadr:	equ	mfp+$1F 
 
int_vec:	equ	$134 
sc_reg:	equ	$FF8800 
sc_data:	equ	$FF8802 
 
 
*************************** 
*   sound flag offsets    * 
*************************** 
 
c_off0:	equ	0 
c_off1:	equ	1 
c_off2:	equ	2 
c_off3:	equ	3 
c_off4:	equ	4 
c_off5:	equ	5 
c_off6:	equ	6 
c_off7:	equ	7 
c_off8:	equ	8 
c_off9:	equ	9 
c_off10:	equ	10 
c_off11:	equ	11 
c_off12:	equ	12 
c_off13:	equ	13 
c_off14:	equ	14 
c_off15:	equ	15 
c_off16:	equ	16 
c_off17:	equ	17 
c_off18:	equ	18 
c_off19:	equ	19 
 
 
 
 
************************* 
* sound flag priorities * 
************************* 
 
	even 
 
spr_tab: 
	dc.w	11,1,2,3,4,5,6,7,9,10 
	dc.w	0,12,8,13,14,15,16,17,18,19 
 
 
* sound data offsets 
 
	even 
 
snd_offs: 
	dc.l	0 
	dc.l	11689 
 
 
snd_lst:	dc.l	0		* sound data pntr 
;; snd_len:	dc.w	0		* sound length 
snd_pty:	dc.w	19		* sound priority 
c_flags:	ds.b	20		* sound flags 
 
