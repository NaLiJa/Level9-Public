; RAM.S - alll Hero Workspace
;
; Copyright (C) 1988 Level 9 COmputing
;
; M.J.Austin 1987/1988
;
 even
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




SpriteCurrent1End
SpriteCurrentSize equ 48 * SpriteCurrent1End-SpriteCurrentInfo


; data for missiles etc (set up at runtime)...
; It is in the same format as the above, and uses the same offsets

 even
MaxMovingSprites equ 75
 ds.b SpriteCurrentSize*(MaxMovingSprites+1)

EndSpriteTable
;---
LongWorkspace
;Long workspace....
 even

AcodeFns ds.l 1 * offset 0
MCFns ds.l 1 * offset 4
RandomSeed ds.l 1 * offset 8

LogicalBase
 ds.l 1 * holds address 8 less than the real physical base
* to allow the leftmost 16 pels to be clipped in an elegant fashion

PhysicalBase ds.l 1 * holds address of currently displayed screen

OSScreenAddress ds.l 1 * screen address when game started

FrameCounter
 ds.l 1

YFineScroll ds.l 1

SpriteDataPtr ds.l 1

MapGraphicsPtrs
MapGraphicsPtr ds.l 1
MapGraphicsPtr2 ds.l 1
MapGraphicsPtr3 ds.l 1
MapGraphicsPtr4 ds.l 1

CurrentMapGraphicsPtr ds.l 1

MapLayoutPtr ds.l 1

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


SpriteTPtr ds.l 1

LastTime ds.l 1

DestroyedWallPtr ds.l 1

;; Player1SpriteBlock ds.l 1

HiUsedMemory ds.l 1

IgnoreBlock ds.l 1

FreeWorkSpace ds.l 1 * pointer to next unused area of memory

OSVblHandler ds.l 1 * pointer to os vbl handler
OSHblHandler ds.l 1 * pointer to os hbl handler

Old_Iea	ds.b 1	* Place to save Interrupt enable reg A
Old_Ima ds.b 1	* Ditto         Interrupt mask A

InCh ds.w 1	* Used for Input media choice *

MIMFirst ds.w 1	* Used for checking if 1st time into MIM
Numspr ds.w 1	* Number of sprites to process with MakeIntoMono routine

FillFlg ds.w 1 	* To see wether or not to fill a block (monomapbuilding)
FillPat ds.l 1	* the pattern to fill *

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
TextBufferOffset ds.w 1 * offset 28 - used in oswrch to buffer
FreeSprites ds.w 1 * offset 30

MouseDistances ds.w 2 * x,y distances offset 32,34

TextOffset ds.w 1

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

;; StarCounter ds.b 1


DoingPseudoFlip ds.b 1

PseudoFlipDirection ds.b 1

TextSmoothScroll ds.b 1

;; TempStarPhase ds.b 1

FireButtonHeld ds.b 1

;; ScrollStep ds.b 1

StillNeedToSwapScreen ds.b 1

DoYRangeKill ds.b 1

;;CurrentWeapon ds.b 1

;;BreakPointArmed ds.b 1

TimeToNextShot ds.b 1

ScreenResolution ds.b 1

CDDirection ds.b 1

SourceWeapon ds.b 1 ;***** GRAHAM

SpecialMissile ds.b 1 ;***** GRAHAM


;---
 even
TextBuffer ds.b 256 * used to decompress text into

VectorSaveTable
* used to save kbd processor jump table
 ds.b 40 * 32 bytes are used

;;TextBuffer ds.b 120 * 40 bytes are used

LRTable
; table giving left-right bit reversal of all byte-sized bit
; patterns. Note that each entry is a word, the low-order
; being null. This avoids the need for shifting when the destination
; is the high-order byte of a word
 ds.w 256
LRTableEnd




MaxDestroyedWalls equ 100
;DestroyedWallSpace
; ds.b 5000 * temporary space
;---
 even

 ds.b 512 ; used for system stack as well - so need plenty of space
HeroStack
;---
; interpreter workspace....
workspacestart
vartable
* must be on even word boundary
listarea equ WorkSpaceStart+512
ListAreaSize equ 30000 ; 14000 ; 10000
workspaceend equ WorkSpaceStart+ListAreaSize+512
inputdebugblock equ WorkSpaceEnd
* this is used to store input keywoard values
* 32 bytes per keyword entered, so 1K = 32 keywords
IntWorkSpaceEnd equ InputDebugBlock+128 **** necessary?
IntWorkSpaceSize equ IntWorkSpaceEnd-WorkSpaceStart
;---

;; Transient workspace - loaded from data files etc
;StartFile equ IntWorkSpaceEnd+4000

WS equ IntWorkSpaceEnd+4000
;; workspace for 3D+structure handler
g_map equ WS+0	;ds.b	map_cells*4 	* ground cell map
links equ g_map+map_cells*4 ;	ds.b	10240-map_cells*4	* link list area
v_map equ links+10240-map_cells*4 ;:	ds.b	map_cells*2 	* view map area

; Transient workspace - loaded from data files etc
;WorkSpace equ v_map+map_cells*2    ;IntWorkSpaceEnd
;StartFile equ WorkSpace
StartFile equ v_map+map_cells*2    ;IntWorkSpaceEnd

