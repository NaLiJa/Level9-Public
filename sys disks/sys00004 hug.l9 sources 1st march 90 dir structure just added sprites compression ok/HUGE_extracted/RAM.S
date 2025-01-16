 ifnd MCStart
 include 'Condit.s'
 endc

* 3d_vars.s and RAM.S
*
* M.J.Austin26/2/90
*
*>>Mike 26/1/89 - pointers moved at end of this file 
 
 ifne ST
BPC equ 8 * bytes per cell (one pixel line)
 endc
 ifne Amiga
BPC equ 2 * bytes per cell (one pixel line)
 endc


;----
DirectoryPtr dc.l 0

;----
FirstCellPointerInMemory dc.w 0
LastCellPointerInMemory dc.w 0
CellPointers dc.l 0


SectorSize equ 512
HuffmanSectorBufferPtr dc.l 0 * pointer to a 2-sector (1K) buffer
HuffmanHeaderPtr dc.l 0 
SpritesFileType dc.b 0 * 0 means undecided.
CompressedType equ 1
UncompressedType equ -1
LastHuffmanReadAddress dc.l 0
HuffmanLoadAddress dc.l 0 * temp store for cell read address

HuffmanCellsUnpacked dc.l 0
HuffmanDiskReads dc.l 0

MikeTemp ds.b 48 * general buffer for driver blocks etc.
HaveDoneInitScrolling dc.b 0
 even
 
*  memory variables  ----------
 
msg_off:	equ	21	* message switch offset 
 
sys_clock:	dc.w	36	* clock 
handle:	dc.w	0	* file handle 
timer:	dc.w	0	* flags/clock 
cell_1:	dc.w	0	* 1st cell to load 
;cell_cnt:	dc.w	0	* no. cells counter 
 
drive_flag:	dc.w	0	* drive id flag 
 
 ifne ST
ld_cnt:	dc.w	0	* load counter 
d_flag:	dc.w	0	* disc flag 
disc_num:	dc.w	0	* reqd disc no. 
sect_num:	dc.w	0	* reqd sector no. 
ld_rem:	dc.w	0	* load remainder 
id_sect:	dc.w	0	* id sector no. 
last_sect:	dc.w	0	* last sector read 
 endc * ST
 
reqd_cell:	dc.l	0	* cell no./pointer 
info_pnt:	dc.l	0	* disc info pointer 
ld_pnt:	dc.l	0	* load pointer 
data_len:	dc.l	0	* data block len 
 
 ifne ST
;dead_tab:	dc.w	54,55,102,103,198,199,254,255 
;	dc.w	334,335,406,407,478,479,554,555 
;	dc.w	614,615,702,703,$FFFF 
 
;info_tab:	ds.b	9*8 
; 
;msg1:	dc.b	27,'E','Please insert disc x into drive.',0 
; 
;id_msg:	dc.b	'Lauren.',0 
 even
;CheckSpritesFilename dc.b 'sprites?.dat',0
 endc * ST 
 
*   drawing variables mainly  -----------
 
  
;;ConstMapWidth equ 21 
;;ConstMapHeight equ 12
 ifne ScrollingSystem
ConstScreenXCells equ 21
ConstScreenYCells equ 13
 endc
 ifeq ScrollingSystem
ConstScreenXCells equ 20
ConstScreenYCells equ 12
 endc

;map_wdth:	dc.w	ConstScreenXCells	* map/pic width+1 
 dc.w 0 * must be just before Map_XCellsTimes4 so
* we can address map_XCellsTimes4 as a long, if we so wish.
 ifne ScrollingSystem
mapXCellsTimes4  dc.w	(ConstScreenXCells-1)*4	* map/pic width+1 
 endc
 ifeq ScrollingSystem
mapXCellsTimes4  dc.w	(ConstScreenXCells)*4	* map/pic width+1 
 endc

;map_hgt:	dc.w	ConstScreenYCells	* map/pic height 
MapXCells dc.w ConstScreenXCells
MapXCellsMinus1 dc.w ConstScreenXCells-1
MapXPixels dc.w ConstScreenXCells*16
MapYCells dc.w ConstScreenYCells
MapYCellsMinus1 dc.w ConstScreenYCells-1
MapCells dc.w ConstScreenXCells*ConstScreenYCells
ConstMapCells equ ConstScreenXCells*ConstScreenYCells
MapCellsTimes4 dc.w ConstMapCells*4
MapCellsMinus1 dc.w ConstMapCells-1
MapCellsTimes128Div4MInus1 dc.w ConstMapCells*128/4-1
MapCellsTimes128Div64MInus1 dc.w ConstMapCells*128/64-1

 ifne Amiga
 ifeq ScrollingSystem
BytesPerPixelLine equ 160 *^^^
ConstDisplayedXCells equ 20
ConstDisplayedYCells equ 12
 endc
 ifne ScrollingSystem
BytesPerPixelLine equ 168 *^^^^42
ConstDisplayedXCells equ 21
ConstDisplayedYCells equ 12
 endc
 endc

 ifne ST
ConstDisplayedXCells equ 20
ConstDisplayedYCells equ 12
BytesPerPixelLine equ 160
 endc


* a complete set of the same variables for the actual
* displayed area of the screen. These will in general
* not be changed by the program.
 dc.w 0 * must be just before Displayed_XCellsTimes4 so
* we can address Displayed_XCellsTimes4 as a long, if we so wish.
DisplayedXCellsTimes4  dc.w	ConstScreenXCells*4	* map/pic width+1 
;map_hgt:	dc.w	ConstScreenYCells	* map/pic height 
DisplayedXCells dc.w ConstScreenXCells
DisplayedXCellsMinus1 dc.w ConstScreenXCells-1
DisplayedYCells dc.w ConstScreenYCells
DisplayedYCellsMinus1 dc.w ConstScreenYCells-1
DisplayedYPixels dc.w 12*16
DisplayedCells dc.w ConstScreenXCells*ConstScreenYCells
DisplayedCellsMinus1 dc.w ConstScreenXCells*ConstScreenYCells-1
DisplayedCellsTimes128Div4MInus1 dc.w ConstScreenXCells*ConstScreenYCells*128/4-1
DisplayedCellsTimes128Div64MInus1 dc.w ConstScreenXCells*ConstScreenYCells*128/64-1

 ifne ScrollingSystem
ConstBSXCells equ 21 * 1 over-size, to allow nice clipping
ConstBSYCells equ 13 * 1 over-size, to allow nice clipping
 endc
 ifeq ScrollingSystem
ConstBSXCells equ 20 * 1 over-size, to allow nice clipping
ConstBSYCells equ 12 * 1 over-size, to allow nice clipping
 endc

 ifne ST
ConstBytesPerBSLine equ ConstBSXCells*BPC
 endc
 ifne Amiga
ConstBytesPerBSLine equ ConstBSXCells*BPC*4 * 4 bit-planes^^^
 endc

BytesPerBSLine dc.l ConstBytesPerBSLine *BytesPerPixelLine
BytesPerBSCellLine dc.w ConstBytesPerBSLine*16
BytesPerBSLineTimes16 dc.l ConstBytesPerBSLine*16 *BytesPerPixelLine*16
;ConstBSPlaneSize equ BPSize+1000
 ifne ST
BytesPerScreenLine dc.l ConstDisplayedXCells*BPC * same size as buffer screen at present
 endc

 ifne Amiga
BytesPerScreenLine dc.l ConstDisplayedXCells*BPC*4 * same size as buffer screen at present
* 4 bit-planes: because bit planes are interleaved in a strange
* way.
 endc

ConstBSPlaneSpacing equ ConstBSXCells*BPC *^^^^^^^
BSPlaneSpacing dc.l ConstBSPlaneSpacing

ConstBSLineSpacing equ ConstBSPlaneSpacing*4
BSLineSpacing dc.l ConstBSLineSpacing


ConstBSPlaneSize equ (ConstBSXCells*BPC)*(ConstBSYCells+2)*16 *****31/1/90 was +2
BSPlaneSize dc.l ConstBSPlaneSize

 ifne Amiga
 ifeq Colors32
ConstBSSize equ ConstBSPlaneSize*4
BSSize dc.l ConstBSPlaneSize*4 * 4 bit planes
BSDisplayedPlaneSizeMinus16Lines dc.l (ConstBSXCells*BPC)*((ConstDisplayedYCells-1)*16)
BSDisplayedPlaneSize dc.l (ConstBSXCells*BPC)*((ConstDisplayedYCells)*16)
 endc
 endc

 ifne ST
ConstBSSize equ ConstBSPlaneSize
BSSize dc.l ConstBSPlaneSize ******4 * 4 bit planes
BSDisplayedPlaneSizeMinus16Lines dc.l (ConstBSXCells*BPC)*((ConstDisplayedYCells-1)*16)
BSDisplayedPlaneSize dc.l (ConstBSXCells*BPC)*((ConstDisplayedYCells)*16)
 endc

ScreenYClip equ 175 * clipping level for 3d sprite plotting. 
GameMode dc.b ScrollingSystem * 0 for fixed, 1 for scrolling.
 even

* workspace for clipping window 
LH3d dc.w 0 
LHMinus16 dc.w -16 
RH dc.w 319+16 * for scrolling 
RHMinus15 dc.w 304+16 * for scrolling 
 ifne Amiga
Top dc.w 0 
TopMinus16 dc.w -16 
TopPlus16 dc.w 16
 endc
 ifne ST
 ifeq ScrollingSystem
Top dc.w 0 
TopMinus16 dc.w -16 
TopPlus16 dc.w 16
 endc
 ifne ScrollingSystem
Top dc.w 0 *-16
TopMinus16 dc.w -16 *-32
TopPlus16 dc.w 16 *0
 endc
 endc

Bottom dc.w ConstBSYCells*16-1 *191  * for scrolling
BottomMinus15 dc.w ConstBSYCells*16-15 *dc.w 176  for scrolling.
ClipMask dc.w 0 
FreeTransparencies dc.w 0 
 

 
;xcord:	dc.w	0	* x_cord 
;zcord:	dc.w	0	* z_cord 
;hcord:	dc.w	0	* h_cord 
;ycord:	dc.w	0	* lo-res y cord 
;ypos:	dc.w	0	* hi_res y cord 
 
list_len:	dc.w	0	* data list length 
xsize:	dc.w	0	* block x width 
xcnt:	dc.w	0	* block x width counter 
ycnt:	dc.w	0	* block y height counter 
drw_flag:	dc.w	0	* draw/insert flag 
obj_num:	dc.w	0	* initial object no. 
rev_flag:	dc.w	0	* reverse draw flag 
rev_ptr:	dc.l	0		* reverse cell list pointer 
 
image:	dc.w	0	* image no. 
hi_cnt:	dc.w	0	* top lines count 
lo_cnt:	dc.w	0	* low lines count 
pd_off:	dc.l	0	* low data offset 
pm_off:	dc.l	0	* hi mask offset 
 
mask1:	dc.l	0	* mask1 pointer 
mask2:	dc.l	0 
mask3:	dc.l	0 
mask4:	dc.l	0 
scrn1:	dc.l	0	* screen1 pointer 
scrn2:	dc.l	0 
scrn3:	dc.l	0 
scrn4:	dc.l	0 
 
; ifne Amiga
* Add for the ST as soon as the code's in to set it up!
mask_buffPtr ds.l 1
; endc
 ifne Amiga
WideMaskPtr ds.l 1 * only for Amiga sprite-plotting blitter code
WideSpriteMaskPtr ds.l 1 * only for Amiga: expanded sprite mask
 endc

ReversedCellBufferPtr ds.l 1 * pointer to reversed cell bufer (128 bytes)
WSMaskPtr ds.l 1

 ifne ST
mask_buff:	ds.b	32 
ReversedCellBuffer ds.l 128
 endc
 
 ifne ST
null_mask:	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF 
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF 
 endc * ST

null_maskPtr ds.l 1
DiskCachePtr ds.l 1 * pointer to disk cache, 0 if none. 
DiskCacheOffset dc.l 0 * offset of cache within sprites.dat file
DiskCacheSize equ 8192
	even 
 
PoolSizeCells: dc.w 0
NumCells:	dc.w	0	* 1st comp cell no. 
MaxShiftedCell: dc.w	0 * highest cell number we can
* generate for non-aligned insert.
CurrentShiftedCell dc.w 0 * cell number we're about to generate
ShiftedCellTablePtr ds.l 1

FreeLinks dc.w 0 * see also FreeTransparencies. Primarily
* for debugging purposes.
num_links:	dc.w	0	* max. no. links in structure 
nx_f_link:	dc.w	0	* next free link offset 
;;nx_f_cnum:	dc.w	0	* next free char number 
;;nx_f_char:	dc.l	0	* next free char pointer 
nx_f_mask:	dc.l	0	* next free mask pointer 
masks_start:	dc.l	0	* start of masks 
masks_end:		dc.l	0	* end of masks
;comps_start:	dc.l	0	* start of reversed cells pool 
;* (was composite cells for view-map as well) 
 
sz_f_cmemPtr:	dc.l	0	* free memory pool size 
cmem_sizePtr:	dc.l	0	* max memory pool size 
;;nx_f_cmem:	dc.l	0	* next free cell memory 
PoolFSLL	dc.l 0 * start of FS linked list
* within cell table - i.e. the cells are linked together. 
cmem_mapPtr:	dc.l	0	* memory purge map 
cell_tabPtr:	dc.l	0	* cell data pointers 
cmem_poolPtr:	dc.l	0	* start of memory pool 
cmem_strtPtr:	dc.l	0	* cmem_pool start 
cmem_endPtr:	dc.l 	0 * primarily for Amiga VM
CurrentPurgeCell dc.w 0
g_mapPtr:	dc.l	0	* G_map pointer 
;;v_mapPtr:	dc.l	0	* V_map pointer 
BufferScreen1	dc.l	0	* contains the cumulative 
* effect of all the structures, in a form just raring to 
* be copied onto a standard ST screen. 
BufferScreen1End	dc.l	0
 
SpritesHandle dc.l 0

ScrollXPos dc.w 0
ScrollYPos dc.w 16 * makes it have no effect.
 even

SpriteFileTable
 dc.l -1 * two words for each sprite file we're allowed.
 dc.l -1 * Thus a value of 8 allows a maximum of 7 disks (disk 0 is dummy)
 dc.l -1
 dc.l -1
 dc.l -1
 dc.l -1
 dc.l -1
 dc.l -1

 
pntrs_tab:	ds.b	30	* data pointers 
CheckDiskFlag dc.b 0
;CurrentDiskSprites dc.b 0 * contains number of a sprites
RequestorDisplayed dc.b 0
* file on this disk.
 even
; ds.b 512 * temporarily use as a track buffer as well

LastCellRead ds.l 1
LastCellBuffer ds.b 128
 ifne ST
dtaBuffer ds.b 46 * 44 byte buffer for disk transfer etc.
 endc

 ifne Amiga
InfoBlockPtr dc.l 0 * points to a 260 byte buffer
; for using "INFO" - needs
;* a 260 byte buffer (!), plus may have to vary by 0..+2 to
;* guarantee it's long-aligned.
 endc

; ifne Amiga
; ds.b 138 * extension to LastCellBuffer for using "INFO" - needs
;* a 260 byte buffer (!), plus may have to vary by 0..+2 to
;* guarantee it's long-aligned.
; endc

DiskNum dc.w 1 * disk number we want next

 IFNE ST
SpritesFilename: dc.b 'SPRITES'
SpritesFileNum: dc.b '1'
SpritesFileDot: dc.b '.'
SpritesFileExtension dc.b 'DAT',0 

ConstCompressedExtension equ '.'<<24+'C'<<16+'M'<<8+'P'
ConstUncompressedExtension equ '.'<<24+'D'<<16+'A'<<8+'T'

 ENDC

 IFNE AMIGA
SpritesFilename:
 ifne ForceDF0
  dc.b 'DF0:'
 endc
; dc.b ':'
SpritesDiskNum:
* dc.b '0
 dc.b 'SPRITES'
SpritesFileNum: dc.b '1'
SpritesFileDot: dc.b '.DAT',0 
ConstCompressedExtension equ '.'<<24+'C'<<16+'M'<<8+'P'
ConstUncompressedExtension equ '.'<<24+'D'<<16+'A'<<8+'T'

 ENDC

 even
 
load_list:	dc.l	0 
;;rev_list:	ds.w	(600*2)	* reverse cell number list 
 
 
 
; RAM.S - alll Hero Workspace 
; 
; Copyright (C) 1988 Level 9 COmputing 
; 
; M.J.Austin 1987/1988 
; 
; 27/1/89 - FreeWorkSpace moved to be accessible by acode 
 
 
 even 

CheckDiskTimer dc.w 0
LastSeekPos dc.l 0
AcodePtrsInitialised dc.l 0
DriveLetter dc.w 0

 dc.w 0 * space in case we use error code (-1) as channel no.
 dc.w 0 
Channel0Records
TimeOffset equ *-Channel0Records
 dc.w 0 * time remaining for this tone
NoteNumberOffset equ *-Channel0Records
 dc.w 0 * note number of tone currently playing

ChannelRecordsSize equ *-Channel0Records
Channel1Records
 dc.w 0 * time remaining for this tone
 dc.w 0 * note number of tone currently playing
Channel2Records
 dc.w 0 * time remaining for this tone
 dc.w 0 * note number of tone currently playing
Channel3Records
 dc.w 0 * time remaining for this tone
 dc.w 0 * note number of tone currently playing

LastDMACon dc.w 0 * last value written to dmacon



 ifne WantAdept
PlayerXPos ds.w 1 * for convenience only - a copy of the player's 
PlayerYPos ds.w 1 * normal sprite block entries 
 
SpriteTable 
SpriteCurrentInfo 
; Space for temporary values for missiles/players etc. 
 
InfoPtrOffset equ *-SpriteCurrentInfo 
 dc.l 0 * ptr to permament sprite info for this sprite 
* (must be the first entry) 
 
XSpeedOffset equ *-SpriteCurrentInfo 
 dc.w 0 ; Current X Speed 
 
YSpeedOffset equ *-SpriteCurrentInfo 
 dc.w 0 ; Current Y Speed 
 
XPosOffset equ *-SpriteCurrentInfo 
;PlayerXPos 
	 ds.w 1 
 
YPosOffset equ *-SpriteCurrentInfo 
;PlayerYPos 
	 ds.w 1 
 
DataPtrOffset equ *-SpriteCurrentInfo 
 ds.l 1 * ptr to currently displayed bit pattern 
 
NextPtrOffset equ *-SpriteCurrentInfo 
 ds.l 1 * ptr to next entry in sprite table 
 
LastPtrOffset equ *-SpriteCurrentInfo 
 ds.l 1 * ptr to last entry in sprite table 
 
NameOffset equ *-SpriteCurrentInfo 
 ds.w 1 * the 'name' of the monster. 
* This is equal to the sprite number for ordinary monsters. For humans, 
* and if we allow players to christen monsters, this will change. 
* Its purpose is to allow the special case handlers to distinguish 
* between monsters with the same fixed data blocks. 
 
HitPointOffset equ *-SpriteCurrentInfo 
 ds.w 1 * the number of hit points remaining for the monster 
 
BlowStrengthOffset equ *-SpriteCurrentInfo 
 ds.w 1 * number of hit points of damage done by blows. 
 
TimeToNextBlowOffset equ *-SpriteCurrentInfo 
 ds.b 1 
 
ViewOffset equ *-SpriteCurrentInfo 
;PlayerView 
	 ds.b 1 
 
StageOffset equ *-SpriteCurrentInfo 
;PlayerAnimationStage 
 ds.b 1 
 
NullMovesMadeOffset equ *-SpriteCurrentInfo 
;PlayerNullMovesMade 
 ds.b 1 
 
OnScreenOffset equ *-SpriteCurrentInfo 
;PlayerOnScreenFlag 
  ds.b 1 
 
DistanceOffset equ *-SpriteCurrentInfo 
;PlayerDistanceTravelled 
 ds.b 1 
 
LifeCounterOffset equ *-SpriteCurrentInfo 
 ds.b 1 * counts down until 0, when sprite self-destructs 
 
AddDirOffset equ *-SpriteCurrentInfo 
 ds.b 1 * adds to view when sprite trying to unblock itself 
 
AnimationOffset equ *-SpriteCurrentInfo 
 
;***** GRAHAM 
 ds.w 1 
 
WealthOffset equ *-SpriteCurrentInfo 
 ds.w 1 * gold pieces owned by, e.g. a leprechaun 
 
SourceWeaponOffset equ *-SpriteCurrentInfo 
 ds.b 1 * source of missiles (i.e. wand type) 
 
MagicOffset equ *-SpriteCurrentInfo 
 ds.b 1 * 8 bit +/- 5 magic adjustment 
 
CursedOffset equ *-SpriteCurrentInfo 
 ds.b 1 * set if cursed 
 
SlowCounterOffset equ *-SpriteCurrentInfo 
 ds.b 1 * set when monster cursed with slowness 
 
RunAwayOffset equ *-SpriteCurrentInfo 
 ds.b 1 * countdown while monster is running away 
;***** 
 
SpriteNumberOffset equ *-SpriteCurrentInfo 
 ds.b 1 * number of sprite used.# 
 
 
SpriteCurrent1End 
SpriteCurrentSize equ 48 * SpriteCurrent1End-SpriteCurrentInfo 
 
 
; data for missiles etc (set up at runtime)... 
; It is in the same format as the above, and uses the same offsets 
 
 even 
MaxMovingSprites equ 75 
 ds.b SpriteCurrentSize*(MaxMovingSprites+1) 
 endc
 
EndSpriteTable 
;--- 
 even 
LongWorkspace 
;Long workspace.... 
AcodeFns ds.l 1 * offset 0 
MCFns ds.l 1 * offset 4 
RandomSeed ds.l 1 * offset 8 
 
LogicalBase * offset 12 
 ds.l 1 * holds address 8 less than the real physical base 
* to allow the leftmost 16 pels to be clipped in an elegant fashion 
 
PhysicalBase * offset 16 
 ds.l 1 * holds address of currently displayed screen 
 
OSScreenAddress * offset 20 
 ds.l 1 * screen address when game started 
 
TextScreenBase ds.l 1 * offset 24 
 
CurrentTaskMTCBOffset dc.l 0 * should probably keep as dc.l offset 28 
NextTaskMTCBOffset dc.l 0 * should probably keep as dc.l offset 32 
MTCB ds.l 16 * allow for 16 concurrent tasks. offset 36 
 
FrameCounter * offset 100 
 ds.l 1 
 
YFineScroll ds.l 1 * offset 104 
 
SpriteDataPtr ds.l 1 * offset 108 
 
comp_MasksPtr ds.l 1 * offset 112 
comp_cellsPtr ds.l 1 * offset 116 
 
SpriteTPtr ds.l 1 * offset 120 
 
FreeWorkSpace ds.l 1 * pointer to next unused area of memory 
* offset 124 
 
SBStart ds.l	1	* offset 128 
 
MapGraphicsPtrs 
MapGraphicsPtr ds.l 1 * 132 (N/U) 
MapGraphicsPtr2 ds.l 1 * 136 (N/U) 
MapGraphicsPtr3 ds.l 1 * 140 (N/U) 
MapGraphicsPtr4 ds.l 1 * 144 (N/U) 
CurrentMapGraphicsPtr ds.l 1 * 148 (N/U) 
MapLayoutPtr ds.l 1 * offset 152 
LongMCStart ds.l 1 * offset 156 
 
GraphicsScreenBase ds.l 1 * offset 160 
 
TextBufferOffset ds.l 1 * offset 164 

InitialFreeMemory ds.l 1  * offset 168 - debugging only
 
* There are 8 ScrolledLayoutPtrs because the order of sprites 
* is scrambled compared to the original - MapLayoutPtr 
* Therefore these 8 copies are made which are cycled through instead 
* The only difference between them is that they have different 
* sprite values for the cyclical blocks 
ScrolledLayoutPtr ds.l 1 
ScrolledLP2 ds.l 1 
ScrolledLP3 ds.l 1 
ScrolledLP4 ds.l 1 
ScrolledLP5 ds.l 1 
ScrolledLP6 ds.l 1 
ScrolledLP7 ds.l 1 
ScrolledLP8 ds.l 1 
 
SupervisorStack ds.l 1 
 
PalettePtr ds.l 1 
 
CyclicOffset ds.l 1 
 
 
 
LastTime ds.l 1 
 
DestroyedWallPtr ds.l 1 
 
;; Player1SpriteBlock ds.l 1 
 
HiUsedMemory ds.l 1 
 
IgnoreBlock ds.l 1 
 
 
OSVblHandler ds.l 1 * pointer to os vbl handler 
OSHblHandler ds.l 1 * pointer to os hbl handler 
OSTrap13Vec ds.l 1 * pointer to os TRAP13 handler.
Trap13Errors dc.w 0 * set to non-zero when we want
* bconin and bconout to be prevented.

EndSpriteDataPtr ds.l 1 * primarily for use by Amiga non-vm
 
PreSoundInt_Vec ds.l 1 * value of int_vec before init_snd 

STOS ds.l 1 * set up by keyboardinit to which os we're using
 
Old_Iea	ds.b 1	* Place to save Interrupt enable reg A 
Old_Ima ds.b 1	* Ditto         Interrupt mask A 
Old_IMRB ds.b 1 
Old_IERB ds.b 1 
 
InCh ds.w 1	* Used for Input media choice * 
 
MIMFirst ds.w 1	* Used for checking if 1st time into MIM 
Numspr ds.w 1	* Number of sprites to process with MakeIntoMono routine 
 
FillFlg ds.w 1 	* To see wether or not to fill a block (monomapbuilding) 
FillPat ds.l 1	* the pattern to fill * 
 
 ifne WantMonochrome
pats		 
*0 
		dc.b	0 
		dc.b	0 
* 1 
		dc.b	0 
		dc.b	0 
*2 
		dc.b	0 
		dc.b	0 
*3 
		dc.b	0 
		dc.b	1 
*4 
		dc.b	0 
		dc.b	2 
*5 
		dc.b	2 
		dc.b	0 
*6 
		dc.b	1 
		dc.b	0 
*7 
		dc.b	1 
		dc.b	2 
*8 
		dc.b	2 
		dc.b	1 
*9 
		dc.b	3 
		dc.b	0 
*10 
		dc.b	0 
		dc.b	3 
*11 
		dc.b	3 
		dc.b	1 
*12 
		dc.b	3 
		dc.b	2 
*13 
		dc.b	2 
		dc.b	3 
*14 
		dc.b	3 
		dc.b	3 
*15 
		dc.b	3 
		dc.b	3 
 
 even 
* pre-cursor to divide by 3 table below: to allow the filetype 
* to make the whole picture darker in black and white. 
 dc.b 0,0,0,0 
 dc.b 0,0,0 
 dc.b 0,0,0 
 dc.b 0,0,0 
 dc.b 0,0,0 
DivideBy3 
* actually divide by (49/15)=3.2666 
 dc.b 0,0,0 
 dc.b 1,1,1	* 3 
 dc.b 2,2,2	* 6 
 dc.b 3,3,3	* 9 
 dc.b 4,4,4	* 12 
 dc.b 5,5,5 	* 15 
 dc.b 6,6,6	* 18 
 dc.b 6,7,7	* 21 
 dc.b 7,8,8	* 24 
 dc.b 8,9,9	* 27 
 dc.b 9,9,10	* 30 
 dc.b 10,10,11	* 33 
 dc.b 11,11,12	* 36 
 dc.b 12,12,13	* 39 
 dc.b 13,13,13	* 42 
 dc.b 14,14,14	* 45 
 dc.b 15,15,15	* 48 
 dc.b 15,15,15,15,15,15,15,15 * to allow for picture being made brighter 
 dc.b 15,15,15,15,15,15,15 
 
intens	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
	dc.w 0 
 endc * WantMonochrome 
 
 
SaveA0 ds.l 1 
savea1 ds.l 1 
SaveA2 ds.l 1 
SaveA3 ds.l 1 
SaveA4 ds.l 1 
SaveA5 ds.l 1 
SaveA6 ds.l 1 
Saved0 ds.l 1 
Saved1 ds.l 1 
Saved2 ds.l 1 
Saved3 ds.l 1 
Saved4 ds.l 1 
Saved5 ds.l 1 
Saved6 ds.l 1 
Saved7 ds.l 1 
 
 
SaveLast ds.l 1 
SaveNext ds.l 1 
 
EndUserMemory ds.l 1 
 
EndFreeMemory ds.l 1 
 
;; VarTablePtr ds.l 1 
ListAreaPtr ds.l 1 

StartFilePtr ds.l 1 * introduced for Amiga
;--- 
WordWorkspace 
;Wordwise workspace... 
CursorXPos ds.w 1 * must be first entry in word list (used by acode) 
CursorYPos ds.w 1 * must be second entry. Offset 2 
FrameTime ds.w 1 * third entry. Offset 4 
Player1SpriteOffset ds.w 1 * offset of player sprite block within 
; spriteTable * offset 6 
 
ScreenXPos ds.w 1 * offset 8 
ScreenYPos ds.w 1 * offset 10 
ScreenXMax ds.w 1 * offset 12 
ScreenYMax ds.w 1 * offset 14 
PlayerXMax ds.w 1 * offset 16 
PlayerYMax ds.w 1 * offset 18 
 
ScreenXBlocks ds.w 1 * offset 20 
ScreenYBlocks ds.w 1 * offset 22 
 
XPosSave ds.w 1 * offset 24 
YPosSave ds.w 1 * offset 26 
 
*>>Mike 27/5/89 TextBufferOffset ds.w 1 * offset 28 - used in oswrch to buffer 
 ds.w 1 * now dummy to avoid changing later offsets 
 
FreeSprites ds.w 1 * offset 30 
 
MouseDistances ds.w 2 * x,y distances offset 32,34 
 
SuspendTaskSwap ds.w 1 * offset 36 
 
UseVm ds.w 1 * offset 38 - set to 1 if 3d plotting should use vm 
 
VBLDisabled ds.w 1 * offset 40 - set to 1 to disable VBL 
 
TextOffset ds.w 1 
 
AniHeader ds.w 1 * offset 44 
 
xcord:	dc.w	0	* x_cord offset 46 
zcord:	dc.w	0	* z_cord offset 48 
hcord:	dc.w	0	* h_cord offset 50 
yCell:	dc.w	0	* lo-res y cord offset 52 
ypos:	dc.w	0	* hi_res y cord offset 54 
 
RasterOffset ds.w 1	* value to add on to all raster blocks displayed. Offset 56 
snd_len:	dc.w	0	* sound length still to play. Offset 58. 
 
zangle		dc.w	0 * offset 60 
xangle		dc.w	0 * offset 62 
yangle		dc.w	0 * offset 64 
 
WordErrorNumber dc.w	0 * offset 66 
 
TimeSinceVBL ds.w 1 
 
SIXspeed ds.w 1 
SIYSpeed ds.w 1 
SIStepsToGo ds.w 1 
SIYStepsToGo ds.w 1 
 
DAMSLoopCounter ds.w 1 
 
 
NumDestroyedWalls ds.w 1 
 
 
TempNameStorage ds.w 1 
 
 
;--- 
ByteWorkspace 
; Bytewise workspace... 
JoystickStatus ds.b 1 * must be first entry in ByteWS 
 
LastKeyPressed ds.b 1 * must be second entry in ByteWS 
 
;FrameReady 
 ds.b 1 * set to 1 when LogicalBase is ready for display. 
;* must be third entry in ByteWS 
 
ByteInvertFlag ds.b 1 * set to 1 to invert text. 4th entry 
 
BreakPointArmed ds.b 1 * For Debugging. 5th entry 
 
ScrollStep ds.b 1 * size of screen movements. 6th entry 
 
CurrentWeapon ds.b 1 * weapon type. 0=normal,1=digging, 2=explosive. 7th entry 
 
LineCleared ds.b 1 * offset 7 
PageSwapped ds.b 1 * offset 8 
 
FrameReady ds.b 1 * set to 1 when LogicalBase is ready for display. 
* must be offset 9 
 
TempStarPhase ds.b 1 * offset 10 
 
width ds.b 1 * offset 11: word-wrap width 
 
DoingPseudoFlip ds.b 1 * offset 12(NU) 
 
PseudoFlipDirection ds.b 1 * offset 13(NU) 
 
TextSmoothScroll ds.b 1 * offset 14(NU) 
 
FireButtonHeld ds.b 1 * offset 15(NU) 
 
StillNeedToSwapScreen ds.b 1 * offset 16(NU) 
 
DoYRangeKill ds.b 1 * offset 17(NU) 
 
TimeToNextShot ds.b 1 * offset 18(NU) 
 
ScreenResolution ds.b 1 * offset 19(NU) 
 
CDDirection ds.b 1 * offset 20(NU) 
 
SourceWeapon ds.b 1 ;***** GRAHAM 21 
 
SpecialMissile ds.b 1 ;***** GRAHAM22 
 
TrueJoystickStatus ds.b 1 * 23 
 
PlayerSpeed ds.b 1 * 24 
 
OutputDevice dc.b 2 * 25. By default, send to screen. (please 
; leave as dc.b 2) 
 
;--- 
 even 
;; TextBuffer ds.b 256 * used to decompress text into 
 
 ifne ST
VectorSaveTable 
* used to save kbd processor jump table 
 ds.b 40 * 32 bytes are used 
 endc
 
MaxDestroyedWalls equ 100 
;--- 
LRTable 
; table giving left-right bit reversal of all byte-sized bit 
; patterns. Note that each entry is a word, the low-order 
; being null. This avoids the need for shifting when the destination 
; is the high-order byte of a word 
;>>Mike15/6/89 - now overlaps with stack. ds.w 256 
LRTableEnd equ LRTable+512 
 
 even 
; ifne Amiga
;  ds.b 1500 * Operating system can use >>1K for Opening files
;* etc.
; endc
 ifne ST
 ds.b 500
 ds.b 512 ; used for system stack as well - so need plenty of space 
 endc
HeroStack 
 ds.l 2 * make sure ws doesn't clash with stack.
;--- 
 ifne ST * on Amiga, these are allocated dynamically
; interpreter workspace.... 
WorkSpaceStart 
;vartable 
* must be on even word boundary 
;listarea equ WorkSpaceStart+512 
ListAreaSize equ 1000 *****reduce memory usage. 4000 ; >>Mike15/6/89 30000 
WorkSpaceEnd equ WorkSpaceStart+ListAreaSize+512 
InputDebugBlock equ WorkSpaceEnd 
* this is used to store input keywoard values 
* 32 bytes per keyword entered, so 1K = 32 keywords 
IntWorkSpaceEnd equ InputDebugBlock ;>>mike 15/6/89+128 **** necessary? 
IntWorkSpaceSize equ IntWorkSpaceEnd-WorkSpaceStart 
 endc * ST
;--- 
;=========
 ifne Amiga
;; bss
VBLNextInterrupt dc.l 0
KBDNextInterrupt dc.l 0
KBDReadPtr dc.w 0 * read offset for keyboard circular buffer
KBDFreeSpacePtr dc.w 0 * write ptr offset
KBDCharsInBuffer dc.w 0
KBDBuffer dc.b 64

HandlerStuff
 ds.b 32

InputRequestBlock
 ds.b 32

;InterruptHandlerBlock
; ds.l 1 * is_data
; ds.l 1 * is_code
;IS_NODE equ *-InterruptHandlerBlock
; ds.l 1 * node ptr (?)
; ds.b 32 * for security
 even

MikeMatrix ds.b 128 * keyboard matrix

MikeInputEventHandlerData

MikeBuffer ds.b MikeBufferSize

AmigaSP ds.l 1

 endc * end of amiga-specific

 ifne AmigaCellGrouping
SizeCellGroupTable equ 150*12 * in bytes
 endc

SizePreLoadTable dc.w 0

 ifeq AmigaCellGrouping
SizeCellGroupTable equ 0 * in bytes
 endc
CellGroupFreeEntry dc.l 0
CellGroupTable dc.l 0

;=========

;MikeScreen
; ds.b 40000

 
;; Transient workspace - loaded from data files etc 
 ifne ST 
WS equ IntWorkSpaceEnd ;>>Mike15/6/89 +4000 
 
; Transient workspace - loaded from data files etc 
StartFile equ WS 
 endc * ST
