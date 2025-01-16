*******************************************************************
*            Z80 TO M68000 TRANSLATION  -  N. BROWN               *
*******************************************************************
*************  Data Areas and Initialisation Code *****************
*
        JMP     PRG.CODE        Jump around data areas
PRG.STRT:
F       EQU     *-PRG.STRT      Flags Register
        DS.W    1
I       EQU     *-PRG.STRT      Interrupt Register (not used)
        DS.W    1
R       EQU     *-PRG.STRT      Refresh Register (not used)
        DS.W    1
ALT.REGS EQU    *-PRG.STRT      Alternative register set
        DS.W    4
STAK.SIZ EQU    400             Default stack size
Z80.STAK DS.B   STAK.SIZ+2      Default Z80 Stack
*
PRG.CODE LEA    PRG.STRT,A5     Set A5 to code base address
        LEA     Z80.STAK+STAK.SIZ,A4  Set up stack pointer ...
        SUBA.L  A5,A4           ... as a relative (word) value ...
        MOVE.W  A4,D6           ... in D6
*
******************* Start Of Translated Code **********************
*
*				;;MESSAGE.TXT to SQUASH.DAT compresser
*				;;
*				;; 24/06/86
*				;;
*				;;CMAIN.Z80
*				;;
*				;;-----
*				;;
*				;;Maximum number of characters allowed in a single 'word':
MAXWORDLEN 	EQU	$20 	;MAXWORDLEN EQU $20
*				;;
*				;;Maximum buffer for serial reading of SMT:
MAXMESSAGELEN 	EQU	$400 	;MAXMESSAGELEN EQU $400
*				;;
ENDMEMORY 	EQU	$6 	;ENDMEMORY EQU $6
*				;;
*				;;-----
*				;;
*				;;Message Descriptor Header:
JUMP 	EQU	7 	;JUMP EQU 7 ;Jump header or Message header.
PARSE 	EQU	6 	;PARSE EQU 6 ;Message contains keywords.
*				;;
*				;;Word reference:
LONG 	EQU	7 	;LONG EQU 7 ;Short or Long-form reference.
*				;;
*				;;Special short-codes:
LONGC 	EQU	$1A 	;LONGC EQU $1A ;Long escape code
HEADER 	EQU	$1C 	;HEADER EQU $1C ;Header short-code
ENDSEG 	EQU	$1B 	;ENDSEG EQU $1B ;Segment end marker
*				;;
*				;;Greater than $07, Less than LONGC:
UPPERCASEMARK 	EQU	$10 	;UPPERCASEMARK EQU $10 ;Operand to LONGC
*				;;
MAXHEADERLENGTH 	EQU	3 	;MAXHEADERLENGTH EQU 3 ;Max similarity count in header
*				;;
*				;;-----
*				;;
ORIGIN 	EQU	*-PRG.STRT	;ORIGIN
	MOVE.W 	#STACK,D6 	; LD SP,STACK
	MOVE.W 	#SETCOMPUTERTYPE,D7 	; CALL SETCOMPUTERTYPE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"COMPACT " 	; DEFM "COMPACT "
	DC.B 	MAJOR,'.',MINOR 	; DEFB MAJOR,'.',MINOR
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"12th August 1986" 	; DEFM "12th August 1986"
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Available memory =" 	; DEFM "Available memory ="
	DC.B 	0 	; DEFB 0
*				;;
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#STARTTABLEMEMORY,D3 	; LD DE,STARTTABLEMEMORY
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#ORIGIN,D1 	; LD HL,ORIGIN
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
AA01 	EQU	*-PRG.STRT	;AA01
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#CHKSUM,D3 	; LD DE,CHKSUM
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,AA02
	BNE.S 	LAB.1 	;
	JMP 	AA02(A5) 	;
LAB.1:
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	ADD.B 	0(A5,D1.W),D0 	; ADD A,(HL)
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	AA01(A5) 	; JR AA01
AA02 	EQU	*-PRG.STRT	;AA02
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
	MOVE 	F(A5),SR 	; JR Z,AA03
	BNE.S 	LAB.2 	;
	JMP 	AA03(A5) 	;
LAB.2:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"***** Corrupted *****" 	; DEFM "***** Corrupted *****"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
AA03 	EQU	*-PRG.STRT	;AA03
*				;;
	MOVE.B 	$82(A5),D0 	; LD A,($82)
	CMP.B 	#'N',D0 	; CP 'N'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,NOISE1
	BNE.S 	LAB.3 	;
	JMP 	NOISE1(A5) 	;
LAB.3:
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,NOISE1
	BNE.S 	LAB.4 	;
	JMP 	NOISE1(A5) 	;
LAB.4:
	MOVE.B 	#'N',D0 	; LD A,'N'
NOISE1 	EQU	*-PRG.STRT	;NOISE1
	MOVE.B 	D0,NOISY(A5) 	; LD (NOISY),A
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,DEBUG1
	BEQ.S 	LAB.5 	;
	JMP 	DEBUG1(A5) 	;
LAB.5:
*				;;
	MOVE.B 	$83(A5),D0 	; LD A,($83)
	CMP.B 	#'N',D0 	; CP 'N'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DEBUG2
	BNE.S 	LAB.6 	;
	JMP 	DEBUG2(A5) 	;
LAB.6:
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DEBUG2
	BNE.S 	LAB.7 	;
	JMP 	DEBUG2(A5) 	;
LAB.7:
DEBUG1 	EQU	*-PRG.STRT	;DEBUG1
	MOVE.B 	#'N',D0 	; LD A,'N'
DEBUG2 	EQU	*-PRG.STRT	;DEBUG2
	MOVE.B 	D0,DEBUG(A5) 	; LD (DEBUG),A
*				;;
	MOVE.W 	#$84,D1 	; LD HL,$84
	MOVE.W 	#HEXCONV,D7 	; CALL HEXCONV
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#$85,D1 	; LD HL,$85
	MOVE.W 	#HEXCONV,D7 	; CALL HEXCONV
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	$84(A5),D0 	; LD A,($84)
	CMP.B 	#'A',D0 	; CP 'A'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,NOCW
	BCC.S 	LAB.8 	;
	JMP 	NOCW(A5) 	;
LAB.8:
	CMP.B 	#'P'+1,D0 	; CP 'P'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,NOCW
	BCS.S 	LAB.9 	;
	JMP 	NOCW(A5) 	;
LAB.9:
	MOVE.B 	$85(A5),D0 	; LD A,($85)
	CMP.B 	#'A',D0 	; CP 'A'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,NOCW
	BCC.S 	LAB.10 	;
	JMP 	NOCW(A5) 	;
LAB.10:
	CMP.B 	#'P'+1,D0 	; CP 'P'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,NOCW
	BCS.S 	LAB.11 	;
	JMP 	NOCW(A5) 	;
LAB.11:
*				;;
	MOVE.B 	$84(A5),D0 	; LD A,($84)
	SUB.B 	#'A',D0 	; SUB 'A'
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A 
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$F0,D0 	; AND $F0
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	$85(A5),D0 	; LD A,($85)
	SUB.B 	#'A',D0 	; SUB 'A'
	MOVE 	SR,F(A5) 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	JMP 	GOTCW(A5) 	; JR GOTCW
*				;;
NOCW 	EQU	*-PRG.STRT	;NOCW
*				;;Up to 128 entries allowed in 'Common Word Dictionary':
	MOVE.B 	#128,D0 	; LD A,128
GOTCW 	EQU	*-PRG.STRT	;GOTCW
	MOVE.B 	D0,COMMONMAXENTRIES(A5) 	; LD (COMMONMAXENTRIES),A
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Options: " 	; DEFM "Options: "
	DC.B 	0 	; DEFB 0
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	COMMONMAXENTRIES(A5),D0 	; LD A,(COMMONMAXENTRIES)
	ROR.W 	#8,D1 	; LD H,0
	MOVE.B 	#0,D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D0,D1 	; LD L,A
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	13,13,0 	; DEFB 13,13,0
*				;;
	MOVE.W 	#PHASE01,D7 	; CALL PHASE01
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE02,D7 	; CALL PHASE02
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE03,D7 	; CALL PHASE03
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE04,D7 	; CALL PHASE04
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE05,D7 	; CALL PHASE05
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE06,D7 	; CALL PHASE06
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE07,D7 	; CALL PHASE07
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE08,D7 	; CALL PHASE08
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PHASE09,D7 	; CALL PHASE09
	JSR 	SYS.JSR(A5) 	;
WARMSTART 	EQU	*-PRG.STRT	;WARMSTART
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
INPUT 	EQU	*-PRG.STRT	;INPUT
	DC.B 	2 	; DEFB 2 ;Drive B:
	DC.B 	"MESSAGE TXT" 	; DEFM "MESSAGE TXT"
*				;;
ARGUMENTS 	EQU	*-PRG.STRT	;ARGUMENTS
	DC.B 	ARGLEN 	; DEFB ARGLEN
	DC.B 	" B:MESSAGE.TXT" 	; DEFM " B:MESSAGE.TXT"
ARGLEN 	EQU	$-ARGUMENTS-1 	;ARGLEN EQU $-ARGUMENTS-1 
	DC.B 	ASCIICR 	; DEFB ASCIICR
ARGSIZE 	EQU	$-ARGUMENTS 	;ARGSIZE EQU $-ARGUMENTS
*				;;
*				;;-----
*				;;
HEXCONV 	EQU	*-PRG.STRT	;HEXCONV
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,HC02
	BCC.S 	LAB.12 	;
	JMP 	HC02(A5) 	;
LAB.12:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,HC01
	BCS.S 	LAB.13 	;
	JMP 	HC01(A5) 	;
LAB.13:
	SUB.B 	#'0'-'A',D0 	; SUB '0'-'A'
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	JMP 	SYS.RET(A5) 	; RET 
HC01 	EQU	*-PRG.STRT	;HC01
	CMP.B 	#'A',D0 	; CP 'A'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,HC02
	BCC.S 	LAB.14 	;
	JMP 	HC02(A5) 	;
LAB.14:
	CMP.B 	#'F'+1,D0 	; CP 'F'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,HC02
	BCS.S 	LAB.15 	;
	JMP 	HC02(A5) 	;
LAB.15:
	SUB.B 	#'A'-'K',D0 	; SUB 'A'-'K'
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	JMP 	SYS.RET(A5) 	; RET 
HC02 	EQU	*-PRG.STRT	;HC02
	MOVE.B 	#$FF,0(A5,D1.W) 	; LD (HL),$FF
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Do a 'PRS' if DEBUG is 'Y'
*				;;Otherwise the message is skipped
*				;;
TRACE 	EQU	*-PRG.STRT	;TRACE
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,PRS
	BNE.S 	LAB.16 	;
	JMP 	PRS(A5) 	;
LAB.16:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
TRACE1 	EQU	*-PRG.STRT	;TRACE1
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,TRACE1
	BEQ.S 	LAB.17 	;
	JMP 	TRACE1(A5) 	;
LAB.17:
	JMP 	0(A5,D1.W) 	; JP (HL)
*				;;
*				;;-----
*				;;
*				;;Do a 'breakpoint' if (DEBUG)='Y'
*				;;
BREAK 	EQU	*-PRG.STRT	;BREAK
	LEA 	HLSAVE(A5),A0 	; LD (HLSAVE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	DESAVE(A5),A0 	; LD (DESAVE),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
	LEA 	BCSAVE(A5),A0 	; LD (BCSAVE),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	LEA 	AFSAVE(A5),A0 	; LD (AFSAVE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,BR01
	BEQ.S 	LAB.18 	;
	JMP 	BR01(A5) 	;
LAB.18:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL ;Address after CALL BREAK instruction
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"PC=" 	; DEFM "PC="
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DISPLAYSAVES,D7 	; CALL DISPLAYSAVES
	JSR 	SYS.JSR(A5) 	;
BR01 	EQU	*-PRG.STRT	;BR01
	LEA 	AFSAVE(A5),A0 	; LD HL,(AFSAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	LEA 	BCSAVE(A5),A0 	; LD BC,(BCSAVE)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	LEA 	DESAVE(A5),A0 	; LD DE,(DESAVE)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	LEA 	HLSAVE(A5),A0 	; LD HL,(HLSAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display AFSAVE, HLSAVE, DESAVE and BCSAVE
*				;;
DISPLAYSAVES 	EQU	*-PRG.STRT	;DISPLAYSAVES
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"AF=" 	; DEFM "AF="
	DC.B 	0 	; DEFB 0
	LEA 	AFSAVE(A5),A0 	; LD HL,(AFSAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" HL=" 	; DEFM " HL="
	DC.B 	0 	; DEFB 0
	LEA 	HLSAVE(A5),A0 	; LD HL,(HLSAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" DE=" 	; DEFM " DE="
	DC.B 	0 	; DEFB 0
	LEA 	DESAVE(A5),A0 	; LD HL,(DESAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" BC=" 	; DEFM " BC="
	DC.B 	0 	; DEFB 0
	LEA 	BCSAVE(A5),A0 	; LD HL,(BCSAVE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
*				;;-----
*				;;
*				;;Display HL as both a 16-bit hex number
*				;;and as a positive decimal number.
*				;;
DISPLAYHLBOTH 	EQU	*-PRG.STRT	;DISPLAYHLBOTH
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" &" 	; DEFM " &"
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#DISPLAYHLHEX,D7 	; CALL DISPLAYHLHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" = " 	; DEFM " = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	DISPLAYDECIMAL(A5) 	; JP DISPLAYDECIMAL
*				;;
*				;;----
*				;;
*				;;Display a newline sequence
*				;;
NEWLINE 	EQU	*-PRG.STRT	;NEWLINE
	MOVE.B 	#ASCIICR,D0 	; LD A,ASCIICR
	JMP 	OSWRCH(A5) 	; JP OSWRCH
*				;;
*				;;-----
*				;;
*				;;Calculate HL-DE and display in the form:
*				;;   &hhhh = ddd bytes.
*				;;
DISPLAYBYTESFREE 	EQU	*-PRG.STRT	;DISPLAYBYTESFREE
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#DISPLAYHLBOTH,D7 	; CALL DISPLAYHLBOTH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" bytes." 	; DEFM " bytes."
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Copy block length BC start HL to DE
ICOPY 	EQU	*-PRG.STRT	;ICOPY
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.19 	;
	JMP 	SYS.RET(A5) 	;
LAB.19:
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,IC01
	BCS.S 	LAB.20 	;
	JMP 	IC01(A5) 	;
LAB.20:
	SUBQ.W 	#1,D2 	; DEC BC
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ADDQ.W 	#1,D2 	; INC BC
	JSR 	SYS.LDDR(A5) 	; LDDR 
	JMP 	SYS.RET(A5) 	; RET 
IC01 	EQU	*-PRG.STRT	;IC01
	JSR 	SYS.LDIR(A5) 	; LDIR 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
INPUTTERMINATE 	EQU	*-PRG.STRT	;INPUTTERMINATE
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display a character
DISPLAYCODE 	EQU	*-PRG.STRT	;DISPLAYCODE
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,OW01
	BEQ.S 	LAB.21 	;
	JMP 	OW01(A5) 	;
LAB.21:
	MOVE.W 	#DISPLAYCONTROL,D7 	; CALL DISPLAYCONTROL
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#ASCIILF,D0 	; LD A,ASCIILF
	JMP 	OW03(A5) 	; JR OW03
OW01 	EQU	*-PRG.STRT	;OW01
	CMP.B 	#$80,D0 	; CP $80
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,OW02
	BCC.S 	LAB.22 	;
	JMP 	OW02(A5) 	;
LAB.22:
	SUB.B 	#$80,D0 	; SUB $80
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	#"*",D0 	; LD A,"*"
	MOVE.W 	#DISPLAYCONTROL,D7 	; CALL DISPLAYCONTROL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
OW02 	EQU	*-PRG.STRT	;OW02
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,OW03
	BCS.S 	LAB.23 	;
	JMP 	OW03(A5) 	;
LAB.23:
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	#'^',D0 	; LD A,'^'
	MOVE.W 	#DISPLAYCONTROL,D7 	; CALL DISPLAYCONTROL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	ADD.B 	#'A'-1,D0 	; ADD A,'A'-1
	MOVE 	SR,F(A5) 	;
OW03 	EQU	*-PRG.STRT	;OW03
	MOVE.W 	#DISPLAYCONTROL,D7 	; CALL DISPLAYCONTROL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
S 	EQU	*-PRG.STRT	;S*				;;MESSAGE.TXT to SQUASH.DAT compresser
*				;;
*				;; 12/08/86
*				;;
*				;;STAGE1.Z80
*				;;
*				;;-----
*				;;
*				;;Phase 1 - Load B:MESSAGE.TXT
*				;;
*				;;Load B:MESSAGE.TXT at address STARTTABLEMEMORY ($3000)
*				;;Copy the file up to the top of memory.
*				;;(STARTINPUTFILE) is the address of the start of this
*				;;
*				;;-----
*				;;
PHASE01 	EQU	*-PRG.STRT	;PHASE01
	 	 	;
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 1 - Clear memory" 	; DEFM "Phase 1 - Clear memory"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;Clear entire table area
*				;;
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#STARTTABLEMEMORY,D3 	; LD DE,STARTTABLEMEMORY
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#1,D1 	; DEC HL
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D1,D2 	; LD C,L
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STARTTABLEMEMORY,D1 	; LD HL,STARTTABLEMEMORY
	MOVE.W 	#STARTTABLEMEMORY+1,D3 	; LD DE,STARTTABLEMEMORY+1
	MOVE.B 	#ASCIIEOF,0(A5,D1.W) 	; LD (HL),ASCIIEOF
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
	JMP 	RESET(A5) 	; JP RESET ;Clear RAM directory
*				;;
*				;;-----
*				;;
*				;;Phase 2 - Sort messages
*				;;
*				;;Phase 2 read the file B:MESSAGE.TXT serially and creates
*				;;the 'Sorted Message Table' - A list of all messages in
*				;;numeric order.
*				;;
*				;;B:MESSAGE.TXT is read serially by SERIALREADBYTE
*				;;and written to B:SQUASH.TMP by SERIALWRITEBYTE
*				;;
*				;;Each 'Sorted Message' entry starts with a six-byte
*				;;header giving the length of the header (2 bytes), the
*				;;message number (2 bytes) and the B:MESSAGE.TXT line
*				;;number (2 bytes) for error messages.
*				;;
*				;;Comments, '[' and ']' are discarded.
*				;;
*				;;-----
*				;;
PHASE02 	EQU	*-PRG.STRT	;PHASE02
	 	 	;
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 2 - Sort into message number order" 	; DEFM "Phase 2 - Sort into message number order"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Squashing. Please wait." 	; DEFM "Squashing. Please wait."
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;Initialise 'Sorted Message Table'
*				;;
	MOVE.W 	#1,D1 	; LD HL,1 ;Line in source file
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#$0,D1 	; LD HL,$0 ;After auto-increment first message is number 1
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMCHARACTERS(A5),A0 	; LD (NUMCHARACTERS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	LENGTHSMT(A5),A0 	; LD (LENGTHSMT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	INPUTLENGTH(A5),A0 	; LD (INPUTLENGTH),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	MODIFYCOUNT(A5),A0 	; LD (MODIFYCOUNT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	#0,D0 	; LD A,0
	MOVE.B 	D0,SEENCOMMENT(A5) 	; LD (SEENCOMMENT),A
*				;;
*				;;Open B:MESSAGE.TXT for reading
*				;;
	MOVE.W 	#INITSERIALINPUT,D7 	; CALL INITSERIALINPUT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PB01 ;Opened OK
	BCS.S 	LAB.101 	;
	JMP 	PB01(A5) 	;
LAB.101:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Can't read" 	; DEFM "Can't read"
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYINPUTNAME,D7 	; CALL DISPLAYINPUTNAME
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;Open B:SQUASH.TMP for writing
*				;;
PB01 	EQU	*-PRG.STRT	;PB01
	 	 	;
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#TEMPFILE,D1 	; LD HL,TEMPFILE
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Writing " 	; DEFM "Writing "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"..." 	; DEFM "..."
	DC.B 	$D,0 	; DEFB $D,0
*				;;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output control block
	MOVE.W 	#OPENSERIALWRITE,D7 	; CALL OPENSERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PB02 ;Created OK
	BCS.S 	LAB.102 	;
	JMP 	PB02(A5) 	;
LAB.102:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Can't create " 	; DEFM "Can't create "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#ABORTSERIALINPUT,D7 	; CALL ABORTSERIALINPUT
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
PB02 	EQU	*-PRG.STRT	;PB02
	 	 	;
	MOVE.W 	#SORTFILE,D7 	; CALL SORTFILE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#ENDSERIALINPUT,D7 	; CALL ENDSERIALINPUT
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... close" 	; DEFM "... close"
	DC.B 	$D,$D,0 	; DEFB $D,$D,0
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output control block
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP C,WRITEERROR
	BCC.S 	LAB.103 	;
	JMP 	WRITEERROR(A5) 	;
LAB.103:
*				;;
*				;;(Optional) Display length of SMT (B:SQUASH1.TMP)
*				;;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.104 	;
	JMP 	SYS.RET(A5) 	;
LAB.104:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Length of SMT (B:SQUASH1.TMP) =" 	; DEFM "Length of SMT (B:SQUASH1.TMP) ="
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHSMT(A5),A0 	; LD HL,(LENGTHSMT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;(Optional) Display sorted messages
*				;;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,PB05
	BEQ.S 	LAB.105 	;
	JMP 	PB05(A5) 	;
LAB.105:
*				;;
	MOVE.W 	#$0,D1 	; LD HL,$0
	LEA 	NUMMESSAGES(A5),A0 	; LD (NUMMESSAGES),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	MOVE.W 	#INITSERIALSMT,D7 	; CALL INITSERIALSMT
	JSR 	SYS.JSR(A5) 	;
PB03 	EQU	*-PRG.STRT	;PB03
	 	 	;
	MOVE.W 	#ENDSERIALSMT,D7 	; CALL ENDSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PB04 ;End of file
	BNE.S 	LAB.106 	;
	JMP 	PB04(A5) 	;
LAB.106:
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYSORTEDMESSAGE,D7 	; CALL DISPLAYSORTEDMESSAGE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEXTSERIALSMT,D7 	; CALL NEXTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	LEA 	NUMMESSAGES(A5),A0 	; LD BC,(NUMMESSAGES)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ADDQ.W 	#1,D2 	; INC BC
	LEA 	NUMMESSAGES(A5),A0 	; LD (NUMMESSAGES),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	JMP 	PB03(A5) 	; JR PB03
PB04 	EQU	*-PRG.STRT	;PB04
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of messages = " 	; DEFM "Number of messages = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMMESSAGES(A5),A0 	; LD HL,(NUMMESSAGES)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
PB05 	EQU	*-PRG.STRT	;PB05
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Number of modifications =" 	; DEFM "Number of modifications ="
	DC.B 	0 	; DEFB 0
	LEA 	MODIFYCOUNT(A5),A0 	; LD HL,(MODIFYCOUNT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLBOTH,D7 	; CALL DISPLAYHLBOTH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of text characters =" 	; DEFM "Number of text characters ="
	DC.B 	0 	; DEFB 0
	LEA 	NUMCHARACTERS(A5),A0 	; LD HL,(NUMCHARACTERS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLBOTH,D7 	; CALL DISPLAYHLBOTH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
*				;;-----
*				;;
WRITEERROR 	EQU	*-PRG.STRT	;WRITEERROR
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Error writing " 	; DEFM "Error writing "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input control block
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output control block
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
HITEOF 	EQU	*-PRG.STRT	;HITEOF
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Unexpected EOF" 	; DEFM "Unexpected EOF"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
INVALIDNUMBER 	EQU	*-PRG.STRT	;INVALIDNUMBER
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal message number" 	; DEFM "Illegal message number"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
P2BADWORDTYPE 	EQU	*-PRG.STRT	;P2BADWORDTYPE
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Mis-use of special character '^'" 	; DEFM "Mis-use of special character '^'"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
P2BADSLASH 	EQU	*-PRG.STRT	;P2BADSLASH
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Mis-use of special character '/'" 	; DEFM "Mis-use of special character '/'"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART 
*				;;
P2BADOPEN 	EQU	*-PRG.STRT	;P2BADOPEN ;> 12/08/86
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS ;> 12/08/86
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Mis-use of special character '['" 	; DEFM "Mis-use of special character '['"
	DC.B 	0 	; DEFB 0 ;> 12/08/86
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WAMRSTART
*				;;
P2BADCLOSE 	EQU	*-PRG.STRT	;P2BADCLOSE ;> 12/08/86
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS ;> 12/08/86
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Mis-use of special character ']'" 	; DEFM "Mis-use of special character ']'"
	DC.B 	0 	; DEFB 0 ;> 12/08/86
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
ILLEGALCHAR 	EQU	*-PRG.STRT	;ILLEGALCHAR
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF ;Character code
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal character &" 	; DEFM "Illegal character &"
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#DISPLAYAHEX,D7 	; CALL DISPLAYAHEX
	JSR 	SYS.JSR(A5) 	;
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
BADNEWLINE 	EQU	*-PRG.STRT	;BADNEWLINE
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal newline" 	; DEFM "Illegal newline"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE2ERROR(A5) 	; JP PHASE2ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
*				;;Sorted Message Table:
TEMPFILE 	EQU	*-PRG.STRT	;TEMPFILE
	 	 	;
	DC.B 	2 	; DEFB 2 ;Drive B:
	DC.B 	"SQUASH1 " 	; DEFM "SQUASH1 "
	DC.B 	"TMP" 	; DEFM "TMP"
*				;;
*				;;-----
*				;;
SORTFILE 	EQU	*-PRG.STRT	;SORTFILE
	 	 	;
*				;;
*				;;Read characters until found start of message '['
*				;;
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#ASCIIEOF,D0 	; CP ASCIIEOF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z ;Normal end-of-file exit
	BNE.S 	LAB.107 	;
	JMP 	SYS.RET(A5) 	;
LAB.107:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SORTFILE
	BNE.S 	LAB.108 	;
	JMP 	SORTFILE(A5) 	;
LAB.108:
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SF01
	BNE.S 	LAB.109 	;
	JMP 	SF01(A5) 	;
LAB.109:
	CMP.B 	#ASCIILF,D0 	; CP ASCIILF ;Line Feed 
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SORTFILE
	BNE.S 	LAB.110 	;
	JMP 	SORTFILE(A5) 	;
LAB.110:
	CMP.B 	#';',D0 	; CP ';'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SF02
	BNE.S 	LAB.111 	;
	JMP 	SF02(A5) 	;
LAB.111:
	CMP.B 	#'[',D0 	; CP '['
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SF03
	BNE.S 	LAB.112 	;
	JMP 	SF03(A5) 	;
LAB.112:
*				;;
*				;;Character not part of official comment or message
*				;;
	CMP.B 	#']',D0 	; CP ']' ;> 12/08/86
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P2BADCLOSE ;> 12/08/86
	BNE.S 	LAB.113 	;
	JMP 	P2BADCLOSE(A5) 	;
LAB.113:
*				;;
	MOVE.B 	SEENCOMMENT(A5),D0 	; LD A,(SEENCOMMENT) ;> 04/08/86
	OR.B 	D0,D0 	; OR A               ;> 04/08/86
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SORTFILE     ;> 12/08/86 Comment character
	BEQ.S 	LAB.114 	;
	JMP 	SORTFILE(A5) 	;
LAB.114:
	MOVE.B 	#1,D0 	; LD A,1             ;> 04/08/86
	MOVE.B 	D0,SEENCOMMENT(A5) 	; LD (SEENCOMMENT),A ;> 04/08/86
	MOVE.W 	#PRS,D7 	; CALL PRS           ;> 04/08/86
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR       ;> 04/08/86
	DC.B 	"Warning: Characters not within message are comment" 	; DEFM "Warning: Characters not within message are comment"
	DC.B 	0 	; DEFB 0             ;> 04/08/86
	MOVE.W 	#DISPLAYWHERE,D7 	; CALL DISPLAYWHERE  ;> 04/08/86
	JSR 	SYS.JSR(A5) 	;
	JMP 	SORTFILE(A5) 	; JR SORTFILE        ;> 12/08/86 Comment character
*				;;
*				;;> 04/08/86 ;Illegal character
*				;;
*				;;> 04/08/86 JP ILLEGALCHAR
*				;;
*				;;Comment. Ignore characters up to next CR.
*				;;
SF02 	EQU	*-PRG.STRT	;SF02
	 	 	;
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#ASCIIEOF,D0 	; CP ASCIIEOF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z ;End of file
	BNE.S 	LAB.115 	;
	JMP 	SYS.RET(A5) 	;
LAB.115:
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SF02
	BEQ.S 	LAB.116 	;
	JMP 	SF02(A5) 	;
LAB.116:
*				;;
*				;;Carriage Return. Increments current line
*				;;number but has no other effect.
*				;;
SF01 	EQU	*-PRG.STRT	;SF01
	 	 	;
	LEA 	LINENUM(A5),A0 	; LD BC,(LINENUM)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ADDQ.W 	#1,D2 	; INC BC
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	JMP 	SORTFILE(A5) 	; JP SORTFILE
*				;;
*				;;'[' Start of message
*				;;
SF03 	EQU	*-PRG.STRT	;SF03
	 	 	;
	MOVE.W 	#SORTMESSAGE,D7 	; CALL SORTMESSAGE
	JSR 	SYS.JSR(A5) 	;
	JMP 	SORTFILE(A5) 	; JP SORTFILE
*				;;
*				;;-----
*				;;
SORTMESSAGE 	EQU	*-PRG.STRT	;SORTMESSAGE
	 	 	;
	MOVE.W 	#STARTTABLEMEMORY,D1 	; LD HL,STARTTABLEMEMORY
	LEA 	STARTMSG(A5),A0 	; LD (STARTMSG),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A ;'WRAPRESET' in AINT
*				;;
*				;;Read remainder of message
*				;;
SM01 	EQU	*-PRG.STRT	;SM01
	 	 	;
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
SM01A 	EQU	*-PRG.STRT	;SM01A
	 	 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
	CMP.B 	#']',D0 	; CP ']' ;End of message
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,SM14
	BNE.S 	LAB.117 	;
	JMP 	SM14(A5) 	;
LAB.117:
	CMP.B 	#ASCIILF,D0 	; CP ASCIILF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM01
	BNE.S 	LAB.118 	;
	JMP 	SM01(A5) 	;
LAB.118:
*				;;
	MOVE.B 	D0,LASTSIGCHAR(A5) 	; LD (LASTSIGCHAR),A
*				;;
	CMP.B 	#'/',D0 	; CP '/' ;Disables effect of special characters ']' '%' etc.
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM02
	BNE.S 	LAB.119 	;
	JMP 	SM02(A5) 	;
LAB.119:
	CMP.B 	#'[',D0 	; CP '[' ;> 04/08/86
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P2BADOPEN ;> 12/08/86
	BNE.S 	LAB.120 	;
	JMP 	P2BADOPEN(A5) 	;
LAB.120:
	CMP.B 	#'^',D0 	; CP '^' ;Start of keyword
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM04
	BNE.S 	LAB.121 	;
	JMP 	SM04(A5) 	;
LAB.121:
	CMP.B 	#'|',D0 	; CP '|' ;Keyword separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM06
	BNE.S 	LAB.122 	;
	JMP 	SM06(A5) 	;
LAB.122:
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,SM09 ;Increments LINENUM then as SPACE
	BNE.S 	LAB.123 	;
	JMP 	SM09(A5) 	;
LAB.123:
	CMP.B 	#'%',D0 	; CP '%'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,SM13
	BNE.S 	LAB.124 	;
	JMP 	SM13(A5) 	;
LAB.124:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP C,ILLEGALCHAR
	BCC.S 	LAB.125 	;
	JMP 	ILLEGALCHAR(A5) 	;
LAB.125:
	JMP 	SM10(A5) 	; JP SM10
*				;;
*				;;Escape disables effect of ']' and disables conversion.
*				;;Store 'escaped' characters with top bit set
*				;;
SM02 	EQU	*-PRG.STRT	;SM02
	 	 	;
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P2BADSLASH
	BNE.S 	LAB.126 	;
	JMP 	P2BADSLASH(A5) 	;
LAB.126:
	CMP.B 	#ASCIILF,D0 	; CP ASCIILF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P2BADSLASH
	BNE.S 	LAB.127 	;
	JMP 	P2BADSLASH(A5) 	;
LAB.127:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM03
	BNE.S 	LAB.128 	;
	JMP 	SM03(A5) 	;
LAB.128:
	BSET 	D0,#7 	; SET 7,A
SM03 	EQU	*-PRG.STRT	;SM03
	 	 	;
	MOVE.W 	#INCNUMCHARS,D7 	; CALL INCNUMCHARS
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	SM01(A5) 	; JR SM01
*				;;
*				;;'^' must be followed by word-type: a non-space character
*				;;from TYPETABLE.
*				;;
SM04 	EQU	*-PRG.STRT	;SM04
	 	 	;
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	ADDQ.W 	#1,D1 	; INC HL
*				;;
	MOVE.W 	#TYPETABLE+1,D3 	; LD DE,TYPETABLE+1
	ROR.W 	#8,D2 	; LD B,8-1
	MOVE.B 	#8-1,D2 	;
	ROR.W 	#8,D2 	;
SM05 	EQU	*-PRG.STRT	;SM05
	 	 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL ;CP (DE)
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)  ;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL ;
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE 	F(A5),SR 	; JR Z,SM05A
	BNE.S 	LAB.129 	;
	JMP 	SM05A(A5) 	;
LAB.129:
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.W 	#SM05,D7 	; DJNZ SM05
	JSR 	SYS.DJNZ(A5) 	;
	JMP 	P2BADWORDTYPE(A5) 	; JP P2BADWORDTYPE
SM05A 	EQU	*-PRG.STRT	;SM05A
	 	 	;
	MOVE.W 	#INPUTREADBYTE,D7 	; CALL INPUTREADBYTE
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM05A
	BNE.S 	LAB.130 	;
	JMP 	SM05A(A5) 	;
LAB.130:
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM05B
	BNE.S 	LAB.131 	;
	JMP 	SM05B(A5) 	;
LAB.131:
	CMP.B 	#ASCIILF,D0 	; CP ASCIILF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM05A
	BNE.S 	LAB.132 	;
	JMP 	SM05A(A5) 	;
LAB.132:
	JMP 	SM01A(A5) 	; JR SM01A
SM05B 	EQU	*-PRG.STRT	;SM05B
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	LINENUM(A5),A0 	; LD HL,(LINENUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SM05A(A5) 	; JR SM05A
*				;;
*				;;"|" marks end of message, start of keywords
*				;;Remove any spaces stored before '|'
*				;;
SM06 	EQU	*-PRG.STRT	;SM06
	 	 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A
SM07 	EQU	*-PRG.STRT	;SM07
	 	 	;
	MOVE.W 	#P1GETLASTCHAR,D7 	; CALL P1GETLASTCHAR
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SM08
	BEQ.S 	LAB.133 	;
	JMP 	SM08(A5) 	;
LAB.133:
	SUBQ.W 	#1,D1 	; DEC HL
	JMP 	SM07(A5) 	; JR SM07
SM08 	EQU	*-PRG.STRT	;SM08
	 	 	;
	MOVE.B 	#'|',D0 	; LD A,'|'
	JMP 	SM10(A5) 	; JR SM10
*				;;
*				;;CR. Incremente line number then as SPACE
*				;;
SM09 	EQU	*-PRG.STRT	;SM09
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	LINENUM(A5),A0 	; LD HL,(LINENUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#P1GETLASTCHAR,D7 	; CALL P1GETLASTCHAR
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'%',D0 	; CP '%'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,SM01 ;Don't store CR.
	BNE.S 	LAB.134 	;
	JMP 	SM01(A5) 	;
LAB.134:
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
*				;;Remove upper case chars if follow '.' '?' or '!'
*				;;
SM10 	EQU	*-PRG.STRT	;SM10
	 	 	;
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SM11
	BEQ.S 	LAB.135 	;
	JMP 	SM11(A5) 	;
LAB.135:
	MOVE.B 	#',D0 	; LD A,' '
*				;;
SM11 	EQU	*-PRG.STRT	;SM11
	 	 	;
	MOVE.W 	#CASEMODIFY,D7 	; CALL CASEMODIFY
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,SM12
	BCC.S 	LAB.136 	;
	JMP 	SM12(A5) 	;
LAB.136:
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM13
	BNE.S 	LAB.137 	;
	JMP 	SM13(A5) 	;
LAB.137:
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	MODIFYCOUNT(A5),A0 	; LD HL,(MODIFYCOUNT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	MODIFYCOUNT(A5),A0 	; LD (MODIFYCOUNT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SM13(A5) 	; JR SM13
*				;;
*				;;Needs lower-case force
*				;;So set top bit
*				;;
SM12 	EQU	*-PRG.STRT	;SM12
	 	 	;
	BSET 	D0,#7 	; SET 7,A
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
*				;;Next byte of input
*				;;
SM13 	EQU	*-PRG.STRT	;SM13
	 	 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#INCNUMCHARS,D7 	; CALL INCNUMCHARS
	JSR 	SYS.JSR(A5) 	;
	JMP 	SM01(A5) 	; JP SM01 
*				;;
*				;;']' for end of message
*				;;
SM14 	EQU	*-PRG.STRT	;SM14
	 	 	;
	LEA 	ENDMSG(A5),A0 	; LD (ENDMSG),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	LASTSIGCHAR(A5),D0 	; LD A,(LASTSIGCHAR)
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,BADNEWLINE
	BNE.S 	LAB.138 	;
	JMP 	BADNEWLINE(A5) 	;
LAB.138:
*				;;
*				;;Check if starts with number
*				;;
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
SM15 	EQU	*-PRG.STRT	;SM15
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDMSG(A5),A0 	; LD DE,(ENDMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,SM18 ;No number
	BNE.S 	LAB.139 	;
	JMP 	SM18(A5) 	;
LAB.139:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SM16
	BEQ.S 	LAB.140 	;
	JMP 	SM16(A5) 	;
LAB.140:
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	SM15(A5) 	; JR SM15
SM16 	EQU	*-PRG.STRT	;SM16
	 	 	;
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,SM18 ;No number
	BCC.S 	LAB.141 	;
	JMP 	SM18(A5) 	;
LAB.141:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,SM18 ;No number
	BCS.S 	LAB.142 	;
	JMP 	SM18(A5) 	;
LAB.142:
	MOVE.W 	#EVALNUMBER,D7 	; CALL EVALNUMBER
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP C,INVALIDNUMBER
	BCC.S 	LAB.143 	;
	JMP 	INVALIDNUMBER(A5) 	;
LAB.143:
SM17 	EQU	*-PRG.STRT	;SM17
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	ENDMSG(A5),A0 	; LD DE,(ENDMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,SM18 ;No number
	BNE.S 	LAB.144 	;
	JMP 	SM18(A5) 	;
LAB.144:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL) ;Check if number followed by ":"
	ADDQ.W 	#1,D1 	; INC HL
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM17
	BNE.S 	LAB.145 	;
	JMP 	SM17(A5) 	;
LAB.145:
	CMP.B 	#':',D0 	; CP ':'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM19
	BNE.S 	LAB.146 	;
	JMP 	SM19(A5) 	;
LAB.146:
*				;;
*				;;No message number
*				;;
SM18 	EQU	*-PRG.STRT	;SM18
	 	 	;
	LEA 	MSGNUM(A5),A0 	; LD HL,(MSGNUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,INVALIDNUMBER
	BNE.S 	LAB.147 	;
	JMP 	INVALIDNUMBER(A5) 	;
LAB.147:
	JMP 	SM21(A5) 	; JR SM21
*				;;
*				;;Message number valid
*				;;
SM19 	EQU	*-PRG.STRT	;SM19
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL ;New message start address
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE ;Message number
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	STARTMSG(A5),A0 	; LD DE,(STARTMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
*				;;HL=Length of number
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	LEA 	NUMCHARACTERS(A5),A0 	; LD HL,(NUMCHARACTERS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	NUMCHARACTERS(A5),A0 	; LD (NUMCHARACTERS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	LEA 	STARTMSG(A5),A0 	; LD (STARTMSG),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	MSGNUM(A5),A0 	; LD HL,(MSGNUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D3 	; OR D
	OR.B 	D3,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D3 	;
	OR.B 	D3,D0 	; OR E
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SM20
	BNE.S 	LAB.148 	;
	JMP 	SM20(A5) 	;
LAB.148:
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,INVALIDNUMBER
	BCS.S 	LAB.149 	;
	JMP 	INVALIDNUMBER(A5) 	;
LAB.149:
SM20 	EQU	*-PRG.STRT	;SM20
	 	 	;
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
*				;;
SM21 	EQU	*-PRG.STRT	;SM21
	 	 	;
*				;;
*				;;Calculate length of header required
*				;;
	LEA 	ENDMSG(A5),A0 	; LD HL,(ENDMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTMSG(A5),A0 	; LD DE,(STARTMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z ;Blank message not stored
	BNE.S 	LAB.150 	;
	JMP 	SYS.RET(A5) 	;
LAB.150:
	MOVE.W 	#6,D2 	; LD BC,6 ;Sorted message header length
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
*				;;
*				;;Write header. Two bytes are length of entry
*				;;
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Two bytes are message number
*				;;
	LEA 	MSGNUM(A5),A0 	; LD HL,(MSGNUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	LEA 	MSGNUM(A5),A0 	; LD HL,(MSGNUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Two bytes are source line number
*				;;
	LEA 	LINENUM(A5),A0 	; LD HL,(LINENUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	LEA 	LINENUM(A5),A0 	; LD HL,(LINENUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
SM22 	EQU	*-PRG.STRT	;SM22
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDMSG(A5),A0 	; LD DE,(ENDMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET Z ;All message stored
	BNE.S 	LAB.151 	;
	JMP 	SYS.RET(A5) 	;
LAB.151:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#OUTPUTWRITEBYTE,D7 	; CALL OUTPUTWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	SM22(A5) 	; JR SM22
*				;;-----
*				;;
INCNUMCHARS 	EQU	*-PRG.STRT	;INCNUMCHARS
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	NUMCHARACTERS(A5),A0 	; LD HL,(NUMCHARACTERS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMCHARACTERS(A5),A0 	; LD (NUMCHARACTERS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
P1GETLASTCHAR 	EQU	*-PRG.STRT	;P1GETLASTCHAR
	 	 	;
	LEA 	STARTMSG(A5),A0 	; LD DE,(STARTMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.B 	#0,D2 	; LD C,0 ;Returned char if end-of-message
GL01 	EQU	*-PRG.STRT	;GL01
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,GL02 ;Reached end
	BNE.S 	LAB.152 	;
	JMP 	GL02(A5) 	;
LAB.152:
	MOVE 	F(A5),SR 	; JR C,GL02
	BCC.S 	LAB.153 	;
	JMP 	GL02(A5) 	;
LAB.153:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	MOVE.B 	D0,D2 	; LD C,A ;Save last char
	ADDQ.W 	#1,D3 	; INC DE
	JMP 	GL01(A5) 	; JR GL01
*				;;Last char of message is register C
GL02 	EQU	*-PRG.STRT	;GL02
	 	 	;
	MOVE.B 	D2,D0 	; LD A,C
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
INPUTREADBYTE 	EQU	*-PRG.STRT	;INPUTREADBYTE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#NEXTSERIALINPUT,D7 	; CALL NEXTSERIALINPUT
	JSR 	SYS.JSR(A5) 	;
	LEA 	INPUTLENGTH(A5),A0 	; LD HL,(INPUTLENGTH)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	INPUTLENGTH(A5),A0 	; LD (INPUTLENGTH),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
OUTPUTWRITEBYTE 	EQU	*-PRG.STRT	;OUTPUTWRITEBYTE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output control block
	MOVE.W 	#SERIALWRITEBYTE,D7 	; CALL SERIALWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP C,HITEOF
	BCC.S 	LAB.154 	;
	JMP 	HITEOF(A5) 	;
LAB.154:
	LEA 	LENGTHSMT(A5),A0 	; LD HL,(LENGTHSMT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LENGTHSMT(A5),A0 	; LD (LENGTHSMT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
INITSERIALINPUT 	EQU	*-PRG.STRT	;INITSERIALINPUT
	 	 	;
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#&6000,D3 	; LD DE,&6000 ;Must be small enough to use TBUG
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	STARTBUFFER(A5),A0 	; LD (STARTBUFFER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	BUFFERSIZE(A5),A0 	; LD (BUFFERSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	UNREADSIZE(A5),A0 	; LD (UNREADSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,INPUTEOF(A5) 	; LD (INPUTEOF),A
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Reading " 	; DEFM "Reading "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYINPUTNAME,D7 	; CALL DISPLAYINPUTNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"..." 	; DEFM "..."
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#INPUT,D1 	; LD HL,INPUT
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input control block
	MOVE.W 	#OPENSERIALREAD,D7 	; CALL OPENSERIALREAD
	JSR 	SYS.JSR(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
NEXTSERIALINPUT 	EQU	*-PRG.STRT	;NEXTSERIALINPUT
	 	 	;
	LEA 	UNREADSIZE(A5),A0 	; LD HL,(UNREADSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SI04 ;Buffer contains enough chars
	BEQ.S 	LAB.155 	;
	JMP 	SI04(A5) 	;
LAB.155:
*				;;
	MOVE.B 	INPUTEOF(A5),D0 	; LD A,(INPUTEOF)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SI05 ;Return EOF
	BEQ.S 	LAB.156 	;
	JMP 	SI05(A5) 	;
LAB.156:
*				;;
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
SI01 	EQU	*-PRG.STRT	;SI01
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDMEMORY(A5),A0 	; LD DE,(ENDMEMORY)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR NC,SI03 ;Buffer full
	BCS.S 	LAB.157 	;
	JMP 	SI03(A5) 	;
LAB.157:
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input control block
	MOVE.W 	#SERIALREADBYTE,D7 	; CALL SERIALREADBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,SI02
	BCC.S 	LAB.158 	;
	JMP 	SI02(A5) 	;
LAB.158:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	SI01(A5) 	; JR SI01
SI02 	EQU	*-PRG.STRT	;SI02
	 	 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	#1,D0 	; LD A,1
	MOVE.B 	D0,INPUTEOF(A5) 	; LD (INPUTEOF),A
SI03 	EQU	*-PRG.STRT	;SI03
	 	 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD (BUFFERSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	UNREADSIZE(A5),A0 	; LD (UNREADSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
SI04 	EQU	*-PRG.STRT	;SI04
	 	 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD HL,(BUFFERSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	LEA 	UNREADSIZE(A5),A0 	; LD DE,(UNREADSIZE)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	LEA 	UNREADSIZE(A5),A0 	; LD HL,(UNREADSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#1,D1 	; DEC HL
	LEA 	UNREADSIZE(A5),A0 	; LD (UNREADSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
SI05 	EQU	*-PRG.STRT	;SI05
	 	 	;
	MOVE.B 	#ASCIIEOF,D0 	; LD A,ASCIIEOF
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
ENDSERIALINPUT 	EQU	*-PRG.STRT	;ENDSERIALINPUT
	 	 	;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; CALL Z,NEWLINE
	BNE.S 	LAB.159 	;
	MOVE.W 	#NEWLINE,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.159:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... eof" 	; DEFM "... eof"
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input control block
	JMP 	CLOSESERIALREAD(A5) 	; JP CLOSESERIALREAD
*				;;
*				;;-----
*				;;
ABORTSERIALINPUT 	EQU	*-PRG.STRT	;ABORTSERIALINPUT
	 	 	;
	JMP 	CLOSESERIALREAD(A5) 	; JP CLOSESERIALREAD
*				;;
*				;;-----
*				;;
CASEMODIFY 	EQU	*-PRG.STRT	;CASEMODIFY
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
*				;;Transparent characters:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC04
	BNE.S 	LAB.160 	;
	JMP 	PC04(A5) 	;
LAB.160:
	CMP.B 	#'_',D0 	; CP '_'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC04
	BNE.S 	LAB.161 	;
	JMP 	PC04(A5) 	;
LAB.161:
	CMP.B 	#'%',D0 	; CP '%'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC04
	BNE.S 	LAB.162 	;
	JMP 	PC04(A5) 	;
LAB.162:
	CMP.B 	#'!'+1,D0 	; CP '!'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,PC00B
	BCC.S 	LAB.163 	;
	JMP 	PC00B(A5) 	;
LAB.163:
	CMP.B 	#')'+1,D0 	; CP ')'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,PC04
	BCC.S 	LAB.164 	;
	JMP 	PC04(A5) 	;
LAB.164:
*				;;End of sentance characters:
PC00B 	EQU	*-PRG.STRT	;PC00B
	 	 	;
	MOVE.B 	LASTCHAR(A5),D0 	; LD A,(LASTCHAR)
	CMP.B 	#'!',D0 	; CP '!'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC01
	BNE.S 	LAB.165 	;
	JMP 	PC01(A5) 	;
LAB.165:
	CMP.B 	#'?',D0 	; CP '?'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC01
	BNE.S 	LAB.166 	;
	JMP 	PC01(A5) 	;
LAB.166:
	CMP.B 	#'.',D0 	; CP '.'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,PC03
	BEQ.S 	LAB.167 	;
	JMP 	PC03(A5) 	;
LAB.167:
PC01 	EQU	*-PRG.STRT	;PC01
	 	 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A
	CMP.B 	#"a",D0 	; CP "a"
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,PC02
	BCC.S 	LAB.168 	;
	JMP 	PC02(A5) 	;
LAB.168:
	CMP.B 	#"z"+1,D0 	; CP "z"+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C ;Already lower case
	BCC.S 	LAB.169 	;
	JMP 	SYS.RET(A5) 	;
LAB.169:
PC02 	EQU	*-PRG.STRT	;PC02
	 	 	;
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
PC03 	EQU	*-PRG.STRT	;PC03
	 	 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,LASTCHAR(A5) 	; LD (LASTCHAR),A
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
PC04 	EQU	*-PRG.STRT	;PC04
	 	 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	OR.B 	D0,D0 	; OR A ;Reset carry
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DISPLAYSORTEDMESSAGE 	EQU	*-PRG.STRT	;DISPLAYSORTEDMESSAGE
	 	 	;
	MOVE.W 	#DISPLAYHEADER,D7 	; CALL DISPLAYHEADER
	JSR 	SYS.JSR(A5) 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" Text " 	; DEFM " Text "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Length of entry
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL ;Adjust for start of text
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
DS01 	EQU	*-PRG.STRT	;DS01
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DS02
	BNE.S 	LAB.170 	;
	JMP 	DS02(A5) 	;
LAB.170:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DISPLAYCODE,D7 	; CALL DISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	DS01(A5) 	; JR DS01
DS02 	EQU	*-PRG.STRT	;DS02 JP NEWLINE
	JMP 	NEWLINE(A5) 	;
*				;;
*				;;-----
*				;;
*				;;Display line and message number of a Sorted Message Header.
DISPLAYHEADER 	EQU	*-PRG.STRT	;DISPLAYHEADER
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Line " 	; DEFM "Line "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Line number
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D7 	; LD H,(HL)
	ROR.W 	#8,D1 	;
	MOVE.B 	D7,D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" Number " 	; DEFM " Number "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Message number
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D7 	; LD H,(HL)
	ROR.W 	#8,D1 	;
	MOVE.B 	D7,D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;> 04/08/86 DISPLAYLINENUM
DISPLAYWHERE 	EQU	*-PRG.STRT	;DISPLAYWHERE ;> 04/08/86
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" in line " 	; DEFM " in line "
	DC.B 	0 	; DEFB 0
	LEA 	LINENUM(A5),A0 	; LD HL,(LINENUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" (message " 	; DEFM " (message "
	DC.B 	0 	; DEFB 0
	LEA 	MSGNUM(A5),A0 	; LD HL,(MSGNUM)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	')',ASCIICR,ASCIICR,0 	; DEFB ')',ASCIICR,ASCIICR,0
	JMP 	SYS.RET(A5) 	; RET ;> 04/08/86
*				;;
DISPLAYLINENUM 	EQU	*-PRG.STRT	;DISPLAYLINENUM ;> 04/08/86
	 	 	;
	MOVE.W 	#DISPLAYWHERE,D7 	; CALL DISPLAYWHERE ;> 04/08/86
	JSR 	SYS.JSR(A5) 	;
	JMP 	WARMSTART(A5) 	; JP WARMSTART
*				;;
*				;;-----
*				;;
*				;;Try to read character at address HL as a decimal number.
*				;;Returns DE as address of the character following the end
*				;;of the number and HL as the numbers binary value.
*				;;
EVALNUMBER 	EQU	*-PRG.STRT	;EVALNUMBER LD A,(HL)
	MOVE.B 	0(A5,D1.W),D0 	;
	MOVE.W 	#$0,D3 	; LD DE,$0
RN01 	EQU	*-PRG.STRT	;RN01 EX DE,HL
	MOVE.W 	D3,-(SP) 	;
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#6554,D2 	; LD BC,6554
	EOR.B 	D0,D0 	; XOR A;Reset carry
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	MOVE 	F(A5),SR 	; RET C ;Number too big ( greater than 65539 )
	BCC.S 	LAB.171 	;
	JMP 	SYS.RET(A5) 	;
LAB.171:
	ADD.W 	D1,D1 	; ADD HL,HL
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D1,D2 	; LD C,L
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	ADD.W 	D1,D1 	; ADD HL,HL
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL
	MOVE 	SR,F(A5) 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	SUB.B 	#'0',D0 	; SUB '0'
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,D2 	; LD C,A
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C ;Number too big ( 65536 thru 65539 )
	BCC.S 	LAB.172 	;
	JMP 	SYS.RET(A5) 	;
LAB.172:
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	ADDQ.W 	#1,D1 	; INC HL;Next char
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	MOVE 	F(A5),SR 	; RET NC ;Number OK
	BCS.S 	LAB.173 	;
	JMP 	SYS.RET(A5) 	;
LAB.173:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC ;Number OK
	BCS.S 	LAB.174 	;
	JMP 	SYS.RET(A5) 	;
LAB.174:
	JMP 	RN01(A5) 	; JR RN01
*				;;
*				;;-----
*				;;
*				;;Compare HL with (ENDMEMORY).
*				;;Returns NC if HL >= (ENDMEMORY)
*				;;
CHECKENDMEMORY 	EQU	*-PRG.STRT	;CHECKENDMEMORY
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	ENDMEMORY(A5),A0 	; LD DE,(ENDMEMORY)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
PHASE2ERROR 	EQU	*-PRG.STRT	;PHASE2ERROR
	 	 	;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input control block
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output file
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM
	JSR 	SYS.JSR(A5) 	;
	JMP 	DISPLAYLINENUM(A5) 	; JP DISPLAYLINENUM ;Ends in WARMSTART
*				;;
*				;;-----
*				;;
*				;;Phase 3 - Construct 'Frequency Table'
*				;;
*				;;Phase 3 scans the 'Sorted Message Table' and builds the
*				;;Frequency Table' - A list of all 'words' in
*				;;alphabetical order stored with the number of times they
*				;;are used.
*				;;
*				;;The 'Frequency Table' occupies addresses (STARTFT)
*				;;thru (ENDFT)-1.
*				;;
*				;;Each Frequency entry starts with
*				;;the entries length (one byte) and the number of
*				;;occurrances (two bytes.)
*				;;
*				;;-----
*				;;
PHASE03 	EQU	*-PRG.STRT	;PHASE03
	 	 	;
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 3 - Construct 'Frequency Table'" 	; DEFM "Phase 3 - Construct 'Frequency Table'"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;Clear Frequency Table'
*				;;
	MOVE.W 	#STARTTABLEMEMORY,D1 	; LD HL,STARTTABLEMEMORY
	LEA 	STARTFT(A5),A0 	; LD (STARTFT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	ENDFT(A5),A0 	; LD (ENDFT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTFT(A5),A0 	; LD DE,(STARTFT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#1,D1 	; DEC HL
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D1,D2 	; LD C,L
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D3 	; LD D,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D3 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D1,D3 	; LD E,L
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.B 	#$0,0(A5,D1.W) 	; LD (HL),$0
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
*				;;Clear estimated-character-count table:
*				;;
	MOVE.W 	#CHARACTERCOUNTS,D1 	; LD HL,CHARACTERCOUNTS
	MOVE.W 	#CHARACTERCOUNTS+1,D3 	; LD DE,CHARACTERCOUNTS+1
	MOVE.W 	#$100-1,D2 	; LD BC,$100-1
	MOVE.B 	#$0,0(A5,D1.W) 	; LD (HL),$0
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
	MOVE.W 	#INITSERIALSMT,D7 	; CALL INITSERIALSMT
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Search each sentance picking out 'words'
*				;;
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	NUMWORDS(A5),A0 	; LD (NUMWORDS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
PC11 	EQU	*-PRG.STRT	;PC11
	 	 	;
	MOVE.W 	#ENDSERIALSMT,D7 	; CALL ENDSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PC13 ;End of file
	BNE.S 	LAB.175 	;
	JMP 	PC13(A5) 	;
LAB.175:
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Length of Sorted Message Table entry
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
*				;;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,PC12
	BEQ.S 	LAB.176 	;
	JMP 	PC12(A5) 	;
LAB.176:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Message number = " 	; DEFM "Message number = "
	DC.B 	0 	; DEFB 0
	ROR.W 	#8,D1 	; LD H,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
PC12 	EQU	*-PRG.STRT	;PC12
	 	 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH BC ;Store line number for error messages
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	MOVE.W 	#COUNTSENTANCE,D7 	; CALL COUNTSENTANCE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.W 	#NEXTSERIALSMT,D7 	; CALL NEXTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#1,D1 	; DEC HL
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	JMP 	PC11(A5) 	; JR PC11
*				;;
*				;;Check frequency table not too big (2^12-128)
*				;;And note word number of first 'typed' word.
*				;;
PC13 	EQU	*-PRG.STRT	;PC13
	 	 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	LEA 	NUMWORDS(A5),A0 	; LD BC,(NUMWORDS)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP C,TOOMANY
	BCC.S 	LAB.177 	;
	JMP 	TOOMANY(A5) 	;
LAB.177:
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.178 	;
	JMP 	SYS.RET(A5) 	;
LAB.178:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Number of 'words' =" 	; DEFM "Number of 'words' ="
	DC.B 	0 	; DEFB 0
	LEA 	NUMWORDS(A5),A0 	; LD HL,(NUMWORDS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYHLBOTH,D7 	; CALL DISPLAYHLBOTH
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR 	; DEFB ASCIICR,ASCIICR
	DC.B 	"Length of 'Frequency Table' =" 	; DEFM "Length of 'Frequency Table' ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDFT(A5),A0 	; LD HL,(ENDFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTFT(A5),A0 	; LD DE,(STARTFT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR 	; DEFB ASCIICR,ASCIICR
	DC.B 	"Low memory used =" 	; DEFM "Low memory used ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDFT(A5),A0 	; LD HL,(ENDFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#STARTTABLEMEMORY,D3 	; LD DE,STARTTABLEMEMORY
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"High memory used =" 	; DEFM "High memory used ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" Free =" 	; DEFM " Free ="
	DC.B 	0 	; DEFB 0
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	ENDFT(A5),A0 	; LD DE,(ENDFT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
*				;;-----
*				;;
*				;;Search each sentance skiping punctuation, picking out
*				;;words. HL is address of start of text of sentance. BC
*				;;is its length.
*				;;
COUNTSENTANCE 	EQU	*-PRG.STRT	;COUNTSENTANCE
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.179 	;
	JMP 	SYS.RET(A5) 	;
LAB.179:
*				;;
*				;;If a non-simple word it will be preceeded by '^'
*				;;and a word-type.
*				;;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#'^',D0 	; CP '^'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,CS05
	BEQ.S 	LAB.180 	;
	JMP 	CS05(A5) 	;
LAB.180:
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P3BADWORDTYPE ;'^' and end of sentance
	BNE.S 	LAB.181 	;
	JMP 	P3BADWORDTYPE(A5) 	;
LAB.181:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#TYPETABLE+1,D3 	; LD DE,TYPETABLE+1
	ROR.W 	#8,D2 	; LD B,1
	MOVE.B 	#1,D2 	;
	ROR.W 	#8,D2 	;
CS01 	EQU	*-PRG.STRT	;CS01
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#8,D0 	; CP 8
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P3BADWORDTYPE ;Unknown word-type
	BNE.S 	LAB.182 	;
	JMP 	P3BADWORDTYPE(A5) 	;
LAB.182:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CS02
	BNE.S 	LAB.183 	;
	JMP 	CS02(A5) 	;
LAB.183:
	ADDQ.W 	#1,D3 	; INC DE
	ADD.W 	#$100,D2 	; INC B
	JMP 	CS01(A5) 	; JR CS01
CS02 	EQU	*-PRG.STRT	;CS02
	 	 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Word-type declaration must be followed by a word
*				;;
CS03 	EQU	*-PRG.STRT	;CS03
	 	 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P3BADWORDTYPE ;Missing word
	BNE.S 	LAB.184 	;
	JMP 	P3BADWORDTYPE(A5) 	;
LAB.184:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CS03
	BNE.S 	LAB.185 	;
	JMP 	CS03(A5) 	;
LAB.185:
	MOVE.W 	#VALIDWORDSTART,D7 	; CALL VALIDWORDSTART
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,P3BADWORDTYPE ;Not followed by word
	BCS.S 	LAB.186 	;
	JMP 	P3BADWORDTYPE(A5) 	;
LAB.186:
	JMP 	CS06(A5) 	; JR CS06
*				;;
*				;;Check for a simple word
*				;;
CS05 	EQU	*-PRG.STRT	;CS05
	 	 	;
	MOVE.W 	#VALIDWORDSTART,D7 	; CALL VALIDWORDSTART
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,CS07 ;Invalid start of word
	BCS.S 	LAB.187 	;
	JMP 	CS07(A5) 	;
LAB.187:
*				;;
CS06 	EQU	*-PRG.STRT	;CS06
	 	 	;
	MOVE.W 	#LOADBUFFER,D7 	; CALL LOADBUFFER
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#ADDFREQUENCY,D7 	; CALL ADDFREQUENCY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	COUNTSENTANCE(A5) 	; JR COUNTSENTANCE
*				;;
*				;;Not part of a word so count as puctuation:
*				;;
CS07 	EQU	*-PRG.STRT	;CS07
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	ROR.W 	#8,D3 	; LD D,$0
	MOVE.B 	#$0,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D0,D3 	; LD E,A
	MOVE.W 	#CHARACTERCOUNTS,D1 	; LD HL,CHARACTERCOUNTS
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D3 	; INC DE
	ROR.W 	#8,D3 	; LD (HL),D
	MOVE.B 	D3,0(A5,D1.W) 	;
	ROR.W 	#8,D3 	;
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.B 	D3,0(A5,D1.W) 	; LD (HL),E
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	COUNTSENTANCE(A5) 	; JR COUNTSENTANCE
*				;;
P3BADSLASH 	EQU	*-PRG.STRT	;P3BADSLASH
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Bad use of special character '/'" 	; DEFM "Bad use of special character '/'"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE3ERROR(A5) 	; JP PHASE3ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
*				;;-----
*				;;
*				;;Phase 3 only:
*				;;Returns 'C' if a valid start-of-word sequence.
*				;;HL is address of char in Frequency Table. BC is number
*				;;or chars remaining in message.
*				;;
VALIDWORDSTART 	EQU	*-PRG.STRT	;VALIDWORDSTART
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,VS03
	BCC.S 	LAB.188 	;
	JMP 	VS03(A5) 	;
LAB.188:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C ;Valid
	BCC.S 	LAB.189 	;
	JMP 	SYS.RET(A5) 	;
LAB.189:
VS03 	EQU	*-PRG.STRT	;VS03
	 	 	;
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	MOVE 	F(A5),SR 	; RET NC ;Invalid
	BCS.S 	LAB.190 	;
	JMP 	SYS.RET(A5) 	;
LAB.190:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET ;'C' if valid
*				;;
P3BADWORDTYPE 	EQU	*-PRG.STRT	;P3BADWORDTYPE
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Bad of special character '^'" 	; DEFM "Bad of special character '^'"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE3ERROR(A5) 	; JP PHASE3ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
*				;;-----
*				;;
*				;;Copy word from Sorted Message Table into BUFFER.
*				;;HL is address in S.M.T. BC is length of sentance
*				;;remaining.
*				;;
LOADBUFFER 	EQU	*-PRG.STRT	;LOADBUFFER
	 	 	;
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
LB02 	EQU	*-PRG.STRT	;LB02
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,LB10
	BNE.S 	LAB.191 	;
	JMP 	LB10(A5) 	;
LAB.191:
*				;;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BTST 	D0,#7 	; BIT 7,A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,LB02A
	BEQ.S 	LAB.192 	;
	JMP 	LB02A(A5) 	;
LAB.192:
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LB02A
	BNE.S 	LAB.193 	;
	JMP 	LB02A(A5) 	;
LAB.193:
	BSET 	0(A5,D1.W),#7 	; SET 7,(HL)
LB02A 	EQU	*-PRG.STRT	;LB02A
	 	 	;
*				;;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	CMP.B 	#"'",D0 	; CP "'"
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LB08
	BNE.S 	LAB.194 	;
	JMP 	LB08(A5) 	;
LAB.194:
	CMP.B 	#'-',D0 	; CP '-'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LB08
	BNE.S 	LAB.195 	;
	JMP 	LB08(A5) 	;
LAB.195:
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB03
	BCC.S 	LAB.196 	;
	JMP 	LB03(A5) 	;
LAB.196:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE 	F(A5),SR 	; JR C,LB07
	BCC.S 	LAB.197 	;
	JMP 	LB07(A5) 	;
LAB.197:
LB03 	EQU	*-PRG.STRT	;LB03
	 	 	;
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB04
	BCC.S 	LAB.198 	;
	JMP 	LB04(A5) 	;
LAB.198:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE 	F(A5),SR 	; JR C,LB07
	BCC.S 	LAB.199 	;
	JMP 	LB07(A5) 	;
LAB.199:
LB04 	EQU	*-PRG.STRT	;LB04
	 	 	;
	JMP 	LB10(A5) 	; JR LB10
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB05
	BCC.S 	LAB.200 	;
	JMP 	LB05(A5) 	;
LAB.200:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB06
	BCC.S 	LAB.201 	;
	JMP 	LB06(A5) 	;
LAB.201:
LB05 	EQU	*-PRG.STRT	;LB05
	 	 	;
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB06
	BCC.S 	LAB.202 	;
	JMP 	LB06(A5) 	;
LAB.202:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,LB10
	BCS.S 	LAB.203 	;
	JMP 	LB10(A5) 	;
LAB.203:
*				;;
*				;;Escaped character
*				;;
LB06 	EQU	*-PRG.STRT	;LB06
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	MOVE.W 	#UPPOINTER,D7 	; CALL UPPOINTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	LB02(A5) 	; JR LB02
*				;;
*				;;Single alphabetic character
*				;;
LB07 	EQU	*-PRG.STRT	;LB07
	 	 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	MOVE.W 	#UPPOINTER,D7 	; CALL UPPOINTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	LB02(A5) 	; JR LB02
*				;;
*				;;Single quote, will be an apostrophe if followed by an
*				;;alpha. It's already preceeded by an alpha otherwise
*				;;can't be a word.
*				;;
LB08 	EQU	*-PRG.STRT	;LB08
	 	 	;
	MOVE.W 	#UPPOINTER,D7 	; CALL UPPOINTER
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LB09
	BNE.S 	LAB.204 	;
	JMP 	LB09(A5) 	;
LAB.204:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LB09
	BCC.S 	LAB.205 	;
	JMP 	LB09(A5) 	;
LAB.205:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,LB09
	BCS.S 	LAB.206 	;
	JMP 	LB09(A5) 	;
LAB.206:
	MOVE.W 	#DOWNPOINTER,D7 	; CALL DOWNPOINTER
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	MOVE.W 	#UPPOINTER,D7 	; CALL UPPOINTER
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	MOVE.W 	#UPPOINTER,D7 	; CALL UPPOINTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	LB02(A5) 	; JR LB02
LB09 	EQU	*-PRG.STRT	;LB09
	 	 	;
	MOVE.W 	#DOWNPOINTER,D7 	; CALL DOWNPOINTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	LB10(A5) 	; JR LB10
*				;;
*				;;End of word
*				;;
LB10 	EQU	*-PRG.STRT	;LB10
	 	 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Advance read and write pointers, decrement count (to
*				;;end of sentance.) Check that write pointer does not
*				;;escape buffer. 
*				;;
UPPOINTER 	EQU	*-PRG.STRT	;UPPOINTER
	 	 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#BUFFER+MAXWORDLEN,D1 	; LD HL,BUFFER+MAXWORDLEN
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JP C,TOOLONG
	BCC.S 	LAB.207 	;
	JMP 	TOOLONG(A5) 	;
LAB.207:
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Retreate read and write pointers.
*				;;
DOWNPOINTER 	EQU	*-PRG.STRT	;DOWNPOINTER
	 	 	;
	SUBQ.W 	#1,D1 	; DEC HL
	SUBQ.W 	#1,D3 	; DEC DE
	ADDQ.W 	#1,D2 	; INC BC
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;If word in buffer is already in dictionary its frequency 
*				;;count is incremented. Otherwise the word is inserted in
*				;;alphabetical order.
*				;;
ADDFREQUENCY 	EQU	*-PRG.STRT	;ADDFREQUENCY
	 	 	;
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
AF01 	EQU	*-PRG.STRT	;AF01
	 	 	;
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,AF06 ;Add word to end
	BCS.S 	LAB.208 	;
	JMP 	AF06(A5) 	;
LAB.208:
	MOVE.W 	#COMPARE,D7 	; CALL COMPARE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,AF02 ;Word exists
	BNE.S 	LAB.209 	;
	JMP 	AF02(A5) 	;
LAB.209:
*				;;
	MOVE 	F(A5),SR 	; JR C,AF03 ;Insert word here.
	BCC.S 	LAB.210 	;
	JMP 	AF03(A5) 	;
LAB.210:
	ROR.W 	#8,D2 	; LD B,$0 ;Move on one entry.
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	JMP 	AF01(A5) 	; JR AF01
*				;;
*				;;Word already exists
*				;;
AF02 	EQU	*-PRG.STRT	;AF02
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D2 	; INC BC
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.211 	;
	JMP 	SYS.RET(A5) 	;
LAB.211:
	JMP 	DISPLAYFREQUENCY(A5) 	; JP DISPLAYFREQUENCY
*				;;
*				;;Move up dictionary
*				;;
AF03 	EQU	*-PRG.STRT	;AF03
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL;Insert point
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	D1,D2 	; LD C,L
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	LEA 	ENDFT(A5),A0 	; LD HL,(ENDFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D1,D2 	; LD C,L
	ROR.W 	#8,D2 	; LD B,H;BC=Copy length
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
AF04 	EQU	*-PRG.STRT	;AF04
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,AF05
	BNE.S 	LAB.212 	;
	JMP 	AF05(A5) 	;
LAB.212:
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	JMP 	AF04(A5) 	; JR AF04
AF05 	EQU	*-PRG.STRT	;AF05
	 	 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL 
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#ICOPY,D7 	; CALL ICOPY
	JSR 	SYS.JSR(A5) 	;
	LEA 	NUMWORDS(A5),A0 	; LD HL,(NUMWORDS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMWORDS(A5),A0 	; LD (NUMWORDS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Put word in dictionary
*				;;
AF06 	EQU	*-PRG.STRT	;AF06
	 	 	;
	MOVE.W 	#$0,D2 	; LD BC,$0
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
AF07 	EQU	*-PRG.STRT	;AF07
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,AF08
	BNE.S 	LAB.213 	;
	JMP 	AF08(A5) 	;
LAB.213:
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D2 	; INC BC
	JMP 	AF07(A5) 	; JR AF07
AF08 	EQU	*-PRG.STRT	;AF08
	 	 	;
	ADDQ.W 	#1,D2 	; INC BC
	ADDQ.W 	#1,D2 	; INC BC
	ADDQ.W 	#1,D2 	; INC BC
*				;;
*				;;Do not let 'Frequency Table' (built at bottom
*				;;overwrite unprocessed section of 'Sorted Message Table'
*				;;(at top of memory)
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	LEA 	ENDFT(A5),A0 	; LD HL,(ENDFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	ENDFT(A5),A0 	; LD (ENDFT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD BC,(STARTBUFFER)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,FTFULL
	BCS.S 	LAB.214 	;
	JMP 	FTFULL(A5) 	;
LAB.214:
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#1,0(A5,D1.W) 	; LD (HL),1 ;Initially occurances=1
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#$0,0(A5,D1.W) 	; LD (HL),$0
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#BUFFER,D1 	; LD HL,BUFFER
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	MOVE.W 	#ICOPY,D7 	; CALL ICOPY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.215 	;
	JMP 	SYS.RET(A5) 	;
LAB.215:
	JMP 	DISPLAYFREQUENCY(A5) 	; JP DISPLAYFREQUENCY
*				;;
*				;;-----
*				;;
COMPARE 	EQU	*-PRG.STRT	;COMPARE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#INSENSITIVECOMPARE,D7 	; CALL INSENSITIVECOMPARE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET NZ ;Not case-insensitive the same
	BEQ.S 	LAB.216 	;
	JMP 	SYS.RET(A5) 	;
LAB.216:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#SENSITIVECOMPARE,D7 	; CALL SENSITIVECOMPARE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Compare word in buffer with dictionary entry at HL
*				;;Returns 'Z' if identical
*				;;'NZ' and 'C' if buffer alphabetically before dictionary
*				;;
INSENSITIVECOMPARE 	EQU	*-PRG.STRT	;INSENSITIVECOMPARE
	 	 	;
	ROR.W 	#8,D2 	; LD B,(HL) ;B=Length dictionary entry
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B 
	SUB.W 	#$100,D2 	; DEC B
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
ICOMP1 	EQU	*-PRG.STRT	;ICOMP1
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,ICOMP2
	BNE.S 	LAB.217 	;
	JMP 	ICOMP2(A5) 	;
LAB.217:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,ICOMP3
	BNE.S 	LAB.218 	;
	JMP 	ICOMP3(A5) 	;
LAB.218:
*				;;
*				;;Do comparison on case-insensitivity first
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	MOVE.W 	#UPPER,D7 	; CALL UPPER
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	BCLR 	D0,#7 	; RES 7,A
	MOVE.W 	#UPPER,D7 	; CALL UPPER
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.219 	;
	JMP 	SYS.RET(A5) 	;
LAB.219:
*				;;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	SUB.W 	#$100,D2 	; DEC B
	JMP 	ICOMP1(A5) 	; JR ICOMP1
*				;;
*				;;End of dictionary entry. Check if also end of
*				;;buffer.
*				;;
ICOMP2 	EQU	*-PRG.STRT	;ICOMP2
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z;Both end together
	BNE.S 	LAB.220 	;
	JMP 	SYS.RET(A5) 	;
LAB.220:
	MOVE.B 	#1;Return,D0 	; LD A,1;Return 'NZ' and 'NC'
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Buffer ends but dictionary entry does not
*				;;
ICOMP3 	EQU	*-PRG.STRT	;ICOMP3
	 	 	;
	MOVE.B 	#1;Return,D0 	; LD A,1;Return 'NZ' and 'C'
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Compare word in buffer with dictionary entry at HL
*				;;Returns 'Z' if identical,
*				;;'NZ' and 'C' if buffer alphabetically before dictionary.
*				;;
SENSITIVECOMPARE 	EQU	*-PRG.STRT	;SENSITIVECOMPARE
	 	 	;
	ROR.W 	#8,D2 	; LD B,(HL) ;Length of dictionary entry
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
SCOMP1 	EQU	*-PRG.STRT	;SCOMP1
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SCOMP2
	BNE.S 	LAB.221 	;
	JMP 	SCOMP2(A5) 	;
LAB.221:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SCOMP3
	BNE.S 	LAB.222 	;
	JMP 	SCOMP3(A5) 	;
LAB.222:
*				;;
	SUBQ.W 	#2,D6 	; PUSH BC ;LD A,(HL):CP (DE)
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	BCLR 	D0,#7 	; RES 7,A
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#UPPER,D7 	; CALL UPPER
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE 	F(A5),SR 	; JR NZ,SCOMP1D
	BEQ.S 	LAB.223 	;
	JMP 	SCOMP1D(A5) 	;
LAB.223:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#UPPER,D7 	; CALL UPPER
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE 	F(A5),SR 	; JR Z,SCOMP1A
	BNE.S 	LAB.224 	;
	JMP 	SCOMP1A(A5) 	;
LAB.224:
SCOMP1D 	EQU	*-PRG.STRT	;SCOMP1D
	 	 	;
*				;;One char is lower case
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	JMP 	SCOMP1B(A5) 	; JR SCOMP1B
*				;;Not lower case so escape flag does not matter
SCOMP1A 	EQU	*-PRG.STRT	;SCOMP1A
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	BCLR 	D0,#7 	; RES 7,A
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
SCOMP1B 	EQU	*-PRG.STRT	;SCOMP1B
	 	 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.225 	;
	JMP 	SYS.RET(A5) 	;
LAB.225:
*				;;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	SUB.W 	#$100,D2 	; DEC B
	JMP 	SCOMP1(A5) 	; JR SCOMP1
*				;;
*				;;End of entry. Check if also end of buffer.
SCOMP2 	EQU	*-PRG.STRT	;SCOMP2
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z;Both end together
	BNE.S 	LAB.226 	;
	JMP 	SYS.RET(A5) 	;
LAB.226:
	MOVE.B 	#1,D0 	; LD A,1 ;Return 'NZ' and 'NC'
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Buffer ends but dictionary entry does not
*				;;
SCOMP3 	EQU	*-PRG.STRT	;SCOMP3
	 	 	;
	MOVE.B 	#1,D0 	; LD A,1 ;Return 'NZ' and 'C'
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Compare HL with (ENDFT). Returns 'NC' if HL >= (ENDFT)
*				;;
CHECKENDFT 	EQU	*-PRG.STRT	;CHECKENDFT
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	ENDFT(A5),A0 	; LD DE,(ENDFT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Word longer that buffer
*				;;
TOOLONG 	EQU	*-PRG.STRT	;TOOLONG
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Word too long" 	; DEFM "Word too long"
	DC.B 	0 	; DEFB 0
	JMP 	DISPLAYLINENUM(A5) 	; JP DISPLAYLINENUM ;Ends in WARMSTART
*				;;
*				;;-----
*				;;
*				;;Frequency Table full.
*				;;
FTFULL 	EQU	*-PRG.STRT	;FTFULL
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"'Frequency Table' full" 	; DEFM "'Frequency Table' full"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE3ERROR(A5) 	; JP PHASE3ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
*				;;-----
*				;;
*				;;Too many words
*				;;
TOOMANY 	EQU	*-PRG.STRT	;TOOMANY
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"More than &0F80 words" 	; DEFM "More than &0F80 words"
	DC.B 	0 	; DEFB 0
	JMP 	PHASE3ERROR(A5) 	; JP PHASE3ERROR ;Calls DISPLAYLINENUM then WARMSTART
*				;;
*				;;-----
*				;;
PHASE3ERROR 	EQU	*-PRG.STRT	;PHASE3ERROR
	 	 	;
	JMP 	DISPLAYLINENUM(A5) 	; JP DISPLAYLINENUM ;Ends in WARMSTART
*				;;
*				;;-----
*				;;
*				;;Phase 4 - (Optional) Display 'Frequency Table'
*				;;
*				;;Phase 4 Displays the Sorted 'Frequency Table'
*				;;list of all 'words'.
*				;;
*				;;-----
*				;;
PHASE04 	EQU	*-PRG.STRT	;PHASE04
	 	 	;
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 4 - (Optional) Display 'Frequency Table'" 	; DEFM "Phase 4 - (Optional) Display 'Frequency Table'" 
	DC.B 	ASCIICR,0 	; DEFB ASCIICR,0
*				;;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.227 	;
	JMP 	SYS.RET(A5) 	;
LAB.227:
*				;;
*				;;Display 'Frequency Table'
*				;;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
PD01 	EQU	*-PRG.STRT	;PD01
	 	 	;
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PD02
	BCS.S 	LAB.228 	;
	JMP 	PD02(A5) 	;
LAB.228:
	MOVE.W 	#DISPLAYFREQUENCY,D7 	; CALL DISPLAYFREQUENCY
	JSR 	SYS.JSR(A5) 	;
	JMP 	PD01(A5) 	; JR PD01
PD02 	EQU	*-PRG.STRT	;PD02
	 	 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#CHARACTERCOUNTS,D1 	; LD HL,CHARACTERCOUNTS
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
PD03 	EQU	*-PRG.STRT	;PD03
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#128,D0 	; CP 128
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.229 	;
	JMP 	SYS.RET(A5) 	;
LAB.229:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	OR.B 	D3,D0 	; OR E
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PD04
	BNE.S 	LAB.230 	;
	JMP 	PD04(A5) 	;
LAB.230:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Character &" 	; DEFM "Character &"
	DC.B 	0 	; DEFB 0
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#DISPLAYAHEX,D7 	; CALL DISPLAYAHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" occurances = " 	; DEFM " occurances = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
PD04 	EQU	*-PRG.STRT	;PD04
	 	 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADD.W 	#$100,D2 	; INC B
	JMP 	PD03(A5) 	; JR PD03
*				;;
*				;;-----
*				;;
*				;;Display a single entry from the 'Frequency Table'.
*				;;HL is the address of the entry.
*				;;
DISPLAYFREQUENCY 	EQU	*-PRG.STRT	;DISPLAYFREQUENCY
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Occurances = " 	; DEFM "Occurances = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Length
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Occurances
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D1 	; LD H,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	MOVE.W 	#DISPLAYHLBOTH,D7 	; CALL DISPLAYHLBOTH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" Word = " 	; DEFM " Word = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	SUBQ.B 	#1,D2 	; DEC C
	SUBQ.B 	#1,D2 	; DEC C
	SUBQ.B 	#1,D2 	; DEC C
*				;;
*				;;Display word 
*				;;
LF01 	EQU	*-PRG.STRT	;LF01
	 	 	;
	MOVE.B 	D2,D0 	; LD A,C
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,NEWLINE
	BNE.S 	LAB.231 	;
	JMP 	NEWLINE(A5) 	;
LAB.231:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DISPLAYCODE,D7 	; CALL DISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.B 	#1,D2 	; DEC C
	JMP 	LF01(A5) 	; JR LF01
*				;;
*				;;-----
*				;;
*				;;Phase 5 - Construct 'Common Word Dictionary'
*				;;
*				;;Phase 5 scans the 'Frequency Table' and picks
*				;;most often used words. this are built into the 'Common
*				;;Word Dictionary' at address (STARTCWT) thru (ENDCWT)-1.
*				;;
*				;;-----
*				;;
PHASE05 	EQU	*-PRG.STRT	;PHASE05
	 	 	;
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 5 - Construct 'Common Word Dictionary'" 	; DEFM "Phase 5 - Construct 'Common Word Dictionary'"
	DC.B 	ASCIICR,0 	; DEFB ASCIICR,0
*				;;
*				;;Clear 'Common Word Dictionary'
*				;;
	LEA 	ENDFT(A5),A0 	; LD HL,(ENDFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTCWT(A5),A0 	; LD (STARTCWT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	ENDCWT(A5),A0 	; LD (ENDCWT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Select each word in 'Frequency Table' and asses it for
*				;;insertion into the 'Common Word Dictionary'.
*				;;
	MOVE.W 	#$0,D1 	; LD HL,$0
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
PE01 	EQU	*-PRG.STRT	;PE01
	 	 	;
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PE02
	BCS.S 	LAB.232 	;
	JMP 	PE02(A5) 	;
LAB.232:
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	LEA 	FREQUENCYTIMES(A5),A0 	; LD (FREQUENCYTIMES),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL ;Check if a 'typed' entry
	MOVE.W 	#ASSESSCOMMONWORD,D7 	; CALL ASSESSCOMMONWORD
	JSR 	SYS.JSR(A5) 	;
	LEA 	WORDNUMBER(A5),A0 	; LD HL,(WORDNUMBER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	JMP 	PE01(A5) 	; JR PE01
*				;;
*				;;Go through each 'character' used and asses each to be
*				;;a common reference.
*				;;
PE02 	EQU	*-PRG.STRT	;PE02
	 	 	;
	MOVE.W 	#CHARACTERCOUNTS,D1 	; LD HL,CHARACTERCOUNTS
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
PE03 	EQU	*-PRG.STRT	;PE03
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD C,B
	MOVE.B 	D2,D7 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D7,D2 	;
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	FREQUENCYTIMES(A5),A0 	; LD (FREQUENCYTIMES),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	OR.B 	D3,D0 	; OR E
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PE04
	BNE.S 	LAB.233 	;
	JMP 	PE04(A5) 	;
LAB.233:
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#'|',D0 	; CP '|' ;End of parse marker
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PE04
	BNE.S 	LAB.234 	;
	JMP 	PE04(A5) 	;
LAB.234:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#ASSESSCOMMONWORD,D7 	; CALL ASSESSCOMMONWORD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
PE04 	EQU	*-PRG.STRT	;PE04
	 	 	;
	ADD.W 	#$100,D2 	; INC B
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#128,D0 	; CP 128
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,PE03
	BEQ.S 	LAB.235 	;
	JMP 	PE03(A5) 	;
LAB.235:
*				;;
	MOVE.W 	#&200,D1 	; LD HL,&200
	LEA 	FREQUENCYTIMES(A5),A0 	; LD (FREQUENCYTIMES),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	MOVE.W 	#&1FAE,D1 	; LD HL,&1FAE ;dot space
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#ASSESSCOMMONREF,D7 	; CALL ASSESSCOMMONREF
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#&1FAC,D1 	; LD HL,&1FAC ;comma space
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#ASSESSCOMMONREF,D7 	; CALL ASSESSCOMMONREF
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#&1FBA,D1 	; LD HL,&1FBA ;colon space
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#ASSESSCOMMONREF,D7 	; CALL ASSESSCOMMONREF
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#&2FA2,D1 	; LD HL,&2FA2 ;space quote
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#ASSESSCOMMONREF,D7 	; CALL ASSESSCOMMONREF
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Convert 'Frequency Table' addresses to word references
*				;;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D3 	; LD D,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D3 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D1,D3 	; LD E,L
PE05 	EQU	*-PRG.STRT	;PE05
	 	 	;
	MOVE.W 	#CHECKENDCWT,D7 	; CALL CHECKENDCWT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PE06
	BCS.S 	LAB.236 	;
	JMP 	PE06(A5) 	;
LAB.236:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	PE05(A5) 	; JR PE05
PE06 	EQU	*-PRG.STRT	;PE06
	 	 	;
	LEA 	ENDCWT(A5),A0 	; LD (ENDCWT),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
*				;;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,PE09
	BEQ.S 	LAB.237 	;
	JMP 	PE09(A5) 	;
LAB.237:
*				;;
*				;;Display 'Common Word Dictionary'
*				;;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
PE07 	EQU	*-PRG.STRT	;PE07
	 	 	;
	MOVE.W 	#CHECKENDCWT,D7 	; CALL CHECKENDCWT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PE08
	BCS.S 	LAB.238 	;
	JMP 	PE08(A5) 	;
LAB.238:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	MOVE.W 	#DISPLAYWORD,D7 	; CALL DISPLAYWORD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	PE07(A5) 	; JR PE07
PE08 	EQU	*-PRG.STRT	;PE08
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;Display length of 'Common Word Dictionary'
*				;;
PE09 	EQU	*-PRG.STRT	;PE09
	 	 	;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.239 	;
	JMP 	SYS.RET(A5) 	;
LAB.239:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Length of 'Common Word Dictionary' =" 	; DEFM "Length of 'Common Word Dictionary' ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTCWT(A5),A0 	; LD DE,(STARTCWT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
*				;;-----
*				;;
*				;;Display word reference 'DE'
*				;;
DISPLAYWORD 	EQU	*-PRG.STRT	;DISPLAYWORD
	 	 	;
	ROR.W 	#8,D3 	; LD A,D ;1tttiiii, ttt is word type
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$07,D0 	; AND $07
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LW01
	BNE.S 	LAB.240 	;
	JMP 	LW01(A5) 	;
LAB.240:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#TYPETABLE,D1 	; LD HL,TYPETABLE
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,D2 	; LD C,A
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE.B 	#'^',D0 	; LD A,'^'
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
LW01 	EQU	*-PRG.STRT	;LW01
	 	 	;
*				;;
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D1 	; LD H,A
	MOVE.B 	D0,D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D3,D1 	; LD L,E
	MOVE.W 	#$0F80,D2 	; LD BC,$0F80
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,LW04
	BCC.S 	LAB.241 	;
	JMP 	LW04(A5) 	;
LAB.241:
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" {" 	; DEFM " {"
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D1,D0 	; LD A,L
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,LW02
	BEQ.S 	LAB.242 	;
	JMP 	LW02(A5) 	;
LAB.242:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"CR" 	; DEFM "CR"
	DC.B 	0 	; DEFB 0
	JMP 	LW03(A5) 	; JR LW03
LW02 	EQU	*-PRG.STRT	;LW02
	 	 	;
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
LW03 	EQU	*-PRG.STRT	;LW03
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"} " 	; DEFM "} "
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
LW04 	EQU	*-PRG.STRT	;LW04
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" [" 	; DEFM " ["
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D3,D2 	; LD C,E
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
LW05 	EQU	*-PRG.STRT	;LW05
	 	 	;
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,ILLEGALREFERENCE
	BCS.S 	LAB.243 	;
	JMP 	ILLEGALREFERENCE(A5) 	;
LAB.243:
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LW06
	BNE.S 	LAB.244 	;
	JMP 	LW06(A5) 	;
LAB.244:
*				;;
*				;;Move to next word
*				;;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	LW05(A5) 	; JR LW05
*				;;
*				;;Display the word
*				;;
LW06 	EQU	*-PRG.STRT	;LW06
	 	 	;
	ROR.W 	#8,D2 	; LD B,(HL) ;Length
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B 
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
LW07 	EQU	*-PRG.STRT	;LW07
	 	 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,LW08
	BNE.S 	LAB.245 	;
	JMP 	LW08(A5) 	;
LAB.245:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DISPLAYCODE,D7 	; CALL DISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	JMP 	LW07(A5) 	; JR LW07
LW08 	EQU	*-PRG.STRT	;LW08 
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"] " 	; DEFM "] "
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
TYPETABLE 	EQU	*-PRG.STRT	;TYPETABLE
	 	 	;
	DC.B 	' 	; DEFB ' ' ;No meaning
	DC.B 	'v' 	; DEFB 'v' ;Verb
	DC.B 	'j' 	; DEFB 'j' ;Conjunction
	DC.B 	'p' 	; DEFB 'p' ;Preposition
	DC.B 	'n' 	; DEFB 'n' ;Noun
	DC.B 	'a' 	; DEFB 'a' ;Adjective
	DC.B 	'c' 	; DEFB 'c' ;Proper Noun
	DC.B 	'u' 	; DEFB 'u' ;Captalised but no meaning
*				;;
*				;;
*				;;-----
*				;;
*				;;If word is more 'Common' than those in Dictionary then it
*				;;replaces one of them. HL is address of Frequency entry.
*				;;
ASSESSCOMMONWORD 	EQU	*-PRG.STRT	;ASSESSCOMMONWORD
	 	 	;
	LEA 	WORDNUMBER(A5),A0 	; LD HL,(WORDNUMBER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D1 	; LD H,A
	MOVE.B 	D0,D1 	;
	ROR.W 	#8,D1 	;
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
ASSESSCOMMONREF 	EQU	*-PRG.STRT	;ASSESSCOMMONREF
	 	 	;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
AC01 	EQU	*-PRG.STRT	;AC01
	 	 	;
	MOVE.W 	#CHECKENDCWT,D7 	; CALL CHECKENDCWT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,AC02
	BCS.S 	LAB.246 	;
	JMP 	AC02(A5) 	;
LAB.246:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL) ;Get occurrance count
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	FREQUENCYTIMES(A5),A0 	; LD HL,(FREQUENCYTIMES)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE 	F(A5),SR 	; JR C,AC03
	BCC.S 	LAB.247 	;
	JMP 	AC03(A5) 	;
LAB.247:
*				;;
*				;;Insert new Common Word
*				;;
AC02 	EQU	*-PRG.STRT	;AC02
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL ;Address to insert
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#1,D1 	; DEC HL
	SUBQ.W 	#1,D1 	; DEC HL
	SUBQ.W 	#1,D1 	; DEC HL
	SUBQ.W 	#1,D1 	; DEC HL
	LEA 	ENDCWT(A5),A0 	; LD DE,(ENDCWT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP C,CWTFULL
	BCC.S 	LAB.248 	;
	JMP 	CWTFULL(A5) 	;
LAB.248:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D1,D2 	; LD C,L
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ROR.W 	#8,D3 	; LD D,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D3 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D1,D3 	; LD E,L
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D3 	; INC DE
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#ICOPY,D7 	; CALL ICOPY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	LEA 	WORDNUMBER(A5),A0 	; LD BC,(WORDNUMBER)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	FREQUENCYTIMES(A5),A0 	; LD BC,(FREQUENCYTIMES)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
*				;;
*				;;Adjust top of table pointer
*				;;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	COMMONMAXENTRIES(A5),D0 	; LD A,(COMMONMAXENTRIES)
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,D2 	; LD C,A
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D1,D2 	; LD C,L
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC
	BCS.S 	LAB.249 	;
	JMP 	SYS.RET(A5) 	;
LAB.249:
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	ENDCWT(A5),A0 	; LD (ENDCWT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Keep on moving down 'Common Word Dictionary'
*				;;
AC03 	EQU	*-PRG.STRT	;AC03
	 	 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	AC01(A5) 	; JP AC01
*				;;
*				;;-----
*				;;
ILLEGALREFERENCE 	EQU	*-PRG.STRT	;ILLEGALREFERENCE
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"SQUASH error. Invalid word number" 	; DEFM "SQUASH error. Invalid word number"
	DC.B 	0 	; DEFB 0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
*				;;'Common Word Dictionary' full
*				;;
CWTFULL 	EQU	*-PRG.STRT	;CWTFULL
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"'Common Word Dictionary' too big" 	; DEFM "'Common Word Dictionary' too big"
	DC.B 	0 	; DEFB 0
	JMP 	WARMSTART(A5) 	; JP WARMSTART
*				;;
*				;;-----
*				;;
*				;;Compare HL with (ENDCWT). Returns 'NC' if HL >= (ENDCWT)
*				;;
CHECKENDCWT 	EQU	*-PRG.STRT	;CHECKENDCWT
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	ENDCWT(A5),A0 	; LD DE,(ENDCWT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DISPLAYINPUTNAME 	EQU	*-PRG.STRT	;DISPLAYINPUTNAME
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"B:MESSAGE.TXT " 	; DEFM "B:MESSAGE.TXT "
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DISPLAYTEMPNAME 	EQU	*-PRG.STRT	;DISPLAYTEMPNAME
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"B:SQUASH1.TMP " 	; DEFM "B:SQUASH1.TMP "
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DISPLAYOUTPUTNAME 	EQU	*-PRG.STRT	;DISPLAYOUTPUTNAME
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"B:SQUASH.DAT " 	; DEFM "B:SQUASH.DAT "
	DC.B 	0 	; DEFB 0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
G 	EQU	*-PRG.STRT	;G	 	 	;
001 	EQU	*-PRG.STRT	;001 ;MESSAGE.TXT to SQUASH.DAT compresser
*				;;
*				;;28/09/86
*				;;
*				;;STAGE2.Z80
*				;;
*				;;-----
*				;;
LENGTHPOINTERS 	EQU	$14 	;LENGTHPOINTERS EQU $14
*				;;
*				;;-----
*				;;
*				;;Phase 6 - Construct 'Message Descriptors'
*				;;
*				;;Phase 6 Scans the 'Sorted Message Table' in conjunction
*				;;with the 'Frequency Table' (for word numbers)
*				;;'Common Word Dictionary' (for short-form references)
*				;;and builds the 'Message Descriptors'.
*				;;
*				;;-----
*				;;
MODENULL 	EQU	1 	;MODENULL EQU 1 ;Initial/Follows-word state
MODESPACE 	EQU	2 	;MODESPACE EQU 2 ; Stored-space
MODECHAR 	EQU	3 	;MODECHAR EQU 3 ;Stored-character (in P6CHAR)
MODESC 	EQU	4 	;MODESC EQU 4 ;Space followed by character (in P6CHAR)
MODECS 	EQU	5 	;MODECS EQU 5 ;Character followed by space (character in P6CHAR)
MODEINIT 	EQU	6 	;MODEINIT EQU 6 ;Start of message
MODELEAD 	EQU	7 	;MODELEAD EQU 7 ;Spaces at start of message
*				;;
PHASE06 	EQU	*-PRG.STRT	;PHASE06
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 6 - Construct 'Message Descriptors'" 	; DEFM "Phase 6 - Construct 'Message Descriptors'"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;MAXMDT will be highest byte used (below buffer)
*				;;
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MAXMDT(A5),A0 	; LD (MAXMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Set up message number expected
*				;;
	MOVE.W 	#$0,D1 	; LD HL,$0 
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMSHORTREFS(A5),A0 	; LD (NUMSHORTREFS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMLONGREFS(A5),A0 	; LD (NUMLONGREFS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMMSGHEADS(A5),A0 	; LD (NUMMSGHEADS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMJUMPHEADS(A5),A0 	; LD (NUMJUMPHEADS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Open B:SQUASH1.TMP for reading
*				;;
	MOVE.W 	#INITSERIALSMT,D7 	; CALL INITSERIALSMT
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Open B:SQUASH2.TMP for writing
*				;;
	MOVE.W 	#INITSERIALICF,D7 	; CALL INITSERIALICF
	JSR 	SYS.JSR(A5) 	;
PF01 	EQU	*-PRG.STRT	;PF01
	MOVE.W 	#ENDSERIALSMT,D7 	; CALL ENDSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PF02 ;End of SMT
	BNE.S 	LAB.301 	;
	JMP 	PF02(A5) 	;
LAB.301:
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;
	MOVE.W 	#CONVERTMESSAGE,D7 	; CALL CONVERTMESSAGE
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Find next 'Sorted Message Table' entry.
*				;;
	MOVE.W 	#NEXTSERIALSMT,D7 	; CALL NEXTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Increment expected message number
*				;;
	LEA 	MSGNUM(A5),A0 	; LD BC,(MSGNUM)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ADDQ.W 	#1,D2 	; INC BC
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	JMP 	PF01(A5) 	; JR PF01
*				;;
*				;;Display Message Descriptors
*				;;
PF02 	EQU	*-PRG.STRT	;PF02
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM ;Delete B:SQUASH1.TMP
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,PF03
	BEQ.S 	LAB.302 	;
	JMP 	PF03(A5) 	;
LAB.302:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Number of short-references = " 	; DEFM "Number of short-references = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMSHORTREFS(A5),A0 	; LD HL,(NUMSHORTREFS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of long-references = " 	; DEFM "Number of long-references = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMLONGREFS(A5),A0 	; LD HL,(NUMLONGREFS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of Message Headers = " 	; DEFM "Number of Message Headers = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMMSGHEADS(A5),A0 	; LD HL,(NUMMSGHEADS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of Jump Headers = " 	; DEFM "Number of Jump Headers = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMJUMPHEADS(A5),A0 	; LD HL,(NUMJUMPHEADS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
PF03 	EQU	*-PRG.STRT	;PF03
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF) ;*
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	LENGTHMD(A5),A0 	; LD (LENGTHMD),HL ;*
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#LENGTHPOINTERS,D2 	; LD BC,LENGTHPOINTERS ;*
	ADD.W 	D2,D1 	; ADD HL,BC ;*
	MOVE 	SR,F(A5) 	;
	LEA 	INDEXMD(A5),A0 	; LD (INDEXMD),HL ;*
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.303 	;
	JMP 	SYS.RET(A5) 	;
LAB.303:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Longest compressed message =" 	; DEFM "Longest compressed message ="
	DC.B 	0 	; DEFB 0
	LEA 	MAXMDT(A5),A0 	; LD HL,(MAXMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	ENDCWT(A5),A0 	; LD DE,(ENDCWT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Length compressed Message Desriptors =" 	; DEFM "Length compressed Message Desriptors ="
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHMD(A5),A0 	; LD HL,(LENGTHMD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR 	; DEFB ASCIICR,ASCIICR
	DC.B 	"Low memory used =" 	; DEFM "Low memory used ="
	DC.B 	0 	; DEFB 0
	LEA 	MAXMDT(A5),A0 	; LD HL,(MAXMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#STARTTABLEMEMORY,D3 	; LD DE,STARTTABLEMEMORY
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"High memory used =" 	; DEFM "High memory used ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Free =" 	; DEFM "Free ="
	DC.B 	0 	; DEFB 0
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MAXMDT(A5),A0 	; LD DE,(MAXMDT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
P6BADWORDTYPE 	EQU	*-PRG.STRT	;P6BADWORDTYPE
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal use of special character '^'" 	; DEFM "Illegal use of special character '^'"
	DC.B 	0 	; DEFB 0
	JMP 	P6ERROR(A5) 	; JP P6ERROR ;Calls DISPLAYLINENUM and WARMSTART
*				;;
P6BADSLASH 	EQU	*-PRG.STRT	;P6BADSLASH
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal use of special character '/'" 	; DEFM "Illegal use of special character '/'"
	DC.B 	0 	; DEFB 0
	JMP 	P6ERROR(A5) 	; JP P6ERROR ;Calls DISPLAYLINENUM and WARMSTART
*				;;
MODEERROR 	EQU	*-PRG.STRT	;MODEERROR
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"SQUASH error: Invalid P6MODE value: " 	; DEFM "SQUASH error: Invalid P6MODE value: "
	DC.B 	0 	; DEFB 0
	MOVE.B 	P6MODE(A5),D0 	; LD A,(P6MODE)
	MOVE.W 	#DISPLAYAHEX,D7 	; CALL DISPLAYAHEX
	JSR 	SYS.JSR(A5) 	;
	JMP 	P6ERROR(A5) 	; JP P6ERROR ;Calls DISPLAYLINENUM and WARMSTART
*				;;
P6ERROR 	EQU	*-PRG.STRT	;P6ERROR
	MOVE.W 	#ABORTSERIALSMT,D7 	; CALL ABORTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#ABORTSERIALICF,D7 	; CALL ABORTSERIALICF
	JSR 	SYS.JSR(A5) 	;
	JMP 	DISPLAYLINENUM(A5) 	; JP DISPLAYLINENUM ;ends in WARMSTART
*				;;
*				;;-----
*				;;
*				;;Build a message descriptor from one 'Sorted Message 
*				;;Table' entry. HL is address of SMT entry. 
*				;;
CONVERTMESSAGE 	EQU	*-PRG.STRT	;CONVERTMESSAGE
*				;;Reset for new message:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDCWT(A5),A0 	; LD HL,(ENDCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	CURRENTMDT(A5),A0 	; LD (CURRENTMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL ;Get source line number (for errors)
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
*				;;
*				;;Check this is the next message number in sequence
*				;;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	LEA 	MSGNUM(A5),A0 	; LD BC,(MSGNUM)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM02
	BNE.S 	LAB.304 	;
	JMP 	HM02(A5) 	;
LAB.304:
*				;;
*				;;Calculate distance of 'jump'
*				;;
	SUBQ.W 	#1,D1 	; DEC HL ;Jump range is 1-$80.
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#$80,D2 	; LD BC,$80
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR C,HM01
	BCC.S 	LAB.305 	;
	JMP 	HM01(A5) 	;
LAB.305:
	MOVE.W 	#$7F,D1 	; LD HL,$7F ;Jump is too far
*				;;
*				;;Adjust for new expected message number
*				;;
HM01 	EQU	*-PRG.STRT	;HM01
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	MSGNUM(A5),A0 	; LD BC,(MSGNUM)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	MSGNUM(A5),A0 	; LD (MSGNUM),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	D1,D0 	; LD A,L
	BSET 	D0,#JUMP 	; SET JUMP,A ;Make a jump header
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	LEA 	NUMJUMPHEADS(A5),A0 	; LD HL,(NUMJUMPHEADS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMJUMPHEADS(A5),A0 	; LD (NUMJUMPHEADS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	CONVERTMESSAGE(A5) 	; JR CONVERTMESSAGE
*				;;
*				;;Not a jump, Create zero-length 'Message Header'
*				;;
HM02 	EQU	*-PRG.STRT	;HM02
	EOR.B 	D0,D0 	; XOR A ;Invalid 'mode'
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,WORDTYPE(A5) 	; LD (WORDTYPE),A ;Clear type of next word
	MOVE.B 	#MODEINIT,D0 	; LD A,MODEINIT
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	NUMKEYWORDS(A5),A0 	; LD (NUMKEYWORDS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	#$00,0(A5,D1.W) 	; LD (HL),$00 ;Zero-length header
	LEA 	STARTMSG(A5),A0 	; LD (STARTMSG),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	CURRENTMDT(A5),A0 	; LD (CURRENTMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#CHECKBELOWBUFFER,D7 	; CALL CHECKBELOWBUFFER
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,MDTFULL
	BCS.S 	LAB.306 	;
	JMP 	MDTFULL(A5) 	;
LAB.306:
	LEA 	NUMMSGHEADS(A5),A0 	; LD HL,(NUMMSGHEADS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMMSGHEADS(A5),A0 	; LD (NUMMSGHEADS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC 
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	SUBQ.W 	#1,D2 	; DEC BC
	LEA 	MESSAGELENGTH(A5),A0 	; LD (MESSAGELENGTH),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#2,D6 	; PUSH BC ;Message number
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LINENUM(A5),A0 	; LD (LINENUM),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM03
	BEQ.S 	LAB.307 	;
	JMP 	HM03(A5) 	;
LAB.307:
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Message number = " 	; DEFM "Message number = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
HM03 	EQU	*-PRG.STRT	;HM03
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Examine for words
*				;;
HM04 	EQU	*-PRG.STRT	;HM04
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,HM33
	BNE.S 	LAB.308 	;
	JMP 	HM33(A5) 	;
LAB.308:
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,WORDTYPE(A5) 	; LD (WORDTYPE),A
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DEBUGDISPLAYCODE,D7 	; CALL DEBUGDISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#',D0 	; CP ' ' ;Space, cr or lf
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM12
	BEQ.S 	LAB.309 	;
	JMP 	HM12(A5) 	;
LAB.309:
*				;;
*				;;Space found
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	P6MODE(A5),D0 	; LD A,(P6MODE)
	CMP.B 	#MODEINIT,D0 	; CP MODEINIT
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM05
	BEQ.S 	LAB.310 	;
	JMP 	HM05(A5) 	;
LAB.310:
	MOVE.B 	#MODELEAD,D0 	; LD A,MODELEAD
	JMP 	HM09(A5) 	; JR HM09
HM05 	EQU	*-PRG.STRT	;HM05
	CMP.B 	#MODELEAD,D0 	; CP MODELEAD
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM10
	BNE.S 	LAB.311 	;
	JMP 	HM10(A5) 	;
LAB.311:
	CMP.B 	#MODENULL,D0 	; CP MODENULL
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM06
	BEQ.S 	LAB.312 	;
	JMP 	HM06(A5) 	;
LAB.312:
	MOVE.B 	#MODESPACE,D0 	; LD A,MODESPACE
	JMP 	HM09(A5) 	; JR HM09
HM06 	EQU	*-PRG.STRT	;HM06
	CMP.B 	#MODESPACE,D0 	; CP MODESPACE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM10
	BNE.S 	LAB.313 	;
	JMP 	HM10(A5) 	;
LAB.313:
	CMP.B 	#MODECHAR,D0 	; CP MODECHAR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM07
	BEQ.S 	LAB.314 	;
	JMP 	HM07(A5) 	;
LAB.314:
	MOVE.B 	#MODECS,D0 	; LD A,MODECS
	JMP 	HM09(A5) 	; JR HM09
HM07 	EQU	*-PRG.STRT	;HM07
	CMP.B 	#MODESC,D0 	; CP MODESC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM08
	BEQ.S 	LAB.315 	;
	JMP 	HM08(A5) 	;
LAB.315:
*				;;Output character
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	ROR.W 	#8,D3 	; LD D,$30 ;Leading+trailing spaces
	MOVE.B 	#$30,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#MODENULL,D0 	; LD A,MODENULL
	JMP 	HM09(A5) 	; JR HM09
HM08 	EQU	*-PRG.STRT	;HM08
	CMP.B 	#MODECS,D0 	; CP MODECS
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,MODEERROR
	BEQ.S 	LAB.316 	;
	JMP 	MODEERROR(A5) 	;
LAB.316:
	JMP 	HM10(A5) 	; JR HM10
HM09 	EQU	*-PRG.STRT	;HM09
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
HM10 	EQU	*-PRG.STRT	;HM10
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Move on to next character
*				;;
HM11 	EQU	*-PRG.STRT	;HM11
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	LEA 	MESSAGELENGTH(A5),A0 	; LD (MESSAGELENGTH),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	JMP 	HM04(A5) 	; JR HM04
*				;;
*				;;Check for 'special' characters
*				;;
HM12 	EQU	*-PRG.STRT	;HM12
	LEA 	WORDADDRESS(A5),A0 	; LD (WORDADDRESS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	CMP.B 	#'%',D0 	; CP '%' ;Forces a cr.
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,HM21
	BNE.S 	LAB.317 	;
	JMP 	HM21(A5) 	;
LAB.317:
	CMP.B 	#'_',D0 	; CP '_' ;Forces a space
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,HM21
	BNE.S 	LAB.318 	;
	JMP 	HM21(A5) 	;
LAB.318:
	CMP.B 	#'|',D0 	; CP '|' ;Terminates printing part of message
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,HM21
	BNE.S 	LAB.319 	;
	JMP 	HM21(A5) 	;
LAB.319:
	CMP.B 	#'^',D0 	; CP '^' ;Word-type
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM13
	BEQ.S 	LAB.320 	;
	JMP 	HM13(A5) 	;
LAB.320:
*				;;
*				;;Process word-type declaration
*				;;
	MOVE.W 	#WT01,D7 	; CALL WT01
	JSR 	SYS.JSR(A5) 	;
HM13 	EQU	*-PRG.STRT	;HM13
	MOVE.W 	#FF01,D7 	; CALL FF01
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP C,HM20 ;Not a word
	BCC.S 	LAB.321 	;
	JMP 	HM20(A5) 	;
LAB.321:
*				;;
*				;;Frequency table address of word found, check if it's
*				;;a 'Common Word', convert and store its word number.
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL ;Frequency Table entry address
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	P6MODE(A5),D0 	; LD A,(P6MODE)
	CMP.B 	#MODENULL,D0 	; CP MODENULL
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM19 ;Store word
	BNE.S 	LAB.322 	;
	JMP 	HM19(A5) 	;
LAB.322:
	CMP.B 	#MODEINIT,D0 	; CP MODEINIT
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM19 ;Store word
	BNE.S 	LAB.323 	;
	JMP 	HM19(A5) 	;
LAB.323:
	CMP.B 	#MODELEAD,D0 	; CP MODELEAD
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM15
	BNE.S 	LAB.324 	;
	JMP 	HM15(A5) 	;
LAB.324:
	CMP.B 	#MODESPACE,D0 	; CP MODESPACE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM19 ;Store word
	BNE.S 	LAB.325 	;
	JMP 	HM19(A5) 	;
LAB.325:
	CMP.B 	#MODESC,D0 	; CP MODESC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM16
	BNE.S 	LAB.326 	;
	JMP 	HM16(A5) 	;
LAB.326:
	CMP.B 	#MODECS,D0 	; CP MODECS
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM17
	BNE.S 	LAB.327 	;
	JMP 	HM17(A5) 	;
LAB.327:
	CMP.B 	#MODECHAR,D0 	; CP MODECHAR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,MODEERROR
	BEQ.S 	LAB.328 	;
	JMP 	MODEERROR(A5) 	;
LAB.328:
	ROR.W 	#8,D3 	; LD D,$0
	MOVE.B 	#$0,D3 	;
	ROR.W 	#8,D3 	;
	JMP 	HM18(A5) 	; JR HM18
*				;;Only places where space is before a word are at start
*				;;of sentance or where space is forced as a character ('_' or '/ ')
HM15 	EQU	*-PRG.STRT	;HM15
	MOVE.W 	#$0F80+',D1 	; LD HL,$0F80+' '
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	HM19(A5) 	; JR HM19 ;Store word
*				;;Previously found space then character (hoping
*				;;to find another space, but got a word)
HM16 	EQU	*-PRG.STRT	;HM16
	ROR.W 	#8,D3 	; LD D,$20 ;Leading space
	MOVE.B 	#$20,D3 	;
	ROR.W 	#8,D3 	;
	JMP 	HM18(A5) 	; JR HM18
*				;;Not stricktly required:
HM17 	EQU	*-PRG.STRT	;HM17
	ROR.W 	#8,D3 	; LD D,$10 ;Trailing space
	MOVE.B 	#$10,D3 	;
	ROR.W 	#8,D3 	;
*				;;
*				;;Output stored character with word-type D
*				;;(D=0 character only, D=$10 traling space, D=$20 leading space)
HM18 	EQU	*-PRG.STRT	;HM18
*				;;> CALL OLDFIX ;> For Adrian Mole/Archers
*				;;
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Output word and reset to 'idle' state
HM19 	EQU	*-PRG.STRT	;HM19
	MOVE.B 	#MODENULL,D0 	; LD A,MODENULL
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
	MOVE.W 	0(A5,D6.W),D1 	; POP HL ;Adress of a FT entry
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.W 	#SW01,D7 	; CALL SW01
	JSR 	SYS.JSR(A5) 	;
	JMP 	HM04(A5) 	; JP HM04
*				;;
*				;;Not in Frequency Table (i.e. Not a 'word')
*				;;
HM20 	EQU	*-PRG.STRT	;HM20
*				;;
*				;;Check for special character codes
	LEA 	WORDADDRESS(A5),A0 	; LD HL,(WORDADDRESS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BTST 	D0,#7 	; BIT 7,A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM21
	BNE.S 	LAB.329 	;
	JMP 	HM21(A5) 	;
LAB.329:
	BCLR 	D0,#7 	; RES 7,A
	JMP 	HM24(A5) 	; JR HM24
*				;;
HM21 	EQU	*-PRG.STRT	;HM21
	CMP.B 	#'%',D0 	; CP '%' ;Forces a CR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM22
	BEQ.S 	LAB.330 	;
	JMP 	HM22(A5) 	;
LAB.330:
	MOVE.B 	#ASCIICR,D0 	; LD A,ASCIICR
HM22 	EQU	*-PRG.STRT	;HM22
	CMP.B 	#'_',D0 	; CP '_' ;Forces a SPACE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM23
	BEQ.S 	LAB.331 	;
	JMP 	HM23(A5) 	;
LAB.331:
	MOVE.B 	#',D0 	; LD A,' '
HM23 	EQU	*-PRG.STRT	;HM23
	CMP.B 	#'|',D0 	; CP '|' ;End of printable message
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,HM24
	BEQ.S 	LAB.332 	;
	JMP 	HM24(A5) 	;
LAB.332:
	MOVE.W 	#MODEEOF,D7 	; CALL MODEEOF
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#KY00,D7 	; CALL KY00
	JSR 	SYS.JSR(A5) 	;
	JMP 	HM33(A5) 	; JP HM33
*				;;
HM24 	EQU	*-PRG.STRT	;HM24
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	P6MODE(A5),D0 	; LD A,(P6MODE)
	CMP.B 	#MODEINIT,D0 	; CP MODEINIT
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM25
	BNE.S 	LAB.333 	;
	JMP 	HM25(A5) 	;
LAB.333:
	CMP.B 	#MODELEAD,D0 	; CP MODELEAD
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM26
	BNE.S 	LAB.334 	;
	JMP 	HM26(A5) 	;
LAB.334:
	CMP.B 	#MODESPACE,D0 	; CP MODESPACE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM26
	BNE.S 	LAB.335 	;
	JMP 	HM26(A5) 	;
LAB.335:
	CMP.B 	#MODECHAR,D0 	; CP MODECHAR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM28
	BNE.S 	LAB.336 	;
	JMP 	HM28(A5) 	;
LAB.336:
	CMP.B 	#MODESC,D0 	; CP MODESC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM29
	BNE.S 	LAB.337 	;
	JMP 	HM29(A5) 	;
LAB.337:
	CMP.B 	#MODECS,D0 	; CP MODECS
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM30
	BNE.S 	LAB.338 	;
	JMP 	HM30(A5) 	;
LAB.338:
	CMP.B 	#MODENULL,D0 	; CP MODENULL
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,MODEERROR
	BEQ.S 	LAB.339 	;
	JMP 	MODEERROR(A5) 	;
LAB.339:
*				;;Character in initial and 'idle' states just stores
HM25 	EQU	*-PRG.STRT	;HM25
	MOVE.B 	#MODECHAR,D0 	; LD A,MODECHAR
	JMP 	HM27(A5) 	; JR HM27
*				;;Following a space
HM26 	EQU	*-PRG.STRT	;HM26
	MOVE.B 	#MODESC,D0 	; LD A,MODESC
HM27 	EQU	*-PRG.STRT	;HM27
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,P6CHAR(A5) 	; LD (P6CHAR),A
	JMP 	HM32(A5) 	; JR HM32
*				;;Two characters together
HM28 	EQU	*-PRG.STRT	;HM28
	ROR.W 	#8,D3 	; LD D,$0
	MOVE.B 	#$0,D3 	;
	ROR.W 	#8,D3 	;
	JMP 	HM31(A5) 	; JR HM31
*				;;Space character character
HM29 	EQU	*-PRG.STRT	;HM29
	ROR.W 	#8,D3 	; LD D,$20 ;Leading space
	MOVE.B 	#$20,D3 	;
	ROR.W 	#8,D3 	;
	JMP 	HM31(A5) 	; JR HM31
*				;;Character space character
HM30 	EQU	*-PRG.STRT	;HM30
	ROR.W 	#8,D3 	; LD D,$10 ;Trailing space
	MOVE.B 	#$10,D3 	;
	ROR.W 	#8,D3 	;
HM31 	EQU	*-PRG.STRT	;HM31
*				;;Save stored character, D=word-type
*				;;> CALL OLDFIX ;>
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	#MODECHAR,D0 	; LD A,MODECHAR
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,P6CHAR(A5) 	; LD (P6CHAR),A
*				;;
HM32 	EQU	*-PRG.STRT	;HM32
	LEA 	WORDADDRESS(A5),A0 	; LD HL,(WORDADDRESS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	JMP 	HM11(A5) 	; JP HM11
*				;;
*				;;End of message descriptor
*				;;
HM33 	EQU	*-PRG.STRT	;HM33
	MOVE.W 	#MODEEOF,D7 	; CALL MODEEOF
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; CALL Z,NEWLINE
	BNE.S 	LAB.340 	;
	MOVE.W 	#NEWLINE,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.340:
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL) ;Examine message header
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,HM39
	BEQ.S 	LAB.341 	;
	JMP 	HM39(A5) 	;
LAB.341:
*				;;
*				;;If message contains any non-garbage words then
*				;;set 'parse' bit in first header byte.
*				;;
	LEA 	NUMKEYWORDS(A5),A0 	; LD HL,(NUMKEYWORDS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,HM34
	BNE.S 	LAB.342 	;
	JMP 	HM34(A5) 	;
LAB.342:
*				;;
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BSET 	D0,#PARSE 	; SET PARSE,A
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
*				;;Calculate length of finished message
*				;;
HM34 	EQU	*-PRG.STRT	;HM34
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTMSG(A5),A0 	; LD DE,(STARTMSG)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	FREQUENCYTIMES(A5),A0 	; LD (FREQUENCYTIMES),HL ;Length
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
HM35 	EQU	*-PRG.STRT	;HM35
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#$003F+1,D2 	; LD BC,$003F+1
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR C,HM36
	BCC.S 	LAB.343 	;
	JMP 	HM36(A5) 	;
LAB.343:
*				;;
*				;;Length is greater than allowed for a single
*				;;header byte, add additional header.
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL) ;Duplicate 'PARSE' flag
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	STARTMSG(A5),A0 	; LD (STARTMSG),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#1,D1 	; DEC HL
	LEA 	CURRENTMDT(A5),A0 	; LD DE,(CURRENTMDT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	LEA 	FREQUENCYTIMES(A5),A0 	; LD BC,(FREQUENCYTIMES) ;Length
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	JSR 	SYS.LDDR(A5) 	; LDDR 
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	CURRENTMDT(A5),A0 	; LD (CURRENTMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#CHECKBELOWBUFFER,D7 	; CALL CHECKBELOWBUFFER
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,MDTFULL
	BCS.S 	LAB.344 	;
	JMP 	MDTFULL(A5) 	;
LAB.344:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#$003F,D2 	; LD BC,$003F
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	JMP 	HM35(A5) 	; JR HM35
*				;;
*				;;Replace length byte
*				;;
HM36 	EQU	*-PRG.STRT	;HM36
	MOVE.B 	D1,D0 	; LD A,L
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	OR.B 	0(A5,D1.W),D0 	; OR (HL)
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MAXMDT(A5),A0 	; LD DE,(MAXMDT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,HM37
	BCC.S 	LAB.345 	;
	JMP 	HM37(A5) 	;
LAB.345:
*				;;
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MAXMDT(A5),A0 	; LD (MAXMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Write message to B:SQUASH2.TMP
*				;;
HM37 	EQU	*-PRG.STRT	;HM37
	LEA 	STARTMSG(A5),A0 	; LD HL,(STARTMSG)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
HM38 	EQU	*-PRG.STRT	;HM38
	LEA 	CURRENTMDT(A5),A0 	; LD DE,(CURRENTMDT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.346 	;
	JMP 	SYS.RET(A5) 	;
LAB.346:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	HM38(A5) 	; JR HM38
*				;;
HM39 	EQU	*-PRG.STRT	;HM39
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Illegal message header" 	; DEFM "Illegal message header"
	DC.B 	0 	; DEFB 0
	JMP 	P6ERROR(A5) 	; JP P6ERROR ;Calls DISPLAYLINENUM and WARMSTART
*				;;
*				;;-----
*				;;
OLDFIX 	EQU	*-PRG.STRT	;OLDFIX ;>
	ROR.W 	#8,D3 	; LD A,D ;>
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	CMP.B 	#$20,D0 	; CP $20 ;>
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,OF01
	BEQ.S 	LAB.347 	;
	JMP 	OF01(A5) 	;
LAB.347:
	SUBQ.W 	#2,D6 	; PUSH DE ;>
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#$0F80+",D1 	; LD HL,$0F80+" " ;>
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER ;>
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE ;>
	ADDQ.W 	#2,D6 	;
OF01 	EQU	*-PRG.STRT	;OF01 ;>
*				;;
	SUBQ.W 	#2,D6 	; PUSH DE ;>
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	ROR.W 	#8,D3 	; LD D,0 ;>
	MOVE.B 	#0,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STORECHARACTER,D7 	; CALL STORECHARACTER
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE ;>
	ADDQ.W 	#2,D6 	;
*				;;
	ROR.W 	#8,D3 	; LD A,D ;>
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	CMP.B 	#$10,D0 	; CP $10 ;>
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ ;>
	BEQ.S 	LAB.348 	;
	JMP 	SYS.RET(A5) 	;
LAB.348:
	MOVE.W 	#$0F80+",D1 	; LD HL,$0F80+" " ;>
	JMP 	STORECHARACTER(A5) 	; JP STORECHARACTER ;>
*				;;
*				;;-----
*				;;
MODEEOF 	EQU	*-PRG.STRT	;MODEEOF
	MOVE.W 	#ME01,D7 	; CALL ME01
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#MODENULL,D0 	; LD A,MODENULL
	MOVE.B 	D0,P6MODE(A5) 	; LD (P6MODE),A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
ME01 	EQU	*-PRG.STRT	;ME01
	MOVE.B 	P6MODE(A5),D0 	; LD A,(P6MODE)
	CMP.B 	#MODENULL,D0 	; CP MODENULL
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.349 	;
	JMP 	SYS.RET(A5) 	;
LAB.349:
	CMP.B 	#MODEINIT,D0 	; CP MODEINIT
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.350 	;
	JMP 	SYS.RET(A5) 	;
LAB.350:
	CMP.B 	#MODESPACE,D0 	; CP MODESPACE
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,ME01A
	BNE.S 	LAB.351 	;
	JMP 	ME01A(A5) 	;
LAB.351:
	CMP.B 	#MODELEAD,D0 	; CP MODELEAD
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,ME02
	BEQ.S 	LAB.352 	;
	JMP 	ME02(A5) 	;
LAB.352:
ME01A 	EQU	*-PRG.STRT	;ME01A
	MOVE.W 	#$0F80+',D1 	; LD HL,$0F80+' '
	JMP 	STORECHARACTER(A5) 	; JP STORECHARACTER
ME02 	EQU	*-PRG.STRT	;ME02
	CMP.B 	#MODECHAR,D0 	; CP MODECHAR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,ME03
	BEQ.S 	LAB.353 	;
	JMP 	ME03(A5) 	;
LAB.353:
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	ROR.W 	#8,D3 	; LD D,0
	MOVE.B 	#0,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	JMP 	STORECHARACTER(A5) 	; JP STORECHARACTER
ME03 	EQU	*-PRG.STRT	;ME03
	CMP.B 	#MODESC,D0 	; CP MODESC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,ME04
	BEQ.S 	LAB.354 	;
	JMP 	ME04(A5) 	;
LAB.354:
	ROR.W 	#8,D3 	; LD D,$20 ;Leading space
	MOVE.B 	#$20,D3 	;
	ROR.W 	#8,D3 	;
	JMP 	ME05(A5) 	; JR ME05
ME04 	EQU	*-PRG.STRT	;ME04
	CMP.B 	#MODECS,D0 	; CP MODECS
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP NZ,MODEERROR
	BEQ.S 	LAB.355 	;
	JMP 	MODEERROR(A5) 	;
LAB.355:
	ROR.W 	#8,D3 	; LD D,$10 ;Trailing space
	MOVE.B 	#$10,D3 	;
	ROR.W 	#8,D3 	;
ME05 	EQU	*-PRG.STRT	;ME05
*				;;> JP OLDFIX ;>
	MOVE.B 	P6CHAR(A5),D0 	; LD A,(P6CHAR)
	MOVE.B 	D0,D3 	; LD E,A
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	JMP 	STORECHARACTER(A5) 	; JP STORECHARACTER
*				;;
*				;;-----
*				;;
*				;;Examine for key words
*				;;
KY00 	EQU	*-PRG.STRT	;KY00
	MOVE.W 	#$0F80,D1 	; LD HL,$0F80
	MOVE.W 	#STOREREFERENCE,D7 	; CALL STOREREFERENCE
	JSR 	SYS.JSR(A5) 	;
	LEA 	WORDADDRESS(A5),A0 	; LD HL,(WORDADDRESS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
KY02 	EQU	*-PRG.STRT	;KY02
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.356 	;
	JMP 	SYS.RET(A5) 	;
LAB.356:
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	LEA 	MESSAGELENGTH(A5),A0 	; LD (MESSAGELENGTH),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
KY01 	EQU	*-PRG.STRT	;KY01
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.357 	;
	JMP 	SYS.RET(A5) 	;
LAB.357:
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,WORDTYPE(A5) 	; LD (WORDTYPE),A
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DEBUGDISPLAYCODE,D7 	; CALL DEBUGDISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#'^',D0 	; CP '^'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,KY03
	BNE.S 	LAB.358 	;
	JMP 	KY03(A5) 	;
LAB.358:
*				;;
*				;;Not a keyword so ignore
*				;;
	JMP 	KY02(A5) 	; JR KY02
*				;;
*				;;Check for 'special' characters
*				;;
KY03 	EQU	*-PRG.STRT	;KY03
	LEA 	WORDADDRESS(A5),A0 	; LD (WORDADDRESS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Process word-type declaration
*				;;
	MOVE.W 	#WT01,D7 	; CALL WT01
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#FF01,D7 	; CALL FF01
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,KY20 ;Not a word
	BCC.S 	LAB.359 	;
	JMP 	KY20(A5) 	;
LAB.359:
	MOVE.W 	#SW01,D7 	; CALL SW01 ;Store it
	JSR 	SYS.JSR(A5) 	;
	JMP 	KY01(A5) 	; JR KY01
*				;;
*				;;Not in Frequency Table (i.e. Not a 'word')
*				;;
KY20 	EQU	*-PRG.STRT	;KY20
	LEA 	WORDADDRESS(A5),A0 	; LD HL,(WORDADDRESS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	JMP 	KY02(A5) 	; JP KY02
*				;;
*				;;-----
*				;;
*				;;Process word-type declaration
*				;;
WT01 	EQU	*-PRG.STRT	;WT01
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P6BADWORDTYPE
	BNE.S 	LAB.360 	;
	JMP 	P6BADWORDTYPE(A5) 	;
LAB.360:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#DEBUGDISPLAYCODE,D7 	; CALL DEBUGDISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#TYPETABLE+1,D3 	; LD DE,TYPETABLE+1
	ROR.W 	#8,D2 	; LD B,1
	MOVE.B 	#1,D2 	;
	ROR.W 	#8,D2 	;
WT02 	EQU	*-PRG.STRT	;WT02
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#8,D0 	; CP 8
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P6BADWORDTYPE
	BNE.S 	LAB.361 	;
	JMP 	P6BADWORDTYPE(A5) 	;
LAB.361:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,WT03
	BNE.S 	LAB.362 	;
	JMP 	WT03(A5) 	;
LAB.362:
	ADDQ.W 	#1,D3 	; INC DE
	ADD.W 	#$100,D2 	; INC B
	JMP 	WT02(A5) 	; JR WT02
WT03 	EQU	*-PRG.STRT	;WT03
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,WORDTYPE(A5) 	; LD (WORDTYPE),A
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,WT04
	BNE.S 	LAB.363 	;
	JMP 	WT04(A5) 	;
LAB.363:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	NUMKEYWORDS(A5),A0 	; LD HL,(NUMKEYWORDS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMKEYWORDS(A5),A0 	; LD (NUMKEYWORDS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
WT04 	EQU	*-PRG.STRT	;WT04
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP Z,P6BADWORDTYPE
	BNE.S 	LAB.364 	;
	JMP 	P6BADWORDTYPE(A5) 	;
LAB.364:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,WT04
	BNE.S 	LAB.365 	;
	JMP 	WT04(A5) 	;
LAB.365:
	LEA 	WORDADDRESS(A5),A0 	; LD (WORDADDRESS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	MESSAGELENGTH(A5),A0 	; LD (MESSAGELENGTH),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	JMP 	DEBUGDISPLAYCODE(A5) 	; JP DEBUGDISPLAYCODE
*				;;
*				;;-----
*				;;
FF01 	EQU	*-PRG.STRT	;FF01
*				;;Search directory for a matching word
*				;;
	MOVE.W 	#LOADBUFFER,D7 	; CALL LOADBUFFER
	JSR 	SYS.JSR(A5) 	;
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
FF02 	EQU	*-PRG.STRT	;FF02
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,FF04
	BCS.S 	LAB.366 	;
	JMP 	FF04(A5) 	;
LAB.366:
	MOVE.W 	#COMPARE,D7 	; CALL COMPARE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,FF03
	BNE.S 	LAB.367 	;
	JMP 	FF03(A5) 	;
LAB.367:
	MOVE 	F(A5),SR 	; JP C,FF04 ;Past it
	BCC.S 	LAB.368 	;
	JMP 	FF04(A5) 	;
LAB.368:
	ROR.W 	#8,D2 	; LD B,$0
	MOVE.B 	#$0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	JMP 	FF02(A5) 	; JR FF02
*				;;
FF03 	EQU	*-PRG.STRT	;FF03
	EOR.B 	D0,D0 	; XOR A ;Found entry in Frequency Table
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Not in Frequency Table (i.e. Not a 'word')
*				;;
FF04 	EQU	*-PRG.STRT	;FF04
	OR.B 	#17,F+1(A6) 	; SCF ;Return 'not-a-word'
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Frequency table address of word found, check if it's
*				;;a 'Common Word', convert and store its word number.
*				;;
SW01 	EQU	*-PRG.STRT	;SW01
	MOVE.W 	#GETWORDNUMBER,D7 	; CALL GETWORDNUMBER
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#STOREREFERENCE,D7 	; CALL STOREREFERENCE
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	WORDADDRESS(A5),A0 	; LD HL,(WORDADDRESS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
	LEA 	MESSAGELENGTH(A5),A0 	; LD BC,(MESSAGELENGTH)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SW03
	BNE.S 	LAB.369 	;
	JMP 	SW03(A5) 	;
LAB.369:
SW02 	EQU	*-PRG.STRT	;SW02
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SW03
	BNE.S 	LAB.370 	;
	JMP 	SW03(A5) 	;
LAB.370:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	MOVE.W 	#DEBUGDISPLAYCODE,D7 	; CALL DEBUGDISPLAYCODE
	JSR 	SYS.JSR(A5) 	;
	JMP 	SW02(A5) 	; JR SW02
SW03 	EQU	*-PRG.STRT	;SW03
	LEA 	MESSAGELENGTH(A5),A0 	; LD (MESSAGELENGTH),BC
	MOVE.B 	D2,(A0) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,1(A0) 	;
	ROR.W 	#8,D2 	;
	EOR.B 	D0,D0 	; XOR A ;Return 'word-ok'
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DEBUGDISPLAYCODE 	EQU	*-PRG.STRT	;DEBUGDISPLAYCODE
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	DEBUG(A5),D0 	; LD A,(DEBUG)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DISPDEBUG01
	BNE.S 	LAB.371 	;
	JMP 	DISPDEBUG01(A5) 	;
LAB.371:
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
DISPDEBUG01 	EQU	*-PRG.STRT	;DISPDEBUG01
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	DISPLAYCODE(A5) 	; JP DISPLAYCODE
*				;;
*				;;-----
*				;;
*				;;HL is Long word reference. Returns 'Z' and
*				;;A = short-ref. Otherwise returns 'NZ'.
*				;;
CHECKSHORTREF 	EQU	*-PRG.STRT	;CHECKSHORTREF
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
CR01 	EQU	*-PRG.STRT	;CR01
	MOVE.W 	#CHECKENDCWT,D7 	; CALL CHECKENDCWT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,CR04
	BCS.S 	LAB.372 	;
	JMP 	CR04(A5) 	;
LAB.372:
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D1 	; LD H,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,CR02
	BNE.S 	LAB.373 	;
	JMP 	CR02(A5) 	;
LAB.373:
	ADD.W 	#$100,D2 	; INC B
	JMP 	CR01(A5) 	; JR CR01
CR02 	EQU	*-PRG.STRT	;CR02
	EOR.B 	D0,D0 	; XOR A ;Return 'Z'
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	JMP 	SYS.RET(A5) 	; RET 
CR04 	EQU	*-PRG.STRT	;CR04
	MOVE.B 	#1,D0 	; LD A,1 ;Return 'NZ'
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;HL is the address of a frequency entry.
*				;;Returns HL as its word number.
*				;;
GETWORDNUMBER 	EQU	*-PRG.STRT	;GETWORDNUMBER
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#0,D2 	; LD BC,0
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
GW01 	EQU	*-PRG.STRT	;GW01
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,SHORTOVERSHOOT
	BCS.S 	LAB.374 	;
	JMP 	SHORTOVERSHOOT(A5) 	;
LAB.374:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,GW02
	BNE.S 	LAB.375 	;
	JMP 	GW02(A5) 	;
LAB.375:
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D2 	; INC BC
	JMP 	GW01(A5) 	; JR GW01
GW02 	EQU	*-PRG.STRT	;GW02
	ROR.W 	#8,D1 	; LD H,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
STOREREFERENCE 	EQU	*-PRG.STRT	;STOREREFERENCE
	ROR.W 	#8,D1 	; LD A,H ;Make it a long-form reference
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D1 	; LD H,A
	MOVE.B 	D0,D1 	;
	ROR.W 	#8,D1 	;
*				;;
	MOVE.B 	WORDTYPE(A5),D0 	; LD A,(WORDTYPE)
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$70,D0 	; AND $70
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D1 	; OR H
	OR.B 	D1,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D1 	; LD H,A
	MOVE.B 	D0,D1 	;
	ROR.W 	#8,D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,WORDTYPE(A5) 	; LD (WORDTYPE),A
*				;;
STORECHARACTER 	EQU	*-PRG.STRT	;STORECHARACTER
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#CHECKSHORTREF,D7 	; CALL CHECKSHORTREF
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JP Z,STORESHORTREF
	BNE.S 	LAB.376 	;
	JMP 	STORESHORTREF(A5) 	;
LAB.376:
	JMP 	STORELONGREF(A5) 	; JP STORELONGREF
*				;;
*				;;-----
*				;;
*				;;HL is a long-form word-reference. It is appended to the
*				;;end of the current message descriptor.
*				;;
STORELONGREF 	EQU	*-PRG.STRT	;STORELONGREF
	ROR.W 	#8,D1 	; SET LONG,H ;Make it a long-form reference
	BSET 	D1,#LONG 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#CHECKBELOWBUFFER,D7 	; CALL CHECKBELOWBUFFER
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,MDTFULL
	BCS.S 	LAB.377 	;
	JMP 	MDTFULL(A5) 	;
LAB.377:
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D3 	; LD (HL),D
	MOVE.B 	D3,0(A5,D1.W) 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	D3,0(A5,D1.W) 	; LD (HL),E
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	CURRENTMDT(A5),A0 	; LD (CURRENTMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMLONGREFS(A5),A0 	; LD HL,(NUMLONGREFS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMLONGREFS(A5),A0 	; LD (NUMLONGREFS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;A is a short-form word-reference. It is appended to
*				;;the end ot the current message descriptor.
*				;;
STORESHORTREF 	EQU	*-PRG.STRT	;STORESHORTREF
	BCLR 	D0,#LONG 	; RES LONG,A ;Make it a short-form reference
	MOVE.B 	D0,D3 	; LD E,A
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#CHECKBELOWBUFFER,D7 	; CALL CHECKBELOWBUFFER
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,MDTFULL
	BCS.S 	LAB.378 	;
	JMP 	MDTFULL(A5) 	;
LAB.378:
	LEA 	CURRENTMDT(A5),A0 	; LD HL,(CURRENTMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	D3,0(A5,D1.W) 	; LD (HL),E
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	CURRENTMDT(A5),A0 	; LD (CURRENTMDT),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	NUMSHORTREFS(A5),A0 	; LD HL,(NUMSHORTREFS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMSHORTREFS(A5),A0 	; LD (NUMSHORTREFS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;'Message Descriptor Table' full
*				;;
MDTFULL 	EQU	*-PRG.STRT	;MDTFULL
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"'Message Descriptor Table' full" 	; DEFM "'Message Descriptor Table' full"
	DC.B 	0 	; DEFB 0
	JMP 	P6ERROR(A5) 	; JP P6ERROR ;Calls DISPLAYLINENUM and WARMSTART
*				;;
*				;;-----
*				;;
*				;;Long-to-Short word reference look-up ran of end of
*				;;Frequency Table
*				;;
SHORTOVERSHOOT 	EQU	*-PRG.STRT	;SHORTOVERSHOOT
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"SQUASH Error. " 	; DEFM "SQUASH Error. "
	DC.B 	"Short-reference address conversion failed." 	; DEFM "Short-reference address conversion failed."
	DC.B 	0 	; DEFB 0
	MOVE.W 	#ABORTSERIALSMT,D7 	; CALL ABORTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#ABORTSERIALICF,D7 	; CALL ABORTSERIALICF
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
*				;;Compare HL with the low address of the serial
*				;;Returns 'NC' if HL > (STARTBUFFER)
*				;;
CHECKBELOWBUFFER 	EQU	*-PRG.STRT	;CHECKBELOWBUFFER
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
INITSERIALSMT 	EQU	*-PRG.STRT	;INITSERIALSMT
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#MAXMESSAGELEN+256,D3 	; LD DE,MAXMESSAGELEN+256
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	STARTBUFFER(A5),A0 	; LD (STARTBUFFER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	LENGTHSMT(A5),A0 	; LD HL,(LENGTHSMT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	UNREADSIZE(A5),A0 	; LD (UNREADSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	BUFFERSIZE(A5),A0 	; LD (BUFFERSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Reading " 	; DEFM "Reading "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"..." 	; DEFM "..."
	DC.B 	ASCIICR,0 	; DEFB ASCIICR,0
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#TEMPFILE,D1 	; LD HL,TEMPFILE
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#OPENSERIALREAD,D7 	; CALL OPENSERIALREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,NS01 ;File OK
	BCS.S 	LAB.379 	;
	JMP 	NS01(A5) 	;
LAB.379:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"SQUASH error. Can't open " 	; DEFM "SQUASH error. Can't open "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
NEXTSERIALSMT 	EQU	*-PRG.STRT	;NEXTSERIALSMT
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	LEA 	UNREADSIZE(A5),A0 	; LD HL,(UNREADSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	UNREADSIZE(A5),A0 	; LD (UNREADSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD HL,(BUFFERSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD (BUFFERSIZE),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD BC,(BUFFERSIZE)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	JSR 	SYS.LDIR(A5) 	; LDIR 
NS01 	EQU	*-PRG.STRT	;NS01
	LEA 	BUFFERSIZE(A5),A0 	; LD HL,(BUFFERSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#MAXMESSAGELEN,D3 	; LD DE,MAXMESSAGELEN
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC ;Buffer contains enough bytes for longest message
	BCS.S 	LAB.380 	;
	JMP 	SYS.RET(A5) 	;
LAB.380:
	LEA 	UNREADSIZE(A5),A0 	; LD HL,(UNREADSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z ;Nothing left to read
	BNE.S 	LAB.381 	;
	JMP 	SYS.RET(A5) 	;
LAB.381:
*				;;
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	BUFFERSIZE(A5),A0 	; LD DE,(BUFFERSIZE)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADDQ.W 	#1,D3 	; INC DE
	LEA 	BUFFERSIZE(A5),A0 	; LD (BUFFERSIZE),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#SERIALREADBYTE,D7 	; CALL SERIALREADBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
*				;;
	MOVE 	F(A5),SR 	; JR NC,NS01 ;Not end of file
	BCS.S 	LAB.382 	;
	JMP 	NS01(A5) 	;
LAB.382:
	LEA 	BUFFERSIZE(A5),A0 	; LD HL,(BUFFERSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	UNREADSIZE(A5),A0 	; LD DE,(UNREADSIZE)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,NS01 ;Valid end of file
	BCS.S 	LAB.383 	;
	JMP 	NS01(A5) 	;
LAB.383:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"SQUASH error. Unexpected EOF in " 	; DEFM "SQUASH error. Unexpected EOF in "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#DISPLAYTEMPNAME,D7 	; CALL DISPLAYTEMPNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#ABORTSERIALSMT,D7 	; CALL ABORTSERIALSMT
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#ABORTSERIALICF,D7 	; CALL ABORTSERIALICF
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
ENDSERIALSMT 	EQU	*-PRG.STRT	;ENDSERIALSMT
	LEA 	UNREADSIZE(A5),A0 	; LD HL,(UNREADSIZE)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.384 	;
	JMP 	SYS.RET(A5) 	;
LAB.384:
	SUBQ.W 	#2,D6 	; PUSH AF ;Save 'NZ' condition
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; CALL Z,NEWLINE
	BNE.S 	LAB.385 	;
	MOVE.W 	#NEWLINE,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.385:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... eof" 	; DEFM "... eof"
	DC.B 	ASCIICR,0 	; DEFB ASCIICR,0
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF ;Return 'NZ'
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
ABORTSERIALSMT 	EQU	*-PRG.STRT	;ABORTSERIALSMT
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
	JMP 	DELETESYSTEM(A5) 	; JP DELETESYSTEM ;Delete B:SQUASH1.TMP
*				;;
*				;;-----
*				;;
NAMEICF 	EQU	*-PRG.STRT	;NAMEICF
	DC.B 	2 	; DEFB 2 ;Drive B:
	DC.B 	"SQUASH2 " 	; DEFM "SQUASH2 "
	DC.B 	"TMP" 	; DEFM "TMP"
*				;;
*				;;-----
*				;;
INITSERIALICF 	EQU	*-PRG.STRT	;INITSERIALICF
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Writing B:SQUASH2.TMP ..." 	; DEFM "Writing B:SQUASH2.TMP ..."
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	LENGTHICF(A5),A0 	; LD (LENGTHICF),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#NAMEICF,D1 	; LD HL,NAMEICF
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	MOVE.W 	#OPENSERIALWRITE,D7 	; CALL OPENSERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; RET NC ;Ok
	BCS.S 	LAB.386 	;
	JMP 	SYS.RET(A5) 	;
LAB.386:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Can't create: B:SQUASH2.TMP" 	; DEFM "Can't create: B:SQUASH2.TMP"
	DC.B 	0 	; DEFB 0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
WRITESERIALICF 	EQU	*-PRG.STRT	;WRITESERIALICF
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LENGTHICF(A5),A0 	; LD (LENGTHICF),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	MOVE.W 	#SERIALWRITEBYTE,D7 	; CALL SERIALWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET NC ;Ok
	BCS.S 	LAB.387 	;
	JMP 	SYS.RET(A5) 	;
LAB.387:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Error writing B:SQUASH2.TMP" 	; DEFM "Error writing B:SQUASH2.TMP"
	DC.B 	0 	; DEFB 0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
ENDSERIALICF 	EQU	*-PRG.STRT	;ENDSERIALICF
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... close" 	; DEFM "... close"
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	JMP 	CLOSESERIALWRITE(A5) 	; JP CLOSESERIALWRITE
*				;;
*				;;-----
*				;;
ABORTSERIALICF 	EQU	*-PRG.STRT	;ABORTSERIALICF
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	JMP 	DELETESYSTEM(A5) 	; JP DELETESYSTEM ;Delete B:SQUASH1.TMP
*				;;
*				;;-----
*				;;
*				;;Phase 7 - Construct 'Word Dictionary'
*				;;
*				;;Phase 7 Converts words from the 'Frequency Table' into
*				;;a bit-stream of 5,10 and 15 bit short-codes.
*				;;These are used to build the 'Word Dictionary'
*				;;at addresses (CURRENTMDT) thru (ENDMEMORY).
*				;;(ENDWD) holds the current top of the Dictionary.
*				;;
*				;;-----
*				;;
PHASE07 	EQU	*-PRG.STRT	;PHASE07
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 7 - Construct 'Word Dictionary'" 	; DEFM "Phase 7 - Construct 'Word Dictionary'"
	DC.B 	ASCIICR,0 	; DEFB ASCIICR,0
*				;;
*				;;* LD HL,(LENGTHICF)
*				;;* LD (LENGTHMD),HL
*				;;* LD BC,LENGTHPOINTERS
*				;;* ADD HL,BC
*				;;* LD (INDEXMD),HL
*				;;
*				;;Clear current segment:
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,SEGNUM(A5) 	; LD (SEGNUM),A
	MOVE.W 	#SEGMENTADDRESSES,D1 	; LD HL,SEGMENTADDRESSES
	LEA 	LASTPOINTER(A5),A0 	; LD (LASTPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Clear 'Previous Word Start' buffer.
*				;;
	MOVE.W 	#CLEARTHREE,D7 	; CALL CLEARTHREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#UNPACK1,D1 	; LD HL,UNPACK1
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	#ENDSEG,D0 	; LD A,ENDSEG
	MOVE.B 	D0,LASTBYTE(A5) 	; LD (LASTBYTE),A
*				;;
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	LEA 	STARTFT(A5),A0 	; LD HL,(STARTFT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
PG01 	EQU	*-PRG.STRT	;PG01
	MOVE.W 	#CHECKENDFT,D7 	; CALL CHECKENDFT
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP NC,PG10
	BCS.S 	LAB.388 	;
	JMP 	PG10(A5) 	;
LAB.388:
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#GETWORDTEXT,D7 	; CALL GETWORDTEXT
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	SUB.B 	#'a',D0 	; SUB 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JP C,PG09
	BCC.S 	LAB.389 	;
	JMP 	PG09(A5) 	;
LAB.389:
	CMP.B 	#26,D0 	; CP 26
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,PG03
	BCC.S 	LAB.390 	;
	JMP 	PG03(A5) 	;
LAB.390:
	MOVE.B 	#103,D0 	; LD A,103
	JMP 	PG05(A5) 	; JR PG05
PG03 	EQU	*-PRG.STRT	;PG03
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,D2 	; LD C,A
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	CMP.B 	#2,D0 	; CP 2
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D2,D0 	; LD A,C
	MOVE 	F(A5),SR 	; JR C,PG05 ;Less than 2 chars
	BCC.S 	LAB.391 	;
	JMP 	PG05(A5) 	;
LAB.391:
*				;;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL 
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	MOVE.W 	#LOWER,D7 	; CALL LOWER
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PG04
	BCS.S 	LAB.392 	;
	JMP 	PG04(A5) 	;
LAB.392:
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	JMP 	PG05(A5) 	; JR PG05
PG04 	EQU	*-PRG.STRT	;PG04
	SUB.B 	#'a',D0 	; SUB 'a'
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	LSR.B 	#1,D0 	; SRL A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$3,D0 	; AND $3
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; ADD A,B
	ADD.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
PG05 	EQU	*-PRG.STRT	;PG05
*				;;
	ADDQ.B 	#1,D0 	; INC A
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	SEGNUM(A5),D0 	; LD A,(SEGNUM)
	ROR.W 	#8,D2 	; CP B
	CMP.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE 	F(A5),SR 	; JR Z,PG09 ;(this segment)
	BNE.S 	LAB.393 	;
	JMP 	PG09(A5) 	;
LAB.393:
	MOVE 	F(A5),SR 	; JR NC,PG09 ;(previous segment)
	BCS.S 	LAB.394 	;
	JMP 	PG09(A5) 	;
LAB.394:
*				;;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
*				;;
	LEA 	LASTPOINTER(A5),A0 	; LD HL,(LASTPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#SEGMENTADDRESSES,D1 	; LD HL,SEGMENTADDRESSES
	MOVE.B 	#104,D0 	; LD A,104 ; = 26*4
	ROR.W 	#8,D3 	; LD D,0
	MOVE.B 	#0,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D0,D3 	; LD E,A
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PG08 ;Table full
	BNE.S 	LAB.395 	;
	JMP 	PG08(A5) 	;
LAB.395:
*				;;
	MOVE.B 	LASTBYTE(A5),D0 	; LD A,(LASTBYTE)
	CMP.B 	#ENDSEG,D0 	; CP ENDSEG
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PG07
	BNE.S 	LAB.396 	;
	JMP 	PG07(A5) 	;
LAB.396:
	MOVE.B 	#ENDSEG,D0 	; LD A,ENDSEG
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
PG07 	EQU	*-PRG.STRT	;PG07
	MOVE.W 	#BYTEALIGN,D7 	; CALL BYTEALIGN
	JSR 	SYS.JSR(A5) 	;
	LEA 	LASTPOINTER(A5),A0 	; LD HL,(LASTPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;
	LEA 	LENGTHICF(A5),A0 	; LD DE,(LENGTHICF)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#LENGTHPOINTERS,D1 	; LD HL,LENGTHPOINTERS
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.B 	D3,0(A5,D1.W) 	; LD (HL),E
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD (HL),D
	MOVE.B 	D3,0(A5,D1.W) 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	WORDNUMBER(A5),A0 	; LD DE,(WORDNUMBER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	SUBQ.W 	#1,D3 	; DEC DE
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.B 	D3,0(A5,D1.W) 	; LD (HL),E
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD (HL),D
	MOVE.B 	D3,0(A5,D1.W) 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	LASTPOINTER(A5),A0 	; LD (LASTPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
PG08 	EQU	*-PRG.STRT	;PG08
	MOVE.B 	SEGNUM(A5),D0 	; LD A,(SEGNUM)
	ADDQ.B 	#1,D0 	; INC A
	MOVE.B 	D0,SEGNUM(A5) 	; LD (SEGNUM),A
*				;;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	PG01(A5) 	; JP PG01
PG09 	EQU	*-PRG.STRT	;PG09
*				;;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#CONVERTWORD,D7 	; CALL CONVERTWORD
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Move on to next word
*				;;
	LEA 	WORDNUMBER(A5),A0 	; LD HL,(WORDNUMBER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	WORDNUMBER(A5),A0 	; LD (WORDNUMBER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	JMP 	PG01(A5) 	; JP PG01
*				;;
*				;;Extend table so it ends on a byte-boundary
*				;;
PG10 	EQU	*-PRG.STRT	;PG10
	MOVE.B 	LASTBYTE(A5),D0 	; LD A,(LASTBYTE)
	CMP.B 	#ENDSEG,D0 	; CP ENDSEG
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PG11 
	BNE.S 	LAB.397 	;
	JMP 	PG11(A5) 	;
LAB.397:
	MOVE.B 	#ENDSEG,D0 	; LD A,ENDSEG ;Terminate final word
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
PG11 	EQU	*-PRG.STRT	;PG11
	MOVE.W 	#BYTEALIGN,D7 	; CALL BYTEALIGN
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Calculate offset into SQUASH file end
*				;;and length of Word Dictionary.
*				;;
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS,D2 	; LD BC,LENGTHPOINTERS
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	INDEXWD(A5),A0 	; LD (INDEXWD),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	INDEXMD(A5),A0 	; LD DE,(INDEXMD)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	LEA 	LENGTHWD(A5),A0 	; LD (LENGTHWD),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;(Optional) Display length of table
*				;;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.398 	;
	JMP 	SYS.RET(A5) 	;
LAB.398:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Length of 'Word Dictionary' =" 	; DEFM "Length of 'Word Dictionary' ="
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHWD(A5),A0 	; LD HL,(LENGTHWD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
	JMP 	NEWLINE(A5) 	; JP NEWLINE
*				;;
*				;;-----
*				;;
CLEARTHREE 	EQU	*-PRG.STRT	;CLEARTHREE
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,THREECHARACTERS(A5) 	; LD (THREECHARACTERS),A
	MOVE.B 	D0,THREECHARACTERS+1(A5) 	; LD (THREECHARACTERS+1),A
	MOVE.B 	D0,THREECHARACTERS+2(A5) 	; LD (THREECHARACTERS+2),A
	MOVE.B 	D0,THREECHARACTERS+3(A5) 	; LD (THREECHARACTERS+3),A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Clear current UNPACK buffer (which must end in an ENDSEG code)
*				;;and re-align ENDWD to the byte following the byte containing
*				;;the last bit of the ENDSEG code.
*				;;
*				;;Also clears THREECHARACTERS to force $1C header type next.
*				;;
BYTEALIGN 	EQU	*-PRG.STRT	;BYTEALIGN
	MOVE.W 	#CLEARTHREE,D7 	; CALL CLEARTHREE
	JSR 	SYS.JSR(A5) 	;
BA01 	EQU	*-PRG.STRT	;BA01
	LEA 	READWRITEPOINTER(A5),A0 	; LD HL,(READWRITEPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#UNPACK1,D3 	; LD DE,UNPACK1
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.399 	;
	JMP 	SYS.RET(A5) 	;
LAB.399:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#DOCONVERSION,D7 	; CALL DOCONVERSION
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D1,D0 	; LD A,L
	CMP.B 	#1,D0 	; CP 1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA07
	BNE.S 	LAB.400 	;
	JMP 	BA07(A5) 	;
LAB.400:
	CMP.B 	#2,D0 	; CP 2
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA07
	BNE.S 	LAB.401 	;
	JMP 	BA07(A5) 	;
LAB.401:
	CMP.B 	#3,D0 	; CP 3
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA02
	BNE.S 	LAB.402 	;
	JMP 	BA02(A5) 	;
LAB.402:
	CMP.B 	#4,D0 	; CP 4
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA03
	BNE.S 	LAB.403 	;
	JMP 	BA03(A5) 	;
LAB.403:
	CMP.B 	#5,D0 	; CP 5
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA04
	BNE.S 	LAB.404 	;
	JMP 	BA04(A5) 	;
LAB.404:
	CMP.B 	#6,D0 	; CP 6
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA05
	BNE.S 	LAB.405 	;
	JMP 	BA05(A5) 	;
LAB.405:
	CMP.B 	#7,D0 	; CP 7
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,BA06
	BNE.S 	LAB.406 	;
	JMP 	BA06(A5) 	;
LAB.406:
	MOVE.W 	#BREAK,D7 	; CALL BREAK
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"byte-align error" 	; DEFM "byte-align error"
	DC.B 	0 	; DEFB 0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
BA02 	EQU	*-PRG.STRT	;BA02
	MOVE.B 	#2,D0 	; LD A,2
	JMP 	BA07(A5) 	; JR BA07
BA03 	EQU	*-PRG.STRT	;BA03
	MOVE.B 	#3,D0 	; LD A,3
	JMP 	BA07(A5) 	; JR BA07
BA04 	EQU	*-PRG.STRT	;BA04
	MOVE.B 	#4,D0 	; LD A,4
	JMP 	BA07(A5) 	; JR BA07
BA05 	EQU	*-PRG.STRT	;BA05
	MOVE.B 	#4,D0 	; LD A,4
	JMP 	BA07(A5) 	; JR BA07
BA06 	EQU	*-PRG.STRT	;BA06
	MOVE.B 	#5,D0 	; LD A,5
	JMP 	BA07(A5) 	; JR BA07
BA07 	EQU	*-PRG.STRT	;BA07
*				;;
*				;;A holds the number of bytes of 'PACK'ed data
*				;;to be written to dictionary
*				;;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#PACK1,D1 	; LD HL,PACK1
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
BA08 	EQU	*-PRG.STRT	;BA08
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#BA08,D7 	; DJNZ BA08
	JSR 	SYS.DJNZ(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.W 	#UNPACK1,D1 	; LD HL,UNPACK1
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Change one 'Frequency Table' entry to a
*				;;'Word Dictionary' entry. HL is the address of
*				;;the 'Frequency Table' entry.
*				;;
CONVERTWORD 	EQU	*-PRG.STRT	;CONVERTWORD
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#GETWORDTEXT,D7 	; CALL GETWORDTEXT
	JSR 	SYS.JSR(A5) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,WORDCASE(A5) 	; LD (WORDCASE),A
	MOVE.B 	D0,D2 	; LD C,A ;=0 Number of characters the same
	MOVE.W 	#THREECHARACTERS,D3 	; LD DE,THREECHARACTERS
CW01 	EQU	*-PRG.STRT	;CW01
	MOVE.B 	D2,D0 	; LD A,C ;Don't exceed header length
	CMP.B 	#MAXHEADERLENGTH,D0 	; CP MAXHEADERLENGTH
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW02
	BNE.S 	LAB.407 	;
	JMP 	CW02(A5) 	;
LAB.407:
	ROR.W 	#8,D2 	; LD A,B ;End of word
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW02
	BNE.S 	LAB.408 	;
	JMP 	CW02(A5) 	;
LAB.408:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	CMP.B 	0(A5,D1.W),D0 	; CP (HL)
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,CW02 ;End of similarity
	BEQ.S 	LAB.409 	;
	JMP 	CW02(A5) 	;
LAB.409:
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	SUB.W 	#$100,D2 	; DEC B
	ADDQ.B 	#1,D2 	; INC C
	JMP 	CW01(A5) 	; JR CW01
*				;;
*				;;Save Word header (111xx, xx is number of characters
*				;;same as previous word.)
*				;;
CW02 	EQU	*-PRG.STRT	;CW02
	MOVE.B 	D2,D0 	; LD A,C
	AND.B 	#$3,D0 	; AND $3 ;Number of similar chars
	MOVE 	SR,F(A5) 	;
	OR.B 	#HEADER,D0 	; OR HEADER ;Word header
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.W 	#CLEARTHREE,D7 	; CALL CLEARTHREE
	JSR 	SYS.JSR(A5) 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC ;C=Number of characters the same
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#GETWORDTEXT,D7 	; CALL GETWORDTEXT
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#THREECHARACTERS,D3 	; LD DE,THREECHARACTERS
	MOVE.B 	#MAXHEADERLENGTH,D2 	; LD C,MAXHEADERLENGTH ;Copy three characters
CW03 	EQU	*-PRG.STRT	;CW03
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW04
	BNE.S 	LAB.410 	;
	JMP 	CW04(A5) 	;
LAB.410:
	MOVE.B 	D2,D0 	; LD A,C
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW04
	BNE.S 	LAB.411 	;
	JMP 	CW04(A5) 	;
LAB.411:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	ADDQ.W 	#1,D3 	; INC DE
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	SUBQ.B 	#1,D2 	; DEC C
	JMP 	CW03(A5) 	; JR CW03
CW04 	EQU	*-PRG.STRT	;CW04 
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Save word itself
*				;;
	MOVE.W 	#GETWORDTEXT,D7 	; CALL GETWORDTEXT
	JSR 	SYS.JSR(A5) 	;
CW05 	EQU	*-PRG.STRT	;CW05
	MOVE.B 	D2,D0 	; LD A,C
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW06
	BNE.S 	LAB.412 	;
	JMP 	CW06(A5) 	;
LAB.412:
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	SUBQ.B 	#1,D2 	; DEC C
	JMP 	CW05(A5) 	; JR CW05
CW06 	EQU	*-PRG.STRT	;CW06
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.413 	;
	JMP 	SYS.RET(A5) 	;
LAB.413:
*				;;
*				;;If remainder of word contains upper case chars but no lower case
*				;;then put in an upper-case-word marker.
*				;;
	MOVE.B 	WORDCASE(A5),D0 	; LD A,(WORDCASE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,CW06A
	BEQ.S 	LAB.414 	;
	JMP 	CW06A(A5) 	;
LAB.414:
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD C,B
	MOVE.B 	D2,D7 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D7,D2 	;
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#UPPERCASEWORD,D7 	; CALL UPPERCASEWORD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,WORDCASE(A5) 	; LD (WORDCASE),A
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW06A
	BNE.S 	LAB.415 	;
	JMP 	CW06A(A5) 	;
LAB.415:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	#LONGC,D0 	; LD A,LONGC
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#UPPERCASEMARK,D0 	; LD A,UPPERCASEMARK
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
CW06A 	EQU	*-PRG.STRT	;CW06A
*				;;
*				;;If character is preceeded by '/' it cannot be
*				;;character so it must be a short-escape or long-escape code.
*				;;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BTST 	D0,#7 	; BIT 7,A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CW08 ;Normal char
	BNE.S 	LAB.416 	;
	JMP 	CW08(A5) 	;
LAB.416:
*				;;
*				;;Not an auto-case alpha so do an escape sequence
*				;;
CW07 	EQU	*-PRG.STRT	;CW07 
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	BCLR 	D0,#7 	; RES 7,A
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
*				;;
*				;;Long escape sequence
*				;;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	#LONGC,D0 	; LD A,LONGC ;Long character escape code
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$07,D0 	; AND $07
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	AND.B 	#$1F,D0 	; AND $1F
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	CW09(A5) 	; JR CW09
*				;;
*				;;Not escaped, so if lower-case alpha it can be
*				;;represented as a 5-bit short-code, Otherwise use 
*				;;either a 10-bit short-escape or
*				;;15-bit long-escape code.
*				;;
CW08 	EQU	*-PRG.STRT	;CW08
	MOVE.B 	WORDCASE(A5),D0 	; LD A,(WORDCASE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE 	F(A5),SR 	; CALL NZ,LOWER ;Called if upper-case-only marker used
	BEQ.S 	LAB.417 	;
	MOVE.W 	#LOWER,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.417:
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,CW07
	BCC.S 	LAB.418 	;
	JMP 	CW07(A5) 	;
LAB.418:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,CW07
	BCS.S 	LAB.419 	;
	JMP 	CW07(A5) 	;
LAB.419:
	SUB.B 	#'a',D0 	; SUB 'a' ;Gives 00000 thru 11001 for 'a' thru 'z'
	MOVE 	SR,F(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#STOREWORDDICTIONARY,D7 	; CALL STOREWORDDICTIONARY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;
*				;;Move on to next character of word in Frequency Table.
*				;;
CW09 	EQU	*-PRG.STRT	;CW09
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	JMP 	CW06(A5) 	; JR CW06
*				;;
*				;;-----
*				;;
*				;;HL is address within Frequency table of a word or part
*				;;or a word, BC is number of chars in remainder
*				;;Returns A non-zero if word is suitable for an
*				;;upper-case-only marker.
UPPERCASEWORD 	EQU	*-PRG.STRT	;UPPERCASEWORD
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	#0,D3 	; LD E,0 ;Count of upper-case chars
UC01 	EQU	*-PRG.STRT	;UC01
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,UC04
	BNE.S 	LAB.420 	;
	JMP 	UC04(A5) 	;
LAB.420:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,UC02
	BCC.S 	LAB.421 	;
	JMP 	UC02(A5) 	;
LAB.421:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,UC05 ;Contains lower-case
	BCC.S 	LAB.422 	;
	JMP 	UC05(A5) 	;
LAB.422:
UC02 	EQU	*-PRG.STRT	;UC02
	CMP.B 	#'A',D0 	; CP 'A'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,UC03
	BCC.S 	LAB.423 	;
	JMP 	UC03(A5) 	;
LAB.423:
	CMP.B 	#'Z'+1,D0 	; CP 'Z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,UC03
	BCS.S 	LAB.424 	;
	JMP 	UC03(A5) 	;
LAB.424:
	ADDQ.B 	#1,D3 	; INC E ;Count of upper-case chars
UC03 	EQU	*-PRG.STRT	;UC03
	ADDQ.W 	#1,D1 	; INC HL
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	UC01(A5) 	; JR UC01
*				;;Found end of word with no lower-case, Check than
*				;;word contains enough upper-case
UC04 	EQU	*-PRG.STRT	;UC04
	MOVE.B 	D3,D0 	; LD A,E
	CMP.B 	#2,D0 	; CP 2
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,UC05
	BCC.S 	LAB.425 	;
	JMP 	UC05(A5) 	;
LAB.425:
*				;;
*				;;Can be upper-case marked
	MOVE.B 	#1,D0 	; LD A,1
	JMP 	UC06(A5) 	; JR UC06
*				;;
*				;;Can't be upper-case-only marked
UC05 	EQU	*-PRG.STRT	;UC05
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
*				;;
UC06 	EQU	*-PRG.STRT	;UC06
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
GETWORDTEXT 	EQU	*-PRG.STRT	;GETWORDTEXT
	ROR.W 	#8,D2 	; LD B,(HL) ;Entries length
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B
	SUB.W 	#$100,D2 	; DEC B
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
STOREWORDDICTIONARY 	EQU	*-PRG.STRT	;STOREWORDDICTIONARY
	MOVE.B 	D0,LASTBYTE(A5) 	; LD (LASTBYTE),A
	LEA 	READWRITEPOINTER(A5),A0 	; LD HL,(READWRITEPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#UNPACK1+8,D3 	; LD DE,UNPACK1+8
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.426 	;
	JMP 	SYS.RET(A5) 	;
LAB.426:
	MOVE.W 	#UNPACK1,D1 	; LD HL,UNPACK1
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Convert 8 short-codes to 5 bytes
*				;;
	MOVE.W 	#DOCONVERSION,D7 	; CALL DOCONVERSION
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Store all 5 bytes of 'PACK'ed buffer
*				;;
	MOVE.W 	#PACK1,D1 	; LD HL,PACK1
	ROR.W 	#8,D2 	; LD B,5
	MOVE.B 	#5,D2 	;
	ROR.W 	#8,D2 	;
SD01 	EQU	*-PRG.STRT	;SD01
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#SD01,D7 	; DJNZ SD01
	JSR 	SYS.DJNZ(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;
*				;;Convert block of 8 short-codes to 5 bytes.
*				;;
DOCONVERSION 	EQU	*-PRG.STRT	;DOCONVERSION
	MOVE.B 	UNPACK1(A5),D0 	; LD A,(UNPACK1) ;000aaaaa
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$F8,D0 	; AND $F8
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A ;aaaaa000
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK2(A5),D0 	; LD A,(UNPACK2) ;000bbbbb
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$07,D0 	; AND $07 ;00000bbb
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
*				;;Store aaaaabbb
	MOVE.B 	D0,PACK1(A5) 	; LD (PACK1),A
	MOVE.B 	UNPACK2(A5),D0 	; LD A,(UNPACK2) ;000bbbbb
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$C0,D0 	; AND $C0
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A ;bb000000
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK3(A5),D0 	; LD A,(UNPACK3) ;000ccccc
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$3E,D0 	; AND $3E ;00ccccc0 
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK4(A5),D0 	; LD A,(UNPACK4) ;000ddddd
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1,D0 	; AND $1 ;0000000d
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
*				;;Store bbcccccd
	MOVE.B 	D0,PACK2(A5) 	; LD (PACK2),A
	MOVE.B 	UNPACK4(A5),D0 	; LD A,(UNPACK4) ;000ddddd
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$F0,D0 	; AND $F0
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A ;dddd0000
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK5(A5),D0 	; LD A,(UNPACK5) ;000eeeee
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$0F,D0 	; AND $0F ;0000eeee
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
*				;;Store ddddeeee
	MOVE.B 	D0,PACK3(A5) 	; LD (PACK3),A
	MOVE.B 	UNPACK5(A5),D0 	; LD A,(UNPACK5) ;000eeeee
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$80,D0 	; AND $80 ;e0000000
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK6(A5),D0 	; LD A,(UNPACK6) ;000fffff
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$7C,D0 	; AND $7C ;0fffff00
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK7(A5),D0 	; LD A,(UNPACK7) ;000ggggg
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$03,D0 	; AND $03 ;000000gg
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
*				;;Store efffffgg
	MOVE.B 	D0,PACK4(A5) 	; LD (PACK4),A
	MOVE.B 	UNPACK7(A5),D0 	; LD A,(UNPACK7) ;000ggggg
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$E0,D0 	; AND $E0
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A ;ggg00000
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	UNPACK8(A5),D0 	; LD A,(UNPACK8) ;000hhhhh
	AND.B 	#$1F,D0 	; AND $1F ;000hhhhh
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
*				;;Store ggghhhhh
	MOVE.B 	D0,PACK5(A5) 	; LD (PACK5),A
*				;;
*				;;(PACK1) thru (PACK5) contain 5 bytes
*				;;packed short-codes.
*				;;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;
*				;;-----
*				;;
*				;;Unpack and Return bytes from Word Dictionary
*				;;
GETDICTIONARYCODE 	EQU	*-PRG.STRT	;GETDICTIONARYCODE
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	LEA 	READWRITEPOINTER(A5),A0 	; LD HL,(READWRITEPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#UNPACK1+8,D3 	; LD DE,UNPACK1+8
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; CALL Z,RD01
	BNE.S 	LAB.427 	;
	MOVE.W 	#RD01,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.427:
	LEA 	READWRITEPOINTER(A5),A0 	; LD HL,(READWRITEPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
RD01 	EQU	*-PRG.STRT	;RD01
	MOVE.W 	#UNPACK1,D1 	; LD HL,UNPACK1
	LEA 	READWRITEPOINTER(A5),A0 	; LD (READWRITEPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	LEA 	BLOCKPOINTER(A5),A0 	; LD HL,(BLOCKPOINTER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#5,D2 	; LD BC,5
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	BLOCKPOINTER(A5),A0 	; LD (BLOCKPOINTER),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#PACK1,D3 	; LD DE,PACK1
	MOVE.W 	#5,D2 	; LD BC,5
	JSR 	SYS.LDIR(A5) 	; LDIR 
*				;;
	MOVE.B 	PACK1(A5),D0 	; LD A,(PACK1) ;aaaaabbb
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1F,D0 	; AND $1F
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,UNPACK1(A5) 	; LD (UNPACK1),A ;000aaaaa
*				;;
	MOVE.B 	PACK1(A5),D0 	; LD A,(PACK1) ;aaaaabbb
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1C,D0 	; AND $1C
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	PACK2(A5),D0 	; LD A,(PACK2) ;bbcccccd
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$3,D0 	; AND $3
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,UNPACK2(A5) 	; LD (UNPACK2),A ;000bbbbb
*				;;
	MOVE.B 	PACK2(A5),D0 	; LD A,(PACK2) ;bbcccccd
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1F,D0 	; AND $1F
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,UNPACK3(A5) 	; LD (UNPACK3),A ;000ccccc
*				;;
	MOVE.B 	PACK2(A5),D0 	; LD A,(PACK2) ;bbcccccd
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$10,D0 	; AND $10
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	PACK3(A5),D0 	; LD A,(PACK3) ;ddddeeee
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$0F,D0 	; AND $0F
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,UNPACK4(A5) 	; LD (UNPACK4),A ;000ddddd
*				;;
	MOVE.B 	PACK3(A5),D0 	; LD A,(PACK3) ;ddddeeee
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1E,D0 	; AND $1E
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	PACK4(A5),D0 	; LD A,(PACK4) ;efffffgg
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1,D0 	; AND $1
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,UNPACK5(A5) 	; LD (UNPACK5),A ;000eeeee
*				;;
	MOVE.B 	PACK4(A5),D0 	; LD A,(PACK4) ;efffffgg
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$1F,D0 	; AND $1F
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,UNPACK6(A5) 	; LD (UNPACK6),A ;0000fffff
*				;;
	MOVE.B 	PACK4(A5),D0 	; LD A,(PACK4) ;efffffgg
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	ADD.B 	D0,D0 	; ADD A,A
	MOVE 	SR,F(A5) 	;
	AND.B 	#$18,D0 	; AND $18
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	PACK5(A5),D0 	; LD A,(PACK5) ;ggghhhhh
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	ROR.B 	#1,D0 	; RRCA 
	MOVE 	SR,F(A5) 	;
	AND.B 	#$07,D0 	; AND $07
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; OR B
	OR.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,UNPACK7(A5) 	; LD (UNPACK7),A ;000ggggg
*				;;
	MOVE.B 	PACK5(A5),D0 	; LD A,(PACK5) ;ggghhhhh
	AND.B 	#$1F,D0 	; AND $1F
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,UNPACK8(A5) 	; LD (UNPACK8),A ;000hhhhh
*				;;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;'Word Dictionary' larger than
*				;;'Sorted Message Table'.
*				;;
WDFULL 	EQU	*-PRG.STRT	;WDFULL
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"'Word Dictionary' full." 	; DEFM "'Word Dictionary' full."
	DC.B 	0 	; DEFB 0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
*				;;Phase 8 - Construct 'Word Dictionary Index'
*				;;
*				;;Reads the SEGMENTADDRESSES table built by the
*				;;'Construct Word Dictionary' phase and builds the 'Word
*				;;Dictionary Index' between addresses (STARTWDI) and (ENDMEMORY)
*				;;
*				;;The current top of this table is (ENDWDI).
*				;;
*				;;-----
*				;;
PHASE08 	EQU	*-PRG.STRT	;PHASE08
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 8 - Construct 'Word Dictionary Index'" 	; DEFM "Phase 8 - Construct 'Word Dictionary Index'"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0 
*				;;
*				;;Clear table
*				;;
	MOVE.W 	#0,D1 	; LD HL,0
	LEA 	NUMSEGS(A5),A0 	; LD (NUMSEGS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Copy each entry from SEGMENTADDRESSES subtracting start
*				;;address of 'Word Dictionary' to give offset.
*				;;
	MOVE.W 	#SEGMENTADDRESSES,D1 	; LD HL,SEGMENTADDRESSES
PH01 	EQU	*-PRG.STRT	;PH01
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	LASTPOINTER(A5),A0 	; LD DE,(LASTPOINTER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,PH02
	BNE.S 	LAB.428 	;
	JMP 	PH02(A5) 	;
LAB.428:
*				;;
*				;;Get address of byte-aligned boundary
*				;;
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ADDQ.W 	#1,D1 	; INC HL
*				;;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
*				;;
*				;;Store offset
*				;;
	MOVE.B 	D3,D0 	; LD A,E
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D2,D0 	; LD A,C
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	NUMSEGS(A5),A0 	; LD HL,(NUMSEGS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	NUMSEGS(A5),A0 	; LD (NUMSEGS),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
*				;;Move on to next entry
*				;;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	PH01(A5) 	; JR PH01
*				;;
*				;;(Optional) Display length of table
*				;;
PH02 	EQU	*-PRG.STRT	;PH02
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS,D2 	; LD BC,LENGTHPOINTERS
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
	LEA 	INDEXWDI(A5),A0 	; LD (INDEXWDI),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
*				;;
	MOVE.B 	NOISY(A5),D0 	; LD A,(NOISY)
	CMP.B 	#'Y',D0 	; CP 'Y'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.429 	;
	JMP 	SYS.RET(A5) 	;
LAB.429:
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Length of 'Word Dictionary Index' =" 	; DEFM "Length of 'Word Dictionary Index' ="
	DC.B 	0 	; DEFB 0
	LEA 	INDEXWDI(A5),A0 	; LD HL,(INDEXWDI)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	INDEXWD(A5),A0 	; LD DE,(INDEXWD)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0
*				;;
*				;;Option to display Segment Table Index removed:
*				;;too difficult when writing SQUASH file 'on-the-fly'
*				;;Original listing not usefull anyway.
*				;;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Phase 9 - Build Squash File
*				;;
*				;;Move 'Common Word Index' to be above 'Dictionary Index'
*				;;then build the 'Squash' file and save it.
*				;;
*				;;-----
*				;;
PHASE09 	EQU	*-PRG.STRT	;PHASE09
	MOVE.W 	#TRACE,D7 	; CALL TRACE
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Phase 9 - Build Squash File" 	; DEFM "Phase 9 - Build Squash File"
	DC.B 	ASCIICR,ASCIICR,0 	; DEFB ASCIICR,ASCIICR,0 
*				;;
*				;;Save CWT to ICF
*				;;
	LEA 	STARTCWT(A5),A0 	; LD HL,(STARTCWT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
PI01 	EQU	*-PRG.STRT	;PI01
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	ENDCWT(A5),A0 	; LD DE,(ENDCWT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,PI02
	BNE.S 	LAB.430 	;
	JMP 	PI02(A5) 	;
LAB.430:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#WRITESERIALICF,D7 	; CALL WRITESERIALICF
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	PI01(A5) 	; JR PI01
*				;;
PI02 	EQU	*-PRG.STRT	;PI02
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;
*				;;Close B:SQUASH2.TMP (ICF)
*				;;
	MOVE.W 	#ENDSERIALICF,D7 	; CALL ENDSERIALICF
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#$D,D0 	; LD A,$D
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Reading B:SQUASH2.TMP ..." 	; DEFM "Reading B:SQUASH2.TMP ..."
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NAMEICF,D1 	; LD HL,NAMEICF
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#OPENSERIALREAD,D7 	; CALL OPENSERIALREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PI03
	BCS.S 	LAB.431 	;
	JMP 	PI03(A5) 	;
LAB.431:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Can't read B:SQUASH2.TMP" 	; DEFM "Can't read B:SQUASH2.TMP"
	DC.B 	$D,0 	; DEFB $D,0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
PI03 	EQU	*-PRG.STRT	;PI03
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,FINALCHECKSUM(A5) 	; LD (FINALCHECKSUM),A
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Writing B:SQUASH.DAT ..." 	; DEFM "Writing B:SQUASH.DAT ..."
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#CLEARFCB,D7 	; CALL CLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#OUTPUT,D1 	; LD HL,OUTPUT
	MOVE.W 	#SYSTEMFCBDRIVE,D3 	; LD DE,SYSTEMFCBDRIVE
	MOVE.W 	#12,D2 	; LD BC,12
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	MOVE.W 	#OPENSERIALWRITE,D7 	; CALL OPENSERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PI04
	BCS.S 	LAB.432 	;
	JMP 	PI04(A5) 	;
LAB.432:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Can't create B:SQUASH.DAT" 	; DEFM "Can't create B:SQUASH.DAT"
	DC.B 	$D,0 	; DEFB $D,0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
PI04 	EQU	*-PRG.STRT	;PI04
*				;;
*				;;Write Header/Pointers:
*				;;
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS+1,D3 	; LD DE,LENGTHPOINTERS+1 ;Include header+checksum
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
*				;;HL = Length of file
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#LENGTHPOINTERS,D1 	; LD HL,LENGTHPOINTERS
*				;;HL = Offset to Message Descriptors
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	LENGTHMD(A5),A0 	; LD HL,(LENGTHMD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;HL = Length of Message Descriptors
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	INDEXMD(A5),A0 	; LD HL,(INDEXMD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;HL = Offset to Word Dictionary
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	LENGTHWD(A5),A0 	; LD HL,(LENGTHWD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;HL = Length of Word Dictionary
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	INDEXWD(A5),A0 	; LD HL,(INDEXWD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;HL = Offset to Dictionary Index
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	NUMSEGS(A5),A0 	; LD BC,(NUMSEGS)
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
*				;;BC = Number of Segments
	MOVE.B 	D2,D0 	; LD A,C
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	LEA 	INDEXWDI(A5),A0 	; LD HL,(INDEXWDI)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
*				;;HL = Offset to Common Word Index
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	#MINOR,D0 	; LD A,MINOR
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH ;Version number
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#MAJOR,D0 	; LD A,MAJOR
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Copy ICF file to Squash file
*				;;
	LEA 	LENGTHICF(A5),A0 	; LD BC,(LENGTHICF) ;Number of bytes to copy
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
PI05 	EQU	*-PRG.STRT	;PI05
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PI07
	BNE.S 	LAB.433 	;
	JMP 	PI07(A5) 	;
LAB.433:
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#SERIALREADBYTE,D7 	; CALL SERIALREADBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,PI06 ;Ok
	BCS.S 	LAB.434 	;
	JMP 	PI06(A5) 	;
LAB.434:
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	$D 	; DEFB $D
	DC.B 	"Unexpected EOF on B:SQUASH2.TMP" 	; DEFM "Unexpected EOF on B:SQUASH2.TMP"
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1 ;Input File Control Block
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM ;Delete B:SQUASH2.TMP
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;Output File Control Block
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM ;Delete B:SQUASH.DAT
	JSR 	SYS.JSR(A5) 	;
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
PI06 	EQU	*-PRG.STRT	;PI06
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	PI05(A5) 	; JR PI05
PI07 	EQU	*-PRG.STRT	;PI07
*				;;
*				;;Write checksum
*				;;
	MOVE.B 	FINALCHECKSUM(A5),D0 	; LD A,(FINALCHECKSUM)
	NEG.B 	D0 	; NEG 
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;(Optional) Pad file to be a multiple of 256 bytes long
*				;;
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS+1,D3 	; LD DE,LENGTHPOINTERS+1
	ADD.W 	D3,D1 	; ADD HL,DE ;Bytes written so far
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D1,D0 	; LD A,L
PI08 	EQU	*-PRG.STRT	;PI08
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PI09
	BNE.S 	LAB.435 	;
	JMP 	PI09(A5) 	;
LAB.435:
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#WRITESQUASH,D7 	; CALL WRITESQUASH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	ADDQ.B 	#1,D0 	; INC A
	JMP 	PI08(A5) 	; JR PI08
*				;;
*				;;Close all files
*				;;
PI09 	EQU	*-PRG.STRT	;PI09
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... close" 	; DEFM "... close"
	DC.B 	$D,0 	; DEFB $D,0
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2
	MOVE.W 	#CLOSESERIALWRITE,D7 	; CALL CLOSESERIALWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"... eof" 	; DEFM "... eof"
	DC.B 	$D,$D,0 	; DEFB $D,$D,0
	MOVE.W 	#FCB1,D1 	; LD HL,FCB1
	MOVE.W 	#CLOSESERIALREAD,D7 	; CALL CLOSESERIALREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM ;Delete B:SQUASH2.TMP
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;Print Statistics
*				;;
	MOVE.W 	#DISPLAYINPUTNAME,D7 	; CALL DISPLAYINPUTNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"file length =" 	; DEFM "file length ="
	DC.B 	0 	; DEFB 0
	LEA 	INPUTLENGTH(A5),A0 	; LD HL,(INPUTLENGTH)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR 	; DEFB ASCIICR
	DC.B 	"Number of characters = " 	; DEFM "Number of characters = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMCHARACTERS(A5),A0 	; LD HL,(NUMCHARACTERS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	". Number of words = " 	; DEFM ". Number of words = "
	DC.B 	0 	; DEFB 0
	LEA 	NUMWORDS(A5),A0 	; LD HL,(NUMWORDS)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	'.',ASCIICR 	; DEFB '.',ASCIICR
	DC.B 	"Low memory used  =" 	; DEFM "Low memory used  ="
	DC.B 	0 	; DEFB 0
	LEA 	MAXMDT(A5),A0 	; LD HL,(MAXMDT)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTFT(A5),A0 	; LD DE,(STARTFT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	$D 	; DEFB $D
	DC.B 	"High memory used =" 	; DEFM "High memory used ="
	DC.B 	0 	; DEFB 0
	LEA 	ENDMEMORY(A5),A0 	; LD HL,(ENDMEMORY)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	STARTBUFFER(A5),A0 	; LD DE,(STARTBUFFER)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	" Free =" 	; DEFM " Free ="
	DC.B 	0 	; DEFB 0
	LEA 	STARTBUFFER(A5),A0 	; LD HL,(STARTBUFFER)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	LEA 	MAXMDT(A5),A0 	; LD DE,(MAXMDT)
	MOVE.B 	1(A0),D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	(A0),D3 	;
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#DISPLAYOUTPUTNAME,D7 	; CALL DISPLAYOUTPUTNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"file length =" 	; DEFM "file length ="
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS+1,D3 	; LD DE,LENGTHPOINTERS+1
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Compressed size of message descriptors = " 	; DEFM "Compressed size of message descriptors = "
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHMD(A5),A0 	; LD HL,(LENGTHMD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Compressed size of word dictionary     = " 	; DEFM "Compressed size of word dictionary     = "
	DC.B 	0 	; DEFB 0
	LEA 	LENGTHWD(A5),A0 	; LD HL,(LENGTHWD)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#DISPLAYBYTESFREE,D7 	; CALL DISPLAYBYTESFREE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#NEWLINE,D7 	; CALL NEWLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	"Compression = " 	; DEFM "Compression = "
	DC.B 	0 	; DEFB 0
	MOVE.W 	#CALCCOMPRESSION,D7 	; CALL CALCCOMPRESSION
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DISPLAYDECIMAL,D7 	; CALL DISPLAYDECIMAL
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	'%',ASCIICR,0 	; DEFB '%',ASCIICR,0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
WRITESQUASH 	EQU	*-PRG.STRT	;WRITESQUASH
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	D0,D1 	; LD L,A
	MOVE.B 	FINALCHECKSUM(A5),D0 	; LD A,(FINALCHECKSUM)
	ADD.B 	D1,D0 	; ADD A,L
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,FINALCHECKSUM(A5) 	; LD (FINALCHECKSUM),A
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
*				;;
	MOVE.W 	#FCB2,D1 	; LD HL,FCB2 ;File output Control Block
	MOVE.W 	#SERIALWRITEBYTE,D7 	; CALL SERIALWRITEBYTE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JP C,WRITESQUASH01
	BCC.S 	LAB.436 	;
	JMP 	WRITESQUASH01(A5) 	;
LAB.436:
*				;;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
WRITESQUASH01 	EQU	*-PRG.STRT	;WRITESQUASH01
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	$D 	; DEFB $D
	DC.B 	"Error writing B:SQUASH.DAT" 	; DEFM "Error writing B:SQUASH.DAT"
	DC.B 	$D,0 	; DEFB $D,0
	JMP 	EXITCPM(A5) 	; JP EXITCPM
*				;;
*				;;-----
*				;;
OUTPUT 	EQU	*-PRG.STRT	;OUTPUT
	DC.B 	2 	; DEFB 2 ;Drive B:
	DC.B 	"SQUASH  " 	; DEFM "SQUASH  "
	DC.B 	"DAT" 	; DEFM "DAT"
*				;;
*				;;-----
*				;;
CALCCOMPRESSION 	EQU	*-PRG.STRT	;CALCCOMPRESSION
	LEA 	LENGTHICF(A5),A0 	; LD HL,(LENGTHICF)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.W 	#LENGTHPOINTERS+1,D3 	; LD DE,LENGTHPOINTERS+1
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
*				;;
	LEA 	NUMCHARACTERS(A5),A0 	; LD BC,(NUMCHARACTERS) ;B=Hi byte of input file length
	MOVE.B 	1(A0),D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	(A0),D2 	;
	MOVE.W 	#DIVIDE,D7 	; CALL DIVIDE ;HL=HL/B
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD B,100 ;HL=DE*100
	MOVE.B 	#100,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#0,D1 	; LD HL,0
CALC1 	EQU	*-PRG.STRT	;CALC1
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#CALC1,D7 	; DJNZ CALC1
	JSR 	SYS.DJNZ(A5) 	;
	ROR.W 	#8,D1 	; LD L,H ;HL=HL/256
	MOVE.B 	D1,D7 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D7,D1 	;
	ROR.W 	#8,D1 	; LD H,0
	MOVE.B 	#0,D1 	;
	ROR.W 	#8,D1 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
DIVIDE 	EQU	*-PRG.STRT	;DIVIDE
*				;;HL=HL/B
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,ZERO
	BNE.S 	LAB.437 	;
	JMP 	ZERO(A5) 	;
LAB.437:
	MOVE.W 	#0,D3 	; LD DE,0 ;Result
DIV1 	EQU	*-PRG.STRT	;DIV1
	MOVE.B 	D1,D0 	; LD A,L
	ROR.W 	#8,D2 	; SUB B
	SUB.B 	D2,D0 	;
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,D1 	; LD L,A
	MOVE 	F(A5),SR 	; JR NC,DIV2
	BCS.S 	LAB.438 	;
	JMP 	DIV2(A5) 	;
LAB.438:
	SUB.W 	#$100,D1 	; DEC H
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	CMP.B 	#$FF,D0 	; CP $FF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DIV3
	BNE.S 	LAB.439 	;
	JMP 	DIV3(A5) 	;
LAB.439:
DIV2 	EQU	*-PRG.STRT	;DIV2
	ADDQ.W 	#1,D3 	; INC DE
	JMP 	DIV1(A5) 	; JR DIV1
DIV3 	EQU	*-PRG.STRT	;DIV3
	JMP 	SYS.RET(A5) 	; RET 
ZERO 	EQU	*-PRG.STRT	;ZERO
	MOVE.W 	#0,D3 	; LD DE,0
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
M 	EQU	*-PRG.STRT	;M*				;;System disk version number
*				;;
*				;; 24/06/86
*				;;
*				;;VERSION.Z80
*				;;
*				;;Version 2.3:
MAJOR 	EQU	'2' 	;MAJOR EQU '2'
MINOR 	EQU	'3' 	;MINOR EQU '3'
*				;;
*				;; Torch/Acorn Z80 Standard Routines
*				;;
*				;; 06/01/86
*				;;
*				;; STANDARD.Z80
*				;;
*				;; Copyright (C) 1985 Level 9 Computing
*				;;
*				;;-----
*				;;
*				;;Entry to all standard CP/M functions:
CPMENTRY 	EQU	&0005 	;CPMENTRY EQU &0005
*				;;
*				;;CPMENTRY 'E' register values:
CPNEXIT 	EQU	0 	;CPNEXIT EQU 0 ;Quit
CPNDCI 	EQU	&06 	;CPNDCI EQU &06 ;Direct Console I/O
CPNRST 	EQU	13;Reset 	;CPNRST EQU 13;Reset disk system
CPNOF 	EQU	15;Open 	;CPNOF  EQU 15;Open File
CPNCF 	EQU	16;Close 	;CPNCF  EQU 16;Close File
CPNDF 	EQU	19;Delete 	;CPNDF  EQU 19;Delete File
CPNRS 	EQU	20;Read 	;CPNRS  EQU 20;Read Sequential
CPNWS 	EQU	21;Write 	;CPNWS  EQU 21;Write Sequential
CPNMF 	EQU	22;Make 	;CPNMF  EQU 22;Make File
*				;;
*				;;Torch CPN bios calls:
USRLMM 	EQU	&FFC0;Call 	;USRLMM EQU &FFC0;Call user function
*				;;
*				;;Torch 1MHz bus drivers:
RX 	EQU	&FFC6;Get 	;RX EQU &FFC6;Get user function result
TX 	EQU	&FFC9;Transmit 	;TX EQU &FFC9;Transmit
*				;;
*				;;Torch User Functions:
UFGES 	EQU	5;Get 	;UFGES EQU 5;Get Escape Status
UFUDC 	EQU	9 	;UFUDC EQU 9 ;Unslave disc cache
UFOSW 	EQU	12 	;UFOSW EQU 12 ;Osword
UFWSR 	EQU	14 	;UFWSR EQU 14 ;Write scratchpad ram
UFOSB 	EQU	15 	;UFOSB EQU 15 ;OsByte
*				;;
*				;;CP/M DMA buffer:
DMAADDR 	EQU	&0080 	;DMAADDR EQU &0080
DMALEN 	EQU	&80 	;DMALEN EQU &80
*				;;
FCBLENGTH 	EQU	&24 	;FCBLENGTH EQU &24 ;Length of File Control Block
SERIALFCBLENGTH 	EQU	FCBLENGTH+2+256 	;SERIALFCBLENGTH EQU FCBLENGTH+2+256 ;Serial Control Block
*				;;
*				;;Ascii/BBC control codes:
ASCIINULL 	EQU	&00 	;ASCIINULL EQU &00
ASCIIBELL 	EQU	&07 	;ASCIIBELL EQU &07
ASCIIBS 	EQU	&08 	;ASCIIBS EQU &08
ASCIILF 	EQU	&0A 	;ASCIILF EQU &0A
ASCIICR 	EQU	&0D 	;ASCIICR EQU &0D
ASCIIEOF 	EQU	&1A 	;ASCIIEOF EQU &1A
ASCIIESC 	EQU	&1B 	;ASCIIESC EQU &1B
ASCIIDEL 	EQU	&7F 	;ASCIIDEL EQU &7F
*				;;
*				;;INPUTLINE buffer length
LINELENGTH 	EQU	80 	;LINELENGTH EQU 80 ;*
*				;;
*				;;-----
*				;;
*				;;'Vectors' for all driver Input/Output:
*				;;
ECHOINPUTCHARACTER 	EQU	*-PRG.STRT	;ECHOINPUTCHARACTER JP OSWRCH
	JMP 	OSWRCH(A5) 	;
*				;;
GETINPUTCHARACTER 	EQU	*-PRG.STRT	;GETINPUTCHARACTER JP OSRDCH
	JMP 	OSRDCH(A5) 	;
*				;;
*				;;*INPUTTERMINATE
*				;;* CP ASCIICR
*				;;* RET 
*				;;
*				;;-----
*				;;
*				;;File type for Z80 code:
TYPECOM 	EQU	*-PRG.STRT	;TYPECOM
	 	 	;
	DC.B 	"COM" 	; DEFM "COM"
*				;;
*				;;File type for ASCII files:
TYPETXT 	EQU	*-PRG.STRT	;TYPETXT
	 	 	;
	DC.B 	"TXT" 	; DEFM "TXT"
*				;;
*				;;-----
*				;;
*				;;Call to set up COMPUTERTYPE. Required before STAR, FX calls
*				;;Disk writes.
*				;;
SETCOMPUTERTYPE 	EQU	*-PRG.STRT	;SETCOMPUTERTYPE
	 	 	;
	MOVE.B 	&FFF4(A5),D0 	; LD A,(&FFF4)
	CMP.B 	#&11,D0 	; CP &11 ;Torch
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SETCOMP01
	BNE.S 	LAB.501 	;
	JMP 	SETCOMP01(A5) 	;
LAB.501:
	CMP.B 	#&C3,D0 	; CP &C3 ;Acorn
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,SETCOMP02
	BNE.S 	LAB.502 	;
	JMP 	SETCOMP02(A5) 	;
LAB.502:
*				;;
*				;;Unknown computer
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SETCOMP03(A5) 	; JR SETCOMP03
*				;;
*				;;Torch system
*				;;
SETCOMP01 	EQU	*-PRG.STRT	;SETCOMP01
	 	 	;
	MOVE.B 	#1,D0 	; LD A,1
	JMP 	SETCOMP03(A5) 	; JR SETCOMP03
*				;;
*				;;Acorn system
*				;;
SETCOMP02 	EQU	*-PRG.STRT	;SETCOMP02
	 	 	;
	MOVE.B 	#2,D0 	; LD A,2
SETCOMP03 	EQU	*-PRG.STRT	;SETCOMP03
	 	 	;
	MOVE.B 	D0,COMPUTERTYPE(A5) 	; LD (COMPUTERTYPE),A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display NEWLINE sequence
*				;;(Preferred to send LF as well as this works with printer)
*				;;
CRLF 	EQU	*-PRG.STRT	;CRLF
	 	 	;
	MOVE.W 	#PRS,D7 	; CALL PRS
	JSR 	SYS.JSR(A5) 	;
	DC.B 	ASCIICR,ASCIINULL 	; DEFB ASCIICR,ASCIINULL
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Read bytes from (HL) and increment HL until a
*				;; non-space if found. Returns 'NC' and 'Z' if
*				;; (HL)=NULL, 'C' and 'NZ' otherwise. Always A=(HL).
*				;;
READEOLN 	EQU	*-PRG.STRT	;READEOLN LD A,(HL)
	MOVE.B 	0(A5,D1.W),D0 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.503 	;
	JMP 	SYS.RET(A5) 	;
LAB.503:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.504 	;
	JMP 	SYS.RET(A5) 	;
LAB.504:
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	READEOLN(A5) 	; JR READEOLN
*				;;
*				;;-----
*				;;
*				;;Quit user program via CP/M warm start
*				;;
EXITCPM 	EQU	*-PRG.STRT	;EXITCPM
	 	 	;
	MOVE.B 	#CPNEXIT,D2 	; LD C,CPNEXIT
	JMP 	CPMENTRY(A5) 	; JP CPMENTRY
*				;;
*				;;-----
*				;;
*				;;Scan memory for a valid 16 bit hex number, Optionally
*				;;preceeded by spaces and terminated by either a space
*				;;or null.
*				;;
READADDRESS 	EQU	*-PRG.STRT	;READADDRESS
	 	 	;
	MOVE.W 	#READEOLN,D7 	; CALL READEOLN ;Used to skip spaces
	JSR 	SYS.JSR(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	MOVE 	F(A5),SR 	; RET C ;NULL found
	BCC.S 	LAB.505 	;
	JMP 	SYS.RET(A5) 	;
LAB.505:
	MOVE.W 	#&0000,D2 	; LD BC,&0000
READADDR01 	EQU	*-PRG.STRT	;READADDR01 LD A,(HL)
	MOVE.B 	0(A5,D1.W),D0 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READADDR04
	BNE.S 	LAB.506 	;
	JMP 	READADDR04(A5) 	;
LAB.506:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READADDR04
	BNE.S 	LAB.507 	;
	JMP 	READADDR04(A5) 	;
LAB.507:
	CMP.B 	#'0',D0 	; CP '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.508 	;
	JMP 	SYS.RET(A5) 	;
LAB.508:
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,READADDR02
	BCS.S 	LAB.509 	;
	JMP 	READADDR02(A5) 	;
LAB.509:
	SUB.B 	#'0',D0 	; SUB '0'
	MOVE 	SR,F(A5) 	;
	JMP 	READADDR03(A5) 	; JR READADDR03
READADDR02 	EQU	*-PRG.STRT	;READADDR02 CALL UPPER
	MOVE.W 	#UPPER,D7 	;
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'A',D0 	; CP 'A'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.510 	;
	JMP 	SYS.RET(A5) 	;
LAB.510:
	CMP.B 	#'F'+1,D0 	; CP 'F'+1
	MOVE 	SR,F(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.511 	;
	JMP 	SYS.RET(A5) 	;
LAB.511:
	SUB.B 	#'A'-10,D0 	; SUB 'A'-10
	MOVE 	SR,F(A5) 	;
READADDR03 	EQU	*-PRG.STRT	;READADDR03 PUSH HL
	SUBQ.W 	#2,D6 	;
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D1 	; LD H,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D2,D1 	; LD L,C
	ADD.W 	D1,D1 	; ADD HL,HL 
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL 
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL 
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL 
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,&00
	MOVE.B 	#&00,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,D2 	; LD C,A
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D2 	; LD B,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D2 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D1,D2 	; LD C,L
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	READADDR01(A5) 	; JR READADDR01
READADDR04 	EQU	*-PRG.STRT	;READADDR04 XOR A
	EOR.B 	D0,D0 	;
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display character
*				;;
OSWRCH 	EQU	*-PRG.STRT	;OSWRCH
	 	 	;
	CMP.B 	#ASCIIEOF,D0 	; CP ASCIIEOF
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.512 	;
	JMP 	SYS.RET(A5) 	;
LAB.512:
*				;;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#DISPLAYCONTROL,D7 	; CALL DISPLAYCONTROL
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE.B 	#ASCIILF,D0 	; LD A,ASCIILF
	MOVE 	F(A5),SR 	; CALL Z,DISPLAYCONTROL
	BNE.S 	LAB.513 	;
	MOVE.W 	#DISPLAYCONTROL,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.513:
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display raw byte data
*				;;
DISPLAYCONTROL 	EQU	*-PRG.STRT	;DISPLAYCONTROL
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	#CPNDCI,D2 	; LD C,CPNDCI
	MOVE.B 	D0,D3 	; LD E,A
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Execute *FX A,B,C
*				;;
FX0 	EQU	*-PRG.STRT	;FX0
	 	 	;
	MOVE.B 	#&00,D2 	; LD C,&00
FX 	EQU	*-PRG.STRT	;FX
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	COMPUTERTYPE(A5),D0 	; LD A,(COMPUTERTYPE)
	CMP.B 	#1,D0 	; CP 1 ;Torch ?
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,FX01
	BNE.S 	LAB.514 	;
	JMP 	FX01(A5) 	;
LAB.514:
	CMP.B 	#2,D0 	; CP 2 ;Acorn ?
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,FX02
	BNE.S 	LAB.515 	;
	JMP 	FX02(A5) 	;
LAB.515:
*				;;
*				;;Unknown computer, Ignore command
*				;;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Torch-style 'FX'
*				;;
FX01 	EQU	*-PRG.STRT	;FX01
	 	 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
*				;;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#USRLMM,D7 	; CALL USRLMM
	JSR 	SYS.JSR(A5) 	;
	DC.B 	UFOSB 	; DEFB UFOSB ;Osbyte
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#RX,D7 	; CALL RX
	JSR 	SYS.JSR(A5) 	;
	ROR.W 	#8,D2 	; LD B,A
	MOVE.B 	D0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#RX,D7 	; CALL RX
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D0,D2 	; LD C,A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Acorn-style 'FX'
*				;;
FX02 	EQU	*-PRG.STRT	;FX02
	 	 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
*				;;
	ROR.W 	#8,D2 	; LD L,B
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D1 	; LD H,C
	MOVE.B 	D2,D1 	;
	ROR.W 	#8,D1 	;
	JMP 	(A5) 	; JP &FFF4 ;Osbyte entry
*				;;
*				;;-----
*				;;
*				;;Convert byte to upper case
*				;;
UPPER 	EQU	*-PRG.STRT	;UPPER
	 	 	;
	CMP.B 	#'a',D0 	; CP 'a'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.516 	;
	JMP 	SYS.RET(A5) 	;
LAB.516:
	CMP.B 	#'z'+1,D0 	; CP 'z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC
	BCS.S 	LAB.517 	;
	JMP 	SYS.RET(A5) 	;
LAB.517:
	SUB.B 	#&20,D0 	; SUB &20
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Execute valid '*' command.
*				;;Hangs in place of 'Bad command'
*				;;
STAR 	EQU	*-PRG.STRT	;STAR
	 	 	;
	MOVE.B 	COMPUTERTYPE(A5),D0 	; LD A,(COMPUTERTYPE)
	CMP.B 	#2,D0 	; CP 2 ;Acorn
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,STAR03
	BNE.S 	LAB.518 	;
	JMP 	STAR03(A5) 	;
LAB.518:
	CMP.B 	#1,D0 	; CP 1 ;Torch
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.519 	;
	JMP 	SYS.RET(A5) 	;
LAB.519:
*				;;
*				;;Torch-style '*'
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
STAR01 	EQU	*-PRG.STRT	;STAR01 PUSH AF
	SUBQ.W 	#2,D6 	;
	MOVE.W 	#AF,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#USRLMM,D7 	; CALL USRLMM
	JSR 	SYS.JSR(A5) 	;
	DC.B 	UFWSR 	; DEFB UFWSR
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.B 	D0,D2 	; LD C,A
	ADDQ.B 	#1,D0 	; INC A
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(DE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,STAR02
	BNE.S 	LAB.520 	;
	JMP 	STAR02(A5) 	;
LAB.520:
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,STAR02
	BNE.S 	LAB.521 	;
	JMP 	STAR02(A5) 	;
LAB.521:
	MOVE.B 	D0,D2 	; LD C,A
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	STAR01(A5) 	; JR STAR01
STAR02 	EQU	*-PRG.STRT	;STAR02 POP AF
	MOVE.W 	0(A5,D6.W),#AF 	;
	ADDQ.W 	#2,D6 	;
	MOVE.B 	#&0D,D2 	; LD C,&0D
	MOVE.W 	#TX,D7 	; CALL TX
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#USRLMM,D7 	; CALL USRLMM
	JSR 	SYS.JSR(A5) 	;
	DC.B 	UFOSW 	; DEFB UFOSW ;Osword
	MOVE.B 	#&00,D2 	; LD C,&00
	JMP 	TX(A5) 	; JP TX
*				;;
*				;;Acorn-style '*'
*				;;
STAR03 	EQU	*-PRG.STRT	;STAR03
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
STAR04 	EQU	*-PRG.STRT	;STAR04
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#ASCIICR,D0 	; CP ASCIICR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,STAR06
	BNE.S 	LAB.522 	;
	JMP 	STAR06(A5) 	;
LAB.522:
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,STAR05
	BNE.S 	LAB.523 	;
	JMP 	STAR05(A5) 	;
LAB.523:
	ADDQ.W 	#1,D1 	; INC HL
	JMP 	STAR04(A5) 	; JR STAR04
STAR05 	EQU	*-PRG.STRT	;STAR05
	 	 	;
	MOVE.B 	#ASCIICR,0(A5,D1.W) 	; LD (HL),ASCIICR
STAR06 	EQU	*-PRG.STRT	;STAR06
	 	 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	(A5) 	; JP &FFF7 ;OSCLI
*				;;
*				;;-----
*				;;
*				;;Copy contents of SYSTEMFCB to block of memory
*				;;
SAVESYSTEMFCB 	EQU	*-PRG.STRT	;SAVESYSTEMFCB
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#SYSTEMFCB,D1 	; LD HL,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Copy FCBLENGTH bytes from memory to SYSTEMFCB.
*				;;
LOADSYSTEMFCB 	EQU	*-PRG.STRT	;LOADSYSTEMFCB
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;If File type in SYSTEMFCB is blank then insert string at HL.
*				;;
SETDEFAULTTYPE 	EQU	*-PRG.STRT	;SETDEFAULTTYPE
	 	 	;
	MOVE.B 	SYSTEMFCBTYPE(A5),D0 	; LD A,(SYSTEMFCBTYPE)
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.524 	;
	JMP 	SYS.RET(A5) 	;
LAB.524:
	MOVE.W 	#SYSTEMFCBTYPE,D3 	; LD DE,SYSTEMFCBTYPE
	MOVE.W 	#&0003,D2 	; LD BC,&0003
	JSR 	SYS.LDIR(A5) 	; LDIR 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Given HL as number of bytes to WRITE to a file, returns
*				;;A = Number of whole 'pages' to write
*				;;
CALCPAGES 	EQU	*-PRG.STRT	;CALCPAGES
	 	 	;
*				;; Do A = (HL+255) DIV 256
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#1,D1 	; DEC HL
	ADD.W 	#$100,D1 	; INC H
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;HL is address of FCBLENGTH bytes for FCB to use.
*				;;File name to open in SYSTEMFCB (DRIVE,NAME,TYPE)
*				;;SYSTEMFCB is corrupted.
*				;;
OPENPAGEREAD 	EQU	*-PRG.STRT	;OPENPAGEREAD
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#OPENSYSTEMREAD,D7 	; CALL OPENSYSTEMREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C ;Error
	BCC.S 	LAB.525 	;
	JMP 	SYS.RET(A5) 	;
LAB.525:
	JMP 	SAVESYSTEMFCB(A5) 	; JP SAVESYSTEMFCB
*				;;
*				;;-----
*				;;
*				;;HL is address of FCBLENGTH bytes for FCB to use.
*				;;File name to open in SYSTEMFCB (DRIVE,NAME,TYPE)
*				;;SYSTEMFCB is corrupted.
*				;;
OPENPAGEWRITE 	EQU	*-PRG.STRT	;OPENPAGEWRITE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#OPENSYSTEMWRITE,D7 	; CALL OPENSYSTEMWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C ;Error
	BCC.S 	LAB.526 	;
	JMP 	SYS.RET(A5) 	;
LAB.526:
	JMP 	SAVESYSTEMFCB(A5) 	; JP SAVESYSTEMFCB
*				;;
*				;;-----
*				;;
*				;;Open system file for reading multiples of pages
*				;;
OPENSYSTEMREAD 	EQU	*-PRG.STRT	;OPENSYSTEMREAD
	 	 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.B 	#CPNOF,D2 	; LD C,CPNOF ;Open file
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#4,D0 	; CP 4
	MOVE 	SR,F(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	JMP 	SYS.RET(A5) 	; RET ;Return 'C' if A=&FF (Not found)
*				;;
*				;;-----
*				;;
*				;;HL is address of FCB used in OPENPAGEREAD
*				;;SYSTEMFCB corrupted.
*				;;DE is address to load data, A number of 256 byte pages to read
*				;;
READPAGES 	EQU	*-PRG.STRT	;READPAGES
	 	 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	#LOADSYSTEMFCB,D7 	; CALL LOADSYSTEMFCB
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL ;HL=Address to load
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.B 	D2,D0 	; LD A,C ;A=Number of pages
	MOVE.W 	#READSYSTEMPAGES,D7 	; CALL READSYSTEMPAGES
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#SAVESYSTEMFCB,D7 	; CALL SAVESYSTEMFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Write multiples of 256 bytes to file opened by OPENPAGEWRITE
*				;;SYSTEMFCB corrupted.
*				;;DE is address to write data, A number of 256 byte pages to write.
*				;;
WRITEPAGES 	EQU	*-PRG.STRT	;WRITEPAGES
	 	 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	#LOADSYSTEMFCB,D7 	; CALL LOADSYSTEMFCB
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL ;HL is address to write
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.B 	D2,D0 	; LD A,C ;A number of pages
	MOVE.W 	#WRITESYSTEMPAGES,D7 	; CALL WRITESYSTEMPAGES
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH AF ;Save error condition
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#SAVESYSTEMFCB,D7 	; CALL SAVESYSTEMFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Read whole number of pages from SYSTEM file following
*				;;call to OPENSYSTEMREAD.
*				;;
READSYSTEMPAGES 	EQU	*-PRG.STRT	;READSYSTEMPAGES LD DE,SYSTEMFCB
	MOVE.W 	#SYSTEMFCB,D3 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.527 	;
	JMP 	SYS.RET(A5) 	;
LAB.527:
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#READSECTOR,D7 	; CALL READSECTOR
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,READSYSTEMPAGES01
	BCC.S 	LAB.528 	;
	JMP 	READSYSTEMPAGES01(A5) 	;
LAB.528:
	MOVE.W 	#READSECTOR,D7 	; CALL READSECTOR
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,READSYSTEMPAGES01
	BCC.S 	LAB.529 	;
	JMP 	READSYSTEMPAGES01(A5) 	;
LAB.529:
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	SUBQ.B 	#1,D0 	; DEC A
	JMP 	READSYSTEMPAGES(A5) 	; JR READSYSTEMPAGES
READSYSTEMPAGES01 	EQU	*-PRG.STRT	;READSYSTEMPAGES01 POP AF
	MOVE.W 	0(A5,D6.W),#AF 	;
	ADDQ.W 	#2,D6 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
READSECTOR 	EQU	*-PRG.STRT	;READSECTOR
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.B 	#CPNRS,D2 	; LD C,CPNRS ;Read sequential
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,READSECTOR01
	BEQ.S 	LAB.530 	;
	JMP 	READSECTOR01(A5) 	;
LAB.530:
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#DMAADDR,D1 	; LD HL,DMAADDR
	MOVE.W 	#DMALEN,D2 	; LD BC,DMALEN
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
READSECTOR01 	EQU	*-PRG.STRT	;READSECTOR01 POP AF
	MOVE.W 	0(A5,D6.W),#AF 	;
	ADDQ.W 	#2,D6 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Close read or write file
*				;;
CLOSEPAGEREAD 	EQU	*-PRG.STRT	;CLOSEPAGEREAD
	 	 	;
CLOSEPAGEWRITE 	EQU	*-PRG.STRT	;CLOSEPAGEWRITE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#LOADSYSTEMFCB,D7 	; CALL LOADSYSTEMFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#STOPFCB,D7 	; CALL STOPFCB
	JSR 	SYS.JSR(A5) 	;
*				;;
CLOSESYSTEMREAD 	EQU	*-PRG.STRT	;CLOSESYSTEMREAD
	 	 	;
CLOSESYSTEMWRITE 	EQU	*-PRG.STRT	;CLOSESYSTEMWRITE
	 	 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.B 	#CPNCF,D2 	; LD C,CPNCF ;Close file
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
*				;;
*				;;No return code
	JMP 	STOPFCB(A5) 	; JP STOPFCB
*				;;
*				;;-----
*				;;
*				;;Wipe all bytes in FCB at (HL) except thoses requires for
*				;;DISPLAYNAME.
*				;;
STOPFCB 	EQU	*-PRG.STRT	;STOPFCB
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.W 	#12,D2 	; LD BC,12 ;Skip Drive/Name/Type
	ADD.W 	D2,D1 	; ADD HL,BC
	MOVE 	SR,F(A5) 	;
*				;;
	MOVE.B 	#0,0(A5,D1.W) 	; LD (HL),0
	ROR.W 	#8,D3 	; LD D,H
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,D3 	;
	ROR.W 	#8,D1 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D1,D3 	; LD E,L
	ADDQ.W 	#1,D3 	; INC DE
	MOVE.W 	#FCBLENGTH-12,D2 	; LD BC,FCBLENGTH-12
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Open system file for writing multiples of pages
*				;;
OPENSYSTEMWRITE 	EQU	*-PRG.STRT	;OPENSYSTEMWRITE
	 	 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.B 	#CPNMF,D2 	; LD C,CPNMF ;Make file
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#4,D0 	; CP 4
	MOVE 	SR,F(A5) 	;
	EOR.B 	#17,F+1(A6) 	; CCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;
*				;;-----
*				;;
*				;;Write pages to file following call to OPENSYSTEMWRITE.
*				;;
WRITESYSTEMPAGES 	EQU	*-PRG.STRT	;WRITESYSTEMPAGES OR A
	OR.B 	D0,D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.531 	;
	JMP 	SYS.RET(A5) 	;
LAB.531:
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#WRITESECTOR,D7 	; CALL WRITESECTOR
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,WRITESYSTEM01
	BCC.S 	LAB.532 	;
	JMP 	WRITESYSTEM01(A5) 	;
LAB.532:
	MOVE.W 	#WRITESECTOR,D7 	; CALL WRITESECTOR
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,WRITESYSTEM01
	BCC.S 	LAB.533 	;
	JMP 	WRITESYSTEM01(A5) 	;
LAB.533:
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	SUBQ.B 	#1,D0 	; DEC A
	JMP 	WRITESYSTEMPAGES(A5) 	; JR WRITESYSTEMPAGES
*				;;
WRITESYSTEM01 	EQU	*-PRG.STRT	;WRITESYSTEM01 POP AF
	MOVE.W 	0(A5,D6.W),#AF 	;
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#CLOSESYSTEMWRITE,D7 	; CALL CLOSESYSTEMWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#DELETESYSTEM,D7 	; CALL DELETESYSTEM
	JSR 	SYS.JSR(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
WRITESECTOR 	EQU	*-PRG.STRT	;WRITESECTOR
	 	 	;
	MOVE.W 	#DMAADDR,D3 	; LD DE,DMAADDR
	MOVE.W 	#DMALEN,D2 	; LD BC,DMALEN
	JSR 	SYS.LDIR(A5) 	; LDIR 
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.B 	#CPNWS,D2 	; LD C,CPNWS ;Write sequential
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.534 	;
	JMP 	SYS.RET(A5) 	;
LAB.534:
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Delete file
*				;;
DELETESYSTEM 	EQU	*-PRG.STRT	;DELETESYSTEM
	 	 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.B 	#CPNDF,D2 	; LD C,CPNDF ;Delete file
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	COMPUTERTYPE(A5),D0 	; LD A,(COMPUTERTYPE)
	CMP.B 	#1,D0 	; CP 1 ;Torch
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NZ
	BEQ.S 	LAB.535 	;
	JMP 	SYS.RET(A5) 	;
LAB.535:
*				;;
*				;;On Torch system clear BBC cache buffer:
*				;;
	MOVE.W 	#USRLMM,D7 	; CALL USRLMM
	JSR 	SYS.JSR(A5) 	;
	DC.B 	UFUDC 	; DEFB UFUDC
*				;;
	MOVE.B 	#CPNRST,D2 	; LD C,CPNRST
	JMP 	CPMENTRY(A5) 	; JP CPMENTRY
*				;;
*				;;-----
*				;;
*				;;Call 'RESET' only when no files open
*				;;'CLEARFCB' initialises FCB before OPEN.
*				;;
RESET 	EQU	*-PRG.STRT	;RESET
	 	 	;
	MOVE.B 	#CPNRST,D2 	; LD C,CPNRST ;Reset disk system
	JMP 	CPMENTRY(A5) 	; JP CPMENTRY
*				;;
RESETANDCLEARFCB 	EQU	*-PRG.STRT	;RESETANDCLEARFCB
	 	 	;
	MOVE.W 	#RESET,D7 	; CALL RESET
	JSR 	SYS.JSR(A5) 	;
CLEARFCB 	EQU	*-PRG.STRT	;CLEARFCB
	 	 	;
	MOVE.W 	#SYSTEMFCB,D1 	; LD HL,SYSTEMFCB
	MOVE.W 	#SYSTEMFCB+1,D3 	; LD DE,SYSTEMFCB+1
	MOVE.W 	#FCBLENGTH-1,D2 	; LD BC,FCBLENGTH-1
	MOVE.B 	#',D0 	; LD A,' '
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	JSR 	SYS.LDIR(A5) 	; LDIR 
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,SYSTEMFCBDRIVE(A5) 	; LD (SYSTEMFCBDRIVE),A
	MOVE.B 	D0,SYSTEMFCBEX(A5) 	; LD (SYSTEMFCBEX),A
	MOVE.B 	D0,SYSTEMFCBCR(A5) 	; LD (SYSTEMFCBCR),A
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display file name contained in SYSTEMFCB.
*				;;
DISPLAYNAME 	EQU	*-PRG.STRT	;DISPLAYNAME
	 	 	;
	MOVE.B 	SYSTEMFCBDRIVE(A5),D0 	; LD A,(SYSTEMFCBDRIVE)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DISPLAYNAME1
	BNE.S 	LAB.536 	;
	JMP 	DISPLAYNAME1(A5) 	;
LAB.536:
	ADD.B 	#'A'-1,D0 	; ADD A,'A'-1
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#':',D0 	; LD A,':'
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
DISPLAYNAME1 	EQU	*-PRG.STRT	;DISPLAYNAME1 LD HL,SYSTEMFCBNAME
	MOVE.W 	#SYSTEMFCBNAME,D1 	;
	ROR.W 	#8,D2 	; LD B,&08
	MOVE.B 	#&08,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#DISPLAYNAME2,D7 	; CALL DISPLAYNAME2
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#'.',D0 	; LD A,'.'
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#SYSTEMFCBTYPE,D1 	; LD HL,SYSTEMFCBTYPE
	ROR.W 	#8,D2 	; LD B,&03
	MOVE.B 	#&03,D2 	;
	ROR.W 	#8,D2 	;
DISPLAYNAME2 	EQU	*-PRG.STRT	;DISPLAYNAME2 LD A,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.537 	;
	JMP 	SYS.RET(A5) 	;
LAB.537:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DISPLAYNAME3
	BNE.S 	LAB.538 	;
	JMP 	DISPLAYNAME3(A5) 	;
LAB.538:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; CALL NZ,OSWRCH
	BEQ.S 	LAB.539 	;
	MOVE.W 	#OSWRCH,D7 	;
	JSR 	SYS.JSR(A5) 	;
LAB.539:
DISPLAYNAME3 	EQU	*-PRG.STRT	;DISPLAYNAME3 INC HL
	ADDQ.W 	#1,D1 	;
	SUB.W 	#$100,D2 	; DEC B
	JMP 	DISPLAYNAME2(A5) 	; JR DISPLAYNAME2
*				;;
*				;;-----
*				;;
*				;;For use in one-file systems.
*				;;Reset disk system then asks for a file name
*				;;Returns: 'C' for invalid file name
*				;;         'NC' and 'Z' for blank input
*				;;         'NC' and 'NZ' for vaid file name
*				;;
GETSYSTEMNAME 	EQU	*-PRG.STRT	;GETSYSTEMNAME
	 	 	;
	MOVE.W 	#RESETANDCLEARFCB,D7 	; CALL RESETANDCLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#INPUTLINE,D7 	; CALL INPUTLINE
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.W 	#BUFFER,D1 	; LD HL,BUFFER
	MOVE.W 	#READEOLN,D7 	; CALL READEOLN
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR C,GETSYS01 ;Found a non-null non-space
	BCC.S 	LAB.540 	;
	JMP 	GETSYS01(A5) 	;
LAB.540:
*				;;
*				;;User entered a blank line (or only spaces)
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
GETSYS01 	EQU	*-PRG.STRT	;GETSYS01
	 	 	;
	MOVE.W 	#READNAME,D7 	; CALL READNAME
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; RET C ;Invalid file name
	BCC.S 	LAB.541 	;
	JMP 	SYS.RET(A5) 	;
LAB.541:
*				;;
	MOVE.W 	#READEOLN,D7 	; CALL READEOLN
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; RET C ;Invalid file name
	BCC.S 	LAB.542 	;
	JMP 	SYS.RET(A5) 	;
LAB.542:
*				;;
*				;;Valid file name
	MOVE.B 	#1,D0 	; LD A,1
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Scan memory for a valid file name, optionally
*				;;spaces and terminated by either a space or null.
*				;;
READNAME 	EQU	*-PRG.STRT	;READNAME
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#RESETANDCLEARFCB,D7 	; CALL RESETANDCLEARFCB
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	#READEOLN,D7 	; CALL READEOLN ;Skip spaces
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,READNAME09 ;Found NULL.
	BCS.S 	LAB.543 	;
	JMP 	READNAME09(A5) 	;
LAB.543:
*				;;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	SUBQ.W 	#1,D1 	; DEC HL
	CMP.B 	#':',D0 	; CP ':'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,READNAME02
	BEQ.S 	LAB.544 	;
	JMP 	READNAME02(A5) 	;
LAB.544:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	SUB.B 	#'A'-1,D0 	; SUB 'A'-1
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,SYSTEMFCBDRIVE(A5) 	; LD (SYSTEMFCBDRIVE),A
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D1 	; INC HL
READNAME02 	EQU	*-PRG.STRT	;READNAME02 LD DE,SYSTEMFCBNAME
	MOVE.W 	#SYSTEMFCBNAME,D3 	;
	MOVE.W 	#&0008,D2 	; LD BC,&0008
	MOVE.W 	#READSYSTEMID,D7 	; CALL READSYSTEMID
	JSR 	SYS.JSR(A5) 	;
	CMP.B 	#'.',D0 	; CP '.'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READNAME03
	BNE.S 	LAB.545 	;
	JMP 	READNAME03(A5) 	;
LAB.545:
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.546 	;
	JMP 	SYS.RET(A5) 	;
LAB.546:
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
READNAME03 	EQU	*-PRG.STRT	;READNAME03 INC HL
	ADDQ.W 	#1,D1 	;
	MOVE.W 	#SYSTEMFCBTYPE,D3 	; LD DE,SYSTEMFCBTYPE
	MOVE.W 	#&0003,D2 	; LD BC,&0003
	MOVE.W 	#READSYSTEMID,D7 	; CALL READSYSTEMID
	JSR 	SYS.JSR(A5) 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.547 	;
	JMP 	SYS.RET(A5) 	;
LAB.547:
READNAME09 	EQU	*-PRG.STRT	;READNAME09
	 	 	;
	OR.B 	#17,F+1(A6) 	; SCF 
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;; Copy up to BC characters from (HL) to (DE) but stop
*				;; if find a totaly illegal character for a file name.
*				;;
READSYSTEMID 	EQU	*-PRG.STRT	;READSYSTEMID LD A,B
	ROR.W 	#8,D2 	;
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READSYSTEM02 ;Copied all, Return A
	BNE.S 	LAB.548 	;
	JMP 	READSYSTEM02(A5) 	;
LAB.548:
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	#UPPER,D7 	; CALL UPPER
	JSR 	SYS.JSR(A5) 	;
*				;;Trap SPACE, NULL and CR:
	CMP.B 	#',D0 	; CP ' '+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,READSYSTEM01
	BCC.S 	LAB.549 	;
	JMP 	READSYSTEM01(A5) 	;
LAB.549:
*				;;Trap illegal characters:
*				;;(From page 11 'The Software Bus')
	CMP.B 	#'.',D0 	; CP '.' ;Name/Type separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.550 	;
	JMP 	SYS.RET(A5) 	;
LAB.550:
	CMP.B 	#',D0 	; CP ',' ;Command line separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.551 	;
	JMP 	SYS.RET(A5) 	;
LAB.551:
	CMP.B 	#';',D0 	; CP ';' ;Password separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.552 	;
	JMP 	SYS.RET(A5) 	;
LAB.552:
	CMP.B 	#':',D0 	; CP ':' ;Drive spec
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.553 	;
	JMP 	SYS.RET(A5) 	;
LAB.553:
	CMP.B 	#'=',D0 	; CP '=' ;Command line separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.554 	;
	JMP 	SYS.RET(A5) 	;
LAB.554:
	CMP.B 	#'?',D0 	; CP '?' ;Ambiguous
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.555 	;
	JMP 	SYS.RET(A5) 	;
LAB.555:
	CMP.B 	#'*',D0 	; CP '*' ;Ambiguous
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.556 	;
	JMP 	SYS.RET(A5) 	;
LAB.556:
	CMP.B 	#'[',D0 	; CP '[' ;Option separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.557 	;
	JMP 	SYS.RET(A5) 	;
LAB.557:
	CMP.B 	#']',D0 	; CP ']' ;Option separator
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.558 	;
	JMP 	SYS.RET(A5) 	;
LAB.558:
	MOVE.B 	D0,0(A5,D1.W) 	; LD (DE),A
	ADDQ.W 	#1,D1 	; INC HL
	ADDQ.W 	#1,D3 	; INC DE
	SUBQ.W 	#1,D2 	; DEC BC
	JMP 	READSYSTEMID(A5) 	; JR READSYSTEMID
*				;;
READSYSTEM01 	EQU	*-PRG.STRT	;READSYSTEM01
	 	 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;Copied all specified chars, Return A=0 if valid name teminator
READSYSTEM02 	EQU	*-PRG.STRT	;READSYSTEM02
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	CMP.B 	#',D0 	; CP ' '+1 ;Check for SPACE, NULL and CR
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC
	BCS.S 	LAB.559 	;
	JMP 	SYS.RET(A5) 	;
LAB.559:
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Read line from keyboard to BUFFER.
*				;;
INPUTLINE 	EQU	*-PRG.STRT	;INPUTLINE
	 	 	;
	MOVE.W 	#BUFFER,D1 	; LD HL,BUFFER
	MOVE.B 	#ASCIINULL,0(A5,D1.W) 	; LD (HL),ASCIINULL
INLIN01 	EQU	*-PRG.STRT	;INLIN01 CALL GETINPUTCHARACTER
	MOVE.W 	#GETINPUTCHARACTER,D7 	;
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	#INPUTTERMINATE,D7 	; CALL INPUTTERMINATE
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,INLIN05
	BNE.S 	LAB.560 	;
	JMP 	INLIN05(A5) 	;
LAB.560:
	CMP.B 	#ASCIIESC,D0 	; CP ASCIIESC
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,INLIN05
	BNE.S 	LAB.561 	;
	JMP 	INLIN05(A5) 	;
LAB.561:
	CMP.B 	#ASCIIBS,D0 	; CP ASCIIBS
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,INLIN04
	BNE.S 	LAB.562 	;
	JMP 	INLIN04(A5) 	;
LAB.562:
	CMP.B 	#ASCIIDEL,D0 	; CP ASCIIDEL
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,INLIN04
	BNE.S 	LAB.563 	;
	JMP 	INLIN04(A5) 	;
LAB.563:
	MOVE 	F(A5),SR 	; JR NC,INLIN01
	BCS.S 	LAB.564 	;
	JMP 	INLIN01(A5) 	;
LAB.564:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,INLIN02
	BCC.S 	LAB.565 	;
	JMP 	INLIN02(A5) 	;
LAB.565:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	#BUFFER,D3 	; LD DE,BUFFER
	AND.B 	D0,D0 	; AND A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D1,D0 	; LD A,L
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	CMP.B 	#LINELENGTH,D0 	; CP LINELENGTH
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,INLIN03
	BCS.S 	LAB.566 	;
	JMP 	INLIN03(A5) 	;
LAB.566:
	MOVE.B 	D2,D0 	; LD A,C
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	MOVE.W 	#ECHOINPUTCHARACTER,D7 	; CALL ECHOINPUTCHARACTER
	JSR 	SYS.JSR(A5) 	;
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#ASCIINULL,0(A5,D1.W) 	; LD (HL),ASCIINULL
	JMP 	INLIN01(A5) 	; JR INLIN01
INLIN02 	EQU	*-PRG.STRT	;INLIN02 CALL ECHOINPUTCHARACTER
	MOVE.W 	#ECHOINPUTCHARACTER,D7 	;
	JSR 	SYS.JSR(A5) 	;
	JMP 	INLIN01(A5) 	; JR INLIN01
INLIN03 	EQU	*-PRG.STRT	;INLIN03 LD A,ASCIIBELL
	MOVE.B 	#ASCIIBELL,D0 	;
	MOVE.W 	#ECHOINPUTCHARACTER,D7 	; CALL ECHOINPUTCHARACTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	INLIN01(A5) 	; JR INLIN01
INLIN04 	EQU	*-PRG.STRT	;INLIN04 LD DE,BUFFER
	MOVE.W 	#BUFFER,D3 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR Z,INLIN01
	BNE.S 	LAB.567 	;
	JMP 	INLIN01(A5) 	;
LAB.567:
	MOVE 	F(A5),SR 	; JR C,INLIN01
	BCC.S 	LAB.568 	;
	JMP 	INLIN01(A5) 	;
LAB.568:
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.B 	#ASCIINULL,0(A5,D1.W) 	; LD (HL),ASCIINULL
	MOVE.B 	#ASCIIDEL,D0 	; LD A,ASCIIDEL
	MOVE.W 	#ECHOINPUTCHARACTER,D7 	; CALL ECHOINPUTCHARACTER
	JSR 	SYS.JSR(A5) 	;
	JMP 	INLIN01(A5) 	; JR INLIN01
INLIN05 	EQU	*-PRG.STRT	;INLIN05
	 	 	;
	EOR.B 	D0,D0 	; XOR A ;Return 'NC'
	MOVE 	SR,F(A5) 	;
	JMP 	INLIN07(A5) 	; JR INLIN07
*				;;
INLIN06 	EQU	*-PRG.STRT	;INLIN06
	 	 	;
	MOVE.W 	#CHECKESCAPE,D7 	; CALL CHECKESCAPE
	JSR 	SYS.JSR(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF ;Return 'C'
*				;;
INLIN07 	EQU	*-PRG.STRT	;INLIN07
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.B 	#ASCIICR,D0 	; LD A,ASCIICR
	MOVE.W 	#ECHOINPUTCHARACTER,D7 	; CALL ECHOINPUTCHARACTER
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Read keyboard
*				;;
OSRDCH 	EQU	*-PRG.STRT	;OSRDCH
	 	 	;
	MOVE.W 	#GETCHARACTER,D7 	; CALL GETCHARACTER
	JSR 	SYS.JSR(A5) 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,OSRDCH
	BNE.S 	LAB.569 	;
	JMP 	OSRDCH(A5) 	;
LAB.569:
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Check if key pressed
*				;;
GETCHARACTER 	EQU	*-PRG.STRT	;GETCHARACTER
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	#CPNDCI,D2 	; LD C,CPNDCI ;Direct console I/O
	MOVE.B 	#&FF,D3 	; LD E,&FF ;Input
	MOVE.W 	#CPMENTRY,D7 	; CALL CPMENTRY
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display in-line string terminated by NULL.
*				;;
PRS 	EQU	*-PRG.STRT	;PRS
	 	 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
PRS1 	EQU	*-PRG.STRT	;PRS1 LD A,(HL)
	MOVE.B 	0(A5,D1.W),D0 	;
	ADDQ.W 	#1,D1 	; INC HL
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,PRS2
	BNE.S 	LAB.570 	;
	JMP 	PRS2(A5) 	;
LAB.570:
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	JMP 	PRS1(A5) 	; JR PRS1
PRS2 	EQU	*-PRG.STRT	;PRS2 JP (HL)
	JMP 	0(A5,D1.W) 	;
*				;;
*				;;-----
*				;;
DISPLAYAHEX 	EQU	*-PRG.STRT	;DISPLAYAHEX
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE 	F(A5),SR 	; RRA 
	ROXR.B 	#1,D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RRA 
	ROXR.B 	#1,D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RRA 
	ROXR.B 	#1,D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RRA 
	ROXR.B 	#1,D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#DISPLAYHEXNYBBLE,D7 	; CALL DISPLAYHEXNYBBLE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
DISPLAYHEXNYBBLE 	EQU	*-PRG.STRT	;DISPLAYHEXNYBBLE
	 	 	;
	AND.B 	#&0F,D0 	; AND &0F
	MOVE 	SR,F(A5) 	;
	ADD.B 	#'0',D0 	; ADD A,'0'
	MOVE 	SR,F(A5) 	;
	CMP.B 	#'9'+1,D0 	; CP '9'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,DISPLAYHEXNYBBLE01
	BCC.S 	LAB.571 	;
	JMP 	DISPLAYHEXNYBBLE01(A5) 	;
LAB.571:
	ADD.B 	#'A'-'0'-10,D0 	; ADD A,'A'-'0'-10
	MOVE 	SR,F(A5) 	;
DISPLAYHEXNYBBLE01 	EQU	*-PRG.STRT	;DISPLAYHEXNYBBLE01 JP OSWRCH
	JMP 	OSWRCH(A5) 	;
*				;;
*				;;-----
*				;;
*				;;Open file for writing. File name in SYSTEMFCB,
*				;;HL address of SERIALFCB.
*				;;
OPENSERIALWRITE 	EQU	*-PRG.STRT	;OPENSERIALWRITE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#OPENSYSTEMWRITE,D7 	; CALL OPENSYSTEMWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C ;Error
	BCC.S 	LAB.572 	;
	JMP 	SYS.RET(A5) 	;
LAB.572:
	JMP 	SERIALOPEN(A5) 	; JP SERIALOPEN
*				;;
*				;;-----
*				;;
*				;;Open file for reading. File name in SYSTEMFCB,
*				;;HL address of SERIALFCB
*				;;
OPENSERIALREAD 	EQU	*-PRG.STRT	;OPENSERIALREAD
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#OPENSYSTEMREAD,D7 	; CALL OPENSYSTEMREAD
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C ;Error
	BCC.S 	LAB.573 	;
	JMP 	SYS.RET(A5) 	;
LAB.573:
	JMP 	SERIALOPEN(A5) 	; JP SERIALOPEN
*				;;
*				;;-----
*				;;
*				;;Open file for serial access following OPENSYSTEMREAD or
*				;;OPENSYSTEMWRITE. Requires a 294 byte Control Block
*				;;
SERIALOPEN 	EQU	*-PRG.STRT	;SERIALOPEN
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#SYSTEMFCB,D1 	; LD HL,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.B 	#&00,0(A5,D1.W) 	; LD (HL),&00
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#&00,0(A5,D1.W) 	; LD (HL),&00
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Read one byte from file following SERIALOPEN.
*				;;
SERIALREADBYTE 	EQU	*-PRG.STRT	;SERIALREADBYTE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SERIALRB01
	BEQ.S 	LAB.574 	;
	JMP 	SERIALRB01(A5) 	;
LAB.574:
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.W 	#READSECTOR,D7 	; CALL READSECTOR
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.575 	;
	JMP 	SYS.RET(A5) 	;
LAB.575:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.B 	#DMALEN,0(A5,D1.W) 	; LD (HL),DMALEN
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#&00,0(A5,D1.W) 	; LD (HL),&00
SERIALRB01 	EQU	*-PRG.STRT	;SERIALRB01 POP HL
	MOVE.W 	0(A5,D6.W),D1 	;
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#1,D2 	; DEC BC
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	MOVE.B 	#&7F,D0 	; LD A,&7F
	SUB.B 	D2,D0 	; SUB C
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,D2 	; LD C,A
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.W 	#&0026,D2 	; LD BC,&0026
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#SYSTEMFCB,D1 	; LD HL,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Close file opened for reading
*				;;
CLOSESERIALREAD 	EQU	*-PRG.STRT	;CLOSESERIALREAD
	 	 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	JMP 	CLOSESYSTEMREAD(A5) 	; JP CLOSESYSTEMREAD
*				;;
*				;;-----
*				;;
*				;;Write byte to file following SERIALOPEN.
*				;;
SERIALWRITEBYTE 	EQU	*-PRG.STRT	;SERIALWRITEBYTE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.B 	0(A5,D1.W),D2 	; LD C,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D2 	; LD B,(HL)
	MOVE.B 	0(A5,D1.W),D2 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ADDQ.W 	#1,D1 	; INC HL
	ADD.W 	D2,D1 	; ADD HL,BC 
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D0,0(A5,D1.W) 	; LD (HL),A
	ADDQ.W 	#1,D2 	; INC BC
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	ROR.W 	#8,D2 	; LD (HL),B
	MOVE.B 	D2,0(A5,D1.W) 	;
	ROR.W 	#8,D2 	;
	SUBQ.W 	#1,D1 	; DEC HL
	MOVE.B 	D2,0(A5,D1.W) 	; LD (HL),C
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NZ,SERIALWB01
	BEQ.S 	LAB.576 	;
	JMP 	SERIALWB01(A5) 	;
LAB.576:
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
SERIALWB01 	EQU	*-PRG.STRT	;SERIALWB01 POP HL
	MOVE.W 	0(A5,D6.W),D1 	;
	ADDQ.W 	#2,D6 	;
SERIALWB02 	EQU	*-PRG.STRT	;SERIALWB02
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	MOVE.W 	#SYSTEMFCB,D3 	; LD DE,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	MOVE.B 	#&00,0(A5,D1.W) 	; LD (HL),&00
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#&00,0(A5,D1.W) 	; LD (HL),&00
	ADDQ.W 	#1,D1 	; INC HL
	MOVE.B 	#&01,D0 	; LD A,&01
	MOVE.W 	#WRITESYSTEMPAGES,D7 	; CALL WRITESYSTEMPAGES
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; RET C ;Error
	BCC.S 	LAB.577 	;
	JMP 	SYS.RET(A5) 	;
LAB.577:
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#SYSTEMFCB,D1 	; LD HL,SYSTEMFCB
	MOVE.W 	#FCBLENGTH,D2 	; LD BC,FCBLENGTH
	JSR 	SYS.LDIR(A5) 	; LDIR 
	EOR.B 	D0,D0 	; XOR A ;Return 'NC'
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Flush buffer and close file opened for serial
*				;;following SERIALOPEN.
*				;;
CLOSESERIALWRITE 	EQU	*-PRG.STRT	;CLOSESERIALWRITE
	 	 	;
	MOVE.W 	#SERIALWB02,D7 	; CALL SERIALWB02
	JSR 	SYS.JSR(A5) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#CLOSESYSTEMWRITE,D7 	; CALL CLOSESYSTEMWRITE
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Convert A to lower-case.
*				;;Returns 'A'. Flags corrupted.
LOWER 	EQU	*-PRG.STRT	;LOWER CP 'A'
	CMP.B 	#'A',D0 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET C
	BCC.S 	LAB.578 	;
	JMP 	SYS.RET(A5) 	;
LAB.578:
	CMP.B 	#'Z'+1,D0 	; CP 'Z'+1
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET NC
	BCS.S 	LAB.579 	;
	JMP 	SYS.RET(A5) 	;
LAB.579:
	ADD.B 	#$20,D0 	; ADD A,$20
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Returns condition 'C' if Escape pressed.
*				;;AF corrupted.
CHECKESCAPE 	EQU	*-PRG.STRT	;CHECKESCAPE
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	MOVE.B 	#229;Enable,D0 	; LD A,229;Enable Escape
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#FX0,D7 	; CALL FX0
	JSR 	SYS.JSR(A5) 	;
*				;;
	MOVE.B 	COMPUTERTYPE(A5),D0 	; LD A,(COMPUTERTYPE)
	CMP.B 	#2,D0 	; CP 2 ;Acorn
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CHECKESC02
	BNE.S 	LAB.580 	;
	JMP 	CHECKESC02(A5) 	;
LAB.580:
	CMP.B 	#1,D0 	; CP 1 ;Torch
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CHECKESC01
	BNE.S 	LAB.581 	;
	JMP 	CHECKESC01(A5) 	;
LAB.581:
*				;;
*				;;Unknown computer, Return non-escape
*				;;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	JMP 	CHECKESC04(A5) 	; JR CHECKESC04
*				;;
*				;;Torch-style check for escape condition
*				;;
CHECKESC01 	EQU	*-PRG.STRT	;CHECKESC01
	 	 	;
	MOVE.W 	#USRLMM,D7 	; CALL USRLMM
	JSR 	SYS.JSR(A5) 	;
	DC.B 	UFGES 	; DEFB UFGES
	MOVE.W 	#RX,D7 	; CALL RX
	JSR 	SYS.JSR(A5) 	;
	JMP 	CHECKESC03(A5) 	; JR CHECKESC03
*				;;
*				;;Acorn-style check for Escape Flag
*				;;
CHECKESC02 	EQU	*-PRG.STRT	;CHECKESC02
	 	 	;
	MOVE.B 	&FF80(A5),D0 	; LD A,(&FF80) ;Escape flag
*				;;
CHECKESC03 	EQU	*-PRG.STRT	;CHECKESC03
	 	 	;
	BTST 	D0,#7 	; BIT 7,A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,CHECKESC04
	BNE.S 	LAB.582 	;
	JMP 	CHECKESC04(A5) 	;
LAB.582:
	MOVE.B 	#126,D0 	; LD A,126 ;Clear escape
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#FX0,D7 	; CALL FX0
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	#21;Flush,D0 	; LD A,21;Flush
	ROR.W 	#8,D2 	; LD B,0
	MOVE.B 	#0,D2 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#FX0,D7 	; CALL FX0
	JSR 	SYS.JSR(A5) 	;
	OR.B 	#17,F+1(A6) 	; SCF 
CHECKESC04 	EQU	*-PRG.STRT	;CHECKESC04
	 	 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;Display a hex address
*				;;Corrupts A.
DISPLAYHLHEX 	EQU	*-PRG.STRT	;DISPLAYHLHEX
	 	 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	#DISPLAYAHEX,D7 	; CALL DISPLAYAHEX
	JSR 	SYS.JSR(A5) 	;
	MOVE.B 	D1,D0 	; LD A,L
	JMP 	DISPLAYAHEX(A5) 	; JP DISPLAYAHEX
*				;;
*				;;-----
*				;;
*				;;Display HL in decimal.
*				;;Nothing corrupted.
DISPLAYDECIMAL 	EQU	*-PRG.STRT	;DISPLAYDECIMAL
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH BC
	MOVE.W 	D2,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH AF
	MOVE.W 	#AF,0(A5,D6.W) 	;
	MOVE.W 	#DD01,D7 	; CALL DD01
	JSR 	SYS.JSR(A5) 	;
	MOVE.W 	0(A5,D6.W),#AF 	; POP AF
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D2 	; POP BC
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
DD01 	EQU	*-PRG.STRT	;DD01
	 	 	;
	ROR.W 	#8,D1 	; LD A,H
	MOVE.B 	D1,D0 	;
	ROR.W 	#8,D1 	;
	OR.B 	D1,D0 	; OR L
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DD05
	BNE.S 	LAB.583 	;
	JMP 	DD05(A5) 	;
LAB.583:
	MOVE.B 	#0,D2 	; LD C,0 ;Reset flag
	MOVE.W 	#DD06,D3 	; LD DE,DD06
	LEA 	PRTPTR(A5),A0 	; LD (PRTPTR),DE
	MOVE.B 	D3,(A0) 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,1(A0) 	;
	ROR.W 	#8,D3 	;
*				;;Find current digit value
DD02 	EQU	*-PRG.STRT	;DD02
	 	 	;
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	LEA 	PRTPTR(A5),A0 	; LD HL,(PRTPTR)
	MOVE.B 	1(A0),D1 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	(A0),D1 	;
	MOVE.B 	0(A5,D1.W),D3 	; LD E,(HL)
	ADDQ.W 	#1,D1 	; INC HL
	ROR.W 	#8,D3 	; LD D,(HL)
	MOVE.B 	0(A5,D1.W),D3 	;
	ROR.W 	#8,D3 	;
	ADDQ.W 	#1,D1 	; INC HL
	LEA 	PRTPTR(A5),A0 	; LD (PRTPTR),HL
	MOVE.B 	D1,(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D1,1(A0) 	;
	ROR.W 	#8,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
*				;;Check five digits found
	ROR.W 	#8,D3 	; LD A,D
	MOVE.B 	D3,D0 	;
	ROR.W 	#8,D3 	;
	OR.B 	D3,D0 	; OR E
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; RET Z
	BNE.S 	LAB.584 	;
	JMP 	SYS.RET(A5) 	;
LAB.584:
*				;;Find current digit
	ROR.W 	#8,D2 	; LD B,'0'
	MOVE.B 	#'0',D2 	;
	ROR.W 	#8,D2 	;
DD03 	EQU	*-PRG.STRT	;DD03
	 	 	;
	EOR.B 	D0,D0 	; XOR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,DE
	SUBX.W 	D3,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,DD04
	BCC.S 	LAB.585 	;
	JMP 	DD04(A5) 	;
LAB.585:
	ADD.W 	#$100,D2 	; INC B
	MOVE.B 	#1,D0 	; LD A,1
	MOVE.B 	D0,D2 	; LD C,A
	JMP 	DD03(A5) 	; JR DD03
*				;;
DD04 	EQU	*-PRG.STRT	;DD04
	 	 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.B 	D2,D0 	; LD A,C
	OR.B 	D2,D0 	; OR C
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,DD02
	BNE.S 	LAB.586 	;
	JMP 	DD02(A5) 	;
LAB.586:
	ROR.W 	#8,D2 	; LD A,B
	MOVE.B 	D2,D0 	;
	ROR.W 	#8,D2 	;
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	JMP 	DD02(A5) 	; JR DD02
*				;;
DD05 	EQU	*-PRG.STRT	;DD05
	 	 	;
	MOVE.B 	#'0',D0 	; LD A,'0'
	MOVE.W 	#OSWRCH,D7 	; CALL OSWRCH
	JSR 	SYS.JSR(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
DD06 	EQU	*-PRG.STRT	;DD06
	 	 	;
	DC.W 	10000 	; DEFW 10000
* Warning 1 : the bytes in above word(s) may not be in required order
	DC.W 	1000 	; DEFW 1000
* Warning 1 : the bytes in above word(s) may not be in required order
	DC.W 	100 	; DEFW 100
* Warning 1 : the bytes in above word(s) may not be in required order
	DC.W 	10 	; DEFW 10
* Warning 1 : the bytes in above word(s) may not be in required order
	DC.W 	1 	; DEFW 1
* Warning 1 : the bytes in above word(s) may not be in required order
	DC.W 	0 	; DEFW 0
* Warning 1 : the bytes in above word(s) may not be in required order
*				;;
*				;;-----
*				;;
*				;;Parse a number at (HL)
*				;;Returns 'Z' if nothing entered. 'C' if error.
*				;;Otherwise returns 'NZ', 'NC' and HL=value.
*				;;
READDECIMAL 	EQU	*-PRG.STRT	;READDECIMAL
	 	 	;
	MOVE.W 	#0,D3 	; LD DE,0
	MOVE.W 	#READEOLN,D7 	; CALL READEOLN ;Skip spaces
	JSR 	SYS.JSR(A5) 	;
	MOVE 	F(A5),SR 	; RET Z ;NULL found
	BNE.S 	LAB.587 	;
	JMP 	SYS.RET(A5) 	;
LAB.587:
*				;;
READDEC02 	EQU	*-PRG.STRT	;READDEC02
	 	 	;
	MOVE.B 	0(A5,D1.W),D0 	; LD A,(HL)
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READDEC04
	BNE.S 	LAB.588 	;
	JMP 	READDEC04(A5) 	;
LAB.588:
	CMP.B 	#',D0 	; CP ' '
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR Z,READDEC04
	BNE.S 	LAB.589 	;
	JMP 	READDEC04(A5) 	;
LAB.589:
	ADDQ.W 	#1,D1 	; INC HL
	SUB.B 	#'0',D0 	; SUB '0'
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR C,READDEC03 ;Error. Character < '0'
	BCC.S 	LAB.590 	;
	JMP 	READDEC03(A5) 	;
LAB.590:
	CMP.B 	#10,D0 	; CP 10
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; JR NC,READDEC03 ;Error. Character > '9'
	BCS.S 	LAB.591 	;
	JMP 	READDEC03(A5) 	;
LAB.591:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	SUBQ.W 	#2,D6 	; PUSH DE
	MOVE.W 	D3,0(A5,D6.W) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	#6554,D2 	; LD BC,6554
	AND.B 	D0,D0 	; AND A
	MOVE 	SR,F(A5) 	;
	MOVE 	F(A5),SR 	; SBC HL,BC
	SUBX.W 	D2,D1 	;
	MOVE 	SR,F(A5) 	;
	MOVE.W 	0(A5,D6.W),D3 	; POP DE
	ADDQ.W 	#2,D6 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR NC,READDEC03 ;Error. Number > 6553
	BCS.S 	LAB.592 	;
	JMP 	READDEC03(A5) 	;
LAB.592:
	SUBQ.W 	#2,D6 	; PUSH HL
	MOVE.W 	D1,0(A5,D6.W) 	;
	ROR.W 	#8,D1 	; LD H,D
	ROR.W 	#8,D3 	;
	MOVE.B 	D3,D1 	;
	ROR.W 	#8,D3 	;
	ROR.W 	#8,D1 	;
	MOVE.B 	D3,D1 	; LD L,E
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL
	MOVE 	SR,F(A5) 	;
	ADD.W 	D1,D1 	; ADD HL,HL
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	ROR.W 	#8,D3 	; LD D,0
	MOVE.B 	#0,D3 	;
	ROR.W 	#8,D3 	;
	MOVE.B 	D0,D3 	; LD E,A
	ADD.W 	D3,D1 	; ADD HL,DE
	MOVE 	SR,F(A5) 	;
	MOVE.W 	D3,-(SP) 	; EX DE,HL
	MOVE.W 	D1,D3 	;
	MOVE.W 	(SP)+,D1 	;
	MOVE.W 	0(A5,D6.W),D1 	; POP HL
	ADDQ.W 	#2,D6 	;
	MOVE 	F(A5),SR 	; JR NC,READDEC02
	BCS.S 	LAB.593 	;
	JMP 	READDEC02(A5) 	;
LAB.593:
*				;;Error. Number too big.
*				;;
READDEC03 	EQU	*-PRG.STRT	;READDEC03
	 	 	;
	OR.B 	#17,F+1(A6) 	; SCF ;Error
	JMP 	SYS.RET(A5) 	; RET 
*				;;
READDEC04 	EQU	*-PRG.STRT	;READDEC04
	 	 	;
	MOVE.B 	#1,D0 	; LD A,1
	OR.B 	D0,D0 	; OR A
	MOVE 	SR,F(A5) 	;
	JMP 	SYS.RET(A5) 	; RET 
*				;;
*				;;-----
*				;;
*				;;'Checksum' reserved as first byte following last byte of code:
CHKSUM 	EQU	*-PRG.STRT	;CHKSUM
	 	 	;
	DS.B 	1 	; DEFS 1
*				;;
COMPUTERTYPE 	EQU	*-PRG.STRT	;COMPUTERTYPE
	 	 	;
	DC.B 	0 	; DEFB 0 ;Default to 'Uknown'
*				;;
	DS.B 	&80 	; DEFS &80
STACK 	EQU	*-PRG.STRT	;STACK
	 	 	;
*				;;
PRTPTR 	EQU	*-PRG.STRT	;PRTPTR
	 	 	;
	DS.B 	2 	; DEFS 2
*				;;
BUFFER 	EQU	*-PRG.STRT	;BUFFER
	 	 	;
	DS.B 	LINELENGTH+1 	; DEFS LINELENGTH+1
BUFFEREND 	EQU	*-PRG.STRT	;BUFFEREND
	 	 	;
	DS.B 	1 	; DEFS 1
*				;;
SYSTEMFCB 	EQU	*-PRG.STRT	;SYSTEMFCB
	 	 	;
SYSTEMFCBDRIVE 	EQU	*-PRG.STRT	;SYSTEMFCBDRIVE DEFS 1
	DS.B 	1 	;
SYSTEMFCBNAME 	EQU	*-PRG.STRT	;SYSTEMFCBNAME DEFS 8
	DS.B 	8 	;
SYSTEMFCBTYPE 	EQU	*-PRG.STRT	;SYSTEMFCBTYPE DEFS 3
	DS.B 	3 	;
SYSTEMFCBEX 	EQU	*-PRG.STRT	;SYSTEMFCBEX DEFS 1
	DS.B 	1 	;
	DS.B 	19;h1,h2,rc,u0-uF 	; DEFS 19;h1,h2,rc,u0-uF
SYSTEMFCBCR 	EQU	*-PRG.STRT	;SYSTEMFCBCR DEFS 1
	DS.B 	1 	;
	DS.B 	3;r0-r2 	; DEFS 3;r0-r2
*				;;
*				;;----------------------------------------
0001 	EQU	*-PRG.STRT	;0001 ;MESSAGE.TXT to SQUASH.DAT compresser
	 	 	;
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
AFSAVE 	EQU	*-PRG.STRT	;AFSAVE DEFS 2
	DS.B 	2 	;
HLSAVE 	EQU	*-PRG.STRT	;HLSAVE DEFS 2
	DS.B 	2 	;
DESAVE 	EQU	*-PRG.STRT	;DESAVE DEFS 2
	DS.B 	2 	;
BCSAVE 	EQU	*-PRG.STRT	;BCSAVE DEFS 2
	DS.B 	2 	;
*				;;
*				;;If status messages requested holds 'Y':
NOISY 	EQU	*-PRG.STRT	;NOISY DEFS 1
	DS.B 	1 	;
*				;;
*				;;If in debug mode holds 'Y'.
DEBUG 	EQU	*-PRG.STRT	;DEBUG DEFS 1
	DS.B 	1 	;
*				;;
*				;;Maximum number of entries in 'Common Word Dictionary':
COMMONMAXENTRIES 	EQU	*-PRG.STRT	;COMMONMAXENTRIES DEFS 1
	DS.B 	1 	;
*				;;
*				;;UNSQUASH screen width:
WRAPWIDTH 	EQU	*-PRG.STRT	;WRAPWIDTH DEFS 1
	DS.B 	1 	;
*				;;
*				;;Length OF B:MESSAGE.TXT input file:
INPUTLENGTH 	EQU	*-PRG.STRT	;INPUTLENGTH DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of temporary file B:SQUASH.TMP
LENGTHSMT 	EQU	*-PRG.STRT	;LENGTHSMT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Input file line number for error reports:
LINENUM 	EQU	*-PRG.STRT	;LINENUM DEFS 2
	DS.B 	2 	;
*				;;
*				;;Message number:
MSGNUM 	EQU	*-PRG.STRT	;MSGNUM DEFS 2
	DS.B 	2 	;
*				;;
*				;;Serial input control block:
FCB1 	EQU	*-PRG.STRT	;FCB1
	 	 	;
	DS.B 	SERIALFCBLENGTH 	; DEFS SERIALFCBLENGTH
*				;;
*				;;Serial output control block:
FCB2 	EQU	*-PRG.STRT	;FCB2
	 	 	;
	DS.B 	SERIALFCBLENGTH 	; DEFS SERIALFCBLENGTH
*				;;
*				;;Address of serial SMT buffer:
STARTBUFFER 	EQU	*-PRG.STRT	;STARTBUFFER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Bytes left in serial buffer:
BUFFERSIZE 	EQU	*-PRG.STRT	;BUFFERSIZE DEFS 2
	DS.B 	2 	;
*				;;
*				;;Bytes unprocessed in serial buffe:
UNREADSIZE 	EQU	*-PRG.STRT	;UNREADSIZE DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 2 (Sort input file) workspace:
*				;;
*				;;Address following '[' or ':' in input buffer
*				;;(Also used by Phase 6 for Address of Message Descriptor Header Byte)
STARTMSG 	EQU	*-PRG.STRT	;STARTMSG DEFS 2
	DS.B 	2 	;
*				;;
*				;;Address of ']' in input buffer
ENDMSG 	EQU	*-PRG.STRT	;ENDMSG DEFS 2
	DS.B 	2 	;
*				;;
*				;;Non-zero if serial input EOF stored in buffer:
INPUTEOF 	EQU	*-PRG.STRT	;INPUTEOF DEFS 1
	DS.B 	1 	;
*				;;
*				;;Number of input characters excluding brackets
NUMCHARACTERS 	EQU	*-PRG.STRT	;NUMCHARACTERS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of messages:
NUMMESSAGES 	EQU	*-PRG.STRT	;NUMMESSAGES DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of characters in input file
*				;;entered in inverted case:
MODIFYCOUNT 	EQU	*-PRG.STRT	;MODIFYCOUNT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Last char/start-of-word input char
LASTSIGCHAR 	EQU	*-PRG.STRT	;LASTSIGCHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;Non-zero once warned about comments
SEENCOMMENT 	EQU	*-PRG.STRT	;SEENCOMMENT DEFS 1
	DS.B 	1 	;
*				;;
*				;;-----
*				;;
*				;;Phase 3 (Construct Frequency Table) workspace:
*				;;
STARTFT 	EQU	*-PRG.STRT	;STARTFT DEFS 2
	DS.B 	2 	;
*				;;
ENDFT 	EQU	*-PRG.STRT	;ENDFT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Two-byte count for estimated number of occurances of
*				;;each ascii code &00 thru &7F not part of a 'word':
CHARACTERCOUNTS 	EQU	*-PRG.STRT	;CHARACTERCOUNTS DEFS $100
	DS.B 	$100 	;
*				;;
*				;;Number of 'words' in 'Frequency Table':
NUMWORDS 	EQU	*-PRG.STRT	;NUMWORDS DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 5 (Find common words) workspace:
*				;;
STARTCWT 	EQU	*-PRG.STRT	;STARTCWT DEFS 2
	DS.B 	2 	;
*				;;
ENDCWT 	EQU	*-PRG.STRT	;ENDCWT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Occurrance count for 'current' frequency word:
*				;;(Also used in Phase 7 as a 'length')
FREQUENCYTIMES 	EQU	*-PRG.STRT	;FREQUENCYTIMES DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 6 (Construct Message Descriptors) workspace:
*				;;
CURRENTMDT 	EQU	*-PRG.STRT	;CURRENTMDT DEFS 2
	DS.B 	2 	;
*				;;
MAXMDT 	EQU	*-PRG.STRT	;MAXMDT DEFS 2
	DS.B 	2 	;
*				;;
*				;;Address within SMT entry of a character in a message:
WORDADDRESS 	EQU	*-PRG.STRT	;WORDADDRESS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Word-type character code for current word
WORDTYPE 	EQU	*-PRG.STRT	;WORDTYPE DEFS 1
	DS.B 	1 	;
*				;;
*				;;MODE flag for splitting into words/spaces/characters:
P6MODE 	EQU	*-PRG.STRT	;P6MODE DEFS 1
	DS.B 	1 	;
*				;;
*				;;Stored character for inclusion with leading/trailing spaces:
P6CHAR 	EQU	*-PRG.STRT	;P6CHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;Number of Message headers:
NUMMSGHEADS 	EQU	*-PRG.STRT	;NUMMSGHEADS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of message skip bytes:
NUMJUMPHEADS 	EQU	*-PRG.STRT	;NUMJUMPHEADS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of short references
NUMSHORTREFS 	EQU	*-PRG.STRT	;NUMSHORTREFS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of long references:
NUMLONGREFS 	EQU	*-PRG.STRT	;NUMLONGREFS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of current message:
MESSAGELENGTH 	EQU	*-PRG.STRT	;MESSAGELENGTH DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of keywords defined in current message:
NUMKEYWORDS 	EQU	*-PRG.STRT	;NUMKEYWORDS DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length of ICF file (B:SQUASH2.TMP)
LENGTHICF 	EQU	*-PRG.STRT	;LENGTHICF DEFS 2
	DS.B 	2 	;
*				;;
*				;;Length if Message Descriptors (in ICF)
INDEXMD 	EQU	*-PRG.STRT	;INDEXMD DEFS 2
	DS.B 	2 	;
*				;;
LENGTHMD 	EQU	*-PRG.STRT	;LENGTHMD DEFS 2
	DS.B 	2 	;
*				;;
STARTCONVERTEDMSG 	EQU	*-PRG.STRT	;STARTCONVERTEDMSG DEFW 0 ;Address of last message header
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
INDEXWD 	EQU	*-PRG.STRT	;INDEXWD DEFS 2
	DS.B 	2 	;
*				;;
LENGTHWD 	EQU	*-PRG.STRT	;LENGTHWD DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Phase 8 (Construct Index) workspace:
*				;;
*				;;Length of MD+WD+WDI
INDEXWDI 	EQU	*-PRG.STRT	;INDEXWDI DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of Dictionary segments
NUMSEGS 	EQU	*-PRG.STRT	;NUMSEGS DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Output file checksum
FINALCHECKSUM 	EQU	*-PRG.STRT	;FINALCHECKSUM DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointer into BUFFER for packing/unpacking 5-bit codes:
*				;;(Also used by 'Construct Message Descriptors'
READWRITEPOINTER 	EQU	*-PRG.STRT	;READWRITEPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Pointer to the start of a 5-byte (40 bits) byte-aligned
*				;;in the 'Word Dictionary':
BLOCKPOINTER 	EQU	*-PRG.STRT	;BLOCKPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;Current segment group
SEGNUM 	EQU	*-PRG.STRT	;SEGNUM DEFS 1
	DS.B 	1 	;
*				;;
*				;;Last byte stored in dictionary
LASTBYTE 	EQU	*-PRG.STRT	;LASTBYTE DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointers into byte-aligned boundaries of 'Word Dictionary':
SEGMENTADDRESSES 	EQU	*-PRG.STRT	;SEGMENTADDRESSES
	 	 	;
	DS.B 	416 	; DEFS 416 ; 26*4*4
*				;;
*				;;Pointer into next free pointer in SEGMENTADDRESSES:
LASTPOINTER 	EQU	*-PRG.STRT	;LASTPOINTER
	 	 	;
	DS.B 	2 	; DEFS 2
*				;;
*				;;Current word during 'Word Dictionary' construction:
WORDNUMBER 	EQU	*-PRG.STRT	;WORDNUMBER DEFS 2
	DS.B 	2 	;
*				;;
*				;;First three characters (padded with nulls) of
*				;;word in 'Word Dictionary':
THREECHARACTERS 	EQU	*-PRG.STRT	;THREECHARACTERS
	 	 	;
	DS.B 	4 	; DEFS 4
*				;;
*				;;Non-zero if current dictionary word is all upper-case
WORDCASE 	EQU	*-PRG.STRT	;WORDCASE
	 	 	;
	DS.B 	1 	; DEFS 1
*				;;
*				;;-----
*				;;
*				;;Conversion READ address:
READPOSITION 	EQU	*-PRG.STRT	;READPOSITION DEFS 2
	DS.B 	2 	;
*				;;
*				;;Conversion WRITE address:
WRITEPOSITION 	EQU	*-PRG.STRT	;WRITEPOSITION DEFS 2
	DS.B 	2 	;
*				;;
*				;;Number of chars output to B:MESSAGE.TXT since
COLUMN 	EQU	*-PRG.STRT	;COLUMN DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Pointer into THREECHARACTERS for reverse-squash:
HEADERPOINTER 	EQU	*-PRG.STRT	;HEADERPOINTER DEFS 2
	DS.B 	2 	;
*				;;
*				;;-----
*				;;
*				;;Current cursor column:
NCHARS 	EQU	*-PRG.STRT	;NCHARS DEFS 1
	DS.B 	1 	;
*				;;
*				;;Pointer into BUFFER for word-wrap:
CURBUF 	EQU	*-PRG.STRT	;CURBUF DEFS 2
	DS.B 	2 	;
*				;;
*				;;Last non-space character printed as part of an unsquashed
*				;;message. Used to decide upper/lower case:
LASTCHAR 	EQU	*-PRG.STRT	;LASTCHAR DEFS 1
	DS.B 	1 	;
*				;;
*				;;True if next time BUFFER is printed it should
*				;;preceeded by a space (or newline) character:
PENDSPACE 	EQU	*-PRG.STRT	;PENDSPACE DEFS 1
	DS.B 	1 	;
*				;;
*				;;-----
*				;;
*				;;Memory here to just below BIOS allocated dynamically
*				;;at run-time for tables/buffers:
*				;;
STARTTABLEMEMORY 	EQU	*-PRG.STRT	;STARTTABLEMEMORY
	 	 	;
*				;;
*				;;-----*
**************** System Routines and Utilities ******************
*
SYS.JSR EQU     *-PRG.STRT      Subroutine Jump:
        MOVE.L  (SP)+,A0        Get return link
        SUBA.L  A5,A0           Make relative to A5
        SUBQ.W  #2,D6           Decrease Z80 SP
        MOVE.W  A0,0(A5,D6.W)   Push link
        JMP     0(A5,D7.W)      Jump via rel. address in D7
*
SYS.RET EQU     *-PRG.STRT      Subroutine Return:
        MOVE.W  0(A5,D6.W),D7   Put link in D7
        ADDQ.W  #2,D6           Adjust Z80 SP
        JMP     0(A5,D7.W)      Return
*
SYS.DJNZ EQU    *-PRG.STRT      Z80 DJNZ:
        ROR.W   #8,D2           Access B
        SUBQ.B  #1,D2           Decrease B
        BEQ.S   S.DJNZ1         Branch if B zero ...
        ADDQ.L  #4,SP           Otherwise ... remove link
        ROR.W   #8,D2           Restore BC
        JMP     0(A5,D7.W)      Jump to label in D7
S.DJNZ1 ROR.W   #8,D2           B zero ... restore BC
        RTS                     Return via link on stack
*
SYS.LDIR EQU    *-PRG.STRT      Z80 LDIR:
        MOVEQ   #1,D7           Put increment in D7
        BRA.S   S.LDIDR         Go to common routine
*
SYS.LDDR EQU    *-PRG.STRT      Z80 LDDR:
        MOVEQ   #-1,D7          Put increment in D7
S.LDIDR MOVE.B  0(A5,D1.W),0(A5,D3.W)  Common routine - move byte
        ADD.W   D7,D1           Adjust HL
        ADD.W   D7,D3           Adjust DE
        SUBQ.W  #1,D2           Decrement BC
        BNE.S   S.LDIDR         Loop if BC not zero
        AND.B   #29,F+1(A5)     Reset overflow bit
        RTS                     Return
*
SYS.LDI EQU     *-PRG.STRT      Z80 LDI:
        MOVE.B  0(A5,D1.W),0(A5,D3.W)  Move byte
        ADDQ.W  #1,D1           Increment HL
        ADDQ.W  #1,D3           Increment DE
        BRA.S   S.LDID          Go to Common routine
*
SYS.LDD EQU     *-PRG.STRT      Z80 LDD:
        MOVE.B  0(A5,D1.W),0(A5,D3.W)  Move byte
        SUBQ.W  #1,D1           Decrement HL
        SUBQ.W  #1,D3           Decrement DE
S.LDID  SUBQ.W  #1,D2           Common routine - Decrement BC
        BEQ.S   S.LDID1         Test for BC zero
        OR.B    #2,F+1(A5)      Set overflow if BC non-zero
        RTS                     Return
S.LDID1 AND.B   #29,F+1(A5)     Reset overflow if BC zero
        RTS                     Return
*
SYS.CPIR EQU    *-PRG.STRT      Z80 CPIR:
        MOVEQ   #1,D7           Set D7 to increment
        BRA.S   S.CPIDR         Go to common routine
*
SYS.CPDR EQU    *-PRG.STRT      Z80 CPDR:
        MOVEQ   #-1,D7          Set D7 to increment
S.CPIDR AND.B   #17,F+1(A5)     Common routine - reset sign,zero,overflow
S.CPIDR1 CMP.B  0(A5,D1.W),D0   Loop - compare (HL) with A
        BEQ.S   S.CPIDR2        Exit if equal
        ADD.W   D7,D1           Adjust HL
        SUBQ.W  #1,D2           Decrement BC
        BNE.S   S.CPIDR1        Loop if BC non-zero
        BRA.S   S.CPIDR3        Otherwise go to common return
S.CPIDR2 OR.B   #4,F+1(A5)      Match found - Set zero flag
        SUBQ.W  #1,D2           Decrement BC once more
        BNE.S   S.CPIDR3        Take common return if more
        OR.B    #2,F+1(A5)      Set sign flag if last byte
S.CPIDR3 ADD.W  D7,D1           Common return - move HL on
        RTS                     Return
*
SYS.CPI EQU     *-PRG.STRT      Z80 CPI:
        MOVE.B  0(A5,D1.W),D7   Move byte to D7
        ADDQ.W  #1,D1           Increment HL
        BRA.S   S.CPID          Go to common routine
*
SYS.CPD EQU     *-PRG.STRT      Z80 CPD:
        MOVE.B  0(A5,D1.W),D7   Move byte to D7
        SUBQ.W  #1,D1           Decrement HL
S.CPID  AND.B   #17,F+1(A5)     Common routine - reset sign,zero,overflow
        SUBQ.W  #1,D2           Decrement BC
        BNE.S   S.CPID1         Test for BC zero
        OR.B    #2,F+1(A5)      BC zero - set overflow
S.CPID1 CMP.B   D7,D0           Compare bytes
        BNE.S   S.CPID2         Test for equal
        OR.B    #4,F+1(A5)      Bytes match - set sign
S.CPID2 RTS                     Return
*
SYS.EXX EQU     *-PRG.STRT      Z80 EXX:
        MOVEM.W D1-D3,-(SP)     Save HL BC DE on stack
        MOVEM.W ALT.REGS+2(A5),D1-D3  Restore alt. reg. set
        MOVE.L  (SP)+,ALT.REGS+2(A5)  Shift saved values
        MOVE.W  (SP)+,ALT.REGS+6(A5)
        RTS                     Return
*
SYS.EXAF EQU    *-PRG.STRT      Z80 EX AF,AF':
        MOVE.B  D0,F(A5)        Move A
        MOVE.W  F(A5),-(SP)     Stack AF
        MOVE.W  ALT.REGS(A5),F(A5) Use alt.regs ...
        MOVE.B  F(A5),D0        ... setting A
        MOVE.W  (SP)+,ALT.REGS(A5)  Saved stacked values
        RTS                     Return
*
SYS.EXDE EQU    *-PRG.STRT      Z80 EX DE,HL:
        MOVE.W  D3,-(SP)        Save DE
        MOVE.W  D1,D3           HL -> DE
        MOVE.W  (SP)+,D1        Old DE -> HL
        RTS                     Return
*
SYS.DAA EQU     *-PRG.STRT      Hooks for unimplemented DAA RLD RRD
SYS.RLD EQU     *-PRG.STRT
SYS.RRD EQU     *-PRG.STRT
*
SYS.RST EQU     *-PRG.STRT      Embryo Z80 RST routine:
* ........ operand value is in D7 .....................
* ........ fill in with code as required ..............
        RTS
*
        END
