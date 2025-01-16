/*
 *   Game Structures Used in H.E.R.O. - (somebody change this name, please ?)
 *
 *   Copyright c 1987 By Level 9 Computing & Leon Thrane.  All Rights Reserved.
 *   9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *   Author: Leon Thrane (July 1987)
 */

struct BackgroundStrct
{
	PLANEPTR  Planes[4];
	char	 *SuBaCWA[4][4];
	short	XPos, YPos;
};

struct PlayMapStrct
{
	char	 *Map;
	short	*Data;
	short	*XSize, *YSize;
};

/*
 *   The 'Flags' are allocated as follows:
 *
 *	   Bit No.	   Description
 *	   -------	   -----------
 *		 0		 Is the Sprite enabled ? (1 = NO, 0 = YES)
 *		 1		 Has the sprite gone of the edge ? (TRUE or FALSE)
 *		 2		 Is Sprite moving ? (Player sprites only)
 *		 3		 Has sprite been written yet needed for ReplaceBckgnd
 *		 7		 Joystick Button (0 = pushed)
 */

struct SpriteStrct
{
	short	Flags;
	short	XPos, YPos;
	short	XDis, YDis;
	short	**Data;
	short	HeightSkip;
	short	oldXPos,oldYPos;	/* used for ReplaceBckgnd */
	short	Direction;		/* 0-7 used for animation */
};

/*
 *   The 'Flags' are allocated as follows:
 *
 *	   Bit No.	   Description
 *	   -------	   -----------
 *		 0		 Frame Parity (skips even frames, ie when bit is 0)
 *		 1		 Interrupt Disable (a 1 disables this particular server)
 *		 2		 BitPlane/Work number (1 or 0)
 */

struct InterruptStrct
{
	short	Flags;
	struct    SpriteStrct *Player;
	struct    SpriteStrct *Missile;
	PLANEPTR  *ScreenPlanes[2];
	PLANEPTR  *WorkPlanes[2];
	APTR	 SoftInt;
	short	*BlocksRow;
	short	*MapPos;  /* (X and Y) */
	char	 *Map;
	struct    SpriteStrct *Monster;
	short	MonsterNumber;
};

