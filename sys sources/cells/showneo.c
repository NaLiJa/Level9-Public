/*	SHOWNEO.C  */

#include <stdio.h>
#include <dos.h>
#include <dir.h>


	FILE *infile;
	int long position;
	char far *screen=0Xa0000000L;
	int screenxbytes=40,screenylines=200,screenbitplanes=4;
	union REGS inregs,outregs;

	static struct ffblk fileblock;
	static char filebuffer[200];
	char *bufferptr;

/*	struct ffblk
			{
			char      ff_reserved[21];
			char      ff_attrib;
			unsigned  ff_ftime;
			unsigned  ff_fdate;
			long      ff_fsize;
			char      ff_name[13];
			};						*/

	static char filename[15];

static int IRGB[64]=
	{
		0,1,2,3,4,5,6,7,
		0,9,2,3,4,5,6,9,
		0,3,10,3,6,5,6,10,
		0,9,10,11,4,9,10,11,
		0,5,6,3,12,5,6,12,
		0,9,2,9,12,13,12,13,
		0,1,10,10,12,12,14,14,
		0,9,10,11,12,13,14,15,
	} ;

	main(argc,argv)
	int argc;
	char **argv;

	{
	int bitp,colour;

/* check parameters */
	if (argc!=2)
		{
		printf("try: SHOWNEO filename\n");
		goto farfinish;
		}

/* parse filename */
	fparse(argv[1],"NEO");


/* find first filename */
	if (findfirst(filename,&fileblock,0)!=0)
		{
		printf("File not found!\n");
		goto farfinish;
		}


/* main loop */
	do
	{


/* open file */
	if ((infile=fopen(fileblock.ff_name,"rb"))==NULL) goto finish;


/* set screen mode */
	setmode(0);


/* set palette */
	fseek(infile,4L,SEEK_SET);
	for (colour=0;colour<(1<<screenbitplanes);colour++)
		setcolour(colour);


/* load data */
	screen=0Xa0000000L;
	fseek(infile,128L,SEEK_SET);
	while (screenylines--!=0)
		{
		readbuffer(infile);
		for (bitp=0;bitp<screenbitplanes;bitp++)
			{
			setbitplane(bitp);
			writebuffer(bitp);
			}
		screen+=screenxbytes;
		}

finish:
	fclose(infile);
	}

/* search for next */
	while (findnext(&fileblock)==0);

/* Wait for key */
    while (getchar()==0);

/* exit */
	setmode(99);
farfinish:
	;
	}



setmode(modenumber)
	int modenumber;

	{
	int screenmode;

	switch(modenumber)
		{
		case 0 :screenmode=13;
				screenxbytes=320/8;
				screenylines=200;
				screenbitplanes=4;
				break;
		case 99:screenmode=2;
				break;
		}
	inregs.h.al=screenmode;
	inregs.h.ah=0;
	int86(0X10,&inregs,&outregs);
	}


setbitplane(bitplane)
	int bitplane;

	{
    outp(0X3C4,2);
	outp(0X3C5,1<<bitplane);
	}


setcolour(colour)
	int colour;

	{
	int tempvalue,portvalue=0;
	int red,green,blue;

	portvalue=0;

	red=(getc(infile)<<5);
	if ((red&64)!=0) portvalue|=32;
	if ((red&128)!=0) portvalue|=4;

	tempvalue=getc(infile);
	green=((tempvalue<<1)&0XE0);
	if ((green&64)!=0) portvalue|=16;
	if ((green&128)!=0) portvalue|=2;

	blue=(tempvalue<<5);
	if ((blue&64)!=0) portvalue|=8;
	if ((blue&128)!=0) portvalue|=1;

/*	if (IRGB[portvalue]>7) portvalue=portvalue|8;	*/

/******/
	portvalue=IRGB[portvalue];
	if (portvalue>7) portvalue |= 0xF0 ;

	if (colour==0) portvalue=0;
	if (colour==8) portvalue=4;
	if (colour==10) portvalue=6;
	if (colour==13) portvalue=7;
	if (colour==14) portvalue=240;
	if (colour==15) portvalue=2;

	inp(0X3DA);
	outp(0X3C0,colour);
	outp(0X3C0,portvalue);

	inp(0X3DA);
	outp(0X3C0,0X20);
	}


fparse(infilename,ext)
	char infilename[11],ext[2];

	{
	int c;

	for (c=0;c<8;c++)
		{
		filename[c]=infilename[c];
		if ((infilename[c]=='.')|(infilename[c]==0)) break;
		}
	filename[c++]='.';
	filename[c++]=ext[0];
	filename[c++]=ext[1];
	filename[c++]=ext[2];
	while (c<12) filename[c++]=' ';
	return;
	}


readbuffer(stream)
	FILE *stream;

	{
	int c=160;

	bufferptr=filebuffer;
	while ((c--)!=0)
		*(bufferptr++)=getc(stream);
	}


writebuffer(offset)
	int offset;

	{
	int c;

	bufferptr=filebuffer+(2*offset);
	offset=0;
	for (c=0;c<20;c++)
		{
		*(screen+offset++)=*(bufferptr++);
		*(screen+offset++)=*(bufferptr++);
		bufferptr+=6;
		}
	}


fpad(c,stream)
	int c;
	FILE *stream;

	{
	while (c--!=0)
		putc(0,stream);
    }