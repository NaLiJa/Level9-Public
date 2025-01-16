; Laser multisize printer
; 23rd June 1988
;
 opt d+
;
;
; bra start
;
;
; Constants
;
bufferlength equ 40 
discbuffersize equ $10000
hidemouse equ $A00A
;
; even
;
; Program
;
start
;
 dc.w hidemouse
;
 lea starttext,a0		;print startup message
printheader
 bsr printtext
;
; Check for command line
 lea start(PC),a0
 sub.l #$80,a0
 clr.w d0
 move.b (a0)+,d0
 beq.s NoCommandLine
 lea nameBuffer+1,a1
 move.b d0,(a1)+
; d0.w is length
GetCommandLine1
 move.b (a0)+,d0
 move.b d0,(a1)+
; dbra d0,GetCommandLine1
 cmp.b #' ',d0
 bne.s GetCommandLine1

GCL2
 move.b (a0)+,d0
 cmp.b #' ',d0
 beq.s GCL2
; size character found in d0.b
 move.b d0,CommandLineSizeChar

GCL3
 move.b (a0)+,d0
 cmp.b #' ',d0
 beq.s GCL3

 subq.l #1,a0
 move.l a0,CommandMarginText
 bra setdta

CommandLineSizeChar dc.b 0
 even
CommandMarginText dc.l 0
;-------
NoCommandLine
 lea namebuffer,a0		;get filename
 bsr gettext
 lea namebuffer+1,a0
 cmp.b #bufferlength,(a0)	;check filename length
 bne setdta
filenameerror
 lea filenametext,a0		;ask for new filename
 move.b CommandLineSizeChar,d0
 beq PrintHeader
; called from command line - just quit
 clr.w -(sp)
 trap #1 * TERM  - i.e. back to tos

; bra printheader
;
setdta
 lea dtaaddress,a0		;set dta address
 move.l a0,-(sp)
 move.w #$1A,-(sp)
 trap #1
 addq.l #6,sp
;
 lea namebuffer+1,a3		;get length of filename
 clr.w d0 
 move.b (a3)+,d0
 clr.b 0(a3,d0.w)		;a3 holds pointer to filename
;
 move.w #0,-(sp)		;search for filename
 move.l a3,-(sp)
 move.w #$4E,-(sp)
 trap #1
 addq.l #8,sp
 tst.w d0
 bne notfoundfile
;
openfile
 move.w #0,-(sp)		;open filename
 move.l a3,-(sp)
 move.w #$3D,-(sp)
 trap #1
 addq.l #8,sp
 tst.w d0
 bpl openedfile
;
notfoundfile
 lea discerrortext,a0
 bsr printtext
 bra filenameerror
;
openedfile
 lea handle,a4			;save handle
 move.w d0,(a4)
 move.w d0,d7			;d7 holds handle
;
askquestion
 move.b CommandLineSizeChar,d0
 bne SetPrinter

 lea questiontext,a0		;print question message - size?
 bsr printtext
;
 lea namebuffer,a0		;get answer
 bsr gettext
 lea namebuffer+1,a0
 cmp.b #bufferlength,(a0)	;check answer length
 beq askquestion
;
 tst.b (a0)+			;check for zero length
 beq askquestion
;
findtype
 move.b (a0)+,d0		;find first character
 cmp.b #' ',d0
 beq findtype
;
 and.b #$5F,d0			;check first character
;
 lea extralargetext,a6		;large text
 cmp.b #'X',d0
 beq setprinter
;
 lea largetext,a6		;large text
 cmp.b #'L',d0
 beq setprinter
;
 lea mediumtext,a6		;medium text
 cmp.b #'M',d0
 beq setprinter
;
 lea smalltext,a6		;small text
 cmp.b #'S',d0
 bne askquestion
;
setprinter
 bsr sendstring
;
baudrateset
;
 bsr MJAStuff
 bsr DoMJAMargin
;
; move.l #-1,-(sp)		;set RTS/CTS & 9600 baud
; move.l #-1,-(sp)
; move.w #2,-(sp)
; move.w #1,-(sp)
; move.w #15,-(sp)
; trap #14
; add.l #14,sp
;
 lea dtaaddress,a4		;length retrieved from dta
 move.l 26(a4),d4		;d4 holds length
 tst.l d4
 bne somelength
;
 lea nulltext,a0		;null length files
printrestart
 bsr printtext
 lea filenametext,a0
 bra printheader
;
somelength
 lea discbuffer,a4  		;a4 holds disc buffer
 cmp.l #discbuffersize,d4
 bhi bigger
;
 tst.l d4
 beq finishedprinting
 move.l a4,-(sp)		;buffer part filled
 move.l d4,-(sp)
 move.l d4,d5			;d5 contains characters
 move.l #0,d4
 bra sizeset
;
bigger
 move.l a4,-(sp)		;buffer filled
 move.l #discbuffersize,-(sp)
 move.l #discbuffersize,d5
 sub.l #discbuffersize,d4
;
sizeset
 move.w d7,-(sp)		;read block
 move.w #$3F,-(sp)
 trap #1
 add.l #12,sp
 tst.l d0
 bpl readdiscokay
;
 lea readerrortext,a0		;read error
 bsr printtext
 bsr closefile
 bra filenameerror
;
readdiscokay
 move.b (a4)+,d3		;print buffered characters 
 subq.l #1,d5
 bsr sendchar

; do margin?
 cmp.b #$0d,-1(a4) * retrieve char just printed
 bne.s MJANoMargin
 bsr DoMJAMargin

MJANoMargin
 tst.l d5
 beq somelength
 bra readdiscokay
;------
;
finishedprinting
 move.b #$0C,d3			;formfeed
 bsr sendchar 
 bsr closefile
 bra filenameerror
;
;
;
;
exit
 clr.w -(sp)
 trap #1
;
;
;
;
printtext
 move.l a0,-(sp)		;write text to screen
 move.w #9,-(sp)
 trap #1
 addq.l #6,sp
 rts
;
gettext
 move.b #bufferlength,(a0)	;read line of text
 move.l a0,-(sp)
 move.w #$0A,-(sp)
 trap #1
 addq.l #6,sp
 rts
;
sendchar
 move.w #1,-(sp)		;check if ready
 move.w #8,-(sp)	
 trap #13
 addq.l #4,sp
 cmp.l #-1,d0
 bne sendchar 
;
 move.w d3,-(sp)		;print character
 move.w #1,-(sp)
 move.w #3,-(sp)
 trap #13
 addq.l #6,sp
 rts
;
closefile
 move.w d7,-(sp)		;close file
 move.w #$3E,-(sp)
 trap #1
 addq.l #4,sp
 bpl closeokay
 lea closeerrortext,a0
 bsr printtext
;
closeokay
 move.w #$0A,-(sp)		;print return
 move.w #2,-(sp)
 trap #1
 addq.l #4,sp
 rts
;--------
MJAStuff
 move.l CommandMarginText,a0
 move.l a0,d0 * test it
 bne MJAStuffCommandLine

 lea MarginText,a0
 bsr printtext
;
 lea MarginBuffer,a0		;get answer
 bsr gettext
 lea MarginBuffer+1,a0
 cmp.b #bufferlength,(a0)	;check answer length
 beq askquestion
;
MJAStuffCommandLine
 clr.l d1
 tst.b (a0)+			;check for zero length
 beq MJASetMargin * just pressed return - assume zero margin
;
 bsr GetDec
; d1.w is the size of margin we want
MJASetMargin
 lea MarginSize(PC),a0
 move.w d1,(a0)
 rts

GetDec
* get decimal number!
 clr.l d1 * the number we're assembling
GetDecLoop
 move.b (a0)+,d0		;find first character
 beq GDLGotNumber
 cmp.b #' ',d0
 beq GetDecLoop
 cmp.b #'0',d0
 bcs.s GetDecLoop
 cmp.b #'9'+1,d0
 bcc.s GetDecLoop
 sub.b #'0',d0
 mulu #10,d1 * shift existing dec number one place left
 add.l d0,d1
 bra.s GetDecLoop

GDLGotNumber
 rts
;

DoMJAMargin
 move.w MarginSize(PC),d0
 beq.s DoMjaMarginRet ; zero length margin
MJAMargin
 move.w d0,-(sp)
  move.w #' ',d3
  bsr SendChar
 move.w (sp)+,d0
 dbra d0,MJAMargin
DoMJAMarginRet
 rts
;-------
;
;
; Variables
;
handle     dc.w $00
namebuffer ds.b bufferlength+2
dtaaddress ds.b 44+2
MarginBuffer ds.l 50 * text input
MarginSize ds.w 1
;
;
;
sendstring
 move.b (a6)+,d3
 tst.b d3
 beq sentstring
 bsr sendchar
 bra sendstring
;
sentstring
 rts
;
;
;
starttext
 dc.b $1B,'E'
 dc.b $0A
 dc.b ' Multiple size Laser Printing',$0D,$0A
 dc.b ' ----------------------------',$0D,$0A

filenametext
 dc.b $0D,$0A
 dc.b ' Enter filename ? '  
 dc.b $00
;
discerrortext
 dc.b $0D,$0A
 dc.b ' File not found !'
 dc.b $0D,$0A
 dc.b $00
;
questiontext
 dc.b $0D,$0A
 dc.b ' Print size (X/L/M/S) ? '
 dc.b $00
;
nulltext
 dc.b $0D,$0A
 dc.b ' Null length file !'
 dc.b $0D,$0A
 dc.b $00
;
readerrortext
 dc.b $0D,$0A
 dc.b ' Read disc error !'
 dc.b $0D,$0A
 dc.b $00
;
closeerrortext
 dc.b $0D,$0A
 dc.b ' Close disc error !'
 dc.b $0D,$0A
 dc.b $00
;
MarginText
 dc.b $0d,$0a
 dc.b ' What size of margin would you like?',00
;
;
extralargetext
 dc.b $1B,$63
 dc.b $1B,$3B
 dc.b $1B,$5B,$32,$20,$4C
 dc.b $0A
 dc.b $1B,$5B,$32,$74
 dc.b $1B,$5B,'200;200 ',$42
 dc.b $00
;
largetext
 dc.b $1B,$63
 dc.b $1B,$3B
 dc.b $1B,$5B,$31,$20,$4C
 dc.b $1B,$5B,$32,$20,$4B
 dc.b $1B,$5B,'200;200 ',$42
 dc.b $00
;
mediumtext
 dc.b $1B,$63
 dc.b $1B,$3B
 dc.b $00
;
smalltext
 dc.b $1B,$63
 dc.b $1B,$3B
 dc.b $1B,$5B,$33,$20,$4C
 dc.b $1B,$5B,$32,$20,$4B
 dc.b $00
;
;
;
end
;
 even
;
discbuffer
;
; end of program








