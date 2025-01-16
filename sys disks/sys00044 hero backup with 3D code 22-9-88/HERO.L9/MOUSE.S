* ST Mouse Handler
* Graeme R. 26/07/88
* Modified from 'ST Joystick Handlers' by
* M.J.Austin 29/11/87

InitMouse

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


	Lea MKBDCommandString-S(a5),a0
	Move.l a0,-(sp) ; address of string to send
	Move.w #1,-(sp) ; length of string to send
	Move.w #25,-(sp) ; code for intelligent send
	Trap #14
	Addq.l #8,sp

	Rts

MouseHandler

* This handler reads packages sent by the Kboard Acia,the package
* sent when the Mouse interrupt is triggered is:
* Header.B(lowest 2 bitz are button statii(?)) RelativeX.b RelativeY.b
* ..the start addr of which is held in a0

 Movem.l d0-d7/a0-a6,-(sp)

	Move.b #0,d7

	Move.b (a0),d0

	Btst #1,d0
	Beq MNotFire
	Bset #Firebutton,d7
MNotFire
	Move.b 1(a0),d0
	Beq MNotHoriz
	Bmi MLeft
	Bset #RightBit,d7
	Bra MNotHoriz
Mleft
	Bset #LeftBit,d7
MNotHoriz
	Move.b 2(a0),d0
	Beq MNotVert
	Bmi MUp
	Bset #DownBit,d7
	Bra MNotVert
MUp
	Bset #UpBit,d7
	
MNotVert
	
	Lea JoystickStatus,a0	* Not actually Joystick *
	Move.b d7,(a0)		* But it's easier *


 Movem.l (sp)+,d0-d7/a0-a6

 Rts



CloseDownMouseHandler

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
	
	Rts


MKBDCommandString
 dc.b $08

 even

