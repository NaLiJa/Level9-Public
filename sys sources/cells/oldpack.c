/*	PACKCELL.C  */

#include <stdio.h>
#include <dos.h>
#include <dir.h>

	FILE *infile;
	int long position;
	char far *screen=0Xa0000000L;
	int screenxbytes=40,screenylines=200,screenbitplanes=4;
	union REGS inregs,outregs;

	static struct ffblk fileblock;
	static char NeoScreen[32128];
	char *bufferptr;

	char garbage[80]; /*****/

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

/*--------------------*/

main(argc,argv)
	int argc;
	char **argv;

{
	int colour;

/* check parameters */
	if (argc!=2)
		{
		printf("try: PACKCELL filename\n");
		goto finish;
		}

	/* parse filename */
	fparse(argv[1],"NEO");

/* find first filename */
	if (findfirst(filename,&fileblock,0)!=0)
	{
		printf("File not found!\n");
		goto finish;
	}

/* open file */
	if ((infile=fopen(fileblock.ff_name,"rb"))==NULL) goto finish;

/* set screen mode */
	setmode(0);

/* set palette */
	fseek(infile,4L,SEEK_SET);
	for (colour=0;colour<16;colour++)
		setcolour(colour);

/* load data */
	fseek(infile,0L,SEEK_SET); /*128L*/
	ReadNeo(infile);
	fclose(infile);

	screen=0Xa0000000L;
/* Display it */
	DisplayNeo();

/* Remove repeated cells... */
	PackNeo();
	DisplayNeo();

	SaveNeo();

/* exit */

finish:

/* Wait for CR */
	printf("Press CR:\n");
	gets(garbage);
	setmode(99);
}


/*--------------------*/

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


/*--------------------*/

setbitplane(bitplane)
	int bitplane;

	{
    outp(0X3C4,2);
	outp(0X3C5,1<<bitplane);
	}


/*--------------------*/

setcolour(colour)
	int colour;

	{
	int tempvalue,portvalue;
	int red,green,blue;

	portvalue=0;

	red=(getc(infile)<<5);
	if ((red&64)!=0) portvalue|=4 ; /* 32;*/
	if ((red&128)!=0) portvalue|=32 ; /*4;*/

	tempvalue=getc(infile);
	green=((tempvalue<<1)&0XE0);
	if ((green&64)!=0) portvalue|=2; /*16;*/
	if ((green&128)!=0) portvalue|=16; /*2;*/

	blue=(tempvalue<<5);
	if ((blue&64)!=0) portvalue|=1; /*8; */
	if ((blue&128)!=0) portvalue|=8; /*1;*/

	if (red+green+blue!=0)
		{
		red|=63;
		green|=63;
		blue|=63;
		}

	if (IRGB[portvalue]>7) portvalue|=8;
/*	portvalue=IRGB[portvalue]; */

	inp(0X3DA);
	outp(0X3C0,colour);
	outp(0X3C0,portvalue);

	inp(0X3DA);
	outp(0X3C0,0X20);
	}


/*--------------------*/

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


/*--------------------*/

ReadNeo(stream)
	FILE *stream;

	{
	int c=32128;

	bufferptr=NeoScreen;
	while ((c--)!=0)
		*(bufferptr++)=getc(stream);
	}

/*--------------------*/

SaveNeo()
	{
		FILE *c; /*infile*/
		c=fopen(fileblock.ff_name,"wb") ;  /*Delete file*/
		fseek(c,0L,SEEK_SET); /*128L*/
		fwrite(NeoScreen,sizeof(char),sizeof(NeoScreen),c)   ;
		fclose(c);
	}

/*--------------------*/

DisplayNeo()
	{
	int bitp;

	for (bitp=0;bitp<screenbitplanes;bitp++)
		{
			setbitplane(bitp);
			DisplayScreen(bitp);
		}
	}

/*--------------------*/

PackNeo()
{
	char *PointerFrom,*PointerTo;
	int FromX,FromY,ToX;

	PointerTo=(PointerFrom=&(NeoScreen[128]));
	ToX=0;
	for (FromY=0;FromY<12;FromY++)
		{
			for (FromX=0;FromX<20;FromX++)
				{
					if ( CellNotBlank(PointerFrom)  )
						{
							if (PointerFrom!=PointerTo)
								{
									CopyCell(PointerFrom,PointerTo);
									EraseCell(PointerFrom);
								}
							PointerTo+=8;
							ToX+=1;
							if (ToX==20)
								{
									ToX=0;
									PointerTo+=2400;
								}
						}
					PointerFrom+=8; /* bytes between each cell */
				}
			PointerFrom+=2400; /* 2560=bytes per 20 cells (one line) */
		}
	}

/*--------------------*/

int CellNotBlank(Pointer)
/* Tell if Cell starting NeoScreen[Pointer] is transparent */
	char *Pointer;
	{
	int c;

	for (c=0;c<16;c++)
		{	if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			if (*Pointer++!='\0') goto NotBlank;
			Pointer+=152 ; /* 160=bytes per line  */
		}
	return(0);

NotBlank:
	return(1);
	}

/*--------------------*/

int CopyCell(PointerFrom,PointerTo)
	char *PointerFrom,*PointerTo;
	{
	int c;

	for (c=0;c<16;c++)
		{	*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			*PointerTo++=*PointerFrom++;
			PointerFrom+=152 ; /* 160=bytes per line  */
			PointerTo  +=152 ;
		}
	}

/*--------------------*/

int EraseCell(Pointer)
	char *Pointer;
	{
	int c;

	for (c=0;c<16;c++)
		{	*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			Pointer+=152 ; /* 160=bytes per line  */
		}
	}

/*--------------------*/

DeleteCell(Pointer)
	char *Pointer;
	{
	int c;

	for (c=0;c<16;c++)
		{
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			*Pointer++='\0';
			Pointer+=152 ; /* 160=bytes per line */
		}
/****	DisplayNeo(); *****/
	}

/*--------------------*/

FlashCell(Pointer)
	char *Pointer;
	{
	int b,c;

	for (c=0;c<16;c++)
		{
			for (b=0;b<8;b++)
				{
					*Pointer^=0xFF;
					Pointer++;
				}
			Pointer+=152 ; /* 160=bytes per line */
		}
	}

/*--------------------*/

DisplayScreen(offset)
	int offset;

	{
	int c;

	bufferptr=&(NeoScreen[128])+(2*offset);
	offset=0;
	for (c=0;c<4000;c++)
		{
		*(screen+offset++)=*(bufferptr++);
		*(screen+offset++)=*(bufferptr++);
		bufferptr+=6;
		}
	}


/*--------------------*/
