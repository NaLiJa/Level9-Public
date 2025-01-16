*-------
 include 'font.s'
InitScreenMode
* First load the font!
 lea FontSpace,a0
* lea LoadFontDriverBlock(PC),a6
* move.l a0,(A6)
* move.b #loaddcode,d0
* bsr driver
* move.l (a6),a0
* add.l #$e,a0
 lea FontAddress(PC),a1
 move.l a0,(a1)

* by default, use smallest possible text.
 lea XScale(PC),a0
 clr.b (a0)
 lea YScale(PC),a0
 clr.b (a0)

 MOVE.B ScreenResolution(PC),D1
 CMP.B #2,D1
 BEQ HInitScreenMode
 BRA CInitScreenMode
*-------
InitFont
 MOVE.B ScreenResolution(PC),D1
 CMP.B #2,D1
 BEQ HInitFont
 BRA CInitFont
*------
OswrchD0
 MOVE.B ScreenResolution(PC),D1
 CMP.B #2,D1
 BEQ HOswrchD0
 BRA COswrchD0
*-------
FastOswrch
 MOVE.B ScreenResolution(PC),D0
 CMP.B #2,D0
 BNE COswrch
*
HOswrch
 MOVE.B CharToDraw(PC),D0
HOswrchD0
 CMP.B #13,D0
 BNE.S HOswrchNotCR
 LEA XCursorPos(PC),A0
 CLR.W (A0)
 RTS

HOswrchNotCR EVEN
* CMP.B #10,D0
* BEQ HScrollScreen

HOswrchNotLF EVEN
 CMP.B #8,D0
 BNE.S HOswrchNotBS
 BSR HRetreatCursor
 MOVE.B #32,D0
 BRA HDrawCharD0

HOswrchNotBS EVEN
 CMP.B #32,D0
 BLT.S HOswrchRet
 BSR HDrawCharD0
 BSR HAdvanceCursor
HOswrchRet EVEN
 RTS
*--------
HCalcCurrentCharAddress EVEN
* calculate the memory address of the current cursor position
 move.l PhysicalBase(PC),a0
 CLR.L D0
 CLR.L D1
 MOVE.W YScreenSize(PC),D0
 SUB.W YCursorPos(PC),D0
* each LINE is 80 pels
 MOVE.B YScale(PC),D1
 BEQ.S HCalcNormalY
 MOVE.W #160,D1
 BRA.S HCalc2

HCalcNormalY EVEN
 MOVE.W #80,D1

HCalc2 EVEN
 MULU D0,D1
 ADD.L D1,A0
 CLR.L D0
 MOVE.B XScale(PC),D0
 BEQ.S HCalcNormal
* Calc for wide chars
 MOVE.W XCursorPos(PC),D0
 LSR.W #2,D0 * 8 pixels per byte
 ADD.L D0,A0
 RTS

HCalcNormal
 MOVE.W XCursorPos(PC),D0
 LSR.W #3,D0 * 8 pixels per byte
 ADD.L D0,A0
 RTS
*---------
HDrawChar EVEN
 MOVE.B CharToDraw(PC),D0

HDrawCharD0 EVEN
*Calculate the address of the font for this char
 CLR.L D1
 MOVE.B D0,D1
 SUB.W #32,D1 * min. char in font
 ASL.W #3,D1 * times 8
* LEA FontSpace(PC),A2
 move.l FontAddress(PC),a2
 ADD.L D1,A2
*
 BSR HCalcCurrentCharAddress
* Now A0.l is address of top left of char.
* and A2.l is address of character pattern

 MOVE.B XScale(PC),D1
 BEQ.S HDrawChar8Wide
HDrawChar16Wide
 MOVE.W #7,D1

HDrawCharLoop EVEN
 MOVE.B (A2)+,D0
* now double every pixel
 CLR.W D2
* assmble the doubled word in D2.w
 MOVE.W #6,D3
HDouble0
 TST.B D0
 BPL.S HDouble1
 OR.W #3,D2

HDouble1
 ROL.B #1,D0
 ROL.W #2,D2
 DBRA D3,HDouble0

* MOVE.b (A2)+,(A0)
 MOVE.W D2,(A0)
 ADD.L #80,A0
 MOVE.B YScale(PC),D3
 BEQ.S HDouble2
 MOVE.W D2,(A0)
 ADD.L #80,A0

HDouble2
 DBRA D1,HDrawCharLoop
 RTS



HDrawChar8Wide
 MOVE.W #7,D1
HDrawChar8Loop EVEN
 MOVE.B (A2),(A0)
 ADD.L #80,A0
 MOVE.B YScale(PC),D3
 BEQ.S HDrawChar2
 MOVE.B (A2),(A0)
 ADD.L #80,A0

HDrawChar2
 ADD.L #1,A2
 DBRA D1,HDrawChar8Loop
 RTS

*---------
HAdvanceCursor
 LEA XCursorPos(PC),A0
 ADDQ.W #8,(A0)
 MOVE.W (A0),D0
 CMP.W XScreenSize(PC),D0
 BLT.S HAdvanceRet
 CLR.W (A0)
 LEA YCursorPos(PC),A0
 CMP.W #8,(A0)
 BLS.S HScrollScreen
 SUB.W #8,(A0)

HAdvanceRet
 RTS
*-------
HRetreatCursor
 LEA XCursorPos(PC),A0
 SUBQ.W #8,(A0)
 MOVE.W (A0),D0
 BPL.S HRetreatRet
 MOVE.W XScreenSize(PC),(A0)
 SUBQ.W #8,(A0)
 LEA YCursorPos(PC),A0
 ADD.W #8,(A0)

HRetreatRet
 RTS
*----------

HScrollScreen
* And scroll screen...
; movem.l d0-d7/a0-a6,-(sp)
; move.b #cr,d0
; bsr absoswrch
; move.b #lf,d0
; bsr absoswrch
; movem.l (sp)+,d0-d7/a0-a6
 rts


* MOVE.B YScale(PC),D0
* BEQ.S HScrollScreen8
* BSR HScrollScreen8
** and drop through to scroll
** another 8 pels for high
** characters.
*
*
*HScrollScreen8
** And scroll screen...
* MOVE.L this_screen(PC),A0
* MOVE.L A0,A1
* ADD.L #640,A1
*
* MOVE.W #392,D0 * lines to scroll
*
*HScrollScreen1 EVEN
*
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
*
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
* MOVE.L (A1)+,(A0)+
*
* DBRA D0,HScrollScreen1
*
* MOVE.W #640,D1
*HScrollScreen2
* MOVE.L #0,(A0)+
* DBRA D1,HScrollScreen2
* RTS

*-----------
HInitScreenMode
 lea YScale(PC),a0
 move.b #1,(a0) * 16 pixel high by default
 MOVE.L PhysicalBase(PC),a0
 MOVE.W #400,D0 * lines to clear

HInitScreen1 EVEN

 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+

 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 MOVE.L #0,(A0)+
 DBRA D0,HInitScreen1

HInitFont
 LEA XCursorPos(PC),A0
 MOVE.W #0,(A0)
 LEA YCursorPos(PC),A0
 MOVE.W #8,(A0)

 LEA XScreenSize(PC),A0
 MOVE.W #640,(A0)
 MOVE.B XScale(PC),D0
 BEQ.S HInitScreen2
 MOVE.W #320,(A0)
HInitScreen2 EVEN

 LEA YScreenSize(PC),A0
 MOVE.W #400,(A0) * whole physical screen, regardless of split etc.
 MOVE.B YScale(PC),D0
 BEQ.S HInitScreen3
 MOVE.W #200,(A0)

HInitScreen3 EVEN
 lea CharHeight(PC),a0
 move.b #8,(a0)

HInitScreen4
 lea BytesPerScreenLine(PC),a0
 move.b #80,(a0)
 RTS
*-------------------------------
CInvertCursor
* preserves d0.b!
 MOVE.W D0,-(SP)
; bsr HidePointer
 BSR CCalcCurrentCharAddress
 CLR.W D0
 MOVE.B CharHeight(PC),D0
 MOVE.B YScale(PC),D1
 BEQ.S CInvertCursor1a
 ADD.B D0,D0 * DOuble cursor height

CInvertCursor1a
 CLR.L D1
 MOVE.B BytesPerScreenLine(PC),D1
CInvertCursor1
 EOR.b #$FF,(A0)
 eor.b #$ff,2(a0)
 MOVE.B XScale(PC),D2
 BEQ.S CInvertCursor2
 EOR.B #$FF,$1(A0)
 eor.b #$ff,$3(a0)

CInvertCursor2
 ADD.L D1,A0
 DBRA D0,CInvertCursor1
; bsr ShowPointer
 MOVE.W (SP)+,D0
 RTS
*-------
COswrch
 MOVE.B CharToDraw(PC),D0
COswrchD0
 CMP.B #13,D0
 BNE.S COswrchNotCR
 LEA XCursorPos(PC),A0
 CLR.W (A0)
 RTS

COswrchNotCR EVEN
 CMP.B #10,D0
 BEQ CScrollScreen

COswrchNotLF EVEN
 CMP.B #8,D0
 BNE.S COswrchNotBS
 BSR CRetreatCursor
 MOVE.B #32,D0
 BRA CDrawCharD0

COswrchNotBS EVEN
 CMP.B #32,D0
 BLT.S COswrchRet
 BSR CDrawCharD0
 BSR CAdvanceCursor
COswrchRet EVEN
 RTS
*--------
CCalcCurrentCharAddress EVEN
* calculate the memory address of the current cursor position
 MOVE.L PhysicalBase(PC),a0
 CLR.L D0
 CLR.L D1
 MOVE.W YScreenSize(PC),D0
 SUB.W YCursorPos(PC),D0
* each LINE is 160 pels
 MOVE.B YScale(PC),D1
 BEQ.S CCalcNormalY
 MOVE.W #320,D1
 BRA.S CCalc2

CCalcNormalY EVEN
 MOVE.W #160,D1
CCalc2
 MULU D0,D1
 ADD.L D1,A0
 CLR.L D0
 MOVE.W XCursorPos(PC),D0
* LSR.W #3,D0 * 8 pixels per byte
*\ AND.W #$FE,D0
*\ ASL.W #2,D0
 MOVE.B XScale(PC),D1
 ASL.W D1,D0 * shift by XScale
 LSR.W #3,D0
 AND.W #$FE,D0
 ASL.W #1,D0
 ADD.L D0,A0
 MOVE.W XCursorPos(PC),D0
 ASL.W D1,D0 * shift by XScale
 BTST #3,D0
 BEQ.S CDC1
 ADDQ.L #1,A0

CDC1
 RTS
*---------
CDrawChar EVEN
 MOVE.B CharToDraw(PC),D0

CDrawCharD0 EVEN
*Calculate the address of the font for this char
 CLR.L D1
 MOVE.B D0,D1
 SUB.W #32,D1 * min. char in font
 ASL.W #3,D1 * times 8
* LEA FontSpace(PC),A2
 move.l FontAddress(PC),a2
 ADD.L D1,A2
*
 BSR CCalcCurrentCharAddress
CDrawCharA0A2
* Now A0.l is address of top left of char.
* and A2.l is address of character pattern

 MOVE.B XScale(PC),D1
 BEQ.S CDrawChar8Wide
;CDrawChar16Wide
; MOVE.W #7,D1
;CDrawCharLoop EVEN
; MOVE.B (A2)+,D0
;* now double every pixel
; CLR.W D2
;* assmble the doubled word in D2.w
; MOVE.W #6,D3
;CDouble0
; TST.B D0
; BPL.S CDouble1
; OR.W #3,D2
;
;CDouble1
; ROL.B #1,D0
; ROL.W #2,D2
; DBRA D3,CDouble0
;
; MOVE.W D2,(A0)
; move.w d2,2(a0)
; ADD.L #160,A0
; MOVE.B YScale(PC),D3
; BEQ.S CDouble2
; MOVE.W D2,(A0)
; move.w d2,2(a0)
; ADD.L #160,A0
;
;CDouble2
; DBRA D1,CDrawCharLoop
; RTS

CDrawChar8Wide
 MOVE.W #7,D1
CDrawChar8Loop EVEN
 MOVE.B (A2),(A0)
 move.b (a2),2(a0)
 ADD.L #160,A0
 MOVE.B YScale(PC),D3
 BEQ.S CDraw2
 MOVE.B (A2),(A0)
 move.b (a2),2(a0)
 ADD.L #160,A0

CDraw2
 ADD.L #1,A2
 DBRA D1,CDrawChar8Loop
 RTS

*---------
CAdvanceCursor
 LEA XCursorPos(PC),A0
 ADDQ.W #8,(A0)
 MOVE.W (A0),D0
 CMP.W XScreenSize(PC),D0
 BLT.S CAdvanceRet
 CLR.W (A0)
 LEA YCursorPos(PC),A0
 CMP.W #8,(A0)
 BLS.S CScrollScreen
 SUB.W #8,(A0)

CAdvanceRet
 RTS
*-------
CRetreatCursor
 LEA XCursorPos(PC),A0
 SUBQ.W #8,(A0)
 MOVE.W (A0),D0
 BPL.S CRetreatRet
 MOVE.W XScreenSize(PC),(A0)
 SUBQ.W #8,(A0)
 LEA YCursorPos(PC),A0
 ADD.W #8,(A0)

CRetreatRet
 RTS
*----------

CScrollScreen
* And scroll screen...
; movem.l d0-d7/a0-a6,-(sp)
; move.b #cr,d0
; bsr absoswrch
; move.b #lf,d0
; bsr absoswrch
; movem.l (sp)+,d0-d7/a0-a6
 rts



* MOVE.B YScale(PC),D0
* BEQ.S CScrollScreen8
* BSR CScrollScreen8
** and drop through to scroll
** another 8 pels for high
** characters.

*CScrollScreen8
; bra dolinefeed

 MOVE.L PhysicalBase(PC),A0
 MOVE.L A0,A1
 ADD.L #1280,A1

 MOVE.W #192,D0 * lines to scroll

CScrollScreen1 EVEN

 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+

 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+

 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+

 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+
 MOVE.L (A1)+,(A0)+

 DBRA D0,CScrollScreen1

 MOVE.W #1280,D1
CScrollScreen2
 MOVE.L #0,(A0)+
 DBRA D1,CScrollScreen2
 RTS

*-----------
CInitScreenMode
 lea YScale(PC),a0
 clr.b (a0)
 MOVE.L PhysicalBase(PC),A0
 MOVE.W #400,D0 * lines to clear
* actually 200 lines of
* 160 rather than 400 of
* 80, but who's counting?
CInitScreen1 EVEN

 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+

 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+
 move.l #0,(A0)+

 DBRA D0,CInitScreen1

CInitFont
 LEA XCursorPos(PC),A0
 MOVE.W #0,(A0)
 LEA YCursorPos(PC),A0
 MOVE.W #8,(A0)
 LEA XScreenSize(PC),A0
 MOVE.W #640,(A0)
 MOVE.B XScale(PC),D0
 BEQ.S CInit1
 MOVE.W #320,(A0)

CInit1
 LEA YScreenSize(PC),A0
 MOVE.W #200,(A0) * whole physical screen, regardless of split etc.
 MOVE.B YScale(PC),D0
 BEQ.S CInit2
 MOVE.W #100,(A0)
CInit2
CInitScreen3 EVEN
 lea CharHeight(PC),a0
 move.b #8,(a0)

CInitScreen4
 lea BytesPerScreenLine(PC),a0
 move.b #160,(a0)
 RTS

XCursorPos DS.W 1 * gives x cursor pos. 0 is leftmost column
YCursorPos DS.W 1 * gives y cursor pos. 0 is bottom row
XScreenSize DS.W 1
YScreenSize DS.W 1 * whole physical screen, regardless of split etc.
 EVEN

CharToDraw DS.W 1
BytesPerScreenLine DS.W 1
CharHeight DS.B 1
BytesPerLine DS.B 1
MinChar DS.B 1
MaxChar DS.B 1
NumChars DS.B 1
XScale DS.B 1
YScale DS.B 1
ScreenResolution ds.b 1

 EVEN
Debug1 DS.L 1
Debug2 DS.L 1
Debug3 DS.L 1
FontAddress ds.l 1

 EVEN
