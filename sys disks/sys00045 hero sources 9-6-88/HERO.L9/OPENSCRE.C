/*
 *   Routines To Manage Our Screen
 *
 *   Copyright c 1987 By Level 9 Computing & Leon Thrane.  All Rights Reserved.
 *   9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *   Author: John Jones-Steele (from Leon Thrane July 1987) October 1987
 */

#include  "hero.h"

/*
 *   Our 'constants' (shoot that man, he talks pascal!)
 */

/*
 *   External functions and procedures
 */

/*
 *   A routine to Open a 'Screen' (View) and initialize all the relevant bits.
 */

struct View *OpenArea(CprList, BMap)
struct cprlist **CprList;
struct BitMap BMap[];
{
	int i, o;
/*   The colours defined in the colour table are layed out as follows:
	black, light brown, red/brown, red, dark green, light green, blue,
	dirt blue, pink, purple, dark brown, white, yellow, grey, tea, cyan   */
	static USHORT colortable[] =
	{ 0x000, 0xeca, 0xc00, 0xf00, 0x090, 0x0f0, 0x00f, 0x000,
		0xfbb, 0xa0f, 0x950, 0xfff, 0xff0, 0x888, 0x444, 0x0ff };
	UWORD *colorpalette;
	struct UCopList *lc;

	if ((GfxBase = (struct GfxBase *) OpenLibrary("graphics.library", 0)) == NULL)
		bye_bye("Cannot Access Library");

	oldview = GfxBase->ActiView;

	InitView(&v);
	InitVPort(&vp);
	v.ViewPort = &vp;

	InitBitMap(&BMap[0], DEPTH, WIDTH, HEIGHT);
	InitBitMap(&BMap[1], DEPTH, WIDTH, HEIGHT);

	for (o = 0; o < 2; o++)
		for (i = 0; i < DEPTH; i++)
			if ((BMap[o].Planes[i] = (PLANEPTR) AllocRaster(WIDTH, HEIGHT)) == NULL)
				bye_bye("Insufficient Free Store");
			else
				BltClear((UBYTE *) BMap[o].Planes[i], RASSIZE(WIDTH, HEIGHT), 0);

	ri.RxOffset = 0;
	ri.RyOffset = 0;
	ri.Next = NULL;

	vp.DWidth = WIDTH;
	vp.DHeight = HEIGHT;
	vp.RasInfo = &ri;

	vp.ColorMap = GetColorMap(NO_COLORS);
	colorpalette = (UWORD *) vp.ColorMap->ColorTable;
	for (i = 0; i < NO_COLORS; i++)
		*colorpalette++ = colortable[i];

/*   Make The Copper List To Initiate Our Interrupt Server  */

	if ((lc = (struct UCopList *) AllocMem(sizeof(struct UCopList), MEMF_PUBLIC|MEMF_CLEAR)) == NULL)
		bye_bye("Cannot Allocate UCopList");
	CWAIT(lc, 180, 0);
	CMOVE(lc, custom.intreq, 0x8010);
	CEND(lc);

	ri.BitMap = &BMap[0];
	vp.UCopIns = lc;
	MakeVPort(&v, &vp);
	MrgCop(&v);
	CprList[0] = v.LOFCprList;
	v.LOFCprList = NULL;

	ri.BitMap = &BMap[1];
	MakeVPort(&v, &vp);
	MrgCop(&v);
	CprList[1] = v.LOFCprList;

	return(&v);
}

void CloseArea(CprList, BMap)
struct cprlist **CprList;
struct BitMap BMap[];
{
	int i;

	for (i = 0; i < DEPTH; i++)
	{
		FreeRaster(BMap[0].Planes[i], WIDTH, HEIGHT);
		FreeRaster(BMap[1].Planes[i], WIDTH, HEIGHT);
	}

	FreeColorMap(vp.ColorMap);

	FreeVPortCopLists(&vp);
	FreeCprList(CprList[0]);
	FreeCprList(CprList[1]);

	CloseLibrary(GfxBase);
	LoadView(oldview);
}


