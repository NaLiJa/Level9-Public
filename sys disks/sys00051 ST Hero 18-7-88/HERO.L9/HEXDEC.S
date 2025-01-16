* HexDec - Hex, decimal Io routines
*
* Copyright (C) 1988 Level 9 COmputing
*
*---

readhex
* given a hex string typed by the user at (a0),
* return d0.l = the equivalent value
* and a0.l = position after number
 movem.l d1-d7/a1-a6,-(sp)
 bsr absreadhex
 movem.l (sp)+,d1-d7/a1-a6
 rts
*---

absreadhex
 clr.l d0
readhex1
 move.l d0,-(sp)
 bsr.s readhexdigit
 move.l (sp)+,d0
 cmp.b #$ff,d1 ; finished ?
 beq.s readhexret
 asl.l #4,d0 ; shift existing digits along to make room
 add.b d1,d0
 bra.s readhex1

readhexdigit
* return in d1.b the value of the hex digit at (a0)
* or #$FF if none there
 move.b #$ff,d1 ; error return
 move.b (a0)+,d0
 bsr converttouppercase
 cmp.b #"0",d0
 bcs.s rhdret ; unsigned <, so return
 cmp.b #"9",d0
 bls.s rhdnumber ; unsigned <=
 cmp.b #"A",d0
 bcs.s rhdret ; unsigned <, so return
* got A-F
 sub.b #"A"-10,d0
 move.b d0,d1
readhexret
rhdret
 rts
rhdnumber
* got 0 - 9
 sub.b #"0",d0
 move.b d0,d1
 rts

*---

hexlonga0
 move.l a0,a2 ; preserve a0
 move.l a0,d0 ; transfer to data for shifts
 lsr.l #4,d0
 lsr.l #4,d0
 lsr.l #4,d0
 lsr.l #4,d0
 move.l d0,a0 ; and back again
 bsr hexworda0
 move.l a2,a0
* drop through to hexworda0

hexworda0
* print hex word in a0. a0 preserved, d0 corrupted
 move.w a0,d0
 lsr.w #8,d0
 bsr hexbyted0
 move.w a0,d0
* drop through to hexbyted0

hexbyted0
* print hex byte d0. d0 corrupted, other registers preserved
 move.b d0,-(sp)
 lsr.w #4,d0
 bsr printhexdigit
 move.b (sp)+,d0
 and #$0f,d0
* branch through to printhexdigit
 
printhexdigit
*given d0.b as a single digit, print it as hex
 movem.l d0-d7/a0-a6,-(sp)
 bsr absprinthexdigit
 movem.l (sp)+,d0-d7/a0-a6
 rts

absprinthexdigit
 and.l #$0000000f,d0 ; remove hi-order rubbish
 cmp.b #10,d0
 blt.s phdnum
 add #"A"-10,d0
 bra oswrch
phdnum
 add #"0",d0
 bra oswrch

;printdecimald0
;* print d0.l as a decimal number,
;* suppressing leading zeros
; tst.l d0
; bne.s printdec1
; move.b #"0",d0
; bra printchar
;printdec1
;* non-zero number to print
; move.l d0,d2 ; store number somewhere more sensible
; lea numbertable(pc),a1
; move.b #0,d3 ; reset flag
;printdec1a
;* find the current digit value
; move.l (a1)+,d1 ; get value
; beq.s printdecret ; no more digits possible
;* given d2=remainder of number, d1=value of current digit,
;* find value
; move.b #"0",d0
;printdec2
; sub.l d1,d2
; bcs.s printdec3
; addq.b #1,d0
; move.b #1,d3 ; set leading-zeros flag
; bra.s printdec2
;printdec3
; add.l d1,d2
; tst.b d3 ; flag set yet ?
; beq.s printdec1a
; bsr printchar ; oswrch ; printchar
; bra.s printdec1a 
;
;numbertable
; dc.l 1000000000
; dc.l 100000000
; dc.l 10000000
; dc.l 1000000
; dc.l 100000
; dc.l 10000
; dc.l 1000
; dc.l 100
; dc.l 10
; dc.l 1
; dc.l 0

*-----
* TextIO - Misc Text I/O routines
*
* Copyright(C) 1988 Level 9 Computing
*
* --------

converttouppercase
* convert character in d0.b to upper case
 cmp.b #"a",d0
 bcs.s ctucret ; unsigned <
 cmp.b #"z",d0
 bhi.s ctucret ; unsigned >
 sub.b #"a"-"A",d0
ctucret
 rts

converttolowercase
* convert character in d0.b to lower case
 cmp.b #"A",d0
 bcs.s ctlcret ; unsinged <
 cmp.b #"Z",d0
 bhi.s ctlcret ; unsigned >
 add.b #"a"-"A",d0
ctlcret
 rts

*---
readdecret
 rts

readdecimal
* given a decimal number as an ascii string at a0, return
* its value in d0.l
* and a0.l = charcter after the number
 clr.l d0
readdec1
 clr.w d1
 move.b (a0)+,d1
 cmp.b #"0",d1 ; could it be part of a number (stop if not)
 bcs.s readdecend
 cmp.b #"9"+1,d1
 bcc.s readdecend
 sub.b #"0",d1
* multiply existing number by 10 ( 32 bit so can't use mulu d2,d0)
 asl.l #1,d0 ; gives times 2
 move.l d0,-(sp)
 asl.l #2,d0 ; gives times 8
 add.l (sp)+,d0
 add.l d1,d0   ; and add in the new trailing digit
 bra.s readdec1
readdecend
 subq.l #1,a0
 rts
*---
*---
isd0alphanumeric
* return d0.b = 0 if not
 cmp.b #"0",d0
 bcs.s idanfail ; unsigned <
 cmp.b #"9",d0
 bls.s idanret ; unsigned <=
 cmp.b #"A",d0
 bcs.s idanfail ; unsigned <
* do "quick-and-dirty" lower-upper case conversion
 and.b #$DF,d0
 cmp.b #"Z",d0
 bhi.s idanfail ; unsigned >
idanret
 tst.b d0 ; non-zero
 rts
idanfail
 clr.b d0
 rts
*--- 

 
 even
prs
* print string following call, terminated by 0
 move.l a0,-(sp)
 move.l d0,-(sp)
 move.l $8(sp),a0 ; get return address = start address of string
prs1
 move.b (a0)+,d0 ; (a6)
 beq.s prsend
* move.b #oswrchdcode,d0
 bsr oswrch ; driver
 bra prs1
prsend
* make sure it is an even return address
 move.w a0,d0
 btst #0,d0
 beq.s prsend1
 addq.l #1,a0
prsend1
 move.l a0,$8(sp)
 move.l (sp)+,d0
 move.l (sp)+,a0
 rts
*---
