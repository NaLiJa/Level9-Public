* AMIGA.S: Amiga-specific code for HUGE
*
* Mike Austin June/July/November 1989.
*
* Modified from:
* file examples/freemem.s

 bra MJAStart

WaitBlitter macro
WB set *
 btst #14,$dff002 * dmaconr
 bne WB
 endm


TopChipMemory equ $100000 * should probably change this! *******

MikeBufferSize equ 0 * size of title screen
joy0dat equ $dff00a * See P.192 Amiga System Programmer's guide
joy1dat equ $dff00c
joytest equ $dff036 * write this reg to clear mouse offsets
SizeBitPlane equ 8000
BPSize equ 8000 * size of each bit plane

* firstly get the required constants and macros
	incdir	":include/"

;	include	intuition/intuition.i
;	include	intuition/intuition_lib.i
	include	exec/exec_lib.i
	include	graphics/graphics_lib.i
	include	exec/memory.i
	include	libraries/dos_lib.i
	include	libraries/dos.i
	include	libraries/dosextens.i
	include	devices/keyboard.i
	include	devices/input.i
	include	exec/interrupts.i
	include	exec/nodes.i
 ifnd HUGE
MCStart * stop condit.s being pulled in.
	include	huffman.s
 endc

; ifd MCStart
;MaxPoolSize equ 512000 * for release game only.
; endc

CopperList1 dc.l 0
CopperList2 dc.l 0
CopperListScrollAddress dc.l 0
CopperListDDFSTRTAddress dc.l 0
CopperListBPL1Mod dc.l 0
CopperListBPL2Mod dc.l 0
;CopperListPAL0 dc.l 0
CopperListBPL1PTH dc.l 0
CopperListBPL1PTL dc.l 0
CopperListBPL2PTH dc.l 0
CopperListBPL2PTL dc.l 0
CopperListBPL3PTH dc.l 0
CopperListBPL3PTL dc.l 0
CopperListBPL4PTH dc.l 0
CopperListBPL4PTL dc.l 0
ASSCounter dc.w 0

 ifnd HUGE * define stuff for stand-alone debug version here
 opt d+
WantSampledSound equ 1
MaxPoolSize equ 400000 *128000
UseBlitter equ 1
WantMonochrome equ 1
UseFastMem equ 1
Colors32 equ 0
FirstPoolChunk equ 256000
SmallestPoolChunk equ 64000
AmigaCellGrouping equ 0
ScrollingSystem equ 1
SafeMode equ 0
PossessBlitter equ 0
ForceDF0 equ 0
AllowCache equ 0
S 
ST equ 0
Amiga equ 1
irqVBLHandler
 addq.w #1,VBLTicks
 bsr SoundEnvelopeHandler
 move.b FrameReady(PC),d0 
 beq.s IRQVblHandlerEnd 
 bsr ActuallySwapScreen
 move.b #0,FrameReady
IRQVBLHandlerEnd
 rts

VBLTicks dc.w 0

;FrameReady
; dc.b 0
; even

list0Ptr ds.b 128
CloseDown
 move.l AmigaSP,a7
 bsr goAway
 rts

IORequest
 ds.b 64 * space for io request stuff. **SHould be in MEMF_PUBLIC

XDir dc.w 0
YDir dc.w 0

ErrorHandler
 move.w d0,-(sp)
  bsr DisplayFrame
  bsr WaitForFrame

 move.l #200000,d1
EH2
 subq.l #1,d1
 bne.s EH2
 bsr AbsGetCharFromBDos
 cmp.w #32,d0
 bne.s ErrorHandler
 dc.w $4afa
 move.w (sp)+,d0
 rts

;---

;; AmigaPoolSize equ 100000
LinesPerSprite equ 16
WantAdept equ 0
ReleaseGame equ 0

	include ram.s
;;	include 3d_boot.s
;;	include 3d_vars.s
	include 3d_draw.s
	include 3d_rev.s
	include 3d_mem.s
	include hexdec.s
	include scroll.s
 endc * HUGE

* constant for frequency of re-display
timeout	equ	25				in 50ths of a second

 bra MJAStart
; My workspace...


View
	dc.l 0 ; pointer to first viewport
	dc.l 0 ; copper list ptr
	dc.l 0 ; x,y offsets for whole display
	dc.l 0 ; modes. See P.204 in Kickstart guide

ViewPort
	dc.l 0 ; pointer to next viewport in display
ColorMapPtr	dc.l 0 ; pointer to colormap structure for this slice
	dc.l 0 ; pointer to copper list for display
	dc.l 0 ; copper list to set up sprites
	dc.l 0 ; copper list to remove sprites
	dc.l 0 ; pointer to user copper list
vpwidth	dc.w 0 ; width, height of slice
vpheight	dc.w 0
	dc.w 0 ; x,y offset of slice
	dc.w 0
vpmodes	dc.w 0 ; modes - interlace, dual playfield etc.
	dc.w 0 ; reserved
RasInfoPtr	dc.l 0 ; pointer to rasinfo for this viewport

RastPort
	dc.l 0,0,0,0,0,0 * a jjs structure - not documented

ColorMap
	dc.l 0 * pointer to hardware colortable
RasInfo
	dc.l 0 * pointer to next RasInfo
BitMapPtr	dc.l 0 * pointer to BitMap structure
	dc.w 0 * x offset
	dc.w 0 * y offset
	dc.l 0 * pointer to next RasInfo structure

BitMap
BMBytes	dc.w 0 ; number of bytes per row
BMRows	dc.w 0 ; number of rows
BMFlags	dc.b 0 ; flags
BMDepth	dc.b 0 ; number of bit planes
	dc.b 0 ; padding byte
 even
BMPtrs * pointers to actual bitmaps
Physicalbp0	dc.l 0
Physicalbp1	dc.l 0
Physicalbp2	dc.l 0
Physicalbp3	dc.l 0
Physicalbp4	dc.l 0
	dc.l 0,0,0 * just in case

Logicalbp0 dc.l 0
Logicalbp1 dc.l 0
Logicalbp2 dc.l 0
Logicalbp3 dc.l 0
Logicalbp4 dc.l 0
	dc.l 0,0,0 * just in case

MyColorTable
; Billy The Kid palette, each RGB value*2
 dc.w $0000 * background colour
 dc.w $0ace,$0e46,$0088,$0008,$0060,$0406
 dc.w $0000,$0600,$0008,$0640,$0060,$08c4,$068a,$0446,$0060
 dc.w $0000,$0000,$0000,$0000 ; 10..13
 dc.w $0000,$0000,$0000,$0000 ; 14..17
 dc.w $0000,$0000,$0000,$0000 ; 18..1b
 dc.w $0000,$0000,$0000,$0000 ; 1c..1f




RememberKey ds.l 1

DOSHandle ds.l 1 * handle for default output stream

AllocMemPtr ds.l 1 * pointer into...
AllocMemTable ds.l 64 * number of times we need to call MikeAllocMem
AllocMemTableEnd

MJAStart
 ifnd HUGE
* First batch of experimental code...

 lea AmigaSP,a0
 move.l sp,(a0) * save initial stack pointer.

 bsr AmigaInit

 bsr SetUpKbd
 bsr SetUpVBL
 bsr SetUpAudioInterrupt

; bsr HuffmanDecoderTest
; dc.w $4afa

 bra StructureTest


KeyBoardTestLoop
 move.l #0,CursorXPos
 lea MikeMatrix,a0 * keyboard table (ST format)
 moveq.l #0,d1 * key number

KBDTL1
 move.b (a0)+,d0
 bne.s KBDTL2
 move.l d1,d0
 movem.l d1/a0,-(sp)
  lea KBDNumber,a0
  bsr FormHexLong * poke in size of memory we asked for
  lea KBDText,a0
  bsr DOSText * dc.w $4afa
 movem.l (sp)+,d1/a0

KBDTL2
 add.w #1,d1
 cmp.w #120,d1
 bcs.s KBDTL1
 lea MikeTemp,a4
 bsr MCOSrdch
 move.w 4(a4),d0
 cmp.w #1,d0
 bne.s KeyBoardTestLoop
 dc.w $4afa
 bra CloseDown

KBDText
KBDNumber
 dc.b "       ",0
 even

; move.l #0,a0
;  lea MikePointer,a1
; move.w #200,d0 * height
; move.w #300,d1 * width
; move.w #0,d2
; move.w #0,d3
; move.l _IntuitionBase,a6
; jsr -$10e(a6) * SetPointer
; bra MLSoundLoop
; lea $dff000,a5
; move.w #$8780,INTENA(a5) * enable all audio interrupts

MLSoundTest
 move.l #12000,d0 * size to grab
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
* d0.l is area allocated
 move.l d0,a0
 beq MLEnd
 move.l d0,MidiFileStart
 lea MidiFilename,a1
 move.w #12000,d7 * max size to load
 move.l a0,-(sp)
  bsr LoadStructures
 move.l (sp)+,a0



 move.l #10000,d0 * size to grab
 move.l #MEMF_CHIP,d1
 bsr MikeAllocMem
* d0.l is area allocated
 move.l d0,a0
 beq MLEnd
 lea c1RecorderFilename,a1
 move.w #3000,d7 * max size to load
 move.l a0,c1RecorderAddress * parameter for setupsoundd0
 move.l a0,WaveFormAddress
 bsr LoadStructures

 move.l c1RecorderAddress,a0
 add.l #3000,a0 * kludge max length
 lea c2RecorderFilename,a1
 move.w #3000,d7 * max size to load
 move.l a0,c2RecorderAddress * parameter for setupsoundd0
 bsr LoadStructures

 move.l c2RecorderAddress,a0
 add.l #3000,a0 * kludge max length
 lea c3RecorderFilename,a1
 move.w #3000,d7 * max size to load
 move.l a0,c3RecorderAddress * parameter for setupsoundd0
 bsr LoadStructures


* go through making range -128..127 rather than ST's 0..255
 move.l WaveFormAddress,a0
 move.w #10000,d3
MLChangeLoop
 move.b (a0),d2
 sub.b #128,d2
;; asl.b #4,d2
 move.b d2,(a0)+
 dbra d3,MLChangeLoop


* First a few notes on midi timing:
* The basic unit is the tick, which CLAB fixes at 768 ticks/second.
* Other sequencers may use different values (CLAB can also use 1400-odd)
* but I believe this is fairly standard.
* Next comes the timebase, which is defined in the header below:
* This is measured in ticks/beat.

* From this can be derived the tempo: in beats/minute.
* This is the format the Roland MPU401 prefers: i.e. tempo and timebase.

* The timing codes with each midi event (i.e. the note on/note off
* messages). 

* start by reading MIDI header, which is of the following form:
* (See P.321... in Midi Sequencing in C)
*
* bytes	Contents
*
* ....	"MThd" text
* ....	Length (?)			 0 for CLAB Files.
* ..	Format: either 0 or 1.		 0 for CLab Files.
* ..	Tracks.			 1 for CLab Files.
* ..	Timebase.			C0 for CLab Files.
* ....	"MTrk" text: marks start of each track
* ....	length
* 	Then a stream of times, events:
* VarLen	Time before next item.
* ...	Midi event in standard format ready for output
* 	(e.g. 91 45 5c is note 45 on channel 1, velocity 5c)

* Varlen size: take each byte, if bit 7 is zero, we have the
* number. If bit 7 is 1, shift this number 7 left and add on
* the result of doing this process again on the next byte. Recursive.
* Max number of bytes is about 10, but VERY unlikely!
 move.l MIDIFileStart,a0
 cmp.l #"MThd",(a0)+ * header text
 bne.s BadMidi
 move.l (a0)+,MidiLength
 move.w (a0)+,d0 * Midi type: ignore
 move.w (a0)+,d0 * tracks: ignore at present. Assume 1 only
 move.w (a0)+,d0 * division
 cmp.l #"MTrk",(a0)+ * track header
 bne.s BadMidi
 move.l (a0)+,d0 * length
 move.l a0,CurrentMidiPtr
 move.w #'0',d0 * fake keypress for sound pitch
 bra MLRestartSound

BadMidi
 dc.w $4afa
 bra CloseDown
;---------
GetVarLength
* return d0.l as the variable-length number (Midi format) at a0.l
 clr.l d0
GVL1
 move.b (a0)+,d1
 bmi.s GVL2
* number finished
 or.b d1,d0
 rts

GVL2
 and.b #$7f,d1
 or.b d1,d0
 asl.l #7,d0
 bra.s GVL1
;--------
HandleMidiEvent
 move.l CurrentMidiPtr,a0
 bsr GetVarLength
* d0.l is the time before the next event
* add on age to all note timers
 lea Channel0Records,a1
 move.w #4-1,d2 * loop count
HME1
 move.w (a1),d1
 beq.s HME2
 add.w d0,d1
 move.w d1,(a1)
HME2
 addq.l #4,a1
 dbra d2,HME1


* delay loop...
HMEDelay1
 move.w #$700,d1 *#$900,d1 * $680,d1
HMEDelay2
 dbra d1,HMEDelay2
 dbra d0,HMEDelay1

 move.b (a0)+,d1
 cmp.b #$ff,d1
 beq MidiMetaEvent
 move.b d1,d2
 and.b #$F0,d2 * remove channel number, leaving just the type
 cmp.b #$90,d2
 beq.s MidiNoteOn
 cmp.b #$80,d2
 beq MidiNoteOff

GenericThreeByte
 addq.l #2,a0 * skip the two arguments
 rts
;--------------
MidiNoteOn
* note after time d0.w
 movem.l d0-d7/a0-a6,-(sp)
MNO1
 bsr AbsGetCharFromBDos
; cmp.b #0,d0
; beq.s MNO1
 cmp.b #32,d0
 beq MLEnd

 cmp.b #'0',d0
 bne.s MNO1a
 bsr CloseDownSound * turn off all notes.

MNO1a
 cmp.b #13,d0
 bne.s MNO2
 dc.w $4afa
MNO2
 movem.l (sp)+,d0-d7/a0-a6

TransposeValue equ 8 * transpose an octave up, down from c# to a
 clr.w d3
 move.b (a0)+,d3 * note value
 move.b (a0)+,d6 * velocity - picked up from here by setupsound
 asr.w #1,d6 * midi velocity is 0..127, amiga is 0..63
 cmp.b #10,d6
 bcs MidiNoteOff2 * low velocity(volume) - turn note off

 movem.l d0-d3,-(sp)
  bsr GetFreeChannel * get free channel d4.w for note number d3.w
 movem.l (sp)+,d0-d3
 tst.w d4
 bmi MNONoChannel

 add.w #TransposeValue,d3
 move.l c1RecorderAddress,d0 * waveform table to use.
 move.w #2576/2,d1 * length of sample
 cmp.b #72,d3 * c0: middle c
 bcs.s GotWaveform

 sub.b #12,d3 * transpose down in period table because
* the fundamental frequency of our sample is higher
 move.l c2RecorderAddress,d0
 move.w #2379/2,d1 * length of sample
 cmp.b #72,d3 * c1: c above that
 bcs.s GotWaveForm

 sub.b #12,d3 * transpose down in period table because
* the fundamental frequency of our sample is higher
 move.l c3RecorderAddress,d0
 move.w #1636/2,d1 * length of sample

GotWaveForm
 asr.w #2,d1 ************ divide by 4 to improve precision
 add.w d3,d3 * get table index
 lea AmigaMidiToPeriodTable,a1
 move.w 0(a1,d3.l),d2 * period for this midi note

 move.w #$7fff,MikeCounter * don't turn off the sound - should cycle
;; move.w #2379/2,d1 * 2379 for c2. 2576/2 for c3. * length of sound in WORDS.
; move.l WaveformAddress,d0 * would sign-extend but we're in chip (low) memory
; add.l #$0,d0 * skip over header ( roughly)
* offset $10c0, length $3c0 for saxophone.
 movem.l d0-d2/a0,-(sp)
;;  move.w #1,d4 * channel number 0..3
  bsr SetupSoundD0Chand4
 movem.l (sp)+,d0-d2/a0
MidiNoteOnRet
MNONoChannel
 rts
;-------
GetFreeChannel
* get channel number to use in d4.w
* to play midi (roland) tone number d3.w
* Choose them in order 0,2,1,3 because 0,2 are right;
* 1,3 are left.
 lea Channel0Records,a1
 move.w #0,d4 * channel number
 move.w (a1),d0 * free?
 beq GFCRet * yup
* no, another channel?

 lea Channel2Records,a1
 move.w #2,d4 * channel number
 move.w (a1),d0 * free?
 beq GFCRet * yup
* no, another channel?

 lea Channel1Records,a1
 move.w #1,d4 * channel number
 move.w (a1),d0 * free?
 beq.s GFCRet * yup
* no, another channel?

 lea Channel3Records,a1
 move.w #3,d4 * channel number
 move.w (a1),d0 * free?
 beq.s GFCRet * yup

* choose one of the channels to kill...
* a0.l points to the rest of the midi file...
* Go through and look for imminent "note off" commands
 clr.w d0 * cumulative time from now
 clr.w d1

 movem.l d3/a0,-(sp) * save midi ptr
 bra FindNoteToKillNotFound *************** disable the scan!
FindNoteToKill1
  move.b (a0),d1
  add.w d1,d0 * cumulative time from now
  cmp.w #10,d0 * close enough?
  bcc.s FindNoteToKillNotFound
  move.b 1(a0),d1 * midi command
  and.b #$f0,d1
  cmp.b #$80,d1 * note off?
  beq.s FindNoteToKill2
  cmp.b #$90,d1 * note on?
  bne.s FindNoteToKillLoop
  move.b 3(a0),d1 * low velocity note on?
  cmp.b #10,d1
  bcs.s FindNoteToKill2
  
FindNoteToKillLoop
 addq.l #4,a0
 bra.s FindNoteToKill1
 
FindNoteToKill2
* got note! Number=2(a0)
 clr.w d3
 move.b 2(a0),d3
 movem.w d0-d1,-(sp) * save in case we go back to FNTKLoop
  bsr MidiNoteOff2
 movem.w (sp)+,d0-d1
* d3.w is the channel number we turned off
 ext.l d3
 cmp.b #3,d3
 bcc.s FindNoteToKillLoop * didn't find this note.
 asl.l #2,d3 * times 4 =  ChannelRecordsSize
 lea Channel0Records,a1
 add.l d3,a1

FindNoteToKill3
 movem.l (sp)+,d3/a0

GFCRet
 move.w #1,TimeOffset(a1) * mark this channel as being in use
 move.w d3,NoteNumberOffset(a1) * record the note number
* so our note off command will find the right note.
 rts

FindNoteToKilla1
* kill channel with records a1.l
 move.l a1,d4
 sub.l #Channel0Records,d4
 asr.w #2,d4 * returns d4.w as the channel nummber
 movem.l (sp)+,d3/a0
 bra.s GFCRet

;--------
FindNoteToKillNotFound
* no notes are just about to be turned off - so pick the longest
* existing notes
 lea Channel0Records,a1 * channel containing current oldest
 move.w (a1),d3 * age of oldest
 move.l a1,a0 * current channel to examine
FNTKNF0
 cmp.w (a0),d3
 bcc.s FNTKNF1
 move.l a0,a1
 move.w (a0),d3

FNTKNF1
 add.l #4,a0
 cmp.l #Channel3Records+4,a0
 bcs.s FNTKNF0
* a1.l is the address of the records for the oldest channel
 cmp.w #$140,d3
 bcc FindNoteToKilla1

 movem.l (sp)+,d3/a0 *****
 move.w #-1,d4 *****
 rts *******

* our longest note is very short - something like a
* quaver in 120 time. Try instead searching for the lowest note.
* This will usually be accompianament, so will matter less
* if it has to disappear.
 lea Channel0Records,a1 * channel containing current lowest
 lea Channel0Records,a2 * channel containing current highest
 move.w 2(a1),d3 * note number of lowest
 move.w 2(a1),d4 * note number of highest
 move.l a1,a0 * current channel to examine
FNTKNF2
 cmp.w (a0),d3
 blt.s FNTKNF3 * our lowest is lower
 move.l a0,a1
 move.w (a0),d3

FNTKNF3
 cmp.w (a0),d4
 bgt.s FNTKNF4 * our highest is highest
 move.l a0,a2
 move.w (a0),d4

FNTKNF4
 add.l #4,a0
 cmp.l #Channel3Records+4,a0
 bcs.s FNTKNF2
* a1.l is the address of the records for the lowest channel
* a2.l is the address of the records for the hightest channel
* d3.w is lowest note, d4,w is highest note
* Now pick a note that is in the middle - one of the other two
* channels

 lea Channel0Records,a0
FNTKNF5a
 move.w 2(a0),d0
 cmp.w d3,d0
 beq.s FNTKNF5
 cmp.w d4,d0
 beq.s FNTKNF5
 move.l a0,a1
 bra FindNoteToKilla1

FNTKNF5
 addq.l #4,a0
 cmp.l #Channel3Records+4,a0
 bcs.s FNTKNF5a
 dc.w $4afa
* a1.l is channel containing lowest note - as
* last resort, we'll use that.
 bra FindNoteToKilla1
;-------
;----
MidiNoteOff
; addq.l #2,a0 * skip the two arguments
 clr.w d3
 move.b (a0)+,d3 * note value
 move.b (a0)+,d1 * velocity 
MidiNoteOff2 * come here from midi note on, velocity=0
* figure out which channel is playing this note and turn it off.
 lea Channel0Records,a1
 cmp.w NoteNumberOffset(a1),d3
 beq.s MNOGotcha
 lea Channel1Records,a1
 cmp.w NoteNumberOffset(a1),d3
 beq.s MNOGotcha
 lea Channel2Records,a1
 cmp.w NoteNumberOffset(a1),d3
 beq.s MNOGotcha
 lea Channel3Records,a1
 cmp.w NoteNumberOffset(a1),d3
 beq.s MNOGotcha
* not found - ignore. Probably turned off already
* by the channel allocation code (GetFreeChannel)
 move.w #$ffff,d3 * error code
 rts

MNOGotcha
 move.w #0,TimeOffset(a1)
 move.w #0,NoteNumberOffset(a1)
 sub.l #Channel0Records,a1
 move.l a1,d3
 divu #ChannelRecordsSize,d3
 cmp.w #4,d3
 bcs.s MNORangeCheck
 dc.w $4afa
 rts

MNORangeCheck
* d3.w is channel number
 move.w d3,-(sp)
  asl.w #4,d3
  lea $dff000,a5
  ext.l d3
  add.l d3,a5
  move.w #0,aud0len(a5) * kill sound
 move.w (sp)+,d3
 move.w #1,d4
 asl.w d3,d4 * shift bit we want to turn off
 lea $dff000,a5
 move.w d4,dmacon(a5) * audio dma off
; eor #$ffff,d4
; move.w LastDMACon,d5
; and.w d5,d4
; move.w d4,LastDMACon
 lea mikeCounter,a5 * make a5 safe for monitor again.
 rts
;-----
MidiMetaEvent
* next byte specifies what type of event it is. Mostly
* ignored at present.
 move.b (a0)+,d1
 cmp.b #1,d1
 beq.s MidiMetaText
 cmp.b #$20,d1
 beq.s MidiChannelPrefix
 cmp.b #$2f,d1
 beq.s MidiEndOfTrack
 cmp.b #$5f,d1
 beq.s MidiSetTempo
 cmp.b #$58,d1
 beq.s MidiTimeSignature
 nop * keep assembler happy

MidiTimeSignature
MidiSetTempo
MidiChannelPrefix
MidiEndOfTrack
 rts

MidiMetaText
 clr.l d0
 move.b (a0)+,d0
* d0.l is the length of the meta text.
 add.l d0,a0 * skip the meta text.
 rts
;--------
AmigaMidiToPeriodTable
* note number 0 is c-5: 5 octaves below middle c
 dc.w 1708 * c
 dc.w 1708 * c#
 dc.w 1708 * d
 dc.w 1708 * d#
 dc.w 1708 * e
 dc.w 1708 * f
 dc.w 1708 * f#
 dc.w 1708 * g
 dc.w 1708 * g#
 dc.w 1708 * a
 dc.w 1708 * a#
 dc.w 1708 * b

* 4 ocaves below middle c:
 dc.w 1708 * c
 dc.w 1708 * c#
 dc.w 1708 * d
 dc.w 1708 * d#
 dc.w 1708 * e
 dc.w 1708 * f
 dc.w 1708 * f#
 dc.w 1708 * g
 dc.w 1708 * g#
 dc.w 1708 * a
 dc.w 1708 * a#
 dc.w 1708 * b

* 3 octaves below middle c:
 dc.w 1708 * c
 dc.w 1708 * c#
 dc.w 1708 * d
 dc.w 1708 * d#
 dc.w 1708 * e
 dc.w 1708 * f
 dc.w 1708 * f#
 dc.w 1708 * g
 dc.w 1708 * g#
 dc.w 1708 * a
 dc.w 1708 * a#
 dc.w 1708 * b

* 2 octaves below middle c:
 dc.w 1708 * c * exactly.
 dc.w 1612 * c#
 dc.w 1522 * d
 dc.w 1436 * d#
 dc.w 1356 * e
 dc.w 1280 * f
 dc.w 1208 * f#
 dc.w 1140 * g
 dc.w 1076 * g#
 dc.w 1015 * a
 dc.w 958 * a#
 dc.w 905 * b

* 1 octaves below middle c:
 dc.w 854 * c
 dc.w 806 * c#
 dc.w 761 * d
 dc.w 718 * d#
 dc.w 678 * e
 dc.w 640 * f
 dc.w 604 * f#
 dc.w 570 * g
 dc.w 538 * g#
 dc.w 507 * a
 dc.w 479 * a#
 dc.w 452 * b

* middle c:
 dc.w 427 * c * values from the book:
 dc.w 404 * c#
 dc.w 381 * d
 dc.w 359 * d#
 dc.w 339 * e
 dc.w 320 * f
 dc.w 302 * f#
 dc.w 285 * g
 dc.w 269 * g#
 dc.w 254 * a
 dc.w 240 * a#
 dc.w 226 * b

* 1 octaves above middle c:
 dc.w 214 * c
 dc.w 202 * c# doubtful values...
 dc.w 191 * d
 dc.w 180 * d#
 dc.w 170 * e
 dc.w 160 * f
 dc.w 151 * f#
 dc.w 143 * g
 dc.w 135 * g#
 dc.w 127 * a
 dc.w 120 * a#
 dc.w 120 * b

* 2 octaves above middle c:
 dc.w 120 * c
 dc.w 120 * c#
 dc.w 120 * d
 dc.w 120 * d#
 dc.w 120 * e
 dc.w 120 * f
 dc.w 120 * f#
 dc.w 120 * g
 dc.w 120 * g#
 dc.w 120 * a
 dc.w 120 * a#
 dc.w 120 * b

* 3 octaves above middle c:
 dc.w 120 * c
 dc.w 120 * c#
 dc.w 120 * d
 dc.w 120 * d#
 dc.w 120 * e
 dc.w 120 * f
 dc.w 120 * f#
 dc.w 120 * g
 dc.w 120 * g#
 dc.w 120 * a
 dc.w 120 * a#
 dc.w 120 * b

* 4 octaves above middle c:
 dc.w 120 * c
 dc.w 120 * c#
 dc.w 120 * d
 dc.w 120 * d#
 dc.w 120 * e
 dc.w 120 * f
 dc.w 120 * f#
 dc.w 120 * g
 dc.w 120 * g#
 dc.w 120 * a
 dc.w 120 * a#
 dc.w 120 * b

* 5 octaves above middle c:
 dc.w 120 * c
 dc.w 120 * c#
 dc.w 120 * d
 dc.w 120 * d#
 dc.w 120 * e
 dc.w 120 * f
 dc.w 120 * f#
 dc.w 120 * g
 dc.w 120 * g#
 dc.w 120 * a
 dc.w 120 * a#
 dc.w 120 * b





;--------
MLRestartSound
 bsr HandleMidiEvent
 move.l a0,CurrentMidiPtr

; move.w #1000,d1 * length of sound
; move.w #716,d2 * aud0per
;* increase pitch by amount key stroke differs from '0'
; sub.w #'0',d0
; asl.w #5,d0
; add.w d0,d2
; move.l WaveformAddress,d0 * would sign-extend but we're in chip (low) memory
; movem.l d0-d2/a0,-(sp)
;  bsr SetupSoundD0
; movem.l (sp)+,d0-d2/a0


MLSoundLoop
 bra MLRestartSound
 movem.l d1-d2/a0,-(sp)
  bsr AbsGetCharFromBDos
 movem.l (sp)+,d1-d2/a0
; cmp.b #0,d0
; beq.s MLSoundLoop
 cmp.b #32,d0
 beq MLEnd
 cmp.b #'0',d0
 bcs.s MLSoundLoop
 cmp.b #'9',d0
 ble.s MLRestartSound
 move.w #'0',d0
 bra MLSoundLoop

MLEnd
; lea $dff000,a5
;11:39 move.w #$8080,INTENA(a5) * enable aud0 audio interrupt
MLEnd2
; bsr AbsGetCharFromBDos
; cmp.b #13,d0
; bne.s MLEnd2
 lea $dff000,a5
 move.w #$000f,dmacon(a5) * audio dma off
 move.w #$0780,INTENA(a5) * disable all audio interrupts
 lea MikeCounter,a5
 bsr CloseDownSound
 bra CloseDown

MikePointer
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,00,0,0
 even
SpeedCount dc.w 0

PadControlsSprite dc.b 0

 even

MLOrgan
; test code to play tones and allow inc/dec
 move.w #60,d3
MLMike
 movem.l d3,-(sp)
  add.w d3,d3 * get table index
  lea AmigaMidiToPeriodTable,a1
  move.w 0(a1,d3.l),d2 * period for this midi note.
 move.l (sp)+,d3
 move.w #2576/2,d1 * length of sound in WORDS.
 move.l WaveformAddress,d0 * would sign-extend but we're in chip (low) memory
 add.l #$0,d0 * skip over header ( roughly)
* offset $10c0, length $3c0 for saxophone.
 move.w #0,d4
 movem.l d0-d7/a0-a6,-(sp)
  bsr SetupSoundD0Chand4
 movem.l (sp)+,d0-d7/a0-a6
 movem.l d0-d2/a0-a6,-(sp)
MLO2
  bsr AbsGetCharFromBDos
  cmp.b #32,d0
  beq MLEnd
  cmp.b #'=',d0
  bne.s MLNotInc
  addq.w #1,d3
MLNotInc
 cmp.b #'-',d0
 bne.s MLNotDec
 subq.w #1,d3

MLNotDec
 cmp.b #13,d0
 bne.s MLONotBreak
 dc.w $4afa
MLONotBreak
 cmp.b #0,d0
 beq.s MLO2
 movem.l (sp)+,d0-d2/a0-a6
 bra.s MLMike
;----
StructuresFilenameDF0
 dc.b "structur.dat",0
 even

PhysicalClearRectangle rts
OSWRCH rts

StructureTest
 lea S(PC),a5
 move.b #1,UseVM

 bsr MCInitSpritesFile
 lea S(PC),a5
 move.l #40000,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
 move.l d0,FreeWorkSpace-S(A5)
 beq goaway

 move.l #40000,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem
 move.l d0,a0 * parameter for loadstructures.
 beq goaway
 lea StructuresFilenameDF0,a1
 move.l #40000,d7  * max length
 move.l a0,-(sp)
  bsr LoadStructures
 move.l (sp)+,a0
 lea S(PC),a5
 bsr Setup_ptrsA0
 lea S(PC),a5
* set up map size
 lea MikeTemp+16,a4
 move.w #639,2(a4) *319,2(a4) * horizontal size in pixels (e.g. 0..319)
 move.w #383,4(a4) *191,4(a4) * vertical size in pixels (e.g. 0..191)
 move.w #1,6(a4) * game mode. 1 for scrolling
 bsr InitialiseScrolling

 lea S(PC),a5
 move.w #12000,2(a4) **** MUCH larger for raj test. 2000,2(a4) * number of cells
 move.w #1500,4(a4) * links
 move.w #1500,6(a4) * now redundant
 move.w #1500,8(a4) * masks
 bsr MCSetUpVariablePtrs * Also sets up pool, so chobbles all memory

* ScrollDirection: v1=horiz step, v2=vert step, +/- words
* returns actual values

 lea S(PC),a5
 bsr MCEmptyRoom
 lea MikeTemp+16,a4
 bsr MCPre_load_cells
 move.w #546,2(a4) * was 400 for scrolling. 546 is Raj
 move.w #0,4(a4) * x
 move.w #0,6(a4) * z
 move.w #0,8(a4) * h
 move.w #3,10(a4) * preload
 move.w #0,12(a4) * not reversed
 bsr MCMake_Pic0
 move.w #401,2(a4)
 move.w #0,4(a4) * x
 move.w #3,10(a4) * preload
 bsr MCMake_Pic0
 bsr MCPre_load_cells

 lea MikeTemp,a4
 move.w #546,2(a4) **** RAJ ..... 400,2(a4) * TR is 400
 move.w #320,4(a4) * x
 move.w #0,10(a4) * build
 bsr MCMake_Pic0
 move.w #401,2(a4) * BR is 401
 move.w #-200,8(a4) * h
 bsr MCMake_pic0

 move.w #400,2(a4) * BL is 400
 move.w #0,4(a4) * x
 bsr MCMake_Pic0
 move.w #401,2(a4) * TL is 401
 move.w #0,8(a4) * h
 bsr MCMake_pic0

 move.w #128,2(a4) * x position of map
 move.w #128,4(a4) * y position of map
 bsr MCBuildRoom

 lea S(PC),a5
 lea MikeTemp+16,a4
 move.w #520,2(a4) * ****501,2(a4)
 move.w #220,4(a4) * x
 move.w #176,6(a4) * z
 move.w #100,8(a4) * h
;; bsr MLSpriteSpeed

MLSpriteTest
; move.l BufferScreen1-S(A5),a0 *********
; move.w #0,(a0) ************************

 bsr MCDisplayRoom
; bsr MCClearScreen
; movem.l a0-a6,-(sp)
;  CALLGRAF WaitBlit
; movem.l (sp)+,a0-a6
 WaitBlitter
 bsr MLDelay

 lea MikeTemp+16,a4
 move.w #1,10(a4) * draw
 move.w #0,12(a4) * not reversed
 bsr MCMake_Pic0

 lea S(PC),a5
 move.l a4,-(sp)
  lea MikeTemp+16,a4
  move.w #546,2(a4) ***** 521,2(a4)
  move.w #160,4(a4)
  move.w #200,6(a4)
  move.w #128,8(a4)
  move.w #1,10(a4) * draw
  move.w #0,12(a4) * not reversed
  bsr MCMake_Pic0
 move.l (sp)+,a4


; movem.l a0-a6,-(sp)
;  CALLGRAF WaitBlit
; movem.l (sp)+,a0-a6
 WaitBlitter
 bsr MLDelay

 bsr MCUpdateScreen
 bsr DisplayFrame

MLFrameLimit
 move.w VBLTicks,d0
 cmp.w #2,d0
 bcs.s MLFrameLimit
 move.w #0,VBLTicks
 bsr WaitForFrame


 bsr TestKeyboardHandler

; clr.w d0
; move.w ScrollXPos,d0
; move.w d0,d1
; asl.w #4,d1 * duplicate scroll value in next nybble
; or.w d1,d0
; move.l CopperListScrollAddress,a0
; move.w d0,(a0)
; move.w d0,$dff102

 bra MLSpriteTest
;----
TestKeyboardHandler
 move.l #0,d1
ClearKbdLoop
 move.l d1,-(sp)
  bsr AbsGetCharFromBDos * The equivalent of MCOsrdch
 move.l (sp)+,d1
 tst.b d0
 beq.s ClearKbd1
 move.b d0,d1
 bra.s ClearKbdLoop

ClearKbd1
 move.b d1,d0
; beq.s ClearKbdLoop ;* force a key press every frame
; cmp.b #27,d0
; beq goaway

 move.w CallsBeforePause,d2
 beq.s TKH2
 subq.w #1,d2
 move.w d2,CallsBeforePause

 move.b d1,d0
 bne.s TKH2
TKH1a
 bsr AbsGetCharFromBDos * The equivalent of MCOsrdch
 tst.b d0
 beq.s TKH1a



TKH2
 cmp.b #'s',d0
 bne.s TKHNotStep
 add.w #1+1,CallsBeforePause-S(A5)

TKHNotStep
 cmp.b #'w',d0
 bne.s TKHNotWait
 add.w #10+1,CallsBeforePause-S(A5)

TKHNotWait
 cmp.b #'r',d0
 bne.s TKHNotRun
 move.w #0,CallsBeforePause-S(A5)

TKHNotRun

 lea MikeTemp,a4
 cmp.b #' ',d0
 bne.s MLNotBreak
 dc.w $4afa

MLNotBreak
 cmp.b #"q",d0
 beq CloseDown
 cmp.b #"Q",d0
 beq CloseDown

 cmp.b #'0',d0
 bne.s MLNotToggle
* toggle between cursor pad controlling screen scroll and
* controlling sprite movement
 move.b PadControlsSprite,d0
 eor #255,d0
 move.b d0,PadControlsSprite

MLNotToggle
 cmp.b #'+',d0
 bne.s NotIncreaseSprite
 addq.w #1,2(a4)

NotIncreaseSprite
 cmp.b #'-',d0
 bne.s NotDecreaseSprite
 subq.w #1,2(a4)

NotDecreaseSprite
* move.l #0,XDir * Make screen move once per press **********

StepSizeChange equ 4

 cmp.b #'4',d0
 bne.s MLNotLeft
 move.b PadControlsSprite,d0
 beq.s MLLeftScroll
 subq.w #1,4(a4)
 bra.s MLNotLeft
MLLeftScroll
 sub.w #StepSizeChange,XDir * bsr CompleteMoveLeft

MLNotLeft
 cmp.b #'6',d0
 bne.s MLNotRight
 move.b PadControlsSprite,d0
 beq.s MLRightScroll
 addq.w #1,4(a4)
 bra.s MLNotRight
MLRightScroll
 add.w #StepSizeChange,XDir * bsr CompleteMoveRight

MLNotRight
 cmp.b #'8',d0
 bne.s MLNotUP
 move.b PadControlsSprite,d0
 beq.s MLUpScroll
 addq.w #1,8(a4) * h
 bra.s MLNotUp
MLUpScroll
 sub.w #StepSizeChange,YDir * bsr CompleteMoveUp

MLNotUp
 cmp.b #'2',d0
 bne.s MLNotDown
 move.b PadControlsSprite,d0
 beq.s MLDownScroll
 subq.w #1,8(a4) * h
 bra.s MLNotDown
MLDownScroll
 add.w #StepSizeChange,YDir * bsr CompleteMoveDown

MLNotDown
 cmp.b #'3',d0
 bne.s MLNotIncreaseZ
 addq.w #1,6(a4) * z

MLNotIncreaseZ
 cmp.b #'9',d0
 bne.s MLNotDecreaseZ
 subq.w #1,6(a4) * z

MLNotDecreaseZ
 move.l a4,-(sp)
  lea XDir-2,a4
  bsr MCScrollDirection
 move.l (sp)+,a4

 cmp.b #'Z',d0
 beq.s MLScrollLeft
 cmp.b #'z',d0
 bne.s MLNotScrollLeft
MLScrollLeft
 clr.w d0
 move.w ScrollXPos,d0
 add.b #1,d0
 and.b #15,d0
 move.w d0,ScrollXPos

MLNotScrollLeft
 cmp.b #'X',d0
 beq.s MLScrollRight
 cmp.b #'x',d0
 bne.s MLNotScrollRight
MLScrollRight
 move.w ScrollXPos,d0
 sub.b #1,d0
 and.b #15,d0
 move.w d0,ScrollXPos

MLNotScrollRight


 rts

;----
DisplayFrame
 move.b #1,FrameReady
 rts

WaitForFrame
 move.b FrameReady,d0 
 bne WaitForFrame
 rts
;----
MLDelay
 move.l #800,d0 * a short delay
MLDelay1
 subq.l #1,d0
 bne.s MLDelay1
 rts
;---
MLSpriteSpeed
 bsr MCDisplayRoom
 lea MikeTemp,a4
 move.w #501,2(a4)
 move.w #72,4(a4) * x
 move.w #72,6(a4) * z
 move.w #0,8(a4) * h
 move.w #1,10(a4) * draw
 move.w #0,12(a4) * not reversed
 lea MikeVBLCounter,a0
 dc.w $4afa
 clr.l (a0) * reset counter
;; move.w #500,d7 * Do 500 room displays ( about 25 seconds, probably)
 move.w #500,d7 * plot sprite 50000 times

MLSpriteSpeedLoop
 lea MikeTemp,a4
 move.w d7,-(sp)
  bsr make_pic0
 move.w (sp)+,d7
 dbra d7,MLSpriteSpeedLoop
 move.l MikeVBLCounter,d0
 move.l d0,MikeResult * store result permamently
 dc.w $4afa
 rts
;----
 lea MikeVBLCounter,a0
 dc.w $4afa
 clr.l (a0) * reset counter
;; move.w #500,d7 * Do 500 room displays ( about 25 seconds, probably)
 move.w #5000,d7 * plot sprite 50000 times

MLRoomLoop
 move.w d7,-(sp)
;;  bsr MCDisplayRoom
  bsr make_pic0
 move.w (sp)+,d7
 dbra d7,MLRoomLoop
 move.l MikeVBLCounter,d0
 move.l d0,MikeResult * store result permamently

MLRoomLoop2
 bsr MCDisplayRoom
 bsr ActuallySwapScreen
 bsr AbsGetCharFromBDos
 cmp.b #32,d0
 beq goaway
 bra MLRoomLoop2 **
 cmp.b #27,d0
 bne.s MLRoomLoop2
 bra goaway





MNL1
 move.l #$12345678,d0
 lea METNumber,a0
 bsr FormHexLong * poke in size of memory we asked for
 lea MemoryErrorText,a0
 bsr DOSText * dc.w $4afa
 bra MNL1

ML2
; copy keyboard table to physical screen for debugging
; lea MikeMatrix,a0
; tst.b 1(a0) * is escape key pressed?
; bne.s MLRet
 bsr AbsGetCharFromBDOS
; cmp.b #27,d0
; beq goAway
 cmp.b #32,d0
 bne ML3
 bsr DisplayScreen ; redisplay screen, with new palette.
 bra ML2


ML3
 bra ML2

MLRet
 rts

 move.l PhysicalBP0,a0
 move.l #$FFFFFFFF,(a0)+
 move.l #$FFFFFFFF,(a0)+
 move.l #$FFFFFFFF,(a0)+
 move.l #$FFFFFFFF,(a0)+
 move.l #$FFFFFFFF,(a0)+
 move.l #$FFFFFFFF,(a0)+

 move.l LogicalBP0,a0
 move.l #$F0F0F0F0,(a0)+
 move.l #$F0F0F0F0,(a0)+
 move.l #$F0F0F0F0,(a0)+
 move.l #$F0F0F0F0,(a0)+
 move.l #$F0F0F0F0,(a0)+
 move.l #$F0F0F0F0,(a0)+

 bsr ActuallySwapScreen

 MOVE.L #$100000,d0
MJALoop1
 subq.l #1,d0
 bne.s MJALoop1

 bsr ActuallySwapScreen

 MOVE.L #$100000,d0
MJALoop2
 subq.l #1,d0
 bne.s MJALoop2
 bra NormalExit
 endc * HUGE: experimental code
;-------
GoAway
 ifne PossessBlitter
 CALLGRAF DisownBlitter
 endc

 bsr MikeFreeMem * deallocate memory used for graphics windows

 lea ViewPort,a0
 CALLGRAF FreeVPortCopLists

 move.l ColormapPtr,a0
 CALLGRAF FreeColorMap

 move.l _IntuitionBase,a6
 jsr -$180(a6) * RemakeDisplay

; move.l PhysicalBP0,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l PhysicalBP1,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l PhysicalBP2,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l PhysicalBP3,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; ifne Colors32
;  move.l PhysicalBP4,a0
;  move.w #320,d0
;  move.w #200,d1
;  CALLGRAF FreeRaster
; endc

; move.l LogicalBP0,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l LogicalBP1,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l LogicalBP2,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; move.l LogicalBP3,a0
; move.w #320,d0
; move.w #200,d1
; CALLGRAF FreeRaster
; ifne Colors32
;  move.l LogicalBP4,a0
;  move.w #320,d0
;  move.w #200,d1
;  CALLGRAF FreeRaster
; endc

 bsr CloseLibraries * must be the last thing we do
 moveq #0,d0
 rts * exit
;----
CloseLibraries
	move.l _IntuitionBase,a1
	CALLEXEC CloseLibrary
	move.l	_GfxBase,a1
	CALLEXEC CloseLibrary
	move.l	_DOSBase,a1
	CALLEXEC CloseLibrary
	rts
;---
numData equ 300
akey equ $bfec01
pri equ 100

Type equ 2
IntNum equ 3 * CIA interrupt - probably keyboard.
;is_data equ 14
;is_Code equ 18
;ln_type equ 8
;ln_Pri equ 9
;ln_Name equ 10
AllocMem equ -198
Freemem equ -210
AddIntServer equ -168
RemIntServer equ -174
AvailMem equ -216

;-----------
MCKeyDown
; v1 is scan code. Return v1=0 if up, non-zero if down.
 lea MikeMatrix,a0 * keyboard table (ST format)
 move.w 2(a4),d0
 move.b (a0,d0.w),d0 * read table.
;; eor.b #128,d0 * flip top bit
 move.w d0,2(a4)
 rts

;------------


SetUpKBD
* This example taken from P.305, Amiga System Programmer's Guide
 move.l #300,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem * get memory for the structures we want to set up
 move.l d0,a2
 beq SUKRet
 add.l #32,d0 * start of data storage
 move.l d0,is_data(a2)
 move.b #pri,ln_pri(a2)
 move.b #Type,ln_type(a2)
 move.l #EndKbd-StartKbd+8,d0 * code size set for program
 bsr MikeAllocMem * get memory to copy interrupt handler into.
 move.l d0,a3
 beq SUKRet * couldn't get memory

 move.l a3,is_Code(a2)
 move.l a2,a1 * interrupt structure

 lea StartKbd,a2
 move.l #EndKbd-StartKbd,d0
L1
* copy handler into the memory we've set up
 move.b (a2)+,(a3)+
 dbf d0,l1


; set up circular buffer for keystrokes
 clr.w d0
 move.w d0,KBDReadPtr
 move.w d0,KBDFreeSpacePtr
 move.w d0,KBDCharsInBuffer
; clear keyboard table
 lea MikeMatrix,a0
 move.w #128/4-1,d0
CKT1
 clr.l (a0)+
 dbra d0,CKT1

 move.l $4,a6 * load base ptr
 move.l #3,d0 * interrupt number for key int
 jsr AddIntServer(a6)


SUKRet
 rts

CloseDownKBD
 move.l KbdNextInterrupt,d0
 beq.s NoKbd
 move.l d0,a1 *  next interrupt after our handler
 move.l #3,d0 * interrupt number for key int
 move.l $4,a6
 jsr RemIntServer(a6)
NoKbd
 rts
;---
SetUpVBL
 move.l #300,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem * get memory for the structures we want to set up
 move.l d0,a2
 beq SUKRet
 add.l #32,d0 * start of data storage
 move.l d0,is_data(a2)
 move.b #pri,ln_pri(a2)
 move.b #5,ln_type(a2) * Type - vertical blank. See P.287 System Prog.
 move.l #EndVBL-StartVBL+8,d0 * code size set for program
 bsr MikeAllocMem * get memory to copy interrupt handler into.
 move.l d0,a3
 beq SUKRet * couldn't get memory

 move.l a3,is_Code(a2)
 move.l a2,a1 * interrupt structure

 lea StartVBL,a2
 move.l #EndVBL-StartVBL,d0
L2
* copy handler into the memory we've set up
 move.b (a2)+,(a3)+
 dbf d0,l2

 move.l $4,a6 * load base ptr
 move.l #5,d0 * for vertical blank interrupt: number 5. See P.287 System.
 jsr AddIntServer(a6)
 rts

StartVBL
 move.l a5,-(sp)
 move.l d0,a5 * next interrupt
 move.l 4(a5),a1 * interrupt after a1
 move.l a1,VBLNextInterrupt * save for benefit of closedown routine
** jsr irqVBLHandler * have to use jsr because this code
* executes in a separate area of memory, at a random location
** jsr ActuallySwapScreen (Works fine)
** jsr irqHBLHandler * works fine

 jsr irqVBLHandler

 lea MikeVBLCounter,a1
 addq.l #1,(a1)

;; move.w #0,joytest * stop OS getting the mouse movement.
;; move.w #$ffff,joytest * make os move mouse to bottom right
* keep on incrementing joystick value to make sure it keeps
; on moving towards the bottom right of the screen
 lea MouseDistances,a1
 move.w joy0Dat,d0 * read mouse distance since last read.
 move.w d0,d1

; move.w #1,d2 ***

 and.w #$00ff,d0 * x value
 sub.b MikeJoystickValue,d0 * subtract what we set it to last time.
 ext.w d0
 and.w #$FFFC,d0 * lose bottom two bits as well
; bpl.s GotXSign *****
; move.w #-1,d2 *&***
;GotXSign ******
; move.w d2,d0 *****

 add.w d0,(a1)
 asr.w #8,d1 * y value
 sub.b MikeJoystickValue+1,d1 * subtract what we set it to last time.
 ext.w d1
 and.w #$FFFC,d1 * lose bottom two bits
 add.w d1,2(a1)
; move.w #0,joytest

 move.b MikeJoystickValue,d0
 add.b #40,d0
 move.b d0,MikeJoystickValue
; move.b d0,d1
; lsl.w #8,d1
; or.w d1,d0
 move.b MikeJoystickValue+1,d0
 add.b #40,d0
 move.b d0,MikeJoystickValue+1
 move.w MikeJoystickValue,d0
 move.w d0,joytest

* (Which keeps it very nearly off-screen)
 move.l MikeSpriteData,d0
 move.l d0,$dff120 * set up all sprite pointers
 move.l d0,$dff124
 move.l d0,$dff128
 move.l d0,$dff12c
 move.l d0,$dff130
 move.l d0,$dff134
 move.l d0,$dff138
 move.l d0,$dff13c

 move.l (sp)+,a5
 clr.l d0 * allow other things to get interrupts (at least:
* mouse handler, thing which turns the disk light off)
 rts


EndVBL

CloseDownVBL
 move.l VBLNextInterrupt,d0
 beq.s NoVBL
 move.l d0,a1 *  next interrupt after our handler
 move.l #5,d0 * interrupt number for vbl interrupt
 move.l $4,a6
 jsr RemIntServer(a6)
NoVBL
 rts
;-----
SetUpAudioInterrupt
* the audio interrupt merely turns off the sampled sound
* at its end - to prevent it looping
 ifne WantSampledSound *ReleaseGame

 move.l #300,d0
 move.l #MEMF_FAST,d1
 bsr MikeAllocMem * get memory for the structures we want to set up
 move.l d0,a2
 beq SUKRet
 add.l #32,d0 * start of data storage
 move.l d0,is_data(a2)
 move.b #pri,ln_pri(a2)
 move.b #7,ln_type(a2) * Type - vertical blank. See P.287 System Prog.
 move.l #EndAudio-StartAudio+8,d0 * code size set for program
 bsr MikeAllocMem * get memory to copy interrupt handler into.
 move.l d0,a3
 beq SUKRet * couldn't get memory
 move.l a3,is_Code(a2)
 move.l a2,a1 * interrupt structure
 lea StartAudio,a2
 move.l #EndAudio-StartAudio,d0
SUAL2
* copy handler into the memory we've set up
 move.b (a2)+,(a3)+
 dbf d0,SUAl2

 move.w #1,MikeCounter  * only acknowledge nth iteration of interrupt

 move.l #7,d0 * number
* a1.l is address of interrupt structure
 move.l $4,a6 * load base ptr
 jsr -$a2(a6) * SetIntVector(a6)

 endc * WantSampledSound
 rts


; move.l $4,a6 * load base ptr
; move.l #7,d0 * for audio0 interrupt: number 7. See P.287 System.
; jsr AddIntServer(a6)
; rts

StartAudio
* See P.59 Exec manual...
* acknowledge interrupt...
; move.w #$0080,$009c(a0) * intreq=$009c, intf_aud0=$0080
 move.l a5,-(sp)
 move.w #$0380,$dff09c * acknowledge interrupt:
* Bit 7=aud0, 8=aud 1 etc. Presently clear all of them!********
* Hardware base=dff000, intreq=$009c, intf_aud0=$0080
  lea MikeCounter,a5
  cmp.w #$7fff,(a5)
  move.w MikeTurnOffSound,d0
  beq.s SAEnd * don't turn this sound off
  sub.w #1,(a5)
  bpl.s SAEnd
  lea $dff000,a5
  move.w #$000f,dmacon(a5) * audio dma off
  move.w #$0080,INTENA(a5) * disable aud0 audio interrupt

  move.w #0,aud0len(a5) * zero length sound * don't play again.

SAEnd
 move.l (sp)+,a5
 rts

EndAudio

MikeCounter ds.w 1
MikeTurnOffSound dc.w 0

CloseDownAudio
 ifne WantSampledSound
 move.l AudioNextInterrupt,d0
 beq.s NoAudio
 move.l d0,a1 *  next interrupt after our handler
 move.l #5,d0
 move.l $4,a6
 jsr RemIntServer(a6)
NoAudio
 endc * WantSampledSound
 rts

;----

; A1 is pointer to data storage.
; Used only with d0,d1,a1,a5,a6

StartKbd
 move.l d0,a5 * next interrupt
 move.l 4(a5),a1 * interrupt after a1
 move.l a1,KbdNextInterrupt * save for benefit of closedown routine

 move.b akey,d0

 ifne ReleaseGame
* only prevent OS getting keypress if we know this to be a
* released game.
  move.w #75,d1 * wait for at least 75 microseconds
SK1
  move.b #0,akey * acknowledge receipt
  dbra d1,SK1
 endc

 not d0
 ror.b #1,d0
* d0.b is key code. do anything you want, 
* then rts to exit.
; Amiga keyboard table is on P.239 Hardware manual.

; convert to ST-style keycode and extract ascii if key was pressed
 movem.l d1-d4/a0,-(sp)
  move.w d0,d1
  and.w #$007f,d1 * trim off top bit (which gives up/down transition)
  lea AmigaToSTTable,a0
  add.w d1,d1
  clr.w d2
  move.b (a0,d1),d2 * ST-style key code
  clr.w d3
  btst #7,d0 * did the key go down, or up?
  bne.s KeyUp * >$80 -> an up transition
  move.b 1(a0,d1),d3 * ascii code.
KeyUp
* d2.w is ST-style key code, d3.b is ascii code (0 if none)
* d0.8 is up/down
  move.b d0,d1 * restore d1 as offset into byte-wise table
  lea MikeMatrix,a0
  and.b #$80,d0 * now $80 means up, $0 means down
  eor.b #$80,d0 * now $0 means up, $80 means pressed
  move.b d0,(a0,d2) * write into keytable

 tst.b d0 * was it pressed, or released
 bpl.s NoKey * released - so don't put into keyboard buffer
* do keyboard buffering on d3.b, keycode d2.b
 tst.b d2
 beq.s NoKey
 move.w KBDFreeSpacePtr,d1
 move.w KBDCharsInBuffer,d0 * first we've used
 cmp.w #32,d0
 bcc.s DiscardKey * can't store any more, so discard it.
 lea KBDBuffer,a0
 move.b d3,(a0,d1) * store ascii code of keystroke
 move.b d2,1(a0,d1) * store keycode as well
 add.w #2,d1 * two bytes per entry in circular buffer
 and.w #63,d1 * 64 byte circular buffer: 32chars.
 move.w d1,KBDFreeSpacePtr
 add.w #1,d0
 move.w d0,KBDCharsInBuffer
DiscardKey
; movem.l (sp)+,d1-d4/a0
; moveq.l #-1,d0 * prevent anything else getting keystrokes
; rts

NoKey
 movem.l (sp)+,d1-d4/a0
 clr.l d0 * allow other things to get interrupts
 rts


AmigaToSTTable
* table giving each amiga key code in order,
* with ST equivalent, and ASCII equivalent.
 dc.b 0,0	* 00: `~
 dc.b 2,49	* 01: 1!
 dc.b 3,50	* 02: 2@
 dc.b 4,51	* 03: 3#
 dc.b 5,52	* 04: 4$
 dc.b 6,53	* 05: 5%
 dc.b 7,54	* 06: 6^
 dc.b 8,55	* 07: 7&
 dc.b 9,56	* 08: 8*
 dc.b 10,57	* 09: 9(
 dc.b 11,48	* 0a: 0)
 dc.b 12,45 * 0b: -_
 dc.b 13,61 * 0c: =+
 dc.b 41,96	* 0d: \|
 dc.b 0,0	* 0e
 dc.b 112,48 * 0f: keypad 0
 dc.b 16,81	* 10: qQ
 dc.b 17,87	* 11: wW
 dc.b 18,69	* 12: eE
 dc.b 19,82	* 13: rR
 dc.b 20,84	* 14: tT
 dc.b 21,89	* 15: yY
 dc.b 22,85	* 16: uU
 dc.b 23,73	* 17: iI
 dc.b 24,79	* 18:oO
 dc.b 25,80	* 19: pP
 dc.b 26,91	* 1a: [{
 dc.b 27,93	* 1b: ]}
 dc.b 0,0	* 1c:
 dc.b 109,49 * 1d: keypad 1
 dc.b 110,50 * 1e: keypad 2
 dc.b 111,51 * 1f: keypad 3
 dc.b 30,65	* 20: a
 dc.b 31,83	* 21:s
 dc.b 32,68	* 22:d
 dc.b 33,70	* 23:f
 dc.b 34,71	* 24:g
 dc.b 35,72	* 25:h
 dc.b 36,74	* 26:j
 dc.b 37,75	* 27:k
 dc.b 38,76	* 28:l
 dc.b 39,59	* 29: ;:
 dc.b 40,39	* 2a: '"
 dc.b 0,0	* 2b
 dc.b 0,0	* 2c
 dc.b 106,52 * 2d: keypad 4
 dc.b 107,53 * 2e: keypad 5
 dc.b 108,54 * 2f: keypad 6
 dc.b 0,0	* 30:
 dc.b 44,90	* 31: z
 dc.b 45,88	* 32: x
 dc.b 46,67	* 33: c
 dc.b 47,86	* 34: v
 dc.b 48,66	* 35: b
 dc.b 49,78	* 36: n
 dc.b 50,77	* 37: m
 dc.b 51,44	* 38: ,<
 dc.b 52,46	* 39: .>
 dc.b 53,47	* 3a: /?
 dc.b 0,0	* 3b:
 dc.b 0,0	* 3c
 dc.b 103,55	* 3d: keypad 7
 dc.b 104,56 * 3e: keypad 8
 dc.b 105,57 * 3f: keypad 9
 dc.b 57,32	* 40: space bar
 dc.b 14,8	* 41: BS
 dc.b 0,0	* 42
 dc.b 114,13 * 43 keypad enter
 dc.b 28,13 	* 44 return key
 dc.b 1,27	* 45: ESC
 dc.b 0,0	* 46
 dc.b 0,0	* 47
 dc.b 0,0	* 48
 dc.b 0,0	* 49
 dc.b 113,46 * 4a: keypad .
 dc.b 0,0	* 4b
 dc.b 72,0	* 4c: cursor up
 dc.b 80,0	* 4d: cursor down
 dc.b 77,0	* 4e: cursor right
 dc.b 75,0	* 4f: cursor left
 dc.b 0,0	* 50: f1
 dc.b 0,0	* 51: f2
 dc.b 0,0	* 52: f3
 dc.b 0,0	* 53: f4
 dc.b 0,0	* 54: f5
 dc.b 0,0	* 55: f6
 dc.b 0,0	* 56: f7
 dc.b 0,0	* 57: f8
 dc.b 0,0	* 58: f9
 dc.b 0,0	* 59: f10
 dc.b 0,0	* 5a
 dc.b 0,0	* 5b
 dc.b 0,0	* 5c
 dc.b 0,0	* 5d
 dc.b 0,0	* 5e
 dc.b 98,0	* 5f: help
 dc.b 42,0	* 60: left shift
 dc.b 54,0	* 61: right shift
 dc.b 58,0	* 62: caps lock
 dc.b 29,0	* 63: control
 dc.b 56,0	* 64: Alt
 dc.b 0,0	* 65: right alt
 dc.b 0,0	* 66: left Amiga
 dc.b 0,0	* 67: right amiga
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 * just in case

EndKbd:
 even
 dc.w 0,0,0,0 * just in case

;---------
MCOsrdch 
 movem.l a3-a6,-(sp) 
  ifne ST
   bsr AskForJoystick ; update joystick status 
  endc
  ifne Amiga
   bsr CheckJoystick ; update joystick status
  endc
  bsr AbsGetCharFromBdos 
 movem.l (sp)+,a3-a6 
 move.w d0,2(a4) 
 swap d0 ; return high value in v2: 

; cmp.b #106,d0
; bne.s AGCNoDebug ******
; dc.w $4afa
;
;AGCNoDebug ****

 move.w d0,4(a4) 
 ifne ST
  cmp.b #$74,d0 
  beq.s MouseButton 
  cmp.b #$75,d0 
  beq.s MouseButton 
 endc
 clr.l d0 * return high word of d0.l clear
 rts 
 
MouseButton 
; key codes $74/$75 are the mouse button packets (ST). 
 clr.w 2(a4) 
 clr.w 4(a4) * return no key 
 rts 
;--- 
ABSGetCharFromBDOS
; get d0.b as next key waiting from keyboard
 move.w KBDCharsInBuffer,d2 * first we've used
 beq.s NoReadKey * no keys waiting
 move.w KBDReadPtr,d1 * free space area
 lea KBDBuffer,a0
 clr.l d0
 move.b 1(a0,d1),d0
 swap d0 * get keycode in bits 16..23
 move.b (a0,d1),d0 * get ascii version of ascii code
 move.w #0,(a0,d1) * stop it being read again

 add.w #2,d1 * 2 bytes per entry
 and.w #63,d1 * 64 byte circular buffer
 move.w d1,KBDReadPtr
 sub.w #1,d2 * decrease no. of chars
 move.w d2,KBDCharsInBuffer
 rts

NoReadKey
 clr.l d0 * return 0,0
 rts
;---
ActuallySwapScreen:
; swap over acode's ptrs
; (on Amiga, only really used to set up
; which text screen to write to)
; move.l a2,-(sp)
;  move.l LogicalBase-S(a5),a2 
;  move.l PhysicalBase-S(a5),LogicalBase-S(A5) 
;  move.l PhysicalBase-S(a5),GraphicsScreenBase-S(A5) *>>Mike 19/3/ 
;  move.l a2,PhysicalBase-S(a5) 
; move.l (sp)+,a2

; now swap over machine code's pointers (the important ones,
; and used to build the copper list etc.)
 lea Physicalbp0,a0
 lea Logicalbp0,a1
 move.w #4,d1 * 5 bit planes. Minus 1 'cause we loop till -ve
ASS1
 move.l (a0),d0
 move.l (a1),(a0)+
 move.l d0,(a1)+
 dbra d1,ASS1

 add.w #1,ASSCounter
 ifne ReleaseGame
  move.w ASSCounter,d0
  and.w #$f,d0
  bne.s ASS1a
 endc
 bsr DisplayScreen * Use Os to re-setup the screen every
* now and then, in case of accidents.

ASS1a

 move.l PhysicalBP0,PhysicalBase * can't use A5 here, of course
 move.l LogicalBP0,LogicalBase
 move.l PhysicalBase,GraphicsScreenBase *>>Mike 19/3/ 
 move.b GameMode,d0 * for scrolling mode, this is right.
 bne.s ASS2 * For non-scrolling mode, we don't have
* the <one cell margin at the top of the screen
 add.l #(ConstBytesPerBSLine*16),GraphicsScreenBase

ASS2

 move.l PhysicalBP0,d0
 swap d0
 move.l CopperListBPL1PTH,a0
 move.w d0,(a0)
 swap d0
 move.l CopperListBPL1PTL,a0
 move.w d0,(a0)

 move.l PhysicalBP1,d0
 swap d0
 move.l CopperListBPL2PTH,a0
 move.w d0,(a0)
 swap d0
 move.l CopperListBPL2PTL,a0
 move.w d0,(a0)

 move.l PhysicalBP2,d0
 swap d0
 move.l CopperListBPL3PTH,a0
 move.w d0,(a0)
 swap d0
 move.l CopperListBPL3PTL,a0
 move.w d0,(a0)

 move.l PhysicalBP3,d0
 swap d0
 move.l CopperListBPL4PTH,a0
 move.w d0,(a0)
 swap d0
 move.l CopperListBPL4PTL,a0
 move.w d0,(a0)

 bsr UpdateCopperList
 movem.l d0-d7/a0-a6,-(sp)
  bsr UpdatePalette * set palette in copper list etc.
 movem.l (sp)+,d0-d7/a0-a6
 rts
;----------
DisplayScreen
* set the screen to display the screen which
* has a table of bit plane in PhysicalBP0.
* Tell the system to build a copper list for it...
 lea View,a0
 lea ViewPort,a1
 CALLGRAF MakeVPort

 lea View,A1
 CALLGRAF MrgCop

 bsr ScanCopperList
 bsr UpdateCopperList
 lea View,a1
 CALLGRAF LoadView	* turn on the copper list we;ve created.

 bsr ScanCopperList
 bsr UpdateCopperList

 lea ViewPort,a0
 CALLGRAF FreeVPortCopLists

 bsr UpdatePalette ; copy the proper palette in.
 rts
;----
ScanCopperList
* scan the copper list that the OS has created to find
* the instruction which resets the scroll position
 move.l view+4,a0
 addq.l #4,a0
 move.l (a0),a0
* now a0.l is the address of the copper list.
ScanCopperListLoop
 move.w (a0)+,d0
 bpl.s SCLNotEnd
 rts

SCLNotEnd
 cmp.w #$92,d0 * DDFSTRT (timing shift of picture start relative
* left of monitor)
 bne.s SCLNotDDFSTRT
 move.l a0,CopperListDDFSTRTAddress

SCLNotDDFSTRT
 cmp.w #$0102,d0 * BPLCON1?
 bne.s SCLNotScroll
 move.l a0,CopperListScrollAddress

SCLNotScroll
 cmp.w #$108,d0 * BPL1MOD?
 bne.s SCLNotMod1
 move.l a0,CopperListBPL1MOD

SCLNotMod1
 cmp.w #$10a,d0 * BPL2MOD?
 bne.s SCLNotMod2
 move.l a0,CopperListBPL2MOD

SCLNotMod2
 cmp.w #$e0,d0 * BPL1PTH
 bne.s SCLNotBPL1PTH
 move.l a0,CopperListBPL1PTH

SCLNotBPL1PTH
 cmp.w #$e2,d0 * BPL1PTL
 bne.s SCLNotBPL1PTL
 move.l a0,CopperListBPL1PTL

SCLNotBPL1PTL
 cmp.w #$e4,d0 * BPL2PTH
 bne.s SCLNotBPL2PTH
 move.l a0,CopperListBPL2PTH

SCLNotBPL2PTH
 cmp.w #$e6,d0 * BPL2PTL
 bne.s SCLNotBPL2PTL
 move.l a0,CopperListBPL2PTL

SCLNotBPL2PTL
 cmp.w #$e8,d0 * BPL3PTH
 bne.s SCLNotBPL3PTH
 move.l a0,CopperListBPL3PTH

SCLNotBPL3PTH
 cmp.w #$ea,d0 * BPL3PTL
 bne.s SCLNotBPL3PTL
 move.l a0,CopperListBPL3PTL

SCLNotBPL3PTL
 cmp.w #$ec,d0 * BPL4PTH
 bne.s SCLNotBPL4PTH
 move.l a0,CopperListBPL4PTH

SCLNotBPL4PTH
 cmp.w #$ee,d0 * BPL4PTL
 bne.s SCLNotBPL4PTL
 move.l a0,CopperListBPL4PTL

SCLNotBPL4PTL
; cmp.w #$180,d0 * Palette instruction
; bne.s SCLNotPalette
; move.l a0,CopperListPAL0
;
;SCLNotPalette
 addq.l #2,a0 * skip over argument of instruction
 bra ScanCopperListLoop
;-------
ChangeColourD3
* We want to change colour d3.w to palette value d4.w
* Some of the colours are reset in the copper list - so
* let's scan that first.
 move.w d3,d1
 asl.w #1,d1
 add.w #$180,d1
* d1.w is the copper instruction we're expecting

 move.l view+4,a0
 addq.l #4,a0
 move.l (a0),a0
* now a0.l is the address of the copper list.
ChangeColourLoop
 move.w (a0)+,d0
 bmi.s CCEnd
 cmp.w d1,d0
 bne.s CCNotPalette
 move.w d4,(a0)
 rts

CCNotPalette
 addq.l #2,a0 * skip over argument of instruction
 bra.s ChangeColourLoop

CCEnd
* have reached end without finding the copper entry -
* so let's just program it here.
 rts * I don't like the implications of this code any more...
; subq.l #2,a0 * backtrack to the "end of copper list" instruction
; move.l (a0),4(a0) * duplicate it
; asl.l #8,d1 * put copper list instruction in high word
; move.w d4,d1
; move.l d1,(a0)
; rts

; lea $dff000+$180,a0 * start of palette registers
; move.w d3,d0
; asl.w #1,d0
; move.w d4,0(a0,d0.w)
; rts
;---
UpdateCopperList
 move.l CopperListBPL1MOD,a0
 move.w #(BytesPerPixelLine-(BytesPerPixelLine/4)),(a0)
 move.l CopperListBPL2MOD,a0
 move.w #(BytesPerPixelLine-(BytesPerPixelLine/4)),(a0)
 move.w #$30,d1
 ifne ScrollingSystem
  move.b GameMode,d0
  bne.s UpdateCopperListScrolling
 endc
 move.w #0,ScrollXPos
 move.w #$38,d1 * Default value for DDFSTRT
;^^^ ifne ScrollingSystem
;  move.l CopperListBPL1MOD,a0
;  move.w #2,(a0)
;  move.l CopperListBPL2MOD,a0
;  move.w #2,(a0)
; endc

UpdateCopperListScrolling
 move.l CopperListDDFSTRTAddress,a0
* The default value for DDFSTRT is $38.
* To provide a margin to scroll away from at the left,
* for scrolling screens we set it to $30.
 move.w d1,(a0)

 clr.w d0
 move.w ScrollXPos,d0
 move.w d0,d1
 asl.w #4,d1 * duplicate scroll value in next nybble
 or.w d1,d0
 move.l CopperListScrollAddress,a0
 move.w d0,(a0)
; move.w d0,$dff102
 rts
;---
;ShowSprite
; lea MikeTemp,a4
; move.w #501,2(a4) * object nummber
;; move.w #128,4(a4) * x
;; move.w #64,6(a4) * z
;; move.w #64,8(a4) * h
; move.w #1,10(a4) * draw flag
; bsr make_pic0
; rts
;---
CheckJoystick
 clr.w d3 * build ST-style joystick status here:
* bit 0: 1=North
* bit 1: 2=South
* bit 2: 4=left
* bit 3: 8=right
* bit 4: 128=button
 move.w joy1dat,d1
 btst #1,d1
 beq.s NotRight
 bset #3,d3

NotRight
 btst #9,d1
 beq.s NotLeft
 bset #2,d3

NotLeft
* to get "back" switch, do 1 xor 0
 move.w d1,d0
 asr.w #1,d0
 eor d1,d0
 btst #0,d0
 beq.s NotBack
 bset #1,d3

NotBack
* to get "Forward" switch, do 9 xor 8
 move.w d1,d0
 asr.w #1,d0
 eor.w d1,d0
 btst #8,d0
 beq.s NotFore
 bset #0,d3

NotFore
* fire button?
RightButton equ 6 
FireButton equ 7 
 move.b $bfe001,d0 * CIA-A port register A
* See P. 188/195 in Amiga System Programmer's guide
 btst #7,d0 * bit 7 is joystick in port 0.
 bne.s NotFire * 0=pressed
 bset #FireButton,d3

NotFire
 btst #6,d0 * bit 6 is left mouse button.
 bne.s NotMouseFire
 bset #FireButton,d3

NotMouseFire
;* scan right mouse button:
; move.w #$0300,$bfe034 * POTGO: switch DATLY to output
; move.w $bfe016,d0 * POTGOR
; btst #10,d0
; bne.s NotRightMouse
; bset #FireButton,d3
; bset #RightButton,d3
;
;NotRightMouse
 move.b d3,JoystickStatus
 rts
;----
NoLib:
 bra GoAway

AmigaInit
* firstly open the intuition library
	lea	intname(pc),a1
	moveq	#0,d0				dont care which version
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	NoLib *goaway

	move.l	d0,_IntuitionBase		store lib pointer
* and open the graphics library
	lea	grafname(pc),a1
	moveq	#0,d0
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	NoLib * GoAway
	move.l	d0,_GfxBase

* and open a DOS library
	lea	dosname(pc),a1
	moveq	#0,d0
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	NoLib * GoAway
	move.l	d0,_DOSBase

* determine the standard output channel, for
* vital error messages
 CALLDOS Output
* d0.l is handle
 move.l d0,DOSHandle

 move.l #100000,d1 * try closing it lots of times
TryCloseWB
 movem.l d1-d7/a0-a6,-(sp)
;  CALLINT CloseWorkBench
  move.l _IntuitionBase,a6
  jsr -$4e(a6) * CloseWorkBench
 movem.l (sp)+,d1-d7/a0-a6
 tst.w d0
 beq.s ClosedWB
 sub.l #1,d1
 bne.s TryCloseWB

ClosedWB:
 bsr CalcFreeMem
 move.l d0,InitialFreeMemory ***** make it accessible by acode for debugging
 lea PoolSizeNumber,a0
 bsr FormHexLong * poke in memory amount
 lea PoolSizeText,a0
 bsr DOSText

* intialise the memory allocation stuff...
 lea AllocMemTable,a0
 lea AllocMemPtr,a1
 move.l a0,(a1)

; bsr TurnOffSprites
 bsr SetupBothScreens

; ifne PossessBlitter
;  WaitBlitter
;  CALLGRAF OwnBlitter * grab the blitter permamently!
; endc
* Also has the benefit of putting most other tasks (except for
* disk validator) to sleep

 move.l #260,d0 * space for buffer for "info"
 move.l #MEMF_CLEAR,d1
 bsr MikeAllocMem
 move.l d0,InfoBlockPtr
 beq  OutOfMemory

 rts
;-----------------

; bsr AllocateBitPlanes * allocate memory for first screen
; lea PhysicalBP0,a0
; lea LogicalBP0,a1
; lea LogicalBase,a2
; move.l (a0),(a2) * set up ptr so acode can tell which
;* pointer we're using
; move.l (a0)+,(a1)+
; move.l (a0)+,(a1)+
; move.l (a0)+,(a1)+
; move.l (a0)+,(a1)+
; move.l (a0)+,(a1)+
; 
; bsr AllocateBitPlanes * allocate memory for first screen

;CLSize equ 100 * *******10*4 * 8 words per copper list+terminator
;
;* get memory for copper lists
; move.l #2*CLSize,d0 * size of 2 copper lists
; move.l #MEMF_CHIP,d1
; bsr MikeAllocMem
; move.l d0,CopperList1
; beq goaway * couldn't get memory
; move.l d0,a0
; add.l #CLSize,d0
; move.l d0,CopperList2 * save off pointer for second copper list.
; lea LogicalBP0,a1
; bsr MakeCopperList
;
; move.l CopperList2,a0
; lea PhysicalBP0,a1
; bsr MakeCopperList

; DMA and task switching off
dmacon equ $96
color00 equ $180 * color palette register 0
bplcon0 equ $100 * bit plane control register 0.
bplcon1 equ $102 * scroll value
bplcon2 equ $104 * sprite/playfield priority
forbid equ -30-102
permit equ -30-108
diwstrt equ $08e * start of screen windows
diwstop equ $090 * end of screen windows
ddfstrt equ $092 * bit plane DMA start
ddfstop equ $094 * bit plane DMA stop
bpl1mod equ $108 * modulo value for odd bit planes
bpl2mod equ $10a * modulo value for even bit planes

; CALLEXEC forbid * jsr forbid(a6)
; lea $dff000,a5
; move.w #$01e0,dmacon(a5) * DMA off
;; copper initialisation
; move.l CopperList2,$80(a5) * i.e. cop1lc(a5) Copperlist2 is physical screen
; clr.w $88(a5) * i.e. copjmp1(a5)
;; Playfield initialisation
; move.w #0,color00(a5) * we DON'T NEED THIS
; move.w #$0f00,color00+2(a5)
; move.w #$00f0,color00+10(a4)
; move.w #$000F,color00+18(a5)
; move.w #$3081,diwstrt(a5)
; move.w #$30c1,diwstop(a5)
; move.w #$0038,ddfstrt(a5) * read one extra word
; move.w #$00d0,ddfstop(a5)
; move.w #%0100001000000000,bplcon0(a5)
;*         H#  HDCG----LLE-
;*         iP  ouoe    PAx
;*         rl  maln    ECt
;*         ea  olol    NES
;*         sn  d ro      y
;*          e     c      n
;*          s     k      c
; clr.w bplcon1(a5) * and scroll to start on 0
; clr.w bplcon2(a5) * playfield 1 or playfield 2
; move.w #0,bpl1mod(a5) * no modulo
; move.w #0,bpl2mod(a5)
;; DMA on
; move.w #$8180,dmacon(a5)
;
;* and let's do some other pratting around with dma control
;* flags whilst we're at it...
;* See P. 84 in Amiga System Programmer's for details.
; move.w #$8400,dmacon(a5) * DMACON - set blitter absolute priority
; move.w #$0020,dmacon(a5) * DMACON - disable sprite dma.
; CALLEXEC permit * jsr permit(a6) * allow task switching again.


;* Tell OS about things
; lea	grafname(pc),a1
; moveq	#0,d0
; CALLEXEC OpenLibrary
; move.l d0,a4
; move.l CopperList2,38(a4)
; move.l COpperList2,View+4
;
;
; lea S,a5
; rts
;---
;ScreenTest
; movem.l d0-d7/a0-a6,-(sp)
; move.l #0,d0
; move.l PhysicalBP0,a0
; move.l PhysicalBP1,a1
; move.l PhysicalBP2,a2
; move.l PhysicalBP3,a3
;ScreenTestLoop
; move.l d0,(a0)
; move.l d0,(a1)
; move.l d0,(a2)
; move.l d0,(a3)
; addq.l #1,d0
; move.l d0,4(a1)
; move.l d0,4(a2)
; move.l d0,4(a3)
; move.l d0,8(a2)
; move.l d0,8(a3)
; move.l d0,12(a3)
; move.l d0,16(a2)
; move.l d0,20(a1)
; move.l d0,24(a0)
; cmp.l #100000,d0
; bne.s ScreenTestLoop
; movem.l (sp)+,d0-d7/a0-a6
; rts
;;----
;
;MakeCopperList
;* at chip memory a0.l, using bit plane pointers at a1.l
; move.l #$2c01fffe,(a0)+
;; move.l #$01820fff,(a0)+ * palette registers
;; move.l #$01840f0f,(a0)+ * palette registers
;; move.l #$018600ff,(a0)+ * palette registers
;; move.l #$0188000f,(a0)+ * palette registers
;; move.l #$018a0f00,(a0)+ * palette registers
;; move.l #$018c0f0f,(a0)+ * palette registers
;; move.l #$018e0f7f,(a0)+ * palette registers
;; move.l #$019007ff,(a0)+ * palette registers
;; move.l #$01920ff7,(a0)+ * palette registers
;; move.l #$008e057a,(a0)+ * DIWSTRT
;; move.l #$01000420,(a0)+ * #$01000200,(a0)+ * BPLCON0 color=1
;; move.l #$01040024,(a0)+ * BPLCON2
;; move.l #$009040ba,(a0)+ * DIWSTOP
;; move.l #$00920038,(a0)+ * DDFSTRT
;; move.l #$009400cc,(a0)+ * DDFSTOP
;; move.l #$01020000,(a0)+ * #$01020011,(a0)+ * BPLCON1 Scroll Value
;; move.l #$01080000,(a0)+ * BPL1MOD
;
;
;
; move.w #$e0,d3 *BPL1PTH i.e. indicate a bit plane pointer
; moveq #4-1,d4 * 4 bit planes
;MakeCL
; move.l (a1)+,d1 * address of bit plane
; move.w d3,(a0)+
; swap d1 * high word first
; move.w d1,(a0)+
; addq.w #2,d3 * skip on to next command (for low part of pointer)
; move.w d3,(a0)+
; swap d1 * now low word
; move.w d1,(a0)+
; addq.w #2,d3 * skip on to command for next bit plane pointer
; dbra d4,MakeCL
; move.l #$FfdfFffe,(a0) * terminate copper list.
; rts


*---------------------

SetupBothScreens
* set up two screens: logical and physical
* Swap between them using ActuallySwapScreen
 lea View,a1
 bsr InitAScreen
 lea PhysicalBP0,a0
 lea LogicalBP0,a1
 lea LogicalBase,a2
 move.l (a0),(a2) * set up ptr so acode can tell which
* pointer we're using
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+

 
 bsr TurnOffSprites

 lea ViewPort,a0
 CALLGRAF FreeVPortCopLists
 move.l ColormapPtr,a0
 CALLGRAF FreeColorMap


 lea View,a1
 bsr InitAScreen
 lea PhysicalBP0,a0
 lea PhysicalBase,a2
 move.l (a0),(a2) * set up ptr so acode can tell which

;; On_Display
; bsr LoadTitleScreen

; lea MikeBuffer,a0
; move.l bp0,a1
; move.w #1999,d0
;ML1
; move.l (a0)+,(a1)+
; dbra d0,ML1
; bsr DisplayTitleScreen

; bsr InitEventHandlers
;
; dc.w $4afa
; move.l d0,-(sp)
;  bsr ScanKeys
; move.l (sp)+,d0

; now disable the requestors. To do this, we find
; our task control block using FindTask, and set pr_windowPtr
; to -1, which asks DOS (very nicely) to return error
; codes instead of putting up stupid requestors on
; the wrong screen!
 move.l #0,a1 * find THIS task
 CALLEXEC FindTask
; d0.l is ptr to the task control block.
 move.l d0,a0
 move.l #-1,pr_WindowPtr(a0)
 move.l d0,a1
 move.b #0,d0 * set ourselves to be very high priority
* 18 is too high (stops disk validator).
 CALLEXEC SetTaskPri

 bsr ActuallySwapScreen

 lea S,a5
 rts
;----------
MCSetPalette
; v1=list number, v2=offset within list.
; Palette is in Neochrome format
 movem.l a3-a6,-(sp)
  move.w 2(a4),d0 ; V1 
  asl.w #2,d0 
  lea List0Ptr-S(a5),a0 
  ext.l d0 
  add.l d0,a0 
; (a0).l is ptr to list. 
  move.l (a0),a0
  clr.l d0
  move.w 4(a4),d0
  add.l d0,a0
; copy palette (a0) to (MyColorTable)
  lea MyColorTable,a1
  move.w #16-1,d2
MCSP1
  move.w (a0)+,d1
  move.w d2,-(sp)
   bsr TranslateColourD1 * multiply by 2 because amiga colours are
  move.w (sp)+,d2
  move.w d1,(a1)+
  dbra d2,MCSP1
  bsr UpdatePalette
 movem.l (sp)+,a3-a6
 clr.l d0 * return high word of d0.l clear
 rts
;--------
UpdatePalette
* tell the hardware about the palette we're now using
 lea MyColorTable,a0 * color table in acode format: i.e. ST/PC format.
 move.w #16-1,d0
 move.w #0,d3 * colour number we're programming
CPL1
  move.w (a0)+,d4 * amiga format palette value
  movem.l d0-d7/a0-a6,-(sp)
   bsr ChangeColourD3
  movem.l (sp)+,d0-d7/a0-a6
  add.w #1,d3 * next colour to program
  dbra d0,CPL1
 rts
;---------
TranslateColourD1
* translate colour d1.w from ST format to an amiga colour.
* We need to increase the brightness of each colour
* by a factor of slightly more than 2.
* Uses a2,d0 as workspace
 move.w d1,d2 * work version of original color
 clr.w d1 * color we're assembling
 lea ColourTranslateTable,a2
 rol.w #4,d2 * do R value first
 move.w d2,d0
 and.w #$0007,d0
 or.b 0(a2,d0.w),d1 * merge it back in

 rol.w #4,d2 * now G value
 rol.w #4,d1
 move.w d2,d0
 and.w #$0007,d0
 or.b 0(a2,d0.w),d1 * merge it back in

 rol.w #4,d2 * now B value
 rol.w #4,d1
 move.w d2,d0
 and.w #$0007,d0
 or.b 0(a2,d0.w),d1 * merge it back in

 rts
;------------
ColourTranslateTable
* for each ST intensity nybble, gives the corresponding
* value for the amiga.
 dc.b 0,2,4,6,8,10,12,14
 even
;---
TurnOffSprites
 move.l #128,d0 * ask for 128 bytes of chip memory
* for MY sprite data areas
 move.l #MEMF_CHIP,d1
 bsr MikeAllocMem
 move.l d0,MikeSpriteData
 beq TOSError
 move.l d0,$dff120
 move.l d0,$dff124
 move.l d0,$dff128
 move.l d0,$dff12c
 move.l d0,$dff130
 move.l d0,$dff134
 move.l d0,$dff138
 move.l d0,$dff13c
TOSError
 rts
MikeSpriteData ds.l 1 *&&&&******
;---
InitAScreen
; init screen refered to as View a1
; lea View,a1
 move.l a1,-(sp)
  CALLGRAF InitView
  lea ViewPort,a0
  CALLGRAF InitVPort
  lea ViewPort,a0
 move.l (sp)+,a1 * lea View,a1
 move.l a0,(a1) * link view into view port
 move.l a1,-(sp)
  lea RasInfo,a0
  lea RasInfoPtr,a1
  move.l a0,(a1)
  lea BitMapPtr,a0 * within RasInfo
  lea BitMap,a1
  move.l a1,(a0) * set up ptr from RasInfo to BitMap

  lea vpwidth,a0
  move.w #320,(a0)
  lea vpheight,a0
  move.w #200,(a0)

* appears to affect how many color commands
* are compiled into copper list (and not much else)...
 ifne Colors32
  move.w #5,d0 * depth * changed from 4 2/12/89
 endc
 ifeq Colors32
  move.w #4,d0 * depth * changed from 4 2/12/89
 endc
  move.w #320,d1 * width
  move.w #200,d2 * height
  lea BitMap,a0
  CALLGRAF InitBitMap

* set up pointers to bit planes...
  bsr AllocateBitPlanes

; set up color table...
 ifne Colors32
  move.l #32,d0 *no. of colors
 endc
 ifeq Colors32
  move.l #16,d0 *no. of colors
 endc
  CALLGRAF GetColorMap
* returns d0.l=address of colormap structure
  move.l d0,ColorMapPtr

  lea MyColorTable,a1 * d0,a1
  lea ViewPort,a0
 ifne Colors32
  move.w #32,d0 *no. of colors to change
 endc
 ifeq Colors32
  move.w #16,d0 * no. of colors to change
 endc
  CALLGRAF LoadRGB4

 move.l (sp),a0 * lea View,a0
  lea ViewPort,a1
  CALLGRAF MakeVPort
 move.l (sp),a1 * lea View,A1
  CALLGRAF MrgCop
 move.l (sp)+,a1 * lea View,a1
  CALLGRAF LoadView	* turn on the copper list we;ve created.
 bsr ScanCopperList
 rts
;---
AllocateBitPlanes
 movem.l d0-d7/a1-a6,-(sp)
  move.l a0,-(sp)
   move.w DisplayedXCells,d0
   mulu #2*200*4,d0 *  move.l #40*200,d0
 ifeq ReleaseGame ************ for shifting BS screen about for debugging
 add.l #4000,d0 ******************************* 
 endc *********
   move.l #MEMF_CHIP,d1
   bsr MikeAllocMem
  move.l (sp)+,a0
  move.l d0,(a0)+ * area allocated
  beq.s ABPError

;  move.w DisplayedXCells,d1
;  mulu #2*200,d1
  move.l d0,BMPtrs
  add.l #(BytesPerPixelLine/4),d0 * 4 bit-planes
  move.l d0,BMPtrs+4
  add.l #(BytesPerPixelLine/4),d0 * 4 bit-planes
  move.l d0,BMPtrs+8
  add.l #(BytesPerPixelLine/4),d0 * 4 bit-planes
  move.l d0,BMPtrs+12
 movem.l (sp)+,d0-d7/a1-a6
 rts



 lea BMPtrs,a0
 bsr AllocateABitPlane
 beq.s ABPError
 bsr AllocateABitPlane
 beq.s ABPError
 bsr AllocateABitPlane
 beq.s ABPError
 bsr AllocateABitPlane
 beq.s ABPError
 ifne Colors32
  bsr AllocateABitPlane
  beq.s ABPError
 endc
ABPRet
 rts

ABPError
 bra closedown *  rts
;---
AllocateABitPlane
 movem.l d0-d7/a1-a6,-(sp)
  move.l a0,-(sp)
   move.w DisplayedXCells,d0
   mulu #2*200,d0 *  move.l #40*200,d0
   move.l #MEMF_CHIP,d1
   bsr MikeAllocMem
  move.l (sp)+,a0
  move.l d0,(a0)+ * area allocated
  beq.s ABPError
 movem.l (sp)+,d0-d7/a1-a6
 rts



; move.l a0,-(sp)
;  move.l #320,d0 * width
;  move.l #200,d1 * height
;  CALLGRAF AllocRaster
; move.l (sp)+,a0
; move.l d0,(a0)+ * area allocated
; beq.s ABPError
;
;* clear the area
; move.l d0,a1
; move.w #(320*200/16)-1,d1
;AABP1
; clr.w (a1)+
; dbra d1,AABP1
; tst.w d0 * set up success flag
; rts


;  move.l #BPSize,d0 * want an 8000 byte block
;  move.l #MEMF_CHIP,d1
;  bsr MikeAllocMem * allocate, and remember what we;ve allocated for
;* benefit of the MikeFreeMem routine to deallocate everything
;* gives d0.l=area of memory allocated
; move.l d0,(a0)+
; rts
;----
MikeAllocMem
* allocate area of memory of size d0.l, type d1.l
* likely types are: (also see include/exec/memory.i)
* MEMF_PUBLIC  for stuff to be usable by several tasks
* MEMF_CHIP    for stuff to be used by custom chips
* MEMF_FAST    for the fastest memory available, ==chip memory on small machines.
* MEMF_CLEAR

* return d0.l as area of memory allocated.
* Also keep track of what areas we allocate, so
* MikeFreeMem can deallocate it all...
* PRESERVES ALL REGISTERS except d0.l(result)
 movem.l d1-d7/a0-a6,-(sp) * inefficient, but who gives a &!&!&
  move.l AllocMemPtr,a0
  cmp.l #AllocMemTableEnd,a0
  bcc MAMFFail * out of table space to record entries.
  move.l d0,(a0) * record size to allocate
  move.l d0,-(sp)
  or.l #MEMF_CLEAR,d1 * always clear memory we allocate
  CALLEXEC AllocMem * do all the allocation stuff
  tst.l d0
  beq.s MikeAllocMemFail
  addq.l #4,sp * skip d0.l on stack
  bsr MikeRecordAllocation
 movem.l (sp)+,d1-d7/a0-a6
 rts

MikeRecordAllocation
 move.l AllocMemPtr,a0
 addq.l #4,a0 * skip over length we;ve already written in.
 move.l d0,(a0)+ * write in the start address to our table
 move.l a0,AllocMemPtr * update pointer.
 rts

MikeAllocMemFail
; couldn't allocate memory. Can we try a different type?
 move.l (sp)+,d0
 movem.l (sp)+,d1-d7/a0-a6
 cmp.l #MEMF_FAST,d1 * !=OR
 bne.s MAMFFail
 move.w #MEMF_CHIP,d1
 bra.s MikeAllocMem

MAMFFail
 lea METNumber,a0
 bsr FormHexLong * poke in size of memory we asked for
 lea MemoryErrorText,a0
 bsr DOSText * dc.w $4afa
 bra CloseDown * restore stack, quit

MemoryErrorText
 dc.b "Not enough memory:    "
METNumber
 ds.b 8 * space for hex long.
 dc.b 10,0
 even
;----
FormHexLong
* form a hex long (ascii) at a0.l, with value d0.l
 move.l a0,-(sp)
  swap d0 * do high nybble first
  bsr FormHexWord
  swap d0 * now low nybble
  add.l #4,a0
  bsr FormHexWord
 move.l (sp)+,a0
 rts

FormHexWord
 move.l a0,-(sp)
 move.l d0,-(sp)
  bsr FormHexNybble * lowest nybble
  subq.l #1,a0
  lsr.l #4,d0
  bsr FormHexNybble * nybble
  subq.l #1,a0
  lsr.l #4,d0
  bsr FormHexNybble * nybble
  subq.l #1,a0
  lsr.l #4,d0
  bsr FormHexNybble * highest nybble
  subq.l #1,a0
  lsr.l #4,d0
 move.l (sp)+,d0
 move.l (sp)+,a0
 rts

FormHexNybble
 move.l a0,-(sp)
 move.w d0,-(sp)
  and.b #$0f,d0
  add.b #'0',d0
  cmp.b #'9'+1,d0
  bcs.s FHN1
  add.b #'a'-'0'-10,d0

FHN1
 move.b d0,(a0)
 move.w (sp)+,d0
 move.l (sp)+,a0
 rts
;---
MikeFreeMem
 bsr CloseDownVBL
 bsr CloseDownKbd
 bsr CloseDownAudio

; free the memory already allocated by MikeAllocMem
 lea AllocMemTable,a3
 move.l AllocMemPtr,a4 * first free site
MFMLoop
 cmp.l a4,a3
 beq.s MFMRet * reached end
 move.l (a3)+,d0 * size of memory to free, in bytes
 move.l (a3)+,a1 * address to deallocate
 movem.l a3-a4,-(sp)
  CALLEXEC FreeMem
 movem.l (sp)+,a3-a4
 bra.s MFMLoop
MFMRet
 rts
;---

;FreeBitPlanes
; move.l #BPSize,d0 * size of memory to free, in bytes
; movem.l d0/a0,-(sp)
;  CALLEXEC FreeMem
; movem.l (sp)+,d0/a0
; dbra d0,FBP1
; rts
;---
DOSText
* write text string at a0 to standard text output
; determine length of string...
 clr.l d3
 move.l a0,d2 * put buffer address into parameter for call
DOSText1
 move.b (a0)+,d0
 beq.s DOSText2
 addq.l #1,d3
 bra.s DOSText1

DOSText2
 move.l DOSHandle,d1
 CALLDOS Write
 rts

;----
LoadTitleScreen
 move.l #InitScreenFilename,d1
 move.l #MODE_OLDFILE,d2 * access mode - read existing file. 1006. is create new
 CALLDOS Open
* d0 is file handle
 tst.w d0
 beq.s OpenError
 move.l d0,d1 * copy file handle across
 move.l #MikeBuffer,d2
 move.l #MikeBufferSize,d3
 CALLDOS Read
OpenError
 rts
;---
LoadFile
;**** should pass back error flag!
 movem.l d0-d7/a0-a6,-(sp)
  move.l (a6),a0
  lea 8(a6),a1 * filename address
  move.l #1000000,d7 * max length to load
  move.l a6,-(sp)
   bsr LoadStructures
  move.l (sp)+,a6
 move.l d2,4(a6) * write end address back to driver block
 movem.l (sp)+,d0-d7/a0-a6
 rts
;---
LoadStructures
; load file with filename(a1.l) at address a0
; of max length d7.l
 movem.l a0/d7,-(sp) * load address, max bytes to load
* does file exist?
  move.l a1,d1 * address of filename
  move.l #ACCESS_READ,d2
  movem.l a0-a6,-(sp)
   CALLDOS Lock
  movem.l (sp)+,a0-a6
  tst.l d0 * does it exist?
  beq ReadPop * no -give up.
  move.l d0,d1 * value of "lock"
  movem.l a0-a6,-(sp)
   CALLDOS Unlock * I don't want the lock - just needed to know
  movem.l (sp)+,a0-a6
* that the file exists! (Open corrupts stuff if it doesn't)

  move.l a1,d1 * address of filename
  move.l #MODE_OLDFILE,d2 * access mode - read existing file. 1006. is create new
  CALLDOS Open
 movem.l (sp)+,a0/d7 * load address, max bytes to load
 bsr rdFile
 CALLDOS Close * close file with handle d1
 rts

;----
rdFileD0
* read file at (a6.l).l of max length d0.l with handle d4
* return 4(a6.l) as the end of file
* Same format parameters as ST version
 move.l (a6),a0
 move.l d0,d7
 move.l d4,d0
; fall through to rdFile
 move.l a6,-(sp)
  bsr rdFile
 move.l (sp)+,a6
 move.l d2,4(a6) * return end of file read
 rts
;---
rdFile
* d0 is file handle
* a0.l is load address
* d7.l is max bytes to read.
 tst.w d0
 beq OpenError
 move.l d0,d1 * copy file handle across
 move.l a0,d2 * load address
 move.l d7,d3 * max bytes to load
* read in max 32K chunks (because asking for 64K results in
* the system doing VERY odd things)
 bra ReadLoop * bsr, rts
;--------

;---
ReadLoop
* come here from vm system, as well.
* Return d2.l as end of memory loaded
 movem.l d1-d4/a5,-(sp)
  cmp.l #$8000,d3
  bcs.s ReadOk2
  move.l #$8000,d3 * limit amount to read to 32K
ReadOk2
  CALLDOS Read
 movem.l (sp)+,d1-d4/a5
* the system read d0.l bytes
 tst.l d0
 beq.s ReadFinished
 add.l d0,d2 * increase load address by amount loaded.
 sub.l d0,d3 * reduce amount still to read
 bpl.s ReadLoop

ReadFinished
 rts

ReadPop
 movem.l (sp)+,a0/d7 * load address, max bytes to load
 rts
;----
SaveFile
; save file with filename(a1.l) at address a0.l
; of length d7.l
 movem.l a0/d7,-(sp) * load address, max bytes to load
 move.l a1,d1 * address of filename
 move.l #1006,d2 * access mode - read existing file. 1006. is create new
 CALLDOS Open
 movem.l (sp)+,a0/d7
* d0 is file handle
 tst.w d0
 beq OpenError
 move.l d0,d1 * copy file handle across
 move.l a0,d2 * save address
 move.l d7,d3 * bytes to write
 move.l d1,-(sp)
  CALLDOS Write
 move.l (sp)+,d1
 CALLDOS Close * close file with handle d1
 rts


;----
SetupEnvelopeD4
* set up the envelope parameters for a note starting on
* Channel D4.w
 move.l a0,-(sp)
  lea Channel0ASDR,a0
  tst.w d4
  beq.s SUED1
  lea Channel1ASDR,a0
  cmp.w #1,d4
  beq.s SUED1
  lea Channel2ASDR,a0
  cmp.w #2,d4
  beq.s SUED1
  lea Channel3ASDR,a0
  cmp.w #3,d4
  bne SUED2
SUED1
  move.l #0,TimeSinceNoteStarted(a0) * also does CurrentVolume(a0).w
  move.w #0,TimeBeforeAttack(a0) * time before start attack
  move.w #64,AttackRate(a0)
  move.w #64,AttackTarget(a0)
  move.w #30,TimeBeforeDecay(a0)
  move.w #-2,DecayRate(a0)
  move.w #0,DecayTarget(a0)
SUED2
  move.l (sp)+,a0
 rts
;----
Channel0ASDR
TimeSinceNoteStarted equ 0 * ** time since note started
 dc.w 0
CurrentVolume equ 2 * ** Current Volume
 dc.w 0
TimeBeforeAttack equ 4 * 4 ** Time before start attack
 dc.w 0
AttackRate equ 6 * 6 ** volume increment each vbl in attack phase
 dc.w 0
AttackTarget equ 8 * 8 ** Target volume for attack
 dc.w 0
TimeBeforeDecay equ 10 * 10 ** Time before start decay
 dc.w 0
DecayRate equ 12 * 12 ** volume decrement each vbl in decay phase
 dc.w 0
DecayTarget equ 14 * 14 ** Target volume for decay
 dc.w 0

Channel1ASDR
 dc.w 0,0,0,0,0,0,0,0

Channel2ASDR
 dc.w 0,0,0,0,0,0,0,0

Channel3ASDR
 dc.w 0,0,0,0,0,0,0,0

SoundEnvelopeHandler
; called every 50th of a second - 
; adjust the volume to process the ASD(R) parameters.
* Channel0ASDR data block is of the format:
; movem.l d0-d1/a0/a5,-(sp)
 movem.l d0-d7/a0-a6,-(sp)
 lea Channel0ASDR,a0
 lea $dff000,a5 * hardware register base for channel 0
 bsr SEH
 lea Channel1ASDR,a0
 lea $dff010,a5 * hardware register base for channel 0
 bsr SEH
 lea Channel2ASDR,a0
 lea $dff020,a5 * hardware register base for channel 0
 bsr SEH
 lea Channel3ASDR,a0
 lea $dff030,a5 * hardware register base for channel 0
 bsr SEH
; movem.l (sp)+,d0-d1/a0/a5
 movem.l (sp)+,d0-d7/a0-a6
 rts
;-------
SEH
* change volume according to data block (a0)
* by programming the hardware registers, which for this
* channel start at a5.l
 addq.w #1,(a0) * increase time since note start.
 move.w TimeSinceNoteStarted(a0),d0
 move.w CurrentVolume(a0),d1
 cmp.w TimeBeforeAttack(a0),d0 * into attack stage?
 blt.s SEHRet
 cmp.w TimeBeforeDecay(a0),d0 * into decay stage?
 bcc.s SEHNotAttack
* attack phase
 cmp.w AttackTarget(a0),d1 * target volume>=current volume?
 bcc.s SEHAttack1
 move.w AttackRate(a0),d0 * rate at which we alter volume
 add.w d0,d1 * add on increment
 cmp.w AttackTarget(a0),d1
 blt.s SEHAttack1
 move.w AttackTarget(a0),d1 * limit volume

SEHAttack1
 move.w d1,CurrentVolume(a0) * current volume
 move.w d1,aud0vol(a5) * program hardware volume
SEHRet
 rts

SEHNotAttack
* decay stage - no sustain or release with Amiga instruments
 cmp.w DecayTarget(a0),d1 * target volume<=current volume?
 ble.s SEHDecay1
 move.w DecayRate(a0),d0 * rate at which we alter volume
 add.w d0,d1 * add on increment
 cmp.w DecayTarget(a0),d1
 bge.s SEHDecay1
 move.w DecayTarget(a0),d1 * limit volume

SEHDecay1
 move.w d1,CurrentVolume(a0) * current volume
 move.w d1,aud0vol(a5) * program hardware volume
 rts



;-----
intena equ $9a * interrupt enable register
;dmacon equ $96 * DMA control register
; audio register
aud01c equ $a0 * address of audio data list
aud0len equ $a4 * length of audio data list
aud0per equ $a6 * sampling period
aud0vol equ $a8 * volume
adkcon equ $9e * control register for modulation

SetUpSound
* From P.186 Amiga System Programmers
 move.l #(ALEnd-ALStart),d0 * size to grab
 move.l #MEMF_CHIP,d1
 bsr MikeAllocMem
* d0.l is area allocated
 move.l d0,a0
 beq SUSRet
 move.l #ALStart,a1
 move #ALEnd-AlStart-1,d1
CopySoundLoop
 move.b (a1)+,(a0)+
 dbra d1,CopySoundLoop
 move.w #716,d2

SetUpSoundd0Chan0
* Play the sound in chip memory at d0.l
* which is of length d1.w words
* with aud0per set to d2.w
* initialise audio registers
 lea $dff000,a5
 move.w #$0001,d4 * dmacon value
 move.w #$8080,d5 * INTENA value
 bra.s SUSC1

SetUpSoundd0Chan1
 lea $dff010,a5
 move.w #$0002,d4 * dmacon value
 move.w #$8100,d5 * INTENA value
 bra.s SUSC1

SetUpSoundd0Chan2
 lea $dff020,a5
 move.w #$0004,d4 * dmacon value
 move.w #$8200,d5 * INTENA value
 bra.s SUSC1

SetUpSoundD0ChanD4
* channel d4.w
 bsr SetUpEnvelopeD4
 cmp.w #4,d4
 bcs.s SUSDRangeCheck
 dc.w $4afa
 rts

SUSDRangeCheck
 move.w d4,d5
* multiply by $10
 asl.w #4,d5
 ext.l d5
 lea $dff000,a5
 add.l d5,a5
 move.w #$1,d5
 asl.w d4,d5
 move.w d5,-(sp)
 move.w #$0080,d5
 asl.w d4,d5
 or.w #$8000,d5 * Intena value
 move.w (sp)+,d4 * dmacon
 bra.s SUSC1

SetUpSoundd0Chan3
 lea $dff030,a5
 move.w #$0008,d4 * dmacon value
 move.w #$8400,d5 * INTENA value

SUSC1
* play sound waveform address d0.l,
* volume d6.w
* first, turn off the audio dma for this channel...
;;********* move.w d4,dmacon+$dff000 *(a5) * audio dma off for this channel
* Now that we're sure the dma is off, change the pitch
* and start the new sound....

 move.l d0,aud01c(a5) * set address of data list
 move.w d1,aud0len(a5) * length in words
 move.w d6,aud0vol(a5) * d6=63=full volume

* Aud0Per contains the number of bus cycles between any
* pair of samples. A bus cycle is 279.365 nanoseconds.
* Therefore our 5KHz sample in ST format should be played
* at 5000/2.79365E-7 = 715.9
;; or.b #1,intena(a5) * enable interrupt at end of sound
**temporarily disabled - one of these per channel? move.w #$00ff,adkcon(a5) * disable modulation
 move.w d2,aud0per(a5) * 716 = frequency: 440Hz


* enable audio interrupt - it gets called at the start
* of each sound sample. i.e. once when we start this one,
* and again when it starts to repeat ( for each repeat if we
* let it continue)
 move.w #1,MikeCounter * number of interrupts to process
* before stopping the sound. i.e. 1=>2.
 lea $dff000,a5
 move.w #$0080,$009c(a5) * intreq=$009c, intf_aud0=$0080 * acknowledge interrupt,
* if one was waiting
;mike2/1/89 - temporarily removed. move.w d5,INTENA(a5) * enable aud0 audio interrupt see P.87 Amiga System Programmers

 or.w #$8200,d4 * flags for dmacon to set this bit, enable all dma
 move.w d4,dmacon(a5) * channell 0 on * See P.84 Amiga System Programmers
* sound should now be playing
SUSRet
 rts

ALStart
* small sample sound
 dc.b 0,49,90,117,127,117,90,49,0,-49,-90,-117,-127,-117,-90,-49
ALEnd

CloseDownSound
 lea $dff000,a5
 move.w #$000F,dmacon(a5) * channels 0-3 off
 move.l #0,Channel0Records
 move.l #0,Channel1Records
 move.l #0,Channel2Records
 move.l #0,Channel3Records
 rts
;----
MCStartSound
; play sound at listV1(v2) of length v3 samples 
 movem.l a3-a6,-(sp) 
  move.w 2(a4),d0 ; V1 
  asl.w #2,d0 
  lea List0Ptr-S(a5),a0 
  ext.l d0 
  add.l d0,a0 
; (a0).l is ptr to list. 
  move.l (a0),a0 
  move.w 4(a4),d0 
  add.l d0,a0 
* now a0.l is the address of the sound to start playing. 
  move.l a0,d0 * parameter for setupsoundd0
  move.w 6(a4),d1 * length of sound in samples. 
  asr.w #1,d1 * get length in words
  move.w #716,d2 * aud0per
  bsr SetUpSoundD0Chan0
  move.w #1,MikeCounter  * only acknowledge nth iteration of interrupt
  lea $dff000,a5
  move.w #$0080,$009c(a5) * intreq=$009c, intf_aud0=$0080 * acknowledge interrupt,
* if one was waiting
  move.w #$8080,INTENA(a5) * enable aud0 audio interrupt
 movem.l (sp)+,a3-a6 
 clr.l d0 * return high word of d0.l clear
 rts 
;------
CalcFreeMem
* returns d0 as amount of memory free
 movem.l d1-d7/a0-a6,-(sp)
  moveq	#MEMF_PUBLIC,d1
  CALLEXEC AvailMem			get the figure
 movem.l (sp)+,d1-d7/a0-a6
 rts
 
;-----
; experimental stuff...
 ifnd HUGE


; and re-initialise the screen in case the monitor
; or something has replaced it with workbench
 lea View,a1
 CALLGRAF LoadView	* turn on the copper list we;ve created.

; now display a few flickering things etc.
 move.l #$40000,d0
 move.l #100,d7
 lea MikeTemp,a4
dloop
 bsr CheckJoystick
 move.l Physicalbp0,a1 * A1.L:=FIRST bit plane
 eor.l d0,3000(a1)
 move.l Physicalbp1,a1
 move.l d0,250(a1)
 move.l Physicalbp2,a1
 move.l d0,500(a1)
 move.l Physicalbp3,a1
 move.l d0,1000(a1)
 move.l d0,0(a1,d7)

 subq.l #1,d0
 move.w joy1dat,d1
 btst #6,d1 * fire button
 beq.s dloop
 bra NormalExit

NoMemExit

NormalExit
 bra goaway



;----
DisplayTitleScreen
; copy title screen (in neo format) from MikeBuffer
; to bp0,1,2,3,4
 move.l Physicalbp0,a0
 move.l Physicalbp1,a1
 move.l Physicalbp2,a2
 move.l Physicalbp3,a3
 ifne Colors32
  move.l Physicalbp4,a4
 endc
 lea MikeBuffer+128,a5 * skip over neo info.
 move.w #BPSize/2-1,d0 * size of a bit plane/2
dts1
 move.w (a5)+,(a0)+
 move.w (a5)+,(a1)+
 move.w (a5)+,(a2)+
 move.w (a5)+,(a3)+
 ifne Colors32
  clr.w (a4)+
 endc
 dbra d0,dts1
 rts
;---
InitEventHandlers
 lea InputDeviceName,a0 * should really be in MEMF_PUBLIC.
 move.l #0,d0
 lea IORequest,a1
 move.l #0,d1
 CALLEXEC OpenDevice
; move.l #IND_ADDHANDLER,d0

; set up stuff to request system to add our input event handler
; on to the queue
 lea IORequest,a1
 lea HandlerStuff,a2
 lea MikeInputEventHandlerData,a0
 move.l a0,IS_DATA(a2) * address of data area
 lea MikeInputEventHandler,a0
 move.l a0,IS_CODE(a2) * entry point
;*** move.b #49,IS_NODE+LN_PRI(a2) * priority. Intuition is 50

 lea InputRequestBlock,a3
 move.w #IND_ADDHANDLER,IO_COMMAND(a3)
 move.l a2,IO_DATA(a3) * link in address of interruptHandlerBlock
 move.l a3,a0 * InputRequestBlock is parameter to routine

 CALLEXEC DoIO
* returns d0 as error code
 rts
;---
CloseEventHandlers
 lea IORequest,a1 * close down input device again.
 CALLEXEC CloseDevice
 rts
;----
MikeInputEventHandler
 move.l a1,-(sp)
  move.l Physicalbp1,a1
  move.l a0,(a1)+ * write parameter we got to the screen.
  addq.l #1,(a1)+
  move.l d0,(a1)+
  move.l d1,(a1)+
 move.l (sp)+,a1
 rts
;---
ScanKeys
 lea MikeMatrix,a0
* returns d0 as error code
 lea IORequest,a1
 move.w #KBD_READMATRIX,IO_COMMAND(a1)
 move.l a0,IO_DATA(a1)
 move.l a1,a0
 CALLEXEC DoIO
* returns d0 as error code
 rts

;---


 endc * End of experimental stuff.

;---
* strings here
intname	 dc.b 'intuition.library',0 *	INTNAME				name of intuition lib
grafname	GRAFNAME			name of graphics library
dosname		DOSNAME				name of dos library

windowtitle	dc.b	' ',$a9,' HiSoft 1987 ',0
thestring	dc.b	'00000000 bytes free'
thestringlen	equ	*-thestring

* variables here
_IntuitionBase	dc.l	0			for int library
_GfxBase	dc.l	0			for graphics library
_DOSBase	dc.l	0			for dos library
windowptr	dc.l	0			for window ptr
oldfreemem	dc.l	0			for freemem


InitScreenFilename dc.b "traindem.neo",0
 even

StructuresFilename dc.b "Structur.dat",0
 even

;SpritesFilename dc.b "sprites.dat",0
; even

InputDeviceName dc.b "input.device",0
 even

C1RecorderFilename dc.b "c1rec20.spl",0
 even
c2RecorderFilename dc.b "c2rec20.spl",0
 even
C3RecorderFilename dc.b "c3rec20.spl",0
 even

c1RecorderAddress dc.l 0
c2RecorderAddress dc.l 0
c3RecorderAddress dc.l 0

SoundFilename dc.b "c4rec20.spl",0 * "saxophone.ss",0 * "7thdimstr.ss",0 * 3.spl",0



 even
MidiFileStart dc.l 0
WaveformAddress dc.l 0
MidiLength dc.l 0
CurrentMidiPtr dc.l 0

MidiFilename dc.b "BACH.MID",0
 even


 even

MikeIO		ds.b	MN_SIZE
MikeIO_DEVICE	ds.l	1
MikeIO_UNIT		ds.l	1
MikeIO_COMMAND	ds.w	1
MikeIO_FLAGS	ds.b	1
MikeIO_ERROR	ds.b	1
MikeIO_SIZE		ds.w	0
MikeIO_ACTUAL	ds.l	1
MikeIO_LENGTH	ds.l	1
MikeIO_DATA		ds.l	1
MikeIO_OFFSET	ds.l	1
MikeIOSTD_SIZE	ds.w	0
MikeIOB_QUICK	equ	0
MikeIOF_QUICK	equ	1<<0


;xcord dc.w 0
;zcord dc.w 0
;hcord dc.w 0
;ypos dc.w 0
;ycell dc.w 0
;List0Ptr ds.l 32 * space for all lists
;rev_flag dc.w 0
;ClipMask dc.w 0
;;LinesPerSprite equ 16

;---
;m_load_u
; rts
;---
;ErrorHandler
; dc.w $4afa
; rts
;
;get_sect
; rts
;---
MikeVBLCounter dc.l 0 * Incremented each vbl
MikeResult dc.l 0 * time taken for timed thingy
AudioNextInterrupt ds.l 1
MikeJoystickValue ds.b 1
 even
CallsBeforePause dc.w 0

SBPtr ds.l 1

FreeMemText
	dc.b "Mem size      "
FreeMemNumber ds.l 1
	dc.b 10,10,10,10,0,0,0
 even

