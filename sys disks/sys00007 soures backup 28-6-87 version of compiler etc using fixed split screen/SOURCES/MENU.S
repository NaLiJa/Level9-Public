* Menu program for adventures on Atari ST
*
* M.J.Austin started 22/8/86
* last change: 3/11/86
*
* Copyright (C) 1986 Level 9 Computing
*
*
* When building a RELEASE DISK -
*
* Don't forget that the menu program must be called MENU.PRG
* and must be both in root and AUTO directories
* put games on the disk in trilogy order
*
* Don't forget to update the checksum value in the interpreter
* (right at the start!). The easiest way to do this is to
* set it to 0, assemble and run, restore(cr)c(cr)
* then calculate 0-the value printed, and enter it as
* the checksum value
*
* make sure there are no occurences of opt d+
* in any of the sources - it would make hackers
* lives TOO easy!!
*---
*
* This code does not entirely follow the driver convention
* - naughty, naughty! But it did make it lots easier to write!
* ( and probably gave a better effect )
startmenu
graphics set startmenu
 bra menustart

 include driver.s
 include int.s

menustart
* set up medium rez if using a colour monitor
 call_ebios _getrez
 addq.l #2,sp
* d0.b = 2 for hires
 cmp.b #2,d0
 beq.s menustartnoswitch
 move.w #1,-(sp) * medium resolution
 move.l #-1,-(sp) * retain physical base
 move.l #-1,-(sp) * retain logical base
 call_ebios _setscreen
 add.l #12,sp
menustartnoswitch

 bsr setsupervisormode

 lea driverbuffer(pc),a6
 lea filenamelist,a5
 move.b #0,d7 * number of files found

 dc.w $A00A * Line A function to hide mouse
 
* and set up palette - we want yellow text on black background
 bsr setuppalette

menu
 lea scrolledlines,a0
 clr.b (a0)
 lea filenamelist,a5
 clr.b d7 * number of files found
 bsr prs
 dc.b 27,'E' * cursor home
 dc.b 27,'J' * clear screen below cursor
 dc.b cr,cr
 dc.b "                             Level 9 Adventures",cr,cr
 dc.b "                    "
 dc.b "Copyright (C) 1986 Level 9 Computing",cr,cr,cr,cr,cr,0
 even

* look in current directory for interesting sub-directories - 
* i.e. those which match with directoryname
 lea fileblock(pc),a0
 move.l a0,-(sp)
 move.w #$1a,-(sp) * function number setdta
 trap #1

 addq.l #6,sp
 move.w #$10,-(sp) * attribute byte - find sub-directories
 lea directoryname(pc),a0
 move.l a0,-(sp)
 move.w #$4e,-(sp) * function number sfirst
 trap #1
 addq.l #8,sp

 tst d0 * file found ?
 bne nofiles

menuprintfname
* filename is at $1e(fileblock)
* first, add it to the list of names
* a5.l=current position in list

 bsr prs
 dc.b "                               ",0
 even

 addq.b #1,d7 * number of files found so far
 clr.l d0
 move.b d7,(a6)
 add.b #"1"-1,(a6)
 move.b #oswrchdcode,d0
 jsr driver
 bsr prs
 dc.b " .. ",0
 even

 clr.b d3 * flag which is set when a dot has been encountered -
* designed to prevent printing .L9 extension after filename

 clr.w d2 * move.w #0,d2
 lea fileblock(pc),a0
menuprintfname1
 move.b $1e(a0,d2),d1
 move.b d1,(a5)+
 beq.s nextfile

 cmp.b #'.',d1
 bne.s mpfnotdot
 move.b #1,d3 * set flag to prevent printing rest of name
mpfnotdot
 tst.b d3 * in filename extension?
 bne.s mpfnoprint

 move.b d1,(a6)
 move.b #oswrchdcode,d0
 jsr driver
mpfnoprint
 addq.l #1,d2 * offset into filename
 bra.s menuprintfname1

nextfile
 move.b #cr,(a6)
 move.b #oswrchdcode,d0
 jsr driver

 move.w #$4f,-(sp) * snext function - any more files?
 trap #1
 addq.l #2,sp
 tst d0
 beq menuprintfname
* no more files
 bra getselection

nofiles
 bsr prs
 dc.b 'no suitable files on disk',cr,0
 jsr waitkey
 bra returntogem

getselection
 cmp.b #1,d7
 bne.s getsel0
 bsr prs
 dc.b "Only one game available - I am loading it!",cr,0
 even
 move.b #1,d0
 bra loadfiled0

getsel0
 bsr prs
 dc.b cr,cr,"Press the key corresponding to your choice "
 dc.b "or 'Help' for more information. ",0
 even

* now get a digit, '1'..d7+'1'
getsel1
 move.b #osrdchdcode,d0
 jsr driver
 move.b (a6),d0
 beq.s getsel1

 cmp.b #helpkey,d0
 beq displayhelp

 bsr converttouppercase

 move.w d0,-(sp) * echo character, leave cursor where it is
 bsr protectedoswrch
 move.b #8,(a6) * backspace cursor
 move.b #oswrchdcode,d0
 jsr driver
 move.w (sp)+,d0

 sub.b #'0',d0
 beq getsel1 * '@' is not allowed
 cmp.b d7,d0
 bhi.s getsel1 * unsigned >

loadfiled0
* d0.b is number of file to load
* so go through filenamelist
 lea filenamelist,a0
 move.w #0,d1 * offset
searchfilenamelist
 subq.b #1,d0
 beq sflfound
sfl2
 move.b $0(a0,d1),d2
 add.w #1,d1
 tst.b d2
 beq.s searchfilenamelist
 bra.s sfl2

sflfound
* load game from sub-directory whose name is at $0(a0,d1)
 pea $0(a0,d1) * path name
 move.w #$3b,-(sp) * chdir
 trap #1
 addq.l #6,sp
 tst.w d0 * error?
 bne nofiles

 bra intstart

*---
displayhelp
 lea scrolledlines,a0
 clr.b (a0) * prevent <More> message
 bsr prs
 dc.b 27,'E' * cursor home
 dc.b 27,'J' * clear screen below cursor
 dc.b cr,cr
 dc.b "When entering commands in a game, you may use the cursor"
 dc.b " left and right keys",cr

 dc.b "to move through a line and make changes as required."

 dc.b "Previous lines may be",cr
 dc.b "recalled and edited using the up and"
 dc.b " down cursor keys:"

 dc.b " press return when the",cr
 dc.b "line looks correct.",cr

 dc.b cr
 dc.b "There is a 1000 character type-ahead buffer, so you can"
 dc.b " enter commands",cr

 dc.b "while the game is obeying your earlier orders."
 dc.b " If something goes wrong",cr

 dc.b "(like a monster appearing!), "
 dc.b "you can clear the type-ahead buffer by",cr

 dc.b "pressing the key marked 'Esc'.",cr,cr

 dc.b "To leave the game, press 'Alt' and 'Q'.",cr,cr

 dc.b "The 'Help' and 'Undo' keys perform useful functions.",cr,cr
 dc.b "Have fun, and press a key to return to the menu.",0
 even
 jsr waitkey
 bra menu
*---

* now some experimental mouse handler code
* dc.w $A000 * line A initialise
* a0 = start address of line A variables
* A1 = table of address of the three system font headers
* A2 = start addresses of the lineA routines
* dc.w $a009 * show mouse


*---
 move.b #inputlinedcode,d0
 jsr driver
 move.l a6,-(sp) * path name
 move.w #$3b,-(sp) * chdir
 trap #1
 addq.l #6,sp
 tst.w d0 * error?
 bne nofiles

 bra intstart

*
 even
mousehandler
 addq.b #1,$7a000
 rts * rte

fileblock
 ds.b 44 * space for the file spec buffer
 even

directoryname
 dc.b '*.L9',0
 even

mouseparameter
* see p. 156/157 ST internals for details
 dc.b 0 * topmode - y=0  in lower corner
 dc.b 1 * abs position when button pressed. See p. 75 ST internals
 dc.b 1 * x scaling factor
 dc.b 1 * y scaling factor
 dc.w 1000 * xmax
 dc.w 1000 * ymax
 dc.w 200 * x start
 dc.w 200 * y start

 even
current
startfile equ current
filenamelist
* for menu program to build up a list
* of possible games, from which the user chooses one
* this data is overwritten when the game is loaded