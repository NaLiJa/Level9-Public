 opt o+,ow-
* Menu program for adventures on Atari ST
*
* M.J.Austin started 22/8/86
* last change: 9/1/88
* text printing+command line editor changed by Mike 21/10/87
* picture compression code added 9/1/88
*
* Copyright (C) 1988 Level 9 Computing
*
*
* When building a RELEASE DISK -
*

* AllowTraps equ 1 ; permits table overflow traps if equ 1
* Comment out for release game

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
*----
* late changes: (see also other source files)
*
* Mike 6/5/88:
*  in an effort to remove the annoying flicker when the title
* screen scrolls up on the monochrome system, I've added
* some code to synchronise the scroll the the frame sync -
* find "scroll_it" in this file. This went some way towards
* the solution - leaving a single, stable glitch towards the
* bottom of the title screen area.
* The full solution was to change GINT.S gintloop1/2 to
* dramatically speed up the monochrome copy. The
* colour copy appears fast enough already, as this
* used the proper routine anyway.

*---
*
* This code does not entirely follow the driver convention
* - naughty, naughty! But it did make it lots easier to write!
* ( and probably gave a better effect )
startmenu
graphics set startmenu
 	jmp menustart

 include "driver.s"
 include "int.s"
 include "gint.s"
 include "newhires.s"
 include "decomp.s"

menustart
; first null out the palette
	move.l	#nullmap,-(sp)
	call_ebios	_setpalette
	addq.l	#6,sp
* set up medium rez if using a colour monitor
 call_ebios _getRez
 addq.l #2,sp
 move.b	d0,screenresolution
* d0.b = 2 for hires
 cmp.b #2,d0
 beq.s menustartnoswitch
 move.w #1,-(sp) * medium resolution
 move.l #-1,-(sp) * retain physical base
 move.l #-1,-(sp) * retain logical base
 call_ebios _setscreen
 add.l #12,sp
menustartnoswitch

 jsr setsupervisormode

 lea -500(sp),sp ; >>mike 14/7/87 - give some space for system stack


 lea driverbuffer(pc),a6
 lea filenamelist,a5
 move.b #0,d7 * number of files found

 dc.w $A00A * Line A function to hide mouse
 
* and set up palette - we want yellow text on black background
; changes made here to cope with fact that screen memory may
; not be at ??8000
	jsr	getscreenaddress
	move.l	d0,screenpointer
	move.l	d0,this_screen
	clr.l	d1
	move.w	d0,d1
	move.l	#allbuffers+$10000,d0
	and.l	#$ffff0000,d0
	add.l	d1,d0
	move.l	d0,screenpointer2
	move.l	d0,d1
	sub.l	#32000,d1
	cmp.l	#allbuffers,d1
	bcs.s	allabove
	move.l	d1,logpointer
	sub.l	#32000,d1
	cmp.l	#allbuffers,d1
	bcs.s	someabove
	move.l	d1,hscreen
	bra.s	oneabove
allabove
	add.l	#32000,d0
	move.l	d0,logpointer
someabove
	add.l	#32000,d0
	move.l	d0,hscreen
oneabove
	add.l	#32000,d0
	move.l	d0,fbuffer

menu
 jsr InitScreenMode
 lea scrolledlines,a0
 clr.b (a0)
 lea filenamelist,a5
 clr.b d7 * number of files found

 lea YCursorPos,a0
 move.w #160,(a0)
 bsr MenuPrs
* dc.b 27,'E' * cursor home
* dc.b 27,'J' * clear screen below cursor
 dc.b "                             Level 9 Adventures",cr,cr
 dc.b "                    "
 dc.b "Copyright (C) 1988 Level 9 Computing",cr,cr,cr,cr,cr,0
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

 bsr MenuPrs
 dc.b "                               ",0
 even

 addq.b #1,d7 * number of files found so far
 clr.l d0
 move.b d7,(a6)
 add.b #"1"-1,(a6)
 move.b #oswrchdcode,d0
 jsr driver
 bsr MenuPrs
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
 bsr MenuPrs
 dc.b 'no suitable files on disk',cr,0
 jsr waitkey
 jmp returntogem

getselection
 cmp.b #1,d7
 bne.s getsel0
* bsr prs
* dc.b "Only one game available - I am loading it!",cr,0
* even
 move.b #1,d0
 bra loadfiled0

getsel0
 bsr Menuprs
 dc.b cr,cr,"Press the key corresponding to your choice "
 dc.b "or 'Help' for more information. ",0
 even
 jsr	setuppalette * added mike 15/8/87

* now get a digit, '1'..d7+'1'
getsel1
 move.b #osrdchdcode,d0
 jsr driver
 move.b (a6),d0
 beq.s getsel1

 cmp.b #helpkey,d0
 beq displayhelp

 jsr converttouppercase

 move.w d0,-(sp) * echo character, leave cursor where it is
 jsr protectedoswrch
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

 bra readytointstart

*---
displayhelp
 lea scrolledlines,a0
 clr.b (a0) * prevent <More> message
 bsr Menuprs
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
; load the title page
readytointstart
; lets store current directory so can cd to it for chaining
	move.w	#0,-(sp)
	move.l	#dirbuff,-(sp)
	call_bdos	D_GETPATH
	addq.l	#8,sp
; lets try to read the directory sector for side b
	move.w	#0,doubledisk
	move.w	#$19,-(sp)
 	trap	#1
	addq.l	#2,sp
	move.w	d0,thisdrive
	move.b	d0,d1
	add.b	#'A',d1
	move.b	d1,dirbuff2
	cmp.w	#2,d0
	bcc	notdouble		; if not A or B
	move.w	#1,-(sp)
	move.w	#1,-(sp)
	move.w	#0,-(sp)
	move.w	#1,-(sp)
	move.w	thisdrive,-(sp)
	clr.l	-(sp)
	move.l	#dirtrack,-(sp)
	move.w	#8,-(sp)
	trap	#14
	lea	20(sp),sp
	tst.w	d0
	bne	notdouble
	lea	dirtrack,a0
	move.w	510(a0),d0
	cmp.w	#$1234,d0
	bne	notdouble
	move.w	#1,doubledisk
notdouble
	lea	initialstackpointer,a0
	move.l	sp,(a0)
	bsr	intinit1
	jsr	setuppalette
tttt
	bsr	GetTitle
	bsr	scroll_itnow

	bsr	intinitialise2
	bsr	doscrollup
;
	move.w	#1,oktouse
	bsr	showpointer
	bra intstart2

doscrollup
; delay before starting
	move.w	#40,d1
doloop2	move.l	#10000000,d0
doloop	dbra	d0,doloop
	dbra	d1,doloop2
	disable_cursor
doscrollup2
	move.w	picy,d0
	move.w	ymax,d1
	sub.w	#4,d1
	cmp.w	d1,d0
	beq.s	donescrollup
	sub.w	#1,picy

;>>mike 6/5/88
; new addition to remove flicker on scrolling....
 move.l this_screen,d0
 add.l #500,d0
 lsr.l #8,d0 ; calc mid byte of screen address - near start of screen
 move.w d0,d1
 lsr.l #8,d1

	move.l	#$ff8207,a0
mjatohires1
* now wait for the scanning beam to go off-screen
 move.b (a0),d2
 move.b -2(a0),d3
	cmp.b (a0),d0
	bcs.s mjatohires1 ; unsigned <
 cmp.b -2(a0),d1
 bne.s mjaToHires1
; end of additional code (Mike 6/5/88)

	bsr	scroll_itnow
	bra.s	doscrollup2
donescrollup
**18/10/87	enable_cursor
	rts

;------
	even
CompressedTitle		dc.b '30.squ',0

	even
UncompressedTitle	dc.b '30',0
	even

GetTitle
* try compressed pictures first...
	addq.w	#1,suspendtaskswap
	 move.w	#0,-(sp)	;read
	 move.l	#CompressedTitle,-(sp)
	 move.w	#f_open,-(sp)
	 trap	#1
	 add.l	#8,sp
	subq.w	#1,suspendtaskswap
	tst.w	d0
	bmi	TryUncompressedTitle * filereaderr3
	move.w	d0,handle
	lea YOffset,a0
	move.w #16,(a0)
	lea XOffset,a0
	clr.w (a0)
	lea UseCompressedGraphics,a0
	move.b #1,(a0)
	move.l fbuffer,a0
	bsr	CompressedLoadDisplay
 bsr CopyCols
	bra	FinishOffTitleScreen * copyover

TryUncompressedTitle
; uncompressed title page...
	addq.w	#1,suspendtaskswap
	move.w	#0,-(sp)	;read
	move.l	#UnCompressedTitle,-(sp)
	move.w	#f_open,-(sp)
	trap	#1
	add.l	#8,sp
	subq.w	#1,suspendtaskswap
	tst.w	d0
	bmi	filereaderr3
	move.w	d0,handle

	lea UseCompressedGraphics,a0
	clr.b (a0)

	readf	colormap2,32,handle
	tst.w	d0
	bmi	filereaderr2
	readf	xsize,4,handle
	readf	ysize,4,handle
	readf	maskleft,2,handle
	readf	maskright,2,handle
	tst.w	d0
	bmi	filereaderr2
* now set up registers for picture load
* as in the amiga, assume full size picture
	readfp	fbuffer,32000,handle	
	addq.w	#1,suspendtaskswap
	move.w	handle,-(sp)
	move.w	#$3e,-(sp)
	trap	#1
	addq.l	#4,sp
	clr.w	handle		; cleaned up tidy
	subq.w	#1,suspendtaskswap
	bsr	copycols
FinishOffTitleScreen
	move.b	#1,first
	tst.b	screenresolution
	beq.s	no_stipple2
	bsr	stipple
no_stipple2
	bsr	copyover
	rts

filereaderr2
	addq.w	#1,suspendtaskswap
	move.w	handle,-(sp)
	move.w	#$3e,-(sp)
	trap	#1
	addq.l	#4,sp
	clr.w	handle		; cleaned up tidy
	subq.w	#1,suspendtaskswap
	bsr	scroll_itnow
filereaderr3
	rts

copyover
	move.l	hscreen,a0
	move.l	fbuffer,a1
	move.w	#7959,d0
cloop	move.l	(a1)+,(a0)+
	dbra	d0,cloop
	rts

MenuPrs jmp PRS
*

;fileblock
; ds.b 44 * space for the file spec buffer
; even

dirbuff2	dc.b	'\',0 * was 'a:\' before 20/10/87
	even
;dirbuff		ds.b	128
;	even
directoryname
 dc.b '*.L9',0
 even
thisdrive	dc.w	0
doubledisk	dc.w	0
;dirtrack	ds.w	256
hscreen		dc.l	0	; hires screen buffer
fbuffer		dc.l	0	; hires file buffer
nullmap		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0

 include "font.s"
 include "ram.s"
