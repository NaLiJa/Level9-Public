; Code generation section specific to particular processors
;
; 8086 version. N.W.Austin 18/7/88
;
; Copyright (C) 1988 Level 9 Computing
;
; last change 18/7/88

;Gamedata segment contains:
;  0,1      PC for return to acode
;  2,3      Acode INT segment
;  4,5      Address of start of table 0
;  6,7      Segment paragraph containing table 0
;  8-35     addresses of lists 1 thru 9
;  36-141   addresses of lists 10 thru 31
;  142      RET instrction
;  143      Not used
;  144-2191 Vars and temp lists
;  2192+    Gamedata (includes acode and permanent tables)

PCListVector=4
PCvarsoffset=144

;-----
StartUpMessage
 bsr compprs
 dc.b cr
 dc.b 15 * switch off paging
 dc.b "68000 Acode to 8086 cross-compiler 1.5",cr
 dc.b "Copyright (C) 1989 Level 9 Computing.",cr
 dc.b "Mike Austin 14/8/89",cr
 dc.b "Nick Austin 15/2/89",cr,0
 even
 rts
;-----

MCPush
 bsr compgetvar
 lea DataPush,a0
 bra.s MCPushPop

;----

MCPop
 bsr CompGetVar
 lea DataPop,a0
MCPushPop
 move.w d0,d4 * save var number
 asl.w #1,d4 * double var number
 add.w #PCvarsoffset,d4
 bsr compsearch
 bra Generate
;---
MCASR
 bsr CompGetVar
 lea DataAsr,a0
 move.w d0,d4 * save vr number
 asl #1,d4 * double var number
 add.w #PCvarsoffset,d4
 bsr compsearch
 bra Generate

;---
MCAnd
 lea DataAndVV,a0
 bra MCaddsub

MCOr
 lea DataOrVV,a0
 bra MCAddSub

MCXor
 lea DataXorVV,a0
 bra MCAddSUb
;---
MCData
 lea opcodeaddress,a0
 lea jumpdummyopcode,a1
 move.l a1,(a0)
 bsr CompSearch
 cmp.b #'@',d0
 bne.s MCData1
 addq.l #1,ptr
MCData1
 bsr MCDataEntry * MCLongJump * jumpstuff
 bsr compsearch
 addq.l #1,ptr * skip over comma
 cmp.b #",",d0
 beq.s MCData
 cmp.b #";",d0
 beq compssskiptoeol
 rts
*---
MCDataEntry
;!nick 1/8/88 lea OpcodeAddress,a0
;!nick 1/8/88 lea DummyLongOpcode,a1
;!nick 1/8/88 move.l a1,(a0)
 bsr getlabel

; try to ignore code state for data statements
; move.b CodeStateOffset(a0),d1
; beq.s MCCantCheck1
; cmp.b CodeState,d1
; bne WrongCodeState
;MCCantCheck1

* d0.w is value of label relative to start of acode
;* find current address relative to start
; move.l compacodeptr,d1
; sub.l startacode,d1
; sub.l d1,d0 * find offset of destination from current?
;**********

 ror.w #8,d0
 bsr Code
 ror.w #8,d0
 bra Code

*---

MCToAcode
;! nick 18/7/88
; generate code to switch execution from machine code to ACODE
 move.l CompAcodePtr,d4 * first arg
 sub.l StartAcode,d4    * relative to start of acode
 add.l #9,d4            * make it address of the next instruction

* to the start of the first acode instruction to be executed
 Lea DataToAcode,a0
 bra Generate

*---

MCReturn
 lea DataReturn,a0
 bra Generate

MCLetVC
* unusual in that it is called by BSR from LetVC
* are we in MC mode?
 move.b CodeState,d1
 cmp.b #'-',d1
 beq.s MCLetVcRet
 addq.l #4,sp * lose return address
* d0.W = constant value
 move.w d0,d5 * into second arg
* (sp).w = variable number
 move.w (sp)+,d4 * constant
 asl.w #1,d4 * give offset into variable table
 add.w #PCvarsoffset,d4
 lea DataLetVC,a0
 bsr Generate
 bra MainProgLoop * finished compiling this statement

MCLetVcRet
MCLetVVRet
 rts
;---
MCLetVV
* unusual in that it is called by BSR from LetVV
* are we in MC mode?
 move.b CodeState,d1
 cmp.b #'-',d1
 beq.s MCLetVVRet
 addq.l #4,sp * lose return address
* ValueOffset(a0).w = constant value
 move.w ValueOffset(a0),d5 * into second arg
* (sp).w = variable number
 move.w (sp)+,d4 * var to write to
 asl.w #1,d4 * give offset into variable table
 add.w #PCvarsoffset,d4
 asl.w #1,d5 * give offset into variable table
 add.w #PCvarsoffset,d5
 lea DataLetVV,a0
 bsr Generate
 bra MainProgLoop * finished compiling this statement
;---
MCAdd
 lea DataAddVV,a0
 bra.s MCaddsub

MCSub
 lea DataSubVV,a0

MCaddsub
 move.l a0,-(sp) * save generation table address
 bsr compgetvar
 move.w d0,d4 * save var number
 bsr compsearch
 cmp.b #",",d0
 bne commaexpected
 addq.l #1,ptr * skip over comma
 bsr compgetvar
 move.w d0,d5 * first var - result of add
 asl.w #1,d4 * double to give offset in var table
 asl.w #1,d5 * double to give offset in var table
 add.w #PCvarsoffset,d4
 add.w #PCvarsoffset,d5
 move.l (sp)+,a0 * restore generation table address
 bra Generate
*---
MCAttRet
 rts
*---
MCAttVar
 move.b CodeState,d0
 cmp.b #'-',d0
 beq.s MCAttRet
 addq.l #4,sp * lose return address

* (sp).w = table number
* valueOffset(a0) = index
 move.w ValueOffset(a0),-(sp) * index
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

 move.w (sp)+,d5 * index
 move.w (sp)+,d4 * table number
 move.w d0,d6 * var to assign from
 asl.w #2,d4 * quadruple index - long pointers
 asl.w #1,d5 * double var number
 asl.w #1,d6 * double var number
 add.w #PCListVector,d4
 add.w #PCvarsoffset,d5
 add.w #PCvarsoffset,d6

 lea DataAttVV,a0
 lea DataAttVV16,a1
 bra TableGenerate

MCAttCRet
 rts

*---

MCAttConst
 move.b CodeState,d2
 cmp.b #'-',d2
 beq.s MCAttCRet
 addq.l #4,sp * lose return address

* (sp).w = table number
* d0.w = index
* generate code for table(c)=v
 move.w d0,-(sp) * index

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

 move.w (sp)+,d5 * index - constant - second arg
 move.w (sp)+,d4 * table number
 move.w d0,d6 * var to assign from
 asl.w #1,d6 * double var to give vartbl offset
 asl.w #2,d4 * quadruple table number to give ptr table offset
 add.w #PCvarsoffset,d6
 add.w #PCListVector,d4

 lea DataAttCV,a0 
 lea DataAttCV16,a1
 bra TableGenerate

MCAftRet
 rts

*-----
MCAft * ttVar
* called as soon as the table reference has been parsed
 move.b CodeState,d1
 cmp.b #'-',d1
 beq.s MCAftRet
 addq.l #4,sp * lose return address

 move.w valueoffset(a0),-(sp) * table number
 bsr compsearch
 cmp.b #"(",d0
 bne bracketsexpected
 addq.l #1,ptr
 bsr findsymbol
 or.b #$80,typeoffset(a0) ; set "USED" bit
 tst.b d0
 bne MCaftmaybenumeric
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #vartype,d0
 beq MCaftvar
 cmp.b #constanttype,d0
 bne badindex
* a manifest constant
 move.w valueoffset(a0),d0 * value of constant
; move.b #$c0,d1 * base value for var=table(c)
 bra.s MCaftconst
;---
MCaftmaybenumeric
 bsr getnumberconstant * will print an error message if not
; move.b #$C0,d1 * base value for var=table(c)

MCaftconst
 move.w d0,-(sp) * table index
 bsr compsearch
 cmp.b #")",d0
 bne bracketsexpected
 addq.l #1,ptr * skip brackets
* now generate the code

 move.w (sp)+,d6 * index
 move.w (sp)+,d5 * V *table number
 move.w (sp)+,d4 * v1
 asl.w #1,d4 * double v1
 asl.w #2,d5 * quadruple table number
 add.w #PCvarsoffset,d4
 add.w #PCListVector,d5

 lea DataAftVC,a0
 lea DataAftVC16,a1
 bra TableGenerate

*---

MCaftvar
; move.b #$A0,d1 * base value for var=table(v)
 move.w valueoffset(a0),-(sp) * table index
 bsr compsearch
 cmp.b #")",d0
 bne bracketsexpected
 addq.l #1,ptr * skip brackets
* now generate the code
 move.w (sp)+,d6 * index - third arg
 move.w (sp)+,d5 * table number - second arg
 move.w (sp)+,d4 * var to assign to - first arg
 exg d4,d6
 asl.w #1,d4
 asl.w #2,d5
 asl.w #1,d6
 add.w #PCvarsoffset,d4
 add.w #PCListVector,d5
 add.w #PCvarsoffset,d6

 lea DataAftVV,a0
 lea DataAftVV16,a1
 bra TableGenerate
; bsr Generate
; rts

;* first put in opcode - base value+table number
; move.w $2(sp),d0 * table number
; or.b d1,d0 * or (add) in base
; bsr code
;
;* and the index
; move.w (sp),d0
; cmp.w #$100,d0
; bcc badindex * single byte index only
; bsr code
;
;* now thing not inside the brackets
; move.w $4(sp),d0
; bsr code
;
; addq.l #6,sp
; rts
;
*---
TableGenerate
* use A0.L as generation table pointer in 8 bit table mode,
* or A1.L in 16 bit mode
 move.b SixteenFlag,d0
 beq Generate
 move.l a1,a0
 bra Generate
*---

TableNumberInReg: dc.w 0

;-----

MCgoto
 bsr compsearch
 lea DataShortGoto,a0
 cmp.b #"@",d0
 bne.s MCShortGoto
 addq.l #1,ptr

MCLongGoto
 lea DataLongGoto,a0
 bsr Generate
 bra.s MCLongJump

MCShortGoto
 move.b forcedlongjumps,d0
 bne.s MCLongGoto
 lea DataShortGoto,a0
 bsr Generate
 bra.s MCShortJump
;---
MCgosub
 bsr compsearch
 cmp.b #"@",d0 ;!8086 does not have short gosub, so junk '@'
 bne.s MCShortGosub
 addq.l #1,ptr
MCLongGosub
MCShortGosub ;!
 lea DataLongGosub,a0
 bsr Generate
;! bra.s MCLongJump

;!MCShortGosub
;! move.b forcedlongjumps,d0
;! bne.s MCLongGosub
;! lea DataShortGosub,a0
;! bsr Generate
;! lea opcodeaddress,a0
;! bra.s MCShortJump
;---
MCLongjump
 lea OpcodeAddress,a0
 lea DummyLongOpcode,a1
 move.l a1,(a0)
 bsr getlabel

 move.b CodeStateOffset(a0),d1
 beq.s MCCantCheck1
 cmp.b CodeState,d1
 bne WrongCodeState
MCCantCheck1

;!nick 20/7/88 long-jump short and long gosubs to defined label.
;!nick 20/7/88 (short gosub generates long gosub code)

* d0.w is value of label relative to start of acode
* find current address relative to start
 move.l compacodeptr,d1
 sub.l startacode,d1
 sub.l d1,d0 * find offset of destination from current?
 subq.l #2,d0 ;!nick 20/7/88 offset is from next instruction
 bsr Code ;!nick 20/7/88 Lo byte firest
 ror.w #8,d0
;! bsr Code
;! ror.w #8,d0
 bra Code

MCShortJump
 move.b forcedlongjumps,d0
 bne.s MCLongJump
* relative jump, so set relbit in opcode
; move.l opcodeaddress,a0
; or.b #relmask,(a0) * set relbit
 lea OpcodeAddress,a0
 lea DummyShortOpcode,a1
 move.l a1,(a0)
 bsr getlabel

 move.b CodeStateOffset(a0),d1
 beq.s MCCantCheck2
 cmp.b CodeState,d1
 bne WrongCodeState
MCCantCheck2

;!nick 20/7/88 Short jump to defined label (8086 can't short-gosub)

* d0.w is value of label relative to start of acode
* find current address relative to start
 move.l compacodeptr,d1
 sub.l startacode,d1
 addq.l #1,d1 * short relative is relative to start of next instruction
 sub.l d1,d0 * how close are current and destination?
 cmp.w #$80,d0 ;>>was $100
 bcs code * unsigned < - ok!
 cmp.w #$FF80,d0 ;>>was $ff00
 bcs reljumpoutofrange * unsigned <
 bra code
*---

MCrfr
 move.l StartAcode,a1
 move.l compacodeptr,d3
 sub.l a1,d3 * sub startacode,d3 - d3=current offset in acode

 clr.l d1
 move.w $6(a0,d0),d1 * offset of opcode
 move.l a1,a2
 add.l d1,a2
 move.b (a2),d2 * move.b $0(a1,d1),d2 * opcode

 move.w d1,d4 * preserve offset of opcode
 cmp.w #(((JumpDummyOpcode-StartFile)&$FFFF)-LengthOffset+2),d1
 bne.s MCRFRNotData
; DATA is relative to acode start, unlike everything else
 move.w $4(a0,d0),d1 * offset of reference
 add.w d1,d3 * add on position
 add.w #2,d3

MCRFRNotData
* poke back in address for a long jump
 clr.l d1
 move.w $4(a0,d0),d1 * offset of reference
 move.l a1,a2
 add.l d1,a2 * (a2)=reference to change

 cmp.w #(((DummyShortOpcode-StartFile)&$FFFF)-LengthOffset+2),d4
 beq MCRFRShort * a short jump
 sub.l d1,d3 * d3=label-ref - i.e. make relative

 cmp.l #$8000,d3
 bcs.s MCrfrOk
 cmp.l #$ffff8000,d3
 bcs MCTooFar

MCrfrOk
* poke back two-byte reference
 subq.w #2,d3 * relative to instruction AFTER the current one
 move.b d3,(a2) * move.b d3,$1(a1,d1) * low byte
 lsr.w #8,d3
 move.b d3,1(a2) *   move.b d3,$0(a1,d1) * high byte
 rts
*-
MCrfrshort
* poke back in address for short jump
* make it relative to address of reference
 move.w $4(a0,d0),d1 * offset of reference
 subq.w #1,d3 * relative to start of next instruction after Bra.s
* so change the wrong one (should add.w #1,d1 logically) to avoid
* corrupting d1.w
 sub.w d1,d3 * d3=label-ref
 cmp.w #$80,d3 ; >>was $100!
 bcc forwardoutofrange * note special line number treatment
 move.b d3,(a2) * move.b d3,$0(a1,d1) * poke in single byte reference
 rts
*---


 ifne 0
;!Insert forward reference when used from machine code

MCrfr
 move.l compacodeptr,d3
 and.l #$0000ffff,d1
 add.l d1,a1 * get actual address within acode area

 sub.l a1,d3 * sub startacode,d3 - d3=current offset in acode
 move.w $6(a0,d0),d1 * offset of opcode
; move.b $0(a1,d1),d2 * opcode
 move.b (a1),d2 * opcode

 and.b #relmask,d2 *is this a jump? ;!nick 1/8/88
 bne mcrfrjump                      ;!nick 1/8/88

* poke back in address for DATA           ;!nick 1/8/88
 move.w $4(a0,d0),d1 ;offset of reference ;!nick 1/8/88

;>>Mike 4/8/89 - to handle larger acodes
 move.b d3,$0(a1) * low byte           ;!nick 20/7/88
 lsr.w #8,d3                              ;!nick 1/8/88
 move.b d3,$1(a1) * high byte          ;!nick 20/7/88

; move.b d3,$0(a1,d1) * low byte           ;!nick 20/7/88
; lsr.w #8,d3                              ;!nick 1/8/88
; move.b d3,$1(a1,d1) * high byte          ;!nick 20/7/88
 rts

mcrfrjump                               ;!nick 1/8/88
; move.b $0(a1,d1),d2 * opcode           ;!nick 1/8/88
 move.b (a1),d2 * opcode
 and #smallmask,d2 *is this a long jump ;!nick 1/8/88
 bne MCrfrshort * No!                   ;!nick 1/8/88

* poke back in address for a long jump
 move.w $4(a0,d0),d1 * offset of reference
 sub.w d1,d3 * d3=label-ref - i.e. make relative
* poke back two-byte reference
 subq.l #2,d3 ;!nick 20/7/88 long-jump and gosubs are 'from' next instruction
 move.b d3,(a1) * low byte ;!nick 20/7/88
 lsr.w #8,d3
 move.b d3,$1(a1) * high byte ;!nick 20/7/88

; move.b d3,$0(a1,d1) * low byte ;!nick 20/7/88
; lsr.w #8,d3
; move.b d3,$1(a1,d1) * high byte ;!nick 20/7/88
 rts
*-
MCrfrshort
* poke back in address for short jump
* make it relative to address of reference
 move.w $4(a0,d0),d1 * offset of reference
 subq.w #1,d3 * relative to start of next instruction after Bra.s
* so change the wrong one (should add.w #1,d1 logically) to avoid
* corrupting d1.w
 sub.w d1,d3 * d3=label-ref
 cmp.w #$80,d3 ; >>was $100!
 bcc forwardoutofrange * note special line number treatment
 move.b d3,(a1) * poke in single byte reference

; move.b d3,$0(a1,d1) * poke in single byte reference
 rts
 endc
*---
MCIF
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
 beq MCif1
* only other possibility is a number
 bsr getnumberconstant
* d0.w = value
 move.l a6,a0
 move.w d0,valueoffset(a0) * use driverbuffer
* as temporary workspace - surely no-one will mind?
* - sets up value so it is retrieved correctly by later code
 bra.s MCifvc
MCif1
 or.b #$80,typeoffset(a0) ; set "USED" bit
 move.b typeoffset(a0),d0
 and.b #$7f,d0 ; remove "used" bit
 cmp.b #vartype,d0
 beq.s MCifvv
 cmp.b #constanttype,d0
 bne badtype
MCifvc
 move.w (sp)+,d1 * operator type 
 move.w (sp)+,d4 * first var - first argument
 asl.w #1,d4 * double to give offset
 add.w #PCvarsoffset,d4
 move.w ValueOffset(a0),d5 * constant - second argument

 lea MCIfVCTable,a0

MCifcommon
* given d4.w,d5.w as two args for the comparison stage,
* and a0.w as basic IF V C/V Table
* and d1.b as the comparator type, generate the code:
 and.w #$00FF,d1 * ensure top bits are clear
 asl.w #2,d1 ;'MCIfV' tables are 4-byte entries
 add.w d1,a0
* still need to add 16 if it's going to be a Long jump
 movem.l d4-d5/a0,-(sp) * save ptrs

* skip over "THEN" if present, then evaluate jump address
 bsr compsearch
 lea thenstring,a3
 move.w #0,d1
 bsr stringcompare
* stringcompare automatically skips string if matched
* is this a short or a long jump?
 bsr compsearch
 cmp.b #"@",d0
 bne.s MCShortIf
 addq.l #1,ptr * skip over "@"

MCLongIf
 movem.l (sp)+,d4-d5/a0 * restore ptrs
 add.l #16,a0 * move to long if table
 move.l (a0),a0 * address of data for this kind of IF
 bsr Generate
 bra MCLongJump

MCShortIf
 move.b forcedlongjumps,d0
 bne.s MCLongIf

 movem.l (sp)+,d4-d5/a0 * restore ptrs
 move.l (a0),a0 * address of data for this kind of IF
 bsr Generate
 bra MCShortJump
*---
MCifvv
 move.w (sp)+,d1 * operator type
 move.w (sp)+,d4 * first var number
 move.w valueoffset(a0),d5 * second var number
 asl.w #1,d4 * double to give offset in var table
 asl.w #1,d5 * double to give offset in var table bra.s MCifcommon
 add.w #PCvarsoffset,d4
 add.w #PCvarsoffset,d5

 lea MCIfVVTable,a0
 bra.s MCifcommon
*---
MCIfVVTable
* first the short branch versions...
 dc.l DataIfEQVVShort
 dc.l DataIfNEVVShort
 dc.l DataIfLTVVShort
 dc.l DataIfGTVVShort

 dc.l DataIfEQVVLong
 dc.l DataIfNEVVLong
 dc.l DataIfLTVVLong
 dc.l DataIfGTVVLong

McIfVCTable
 dc.l DataIfEQVCShort
 dc.l DataIfNEVCShort
 dc.l DataIfLTVCShort
 dc.l DataIfGTVCShort

 dc.l DataIfEQVCLong
 dc.l DataIfNEVCLong
 dc.l DataIfLTVCLong
 dc.l DataIfGTVCLong
;---
;---
MCPrint
MCMessage
*MCMessageC
MCFunction
MCInput
MCCHangeCode
MCCall
MCExit
MCScreen
MCPicture
MCGetNext
MCPrintInput
MCDriverOpcode
MCRandom
MCSave
MCRestore
MCClear
MCStack
MCPrs
MCCLS

MCJump
MCAcodePrs
 bra NotAllowedInMC

MCBreakPt
 lea DataBreakPt,a0
 bra generate

DataBreakPt
 dc.w 1
 dc.w $00CC

;----

Generate
; given (a0.l) as the code data for the current instruction
; d4.w is first argument, d5.w is second argument, d6.w is third argument
* check that code ptr is even.
;! move.l CompAcodePtr,d0
;! btst #0,d0
;! bne EvenError

 move.w (a0)+,d7 * length of this code fragment
Generate1
 tst.b d7 * end of code?
 beq.s GenerateRet
 move.w (a0)+,d0
* which argument do we want?
 move.w d4,d1 * d4.w is first argument
 btst #14,d0
 bne.s Generate2 * correct argument
 move.w d5,d1 * d5.w is second argument
 btst #13,d0
 bne.s Generate2
 move.w d6,d1 * d6.w is third argument
 btst #12,d0
 bne.s Generate2
* don't use argument - use d0.b instead (i.e. low byte from table)
 move.w d0,d1
 bra.s Generate3 * no argument

Generate2
* add anything to argument?
 clr.w d2
 move.b d0,d2 * low byte of d0.w is 8-bit offset
 ext.w d2
 add.w d2,d1

* use high/low byte of argument?
 btst #15,d0
 beq.s Generate3 * use low byte
 lsr.w #8,d1 * use high byte of word

Generate3
 move.b d1,d0 * got code

Generate4
 bsr Code
 subq.b #1,d7
 bra.s Generate1

GenerateRet
 rts
;---
* data tables for ALL instructions
* one word per byte which goes into code.
* If the high byte of the word is zero, the low byte
* is used immediately as code.
* if the high byte is non-zero, it codes information as follows:
* codes information as follows:
* bit 15 set: use high byte of argument as byte of code
* bit 14 set: substitute argument 1 for the current byte
* bit 13 set: substitute argument 2 for the current byte

* convention: arguments are given in the same order as in
* the acode source.

DataShortGoto
* jmp short
 dc.w 1
 dc.w $00EB

DataLongGoto
* jmp near
 dc.w 1
 dc.w $00E9

DataLongGosub
* call near
 dc.w 1
 dc.w $00E8

DataReturn
* ret near
 dc.w 1
 dc.w $00C3

DataToAcode
* mov bx,offset label
* mov di,0
* jmp far cs:[di]
*label:
 dc.w 9 ;length also used in 'MCToAcode'
 dc.w $00BB
 dc.w $4000,$C000 ;D4.w
 dc.w $00BF
 dc.w $0000
 dc.w $0000
 dc.w $002E
 dc.w $00FF
 dc.w $002D

* mov bx,offset label
* jmp word ptr cs:0 ;indexed intra-segment jmp
*label:
;> dc.w 8
;> dc.w $00BB
;> dc.w $4000,$C000 ;D4.w
;> dc.w $002E
;> dc.w $00FF,$0026
;> dc.w $0000,$0000 ;Location cs:0 is new PC. Location cs:2 is new CS

DataLETVC * i.e. Let V1=CCCC
* mov ds:V1,C1
 dc.w 6
 dc.w $00C7
 dc.w $0006
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1

DataLETVV * i.e. LET V1=V2
* mov ax,ds:[V2]
* mov ds:[V1],ax
 dc.w 6
 dc.w $00A1
 dc.w $2000,$A000 ;V2
 dc.w $00A3
 dc.w $4000,$C000 ;V1

DataAddVV * i.e. ADD V1,V2: V1:=V1+V2
* mov ax,ds:V2
* add ds:V1,ax
 dc.w 7
 dc.w $00A1
 dc.w $2000,$A000 ;V2
 dc.w $0001
 dc.w $0006
 dc.w $4000,$C000 ;V1

DataSubVV * i.e. SUB V1,V2: V1:=V1-V2
* mov ax,ds:V2
* sub ds:V1,ax
 dc.w 7
 dc.w $00A1
 dc.w $2000,$a000 ;V2
 dc.w $0029
 dc.w $0006
 dc.w $4000,$C000 ;V1

DataIfNEVCShort * i.e. IF V<>C THEN label
* cmp ds:V,C
* jnz
 dc.w 7
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0075

DataIfNEVCLong * i.e. IF V<>C THEN @label
* cmp ds:V1,C1
* jz+3
* jmp
 dc.w 9 
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0074
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataIfEQVCShort * i.e. IF V=C THEN label
* cmp ds:V1,C1
* jz
 dc.w 7
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0074

DataIfEQVCLong * i.e. IF V=C THEN @label
* cmp ds:V1,C1
* jnz+3
* jmp
 dc.w 9
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0075
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataIfLTVCShort * i.e. IF V<C THEN label
* cmp ds:V1,C1
* jb                     ;>NICK 23/11/88 * jl
 dc.w 7
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0072              ;>NICK 23/11/88 dc.w $007C

DataIfLTVCLong * i.e. IF V<C THEN @label
* cmp ds:V1,C1
* jae+3                         ;>NICK 23/11/88 * jge+3
* jmp
 dc.w 9
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0073                     ;>NICK 23/11/88 dc.w $007D
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataIfGTVCShort * i.e. IF V>C THEN label
* cmp ds:V1,C1
* ja                          ;>NICK 23/11/88 * jg
 dc.w 7
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0077                   ;>NICK 23/11/88 dc.w $007F

DataIfGTVCLong * i.e. IF V>C THEN @label
* cmp ds:V1,C1
* jbe +3                     ;>NICK 23/11/88 * jle +3
* jmp
 dc.w 9
 dc.w $0081
 dc.w $003E
 dc.w $4000,$C000 ;V1
 dc.w $2000,$A000 ;C1
 dc.w $0076                  ;>NICK 23/11/88 dc.w $007E
 dc.w $0003
 dc.w $00E9 ;jmp

;----

DataIfNEVVShort * i.e. IF V<>V1 THEN label
* mov ax,ds:V
* cmp ax,ds:V1
* jnz
 dc.w 8
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0075

DataIfNEVVLong * i.e. IF V<>V1 THEN @label
* mov ax,ds:V
* cmp ax,ds:V1
* jz +3
* jmp
 dc.w 10
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0074
 dc.w $0003
 dc.w $00E9 ;jmp

;---
DataIfEQVVShort * i.e. IF V=V1 THEN label
* mov ax,ds:V
* cmp ax,ds:V1
* jz
 dc.w 8
 dc.w $00A1
 dc.w $4000,$C000
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000
 dc.w $0074

DataIfEQVVLong * i.e. IF V=V1 THEN @label
* mov ax,ds:V
* cmp ax,ds:V1
* jnz +3
* jmp
 dc.w 10
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0075
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataIfLTVVShort * i.e. IF V<V1 THEN label
* mov ax,ds:V
* cmp ax,ds:V1
* jb                         ;>NICK 23/11/88 * jl
 dc.w 8
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0072                 ;>NICK 23/11/88 dc.w $007C

DataIfLTVVLong * i.e. IF V<V1 THEN @label
* mov ax,ds:V
* cmp ax,ds:V1
* jae +3                      ;>NICK 23/11/88 * jge +3
* jmp
 dc.w 10
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0073                   ;>NICK 23/11/88 dc.w $007D
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataIfGTVVShort * i.e. IF V>V1 THEN label
* mov ax,ds:V
* cmp ax,ds:V1
* ja                       ;>NICK 23/11/88 * jg
 dc.w 8
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0077                ;>NICK 22/11/88 dc.w $007F

DataIfGTVVLong * i.e. IF V>V1 THEN @label
* mov ax,ds:V
* cmp ax,ds:V1
* jbe +3                      ;>NICK 23/11/88 * jle +3
* jmp
 dc.w 10
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $003B
 dc.w $0006
 dc.w $2000,$A000 ;V1
 dc.w $0076                   ;>NICK 23/11/88 dc.w $007E
 dc.w $0003
 dc.w $00E9 ;jmp

;---

DataAttVV * i.e. TableN(V1)=V2
* les di,ds:N
* add di,ds:V1
* mov al,ds:V2
* stosb
 dc.w 12
 dc.w $00C4
 dc.w $003E
 dc.w $4000,$C000 ;N
 dc.w $0003
 dc.w $003E
 dc.w $2000,$A000 ;V1
 dc.w $00A0
 dc.w $1000,$9000 ;V2
 dc.w $00AA
 
;!nick 14/9/89 * les ds:N
;!nick 14/9/89 * mov bx,ds:V1
;!nick 14/9/89 * mov al,ds:V2
;!nick 14/9/89 * mov es:[bx+si],al
;!nick 14/9/89  dc.w 14
;!nick 14/9/89  dc.w $00C4
;!nick 14/9/89  dc.w $0036
;!nick 14/9/89  dc.w $4000,$C000 ;N
;!nick 14/9/89  dc.w $008B
;!nick 14/9/89  dc.w $001E
;!nick 14/9/89  dc.w $2000,$A000 ;V1
;!nick 14/9/89  dc.w $00A0
;!nick 14/9/89  dc.w $1000,$9000 ;V2
;!nick 14/9/89  dc.w $0026
;!nick 14/9/89  dc.w $0088
;!nick 14/9/89  dc.w $0000
 
;---

DataAttCV * i.e. TableN(C)=V
* les ds:N
* mov al,ds:V
* mov es:C[si],al
 dc.w 12
 dc.w $00C4
 dc.w $0036
 dc.w $4000,$C000 ;N
 dc.w $00A0
 dc.w $1000,$9000 ;V
 dc.w $0026
 dc.w $0088
 dc.w $0084 ;********** Short constant is available
 dc.w $2000,$A000 ;C

;---

DataAftVV * i.e. V2=TableN(V1)
* les ds:N
* mov bx,ds:V1
* mov dl,es:[si+bx]
* mov ds:V2,dx ;DH is always zero in m/c
 dc.w 15
 dc.w $00C4
 dc.w $0036
 dc.w $2000,$A000 ;N
 dc.w $008B
 dc.w $001E
 dc.w $4000,$C000 ;V1
 dc.w $0026
 dc.w $008A
 dc.w $0010
 dc.w $0089
 dc.w $0016
 dc.w $1000,$9000 ;V2

;---

DataAftVC * i.e. V=TableN(C)
* les ds:N
* mov dl,es:C[si]
* mov ds:V,dx
 dc.w 13
 dc.w $00C4
 dc.w $0036
 dc.w $2000,$A000 ;N
 dc.w $0026
 dc.w $008A ;***** Can be optimised for CC<256
 dc.w $0094
 dc.w $1000,$9000 ;C
 dc.w $0089
 dc.w $0016
 dc.w $4000,$C000 ;V

;---

DataAttVV16 * i.e. &TableN(V1)=V2
* les di,ds:N
* add di,ds:V1
* mov ax,ds:V2
* xchg ah,al
* stosw
 dc.w 14
 dc.w $00C4
 dc.w $003E
 dc.w $4000,$C000 ;N
 dc.w $0003
 dc.w $003E
 dc.w $2000,$A000 ;V1
 dc.w $00A1
 dc.w $1000,$9000 ;V2
 dc.w $0086
 dc.w $00E0
 dc.w $00AB

;!nick 14/9/89 * les ds:N
;!nick 14/9/89 * mov bx,ds:V1
;!nick 14/9/89 * mov ax,ds:V2
;!nick 14/9/89 * xhcg ah,al
;!nick 14/9/89 * mov es:[si+bx],ax
;!nick 14/9/89  dc.w 16
;!nick 14/9/89  dc.w $00C4
;!nick 14/9/89  dc.w $0036
;!nick 14/9/89  dc.w $4000,$C000 ;N
;!nick 14/9/89  dc.w $008B
;!nick 14/9/89  dc.w $001E
;!nick 14/9/89  dc.w $2000,$A000 ;V1
;!nick 14/9/89  dc.w $00A1
;!nick 14/9/89  dc.w $1000,$9000 ;V2
;!nick 14/9/89  dc.w $0086
;!nick 14/9/89  dc.w $00E0
;!nick 14/9/89  dc.w $0026
;!nick 14/9/89  dc.w $0089
;!nick 14/9/89  dc.w $0000

;---
DataAttCV16 * i.e. &TableN(C)=V
* les ds:N
* mov ax,ds:V
* xchg ah,al
* mov es:C[si],ax
 dc.w 14
 dc.w $00C4
 dc.w $0036
 dc.w $4000,$C000 ;N
 dc.w $00A1
 dc.w $1000,$9000 ;V
 dc.w $0086
 dc.w $00E0
 dc.w $0026
 dc.w $0089 ;***** Optimise for CC<256
 dc.w $0084
 dc.w $2000,$A000 ;C

;---

DataAftVV16 * i.e. &V2=TableN(V1)
* les si,ds:N
* add si,ds:V1
* lods es:[si]
* xchg ah,al
* mov ds:V2,ax
 dc.w 15
 dc.w $00C4
 dc.w $0036
 dc.w $2000,$A000 ;N
 dc.w $0003
 dc.w $0036
 dc.w $4000,$C000 ;V1
 dc.w $0026
 dc.w $00AD
 dc.w $0086
 dc.w $00E0
 dc.w $00A3
 dc.w $1000,$9000 ;V2

;!nick 14/9/89 * les si,[N]
;!nick 14/9/89 * mov bx,ds:V1
;!nick 14/9/89 * mov ax,es:[si+bx]
;!nick 14/9/89 * xchg ah,al
;!nick 14/9/89 * mov ds:V2,ax
;!nick 14/9/89 
;!nick 14/9/89  dc.w 16
;!nick 14/9/89  dc.w $00C4
;!nick 14/9/89  dc.w $0036
;!nick 14/9/89  dc.w $2000,$A000 ;N
;!nick 14/9/89  dc.w $008B
;!nick 14/9/89  dc.w $001E
;!nick 14/9/89  dc.w $4000,$C000 ;V1
;!nick 14/9/89  dc.w $0026
;!nick 14/9/89  dc.w $008B
;!nick 14/9/89  dc.w $0000
;!nick 14/9/89  dc.w $0086
;!nick 14/9/89  dc.w $00E0
;!nick 14/9/89  dc.w $00A3
;!nick 14/9/89  dc.w $1000,$9000 ;V2

;---

DataAftVC16 * i.e. &V=TableN(C)
* les si,ds:[n]
* mov ax,es:[si+C]
* xchg ah,al
* mov ds:V,ax
 dc.w 14
 dc.w $00C4
 dc.w $0036
 dc.w $2000,$A000 ;N
 dc.w $0026
 dc.w $008B ;***** Optimise for CC<256
 dc.w $0084
 dc.w $1000,$9000 ;C
 dc.w $0086
 dc.w $00E0
 dc.w $00A3
 dc.w $4000,$C000

;---

DataPush
* mov ax,ds:V
* push ax
 dc.w 4
 dc.w $00A1
 dc.w $4000,$C000 ;V
 dc.w $0050

;---

DataPop
* pop ax
* mov ds:V,ax
 dc.w 4
 dc.w $0058
 dc.w $00A3
 dc.w $4000,$C000 ;V

;---

DataAndVV
* mov ax,ds:V2
* and ds:V1,ax
 dc.w 7
 dc.w $00A1
 dc.w $2000,$A000 ;V2
 dc.w $0021
 dc.w $0006
 dc.w $4000,$C000 ;V1

;---

DataOrVV
* mov ax,ds:V2
* or ds:V1,ax
 dc.w 7
 dc.w $00A1
 dc.w $2000,$A000 ;V2
 dc.w $0009
 dc.w $0006
 dc.w $4000,$C000 ;V1

;---

DataXorVV
* mov ax,ds:V2
* xor ds:V1,ax
 dc.w 7
 dc.w $00A1
 dc.w $2000,$A000 ;V2
 dc.w $0031
 dc.w $0006
 dc.w $4000,$C000 ;V1

;---

DataASR
* sar ds:V1,1
 dc.w 4
 dc.w $00D1
 dc.w $003E
 dc.w $4000,$C000 ;V1

;---
