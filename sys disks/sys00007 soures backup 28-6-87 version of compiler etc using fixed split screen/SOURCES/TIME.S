* program to set up time and date on start-up
*
* Copyright (C) 1986 Level 9 Computing
*
 bra timestart
 include driver.s
printchar
 bra driverprintchar

timestart
 lea driverbuffer(pc),a6

 bsr prs
 dc.b cr,"Enter date: (DD MM YY) ",0
 even

 move.b #inputlinedcode,d0
 bsr driver

 move.l a6,a0
 bsr readdecimal
* gives first number in d0.l
* a0.l = pointer to next byte
 move.w d0,-(sp) * preserve day

 bsr skipseparator
 bsr readdecimal
 asl.w #5,d0
 or.w d0,(sp)

 bsr skipseparator
 bsr readdecimal
* want to store year-1980
 sub.w #80,d0
 asl.w #5,d0 * shift into bits 9 - 15
 asl.w #4,d0
 or.w (sp)+,d0

 move.w d0,-(sp)
 move.w #$2b,-(sp)
 trap #1
 addq.l #6,sp

 bsr prs
 dc.b cr,"Enter time: (HH MM)    ",0
 even

 move.b #inputlinedcode,d0
 bsr driver

 move.l a6,a0
 bsr readdecimal
* gives first number in d0.l
* a0.l = pointer to next byte
 asl.w #6,d0 * shift into top 5 bits
 asl.w #5,d0
 move.w d0,-(sp) * preserve hour

 bsr skipseparator

 bsr readdecimal
* gives second number in d0.l
* a0.l = pointer to next byte
 asl.w #5,d0 * shift into bits 5 - 10
 or.w (sp)+,d0
 move.w d0,-(sp) * time
 move.w #$2d,-(sp) * function
 trap #1
 addq.l #6,sp

 bra returntogem

skipseparator
 move.b (a0),d0
 cmp.b #"0",d0
 bcs.s ss1
 cmp.b #"9",d0
 bhi.s ss1
 rts

ss1
 addq.l #1,a0
 bra.s skipseparator
















