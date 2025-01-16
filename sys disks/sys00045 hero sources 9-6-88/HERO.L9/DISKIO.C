/*
 *Routines To Read And Write Data Of Disk
 *
 *Copyright c 1987 By Level 9 Computing & Leon Thrane.	All Rights Reserved.
 *9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *Author: Leon Thrane (July 1987)
 */

#include "hero.h"

/*
 *Get the background block data from the file: 'Background.dat', each block
 *is 128 bytes is size.
 */

short *ReadBackground()
{
	short *block_data;
	long number;
	FILE *stream;

	if ((stream = fopen("Background.dat", "r")) == NULL)
		bye_bye("File Not Found");

	if (fread((char *) &number, sizeof(number), 1, stream) != 1)
		bye_bye("Unexpected EOF Marker");
	if ((block_data = (short *) malloc(number*128)) == NULL)
		bye_bye("Insufficient Free Store");

	if (fread((char *) block_data, 128, number, stream) != number)
		bye_bye("Unexpected EOF Marker");

	(void) fclose(stream);

	return(block_data);
}

char *ReadMap()
{
	char *MapData;
	long number[2];
	FILE *stream;

	if ((stream = fopen("Map.dat", "r")) == NULL)
		bye_bye("File Not Found");

	if (fread((char *) number, sizeof(number[0]), 2, stream) != 2)
		bye_bye("Unexpected EOF Marker");
	if ((MapData = malloc(number[0]*number[1]+4)) == NULL)
		bye_bye("Insufficient Free Store");

	if (fread(MapData+4, number[0], number[1], stream) != number[1])
		bye_bye("Unexpected EOF Marker");

	*((short *) MapData) = (short) number[0];
	*((short *) (MapData+2)) = (short) number[1];

	(void) fclose(stream);

	return(MapData);
}
