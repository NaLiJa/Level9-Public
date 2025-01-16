/*
 *   H.E.R.O. - A 'Gauntlet' type of 'Hack'
 *
 *   Copyright c 1987 By Level 9 Computing & Leon Thrane.  All Rights Reserved.
 *   9 Mendip Road, Crown Wood, Bracknell, Berkshire, RG12 3XG - (0344) 487597
 *
 *   Author: Leon Thrane (July 1987)
 */

#include "hero.h"

/*
 *   A routine to report an error text pointed to by text and then exit cleanly.
 */

void bye_bye(text)
char *text;
{
	printf("*** ERROR - %s!\n", text);
	exit(0);
}
