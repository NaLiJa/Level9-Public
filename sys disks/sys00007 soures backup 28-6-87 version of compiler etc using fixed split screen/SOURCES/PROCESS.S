* File processor system
*
* Copyright (C) 1986 Level 9 Computing
*
* M.J.Austin 23/11/86

 opt d+  * turn on symbol table dump (remove this line to prevent)

processstart

 move.b #initdcode,d0
 bsr driver

 bra start
 include driver.s

 even
memoryerrors
 dc.w 0

 even
start
 lea processdriverbuffer(pc),a6
 bsr prs
 dc.b 13,"File processor 1.2  23/11/86",cr
 dc.b "Copyright (C) 1986 Level 9 Computing",cr
 dc.b "M.J.Austin.",cr,0
 even

displaymenu
 bsr prs
 dc.b 27,"v" * enable auto-overflow at eol
 dc.b 15 * switch off paging
 dc.b cr
 dc.b "0 .. Return to Gem",cr
 dc.b "1 .. Display file",cr
 dc.b "2 .. Replace spaces with &1E (for use by 1st Word)",cr
 dc.b "3 .. Display character set",cr
 dc.b "4 .. Count number of words in file",cr
 dc.b "5 .. Replace control codes (other than cr,lf) with spaces",cr
 dc.b "6 .. Examine memory",cr
 dc.b "7 ..  [Set 50 Hz operation (colour monitor only)]",cr
 dc.b "8 .. Memory test",cr
 dc.b "9 ..  [Change memory configuration (risky)]",cr
 dc.b "A ..  [Set 512K operation (doesn't work)]",cr
 dc.b "B ..  [Operate as centronics to serial converter (notimp)]",cr
 dc.b "C ..  [Convert Z80 source to 68000 (not implemented)]",cr
 dc.b "D .. Binary search/replace on file",cr
 dc.b "E .. Load a file into memory",cr
 dc.b "F .. Save a file from memory",cr
 dc.b "G .. Hit Breakpoint (Needs MONST)",cr
 dc.b "H .. compare two files",cr
 dc.b "I .. strip first n characters from each line",cr
 dc.b "J .. compression stuff",cr
 dc.b "Your selection: ",0
 even

getselection
 bsr osrdch
 bsr converttouppercase
 cmp.b #"0",d0
 beq returntogem
 cmp.b #"1",d0
 beq displayfile
 cmp.b #"2",d0
 beq replacespaces
 cmp.b #"3",d0
 beq displaycharacterset
 cmp.b #"4",d0
 beq countwords
 cmp.b #"5",d0
 beq stripcontrolcodes
 cmp.b #"6",d0
 beq examinememory
 cmp.b #"7",d0
 beq set50
 cmp.b #"8",d0
 beq systemtest
 cmp.b #"9",d0
 beq changememory
 cmp.b #"A",d0
 beq set512k
 cmp.b #"B",d0
 beq paralleltoserial
 cmp.b #"C",d0
 beq convertz80to68000
 cmp.b #"D",d0
 beq globalreplace
 cmp.b #"E",d0
 beq loadfileintomemory
 cmp.b #"F",d0
 beq savefilefrommemory
 cmp.b #"G",d0
 beq hitbreakpoint
 cmp.b #"H",d0
 beq filecompare
 cmp.b #"I",d0
 beq stripfirst
 cmp.b #"J",d0
 beq compression
 bra getselection

stripfirst
 lea processend,a0
 move.l a0,(a6)
 clr.b $8(a6) * zero filename - driver to prompt
 move.b #loaddcode,d0
 bsr driver

 move.l $4(a6),a5 ; end address
 bsr prs
 dc.b "How many characters to strip? ",0
 even
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 bsr readdecimal
 move.l d0,d7 ; no. of chars to strip off
 lea processend,a0 ; current pointer
 move.l a5,a4 ; a4=write pointer
stripmore
 add.l d7,a0 ; skip n characters
; now copy to end of line
strip1
 move.b (a0)+,d0
 move.b d0,(a4)+
 cmp.b #lf,d0
 beq stripmore
 cmp.l a5,a0 ; a5=end of source, a0=current read address
 bls.s strip1
; end of file, write out result
 move.l a4,$4(a6) ; end of resulting file
 move.l a5,(a6) ; start of resulting file
 move.b #savedcode,d0
 bsr driver
 bra displaymenu
;---
filecompare
 move.b #loaddcode,d0
 lea processend,a0
 move.l a0,(a6)
 clr.b $8(a6) * zero filename - driver to prompt
 bsr driver

 move.l $4(a6),d0
* make address even
 btst #0,d0
 beq.s filecompare0a
 addq.l #1,d0
filecompare0a

 move.l d0,(a6) * load new file at end of first
 clr.b $8(a6) * zero filename - driver to prompt
 move.b #loaddcode,d0
 bsr driver

 lea processend,a0
 move.l (a6),a5
* a0.l = first address of first file
* a5.l = first address of second file
filecompare0
 move.b (a5)+,d0
 cmp.b (a0)+,d0
 beq.s filecompare1

 move.l a0,-(sp)
 lea processend,a1
 sub.l a1,a0 * make relative to start of file
 move.l a0,d0
 bsr printdecimald0
 bsr prs
 dc.b " $",0
 even
 move.l (sp),a0 * no inc, notice
 lea processend,a1
 sub.l a1,a0 * make relative to start of file
 bsr hexlonga0
 bsr prs
 dc.b cr,0
 even
 move.l (sp)+,a0

filecompare1
 move.l $4(a6),d0
 cmp.l a5,d0
 bne filecompare0
 bra displaymenu
*---
loadfileintomemory
 bsr prs
 dc.b cr,"First free memory is at: ",0
 even
 lea processend,a0
 bsr hexlonga0

 bsr prs
 dc.b cr,"Enter start address: ",0
 even
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 bsr readhex

 move.l d0,(a6) * load address
 move.b #0,$8(a6) * force driver to prompt for filename
 move.b #loaddcode,d0
 bsr driver
 bsr prs
 dc.b cr,"End of file is at: ",0
 even
 move.l $4(a6),a0
 bsr hexlonga0
 bra displaymenu

savefilefrommemory
 bsr prs
 dc.b cr,"Enter start address: ",0
 even
 move.b #0,$8(a6)
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 bsr readhex
 move.l d0,-(sp)

 bsr prs
 dc.b cr,"Enter end address:   ",0
 even
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 bsr readhex
 move.l d0,$4(a6) * end address

 move.l (sp)+,d0
 move.l d0,(a6) * start address

 move.b #0,$8(a6) * force driver to prompt for filename
 move.b #savedcode,d0
 bsr driver
 bra displaymenu

hitbreakpoint
 dc.w $4afa * leave this in !!!!
 lea processend,a0
 bra displaymenu

globalreplace
* first get file
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * zero filename - tells driver to get one from user
 lea buffer(pc),a1
 move.l a1,(a6)
 move.b #loaddcode,d0
 bsr driver
* now, $0(a6) is start of file
*      $4(a6) is end of file
 lea endoldfile(pc),a0
 move.l $4(a6),d5
 move.l d5,(a0) * preserve for later use
 move.l (a6),a5 * current pos in buffer
* now get string of bytes to replace
 bsr prs
 dc.b 'Enter hex values of string to replace',cr,0
 even
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 lea origtable(pc),a1
 clr.l d4 * number of bytes entered
gr1
 cmp.b #0,(a0) * any more bytes present on line?
 beq.s endsearchtable
 bsr search * skip any redundant spaces
 bsr readhex * at a0
 sub.l #1,a0 * go back to avoid losing bytes
 move.b d0,(a1)+
 addq.b #1,d4
 bra.s gr1

endsearchtable
 bsr prs
 dc.b 'Enter hex values to replace with:',cr,0
 even
* now get hex values from user in repltable
 move.b #inputlinedcode,d0
 bsr driver
 move.l a6,a0
 lea repltable(pc),a1
 clr.l d3 * number of bytes in repltable
gr2
 cmp.b #0,(a0) * any more bytes present on line
 beq.s gr3
 bsr search * skip any redundant spaces
 bsr readhex * at a0
 subq #1,a0 * go back to avoid losing bytes
 move.b d0,(a1)+
 addq.b #1,d3
 bra.s gr2

gr3
* now go through and do search/replace
* writing out a new copy
* a5 is current buffer pos
* d5 is length of file
* d4 is number of bytes to search for
* d3 is number of bytes to replace with
* first calc position of new version
 move.l endoldfile(pc),a2
 move.l a2,d5
 sub.l a0,d5 * calc length
 add.l #8,a2 * skip to start of new version

* (origtable) is bytes to replace
* (repltable) is bytes to replace with
 lea origtable(pc),a4
 lea repltable(pc),a3
comp1
 clr.l d1 * offset from base values for compare
comp2
 move.b $0(a5,d1),d0
 cmp.b $0(a4,d1),d0
 bne.s nomatch
* got a match, so continue comparing until end of match table
 addq.b #1,d1
 cmp.b d1,d4
 bne.s comp2
* got a complete match, so skip values in original,
 add.l d4,a5
 sub.l d4,d5 * reduce file length to go
* and replace with repltable in new version
 move.b #0,d1
repl1
 move.b $0(a3,d1),d0 * value from repltable
 move.b d0,(a2)+ * copy into new version
 addq.b #1,d1
 cmp.b d1,d3 * number of bytes in repltable
 bne.s repl1
 bra.s nomatch1

nomatch
* no match, so copy a single character 'as is'
 move.b (a5)+,d0
 move.b d0,(a2)+
 sub.l #1,d5 * decrement length of file
nomatch1
 tst.l d5 * length of file remaining
 bpl.s comp1
* that's all folks!
* write the file out to disk
 move.l a2,$4(a6) * end of file
 move.l endoldfile(pc),a0
 add.l #8,a0 * skip to start of new version
 move.l a0,(a6) * start of file
 move.b #savedcode,d0
 bsr driver
 bra displaymenu 


convertz80to68000
* given a z80 source listing, generate  68000 code version
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * zero filename - tells driver to get one from user
 lea buffer(pc),a1
 move.l a1,(a6)
 move.b #loaddcode,d0
 bsr driver
* now, $0(a6) is start of file
*      d5     is end of file
 move.l $0(a6),a0
 move.l $4(a6),a2 * end of file - pointer to new version
cz80loop
 bsr search * skip over tables etc.
 cmp.b #";",d0
 beq.s cz80comment
 lea opcodetable(pc),a1
 bsr compareopcode * if recognized, sets a1 to entry in table
 bne.s cz80comment ; not recognized, so treat as a comment
* now replace this opcode with the 68000 version
* a1 is the pointer to the new version
* a0 is at start of opcode
* first, copy in new opcode
cz80replace1
 move.b (a1)+,d0
 cmp.b #" ",d0
 beq.s cz80replace2
 move.b d0,(a2)+
 bra.s cz80loop

cz80replace2
* first, skip the opcode
 bsr skiptospace
 bsr search
* now a0 points to first argument in z80 code
* and a1 points to first argument in 68000 version


 bra displaymenu

cz80comment
* ignore the rest of the line
 move.b (a0)+,d0
 cmp.b #lf,d0
 bne.s cz80comment
 bra.s cz80loop

compareopcode
 rts

search
* given a0=pointer into text file,
* move to next non-space character
* which is returned in d0.b
 move.b (a0),d0
 beq.s searchret
 cmp.b #" ",d0
 bne.s searchret
 addq #1,a0
 bra.s search
searchret
 rts

skiptospace
* given a0=pointer into text file,
* move to next space
 move.b (a0)+,d0
 cmp.b #" ",d0
 bne.s search
 rts

opcodetable
 dc.b "hello",0


paralleltoserial
* turns the ST into a parallel-in serial-out buffer
* Useful for serial printers.

* first set port B (of GIA) to input and port A to output
* turn all sound off as well
 move.w #$40,d1
 move.w #7,d0 * register to write
 bsr giawrite

 bsr clearbusy

* now look for data strobe, then pick up data
waitstrobe
 move.w #15,d0 * read port B
 bsr giaread
* data is in d1.w
 btst #7,d1
 bne.s waitstrobe
* got valid data in d1.w
 and.b #$7f,d1
 move.b d1,(a6)
 move.b #oswrchdcode,d0
 bsr driver
 bra waitstrobe
*---

clearbusy
* send low on the ST's strobe line - but remember
* we are pretending the ST is a printer, so this
* appears as a busy signal to the outside world
* see p. 193 of ST Internals
 move.w #5,-(sp)
 move.w #30,-(sp) * offgibit - clear bit 5 of port A
 trap #14
 addq.l #4,sp
 rts
*---
giaread
* read gia register d0.w, giving result in d1.w
 movem.l d0-d3,-(sp)

 move.w d0,-(sp)
 move.w #0,-(sp)
 move.w #28,-(sp)
 trap #14
 addq.l #6,sp

 movem.l (sp)+,d0-d3
 rts
*---
giawrite
* write gia register d0.w with data d1.w
 movem.l d0-d3,-(sp)

 or.b #$80,d0
 move.w d0,-(sp)
 move.w d1,-(sp)
 move.w #28,-(sp)
 trap #14
 addq.l #6,sp

 movem.l (sp)+,d0-d3
 rts
*---


set50
* routine executes set50a in supervisor mode:
 lea set50a(pc),a0
 bsr.s callsupera0
 bra start

callsupera0
* execute routine at a0 in supervisor mode
 move.l a0,-(sp)
 move.w #38,-(sp)
 trap #14
 addq.l #6,sp
 rts

set50a
* this routine is called in supervisor mode
 move.b #2,$ff820a
 rts

changememory
* this routine executes cma in supervisor mode:
 bsr prs
 dc.b cr,"Current value of configuration word ($FF8001)"
 dc.b cr,"(see p56 of ST Internals for info) is ...... ",0
 even
 lea readconfiguration(pc),a0
 bsr.s callsupera0
 move.b configuration(pc),d0
 bsr hexbyted0
 bsr prs
 dc.b cr,"Enter new value (05 = 1024 K, 04 = 512 K )"
 dc.b cr," (press return to leave well alone): ",0
 even
 move.b #inputlinedcode,d0
 bsr driver
 move.b (a6),d0
 beq start * nothing entered
 move.l a6,a0
 bsr readhex * returns (a0) in d0.l
 lea configuration(pc),a0
 move.b d0,(a0)
 lea writeconfiguration(pc),a0
 bsr callsupera0
 bra start

configuration dc.b 0
 even

readconfiguration
* read memory configuration (executed in supervisor mode)
 move.b $ff8001,d0
 lea configuration(pc),a0
 move.b d0,(a0)
 rts

writeconfiguration
 move.b configuration(pc),d0
 move.b d0,$ff8001
 rts

set512k
* first set screen address to $78000
 move.w #-1,-(sp) * retain resolution
 move.l #$78000,-(sp)
 move.l #$78000,-(sp)
 move.w #5,-(sp) * code to set screen
 trap #14
 add.l #12,sp
* now change memory configuration
 lea configuration(pc),a0
 move.b #4,(a0)
 lea writeconfiguration(pc),a0
 bsr callsupera0
 bra start

*---
 
systemtest
 lea memoryerrors(pc),a0
 move.w #0,(a0)
 bsr prs
 dc.b cr,"Performing memory test (hit a key to exit)",cr
 dc.b "Start of screen = ",0
 even

 bsr getscreenaddress
* a0.l = start of screen
 bsr hexlonga0
 bsr prs
 dc.b cr,"Total memory installed = ",0
 even

 bsr getscreenaddress
* a0.l=d0.l = screen start
 add.l #$8000,d0
 move.l d0,-(sp) * preserve top of memory
 lsr.l #5,d0
 lsr.l #5,d0
 bsr printdecimald0
 bsr prs
 dc.b "K",cr,0 * amount of storage in K
 even

 bsr prs
 dc.b "Memory Free = ",0
 even
 bsr getscreenaddress
 lea processstart(pc),a1
 sub.l a1,a0 * a0=free memory
 move.l a0,d0
 lsr.l #5,d0
 lsr.l #5,d0
 bsr printdecimald0
 bsr prs
 dc.b "K",cr,0
 even


 bsr getscreenaddress
 move.l a0,a1 * end for memory test routines
systemtest0
* now do memory test between processend and screen start
 lea processend(pc),a0
systemtest1
 move.b #0,(a0)+
 cmp.l a0,a1
 bne systemtest1
 lea processend(pc),a0
systemtest2
 move.b (a0),d0
 bne.s memoryfail
 move.b #$ff,(a0)+
 cmp.l a0,a1
 bne.s systemtest2

 lea processend(pc),a0
systemtest3
 move.b (a0)+,d0
 cmp.b #$ff,d0
 bne.s memoryfail
 cmp.l a0,a1
 bne.s systemtest3

 lea scrolledlines,a0
 clr.b (a0) * reset paging count in driver

 bsr prs
 dc.b "OK ",0 
 even

 move.b #osrdchdcode,d0
 bsr driver
 cmp.b #0,(a6)
 beq systemtest0
 bsr prs
 dc.b cr,"Total errors found = ",0
 even

 move.w memoryerrors(pc),a0
 bsr hexworda0
 bsr prs
 dc.b cr,0
 even

 bra start

memoryfail
 bsr prs
 dc.b cr,"memory fail at: ",7,7,7,0
 bsr hexlonga0
 bsr prs
 dc.b cr,0
 lea memoryerrors(pc),a0
 addq.w #1,(a0)
 bra systemtest0

*---

displayfile
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * zero filename - tells driver to get one from user
 lea buffer(pc),a1
 move.l a1,(a6)
 move.b #loaddcode,d0
 bsr driver
 move.l (a6),a1
 move.l $4(a6),d5 * end address of file
 sub.l a1,d5
displayfileloop
 move.l d5,-(sp) * preserve length of file
* display 8 words in hex format
* first give address, relative to start of file
 move.l a1,a0
 lea buffer(pc),a2
 sub.l a2,a0
 bsr hexlonga0
 move.b #" ",d0
 bsr oswrch

 move.w #8,d6
dflhex
 move.w (a1)+,a0 * get data
 bsr hexworda0
 move.b #" ",d0
 bsr oswrch
 subq.b #1,d6
 bne.s dflhex

* display same 8 words in ascii format
 sub.l #16,a1
 move.w #16,d6
dflascii
 move.b (a1)+,d0 * get data
 bsr protectedoswrch
 subq.b #1,d6
 bne.s dflascii

 move.b #crlf,d0
 bsr oswrch

 move.l (sp)+,d5
 sub.l #16,d5
 bpl.s displayfileloop 
 bra displaymenu

getfileinbuffer
* return d5=length, a1=first address
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * no filename supplied to load
 lea buffer(pc),a1
 move.l a1,(a6)
 move.b #loaddcode,d0
 bsr driver
 move.l (a6),a1
 move.l $4(a6),d5 * end address loaded
 sub.l a1,d5 * calc length of file
 rts

replacespaces
* go through file, replacing spaces ($20) with $1E
* as required by 1st Word ($20 is treated as a 'hard' space)
 bsr getfileinbuffer
* a1=first address, d5=length
rs1
 move.b (a1)+,d0
 cmp.b #" ",d0
 bne.s rs2
 move.b #$1e,$-1(a1)
rs2
 bsr protectedoswrch
 subq.w #1,d5 * data loaded
 bne.s rs1
* now save out modified file
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * zero filename
 lea buffer(pc),a1
 move.l a1,(a6)
* end address is still at $4(a6)
 move.b #savedcode,d0
 bsr driver
 bra displaymenu

stripcontrolcodes
* go through file, replacing control codes with spaces
 bsr getfileinbuffer
* a1=first address, d5=length
scc1
 move.b (a1)+,d0
 cmp.b #" ",d0
 bge.s scc2
 cmp.b #cr,d0
 beq.s scc2
 cmp.b #lf,d0
 beq.s scc2
 move.b #" ",$-1(a1)
scc2
 subq.w #1,d5 * data loaded
 bne.s scc1
* now save out modified file
 lea processdriverbuffer(pc),a6
 move.b #0,$8(a6) * zero filename
 lea buffer(pc),a1
 move.l a1,(a6)
* end address is still at $4(a6)
 move.b #savedcode,d0
 bsr driver
 bra displaymenu


displaycharacterset
 bsr prs
 dc.b cr,cr,0
 even
 lea processdriverbuffer(pc),a6
 move.b #0,d7
dcs1
 move.b d7,d0
 bsr hexbyted0
 move.b d7,(a6)
 move.b #oswrchdcode,d0
 bsr driver
 move.b #" ",(a6)
 move.b #oswrchdcode,d0
 bsr driver
 addq.b #1,d7
 bne.s dcs1
 bsr prs
 dc.b cr,"Press a key to return to menu",cr,0
 even
 bsr waitkey
 bra start

countwords
 bsr getfileinbuffer
 move.w #0,d1 * number of words found
countwords1
* find the start of a word
 move.b (a1)+,d0
 subq.w #1,d5 * decrement length
 beq.s countwordsreport
 cmp.b #"A",d0
 bls countwords1 * less than or equal
* start of  a word
* now skip to end of word
 addq.w #1,d1 * increment word counter
countwords2
 move.b (a1)+,d0
 subq.w #1,d5
 beq.s countwordsreport
 cmp.b #"A",d0
 bcc.s countwords2 * still an alphanumeric
 bra.s countwords1 * and another word
 
countwordsreport
 move.w d1,-(sp)
 bsr prs
 dc.b "Number of Words found = ",0
 even

 clr.l d0 * clear hi-order bits of number of words
 move.w (sp)+,d0
 bsr printdecimald0
 bra displaymenu
*---
examinememory
 lea driverbuffer(pc),a6
 bsr prs
 dc.b 12,'graphics experimentor',cr
 dc.b ' 0 .. return to main menu',cr
 dc.b ' 1 .. fill area of memory with pattern 0,1,2...255 etc.',cr
 dc.b ' 2 .. change single byte',cr
 dc.b cr
 dc.b ' Your choice: ',0
 even
em1
 move.b #osrdchdcode,d0
 bsr driver
 move.b (a6),d0
 tst.b d0
 beq.s em1
 cmp.b #"0",d0
 beq start
 cmp.b #"1",d0
 beq.s fillarea
 cmp.b #"2",d0
 beq.s changebyte
 bra examinememory
*
getnumberd0
 move.b #inputlinedcode,d0
 bsr driver
 move.b (a6),d0
 cmp.b #"*",d0
 beq examinememory
 move.l a6,a0 * for readhex
 bra readhex
* cmp.b #"0",d0
* bcs.s getnumberd0
* cmp.b #"9",d0
* bhi.s getnumberd0
* move.l a6,a0
* bra readdecimal

changebyte
 bsr prs
 dc.b 'address (* to exit): ',0
 even

 bsr.s getnumberd0
 move.l d0,-(sp)
 bsr prs
 dc.b 'value (* to exit): ',0
 even

 bsr getnumberd0
 move.l (sp)+,a0
 move.b d0,(a0)
 bra changebyte

fillarea
 bsr prs
 dc.b 'address (* to exit): ',0
 even
 bsr getnumberd0
 cmp.l #$10000,d0
 blt.s fillarea
* value is in d0.l
 move.l d0,a0
 move.b #0,d0
 move.w #1000,d1 * area to fill
fillarea1
 move.b d0,(a0)+
 addq.b #1,d0
 subq.w #1,d1
 tst.w d1
 bne.s fillarea1
 bra examinememory

printchar
 bra oswrch * should not be here (see comment on printchar in driver)
 even

compression
* load a picture into the screen
 lea picturefilenamebuffer,a6
 move.b #loaddcode,d0
 bsr driver
* now demonstrate the effects of compression on the picture...
 dc.w $4afa
 lea #$78000,a0
compress1
 move.b (a0),d0
 ror.b #4,d0 * do hi nibble first
 bsr compressnibble
 ror.b #4,d0 * do lo nibble next
 bsr compressnibble
 move.b d0,(a0)+
 cmp.l #$7ffff,a0
 bne.s compress1
 dc.w $4afa

compressnibble
* d2='accumulated value'
 move.b d0,d1
 and.b #$0f,d1 * mask off high nibble
 cmp.b d1,d2 * d2=last value
 bge.s cn2
* last value<new value, so move in positive direction
 move.b #1,d3
 bra.s cn5

cn2
 ble.s cn3
* last value>new value, so move in negative direction
 move.b #$ff,d3
 bra.s cn5

cn3
* last value=new value, so move in opposite direction to
* last time
 move.b #$ff,d7
 cmp.b #1,d4
 beq.s cn4
 move.b #1,d7
cn4
 move.b d7,d3

cn5
* d3=direction to move in this time
* now change step size (d5) depending on last direction (d4)
 cmp.b d3,d4
 beq cnincreasestep
* reduce step
 lsr.b #1,d5 * step size=stepsize/2
 tst.b d5
 bne.s cn7
 move.b #1,d5 * limit step size to 1
 bra.s cn7

cnincreasestep
 asl.b #1,d5 * step size=stepsize*2
 cmp.b #16,d5
 ble.s cn7
 move.b #16,d5 * limit step size to 16

cn7
* step size is d5, direction is d4
 cmp.b #1,d4
 bne.s cn7notpositive
 add.b d5,d2
 cmp.b #16,d2
 blt.s cn10
 move.b #16,d2 * limit to 16 (max permitted pixel value)
 bra.s cn10

cn7notpositive

cn10
* d2 is new accumulated value

picturefilenamebuffer
 dc.l $78000
 dc.l 0
 dc.b "\pictures.l9\cave.l9",0
* ------------- 
processdriverbuffer
 ds.b 80
 nolist

 even
endoldfile
 dc.l 0

 even
origtable
* for search/replace
 ds.b 40
 even
repltable
 ds.b 40

buffer
 ds.l 2 * must be last thing in code

even
processend
* end of data in code (start of memory test area)












































