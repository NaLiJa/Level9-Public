; Static Data for Hero
;
; Copyright (C) 1988 Level 9 Computing
;
; M.J.Austin 1987/1988
;

BGMinXTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BGMaxXTable equ *-16
* for each background block, record here the max x
* value which should be cd'd with.
* start with block 16....
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

BGMinYTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BGMaxYTable equ *-16
* for each background block, record here the min x
* value which should be cd'd with.
* start with block 16....
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
 dc.b 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15

;-------
BigExplosionTable
* table giving the x,y speeds for the elements of a big explosion
* up, right quarter
 dc.w 0,-12 * north
 dc.w 6,-11
 dc.w 12,-12
 dc.w 11,-6

* down, right quarter
 dc.w 12,0 * east
 dc.w 11,6
 dc.w 12,12
 dc.w 6,11

* down, left quarter
 dc.w 0,12 * south
 dc.w -6,11
 dc.w -12,12
 dc.w -12,6

* down, right quarter
 dc.w -12,0 * west
 dc.w -11,-6
 dc.w -12,-12
 dc.w -6,-11

 dc.w 0,0 * terminates table
;--------------
ViewConversionTable
; Table to convert from joystick status values to view of player to use
 dc.b 0 ; 0000 dummy entry
 dc.b 0 ; 0001 north
 dc.b 4 ; 0010 south
 dc.b 0 ; 0011 -
 dc.b 6 ; 0100 west
 dc.b 7 ; 0101 northwest
 dc.b 5 ; 0110 southwest
 dc.b 0 ; 0111 -
 dc.b 2 ; 1000 east
 dc.b 1 ; 1001 east-north
 dc.b 3 ; 1010 east-south
 dc.b 0 ; 1011 -
 dc.b 0 ; 1100 -
 dc.b 0 ; 1101 -
 dc.b 0 ; 1110 -
 dc.b 0 ; 1111 -
;---
 even
ViewToXYConversionTable
; Table to convert from player view to XY offset (used for
; firing missiles etc.)
 dc.w 0,-1 * north
 dc.w 1,-1 * ne
 dc.w 1,0 * e
 dc.w 1,1 * se
 dc.w 0,1 * s
 dc.w -1,1 * sw
 dc.w -1,0 * w
 dc.w -1,-1 * nw
;-----
 even
 dc.b 0*4 * -3 - sixth attempt
 ds.b 3
 dc.b 3*4 * -2 - fifth attempt
 ds.b 3
 dc.b 2*4 * -1 - fourth attempt
 ds.b 3
NextAddDirTable
; byte-wise table that, given the current addition to the
; movement direction, gives the new addition
 dc.b 1*4 * 0 - first altered direction
 ds.b 3
 dc.b -1*4 * 1 - second attempt
 ds.b 3
 dc.b -2*4 * 2 - third attempt
 ds.b 3
 dc.b -3*4 * 3 - seventh attempt
 ds.b 3
 dc.b 0 * 4 - eighth attempt - start sequence again
 ds.b 3

;----
***** not used nowadays
 even
 dc.b 0*4 * -3
 ds.b 3
 dc.b 0*4 * -2
 ds.b 3
 dc.b 0*4 * -1
 ds.b 3
NearbyAddDirTable
; byte-wise table that, given the current addition to the
; movement direction, gives the new addition
 dc.b 1*4 * 0
 ds.b 3
 dc.b -1*4 * 1
 ds.b 3
 dc.b 0*4 * 2
 ds.b 3
 dc.b 0*4 * 3
 ds.b 3
 dc.b 0 * 4
 ds.b 3
;---
; Driver Blocks etc...
 even
LoadSpritesDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'Sprites.Dat',0
 even

LoadPlaySprDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'Sprites.Dat',0
 even


LoadMapLayoutDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'map.dat',0
 even

LoadMapGraphicsDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'mapgraph.dat',0
 even
;---
LoadTitleScreenDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'SideScr.dat',0
 even
;----
LoadGamedataDriverBlock
 ds.l 1
 ds.l 1
 dc.b 'Gamedata.dat',0
 even
;-------
Palette
 dc.w $000,$333,$555,$777,$300,$500,$700
 dc.w $030,$050,$070,$003,$005,$007,$330,$550,$770
;-----
SpriteDataStructure
PlayerSDS
; 0 is left player
StationaryAnimationOffset equ *-SpriteDataStructure
 dc.w 0	* animation offset range when stationary ( from current view)
MovingAnimationOffset equ *-SpriteDataStructure
 dc.w 0	* animation range when moving north
 dc.w 8	* animation range when moving ne
 dc.w 16	* animation range when moving e
 dc.w 24	* animation range when moving se
 dc.w 32	* animation range when moving s
 dc.w 40	* animation range when moving sw
 dc.w 48	* animation range when moving w
 dc.w 56	* animation range when moving nw

FightAnimationOffset equ *-SpriteDataStructure
 dc.w 0 * roughly change the colour of the player.
* added to above animation ranges when in hand to hand combat
* ( this is the actual offset in bytes )

ThrowAnimationOffset equ *-SpriteDataStructure
 dc.w 256 * added to above animation ranges when player is throwing
* something.

InitialHitPointOffset equ *-SpriteDataStructure
 dc.w 1000 * initial hit points

InitialBlowStrengthOffset equ *-SpriteDataStructure
 dc.w 30 * damage done

TimeBetweenBlowsOffset equ *-SPriteDataStructure
 dc.b 5

MaxAnimationStage
NumAnimationOffset equ *-SpriteDataStructure
 dc.b 7 * max animation offset

TypeOffset equ *-SpriteDataStructure
 dc.b 1 * player type
* type is 1 bit, corresponding to those
* specified by the collision detection flags

PlayerStepSize
SpeedOffset equ *-SpriteDataStructure
 dc.b 4 	* speed of movement (pels)
NullMovesOffset equ *-SpriteDataStructure
 dc.b 0 	* number of null moves per real move

* bit assignments for use in typeoffset, and
* the various cd fields below
CDWithPlayer equ 0 * bit 0
CDWithMissiles equ 1
CDWithMonsters equ 2
CDWithBG equ 3 * bit 3
CDWithObject equ 4
CDWithInvisibles equ 5
CDWithMonsterMissile equ 6

CDFlagsOffset equ *-SpriteDataStructure
 dc.b $fd 	* which collisions are detected?
CDSpecialsOffset equ *-SpriteDataStructure
 dc.b $34 	* which collisions activate specials?
CDDestroyedOffset equ *-SpriteDataStructure
 dc.b $00	* does THIS sprite explode on these collisions
CDBlockedOffset equ *-SpriteDataStructure
 dc.b $0f	* is this sprite blocked by these collisions

PriorityOffset equ *-SpriteDataStructure
 dc.b 100 * 128	* priority of sprite. 255 appears on top, 0 at bottom
* sprites of equal priority are sorted vertically
HeightOffset equ *-SpriteDataStructure
 dc.b 19 * offset of bottom row used in cd
HeadOverlapOffset equ *-SpriteDataStructure
 dc.b 4 * number of rows at top of sprite not cd'd
 even

SDS1End
SDSSize equ SDS1End-SpriteDataStructure

;-
; 1 is missile
 dc.w 112 *64	* animation offset range when stationary ( from current view)
 dc.w 112 *64	* animation range when moving north
 dc.w 112 *64	* animation range when moving ne
 dc.w 112 *64	* animation range when moving e
 dc.w 112 *64	* animation range when moving se
 dc.w 112 *64	* animation range when moving s
 dc.w 112 *64	* animation range when moving sw
 dc.w 112 *64	* animation range when moving w
 dc.w 112 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 20 * damage done
 dc.b 0 * continuous blows

 dc.b 7 * max animation offset
 dc.b 2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $cc 	* collision detect?
 dc.b $cc 	* specials?
 dc.b $cc	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 2 is  an animated skull monster
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 99	* animation range when moving north
 dc.w 99	* animation range when moving ne
 dc.w 99	* animation range when moving e
 dc.w 99	* animation range when moving se
 dc.w 99	* animation range when moving s
 dc.w 99	* animation range when moving sw
 dc.w 99	* animation range when moving w
 dc.w 99	* animation range when moving nw
 dc.w 3 * *200	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 2 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 3 is  an explosion effect
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 88	* animation range when moving north
 dc.w 88	* animation range when moving ne
 dc.w 88	* animation range when moving e
 dc.w 88	* animation range when moving se
 dc.w 88	* animation range when moving s
 dc.w 88	* animation range when moving sw
 dc.w 88	* animation range when moving w
 dc.w 88	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * blows per second

 dc.b 8 * max animation offset
 dc.b 0 * no type - will not cd with anything
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00 	* destroyed?
 dc.b $0f	* blocked?
 dc.b 105	* priority
 dc.b 15 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;-------
; 4 is  an animated skull monster for space invaders
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 96	* animation range when moving north
 dc.w 96	* animation range when moving ne
 dc.w 96	* animation range when moving e
 dc.w 96	* animation range when moving se
 dc.w 96	* animation range when moving s
 dc.w 96	* animation range when moving sw
 dc.w 96	* animation range when moving w
 dc.w 96	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 2 * max animation offset
 dc.b $84 * monster type, but not auto-moving, hence bit 7 set
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $02 	* collision detect?
 dc.b $00 	* specials?
 dc.b $02	* destroyed?
 dc.b $00	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;------
; 5 is missile for space invaders to fire
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 25 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $40 * si missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $01	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 6 is missile to fire at space invaders
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $c4 	* collision detect?
 dc.b $00 	* specials?
 dc.b $c4	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;-----
; 7 is  a Rainbird monster
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 104	* animation range when moving north
 dc.w 104	* animation range when moving ne
 dc.w 104	* animation range when moving e
 dc.w 104	* animation range when moving se
 dc.w 104	* animation range when moving s
 dc.w 104	* animation range when moving sw
 dc.w 104	* animation range when moving w
 dc.w 104	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 0 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0f	* blocked?
 dc.b 100	* priority
 dc.b 15 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

;-----
; 8 is the explosive missile fired by the player
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 50 * damage done
 dc.b 0 * continuous blows

 dc.b 7 * max animation offset
 dc.b $22 * $02=missile type, $20=explosive missile
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $cc 	* collision detect?
 dc.b $cc 	* specials?
 dc.b $cc	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;------
; 9 is digging missile.
 dc.w 112 *64	* animation offset range when stationary ( from current view)
 dc.w 112 *64	* animation range when moving north
 dc.w 112 *64	* animation range when moving ne
 dc.w 112 *64	* animation range when moving e
 dc.w 112 *64	* animation range when moving se
 dc.w 112 *64	* animation range when moving s
 dc.w 112 *64	* animation range when moving sw
 dc.w 112 *64	* animation range when moving w
 dc.w 112 *64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 2 * missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $c8 	* collision detect?
 dc.b $c8 	* specials?
 dc.b $c8	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;------
; 10 is bottle
 dc.w 122 *64	* animation offset range when stationary ( from current view)
 dc.w 122 *64	* animation range when moving north
 dc.w 122 *64	* animation range when moving ne
 dc.w 122 *64	* animation range when moving e
 dc.w 122 *64	* animation range when moving se
 dc.w 122 *64	* animation range when moving s
 dc.w 122 *64	* animation range when moving sw
 dc.w 122 *64	* animation range when moving w
 dc.w 122 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 11 is invisible object
 dc.w -1	* animation offset range when stationary ( from current view)
 dc.w -1	* animation range when moving north
 dc.w -1	* animation range when moving ne
 dc.w -1	* animation range when moving e
 dc.w -1	* animation range when moving se
 dc.w -1	* animation range when moving s
 dc.w -1	* animation range when moving sw
 dc.w -1	* animation range when moving w
 dc.w -1	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $20 * trap type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 15 * offset of bottom row - used by rough cd
 dc.b 0 * head overlap
 even
;-----
; 12 is missile for space invaders to fire
 dc.w 64	* animation offset range when stationary ( from current view)
 dc.w 64	* animation range when moving north
 dc.w 64	* animation range when moving ne
 dc.w 64	* animation range when moving e
 dc.w 64	* animation range when moving se
 dc.w 64	* animation range when moving s
 dc.w 64	* animation range when moving sw
 dc.w 64	* animation range when moving w
 dc.w 64	* animation range when moving nw
 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 100 * initial hit points
 dc.w 25 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b $44 * monster missile type
 dc.b 12 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0b 	* collision detect?
 dc.b $0b 	* specials?
 dc.b $0b	* destroyed?
 dc.b $00	* blocked?
 dc.b 120	* priority
 dc.b 11 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

;----
; 13 is  an explosion effect
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 80	* animation range when moving north
 dc.w 80	* animation range when moving ne
 dc.w 80	* animation range when moving e
 dc.w 80	* animation range when moving se
 dc.w 80	* animation range when moving s
 dc.w 80	* animation range when moving sw
 dc.w 80	* animation range when moving w
 dc.w 80	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * blows per second

 dc.b 8 * max animation offset
 dc.b 0 * no type - will not cd with anything
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $00 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00 	* destroyed?
 dc.b $00	* blocked?
 dc.b 105	* priority
 dc.b 15 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
;-------
; 14 is NEW bottle
 dc.w 122 *64	* animation offset range when stationary ( from current view)
 dc.w 122 *64	* animation range when moving north
 dc.w 122 *64	* animation range when moving ne
 dc.w 122 *64	* animation range when moving e
 dc.w 122 *64	* animation range when moving se
 dc.w 122 *64	* animation range when moving s
 dc.w 122 *64	* animation range when moving sw
 dc.w 122 *64	* animation range when moving w
 dc.w 122 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 15 is sword
 dc.w 123 *64	* animation offset range when stationary ( from current view)
 dc.w 123 *64	* animation range when moving north
 dc.w 123 *64	* animation range when moving ne
 dc.w 123 *64	* animation range when moving e
 dc.w 123 *64	* animation range when moving se
 dc.w 123 *64	* animation range when moving s
 dc.w 123 *64	* animation range when moving sw
 dc.w 123 *64	* animation range when moving w
 dc.w 123 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 16 is armour
 dc.w 124 *64	* animation offset range when stationary ( from current view)
 dc.w 124 *64	* animation range when moving north
 dc.w 124 *64	* animation range when moving ne
 dc.w 124 *64	* animation range when moving e
 dc.w 124 *64	* animation range when moving se
 dc.w 124 *64	* animation range when moving s
 dc.w 124 *64	* animation range when moving sw
 dc.w 124 *64	* animation range when moving w
 dc.w 124 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 17 is ring
 dc.w 125 *64	* animation offset range when stationary ( from current view)
 dc.w 125 *64	* animation range when moving north
 dc.w 125 *64	* animation range when moving ne
 dc.w 125 *64	* animation range when moving e
 dc.w 125 *64	* animation range when moving se
 dc.w 125 *64	* animation range when moving s
 dc.w 125 *64	* animation range when moving sw
 dc.w 125 *64	* animation range when moving w
 dc.w 125 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 18 is wand
 dc.w 126 *64	* animation offset range when stationary ( from current view)
 dc.w 126 *64	* animation range when moving north
 dc.w 126 *64	* animation range when moving ne
 dc.w 126 *64	* animation range when moving e
 dc.w 126 *64	* animation range when moving se
 dc.w 126 *64	* animation range when moving s
 dc.w 126 *64	* animation range when moving sw
 dc.w 126 *64	* animation range when moving w
 dc.w 126 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 19 is scroll
 dc.w 127 *64	* animation offset range when stationary ( from current view)
 dc.w 127 *64	* animation range when moving north
 dc.w 127 *64	* animation range when moving ne
 dc.w 127 *64	* animation range when moving e
 dc.w 127 *64	* animation range when moving se
 dc.w 127 *64	* animation range when moving s
 dc.w 127 *64	* animation range when moving sw
 dc.w 127 *64	* animation range when moving w
 dc.w 127 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 20 is pot of gold
 dc.w 106 *64	* animation offset range when stationary ( from current view)
 dc.w 106 *64	* animation range when moving north
 dc.w 106 *64	* animation range when moving ne
 dc.w 106 *64	* animation range when moving e
 dc.w 106 *64	* animation range when moving se
 dc.w 106 *64	* animation range when moving s
 dc.w 106 *64	* animation range when moving sw
 dc.w 106 *64	* animation range when moving w
 dc.w 106 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 21 is club
 dc.w 108 *64	* animation offset range when stationary ( from current view)
 dc.w 108 *64	* animation range when moving north
 dc.w 108 *64	* animation range when moving ne
 dc.w 108 *64	* animation range when moving e
 dc.w 108 *64	* animation range when moving se
 dc.w 108 *64	* animation range when moving s
 dc.w 108 *64	* animation range when moving sw
 dc.w 108 *64	* animation range when moving w
 dc.w 108 *64	* animation range when moving nw

 dc.w 0 * fight offset
 dc.w 0 * throw offset
 dc.w 0 * initial hit points
 dc.w 0 * damage done
 dc.b 0 * continuous blows

 dc.b 0 * max animation offset
 dc.b $10 * object type
 dc.b 0 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $01 	* collision detect?
 dc.b $00 	* specials?
 dc.b $00	* destroyed?
 dc.b $00	* blocked?
 dc.b 0		* priority
 dc.b 12 * offset of bottom row - used by rough cd
 dc.b 4 * head overlap
 even
;----
; 22 is  a floating eye monster
 dc.w 0	* animation offset range when stationary ( from current view)
;; EyeGraphic equ 128
 dc.w EyeGraphic	* animation range when moving north
 dc.w EyeGraphic	* animation range when moving ne
 dc.w EyeGraphic	* animation range when moving e
 dc.w EyeGraphic	* animation range when moving se
 dc.w EyeGraphic	* animation range when moving s
 dc.w EyeGraphic	* animation range when moving sw
 dc.w EyeGraphic	* animation range when moving w
 dc.w EyeGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $09 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


;----
; 23 is  an acide blob
 dc.w 0	* animation offset range when stationary ( from current view)
AcidGraphic equ 136
 dc.w AcidGraphic	* animation range when moving north
 dc.w AcidGraphic	* animation range when moving ne
 dc.w AcidGraphic	* animation range when moving e
 dc.w AcidGraphic	* animation range when moving se
 dc.w AcidGraphic	* animation range when moving s
 dc.w AcidGraphic	* animation range when moving sw
 dc.w AcidGraphic	* animation range when moving w
 dc.w AcidGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 24 is a jelly
 dc.w 0	* animation offset range when stationary ( from current view)
JellyGraphic equ 140
 dc.w JellyGraphic	* animation range when moving north
 dc.w JellyGraphic	* animation range when moving ne
 dc.w JellyGraphic	* animation range when moving e
 dc.w JellyGraphic	* animation range when moving se
 dc.w JellyGraphic	* animation range when moving s
 dc.w JellyGraphic	* animation range when moving sw
 dc.w JellyGraphic	* animation range when moving w
 dc.w JellyGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 25 is a fog cloud
 dc.w 0	* animation offset range when stationary ( from current view)
FogGraphic equ 144
 dc.w FogGraphic	* animation range when moving north
 dc.w FogGraphic	* animation range when moving ne
 dc.w FogGraphic	* animation range when moving e
 dc.w FogGraphic	* animation range when moving se
 dc.w FogGraphic	* animation range when moving s
 dc.w FogGraphic	* animation range when moving sw
 dc.w FogGraphic	* animation range when moving w
 dc.w FogGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 26 is a ghost
 dc.w 0	* animation offset range when stationary ( from current view)
GhostGraphic equ 148
 dc.w GhostGraphic	* animation range when moving north
 dc.w GhostGraphic	* animation range when moving ne
 dc.w GhostGraphic	* animation range when moving e
 dc.w GhostGraphic	* animation range when moving se
 dc.w GhostGraphic	* animation range when moving s
 dc.w GhostGraphic	* animation range when moving sw
 dc.w GhostGraphic	* animation range when moving w
 dc.w GhostGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 27 is a will'o wisp
 dc.w 0	* animation offset range when stationary ( from current view)
WispGraphic equ 152
 dc.w WispGraphic	* animation range when moving north
 dc.w WispGraphic	* animation range when moving ne
 dc.w WispGraphic	* animation range when moving e
 dc.w WispGraphic	* animation range when moving se
 dc.w WispGraphic	* animation range when moving s
 dc.w WispGraphic	* animation range when moving sw
 dc.w WispGraphic	* animation range when moving w
 dc.w WispGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 28 is a ghoul
 dc.w 0	* animation offset range when stationary ( from current view)
GhoulGraphic equ 160
 dc.w GhoulGraphic	* animation range when moving north
 dc.w GhoulGraphic	* animation range when moving ne
 dc.w GhoulGraphic	* animation range when moving e
 dc.w GhoulGraphic	* animation range when moving se
 dc.w GhoulGraphic	* animation range when moving s
 dc.w GhoulGraphic	* animation range when moving sw
 dc.w GhoulGraphic	* animation range when moving w
 dc.w GhoulGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 29 is a spider
 dc.w 0	* animation offset range when stationary ( from current view)
SpiderGraphic equ 164
 dc.w SpiderGraphic	* animation range when moving north
 dc.w SpiderGraphic	* animation range when moving ne
 dc.w SpiderGraphic	* animation range when moving e
 dc.w SpiderGraphic	* animation range when moving se
 dc.w SpiderGraphic	* animation range when moving s
 dc.w SpiderGraphic	* animation range when moving sw
 dc.w SpiderGraphic	* animation range when moving w
 dc.w SpiderGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even
; 22 is  a floating eye monster
 dc.w 0	* animation offset range when stationary ( from current view)
EyeGraphic equ 128
 dc.w EyeGraphic	* animation range when moving north
 dc.w EyeGraphic	* animation range when moving ne
 dc.w EyeGraphic	* animation range when moving e
 dc.w EyeGraphic	* animation range when moving se
 dc.w EyeGraphic	* animation range when moving s
 dc.w EyeGraphic	* animation range when moving sw
 dc.w EyeGraphic	* animation range when moving w
 dc.w EyeGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 30 is a leprecaun
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 168	* animation range when moving north
 dc.w 172	* animation range when moving ne
 dc.w 176	* animation range when moving e
 dc.w 180	* animation range when moving se
 dc.w 184	* animation range when moving s
 dc.w 188	* animation range when moving sw
 dc.w 192	* animation range when moving w
 dc.w 196	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 31 is a gorgon
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 288	* animation range when moving north
 dc.w 296	* animation range when moving ne
 dc.w 304	* animation range when moving e
 dc.w 312	* animation range when moving se
 dc.w 320	* animation range when moving s
 dc.w 328	* animation range when moving sw
 dc.w 336	* animation range when moving w
 dc.w 344	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 32 is a minotaur
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 320	* animation range when moving north
 dc.w 324	* animation range when moving ne
 dc.w 328	* animation range when moving e
 dc.w 332	* animation range when moving se
 dc.w 336	* animation range when moving s
 dc.w 340	* animation range when moving sw
 dc.w 344	* animation range when moving w
 dc.w 348	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 33 is a mummy
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 352	* animation range when moving north
 dc.w 356	* animation range when moving ne
 dc.w 360	* animation range when moving e
 dc.w 364	* animation range when moving se
 dc.w 368	* animation range when moving s
 dc.w 372	* animation range when moving sw
 dc.w 376	* animation range when moving w
 dc.w 380	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 4 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 34 is a balrog
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 416	* animation range when moving north
 dc.w 420	* animation range when moving ne
 dc.w 424	* animation range when moving e
 dc.w 428	* animation range when moving se
 dc.w 432	* animation range when moving s
 dc.w 436	* animation range when moving sw
 dc.w 440	* animation range when moving w
 dc.w 444	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 35 is a demon
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 448	* animation range when moving north
 dc.w 452	* animation range when moving ne
 dc.w 456	* animation range when moving e
 dc.w 460	* animation range when moving se
 dc.w 464	* animation range when moving s
 dc.w 468	* animation range when moving sw
 dc.w 472	* animation range when moving w
 dc.w 476	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 36 is a skeleton
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 480	* animation range when moving north
 dc.w 484	* animation range when moving ne
 dc.w 488	* animation range when moving e
 dc.w 492	* animation range when moving se
 dc.w 496	* animation range when moving s
 dc.w 500	* animation range when moving sw
 dc.w 504	* animation range when moving w
 dc.w 508	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 37 is a nymph
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 544	* animation range when moving north
 dc.w 548	* animation range when moving ne
 dc.w 552	* animation range when moving e
 dc.w 556	* animation range when moving se
 dc.w 560	* animation range when moving s
 dc.w 564	* animation range when moving sw
 dc.w 568	* animation range when moving w
 dc.w 572	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 38 is a vampire
 dc.w 0	* animation offset range when stationary ( from current view)
 dc.w 576	* animation range when moving north
 dc.w 580	* animation range when moving ne
 dc.w 584	* animation range when moving e
 dc.w 588	* animation range when moving se
 dc.w 592	* animation range when moving s
 dc.w 596	* animation range when moving sw
 dc.w 600	* animation range when moving w
 dc.w 604	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 3 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even


; 39 is killer bee
 dc.w 0	* animation offset range when stationary ( from current view)
BeeGraphic equ 608
 dc.w BeeGraphic	* animation range when moving north
 dc.w BeeGraphic	* animation range when moving ne
 dc.w BeeGraphic	* animation range when moving e
 dc.w BeeGraphic	* animation range when moving se
 dc.w BeeGraphic	* animation range when moving s
 dc.w BeeGraphic	* animation range when moving sw
 dc.w BeeGraphic	* animation range when moving w
 dc.w BeeGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 40 is a snake
 dc.w 0	* animation offset range when stationary ( from current view)
SnakeGraphic equ 616
 dc.w SnakeGraphic	* animation range when moving north
 dc.w SnakeGraphic	* animation range when moving ne
 dc.w SnakeGraphic	* animation range when moving e
 dc.w SnakeGraphic	* animation range when moving se
 dc.w SnakeGraphic	* animation range when moving s
 dc.w SnakeGraphic	* animation range when moving sw
 dc.w SnakeGraphic	* animation range when moving w
 dc.w SnakeGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

; 41 is a freezing sphere
 dc.w 0	* animation offset range when stationary ( from current view)
SphereGraphic equ 624
 dc.w SphereGraphic	* animation range when moving north
 dc.w SphereGraphic	* animation range when moving ne
 dc.w SphereGraphic	* animation range when moving e
 dc.w SphereGraphic	* animation range when moving se
 dc.w SphereGraphic	* animation range when moving s
 dc.w SphereGraphic	* animation range when moving sw
 dc.w SphereGraphic	* animation range when moving w
 dc.w SphereGraphic	* animation range when moving nw
 dc.w 0	* fight offset
 dc.w 0 * throw offset
 dc.w 50 * initial hit points
 dc.w 5 * damage done
 dc.b 10 * roughly one blow per second

 dc.b 7 * max animation offset
 dc.b 4 * monster type
 dc.b 1 	* speed of movement (pels)
 dc.b 0 	* number of null moves per real move
 dc.b $0d 	* collision detect?
 dc.b $01 	* specials?
 dc.b $00	* destroyed?
 dc.b $0d	* blocked?
 dc.b 100	* priority
 dc.b 19 * offset of bottom row - used in cd
 dc.b 4 * head overlap
 even

