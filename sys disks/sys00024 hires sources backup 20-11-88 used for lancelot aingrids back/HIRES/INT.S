* 68000 Acode interpreter
*
* Copyright (C) 1986 Level 9 Computing
*
* M.J.Austin 13/7/86
*
* Amiga version started 19/5/86
*
* the label computertype is initialised in the driver

* recent changes:

* 10/1/88 to avoid output overflow.

* Dec 87? InitDict: to allow text sizes>32K

* 29/4/88 - change to listvlv trap code to allow
* static tables of size >1.5K
*
* Changes to allow compilation to MC: Mike 7/6/88: marked with &&

cachesize	equ	32048
checksumvalue equ $ee * update this if you change the code!
*-------------------
_main

        bra     intstart
*        include "gint.s"
        even

* constants for interpreter
relativebit     equ     5
sizebit         equ     6
numberofvars    equ     255
controlc        equ     3
formfeed        equ     12
flushcode       equ     126 ; tilda on BBC
        ifnd    true
true            equ     $ff
        endc
false           equ     $0
runmodecode     equ     0
stepmodecode    equ     'S'
acodespeedmodecode      equ     'X'
inputspeedmodecode      equ     'Y'
outputspeedmodecode     equ     'Z'
tracemodecode   equ     'T'
* now data block for file
        even
absdatablock
exitsptr        dc.l    0
listtbl
* commandsptr also allows space for list0ptr, which does not exist
commandsptr     dc.l    0
list1ptr        dc.l    0
list2ptr        dc.l    0
list3ptr        dc.l    0
list4ptr        dc.l    0
list5ptr        dc.l    0
list6ptr        dc.l    0
list7ptr        dc.l    0
list8ptr        dc.l    0
list9startptr   dc.l    0
acodeptr        dc.l    0
*
startramsavearea dc.l 0

*       ---

* language equates
jumphbit        equ     7       * jump header or message header
parsebit        equ     6       * message contains keywords
longbit         equ     7       * shortor long form reference
* special short-codes
longc           equ     $1a     * long escape code
header          equ     $1c     * header short code
endseg          equ     $1b     * segment end marker
screenwidth     equ     79
uppercasemark   equ     $10

* language workspace
startmd         dc.l    0       * address of start of message descriptors
endmd           dc.l    0       * end address+1 of message descriptors
endwdp5         dc.l    0       * address+6 of end of word dictionary 
mdtmode         dc.l    0       * ?? w
wrapbufferpointer       dc.l    0
list9ptr        dc.l    0
ibuffpointer    dc.l    0
keywordnumber   dc.l    0       * ?? w
abrevword       dc.l    0       * ??w
        even
;unpackbuffer
;                ds.b    64      * ??8
;threecharacters
;                ds.b    33      * word expansion buffer
;        even
;
;wrapbuffer      ds.b    32
;WrapBufferEnd
;        even
;
;obuff           ds.b    33      * lower case input buff
        even
*ibuff           ds.b    500     * ascii input buffer
nchars          dc.b    0
lastchar        dc.b    0
width           dc.b    0
lastheader      dc.b    0
wordcase        dc.b    0
pendspace       dc.b    0
AreWeChaining 	dc.b 	0 * Initial value of zero is used

*       ---

        even
* general workspace
initialstackpointer     dc.l    0
breakpointaddress       dc.l    0
randomseed      dc.w    0
textmode        dc.b    0
debuggingstatus dc.b    0
speedmode       dc.b    0
disableoutput   dc.b    0
disableinput    dc.b    0
apmlastcharprinted dc.b 0
numberaddress dc.l 0
        even
inputdebugptr   dc.l    inputdebugblock
inputdebugstatus        dc.b    0

*       gno     workspace
        even
searchdepth     dc.w    0
hisearchpos     dc.w    0
searchpos       dc.w    0
object          dc.w    0
numobjectfound  dc.w    0
inithisearchpos dc.w    0
hipos           dc.w    0
hisearchposvar  dc.l    0
searchposvar    dc.l    0
nonspecific     equ     31
gnosp           dc.l    0
maxobject       dc.w    0
*gnospbase - not used
*                ds.w    127     * should give plenty of space
*gnospinitial
;gnoscratch      ds.b    nonspecific

        even
startchecksumarea
* no more variables after here
*--
intinit1
        lea     intdriverbuffer,a6 * a6 remains as driver buffer pointer throughout
        move.b  #initdcode,d0
        bsr     driver
        move.b  #clgdcode,d0
        bra     driver
*---
intinitialise
        bsr intinit1

intinitialise2
        move.l  a6,-(sp)        * save a6 while initialising
tryitagain
        lea     gamedatadriverblock,a6
        lea     startfile,a0
        move.l  a0,(a6)
        move.b  #loaddcode,d0
        bsr     driver          * load in data for game
        move.b (a6),d0
        beq 	gotit
	bsr	loadingerror
	bra.s	tryitagain
gotit
*        move.l $4(a6),a0
*	add.l #4500,a0 * give space for part2/3 when they are chained
 lea startfile,a0 ;>>mike 30/7/87
 add.l #54000,a0 ;>>mike 30/7/87
 move.l a0,$4(a6) ;>>mike 30/7/87
* a0.l is address of caches at this point
        move.l (sp)+,a6
intinitloadpics
        move.l a6,-(sp)
* make a0.l even
        move.l a0,d0
        btst    #0,d0
        beq.s alreadyeven
        addq.l #1,a0
alreadyeven
; move.b AreWeChaining,d0 ;>>mike 30/7/87
; bne.s aftercacheinit ;>>mike 30/7/87
; lea AreWeChaining,a0 ;>>mike 30/7/87
; move.b #1,(a0) * set the flag to prevent re-initialisation ;>>miek 30/7/8

; new code to add caches to ST version
	move.w	#-1,d3
	move.l	a0,d0			; lets see how much memory we have
	move.l	screenpointer,d1
	sub.l	d0,d1			; dont try to use more
	asr.l	#1,d1			; than half available memory
	move.l	d1,d0
	move.l	#cachesize,d2		; size of 1 cache buffer
findagain	
	tst.l	d0			; find out how many cahces
	bmi.s	allfound
	addq.w	#1,d3
	sub.l	d2,d0
	bra.s	findagain
allfound
	cmp.w	#2,d3			; if less than 2 make 0
	bcc.s	not_little
ZeroCaches
	clr.w	d3
not_little
	cmp.w	#26,d3			; if > 25 make 25
	bcs.s	not_too_big
	move.w	#25,d3
not_too_big

; lea IsPictureValid,a1
; clr.b (a1) * void any picture currently loading

	move.w	d3,no_caches
	lea	cache,a1
alloc_cache
	tst.w	d3
	beq.s	all_done
	move.l	a0,(a1)+
	add.l	d2,a0
	subq.w	#1,d3
	bra.s	alloc_cache
all_done
	move.l	a0,4(a6)
        lea     startramsavearea,a0
        move.l  $4(a6),(a0) * start of memory for ram save

aftercacheinit
        move.l  (sp)+,a6                        * restore a6

*       bsr     prs
*       dc.b    '68000 Adventure System 1.0',cr
*       dc.b    'Copyright (c) 1986 Level 9 Computing.',cr
*       dc.b    'M.J.Austin 17/2/86',cr,cr,0
*       even

        lea     debuggingstatus,a0
        move.b  #stepmodecode,(a0)      * select full trace mode

* now convert relative addresses supplied at start
* of data to absolute addresses
        lea     absdatablock,a3 * data will be copied to here in absolute form
        lea     startfile,a0    * fixed pointer to startofdata
        clr.l   d0
        lea     startfile+18,a1 * pointer to pointer being processed
        move.b  #$0c,d1         * no. of pointers to adjust
copy1
        move.l  a0,a2           * what this pointer is relative to
*get relative pointer (low byte first on 6502/Z80, remember)
        move.b  $1(a1),d0
        asl.w   #8,d0
        move.b  (a1),d0                 * d0 is now the relative pointer
        addq.l  #2,a1
        cmp.w   #$8000,d0               * check if it was a workspace list reference
        blt.s   copy2
        cmp.w   #$9000,d0
        bgt.s   copy2
* workspace list reference
 cmp.b #1,d1
 beq.s copy2 * don't affect acode ptr.
        sub     #$8000,d0

;	movem.l	d0-d7/a0-a6,-(sp)
;	bsr	printdecimald0
;	move.b	#' ',d0
;	bsr	printchar
;	movem.l	(sp)+,d0-d7/a0-a6


        lea     listarea,a2             * this pointer is now relative to listarea
copy2
        add.l   d0,a2
        move.l  a2,(a3)+
        subq.b  #1,d1                   * why can't I use dbne ?
        bne.s   copy1                   * all pointers done ?

        lea     startmd,a0              * remains set as pointer to calculation results
        move.b  startfile+3,d0
        asl.w   #8,d0
        move.b  startfile+2,d0
        lea     startfile,a1
        add.w   d0,a1
        move.l  a1,(a0)+                * startmd
        clr.l   d0
        move.b  startfile+5,d0
        asl.w   #8,d0
        move.b  startfile+4,d0
        add.l   d0,a1                   * add in length of message descriptors
        move.l  a1,(a0)+                * endmd

        lea     startfile+5,a1
        clr.l   d0
        move.b  startfile+9,d0
        asl.w   #8,d0
        move.b  startfile+8,d0
        add.l   d0,a1                   * length of word dictionary
        clr.l   d0
        move.b  startfile+7,d0
        asl.w   #8,d0
        move.b  startfile+6,d0
        add.l   d0,a1                   * offset of word dictionary
        move.l  a1,(a0)                 * endwdp5
*
* make sure list9 is NOT word-aligned
* so that calldriver can give list9+1 as a word-aligned
* value (for use by oops routines)
        move.l  list9startptr,d0
        btst    #0,d0
        bne.s   initwordaligned
        addq.l  #1,d0
        lea list9startptr,a0
        move.l  d0,(a0)
initwordaligned
        rts

*
*---
*
loadingerror
	move.w	thisdrive,d0
	cmp.w	#2,d0
	bcc	notfloppy2
; Restore the directory in case changed by disc swap
redoit	bsr	prs
	dc.b	'Please return game disc to original drive '
	dc.b	'and hit space!',13,0
	even
	bsr	waitkey
	addq.w	#1,suspendtaskswap
	move.w	#1,-(sp)
	move.w	#0,-(sp)
	move.w	#1,-(sp)
	move.w	#1,-(sp)
	move.w	thisdrive,-(sp)
	clr.l	-(sp)
	move.l	#thissect,-(sp)
	move.w	#8,-(sp)
	trap	#14
	lea	20(sp),sp
	subq.w	#1,suspendtaskswap
	tst.w	d0
	bne	redoit
	bsr	try10times
notfloppy2
	move.l	#dirbuff,-(sp)
	call_bdos	D_SETPATH
	addq.l	#6,sp
	tst.w	d0
	rts

intstart
        lea     initialstackpointer,a0
        move.l  sp,(a0)
        bsr     intinitialise
intstart2
        bsr     checksumgamedata
        move.l  acodeptr,a5             * a5 remains as acode pointer throughout
* set up random number seed
        move.b  #randomnumberdcode,d0
        bsr     driver
        lea     randomseed,a0
        move.w  (a6),(a0)

        bsr     wrapreset
        lea     ibuffpointer,a0
        move.l  #0,(a0)
instructionloop
;       bsr     debugging
        move.b  (a5)+,d7                * get instruction - stays in d7
        bsr.s   executeinstruction
        bra.s   instructionloop

executeinstruction
        move.b  d7,d0
        bmi     listhandler
        and.w   #$1f,d0                 * reset bits 5-15.
        asl.b   #2,d0                   * get index into jump table
        lea     jumptable,a0
        move.l  $0(a0,d0),a1
        jmp     (a1)

debugging
        lea     debuggingstatus,a0
        move.b  (a0),d0
        cmp.b   #runmodecode,d0
        bne.s   traceinstruction
        rts

traceinstruction
* is acode running in interruptible mode ?
        movem.l d0-d7/a0-a6,-(sp)
        move.b  (a5),d7                 * acode instruction to be executed next
        cmp.b   #tracemodecode,d0
        beq.s   tracemode
        cmp.b   #'I',d0
        bne.s   debugnotinterruptible
* running in interruptible mode - check for breakpoint address
        bsr     checkbreakpoint
        bra.s   checkforstop
tracemode
        bsr.s   intdisplayinstruction
checkforstop
        move.b  #osrdchdcode,d0
        bsr     driver
        move.b  (a6),d0
        tst.b   d0
        beq.s   debuggingend            * no, so continue running


emergencystop
        lea     debuggingstatus,a0
        move.b  #stepmodecode,(a0)      * select full debugging

debugnotinterruptible
        bsr     displayvariables
* now display instruction to execute next
        bsr     prs
        dc.b    'about to execute instruction: ',0
        even

        bsr.s   intdisplayinstruction
        bsr     getdebuggingoption
debuggingend
        movem.l (sp)+,d0-d7/a0-a6
debuggingret
        rts

intdisplayinstruction
        move.l  a5,a0
        move.l  acodeptr,a1
        sub.l   a1,a0
        bsr     hexlonga0
        move.b  #' ',(a6)
        move.b  #oswrchdcode,d0
        bsr     driver
        move.b  d7,d0
        bsr     hexbyted0
        move.b  #crlf,(a6)
        move.b  #oswrchdcode,d0
        bra     driver

displayvariables
        lea     vartable,a1
displaymemorya1
        move.l  #128,d5                 * length to display
displayfileloop
* display 16 words in hex format
        move.w  #16,d6
dflhex
* get word from memory, not necessarily word - aligned
        move.b  (a1)+,d0
        asl.w   #8,d0
        move.b  (a1)+,d0
        move.w  d0,a0
        bsr     hexworda0
        move.b  #' ',d0
        bsr     oswrch
        subq.b  #1,d6
        bne.s   dflhex
        move.b  #crlf,d0
        bsr     oswrch

        sub.w   #32,d5
        bpl.s   displayfileloop 
        rts

*       ---

debugginghelp
        bsr     prs
        dc.b    '68000 Acode debugging package 0.1',cr
        dc.b    'Copyright (C) 1986 Level 9 Computing.',cr
        dc.b    'M.J.Austin 17/2/86',cr,cr
        dc.b    'The following commands are valid:',cr
        dc.b    ' R .. run game from current position.',cr
        dc.b    ' I .. interruptible mode - runs until a key is pressed',cr
        dc.b    ' B .. set breakpoint at a known address',cr
        dc.b    ' M .. display memory (relative to acode start)',cr
        dc.b    ' T .. trace',cr
        dc.b    ' S .. or any other key to single step',cr
        dc.b    ' Q .. Return to Monst or GEM.',cr
        dc.b    ' X .. Measure acode speed only',cr
        dc.b    ' Y .. Measure input and acode speed (disable output)',cr
        dc.b    ' Z .. Measure output and acode speed (disable input)',cr
        dc.b    ' ? .. Display this menu',cr,0
        even

getdebuggingoption
        bsr     prs
        dc.b    'Command:',0
        even

gdoloop
        move.b  #osrdchdcode,d0
        bsr     driver
        move.b  (a6),d0
        cmp.b   #32,d0
        bcs.s   gdoloop

* now echo the selection:
        move.b  d0,-(sp)                * save code
        move.b  #oswrchdcode,d0
        bsr     driver
        move.b  #crlf,(a6)
        bsr     driver
        move.b  (sp)+,d0
        bsr     converttouppercase

* now look at what the user wanted
        cmp.b   #'?',d0
        beq     debugginghelp
        cmp.b   #'H',d0
        beq     debugginghelp

        cmp.b   #'Q',d0
        beq     generatebreakpoint

        move.b  #'I',d1         * interruptible mode
        cmp.b   #'I',d0
        beq.s   startrunning

        cmp.b   #'B',d0
        bne.s   gdonotbreakpoint
        bsr     setbreakpoint
        move.b  #'B',d1
        bra.s   gotoption

gdonotbreakpoint
        move.b  #stepmodecode,d1        * full debugging mode
        cmp.b   #'S',d0
        beq.s   gotoption

        cmp.b   #'R',d0
        bne.s   notrunmode

faststartrunning
        move.b  #runmodecode,d1
startrunning
        bsr     prs
        dc.b    'Running ... ',cr,0
        even

        bra.s   gotoption

setupdisableboth
* disable both input and output
        lea     disableoutput,a0
        move.b  #true,(a0)
        bra.s   setupdisableinput

setupdisableoutput
        lea     disableoutput,a0
        move.b  #true,(a0)
        bra.s   speedrun

setupdisableinput
        lea     disableinput,a0
        move.b  #true,(a0)

speedrun
* doing a speed measurement
        lea     speedmode,a0
        move.b  d1,(a0)
        bra.s   faststartrunning

notrunmode
        move.b  #tracemodecode,d1       * trace mode
        cmp.b   #'T',d0
        beq.s   gotoption

        move.b  #stepmodecode,d1        * full debugging stuff
        cmp.b   #'M',d0
        beq.s   displaymemory

        cmp.b   #acodespeedmodecode,d0
        beq.s   setupdisableboth
        cmp.b   #inputspeedmodecode,d0
        beq.s   setupdisableoutput
        cmp.b   #outputspeedmodecode,d0
        beq.s   setupdisableinput

* key not recognized - put into step mode to avoid damage
        move.b  #stepmodecode,d1
gotoption
        lea     debuggingstatus,a0
        move.b  d1,(a0)
        rts

displaymemory
* prompt for address and display a small block of memory
        bsr     prs
        dc.b    'Enter address relative to acode start to display:',0
        even

        bsr     getaddress
* have got relative address in d0.l
        lea     acodeptr,a0
        move.l  d0,a1
        add.l   (a0),a1
        bsr     displaymemorya1
        bra     getdebuggingoption      * don't want to single step yet

generatebreakpoint
* send monitor back to MonST or tos
        bsr     prs
        dc.b    cr
        dc.b    'Press M to go to MonST (will crash if not present),',cr
        dc.b    '      G to return to Gem or return to continue: ',cr,0
        even

gbp1
        move.b  #osrdchdcode,d0
        bsr     driver
        move.b  (a6),d0
        beq.s   gbp1
        bsr     converttouppercase
        cmp.b   #'M',d0
        beq.s   gbp2
        cmp.b   #'G',d0
        beq     returntogem
        rts
gbp2
        dc.w    $4afa           * generate breakpoint with monitor
        rts
* ---

setbreakpoint
        bsr     prs
        dc.b    'Enter address of acode breakpoint in hex:',0
        even

        bsr     getaddress
        lea     breakpointaddress,a0
        move.l  d0,(a0)
        rts

getaddress
        move.b  #inputlinedcode,d0
        bsr     driver
        lea     intdriverbuffer,a0
        bsr     readhex                 * get hex number user typed in d0
        rts

checkbreakpoint
        lea     acodeptr,a0
        move.l  a5,a1
        sub.l   (a0),a1
* now a1=address we're executing relative to start
        lea     breakpointaddress,a0
        cmp.l   (a0),a1
        bne.s   cbpret
        bsr     prs
        dc.b    'Breakpoint.',cr,0
        even

        lea     debuggingstatus,a0
        move.b  #stepmodecode,(a0)
cbpret
        rts

* ---

        even
jumptable
        dc.l    goto
        dc.l    intgosub
        dc.l    intreturn
        dc.l    printnumber
        dc.l    messagev
        dc.l    messagec
        dc.l    function
        dc.l    input
        dc.l    varcon
        dc.l    varvar
        dc.l    _add
        dc.l    _sub
        dc.l    ToMC * ilins
        dc.l    ilins
        dc.l    jump
        dc.l    exit

        dc.l    ifeqvt
        dc.l    ifnevt
        dc.l    ifltvt
        dc.l    ifgtvt
        dc.l    screen
        dc.l    cleartg
        dc.l    picture
        dc.l    getnextobject
        dc.l    ifeqct
        dc.l    ifnect
        dc.l    ifltct
        dc.l    ifgtct
        dc.l    printinput
        dc.l    ilins
        dc.l    ilins
        dc.l    ilins
*---
*---
ToMC *&& all the following:
 move.l a5,d0 * address of MC
 btst #0,d0
 beq.s ToMC1
 addq.l #1,a5 * in case we had to pad
ToMC1
 pea ToMCEnd * push on return address: simulates JSR (A5)
 lea VarTable,a4 * set up var table block
 lea ListTbl,a3 * ptrs to lists
 moveq.w #0,d7 * kept zero for use in 0(a3,d7) accesses
 jmp (a5)

ToMCEnd
* a5.l is new acode ptr
* (relative to start of acode)
 add.l AcodePtr,a5
 rts
*---
*---
messagec
        bsr.s   getcon
        bra     printmessage

messagev
        bsr     getvar
        move.w  (a0),d0                 * get value of message to print
        bra     printmessage

goto
        bsr     getaddr
        move.l  a0,a5
        rts

intgosub
        addq.l  #4,sp                   * lose return address
        bsr     getaddr
        move.l  a5,-(sp)
        move.l  a0,a5
        bra     instructionloop

intreturn
        addq.l  #4,sp                   * lose return address
        move.l  (sp)+,a5
        bra     instructionloop

varcon
* var:=con
        bsr.s   getcon
        bra.s   varvar1

varvar
        bsr.s   getvar
        move.w  (a0),d0
varvar1
* write d0 into var (acode)
        move.w  d0,d6                   * preserve d0
        bsr.s   getvar
        move.w  d6,(a0)
        rts

_add
        bsr.s   getvar
        move.l  a0,a4                   * preserve address of var
        bsr.s   getvar
        move.w  (a4),d0
        add.w   d0,(a0)
        rts

_sub
        bsr.s   getvar
        move.l  a0,a4                   * preserve address of Bvar
        bsr.s   getvar
        move.w  (a4),d0
        sub.w   d0,(a0)
        rts

getcon
* get constant stored in code in d0.w, sized according to sizebit
        btst    #sizebit,d7             * and.b #sizemask,d7
        bne.s   getconsmall
movewa5d0
* get 16 bit value from acode in reverse-format
        move.b  $1(a5),d0
        asl.w   #8,d0
        move.b  (a5),d0
        addq.l  #2,a5
        rts

getconsmall
        clr.w   d0
        move.b  (a5)+,d0
        rts

*
getaddr
* get address to jump to in a0.l
        btst    #relativebit,d7         * and.b #relativemask,d7
        bne.s   getaddrshort
* write out this subroutine for easy speed increase
        clr.l   d0
        bsr.s   movewa5d0               * get 16 bit value in reverse-format
* d0 = new address relative to code start
        move.l  acodeptr,a0
        add.l   d0,a0
        rts
getaddrshort
* get a 8 bit relative offset from pc
        clr.l   d0
        move.b  (a5)+,d0
* sign-extend it:
        bpl     gaspl
        or.l    #$ffffff00,d0

gaspl
        move.l  a5,a0
        add.l   d0,a0
        subq.l  #1,a0           * make it relative to address of offset byte
        rts
*
getvar
* get address of var (acode) in a0.l
* note value not returned (unlike other versions of interpreter)
* this may be accessed by move.w (a0),d0 or similar
        clr.l   d0
        move.b  (a5)+,d0                * get var number from acode
        asl.w   #1,d0                   * get index into var table
        lea     vartable,a0
        add.l   d0,a0
        rts

listhandler
        lea     listtbl,a0
        clr.l   d0
        move.b  d7,d0                   * new code
        and.w   #$00ff,d0
        cmp.b   #224,d0
        bcc.s   listvv                  * unsigned d0>=224
        cmp.b   #192,d0
        bcc   listvlc                 * unsigned d0>=192
        cmp.b   #160,d0
        bcc     listvlv                 * unsigned d0>=160
* d0=128-159
* listN(cons)=var
        sub.b   #128,d0
* get start of list code - equivalent of getind
        asl.b   #2,d0                   * get index into list table
        move.l  $0(a0,d0),a4            * save address of list
* bits 8 to 15 of d0 were set to 0 because index to list table <40
        clr.l   d0
        move.b  (a5)+,d0                * get constant index into list
        add.l   d0,a4                   * address of byte to modify in list
        bsr     getvar
        move.b  $1(a0),(a4)             * low byte of var only
        rts
        
listvv
* list N(var)=var
        sub.b   #224,d0
* get start of list - equivalent of getind
        asl.b   #2,d0                   * get index into list table
        move.l  $0(a0,d0),a4            * save address of list
        bsr     getvar                  * get index into list
        clr.l   d0
        move.w  (a0),d0

; debugging code added......

;; bpl.s listvvindexok
 cmp.w #$601,d0
 bls.s listvvindexok

; comment out this code for release game...
 ifd allowtraps
 bsr prs
 dc.b "Array index too big. ",0
 even
 bsr emergencystop
 endc

; leave this code in anyway
; return zero value
 add.l d0,a4
 bsr getvar
 move.b #0,(a4)
 rts


listvvindexok
        add.l   d0,a4                   * address of byte to modify in list
	move.l	d0,-(sp) ;***
        bsr     getvar
	move.l	(sp)+,d0 ;***
        move.b  $1(a0),(a4)             * low byte of var only

 ifd allowtraps
; check for overflow of table area
	lea	listarea,a1
	add.l	#$600,a1
	cmp.l   a1,a4
	bls.s	listvvret

	movem.l	d0-d7/a0-a6,-(sp)

	movem.l	d0-d7/a0-a6,-(sp)
	bsr	printdecimald0
	move.b	#' ',d0
	bsr	printchar
	movem.l	(sp)+,d0-d7/a0-a6

	sub.l	d0,a4
	lea	listarea,a0
	sub.l	a0,a4
	move.l	a4,d0
	bsr	printdecimald0
	move.b	#' ',d0
	bsr	printchar
	movem.l	(sp)+,d0-d7/a0-a6

	lea	listarea,a0
	sub.l	a0,a4
	move.l	a4,d0
	bsr 	printdecimald0
	move.b 	#' ',d0
	bsr	printchar
	bsr	prs
	dc.b	" list area overflow",0
	even
	bsr	emergencystop
 endc ; allowtraps

listvvret
        rts

listvlc
* var=listn(cons)
        sub.b   #192,d0
* get start of list - equivalent of getind
        asl.b   #2,d0                   * get index into list table
        move.l  $0(a0,d0),a4            * save address of list
* bits 8-15 were set to 0 because index into list table <40
        clr.l   d0
        move.b  (a5)+,d0                * get constant table index
        add.l   d0,a4
        bsr     getvar
        move.b  (a4),$1(a0)             * modify low byte of var only
        move.b  #0,(a0)                 * zero high byte of var
        rts

listvlv
* var=listn(var)
        sub.b   #160,d0
* get start of list - equivalent of getind
        asl.b   #2,d0                   * get index into list table
        move.l  $0(a0,d0),a4            * save address of list
        bsr     getvar
        clr.l   d0
        move.w  (a0),d0

; debugging code added......
;; bpl.s listvlvindexok
 cmp.w #$601,d0
 bls.s listvlvindexok
 cmp.l #WorkSpaceEnd,a4 * temporary list?
 bcc.s listvlvindexok

 ifd allowtraps
; comment this code out for release game...
 bsr prs
 dc.b "Array index too big. ",0
 even
 bsr emergencystop
 endc


; leave this code in anyway....
; just return a zero value for the release game...
 add.l d0,a4
 bsr getvar
 move.b #0,$1(a0)
 move.b #0,(a0)
 rts

listvlvindexok

        add.l   d0,a4                   * address of byte in list
        bsr     getvar
        move.b  (a4),$1(a0)             * low byte of var only
        move.b  #0,(a0)                 * zero high byte of var
        rts

ifeqvt
* if v=v then ...
        bsr.s   checkequv
        beq.s   ifthen
        rts

ifnevt
* if v<>v then ...
        bsr.s   checkequv
        bne.s   ifthen
        rts

ifltvt
* if v<v then ...
        bsr.s   checkequv
        bhi.s   ifthen                  * unsigned
        rts

ifgtvt
* if v>v then ...
        bsr.s   checkequv
        bcs.s   ifthen                  * unsigned
        rts

checkequv
        bsr     getvar
        move.l  a0,a4                   * preserve address of first var
        bsr     getvar
        move.l  a0,a3                   * preserve address of second var
        bsr     getaddr
        move.w  (a3),d0
        cmp.w   (a4),d0
        rts

ifeqct
* if v=c then ...
        bsr.s   checkequc
        beq.s   ifthen
        rts

ifnect
* if v<>c then ...
        bsr.s   checkequc
        bne.s   ifthen
        rts

ifltct
* if v<c then ...
        bsr.s   checkequc
        bhi.s   ifthen
        rts

ifgtct
* if v>c then ...
        bsr.s   checkequc
        bcs.s   ifthen
        rts

checkequc
        bsr     getvar
        move.l  a0,a4                   * preserve var address
        bsr     getcon
        move.w  d0,d6                   * preserve constant value
        bsr     getaddr                 * in a0
        cmp.w   (a4),d6                 * do compare
        rts

ifthen
        move.l  a0,a5
        rts

;---
acodeprs
; print the text following the function call up to 0
; for debugging purposes only
 move.b (a5)+,d0
 beq.s acodeprsret
 bsr printchar
 bra acodeprs
acodeprsret
 rts
;---
function
        move.b  (a5)+,d0
        cmp.b   #1,d0
        beq.s   calldriver              * was stop originally
        cmp.b   #2,d0
        beq     random
        cmp.b   #3,d0
        beq     save
        cmp.b   #4,d0
        beq     restore
        cmp.b   #5,d0
        beq.s   clearworkspace
        cmp.b   #6,d0
        beq     resetstack
        cmp.b   #250,d0
        beq     acodeprs
        bra ilins
;---
resetstack
* reset stack

        move.l  initialstackpointer,sp
        bra     instructionloop

clearworkspace
* reset all vars to 0
        lea     vartable,a0
        move.w  #numberofvars,d0
cws1
        move.w  #0,(a0)+
        dbne    d0,cws1
        rts

calldriver
        move.l  a6,-(sp)                * save interpreter driver pointer
        move.l  list9startptr,a6
        move.b  (a6)+,d0                * driver code to call
                        
	beq.s	callDriverEnd * prevent doing a new init
        cmp.b   #osrdchdcode,d0
        beq.s   intosrdch
        cmp.b   #ramsavedcode,d0
        beq.s   intramsave
        cmp.b   #ramloaddcode,d0
        beq.s   intramload
	cmp.b 	#chainprogramdcode,d0
	beq.s	chainprog
calldrivercont
        bsr     driver
CallDriverEnd
        move.l  (sp)+,a6                * restore interpreter driver pointer
        rts

intosrdch
* because ST is much faster than other machines,
* The Lenslok code is hard to enter quickly enough !
* so a small delay is introduced here as a TEMPORARY fix
 bsr Snooze
; move.w #10000,d1
;intosrdch1
; subq.w #1,d1
; bne.s intosrdch1
 bra.s calldrivercont
*---
intramsave
intramload
* set up args for the drivercall
* (a6).b is position number
        move.w  d0,-(sp)
        move.b  (a6),d0
        
        cmp.b   #250,d0
        bhi.s   intramfail * unsigned >
* now multiply d0 (position number) by size of workspace
        move.l  #(workspaceend-workspacestart),d1
        clr.l   d2 * result
intramload1
        add.l   d1,d2
        tst.b   d0
        beq.s   intramload2
        subq.b  #1,d0
        bra.s intramload1

intramload2
* now d2 is offset into save ram area   

        move.l  startramsavearea,a0
        add.l   d2,a0
        move.l  a0,$8(a6)
        lea     workspacestart,a0
        move.l  a0,(a6)
        lea     workspaceend,a0
        move.l  a0,$4(a6)

        move.w  (sp)+,d0
        bsr driver
intramend
        move.l  list9startptr,a0
        move.b  (a6),(a0) * copy result for interpreter
        move.l  (sp)+,a6
        rts

intramfail
        move.b  #1,(a6)
        move.w  (sp)+,d0
        bra.s   intramend
*----
*---
chainprog
; load in the next section of the game and initialise system
	jsr try10times ;>>mike 28/6/87 - force loading of directory
        move.b  (a6),d0
        add.b   #'0',d0
        move.l  a6,-(sp)        * save a6 while initialising
        lea     gamedatadriverblock,a6
        move.b  d0,15(a6)       ; patch file name

; lea IsPictureValid,a0
; clr.b (a0) * void any picture currently being loaded

	bsr intinitialise2 * do full init, except screen

; lea IsPictureValid,a0
; clr.b (a0) * void any picture currently being loaded

	bra intstart2
*---
*---
random
        bsr     getvar
        move.w  randomseed,d0
        move.w  d0,d1
        asl.w   #8,d1
        move.b  #10,d1
        sub.w   d0,d1
        asl.w   #2,d1
        add.w   d0,d1
        addq.w  #1,d1
        move.b  d1,$1(a0)               * return in var
        move.b  #0,(a0)                 * zero high byte of var
        lea     randomseed,a0
        move.w  d1,(a0)
        rts

save
	lea	savedriverblock,a6
        lea     workspacestart,a0
        move.l  a0,(a6)
        lea	workspaceend,a0
        move.l  a0,$4(a6)
        move.b  #0,$8(a6)               * prompt user for filename
	jsr beforesavestuff ;>>mike 28/6/87
        move.b  #savedcode,d0
        bsr     driver
	jmp aftersavestuff ;>>mike 28/6/87

restore
	lea	savedriverblock,a6
        lea intstart,a0
        move.l a0,(a6)
        lea     workspacestart,a0
        move.l  a0,(a6)
        move.b  #0,$8(a6)               * prompt user for filename
	jsr beforeloadstuff ;>>mike 28/6/87
        move.b  #loaddcode,d0
        bsr     driver

        move.b (a6),d0
        beq 	restoreok
	bsr	prs
	dc.b	"Press a key to restart. ",0
	even
	bsr	waitkey
	bsr	prs
	dc.b	cr,0	 ; I don't know if this is necessary
	even

	bsr	flush
	bra	intstart2

restoreok
        bsr     checksumgamedata
	jsr afterloadstuff ;>>mike 28/6/87

* if filename was "c", do a checksum on the code
        move.b  $8(a6),d0
        cmp.b    #'c',d0
        bne.s   restoreret
        move.b  $9(a6),d0
        bne.s   restoreret
        bsr     prs
        dc.b    cr
        dc.b    "The checksum value for the machine code is:",0
        even
        lea     startchecksumarea,a0
        move.l  a0,(a6)
        lea     endchecksumarea,a0
        move.l  a0,$4(a6)
        move.b  #checksumdcode,d0
        bsr     driver
        move.b  (a6),d0
        bsr     hexbyted0
        bsr prs
        dc.b    cr
        dc.b    "Checking game data ...",cr
        dc.b    0
        even
        bsr     checksumgamedata
restoreret
        rts
*---
checksumgamedata
        lea     startfile,a0
        move.l  a0,(a6) * start address
        clr.l   d0
        move.b  $1(a0),d0 * high byte of length
        asl.w   #8,d0
        move.b  (a0),d0 * length of file
        add.l   d0,a0
        move.l  a0,$4(a6) * end address
        move.b #checksumdcode,d0
        bsr driver
        tst.b   (a6)
        beq.s checksumok
        bsr prs
        dc.b "Don't panic ... CHECKSUM ERROR !!!",cr,cr
        dc.b "Press a key to continue ... ",0
        even
        bsr waitkey
checksumok
        rts
*---
screen
        lea     textmode,a0
        move.b  (a5)+,d0
        move.b  d0,(a0)
        beq     screent
        addq.l  #1,a5
        bsr     flush *>> mike 24/8/86 - fix "WORDS,PICTURES"->" K."
        bra.s   clearg
screent
;       bsr     stopgint
        move.b  #settextdcode,d0
        bra     driver
*---
cleartg
        move.b  (a5)+,d0
        beq     cleart
clearg
        move.b  textmode,d0
        beq.s   cleargret
        bsr     stopgint
        bsr     gintclearg      
cleargret
pictureret
        rts

cleart
        move.b  #12,d0
        bra     oswrch

picture
        bsr     getvar
* (a0).w is picture number to draw
        tst.b   textmode
        beq.s   pictureret
        move.w  (a0),d0
        bsr     setuppictured0

        move.b  #taskinitdcode,d0
        bra     driver

stopgint
        clr.w   d0
        bsr     setuppictured0
        move.b  #taskinitdcode,d0
        bra driver

*---

printnumber
        bsr     getvar
        clr.l   d0
        move.b  (a0),d0
        asl.w   #8,d0
        move.b  $1(a0),d0
        bra     printdecimald0

exit
* from, dir, status, newroom
        bsr     getvar
        move.b  $1(a0),d7               * from
        bsr     getvar
        move.b  $1(a0),d6               * direction
        bsr     exit1
* d4.b=status byte, d5=to room
        bsr     getvar
        and.b   #$70,d4
        lsr.b   #4,d4
        move.b  d4,$1(a0)
        clr.b   (a0) * reset high byte
        bsr     getvar
        move.b  d5,$1(a0)
        clr.b   (a0) * reset high byte
        rts

exit1
*given d7=from, d6=direction, return d4.b=status, d5.b=to room
        move.l  exitsptr,a0
        move.b  d7,d1
        subq.b  #1,d1                   * decrement room counter
        beq.s   exit3
exit2
        move.b  (a0),d0

	bne.s	exit2a ;>>mike 8/8/87
; all-zero status - maybe end of table?
	tst.b	$1(a0) ;>>mike 8/8/87
	beq.s notfn4 ;>>mike 8/8/87 - yes - so try reversible directions

exit2a
        addq.l  #2,a0
        btst    #7,d0
        beq.s   exit2                   * not end of room list
        subq.b  #1,d1
        bne.s   exit2
* got room d7
* now find entry direction d6.b
exit3
        move.b  (a0)+,d0
        move.b  d0,d4                   * status byte
        and.b   #$0f,d0	* separate out direction
        cmp.b   d6,d0
        bne.s   exit4
* got an entry
        move.b  (a0),d5                 * get to room
        rts
exit4
        btst    #7,d4
        bne.s   notfn4                  * end of entries for this room - now try reversibles
        addq.l  #1,a0
        bra.s   exit3

notfn4
* first pass failed, so try reversible exits
* first invert direction
        lea     exitreversaltable,a0
        move.b  $0(a0,d6),d0
        move.b  d0,d6
* find exit going to room d7.b, direction d6.b, reversible
        move.l  exitsptr,a0
        move.b  #1,d5                   * room counter (TO room)
exit5
        move.b  (a0)+,d0
        move.b  d0,d4                   * status byte
        btst    #4,d0                   * reversible
        beq.s   exit6
* it's reversible, but is it in the right direction ?
        and.b   #$0f,d0
        cmp.b   d0,d6
        bne.s   exit6
* and does it go to the right place ?
        move.b  (a0)+,d0
        cmp.b   d7,d0
        beq.s   exitret                 * found it!
        bra.s   exit6noinc
exit6
* try another exit
        addq.l  #1,a0
exit6noinc
        btst    #7,d4                   * test status on previous exit
        beq.s   exit7
        addq.b  #1,d5                   * inc room number
exit7
        tst.b   d4                      * at end of exits file ?
        bne.s   exit5
        move.b  #0,d5                   * no destination found
exitret
        rts

exitreversaltable
        dc.b    0,4,6,7,1,8,2,3,5,10,9,12,11,13,14,15


getnextobject       
* given: hisearchpos,searchpos
* return: object,number of of object in this pass
* if hi,searchpos=0 then initialise search
* at end of search, return object=0

* in getnextobject, the following reigsters are used for speed:
* d2=maxobject      a2=gnoscratch
* d3=hisearchpos    a3=gno SP
* d4=searchpos      a4=list2 base
* d5=object
* d6= hipos

* transfer the constants to registers
        clr.w   d2
        clr.w   d3
        clr.w   d4
        clr.w   d5
        move.b  object,d5               * set up object
        move.l  list2ptr,a4             * a2=list 2 base
        bsr     getvar
        move.b  $1(a0),d2               * set up maxobject
        lea     gnoscratch,a2
        move.l  gnosp,a3

        bsr     getvar
        move.b  $1(a0),d3               * set up hisearchpos
        lea     hisearchposvar,a1
        move.l  a0,(a1)

        
        bsr     getvar
        move.b  $1(a0),d4               * set up searchpos
        lea     searchposvar,a1
        move.l  a0,(a1)

gnoabs
        move.b  d4,d0                   * searchpos
        or.b    d3,d0                   * hisearchpos,searchpos
        beq     initgetobjsp            * set up,ret
        
        lea     numobjectfound,a0
        tst.b   (a0)
        bne.s   gnonext
* start of a new pass
        lea     inithisearchpos,a0
        move.b  d3,(a0)

gnonext
        addq.b  #1,d5                   * object        
        cmp.b   $0(a4,d5.w),d4          * list2(object),searchpos
        beq     gnomaybefound
        cmp.b   d5,d2                   * if maxobject>=object ?
        bcc.s   gnonext
* no, so have reached end of current pass
        lea     inithisearchpos,a0
        cmp.b   #nonspecific,(a0)       * inithisearchpos
        bne.s   gnonewlevel
* started off as non-specific search, so there
* may be unscanned directions to try
        move.b  #0,$0(a2,d3)            * gnoscratch(hisearchpos)=0
        move.b  #0,d3                   * hisearchpos=0
gnoloop
        tst.b   $0(a2,d3)               * gnoscratch(hisearchpos)
        beq.s   gnoloop1
        move.b  d4,-(a3)                * push searchpos
        move.b  d3,-(a3)                * push hisearchpos
gnoloop1
        addq.b  #1,d3                   * inc hisearchpos
        cmp.b   #nonspecific,d3         * hisearchpos<nonspecific ?
        bcs.s   gnoloop
gnonewlevel
        bsr     gnopop                  * get hisearchpos and searchpos
        lea     numobjectfound,a0
        move.b  #0,(a0)
        cmp.b   #nonspecific,d3         * hisearchpos
        bne.s   gnonewlevelcont
* nonspecific hisearchpos, so this is a real new level
        lea     searchdepth,a0
        addq.b  #1,(a0)
gnonewlevelcont
        bsr     initgetobj
        tst.b   d4                      * searchpos
        bne.s   gnoabs
gnofinish
        move.b  #0,d5                   * object
        move.b  d5,d3                   * hisearchpos
        move.b  d5,d4                   * searchpos
gnoreturnargs
* copy all data registers back to workspace
        lea     object,a0
        move.b  d5,(a0)
        lea     gnosp,a0
        move.l  a3,(a0)                 * save internal sp

* and return args to acode

        move.l  hisearchposvar,a0
        move.b  d3,$1(a0)
        move.l  searchposvar,a0
        move.b  d4,$1(a0)
        bsr     getvar
        move.b  d5,$1(a0)               * return object
        clr.b   (a0) * reset high byte
        bsr     getvar
        lea     numobjectfound,a1
        move.b  (a1),$1(a0)             * return numobjectfound
        clr.b   (a0) * reset high byte
        bsr     getvar
        lea     searchdepth,a1
        move.b  (a1),$1(a0)             * return searchdepth
        clr.b   (a0) * reset high byte
        rts

gnomaybefound
* a quick check suggests we may have something here
* get d6=hipos(object)
        move.l  list3ptr,a1
*       move.b  object,d0
        move.b  $0(a1,d5),d6            * d5 = current object
        and.b   #$1f,d6
        cmp.b   d6,d3                   * hipos,hisearchpos
        beq.s   gnofound
        tst.b   d6                      * is hipos=0 ?
        beq     gnonext
        tst.b   d3                      * is hisearchpos=0 ?
        beq     gnonext
* want same object in different containment
        cmp.b   #nonspecific,d3         * hisearchpos=nonspecific?
        beq.s   gnomf1
* gotcha - so note it down for reference at end
        move.b  d6,$0(a2,d6)            * gnoscratch(hipos)=hipos
        bra     gnonext

gnomf1
* start looking for this type rather than nonspecific type
        move.b  d6,d3                   * hisearchpos:=hipos
gnofound
        lea     numobjectfound,a0
        addq.b  #1,(a0)
        move.b  d5,-(a3)                * push object
        move.b  #nonspecific,-(a3)      * push nonspecific
* found object, so return it to calling prog
        bra     gnoreturnargs
*
initgetobjsp
        lea     gnospinitial,a3 * set up gno stack pointer
        lea     searchdepth,a0
        move.b  #0,(a0)
        bsr.s   initgetobj
        bra     gnoreturnargs

initgetobj
        lea     numobjectfound,a0
        move.b  #0,(a0)
        lea     object,a0
        move.b  #0,d5                   * object
        move.b  d5,(a0)
        move.l  a2,a0                   * gnoscratch pointer
        move.b  #nonspecific,d0
igo1
        move.b  #0,(a0)+                * gnoscratch(d0)=0
        subq.b  #1,d0
        bne.s   igo1
        rts

gnopop
        lea     gnospinitial,a0
        cmp.l   a0,a3
        beq.s   gnopoperror
        move.b  (a3)+,d3                * pop hisearchpos
        move.b  (a3)+,d4                * pop searchpos
        rts

gnopoperror
        move.b  #0,d3
        move.b  #0,d4
        rts
                

*       ---

jump
        clr.w d0
        move.b (a5)+,d0
        move.b (a5)+,d1
        asl.w #8,d1
        or.w d1,d0
        move.w d0,-(sp) * rel pos of jump table
        bsr getvar
* (a0).w is value of variable
        clr.l   d0
        move.w  (a0),d0
        asl.w   #1,d0
        add.w   (sp)+,d0
        move.l  acodeptr,a0
        add.l   d0,a0
* a0 = offset of new code from start of acode
        clr.l   d0
        move.b  $1(a0),d0 * high byte
        asl.w   #8,d0
        move.b  (a0),d0 * low byte
        move.l  acodeptr,a0
        add.l   d0,a0
        move.l  a0,a5
        rts

ilins
        move.b  -(a5),d0
        bsr hexbyted0
        bsr     prs
        dc.b    cr,'Illegal instruction',cr,0
        even

        bsr debugging * ?????

fatalerror
        bsr     prs
        dc.b    cr,'fatal error. Press space to return to Gem',cr,0
        even

fatalerror1
        move.b  #osrdchdcode,d0
        bsr     driver
        cmp.b   #' ',(a6)               * examine character typed (if any)
        bne.s   fatalerror1
        bra     returntogem

printinput
* acode instruction with no arguments
* print last input word processed
* now always prints dictionary word

*       move.w  keywordnumber,d1
*       cmp.w   #$ffff,d1
*       bne.s   printinput2             * matched in dictionary
        lea     obuff,a0
printinput1
        move.b  (a0)+,d0
        cmp.b   #' ',d0
        beq.s   printinputret
        bsr     printchar
        bra.s   printinput1
*printinput2
** print a word from dictionary
*       movem.l a5-a6,-(sp)
**2     bsr     displaywordref          * display word d1
*       movem.l (sp)+,a5-a6
printinputret
        rts

crlfret
        move.b  #crlf,(a6)
        move.b  #oswrchdcode,d0
        bra     driver


input
*       bsr     inputdebugging
        movem.l a5-a6,-(sp)
        bsr.s   corruptinginput
        move.l  list9startptr,a0                * ????
        movem.l (sp)+,a5-a6
        addq.l  #4,a5                           * skip variable parameters
        rts

corruptinginput
* input routine which corrupts everything !
* if last input returned end or line, then get more input from user
        move.l  list9startptr,a0
        lea     list9ptr,a1
        move.l  a0,(a1)
        lea     ibuffpointer,a4
        move.l  (a4),d0
        bne.s   ip04
* get keyboard input
        bsr     flush
        bsr     wrapreset
*       bsr     hardinputdebugging
        lea     ibuff,a6
        move.b  #inputlinedcode,d0
        bsr     driver
        move.l  a6,(a4)                 * set up ibuffpointer
ip04
* a4 is lea ibuffpointer
* copy next input word to obuff converting to upper case
* and removing transparent characters
        move.l  (a4),a6
* a6 is address of end of previous word
        lea     obuff,a2
ip05
        move.b  (a6)+,d0                * get character from input word
        beq     ip20                    * end of input
        bsr     partword                * could d0.b be part of a word ?
        beq.s   ip06                    * yes
* no - so return it as an ascii character,  unless it's just a space
        cmp.b   #' ',d0
        beq.s   ip05
        move.l  a6,(a4)                 * write pointer back to ibuffpointer
        move.l  list9ptr,a0
        move.b  #0,(a0)+                * write to list9
        move.b  d0,(a0)+                * write to list9
        move.b  d0,(a2)                 * write to obuff
        move.b  #' ',(a2)
        lea     keywordnumber,a1
        move.w  #$ffff,(a1)             * force printinput to print obuff
        bra     ip19a                   * return list9 terminating zeros and return to acode

ip06
        subq.l  #1,a6                   * only executed for first char of word
ip06loop
        move.b  (a6)+,d0
        bsr     partword
        bne.s   ip06a
* copy one character of word
        bsr converttolowercase
        move.b  d0,(a2)+                * write to obuff
        lea     obuff,a1                * is the
        add.l   #31,a1                  * buffer full ?
        cmp.l   a1,a2
        bcs.s   ip06loop
* buffer full, simulate end of word

ip06a
        move.b  #' ',(a2)               * write to obuff
*ip09
        subq.l  #1,a6   * make a6 point to char which caused the copy to stop
        move.l  a6,(a4) * set up ibuffpointer

;* now code to use uncompressed text .....
;* word to analyse is (obuff.l).s, terminated by space
; move.l a2,a4 * preserve it
; move.l list9startptr,a0
; lea list9ptr,a1
; move.l a0,(a1) * set up pointer for returns
;* now find text...
; move.l        startmd,a0 * set up pointer to message text
;ipm1
; cmp.b #'[',(a0)+
; bne.s ipm1
;* check for end of file
; cmp.b #'œ',(a0)
; beq ipmret
;* now skip over number
;ipm2
;* preserve address of message number
; lea numberaddress,a1
; move.l a0,(a1)
;ipmskipcolon
;* skip over colon
; cmp.b #':',(a0)+
; bne ipmskipcolon
; move.w d0,d7 * preserve message number
;ipm3
;* have got the start of a message. Now compare
;* marked words with the input...
;
;* find a marked word..
; move.b (a0)+,d0
; cmp.b #'^',d0
; beq.s ipmmarked
; cmp.b #']',d0
; bne.s ipm3
;* end of message. Go back for more...
; bra.s ipm1
;
;ipmmarked
;* have found a marked word, type is (a0.l).b
; move.b (a0)+,d6 * preserve type
;ipmfindword
; move.b (a0)+,d0
; bsr isd0alphanumeric
; tst.b d0
; beq.s ipmfindword * not got to word yet...
;* now compare the word itself
; lea obuff,a4 * pointer to input word
;ipmf1
; bsr converttolowercase
; move.b (a4)+,d1
; cmp.b #' ',d1
; beq.s ipmmatch * got to end of input word without error
; cmp.b d0,d1
; bne.s ipm3 * find another marked word
; move.b (a0)+,d0
; bra.s ipmf1
;
;ipmmatch
; move.l a0,-(sp)
; move.l numberaddress,a0
; bsr readdecimal
; move.l (sp)+,a0
; move.w d0,d7 * save message number
;* know d7.w=message number, d6.b=type letter
; dc.w $4afa
; move.b d6,d0
; bsr converttolowercase
; clr.b d6
; cmp.b #'v',d0
; bne.s ipmnotverb
; move.w #$2000,d6
;ipmnotverb
; cmp.b #'j',d0
; bne.s ipmnotconjunction
; move.w #$4000,d6
;ipmnotconjunction
; cmp.b #'p',d0
; bne.s ipmnotprep
; move.w #$6000,d6
;ipmnotprep
; cmp.b #'n',d0
; bne.s ipmnotnoun
; move.w #$8000,d6
;ipmnotnoun
; cmp.b #'a',d0
; bne.s ipmnotadj
; move.w #$a000,d6
;ipmnotadj
; cmp.b #'c',d0
; bne.s ipmnotc
; move.w #$c000,d6
;ipmnotc
;* now d6.w = word type in appropriate form. merge with message number
; or.w d6,d7
;
;* return them to acode in standard form!
;       lea     list9ptr,a0
;       move.l  (a0),a1
;       move.b  d7,$1(a1)
;       lsr.w   #8,d7
;       move.b  d7,(a1)
;       addq.l  #2,a1
;       move.l  a1,(a0) * write pointer back to list9ptr
;       sub.l   #32,a1  * space allowed for returns
;       cmp.l   list9startptr,a1
;       bcs     ipm3 * try finding some more matches
;* list9 full
; rts
;
;ipmret
; move.l list9ptr,a0
; clr.b (a0)+
; clr.b (a0)+
; rts
;*---------

* convert word in obuff to word number

        lea     abrevword,a1
        move.w  #$ffff,(a1)
        lea     keywordnumber,a1
        move.w  #$ffff,(a1)
        move.l  list9startptr,a0
        lea     list9ptr,a1
        move.l  a0,(a1)

        bsr     setindex
* now a0.l=address of start of index table
* d2.w is number of segments left
        move.b  obuff,d0
        sub.b   #'a',d0
        bcc.s   ip10
        
* first character not ascii, so must be in first segment
* first segment has no pointer,
* dictionary address = start of dictionary, first wordnumber=0
        move.b  startfile+7,d0
        asl.w   #8,d0
        move.b  startfile+6,d0
        move.w  d0,a6
* a6=wordaddress(z80) = start of word dictionary
        move.w  #0,d1                   * set up word number in first segment
        bra.s   ip13gotwordnumber

ip10
* d0.b is first letter of input word-'a'
* i.e. if it is alpha, it has a code 0-25
        move.w  #103,d1 * number of last segment (?)
        cmp.b   #26,d0
        bcc.s   ip13    * why is this different to case above   ?????
* ip11
        asl.b   #2,d0
        move.b  d0,d1 * d1 is now segment number based on first char
* if there is a second character in the input word, 
* we can be more precise:
        move.b  obuff+1,d0
        cmp.b   #' ',d0
        beq.s   ip13 * have to make do with segment number in d1
ip12
        sub.b   #'a',d0
        lsr.b   #3,d0
        and.b   #3,d0   * get an extra two bits resolution on   segment number
        add.b   d0,d1

ip13
* d1.b is segment number
* now find a6.w as address of dictionary segment relative to startfile
* and d1.w as first word number of this segment
        cmp.b   d2,d1 * d2.w=number of segments in file (from setindex)
        bcc     ip22  * no such segment
* a0.l is start of index table(from setindex)
* clear high 3 bytes of d1
        move.b d1,-(sp)
        clr.l d1
        move.b (sp)+,d1
        
        asl.w   #2,d1   * get index into index table (4 bytes per entry)
        add.l   d1,a0
* a0=entry in index table
        move.b  $1(a0),d0
        asl.w   #8,d0
        move.b  (a0),d0
        move.w  d0,a6   * get relative address of dictionary segment
        move.b  $3(a0),d1
        asl.w   #8,d1
        move.b  $2(a0),d1

ip13gotwordnumber
* have got d1.w as word number at start of segment
* and a6.l as address of dictionary block

        move.l  a6,a0   * for use by initdict
        move.w  d1,d7   * preserve word number for use in ip14-ip17
        bsr     initunpack
ip14
        bsr     unpackword

        bne     ip21b                   * end of dictionary
* have a word in threecharacters
* try comparing it with the input word
        lea     obuff,a0
        lea     threecharacters,a1
        move.b  #-1,d6                  * no. of chars which match
ip15
        addq.b  #1,d6
        move.b  (a1)+,d0                * word from dictionary
        and.b   #$7f,d0
        bsr     converttolowercase
        
        move.b  (a0)+,d2                * word from user input
        cmp.b   d2,d0
        beq.s   ip15
* ip16
        cmp.b   #' ',d2                 * end of input word ?
        bne.s   ip17
* yes, so was it a complete match ?
        tst.b   d0
        beq.s   ip18
* no, so can we take it as an abbreviation
        move.w  abrevword,d0
        cmp.w   #$ffff,d0
        bne     ip22

* how many characters matched ?
        cmp.b   #4,d6
        bcc.s   ip18
* could be an abbreviation
        lea     abrevword,a0
        move.w  d7,(a0)                 * write wordnumber
        bra.s   ip17b

ip17
        move.w  abrevword,d0
        cmp.w   #$ffff,d0
        beq.s   ip17b
* have already had an abbreviated word,
* so can't accept another unsatisfactory one
        move.w  #$ffff,d0
        bra.s   ip18b
ip17b
        addq.w  #1,d7                   * inc wordnumber
        bra     ip14

ip18
* have got word number in d7.w
* now fill list9 with a sequence of possible word-type/message-number
* possibilities terminated by $00 $00

        move.w  d7,d0
ip18b
        lea     keywordnumber,a0
        move.w  d0,(a0)                 * write to keywordnumber for benefit    of      printinput
        movem.l d3-d7,-(sp)
        bsr     findmsgequiv
        movem.l (sp)+,d3-d7
        lea     abrevword,a0
        move.w  #$ffff,(a0)
        move.l  list9ptr,a0
        cmp.l   list9startptr,a0
        beq.s   ip17b                   * no words found - garbage word
* ip19
* a0=(list9ptr)
ip19a
        move.b  #0,(a0)+                * write double zero to indicate end of input list
        move.b  #0,(a0)+
        rts                             * return to acode

ip20
        lea     ibuffpointer,a0
        move.l  #0,(a0)                 * zero ibuffpointer - forced to get input next time
        move.l  list9ptr,a0
        bra.s   ip19a                   * write double zero and return
ip21
        rts                             * return to acode

ip21b
        move.w  abrevword,d0
        cmp.w   #$ffff,d0
        bne.s   ip18b                   * write abrevword to keywordnumber
ip22
* not a keyword, try it for a number
        move.b  obuff,d0
        cmp.b   #'0',d0
        bcs.s   ip22z
        cmp.b   #'9'+1,d0
        bcc.s   ip22z
        lea     obuff,a0
        bsr     readdecimal
* returns number in d0.l
        move.l  list9ptr,a0
        move.b  #1,(a0)+ ; 1 indicates this is a number
        move.w  #3,d1
ip22b
        move.b  d0,(a0)+
        lsr.l   #8,d0
        dbne    d1,ip22b
        bra.s   ip19a                   * terminate with zero's and return

ip22z
* garbage word - return $00 $80
        move.l  list9ptr,a0             * ?? was list9startptr
        move.b  #$00,(a0)+
        move.b  #$80,(a0)+
        bra.s   ip19a                   * write 00 00 to (a0) and return

findmsgequiv
* given word number d7.w
* return in list9 lots and lots of messages containing
* meaningful (marked) references to it
* variables used:
* d4 - current message number
* a2 - current position in message descriptors
        clr.w   d4                      * reset message number
        move.l  startmd,a2              * set up pointer to message descriptors
        bra.s   fe02

fe01
        addq.w  #1,d4                   * inc message number
fe02
        cmp.l   endmd,a2                * have we passed the end of message descriptor table
        bhi     feret                   * unsigned a2>endmd - have searched all messages
        move.b  (a2),d0
        btst    #jumphbit,d0            * jump header ?
        bne.s   fe03
* found a message header
        btst    #parsebit,d0
        bne.s   fefoundheader           * contains keywords

* skip message
        bsr     getmdlength *returns d6.l

        add.l   d6,a2                   * d6=length
        bra.s   fe01

fe03
* jump in message numbering
        addq.l  #1,a2   * skip message header
        and.w   #$007f,d0
        add.w   d0,d4   * allow for gap
        bra.s   fe01 * inc d4 - given value of zero gives gap of one

fefoundheader
* was fe04
* have found a message header which contains keywords
        bsr     getmdlength
        bra.s   fe07
feskipbyte
        addq.l  #1,a2
        subq.w  #1,d6                   * decrement length due to byte fetched
fe05
* loop through message finding any references
fe07
        tst.w   d6
        beq.s   fe01                    * if message length=0, nothing to print
* must preserve d6.w as message length
        clr.w   d1
        move.b  (a2)+,d1
        subq.w  #1,d6                   * decrement length due to byte fetched
        btst    #longbit,d1
        beq.s   fe07                    * short form reference - no meaning
* felongform
* long form reference
        cmp.b   #$90,d1
        bcs.s   feskipbyte              * garbage word
        asl.w   #8,d1                   * move first byte to hi-order
        move.b  (a2)+,d1                * and low byte
        subq.w  #1,d6                   * decrement length due to extra byte    fetched
        move.w  d1,d0
        and.w   #$0fff,d0

* compare with word we're looking for
        cmp.w   d7,d0
        bne.s   fe07                    * not same, so get another from dictionary
* d1.w contains whole word, high-bits are word type
* write it to list 9 in appropriate format:
        asl.w   #1,d1
        and.w   #$e000,d1
        or.w    d4,d1                   * add in message number
        lea     list9ptr,a0
        move.l  (a0),a1
        move.b  d1,$1(a1)
        lsr.w   #8,d1
        move.b  d1,(a1)
        addq.l  #2,a1
        move.l  a1,(a0)                 * write pointer back to list9ptr
        sub.l   #32,a1                  * space allowed for returns
        cmp.l   list9startptr,a1
        bcs     fe05
* list9 full
feret
        rts

initunpack
        bsr     initdict
        move.w  #header,d3              * lastheader on z80
* drop through to unpackword

unpackword
        cmp.b   #endseg,d3              * padder at end of segment
        beq.s   uwendofseg
        and.l   #3,d3
        lea     threecharacters,a3
        add.l   d3,a3                   * get pointer to expansion buffer allowing      for     similarity
uw01
        bsr     getdictionarycode
        move.l  endwdp5,a0
        cmp.l   a0,a6                   * at end of dictionary ??
        bcc.s   uwendofdictionary
        cmp.b   #endseg,d0
        bcc.s   uw03
* not a header
        bsr     getdictionary
        move.b  d0,(a3)+
        bra.s   uw01

uw03
        move.b  d0,d3                   * lastheader on z80
        move.b  #0,(a3)+
* z condition returned
        rts

uwendofseg
uwendofdictionary
        move.b  #1,d0                   * ret nz
        rts


*       ---
                

partword
* return z (and d1.b=0) if d0.b could be part of a word
        bsr     converttolowercase
        move.b  #0,d1                   * default is ok - is part of a word
        cmp.b   #'''',d0                * appostraphe
        beq.s   pw02                    * ok
        cmp.b   #'-',d1                 * hyphen
        beq.s   pw02                    * ok
        cmp.b   #'0',d0
        bcs.s   pw01                    * false
        cmp.b   #'9'+1,d0
        bcs.s   pw02                    * ok
        cmp.b   #'a',d0
        bcs.s   pw01                    * false
        cmp.b   #'z'+1,d0
        bcs.s   pw02                    * ok
* not part of a word
pw01
        move.b  #1,d1
pw02
* d1=0 if d0.b could be part of a word
        tst.b   d1
        rts                             * return appropriate flag in d1.b

printmessage
* print message number d0
        bsr     printmessagedebugging
        move.l  a5,-(sp)
        move.l  a6,-(sp)
        bsr.s   absprintmessage
        move.l  (sp)+,a6
        move.l  (sp)+,a5
        rts

;absprintmessage
;* print message d0.w
;* (from uncompressed text)
; move.w d0,d7 ; put it somewhere safe...
; move.l        startmd,a0 * set up pointer to message text
;* skip to next message (denoted by "[")
;apm1
; cmp.b #'[',(a0)+
; bne.s apm1
; bsr readdecimal * at correct message?
; cmp.w d0,d7
; beq.s apmfound
; bhi.s apm1 * try again
;* not found, just ignore at present
; rts
;
;apmfound
; addq.l #1,a0 * skip over colon
;
;* now print message until ']'
;apm2
; move.b (a0)+,d0
; cmp.b #']',d0
; beq.s apmret
; cmp.b #'|',d0
; beq.s apmret
; cmp.b #'^',d0
; bne.s apmnotmarked
; addq.l #1,a0 * skip word type
; bra.s apm2
;
;apmnotmarked
; cmp.b #'_',d0
; beq.s apmspace * forced space
; cmp.b #cr,d0
; beq.s apmspace * crs are treated as spaces..
; cmp.b #lf,d0
; beq.s apmspace * lfs are treated as spaces..
; cmp.b #' ',d0
; bne.s apmnotspace
;apmspace
; move.b #' ',d0
;* skip multiple spaces
; lea apmlastcharprinted,a1
; cmp.b (a1),d0 * d6.b=last char printed
; beq.s apm2
;
;apmnotspace
; cmp.b #'%',d0
; bne.s apmnotpercent
; move.b #cr,d0
;
;apmnotpercent
;* preserve last char printed in d6.b
; lea apmlastcharprinted,a1
; move.b d0,(a1)
; bsr printchar
; bra apm2
;apmret
; rts
;
;
;*-----
absprintmessage
* can (and does!) corrupt all registers
* The use of some registers is fairly constant in this routine:
* d0 - general parameter and scratch
* d1 - word number (and scratch)
* d2 - number of segments left and scratch
* d3 - NOT USED !
* d4 - no. of chars same as previous word
* d5 - word type
* d6 - message length
* d7 - message number

* a0 - general parameter and scratch
* a1 - scratch
* a2 - pointer to message decriptors
* a3 - pointer to expansion buffer
* a4 - start of common word dictionary
* a5 - getdictionarycode pointer to its private-use buffer
* a6 - address in dictionary of packed form


        move.w  d0,d7                   * store it away somewhere more sensible
* first set up some useful values in registers
        clr.l d1
        move.b  startfile+15,d1 * common word dictionary rel to data block
        asl.w   #8,d1
        move.b  startfile+14,d1
        lea     startfile,a4
        add.l   d1,a4                   * a4 = start of common word dictionary
        lea     unpackbuffer,a5 * a5 = start of unpack buffer
        move.b  #8,d4                   * d4 = number of characters in unpack buffer

        move.l  startmd,a2              * set up pointer to message descriptors

* search through message descriptor table, decrementing
* message number d7.w until =0
LM01
        cmp.l   endmd,a2                * have we passed the end of message descriptor table
        bhi     LMret                   * unsigned a2>endmd
        tst.w   d7                      * is message number = 0 ?
        beq.s   LMfoundheader
        move.b  (a2),d0
        btst    #jumphbit,d0            * jump header ?
        bne.s   LM02
* skip message
        bsr.s   getmdlength
        add.l   d6,a2                   * d6=length
* end of message
        subq.w  #1,d7                   * decrement message counter
        bra.s   LM01

LM02
* jump in message numbering
        addq.l  #1,a2                   * skip message header
        and.w   #$007f,d0
        subq.w  #1,d7                   * given value 0 gives actual gap of 1
        sub.w   d0,d7                   * allow for gap
        bpl.s   LM01                    * sign set up on word size of previous sub
LMret
        rts

LMfoundheader
* was LM04
* have found required message header
        move.b  (a2),d0
        btst    #jumphbit,d0
        bne.s   LMret                   * jump header (so ???)
        bsr.s   getmdlength
LM05
* loop through message until length to print=0
        tst.w   d6
        beq.s   LMret                   * if message length=0, nothing to print
* must preserve d6.l as message length
        clr.w   d1
        move.b  (a2)+,d1
        subq    #1,d6                   * decrement length due to byte fetched
        btst    #longbit,d1
        bne.s   LMlongform
* short form reference
        add.w   d1,d1         * set of two byte word numbers
        move.b  $0(a4,d1),d2  * build up word number in (not necessarily
        asl.w   #8,d2         *       word-aligned)
        move.b  $1(a4,d1),d2
        move.w  d2,d1
* now d1=word number
        bra.s   LM07

LMlongform
* long form reference
        asl.w   #8,d1                   * first byte is hi-order
        move.b  (a2)+,d1                * and low byte
        subq.w  #1,d6                   * decrement length due to extra byte    fetched
LM07
* display word reference d1.w
        cmp.w   #$8f80,d1               * is it a | terminator ?
        beq.s   LMret                   * if so, nothing more to display
        bsr.s   displaywordref
        bra.s   LM05

* ---

getmdlength
* a2 is the address in the message descriptors of a message header
* return: a2=address of the first word rrrreference of that 
* message, d6.w as the length in bytes of that message
        clr.l   d6
gmdl01          
        move.b  (a2)+,d1
        and.b   #$3f,d1
        subq.b  #1,d1 * if bits 0:5 are 0, will wrap round to $ff
        and.w   #$3f,d1 * if this happens, another byte is used to      extend
        add.w   d1,d6   * the length
        cmp.b   #$3f,d1
        beq.s   gmdl01
        rts

*       ---

displaywordref
* display word reference d1.w
* preserve d6,d7,a2
        lea     wordcase,a0
        move.b  #0,(a0)                 * reset flag
        move.w  d1,d5
        lsr.w   #8,d5                   * get word type
        lsr.w   #4,d5                   * get word type
        and.b   #$07,d5                 * strip top bit, just leaving wordtype
        and.w   #$0fff,d1               * remove wordtype

        cmp.w   #$f80,d1
        bcs     dwr01
* single ascii character specified
        btst    #1,d5                   * wordtype
        beq.s   dwrnoprespace
        move.b  #' ',d0
        bsr     printchar
dwrnoprespace
        lea     mdtmode,a0
        move.b  #2,(a0)

        move.b  d1,d0                   * character to print
        and.b   #$7f,d0                 * was $f80+ascii code, so strip off top bit
        cmp.b   #flushcode,d0
        beq.s   dontdisplayit
        bsr     printchar
dontdisplayit
        btst    #0,d5                   * wordtype
        beq.s   swrnopostspace
        move.b  #' ',d0
        bsr     printchar
swrnopostspace
        rts

dwr01
* d1.w=reference to real word
        lea     mdtmode,a0
        cmp.b   #1,(a0)
        bne.s   dwr01a
        move.b  #' ',d0
        bsr     printchar
dwr01a
        move.b  #1,(a0)                 * mdtmode
* display word number d1.w
        bsr     setindex
        move.l  a0,-(sp)                * save starting index address
dwr02
* d1.w is word number to display
* a0.l is address of current index entry
* d2.w is number of index segments left
        tst.w   d2                      * run out of segments ?
        beq.s   dwr04
        clr.w   d0
        move.b  $3(a0),d0
        asl.w   #8,d0
        move.b  $2(a0),d0
        cmp.w   d1,d0                   * gone past word number to display ?
        bhi.s   dwr04
* not gone past yet, so try another
        addq.l  #4,a0
        subq.w  #1,d2
        bra.s   dwr02

dwr04
* have just gone past word reference pointer, 
* if we are still on the first table entry, then
* the word reference was to segment -1
* (should be zero except for a bug or whatever in the squasher)
        cmp.l   (sp)+,a0
        bne.s   dwr04a
* so we ARE still on the first entry.
* the real data on this segment is set up as follows:
* first word of segment is number 0, so d1.w is alread relative
* to segment start. Copy it into d7.w for future use
        move.w  d1,d7
* address of segment is the address of the dictionary itself
        move.b  startfile+7,d0
        asl.w   #8,d0
        move.b  startfile+6,d0
        move.w  d0,a0                   * for use by initdict
        bra.s   dwr04b

dwr04a
* not segment -1,
* so step back one entry to get pointer to the segment
* containing the word we want
        subq.l  #4,a0
* get word reference at start of this block in d0.w
        move.b  $3(a0),d0
        asl.w   #8,d0
        move.b  $2(a0),d0
        sub.w   d0,d1
        move.b  d1,d7
* store away relative wordaddress
        move.b  $1(a0),d0
        asl.w   #8,d0
        move.b  (a0),d0
        move.w  d0,a0                   * for use by initdict
dwr04b
* d7.w is now the number of the word within this segment
* and a6.l the address within the dictionary of the packed form
* need to increment d7.w before starting due to layout of loop
        addq.b  #1,d7
        bsr     initdict
        bra.s   dwr05                   * find it !

dwr06A
        bsr     getlongcode
        bra.s   dwr06B

dwr06
* not a header
        cmp.b   #longc,d0
        bcc.s   dwr06A
* normal alpha
        add.b   #'a',d0
dwr06B
        move.b  d0,(a3)+
*
dwr05
* d7.w is number of word within current segment
        bsr     getdictionarycode
        cmp.b   #header,d0
        bcs.s   dwr06
        and.l   #$00000003,d0   * get number of characters same as      previous        word
        lea     threecharacters,a3
        add.l   d0,a3   * a3 now points to point of word to which to start expanding
        subq.b  #1,d7
        bne.s   dwr05           * if not reached word we want,  go      for     more    data
*
        lea     threecharacters,a3
        move.b  d0,d1           * preserve no. of characters same count
dwr09
* have got the start of a word in the threecharacters buffer
* print this out (d1.b characters are the same as previous word)
* tst.b d1 is redundant because last instruction referred to d1
        beq.s   dwr10
        move.b  (a3)+,d0                        * fetch character from threecharacters buffer
        bsr     printautocase
        subq.b  #1,d1                           * decrement no. of characters to print here
        bra.s   dwr09

dwr10
* have printed characters same as previous word
* now print out any subsequent characters
* stored for this word
        bsr.s   getdictionarycode
        cmp.b   #endseg,d0
        bcc.s   dwrret
        bsr.s   getdictionary
        bsr     printautocase
        bra.s   dwr10

*       ---

setindex
* return a0.l = address of first index entry
*        d2.w as no. of segments
        clr.l   d2 * clear high bytes for add
        move.b  startfile+11,d2
        asl.w   #8,d2
        move.b  startfile+10,d2
        lea     startfile,a0
        add.l   d2,a0
        move.b  startfile+13,d2
        asl.w   #8,d2
        move.b  startfile+12,d2
dwrret
        rts

*       ---
        
getdictionary
* d0.b is the current short code
* returns d0.b as the next unpacked ascii code
        cmp.b   #longc,d0
        bcc.s   getlongcode
* normal alpha
        add.b   #'a',d0
        rts
getlongcode
* long escape short code (?)
        bsr.s   getdictionarycode
        cmp.b   #uppercasemark,d0
        bne.s   glc02
* upper-case-only marker
        lea     wordcase,a0
        move.b  #1,(a0)
        bsr.s   getdictionarycode
        bra.s   getdictionary

glc02
        rol.b   #5,d0                   * asl should do as well
        and.b   #$E0,d0
        move.b  d0,-(sp)
        bsr.s   getdictionarycode
        and.b   #$1f,d0
        or.b    (sp)+,d0
        or.b    #$80,d0                 * flag character as a long code
        rts

*       ---

getdictionarycode
* unpack and return byte from word dictionary in d0.b
        cmp.b   #8,d4                   * offset into unpack buffer     
        beq.s   unpackbytes
        move.b  $0(a5,d4),d0
        addq.b  #1,d4
        rts

unpackbytes
        move.b  (a6)+,d0                * aaaaabbb
        move.b  d0,d1                   * preserve it
        lsr.b   #3,d0
        move.b  d0,$0(a5)               * put aaaaa into unpack buffer

        move.b  (a6)+,d0                * bbcccccd
        move.b  d0,d2                   * preserve it
        roxl.b  #1,d0
        roxl.b  #1,d1
        roxl.b  #1,d0
        roxl.b  #1,d1
        and.b   #$1f,d1
        move.b  d1,$1(a5)               * put bbbbb into unpack buffer

        move.b  (a6)+,d0                * ddddeeee
        move.b  d0,d1                   * preserve e's
        roxr.b  #1,d2                   * (d2=bbcccccd - get high bit of d
        roxr.b  #4,d0
        and.b   #$1f,d0
        move.b  d0,$3(a5)               * put ddddd into unpack buffer
        and.b   #$1f,d2
        move.b  d2,$2(a5)               * put ccccc into unpack buffer
  
* d1=ddddeeee
        move.b  (a6)+,d0                * get efffffgg
        move.b  d0,d2                   * preserve it
        roxl.b  #1,d0                   
        roxl.b  #1,d1
        and.b   #$1f,d1
        move.b  d1,$4(a5)               * put eeeee into unpack buffer
* now get fffff, ggggg and hhhhh in one fell swoop (more or less):
        move.b  (a6)+,d1                * get ggghhhhh
        move.b  d1,d0
        and.b   #$1f,d0
        move.b  d0,$7(a5)               * put hhhhh into unpack buffer
        roxr.b  #1,d2
        roxr.b  #1,d1
        roxr.b  #1,d2
        roxr.b  #1,d1
        and.b   #$1f,d2
        move.b  d2,$5(a5)               * put fffff into unpack buffer
        lsr.b   #3,d1
        move.b  d1,$6(a5)               * put ggggg into unpack buffer

        move.b  (a5),d0                 * get first byte of data, so
        move.b  #1,d4                   * offset into unpack pointer is 1 (not 0)
        rts

printautocase
        movem.l d0-d7/a0-a7,-(sp)
        bsr.s   absprintautocase
        movem.l (sp)+,d0-d7/a0-a7
        rts

absprintautocase
        btst    #7,d0                   * long code ?
        bne     printchar
        move.b  wordcase,d1
        bne.s   pac02
        cmp.b   #6,d5                   * d5=wordtype proper noun or upper case 2marked in text
        bcs.s   pac03
        move.b  #0,(a0)                 * zero wordtype flag
pac02
        bsr     converttouppercase
pac03

printchar
        movem.l d0-d7/a0-a7,-(sp)
        bsr.s   printchar1
        movem.l (sp)+,d0-d7/a0-a7
        rts

printchar1
        btst    #7,d0                   * long code ?
        bne.s   pc02
* transparent characters: cr space ' œ $ % & ' ( )
        cmp.b   #flushcode,d0
        beq     pc03
        cmp.b   #' ',d0
        beq.s   pc03
        cmp.b   #$d,d0
        beq.s   pc03
        cmp.b   #'!'+1,d0
        bcs.s   pc00a
        cmp.b   #')'+1,d0
        bcs.s   pc03
pc00a
* sentence terminators: ! ? .
        move.b  lastchar,d1
        cmp.b   #'!',d1
        beq.s   pc01
        cmp.b   #'?',d1
        beq.s   pc01
        cmp.b   #'.',d1
        bne.s   pc02
pc01
        bsr     converttouppercase
pc02
        and.b   #$7f,d0
*       cmp.b #' ',d0           * not in z80 version
*       beq.s   pc03            * not in z80 version
        lea     lastchar,a0
        move.b  d0,(a0)
pc03
        cmp.b   #' ',d0
        bne.s   pc04
        bsr.s   flush
        lea     pendspace,a0
        move.b  #$ff,(a0)
        rts
pc04
        cmp.b   #$d,d0
        bne.s   pc05
        bsr.s   flush
        move.b  #crlf,d0
        bra     wrapoutput
pc05
        move.l  wrapbufferpointer,a0
	cmp.l #WrapBufferEnd,a0 * >>mike 10/1/88
	beq.s pc06 * >>Mike 10/1/88
        move.b  d0,(a0)+
        lea     wrapbufferpointer,a1
        move.l  a0,(a1)
pc06
        rts

* ---

wrapreset
        lea     mdtmode,a0
        move.b  #0,(a0)
        lea     nchars,a0
        move.b  #0,(a0)
        lea     lastchar,a0
        move.b  #'.',(a0)
	bsr.s SetUpWidth
        bra.s   flush6

SetupWidth
 lea     width,a0
 move.b  #screenwidth-1,(a0)
 move.b XScale(PC),d0
 beq.s suwRet
 move.b #39,(a0)
suwRet
 rts
*---

flush
        move.b  pendspace,d0
        beq.s   flush4
        lea     wrapbuffer,a0
        move.l  wrapbufferpointer,d1
        sub.l   a0,d1
        add.b   nchars,d1
        move.b  #' ',d0
        cmp.b   width,d1
        bcs.s   flush3
        move.b  #crlf,d0
flush3
        bsr.s   wrapoutput
flush4
        lea     wrapbuffer,a1
flush5
        cmp.l   wrapbufferpointer,a1
        bcc.s   flush6
        move.b  (a1)+,d0
        bsr.s   wrapoutput
        bra.s   flush5
flush6
        lea     wrapbuffer,a0
        lea     wrapbufferpointer,a1
        move.l  a0,(a1)
        lea     pendspace,a0
        move.b  #0,(a0)
        rts

*       ---

wrapoutput
        cmp.b   #$0d,d0
        bne.s   wrapoutput2
        move.b  nchars,d0
        beq.s   wrapoutput3
        move.b  #crlf,d0
        bsr     absprintchar
wrapoutput1
        lea     nchars,a0
        move.b  #0,(a0)
        bra.s   wrapoutput3
wrapoutput2
        bsr.s   absprintchar
        lea     nchars,a0
        addq.b  #1,(a0)
wrapoutput3
        rts

*       ---


absprintchar
        move.l  a6,-(sp)
        move.w  d0,-(sp)
        lea     intdriverbuffer,a6
        move.b  d0,(a6)
        move.b  #oswrchdcode,d0
        bsr     driver
        move.w  (sp)+,d0
        move.l  (sp)+,a6
        rts
        
initdict
* get absolute address of packed word in a6.l
* given a0= address of word relative to start of file
* clear high bytes of a0.w for add
;        move.w  a0,-(sp)
;        move.l  #0,a0   * clr.l a0 is not allowed
;        move.w  (sp)+,a0
 move.l d0,-(sp)
 move.l a0,d0
 and.l #$ffff,d0
 move.l d0,a0
 move.l (sp)+,d0

        lea     startfile,a6
        add.l   a0,a6
        lea     unpackbuffer,a5
        move.w  #8,d4                   * offset into unpack buffer
        rts

*       ----

printmessagedebugging
* are we running with output disabled ?
        move.b  disableoutput,d1                * can't corrupt d0
        beq.s   pmdret
* we want to measure input + acode speed, so
* discard return address that this is called from (printmessage)
        move.l  (sp)+,a0
pmdret
        rts

hardinputdebugging
* acode has requested input from user
* are we running with OUTPUT disabled:
        move.b  disableoutput,d0
        beq.s   inputdebugret
* running with OUTPUT disabled
* therefore we want to do input as normal,
* but to help the user, print a single character prompt
        move.b  #'?',d0
        bsr     oswrch
inputdebugret
        rts

*       ----

inputdebugging
* are we running with INPUT disabled?:
        move.b  disableinput,d0
        beq.s   inputdebugret
* Don't want to prompt for input.
* unfortunately, were we to do this without precautions,
* nothing would happen. So, what we want to do is to
* allow the user to enter a command, then store up
* the keywords generated by that command.
* these may then be given to acode, which should
* be quick enough
        lea     inputdebugstatus,a0
        move.b  (a0),d0
        bne.s   inputdebug2
* first time we've called input - so let it prompt user
        move.b  #1,(a0)
        rts

inputdebug2
* Are we storing up values for later retrieval ?
        cmp.b   #1,d0
        bne.s   inputdebugretrieve
* yes, so copy input buffer to current position in storage table
        move.l  list9startptr,a0
* was a zero returned ?
        move.b  (a0),d0
        or.b    $1(a0),d0
        beq.s   inputdebugfinished
        move.l  inputdebugptr,a1
        move.b  #32,d1                  * bytes to copy
inputdebug2loop
        move.b  (a0)+,d0
        move.b  d0,(a1)+
        subq.b  #1,d1
        bne.s   inputdebug2loop
        lea     inputdebugptr,a0
        move.l  a1,(a0)
        rts

inputdebugfinished
* have come to the end of the text which was entered
        lea     inputdebugstatus,a0
        move.b  #2,(a0)
        lea     inputdebugblock,a0
        lea     inputdebugptr,a1
        move.l  a0,(a1)

        move.b  #'*',(a5)
        move.b  #oswrchdcode,d0
        bra     driver

inputdebugrfinished
* have come to end of retrieving keywords
* have to return 0 to acode
        move.b  #0,(a1)
        move.b  #0,$1(a1)
        bsr.s   inputdebugfinished
        bra.s   inputdebugr             * remove ret addr, input variables
* ---

inputdebugretrieve
* now go through, copying from buffer to list9
        move.l  inputdebugptr,a0
        move.l  list9startptr,a1
        move.b  (a0),d0
        or.b    $1(a0),d0
        beq.s   inputdebugrfinished
        move.b  #32,d1                  * number of bytes to copy
inputdebugrloop
        move.b  (a0)+,d0
        move.b  d0,(a1)+
        subq.b  #1,d1
        bne.s   inputdebugrloop
        lea     inputdebugptr,a1
        move.l  a0,(a1)
* and discard return address fromp input
inputdebugr
        move.l  (sp)+,a0
        addq.l  #4,a5                   * skip variables after input statement
        rts

*       --------
checksumbyte dc.b checksumvalue
endchecksumarea
 even
*---
        even
*intdriverbuffer
*        ds.b 500
no_caches	dc.w	0
;cache		ds.l	25

savedriverblock
	dc.l	0
	dc.l	0
	dc.b	'xxxxxxxx.xxx',0
	even

gamedatadriverblock
* gives loading data for game data
        dc.l    0                       * used as load address
        dc.l    0
        dc.b    'gamedat1.dat',0
                
        even

*---
*workspacestart
*vartable
** must be on even word boundary
*        ds.b    512     * dcb.b 256,0 on amiga
*listarea
*        ds.b    $600    * dcb.b 512,0 on amiga          * workspace
*        even
*workspaceend
*inputdebugblock
** this is used to store input keywoard values
** 32 bytes per keyword entered, so 1K = 32 keywords
*        ds.b    128 * 1024
