; MT.S: multi-tasking kernel for AA 
; 
; M.J.Austin Nov 1988 
; 
; Copyright (C) 1988 Level 9 Computing 
; 
 
;============= 
;killmultitasking 
;* is multi-tasking running? 
; move.l osvblhandler(pc),d0 
; beq.s closenotasks 
; move.l d0,$70 ; restore os irq vector 
;closenotasks 
; move.l oshblhandler(pc),d0 
; beq.s closenosplit 
; move.l d0,$68 ; restore fast vector 
;closenosplit 
;* all split screens disabled (if they were running) 
; move.b screenresolution,d0 
; cmp.b #hires,d0 
; beq.s closedownhires ; changing to med res from lowres reboots! 
;* Now set medium resolution, 
;* so OS will print 80 column text correctly 
; move.w #1,-(sp) ; medium resolution 
; move.l #-1,-(sp) ; retain physical base 
; move.l #-1,-(sp) ; retail logical base 
;* move.w #5,-(sp) ; set screen 
; call_ebios _setscreen 
; add.l #12,sp 
; 
;closedownhires 
; lea defaultcolours,a0 
; bra setuppalettea0 
*------ 
numswaps 
 dc.w 0 ; ?????? 
 even ;????? 
*--- 
;resetginttask 
;	add.w	#1,suspendtaskswap 
; lea gintstacktop(pc),a0 
; 
; lea gintstart(pc),a1 
; move.l a1,-(a0) 
; move.w sr,-(a0) 
; lea irqswaptaskend(pc),a1 
; move.l a1,-(a0) ; return address from ist1 
; 
; movem.l d0-d7/a0-a6,-(a0) ; dummy stack values 
; lea taskstackptr,a1 
; move.l a0,(a1) 
;	move.b	#1,drivergraphicsmode 
;	bsr	hidepointer 
;	bsr	showpointer 
;	bsr	scroll_itnow 
; subq.w #1,suspendtaskswap 
;	rts 
*--- 
setsupervisormode 
 ifne ST

 clr.l -(sp) 
 call_bdos _super 
 add.l #6,sp 
* and check if in supervisor mode 
 move.w sr,d0 
 and.w #$2000,d0 
 beq.s setsupervisormode ; NO! ;+@%*^%* operating system! 
* d0 = old supervisor stack (See P.113 ST Internals for details) 
 endc * st only
 rts 
;----- 
;initialisetasks 
;* set up stack values for tasks 
;* the task for the program which called initdcode  
;* is automatically set up, so ignore it at present 
;*  push on a ret address on to fire up the gint task 
;*  fake a status word as if from an exception vector 
;* first, put system permamently into supervisor mode 
; bsr.s setsupervisormode 
; bsr resetginttask 
* now set up the interrupt vector 
* it doesn't matter if interrupts occur during the 
* following bit of code .... 
* now set up MY VBL interrupt handler routine 
; tst.l osvblhandler 
; bne.s vblalreadysetup 
; move.l $70,d0			; address of OS routine 
; lea StartOfDriver,a1 
; cmp.l a1,d0 
; bcc.s vblsetup2 
;* already within the driver 
;* is our record of the osvblhandler ok? 
; move.l osvblhandler,d1 
; cmp.l a1,d1 
; bcs.s vblAlreadySetup * within the os ( I think ) 
;* oh dear! 
; lea NullVBL,a0 
; move.l a0,d0 * set osvblhandler to just do an rte - for safety 
; 
;vblsetup2 
; lea osvblhandler,a0 
; move.l d0,(a0) 
; 
; lea irqvblhandler,a0 
; move.l a0,$70			; ... and enable my routine 
;vblalreadysetup 
; rts 
; 
;NullVBL 
;* security code only 
; rte 
*--- 
snoozeend 
 move.w (sp)+,d0 
snoozeret 
 rts 
*--- 
snooze 
; move.w d0,-(sp) 
; move.b snoozesinceswap(pc),d0 
; bne.s snoozeend 
; move.w (sp)+,d0 
 
; move.l a0,-(sp) 
; lea snoozesinceswap,a0 
; move.b #1,(a0) ; prevent further snoozes in this time slot 
; move.l (sp)+,a0 
 
 move.w sr,-(sp) ; simulate a irq 
 bsr.s ist1 
* and remove the sr value 
 move.w (sp)+,sr 
 rts 
 
irqswaptaskend 
 move.l osvblhandler,-(sp) 
 rts 
*--- 
ist1 
* can't interrupt the OS ;(because it does all sorts of terrible 
* things - like non-reentrant code etc.) 
; move.w sr,-(sp) ******** 
 
; move.w sr,-(sp) 
; tst.l 4(sp) 
; bpl.s istOk 
; move.w (sp)+,sr 
; rts 
; 
;istOk 
; move.w (sp)+,sr 
 
 
 movem.l d0-d7/a0-a6,-(sp) ; from task just finished 
; move.b drivergraphicsmode,d0 
; beq.s istnoswap ; false, so in text mode, so don't do task swapping 
 tst.w	suspendtaskswap 
 bne.s	istnoswap 
 
 lea SuspendTaskSwap,a0 
 move.w #1,(a0) * prevent re-entrance of code which changes 
; task blocks directly... 
 move.l CurrentTaskMTCBOffset,d0 
 lea MTCB,a0 
 add.l d0,a0 
 move.l sp,(a0) * save stack ptr. 
 
 move.l NextTaskMTCBOffset,d0 
 lea CurrentTaskMTCBOffset,a1 
 move.l d0,(a1) * set up new currenttask ptr offset 
 lea MTCB,a1 
 add.l d0,a1 
 move.l (a1),d0 
* and now do the task swap !!!! 
 move.l d0,sp 
 
 lea SuspendTaskSwap,a0 
 move.w #0,(a0) * ok to interrupt again, (if you must)... 
 
istnoswap 
 movem.l (sp)+,d0-d7/a0-a6 ; restore reggies (for task to start) 
; move.w (sp)+,sr ******* 
istret 
 rts 
*--- 
MCInitialiseTask 
* spawn a new task with control block at MTCB+v1.w 
* with stack starting at HeroStack-v2.w 
* It should start executing at (AcodeFNS+v3) 
 lea HeroStack-S(A5),a0 
 clr.l d0 
 move.w 4(a4),d0 * v2 
 sub.l d0,a0 
 
* and set up dummy stack entry 
 move.l AcodeFns-S(A5),a1 
 move.w 6(a4),d0 * v3 
 add.l d0,a1 * => a1=start address of new task. 
 move.l a1,-(a0) 
 move.w sr,-(a0) 
 lea irqswaptaskend(pc),a1 
 move.l a1,-(a0) ; return address from ist1 
; move.w sr,-(a0) ************* 
 movem.l d0-d7/a0-a6,-(a0) ; dummy stack values 
 
* and set up MTCB ptr to stack entries. 
 lea MTCB-S(A5),a1 
 clr.l d0 
 move.w 2(a4),d0 * v1 
 add.l d0,a1 
 move.l a0,(a1) * write in stack ptr. 
 rts 
;------ 
