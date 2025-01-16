* 
* Routines To Handle Collision Detection Between Sprites and Background 
* 
* Copyright (c) 1987 By Level 9 Computing. All Rights Reserved. 
* 9 Mendip Road, Crown Wood, Bracknell, Berkshire RG12 3XG - (0344) 487597 
* 
MaxWalkableBlock equ 31 * max map square things can go onto 
 
BreakIfArmed 
 movem.l d0/a0,-(sp) 
 move.b BreakPointArmed-S(a5),d0 
 beq.s BIAEnd 
 lea BreakPointArmed-S(a5),a0 
 dc.w $4afa 
 clr.b (a0) 
 
BIAEnd 
 movem.l (sp)+,d0/a0 
 rts  
;---- 
CheckPlayerMove 
* see if player can move by offset X=D4.W Y=D5.W 
* and make any move possible 
;; move.l Player1SpriteBlock-S(a5),a6 
 clr.l d0 
 move.w Player1SpriteOffset-S(A5),d0 
;>>mike 27/12/88 lea SpriteTable-S(A5),a6 
 move.l List28Ptr-S(A5),a6 
 add.l d0,a6 
 
 move.l (a6),a4 
; lea PlayerSDS,a4 * fixed data block for player 
 
; Set up Appropriate view of player 
 clr.l d0 
 move.b JoystickStatus-S(a5),d0 
 and.b #$f,d0 
 beq.s NoViewChange 
 lea ViewConversionTable-S(a5),a0 
 add.l d0,a0 
; lea PlayerView,a1 
; move.b (a0),(a1) 
 move.b (a0),ViewOffset(a6) 
 
NoViewChange 
; lea PlayerXSpeed,a0 
; clr.w (a0) 
; lea PlayerYSpeed,a0 
; clr.w (a0) 
 clr.w XSpeedOffset(a6) 
 clr.w YSpeedOffset(a6) 
; move.w PlayerXPos,d0 
 move.w XPosOffset(a6),d0 
 add.w d4,d0 
; move.w PlayerYPos,d1 
 move.w YPosOffset(a6),d1 
 add.w d5,d1 
; add.w #4,d1 * add 4 to y position to allow overlap of head over blocks. 
 movem.w d5-d6,-(sp) 
  move.b HeightOffset(a4),d6 * offset of bottom row 
  bsr MapCheck 
 movem.w (sp)+,d5-d6 
 bne CPMMakeMove 
* not possible - was player trying to go diagonally? 
 tst.w d4 
 beq MaybeCushionVertically 
 tst.w d5 
 beq.s MaybeCushionHorizontally 
* yup - so is movement possible in one of the orthogonal directions? 
* x only? 
; move.w PlayerXPos,d0 
 move.w XPosOffset(a6),d0 
 add.w d4,d0 
; move.w PlayerYPos,d1 
 move.w YPosOffset(a6),d1 
; add.w #4,d1 * add 4 to y position to allow overlap of head over blocks. 
 movem.w d5-d6,-(sp) 
  move.b HeightOffset(a4),d6 * offset of bottom row 
  bsr MapCheck 
 movem.w (sp)+,d5-d6 
 beq.s CPMNotHorizontal 
 clr.w d5 
 bra CPMMakeMove 
 
CPMNotHorizontal 
* y only? 
; move.w PlayerXPos,d0 
; move.w PlayerYPos,d1 
 move.w XPosOffset(a6),d0 
 move.w YPosOffset(a6),d1 
 add.w d5,d1 
; add.w #4,d1 * add 4 to y position to allow overlap of head over blocks. 
 movem.w d5-d6,-(sp) 
  move.b HeightOffset(a4),d6 * offset of bottom row 
  bsr MapCheck 
 movem.w (sp)+,d5-d6 
 beq.s CPMNotVertical 
 clr.w d4 
 bra CPMMakeMove 
 
CPMNotVertical 
CPMCantMove 
 clr.w d4 
 clr.w d5 
 rts 
 
MaybeCushionHorizontally 
* trying to move horizontally - try cushioning 
; move.w PlayerXPos,d0 
 move.w XPosOffset(a6),d0 
 add.w d4,d0 
; move.w PlayerYPos,d1 
 move.w YPosOffset(a6),d1 
 add.w #4,d1 * because player sprite is 20 high - i.e. 20-16=4 
 and.w #15,d1 
 cmp.w #10,d1 
 bgt.s NoCushionUp 
 move.w PlayerYPos-S(a5),d1 
; add.w #4,d1 
; and.w #$fff0,d1 
; sub.w d3,d1 
 sub.w #4,d1 * move up one step 
 move.w d1,-(sp) 
 movem.w d5-d6,-(sp) 
  move.b HeightOffset(a4),d6 * offset of bottom row of pels 
  bsr MapCheck 
 movem.w (sp)+,d5-d6 
 move.w (sp)+,d1 
 tst.b d0 
 beq.s CPMCantMove 
 lea PlayerYPos-S(a5),a0 
;; sub.w #4,d1 * take into account head overlap 
 move.w d1,(a0) 
 bra CPMCantMove 
 
NoCushionUp 
 cmp.w #12,d1 
 blt.s NoCushionDown 
; move.w d1,d3 
; move.w PlayerYPos,d1 
 move.w YPosOffset(a6),d1 
 add.w #4,d1 
; and.w #$fff0,d1 
; add.w #16,d1 * move down to align with next 16x16 block 
;; sub.w d3,d1 
 movem.w d1/d5-d6,-(sp) 
 move.b HeightOffset(a4),d6 * offset of bottom row of pels 
 bsr MapCheck 
 movem.w (sp)+,d1/d5-d6 
 tst.b d0 
 beq.s CPMCantMove 
; lea PlayerYPos,a0 
; sub.w #4,d1 * take into account head overlap 
; move.w d1,(a0) 
 move.w d1,YPosOffset(a6) 
 
NoCushionDown 
 bra CPMCantMove * can't move as requested - give up 
 
MaybeCushionVertically 
* trying to move vertically - try cushioning 
; move.w PlayerXPos,d0 
; move.w PlayerYPos,d1 
 move.w XPosOffset(a6),d0 
 move.w YPosOffset(a6),d1 
 add.w d5,d1 
; add.w #4,d1 
 
 and.w #15,d0 
 cmp.w #6,d0 
 bgt.s NoCushionLeft 
; move.w d1,d3 
; move.w PlayerXPos,d0 
 move.w XPosOffset(a6),d0 
;* add.w #4,d0 
 and.w #$fff0,d0 
 movem.w d0/d5-d6,-(sp) 
 move.b HeightOffset(a4),d6 * offset of bottom row of pels 
 bsr MapCheck 
 movem.w (sp)+,d3/d5-d6 * actually x co-ordinate 
 tst.b d0 
 beq CPMCantMove 
; lea PlayerXPos,a0 
; move.w d3,(a0) 
 move.w d3,XPosOffset(a6) 
 bra CPMCantMove 
 
NoCushionLeft 
 cmp.w #12,d0 
 blt.s NoCushionRight 
; move.w PlayerXPos,d0 
 move.w XPosOffset(a6),d0 
;* add.w #4,d0 
 and.w #$fff0,d0 
 add.w #16,d0 
 movem.w d0/d5-d6,-(sp) 
 move.b HeightOffset(a4),d6 * offset of bottom row of pels 
 bsr MapCheck 
 movem.w (sp)+,d3/d5-d6 * actually x co-ordinate 
 tst.b d0 
 beq CPMCantMove 
; lea PlayerXPos,a0 
; move.w d3,(a0) 
 move.w d3,XPosOffset(a6) 
 
NoCushionRight 
 bra CPMCantMove * can't move as requested - give up 
 
 
CPMMakeMove 
; make move 
; Return d4=xspeed and d5=yspeed 
 rts 
;---------- 
CPMFinishMove 
 
;; move.l Player1SpriteBlock-S(a5),a6 
 clr.l d0 
 move.w Player1SpriteOffset-S(A5),d0 
;>>mike 27/12/88 lea SpriteTable-S(A5),a6 
 move.l List28Ptr-S(A5),a6 
 add.l d0,a6 
 
 
; move.l (a6),a4 
 move.w d4,XSpeedOffset(a6) 
 move.w d5,YSpeedOffset(a6) 
; animate if the player is moving... 
; move.b StageOffset(a6),d1 
; tst.w d4 
; bne.s CPMAni 
; tst.w d5 
; beq.s CPMNoAni * don't animate if not moving 
;CPMAni 
; addq.b #1,d1 
; 
;CPMNoAni 
; cmp.b NumAnimationOffset(a4),d1 
; ble.s CPM1 
; clr.b d1 
; 
;CPM1 
; move.b d1,StageOffset(a6) 
 rts 
 
 
*    A routine which will determine whether a 16x16 sprite is occupying a part 
*    of the map which is defined to be a wall.  If it is TRUE will be returned, 
*    otherwise FALSE. 
* 
*         (int) return = MapCheck(XPos, YPos, Height, Map); 
*                 D0               D0    D1     D6.b   A0 
* d6.b is actually the offset of the bottom row of pels 
* (in steps of 1 pel. Thus for a 16pel high monster, d6=$0f) 
* 
*    RETURN VALUE: TRUE if on a wall pattern, FALSE if not 
* Returns: (A0.L), 2(a0.L), 0(a0,d6) and 2(a0,d6) as the relevant  
* entries in the map layout 
 
MapCheck: 
 
*    Variable Initializing... 
 
 clr.w d5 
 move.b HeadOverlapOffset(a4),d5 
 add.w d5,d1 * increase y pos to allow for overlap 
 sub.b HeadOverlapOffset(a4),d6 * reduce height by same 
          move.w    D1,d5           (4) copy YPos into d5 
          andi.l    #15,D1         (16) get the RelYPos 
          add.b     d6,D1           (4) add the Height to RelYPos 
          lsr.w     #4,d5          (14) divide YPos by 16 
          move.w    ScreenXBlocks-S(a5),d6         (8) get the XSize of the Map 
 asl.w #1,d6 * map entries are word sized 
          mulu      d6,d5  (<70) get the Y displacement 
          ext.l     d6              (4) extend d6 to size long 
	  move.l MapLayoutPtr-S(a5),a0 
          add.l     d5,A0           (8) add the Y displacement 
          move.w    D0,d5           (4) copy XPos to d5 
          andi.l    #15,D0         (16) get the RelXPos 
          lsr.w     #3,d5          (14) divide XPos by 16 
* but *2 because map entries are word sized 
 and.w #$fffe,d5 
          ext.l     d5              (4) extend D0 to size long 
          add.l     d5,A0           (8) add XPos to the Map pointer 
 
*    The Actual Test 
MapCheckA0D5 
* check (a0); 2(a0); 0(a0,d6); 2(a0,d6) for blocks less than d5.w 
 
 cmp.w #MaxWalkableBlock,(a0) 
 bcc.s OnWallClearD6 
          tst.b     D0              (4) is RelXPos == 0 ? 
          beq.s     L1           (10/8) YES - branch to L1 
* sprite spills over into next 16x16 along - so check for collision with 
* that. 
 cmp.w #MaxWalkableBlock,2(a0) 
 bcc.s OnWallClearD6 
 
L1 
          cmpi.b    #16,D1          (8) does the sprite extend 
* down onto next row of blocks? 
          blt.s     NotOnWall    (10/8) NO - so no collision 
* (d6.l here is twice ScreenXBlocks) 
 cmp.w #MaxWalkableBlock,0(a0,d6) 
 bcc.s OnWall 
          tst.b     D0              (4) is RelXPos == 0 ? 
          beq.s     NotOnWall    (10/8) YES - branch to 'NotOnWall' 
 cmp.w #MaxWalkableBlock,2(a0,d6) 
 bcs.s NotOnWall 
 bra.s OnWall 
 
OnWallClearD6 
 clr.w d6 
 
OnWall 
	  moveq     #0,D0           (4) set return flag to be false 
          rts                      (16) bye bye ... 
 
NotOnWall 
	  moveq     #1,D0           (4) set return flag to be true 
          rts                      (16) bye bye ... 
;--------- 
SpecialMapCheck 
* we believe there is a collision between the sprite (a6) 
* and the background at 0(a0,d6) or 2(a0,d6) 
 
 move.w XPosOffset(a6),d0 
 move.w YPosOffset(a6),d1 
 move.b HeightOffset(a4),d6 * offset of bottom row of pels 
 bsr MapCheck 
 
* and get address of sprite data... 
; move.l (a6),a4 * address of sprite structure 
* calc address of sprite data 
 clr.w d0 
 move.b ViewOffset(a6),d0 
 asl.w #1,d0 * double to get index into word-wise table 
 clr.l d4 
; move.w MovingAnimationOffset(a4,d0),d4 * get base sprite number for view 
; add.b StageOffset(a6),d4 * add on animation stage 
 move.w AnimationOffset(a4,d0),d4 
 move.l SpriteDataPtr-S(a5),a3 
; asl.l #7,d4 ; mulu #LinesPerSprite*10,d4 
 mulu #LinesPerSprite*8,d4 
 add.l d4,a3 
* now a3.l = pointer to sprite data. 
* We want the transparency mask, which is the 5th word for each 
* line of 16 pels. 
; add.l #8,a3 * get a3 to point to the first transparency mask 
 
* Get the co-ordinates. 
 move.w XPosOffset(a6),d0 
 move.w YPosOffset(a6),d1 
 clr.w d3 
 move.b HeadOverlapOffset(a4),d3 
 add.w d3,d1 
 and.w #15,d0 * get relative positions  
 and.w #15,d1 * from x and y grid. 
 
* we will do two loops which will check for collisions 
* The first loop checks the upper two 16x16 blocks 
* The second loop checks the lower two 16x16 blocks 
 
* For each loop, bits set in d3.w correspond 
* to bits in the sprite which must be transparent (i.e. 1) in 
* the sprite transparency mask. 
 
 clr.w d4 * start loop at top of sprite (but ignore the head overlap) 
 move.b HeadOverlapOffset(a4),d4 
 
* and work out how many lines there are within the current map square. 
* (note that d1, the y offset within the square, gives the start 
* of the area to cd with. The head overlap has already been taken off) 
 move.w #16,d5 
 sub.w d1,d5 
 add.w d4,d5 * and add on to the starting row. 
 clr.w d6 * check upper two map squares to start with 
 
SMCLoop 
 
 movem.l d4-d5,-(sp) 
 
* for blocks 16-31 inclusive, reduce the height of the blocks 
* to allow diagonal fire. 
  move.w #$ffff,d7 * full width block 
  cmp.w #$10,0(a0,d6) 
  bcs.s SMCReduce1 * left block isn't reduced height 
  cmp.w #$20,0(a0,d6) 
  bcs.s SMCReduce2 * left block IS reduced height 
SMCReduce1 
  cmp.w #$10,2(a0,d6) 
  bcs.s SMCReduce3 * left block isn't reduced height 
  cmp.w #$20,0(a0,d6) 
  bcc.s SMCReduce3 * left block isn't reduced height 
SMCReduce2 
* reduce the height of the block 
  move.l #$1ff8,d7 * mask - reduce width of block 
  sub.w #4,d5 * reduce the end point 
  bmi.s SMCMaybeAnother 
  cmp.w d5,d4 
  bge.s SMCMaybeAnother * end point now before start point 
  
SMCReduce3 
* have we gone too far? 
  move.b HeightOffset(a4),d0 
  cmp.b d0,d5 
  ble.s SMCHeightOk 
* have we gone much too far? - in which case we terminate 
  cmp.b d0,d4 * is the start past the height of the sprite? 
  bgt SMCPopNotOnWall 
  move.b d0,d5 * limit end counter to height of sprite. 
 
SMCHeightOk 
  mulu #10,d4 * calculate the byte offset 
  mulu #10,d5 
  move.w XPosOffset(a6),d0 
  and.w #$0f,d0 
  bsr CheckSomeLines 
  beq.s SMCCollision * got a collision 
 
SMCMaybeAnother 
 movem.l (sp)+,d4-d5 
 
 add.w ScreenXBlocks-S(a5),d6 * check lower two map squares 
 add.w ScreenXBlocks-S(a5),d6 * because map is word-based. 
 add.w #1,d5 * increment end pos - because it has already been checked 
 move.w d5,d4 * old end pos becomes new start pos 
 add.w #16,d5 * increase end position for check 
 bra SMCLoop 
 
SMCCollision 
 movem.l (sp)+,d4-d5 
 bra OnWall 
;----- 
SMCPopNotOnWall 
 movem.l (sp)+,d4-d5 
 bra NotOnWall 
;----- 
CheckSomeLines 
* d4.w is the loop counter - giving the index into the sprite 
* data table. 
* d5.w is the end of loop value 
 
* first calculate the bit mask corresponding to the top left 16x16 block 
 clr.w d3 * zero mask 
* cd with upper left block? 
 cmp.w #MaxWalkableBlock,0(a0,d6) 
 bcs.s CSL1 * walkable block 
; move.w #$0ff0,d3 * FFFF,d3 
 move.w d7,d3 * mask - either full width or reduced width 
* introduce d0.w zeros into the mask. These zeros correspond 
* to the amount of the sprite on the RHS that overlaps the next 
* map square along. 
 asl.w d0,d3 * shift mask along by amount corresponding to x offset 
CSL1 
 
* cd with upper right block? 
 cmp.w #MaxWalkableBlock,2(a0,d6) 
 bcs.s CSL2 * walkable block 
* introduce d0.w 1s into the mask. These 1s correspond 
* to the amount of the sprite on the RHS that overlaps the next 
* map square along. 
; move.l #$00000ff0,d7 * ffff,d7 
; d7 is already the unshifted mask for the block - either 0ff0 or ffff 
 asl.l d0,d7 
 swap d7 * bring the high word into the low word. 
 or.w d7,d3 * and bring the ones into the main mask 
 
CSL2 
* now d3.w is the mask. 
* Let's check the data! 
* Go between 0(a3,d4) and 0(a3,d5) 
 
CSLLoop 
 move.w 0(a3,d4),d7 
 not.w d7 
 and.w d3,d7 * mask out irrelevant bits 
 bne SMCOnWall 
 add.w #10,d4 
 cmp.w d5,d4 
 ble.s CSLLoop 
 bra NotOnWall 
 
SMCOnWall 
 bra OnWall 
;--------------------------------- 
CDWithAllSprites 
* on entry: d0.w=new x position, d1.w=new y position 
* a6.l=address of control block, a4.l= fixed data block 
* returns d7.b=1 if OK to move to this position 
* and a0.l as control block for the sprite we hit 
 
* collision detect with all other sprites... 
 move.l a6,IgnoreBlock-S(a5) * a5 * sprite control block to IGNORE 
* what type is the sprite to compare with things? 
* a4.l = start of permament data block for sprite 
 move.b TypeOffset(a4),d6 * remains as type throughout 
 move.b CDFlagsOffset(a4),d5 
* d5.b remains as collision detect flag 
 beq CDWASOk * don't collision detect with anything 
;>>mike 27/12/88 lea SpriteTable-S(A5),a0 
 move.l List28Ptr-S(A5),a0 
 move.w #MaxMovingSprites,d7 
 
 move.w XPosOffset(a6),d0 
 move.w YPosOffset(a6),d1 
; clr.w d4 
; move.b HeadOverlapOffset(a4),d4 
; add.w d4,d1 
* search sprites after current one on screen.... 
 move.l a6,a0 * initial value 
CDWFore1 
 move.l NextPtrOffset(a0),d4 
 beq.s CDWForeEnd 
 move.l d4,a0 
* cd sprite (a0) with sprite (a6) 
* chek y poses of the two sprites... 
* ( ignore head overlap at the present as it will be the same for 
* both sprite) 
 move.w d1,d4 * copy y pos to temporary 
 sub.w YPosOffset(a0),d4 
 bpl.s CDWFore3 
 neg.w d4 
 
CDWFore3 
 cmp.w #13,d4 
 bgt CDWFore1 
* check x poses of the two sprites... 
 move.w d0,d4 * copy x pos to temporary 
 sub.w XPosOffset(a0),d4 
 bpl.s CDWFore2 
 neg.w d4 
CDWFore2 
 cmp.w #13,d4 
 bgt.s CDWFore1 
 
;- 
;* now do more accurate y detect, allowing for head overlap 
; move.w d1,-(sp) * copy y pos to temporary 
; clr.w d4 
; move.b HeadoverlapOffset(a4),d4 
; sub.w YPosOffset(a0),d4 * take off the head overlap 
; neg.w d4 
; sub.w (sp)+,d4 * how far apart are sprites really? 
; bpl.s CMSFore3b 
; neg.w d4 
;CMSFore3b 
; cmp.w #13,d4 
; bgt CDWFore1 
;- 
 
* collision! 
* should we take any notice of it? 
 
 move.l (a0),a1 * get permament data block for sprite 
 move.b TypeOffset(a1),d4 
 and.b d5,d4 * do this collision detect? 
 bne.s CDWForeCollision * yes 
 move.b CDFlagsOffset(a1),d4 
 and.b d6,d4 * check flags other way round... 
 beq.s CDWFore1 * don't bother... 
 
CDWForeCollision 
 movem.l d0-d3/d5-d7,-(sp) 
  bsr FGSpecials 
 movem.l (sp)+,d0-d3/d5-d7 
 tst.w d4 * should be carry on with cd? 
 bne CDWFore1 
 rts * fatal collision - no more checking 
; move.b #0,d7 
; rts * collision! 
*------ 
CDWForeEnd 
* search sprites before current one on screen.... 
 move.l a6,a0 * reset pointer to the current sprite 
CDWBack1 
 move.l LastPtrOffset(a0),d4 
 beq.s CDWBackEnd 
 move.l d4,a0 
* cd sprite (a0) with sprite (a6) 
* check y poses of the two sprites... 
 move.w d1,d4 * copy y pos to temporary 
 sub.w YPosOffset(a0),d4 
 bpl.s CDWBack3 
 neg.w d4 
CDWBack3 
 cmp.w #13,d4 
 bgt CDWBack1 
* check x poses of the two sprites... 
 move.w d0,d4 * copy x pos to temporary 
 sub.w XPosOffset(a0),d4 
 bpl.s CDWBack2 
 neg.w d4 
CDWBack2 
 cmp.w #13,d4 
 bgt.s CDWBack1 
* collision! 
* should we take any notice of it? 
 move.l (a0),a1 * get permament data block for sprite 
 move.b TypeOffset(a1),d4 
 and.b d5,d4 * do this collision detect? 
 bne.s CDWBackCollision * yes 
 move.b CDFlagsOffset(a1),d4 
 and.b d6,d4 * check flags other way round... 
 beq.s CDWBack1 * don't bother... 
 
CDWBackCollision 
 movem.l d0-d3/d5-d7,-(sp) 
  bsr FGSpecials 
 movem.l (sp)+,d0-d3/d5-d7 
 tst.w d4 * should we carry on with cd? 
 bne.s CDWBack1 
 rts * fatal collision - no more checking 
; move.b #0,d7 
; rts * collision! 
*------ 
CDWBackEnd 
 move.b #1,d7 * no collision 
 rts 
 
*------ end of new code... 
 
* The following loop is optimized on the basis that 
* we want to check for collisions between most sprites. 
* There are only a few things which cannot collide - such as missiles 
* with players, and players with each other. These cases are 
* handled after the collision has been detected, to avoid slowing down 
* the rest of the code 
CDWAS1 
 tst.l (a0) 
 beq.s CDWAS2 * this sprite does not exist 
 
* check x poses of the two sprites... 
 move.w d0,d2 * copy x pos to temporary 
 sub.w XPosOffset(a0),d2 
 bpl.s CDWASC1 
 neg.w d2 
CDWASC1 
 cmp.w #13,d2 
 bgt CDWASC3 
* chek y poses of the two sprites... 
 move.w d1,d2 * copy y pos to temporary 
 sub.w YPosOffset(a0),d2 
 bpl.s CDWASC2 
 neg.w d2 
CDWASC2 
 cmp.w #13,d2 
 bgt CDWASC3 
* collision! 
* should we take any notice of it? 
 cmp.l IgnoreBlock-S(a5),a0 * a5 
 beq.s CDWAS2 * ignore the current sprite 
 
 move.l (a0),a1 * get permament data block for sprite 
 move.b TypeOffset(a1),d4 
 and.b d5,d4 * do this collision detect? 
 bne.s CDWAS1a * yes 
 move.b CDFlagsOffset(a1),d4 
 and.b d6,d4 * check flags other way round... 
 beq.s CDWAS2 * don't bother... 
 
CDWAS1a 
 move.b #0,d7 
 rts * collision! 
 
CDWASC3 
* no collision 
 
CDWAS2 
 add.l #SpriteCurrentSize,a0 
 dbra d7,CDWAS1 
 
CDWASOk 
 move.b #1,d7 * ok to move 
 RTS 
*----- 
* 
*         (int) result = BitCheck(Sprite1, Sprite2); 
*                 D0                 A6(a4)      A0(a1) 
*				   temp(fixed) temp(fixed) 
MCSpecialCheck 
 movem.l a3-a6,-(sp) 
  move.l List20Ptr-S(A5),a0 * sprite 1 
  move.l (a0),a1 * fixed data ptr 
  move.l List22Ptr-S(A5),a6 * fixed sprite 
  move.l (a6),a4 * fixed data ptr 
  bsr SpecialCheck 
 movem.l (sp)+,a3-a6 
 move.w d0,2(a4) ; return result of check in V1 
 rts 
 
SpecialCheck: 
;           movem.l   D1-D3/A0-A3,-(SP)   (64) save used registers 
;          addq.l    #2,A0                (8) skip the flags 
;          addq.l    #2,A1                (8) ditto... 
 
*    Determine which sprite is higher on the screen 
          move.w    YposOffset(A6),D2            (12) D2 = Sprite1.YPos 
 clr.w d3 
 move.b HeadOverlapOffset(a4),d3 
 add.w d3,d2 
;          add.w     12(A0),D2           (12) add the HeightSkip 
          move.w    YPosOffset(A0),D3            (12) D3 = Sprite2.YPos 
 clr.w d0 
 move.b HeadOverlapOffset(a1),d0 
 add.w d0,d3 
;          add.w     12(A0),D3           (12) add the HeightSkip 
          cmp.w     D3,D2                (4) is 2.YPos greater than 1.YPos ? 
          ble.s     ld3                (10/8) NO - branch to 'ld3' 
          exg       A6,A0                (6) exchange Sprite1 and Sprite2 
	  exg	    a4,a1 
          exg       D2,D3                (6) exchange 1.YPos and 2.YPos 
 
*    Initialize Sprite.Data pointers 
 
ld3 
* calc a2,a3 as sprite data areas 
* calc address of sprite data 
 clr.w d0 
 move.b ViewOffset(a6),d0 
 asl.w #1,d0 * double to get index into word-wise table 
 clr.l d4 
; move.w MovingAnimationOffset(a4,d0),d4 * get base sprite number for view 
; add.b StageOffset(a6),d4 * add on animation stage 
 move.w AnimationOffset(A4,d0),d4 
 move.l SpriteDataPtr-S(a5),a2 
; asl.l #7,d4 ; mulu #LinesPerSprite*10,d4 
 mulu #LinesPerSprite*8,d4 
 add.l d4,a2 
* now a2.l = pointer to sprite data for sprite 1. 
 
* calc address of sprite data for sprite 2 
 clr.w d0 
 move.b ViewOffset(a0),d0 
 asl.w #1,d0 * double to get index into word-wise table 
; move.w MovingAnimationOffset(a1,d0),d4 * get base sprite number for view 
; clr.l d4 
; add.b StageOffset(a0),d4 * add on animation stage 
 move.w AnimationOffset(a1,d0),d4 
 move.l SpriteDataPtr-S(a5),a3 
; asl.l #7,d4 ; mulu #LinesPerSprite*10,d4 
 mulu #LinesPerSprite*8,d4 
 add.l d4,a3 
* now a3.l = pointer to sprite data. 
 
;        move.l    8(A0),A2            (16) A2 = Sprite1.Data 
;	move.l	(A2),a2 
;        move.l    8(A1),A3            (16) A3 = Sprite2.Data 
;	move.l	(a3),a3 
 
          sub.w     D2,D3                (4) subtract 1.YPos from 2.YPos 
 
 clr.w d2 
 move.b HeightOffset(a4),d2 
;          move.w    (A2),D2              (8) D2 = Sprite1.height 
          sub.w     D3,D2                (4) subtract difference in height 
 clr.w d1 
 move.b HeightOffset(a1),d1 
;          move.w    (A3),D1              (8) D1 = Sprite2.height 
 
 clr.w d0 
 move.b HeadOverlapOffset(a6),d0 
;          move.w    12(A0),D0           (12) D0 = 1.HeightSkip 
          sub.w     D0,D2                (4) subtract 1.HeightSkip from D2 
          add.w     D3,D0                (4) add difference in height 
          mulu      #10,D0              (42) offset in data table 
;          addq.w    #2,D0                (4) skip sprite height register 
          add.l     D0,A2                (8) add the offset to Sprite1.Data 
 
 clr.w d0 
 move.b HeadOverlapOffset(a1),d0 
;          move.w    12(A1),D0           (12) D0 = 2.HeightSkip 
 
* calculate the number of lines which overlap, in d2.w 
          sub.w     D0,D1                (4) subtract2.HeightSkip from D1 
          mulu      #10,D0              (42) offset in data table 
;          addq.w    #2,D0                (4) skip sprite height register 
          add.l     D0,A3                (8) add the offset to Sprite2.Data 
 
          cmp.w     D1,D2                (4) is D2 the smallest number ? 
          ble.s     lc8                (10/8) YES - branch to 'lc8' 
          move.w    D1,D2                (4) D1 is the smallest number 
 
*    Initialize the shift counters 
 
lc8 
;          move.w    (A0),D0              (8) D0 = Sprite1.XPos 
;          move.w    (A1),D1              (8) D1 = Sprite2.XPos 
 tst.w d2 
 beq lc5 * no overlap at all! Therefore no collision 
 
 move.w XPosOffset(a6),d0 
 move.w XPosOffset(a0),d1 
          cmp.w     D0,D1                (4) is 2.XPos greater than 1.XPos ? 
          bgt.s     le1                (10/8) YES - branch to 'le1' 
          sub.w     D1,D0                (4) find the difference 
          moveq     #0,D1                (4) clear D0 (long) 
          bra.s     lc2                  (10) branch to 'lc2' 
 
le1        sub.w     D0,D1                (4) find the difference 
 
 
*    Determine which sprite is furthest to the right 
 
lc2        tst.w     D1                   (4) is D1 == 0 ? 
          beq.s     lc4                (10/8) YES - skip to 'lc4' 
 
*    Sprite2 is furthest to the right... 
 
lc7 
          move.w    8(A2),D0              (8) get the mask for Sprite1 
          not.w     D0                   (4) NOT the 1.mask 
          lsl.l     D1,D0             (8+2n) shift to the left by shift count 
          move.w    8(A3),D3              (8) get the mask for Sprite2 
          not.w     D3                   (4) NOT the 2.mask 
          and.w     D3,D0                (4) AND it with 1.mask 
          not.w     D3                   (4) NOT the 2.mask 
          eor.w     D3,D0                (4) EOR it with the pattern 
          cmp.w     D3,D0                (4) did it change the mask ? 
          bne.s     lc6                (10/8) YES - skip to 'lc6' 
          add.l     #10,A2              (16) next transparency mask for Sprite1 
          add.l     #10,A3              (16) ditto for Sprite2... 
 
          dbf       D2,lc7             (10+4) last line ? 
 
          bra.s     lc5                  (10) no collision! 
 
*    Sprite1 is furthest to the right... 
 
lc4        move.w    8(A3),D1              (8) get the mask for Sprite2 
          not.w     D1                   (4) NOT the mask 
          lsl.l     D0,D1             (8+2n) shift to the left by shift count 
          move.w    8(A2),D3              (8) get the mask for Sprite1 
          not.w     D3                   (4) NOT the 1.mask 
          and.w     D3,D1                (4) AND it with 2.mask 
          not.w     D3                   (4) NOT the 1.mask 
          eor.w     D3,D1                (4) EOR it with the pattern 
          cmp.w     D3,D1                (4) did it change the mask ? 
          bne.s     lc6                (10/8) YES - skip to 'lc6' 
          add.l     #10,A2              (16) next transparency mask for Sprite1 
          add.l     #10,A3              (16) ditto for Sprite2... 
 
          dbf       D2,lc4             (10+4) last line ? 
 
*    FalseExit, use this when there is no collision... 
 
lc5        moveq     #1,D0                (4) set the return register to FALSE 
          rts                           (16) bye bye ... 
 
*    TrueExit, use this when collision has occurred! 
 
lc6        moveq     #0,D0                (4) set the return register to TRUE 
          rts                           (16) bye bye ... 
 
;---- 
CheckForSpriteCollision 
* collision with other sprites? 
 tst.w d2 
 bne.s CFSC1 
 tst.w d3 
 bne CFSC1 
* no movement 
 cmp.w #0,NameOffset(a6) 
 bne CFSCRet * no movement - don't bother checking 
* for player - always check 
 
CFSC1 
 bra CDWithAllSprites * bsr, rts 
 
;  bra NoSpriteCollision  
 
 
;  bne NoSpriteCollision * collision with another sprite? 
;* yes - we collided with sprite having control block (a0.l) 
; move.l (a0),a1 * sprite fixed data block 
; 
;* should the sprite we just moved be destroyed? 
;  move.b CDDestroyedOffset(a4),d5 
;  and.b TypeOffset(a1),d5 * the sprite we collided with. 
;  beq.s NoDestroy1 
;* yup. 
;* first do an accurate check. This is mainly for the benefit 
;* of fast-moving missiles etc. 
; movem.l a0-a6,-(sp) 
;  bsr SpecialCheck 
; movem.l (sp)+,a0-a6 
; tst.b d0 
; bne CFSCRet * no collision 
;* kill the sprite just moved 
; movem.l a0-a1,-(sp) 
;  move.l a6,a0 
;  bsr destroySprite 
; movem.l (sp)+,a0-a1 
; 
;NoDestroy1 
;* should the sprite we collided with be destroyed? 
; move.b CDDestroyedOffset(a1),d5 
; and.b TypeOffset(a4),d5 
; beq.s NoDestroy2 
;* yup. 
; movem.l a0-a1,-(sp) 
;  bsr DestroySprite * kill sprite we collided with 
; movem.l (sp)+,a0-a1 
; 
;NoDestroy2 
;* activate any specials for the sprite we collided with? 
; move.b CDSpecialsOffset(a1),d5 
; and.b TypeOffset(a4),d5 
; beq.s NoSpecials1 
;* yes. 
; exg a0,a6 * swap over so we act on the right sprite. 
; exg a1,a4 
; bsr FGSpecials 
; exg a0,a6 * and restore them. 
; exg a1,a4 
; 
;NoSpecials1 
;* activate any specials for the sprite we just moved? 
; move.b CDSpecialsOffset(a4),d5 
; and.b TypeOffset(a1),d5 
; beq.s NoSpecials2 
; bsr FGSpecials 
; bsr FGSpecialsForMovedSpriteOnly 
; 
;NoSpecials2 
;* should the sprite we just moved be blocked? 
; move.b CDBlockedOffset(a4),d5 
; and.b TypeOffset(a1),d5 
; beq.s SpriteNotBlocked * Collision ? 
;* reset co-ords 
; move.w XPosSave-S(A5),XPosOffset(a6) 
; move.w YPosSave-S(A5),YPosOffset(a6) 
; clr.w d2 * clear x speed 
; clr.w d3 * clear y speed to avoid unnecessary sorting 
; bra FGSpriteCantMove 
; 
;SpriteNotBlocked 
;NoSpriteCollision 
;* sprite can move ok - add to distance travelled, and 
;* if AddDirOffset is set, eventually stop moving in that direction 
; lea DistanceOffset(a6),a0 
; addq.b #1,(a0) 
; move.b AddDirOffset(a6),d4 
; beq.s NSCRet 
; move.b DistanceOffset(a6),d4 
; cmp.b #9,d4 * max distance monster can move in a direction 
;* not directly towards the player without reconsidering. 
; blt.s NSCRet 
; lea AddDirOffset(a6),a0 
; clr.b (a0) * try moving in desired direction again 
;; bra SpriteCantMove * change direction 
; 
NSCRet 
CFSCRet 
 rts ; display normally 
 
;FGExplode 
; 
; movem.l a0-a6,-(sp) 
; move.l (a0),a1 
;  bsr SpecialCheck 
; movem.l (sp)+,a0-a6 
; tst.b d0 
; bne.s NSCRet * no collision 
; 
;* now replace the sprite we ran into with an explosion 
;  bsr HandleFGExplosion 
;* kill the sprite just moved 
; move.l a6,a0 
; bra destroySprite 
;----- 
;FGSpriteCantMove 
; sprite (a6) was blocked from moving in the direction it intended to 
; Change the direction of moving 
; Unless it is fighting the player 
; What was the sprite we were blocked by? 
; move.l (a0),a1 
; move.b TypeOffset(a1),d4 
; cmp.b #1,d4 * Player type 
; beq.s SCMRet 
 
; move.b InCombatOffset(a6),d4 
; bne.s SCMRet 
 
;BGSpriteCantMove 
; Unless it is really close to the player 
; move.w XPosOffset(a6),d4 
; sub.w PlayerXPos,d4 
; bpl.s SCM1 
; neg.w d4 
; 
;SCM1 
; move.w YPosOffset(a6),d5 
; sub.w PlayerYPos,d5 
; bpl.s SCM2 
; neg.w d5 
; 
;SCM2 
;* d4,d5 are x,y distances from player 
; add.w d5,d4 
; cmp.w #49,d4 
; ble.s SCMNearby 
; 
 
 
; clr.w d4 
; move.b AddDirOffset(a6),d4 
; ext.w d4 
; lea NextAddDirTable-S(a5),a0 
; move.b 0(a0,d4),d4 
; lea AddDirOffset(a6),a0 
; move.b d4,(a0) 
; clr.b DistanceOffset(a6) 
SCMRet 
 rts 
;---- 
;SCMNearby 
;* this sprite is close to the player - don't ever go away from it! 
; clr.w d4 
; move.b AddDirOffset(a6),d4 
; ext.w d4 
; lea NearbyAddDirTable,a0 
; move.b 0(a0,d4),d4 
; lea AddDirOffset(a6),a0 
; move.b d4,(a0) 
; clr.b DistanceOffset(a6) 
; rts 
;----- 
