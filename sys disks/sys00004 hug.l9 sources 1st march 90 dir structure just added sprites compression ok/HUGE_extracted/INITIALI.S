; Hero initialization code... 
; 
; Copyright (C) 1988 Level 9 Computing 
;  
; M.J.Austin 1987/1988. 
 
;--- 
;LoadAndDisplayTitleScreen 
; move.l FreeWorkSpace-S(a5),a0 
; lea LoadTitleScreenDriverBlock-S(a5),a6 
; bsr MakeA0Even 
; move.l a0,(a6) 
; bsr LoadFile 
; move.l (a6),a0 * start of screen just loaded 
; add.l #$1c,a0 
; move.l LogicalBase-S(a5),a1 
; add.l #8,a1 * allow for 8 pel offset of physical screen from logical scre 
; move.w #200,d0 * number of screen lines 
; 
; move.b ScreenResolution,d1 
; cmp.b #2,d1 
; beq.s MonoLADTS0 
; 
;LADTS1 
;* display a single scan-line's worth ($28 bytes) 
; add.l #160-$28,a1 * move along to right place for display 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; move.l (a0)+,(a1)+ 
; dbra d0,LADTS1 
;* and copy screen to the alternate page 
; move.l LogicalBase-S(a5),a0 
; move.l PhysicalBase-S(a5),a1 
; move.w #200*160/4,d0 
;LADTS2 
; move.l (a0)+,(a1)+ 
; dbra d0,LADTS2 
; rts 
;;----- 
;Double4Bits macro 
; roxl.w #1,d0 
; roxl.l #1,d1 
; asl.l #1,d1 
; roxl.w #1,d0 
; roxl.l #1,d1 
; asl.l #1,d1 
; roxl.w #1,d0 
; roxl.l #1,d1 
; asl.l #1,d1 
; roxl.w #1,d0 
; roxl.l #1,d1 
; asl.l #1,d1 
; endm 
; 
;MonoTitleMacro macro 
; move.w (a0),d0 
;* double all bits in d0.w to give d1.l 
; Double4Bits 
; Double4Bits 
; Double4Bits 
; Double4Bits 
; 
;* now d1.l has double-spaced, single bits 
; move.l d1,d0 
; lsr.l #1,d0 * copy and shift 
; or.l d1,d0 * give double-spaced, double bits 
; swap d0 
; move.w d0,(a1)+ 
; swap d0 
; move.w d0,(a1)+ 
;; move.w #0,(a1)+ 
;; move.w (a0),76(a1) 
;; move.w (a0),78(a1) 
; add.l #8,a0 
; endm 
; 
;MonoLADTS0 
; subq.l #4,a1 
; move.w d0,d2 * loop counter 
; 
;MonoLADTS1 
;* display a single scan-line's worth ($14 bytes) 
; add.l #160-20,a1 * move along to right place for display 
; 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; 
; add.l #160-20,a1 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; MonoTitleMacro 
; 
; dbra d2,MonoLADTS1 
;* and copy screen to the alternate page 
; move.l LogicalBase-S(a5),a0 
; move.l PhysicalBase-S(a5),a1 
; move.w #200*160/4,d0 
;MonoLADTS2 
; move.l (a0)+,(a1)+ 
; dbra d0,MonoLADTS2 
; rts 
; 
;----- 
;MCLoadSprites 
; move.l FreeWorkSpace-S(A5),a0 
; bsr MakeA0Even 
; lea LoadPlaySprDriverBlock-S(a5),a6 
; move.l a0,(a6) 
; bsr LoadFile 
; move.l (a6),a0 ; set a0.l = start of sprite data just loaded 
; lea SpriteDataPtr-S(a5),a1 
; move.l a0,(a1) ; start of sprite data 
; move.l $4(a6),a0 * free space for next load 
; lea FreeWorkSpace-S(A5),a1 
; move.l a0,(a1) 
; 	 
;	Cmp.b #2,ScreenResolution-S(a5) 
;	Bne JmpMonoExpand 
; 
;	Movem.l d0-d7/a0-a6,-(sp) 
;	Bsr GetIntens 
;	Movem.l (sp)+,d0-d7/a0-a6 
; 
;	Movem.l d0-d7/a0-a6,-(sp) 
;	Bsr MonoExpandSprites 
;	Movem.l (sp)+,d0-d7/a0-a6 
; 
;JmpMonoExpand 
; rts 
 
;----- 
LoadDataFiles 
; bsr LoadAndDisplayTitleScreen * load in title screen 
 ifne Amiga
  rts
 endc


 ifne 0 * ST 
  lea LoadMapGraphicsDriverBlock-S(a5),a6 
  move.l FreeWorkSpace-S(a5),a0 ; first free area (after gamedata etc.) 
  bsr MakeA0Even 
  move.l a0,(a6) 
  bsr LoadFile 
  move.l (a6),a0 ; set a0.l = start of map graphics just loaded 
  lea MapGraphicsPtr-S(a5),a1 
  move.l a0,(a1) ; start of map area 
  move.l $4(a6),a0 * free space for next load 
 
 
 bsr MakeA0Even 
; lea LoadMapLayoutDriverBlock-S(a5),a6 
; move.l a0,(a6) 
; bsr LoadFile 
; move.l (a6),a0 ; set a0.l = start of map graphics just loaded 
; add.l #$1c,a0 ; skip over header put on sprite file by GENST 
; move.l a0,a1 
; move.l $4(a6),a0 * free space 
; bsr MakeA0Even 
; lea MapLayoutPtr-S(a5),a2 
; move.l a0,(a2) ; start of copied map layout data 
;* copy map layout to free space + convert to word format 
; move.l a0,d0 
; sub.l a1,d0 * find length in d0.l 
;CopyMapLoop 
; clr.l d1 
; move.b (a1)+,d1 
; bpl.s CopyMap1 
;* Set bit 15 to indicate cyclic - 128..255 remains range 
;* of cyclic sprites so bit 7 remains set 
; or.w #$8000,d1 
;CopyMap1 
; move.w d1,(a0)+ 
; dbra d0,CopyMapLoop 
;* a0.l = free space for next load 
; move.l a0,DestroyedWallPtr-S(A5) 
; clr.w (a0) * zero first table entry 
; add.l #5000,a0 
; 
; 
;; bsr PreScrollMap 
;; dc.w $4afa 
;; move.l FreeWorkSpace-S(A5),a0 ****** 
;; move.l HiUsedMemory-S(A5),a0 ******* 
 move.l a0,FreeWorkSpace-S(A5) 
 endc * ST
 rts 
;--- 
 
