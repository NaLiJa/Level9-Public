; Code generation section specific to particular processors
;
; 68000 version. M.J.Austin 2/6/88
;
; Copyright (C) 1988 Level 9 Computing
;
; last change 13/6/88

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
 lea OpcodeAddress,a0
 lea DummyLongOpcode,a1
 move.l a1,(a0)
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
 ror.w #8,d0
 bsr Code
 ror.w #8,d0
 bra Code
*---


MCToAcode
; generate code to switch execution from machine code to ACODE
 move.l CompAcodePtr,d4 * first arg
 sub.l StartAcode,d4 * relative to start of acode
 add.l #12,d4 * allow for code generated: i.e. make d4.w point

* and second argument gives offset of the first
* byte of acode - i.e. the initial jump
 move.l StartAcode,D5
 sub.l CompAcodePtr,D5
* now d5.l is offset of start of acode from current.
* subtract 2 to allow for it being relative to offset word
 sub.l #2,d5

* to the start of the first acode instruction to be executed
 Lea DataToAcode,a0
 bra Generate




; move.l CompAcodePtr,d4 * first arg
; sub.l StartAcode,d4 * relative to start of acode
; add.l #8,d4 * allow for code generated: i.e. make d4.w point
;* to the start of the first acode instruction to be executed
; Lea DataToAcode,a0
; bra Generate

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
 asl.w #1,d5 * give offset into variable table
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

; add.w #1,d6 * only reading LOW byte of var

 lea DataAttVV,a0
 lea DataAttVV16,a1
; bsr Generate
 bra TableGenerate
; move.w d0,-(sp) * save var not inside brackets
; add.w $4(sp),d1 * add on table number to base value
; move.b d1,d0
; bsr code
; move.w $2(sp),d0 * table index
; cmp.w #$100,d0
; bcc badindex * single byte only!
; bsr code
; move.w (sp),d0 * var not inside brackets
; bsr code
; addq.l #6,sp
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

; add.w #1,d6 * only reading LOW byte of var

 lea DataAttCV,a0 
 lea DataAttCV16,a1
; bsr Generate
 bra TableGenerate
; move.w d0,-(sp) * save var not inside brackets
; add.w $4(sp),d1 * add on table number to base value
; move.b d1,d0
; bsr code
; move.w $2(sp),d0 * table index
; cmp.w #$100,d0
; bcc badindex * single byte only!
; bsr code
; move.w (sp),d0 * var not inside brackets
; bsr code
; addq.l #6,sp
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

; add.w #1,d4 * only writing to LOW byte of var

 lea DataAftVC,a0
 lea DataAftVC16,a1
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

; add.w #1,d4 * only writing to LOW byte of var

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
 cmp.b #"@",d0
 bne.s MCShortGosub
 addq.l #1,ptr
MCLongGosub
 lea DataLongGosub,a0
 bsr Generate
 bra.s MCLongJump

MCShortGosub
 move.b forcedlongjumps,d0
 bne.s MCLongGosub
 lea DataShortGosub,a0
 bsr Generate
 lea opcodeaddress,a0
 bra.s MCShortJump
;---
;MCgosub1
; lea opcodeaddress,a0
; move.l compacodeptr,(a0)
;; bsr code
;MCjumpstuff
;* insert code for a jump to the label (ptr.l)
;* the address of the opcode for this jump is at $0(sp.l)
; bsr compsearch
; cmp.b #"@",d0
; bne.s MCrelativejump
;* long jump
; addq.l #1,ptr
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

* d0.w is value of label relative to start of acode
* find current address relative to start
 move.l compacodeptr,d1
 sub.l startacode,d1
 sub.l d1,d0 * find offset of destination from current?
 ror.w #8,d0
 bsr Code
 ror.w #8,d0
 bra Code
* bra codew

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
 move.l compacodeptr,d3
 sub.l a1,d3 * sub startacode,d3 - d3=current offset in acode
 move.w $6(a0,d0),d1 * offset of opcode
 move.b $0(a1,d1),d2 * opcode
 and.b #relmask,d2 * is this a long jump?
 bne MCrfrshort * no!
* poke back in address for a long jump
 move.w $4(a0,d0),d1 * offset of reference
 sub.w d1,d3 * d3=label-ref - i.e. make relative
* poke back two-byte reference
 move.b d3,$1(a1,d1) * low byte
 lsr.w #8,d3
 move.b d3,$0(a1,d1) * high byte
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
 move.b d3,$0(a1,d1) * poke in single byte reference
 rts
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
 asl.w #1,d4 * double to give offset into table
 move.w ValueOffset(a0),d5 * constant - second argument

 lea MCIfVCTable,a0

MCifcommon
* given d4.w,d5.w as two args for the comparison stage,
* and a0.w as basic IF V C/V Table
* and d1.b as the comparator type, generate the code:
 and.w #$00FF,d1 * ensure top bits are clear
 asl.w #2,d1
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
 bra Generate

;----
Generate
; given (a0.l) as the code data for the current instruction
; d4.w is first argument, d5.w is second argument, d6.w is third argument
* check that code ptr is even.
 move.l CompAcodePtr,d0
 btst #0,d0
 bne EvenError

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
 dc.w 1
 dc.w $0060 * bra.s
; dc.w $4000 * offset

DataLongGoto
 dc.w 2
 dc.w $0060 * bra
 dc.w $0000 * bra
; dc.w $C000,$4000 * offset

DataShortGosub
 dc.w 1
 dc.w $0061 * bsr.s
; dc.w $4000 * offset

DataLongGosub
 dc.w 2
 dc.w $0061 * bsr
 dc.w $0000 * bsr
; dc.w $C000,$4000 * offset

DataReturn
 dc.w 2
 dc.w $4e,$75 * rts


DataToAcode
* move.l ToAcodePtr(PC),a0   $207a XXXX (where XXXX is rel. to XXXX)
* move.w #AcodePtr,A5        $2a7c 0000 XXXX
* jmp (a0)		     $4ed0
 dc.w 12
 dc.w $0020,$007A
 dc.w $A000,$2000
 dc.w $002A,$007c,$0000,$0000
 dc.w $C000,$4000 * address
 dc.w $004E,$00D0

;* move.w #AcodePtr,a5	$2a7C 0000 XXXX
;* rts:			$4E75
; dc.w 8 * 8 bytes
; dc.w $002A,$007C,$0000,$0000
; dc.w $C000,$4000 * adddress
; dc.w $4e,$75 * rts

; DataPrint
; DataMessagev/c
DataLETVC * i.e. Let V1=CCCC
* move.w #xxxx,yyyy(a5)
* format is: $3 rrr1  7 C  XXXX  YYYY i.e. 6 bytes
 dc.w 6
 dc.w $0039
 dc.w $007C
 dc.w $A000,$2000 * const offset
 dc.w $C000,$4000 * var number*2

DataLETVV * i.e. LET V1=V2
* move.w xxxx(A5),yyyy(A5)
* format is: $3 rrr1  6 1sss  XXXX  YYYY (rrr=source address reg)
 dc.w 6
 dc.w $0039
 dc.w $006C
 dc.w $A000,$2000 * xxxx
 dc.w $C000,$4000 * yyyy

DataAddVV * i.e. ADD V1,V2: V1:=V1+V2
* move.w V2(a5),d0:  	$302C VVVV
* add.w d0,V1(a5):	$D16C VVVV
 dc.w 8
 dc.w $0030,$2C
 dc.w $A000,$2000 * V2 offset
 dc.w $00D1,$6C
 dc.w $C000,$4000 * V1 offset

DataSubVV * i.e. SUB V1,V2: V1:=V1-V2
* move.w V2(A5),d0:	$302C VVVV
* sub.w d0,V1(A5):	$916C VVVV
 dc.w 8
 dc.w $0030,$2C
 dc.w $A000,$2000 * V2 offset
 dc.w $0091,$6C
 dc.w $C000,$4000 * V1 offset


DataIfNEVCShort * i.e. IF V<>C THEN label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$66XX where XX is offset from next instruction
 dc.w 7
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0066

DataIfNEVCLong * i.e. IF V<>C THEN @label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$6600 XXXX
*       		where XXXX is offset from XXXX
 dc.w 8
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0066,$0000

;---
DataIfEQVCShort * i.e. IF V=C THEN label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$67XX where XX is offset from next instruction
 dc.w 7
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0067

DataIfEQVCLong * i.e. IF V=C THEN @label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$6700 XXXX
*       		where XXXX is offset from XXXX
 dc.w 8
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0067,$0000

;---
DataIfLTVCShort * i.e. IF V<C THEN label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$65XX where XX is offset from next instruction
 dc.w 7
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0065

DataIfLTVCLong * i.e. IF V<C THEN @label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$6500 XXXX
*       		where XXXX is offset from XXXX
 dc.w 8
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0065,$0000

;---
DataIfGTVCShort * i.e. IF V>C THEN label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$62XX where XX is offset from next instruction
 dc.w 7
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0062

DataIfGTVCLong * i.e. IF V>C THEN @label
* cmp.w #C,V(A5):	$0C6C CCCC VVVV
* beq label:		$6200 XXXX
*       		where XXXX is offset from XXXX
 dc.w 8
 dc.w $000C,$006C
 dc.w $A000,$2000 * C offset(2nd arg)
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $0062,$0000
;----


DataIfNEVVShort * i.e. IF V<>V1 THEN label
* move.w V(A5),d0:	$302C VVVV
* cmp.w V1(A5),D0:	$B06C V1V1
* beq label:		$66XX where XX is offset from next instruction
 dc.w 9
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0066

DataIfNEVVLong * i.e. IF V<>V1 THEN @label
* move.w V(A5),d0:	$302C VVVV
* cmp.w V1(A5),D0:	$B06C V1V1
* beq label:		$6600 XXXX
*       		where XXXX is offset from XXXX
 dc.w 10
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0066,$0000

;---
DataIfEQVVShort * i.e. IF V=V1 THEN label
* move.w V(A5),d0:	$302C VVVV
* cmp.w V1(A5),D0:	$B06C V1V1
* beq label:		$67XX where XX is offset from next instruction
 dc.w 9
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0067

DataIfEQVVLong * i.e. IF V=C THEN @label
* move.w V(A5),d0:	$302C VVVV
* cmp.w V1(A5),D0:	$B06C V1V1
* beq label:		$6700 XXXX
*       		where XXXX is offset from XXXX
 dc.w 10
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0067,$0000

;---
DataIfLTVVShort * i.e. IF V<V1 THEN label
* move.w V(A4),d0:	$302C VVVV
* cmp.w V1(A4),D0:	$B06C V1V1
* beq label:		$65XX where XX is offset from next instruction
 dc.w 9
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0065

DataIfLTVVLong * i.e. IF V<V1 THEN @label
* move.w V(A4),d0:	$302C VVVV
* cmp.w V1(A4),D0:	$B06C V1V1
* beq label:		$6500 XXXX
*       		where XXXX is offset from XXXX
 dc.w 10
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0065,$0000

;---
DataIfGTVVShort * i.e. IF V>V1 THEN label
* move.w V(A4),d0:	$302C VVVV
* cmp.w V1(A4),D0:	$B06C V1V1
* bhi label:		$62XX where XX is offset from next instruction
 dc.w 9
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0062

DataIfGTVVLong * i.e. IF V>V1 THEN @label
* move.w V(A4),d0:	$302C VVVV
* cmp.w V1(A4),D0:	$B06C V1V1
* bhi label:		$6200 XXXX
*       		where XXXX is offset from XXXX
 dc.w 10
 dc.w $0030,$002C
 dc.w $C000,$4000 * V offset(1st arg)
 dc.w $00B0,$006C
 dc.w $A000,$2000 * V1 offset(2nd arg)
 dc.w $0062,$0000
;---
DataAttVV * i.e. TableN(V1)=V2
* move.l N*4(a3),A0:		$206B NNNN
* move.w V1(a4),D0:		$302C V1V1
* MOVE.B V2+1(a4),0(a0,d0)	$11AC V2V2 0000
 dc.w 14
 dc.w $0020,$006B
 dc.w $c000,$4000
 dc.w $0030,$002C
 dc.w $A000,$2000
 dc.w $0011,$00AC
 dc.w $9001,$1001
 dc.w $0000,$0000
;---
DataAttCV * i.e. TableN(C)=V
* move.l N*4(a3),A0:		$206B NNNN
* MOVE.B V2+1(a4),CCCC(a0)	$116C V2V2 CCCC
 dc.w 10
 dc.w $0020,$006B
 dc.w $C000,$4000
 dc.w $0011,$006C
 dc.w $9001,$1001
 dc.w $A000,$2000
;---

DataAftVV * i.e. V1=TableN(V2)
* move.l N*4(a3),A0:		$206B NNNN
* move.w V1(a4),D0:		$302C V1V1
* CLR.W V2(A4):			$426C V2V2
* MOVE.B 0(a0,d0),V2+1(A4)	$1970 0000 V2V2
 dc.w 18
 dc.w $0020,$006B
 dc.w $A000,$2000
 dc.w $0030,$002C
 dc.w $C000,$4000
 dc.w $0042,$006C
 dc.w $9000,$1000
 dc.w $0019,$0070,$0000,$0000
 dc.w $9001,$1001
;---
DataAftVC * i.e. V=TableN(C)
* move.l N*4(a3),A0:		$206B NNNN
* clr.w V2(A4):			$426C VVVV
* MOVE.B CCCC(a0),V2+1(A4)	$1968 CCCC VVVV
 dc.w 14
 dc.w $0020,$006B
 dc.w $A000,$2000
 dc.w $0042,$006C
 dc.w $c000,$4000
 dc.w $0019,$0068
 dc.w $9000,$1000
 dc.w $C001,$4001
;---


;---
DataAttVV16 * i.e. &TableN(V1)=V2
* move.l N*4(a3),A0:		$206B NNNN
* move.w V1(a4),D0:		$302C V1V1
* MOVE.W V2(a4),0(a0,d0)	$31AC V2V2 0000
 dc.w 14
 dc.w $0020,$006B
 dc.w $c000,$4000
 dc.w $0030,$002C
 dc.w $A000,$2000
 dc.w $0031,$00AC
 dc.w $9000,$1000
 dc.w $0000,$0000
;---
DataAttCV16 * i.e. &TableN(C)=V
* move.l N*4(a3),A0:		$206B NNNN
* MOVE.W V2(a4),CCCC(a0)	$316C V2V2 CCCC
 dc.w 10
 dc.w $0020,$006B
 dc.w $C000,$4000
 dc.w $0031,$006C
 dc.w $9000,$1000
 dc.w $A000,$2000
;---

DataAftVV16 * i.e. &V1=TableN(V2)
* move.l N*4(a3),A0:		$206B NNNN
* move.w V1(a4),D0:		$302C V1V1
* MOVE.W 0(a0,d0),V2(A4)	$3970 0000 V2V2
 dc.w 14
 dc.w $0020,$006B
 dc.w $A000,$2000
 dc.w $0030,$002C
 dc.w $C000,$4000
 dc.w $0039,$0070,$0000,$0000
 dc.w $9000,$1000
;---
DataAftVC16 * i.e. &V=TableN(C)
* move.l N*4(a3),A0:		$206B NNNN
* MOVE.W CCCC(a0),V2(A4)	$3968 CCCC VVVV
 dc.w 10
 dc.w $0020,$006B
 dc.w $A000,$2000
 dc.w $0039,$0068
 dc.w $9000,$1000
 dc.w $C000,$4000
;---
DataBreakPt
 dc.w 2
 dc.w $004a,$00fa
;---
DataPush
* move.l V1(a4),-(Sp):	3f2c VVVV
 dc.w 4
 dc.w $003f,$002c
 dc.w $C000,$4000
;---
DataPop
* move.l (sp)+,v1(a4):	395f vvvv
 dc.w 4
 dc.w $0039,$005f
 dc.w $C000,$4000
;---
DataAndVV
* move.w V2(a4),d0:  	$302C VVVV
* and.w d0,V1(a4):	$C16C VVVV
 dc.w 8
 dc.w $0030,$2C
 dc.w $A000,$2000 * V2 offset
 dc.w $00C1,$6C
 dc.w $C000,$4000 * V1 offset
;---
DataOrVV
* move.w V2(a4),d0:  	$302C VVVV
* or.w d0,V1(a4):	$816C VVVV
 dc.w 8
 dc.w $0030,$2C
 dc.w $A000,$2000 * V2 offset
 dc.w $0081,$6C
 dc.w $C000,$4000 * V1 offset
;---
DataXorVV
* move.w V2(a4),d0:  	$302C VVVV
* eor.w d0,V1(a4):	$B16C VVVV
 dc.w 8
 dc.w $0030,$2C
 dc.w $A000,$2000 * V2 offset
 dc.w $00B1,$6C
 dc.w $C000,$4000 * V1 offset
;---
;opcgoto equ 0
;opcgosub equ 1
;opcreturn equ 2
;opcprint equ 3
;opcmessagev equ 4
;opcmessagec equ 5
;opcmessagecsmall equ opcmessagec+$40 * smallmask
;opcmessagecbig equ opcmessagec
;opcfunction equ 6
;opcinput equ 7
;opcletvcbig equ 8
;opcletvcsmall equ opcletvcbig+$40 * smallmask
;opcletvv equ 9
;opcaddvvequ 10
;opcsubvv equ 11
;OpcChangeCode equ 12 * change code generation state
;opccall equ 14
;opcexit equ 15
;opcscreen equ 20
;opcclear equ 21
;opcpicture equ 22
;opcgetnext equ 23
;opcprintinput equ 28
;*
;* function codes
;fncacodedriver equ 1
;fncrandom equ 2
;fncsave equ 3
;fncrestore equ 4
;fncclear equ 5
;fncstack equ 6
;fncbreakpt equ 7
;fncprs equ 250
