; All workspace is now in Z80 RAM AREA (A4+AAAA)
RamArea equ *
startvariablearea EQU *-prg.strt * used to set up A4 RamArea
 even
endmemory equ *-RamArea
 dc.w 0

 even
startfilebuffer equ *-RamArea
 dc.l 0

;;;;;startvariablearea EQU *-prg.strt * used to set up A4 RamArea
;
;'Checksum' reserved as first byte following last byte of code:
CHKSUM 	EQU	*-RamArea 	;CHKSUM
	DS.B 	1 	; DEFS 1
*				;;
squashercomputertype 	EQU	*-RamArea 	;squashercomputertype
	DC.B 	0 	; DEFB 0 ;Default to 'Uknown'
*				;;
	DS.B 	$80 	; DEFS $80
STACK 	EQU	*-RamArea 	;STACK
*				;;
PRTPTR 	EQU	*-RamArea 	;PRTPTR
	DS.B 	2 	; DEFS 2
*				;;
BUFFER 	EQU	*-RamArea 	;BUFFER
	DS.B 	200 ;****** LINELENGTH+1 	; DEFS LINELENGTH+1
BUFFEREND 	EQU	*-RamArea 	;BUFFEREND
	DS.B 	1 	; DEFS 1
*				;;
SYSTEMFCB 	EQU	*-RamArea 	;SYSTEMFCB
SYSTEMFCBDRIVE 	EQU	*-RamArea 	;SYSTEMFCBDRIVE DEFS 1
	DS.B 	1 	;
SYSTEMFCBNAME 	EQU	*-RamArea 	;SYSTEMFCBNAME DEFS 8
	DS.B 	8 	;
SYSTEMFCBTYPE 	EQU	*-RamArea 	;SYSTEMFCBTYPE DEFS 3
	DS.B 	3 	;
SYSTEMFCBEX 	EQU	*-RamArea 	;SYSTEMFCBEX DEFS 1
	DS.B 	1 	;
* ... Altered ...
	DS.B 	19 	; DEFS 19;h1,h2,rc,u0-uF
SYSTEMFCBCR 	EQU	*-RamArea 	;SYSTEMFCBCR DEFS 1
	DS.B 	1
* ... Altered ... 
	DS.B 	3 	; DEFS 3;r0-r2
*				;;
*				;;----------------------------------------
*                       	;0001 ;MESSAGE.TXT to SQUASH.DAT compresser
*				;;
*				;;24/06/86
*				;;
*				;;RAM.Z80
*				;;
*				;;-----
*				;;
*				;;General workspace:
*				;;
*				;;Register save area for debugging:
AFSAVE 	EQU	*-RamArea 	;AFSAVE DEFS 2
	DS.B 	2 	;
HLSAVE 	EQU	*-RamArea 	;HLSAVE DEFS 2
	DS.B 	2 	;
DESAVE 	EQU	*-RamArea 	;DESAVE DEFS 2
	DS.B 	2 	;
BCSAVE 	EQU	*-RamArea 	;BCSAVE DEFS 2
	DS.B 	2 	;
*				;;
*				;;If status messages requested holds 'Y':
NOISY 	EQU	*-RamArea 	;NOISY DEFS 1
	DS.B 	1 	;
*				;;
*				;;If in debug mode holds 'Y'.
DEBUG 	EQU	*-RamArea 	;DEBUG DEFS 1
	DS.B 	1 	;
*				;;
*				;;Maximum number of entries in 'Common Word Dictionary':
COMMONMAXENTRIES 	EQU	*-RamArea 	;COMMONMAXENTRIES DEFS 1
	DS.B 	1 	;
*				;;
*				;;UNSQUASH screen width:
WRAPWIDTH 	EQU	*-RamArea 	;WRAPWIDTH DEFS 1
	DS.B 	1 	;
*				;;
*				;;Length OF B:MESSAGE.TXT input file:
INPUTLENGTH 	EQU	*-RamArea 	;INPUTLENGTH DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of temporary file B:SQUASH.TMP
 even
LENGTHSMT 	EQU	*-RamArea 	;LENGTHSMT DEFS 2
	DS.B 	4 	;68000 format
*				;;
*				;;Input file line number for error reports:
LINENUM 	EQU	*-RamArea 	;LINENUM DEFS 2
	DS.B 	2 	;
*				;;
*				;;Message number:
MSGNUM 	EQU	*-RamArea 	;MSGNUM DEFS 2
	DS.B 	2 	;
*				;;
*				;;Serial input control block:
FCB1 	EQU	*-RamArea 	;FCB1
	DS.B 	SERIALFCBLENGTH 	; DEFS SERIALFCBLENGTH
*				;;
*				;;Serial output control block:
FCB2 	EQU	*-RamArea 	;FCB2
	DS.B 	SERIALFCBLENGTH 	; DEFS SERIALFCBLENGTH
*				;;
*				;;Address of serial SMT buffer:
STARTBUFFER 	EQU	*-RamArea 	;STARTBUFFER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Bytes left in serial buffer:
BUFFERSIZE 	EQU	*-RamArea 	;BUFFERSIZE DEFS 2
	DS.B 	2 	;
*				;;
*				;;Bytes unprocessed in serial buffe:
 even
UNREADSIZE 	EQU	*-RamArea 	;UNREADSIZE DEFS 2
	DS.B 	4 	;>> 68000 format long
*				;;
*				;;-----
*				;;
*				;;Phase 2 (Sort input file) workspace:
*				;;
*				;;Address following '[' or ':' in input buffer
*				;;(Also used by Phase 6 for Address of Message Descriptor Header Byte)
STARTMSG 	EQU	*-RamArea 	;STARTMSG DEFS 2
	DS.B 	2 	;
*				;;
*				;;Address of ']' in input buffer
ENDMSG 	EQU	*-RamArea 	;ENDMSG DEFS 2
	DS.B 	2 	;
*				;;
*				;;Non-zero if serial input EOF stored in buffer:
INPUTEOF 	EQU	*-RamArea 	;INPUTEOF DEFS 1
	DS.B 	1 	;
*				;;
*				;;Number of input characters excluding brackets
NUMCHARACTERS 	EQU	*-RamArea 	;NUMCHARACTERS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of messages:
NUMMESSAGES 	EQU	*-RamArea 	;NUMMESSAGES DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of characters in input file
*				;;entered in inverted case:
MODIFYCOUNT 	EQU	*-RamArea 	;MODIFYCOUNT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Last char/start-of-word input char
LASTSIGCHAR 	EQU	*-RamArea 	;LASTSIGCHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;Non-zero once warned about comments
SEENCOMMENT 	EQU	*-RamArea 	;SEENCOMMENT DEFS 1
	DS.B 	1 	;
*				;;
*				;;-----
*				;;
*				;;Phase 3 (Construct Frequency Table) workspace:
*				;;
 even
STARTFT 	EQU	*-RamArea 	;STARTFT DEFS 2
	DS.B 	2 	;
*				;;
ENDFT 	EQU	*-RamArea 	;ENDFT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Two-byte count for estimated number of occurances of
*				;;each ascii code $00 thru $7F not part of a 'word':
CHARACTERCOUNTS 	EQU	*-RamArea 	;CHARACTERCOUNTS DEFS $100
	DS.B 	$100 	;
*				;;
*				;;Number of 'words' in 'Frequency Table':
NUMWORDS 	EQU	*-RamArea 	;NUMWORDS DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 5 (Find common words) workspace:
*				;;
STARTCWT 	EQU	*-RamArea 	;STARTCWT DEFS 2
	DS.B 	2 	;
*				;;
ENDCWT 	EQU	*-RamArea 	;ENDCWT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Occurrance count for 'current' frequency word:
*				;;(Also used in Phase 7 as a 'length')
FREQUENCYTIMES 	EQU	*-RamArea 	;FREQUENCYTIMES DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 6 (Construct Message Descriptors) workspace:
*				;;
CURRENTMDT 	EQU	*-RamArea 	;CURRENTMDT DEFS 2
	DS.B 	2 	;
*				;;
MAXMDT 	EQU	*-RamArea 	;MAXMDT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Address within SMT entry of a character in a message:
WORDADDRESS 	EQU	*-RamArea 	;WORDADDRESS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Word-type character code for current word
WORDTYPE 	EQU	*-RamArea 	;WORDTYPE DEFS 1
	DS.B 	1 	;
*				;;
*				;;MODE flag for splitting into words/spaces/characters:
P6MODE 	EQU	*-RamArea 	;P6MODE DEFS 1
	DS.B 	1 	;
*				;;
*				;;Stored character for inclusion with leading/trailing spaces:
P6CHAR 	EQU	*-RamArea 	;P6CHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;Number of Message headers:
NUMMSGHEADS 	EQU	*-RamArea 	;NUMMSGHEADS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of message skip bytes:
NUMJUMPHEADS 	EQU	*-RamArea 	;NUMJUMPHEADS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of short references
NUMSHORTREFS 	EQU	*-RamArea 	;NUMSHORTREFS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of long references:
NUMLONGREFS 	EQU	*-RamArea 	;NUMLONGREFS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of current message:
MESSAGELENGTH 	EQU	*-RamArea 	;MESSAGELENGTH DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of keywords defined in current message:
NUMKEYWORDS 	EQU	*-RamArea 	;NUMKEYWORDS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of ICF file (B:SQUASH2.TMP)
LENGTHICF 	EQU	*-RamArea 	;LENGTHICF DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length if Message Descriptors (in ICF)
INDEXMD 	EQU	*-RamArea 	;INDEXMD DEFS 2
	DS.B 	2 	;
*				;;
LENGTHMD 	EQU	*-RamArea 	;LENGTHMD DEFS 2
	DS.B 	2 	;
*				;;
 even
STARTCONVERTEDMSG 	EQU	*-RamArea 	;STARTCONVERTEDMSG DEFW 0 ;Address of last message header
	DC.W 	0 	;
* Warning 1 : the bytes in above word(s) may not be in required order
*				;;
*				;;-----
*				;;
*				;;Phase 7 (Construct Word Dictionary) workspace:
*				;;
UNPACK1 	EQU	BUFFER 	;UNPACK1 EQU BUFFER
UNPACK2 	EQU	BUFFER+1 	;UNPACK2 EQU BUFFER+1
UNPACK3 	EQU	BUFFER+2 	;UNPACK3 EQU BUFFER+2
UNPACK4 	EQU	BUFFER+3 	;UNPACK4 EQU BUFFER+3
UNPACK5 	EQU	BUFFER+4 	;UNPACK5 EQU BUFFER+4
UNPACK6 	EQU	BUFFER+5 	;UNPACK6 EQU BUFFER+5
UNPACK7 	EQU	BUFFER+6 	;UNPACK7 EQU BUFFER+6
UNPACK8 	EQU	BUFFER+7 	;UNPACK8 EQU BUFFER+7
*				;;
PACK1 	EQU	BUFFER+8 	;PACK1 EQU BUFFER+8
PACK2 	EQU	BUFFER+9 	;PACK2 EQU BUFFER+9
PACK3 	EQU	BUFFER+10 	;PACK3 EQU BUFFER+10
PACK4 	EQU	BUFFER+11 	;PACK4 EQU BUFFER+11
PACK5 	EQU	BUFFER+12 	;PACK5 EQU BUFFER+12
*				;;
*				;;Length of MD+WD
INDEXWD 	EQU	*-RamArea 	;INDEXWD DEFS 2
	DS.B 	2 	;
*				;;
LENGTHWD 	EQU	*-RamArea 	;LENGTHWD DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 8 (Construct Index) workspace:
*				;;
*				;;Length of MD+WD+WDI
INDEXWDI 	EQU	*-RamArea 	;INDEXWDI DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of Dictionary segments
NUMSEGS 	EQU	*-RamArea 	;NUMSEGS DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Output file checksum
FINALCHECKSUM 	EQU	*-RamArea 	;FINALCHECKSUM DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointer into BUFFER for packing/unpacking 5-bit codes:
*				;;(Also used by 'Construct Message Descriptors'
READWRITEPOINTER 	EQU	*-RamArea 	;READWRITEPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Pointer to the start of a 5-byte (40 bits) byte-aligned
*				;;in the 'Word Dictionary':
BLOCKPOINTER 	EQU	*-RamArea 	;BLOCKPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Current segment group
SEGNUM 	EQU	*-RamArea 	;SEGNUM DEFS 1
	DS.B 	1 	;
*				;;
*				;;Last byte stored in dictionary
LASTBYTE 	EQU	*-RamArea 	;LASTBYTE DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointers into byte-aligned boundaries of 'Word Dictionary':
SEGMENTADDRESSES 	EQU	*-RamArea 	;SEGMENTADDRESSES
	DS.B 	416 	; DEFS 416 ; 26*4*4
*				;;
*				;;Pointer into next free pointer in SEGMENTADDRESSES:
LASTPOINTER 	EQU	*-RamArea 	;LASTPOINTER
	DS.B 	2 	; DEFS 2
*				;;
*				;;Current word during 'Word Dictionary' construction:
WORDNUMBER 	EQU	*-RamArea 	;WORDNUMBER DEFS 2
	DS.B 	2 	;
*				;;
*				;;First three characters (padded with nulls) of
*				;;word in 'Word Dictionary':
THREECHARACTERS 	EQU	*-RamArea 	;THREECHARACTERS
	DS.B 	4 	; DEFS 4
*				;;
*				;;Non-zero if current dictionary word is all upper-case
WORDCASE 	EQU	*-RamArea 	;WORDCASE
	DS.B 	1 	; DEFS 1
*				;;
*				;;-----
*				;;
*				;;Conversion READ address:
READPOSITION 	EQU	*-RamArea 	;READPOSITION DEFS 2
	DS.B 	2 	;
*				;;
*				;;Conversion WRITE address:
WRITEPOSITION 	EQU	*-RamArea 	;WRITEPOSITION DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of chars output to B:MESSAGE.TXT since
COLUMN 	EQU	*-RamArea 	;COLUMN DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Pointer into THREECHARACTERS for reverse-squash:
HEADERPOINTER 	EQU	*-RamArea 	;HEADERPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Current cursor column:
NCHARS 	EQU	*-RamArea 	;NCHARS DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointer into BUFFER for word-wrap:
CURBUF 	EQU	*-RamArea 	;CURBUF DEFS 2
	DS.B 	2 	;
*				;;
*				;;Last non-space character printed as part of an unsquashed
*				;;message. Used to decide upper/lower case:
LASTCHAR 	EQU	*-RamArea 	;LASTCHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;True if next time BUFFER is printed it should
*				;;preceeded by a space (or newline) character:
PENDSPACE 	EQU	*-RamArea 	;PENDSPACE DEFS 1
	DS.B 	1 	;
*				;;

 even
Phase06ProgressCounter equ *-RamArea
	dc.l 0 ; relies on initial value of 0

 even
Phase03ProgressCounter equ *-RamArea
	dc.l 0 ; relies on initial value of 0
*				;;-----
*				;;
squasherdriverblock
	ds.b 200


*				;;Memory here to just below BIOS allocated dynamically
*				;;at run-time for tables/buffers:
*				;;
STARTTABLEMEMORY 	EQU	*-RamArea ;STARTTABLEMEMORY
*				;;
*				;;-----