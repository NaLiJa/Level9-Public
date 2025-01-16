* finish program
*
* M.J.Austin 5/8/86
*
* Copyright (C) 1986 Level 9 Computing

finishedptr equr a4
ptr equr a5

 bra finishstart * (!)
 include driver.s

printchar
 bra driverprintchar

finishstart
 lea finishdriverbuffer,a6
 bsr prs
 dc.b "Acode finish 0.1",cr
 dc.b "Copyright (C) 1986 Level 9 Computing",cr,cr,0
 even

* this program always produces a complete.dat
* file from the data on the disk

 lea endfinish,finishedptr * register pointer to data area
 add.l #60000,finishedptr * allow space for files to be loaded
 lea startcomplete,a0
 move.l finishedptr,(a0) * pointer to start of complete.dat block in memory
 add.l #sizeofpointers,finishedptr
 bsr processexits

 bsr processtables

 bsr savedirectory
 bsr selectdirectory * subdirectory for computer-specific text
 bsr processsquash
 bsr climb * and back to root for acode

 bsr processacode

 bsr finishchecksum

 bsr descend
 bsr prs
 dc.b "Saving gamedata.dat",cr,0
 even

 lea savecompletedriverblock,a6
 move.l startcomplete,(a6) * start address to save
 move.l finishedptr,$4(a6) * end address to save
 move.b #savedcode,d0
 bsr driver
 bsr climb * leave us back where we started

 bra returntogem
*---
softinit
* init for each stage of development
 lea linenumber,a0
 move.l #1,(a0)
 rts
*---
even
* make ptr.l even
 move.l ptr,d0
 and.b #1,d0
 beq.s evenret
 addq.l #1,ptr
evenret
 rts
*---
processexits
 bsr softinit
 bsr prs
 dc.b "Loading exit.txt",cr,0
 even
 lea loadexitsdriverblock,a6
 lea endfinish,ptr
 move.l ptr,(a6) * start address
 move.l startcomplete,a0
 add.l #exitptroffset,a0
 move.l finishedptr,d0
 sub.l startcomplete,d0
 move.b d0,(a0) * poke in rel. ptr to exits
 lsr.w #8,d0
 move.b d0,$1(a0)

 move.b #loaddcode,d0
 bsr driver
 move.l (a6),ptr * start of exit data
 move.l $4(a6),a2 * end of exit data
nextexit
* first get four binary digits
 bsr supersearch
 bsr getbin
 move.b d0,d1 * assemble number in d1.b
 bsr getbin
 asl.b #1,d1
 or.b d0,d1
 
 bsr getbin
 asl.b #1,d1
 or.b d0,d1
 
 bsr getbin
 asl.b #1,d1
 or.b d0,d1
 
 bsr search
 move.l ptr,a0
 move.l d1,-(sp)
 bsr readdecimal
 move.l (sp)+,d1
 move.l a0,ptr
* d0.b = direction
 asl.b #4,d1
 or.b d1,d0
 move.b d0,(finishedptr)+
* now get destination room
 bsr search
 beq errorindata
 bsr search
 move.l ptr,a0
 bsr readdecimal
 move.l a0,ptr
 move.b d0,(finishedptr)+
 or.b -2(finishedptr),d0 * 0000 0 0 ? (=end of data)
 bne nextexit
processexitsend
 rts
*---
getbin
* return a binary digit in d0.b
 bsr search
 beq errorindata
 addq.l #1,ptr
 cmp.b #"0",d0
 beq.s gotbin
 cmp.b #"1",d0
 beq.s gotbin
 bra errorindata
gotbin
 sub.b #"0",d0
 rts
*---
processtables
 bsr prs
 dc.b "Loading table.dat",cr,0
 even
 lea endfinish,ptr
 lea loadtablesdriverblock,a6
 move.l ptr,(a6)
 move.b #loaddcode,d0
 bsr driver

* set up pointers at start of complete.dat file
* at the start of the table.dat file are pointers (longs)
* to the tables. There are #numtable of these
* and then a pointer to the end of the table file
* copy the table pointers
 add.l #$1c,ptr * skip reloc information
 move.b #9+1,d1 * number of tables

 move.l finishedptr,d2
 sub.l startcomplete,d2 * get start of tables relative to complete.dat
* ptr.l is start of table data ( assembled by any assembler)
 move.l startcomplete,a0
 add.l #list1ptroffset,a0
ptloop
 move.l (ptr)+,d0
* d0.l is a table pointer
* is it a workspace reference ? ($8000-$9000)
 cmp.l #$8000,d0
 bcs.s pt0
 cmp.l #$9000,d0
 bcs.s pt1 * between 8000 and 9000, so don't adjust
pt0
* so convert it to make it point to the table data
* relative to the start of complete.dat
 add.l d2,d0 * make table pointers relative to complete.dat start
 sub.l #9*4+4,d0 * 9 table pointers = 40
pt1
 move.w d0,d3
 move.b d3,(a0)+
 lsr.w #8,d3
 move.b d3,(a0)+
 subq.b #1,d1 * number of tables to process
 bne ptloop
* and copy data in to finished data area
* d0.w = end of table area offset
* d2.w = offset of start of tables
 move.l startcomplete,a0
pt2
 move.b (ptr)+,d1
 move.b d1,$0(a0,d2)
 addq.w #1,d2
 cmp.w d0,d2
 bne.s pt2 * reached end pointer yet?
 lea $0(a0,d0),finishedptr * end of data just copied
 rts

*---
processsquash
* load in squash.dat at finishedptr.l
* and adjust all pointers
 bsr prs
 dc.b "Loading squash.dat",cr,0
 even
 lea loadsquashdriverblock,a6
 move.l finishedptr,d0
 btst #0,d0
 beq.s psalreadyeven
 addq.l #1,finishedptr
psalreadyeven
 move.l finishedptr,(a6)
 move.b #loaddcode,d0
 bsr driver
 move.l finishedptr,ptr
 move.l startcomplete,finishedptr

 move.l ptr,d1
 sub.l startcomplete,d1
* a0.l = offset to add to all squash pointers
 bsr z80load * length
 lea squashlength,a0
 move.w d0,(a0)
 add.w d1,d0
 bsr z80write * startcomplete+0

 bsr z80load * message destriptor pointer
 add.w d1,d0
 bsr z80write

 bsr z80load * length of descriptors
 bsr z80write

 bsr z80load * word dictionary pointer
 add.w d1,d0
 bsr z80write

 bsr z80load * word dictionary length
 bsr z80write

 bsr z80load * word dictionary index table
 add.w d1,d0
 move.w d0,d2 * preserve value
 bsr z80write

 bsr z80load * number of segments
 move.w d0,d3 * preserve value
 bsr z80write

 bsr z80load * common word dictionary
 add.w d1,d0
 bsr z80write

 bsr z80load * version number - ignore

 bsr z80load * not used - ignore

* and adjust word dictionary pointers
* to make them relative to (startcomplete)
* d1.w is offset to add to pointer
* d2.w is offset of word dictionary pointer
* d3.w is number of segments

* fist find end of index table
 move.w d2,d4
 add.w d3,d4
 add.w d3,d4
 add.w d3,d4
 add.w d3,d4
 move.l startcomplete,a0
* $0(a0,d2) is start of table. $0(a0,d4) is end of table
* let d2.w be the offset used to scan the table
* d1.w is offset to add to pointers
psquash1
 cmp.w d2,d4
 beq psquashend
 move.b $1(a0,d2),d0
 asl.w #8,d0
 move.b $0(a0,d2),d0

 add.w d1,d0
 move.b d0,$0(a0,d2)
 lsr.w #8,d0
 move.b d0,$1(a0,d2)

 addq.w #4,d2
 bra.s psquash1
psquashend
 move.l (a6),ptr
 clr.l d0
 move.w squashlength,d0
 add.l d0,ptr
 move.l ptr,finishedptr
 rts
*---
z80load
 move.b $1(ptr),d0
 asl.w #8,d0
 move.b (ptr),d0
 addq.l #2,ptr
 rts
*---
z80write
 move.b d0,(finishedptr)+
 lsr.w #8,d0
 move.b d0,(finishedptr)+
 rts
*---
processacode
* load acode.acd at finishedptr.l
* and adjust all pointers
 bsr prs
 dc.b "Loading acode.acd",cr,0
 even
 lea loadacodedriverblock,a6

 move.l finishedptr,ptr
 bsr even * make ptr.l even
 move.l ptr,finishedptr

 move.l ptr,(a6)
 move.b #loaddcode,d0
 bsr driver

* get length of acode
 clr.l d0
 bsr z80load
 move.l ptr,d1
 add.l d0,d1 * end of complete.dat file in memory
 addq.l #1,d1 * allow an extra byte for the checksum
 move.l d1,finishedptr * end of complete.dat in memory
 sub.l startcomplete,d1 * size of complete.dat file
 subq.l #1,d1 * and another byte less for good measure
 move.l startcomplete,a1
 move.b d1,(a1)
 lsr.w #8,d1
 move.b d1,$1(a1)

 move.l ptr,d1 * start of acode in memory
 sub.l startcomplete,d1
 move.b d1,40(a1)
 lsr.w #8,d1
 move.b d1,41(a1)
* finishedptr.l is end of complete.dat file in memory
 rts
*---
finishchecksum
 move.l startcomplete,(a6) * start of block to checksum
 move.l finishedptr,a0
 subq.l #1,a0 * disregard checksum byte at present
 move.l a0,$4(a6)
 move.b #checksumdcode,d0
 bsr driver

 move.l $4(a6),a0 * address checksum done up to
 clr.b d0
 sub.b (a6),d0
 move.b d0,(a0)
 rts
*---
errorindata
 bsr prs
 dc.b "error in data at line ",0
 even
 move.l linenumber,d0
 bsr printdecimald0
 bsr prs
 dc.b cr,"Press a key to return to Gem",cr,0
 even
 bsr waitkey
 bra returntogem
*---
supersearch
* search, skipping over comments if present
 bsr search
 cmp.b #"*",d0
 beq ssskiptoeol
 cmp.b #";",d0
 beq ssskiptoeol
 cmp.b terminator,d0
 beq ssskiptoeol
 cmp.b #32,d0
 bcs.s ssskiptoeol * control code, not terminator. => unwanted cr/lf
 tst.b d0
 rts
ssskiptoeol
 bsr skiptoeol
 bra supersearch * on new line as well!
*---
skiptoeol
 move.b (ptr)+,d1
 cmp.b terminator,d1
 beq.s skiptoeol1
 bra.s skiptoeol

skiptoeol1
* now wait for any crs/lfs to die away
 lea linenumber,a0
 addq.l #1,(a0)
* bsr displayline
skiptoeol1a
 move.b (ptr),d1
 cmp.b terminator,d1
 beq.s skiptoeol3
 cmp.b #eof,d1
 beq endoffile
 cmp.b #32,d1
 bcs.s skiptoeol2
* neither cr nor lf, so must be start of new line
 rts

endoffile
 addq.l #4,sp * skip return address
 rts

skiptoeol2
* control code, not a terminator
 addq.l #1,ptr
 bra.s skiptoeol1a
*
skiptoeol3
* terminator, so inc line number
 addq.l #1,ptr
 bra.s skiptoeol1
*---
search
* search, skipping spaces
 move.b (ptr),d0
 cmp.b #' ',d0
 bne.s searchret
 addq.l #1,ptr
 bra.s search
searchret
 rts
*---
*
* ++++++++++++++ Some ST specific code to scan
* 		 for possible sub-directories  +++++++++++++++++
* look in current directory for interesting sub-directories - 
* i.e. those which match with directoryname
selectdirectory
 bsr prs
 dc.b cr,0
 even

 clr.b d7 * number of files found
 lea filenamelist,a5
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
 bne.s nofiles

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
 add.b #"A"-1,(a6)
 move.b #oswrchdcode,d0
 bsr driver
 bsr prs
 dc.b " .. ",0
 even

 move.w #0,d2
 lea fileblock(pc),a0
menuprintfname1
 move.b $1e(a0,d2),d1
 move.b d1,(a5)+
 beq.s nextfile
 move.b d1,(a6)
 move.b #oswrchdcode,d0
 bsr driver
 addq.l #1,d2 * offset into filename
 bra.s menuprintfname1

nextfile
 move.b #cr,(a6)
 move.b #oswrchdcode,d0
 bsr driver

 move.w #$4f,-(sp) * snext function - any more files?
 trap #1
 addq.l #2,sp
 tst d0
 beq.s menuprintfname
* no more files
 bra getselection

nofiles
 bsr prs
 dc.b 'no suitable files on disk',cr,0
 bsr waitkey
 bra returntogem


getselection
 cmp.b #1,d7
 bne.s getsel0
 bsr prs
 dc.b cr,cr,"Only one sub-directory - proceeding with finish",cr,0
 even
 move.b #1,d0
 bra.s getselgotd0

getsel0
 bsr prs
 dc.b cr,cr,"Enter the letter corresponding to your choice .. ",0
 even

* now get a letter, A..d7+'A'
getsel1
 move.b #osrdchdcode,d0
 bsr driver
 move.b (a6),d0
 beq.s getsel1
 bsr converttouppercase

 move.w d0,-(sp) * echo character, leave cursor where it is
 bsr protectedoswrch
 move.b #8,(a6) * backspace cursor
 move.b #oswrchdcode,d0
 bsr driver
 move.w (sp)+,d0

 sub.b #"A"-1,d0
 beq getsel1 * '@' is not allowed
 cmp.b d7,d0
 bhi.s getsel1 * unsigned >

getselgotd0
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
* set up sub-directory whose name is at $0(a0,d1)
 lea $0(a0,d1),a0
 lea subdirnameptr,a1
 move.l a0,(a1) * save sub-directory name

 pea $0(a0,d1) * path name
 move.w #$3b,-(sp) * chdir
 trap #1
 addq.l #6,sp
 tst.w d0 * error?
 bne nofiles

 rts * fine!
*---
descend
* go back down to previously selected directory
 move.l subdirnameptr,-(sp)
 move.w #$3b,-(sp) * chdir
 trap #1
 addq.l #6,sp
 tst.w d0 * error?
 bne nofiles
 rts
*---
savedirectory
* save the current directory
* to be restored by climb
 clr.w d0 * use current drive
 move.w #0,-(sp)
 lea directorypathname,a0
 move.l a0,-(sp)
 move.w #$47,-(sp) * get directory
 trap #1
 addq.l #8,sp
 tst.l d0
 bne.s fileerror
 rts
*---
fileerror
 bsr prs
 dc.b "Can't get current directory name",cr
 dc.b "Press a key to return to gem",cr,0
 even
 bsr waitkey
 bra returntogem
*---
climb
 lea directorypathname,a0
 move.l a0,-(sp) * path name
 move.w #$3b,-(sp) * chdir
 trap #1
 addq.l #6,sp
 tst.w d0 * error?
 bne fileerror
 rts
*---
directorypathname
* will contain the complete path name
* for use by climb
 ds.b 100
*---
fileblock
 ds.b 44 * space for the file spec buffer
 even

directoryname
 dc.b '*.L9',0
 even

subdirnameptr
 dc.l 0

filenamelist
* for menu program to build up a list
* of possible games, from which the user chooses one
* this data is overwritten when the game is loaded
 ds.b 1000
*
* +++++++++++ End of ST Specific code ++++++++++++++++++++
*
*---
 even
finishdriverbuffer
 dc.b 40

 even
loadexitsdriverblock
 dc.l 0
 dc.l 0
 dc.b "exit.txt",0
 even
loadtablesdriverblock
 dc.l 0
 dc.l 0
 dc.b "table.dat",0
 even
loadsquashdriverblock
 dc.l 0
 dc.l 0
 dc.b "squash.dat",0
 even
loadacodedriverblock
 dc.l 0
 dc.l 0
 dc.b "acode.acd",0
 even
savecompletedriverblock
 dc.l 0
 dc.l 0
 dc.b "gamedata.dat",0
 even
*---
* and now some workspace
startcomplete dc.l 0 * start of complete.dat block in memory
endcompleteblock dc.l 0
linenumber dc.l 0
squashlength dc.w 0
*
terminator dc.b cr
 even
*---
* and constants
lengthpointeroffset equ 0
mdptroffset equ 2 * message descriptor ptr
mdlengthoffset equ 4
dictionaryptroffset equ 6
dictionarylengthoffset equ 8
indextableptroffset equ 10
numbersegments equ 12
numbercommonwordtable equ 14
versionptroffset equ 16
exitptroffset equ 18
list1ptroffset equ 22
list2ptroffset equ 24
list9ptroffset equ 38
acodeptroffset equ 40
startofdataoffset equ 42 * first real data starts here


sizeofpointers equ 44
eof equ $1a
endfinish
* this is where the data will be loaded


