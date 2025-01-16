* HUGE.S 
* 
* Hero Screen-Builder and control logic etc. 
* 
* Assemble this file! 
* 
* Copyright(C) 1987/1988/1989 M.J.Austin Started 26/11/87 
* 

* Problems....
*  InitAcode for amiga has a surplus 16K allocated.
* UpdateScreen called from osrdch for debugging


LinesPerSprite equ 16 
 
ReleaseGame equ 0 * if set to 1, certain
* things like the Amiga keyboard handler make it
* very difficult to use the monitor.
SafeMode equ 1 * set to 1 to put in protection for find object,
* getcell odd pointers, etc.
ForceDF0 equ 0 * force use of df0:

* ChipPoolOnly equ 0 * comment out for release game

* Must be 1 for a released game.
WantAdept equ 0 * set to 1 to use adept sprite priority etc.
WantMonochrome equ 0 * set to 1 to include monochrome tables etc.
ScrollingSystem equ 1 * set to 1 for scrolling system.

AmigaPoolSize equ 10 * 150K is ok for ROcket Ranger Not Used Now.
MaxPoolSize equ 150000 * grange works, just, with 80000.
FirstPoolChunk equ MaxPoolSize/2 * 256000
SmallestPoolChunk equ 6000 * 6000 is fine but wasteful. 1024 is too small
* (The disk validator seems to stop working)
WorkspaceReserved equ 160*1024 * 115*1024
* amount required by MCReserveMemory+2.5K for vars/lists
;; SizeGameData equ 30000 *75000 * for amiga only
UseFastMem equ 1 * must be 1 for a release game
UseBlitter equ 1 * set to 1 if blitter is allowed
PossessBlitter equ 0 * set to 1 to prevent other tasks
* using the blitter - must set to 1 for release game.
AmigaCellGrouping equ 0
WantSampledSound equ 1
AllowCache equ 0

* 
* Position at 11/6/88: After a long break, doing Lancelot, T+M, 
* exams etc., I've come back to Hero. The 68000 MC Acode compiler 
* is now done, and the system will be controlled from the MC section 
* of Acode -- Mike. 
 
* Position at 16/6/88: 
* Acode/MC is now pretty well integrated, with the main control 
* loop handled in Acode. I've done enough work to make 
* the game useable in Mono, though it is not yet pretty 
* enough to be demonstrated (need stippling etc.). Now need 
* to transfer the monster intelligence to ACode, write the follow 
* code, and write the menu section. 
* (Also looked at memory useage. To my surprise, the cyclic stuff 
* uses only around 30K for the standard screen. There would appear 
* to be about 540K free with my standard winchester boot, without 
* cyclic stuff. 
* Process.tos (21K big) reports 764K for the same configuration. Thus 
* Hero is using about 245K, including 32K for an extra screen. 
* Thus About 25K of PlaySpr, 21K of Mapgr and 2.5K of Map data 
* (total 49K) is expanded to around 210K of workspace. 
* (N.B. In fact, the second screen took 64K when these figures 
*  were worked out. Thus the true useage is about 178K, not 210) 
 
** Look at why VBLHandler needs a delay to kill 
* the flicker - use a video/STFM to investigate. 
 
* recent changes to hero: 
*  DAMS1 (A6),List21Ptr (7/8/88) 
 
* possible bug in MCFindSprite: (a4) used for v1 
 
* Position at 6/10/88: 
* Acode, hero totally integrated. Mouse handler in. 
* Sound code written, but not yet integrated. 
* 3D + structure handler + memory management written. 
* Hero (1) 70% written, but still no graphics 
* AA graphics doing well, I'm writing structure editor to add 
* in animation. Still need animation code, actual AA game code. 
 
*>>Mike 10/88 - list11 now points to list ptrs. 
*>>mike30/10/88 - MCCalcCurrentCharAddressw no returns list20 as physical screen equivalent. 
*>>mike9/11/88 - AcodePrintNum now steps on cursor position. 
*>>mike10/11/88 - AcodePrintNum now uses ByteInvertFlag 
*>>Mike24/11/88 - Oswrch modified to wrap around at eol. 
*>>Mike27/11/88 - Oswrch changed to call acode on getting a cr. 
*>>Mike27/11/88 - MCParseInputWord added to allow parsing/inputline separately 
*>>Mike 2/12/88 - Oswrch changed to use TextScreenBase 
 
*>>Mike 3/3/89 - closedown changed to set user mode. 
 
*>>Mike 19/3/89 - ActuallySwapScreen: move.l PhysicalBase-S(a5),GraphicsScreenBase-S(A5) *>>Mike 19/3/89 
*>>Mike 20/3/89 - pterm called directly in closedown to try 
*                 to make quit function crash less often. 
*>>Mike 23/3/89 - oswrch modified to output to different devices 
*>>Mike 24/3/89 - PrintDecimal now uses PrintChar, not Oswrch. 
*>>Mike 26/3/89 - DEFNS.S: max length to read increased from $30000 
*>>Mike 29/3/89 - way of returning to acode mode changed to 
*		 allow large acode files to work (ToMC in int.s) 
*		 and CallAcode (Hero.s) 
* Register saving added to OnceOnlyInit 
*>>Mike 29/4/89 - IMRB,IERB saved at start, restored in closedown. 
* 		- sampled sound stuff killed at closedown. 
*		- commented and modified IRQVBLHander, IRQHBLHander etc. 
*>>mike 3/5/89 - boot_prog changed to make floppy game 
*		always use hard disk code: i.e. sprites.dat file. 
*>>Mike 18/5/89 - removed init of workspace for structure buffer. 
*>>Mike 27/5/89 - TextBufferOffset now uses Long (and therefore 
* moves out of the word workspace area.) 
*>>MIke 27/5/89 - list24 now used as text buffer pointer. 
*>>Mike 27/5/89 - TextBuffer no longer included in ram.s 
*>>Mike 28/5/89 - TextBuffer now invoked on crs as well. 
*>>Mike 29/5/89 - Oswrch changed to move lea s(PC),a5 cause a5 sometimes corrupted. 
*>>Mike 31/5/89 - keyboard scan added. 
*>>Mike 16/6/89 - EndUserMemory stuff added + checking on MCReserve 


* Position at 3/7/89. ST version works fine, but needs bits
* and pieces such as scrolling and sound. The Amiga version is
* progressing well, the boxing demo works ok, but there is no
* vm which limits the size of graphics data files. Working on
* a dual drive, 1M Amiga is tricky but can be made to work ok.
* Assembly time is about 1 minute.

* Position at 18/7/89. Amiga version virtually finished. Only
* remaining faults are slight glitch in text printing (occasionally
* loses a complete character) and the mouse pointer which flickers
* on and off sometimes. Sampled sound is fine, vm good (much improved
* on ST version - I've linked the pool cells etc.). Rocket Ranger
* and Grange both work fine - with about 64K pool on a 512K machine.
* I might now add in some blitter code to make things really fast.
*
*
* Question: does Amiga version need to use its own stack?
* wouldn't the OS one do just as well, and eliminate the
* space used in RAM.S

* opt d+ 
 
* ,P+ 
HUGE
MCStart 
 bra IntermediateStart 
; include '3d_head.s' 
ST equ 1
Amiga equ 0
IncludeVector equ 0 * only possible on ST, set to 1 to include
; the vector graphics demo etc.


; ifne ST
;Trap1Macro macro
; move.w #1,Trap13Errors
; trap #1
; move.w #0,Trap13Errors
; endm
; endc
;
; ifne Amiga
;Trap1Macro macro
; trap #1
; endm
; endc


 include 'finder.s'
 ifne ST
Colors32 equ 0
  include sounds.s 
  include 'defns.s' 
 endc
 ifne Amiga
Colors32 equ 0 * set to 1 for 32 color version of game
  include Amiga.s ; was initscreen.s
 endc
	include	3d_draw.s 
	include	3d_mem.s 
	include	3d_rev.s 
	include	scroll.s
 include joystick.s
 ifne IncludeVector
  include e:\vector\4jc2.s 
 endc
 
S * all workspace references are relative to this (a5) 
 
IntermediateStart 
 lea S(PC),a5 
 bra Start 
 include 'font.s' 
 ifne ST
;  include 'stsprite.s' 
; include 'joystick.s' 
;  include 'mouse.s' 
;;  include 'stcoll.s' 
 endc
 include 'int.s' 
 include 'initiali.s' 
; ifne ST
;  include 'si.s' 
; endc
 include 'mt.s' 
 include 'data.s' 
	include huffman.s

 ifne WantAdept
  include 'adept.s'
 endc

 ifnd PreScrollMap
MCPreScrollMap
  rts
 endc
 
*               Signed  Unsigned 
* >=            BGE     BCC 
* >             BGT     BHI 
* =             BEQ     BEQ 
* <>            BNE     BNE 
* <=            BLS     BLS 
* <             BLT     BCS 
 
 
Start 
 ifne ST
; set supervisor mode 
  clr.l -(sp) 
  call_bdos _super 
  add.l #6,sp 
  lea SupervisorStack-S(a5),a0 
  move.l d0,(a0) 
* which OS are we using?
 move.l #1,d1 * code of old os
 move.l $fc2890,d0
 cmp.l #$10290002,d0
 beq.s GotOS
 move.l #2,d1 * code for new os
 move.l $fc2a42,d0
 cmp.l #$10290002,d0
 beq.s GotOS
 clr.l d1 * unknown os, don't do any keyboard scanning

GotOS
 move.l d1,STOS

* trap "Abort, Retry, Ignore" error message + subsequent
* request for a keystroke. Both of these are vectored through
* the BIOS: Trap #13, which is vectored at $000000b4
* function nummber is at 4(sp), 2 for bconin, 3 for bconout.
* For "no disk" error (most likely one), return 'A' for abort
  lea OSTrap13Vec,a0
  move.l $b4,(a0)
  lea MyTrap13,a0
  move.l a0,$b4
  move.w #0,Trap13Errors * don't trap activity unless
* requested to do so
 endc
 
 move.b #0,AcodePtrsInitialised
 ifne ST
  lea StartFile,a0 >>mike21/9/88 - was WorkSpaceStart: must = startFile ; 
  move.l a0,FreeWorkSpace-S(a5) 
 endc

 ifne Amiga
  lea AmigaSP,a0
  move.l sp,(a0)

  bsr AmigaInit
  move.l #WorkspaceReserved,d0 * ask for 128K of workspace
 move.l d0,-(sp)
   move.l #MEMF_FAST,d1
   bsr MikeAllocMem
 move.l (sp)+,d1 * memory we asked for.
  move.l d0,FreeWorkSpace-S(A5)
  beq CloseDown
  add.l d1,d0
  move.l d0,EndFreeMemory-S(A5)
  bsr SetUpKbd
  bsr SetUpAudioInterrupt * The audio interrupt turns off
* sound samples when they've finished (otherwise the hardware
* just repeats them endlessly)
 endc
 
 lea MCStart,a0 
 move.l a0,LongMCStart-S(A5) * just for fun, and debugging. 
 
 ifne ST
*>>MIke 29/4/89 ... 
* save starting values of interrupt mask, enable 
* values used by sampled sound. 
	move.b	IMRB,Old_IMRB-S(A5) 
	move.b	IERB,Old_IERB-S(A5) 
        Lea Old_Iea,a0          Save old Enable and mask registers 
        Move.b $fffa07,(a0) * iea 
        Lea Old_Ima,a0 
        Move.b $fffa13,(a0) * ima 
*>>Mike 9/6/89 
 move.l STOS,d0
 cmp.l #1,d0
 bne.s NotOldClick * not old os
 and.b #$fe,$484 * kill keyboard click. 
NotOldClick
 endc

 lea S(PC),a5
 movem.l d0-d7/a0-a6,-(sp)
  bsr LoadDirectory * load our directory structure - contains
* pathnames etc. for everything we ever need.
 movem.l (sp)+,d0-d7/a0-a6
 
 bsr LoadGamedata * must be first file loaded - at StartFile 
 move.l a0,-(sp) 

* if there is a separate acode block, load it here - so
* the variables etc. can come afterwards
  move.l #0,AcodePtr
  move.l FreeWorkSpace-S(A5),a0 
  bsr MakeA0Even 
  lea AcodeDriverBlock-S(A5),a6 
  move.l a0,(a6) 
  move.l a0,-(sp) 
   bsr LoadFile 
   move.l $4(a6),d0
   beq.s NoSeparateAcode
   lea FreeWorkSpace-S(A5),a0 
   move.l d0,(a0) 
   move.l (a6),d0
   add.l #2,d0 * skip length pointer
   move.l d0,AcodePtr

NoSeparateAcode
; bsr NewHeroOnceOnlyInit
; bsr NewHeroInit
 ifne ST * must use existing stack as base on amiga
  lea HeroStack-S(a5),sp 
 endc
 lea     initialstackpointer,a0 ;>> for acode ResetStack instruction 
 move.l  sp,(a0) 
 ifne ST
  bsr SetScreenResolution 
  bsr SetUpPalette 
 endc

  move.l FreeWorkSpace-S(A5),a0 
  bsr MakeA0Even 

; set up ptr to var table... 
  move.l a0,List0Ptr-S(A5) 
;>>Mike 18/5/89 start. 
  add.l #2048,a0 ; allow for 1000 variables. 
  move.l a0,ListAreaPtr-S(A5) 
;>>Mike 18/5/89 end. 
  move.l a0,FreeWorkSpace-S(A5) * allow plenty of space for lists. 
 move.l (sp)+,a0 * place where gamedata block loaded.
 
 move.l List0Ptr-S(A5),-(sp) 
  bsr InitGamedata 
 move.l (sp)+,List0Ptr-S(A5) 
 

 bsr NewHeroOnceOnlyInit
 bsr NewHeroInit
; ifne ST
;  bra StructureTest ***********
; endc

 move.b #1,AcodePtrsInitialised 
 move.l AcodeFns,a0 
 pea InstructionLoop 
 move.w (a0),d0
 cmp.w #$6000,d0 * bra instruction
 bne EarlyCloseDown * quit out before we do some REAL damage

CallAcode 
 move.l List0Ptr-S(A5),a4 * vartable ptr 
 lea ListTbl,a3 * ptrs to lists 
 moveq.w #0,d7 * kept zero for use in 0(a3,d7) accesses 
 lea ToMCEnd,a6 * set up vector to come back to acode. 
 clr.l d0 * ensure high word is clear.
 jmp (a0) 
 
; bsr HeroOnceOnlyInit 
; 
;ResetMonsters 
;; bsr InitSpriteTable 
; bsr HeroInit 
; 
;MainLoop 
; lea HeroStack-S(a5),sp 
; bsr AllHero 
; bra MainLoop 
;--- 
;MCFrameReady 
;; called from acode 
; movem.l a3-a5,-(sp) 
;  lea S(PC),a5 
;  move.b #1,FrameReady-S(A5) 
; movem.l (sp)+,a3-a5 
; rts 
;----- 
;AllHero 
; bsr MoveScreen 
; bsr Specials 
; 
; bsr BuildBackGround 
;; 
; Now overlay other stuff on top of the background 
; bsr DisplayDestroyedWalls 
; move.l Player1SpriteBlock-S(a5),a6 ***** 
; bsr DisplayAllSprites 
; bsr TrimEdges 
; bsr DisplayTextLine 
; bsr DisplayUpperTextLine 
; bsr DoAllTimers 
; bsr DisplayMemoryFree 
; bsr DisplayHitPoints 
; bsr DisplayFreeSprites 
; bsr DisplayFrameTime 
; 
;; bsr HandlePlayerInput 
; 
; rts 
;------- 
HeroOnceOnlyInit 
 rts

NewHeroOnceOnlyInit
 movem.l a3-a6,-(sp) 
 bsr InitHeroVariables 
 
 ifne ST
;  bsr SetScreenResolution 
;  bsr SetUpPalette 
 endc
 
 bsr LoadDataFiles * includes title page, graphics data etc. 
 
; Make List17Ptr point to 64 bytes of workspace 
; for use as a driver block 
 move.l FreeWorkSpace-S(A5),a0 
 bsr MakeA0Even 
 move.l a0,List17Ptr-S(A5) 
; and make List18Ptr point into area of workspace - 
; used as scratchpad for loading files (Purely for graphics editor) 
 move.l a0,List18Ptr-S(A5) 
 add.l #64,a0
 move.l a0,FreeWorkSpace-S(A5)
 
 ifne ST
  Bsr InitMouse ; Or InitJoystick 
* bsr InitKeyboard * functions actually done in InitMouse

;; bsr InitJoystick 
  bsr SetUpVbl 
;;  bsr InitLRTable 
 endc

 ifne Amiga
  bsr SetUpVbl
 endc
 movem.l (sp)+,a3-a6 
 rts 
;------- 
MCAddToListPtr 
; add (V2,V3).l to listv1 
 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
; (a0).l is ptr to list. 
 move.l 4(a4),d0 ; get v2,v3 
 add.l d0,(a0) 
 clr.l d0 * clear d0 before returning to acode
 rts 
;----- 
MCReserveMemory 
; reserve V1.w bytes of memory for use by acode 
 clr.l d0 
 move.w 2(A4),d0 
 move.l FreeWorkSpace-S(A5),a0 
 add.l d0,a0 
 cmp.l EndFreeMemory-S(A5),a0 
 bcs.s MCReserveMemoryOk 
 move.w #$902,d0 
 bsr ErrorHandler 
 clr.w 2(a4) * signal error explicitly as well. 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
MCReserveMemoryOk 
 add.l d0,FreeWorkSpace-S(A5) 

 clr.l d0 * clear d0 before returning to acode
 rts 
;----
MCReserveChip
; on Amiga, get type V2 of memory
; (usually v2=MEMF_CHIP=2, to request chip mem for sounds)
; Amount of memory=v1, and set up listv3 to point to it.
 ifne Amiga
 movem.l a3-a6,-(sp)
  move.w 4(a4),d1 * type of memory to grab.
  clr.l d0
  move.w 2(a4),d0 * amount to reserve
  bsr MikeAllocMem
* returns d0.l as memory address allocated.
  move.w 6(a4),d1 ; V3 
  asl.w #2,d1
  lea List0Ptr-S(a5),a0 
  ext.l d1
  add.l d1,a0 
  move.l d0,(a0) * set up list pointer
 movem.l (sp)+,a3-a6
MCRMOrdinary
 clr.l d0 * clear d0 before returning to acode
 endc
 rts
;--------------------------- 
 ifne ST
SetUpVBl 
* now set up the interrupt vector 
* it doesn't matter if interrupts occur during the 
* following bit of code .... 
* now set up MY VBL interrupt handler routine 
 
* The following code ACTUALLY sets up the HBL interrupt... 
* Uses timer B in event count mode. 
 tst.l osvblhandler 
 bne.s vblalreadysetup 
 
;>>Mike 29/4/89        Lea Old_Iea,a0          Save old Enable and mask registers 
;        Move.b $fffa07,(a0) * iea 
;        Lea Old_Ima,a0 
;        Move.b $fffa13,(a0) * ima 
 
        And.b #$fe,$fffa07  * iea (iera): Disable H-Blank Interrupt: timer B 
        Move.l $120,OSHblHandler-S(a5)  Save old Hbl Handler 
        Lea irqhblhandler,a0            Put in new routine' 
        Move.l a0,$120 
        Or.b #1,$fffa07 * iea.  Enable H-Blank int 
        Or.b #1,$fffa13	* ima.  (i.e. Timer B interrupt.) 
 
 
* and set up vbl handler... 
 move.l $70,OSVblHandler-S(A5) 
 lea irqvblhandler,a0 
 move.l a0,$70                  ; ... and enable my routine 
vblalreadysetup 
 rts 
;---- 
CloseDownVBL 
        Move.b Old_Iea,$fffa07  Set these back to starting vals 
        Move.b Old_Ima,$fffa13 
 
        move.l OSHblHandler-S(A5),d0 
        move.l d0,$120 
 
 
 move.l OSVblHandler-S(A5),d0 
 move.l d0,$70 
 
 rts 
 endc * ST specific
;----- 
IRQVblHandler 
 ifne ST
        Move.b #0,$fffa1b  * tbcr.      Stop timer B (With cntrl reg) 
        Move.b #200,$fffa21 * tbdata    Set timer B data reg with no.scan lines 
        Move.b #8,$fffa1b   * tbcr      Put timer B into Event Count Mode 
 endc
 clr.w TimeSinceVBL 
 move.w sr,-(sp) 
 move.l d0,-(sp) 
 move.w VBLDisabled(PC),d0 
 beq.s ivblok 
 move.l (sp)+,d0 
 move.w (sp)+,sr 
 bra iRQVBLEnd 
 
ivblok 
 move.l (sp)+,d0 
 move.w (sp)+,sr 
 
 ifne ST
  cmp.l #start,(sp) 
  bcs.s IRQVBLEnd *>>Mike 1/6/89 
 endc
 
 movem.l d0-d7/a0-a6,-(sp) 
 move.w CheckDiskTimer,d0
 addq.w #1,d0
 cmp.w #75,d0 * 1.5 seconds
 bcs.s IRQV1
 move.b #1,CheckDiskFlag
 move.w #0,d0
; bsr MarkDiskForChecking ; check which disk we've got in
;; (or at least mark that we wish to do so before any vm)

IRQV1
 move.w d0,CheckDiskTimer


  move.b AcodePtrsInitialised,d0
  beq.s IRQV2
  lea S(PC),a5 * call acode scheduler 
  move.l AcodeFns-S(A5),a0 
  add.l #24,a0 *  is 7th jump: i.e. an offset of (7-1)*4 
  bsr CallAcode 
IRQV2
 movem.l (sp)+,d0-d7/a0-a6 
 
iRQVBLEnd: 
 ifne ST
  Move.l OSVblHandler,-(sp)       Do OS stuff 
  rts
 endc
;
* on Amiga, just drop through to HBL handler

IRQHblHandler 
* (ST) happens 200 scan lines after IRQVBLHandler 
* because we're using Timer B event count mode. 
 * Cant use A5.L relative here, remember... 
 move.l d0,-(sp) 
 
 move.b FrameReady(PC),d0 
 beq.s IRQHblHandlerEnd 
IV1 
 movem.l a0/a5,-(sp) 
  ifne ST
  lea S(PC),a5
  endc
  bsr ActuallySwapScreen 
  lea S(PC),a5 
  clr.b FrameReady-S(A5) 
 movem.l (sp)+,a0/a5 
 
IRQHblHandlerEnd 
 move.w sr,-(sp) 
 move.l d0,-(sp) 
 move.w VBLDisabled(PC),d0 
 beq.s ihblok 
 move.l (sp)+,d0 
 move.w (sp)+,sr 
 bra iRQhBLEnd 
 
ihblok 
 move.l (sp)+,d0 
 move.w (sp)+,sr 
 
 movem.l d0-d7/a0-a6,-(sp) 
 move.w sr,-(sp) * we're in supervisor mode, so tis ok. 
 move.b AcodePtrsInitialised,d0
 beq.s IRQH2
 lea S(PC),a5 
 move.l AcodeFns-S(A5),a0 
 add.l #28,a0 *  is 8th jump: i.e. an offset of (8-1)*4 
 bsr CallAcode 
IRQH2
 move.w (sp)+,sr 
 movem.l (sp)+,d0-d7/a0-a6 
 
IRQHBLEnd 
 move.l (sp)+,d0 
 ifne ST
* finished - Hblank normally doesnt do much 
*            so no need to goto OShandler 
  Bclr #0,$fffa0f         Allow further interrupts 
  Rte 
 endc * ST
 ifne Amiga
  rts * Amiga uses OS interrupt pre-processor.
 endc
;---- 
 ifne ST
ActuallySwapScreen 
; and set up to write to alternate screen... 
 move.l a2,-(sp) 
  move.l LogicalBase-S(a5),a2 
  move.l PhysicalBase-S(a5),LogicalBase-S(A5) 
  move.l PhysicalBase-S(a5),GraphicsScreenBase-S(A5) *>>Mike 19/3/ 
 
  move.l a2,PhysicalBase-S(a5) 
 move.l (sp)+,a2 
 
 move.l PhysicalBase-S(A5),d0 
;>>mike6/1/89 add.l #8,d0 
 asr.l #8,d0 
 lea $ffff8203,a0 
 move.b d0,(a0) ; $80 for $f8000 
 asr.l #8,d0 
 lea $ffff8201,a0 
 move.b d0,(a0) ; $0f for $f8000 
  ifne IncludeVector
		move.l LogicalBase,a0
		move.l	a0,scraddr3 
		move.l a0,scraddr2 
		move.l	a0,scraddr3 
		move.l	a0,scraddr 
		lea	windowoffset(a0),a0 
		move.l	a0,windowstart 
  ; move.b #1,PageSwapped-S(A5)
  endc * IncludeVector


 endc * St specific
 rts 
 
;------ 
ErrorHandler 
* got error code d0.l from some internal routine. 
* let acode know about it, but nothing else we can do 
 movem.l d0-d7/a0-a6,-(sp) 
  move.w sr,-(sp)
  move.b AcodePtrsInitialised,d1
  beq.s EH2
  move.w d0,WordErrorNumber 
  lea S(PC),a5 
  move.l list0Ptr-S(a5),a4 * set up var table ptr (may
* be corrupted e.g. by 3d code)
  move.l AcodeFns-S(A5),a0 
  add.l #44,a0 *  is 12th jump: i.e. an offset of (12-1)*4 
  bsr CallAcode 
EH2
  move.w (sp)+,ccr 
 movem.l (sp)+,d0-d7/a0-a6 
 rts 
 
 
;------- 
HeroInit 
;; bsr InitSpriteTable 
 rts

NewHeroInit
 move.l PhysicalBase-S(a5),GraphicsScreenBase-S(A5) *>>Mike 19/3/ 

 Lea DoYRangeKill-S(a5),a0 
 clr.b (a0) 
 
;>>Mike 27/12/88 
;; lea SpriteTable-S(a5),a0 
; move.l List28Ptr-S(A5),a0 
; lea SpriteTPtr-S(a5),a1 
; move.l a0,(a1) 
 
 lea ListTbl,a3 * ptrs to lists >>mike 10/88 
 move.l a3,List11Ptr-S(A5) 
;>>MIke 27/5/89 lea TextBuffer,a0 
;>>Mike 27/5/89 move.l a0,List24Ptr-S(A5) 
;>>Mike 6/2/89 move.l MapLayoutPtr-S(A5),a0 
;>>mike 6/2/89 move.l a0,List27Ptr-S(A5) 
;>>mike 27/12/88 
;; lea SpriteTable-S(A5),a0 
; move.l SpriteDataPtr-S(A5),a0 
; move.l a0,List28Ptr-S(A5) 
 lea LongWorkspace-S(A5),a0 
 move.l a0,List29Ptr-S(A5) 
 lea WordWorkspace-S(A5),a0 
 move.l a0,List30Ptr-S(A5) 
 lea ByteWorkspace-S(A5),a0 
 move.l a0,List31Ptr-S(A5) 
 clr.l d0 * clear d0 before returning to acode
 rts 
;------- 
InitHeroVariables 
 lea RandomSeed-S(a5),a0 
 move.l #$c468d134,(a0) 
 
 lea ScrollStep-S(a5),a0 
 move.b #4,(a0) 
 
;       Cmp.b #2,ScreenResolution-S(a5) 
;       Bne ScrSKP1 
;       Move.b #8,ScrollStep-S(a5) 
 
;ScrSKP1 
 
 lea YFineScroll-S(a5),a0 
 move.l #0,(a0) 
 lea DoingPseudoFlip-S(a5),a0 
 clr.b (a0) 
 lea ScreenXPos-S(a5),a0 
 move.w #0,(a0) 
 lea ScreenYPos-S(a5),a0 
 move.w #32,(a0) 
 
 lea BreakPointArmed-S(a5),a0 
 clr.b (a0) 
 lea NumDestroyedWalls-S(a5),a0 
 clr.w (a0) 
 lea TimeToNextShot-S(a5),a0 
 clr.b (a0) 
 
 lea ScreenXMax-S(a5),a0 
 move.w #544,(a0) ; (ScreenXBlocks-16)*16 
 lea PlayerXMax-S(a5),a0 
 move.w #784,(a0) * 800,(a0) ; (ScreenXBlocks-1)*16 
 lea ScreenXBlocks-S(a5),a0 ; number of blocks e.g. 0..ScreenXBlocks-1 
 move.w #50,(a0) 
 lea ScreenYBlocks-S(A5),a0 
 move.w #50,(a0) 
 
 lea ScreenYMax-S(a5),a0 
 move.w #612,(a0) * (screenYBlocks-11.75)*16 
 lea PlayerYMax-S(a5),a0 
 move.w #784,(a0) * (ScreenYBlocks-1)*16 
 
 lea CurrentWeapon-S(a5),a0 
 clr.b (a0) 
 clr.l d0 * clear d0 before returning to acode
 
 rts 
;--- 
DoAllTimers 
* do all special case timers 
 lea TimeToNextShot-S(a5),a0 
 tst.b (a0) 
 beq.s DATRet 
 subq.b #1,(a0) 
DATRet 
 rts 
;------- 
;MCClearScreenArea 
;; called from Acode 
;; clear rectangle between x0,y0 and x1,y1. Uses self-modifying code 
; to setup the linear code to clear each line. 
; movem.l a3-a5,-(sp) 
;  bsr ClearScreenArea 
; movem.l (sp)+,a3-a5 
; rts 
; 
;ClearScreenArea 
; 
;--------- 
MCAbsChangeListPtr 
; set ListV1 to absolute address v2(hi),v3(lo) 
 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
; (a0).l is ptr to list. 
 move.l 4(a4),(a0) ; v2,v3 
 clr.l d0 * clear d0 before returning to acode
 rts 
;-------- 
;MCChangeListPtr 
;; add V2 (unusually, a 16 bit signed integer) 
;; to list ptr v1 
; move.w 2(a4),d0 ; V1 
; asl.w #2,d0 
; lea List0Ptr-S(a5),a0 
; ext.l d0 
; add.l d0,a0 
;; (a0).l is ptr to list. 
; move.w 4(a4),d0 ; v2 
; ext.l d0 ; sign-extend it 
; add.l d0,(a0) 
; rts 
;------- 
MCCopy 
; copy from ListV1(v2) to ListV3(v4) length V5 words 
 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
 move.l (a0),a1 ; source 
 clr.l d0 
 move.w 4(a4),d0 ; start offset 
 ext.l d0 ; sign-extend 
 add.l d0,a1 
 
 move.w 6(a4),d0 ; V3 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
 move.l (a0),a2 ; destination 
 clr.l d0 
 move.w 8(a4),d0 ; start offset 
 ext.l d0 ; sign-extend 
 add.l d0,a2 
 
 move.w 10(a4),d0 ; v5 
 subq.w #1,d0 ; because dbra does 1 too many. 
 
MCCopy1 
 move.w (a1)+,(a2)+ 
 dbra d0,MCCopy1 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
;------- 
MCLoadFile 
 movem.l a3-a6,-(sp) 
  move.w #1,d1 * request disk 1 if necessary
  bsr CheckForDiskChange

  bsr SetUpMCLoadSave 
  move.l (a6),-(sp) * save start address
   bsr LoadFile 
   move.l 4(a6),d0 * end address
  sub.l (sp)+,d0 * take off start address
  move.w d0,2(a4) * write length loaded to v1
 movem.l (sp)+,a3-a6 
 clr.l d0 * clear d0 before returning to acode
 rts 
;--------- 
MCSaveFile 
 movem.l a3-a6,-(sp) 
  move.w #1,d1 * request disk 1 if necessary
  bsr CheckForDiskChange
  bsr SetUpMCLoadSave 
  bsr SaveFile 
 movem.l (sp)+,a3-a6 
 clr.l d0 * clear d0 before returning to acode
 rts 
;------ 
SetUpMCLoadSave 
  lea S(PC),a5 
  move.l List17Ptr-S(A5),a6 ; control block in driver format. 
; i.e. filename at 8(a6) 
; scan for anything that can't be a valid filename
; character
 lea 8(a6),a0
SMLS1
 move.b (a0)+,d0
 cmp.b #'\',d0
 beq.s SMLS1
 cmp.b #'.',d0
 beq.s SMLS1
 cmp.b #'0',d0
 bcs.s SMLSEnd
 cmp.b #'z'+1,d0
 bcs.s SMLS1
SMLSEnd
 move.b #0,-(a0) * overwrite the terminator with a null.

; However, addresses are: ListV1(V2) and length is v5(hi),v6(lo), 
; Find Start Address: 
 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a0 
 ext.l d0 
 add.l d0,a0 
 move.l (a0),a0 
SUMLS2 
 clr.l d0 
 move.w 4(a4),d0 ; v2 
 ext.l d0 ; sign-extend 
 add.l d0,a0 
 move.l a0,(a6) 
; and length... 
 add.l 10(a4),a0 ; v5,v6 as long-word 
 move.l a0,4(a6) 
 rts 
;-------- 
Clear16 Macro 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 endm 
 
MCClearScreen 
; clear the entire logical screen 
 ifne Amiga
 movem.l a3-a6,-(sp)
  move.l LogicalBP0,a0
  move.l LogicalBP1,a1
  move.l LogicalBP2,a2
  move.l LogicalBP3,a3
  move.l LogicalBP4,a4
  move.w #(320*200/(32))-1,d0 * 32= pels per long.
MCC1
  clr.l (a0)+
  clr.l (a1)+
  clr.l (a2)+
  clr.l (a3)+
 ifne Colors32
  clr.l (a4)+
 endc
  dbra d0,MCC1
 movem.l (sp)+,a3-a6
 clr.l d0 * clear d0 before returning to acode
 rts
 endc

 movem.l a3-a5,-(sp) * save acode pointer registers 
 move.l LogicalBase(PC),a0 * A5.L not set up, so can't use relative addressing 
 move.w #200*160/64,d1 * length to clear. About 500 iterations 
 moveq.l #0,d0 * for use by clear16 macro 
ClsLoop 
 Clear16 * clear 16 bytes 
 Clear16 
 Clear16 
 Clear16 
 dbra d1,ClsLoop 
 movem.l (sp)+,a3-a5 
 clr.l d0 * clear d0 before returning to acode
 rts 
;------- 
 
MCCloseDown 
 lea S(PC),a5
CloseDown 
 ifne Amiga
EarlyCloseDown
  move.l AmigaSP,a7
  bra goAway
 endc

 ifne ST
 bsr CloseDownTrap13 * disk error handler
 bsr CloseDownVBL 
        Bsr CloseDownMouseHandler 
 
EarlyCloseDown
* close down sampled sound player 
	move.b	#0,tacr * timer stop 
 
	move.b	Old_IMRB-S(A5),IMRB 
	move.b	Old_IERB-S(A5),IERB 
	move.l PreSoundInt_vec-S(A5),int_vec 
 
 move.l SupervisorStack-S(a5),d0 
 move.l d0,sp * set supervisor stack back to os value. 
 move.w #0,sr * back to user mode. 
 
 move.b ScreenResolution-S(A5),d0 
 cmp.b #2,d0 
 beq.s CloseDownHires 
 bsr SetMedResolution 
 call_bdos p_term_old * $4c 
 call_bdos p_term *>>Mike 20/3/89 
; bsr ReturnToGem 
;----- 
CloseDownHires 
 bsr SetHighResolution 
 bra ReturnToGem 
 endc * above is ST-specific
;--- 
DisplayUpperTextLine 
 ifne Amiga
  rts
 endc

 ifne ST
; clear text area... 
 move.l LogicalBase-S(a5),a0 
; add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area 
 move.w #160*12/16-1,d1 * clear 12 pel lines. 
 move.l #0,d0 
DUTL0 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 move.l d0,(a0)+ 
 dbra d1,DUTL0 
 
; move.b #1,LineCleared-S(A5)
 clr.l d0 * clear d0 before returning to acode
 rts 
 endc
;--- 
MCScrollTextLine 
; scroll a line of text at coords v0,v1 
 ifne Amiga
  rts
 endc

 movem.l a3-a6,-(sp) 
  lea S(PC),a5 * set up ws pointer 
  bsr CalcCurrentCharAddress 
* and set up d0.w as the number of pels to shift by 
  move.w 2(a4),d0 
 
        Cmp.b #2,ScreenResolution-S(a5) 
        Bne GrSKP1 
        Lsl.w #1,d0 
 
GrSKP1 
  bsr ScrollTextLineA0D0 
 movem.l (sp)+,a3-a6 
 clr.l d0 * clear d0 before returning to acode
 rts 
;--- 
 
DisplayTextLine 
 ifne Amiga
  rts
 endc

; clear text area... 
; move.l LogicalBase-S(a5),a0 
; add.l #(199-8)*160+8,a0 * +8 to correspond with displayed area 
; move.w #160*10/16,d1 
; move.l #0,d0 
;DTL0 
; move.l d0,(a0)+ 
; move.l d0,(a0)+ 
; move.l d0,(a0)+ 
; move.l d0,(a0)+ 
; dbra d1,DTL0 
; 
;; On Alternate frames, increment text pointer 
;; On other frame, leave pointer where it is and do a 4-pel scroll 
;; on the text to make it smoother 
; lea TextSmoothScroll-S(a5),a0 
; addq.b #1,(a0) 
; move.b (a0),d0 
; and.b #3,d0 
; beq IncrementTextPtr 
; lea TextOffset-S(a5),a0 
; clr.l d0 
; move.w (a0),d0 
; bsr DTL * Display text line 
;* and scroll it. 
; move.l LogicalBase-S(a5),a0 
; add.l #(200-8)*160+8,a0 * +8 to correspond with physical screen 
; 
; move.b TextSmoothScroll-S(a5),d0 
; and.w #3,d0 
; asl.w #1,d0 
 
ScrollTextLineA0D0 
 addq.l #4,a0 * skip onto later bit plane to improve colour choice. 
* scroll first word separately 
 move.w (a0),d1 
 asl.w d0,d1 
 move.w d1,(a0) 
* (on subsequent screen lines, it is done by the last operation of the 
* previous line) 
 move.b ScreenResolution,d3 
 bne.s MonoDTL 
 
 move.w #8,d3 
DTLScroll0 
 move.l a0,-(sp) 
 move.w #19,d1 
DTLScroll 
 clr.l d2 
 move.w 8(a0),d2 
 asl.l d0,d2 
 move.w d2,8(a0) 
 swap d2 
 or.w d2,(a0) * and write high order byte to first bit plane 
 
 add.l #8,a0 
 dbra d1,DTLScroll 
 and.b #$f0,-7(a0) * blank out last nybble copied in from next line 
 move.l (sp)+,a0 
 add.l #160,a0 
 dbra d3,DTLScroll0 
 clr.l d0 * clear d0 before returning to acode
 rts 
;------- 
MonoDTL 
 move.w #15,d3 
MonoDTLScroll0 
 move.l a0,-(sp) 
 move.w #39,d1 
MonoDTLScroll 
 clr.l d2 
 move.w (a0),d2 
 asl.l d0,d2 
 move.w d2,(a0) 
 swap d2 
 or.w d2,-2(a0) * and write high order byte to first bit plane 
 addq.l #2,a0 
 
 dbra d1,MonoDTLScroll 
 and.b #$f0,(a0) * blank out last nybble copied in from next line 
 move.l (sp)+,a0 
 add.l #80,a0 
 dbra d3,MonoDTLScroll0 
 clr.l d0 * clear d0 before returning to acode
 rts 
;--- 
;IncrementTextPtr 
;; increment ptr to text message 
; lea TextOffset-S(a5),a0 
; clr.l d0 
; move.w (a0),d0 
; add.w #1,d0 
; 
;DTL 
; cmp.w #TextLength,d0 
; bls.s DTL1 
; clr.w d0 
; 
;DTL1 
; move.w d0,(a0) 
; lea TextArea-S(a5),a0 
; add.l d0,a0 
;; Copy 40 Chars from Circular buffer at TextArea to TextBuffer 
;; Are there enough chars left before end of cicular buffer? 
; move.w #TextLength,d7 ; total size of buffer 
; sub.w d0,d7 ; d0.w:=number of chars remaining 
;; Limit d7.w to 40 chars max 
; cmp.w #40,d7 
; ble.s DTL1a 
; move.w #40,d7 
;DTL1a 
;; Copy d7 chars into TextBuffer for starters 
; move.w d7,d6 * save d7 
; lea TextBuffer-S(a5),a1 
;DTL2 
; move.b (a0)+,(a1)+ 
; dbra d7,DTL2 
; 
;; Now copy 40-d6 chars into TextBuffer from the start of the string 
; lea TextArea-S(a5),a0 
; move.w #40,d7 
; sub.w d6,d7 * d6.w is number of chars already copied 
; bmi.s DTL4 * just in case it wraps round! 
;DTL3 
; move.b (a0)+,(a1)+ 
; dbra d7,DTL3 
;DTL4 
; move.l LogicalBase-S(a5),a0 
; add.l #(200-8)*160+8,a0 +8 to correspond with physical screen 
; 
; lea TextBuffer-S(a5),a1 
;; 
; move.b ScreenResolution-S(a5),d7 
; bne.s MonoDisplayTextLine 
; move.w #19,d7 
;DisplayD7CharPairs 
;; Display D7.w characters at screen address a0.l 
;; from Text string at (a1.l) 
;; calc address in font 
; clr.l d0 
; move.b (a1)+,d0 
; bsr WriteChar 
; add.l #1,a0 ; write to odd addresses 
; clr.l d0 
; move.b (a1)+,d0 
; bsr WriteChar 
; add.l #7,a0 ; next address to write to 
; dbra d7,displayD7CharPairs 
; rts 
;;--- 
;MonoDisplayTextLine 
; move.w #19,d7 
;MonoDisplayD7CharPairs 
;; Display D7.w characters at screen address a0.l 
;; from Text string at (a1.l) 
;; calc address in font 
; clr.l d0 
; move.b (a1)+,d0 
; bsr WriteChar 
; add.l #1,a0 ; write to odd addresses 
; clr.l d0 
; move.b (a1)+,d0 
; bsr WriteChar 
; add.l #1,a0 ; next address to write to 
; dbra d7,MonoDisplayD7CharPairs 
; rts 
;--- 
*------------------- 
OswrchFirstVar 
 move.w 2(a4),d0 * first variable - number 1 
 bsr Oswrch
 clr.l d0 * clear d0 before returning to acode
 rts
;--- 
Oswrch:
  move.b OutputDevice,d6 
  cmp.b #2,d6 
 bne ToPrinter * not console, so print it. 
 
 cmp.b #13,d0 
 bne.s OswrchNotCr 
OswrchCR 
  lea S(PC),a5 *>>Mike 29/5/89 
  tst.l TextBufferOffset-S(A5) *>>MIke 28/5/89 
  bne.s OswrchNotCR *>>MIke 28/5/89 - write cr to buffer 
 move.b AcodePtrsInitialised,d0
 beq.s OSWRCH2
 movem.l a3-a6,-(sp) 
  lea S(PC),a5 
  move.l AcodeFns-S(A5),a0 
  add.l #32,a0 *  is 9th jump: i.e. an offset of (9-1)*4 
  bsr CallAcode 
 movem.l (sp)+,a3-a6 
OSWRCH2
 clr.l d0 * clear d0 before returning to acode
 rts 
 
OswrchNotCr 
 move.b ByteInvertFlag(PC),d1 
 bne.s InvertedOswrch 
 movem.l d0-d7/a0-a6,-(sp) 
  lea S(PC),a5 * set up ws pointer 
  and.l #$000000ff,d0 
  move.l d0,-(sp) 
   move.l TextScreenBase-S(A5),a0 
   bsr CalcCurrentCharAddressA0 
  move.l (sp)+,d0 
  tst.l TextBufferOffset-S(A5) 
  bne.s OswrchToBuffer 
  cmp.b #32,d0 
  bcs.s OswrchNoPrint 
  bsr WriteChar 
  addq.w #8,CursorXPos-S(a5) * step on cursor position 
 
 cmp.w #320,CursorXPos-S(A5) * wrap round 
 bcs.s OswrchNoPrint 
; move.w #0,CursorXPos-S(A5) 
; add.w #8,CursorYPos-S(A5) 
 bsr OswrchCR ; tell acode we want a CR, PLEASE. 
 
OswrchNoPrint 
 movem.l (sp)+,d0-d7/a0-a6 
OswrchRet 
 rts 
;--- 
OswrchToBuffer 
; used to expand text into an output buffer 
*>>Mike 27/5/89  lea TextBuffer-S(A5),a0 
  move.l List24Ptr-S(A5),a0 *>>Mike 27/5/89 
  move.l TextBufferOffset-S(A5),d1 
  move.b d0,(a0,d1) 
  addq.l #1,TextBufferOffset-S(A5) 
 movem.l (sp)+,d0-d7/a0-a6 
 rts 
*------------------- 
InvertedOswrchFirstVar 
 move.w 2(a4),d0 * first variable - number 1 
 
InvertedOswrch 
 movem.l d0-d7/a0-a6,-(sp) 
  lea S(PC),a5 * set up ws pointer 
  and.l #$000000ff,d0 
  move.l d0,-(sp) 
   move.l TextScreenBase-S(A5),a0 
   bsr CalcCurrentCharAddressA0 
  move.l (sp)+,d0 
  cmp.b #32,d0 
  bcs.s InvertedOswrchNoPrint 
  bsr InvertedWriteChar 
InvertedOswrchNoPrint 
  addq.w #8,CursorXPos-S(a5) * step on cursor position 
 movem.l (sp)+,d0-d7/a0-a6 
 rts 
;---- 
WriteChar: 
* display char with ascii code d0 at position (a0.l) on screen 
 ifne Amiga
  WaitBlitter ;**************
 endc
 sub.b #32,d0 
 asl.w #3,d0 
 lea FontSpace-S(a5),a2 
 add.l d0,a2 

 ifne Amiga
 lea FontSpace-S(a5),a1 
 add.l d0,a1
* a0.l is offset within bit plane
 move.l a0,d0
 cmp.l #((SizeBitPlane*4)-7*BytesPerPixelLine),d0 * 4 bit-planes
 bcc TLLRet * off end of screen
 movem.l a2-a6,-(sp)

; only write to bitplane 0 for compatability with ST.
; (Also because, when writing to TextScreenBase addressed buffer,
; the buffer is only a maximum of 8K - i.e. one bit plane.)
 move.l a1,-(sp)
   move.l TextScreenBase-S(A5),a1
; A0.l is pointer to text screen.
; is Acode trying to print to logical or physical screens?
   move.l LogicalBP0,a2
   move.l LogicalBase-S(a5),a3
  bra.s GotTextPtrs ************
   cmp.l a3,a1
   beq.s GotTextPtrs
   move.l PhysicalBP0,a2
   move.l PhysicalBase-S(A5),a3
   cmp.l a3,a1
   beq.s GotTextPtrs
   move.l a1,a2 * use textscreenBase

GotTextPtrs
  move.l (sp)+,a1 * pointer to font
  add.l a0,a2 * add on offset within bit plane(s)
  move.w #8-1,d1 * height of character
TLL1
  move.b (a1)+,d0
  move.b d0,(a2)
  add.l #BytesPerPixelLine,a2
  dbra d1,TLL1
 movem.l (sp)+,a2-a6
TLLRet
 rts
 endc * Amiga


 ifne ST
 move.b ScreenResolution-S(A5),d0 
 cmp.b #2,d0 
 beq.s WriteCharMono 

; Write char to current position on screen (a0.l) 
; addq.l #4,a0 * step on to next bit plane to improve colour choice 
 
 move.b (a2)+,(a0) 
 move.b (a2)+,160(a0) 
 move.b (a2)+,320(a0) 
 move.b (a2)+,480(a0) 
 move.b (a2)+,640(a0) 
 move.b (a2)+,800(a0) 
 move.b (a2)+,960(a0) 
 move.b (a2)+,1120(a0) 
 rts 
;---- 
WriteCharMono 
; Write char to current position on screen (a0.l) 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,(a0) 
        Move.w d1,80(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,160(a0) 
        Move.w d1,240(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,320(a0) 
        Move.w d1,400(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,480(a0) 
        Move.w d1,560(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,640(a0) 
        Move.w d1,720(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,800(a0) 
        Move.w d1,880(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,960(a0) 
        Move.w d1,1040(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,1120(a0) 
        Move.w d1,1200(a0) 
 
        Rts 
 endc * ST version 
;--- 
InvertedWriteChar 
* display char with ascii code d0 at position (a0.l) on screen 
 ifne Amiga
  WaitBlitter ;**************
 endc
 sub.b #32,d0 
 asl.w #3,d0 
 lea FontSpace-S(a5),a2 
 add.l d0,a2 


 ifne Amiga
 lea FontSpace-S(a5),a1 
 add.l d0,a1
* a0.l is offset within bit plane
 move.l a0,d0
 cmp.l #((SizeBitPlane*4)-8*BytesPerPixelLine),d0 * 4 bit-planes
 bcc InvTLLRet * off end of screen
 movem.l a2-a6,-(sp)

; only write to bitplane 0 for compatability with ST.
; (Also because, when writing to TextScreenBase addressed buffer,
; the buffer is only a maximum of 8K - i.e. one bit plane.)
 move.l a1,-(sp)
   move.l TextScreenBase-S(A5),a1
; A0.l is pointer to text screen.
; is Acode trying to print to logical or physical screens?
   move.l LogicalBP0,a2
   move.l LogicalBase-S(a5),a3
 bra.s InvGotTextPtrs ************
   cmp.l a3,a1
   beq.s InvGotTextPtrs
   move.l PhysicalBP0,a2
   move.l PhysicalBase-S(A5),a3
   cmp.l a3,a1
   beq.s InvGotTextPtrs
   move.l a1,a2 * use textscreenBase

InvGotTextPtrs
  move.l (sp)+,a1 * pointer to font
  add.l a0,a2 * add on offset within bit plane(s)
  move.w #8-1,d1 * height of character
InvTLL1
  move.b (a1)+,d0
  move.b d0,(a2)
  eor.b #-1,(a2) 
  add.l #BytesPerPixelLine,a2
  dbra d1,InvTLL1
 movem.l (sp)+,a2-a6
InvTLLRet
 rts
 endc * Amiga

 ifne ST
 move.b ScreenResolution-S(A5),d0 
 cmp.b #2,d0 
 beq.s InvertedWriteCharMono 
 
; Write char to current position on screen (a0.l) 
; addq.l #4,a0 * skip to a later bit plane to improve colour useage 
 move.b (a2)+,(a0) 
 eor.b #-1,(a0) 
 move.b (a2)+,160(a0) 
 eor.b #-1,160(a0) 
 move.b (a2)+,320(a0) 
 eor.b #-1,320(a0) 
 move.b (a2)+,480(a0) 
 eor.b #-1,480(a0) 
 move.b (a2)+,640(a0) 
 eor.b #-1,640(a0) 
 move.b (a2)+,800(a0) 
 eor.b #-1,800(a0) 
 move.b (a2)+,960(a0) 
 eor.b #-1,960(a0) 
 move.b (a2)+,1120(a0) 
 eor.b #-1,1120(a0) 
 rts 
;---- 
InvertedWriteCharMono 
 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,(a0) 
        Move.w d1,80(a0) 
        Eor.w #-1,(a0) 
        Eor.w #-1,80(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,160(a0) 
        Move.w d1,240(a0) 
        Eor.w #-1,160(a0) 
        Eor.w #-1,240(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,320(a0) 
        Move.w d1,400(a0) 
        Eor.w #-1,320(a0) 
        Eor.w #-1,400(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,480(a0) 
        Move.w d1,560(a0) 
        Eor.w #-1,480(a0) 
        Eor.w #-1,560(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,640(a0) 
        Move.w d1,720(a0) 
        Eor.w #-1,640(a0) 
        Eor.w #-1,720(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,800(a0) 
        Move.w d1,880(a0) 
        Eor.w #-1,800(a0) 
        Eor.w #-1,880(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,960(a0) 
        Move.w d1,1040(a0) 
        Eor.w #-1,960(a0) 
        Eor.w #-1,1040(a0) 
 
        Move.b (a2)+,d0 
        Bsr DoubleByte 
        Move.w d1,1120(a0) 
        Move.w d1,1200(a0) 
        Eor.w #-1,1120(a0) 
        Eor.w #-1,1200(a0) 
 
        Rts 
 
DoubleByte 
 
* Written with high speed in mind * 
* (Which is why it's long, inelegant and generally tacky) * 
 
        Move.w #0,d1 
         
        Lsl.b #1,d0 
        Bcc DubB1 
        Or.w #3,d1 
DubB1   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB2 
        Or.w #3,d1 
DubB2   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB3 
        Or.w #3,d1 
DubB3   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB4 
        Or.w #3,d1 
DubB4   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB5 
        Or.w #3,d1 
DubB5   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB6 
        Or.w #3,d1 
DubB6   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB7 
        Or.w #3,d1 
DubB7   Lsl.w #2,d1 
         
        Lsl.b #1,d0 
        Bcc DubB8 
        Or.w #3,d1 
DubB8 
        Rts 
 endc * ST 
*-------- 
MCCalcCurrentCharAddress 
; return Listv1 as address on screen given by CursorXPos,CursorYPos 
; and listv2 as address on physical (currently displayed) screen 
 movem.l a3-a6,-(sp) 
 bsr CalcCurrentCharAddress 

 lea s(pc),a5 
 
 ifne Amiga
* amiga calccurrent returns a0.l relative to
* screen bases, unlike st which returns absolute address
  add.l LogicalBase-S(A5),a0
 endc

 move.w 2(a4),d0 ; V1 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a1 
 ext.l d0 
 add.l d0,a1 
; (a1).l is ptr to list. 
 move.l a0,(a1) 
 
 sub.l LogicalBase-S(A5),a0 * >>mike 30/10/88 - return physical base as well 
 add.l PhysicalBase-S(A5),a0 
 move.w 4(a4),d0 ; V2 
 asl.w #2,d0 
 lea List0Ptr-S(a5),a1 
 ext.l d0 
 add.l d0,a1 
; (a1).l is ptr to list. 
 move.l a0,(a1) 
 
 movem.l (sp)+,a3-a6 
 clr.l d0 * clear d0 before returning to acode
 rts 
;------ 
CalcCurrentCharAddress: 
* Calculate in a0.l the screen address represented by 
* CursorXPos,CursorYPos 
* All co-ordinates are presented to this routine on the basis that 
* the full screen is (x=0..319, y=0..199) with x=0,y=0 at top left 
 move.l LogicalBase-S(A5),a0 
CalcCurrentCharAddressA0 
 ifne Amiga
 CLR.L D0 
 CLR.L D1 
 move.w CursorYPos-S(A5),d1 
 MULU #BytesPerPixelLine,D1
 MOVE.W CursorXPos-S(A5),D0 
 
 lsr.w #3,d0  * /8, because 8 pels per byte (bit-planed)
;; and.w #$Fe,d0 * give word-aligned address
 add.l d1,d0
 move.l d0,a0 * return address relative to bit plane start
 rts
 
 endc * Amiga version



 ifne ST
 move.b ScreenResolution-S(A5),d0 
 beq.s CCalcCurrentCharAddress 
 
HCalcCurrentCharAddress EVEN 
* calculate the memory address of the current cursor position 
 add.l #2,a0 * allow for trimming offset 
 CLR.L D0 
 CLR.L D1 
; MOVE.W #ScreenYSize,d0 * YScreenSize(PC),D0 
; SUB.W CursorYPos(PC),D0 
 move.w CursorYPos-S(A5),d0 
* each LINE is 80 pels 
; MOVE.B YScale(PC),D1 
; BEQ.S HCalcNormalY 
; MOVE.W #160,D1 
; BRA.S HCalc2 
; 
;HCalcNormalY EVEN 
 MOVE.W #160,D1 * twice length (80), because actually have 
* 400 lines in mono, not 200 as the co-ords assume 
 
;HCalc2 EVEN 
 MULU D0,D1 
 ADD.L D1,A0 
 CLR.L D0 
; MOVE.B XScale(PC),D0 
; BEQ.S HCalcNormal 
;* Calc for wide chars 
; MOVE.W CursorXPos(PC),D0 
; LSR.W #2,D0 * 8 pixels per byte 
; ADD.L D0,A0 
; RTS 
; 
;HCalcNormal 
 MOVE.W CursorXPos-S(A5),D0 
 lsr.w #2,d0 * 8 pixels per byte (would give a shift by 3), but 
; co-ords are 0..319, not 0..639 so need to double the offset 
 ADD.L D0,A0 
 clr.l d0 * clear d0 before returning to acode
 RTS 
*--------- 
*-------- 
CCalcCurrentCharAddress EVEN 
* calculate the memory address of the current cursor position 
;>>mike6/1/89 add.l #8,a0 * allow for trimming offset 
 CLR.L D0 
 CLR.L D1 
; MOVE.W #ScreenYSize,d0 * YScreenSize(PC),D0 
; SUB.W CursorYPos(PC),D0 
 move.w CursorYPos-S(A5),d0 
;* each LINE is 160 pels 
; MOVE.B YScale(PC),D1 
; BEQ.S CCalcNormalY 
; MOVE.W #320,D1 
; BRA.S CCalc2 
; 
;CCalcNormalY EVEN 
 MOVE.W #160,D1 
CCalc2 
 MULU D0,D1 
 ADD.L D1,A0 
 CLR.L D0 
 MOVE.W CursorXPos-S(A5),D0 
* LSR.W #3,D0 * 8 pixels per byte 
*\ AND.W #$FE,D0 
*\ ASL.W #2,D0 
; MOVE.B XScale(PC),D1 
; ASL.W D1,D0 * shift by XScale 
 
 lsr.w #1,d0 
 and.w #$F8,d0 
 
 ADD.L D0,A0 
 MOVE.W CursorXPos-S(A5),D0 
; ASL.W D1,D0 * shift by XScale 
 BTST #3,D0 
 BEQ.S CDC1 
 ADDQ.L #1,A0 
 
CDC1 
 RTS 
 endc * ST
*--------- 
;--- 
AdvanceA0 
 ifne Amiga
 addq.l #1,a0
 rts
 endc

 ifne ST
 move.b ScreenResolution-S(A5),d0 
 cmp.b #2,d0 
 beq.s MonoAdvance 
 move.w a0,d0 
 btst #0,d0 
 beq.s Advance1 
 addq.l #7,a0 
 rts 
 
MonoAdvance 
Advance1 
 addq.l #1,a0 
 rts 
 endc
;--- 
;DisplayHitPoints 
; move.w #272,CursorXPos-S(A5) 
; move.w #160,CursorYPos-S(A5) 
; bsr CalcCurrentCharAddress 
;; move.b #'H',d0 
;; bsr OswrchD0 
;; move.b #'=',d0 
;; bsr OswrchD0 
;; clr.l d0 
;; lea SpriteTable-S(a5),a1 
;; move.w HitPointOffset(A1),d0 
;; bra ProperPrintDecimalD0 
; 
;; move.l LogicalBase-S(a5),a0 
;; add.l #(200-48)*160+136,a0 
;* and blank out the digits which may possibly be printed 
; move.l a0,-(sp) 
;  bsr PrintSpace 
;  bsr PrintSpace 
;  bsr PrintSpace 
;  bsr PrintSpace 
; move.l (sp)+,a0 
; 
; clr.l d0 
; lea SpriteTable-S(a5),a1 
; move.w HitPointOffset(a1),d0 
; bra PrintDecimald0 * bsr, rts 
;--- 
CalculateMemoryFree 
; move.w #272,CursorXPos-S(A5) 
; move.w #168,CursorYPos-S(A5) 
; bsr CalcCurrentCharAddress 
 
 move.l LogicalBase-S(a5),d0 
 cmp.l PhysicalBase-S(a5),d0 
 blt.s DMF1 
 move.l PhysicalBase-S(a5),d0 
DMF1 
 sub.l HiUsedMemory-S(a5),d0 
 lsr.l #8,d0 * divide by 1024 to convert to K 
 lsr.l #2,d0 
 move.w d0,2(a4) 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
;; move.l LogicalBase-S(a5),a0 
;; add.l #(200-40)*160+136,a0 
;* and blank out the digits which may possibly be printed 
; movem.l d0/a0,-(sp) 
;  bsr PrintSpace 
;  bsr PrintSpace 
;  bsr PrintSpace 
;  bsr PrintSpace 
; movem.l (sp)+,d0/a0 
; bsr PrintDecimald0 
; move.w #'K',D0 
; bra WriteChar 
;---- 
;PrintSpace 
; move.w #32,d0 
; bsr WriteChar 
; bra AdvanceA0 * bsr,rts 
;--- 
;CalculateFreeSprites 
; move.w #272,CursorXPos-S(A5) 
; move.w #176,CursorYPos-S(A5) 
; bsr CalcCurrentCharAddress 
; 
; clr.l d0 
; move.w FreeSprites-S(a5),d0 
; 
;; move.l LogicalBase-S(a5),a0 
;; add.l #(200-32)*160+136,a0 
; movem.l d0/a0,-(sp) 
;* and blank out the digits which may possibly be printed 
;  bsr PrintSpace 
;  bsr PrintSpace 
; movem.l (sp)+,d0/a0 
; 
; bra PrintDecimald0 * bsr, rts 
;--- 
MCReturnFrameTime 
 ifne Amiga
  rts
 endc

 move.l $4ba,d0 
 sub.l LastTime-S(a5),d0 
 move.w d0,2(a4) * return in V1 - first variable 
 clr.l d0 * clear d0 before returning to acode
 rts 
;--- 
MCUpdateFrameTime 
 ifne Amiga
  rts
 endc

 move.l $4ba,LastTime-S(A5) 
 clr.l d0 * clear d0 before returning to acode
 rts 
;---  
;DisplayFrameTime 
; rts 
; 
; lea LastTime-S(a5),a0 
; move.l $4ba,d0 * 200 Hz Timer 
; move.l (a0),d1 
;; move.l d0,(a0) * update last frame time 
; sub.l d1,d0 
;* d0.l is time in 5 ms increments 
; move.w d0,FrameTime-S(A5) 
; mulu #5,d0 * convert to ms 
; 
;; move.l LogicalBase-S(a5),a0 
;; add.l #(200-24)*160+136,a0 
; move.l d0,-(sp) 
;  move.w #272,CursorXPos-S(A5) 
;  move.w #184,CursorYPos-S(A5) 
;  bsr CalcCurrentCharAddress 
; move.l (sp)+,d0 
; 
; movem.l d0/a0,-(sp) 
; bsr AdvanceA0 * first 2 chars are always printed 
; bsr AdvanceA0 
;* and blank out the digits which may possibly be printed 
; bsr PrintSpace 
; bsr PrintSpace 
; bsr PrintSpace 
; bsr PrintSpace 
; movem.l (sp)+,d0/a0 
; 
; bsr PrintDecimald0 
; 
; 
;* now restrict speed to 80 ms 
;DFTDelay 
; lea LastTime-S(a5),a0 
; move.l $4ba,d0 * 200 Hz Timer 
; move.l (a0),d1 
;; move.l d0,(a0) * update last frame time 
; sub.l d1,d0 
;* d0.l is time in 5 ms increments 
; mulu #5,d0 * convert to ms 
; cmp.l #80,d0 
; blt.s DFTDelay 
; move.l $4ba,(a0) * update last frame time 
; 
; 
AcodePrintDecRet 
 rts 
;--- 
AcodePrintDecimalD0 
 movem.l a3-a5,-(sp) 
 lea S(PC),a5 
 move.l d0,-(sp) 
  move.l TextScreenBase-S(A5),a0 
  bsr CalcCurrentCharAddressA0 
 move.l (sp)+,d0 
 bsr PrintDecimalD0 
 movem.l (sp)+,a3-a5 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
printdecimald0 
* print d0.l as a decimal number, 
* suppressing leading zeros 
 tst.l d0 
 bne.s printdec1 
 move.l #"0",d0 
; addq.w #8,CursorXPos-S(a5) * step on cursor position 
; move.b ByteInvertFlag(PC),d1 
; bne.s PDUseInverted 
; bsr WriteChar 
; bra Advancea0 
 bra PrintChar *  bra Oswrch 
 
;PDUseInverted 
; bsr InvertedWriteChar 
; bra AdvanceA0 
 
printdec1 
* non-zero number to print 
 move.l d0,d2 ; store number somewhere more sensible 
 lea numbertable-S(a5),a1 
 move.b #0,d3 ; reset flag 
printdec1a 
* find the current digit value 
 move.l (a1)+,d1 ; get value 
 beq Acodeprintdecret ; no more digits possible 
* given d2=remainder of number, d1=value of current digit, 
* find value 
 move.l #"0",d0 
printdec2 
 sub.l d1,d2 
 bcs.s printdec3 
 addq.b #1,d0 
 move.b #1,d3 ; set leading-zeros flag 
 bra.s printdec2 
printdec3 
 add.l d1,d2 
 tst.b d3 ; flag set yet ? 
 beq.s printdec1a 
 bsr PrintChar * Oswrch 
; addq.w #8,CursorXPos-S(a5) * step on cursor position 
; move.b ByteInvertFlag(PC),d1 
; bne.s PDUSeInverted2 
; bsr WriteChar 
; bsr AdvanceA0 
; bra.s printdec1a  
; 
;PDUseInverted2 
; bsr InvertedWriteChar 
; bsr AdvanceA0 
 bra.s printDec1a 
 
numbertable 
 dc.l 1000000000 
 dc.l 100000000 
 dc.l 10000000 
 dc.l 1000000 
 dc.l 100000 
 dc.l 10000 
 dc.l 1000 
 dc.l 100 
 dc.l 10 
 dc.l 1 
 dc.l 0 
;---- 
;--- 
;ProperPrintDecimald0 
;* print d0.l as a decimal number, 
;* suppressing leading zeros 
; tst.l d0 
; bne.s ProperPrintdec1 
; move.l #"0",d0 
; bra OswrchD0 * WriteChar 
;* bra Advancea0 
; 
;ProperPrintdec1 
;* non-zero number to print 
; move.l d0,d2 ; store number somewhere more sensible 
; lea numbertable-S(a5),a1 
; move.b #0,d3 ; reset flag 
;ProperPrintdec1a 
;* find the current digit value 
; move.l (a1)+,d1 ; get value 
; beq Printdecret ; no more digits possible 
;* given d2=remainder of number, d1=value of current digit, 
;* find value 
; move.l #"0",d0 
;ProperPrintdec2 
; sub.l d1,d2 
; bcs.s ProperPrintdec3 
; addq.b #1,d0 
; move.b #1,d3 ; set leading-zeros flag 
; bra.s ProperPrintdec2 
;ProperPrintdec3 
; add.l d1,d2 
; tst.b d3 ; flag set yet ? 
; beq.s ProperPrintdec1a 
; movem.l d0-d7/a0-a6,-(sp) 
; bsr OswrchD0 * WriteChar 
; movem.l (sp)+,d0-d7/a0-a6 
;* bsr AdvanceA0 
; bra.s ProperPrintdec1a  
; 
;---- 
;TextArea 
; dc.b 'This is a demonstration version of "Hero" - the animated ' 
; dc.b 'adventure system from Level 9 Computing.    ' 
; dc.b 'Copyright (C) 1988, 1989 Mike Austin.    ' 
; dc.b 'Release in 1989. ' 
; dc.b '.   .   .   .   .   .   ',0 
; even 
;TextEnd 
;TextLength equ TextEnd-TextArea-3 
; Note double space at end to avoid hassles with wrap-around 
; caused by using character pairs. 
;------- 
SafebreakPoint 
 movem.l d0-d7/a0-a6,-(sp) 
 bsr SetMedResolution 
 movem.l (sp)+,d0-d7/a0-a6 
 dc.w $4afa ; leave in till release 
 rts 
;-------- 
SetScreenResolution 
 ifne ST

* get screen address 
 call_ebios _physbase 
 addq.l #2,sp 
 move.l d0,OSScreenAddress-S(A5) 
 
* what screen resolution are we in ? 
 call_ebios _getrez ; move.w #4,-(sp) 
 addq.l #2,sp 
* d0.b = 0 - low resolution, 1 = medium resolution, 2 = high res 
 lea screenresolution-S(a5),a0 
 cmp.b #2,d0 
 beq.s inithires1 
 move.b #0,d0 ; always low res for graphics nowadays 
 move.b d0,(a0) 
 bra.s SetLowResolution 
 
inithires1 
 move.b d0,(a0) 
 lea LogicalBase-S(a5),a0 
 move.l #$f7ffe,(a0) 
 lea PhysicalBase-S(a5),a0 
 move.l #$EEFFE,(a0) 
 
SetHighResolution 
 move.w #2,-(sp) * high resolution 
 move.l #$ef000,-(sp) 
 move.l #$ef000,-(sp) ; logical base 
* move.w #5,-(sp) ; set screen 
 call_ebios _setscreen 
 add.l #12,sp 
 endc * above is ST only
 rts 
 
;-------- 
SetLowResolution 
 ifne ST

* Now set low resolution for use by the game 
 move.l OSScreenAddress-S(A5),d0 
; now d0.l is start of current screen 
;>>mike6/1/89 sub.l #8,d0 * allow for trimming of left hand edge 
 sub.l #$1000,d0 * allow for overflow on BuildIt 
 move.l d0,d1 
 sub.l #$9000,d1 * >$8000 because we overflow each screen slightly 
* During BuildIt 
 move.l d1,EndUserMemory-S(A5) 
 move.l d1,EndFreeMemory-S(A5) * >>mike 16/6/89 
 
* d1.l is start of alternate screen 
 
 move.l d1,LogicalBase-S(A5) 
 move.l d0,PhysicalBase-S(a5) 
 move.w #0,-(sp) ; low resolution 
 move.l d0,-(sp) 
 move.l d0,-(sp) ; logical base 
 
* move.w #5,-(sp) ; set screen 
 call_ebios _setscreen 
 add.l #12,sp 
 endc * above is ST-Specific
 rts 
;--- 
;SwapPage 
;* If it will be a long time before we can swap, 
;* set a flag and do it whilst building the new frame 
; move.b ScreenResolution-S(A5),d0 
; bne.s ActuallySwapScreen 
; bra.s ActuallySwapScreen ** 
; 
; move.l PhysicalBase-S(a5),d0 
; add.l #150*200,d0 
; lsr.w #8,d0 
; move.b $ff8207,d1 
; cmp.b d0,d1 
; bge.s ActuallySwapScreen * off screen already, so do it now! 
; 
; move.l PhysicalBase-S(a5),d0 
; add.l #8*160,d0 * get past text line etc. 
; lsr.w #8,d0 
; move.b $ff8207,d1 
; move.l #20000,d2 
; 
;WaitForOnScreen 
; subq.l #1,d2 
; bne.s WFOS1 
; dc.w $4afa ; leave in until release 
; 
;WFOS1 
; move.b $ff8207,d1 
; cmp.b d0,d1 
; blt.s WaitForOnScreen 
; lea StillNeedToSwapScreen-S(a5),a0 
; move.b #1,(a0) 
; bra SetWriteAlternate 
;;--- 
 
WaitForOffScreen 
 ifne Amiga
  rts
 endc

 ifne ST
 move.l PhysicalBase-S(a5),d0 
 add.l #150*200,d0 
 move.l d0,d1 
 lsr.l #8,d0 * make d0.b = middle of 24bit address 
 and.l #$000000ff,d0 
 asl.l #8,d1 * make d0.b(3) = high of 24bit address 
 and.l #$00ff0000,d1 
 or.l d1,d0 
 move.l $ff8204,d1 * read in ff8205,ff8207 
 and.l #$00ff00ff,d1 
 cmp.l d1,d0 
 bne.s WaitForOffScreen 
 rts 
 endc * ST 
; 
;;WaitForOffScreen 
;; move.b $ff8207,d1 
;; cmp.b d0,d1 
;; blt.s WaitForOffScreen 
;; move.w #36,-(sp) 
;; trap #14 
;; addq.l #2,sp 
; 
; cmp.l #$f7ff8,(a0) 
; beq.s SetLowerPage 
; move.l #$f7ff8,(a0) 
; rts 
; 
;SetLowerPage 
; move.l #$e7ff8,(a0) 
; rts 
;------- 
SetMedResolution 
 ifne ST
* Now set medium resolution, 
* so OS will print 80 column text correctly 
 move.w #1,-(sp) ; medium resolution 
 move.l OSScreenAddress-S(A5),-(sp) ; retain physical base 
 move.l OSScreenAddress-S(A5),-(sp) ; retail logical base 
* move.w #5,-(sp) ; set screen 
 call_ebios _setscreen 
 add.l #12,sp 
 endc
 rts 
;------- 
MoveScreen 
 ifne Amiga
  rts
 endc
 ifne WantAdept
; Change position of physical window onto map if appropriate 
 clr.w d6 
; move.b PlayerSDS+SpeedOffset,d6 * find step size 
 move.b ScrollStep-S(a5),d6 
 lea PlayerXpos-S(a5),a0 
 
 move.b DoingPseudoFlip-S(a5),d0 
 beq.s MoveScreen2 
; in the middle of a pseudo flip 
 lea DoingPseudoFlip-S(a5),a1 
 subq.b #1,(a1) 
 move.b PseudoFlipDirection-S(a5),d0 
 beq MoveToRight 
 bra MoveToLeft 
 
; Pseudo-flip handlers... 
 
MoveToLeft 
; player tried to go off the left hand edge 
 lea ScreenXPos-S(a5),a1 
 move.w (a1),d0 
 sub.w d6,d0 
 bmi moveScreenNotLR ; stop moving off screen 
 move.w d0,(a1) 
 bra MoveScreenNotLR 
 
MoveToRight 
; player tried to go off the right hand edge 
 lea ScreenXPos-S(a5),a1 
 move.w (a1),d0 
 add.w d6,d0 * d6 
 cmp.w ScreenXMax-S(a5),d0 
 bgt moveScreenNotLR 
 move.w d0,(a1) 
 bra MoveScreenNotLR 
 
; code to detect when a flip is necessary.. 
 
MoveScreen2 
 move.w PlayerXPos-S(a5),d0 
 sub.w ScreenXPos-S(a5),d0 
 cmp.w #86,d0 *32,d0 
 bgt.s MoveScreenNotLeft 
; lea DoingPseudoFlip,a0 
; move.b #1,(a0) * 5 
; lea PseudoFlipDirection,a0 
; move.b #1,(a0) 
 bra MoveToLeft * bra MoveScreenNotLR 
 
 
MoveScreenNotLeft 
 cmp.w #160,d0 * 130,d0 * 210,d0 
 bls.s MoveScreenNotRight 
; lea DoingPseudoFlip,a0 
; move.b #1,(a0) * 5 
; lea PseudoFlipDirection,a0 
; clr.b (a0) 
 bra MoveToRight * ; drop through to moveScreenNotLR 
 
MoveScreenNotRight 
moveScreenNotLR 
 lea ScreenYPos-S(a5),a0 
 move.w PlayerYPos-S(a5),d1 
 sub.w (a0),d1 
 cmp.w #120,d1 * 140,d1 
 blt.s MoveScreenNotDown 
; player is at the bottom of the screen - so scroll it up 
 
 move.w (a0),d0 
 add.w d6,d0 * d6 
 cmp.w ScreenYMax-S(a5),d0 
 bge.s MoveScreenRet ; MoveScreenNotDown 
 move.w d0,(a0) ; add on step size 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
MoveScreenNotDown 
 cmp.w #60,d1 * #32,d1 
 bgt MoveScreenNotUp 
; player is moving up the screen - so scroll it down 
 move.w (a0),d0 
 sub.w d6,d0 ; decrease screen y position * d6 
 bmi.s MoveScreenRet ; MoveScreenNotUp 
 move.w d0,(a0) 
 
MoveScreenNotUp 
MoveScreenRet 
 clr.l d0 * clear d0 before returning to acode
 endc * WantAdept
 rts 
;---- 
Specials 
;; handle cycling colours etc. 
; lea FrameCounter-S(a5),a0 
; add.l #1,(a0) 
; 
; lea StarCounter-S(a5),a0 
; addq.b #1,(a0) 
; move.b (a0),d0 
; lsr.b #1,d0 
; 
; cmp.b #8,d0 
; bne.s SpecialNotStar 
; clr.b d0 
; clr.b (a0) 
; 
;SpecialNotStar 
; cmp.b #4,d0 
; blt.s SNS1 
; move.b #6,d2 
; sub.b d0,d2 
; move.b d2,d0 
; 
;SNS1 
;* d0=phase of flashing stars 
; lea StarPhase-S(a5),a0 
; move.b d0,(a0) 
 rts 
;----- 
;------ 
SetUpPalette 
 ifne Amiga
  rts
 endc

 ifne ST
; move.l PalettePtr,-(sp) 
 lea Palette-S(a5),a0 
 move.l a0,-(sp) 
 move.w #6,-(sp) 
 trap #14 
 addq.l #6,sp 
 clr.l d0 * clear d0 before returning to acode
 rts 
 
 ifne WantMonochrome                 
* work out intensities for colormap 
getintens 
        Movem.l d0-d7/a0-a6,-(sp) 
 
        lea     Palette-S(a5),a1 
        lea     intens-S(a5),a0 
        move.w  #15,d0 
ginloop move.w  (a1)+,d1                * get colour 
        move.w  d1,d2                   * get blue component 
        and.w   #7,d2 
        move.w  d1,d3                   * green 
        lsr.w   #4,d3 
        and.w   #7,d3 
        move.w  d1,d4                   * red 
        lsr.w   #8,d4 
        and.w   #7,d4 
* approximate intensities with 4*red+2*green+blue 
        lsl.w   #2,d4 
        lsl.w   #1,d3 
        add.w   d3,d2 
        add.w   d4,d2 
*       lsr.w   #2,d2                   * value from 0 to 12 
* pick out appropriate scaling/equalization table to use 
        LEA     DivideBy3-S(a5),a3 
 clr.l d4 
; move.w PictureFileType,d4 
; cmp.w #$ffff,d4 
 bra StandardIntens 
* other file types are added to the scaling table pointer 
* for all colours except border (14/15) 
 cmp.w #1,d0 * border colour? 
 ble.s StandardIntens 
 
 ext.l d4 
 add.l d4,a3 
 add.l #128,a3 * to allow positive as well as negative changes 
 
StandardIntens 
        move.b  0(a3,d2),d2 * d2.w has bits 8-15 clear 
        move.w  d2,(a0)+ 
        dbra    d0,ginloop 
 
        Movem.l (sp)+,d0-d7/a0-a6 
  clr.l d0 * clear d0 before returning to acode
       rts 
 endc * WantMonochrome
 ENDC * ST
 
;----- 
MakeA0Even 
 move.l a0,d0 
 btst #0,d0 
 beq.s MakeA0EvenRet 
 addq.l #1,a0 
MakeA0EvenRet 
 rts 
;---- 
ToPrinter 
 ifne Amiga
  rts
 endc

 ifne ST
; send character d0 to OutputDevice 
; probably either 0=centronics, or 1=rs232 
 movem.l d0-d7/a0-a6,-(sp) 
 lea S(PC),a5 
 bsr AbsToPrinter 
 movem.l (sp)+,d0-d7/a0-a6 
 cmp.b #13,d0 
 beq OswrchCR 
 rts 
 endc
;--- 
AbsToPrinter 
 ifne ST

 move.b OutputDevice-S(A5),d2 * output device 
 cmp.b #1,d2 
 bne.s bdosNotRS232 * only need extra wait for rs232 
;* now send it to the printer 
; wait for device to become ready. 
 movem.l d0-d7/a0-a6,-(sp) 
bdosPrinterWait 
 move.w #1,-(sp) ; aux ready? 
 move.w #8,-(sp) ; bcostat 
 trap #13 
 addq.l #4,sp 
 tst.b d0 
 beq bdosprinterWait 
 movem.l (sp)+,d0-d7/a0-a6 
 
 move.l a0,-(sp) 
 move.w d0,-(sp) * this is argument for routine as well as preservation 
 call_bdos c_auxout * send to printer - call_bdos c_conout 
 addq.l #2,sp * remove function call number etc. 
 move.w (sp)+,d0 
 move.l (sp)+,a0 
ToPrinterRet 
 rts 
 
BDosNotRs232 
 move.l a0,-(sp) 
 move.w d0,-(sp) * this is argument for routine as well as preservation 
 call_bdos c_conout 
 addq.l #2,sp * remove function call number etc. 
 move.w (sp)+,d0 
 move.l (sp)+,a0 
 rts 
;-------
;MCUpdateScreen 
; rts
 endc * above printer stuff is ST only

;--- 
 
 
;-------- 
;DoDelayedFlip 
; movem.l d0-d1/a0,-(sp) 
; move.b StillNeedToSwapScreen-S(a5),d0 
; beq.s DDNoFlip 
; move.l LogicalBase-S(a5),d0 
; add.l #130*200,d0 
; lsr.w #8,d0 
;DDWait 
; move.b $ff8207,d1 
; cmp.b d0,d1 
; blt.s DDWait 
; bsr SetWriteAlternate * make it display the correct buffer 
; bsr ActuallySwapScreen 
;DDNoFlip 
; movem.l (sp)+,d0-d1/a0 
; rts 
;-------- 
MCSetGraphicsWindow 
; Set graphics clipping 
;       v1=Left   X 
;       v2=Right  X 
;       v3=Top    Y 
;       v4=Bottom Y 
 movem.l a3-a6,-(sp) 
  move.w 2(a4),d0 * v1 
  move.w d0,LH3D
  sub.w #16,d0 
  move.w d0,LHMinus16 
  move.w 4(a4),d0 * v2 
  move.w d0,RH 
  sub.w #15,d0 
  move.w d0,RHMinus15 
  move.w 6(a4),d0 * v3 
  move.w d0,Top 
  sub.w #16,d0 
  move.w d0,TopMinus16 
  move.w 8(a4),d0 * v4 
  move.w d0,Bottom 
  move.w d0,DisplayedYPixels **** is this right????
  sub.w #15,d0 
  move.w d0,BottomMinus15 
 movem.l (sp)+,a3-a6 
 clr.l d0 * clear d0 before returning to acode
 rts 
;-------
 ifne Amiga
MCClearSection * should be MCClearRectangle
* clear a rectangle of screen starting at 
* (CursorXPos,CursorYPos) top left 
* of size (v1=0..319,v2=0..199) pixels 
 movem.l a3-a6,-(sp)
  bsr ClearRectangle
 movem.l (sp)+,a3-a6
 clr.l d0 * clear d0 before returning to acode
 rts

PhysicalClearRectangle
 bsr CalcCurrentCharAddress
* a0.l = address of top left of screen relative to start of bit maps
 move.w 4(a4),d1 * y size 
 move.l PhysicalBP0,a1
 add.l a0,a1
 move.l PhysicalBP1,a2
 add.l a0,a2
 move.l PhysicalBP2,a3
 add.l a0,a3
 move.l PhysicalBP3,a5 * NOTE!!!! Must preserve a4 for V1.
 add.l a0,a5
 bra.s CClearLine0
;---
ClearRectangle
 bsr CalcCurrentCharAddress 
* a0.l = address of top left of screen relative to start of bit maps
 move.w 4(a4),d1 * y size 
 move.l LogicalBP0,a1
 add.l a0,a1
 move.l LogicalBP1,a2
 add.l a0,a2
 move.l LogicalBP2,a3
 add.l a0,a3
 move.l LogicalBP3,a5 * NOTE!!!! Must preserve a4 for V1.
 add.l a0,a5
CClearLine0 
 move.w 2(a4),d0 * x size 
 lsr.w #3,d0 * convert to number of bytes 
 movem.l a1-a5,-(sp)
CClearLine1 
  clr.b (a1)+ 
  clr.b (a2)+
  clr.b (a3)+
  clr.b (a5)+ * Note gap!!!
  dbra d0,CClearLine1
 movem.l (sp)+,a1-a5
* skip to next line of block 
 add.l #BytesPerPixelLine,a1 * next line of pels 
 add.l #BytesPerPixelLine,a2 * next line of pels 
 add.l #BytesPerPixelLine,a3 * next line of pels 
 add.l #BytesPerPixelLine,a5 * next line of pels 
 subq.l #1,d1 
 bpl.s CClearLine0 
 rts 
 endc * Amiga MCClearSection
;----
 ifne ST
PhysicalClearRectangle
 move.l PhysicalBase,a0
 bsr CalcCurrentCharAddressA0
 bra.s ClearRectangle

MCClearSection 
; should be MCClearRectangle
* clear a rectangle of screen starting at 
* (CursorXPos,CursorYPos) top left 
* of size (v1=0..319,v2=0..199) pixels 
 bsr CalcCurrentCharAddress 
* a0.l = address of top left of screen 
 move.b ScreenResolution,d0 
 bne.s HClearSection 
* colour version 
ClearRectangle
 move.w 4(a4),d1 * y size 
CClearLine0 
 move.l a0,-(sp) 
 move.w 2(a4),d0 * x size 
 lsr.w #3,d0 * convert to number of bytes 
CClearLine1 
 clr.b (a0) 
 clr.b 2(a0) 
 clr.b 4(a0) 
 clr.b 6(a0) 
 subq.w #1,d0 
 bmi.s CClearLine2 * end of line 
 clr.b 1(a0) 
 clr.b 3(a0) 
 clr.b 5(a0) 
 clr.b 7(a0) 
 subq.w #1,d0 
 bmi.s CClearLine2 * end of line 
 addq.l #8,a0 
 bra.s CClearLine1 
 
CClearLine2 
* skip to next line of block 
 move.l (sp)+,a0 
 add.l #160,a0 * next line of pels 
 subq.l #1,d1 
 bpl.s CClearLine0 
 rts 
;--- 
HClearSection 
 
        Move.l d2,-(sp) * just incase * 
 
        Move.w 4(a4),d1 * y size(Pixels down screen) 
        Lsl.w #1,d1     * multiply by two (cos of hi-res) 
        Sub.w #1,d1     * get it suitable for Dbf loop 
        Move.l a0,-(sp) 
        Move.w 2(a4),d0 * x size 
        Lsr.w #3,d0     * convert to number of bytes 
 
HClearLoop1 
         
        Move.w d0,d2 
        Sub.w #1,d2 
 
HClearLoop2 
         
        Move.b #0,(a0)+ 
 
        Dbf d2,HClearLoop2      * bytes across loop * 
 
        Move.l (sp)+,a0 
        Add.l #80,a0            * a line down * 
        Move.l a0,-(sp) 
        Dbf d1,HClearLoop1      * lines down loop * 
        Move.l (sp)+,a0         * clear up stack * 
        Move.l (sp)+,d2 
        Rts                      
 endc * ST mcclearrectangle 
;-----
 ifne Amiga
MCInitSound
MCInitJoystick
 endc

 ifeq WantAdept
BuildBackground
DisplayDestroyedWalls
MCMoveAllSprites
DisplayAllSprites
TrimEdges
HeroInput
MCDestroySpriteList20
MCDestroySpriteList22
MCFindSprite
MCSetUpNewSprite
MCSprite
MCHandlePlayerInput
MCMapBuildBackground
MCSpecialCheck
MCStartBigExplosion
MCCalcSpriteAddress
MCNoCLipSprite
 rts
 endc


MCReturnSpriteAddress 
; called MCCalcCurrentSpriteAddress in acode
; return List19Ptr as data for sprite V1 
 move.w UseVM,d0
 beq.s MCRSA1
 move.w 2(a4),d0
 mulu #4,d0 * 4 bytes per cell table entry
 move.l Cell_TAbPtr,a0
 add.l d0,a0
 move.l (a0),d0
 and.l #CellAddressMask,d0 * remove protect flag, timer
 move.l d0,List19Ptr-S(a5) * write to storage for use by cd etc. 
 clr.l d0 * clear d0 before returning to acode
 rts

MCRSA1
 clr.l d4 
 move.w 2(a4),d4 
 move.l SpriteDataPtr-S(a5),a1 
 mulu #LinesPerSprite*8,d4 
;; asl.l #7,d4 
 add.l d4,a1 
 move.l a1,List19Ptr-S(a5) * write to storage for use by cd etc. 
 rts 
;------- 



 ifne ST
MCSetPalette
; set palette listv1(v2)
; each word is of format RGBX where X=RGBI value for PC
; and other four letters are one nybble each.
 move.w 2(a4),d0 ; V1
 asl.w #2,d0 
 lea List0Ptr-S(a5),a1 
 ext.l d0 
 add.l d0,a1 
 move.l (a1),a1
 clr.l d0
 move.w 4(a4),d0
 add.l d0,a1
 move.l #$ff8240,a0
 move.w #15,d0
MCSP1
 move.w (a1)+,d1
 lsr.w #4,d1
 move.w d1,(a0)+
 dbra d0,MCSP1
 clr.l d0 * clear d0 before returning to acode
 rts

;----------
MCOsrdch
 movem.l a3-a6,-(sp)
 
 bsr AskForJoystick ; update joystick status

  jsr AbsGetCharFromBdos
 movem.l (sp)+,a3-a6
 move.w d0,2(a4)
 swap d0 ; return high value in v2:
 move.w d0,4(a4)
 cmp.b #$74,d0
 beq.s MouseButton
 cmp.b #$75,d0
 beq.s MouseButton
 clr.l d0 * clear d0 before returning to acode
 rts

MouseButton
; key codes $74/$75 are the mouse button packets.
 clr.w 2(a4)
 clr.w 4(a4) * return no key
 clr.l d0 * clear d0 before returning to acode
 rts
;--- 

CloseDownTrap13
* trap "Abort, Retry, Ignore" error message + subsequent
* request for a keystroke. Both of these are vectored through
* the BIOS: Trap #13, which is vectored at $000000b4
* function nummber is at 6(sp), 2 for bconin, 3 for bconout.
* For no disk error (most likely one), return 'A' for abort
 move.l OSTrap13Vec,a0
 move.l a0,$b4
 rts

MyTrap13
 move.w d0,-(sp)
 move.w Trap13Errors,d0
 beq.s MyTrap13Normal
* prevent bconout from doing anything,
* return 'a' for bconin
 move.w 8(sp),d0 * 6(sp)+2 for d0 saved above
 cmp.w #2,d0 * BConin
 beq.s MyTrap13BConin
 cmp.w #3,d0 * BConout
 bne.s MyTrap13Normal
* bconout
 move.w (sp)+,d0
 rte

MyTrap13BConin:
 ifeq ReleaseGame
  sub.w #1,Trap13Errors * for non-release game, make it
* just generate a few 'a's, to make debugging easier
 endc
 move.w (sp)+,d0
 move.w #'a',d0
 rte

MyTrap13Normal
 move.w (sp)+,d0
 move.l OSTrap13Vec,-(sp)
 rts

;prs
;* print string following call, terminated by 0
; move.l a0,-(sp)
; move.l d0,-(sp)
; move.l $8(sp),a0 * get return address = start address of string
;prs1
; move.b (a0)+,d0 * (a6)
; beq.s prsend
; bsr oswrch
; bra prs1
;prsend
;* make sure it is an even return address
; move.w a0,d0
; btst #0,d0
; beq.s prsend1
; addq.l #1,a0
;prsend1
; move.l a0,$8(sp)
; move.l (sp)+,d0
; move.l (sp)+,a0
; rts

 ifeq ReleaseGame
StructureTest
 move.b #1,UseVM

 bsr MCInitSpritesFile
 lea StructuresDriverBlock,a6
 move.l FreeWorkspace,a0
 move.l a0,(a6)
 move.l a0,-(sp)
  jsr LoadFile
  move.l $4(a6),FreeWorkSpace
 move.l (sp)+,a0
 bsr Setup_ptrsA0
* set up map size
 lea MikeTemp,a4
 move.w #639,2(a4) *319,2(a4) * horizontal size in pixels (e.g. 0..319)
 move.w #383,4(a4) *191,4(a4) * vertical size in pixels (e.g. 0..191)
 move.w #1,6(a4) * game mode. 1 for scrolling
 bsr InitialiseScrolling

 move.w #2000,2(a4) * number of cells
 move.w #1500,4(a4) * links
 move.w #1500,6(a4) * now redundant
 move.w #1500,8(a4) * masks
 bsr MCSetUpVariablePtrs * Also sets up pool, so chobbles all memory

* ScrollDirection: v1=horiz step, v2=vert step, +/- words
* returns actual values

 bsr MCEmptyRoom
 lea MikeTemp,a4
 bsr MCPre_load_cells
 move.w #2,2(a4)
 move.w #0,4(a4) * x
 move.w #0,6(a4) * z
 move.w #0,8(a4) * h
 move.w #3,10(a4) * preload
 move.w #0,12(a4) * not reversed
 bsr MCMake_Pic0
 move.w #2,2(a4)
 move.w #0,4(a4) * x
 move.w #3,10(a4) * preload
 bsr MCMake_Pic0
 bsr MCPre_load_cells

 lea MikeTemp,a4
* 400 is rh pair of pics
 move.w #2,2(a4)
 move.w #320,4(a4) * x
 move.w #0,10(a4) * build
 bsr MCMake_Pic0
 move.w #-200,8(a4) * h
 bsr MCMake_pic0
 move.w #2,2(a4)
 move.w #0,4(a4) * x
 bsr MCMake_Pic0
 move.w #0,8(a4) * h
 bsr MCMake_pic0

 move.w #128,2(a4) * x position of map
 move.w #0,4(a4) * y position of map
 bsr MCBuildRoom

 lea MikeTemp,a4
 move.w #520,2(a4) * 501,2(a4)
 move.w #200,4(a4) * x
 move.w #176,6(a4) * z
 move.w #160,8(a4) * h
;; bsr MLSpriteSpeed

MLSpriteTest
 bsr MCDisplayRoom
; bsr MCClearScreen
 bsr MLDelay

 lea MikeTemp,a4
 move.w #1,10(a4) * draw
 move.w #0,12(a4) * not reversed
 bsr MCMake_Pic0

 bsr MLDelay

 bsr DisplayFrame
 bsr WaitForFrame


 move.l #0,d1
ClearKbdLoop
 move.l d1,-(sp)
 jsr AbsGetCharFromBDos
 move.l (sp)+,d1
 tst.b d0
 beq.s ClearKbd1
 move.b d0,d1
 bra.s ClearKbdLoop

ClearKbd1
 move.b d1,d0
; cmp.b #27,d0
; beq goaway
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
; move.l #0,XDir * Make screen move once per press **
 cmp.b #'4',d0
 bne.s MLNotLeft
 move.b PadControlsSprite,d0
 beq.s MLLeftScroll
 subq.w #1,4(a4)
 bra.s MLNotLeft
MLLeftScroll
 sub.w #1,XDir * bsr CompleteMoveLeft

MLNotLeft
 cmp.b #'6',d0
 bne.s MLNotRight
 move.b PadControlsSprite,d0
 beq.s MLRightScroll
 addq.w #1,4(a4)
 bra.s MLNotRight
MLRightScroll
 add.w #1,XDir * bsr CompleteMoveRight

MLNotRight
 cmp.b #'8',d0
 bne.s MLNotUP
 move.b PadControlsSprite,d0
 beq.s MLUpScroll
 addq.w #1,8(a4) * h
 bra.s MLNotUp
MLUpScroll
 sub.w #1,YDir * bsr CompleteMoveUp

MLNotUp
 cmp.b #'2',d0
 bne.s MLNotDown
 move.b PadControlsSprite,d0
 beq.s MLDownScroll
 subq.w #1,8(a4) * h
 bra.s MLNotDown
MLDownScroll
 add.w #1,YDir * bsr CompleteMoveDown

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

; clr.w d0
; move.w ScrollXPos,d0
; move.w d0,d1
; asl.w #4,d1 * duplicate scroll value in next nybble
; or.w d1,d0
; move.l CopperListScrollAddress,a0
; move.w d0,(a0)
; move.w d0,$dff102

 bra MLSpriteTest
;------
MLDelay
 rts
;------
DisplayFrame
 move.b #1,FrameReady
 rts
;------
WaitForFrame
 move.b FrameReady,d0
 bne.s WaitForFrame
 move.l LogicalBase-S(a5),GraphicsScreenBase-S(A5) *>>Mike 19/3/ 
 rts
;-----
;MikeTemp dc.l 0
; dc.l 0
; dc.l 0
; dc.l 0,0,0,0,0,0,0,0,0,0

PadControlsSprite dc.w 0
 dc.w 0 * padding before xdir.
XDir dc.w 0
YDir dc.w 0

StructuresDriverBlock
 dc.l 0
 dc.l 0
 dc.b 'STRUCTUR.DAT',0
 even


 endc * ReleaseGame

 endc * ST 
 
 include 'ram.s' 
 
 
 
 
