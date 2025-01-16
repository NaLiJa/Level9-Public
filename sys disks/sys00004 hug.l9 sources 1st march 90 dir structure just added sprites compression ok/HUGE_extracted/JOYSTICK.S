 ifnd MCStart
 include 'Condit.s'
 endc

 ifne ST

;===============================
* keyboard scanning stuff
* ST.

InitKeyBoard
; clear keyboard table (containts state of all keys) 
; to 128 for each byte (i.e. key released) 
 lea HeroKbdTable,a0 
 move.w #128/4,d0 
CKBTLoop 
 move.l #$80808080,(a0)+ 
 dbra d0,CKBTLoop 
; and set up irq vector used for keyboard and midi packets... 
 lea OSKbd,a0 
 move.l $118,(a0) * save existing irq vector 
 move.l STOS,d0
 cmp.l #1,d0
 bne.s IMNotOldOS
 lea OldOSIRQHeroKbd,a0 
 lea $118,a1 
 move.l a0,(a1) ; set up exception to point to our code 
 
IMNotOldOS
 cmp.l #2,d0
 bne.s IMNotNewOS
 lea NewOSIRQHeroKbd,a0 
 lea $118,a1 
 move.l a0,(a1) ; set up exception to point to our code 
 
IMNotNewOS
 rts

CloseDownKeyboard
* restore keyboard scan interrupt 
 lea $118,a0 
 move.l OSKbd,(a0) 
 rts

;InitKeyboard:
;* called from once-only init.
;
;* call kbdvbase: see P.199 ST internals.
;* returns d0.l pointer to a vector table for IKB routines.
; move.w #34,-(sp)
; trap #14
; addq.l #2,sp
; move.l d0,a1
; move.l $20(a1),a3 * existing kbd routine
; lea OSKbd,a2
; move.l a3,(a2) * set up vector back to OS
; move.l STOs,d0 * which OS are we using?
; cmp.l #1,d0
; bne.s NotOld
; lea OldOSHeroKbd,a2
; move.l a2,$20(a1) * set up vector to point to our code
; rts
;
;NotOld
; rts

;CloseDownKeyboard
;* get vector table...
; move.w #34,-(sp)
; trap #14
; addq.l #2,sp
; move.l d0,a1
; move.l OSKbd,$20(a1)
; rts
;------
OldOSIRQHeroKbd
 movem.l d0-d3/a0-a3/a5,-(sp)
 lea 0,a5
OldOSIHK1
 bsr OldOSHeroKbd
 Move.l $de8(a5),a2
 jsr (a2) * midi handler
 move.l $dec(a5),a2
; jsr HeroKbd * (a2) * kbd handler
 btst #4,$fffffa01
 beq.s OldOSIHK1
 bclr #6,$fffffa11
 movem.l (sp)+,d0-d3/a0-a3/a5
 rte
;---
OldOSHeroKbd
* a0.l is the packet passed from IKBD
* go on to OS routine after doing our stuff.
* For ACIA docs, see P.44 in ST Internals
  lea $db0(a5),a0 * a5.l=0
  lea $fffffc00,a1
  move.l $dd0(a5),a2
  move.b 0(a1),d2
  btst #7,d2 * state of IRQ pins (?)
  beq OldOSHKRet
  btst #0,d2 * Only proceed if the RX buffer is full
  beq.s OldOSHK2
  Movem.l d2/a0-a2,-(a7)
   move.b 2(a1),d0
   movem.l d0-d1/a0,-(sp)

    move.b d0,d1
    and.w #$80,d1 * just keep up/down record
    and.w #$7f,d0
    lea HeroKbdTable,a0
    move.b d1,(a0,d0.w) * write into table.
   movem.l (sp)+,d0-d1/a0
  jsr $fc2894
  movem.l (sp)+,d2/a0-a2
OldOSHK2
  and.b #$20,d2
  beq OldOSHKRet
 move.b 2(a1),d0
 jmp (a2)
OldOSHKRet
 rts

PacketHeader
HeroKbdExit
NoData
 move.l OSKbd,a2
 jmp (a2)
;====================================
NewOSIRQHeroKbd
 movem.l d0-d3/a0-a3/a5,-(sp)
 lea 0,a5
NewOSIHK1
 bsr NewOSHeroKbd
 Move.l $e2e(a5),a2
 jsr (a2) * midi handler
 move.l $e32(a5),a2
; jsr HeroKbd * (a2) * kbd handler
 btst #4,$fffffa01
 beq.s NewOSIHK1
 bclr #6,$fffffa11
 movem.l (sp)+,d0-d3/a0-a3/a5
 rte
;---
NewOSHeroKbd
* a0.l is the packet passed from IKBD
* go on to OS routine after doing our stuff.
* For ACIA docs, see P.44 in ST Internals
  lea $c76(a5),a0 * a5.l=0
  lea $fffffc00,a1
  move.l $e16(a5),a2
  move.b 0(a1),d2
  btst #7,d2 * state of IRQ pins (?)
  beq NewOSHKRet
  btst #0,d2 * Only proceed if the RX buffer is full
  beq.s NewOSHK2
  Movem.l d2/a0-a2,-(a7)
   move.b 2(a1),d0
   movem.l d0-d1/a0,-(sp)

    move.b d0,d1
    and.w #$80,d1 * just keep up/down record
    and.w #$7f,d0
    lea HeroKbdTable,a0
    move.b d1,(a0,d0.w) * write into table.
   movem.l (sp)+,d0-d1/a0
  jsr $fc2a46
  movem.l (sp)+,d2/a0-a2
NewOSHK2
  and.b #$20,d2
  beq NewOSHKRet
 move.b 2(a1),d0
 jmp (a2)
NewOSHKRet
 rts
;---

MCKeyDown
; v1 is scan code. Return v1=0 if up, non-zero if down.
 lea HeroKbdTable,a0
 move.w 2(a4),d0
 move.b (a0,d0.w),d0 * read table.
 eor.b #128,d0 * flip top bit
 move.w d0,2(a4)
 rts
;---
MCSTKeyboardInit
 movem.l a3-a6,-(sp)
  bsr InitKeyBoard
 movem.l (sp)+,a3-a6
 rts
;--
MCSTKeyboardNormal
 movem.l a3-a6,-(sp)
  bsr CloseDownKeyboard
 movem.l (sp)+,a3-a6
 rts


;---
* workspace for this file...
;LastPacketByte dc.b 0
; even

OSKbd ds.l 1

HeroKbdTablePtr

HeroKbdTable
 ds.b 256


 endc * First 200 lines of this file are ST-ONLY




;============================================
* ST Mouse Handler 
* Graeme R. 26/07/88 
* Modified from 'ST Joystick Handlers' 
 
 ifne ST
InitMouse 
 ifne Amiga
  rts
 endc

* Get address of vector table in d0.l 
	Move.w #34,-(sp) 
	Trap #14 
	Addq.l #2,sp 
 
* Save entire Vector table for Acia Interrupts 
	Move.l d0,a0 
	Lea VectorSaveTable-S(a5),a1 
	Move.w #8,d1 * save 8 longs 
MSaveTable 
	Move.l (a0)+,(a1)+ 
	Dbra d1,MSaveTable 
 
* Change Mouse Interrupt Vector to one of my own * 
	Move.l d0,a1 
	Add.l #16,a1		Mouse vector offset 16 (Jstick's 24) 
	Lea MouseHandler-S(a5),a0 
	Move.l a0,(a1) 
 
; change joystick vector to be intercepted by our routine 
 move.l d0,a1 
 add.l #24,a1 
 lea JoystickHandler-S(a5),a0 
 move.l a0,(a1) 
 
; move.l d0,a1 
; add.l #32,a1 
; lea HeroKbd,a0 
; move.l (a1),OSKbd 
; move.l a0,(a1) * set up vector to point to our code 
 
 bsr InitKeyboard 
 
; ask for correct mouse mode 
 lea MouseString-S(a5),a0 * by default, install mouse 
 move.l a0,-(sp) ; address of string to send 
 move.w #1,-(sp) ; length of string to send 
 move.w #25,-(sp) ; code for intelligent send 
 trap #14 
 addq.l #8,sp 
 rts 
 
 
MouseHandler 
* This handler reads packages sent by the Kboard Acia,the package 
* sent when the Mouse interrupt is triggered is: 
* Header.B(lowest 2 bitz are button statii(?)) RelativeX.b RelativeY.b 
* ..the start addr of which is held in a0 
 move.b (a0),d0 
 cmp.b #$f8,d0 
 bcs.s MHEnd 
 cmp.b #$fc,d0 
 bcc MHEnd 
 
 Movem.l d0-d7/a0-a6,-(sp) 
	lea MouseDistances,a1 
 
	Move.b #0,d7 
	Move.b (a0),d0 
	Btst #1,d0 
	Beq MNotFire 
	Bset #Firebutton,d7 
MNotFire 
	Btst #0,d0 
	Beq MNotRightButton 
	Bset #RightButton,d7 
MNotRightButton 
	move.b d7,JoystickStatus 
 
	Move.b 1(a0),d0 
	Beq MNotHoriz 
	Bmi MLeft 
	addq.w #1,(a1) ; increase x distance 
	Bra MNotHoriz 
Mleft 
	subq.w #1,(a1) ; decrease x distance 
MNotHoriz 
	Move.b 2(a0),d0 
	Beq MNotVert 
	Bmi MUp 
	addq.w #1,2(a1) ; increase y distance 
	Bra MNotVert 
MUp 
	subq.w #1,2(a1) ; decrease y distance 
	 
MNotVert 
 Movem.l (sp)+,d0-d7/a0-a6 
 Rts 
 
MHEnd 
* joystick handler (!) 
 cmp.b #$ff,d0 *** 
 bne MHRet 
 move.b 2(a0),d0 ; get joystick status 
 lea JoystickStatus(PC),a0 * cannot use A5 relative 'cause A5 uncertain 
 move.b d0,(a0) 
 lea TrueJoystickStatus(PC),a0 
 move.b d0,(a0) 
MHRet 
 rts 
 
;* probably a keyboard packet. 
;; d0.b is the key scan code, with top bit set if 
;; this scan code was released. 
; movem.l a0-a6,-(sp) 
;  move.b d0,d1 
;  and.b #$80,d1 * just keep up/down record 
;  and.b #$7f,d0 
;  lea HeroKbdTable,a1 
;  move.b d1,(a1,d0.w) * write into table. 
; movem.l (sp)+,a0-a6 
; rts 
;--- 
CloseDownMouseHandler 
 ifne Amiga
  rts
 endc


; close down joystick... 
 lea KBDCloseDownCommandString-S(a5),a0 
 move.l a0,-(sp) ; address of string to send 
 move.w #1,-(sp) ; length of string to send 
 move.w #25,-(sp) ; code for intelligent send 
 trap #14 
 addq.l #8,sp 
 
* Get address of vector table in d0.l 
	Move.w #34,-(sp) 
	Trap #14 
	Addq.l #2,sp 
 
* Restore vectors for OS 
 
	Move.l d0,a0 
	Lea VectorSaveTable-S(a5),a1 
	Move.w #8,d1 * save 8 longs 
MVectorSaveLoop 
	Move.l (a1)+,(a0)+ 
	Dbra d1,MVectorSaveLoop 
 
 bsr CloseDownKeyboard
	Rts 
 endc * ST
;--- 
; ST Joystick handlers 
; M.J.Austin 29/11/87 
 
UpBit equ 0 
DownBit equ 1 
LeftBit equ 2 
RightBit equ 3 
 ifne ST
RightButton equ 6 
FireButton equ 7 
 endc
 
 ifne ST
MCInitJoystick 
  rts

 move.w 2(a4),d0 * what do we want to install? 
 cmp.w #1,d0 
 beq.s MCIJoystick 
 cmp.w #2,d0 
 beq.s MCIMouse 
 clr.w 2(a4) * device not recognized 
 rts 
 
MCIJoystick 
 lea JoystickString-S(a5),a0 * install joystick 
 move.l a0,-(sp) ; address of string to send 
 move.w #1,-(sp) ; length of string to send 
 move.w #25,-(sp) ; code for intelligent send 
 trap #14 
 addq.l #8,sp 
 rts 
 
MCIMouse 
 lea MouseString-S(a5),a0 * install mouse 
 move.l a0,-(sp) ; address of string to send 
 move.w #1,-(sp) ; length of string to send 
 move.w #25,-(sp) ; code for intelligent send 
 trap #14 
 addq.l #8,sp 
 rts 
 
 
; send command to kbd processor 
; It is to start sending the current status on any change 
; in the format: FF 01 status 
; where status= 
; bit 0 north 
; bit 1 south 
; bit 2 west 
; bit 3 east 
; bit 7 button 
 
;--- 
AskForJoystick 
* auto-return mode (where joystick tells us of each change) 
* doesn't appear to work with the mouse enabled, 
* so let's ask for it (data is returned through 
* normal joystick Handler) 
 rts *** 
 
 lea AskForJoystickString-S(a5),a0 
 move.l a0,-(sp) ; address of string to send 
 move.w #2,-(sp) ; length of string to send 
 move.w #25,-(sp) ; code for intelligent send 
 trap #14 
 addq.l #8,sp 
 rts 
;--- 
JoystickHandler 
; **** This is probably not necessary any more, 
; because I had to trap the joystick packets 
; in the mouse handler to make them co-exist 
 ifne Amiga
  rts
 endc

 movem.l d0-d7/a0-a6,-(sp) 
 move.b (a0),d0 
 cmp.b #$ff,d0 
 bne.s JHEnd 
 move.b 2(a0),d0 ; get joystick status 
 lea JoystickStatus(PC),a0 * cannot use A5 relative 'cause A5 uncertain 
 move.b d0,(a0) 
 lea TrueJoystickStatus(PC),a0 
 move.b d0,(a0) 
 
JHEnd 
 movem.l (sp)+,d0-d7/a0-a6 
 RTS 
;--- 
;CloseDownJoystickHandler 
; lea KBDCloseDownCommandString-S(a5),a0 
; move.l a0,-(sp) ; address of string to send 
; move.w #1,-(sp) ; length of string to send 
; move.w #25,-(sp) ; code for intelligent send 
; trap #14 
; addq.l #8,sp 
; rts 
;--- 
MouseString 
 dc.b $08 * relative mouse position from now on 
; dc.b $14 * return joystick movements. 
 dc.b 0 
 even 
 
JoystickString 
 dc.b $14 * return joystick movements 
 dc.b 0 
 even 
 
 
KBDCloseDownCommandString 
 dc.b $1a * joystick off 
 dc.b $08 * relative mode for mouse 
 dc.b 0 
 even 
 
AskForJoystickString 
; dc.b $14 * auto joystick-mode 
 dc.b $16 * what's joystick PPPPlease... 
; dc.b $08 * relative mode for mouse 
; dc.b $0d * read absolute mouse 
 dc.b 0 
 even 
 endc * ST
 
;------- 
