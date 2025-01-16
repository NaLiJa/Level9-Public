* 68000 graphics system. Copyright (C) 1986 Level 9 Computing
*
* 22:23 Sunday 13/7/86 M.J.Austin
*
* GINT.S
* for graphics display program,
* assemble this on it's own
 bra displayloop

graphics equ 1 * can be defined to anything

 include driver.s

displayloop
* small test program to loop through displaying pictures
 lea driverbuffer(pc),a6
 move.b #initdcode,d0
 bsr driver
 bsr loadpictures
 lea driverbuffer(pc),a6
 move.w #502,d0
 bra.s displayloop2
displayloop1
 move.w d0,-(sp) * current picturenumber
 move.b #inputlinedcode,d0
 bsr driver
 cmp.b #"*",(a6)
 beq returntogem
 move.l a6,a0
 bsr readdecimal
 move.w (sp)+,d1
 tst.w d0
 bne.s displayloop2
 move.w d1,d0
 addq.w #1,d0 * display last picture plus one if return pressed
displayloop2
 movem.l d0-d7/a0-a6,-(sp)
 move.w d0,-(sp)
 bsr prs
 dc.b "Displaying picture number: ",0
 even

 move.w (sp)+,d0
 bsr printdecimald0
 movem.l (sp)+,d0-d7/a0-a6

 move.w d0,-(sp)
 bsr gintclearg
 move.w (sp)+,d0
 move.w d0,-(sp)
 bsr runsub
 move.w (sp)+,d0
 bra displayloop1

*---
* ifnd intstart
*printchar
* bra driverprintchar
* endc * intstart
*---

* manifest constants
maxstack equ 512

* now workspace

gintcolour dc.b 0
option dc.b 0
* chgcoltable dc.b 0,0,0,0
reflectflag dc.b 0
 even
scale dc.w 0 * must be dc.w, must be word-aligned
pictureaddress dc.l 0
 even


*
* now register assignments

currentx equr a2
currenty equr a3
gintsp equr a4
gintpc equr a5


loadpictures
 lea loadparameterblock(pc),a6
 bsr printfilename *???
 lea picturestart(pc),a0
 lea pictureaddress(pc),a1
 move.l a0,(a1)
 move.l a0,(a6)
 move.b #loaddcode,d0
 bsr driver
 lea driverbuffer(pc),a6
 rts

printfilename
 move.w #0,d1 * index for printing filename
printfilename1
 move.b $8(a6,d1),(a6)
 bne.s printfilename2
 rts

printfilename2
 move.b #oswrchdcode,d0
 bsr driver
 addq.b #1,d1
 bra.s printfilename1

* ---
gintclearg
 move.b #clgdcode,d0
 bsr driver
gintinit
* called at start of every picture
 lea gintcolour(pc),a0
 move.b #3,(a0)
 lea option(pc),a0
 move.b #$80,(a0)
 lea reflectflag(pc),a0
 move.b #0,(a0)
 move.w #5120,currentx
 move.w currentx,currenty
 bsr sizereset
 lea gintstackbase(pc),gintsp
 rts

* ---
setuppictured0
* set up a picture number for use by the picture drawing
* task when it is restarted
 movem.l d0-d7/a0-a6,-(sp)
 lea pendingpicture,a0
 move.w d0,(a0)
* bsr runsub
 movem.l (sp)+,d0-d7/a0-a6
 rts
*---
pendingpicture
 dc.w 0

gintstart
* if there is a picture number in (pendingpicture).w
* then draw it
* Then (whether or not a picture was drawn), loop,
* doing snoozes repeatedly.
 lea gintdriverbuffer,a6
 move.w pendingpicture,d0
 beq.s gintsnoozeloop * >> mike 10/8/86 was gintstart
 bsr runsub
gintsnoozeloop
 bsr snooze
 bra gintsnoozeloop
*---
runsub
* run subroutine zero, then subroutine d0.w
 clr.l d7 * this is necessary to make pictures work in
* certain circumstances. e.g. in colossal, get killed
* by jumping off southern cliff (s,s,s,s,s,s)
* decline ressurrection, and restart
* The picture goes haywire the first time it is drawn
* the above clr.l fixes it. Could be a latent bug?
* only testing will tell.

 move.w d0,-(sp) * save picture number
 bsr gintinit
 move.w (sp)+,d0 * restore picture number
 bsr findsub
 bne.s runsubret * don't do anything if sub does not exist
 move.w d0,-(sp)
 move.w #0,d0
 bsr absrunsub
 move.w (sp)+,d0
 bsr absrunsub
 move.b #finishpicturedcode,d0
 bra driver

absrunsub
* run subroutine d0.w
 lea runsubstoredsp(pc),a0
 move.l sp,(a0)
 bsr findsub
 bne.s runsubret
* main loop for picture drawing
cont
 move.b (gintpc)+,d7
 bsr.s getinstruction * get address of routine to execute in a0.l
 lea cont(pc),a1
 move.l a1,-(sp)
 move.l a0,-(sp)
* bsr displayinstruction * ?????
runsubret
 rts

* ---
getinstruction
* gett address of routine to execute in a0.l (opcode is d7.b)
* must preserve d7
 clr.w d0
 move.b d7,d0
 and.b #$c0,d0
 cmp.b #$c0,d0
 beq.s getinstruction1
* sdraw,smove,sgosub
 rol.b #3,d0 * note - this does not go through the carry, unlike 6502
 and.b #$6,d0
 bra.s getinstructionindex

getinstruction1
 move.b d7,d0
 and.b #$38,d0
 cmp.b #$38,d0
 beq.s getinstruction2
 lsr.b #2,d0
 add.b #6,d0
 bra.s getinstructionindex

getinstruction2
 move.b d7,d0
 and.b #7,d0
 asl.b #1,d0
 add.b #20,d0

getinstructionindex
* high byte of d0.w is 0
 lea instructiontable(pc),a0
 clr.l d1
 move.w $0(a0,d0),d1
 add.l d1,a0
 rts
*---
instructiontable
it
 dc.w sdraw-it
 dc.w smove-it
 dc.w sgosub-it

 dc.w draw-it
 dc.w move-it
 dc.w icolour-it
 dc.w size-it
 dc.w gintfill-it
 dc.w gosub-it
 dc.w reflect-it
    
 dc.w notimp-it * duplicate
 dc.w gintchgcol-it
 dc.w notimp-it
 dc.w amove-it
 dc.w opt-it
 dc.w restorescale-it
 dc.w notimp-it
 dc.w return-it
*---
notimp
* not implemented
 bsr prs
 dc.b cr,"not implemented: ",0
 even

displayinstruction
 movem.l d0-d7/a0-a6,-(sp)
 move.l gintpc,a0
 bsr hexlonga0
 move.b #" ",(a6)
 move.b #oswrchdcode,d0
 bsr driver
 move.b $-1(gintpc),d0
 bsr hexbyted0
 move.b #27,(a6) * home cursor
 move.b #oswrchdcode,d0
 bsr driver
 move.b #"H",(a6)
 move.b #oswrchdcode,d0
 bsr driver
diwaitkey
 move.b #osrdchdcode,d0
 bsr driver
 move.b (a6),d0
 beq.s diwaitkey
 cmp.b #cr,d0
 bne.s diret
 dc.w $4afa
diret
 movem.l (sp)+,d0-d7/a0-a6
 rts
*---
findsub
* given d0.w = picture number
* return z if found
* and gintpc.l = start of code in that subroutine
* must preserve d0
 move.w d0,d1
 asl.w #4,d1 * top four bits of d1 are low 4 bits of number looking for
 move.w d1,d2
 lsr.w #8,d2 * d2.b is top 4 bits of number we are looking for
 move.l pictureaddress(pc),gintpc
findsubloop
 move.b (gintpc)+,d3
 bmi.s notfound
 cmp.b d2,d3
 bne.s findsubadd
 move.b (gintpc)+,d3
 and.b #$f0,d3
 cmp.b d1,d3
 bne.s findsubaddsub
 addq.l #1,gintpc * move to start of picture code
 move.b #0,d1 * found
 rts

findsubaddsub
 subq.l #1,gintpc
findsubadd
 clr.l d3
 move.b (gintpc)+,d3
 and.b #$0f,d3
 move.b (gintpc),d4
 move.b d4,d5
 or.b d3,d5
 beq.s notfound
* d3.l= high length, d4.b=low length of this picture
 asl.w #8,d3
 or.b d4,d3
* d3.w = length
 subq.l #2,gintpc
 add.l d3,gintpc
 bra.s findsubloop

notfound
 move.b #$ff,d1
 rts
*---
* now generally used subroutines 
mult
* d0.w (result) := d1.b (was X on 6502) x d2.b (was A in 6502)
 move.b d1,d0
 clr.w d1     * clear high byte of d1.w
 move.b d0,d1 
 bra.s minus
* mult1
* d0.w (result) := d1.w (was result.w in 6502) x d2.b (was A on 6502)

smult
* sign extend d1.b (was X on 6502)
* then do d1.w x d2.b (was A on 6502)
 ext.w d1 * sign extend TO word size
* drop through to minus

mult1
* generate d0.w = d1.w (was scratch1 on 6502) * d2.b (was A on 6502)
minus
mult2
 move.w #0,d0 * zero result
 move.b #8,d3 * was Y on 6502
multloop
 asr.b #1,d2 ( was A on 6502)
 bcc.s multshift
* skip2
 add.w d1,d0 * add.w scratch1,result 
*skip1
multshift
 beq.s shiftret
 asl.w #1,d1 * was scratch1 on 6502
 subq.b #1,d3 * was Y on 6502
 bne.s multloop
shiftret
 rts
*---
amove
 move.b (gintpc)+,d2
 move.b #$40,d1
 bsr mult
 move.w d0,currentx
 move.b (gintpc)+,d2
 move.b #$40,d1
 bsr mult
 move.w d0,currenty
 rts
*---
getxy1
* d7 is opcode
* return d5,d6 as x,y
* first get x
 move.b d7,d5
 asl.b #2,d5 * shift x so sign bit is in bit 7
 asr.b #5,d5 * and shift it down, doing sign extension at the same time
* now get y
 move.b d7,d6
 asl.b #5,d6
 asr.b #3,d6
 bsr.s reflectx
 bra.s reflecty
*---
getxy2
 move.b (gintpc)+,d4 * get byte two of opcode
 move.b d7,d5
 asl.w #8,d5 * lower 3 bits of opcode has top bits of x
 move.b d4,d5
 asr.w #3,d5 * top bit of x is now in top bit of d0.b
 asr.b #2,d5 * x is 6 bits, so sign-extend and shift down

 move.b d4,d6
 asl.b #3,d6 * y is 5 bits, so shift up
 asr.b #1,d6 * and back again, but now it is sign-extended

 bsr reflectx
 bra.s reflecty
*---
reflect
 btst #2,d7
 beq.s reflect1
* reverse reflection bits
 and.b #3,d7
 move.b reflectflag(pc),d0
 eor.b d0,d7
reflect1
 lea reflectflag(pc),a0
 move.b d7,(a0)
 rts
*---
reflectx
* reflect d5.b according to reflection bits
 lea reflectflag(pc),a0
 btst #1,(a0)
 beq.s reflectxret
 neg.b d5
reflectxret
 rts
*---
reflecty
* reflect d6.b accordiing to reflection bits
 lea reflectflag(pc),a0
 btst #0,(a0)
 beq.s reflectyret
 neg.b d6
reflectyret
 rts
*---
newxy
* convert d5.b (x), d6.b (y) to current scaling
* and change the current position ( gives currentx,y)
 move.b d5,d1
 bsr.s offset * returns d0.w as offset in internal co-ords
 add.w d0,currentx * currentx is a register

 move.b d6,d1
 bsr.s offset
 add.w d0,currenty
 rts
*---
offset
* given d1.b as offset given by instruction
* return d0.w as result
 move.b scale(pc),d2 * was A on 6502
 bsr smult
offset1
 and.w #$fff8,d0
 rts
*---
sdraw
 bsr getxy1
 bra gintline
*---
smove
 bsr getxy1
 bra.s newxy
*---
sgosub
 tst.w d0
 move.b d7,d0
 and.b #$3f,d0
 bra gosubd0
*---
draw
 bsr getxy2
 bra gintline
*---
move
 bsr getxy2
 bra.s newxy
*---
icolour
 and.b #3,d7
 lea gintcolour(pc),a0
 move.b d7,(a0)
 rts
*----
opt
 move.b (gintpc)+,d0
 beq.s optend
 and.b #3,d0
 or.b #$80,d0
optend
 lea option(pc),a0
 move.b d0,(a0)
 rts
*---
size
 and.b #7,d7
* d7.b=size change
 beq.s sizereset
 lea sizetable-1(pc),a0
 move.b $0(a0,d7),d2
 move.b scale(pc),d1
 bsr mult
* now divide by 8
* d0.w = result
 asr.w #3,d0 * including sign-extension
* limit scale to 255 ?
 cmp.w #$100,d0
 bcs.s sizeend * unsigned <
 lea scale(pc),a0
 move.b #255,(a0)
 rts
sizeend
 lea scale(pc),a0
 move.b d0,(a0)
 rts
sizereset
 move.b #128,d0
 bra.s sizeend
*---
sizetable
 dc.b 2,4,6,7,9,12,16
 even
*---
restorescale
 lea gintstackbase(pc),a0
 cmp.l a0,gintsp
 beq.s restorescaleret
 lea scale(pc),a0
 move.w $-2(gintsp),(a0)
restorescaleret
 rts
*---
gosub
 move.b d7,d0
 and.b #7,d0
 asl.w #8,d0 * d0.w is now high-byte of subr to call
 move.b (gintpc)+,d0
gosubd0
* call subroutine d0.w
 move.l gintpc,(gintsp) * preserve gintpc
 bsr findsub
 bne.s gosubret * not found
 move.l gintsp,a0
 lea gintstackbase(pc),a1
 sub.l a1,a0
 cmp.l #maxstack,a0
 bhi gosubret
* ok, so skip over return value, and push size value
 addq.l #4,gintsp
 move.w scale(pc),(gintsp)+
gosubret
 rts
*---
return
* gintsp points to next free entry
* is there anything on the stack to pop off ?
 lea gintstackbase(pc),a0
 cmp.l a0,gintsp
 beq.s returnerror
 lea scale(pc),a0
 move.w -(gintsp),(a0) * scale
 move.l -(gintsp),gintpc
 rts
returnerror
* no return address, so drop out of absrunsub
 move.l (sp)+,d0
 rts
*---
gintline
 move.w currentx,$2(a6)
 move.w currenty,$4(a6)
 bsr newxy
 move.w currentx,$6(a6)
 move.w currenty,$8(a6)
 move.b gintcolour(pc),(a6)
 move.b option(pc),$1(a6)
 move.b #linedcode,d0
 bra driver
* ---
displayxy
 movem.l d0-d7/a0-a6,-(sp)
 clr.l d0
 move.w currentx,d0
 bsr printdecimald0
 move.b #" ",(a6)
 move.b #oswrchdcode,d0
 bsr driver
 clr.l d0
 move.w currenty,d0
 bsr printdecimald0
 move.b #" ",(a6)
 move.b #oswrchdcode,d0
 bsr driver
 movem.l (sp)+,d0-d7/a0-a6
 rts
*---
gintfill
 and.b #7,d7
 beq.s filla
 and.b #3,d7
 bra.s fillb
filla
 move.b gintcolour(pc),d7
fillb
 move.b d7,(a6)
 move.b option(pc),$1(a6)
 move.w currentx,$2(a6)
 move.w currenty,$4(a6)
 move.b #filldcode,d0
 bra driver
*---
gintchgcol
 move.b (gintpc)+,d0
 move.b d0,d1
 lsr.b #3,d0
 move.b d0,(a6)
 and.b #7,d1
 move.b d1,$1(a6)
 move.b #chgcoldcode,d0
 bra driver
*---

* experimental program for playing about with st graphics
* bra graphics
* include driver.s
*
*graphics
* lea driverbuffer(pc),a6
* prs menumessage
*graphics1
* move.b #osrdchdcode,d0
* bsr driver
* move.b (a6),d0
* tst.b d0
* beq.s graphics1
* cmp.b #"0",d0
* beq quit
* cmp.b #"1",d0
*beq.s fillarea
*cmp.b #"2",d0
* beq.s changebyte
* bra.s graphics
*
*getnumberd0
* move.b #inputlinedcode,d0
* bsr driver
* move.b (a6),d0
* cmp.b #"*",d0
* beq.s graphics
* cmp.b #"0",d0
* bcs.s getnumberd0
* cmp.b #"9",d0
* bhi.s getnumberd0
* move.l a6,a0
* bra readdecimal
*8
*changebyte
* prs menumessage
* prs addressmessage
* bsr.s getnumberd0
* move.l d0,-(sp)
* prs valuemessage
* bsr getnumberd0
* move.l (sp)+,a0
* move.b d0,(a0)
* bra changebyte

*fillarea
* prs addressmessage
* bsr getnumberd0
* cmp.l #$10000,d0
* blt.s fillarea
* value returned in d0.l
* move.l d0,a0
* move.b #0,d0
* move.w #1000,d1 * area to fill
*fillarea1
* move.b d0,(a0)+
* addq.b #1,d0
* subq.w #1,d1
* tst.w d1
* bne.s fillarea1
* bra graphics
*2
*quit
* move.b #returntoosdcode,d0
* bsr driver
* bra graphics
*
*printchar
* bra absprintchar

menumessage
 dc.b 27,'H','graphics experimentor',cr
 dc.b ' 0 .. quit',cr
 dc.b ' 1 .. fill area of memory with pattern 0,1,2...255 etc.',cr
 dc.b ' 2 .. change single byte',cr
 dc.b cr
 dc.b ' Your choice: ',0

addressmessage
 dc.b 'address: ',0

valuemessage
 dc.b 'value: ',0

 even
loadparameterblock
 dc.l 0
 dc.l 0
 dc.b "picture.dat",0

 even
runsubstoredsp
 dc.l 0

gintstackbase
 ds.b maxstack
 even

gintdriverbuffer
 ds.b 128
 even

picturestart
* this is where the picture data will be loaded
* ( if int not present )














