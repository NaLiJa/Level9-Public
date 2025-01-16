; ST Joystick handlers
; M.J.Austin 29/11/87

UpBit equ 0
DownBit equ 1
LeftBit equ 2
RightBit equ 3
FireButton equ 7

InitJoystick
; get address of vector table in d0.l
 move.w #34,-(sp)
 trap #14
 addq.l #2,sp

; save current joystick table
 move.l d0,a0
 lea VectorSaveTable,a1
 move.w #8,d1 * save 8 longs
SaveTable
 move.l (a0)+,(a1)+
 dbra d1,SaveTable

; change joystick vector to be intercepted by our routine
 move.l d0,a1
 add.l #24,a1
 lea JoystickHandler,a0
 move.l a0,(a1)
 lea WorkSpace,a0

;; Save Current Status of IKBD ; see p.76/77 of ST Internals
; lea KBDSend8C,a0
; move.l a0,-(sp) ; address of string to send
; move.w #1,-(sp) ; length of string to send
; move.w #25,-(sp) ; code for intelligent send
; trap #14
; addq.l #8,sp
;; and save 2 bytes of status info
; lea KBDSave1,a1
; move.w (a0),(a1) **********

; send command to kbd processor
; It is to start sending the current status on any change
; in the format: FF 01 status
; where status=
; bit 0 north
; bit 1 south
; bit 2 west
; bit 3 east
; bit 7 button

 lea KBDCommandString,a0
 move.l a0,-(sp) ; address of string to send
 move.w #1,-(sp) ; length of string to send
 move.w #25,-(sp) ; code for intelligent send
 trap #14
 addq.l #8,sp
 rts
;---
JoystickHandler
 movem.l d0-d7/a0-a6,-(sp)
 move.b (a0),d0
 cmp.b #$ff,d0
 bne.s JHEnd
 move.b 2(a0),d0 ; get joystick status
 lea JoystickStatus,a0
 move.b d0,(a0)

JHEnd
 movem.l (sp)+,d0-d7/a0-a6
 RTS
;---
CloseDownJoystickHandler
 lea KBDCloseDownCommandString,a0
 move.l a0,-(sp) ; address of string to send
 move.w #1,-(sp) ; length of string to send
 move.w #25,-(sp) ; code for intelligent send
 trap #14
 addq.l #8,sp



; get address of vector table in d0.l
 move.w #34,-(sp)
 trap #14
 addq.l #2,sp

; restore vectors for operating system
 move.l d0,a0
 lea VectorSaveTable,a1
 move.w #8,d1 * save 8 longs
VectorSaveLoop
 move.l (a1)+,(a0)+
 dbra d1,VectorSaveLoop
 rts
;---
KBDCommandString
 dc.b $14
 even

KBDCloseDownCommandString
 dc.b $1a * joystick off
 dc.b $08 * relative mode for mouse
 dc.b 0
 even
;-------
