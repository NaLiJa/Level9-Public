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
ScrollingSystem equ 0 * set to 1 for scrolling system.

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

;ST equ 0
;Amiga equ 1
ST equ 0
Amiga equ 1
IncludeVector equ 0 * only possible on ST, set to 1 to include
; the vector graphics demo etc.

