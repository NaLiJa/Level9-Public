/*
 *H.E.R.O. - A 'Gauntlet' type of 'Hack'
 *
 *Copyright c 1987 By Level 9 Computing & Leon Thrane.  All Rights Reserved.
 *9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *Author: Leon Thrane (July 1987)
 */

#include "hero.h"

#define NO_MONSTERS 48

/*
 *External Functions, Procedures and Variables
 */

extern void check_movement(), Initialize(), check_joystick(), 
			InitializeInterrupt(), RemoveInterrupt(), ShowMonsters(),
			InitializePlayer(), InitializeMonster();
extern struct  View *OpenArea();
extern USHORT joydata[];
/*
 *Global Variable Declaration
 */

struct	 PlayMapStrct PlayMap;

/*
 *THE PROGRAM ....
 */

void main()
{
	PLANEPTR Work[2][4];
	struct BitMap BMap[2];
	struct SpriteStrct Player, Missile;
	struct BackgroundStrct Background;
	struct cprlist *CprList[2];
	struct View *view;
	struct InterruptStrct MyInt;
	struct SpriteStrct Monster[NO_MONSTERS];
	register short XInc, YInc, ScrNum = 0;

	InitializePlayer(&Player, &Missile);
	InitializeMonster(&Monster[0], NO_MONSTERS/16);

/*** Initialize The Screen And Related Items ***/

	InitializeScreen(&PlayMap, &Background, Work);
	view = OpenArea(CprList, BMap);
	BuildScr(PlayMap.Data, PlayMap.Map, 0, 0, Background.Planes);
	ScrollCopy(Background.SuBaCWA, &Work[0][0], 0, 0);
	FastCopy(&Work[0][0], BMap[0].Planes);
	view->LOFCprList = CprList[0];
	LoadView(view);

/*** Initialize The Interrupt Structure ***/

	MyInt.Flags = 0;
	MyInt.Player = &Player;
	MyInt.Missile = &Missile;
	MyInt.ScreenPlanes[0] = BMap[0].Planes;
	MyInt.ScreenPlanes[1] = BMap[1].Planes;
	MyInt.WorkPlanes[0] = &Work[0][0];
	MyInt.WorkPlanes[1] = &Work[1][0];
	MyInt.BlocksRow = (short *) PlayMap.Map;
	MyInt.MapPos = &Background.XPos;
	MyInt.Map = PlayMap.Map + 4;
	MyInt.Monster = &Monster[0];
	MyInt.MonsterNumber = NO_MONSTERS-1;
	InitializeInterrupt(&MyInt);

/*** Main Loop ***/

	do
	{
		register Ytemp;
		Ytemp=Player.YPos+Player.HeightSkip;
		YInc = 82-Ytemp+Background.YPos;
		YInc = (abs(YInc) < 42 ? 1 : (abs(YInc) < 64 ? 2 : 8));
		if (Ytemp-Background.YPos > 91 && Background.YPos < *PlayMap.YSize * 16 - 180)
		{
			if (Background.YPos + YInc > *PlayMap.YSize * 16 - 180)
				YInc = *PlayMap.YSize * 16 - 180 - Background.YPos;
			if (((Background.YPos & 15) + YInc) > 15)
				MoveUp(PlayMap.Data, PlayMap.Map, Background.SuBaCWA, Background.XPos >> 4, Background.YPos >> 4);
			YInc = -YInc;
		}
		else
			if (Ytemp-Background.YPos < 73 && Background.YPos > 0)
			{
				if (Background.YPos - YInc < 0)
					YInc = Background.YPos;
				if (((Background.YPos & 15) - YInc) < 0)
					MoveDown(PlayMap.Data, PlayMap.Map, Background.SuBaCWA, Background.XPos >> 4, Background.YPos >> 4);
			}
			else
				YInc = 0;

		XInc = 120-Player.XPos+Background.XPos;
		XInc = (abs(XInc) < 60 ? 1 : (abs(XInc) < 94 ? 2 : 8));
		if (Player.XPos-Background.XPos > 135 && Background.XPos < *PlayMap.XSize * 16 - 256)
		{
			if (Background.XPos + XInc > *PlayMap.XSize * 16 - 256)
				XInc = *PlayMap.XSize * 16 - 256 - Background.XPos;
			if (((Background.XPos & 15) + XInc) > 15)
				MoveLeft(PlayMap.Data, PlayMap.Map, Background.SuBaCWA, Background.XPos >> 4, (Background.YPos - YInc) >> 4);
			XInc = -XInc;
		}
		else
			if (Player.XPos-Background.XPos < 105 && Background.XPos > 0)
			{
				if (Background.XPos - XInc < 0)
					XInc = Background.XPos;
				if (((Background.XPos & 15) - XInc) < 0)
					MoveRight(PlayMap.Data, PlayMap.Map, Background.SuBaCWA, Background.XPos >> 4, (Background.YPos - YInc) >> 4);
			}
			else
				XInc = 0;

		ScrNum ^= 1;
		ScrollCopy(Background.SuBaCWA, &Work[ScrNum][0], Background.XPos - XInc & 15, Background.YPos - YInc & 15);
		ShowMonsters(Background.XPos - XInc, Background.YPos - YInc, &Player, &Missile, &Monster[0], &Work[ScrNum][0]);
		FastCopy(&Work[ScrNum][0], BMap[ScrNum].Planes);
		if (XInc || YInc)
		{
			MyInt.Flags |= 2;
			Background.XPos -= XInc;
			Background.YPos -= YInc;
			MyInt.Flags ^= 2;
		}
		if (!(Missile.Flags & 1) && MapCheck(Missile.XPos, Missile.YPos, **Missile.Data, PlayMap.Map))
			Missile.Flags |= 1;
		Sprite(BMap[ScrNum].Planes, *(Player.Data+Player.Direction), Player.XPos-Background.XPos, Player.YPos-Background.YPos, 40);
		if (!(Missile.Flags & 1))
			Sprite(BMap[ScrNum].Planes, *Missile.Data, Missile.XPos-Background.XPos, Missile.YPos-Background.YPos, 40);
		view->LOFCprList = CprList[ScrNum];
		LoadView(view);
		MyInt.Flags = ScrNum * 4;
	} while (Player.Flags & 64);

/*** Deallocate Resources So Brutally Stolen ***/

	RemoveInterrupt();
	CloseArea(CprList, BMap);
	ReleaseScreen(&PlayMap, &Background, Work);
}

void ShowMonsters(MapXPos, MapYPos, Player, Missile, Monster, Planes)
int MapXPos, MapYPos;
struct SpriteStrct *Player, *Missile, Monster[];
PLANEPTR Planes[];
{
	register USHORT i, o;
	register struct SpriteStrct *Mon1,*Mon2;
	
	for (i = 0; i < NO_MONSTERS; i++)
	{
		Mon1=&Monster[i];
		if (Mon1->XPos+16 < MapXPos || Mon1->YPos+*Mon1->Data[0] < MapYPos || Mon1->XPos > MapXPos+256 || Mon1->YPos > MapYPos+179 || Mon1->Flags & 1)
			continue;
		Mon1->Direction=0;
		Mon1->XDis = (Mon1->XPos > Player->XPos ? -3 : (Mon1->XPos < Player->XPos ? 3 : 0));
		Mon1->YDis = (Mon1->YPos > Player->YPos ? -3 : (Mon1->YPos < Player->YPos ? 3 : 0));
		if(Mon1->XDis)Mon1->Direction=Mon1->XDis>0?2:8;
		if(Mon1->YDis)Mon1->Direction|=Mon1->YDis>0?4:1;
		Mon1->Direction=joydata[Mon1->Direction];
		WallDetection(&Mon1->XDis, &Mon1->YDis, Mon1->XPos, Mon1->YPos, *PlayMap.XSize, PlayMap.Map+4,Mon1->HeightSkip);
		if (!CollisionCheck(Mon1, Player))
		{
			for (o = 0; o < NO_MONSTERS; o++)
			{
				Mon2=&Monster[o];
				if (o != i && !(Mon2->Flags & 1) && CollisionCheck(Mon1, Mon2))
					break;
			}
			if (o == NO_MONSTERS)
			{
				Mon1->XPos += Mon1->XDis;
				Mon1->YPos += Mon1->YDis;
			}
		}
		Sprite(Planes, *(Mon1->Data+Mon1->Direction), Mon1->XPos-MapXPos+16, Mon1->YPos-MapYPos, 36);
	}
}
