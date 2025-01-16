 ifnd MCStart
 include 'Condit.s'
 endc

; Huffman decoder and other sprites decompression bits.
;
; M.J.Austin 3/2/90
;
; Copyright (C) 1990 Level 9 Computing (Partnership).
;
ConstNumCodeWords equ 17
HuffmanDebugging equ 0
HuffmanStandAlone equ 0

HuffmanAmountToRead equ 512*4 * should use sector size really.
* if you change this, must change some code as well.


MikeTest

;
; HUFFMAN DECODER DESIGN
; A huffman decoder needs to read a bit stream, taking one more
; bit at a time to assemble a codeword until that codeword matches
; one of the codewords in its table. At that point the value of the
; original data is known (by the offset within the codeword table).
;
; There are various approaches to this problem. The simplest is just to
; do a comparison with the table, viz:
;
; GetABit:
;     asl.b #1,(a0) * get next bit of bitstream
;     rol.b #1,d0 * our trial codeword
;     lea CodeWordTable,a1
;     cmp.b (a1)+,d0
;     beq.s GotCodeWord0
;     cmp.b (a1)+,d0
;     beq.s GotCodeWord1
;     cmp.b (a1)+,d0
;     beq.s GotCodeWord2
;     ....
;     bra.s GetABit
;----
;
; However, this is SLOW!!! Instead, we can use a different approach.
; As each bit comes in, just do a conditional jump on its value.
; The code therefore works like a finite state machine: at each
; point in the code, the value of the code word is not held in
; a register: it is implied by the position in the code. e.g.
;
;	(code to fill d0.w with bits from bitstream)
;	asl.w #1,d0 * test our bit-stream
;	bmi.s C1
;	;C0 i.e. codeword known about is 0.
;	asl.w #1,d0
;	bmi.s C01
;	;C00 i.e. codeword known about is 00.
;	....
;
;	C1
;	.....
;
;
;    *
;  1/
;  *       *CW:011.
;  0\ 1  1/           1
;    *---*-----------*--------*CW:0101.
;    0\   0          0\
;      *               *
;
; Each * represents a separate piece of code.
; i.e. The decoder is a finite state machine: the code
; word it is decoding is never stored anywhere, it is implied
; by the position in the code.

;------
; This last approach should be optimal, provided that the code
; to fill d0.w from the bitstream is relatively short.
; However, because we start with a different huffman table each
; time, we need to generate the code to parse it in the InitHuffman
; routine.
;---------
; Interleaving/differencing.
; The decoded huffman codes need to be added, mod 16 to the
; last pixel value (0-15).
; There is also an escape code, value 16 which repeats LastPixel 4 more times.
; Once these processes are done, the nybble values emerge. I
; shall be writing out these nybbles into a byte table: this
; will be slightly slower than doing it "on the fly", but will make
; it easier to modify: e.g. for 32 colors.
;===============================================
; Filling the decoder word from the Bitstream.
;
; To keep the decoder efficient, we need to load up a register
; with a known number of bits: on the 68000, a word: 16 bits.
; i.e. whenever the decoder is started, it always sees a full word.
; I call this the "Decoder Register" (d4.w).
; The read process from the "Bitstream" (a4.l) in memory will obviously
; tend to take a word from memory, and part will be shifted into
; the Decoder Register. I call this the "Buffer Register" (d6.w)
; and I keep the number of bits remaining therein in d5.w
;
; On other machines, the buffer register (&number of bits) need only
; be kept in registers for the reloading process which will
; shrink the register usage.
;
;
;
;     (Bitstream) -> (Buffer Register) -> (Decoder Register)
;				|
;			      Code Words Extracted.
;
;
;     Only the "Decoder Register" has to be a hardware register

;===========================================
InitHuffman
; must be called once only, from the machine code
; just before SetUpVariablePtrs. We can allocate whatever
; memory we need here, from FreeWorkSpace
; 2(a4) contains the maximum number of cells the program
; will ever use in a sprites file (or multiple sprite files)
 move.b SpritesFileType-S(A5),d0
 cmp.b #CompressedType,d0
 bne.s InitHuffmanRet * not using compressed sprites.
 move.l FreeWorkSpace-S(A5),a0
 move.l a0,HuffmanSectorBufferPtr-S(A5)
 add.l #HuffmanAmountToRead+SectorSize,a0 * plus space for cell pointers
 move.l a0,FreeWorkSpace-S(A5)

 bsr ReadHeader ; read in header for compressed sprites.
 bsr InitHuffmanTable
; bsr InitSectorPointers
InitHuffmanRet
 rts

;-----
InitHuffmanTable
; Given two tables:
;  HuffmanCodeWords[18]: table of longs. Highest byte first.
;  HuffmanCodeWordSizeTable[18]: table of words. Giving the number
;     of bits to use for each code word: starting with LSB.
; We want to do all our once-only initialisation: including
; building the code to do our Huffman decoder.

; PROCEDURE:
;  We maintain a prototype code word (PCW), and its length (PCWL)
;  We seed PCW=0 and PCWL=1 i.e. 1 bit, of 0.
;
;				<   <
;  If PCW=CW, add node B, take PCW off stack ---|   |
;  else add node A, push modified PCW for branch    |
;       modify PCW.			    |
;	          ------------------------------|
;
; This repeats until PCW is of length>longest code word
; Then pop PCW off stack, and repeat the whole process using
;  that as a basis.
;
; The stack structure keeps the address of the branch, and
; the PCW for that branch.
;
; Node A is ASL.W #1,d0 ; BMI.S ...
; Node B is MOVE.W #CW,d0 ;  MOVE.W #CWL,D3 ;  RTS
;
; Register usage:
; d0.w, d1.w temp, parameter.
; d2.l PCW
; d3.w Number of bits in PCW

; a0.l, a1.l temp, parameters
; 
; a4.l pointer to memory at which the next bit of code
;      will be generated.
; a5.l base for memory addressing modes.
; a6.l Our Stack Structure pointer
 ifne HuffmanStandalone
 lea S(PC),a5
 endc
; bsr GetLongestCodeWord
; move.w d1,LongestCodeWord-S(A5)

 lea DecoderArea-S(A5),a4
 lea CWStackEnd-S(A5),a6
 move.l #0,-(a6) * Dummy address value
 move.l #0,-(a6) * Dummy PCW value for easy error trapping.
 move.w #0,-(a6) * Dummy PCL
 move.l #0,d2 * PCW
 move.w #0,d3 * number of bits: starts with nothing at all, to
* force the code to generate a test, and a conditional branch

BuildDLoop
 bsr CheckForPCWMatch ; If PCW=CW, sets d0.w=CW
 tst.w d0
 bpl GotMatch
; no match
; How Many possible code words start with PCW?
 bsr CountPossibilities
 cmp.w #1,d1
 bne BuildDNoPrune
* only one possible match for this code word (even though
* we haven't yet completed the codeword). The codeword
* is in d5.w
 move.w d3,d1 * save the length we've decoded so far
  move.w d5,d0 * the whole codeword
  move.l CodeWordLengthTablePtr,a0
 clr.w d3
  move.b 0(a0,d5),d3 * PCL for completed codeword
 sub.w d3,d1 * get the difference in length between what
* we've decoded and the length of the codeword
 neg.w d1
 move.w d1,-(sp)
  lea ZeroShiftCode,a0
  lea ZeroShiftCodeEnd,a1
  bsr CopyCode
; and patch in the shift length required - top 3 bits of
; lo nybble of high byte of instruction word (!)
; i.e. .... SSS. .... ....
 move.w (sp)+,d1
 and.w #7,d1 ; 8->0, limit to 3 bits
 asl.w #8,d1
 asl.w #1,d1
 or.w d1,-2(a4)
 bra GotMatch

BuildDNoPrune
 bcc.s BuildDLoopOk
* there are no other possibilities - i.e. some of the codewords
* in the table are unused. This gives a slightly inefficient
* decoder, but I can't be bothered to work out why as it is
* quite unusual.
 lea RTSCode,a0
 lea RTSCodeEnd,a1
 bsr CopyCode
 bra AfterGenerateNodeB * treat as a codeword

BuildDLoopOk
; Add node A (which does a shift), push PCW for branch
 lea NodeACode,a0
 lea NodeACodeEnd,a1
 bsr CopyCode
* The NodeA code will have done a shift, so the code we're jumping
* to (in the generated code) will know only about the shifted code
* word.
 asl.w #1,d2
 add.w #1,d3 * one more bit in PCW
 bset #0,d2 * branch is on 1, so for that branch this will be the PCW
  bsr CWPush
 bclr #0,d2
 bra BuildDLoop

GotMatch
; match - so add node B
 cmp.w #0,d0
 bne.s GenerateNotZeroChange
* Code zero-change separately to improve efficiency,
* and avoid a 68000 feature which causes addq.w #0,d7 to be difficult.
 lea NodeBShortZeroCode,a0
 lea NodeBShortZeroCodeEnd,a1
 bsr CopyCode
; Code we just generated is:
; addq.w #1,d6 * number of pixels this cell
; move.b d7,(a0)+ * write into nybble buffer  10c7
; subq.w #8,d5 * take off codeword length
; rts
 movem.w d0/d3,-(sp)
* PCL: goes to 0101 LLL1  0100 0101
  and.w #7,d3 ; 8->0, limit to 3 bits
  asl.w #1,d3
  or.b d3,-4(a4)
 movem.w (sp)+,d0/d3
 bra AfterGenerateNodeB


GenerateNotZeroChange

 cmp.w #$10,d0
 bne.s GenerateNotRunLength
 lea NodeBRunLengthCode,a0
 lea NodeBRunLengthCodeEnd,a1
 bsr CopyCode
 move.w d3,-4(a4) * length of codeword.
 bra AfterGenerateNodeB

GenerateNotRunLength
* two cases - for CWL>8 and CWL<=8. For the former we
* can use the 68000 short from instruction, which is twice as quick
 cmp.w #8,d3
 bgt.s GenerateNodeBLong
* Short code
* Ok - the codeword is <=8 bits long,
* but how big is its value. If <=8 we can use NodeBShortSmallCode
 cmp.w #8,d0
 bgt.s GenerateNodeBShortBigCode
 move.w d0,-(sp) * save codeword
  lea NodeBShortSmallCode,a0
  lea NodeBShortSmallCodeEnd,a1
  bsr CopyCode
* and patch in the correct codeword and codeword length
* The code we've just copied in is 
; addq.w #8,d7 * add codeword onto last pixel 5047
; move.b d7,(a0)+ * write into nybble buffer  10c7
; subq.w #8,d5 * take off codeword length     5145
; rts			          4e75
 move.w (sp)+,d0
 movem.w d0/d3,-(sp)
  and.w #7,d0 ; 8->0, limit to 3 bits
  asl.w #1,d0 * shift codeword into bit position 9..11
  or.b d0,-8(a4) * codeword
* PCL: goes to 0101 LLL1  0100 0101
  and.w #7,d3 ; 8->0, limit to 3 bits
  asl.w #1,d3
  or.b d3,-4(a4)
 movem.w (sp)+,d0/d3
 bra.s AfterGenerateNodeB

GenerateNodeBShortBigCode
 move.w d0,-(sp) * save codeword
  lea NodeBShortBigCode,a0
  lea NodeBShortBigCodeEnd,a1
  bsr CopyCode
* and patch in the correct codeword and codeword length
* The code we've just copied in is 
; add.w #0,d7 * add codeword onto last pixel  0647 0000
; move.b d7,(a0)+ * write into nybble buffer  10c7
; subq.w #8,d5 * take off codeword length     5145
; rts			          4e75
 move.w (sp)+,d0
 movem.w d0/d3,-(sp)
  move.w d0,-8(a4) * codeword
* PCL: goes to 0101 LLL1  0100 0101
  and.w #7,d3 ; 8->0, limit to 3 bits
  asl.w #1,d3
  or.b d3,-4(a4)
 movem.w (sp)+,d0/d3
 bra.s AfterGenerateNodeB

GenerateNodeBLong
* Ok - the codeword is >8 bits long,
* but how big is its value. If <=8 we can use NodeBLongSmallCode
 cmp.w #8,d0
 bgt.s GenerateNodeBLongBig
; GenerateNodeBLongSmall
 move.w d0,-(sp) * save codeword
  lea NodeBLongSmallCode,a0
  lea NodeBLongSmallCodeEnd,a1
  bsr CopyCode
* and patch in the correct codeword and codeword length
* The code we've just copied in is 
; addq.w #8,d7 * add codeword onto last pixel 5047
; move.b d7,(a0)+ * write into nybble buffer  10c7
; sub.w #0,d5 * take off codeword length      0445 0000
; rts			          4e75
 move.w (sp)+,d0
 and.w #7,d0 ; 8->0, limit to 3 bits
 asl.w #1,d0 * shift into bit position 9..11 in instruction word.
 or.b d0,-10(a4) * codeword
 move.w d3,-4(a4) * codeword length: PCL
 bra.s AfterGenerateNodeB

GenerateNodeBLongBig
 move.w d0,-(sp) * save codeword
  lea NodeBLongBigCode,a0
  lea NodeBLongBigCodeEnd,a1
  bsr CopyCode
* and patch in the correct codeword and codeword length
* The code we've just copied in is 
; add.w #0,d7 * add codeword onto last pixel  0647 0000
; move.b d7,(a0)+ * write into nybble buffer  10c7
; sub.w #0,d5 * take off codeword length      0445 0000
; rts			          4e75
 move.w (sp)+,d0
 move.w d0,-10(a4) * codeword
 move.w d3,-4(a4) * codeword length: PCL

AfterGenerateNodeB


; no other branches from this node (we've found a codeword)
; so take one of the unresolved branches off the stack and
; follow that through
 bsr CWPop
 cmp.l #0,a0
 beq.s BuildDFinished
; patch the bmi.s which points to here.
; the code at a0.l-4 is E340 6BFC i.e. BMI.S itself(FC)
; i.e. Branch is relative to a0.l itself.
 move.l a4,d0 * current code generation position
 sub.l a0,d0 * take off the position in the branch from which distance is measured
* (i.e. the next instruction)
 move.b d0,-1(a0) * patch in distance.
 bra BuildDLoop

BuildDFinished
 rts * no more things on stack, so we've finished.
;----------
CountPossibilities
; Return in d1.w how many possible code words are there which start
; with PCW=d2.l, and must therefore be of length >PCL=d3.w bits
* Also return in d5.w the last codeword matched with (This
* is only of use for the tree-pruning case where there is only
* one possible match)
 move.w #0,d1 * number of possibilities found
 move.l CodeWordTablePtr,a0
 move.l CodeWordLengthTablePtr,a1
 move.w #0,d0 * codeword we're looking at
CP1
 move.l (a0)+,d6 * code word
 move.b (a1)+,d7 * length of code word
CP2
 cmp.b d7,d3 * PCW Too big to match with this one
 bgt.s CP4 * no possible match
 cmp.l d6,d2 * does the reducing code word match with our PCW?
 beq.s CP3 * got a match
 lsr.l #1,d6 * knock of the trailing bits
 sub.b #1,d7
 bra.s CP2

CP3
* our PCW could match with this code word in the future
 addq.w #1,d1 * increase number of possible matches
 move.w d0,d5 * record codeword which matched
CP4
 add.w #1,d0 * next code word
 cmp.w #ConstNumCodewords+1,d0 * number of codewords
 bcs.s CP1
; return d1.w as the number of the codeword found.
 rts
;----------
CheckForPCWMatch
; does our PCW (d2.l), of length d3.w bits
; match with any of the actual codewords?
; Return d0.w as the number of the codewords, or 255 if not found.
 move.l CodeWordTablePtr,a0
 move.l CodeWordLengthTablePtr,a1
 move.w #0,d0 * codeword we're looking at
CFPM1
 cmp.l (a0)+,d2
 bne.s CFPM2
 cmp.b (a1),d3
 bne.s CFPM2
; return d0.w as the number of the codeword found.
 rts

CFPM2
 add.l #1,a1
 add.w #1,d0
 cmp.w #ConstNumCodewords+1,d0 * number of codewords
 bcs.s CFPM1
 moveq.w #-1,d0 * not found return code
 rts
;-------
;GetLongestCodeWord
;* get d1.w as the length of the longest codeword
; move.l CodeWordLengthTablePtr,a1
; move.w #0,d0 * codeword we're looking at
; move.w #0,d1 * length of current longest
;GLCW1
; cmp.b (a1)+,d1
; bcc.s GLCW1 * current longest is longer, or same length
; move.b -1(a1),d1
;
;GLCW1
; add.w #1,d0
; cmp.w #ConstNumCodewords+1,d0 * number of codewords
; bcs.s GLCW1
; rts
;--------

CWPush
; we will later on need to generat some code which is pointed
; to by the nodeA we've just generated (with CopyCode).
; So store the current address, and the PCW for the branch.
 move.l a4,-(a6) * address of next bit of code.
 move.l d2,-(a6) * PCW
 move.w d3,-(a6) * PCL
 cmp.l #CWStackStart,a6
 bcc.s CWPushRet
 dc.w $4afa * stack overflow.

CWPushRet
 rts
;----------
CWPop
; Get a PCW in d4.l, branch address in a0.l off the stack.
; no specific error trapping - there is a dummy 0 value
; at the top of the stack which the caller must trap.
 move.w (a6)+,d3 * PCL
 move.l (a6)+,d2 * PCW
 move.l (a6)+,a0 * address of code after the branch to this node.
 rts
;----
CopyCode
; copy the machine code which starts at a0.l and ends with the
; byte before a1.l to the current position in the generated code: a4.l
; Instructions are always an exact number of words.
 move.w (a0)+,(a4)+
 cmp.l a1,a0
 bcs.s CopyCode
 cmp.l #DecoderAreaEnd,a0
 bcc.s CopyCodeError
 rts

CopyCodeError
 dc.w $4afa
 rts
;-----
NodeCode
NodeACode
 asl.l #1,d4 * shift Decode Register
 bcs.s NodeACode * mi.s NodeACode * dummy jump
NodeACodeEnd

RTSCode
 rts
RTSCodeEnd

;----
* ZeroCode refers to the fact that we must generate code separately
* for the case where the same pixel is used. This is because
* code assembled as addq.w #0,d7 gets interpreted
* as addq.w #8,d7. Whoops!
NodeBShortZeroCode
 addq.w #1,d6 * number of pixels this cell
 move.b d7,(a0)+ * write into nybble buffer  10c7
 subq.w #8,d5 * take off codeword length
 rts
NodeBShortZeroCodeEnd
;----------
NodeBShortSmallCode
 addq.w #1,d6 * number of pixels this cell
 addq.w #8,d7 * add codeword onto last pixel 5047
 move.b d7,(a0)+ * write into nybble buffer  10c7
 subq.w #8,d5 * take off codeword length
 rts
NodeBShortSmallCodeEnd

NodeBShortBigCode
 addq.w #1,d6 * number of pixels this cell
 add.w #0,d7 * add codeword onto last pixel  0647 0000
 move.b d7,(a0)+ * write into nybble buffer  10c7
 subq.w #8,d5 * take off codeword length     5145
 rts
NodeBShortBigCodeEnd
;----
NodeBLongSmallCode
 addq.w #1,d6 * number of pixels this cell
 addq.w #8,d7 * add codeword onto last pixel 5047
 move.b d7,(a0)+ * write into nybble buffer  10c7
 sub.w #0,d5 * take off codeword length      5145
 rts
NodeBLongSmallCodeEnd
NodeBLongBigCode
 addq.w #1,d6 * number of pixels this cell
 add.w #0,d7 * add codeword onto last pixel  0647 0000
 move.b d7,(a0)+ * write into nybble buffer  10c7
 sub.w #0,d5 * take off codeword length      
 rts
NodeBLongBigCodeEnd
;-----
NodeBRunLengthCode
 move.b d7,(a0)+ * write out last pixel 4 times
 move.b d7,(a0)+
 move.b d7,(a0)+
 move.b d7,(a0)+
 addq.w #4,d6 * number of pixels this cell
 sub.w #0,d5 * take off codeword length
 rts
NodeBRunLengthCodeEnd


ZeroShiftCode
 dc.w $E184 * asl.l #0,d4
ZeroShiftCodeEnd

NodeCodeEnd


;==================
 ifne HuffmanStandalone
LoadSprites
SpritesSize equ 50000
 move.l #SpritesSize,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
 move.l d0,a0
 lea HuffmanFilename,a1
 move.l #SpritesSize,d7 * max size to load
 move.l a0,-(sp)
  bsr LoadStructures
 move.l (sp)+,a0
 rts
 endc
;--------
HuffmanFilename
 dc.b "Sprites1.cmp",0
 even

 ifne HuffmanDebugging
BreakArmed dc.w 0
DebugLastBS dc.l 0 
DebugLastBSSize dc.w 0
DebugLastCW dc.w 0  *******
DebugLastCWL dc.w 0 *****
 endc


;--------
 ifne HuffmanStandalone
HuffmanDecoderTest
  ifne HuffmanDebugging
   bsr LoadOriginalSprites
  endc
 bsr LoadSprites
 move.l a0,a4 ; address of sprites file.
; Interpret header
 clr.l d0
 move.w (a0),d0 * compression type used.
 move.w 2(a0),d0 * offset of comment.

 move.l a0,a4
 move.w 4(a0),d0 * offset of codewordTable
 add.l d0,a4
 move.l a4,CodeWordTablePtr-S(A5)

 move.l a0,a4
 move.w 6(a0),d0 * offset of CodewordLengthTable
 add.l d0,a4
 move.l a4,CodeWordLengthTablePtr-S(A5)
 move.l a0,a4
 clr.l d0
 move.w 8(a0),d0 * offset of sector pointers -
* temporarily use as offset of data start.
 add.l d0,a4 * skip header into data

 move.l a4,-(sp)
  bsr InitHuffman * initialise decoder with the codewords from the file.
 move.l (sp)+,a4

 move.l #250000,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
 move.l d0,DecompressAreaPtr-S(A5) * area for decompressed data.
 bsr InitDecompressCell
 move.l DecompressAreaPtr-S(A5),a0 * area for decompressed data.
 dc.w $4afa
 move.w #0,d0 * cell number being decompressed
 ifne HuffmanDebugging
  move.w #0,BreakArmed
 endc
DecompressCellLoop
 move.w d0,-(sp)
  bsr UnpackCell
 move.w (sp)+,d0
 addq.w #1,d0

 ifne HuffmanDebugging
  cmp.w #($800/$80),d0
  bne.s DCLNoBreak
  move.w #1,BreakArmed
  dc.w $4afa

DCLNoBreak
 endc
 cmp.w #1800,d0
 bcs.s DecompressCellLoop

 lea TestFilename,a1
 move.l DecompressAreaPtr-S(A5),a0 * save from a0.l
 move.l #250000,d7 * amount to save
 dc.w $4afa
 bsr SaveFile

 dc.w $4afa
 endc * HuffmanStandalone

;--------------
UnpackCell
 move.l a0,-(sp) * pointer into decompress buffer
  bsr DecompressCell
 move.l (sp)+,a0
 movem.l d3-d6,-(sp)
  bsr InterleaveCell * also steps a0.l onto next position
 movem.l (sp)+,d3-d6
* in DecompressBuffer.
 rts
;---------------
InterleaveCell
; interleave pixel nybbles at NybbleBuffer to cell at a0.l
 lea NybbleBuffer-S(A5),a1
 move.w #16-1,d2 * loop counter for dbra: 16 lines.
InterleaveCell1
* no need to clear d4-d7 as a full set of new pixels is rotated
* into them.
; move.w #16-1,d1 * do 16*4 nybbles per output word (a pixel line).

InterleaveCell2
ICMacro macro
 move.b (a1)+,d0 * get a nybble
 roxr.b #1,d0 * bit for bp3
 roxl.w #1,d7
 roxr.b #1,d0 * bit for bp2
 roxl.w #1,d6
 roxr.b #1,d0 * bit for bp1
 roxl.w #1,d5
 roxr.b #1,d0 * bit for bp0
 roxl.w #1,d4
 endm

 ICMacro
 ICMacro
 ICMacro
 ICMacro

 ICMacro
 ICMacro
 ICMacro
 ICMacro

 ICMacro
 ICMacro
 ICMacro
 ICMacro

 ICMacro
 ICMacro
 ICMacro
 ICMacro

 move.w d4,(a0)+ * bp0
 move.w d5,(a0)+ * bp1
 move.w d6,(a0)+ * bp2
 move.w d7,(a0)+ * bp3
 dbra d2,InterleaveCell1
 rts
;----------------
NBOffset equ 17

InitDecompressCell
; call to initialise the bitstream buffering etc.
* i.e. call when repositioning the pointer into the compressed data.
 move.l (a4)+,d4
 move.w #32-NBOffset,d5 * number of bits -17 which are correct in d4.l
 rts
;------
DecompressCell
; decompress a single cell whose sprite data starts at a4.l
 lea NybbleBuffer-S(A5),a0
 move.w #0,d0
 move.w #0,d7 * LastPixel-S(A5)
 move.w #0,d6 * NumPixels-S(A5)

;ParseNextCodeword2
; cmp.w #256,d6 * NumPixels-S(A5)
; bcc.s GotItEndOfCell
; bsr DecoderArea * Condition codes are SET!
;* d0.w is the codeword found.
;* Condition code is still set from sub.w #CWL,d5
;* Do we still have our guaranteed 16 bits?
; bpl.s ParseNextCodeWord2 * yes
RefillBuffer macro
 move.w (a4)+,d4 * reload bottom 16 bits.
 add.w #16,d5 * number of bits we know about
; There are (32-(D5+NBOffset))=16-d5 bits missing at the low end of the hi word.
 move.w #15,d1 * ( bits remaining are measured 0..15)
 sub.w d5,d1 * no. of bits missing.
 beq.s \@ * none - unlikely, but may happen.
 swap d4
 lsr.w d1,d4 * get rid of junk bits from hi word.
 swap d4
 asl.l d1,d4 * shift back up, dragging in lo-end bits.
\@
 endm

; bra.s ParseNextCodeword2 


ParseNextCodeword
 cmp.w #256-4*8,d6 * NumPixels-S(A5) * 8 codewords at a time,
* max number of nybbles from each is 4.
 bcc ParseNextCodeword2

 bsr DecoderArea * Condition codes are SET!
* d0.w is the codeword found.
* Condition code is still set from sub.w #CWL,d5
* Do we still have our guaranteed 16 bits?
 bpl.s PNCa * yes
 RefillBuffer

PNCa
 bsr DecoderArea
 bpl.s PNCb * yes
 RefillBuffer
PNCb
 bsr DecoderArea
 bpl.s PNCc * yes
 RefillBuffer
PNCc
 bsr DecoderArea
 bpl.s PNCd * yes
 RefillBuffer
PNCd
 bsr DecoderArea
 bpl.s PNCe * yes
 RefillBuffer
PNCe
 bsr DecoderArea
 bpl.s PNCf * yes
 RefillBuffer
PNCf
 bsr DecoderArea
 bpl.s PNCg * yes
 RefillBuffer
PNCg
 bsr DecoderArea
 bpl.s PNCh * yes
 RefillBuffer
PNCh
 bra ParseNextCodeWord

ParseNextCodeword2
 cmp.w #256,d6 * NumPixels-S(A5)
 bcc.s GotItEndOfCell
 bsr DecoderArea * Condition codes are SET!
* d0.w is the codeword found.
* Condition code is still set from sub.w #CWL,d5
* Do we still have our guaranteed 16 bits?
 bpl.s ParseNextCodeWord2 * yes
 RefillBuffer
 bra.s ParseNextCodeWord2

GotItEndOfCell
 rts

;; code to make a single bit decision...
; asl.w #1,d0
; bmi.s ???
;-----------
; code to handle finding a codeword
; move.w #4,d3 * length of codeword in bits
; move.b #7,(a0)+ * write codeword without de-interleaving.
;
;
;TestHuffman
; dc.l %11010110101010111110101101101100

 even
;Decoder
; asl.w #1,d4
; bmi.s C1
;C0
; move.w #1,d3 * number of bits
; move.w #16,d0 * codeword
; rts
;
;C1
; asl.w #1,d4
; bmi.s C11
;C10
; asl.w #1,d4
; bmi.s C101
;C100
; move.w #3,d3 * number of bits
; move.w #0,d0 * codeword
; rts
;
;C11
;
;
;C101
;
;


;==================================================
; The header for the compressed file.
;The format of this is quite simple:
;	.w Compression type. 1=initial single-table Huffman system.
;	.w Offset of comment (also defines number of these pointers)
;	.w Offset of Huffman Code Word Table
;	.w Offset of Huffman CodeWord Length Table
;	.w Offset of Sector pointers table
;	.w Bytes in each sector. Presently 512. This may change in
;	   future if we need bigger sectors (or maybe smaller for
;	   console ROM access)
;	.w Divisor for access to sector pointers table: presently 16
;	   i.e. every 16 cells is stored. You should normally assume
;	   that this will be a power of two, and use instead the right
;	   shift in the next word. However, in the future, where the
;	   two give different results, this divisor should be assumed
;	   to be correct. (I guess we`ll make the shift value 0 in
;	   this case)
;	.w Shift value for access to sector pointers table: presently 4.
;	.w Step between pointers at start of each sector. Presently 1.
;	.w 0 (For easier future expansion)
;	.w 0
;	.w 0
;	.w 0
;	   (More words may be added here later, up to the comment)
;xxxxx  Text comment: terminated by binary 0.
;xxxxx	Huffman table
;xxxxx	Sector pointers table: a table which gives, for every
;		sixteenth cell starting with cell 0, the sector number
;		in which it starts, relative to the start of this file.
;xxxxx	Cell data, compressed.
;
;All Words are in 68000 format (high byte first) and are word-aligned.
;	Likewise, all the table starts are word-aligned.
;
;At the start of each sector, there is another table:
;.w	Cell number of the first cell which starts in this sector
;.w	Cell number of the last cell which starts in this sector
;.w	Offset - bit offset of each cell relative to this sector.
;	Top few bits are currently 0, but this is not guaranteed.
;	Mask what you don't need.
;	i.e. This is a number between 0 and 8*512=4096. It counts
;	bits relative to the sector start=the start of the header.
;	If we
;	later need to change to 1K sectors or whatever, no problem.
;	We can go up to 8K sectors (2 tracks on floppy?) without
;	hassles. Or the spare bits could be used for something else:
;	Maybe a "compression type" flag. Remember that we don`t
;	necessarily need the same sector size on all machines, although
;	it will make things easier. I`ll try to write the ST/Amiga
;	versions to use whatever they`re given. Note the "sector size"
;	word in the main file header.
;
;xxxx Any cell data left over from cells starting in the previous
;	 sector.
;xxxx Cell data.
;
 ifne HuffmanStandAlone
TestFilename dc.b "temp.dat",0
 even



 ifne HuffmanDebugging
LoadOriginalSprites
OSpritesSize equ $2000
 move.l #OSpritesSize,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
 move.l d0,a0
 lea OriginalSpritesFilename,a1
 move.l #OSpritesSize,d7 * max size to load
 move.l a0,-(sp)
  bsr LoadStructures
 move.l (sp)+,a0
; and de-interleave the sprites

 move.l a0,-(sp)
  move.l #OSpritesSize*2,d0
  move.l #MEMF_FAST,d1
  bsr MikeAllocMem
  move.l d0,a1
  move.l d0,OSpritesPtr
 move.l (sp)+,a0
; de-interleave sprite data at a0.l to pixel bytes at a1.l
 move.w #OSpritesSize,d0 * bytes to do

DIDLongLoop
 move.w (a0)+,d4
 move.w (a0)+,d5
 move.w (a0)+,d6
 move.w (a0)+,d7
 move.w #16-1,d2 * bits in a word
DIWordLoop
 clr.w d1
 roxl.w #1,d4
 roxl.w #1,d1
 roxl.w #1,d5
 roxl.w #1,d1
 roxl.w #1,d6
 roxl.w #1,d1
 roxl.w #1,d7
 roxl.w #1,d1
 move.b d1,(a1)+
 dbra d2,DIWordLoop

 sub.w #8,d0 * bytes to do
 bpl.s DIDLongLoop
 rts

;----------
CheckOSprites
; we've just decompressed a pixel d0.b to the stream - 
; check it against our original sprites file.
 move.l a0,-(sp)
 move.l OSpritesPtr-S(a5),a0
 cmp.b (a0)+,d0
 beq.s COSOk
 dc.w $4afa
COSOk
 move.l a0,OSpritesPtr-S(a5)
 move.l (sp)+,a0
 rts

OriginalSpritesFilename
 dc.b "sprites1.dat",0
 even

OSpritesPtr dc.l 0

 endc * HuffmanDebugging

 endc * ifne HuffmanStandAlone

;------------------
ReadHeader
;; lea MikeTemp-S(A5),a6


; move.l a6,-(sp)
;  move.l #40000,d0
;  move.l #MEMF_FAST,d1
;  bsr MikeAllocMem
; move.l (sp)+,a6
; move.l d0,FreeWorkSpace-S(A5)
; beq goaway


 move.l FreeWorkSpace-S(A5),d0
 move.l d0,HuffmanHeaderPtr-S(A5)
 lea MikeTemp-S(A5),a6 * 2-long buffer for load,end addresses
 move.l d0,(a6) ; address of where to put it.
 move.l #HuffmanHeaderSize,d0 * max length to read
 move.l SpritesHandle-S(A5),d4
 bsr RDFileD0 ; load open file with maximum length of d0.l
; success is guaranteed - so now lets use the parts of the
; data we need.

 move.l HuffmanHeaderPtr-S(A5),a0
 clr.l d0
 move.w CodeWordTablePtrOffset(a0),d0 * offset of table
 add.l a0,d0
 move.l d0,CodeWordTablePtr-S(A5)

 move.l HuffmanHeaderPtr-S(A5),a0
 clr.l d0
 move.w CodeWordLengthTablePtrOffset(a0),d0 * offset of table
 add.l a0,d0
 move.l d0,CodeWordLengthTablePtr-S(A5)

 move.l HuffmanHeaderPtr-S(A5),a0
 clr.l d0
 move.w SectorPointersTablePtrOffset(a0),d0 * offset of table
 add.l a0,d0
 move.l d0,SectorPointersTablePtr-S(A5)

 clr.l d0
 move.w 2(a4),d0 * maximum number of cells we need to consider
* in any one sprites file (which may be split across several
* physical files)
 move.w SectorPointersShiftOffset(a0),d1
 move.w d1,SectorPointersShift-S(A5)
 move.w SectorPointersDivisorOffset(a0),d1
 move.w d1,SectorPointersDivisor-S(A5)

 divu d1,d0 ; get the number of cells which actually have
 and.l #$0000ffff,d0 * divu puts some junk in hi word
; a sector number recorded for them.
 addq.w #3,d0 * add on a small margin for safety's sake.
 asl.l #1,d0 * each sector number is a word
* d0 is amount we still have to read in.
 move.l 4(a6),(a6) * load address for the rest of the header.
* d0.l is amount still to read in.
* Sprites handle is still d4.w
 bsr RDFileD0 ; load open file with maximum length of d0.l
 move.l 4(a6),FreeWorkspace-S(A5)
 move.l #0,d0
 bsr SeekToPosD0 * go back to the start of the file,
* to avoid screwing up any existing code.
 rts
;------
;InitSectorPointers
;; initialise the sector pointers which give the
;; fast access to a cell randomly located within sprites file.
;
; rts
;------
;The format of this is quite simple:
CompressionTypeOffset equ 0 ; rs.w 0
;	.w Compression type. 1=initial single-table Huffman system.
CommentPtrOffset equ 2 ;rs.w 0
;	.w Offset of comment (also defines number of these pointers)
CodeWordTablePtrOffset equ 4 ;rs.w 0
;	.w Offset of Huffman Code Word Table
CodeWordLengthTablePtrOffset equ 6 ;rs.w 0
;	.w Offset of Huffman CodeWord Length Table
SectorPointersTablePtrOffset equ 8 ;rs.w 0
;	.w Offset of Sector pointers table
BytesPerSectorOffset equ 10 ;rs.w 0
;	.w Bytes in each sector. Presently 512. This may change in
;	   future if we need bigger sectors (or maybe smaller for
;	   console ROM access)
SectorPointersDivisorOffset equ 12 ;rs.w 0
;	.w Divisor for access to sector pointers table: presently 16
;	   i.e. every 16 cells is stored. You should normally assume
;	   that this will be a power of two, and use instead the right
;	   shift in the next word. However, in the future, where the
;	   two give different results, this divisor should be assumed
;	   to be correct. (I guess we`ll make the shift value 0 in
;	   this case)
SectorPointersShiftOffset equ 14 ;rs.w 0
;	.w Shift value for access to sector pointers table: presently 4.
CellsInFileOffset equ 16 ;rs.w 0
; Cells In File
CellPointersDivisorOffset equ 18 ;rs.w 0
; Cell Pointers Divisor - i.e. what proportion of cells
	; starting in a sector have pointers at the start of that
	; sector. Presently = 1.
CellPointersShiftOffset equ 20 ;rs.w 0
; Cell Pointers Shift - the shift equivalent of the divisor.
; Presently = 0.
; equ 22 ; rs.w 0
;	.w Step between pointers at start of each sector. Presently 1.

; equ 24 ; rs.w 0
 ;	.w 0 (For easier future expansion)
; equ 26 ; rs.w 0 ;	.w 0
; equ 28 ; rs.w 0 ;	.w 0
; equ 30 ; rs.w 0 ;	.w 0
;	   (More words may be added here later, up to the comment)
; equ 32 ; rs.b 32 ; up to 32 byte text comment (variable length)
;xxxxx  Text comment: terminated by binary 0.
; equ 64 ; rs.b 18*4 * Huffman table is #Codewords, each a long.
; equ 136 ; rs.b 0 ;xxxxx	Sector pointers table: a table which gives, for every
;		sixteenth cell starting with cell 0, the sector number
;		in which it starts, relative to the start of this file.
;xxxxx	Cell data, compressed.
;
;All Words are in 68000 format (high byte first) and are word-aligned.
;	Likewise, all the table starts are word-aligned.
HuffmanHeaderSize equ 136
;===========================
;
;At the start of each sector, there is another table:
;.w	Cell number of the first cell which starts in this sector
;.w	Cell number of the last cell which starts in this sector
;.w	Offset - bit offset of each cell relative to this sector.
;	Top few bits are currently 0, but this is not guaranteed.
;	Mask what you don't need.
;	i.e. This is a number between 0 and 8*512=4096. It counts
;	bits relative to the sector start=the start of the header.
;	If we
;	later need to change to 1K sectors or whatever, no problem.
;	We can go up to 8K sectors (2 tracks on floppy?) without
;	hassles. Or the spare bits could be used for something else:
;	Maybe a "compression type" flag. Remember that we don`t
;	necessarily need the same sector size on all machines, although
;	it will make things easier. I`ll try to write the ST/Amiga
;	versions to use whatever they`re given. Note the "sector size"
;	word in the main file header.
;
;xxxx Any cell data left over from cells starting in the previous
;	 sector.
;xxxx Cell data.
;
;----------------------------------------

DecoderArea
 ds.b (NodeCodeEnd-NodeCode)*24 * likely max size of generated code
DecoderAreaEnd
 ds.w 8 * a little overflow area, because CopyCode tends to do
; slightly too much.
 even

CWStackStart
 ds.w 64*10 ***** think about this size in relation to the number of codewords
CWStackEnd

NybbleBuffer ds.b 128*2 * space for one cell's worth.

 ifeq HuffmanStandalone
CodeWordTablePtr dc.l 0
CodeWordLengthTablePtr dc.l 0
 endc
 ifne HuffmanStandalone
CodeWordTablePtr dc.l CodeWordTable
CodeWordLengthTablePtr dc.l CodeWordLengthTable
 endc
SectorPointersTablePtr dc.l 0
SectorPointersDivisor dc.w 0
SectorPointersShift dc.w 0

LongestCodeWord dc.w 0
NumPixels dc.w 0
LastPixel dc.w 0
DecompressAreaPtr dc.l 0
;----
 ifne HuffmanDebugging
* only needed if no compressed sprites file is available.
CodeWordTable
 dc.l %100
 dc.l %1111001
 dc.l %101111
 dc.l %110101
 dc.l %111011
 dc.l %1111101
 dc.l %1111011
 dc.l %110111
 dc.l %1111010
 dc.l %111000
 dc.l %1111000
 dc.l %11111110
 dc.l %111001
 dc.l %110011
 dc.l %110001
 dc.l %11111100
 dc.l %0

CodeWordLengthTable
 dc.b 3,7,6,6,6,7,7,6,7,6,7,8,6,6,6,8,1
 endc * HuffmanDebugging

 even


;--------------------------
HuffmanFillCellCache
 bsr SeekToPosD0 * go to appropriate sector on disk.

 lea MikeTemp-S(A5),a6
 move.l #HuffmanAmountToRead,d0 * d0 is amount we have to read in.
 move.l HuffmanSectorBufferPtr-S(a5),(a6) * load address for the rest of the header.
 move.l SpritesHandle-S(a5),d4
 bsr RDFileD0

 move.l (a6),a1 * sector loaded: first word is the first cell therein
 move.w (a1),FirstCellPointerInMemory-S(A5)
 move.w (a1),LastCellPointerInMemory-S(A5)


 add.l #1,HuffmanDiskReads-S(A5)

* now move all the cell pointers out into a separate area,
* and leave the compressed cell data in a continuous block
 move.l HuffmanSectorBufferPtr-S(a5),a0
 move.l a0,a1 * a1.l points to where the cell pointers are going.
 move.l a0,a2 * a2.l points to where the cell data is going.
 add.l #HuffmanAmountToRead,a1 * where the cell pointers will go.
 move.l a1,CellPointers-S(A5)

 move.w (a0),d0 * starting cell pointer
 move.w d0,FirstCellPointerInMemory-S(A5)
 move.w d0,LastCellPointerInMemory-S(A5)


 move.w #4-1,d3 * number of sectors to process. -1 for dbra

HLCDLoop
 move.l a2,d6
 sub.l HuffmanSectorBufferPtr-S(A5),d6
* cumulative adjustment for each cell pointer
 asl.w #3,d6 * times 8 to give bit offset.


 addq.l #2,a0 * skip over cell number at start of sector
 move.w (a0)+,d5 * number of cell pointers in this sector
 add.w d5,LastCellPointerInMemory-S(A5)
 move.w d5,d4 * save number of cell pointers
 add.w d4,d4 * get number of bytes used by cell pointers.
 addq.w #4,d4 * add 4 for start cell num, number of cell pointers
 move.w d4,d7
 asl.w #3,d7 * times 8 to give number of bits
 sub.w d7,d6 * d6.w is cumulative adjustment for each cell pointer.

 subq.w #1,d5 * -1 for dbra

HLCD1
 move.w (a0)+,d0
 add.w d6,d0
 move.w d0,(a1)+ * copy cell pointer
 dbra d5,HLCD1

 move.w #SectorSize,d0
 sub.w d4,d0 * take off bytes used by cell pointers

* d0.w is number of bytes remaining in sector: always even.
 move.w d0,d7
 asl.w #3,d7 * times 8 to give number of bits
 add.w d7,d6 * add on to adjustment for next sector

 lsr.w #1,d0 * get number of words
 subq.w #1,d0 * -1 for dbra
HLCD2
 move.w (a0)+,(a2)+
 dbra d0,HLCD2

 dbra d3,HLCDLoop * next sector please.
 rts

;----------

HuffmanLoadCell:
; load cell_1 at address d2.l
 add.l #1,HuffmanCellsUnpacked-S(A5) *** Debugging info
 move.l d2,HuffmanLoadAddress-S(A5) * put somewhere safer
HLC0
 clr.l d0
 move.w cell_1-S(A5),d0

 cmp.w FirstCellPointerInMemory-S(A5),d0
 bcs.s HLCNoCache
 cmp.w LastCellPointerInMemory-S(A5),d0
 bge.s HLCNoCache * >= because last cell known about may have been
* split into a sector we don't have loaded at the moment.
 move.w LastCellPointerInMemory-S(A5),d6 ****
 sub.w #2,d6
 cmp.w d6,d0 ****
 bcc.s HLCNoCache ****

HLCCacheHit
 sub.w FirstCellPointerInMemory-S(A5),d0
* d0.w is number of entry within our pointers table.
 add.w d0,d0
 move.l CellPointers-S(A5),a0
 add.l d0,a0
; (a0).w is cell pointer
 move.w (a0),d1
 move.l HuffmanSectorBufferPtr-S(A5),a0 * a0.l is start of cell data.
 bra GotCellWithinSectorD1
* d1.w is the bit offset from a0.l

HLCNoCache
 move.w SectorPointersShift-S(a5),d1
 lsr.w d1,d0
 add.w d0,d0 * because this is a word-based table. Faster than
* shifting less far and anding off bottom bit.
 move.l SectorPointersTablePtr-S(A5),a0
 add.l d0,a0
 clr.l d0
 move.w (a0),d0 * sector number which contains this cell
 asl.l #8,d0 * times 512: sector size for ST.
 add.l d0,d0
 move.w cell_1,d1

HuffmanLoadCellD0
 move.l d0,LastHuffmanReadAddress-S(A5)
 bsr HuffmanFillCellCache
 clr.l d0
 move.w cell_1-S(A5),d0

 cmp.w FirstCellPointerInMemory-S(A5),d0
 bcs.s HLCNoCache3 * error condition - checked for safety only
 cmp.w LastCellPointerInMemory-S(A5),d0
 bge.s HLCNoCache2 * >= because last cell known about may have been
* split into a sector we don't have loaded at the moment.

 move.w LastCellPointerInMemory-S(A5),d6 ****
 sub.w #2,d6
 cmp.w d6,d0 ****
 bcc.s HLCNoCache2 ****


 bra.s HLCCacheHit

HLCNoCache2
 move.l LastHuffmanReadAddress-S(A5),d0
 add.l #SectorSize*2,d0
 bra.s HuffmanLoadCellD0

HLCNoCache3
 dc.w $4afa
 rts

;-------
GotCellWithinSector
* we want cell d0.w within sector at a0.l-4
 add.w d0,d0 * look at word-based table of bit-offsets within sector
* (a0.l) is the table of offsets, starting with the 0th cell
* within this sector.
 move.w (a0,d0),d1 * d1.w is the bit-offset from a0.l
GotCellWithinSectorD1
* d1.w is the bit offset from a0.l
 clr.l d0
 move.w d1,d0
 lsr.w #3,d0 * d0.w=byte offset within sector
 and.w #7,d1 * d1.w=bit offset within that byte
****
 move.b #7,d4 * bit offset is numbered 7..0, not 0..7 ARGHHHH
 sub.b d1,d4
 move.b d4,d1
****

 add.l a0,d0
* (d0.l) is the byte at which we want to start decompressing.
* The huffman decoder requires it to be even aligned, so
* we will start by filling our decoder register: d4.w with either
* 24 bits or 32 bits, so that a4.l will be even aligned to start with.
 btst #0,d0 * even?
 beq.s GCWSEven
 move.l d0,a4
 move.b (a4)+,d4
 swap d4
 move.w (a4)+,d4
 asl.l #8,d4 * only 24 bits there, must start with MSB
 move.w #24-NBOffset,d5 * number of bits -17 which are correct in d4.l
; pulls 24 bits into d4.l We want to get rid of d1.w of them
; (because that is the bit offset at which this cell starts).
 asl.l d1,d4
 sub.w d1,d5 * number of bits valid in d4.w
 move.l HuffmanLoadAddress-S(A5),a0 * address to decompress to.
 bsr UnpackCell
 rts

;----

GCWSEven
 move.l d0,a4
; code which was once in InitDecompressCell
 move.l (a4)+,d4
 move.w #32-NBOffset,d5 * number of bits -17 which are correct in d4.l

; pulls 32 bits into d4.l We want to get rid of d1.w of them
; (because that is the bit offset at which this cell starts).
 asl.l d1,d4
 sub.w d1,d5 * number of bits valid in d4.w
 move.l HuffmanLoadAddress-S(A5),a0 * address to decompress to.
 bsr UnpackCell
 rts

HLCBug
 dc.w $4afa
 rts
;------


