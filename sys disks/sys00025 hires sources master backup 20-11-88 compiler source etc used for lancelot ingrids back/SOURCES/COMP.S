* 68000 Acode compiler
*
* started 18:38 on Tuesday 29/7/86
* last change: 2/6/88
*
* M.J.Austin. Copyright (C) 1988 Level 9 Computing
*
*
* Known bugs:
*
* An attempt to jump to a variable causes the compiler to hang up.
*
* Make sure the appropriate 3 lines at the start of FINISH.S
* are commented out before compiling this file
*
ptr equr a5 * pointer to current pos in file
compacodeptr equr a4 * pointer to code to be generated

* a few constants
*eof equ $1a

 jmp compstart
graphics
 INCLUDE 'DRIVER.S'
 include 'finish.s'
 INCLUDE 'INT.S'
 include 'code.s'

* now some vectors to the real code (probably in driver.s)....
compprs jmp prs

compisd0alphanumeric    jmp isd0alphanumeric
compprintdecimald0      jmp printdecimald0
comphexlonga0           jmp hexlonga0
compdriver              jmp driver
compwaitkey             jmp waitkey
compreaddecimal         jmp readdecimal
comphexbyted0           jmp hexbyted0
compsetsupervisormode	jmp setsupervisormode
compreturntogem call_bdos p_term
		jmp returntogem
compflush
 movem.l d0-d7/a0-a6,-(sp)
 bsr flush
 movem.l (sp)+,d0-d7/a0-a6
 rts
*-------------
compstart
 lea compdriverbuffer,a6
 jsr setsupervisormode
 jsr init1
 jsr init2
 bsr clearsymbols
 bsr wrapreset

 lea CodeState,a0
 move.b #"-",(a0) * set acode generation to start with
 lea CompJumpTable,a0
 lea CurrentJumpTable,a1
 move.l a0,(a1)

 bsr compprs
 dc.b cr
 dc.b 15 * switch off paging
 dc.b "68000 Acode compiler 1.3",cr
 dc.b "Copyright (C) 1988 Level 9 Computing.",cr
 dc.b "M.J.Austin 2/6/88",cr,0
 even

* is there a command file in this directory on the disk?
 bsr compprs
 dc.b cr,"Looking for compilation batch file - 'COMPILE.BAT'",cr,0
 even
 lea loadcommandfile,a6
 lea batchfilebuffer,a0
 move.l a0,(a6) * loading address
 move.b #loaddcode,d0
 bsr compdriver
 cmp.b #1,(a6)
; move.b $4(a6),d0 * end address
 beq compmenu * no, so get instructions from user
 bsr compprs
 dc.b cr,"Executing instructions in file 'COMPILE.BAT'",cr,0
 even
 move.l $4(a6),a0 * end of batch file
 move.b #cr,(a0)+
 move.b #lf,(a0)+

 move.b #eof,(a0)+
 move.b #eof,(a0)+
 move.l (a6),a0
 lea cbatchptr,a1
 move.l a0,(a1) * current batch pointer
 lea cexecutingcommandfile,a0
 move.b #1,(a0)
batchcomp
 lea compdriverbuffer,a6
 pea batchcomp * for error handling
 lea errorstack,a0
 move.l sp,(a0)
 move.l cbatchptr,a0
 move.b (a0)+,d0
 lea cbatchptr,a1
 move.l a0,(a1)
 cmp.b #eof,d0
 beq compmenu * end of batch file, start prompting user
 cmp.b #"1",d0
 beq.s batchcompile
 bsr dojumptable * for normal functions
 bra batchcomp

batchcompile
* get a filename from batch file, then compile it
 bsr compsoftinit
 bsr compprs
 dc.b "Compiling file '",0
 even
 move.l cbatchptr,a0
* copy file name into driverbuffer
 lea $8(a6),a1
compbc1
 move.b (a0)+,d0
 cmp.b #cr,d0
 beq.s compbc2
 move.b d0,(a1)+

 move.b d0,(a6)
 move.b #oswrchdcode,d0
 bsr compdriver
 bra.s compbc1
compbc2
* end of filename, add compterminator
 clr.b (a1)+
 move.l startsource,(a6)
 lea cbatchptr,a1 * and set up batch pointer to after filename
 move.l a0,(a1)

 bsr compprs
 dc.b "'. ",0
 even

 move.b #loaddcode,d0
 bsr compdriver
 cmp.b #1,(a6)
 beq compmenu * not found
 bra abscompilefile
*---
compmenu
 lea cexecutingcommandfile,a0
 clr.b (a0)
 lea compdriverbuffer,a6
 pea compmenu * for error handling
 lea errorstack,a0
 move.l sp,(a0)
 bsr compprs
 dc.b cr
 dc.b " 0 .. Exit to TOS                "
 dc.b " 1 .. Compile Source file",cr

 dc.b " 2 .. Finish acode               "
 dc.b " 3 .. Finish gamedata.dat",cr

 dc.b " 4 .. Save Gamedata and acode    "
 dc.b " 5 .. Run game",cr

 dc.b " 6 .. Toggle debugging info",cr

 dc.b " 7 .. Toggle forced long jumps   "
 dc.b " 8 .. Print symbols",cr

 dc.b " 9 .. Check for unused symbols   "
 dc.b " A .. Toggle printing (to rs232) ",cr
 dc.b cr
 dc.b "Your choice: ",0
 even

compmenu1
 move.b #osrdchdcode,d0
 bsr compdriver
 move.b (a6),d0
 beq.s compmenu1
compmenu2
 cmp.b #cr,d0
 beq compmenu

 move.w d0,-(sp) * echo character typed
 move.b #oswrchdcode,d0
 bsr compdriver
 bsr compprs
 dc.b "  ",0
 even
 move.w (sp)+,d0

 bsr dojumptable
 bra compmenu1 * get another key
*---
dojumptable
* call compiler function by number
 cmp.b #"0",d0
 beq compreturntogem
 cmp.b #"1",d0
 beq compilefile
 cmp.b #"2",d0
 beq finishacode
 cmp.b #"3",d0
 beq finishgamedatainmemory
 cmp.b #"4",d0
 beq savegamedata
 cmp.b #"5",d0
 beq rungame
 cmp.b #"6",d0
 beq toggledebugginginfo
 cmp.b #"7",d0
 beq toggleforcedlongjumps
 cmp.b #"8",d0
 beq printsymboltable
 cmp.b #"9",d0
 beq checkunusedsymbols
 cmp.b #"A",d0
 beq ToggleRS232Printer
 rts
*---
* cmp.b #"0",d0
* beq returntogem
* cmp.b #"1",d0
***22 beq compilefile
* cmp.b #"3",d0
* beq saveacode
* cmp.b #"5",d0
* beq printsymboltable
* cmp.b #"6",d0
* beq toggledebugginginfo
* cmp.b #"7",d0
* beq toggleforcedlongjumps
* rts
*---
ToggleRS232Printer
 lea OutputDevice,a0
 cmp.b #2,(a0) ; currently to CON:?
 beq.s SetRS232
 move.b #2,(a0) ; CON:
 bsr compprs
 dc.b cr,"Printing is now off. ",cr,0
 even
 rts
;---
SetRS232
 move.b #1,(a0) ; AUX:
 bsr compprs
 dc.b cr,"Printing is now on. ",cr,0
 even
 rts
;---
finishgamedatainmemory
 lea finishdriverbuffer,a6
 bsr compprs
 dc.b "Acode finish 1.1",cr
 dc.b "Copyright (C) 1986 Level 9 Computing",cr,cr,0
 even
* this program produces a complete.dat file in memory
* starting from acode.acd in memory and
* from the rest of the data on disk
 lea startfile,finishedptr
* (allows space for acode beneath gamedata.dat)
* now allow space for gamedata. Startsources is where
* the exits etc. are loaded in transiently
 move.l finishedptr,a0
 add.l #sizegamedata,a0
 lea startsources,a1
 move.l a0,(a1)

 add.l #sizeofpointers,finishedptr
 bsr processexits
 bsr processtables
 move.l finishedptr,-(sp)
 bsr savedirectory

 bsr selectdirectory * subdirectory for computer-specific text
 move.l (sp)+,finishedptr
 bsr processsquash
 bsr climb * and back to root for acode

* set up ptr.l = start of acode
 bsr copyacode
 bsr processacodeptr
 bsr finishchecksum

 lea savecompletedriverblock,a6
 move.l startcomplete,(a6) * start address to save
 move.l finishedptr,$4(a6) * end address to save
 rts
*---
copyacode
* work out length
 move.l savedacodeptr,d0
 sub.l startacode,d0
 addq.l #8,d0 * allow plenty of space for length pointer
* now copy it to current position in gamedata.dat i.e. at finishedptr
* move.l finishedptr,a0
* make a0 even
 move.l finishedPtr,d1
 btst #0,d1
 beq.s CopyAcode0
 addq.l #1,d1
CopyAcode0
 move.l d1,FinishedPtr

 move.l finishedptr,a0
 move.l startacode,ptr
 subq.l #2,ptr * backstep over pointer
copyacode1
 move.b (ptr)+,(a0)+
 subq.l #1,d0
 bpl.s copyacode1
 move.l finishedptr,ptr * ptr.l = start of data in final position
 rts
*---
savegamedata
 bsr compprs
 dc.b "Saving acode.acd",cr,0
 even
 bsr saveacode
 bsr descend
 bsr compprs
 dc.b "Saving gamedata.dat",cr,0
 even
 lea savecompletedriverblock,a6
 move.b #savedcode,d0
 bsr compdriver
 bsr climb * leave us back where we started
 rts
*---
rungame
 bsr compprs
 dc.b "Running game... ",cr,0
 even
 bsr descend
; move.b #initdcode,d0
; bsr compdriver
* set up medium rez if using a colour monitor
 call_ebios _getrez
 addq.l #2,sp
* d0.b = 2 for hires
 cmp.b #2,d0
 beq.s rungamenoswitch
 move.w #1,-(sp) * medium resolution
 move.l #-1,-(sp) * retain physical base
 move.l #-1,-(sp) * retain logical base
 call_ebios _setscreen
 add.l #12,sp
rungamenoswitch
 dc.w $A00A * Line A function to hide mouse
* and set up palette - we want yellow text on black background
 jsr setuppalette

 lea initialstackpointer,a0
 move.l sp,(a0)
 bsr intinit1 * first part of initialise
 move.l a6,-(sp)
 lea savecompletedriverblock,a6
 move.l $4(a6),a0 * get end of gamedata file
 move.l (sp)+,a6
 bsr intinitloadpics * at a0
 bra intstart2
*---
toggledebugginginfo
 bsr compprs
 dc.b "Debugging info is",0
 even
 lea debugginginfoon,a0
 eor.b #$ff,(a0)
 bra togglereport
*---
compdebuggingon
; as part of a program
 lea debugginginfoon,a0
 eor.b #$ff,(a0)
 rts
*---
CompCode
; turn machine-code generation ON/OFF
 bsr CompSearch
 cmp.b #"+",d0
 beq.s CompCode2
 cmp.b #"-",d0
 beq.s CompCode2
 bra PlusOrMinusExpected

CompCode2
 move.b CodeState,d1
 cmp.b d0,d1
 beq AlreadyInState
 lea CodeState,a0
 move.b d0,(a0)
* d0.b is new code state
 cmp.b #"-",d0
 beq.s CompToAcode
 lea MCJumpTable,a0
 lea CurrentJumpTable,a1
 move.l a0,(a1)
* change to MC
 bsr CompPrs
 dc.b "to MC. ",0
 even
 bsr CompSkipToEol

 move.b #opcChangeCode,d0
 bsr Code
* is current code ptr (relative to ACODE START) EVEN?
 move.l CompAcodePtr,d0
 sub.l StartAcode,d0
 btst #0,d0
 beq.s CompToMCRet
 move.l CompAcodePtr,d0
 addq.l #1,d0
 move.l d0,CompAcodePtr
CompToMCRet
 rts


CompToAcode
* change to acode
 bsr COmpPrs
 dc.b "to acode. ",0
 even

 bsr CompSkipToEol

 lea CompJumpTable,a0
 lea CurrentJumpTable,a1
 move.l a0,(a1)
 bra MCToAcode
*---
compcif
; start of a section of conditional assembly
 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne maybeletvc
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #constanttype,d0
 bne badtype
 move.w valueoffset(a0),d0
 bne.s compcifend ; non-zero, so allow it to be compiled.
* skip over conditional assembly code
 lea supresscompilation(pc),a0
 addq.b #1,(a0)

compcifend
 rts
*---
compcend
 lea supresscompilation(pc),a0
 subq.b #1,(a0)
 bpl.s compcendret
 clr.b (a0) * prevent it going negative

compcendret
 rts
*---
toggleforcedlongjumps
 bsr compprs
 dc.b "Forced long jumps are",0
 even
 lea forcedlongjumps,a0
 eor.b #$ff,(a0)
togglereport
 tst.b (a0)
 beq.s nowoff
 bsr compprs
 dc.b " now on",cr,0
 even
 rts
nowoff
 bsr compprs
 dc.b " now off",cr,0
 even
 rts
*---
finishacode
 bsr compprs
 dc.b cr,"Number of vars=",0
 even
 clr.l d0
 move.w currentVarNumber,d0
 bsr compprintDecimalD0
 bsr flush
 bsr compprs
 dc.b cr,"Number of source lines=",0
 even
 move.l TotalSourceLines,d0
 bsr compprintDecimalD0
 bsr flush
 bsr compprs
 dc.b cr,0
 even

* check here for remaining forward references
 move.l startsymbols,a0
 move.l a0,a3
fa1
 tst.b (a0)
 beq fanosymbol
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "USED" bit
 cmp.b #undefinedlabeltype,d0
 bne fanosymbol
 move.w valueoffset(a0),d1
 move.l startforward,a1
fa2
 movem.l a0-a1,-(sp)
 move.w d1,-(sp) * save offset in f/r table

 lea compilationerrors,a0
 move.b #1,(a0)
 bsr compprs
 dc.b cr,"Missing symbol ",0
 even
 movem.l a0-a1,-(sp)
 move.w d1,-(sp)
 bsr absprintsymbol
 move.w (sp)+,d1
 movem.l (sp)+,a0-a1
 bsr compprs
 dc.b "which was referenced at line ",0
 even
 clr.l d0
 move.w $2(a1,d1),d0

 movem.w d0-d1,-(sp)
 movem.l a0-a1,-(sp)
 bsr compprintdecimald0
 movem.l (sp)+,a0-a1
 movem.w (sp)+,d0-d1

 bsr compflush * print buffer contents

 bsr compprs
 dc.b " in file ",0
 even
 clr.l d0
 move.b $8(a1,d1),d0

 movem.l a0-a1,-(sp)
 bsr compprintdecimald0
 movem.l (sp)+,a0-a1

 bsr compflush * print buffer contents

 move.w (sp)+,d1 * restore offset in f/r table
 movem.l (sp)+,a0-a1 * restore pointer to f/r table
 move.w $0(a1,d1),d1
 bne fa2 * more undefined references to this label

fanosymbol
 add.l #symbolsize,a0
 cmp.l endsymbols,a0
 bls fa1

 move.b compilationerrors,d0
 beq.s savecodeok
 bsr compprs
 dc.b "Errors in compilation - code not saved",cr
 dc.b "Press a key to return to gem",cr,0
 even
 bsr compwaitkey
 bra CompReturntogem
savecodeok
* poke in length at start
 move.l startacode,a0
 subq.l #2,a0 * give space for end pointer

 move.l compacodeptr,a1
 sub.l startacode,a1
 addq.l #2,a1 * allow space for length pointer
 move.w a1,d0
 move.b d0,(a0)+
 lsr.w #8,d0
 move.b d0,(a0)+
 rts
*---
saveacode
 move.l a6,-(sp) * save driver pointer
 lea saveacodedriverblock,a6
 move.l startacode,a0
 subq.l #2,a0 * allow space for length pointer
 move.l a0,(a6) * start address

 move.l savedacodeptr,$4(a6) * end address
 move.b #savedcode,d0
 bsr compdriver
 move.l (sp)+,a6
 rts
*---
clearsymbols
* acode area is immediately after comp
* complete.dat is afterwards - at fixed address startfile.

* once-only init
 lea endcompiler,a0
* a0.l is pointer to start of each area in this routine

* acode area is first section
 lea startacode,a1
 move.l a0,(a1)
 move.l a0,compacodeptr * a4 - stays set up throughout code
 move.l #sizeacodearea,d0 * max size of acode
 add.l d0,a0
 lea endacode,a1
 move.l a0,(a1)

* complete.dat will eventually be formed after acode - at
* fixed address startfile
 lea startfile,a2
 lea startcomplete,a1
 move.l a2,(a1)

* symbols sit between end of acode
* and source area
 lea symboltablesize,a1
 move.l #sizesymbolarea,(a1) * ?? size of symbol table
 lea startsymbols,a1
 move.l a0,(a1) * set up pointer to start of symbol table

 move.l a0,-(sp)
*  and set up pointer to first free address in symbol table
* ( immediately after the hash table)
 move.l #(hashtablesize),d0
 add.l d0,a0
 lea freesymbol,a1
 move.l a0,(a1)
 move.l (sp)+,a0

 move.l symboltablesize,d0
* clear space between a0.l and a0.l+symbolsize
clearsymbolsloop
 clr.l (a0)+
 sub.l #4,d0
 bpl.s clearsymbolsloop
 lea endsymbols,a1
 move.l a0,(a1) * set up pointer to end of symbol table

* forward reference table is after symbol table
 lea startforward,a1
 move.l a0,(a1)
 lea freeforwardref,a1
 clr.w (a1) * zero offset from start of f/r table
 move.l #sizeforwardarea,d0
 add.l d0,a0
 lea endforward,a1
 move.l a0,(a1)

 lea startsource,a1
 move.l a0,(a1) * set up pointer at which source will be loaded
* and some constants
 lea currentvarnumber,a0
 clr.w (a0)
 rts
*---
compsoftinit
 lea complinenumber,a0
 move.l #1,(a0)
 rts
*---

compilefile
* load a file, with driver prompting for filename
 bsr compsoftinit * init on each and every compile
 move.b #loaddcode,d0
 clr.b $8(a6) * filename = null, so user must enter one
 move.l startsource,a0
 move.l a0,(a6)
 bsr compdriver

 cmp.b #1,(a6)
 beq compmenu * not found
abscompilefile
 lea filenumber,a0
 addq.b #1,(a0)
* ok, now (a6).l = start address
* and $4(a6).l = end address of file just loaded
 move.l $4(a6),a0 * end address of file
 move.b #eof,(a0) * add terminators
 move.b #eof,$1(a0) * (not necessarily word-aligned)
 move.b #cr,$2(a0)
 move.b #lf,$3(a0)
 move.b #eof,$4(a0)
 move.b #eof,$5(a0)

* first find out what the terminator is
* it is assumed there will be one and only one of these per line
* other control codes are ignored completely by the compiler
 move.l (a6),ptr
getterminator
 move.b (ptr)+,d0
 cmp.b #cr,d0
 beq.s gotterminator
 cmp.b #lf,d0
 beq.s gotterminator
 bra.s getterminator
gotterminator
* terminator is d0
 lea compterminator,a0
 move.b d0,(a0)

 move.l (a6),ptr * remains as pointer throughout
 move.l ptr,d0 * test flags
 beq compmenu

* now start compiling it!
* start by looking for const/var definitions
 bsr checkforcontrolword
 tst.b d0 * keyword number
 beq syntaxerror
controlword
* d0 = number for program segment coming up
 cmp.b #1,d0
 beq mainprogram
 cmp.b #2,d0
 beq constantdefinitions
 cmp.b #3,d0
 beq tabledefinitions
 cmp.b #4,d0
 beq vardefinitions
 bra compilerbug

*---
endofcompfile
 lea savedacodeptr,a0
 move.l compacodeptr,(a0)
 bsr compprs
 dc.b "End of source file.",cr,0
 even
 move.b cexecutingcommandfile,d0
 bne batchcomp
 bra compmenu
*---
checkforcontrolword
 lea controlwords,a3
 move.w #numcontrolwords,d7
 bsr compsupersearch * skip spaces, comments etc.
 bra tablecompare
*---
constantdefinitions
 move.b debugginginfoon,d0
 beq.s constndebug
 bsr compprs
 dc.b cr,"Starting constant definitions segment at ",0
 even
 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr,0
 even

constndebug
constdefloop
 pea constdefloop
 lea errorstack,a0
 move.l sp,(a0)
 bsr checkforcontrolword
 tst.b d0
 bne controlword
 move.b #constanttype,d7
 move.w #0,d6 * dummy value
 bsr addsymbol
* a0.l = address of symbol entry
 move.b (ptr)+,d0
 cmp.b #"=",d0
 bne equalsexpected
* now get a number
 move.l a0,-(sp) * save symbol address
 move.l ptr,a0
 bsr compreaddecimal
 move.l a0,ptr * after the string
 move.l (sp)+,a0 * restore symbol address
 move.w d0,valueoffset(a0)
 bra constdefloop
*---
vardefinitions
 move.b debugginginfoon,d0
 beq.s varndebug
 bsr compprs
 dc.b "Starting variable definitions at line ",0
 even
 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr,0
 even

varndebug
vardefloop
 pea vardefloop * errors jump to here
 lea errorstack,a0
 move.l sp,(a0)
 bsr checkforcontrolword
 tst.b d0
 bne controlword
 move.b #vartype,d7
 move.w currentvarnumber,d6 * var number
 addq.w #1,d6
 lea currentvarnumber,a1
 move.w d6,(a1)
 cmp.w #256,d6
 beq TooManyVars
 bsr addsymbol
* a0.l = address of symbol entry
* bsr compskiptoeol * ignore rest of line at present
 bra vardefloop
*---
tabledefinitions
 move.b debugginginfoon,d0
 beq.s tablendebug
 bsr compprs
 dc.b cr,"Starting table definitions at line ",0
 even

 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr,0
 even

tablendebug
tabledefloop
 pea tabledefloop * errors jump to here
 lea errorstack,a0
 move.l sp,(a0)
 bsr checkforcontrolword
 tst.b d0
 bne controlword
 move.b #tabletype,d7
 move.w #0,d6 * dummy value
 bsr addsymbol
* a0.l = address of symbol entry
 move.b (ptr)+,d0
 cmp.b #"=",d0
 bne equalsexpected
* now get a number
 move.l a0,-(sp) * save symbol address
 move.l ptr,a0
 bsr compreaddecimal
 move.l a0,ptr * after the string
 move.l (sp)+,a0 * restore symbol address
 move.w d0,valueoffset(a0)
* bsr compskiptoeol * ignore rest of line at present
 bra tabledefloop
*---
mainprogram
 move.b debugginginfoon,d0
 beq.s mainprogndebug
 bsr compprs
 dc.b "Starting main program at line ",0
 even
 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr,0

mainprogndebug
mainprogloop
 pea mainprogloop * errors jump to here
 lea errorstack,a0
 move.l sp,(a0)
 bsr checkforcontrolword
 tst.b d0
 bne controlword

* defining a label ?
 move.b (ptr),d0
 cmp.b #".",d0
 bne.s mainprognlabel
 move.b supresscompilation(pc),d1
 bne compSkipToEol
 addq.l #1,ptr * move on to text of label
 move.b #labeltype,d7
 move.l compacodeptr,d6 * abs position in memory
 move.l startacode,d0
 sub.l d0,d6 * value of label (pos relative to acode start)
 bsr addsymbol
 move.b CodeState,CodeStateOffset(a0)
 bsr compsupersearch
 rts * back to mainprogloop

mainprognlabel
 lea compinstructiontable,a3
 move.w #numinstructions,d7
 bsr tablecompare

 move.b supresscompilation(pc),d1
 beq.s mainprognotconditional
; only keyword numbers 3/4 (i.e. start/end conditional assembly)
; are assembled in the middle of conditional assembly
 cmp.b #3,d0
 beq.s mainprognotconditional
 cmp.b #4,d0
 beq.s mainprognotconditional
 bra compskiptoeol * ignore instruction

mainprognotconditional
CompileInstructionD0
 tst.b d0 * keyword number
 beq mainprogninstruction

 move.l Currentjumptable,a0
 and.w #$3f,d0
 asl.w #2,d0
 move.l $0(a0,d0),a1
 jmp (a1)

mainprogninstruction
* only other possibility is that it is an assignment
* to a var or table
* check for 16 bit list access...
 lea SixteenFlag,a0
 clr.b (a0)
 bsr compSearch
 cmp.b #'&',d0
 bne.s MPNot16
 move.b #1,(a0)
 addq.l #1,ptr

MPNot16
 bsr findsymbol
 tst.b d0
 bne badinstruction
 move.b typeoffset(a0),d0
 or.b #$80,typeoffset(a0) ; set "used" bit
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #tabletype,d0
 beq assigntotable
 cmp.b #vartype,d0
 bne syntaxerror
 move.w valueoffset(a0),-(sp) * save var number to assign to

 bsr compsearch
 cmp.b #"=",d0
 bne equalsexpected
 addq.l #1,ptr
 bsr compsearch

 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne maybeletvc
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #constanttype,d0
 beq letvcmanifest
 cmp.b #tabletype,d0
 beq assignfromtable
 cmp.b #vartype,d0
 bne varexpected
* var=var
 bsr MCLetVV

 move.b #opcletvv,d0
 bsr code * opc
 move.w valueoffset(a0),d0
 bsr code * v2
 move.w (sp)+,d0
 bra code * v1
*---
letvcmanifest
* assigning from a manifest constant
 move.w valueoffset(a0),d0
 bra.s letvc

maybeletvc
* assigning from constant?
 bsr getnumberconstant
letvc
* d0.l = constant to assign from
 bsr MCLetVC
 move.w d0,-(sp)
 cmp.w #$100,d0
 bcc.s letvcbig * unsigned >=
 move.b #opcletvcsmall,d0
 bsr code
 move.w (sp)+,d0
 bsr code * single byte constant only
 move.w (sp)+,d0 * var number
 bra code * var
*
letvcbig
 move.b #opcletvcbig,d0
 bsr code * d0.b = opcode
 move.w (sp)+,d0
 bsr codew * two byte constant
 move.w (sp)+,d0 * var number
 bra code * var
*---
assigntotable
* have found a table identifier at start of line
* i.e. want to do function of form @(V/C)=V
 move.w valueoffset(a0),-(sp) * table number
 bsr compsearch
 cmp.b #"(",d0
 bne bracketsexpected
 addq.l #1,ptr
 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne attmaybenumeric
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 move.b #$80,d1 * base value for table(const)=var operations
 cmp.b #vartype,d0
 beq attvar

 cmp.b #constanttype,d0
 bne badindex
* a manifest constant index
attconst
 move.w valueoffset(a0),d0 * value of index
 bsr MCAttConst
 bra.s attcgotd0
*---
attvar
* table(var)=var
 bsr MCAttVar

 move.b #$E0,d1 * base value for table(var)=var operations
 bra.s attconst * can treat as constant henceforth
*---
attmaybenumeric
* only remaining possibility is a numeric offset?
 bsr getnumberconstant * will print an error message if not
 move.b #$80,d1 * base for table(const)=var operations
* d0.w is offset
 bsr MCAttConst

attcgotd0
* have value of the constant index - generate code for table(c)=v
 move.w d0,-(sp) * index
 move.b SixteenFlag,d0
 bne CantDo16
 bsr compsearch
 cmp.b #")",d0
 bne bracketsexpected
 addq.l #1,ptr
 bsr compsearch
 cmp.b #"=",d0
 bne equalsexpected
 addq.l #1,ptr
 move.w d1,-(sp) * preserve base value
 bsr compgetvar
 move.w (sp)+,d1

alltablecode
 move.w d0,-(sp) * save var not inside brackets
 add.w $4(sp),d1 * add on table number to base value
 move.b d1,d0
 bsr code
 move.w $2(sp),d0 * table index
 cmp.w #$100,d0
 bcc badindex * single byte only!
 bsr code
 move.w (sp),d0 * var not inside brackets
 bsr code
 addq.l #6,sp
 rts
*---               
getnumberconstant
* a real number
 bsr compsearch
 cmp.b #"0",d0
 bcs syntaxerror * no other possibilities
 cmp.b #"9",d0
 bhi syntaxerror * unsigned >=
* yup, so generate the code
 move.l ptr,a0
 bsr compreaddecimal
 move.l a0,ptr * pointer immediately after number
gotconst2
* d0.w = value
 rts
*---
assignfromtable
* on stack is var to assign to
* var=table(c/v)
 bsr MCAFT
 move.b SixteenFlag,d0
 bne CantDo16

 move.w valueoffset(a0),-(sp) * table number
 bsr compsearch
 cmp.b #"(",d0
 bne bracketsexpected
 addq.l #1,ptr
 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne aftmaybenumeric
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #vartype,d0
 beq aftvar
 cmp.b #constanttype,d0
 bne badindex
* a manifest constant
 move.w valueoffset(a0),d0 * value of constant
 move.b #$c0,d1 * base value for var=table(c)
 bra.s aftconst

aftmaybenumeric
 bsr getnumberconstant * will print an error message if not
 move.b #$C0,d1 * base value for var=table(c)
 bra.s aftconst

aftvar
 move.b #$A0,d1 * base value for var=table(v)
 move.w valueoffset(a0),d0
* drop through to aftconst

aftconst
 move.w d0,-(sp) * table index
 bsr compsearch
 cmp.b #")",d0
 bne bracketsexpected
 addq.l #1,ptr * skip brackets
* now generate the code
* first put in opcode - base value+table number
 move.w $2(sp),d0 * table number
 or.b d1,d0 * or (add) in base
 bsr code

* and the index
 move.w (sp),d0
 cmp.w #$100,d0
 bcc badindex * single byte index only
 bsr code

* now thing not inside the brackets
 move.w $4(sp),d0
 bsr code

 addq.l #6,sp
 rts

*---
compif
* handle if v = <> < > then label
 lea opcodeaddress,a0
 move.l compacodeptr,(a0)

 bsr compgetvar
 move.w d0,-(sp) * preserve variable number
 bsr evaloperator
* d1.b = operator type
 move.w d1,-(sp) * save operator type
 bsr findsymbol
 tst.b d0
 beq if1
* only other possibility is a number
 bsr getnumberconstant
* d0.w = value
 move.l a6,a0
 move.w d0,valueoffset(a0) * use driverbuffer
* as temporary workspace - surely no-one will mind?
* - sets up value so it is retrieved correctly by later code
 bra.s ifvc
if1
 or.b #$80,typeoffset(a0) ; set "USED" bit
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #vartype,d0
 beq.s ifvv
 cmp.b #constanttype,d0
 bne badtype
ifvc
 move.w (sp)+,d1 * operator type 
 or.b #$18,d1 * opcode
* now set up size bit
 move.w valueoffset(a0),d0
 cmp.w #$100,d0
 bcc.s ifvcbig
 or.b #smallmask,d1 * set sizebit - small constant
 move.b d1,d0
* now d1.b=opcode
 bsr code
 move.w (sp)+,d0 * first var number
 bsr code
 move.w valueoffset(a0),d0
 bsr code * single byte constant
 bra.s ifcommon

ifvcbig
* now d1.b=opcode
 move.b d1,d0
 bsr code
 move.w (sp)+,d0 * first var number
 bsr code
 move.w valueoffset(a0),d0
 bsr codew * double byte constant
ifcommon
* skip over "THEN" if present, then evaluate jump address
 bsr compsearch
 lea thenstring,a3
 move.w #0,d1
 bsr stringcompare
* stringcompare automatically skips string if matched
 bra jumpstuff
thenstring
 dc.b "THEN            "
*---
ifvv
 move.w (sp)+,d1 * operator type
 or.b #$10,d1 * opcode
 move.b d1,d0
 bsr code
 move.w (sp)+,d0 * first var number
 bsr code
 move.w valueoffset(a0),d0
 bsr code
 bra.s ifcommon
*---
evaloperator
* return d1.b = code corresponding to operator
 bsr compsearch
 addq.l #1,ptr * skip operator

 move.b #eqop,d1 * equals operator
 cmp.b #"=",d0
 beq.s evalopret

 move.b #gtop,d1
 cmp.b #">",d0
 beq.s evalopret

 move.b #ltop,d1
 cmp.b #"<",d0
 bne badoperator
 move.b (ptr),d0
 move.b #ltop,d1
 cmp.b #">",d0
 bne.s evalopret
 move.b #neop,d1 * must have been <>
 addq.l #1,ptr * and skip > of <>
evalopret
 rts
*---
compgoto
 move.b #opcgoto,d0
 bra gosub1
compgosub
 move.b #opcgosub,d0
gosub1
 lea opcodeaddress,a0
 move.l compacodeptr,(a0)
 bsr code
jumpstuff
* insert code for a jump to the label (ptr.l)
* the address of the opcode for this jump is at $0(sp.l)
 bsr compsearch
 cmp.b #"@",d0
 bne.s relativejump
* absolute jump
 addq.l #1,ptr
absjump
 bsr getlabel
 move.b CodeStateOffset(a0),d1
 beq.s CantCheckForwardRef
 cmp.b CodeState,d1
 bne WrongCodeState
CantCheckForwardRef
* d0.w is value of label relative to start of acode
* which is just what we want!
 bra codew

relativejump
 move.b forcedlongjumps,d0
 bne.s absjump
* relative jump, so set relbit in opcode
 move.l opcodeaddress,a0
 or.b #relmask,(a0) * set relbit
 bsr getlabel

 move.b CodeStateOffset(a0),d1
 beq.s CantCheckForward1
 cmp.b CodeState,d1
 bne WrongCodeState
CantCheckForward1

* d0.w is value of label relative to start of acode
* find current address relative to start
 move.l compacodeptr,d1
 sub.l startacode,d1
 sub.l d1,d0
 cmp.w #$80,d0 ;>>was $100
 bcs code * unsigned < - ok!
 cmp.w #$FF80,d0 ;>>was $ff00
 bcs reljumpoutofrange * unsigned <
 bra code

*---
getlabel
* return d0.w = value of label relative to start of acode area
* set up forward reference if label is not yet defined
 bsr findsymbol
 tst.b d0
 bne glsetupforwardreference
badlabel
 move.b typeoffset(a0),d0
 or.b #$80,typeoffset(a0) ; set "USED" bit
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #undefinedlabeltype,d0
 beq.s addforwardreference
 cmp.b #labeltype,d0
 bne wronglabeltype
 move.w valueoffset(a0),d0
 rts
*---
addforwardreference
* add a forward reference to a label which already
* has some references to it (a0.l) is entry in symbol table
* scan through existing list
 move.w valueoffset(a0),d6 * get first forward reference entry
 move.l startforward,a1
addfr1
 move.w $0(a1,d6),d0
 beq.s addfr2 * end of list
 move.w d0,d6
 bra.s addfr1
addfr2
 move.w freeforwardref,d0
 move.w d0,$0(a1,d6) * set up pointer to new entry
 move.w d0,d6 * pointer to new entry
 bra.s glsufr1 * and set up new entry

*---
glsetupforwardreference
 move.b #undefinedlabeltype,d7 * type
 move.w freeforwardref,d6
* d6 = value of symbol - offset of first entry in chain in f/r table
 bsr addsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
glsufr1
* and set up the entry in the forward reference table
* structure is:
*  .. offset from start of table of next u/d reference to this symbol
*  .. line number of reference
*  .. offset from start of code of the reference
*  .. offset from start of code of the opcode
*  .  file number in which reference occured
; clr.b CodeStateOffset(a0)
 move.l startforward,a1
 clr.w $0(a1,d6) * offset of next entry
 move.l complinenumber,d0
 move.w d0,$2(a1,d6)
 move.l compacodeptr,d0
 sub.l startacode,d0
 move.w d0,$4(a1,d6) * current pos relative to start of acode
 move.l opcodeaddress,d0
 sub.l startacode,d0
 move.w d0,$6(a1,d6)
 move.b filenumber,d1
 move.b d1,$8(a1,d6)
 move.b CodeState,$9(a1,d6)

 add.w #forwardentrysize,d6 * and set up free space pointer
 lea freeforwardref,a1
 move.w d6,(a1)
 cmp.w #sizeforwardarea,d6
 bhi forwardrefoverflow
* returning d0.w as offset relative to acode start.
* This is wrong for MC compilation because DummyOpcode used
 move.b CodeState(PC),d1
 cmp.b #'+',d1
 bne.s glsufr2
* for MC, return current acode position
 move.l compacodeptr,d0
 sub.l startacode,d0

glsufr2
 rts
*---
resolveforwardref
* have just defined encountered ".label" which
* is in the symbol table as type undefinedlabeltype
* so zip through setting up all the jumps correctly
* symbol table entry is (a0.l)
* mark label as defined
 lea symboladdress,a1
 move.l a0,(a1)
 move.b #(labeltype+$80),typeoffset(a0) ; mark as "USED"
 move.w valueoffset(a0),d0

 move.l startforward,a0
 move.l startacode,a1

rfr1
 move.b CodeState,d3
 cmp.b 9(a0,d0),d3
 bne ForwardWrongCodeState
 cmp.b #'-',d3
 beq.s rfrAcode
 bsr MCrfr
 bra.s rfrNext

rfrAcode
 move.l compacodeptr,d3
 sub.l a1,d3 * sub startacode,d3 - d3=current offset in acode
 move.w $6(a0,d0),d1 * offset of opcode
 move.b $0(a1,d1),d2 * opcode
 and.b #relmask,d2 * is this a long jump?
 bne rfrshort * no!
* poke back in address for a long jump
 move.w $4(a0,d0),d2 * offset of reference
* poke back two-byte reference
 move.w d3,d1 * current pos in acode relative to start of acode
 move.b d1,$0(a1,d2) * low byte
 lsr.w #8,d1
 move.b d1,$1(a1,d2) * high byte
 bra rfrnext
*-
rfrshort
* poke back in address for short jump
* make it relative to address of reference
 move.w $4(a0,d0),d1 * offset of reference
 sub.w d1,d3 * d3=label-ref
 cmp.w #$80,d3 ; >>was $100!
 bcc forwardoutofrange * note special line number treatment
 move.b d3,$0(a1,d1) * poke in single byte reference
rfrnext
* any more forward references?
* at present, no garbage collection on forward
* reference area. If this is needed (which I doubt)
* then the easiest way is probably to have a free-space
* linked list to which space is added. When space is
* needed, it can be taken off the start of this list
 move.w $0(a0,d0),d0 * offset of next chained entry
 bne.s rfr1
 rts
*---
compinstructiontable
* see controlwords
numinstructions equ 34
 dc.b "ADD             "
 dc.b "AND             "
 dc.b "BREAK           "
 dc.b "CEND            " ; conditional assembly
 dc.b "CIF             " ; conditional assembly
 DC.B "CLEAR           "
 DC.B "CLS             "
 dc.b "CODE            " ; machine-code compilation
 DC.B "DATA            "
 dc.b "DEBUG           "
 DC.B "DRIVER          "
 DC.B "EXIT            "
 DC.B "GETNEXT         "
 DC.B "GOSUB           "
 DC.B "GOTO            "
 DC.B "IF              "
 DC.B "INPUT           "
 DC.B "JUMP            "
 DC.B "MESSAGE         "
 dc.b "OR              "
 DC.B "PICTURE         "
 dc.b "POP             "
 DC.B "PRINT           "
 DC.B "PRINTINPUT      "
 DC.B "PRS             "
 dc.b "PUSH            "
 DC.B "RANDOM          "
 DC.B "RESTORE         "
 DC.B "RETURN          "
 DC.B "SAVE            "
 DC.B "SCREEN          "
 DC.B "STACK           "
 DC.B "SUB             "
 dc.b "XOR             "
*---
compjumptable
 dc.l 0 * null entry because words numbered from 1 ..
 dc.l COMPADD
 dc.l NotAllowedInAcode * AND
 dc.l COMPBREAKPT
 dc.l compcend
 dc.l compcif
 dc.l COMPCLEAR
 dc.l COMPCLS
 dc.l CompCode
 dc.l COMPDATA
 dc.l COMPdebuggingon
 dc.l COMPDRIVEROPCODE
 dc.l COMPEXIT
 dc.l COMPGETNEXT
 dc.l COMPgosub
 dc.l COMPgoto
 dc.l COMPIF
 dc.l COMPINPUT
 dc.l COMPJUMP
 dc.l COMPMESSAGE
 dc.l NotAllowedInAcode ; OR
 dc.l COMPPICTURE
 dc.l NotAllowedInAcode ; POP
 dc.l COMPPRINT
 dc.l COMPPRINTINPUT
 dc.l COMPACODEPRS
 dc.l NotAllowedInAcode ; PUSH
 dc.l COMPRANDOM
 dc.l COMPRESTORE
 dc.l COMPRETURN
 dc.l COMPSAVE
 dc.l COMPSCREEN
 dc.l COMPSTACK
 dc.l COMPSUB
 dc.l NotAllowedInAcode ; XOR
*---
MCjumptable
* jump table for use in MC mode
 dc.l 0 * null entry because words numbered from 1 ..
 dc.l MCADD
 dc.l MCAND
 dc.l MCBREAKPT
 dc.l CompCend
 dc.l CompCif
 dc.l MCCLEAR
 dc.l MCCLS
 dc.l CompCode
 dc.l MCDATA
 dc.l Compdebuggingon
 dc.l MCDRIVEROPCODE
 dc.l MCEXIT
 dc.l MCGETNEXT
 dc.l MCgosub
 dc.l MCgoto
 dc.l MCIF
 dc.l MCINPUT
 dc.l MCJUMP
 dc.l MCMESSAGE
 dc.l MCOR
 dc.l MCPICTURE
 dc.l MCPOP
 dc.l MCPRINT
 dc.l MCPRINTINPUT
 dc.l MCACODEPRS
 dc.l MCPUSH
 dc.l MCRANDOM
 dc.l MCRESTORE
 dc.l MCRETURN
 dc.l MCSAVE
 dc.l MCSCREEN
 dc.l MCSTACK
 dc.l MCSUB
 dc.l MCXOR
*---
opcgoto equ 0
opcgosub equ 1
opcreturn equ 2
opcprint equ 3
opcmessagev equ 4
opcmessagec equ 5
opcmessagecsmall equ opcmessagec+$40 * smallmask
opcmessagecbig equ opcmessagec
opcfunction equ 6
opcinput equ 7
opcletvcbig equ 8
opcletvcsmall equ opcletvcbig+$40 * smallmask
opcletvv equ 9
opcaddvv equ 10
opcsubvv equ 11
OpcChangeCode equ 12 * change code generation state
opccall equ 14
opcexit equ 15
opcscreen equ 20
opcclear equ 21
opcpicture equ 22
opcgetnext equ 23
opcprintinput equ 28
*
* function codes
fncacodedriver equ 1
fncrandom equ 2
fncsave equ 3
fncrestore equ 4
fncclear equ 5
fncstack equ 6
fncbreakpt equ 7
fncprs equ 250
*---
COMPADD
 move.b #opcaddvv,d0
 bra.s addsub

COMPSUB
 move.b #opcsubvv,d0

addsub
 bsr code
 bsr compgetvar
 move.w d0,-(sp) * save var number
 bsr compsearch
 cmp.b #",",d0
 bne commaexpected
 addq.l #1,ptr * skip over comma
 bsr compgetvar
 bsr code
 move.w (sp)+,d0 * first var - result of add
 bra code
*---
COMPACODEPRS
; Compile a function call for acode prs - for acode debugging
 bsr compsearch
 cmp.b #'"',d0
 bne missingquote
 move.b #opcfunction,d0
 bsr code
 move.b #fncprs,d0
 bsr code
 addq.l #1,ptr ; skip over leading quote

compacodeprs1
 move.b (ptr)+,d0
 cmp.b #'"',d0
 beq.s compacodeprsend
 cmp.b #'œ',d0
 beq poundsignnotallowed ; œ is invisible + messes up capitalization
 bsr code
 bra.s compacodeprs1

compacodeprsend
 moveq #0,d0
 bra code ; add 0 to terminate
;---

COMPCLEAR
 move.b #opcfunction,d0
 bsr code
 move.b #fncclear,d0
 bra code
*---
COMPCLS
 move.b #opcclear,d0
 bsr code
 bsr compsearch
 bsr compisd0alphanumeric * convert to upper case
 addq.l #1,ptr * skip t or g
 cmp.b #"T",d0
 beq.s compcleart
 cmp.b #"G",d0
 bne badarg
 move.b #1,d0
 bra code
compcleart
 clr.b d0
 bra code
*---
COMPDATA
 lea opcodeaddress,a0
 lea jumpdummyopcode,a1
 move.l a1,(a0)
 bsr jumpstuff
 bsr compsearch
 addq.l #1,ptr * skip over comma
 cmp.b #",",d0
 beq.s compdata
 cmp.b #";",d0
 beq compssskiptoeol
 rts
*---
COMPDRIVEROPCODE
 move.b #opcfunction,d0
 bsr code
 move.b #fncacodedriver,d0
 bra code
*---
COMPEXIT
 move.b #opcexit,d0
fourargs
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bra code
*---
COMPGETNEXT
 move.b #opcgetnext,d0
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bsr code

 bsr compgetvar
 bra code
*---
COMPINPUT
 move.b #opcinput,d0
 bra fourargs
*---
COMPJUMP
 move.b forcedlongjumps,d0
 move.w d0,-(sp)
 lea forcedlongjumps,a0
 move.b #1,(a0) * force long jumps here

 lea opcodeaddress,a0
 move.l compacodeptr,(a0)
 move.b #opccall,d0
 bsr code
 bsr jumpstuff
 bsr compgetvar
 bsr code

* and restore original value in forcedlongjumps
 move.w (sp)+,d0
 lea forcedlongjumps,a0
 move.b d0,(a0)
 rts
*---
COMPMESSAGE
 bsr findsymbol
 tst.b d0
 bne messagemaybenumeric
 or.b #$80,typeoffset(a0) ; set "USED" bit
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #constanttype,d0
 beq.s compmessagec
 cmp.b #vartype,d0
 bne badtype
* message v
 move.b #opcmessagev,d0
 bsr code * opcode
 move.w valueoffset(a0),d0
 bra code * var number

compmessagec
 move.w valueoffset(a0),d0
compmessagec1
 cmp.w #$100,d0
 bcc compmessagecbig
 move.w d0,-(sp)
 move.b #opcmessagecsmall,d0
 bsr code
 move.w (sp)+,d0
 bra code * single byte constant

compmessagecbig
 move.w d0,-(sp)
 move.b #opcmessagecbig,d0
 bsr code
 move.w (sp)+,d0
 bra codew * double byte constant
 or.b #smallmask,d0
 
messagemaybenumeric
 bsr getnumberconstant
 bra.s compmessagec1
*---
COMPPICTURE
 move.b #opcpicture,d0
 bsr code
 bsr compgetvar
 bra code
*---
COMPPRINT
 move.b #opcprint,d0
 bsr code
 bsr compgetvar
 bra code
*---
COMPPRINTINPUT
 move.b #opcprintinput,d0
 bra code
*---
*---
COMPBREAKPT
 move.b #opcfunction,d0
 bsr code
 move.b #fncbreakpt,d0
 bra code
*---
COMPRANDOM
 move.b #opcfunction,d0
 bsr code
 move.b #fncrandom,d0
 bsr code
 bsr compgetvar
 bra code * var number
*---
COMPRESTORE
 move.b #opcfunction,d0
 bsr code
 move.b #fncrestore,d0
 bra code
*---
COMPRETURN
 move.b #opcreturn,d0
 bra code
*---
COMPSAVE
 move.b #opcfunction,d0
 bsr code
 move.b #fncsave,d0
 bra code
*---
COMPSCREEN
 move.b #opcscreen,d0
 bsr code  * opcode
 bsr compsearch
 addq.l #1,ptr * skip t/g
 bsr compisd0alphanumeric * convert to upper case
 cmp.b #"T",d0
 beq compscreent
 cmp.b #"G",d0
 bne badarg
 move.b #1,d0
 bsr code
 bsr compgetvar
 bra code * dummy var for screeng g
compscreent
 clr.b d0
 bra code
*---
COMPSTACK
 move.b #opcfunction,d0
 bsr code
 move.b #fncstack,d0
 bra code
*---
* now some general code generation subroutines
codew
* generate code for d0.w
 bsr code
 lsr.w #8,d0
* fall through to code

code
* add d0.b to current position in code
 move.b d0,(compacodeptr)+
 cmp.l endacode,compacodeptr
 bhi acodeoverflow
 rts
*---
compgetvar
* return value of var (ptr.l) in d0.w
 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne varnotdefined
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #vartype,d0
 bne varexpected
 move.w valueoffset(a0),d0
 rts



*---
checkunusedsymbols
 clr.l d4 * total number of symbols
 clr.l d5 * symbols within hash table
 bsr compprs
 dc.b "Undefined symbols... ",cr,0
 even

 move.l startsymbols,a0
 move.l a0,a3
 move.l #hashtablesize,d0
 add.l d0,a3 * end of hash table

cust1
 tst.b (a0)
 beq.s custnosymbol
 move.b typeoffset(a0),d0
 and.b #$80,d0
 bne.s custnosymbol * already defined
 movem.l d0-d7/a0-a6,-(sp)
 bsr printsymbol
 movem.l (sp)+,d0-d7/a0-a6
custnosymbol
 add.l #symbolsize,a0
 cmp.l endsymbols,a0
 bls.s cust1
 bsr compprs
 dc.b cr,0
 even
 rts
*---
printsymboltable
* display all symbols
 clr.l d4 * total number of symbols
 clr.l d5 * symbols within hash table
 bsr compprs
 dc.b cr,0
 even

 move.l startsymbols,a0
 move.l a0,a3
 move.l #hashtablesize,d0
 add.l d0,a3 * end of hash table

pst1
 tst.b (a0)
 beq.s pstnosymbol
 addq.l #1,d4 * number of symbols
 movem.l d0-d7/a0-a6,-(sp)
 bsr printsymbol
 movem.l (sp)+,d0-d7/a0-a6
pstnosymbol
 add.l #symbolsize,a0

 cmp.l a0,a3
 bne.s pst2
 bsr compprs
 dc.b "-----------------",cr
 dc.b "End of hash table",cr
 dc.b "-----------------",cr,0
 even
 move.w d4,d5 * save number of symbols in hash table
pst2

 cmp.l endsymbols,a0
 bls.s pst1
 bsr compprs
 dc.b "Total number of symbols = ",0
 even
 move.l d4,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr
 dc.b "Of which number in hash table = ",0
 even
 move.l d5,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b cr,0
 even
 rts
*---
printsymbol
* print symbol (a0.l)
* first print value
 move.l a0,-(sp)
 move.w valueoffset(a0),d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b " ",9,0 * tab
 even

 bsr absprintsymbol
 bsr compprs
 dc.b cr,0
 even
 move.l (sp)+,a0
 rts
*---
absprintsymbol
* print symbol (a0.l)
 move.l a0,-(sp) * save a0.l
printsymbol1
 move.b (a0)+,d0
 beq.s printsymbolend
 move.b d0,(a6)
 move.b #oswrchdcode,d0
 bsr compdriver
 bra.s printsymbol1
printsymbolend
 move.l (sp)+,a0
 rts
*---

addsymbol
* add symbol (ptr.l) of alphanumeric characters
* with type d7.b
* and value d6.w
* return a0.l = address of symbol
 bsr findsymbol
 tst.b d0
 bne addsymbolok * not defined - so go on!
* only one type of symbol can be redefined
* - where a "undefinedlabeltype" is to be replaced
* by a "labeltype"
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #undefinedlabeltype,d0
 bne cantredefinesymbol
 cmp.b #labeltype,d7
 bne cantredefinesymbol
 move.l a0,-(sp) * preserve address of symbol
 bsr resolveforwardref * ok!
 move.l (sp)+,a0 * restore symbol address
 bra pokeinvalue * set up type, value

addsymbolok
* a0.l = address of last symbol in chain found
 tst.b (a0) * anything there
 beq.s gotsymbolspace * no - first entry with this hash value
 
chainonsymbol
* find the first free address and add a symbol in it
* then chain on ptr at ptroffset(a0)
 lea freesymbol,a1
 move.l (a1),a2
 move.l a2,ptroffset(a0)
 move.l a2,a0
* and adjust free symbol pointer accordingly
 add.l #symbolsize,a2
 move.l a2,(a1)
 cmp.l endsymbols,a2
 bcc symboltableoverflow * unsigned >=
gotsymbolspace
 move.l a0,a1 * preserve a0
 clr.b d1 * length of symbol
* there is space to add a symbol at a0.l so do so
gotsymbol1
 move.b (ptr)+,d0
 bsr compisd0alphanumeric
 beq.s gotsymbol2
 addq.b #1,d1 * length

 move.b d0,(a0)+
 bra.s gotsymbol1
gotsymbol2
* was it short enough
* cmp.b #symboltextlength,d1
**/ bhi symboltoolong
 clr.b CodeStateOffset(a1)
 subq.l #1,ptr * go back
* and add in the type etc.
* a1.l is start of symbol
 move.l a1,a0 * return value to caller
pokeinvalue
 move.b typeoffset(a0),d0
 and.b #$80,d0 ; save valuye of bit 7 ("USED" bit)
 move.b d7,typeoffset(a0)
 or.b d0,typeoffset(a0) ; restore bit 7
 move.w d6,valueoffset(a0)
 rts 
*---
findsymbol
* find symbol (ptr.l) of alphanumeric characters
* return: a0.l = address of symbol if found
* and d0.b = 0
* else d0.b <>0 and a0.l = address of last symbol in chain

* first do hash calculation on the symbol
* to find the offset from the start of the symbol area
 bsr compsearch
 bsr hashcalc
* now d0.l = offset from start of symbol area
* is there an entry there already?
 move.l startsymbols,a3 * for benefit of stringcompare
 add.l d0,a3 * now a3.l = address of this label
 clr.l d1 * offset of 0 for stringcompare
findsymbol1
 bsr stringcompare
 beq symbolfound 
* not found - any chained entries
 move.l ptroffset(a3),d0
 beq.s symbolnotfound
 move.l d0,a3
 bra.s findsymbol1 * d1.l still = 0
symbolnotfound
 move.b #$ff,d0 * error code
 move.l a3,a0 * return address of last symbol found
 rts
symbolfound
 clr.b d0 * success code
 move.l a3,a0 * return address of symbol in a0.l
 rts
*---
hashcalc
* from symbol at (ptr.l), return d0.l as the offset from the
* start of the hash table
 clr.l d1
 clr.w d2 * offset
 move.b (ptr),d0
 bsr compisd0alphanumeric
 beq badsymbol

hashcalc1
 move.b $0(ptr,d2),d0
 bsr compisd0alphanumeric
 beq hashcalcend
 sub.b #"0",d0
 add.b d0,d1
 addq.w #1,d2 * increase offset
 bra hashcalc1




 clr.l d1
 move.b (ptr),d0
 bsr compisd0alphanumeric
 beq badsymbol
 move.b d0,d1

 move.b $1(ptr),d0
 bsr compisd0alphanumeric
 beq.s hashcalcend
 add.b d0,d1

 move.b $2(ptr),d0
 bsr compisd0alphanumeric
 beq.s hashcalcend
 add.b d0,d1

 move.b $3(ptr),d0
 bsr compisd0alphanumeric
 beq.s hashcalcend
 add.b d0,d1

hashcalcend
 move.l d1,d0 * calculated value
* and multiply by the size of a symbol
 move.w #symbolsize,d1
 mulu d1,d0 * unsigned multiply, taking word size args, gives long res
 rts
*---
;isd0alphanumeric
;* return d0.b = 0 if not
; cmp.b #"0",d0
; bcs.s compidanfail * unsigned <
; cmp.b #"9",d0
; bls.s compidanret * unsigned <=
; cmp.b #"A",d0
; bcs.s compidanfail * unsigned <
;* do "quick-and-dirty" lower-upper case conversion
; and.b #$DF,d0
; cmp.b #"Z",d0
; bhi.s compidanfail * unsigned >
compidanret
; tst.b d0 * non-zero
; rts
;compidanfail
; clr.b d0
; rts
*--- 



displayline
* display the line after the current pointer if debugging info is on
 move.b debugginginfoon,d0
 beq.s displaylineret

* display the previous 8 bytes
 bsr compprs
 dc.b cr,0
 even
 move.l compacodeptr,a0
 subq.l #8,a0

 move.l a0,-(sp) * display address relative to start of acode
 sub.l startacode,a0
 bsr comphexlonga0
 move.l (sp)+,a0

 bsr compprs
 dc.b ": ",0
 even
displaylinea
 move.b (a0)+,d0
 bsr comphexbyted0
 bsr compprs
 dc.b " ",0
 even
 cmp.l a0,compacodeptr
 bne.s displaylinea
 bsr compprs
 dc.b " - ",0
 even
* first give line number
 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b ": ",0
 even

 move.l ptr,-(sp)
displayline1
 move.b (ptr)+,d0
 cmp.b #32,d0
 bcs.s displaylinecontrolcode
 move.b d0,(a6)
 move.b #oswrchdcode,d0
 bsr compdriver
 move.b (a6),d0
displaylinecontrolcode
 cmp.b compterminator,d0
 bne.s displayline1
displaylineend
 move.l (sp)+,ptr
displaylineret
 rts
*---
tablecompare
* compare a word of alphanumerics at (ptr.l)
* with table starting at a3.l, which has d7.w entries
* each of length #tsize = #2^tbits
* return d0=keyword number or =0 if not found
 clr.w d6 * lower bound for binary chop
tablecomp1
* get mid-point between d6.w and d7.w as next comparison string
 move.w d7,d1
 add.w d6,d1
 and.w #$fffe,d1 * round down division by two
 asl.w #tbits-1,d1 * get middle entry in table (/2,*tsize)
* d1.w is now offset into table
* so do a single string compare
 bsr stringcompare
 beq.s tablecompfound
* have we finished?
 move.w sr,d2 * preserve status flags
 move.w d7,d0 * upper bound
 sub.w d6,d0 * - lower bound
 cmp.w #1,d0
 bls tablecompnotfound
 move.b d2,ccr * restore flags

* now decide whether to move upper or lower bound
 bcs tablecomp2 * table entry<keyword in program
* table entry > keyword in program
* so upper bound:=value just examined
 lsr.w #tbits,d1 * retrieve keyword number
 move.w d1,d7
 bra.s tablecomp1
tablecomp2
* lower bound:=value just examined
 lsr.w #tbits,d1 * retrieve keyword number
 move.w d1,d6
 bra.s tablecomp1

tablecompnotfound
 clr.w d0 * error condition
 rts

tablecompfound
 lsr.w #tbits,d1 * find keyword number from table offset
 addq.w #1,d1 * numbered from 1 upwards because 0 = error condition
 move.w d1,d0 * return number in d0.w
 rts
*---
stringcompare
* compare string at (ptr.l) with $0(a3.l,d1.w)
* return cs if $0(a3,d1) < (ptr)
* first check initial character
* if the strings match, return ptr.l pointing to first
* character after string
 move.b (ptr),d0
 bsr compisd0alphanumeric * convert to upper case
 move.b $0(a3,d1),d2
 cmp.b d0,d2 * symbol table is upper case
 bne stringcompret

* now check for subsequent characters
* both strings are terminated by any non-alphabetic
* character. For speed, this is at present
* any character<'A'
 move.l ptr,-(sp)
 move.l a3,-(sp)
sc1
 addq.l #1,ptr
 addq.l #1,a3

 move.b $0(a3,d1),d2
 cmp.b #'0',d2
 bcs.s scequal * unsigned < - end of string, so equal
 move.b (ptr),d0
 bsr compisd0alphanumeric
 beq.s scequal * unsigned < - end of string, so equal
 cmp.b d0,d2
 bne.s scfail
 bra.s sc1
scequal
 move.b (ptr),d0
 bsr compisd0alphanumeric
 bne scfailcarryset * more chars in prog, so no match
 move.b $0(a3,d1),d0
 bsr compisd0alphanumeric
 bne scfail * more chars in symbol table, so no match


 move.l (sp)+,a3
 addq.l #4,sp * do not restore ptr - want to point to after it
 clr.b d0 * set z
 rts

scfailcarryset
* set carry, then fail
 or.b #1,ccr * set carry flag

scfail
 move.l (sp)+,a3
 move.l (sp)+,ptr
 move.w sr,d2 * preserve c flag
 move.b #$ff,d0 * error return - ne flags - this also corrupts c!!!!
 and.b #$FB,d2 * make sure z flag is reset
 move.b d2,ccr * restore c flag
stringcompret
 rts
 
*---
compsupersearch
* search, skipping over comments if present
 bsr compsearch
 cmp.b #"*",d0
 beq compssskiptoeol
 cmp.b #";",d0
 beq compssskiptoeol
 cmp.b compterminator,d0
 beq compssskiptoeol
 cmp.b #32,d0
 bcs.s compssskiptoeol * control code, not terminator. => unwanted cr/lf
 tst.b d0
 rts
compssskiptoeol
 bsr compskiptoeol
 bra compsupersearch * on new line as well!
*---
compskiptoeol
 move.b (ptr)+,d1
 cmp.b compterminator,d1
 beq.s compskiptoeol1
 bra.s compskiptoeol

compskiptoeol1
* now wait for any crs/lfs to die away
 lea totalSourceLines,a0
 addq.l #1,(a0)
 lea complinenumber,a0
 addq.l #1,(a0)
 bsr displayline
compskiptoeol1a
 move.b (ptr),d1
 cmp.b compterminator,d1
 beq.s compskiptoeol3
 cmp.b #eof,d1
 beq endofcompfile
 cmp.b #32,d1
 bcs.s compskiptoeol2
* neither cr nor lf, so must be start of new line
 rts

compskiptoeol2
* control code, not a terminator
 addq.l #1,ptr
 bra.s compskiptoeol1a
*
compskiptoeol3
* compterminator, so inc line number
 addq.l #1,ptr
 bra.s compskiptoeol1
*---
compsearch
* search, skipping spaces
 move.b (ptr),d0
 cmp.b #' ',d0
 bne.s compsearchret
 addq.l #1,ptr
 bra.s compsearch
compsearchret
 rts
*---
forwardoutofrange
 move.w d0,-(sp) * preserve offset in f/r table
 bsr compprs
 dc.b cr,"Forward reference to '",0
 even
 movem.l d0-d7/a0-a6,-(sp)
 move.l symboladdress,a0
 bsr absprintsymbol
 movem.l (sp)+,d0-d7/a0-a6

 bsr compprs
 dc.b "' out of range at line",0
 even
FROREnd
 move.w $2(a0,d0),d1
 clr.l d0
 move.w d1,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bsr compprs
 dc.b "in file ",0
 even
 move.w (sp)+,d0 * restore offset in f/r table
 move.b $8(a0,d0),d1
 clr.l d0
 move.b d1,d0 * file number in which error occured
 bsr compprintdecimald0
 bsr compflush * print buffer contents
 bra comperror1
*--- 
varexpected
 bsr compprs
 dc.b cr,"Variable expected",0
 even
 bra comperror
*---
acodeoverflow
 bsr compprs
 dc.b cr,"Acode overflow",0
 even
 bra comperror
*---
symboltableoverflow
 bsr compprs
 dc.b cr,"Symbol table overflow",0
 even
 bra comperror
*---
symboltoolong
 bsr compprs
 dc.b cr,"Symbol too long",0
 even
 bra comperror
*---
varnotdefined
 bsr compprs
 dc.b cr,"Variable not defined",0
 even
 bra comperror
*---
compilerbug
 bsr compprs
 dc.b cr,"Fatal compiler bug",0
 even
comperror
 bsr compprs
 dc.b " at line ",0
 even
 move.l complinenumber,d0
 bsr compprintdecimald0
 bsr compflush * print buffer contents

 bsr compprs
 dc.b " in file '",0
 even
 bsr compprintfilename
 bsr compprs
 dc.b "'",cr,0
 even

comperror1
* all errors come here
 lea compilationerrors,a0
 move.b #1,(a0) * prevent saving of code
 bsr compssskiptoeol
 move.l errorstack,sp
 rts
*---
compprintfilename
 clr.w d1
comppfname1
 move.b $8(a6,d1),d0
 beq.s comppfnameret
 move.b d0,(a6)
 move.b #oswrchdcode,d0
 bsr compdriver
 add.w #1,d1
 bra.s comppfname1
comppfnameret
 rts
*---
chartoprinter
* now send it to the printer
 move.l a0,-(sp)
 move.w d0,-(sp) * this is argument for routine as well as preservation
 call_bdos c_auxout * send to printer - call_bdos c_conout
 addq.l #2,sp * remove function call number etc.
 move.w (sp)+,d0
 move.l (sp)+,a0
 rts
*---
TooManyVars
 bsr compprs
 dc.b cr,"Too many variables at",0
 even
 bra comperror
*---
forwardrefoverflow
 bsr compprs
 dc.b cr,"The forward reference table overflowed",0
 even
 bra comperror
*---
cantredefinesymbol
 bsr compprs
 dc.b cr,"Can't redefine symbol",0
 even
 bra comperror
*---
badsymbol
 bsr compprs
 dc.b cr,"Bad symbol",0
 even
 bra comperror
*---
equalsexpected
 bsr compprs
 dc.b cr,"Equals expected",0
 even
 bra comperror
*---
commaexpected
 bsr compprs
 dc.b cr,"Comma expected",0
 even
 bra comperror
*---
bracketsexpected
 bsr compprs
 dc.b cr,"Bracket expected",0
 even
 bra comperror
*----
reljumpoutofrange
 bsr compprs
 dc.b cr,"Relative jump out of range",0
 even
 bra comperror
*---
badindex
 bsr compprs
 dc.b cr,"Bad table index",0
 even
 bra comperror
*---
badtype
 bsr compprs
 dc.b cr,"Bad type",0
 even
 bra comperror
*---
badoperator
 bsr compprs 
 dc.b cr,"Bad operator",0
 even
 bra comperror
*---
poundsignnotallowed
 bsr compprs
 dc.b cr,"Pound sign is not allowed in prs",0
 even
 bra comperror
*---
missingquote
 bsr compprs
 dc.b cr,"Missing quote",0
 even
 bra comperror
*---
badarg
 bsr compprs
 dc.b cr,"Bad argument",0
 even
 bra comperror
*---
badinstruction
 bsr compprs
 dc.b cr,"Instruction not recognized",0
 even
 bra comperror
*---
wronglabeltype
 bsr compprs
 dc.b cr,"Symbol redefined as different type",0
 even
 bra comperror
*---
compnotimp
 bsr compprs
 dc.b cr,"Something not implemented",0
 even
 bra comperror
*---
syntaxerror
 bsr compprs
 dc.b cr,"Syntax error",0
 even
 bra comperror
*---
PlusOrMinusExpected
 bsr CompPrs
 dc.b cr,"Plus or minus expected",0
 even
 bra comperror
*---
AlreadyInState
 bsr CompPrs
 dc.b cr,"Already in specified code state",0
 even
 bra CompError
*---
NotAllowedInAcode
 bsr CompPrs
 dc.b cr,"Instruction not allowed in interpreted acode",0
 even
 bra CompError
*---
NotAllowedInMC
 bsr CompPrs
 dc.b cr,"Instruction not allowed in machine code",0
 even
 bra CompError
*---
EvenError
 bsr CompPrs
 dc.b cr,"MC must be even-aligned",0
 even
 bra CompError
*---
CantDo16
 bsr CompPrs
 dc.b cr,"Can't do 16 bit tables in interpreted mode",0
 even
 bra COmpError 
*---
WrongCodeState
 move.b CodeState,d0
 bsr CompPRs
 dc.b cr,"Can't jump into area of different code state",0
 even
 bra COmpError
*---
ForwardWrongCodeState
 move.w d0,-(sp) * preserve offset in f/r table
 bsr compprs
 dc.b cr,"Forward reference to '",0
 even
 movem.l d0-d7/a0-a6,-(sp)
 move.l symboladdress,a0
 bsr absprintsymbol
 movem.l (sp)+,d0-d7/a0-a6

 bsr compprs
 dc.b "' changes code state at line",0
 even
 bra FROREnd
; move.w $2(a0,d0),d1
; clr.l d0
; move.w d1,d0
; bsr compprintdecimald0
; bsr compflush * print buffer contents
; bsr compprs
; dc.b "in file ",0
; even
; move.w (sp)+,d0 * restore offset in f/r table
; move.b $8(a0,d0),d1
; clr.l d0
; move.b d1,d0 * file number in which error occured
; bsr compprintdecimald0
; bsr compflush * print buffer contents
; bra comperror1
;

*---
controlwords
* each entry is of length tsize = 2^tbits
* with no terminator
* MUST BE ALPHABTICALLY SORTED
tsize equ 16
tbits equ 4 * number of shifts equivalent to tsize

 dc.b "BEGIN           "
 dc.b "CONST           "
 dc.b "TABLE           "
 dc.b "VAR             "
numcontrolwords equ 4
*---
compdriverbuffer
 ds.b 100
*---
saveacodedriverblock
 dc.l 0
 dc.l 0
 dc.b "acode.acd",0
 even
*---
loadcommandfile
 dc.l 0
 dc.l 0
 dc.b "compile.bat",0
*---
batchfilebuffer
 ds.b 500
*---
* workspace values
opcodeaddress dc.l 0
currentvarnumber dc.l 0 * .w
complinenumber dc.l 0
TotalSourceLines dc.l 0
startsymbols dc.l 0 * start of symbol table area
endsymbols dc.l 0 * end of symbol table area
freesymbol dc.l 0 * first free symbol address
startsource dc.l 0 * start of source area
endsource dc.l 0 * end of source area
symboltablesize dc.l 0 * size of symbol table area
savedacodeptr dc.l 0
startacode dc.l 0 * start of acode area
endacode dc.l 0 * end of acode area
errorstack dc.l 0 * stack value for when errors occur
startforward dc.l 0
freeforwardref dc.l 0 * .w - offset within forward ref table
endforward dc.l 0
symboladdress dc.l 0
cbatchptr dc.l 0

CurrentJumpTable dc.l 0 * pointer to the current compiler jump table
*---
debugginginfoon dc.b 0
compterminator  dc.b 0
jumpdummyopcode dc.b 0 * absolute jump
forcedlongjumps dc.b 0 * zero if off, 1 if on
filenumber dc.b 0
cexecutingcommandfile dc.b 0
compilationerrors dc.b 0 * set non-zero if any errors occur
supresscompilation dc.b 0 * set to 1 for conditional assembly
CodeState dc.b 0 * set to "+" to generate MC
SixteenFlag dc.b 0 * set to indicate 16 bit list operations
*---
* symbol table entry structure
symbolsize equ 32
symbolbits equ 5
symboltextlength equ 20 * deliberately small for cpm compatability
CodeStateOffset equ 24 * states what type of code is present
typeoffset equ 25 * byte - high bit is SET to 1 when label has been used
ptroffset equ 26 * must be word-aligned (long)
valueoffset equ 30 * word-aligned (word)
*
constanttype equ 1
vartype equ 2
tabletype equ 3
labeltype equ 4
undefinedlabeltype equ 5
*
forwardentrysize equ 16 * ???10 * must be even
*
eqop equ 0 * =
neop equ 1 * <>
ltop equ 2 * <
gtop equ 3 * >
*
smallmask equ $40 * if size bit (bit 6)=1, it is a 8 bit constant
relmask equ $20 * if relbit (bit 5)=1, it is a short jump
*--- 
* default sizes of various regions
hashtablesize equ 256*symbolsize * approximately
sizesymbolarea equ 110000 ; 60000
sizeacodearea equ 24500
sizeforwardarea equ 40000 ; 28000
sizegamedata equ 50000 ; 40000
*---
 even
DummyShortOpcode dc.b relmask * must be (startAcode)-6 for CODE.S
DummyShortOpcodeOffset equ -6
DummyLongOpcode dc.b 0 * must be (StartAcode)-5 for CODE.S
DummyLongOpcodeOffset equ -5

 dc.l 0 * pad out - must be just before endcompiler
endcompiler
startfile equ endcompiler+sizeacodearea
; gamedata goes here (at startfile)
; transients like exits, tables are
; loaded at (startsources)=startfile+sizegamedata
