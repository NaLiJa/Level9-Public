/*
 *   Routines To Initialize The Main Variables
 *
 *   Copyright c 1987 By Level 9 Computing & Leon Thrane.  All Rights Reserved.
 *   9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *   Author: Leon Thrane (July 1987)
 */

#include "hero.h"

/*
 *   External functions and procedures
 */
extern USHORT wizardbrush0[],wizardbrush1[],wizardbrush2[],wizardbrush3[];
extern USHORT wizardbrush4[],wizardbrush5[],wizardbrush6[],wizardbrush7[];
extern USHORT ghost0[],ghost1[],ghost2[],ghost3[];
extern USHORT ghost4[],ghost5[],ghost6[],ghost7[];
extern char    *ReadMap();
extern short   *ReadBackground();
static short *wizanims[]={
	wizardbrush0,
	wizardbrush1,
	wizardbrush2,
	wizardbrush3,
	wizardbrush4,
	wizardbrush5,
	wizardbrush6,
	wizardbrush7};

static short player_data[] = { 15,
	0xffff, 0, 0, 0, 0,  0xffff, 0, 0, 0, 0,
	0xfc3f, 0x03c0, 0x03c0, 0x03c0, 0x03c0,
	0xf00f, 0x0c30, 0x0c30, 0x0c30, 0x0c30,
	0xc003, 0x300c, 0x300c, 0x300c, 0x300c,
	0x8001, 0x4002, 0x4002, 0x4002, 0x4002,
	0xc3c3, 0x27e4, 0x27e4, 0x27e4, 0x27e4,
	0x83c1, 0x4422, 0x4422, 0x4422, 0x4422,
	0x83c1, 0x4422, 0x4422, 0x4422, 0x4422,
	0xc3c3, 0x27e4, 0x27e4, 0x27e4, 0x27e4,
	0x8001, 0x4002, 0x4002, 0x4002, 0x4002,
	0xc003, 0x300c, 0x300c, 0x300c, 0x300c,
	0xf00f, 0x0c30, 0x0c30, 0x0c30, 0x0c30,
	0xfc3f, 0x03c0, 0x03c0, 0x03c0, 0x03c0,
	0xffff, 0, 0, 0, 0,  0xffff, 0, 0, 0, 0 };

static short missile_data[] = { 5,
	0xfe7f, 0, 0, 0x0180, 0x0180,
	0xfc3f, 0, 0, 0x03c0, 0x03c0,
	0xf81f, 0, 0, 0x07e0, 0x07e0,
	0xf81f, 0, 0, 0x07e0, 0x07e0,
	0xfc3f, 0, 0, 0x03c0, 0x03c0,
	0xfe7f, 0, 0, 0x0180, 0x0180  };

static short *missanims[]={
	missile_data};
static short *monsanims[]={
	ghost0,
	ghost1,
	ghost2,
	ghost3,
	ghost4,
	ghost5,
	ghost6,
	ghost7};

/*
 *   A routine to release the work areas allocated in InitializeScreen().
 */

void ReleaseScreen(PlayMap, Background, Work)
struct PlayMapStrct *PlayMap;
struct BackgroundStrct *Background;
PLANEPTR Work[][4];
{
	long i;

	for (i = 0; i < 4; i++)
	{
		FreeMem(Background->Planes[i], 8100);
		FreeMem(Work[0][i], 6480);
		FreeMem(Work[1][i], 6480);
	}
}

/*
 *   A routine to initialize the work areas needed for the Grafix.lib routines
 */

void InitializeScreen(PlayMap, Background, Work)
struct PlayMapStrct *PlayMap;
struct BackgroundStrct *Background;
PLANEPTR Work[][4];
{
	long i;

/**  get the background block data  **/

	PlayMap->Data = ReadBackground();

/**  initialize the PlayMap  **/

	PlayMap->Map = ReadMap();
	PlayMap->XSize = (short *) PlayMap->Map;
	PlayMap->YSize = (short *) (PlayMap->Map+2);

/**  initialize the 'SuBaCWA'  **/

	for (i = 0; i < 4; i++)
	{
		if ((Background->Planes[i] = (char *) AllocMem(8100, MEMF_CLEAR)) == NULL)
			bye_bye("Insufficient Free Store");
		Background->SuBaCWA[i][0] = Background->Planes[i];
		Background->SuBaCWA[i][2] = Background->Planes[i];
		Background->SuBaCWA[i][1] = Background->Planes[i]+8064;
		Background->SuBaCWA[i][3] = Background->Planes[i]+8064;
	}

	Background->YPos = 16;
	Background->XPos = 16;

/**  initialize the Work screen  **/

	for (i = 0; i < 4; i++)
		if (!(Work[0][i] = (char *) AllocMem(6480, MEMF_CLEAR)) || !(Work[1][i] = (char *) AllocMem(6480, MEMF_CLEAR)))
			bye_bye("Insufficient Free Store");
}

void InitializePlayer(Player, Missile)
struct SpriteStrct *Player, *Missile;
{
	Player->Flags = 192;
	Player->XPos = 120;
	Player->YPos = 82;
	Player->XDis = 1;
	Player->YDis = 0;
	Player->Direction = 2;
	Player->Data = wizanims;
	Player->HeightSkip = 5;
	Missile->Data = missanims;
	Missile->Flags = 9;
	Missile->HeightSkip = 0;
}

void InitializeMonster(Monster, number)
struct SpriteStrct Monster[];
int number;
{
	long i, o;

	for (o = 0; o < number; o++)
		for (i = 0; i < 16; i++)
		{
			Monster[o*16+i].XPos = i*16+16;
			Monster[o*16+i].YPos = o*16+240;
			Monster[o*16+i].Data = monsanims;
			Monster[o*16+i].HeightSkip = 5;
			Monster[o*16+i].Flags = 0;
		}
}
